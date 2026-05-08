# VBTrainer 云架构设计

> 创建：2026-05-08
> 涵盖：云同步策略 + AI 训练数据管道 + 海外区起步 → 中国大陆扩张
> 状态：**设计阶段**，V1.5 启动开发

---

## 0. TL;DR

- **架构**：Hybrid Local-First + Opt-in Cloud Sync
- **时间表**：V1（M0-M6）仅本地 → V1.5（M6-M9）加云同步 → V2（M9-M12）AI 训练管道 → V3（M12+）中国大陆双区
- **后端栈**：Supabase（海外）→ 阿里云（中国大陆，V3 启动）
- **鉴权**：Sign in with Apple
- **首发区**：仅海外 / 美区 App Store；中国大陆延后到 V3
- **云同步定位**：**「看完整历史」的入口**（30 天以前数据需开云同步）
- **AI 训练**：**独立开关**，默认关；仅在云同步已开时可见

---

## 1. 决策记录（已敲定，不再讨论）

| 决定 | 选定 | 理由 |
|---|---|---|
| 上云时机 | V1.5（M6 左右） | 先把 V1 PMF 做出来再加云 |
| **云同步定位** | **「看历史」的入口** | 不是 AI 的前置；用户因想看历史而主动开 |
| **AI opt-in 关系** | **独立开关**，仅在云同步已开时可见 | 不绑架用户；尊重隐私偏好 |
| 本地保留策略 | 未开云：30 天滑动窗口；开云：30 天热数据 + 摘要 | 让"开云同步"有真正的产品价值 |
| 首发区域 | 仅海外区一年 | 个人开发者，无公司主体；用户多数有美区 Apple ID |
| 后端栈（V1.5）| Supabase | 一站式 Postgres + Auth + Storage + Edge Functions |
| 鉴权 | Sign in with Apple | 免费，无密码，Apple 生态摩擦最小 |
| 数据同步策略 | 增量同步 + 时间戳冲突解决 | 简单可靠 |
| AI 数据脱敏 | UUID + k-匿名 | 符合 PIPL 等主流隐私法 |

---

## 2. 数据流总图

```
┌─────────────────────────────────────────────────────────────┐
│  Apple Watch                  iPhone                         │
│  ┌────────────┐               ┌────────────┐                │
│  │ SwiftData  │── Watch ────► │ SwiftData  │   Always Local │
│  │ (always)   │  Connectivity │ (主库)     │   ────────────►│
│  └────────────┘               └─────┬──────┘                │
│                                     │                        │
│                       (用户开「云同步」)                       │
│                                     │                        │
└─────────────────────────────────────┼────────────────────────┘
                                      │
                                      ▼
                         ┌────────────────────────┐
                         │ Supabase (海外)         │
                         │ Postgres + Auth         │
                         │ ─────────────────       │
                         │ • workouts              │
                         │ • workout_sets          │
                         │ • reps                  │
                         │ • jump_tests            │
                         │ • templates             │
                         │ • personal_records      │
                         │ ✗ HealthKit 原始数据    │ ← 不上传
                         └──────────┬──────────────┘
                                    │
                       (用户开「AI 改进」)
                                    │
                                    ▼
                         ┌────────────────────────┐
                         │ AI 训练数据池           │
                         │ ────────────────       │
                         │ • 脱敏 user_id (UUID)  │
                         │ • 训练数据衍生品        │
                         │ • 删除 timestamp 精度   │
                         │ • k-匿名化              │
                         │ ✗ 真实身份信息          │
                         └────────────────────────┘
```

**核心原则**：
- **Local-first**：本地永远是 Source of Truth，离线 100% 可用
- **Cloud-secondary**：云是镜像 + AI 训练池，不是主存储
- **HealthKit 红线**：原始 HealthKit 数据**永远不上云**（Apple 审核要求）
- **Opt-in 双层**：云同步是一个开关，AI 训练数据贡献是另一个开关

---

## 3. 技术栈详细

### 3.1 后端：Supabase（海外起步）

为什么选 Supabase：
- Postgres 强大，未来迁移阿里云 RDS for PostgreSQL 几乎零代码改动
- Auth 支持 Sign in with Apple 开箱即用
- Edge Functions 可以写后端逻辑（TypeScript）
- Realtime 订阅可用于 V2 私教 SaaS（教练实时看学员）
- Row Level Security 强制每个查询带 user_id 过滤，避免泄露

**月成本估算**：
| 用户量 | Supabase 计划 | 月费 |
|---|---|---|
| 0-500 | Free | $0 |
| 500-5000 | Pro | $25 |
| 5000-50000 | Pro + add-ons | $100-300 |
| 50000+ | Team / Enterprise | $599+ |

V1.5 启动时月活预估 100-500 → Free tier 完全够。

### 3.2 鉴权：Sign in with Apple

```swift
import AuthenticationServices

// iOS 端流程：
let request = ASAuthorizationAppleIDProvider().createRequest()
request.requestedScopes = [.fullName, .email]
// 用户点 "用 Apple 登录"
// → 拿到 identityToken（JWT）
// → POST 给 Supabase Auth 接口换 Supabase 自家的 access token
// → 后续所有 Supabase 请求带这个 token
```

**优势**：
- 完全免费
- 用户零摩擦（Face ID 一秒登录）
- Apple 强制要求：你 App 用第三方登录就必须支持 Apple 登录，所以这是默认选项

### 3.3 数据库 Schema（Postgres）

镜像 `Shared/Models/` 但加上 `user_id` 隔离：

```sql
-- 用户主表
CREATE TABLE users (
    id UUID PRIMARY KEY,                -- 来自 Apple Sign In subject
    apple_user_identifier TEXT UNIQUE,
    nickname TEXT,
    onboarded_at TIMESTAMP,
    cloud_sync_enabled BOOLEAN DEFAULT false,
    ai_contribution_enabled BOOLEAN DEFAULT false,
    region TEXT DEFAULT 'overseas',     -- 'overseas' / 'cn' (V3 才用)
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 用户画像（与 SwiftData UserProfile 同步）
CREATE TABLE user_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    age INT, sex TEXT, height_cm DOUBLE PRECISION, weight_kg DOUBLE PRECISION,
    body_type TEXT, training_experience TEXT, training_goal TEXT,
    measured_hr_max INT, resting_hr INT,
    -- 不存：HealthKit 原始数据
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 训练记录（与 Workout 同步）
CREATE TABLE workouts (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    started_at TIMESTAMP NOT NULL,
    ended_at TIMESTAMP,
    exercise_id TEXT NOT NULL,
    notes TEXT, rpe INT,
    linked_template_id UUID,
    -- heart_rate_samples 不存这里，留在本地（HealthKit 衍生品也不上云）
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_workouts_user_started ON workouts(user_id, started_at DESC);

-- WorkoutSet
CREATE TABLE workout_sets (
    id UUID PRIMARY KEY,
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    set_index INT, weight_kg DOUBLE PRECISION,
    velocity_variant TEXT, target_velocity_min DOUBLE PRECISION, target_velocity_max DOUBLE PRECISION,
    vl_ceiling DOUBLE PRECISION, side TEXT, rest_after_seconds INT
);

-- Rep
CREATE TABLE reps (
    id UUID PRIMARY KEY,
    set_id UUID NOT NULL REFERENCES workout_sets(id) ON DELETE CASCADE,
    rep_index INT,
    mean_velocity DOUBLE PRECISION, peak_velocity DOUBLE PRECISION, mean_propulsive_velocity DOUBLE PRECISION,
    timestamp TIMESTAMP, met_status TEXT
);

-- JumpTest
CREATE TABLE jump_tests (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    performed_at TIMESTAMP, attempts JSONB, flight_time_seconds JSONB, best_height_cm DOUBLE PRECISION,
    linked_workout_id UUID
);

-- Template / TemplateItem
CREATE TABLE templates (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT, notes TEXT, created_at TIMESTAMP, updated_at TIMESTAMP
);

CREATE TABLE template_items (
    id UUID PRIMARY KEY,
    template_id UUID NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
    item_index INT, exercise_id TEXT, target_sets INT, target_reps INT,
    target_weight_kg DOUBLE PRECISION, target_velocity_min DOUBLE PRECISION,
    target_velocity_max DOUBLE PRECISION, vl_ceiling DOUBLE PRECISION,
    rest_seconds INT, side TEXT
);

-- PR
CREATE TABLE personal_records (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id TEXT, kind TEXT, value DOUBLE PRECISION, achieved_at TIMESTAMP,
    source_workout_id UUID, source_jump_test_id UUID
);

-- Row Level Security 强制
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;
CREATE POLICY workouts_owner ON workouts FOR ALL USING (user_id = auth.uid());
-- 其他表同
```

### 3.4 同步协议

**增量同步 + 客户端单向 push**（V1.5 的最小可行版）：

```
1. 客户端：每次 App 进入前台时
2. 拉取本地 last_synced_at 之后的所有 SwiftData 变更
3. POST 到 Supabase Edge Function /sync/upload
4. Edge Function：upsert 到 Postgres，返回 server_synced_at
5. 客户端：更新本地 last_synced_at

冲突策略：last write wins（用客户端 updated_at 比对）
特殊：Workout / Rep 是 append-only，不会冲突
冲突：UserProfile / Template 用客户端最新版覆盖
```

**V2 升级到双向**（拉取也拉服务端变更，用于私教 SaaS 教练编辑学员计划）：

```
1. 客户端发本地变更
2. 服务端返回服务端变更（自上次同步以来）
3. 客户端 merge 到本地 SwiftData
```

### 3.5 不上云的数据

| 数据类型 | 上云？ | 原因 |
|---|---|---|
| Workout / Set / Rep | ✅ | 训练衍生数据 |
| Template / TemplateItem | ✅ | 用户自建 |
| PersonalRecord | ✅ | 训练衍生 |
| JumpTest 跳跃高度 | ✅ | 训练衍生 |
| **心率原始序列** | ❌ | HealthKit 数据，Apple 红线 |
| **HRV / RHR / 睡眠** | ❌ | HealthKit 数据，Apple 红线 |
| **手腕温度** | ❌ | HealthKit 数据 |
| **ReadinessSnapshot 完整** | ⚠️ 仅 score + tier | 不传子项原始值 |
| **IMU 原始信号** | ❌ | V1 根本不存 |

ReadinessSnapshot 上云的字段：
```sql
CREATE TABLE readiness_snapshots (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE,
    score INT,        -- 0-100，可以上
    tier TEXT,        -- green/yellow/red/insufficient
    -- 不存：hrv / rhr / sleep / temp 原始值
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 4. 云同步定位 + AI 训练数据管道

### 4.1 核心定位（关键修订 2026-05-08）

> **云同步是「看历史」的入口，不是「开 AI」的前置条件**。

#### 用户视角的两个独立开关

```
☐ 启用云同步              （默认关）
   作用：保存完整训练历史 + 跨设备恢复
   不开 → 仅看本地缓存（最近 30 天）
   开了 → 看全部历史 + 换手机自动恢复

☐ 帮助改进 AI（实验性）   （默认关）
   作用：你的脱敏数据用于改进 AI 教练算法
   仅在已开启云同步时可见此选项
   关联：技术上必须先有云上数据才能进 AI 池
```

#### 为什么这样设计

- **云同步用「历史数据」做钩子**：99% 的健身用户都想看自己的进步曲线，这是天然刚需
- **AI 训练彻底解耦**：用户开同步**不**等于贡献数据；想隐私的用户也能享受跨设备
- **AI opt-in 是二次确认**：开了同步 ≠ 默认贡献训练数据；用户在设置里二次开启
- **Apple 审核更顺**：不强制收数据，AI 仅"实验性""帮助改进"措辞，审核压力小

#### 用户流转图

```
Onboarding (V1.5)
    │
    ▼
看到「启用云同步」开关 + 解释「保存历史 + 跨设备」
    │
    ├── 不开 → 仅本地，30 天滑动窗口   (大部分隐私敏感用户)
    │
    └── 开 → 数据上云
              │
              ▼
         设置页 → 「帮助改进 AI」开关（默认关）
              │
              ├── 不开 → 数据仅自用，不进 AI 池      (默认)
              │
              └── 开 → 数据脱敏后进入 AI 训练管道    (少数贡献者)
```

### 4.2 本地缓存策略（关键工程决定）

**未开云同步用户**：本地 SwiftData 仅保留最近 30 天完整数据 + 之前的"摘要"。
**开了云同步用户**：本地 + 云双份，本地仍保留最近 30 天热数据，更早的历史按需从云拉取。

```swift
// V1.5 加入的本地清理逻辑
struct LocalRetentionPolicy {
    static let hotDataDays = 30
    
    // 用户未开云同步：30 天前数据完全删除
    // 用户开了云同步：30 天前数据本地保留摘要（id + date + exerciseId + setCount）,
    //                 用户点开详情时从云拉
}
```

### 4.3 脱敏方案

```
原始云数据                  AI 训练池
─────────────              ─────────────
user_id (UUID)        →    pseudonym_id (新 UUID, 单向哈希)
exact timestamp       →    bucketed timestamp (precision=hour)
exact body data       →    bucketed (age=23 → 20-25, weight=72.3 → 70-75)
精确动作记录          →    保留（动作 ID + reps + 速度）
exact GPS / location  →    完全删除
注释 / RPE           →    删除（V2 看是否需要）
```

K-匿名化：每个组合（age_bucket × sex × experience × goal）至少有 ≥ 5 个用户才放进 AI 池，否则丢弃。

### 4.4 用户控制

设置页加两个独立入口：

**「云同步」入口**：
- 当前状态（开 / 关）
- 已同步多少条训练记录
- 上次同步时间
- 关闭云同步 + 删除我的所有云数据（一键）

**「帮助改进 AI（实验性）」入口**（仅在云同步已开时显示）：
- 当前状态（开 / 关）
- 已贡献多少条数据
- 一键关闭并删除我的所有 AI 训练数据
- 数据使用说明（含论文级别透明度）

---

## 5. HealthKit 与 App Store 审核策略

### 5.1 Apple 红线
> "You must not store any data collected through the HealthKit API in iCloud."（Apple Developer 文档）

**解读**：
- ❌ 不能：把心率原始序列上传到任何云服务器
- ✅ 可以：把训练记录（包含计算出的 avg HR）上云
- ✅ 可以：本地处理 HealthKit 数据，处理后写到 Workout 模型
- ✅ 可以：用户主动导出 CSV / JSON 含 HealthKit 数据（用户自主行为）

### 5.2 提交时的关键说明

App Store Review 提交时，"App Privacy" 部分要写清楚：
- ✅ Health & Fitness data: Used and stored on device, NOT linked to user account
- ✅ Workout records (no health data): Optionally synced via your account
- ✅ Linked or not linked to user identity: 看用户开关

提交后第一次审核 Apple 大概率会问"你怎么处理 HealthKit 数据"——把 5.1 这段直接贴过去。

### 5.3 隐私政策（Privacy Policy）

需要起草一份，**App Store 必须有**。核心条款：

1. 我们存什么 / 不存什么（区分本地 vs 云）
2. 用户开关控制权
3. 数据在哪里（Supabase 海外）
4. 如何删除账号 + 数据
5. 联系方式（邮箱）

V1.5 上线前我会写好模板。

---

## 6. 实施时间表

```
M0 - M5  (V1)     仅本地 SwiftData，不开发后端
                  ✅ 当前已完成

M5 - M6  V1.5 设计阶段
                  - 选定后端方案（已选 Supabase）
                  - Schema 落地（本文档）
                  - Sign in with Apple 集成
                  - 隐私政策起草

M6 - M8  V1.5 开发
                  - Supabase 项目初始化
                  - Edge Functions 开发（/sync/upload）
                  - iOS 端 SyncService 实现
                  - Onboarding 加 2 个开关
                  - 设置页加「云同步」「AI 贡献」详情入口

M8 - M9  V1.5 测试 + 上线
                  - 内测 10 用户验证同步可靠性
                  - App Store 审核（重点跑 HealthKit 红线）
                  - 上线

M9 - M11 V2.0 AI 训练管道
                  - AI 数据脱敏 ETL
                  - 训练数据 schema 锁定
                  - 用户控制台升级（贡献量 + 删除入口）

M12 - M15 V2.x AI 推断接入
                  - Claude API / 自训练模型接入
                  - 训练前 readiness 推断
                  - 训练后复盘对话
                  - 计划生成

M15+    V3 中国大陆扩张
                  - 注册公司
                  - ICP / 网信办 / 算法备案
                  - 阿里云迁移（数据本地化）
                  - 中国大陆 App Store 上架
                  - 微信支付 / 支付宝集成
```

---

## 7. 成本估算

### 7.1 V1.5 上线前一次性投入
- Apple Developer Program: ¥99/年
- 域名（如 vbtrainer.app）: ~¥80/年
- 隐私政策起草（自己写或用模板）: ¥0
- **合计：~¥200**

### 7.2 V1.5 月度运营成本（按用户量）

| 阶段 | 月活 | 后端 | 域名+其他 | 月总 |
|---|---|---|---|---|
| 内测 | 10-100 | $0（Free） | ¥10 | <¥100 |
| 早期 | 100-1000 | $0-25 | ¥10 | ¥80-200 |
| 增长 | 1000-10000 | $25-100 | ¥10 | ¥200-800 |
| 商业化 | 10000-50000 | $100-300 | ¥20 | ¥800-2500 |

**关键观察**：
- 月活 1000 以下基本免费
- 月活 5000 时月成本约 ¥500
- 1000 付费用户（年费 ¥299）= ¥30 万/年收入 ≫ 服务器成本

### 7.3 V2 AI 推断额外成本
- Claude API：按调用付费（每用户每月 $0.5-2）
- 自训练模型：先用 Claude API，达到 5 万付费用户再考虑自训练

---

## 8. 风险与缓解

| 风险 | 概率 | 影响 | 缓解 |
|---|---|---|---|
| Apple 审核拒绝（HealthKit 上云） | 中 | 严重 | 严格遵守 5.1 红线，提交说明详细 |
| Supabase 服务中断 | 低 | 中 | 本地 SwiftData 是 source of truth，云挂掉用户照常用 |
| 数据泄露 | 低 | 严重 | RLS + TLS 1.3 + at-rest 加密 + 审计日志 |
| 用户拒绝开同步 | 中 | 中（影响 AI 训练量） | 仅做轻度引导，不强迫 |
| 中国合规推迟 | 高 | 低（V3 才需要） | 先海外验证 PMF |
| 备份丢失 | 低 | 严重 | Supabase 自动每日备份 + 每月手动 dump 到 S3 |

---

## 9. 与 V1 已有代码的兼容

V1 设计时已经预留好接口，V1.5 几乎不需要改 V1 代码：

| 现有 | V1.5 怎么用 |
|---|---|
| `WorkoutSnapshot` (Codable) | 直接 JSON 化 POST 给 Edge Function |
| `JumpTestSnapshot` | 同上 |
| `ConnectivityProtocol` | iPhone 收到 Watch 数据后 → 同步到云 |
| `WorkoutStore.save(...)` | 加一个 hook：保存后异步触发云同步 |
| `iPhoneConnectivityService` | 加个 SyncService 协同 |

新增组件（V1.5）：
- `Shared/Services/CloudSyncService.swift`
- `Shared/Services/AppleAuthService.swift`
- `Shared/Models/SyncMetadata.swift`（last_synced_at 等）

---

## 10. 隐私 FAQ（用户问到时直接答）

### Q: 我开了云同步，VBTrainer 能看到我的心率数据吗？
**A**: 不能。心率、HRV、睡眠等 HealthKit 数据**永远只在你 iPhone 上**，不上云。云上只有训练动作、组数、速度等训练记录。

### Q: 我开了"帮助改进 AI"，我的数据会被卖给广告商吗？
**A**: 不会。数据仅用于训练我们的 AI 教练算法，不出售、不与第三方共享。完全脱敏后存储。

### Q: 我能删除我的云数据吗？
**A**: 能。设置 → 账号 → 删除我的所有云数据。15 天内完全清除。

### Q: 我换手机怎么办？
**A**: 新手机开 App，用同一个 Apple ID 登录，开云同步 → 历史数据自动恢复。

### Q: 我不开云同步会失去什么？
**A**: **看不到 30 天前的完整训练历史**——这是云同步的核心功能。本地只保留最近 30 天热数据。其他失去的：换手机迁移、跨设备同步、AI 教练（V2，需先开云同步才能开）。

### Q: 我开了云同步，是不是就自动加入 AI 训练了？
**A**: **不是**。云同步只是把你的训练记录存到云端，让你看完整历史。AI 训练数据贡献是**单独的开关**（默认关），需要在设置页二次开启。两者完全独立。

---

## 文档维护

- 每个 V 版本（V1.5、V2、V3）启动时 review 一次
- Schema 改动同步更新本文档
- 隐私政策修订必须同步更新

### Changelog
- 2026-05-08：初版（基于用户决定 A/B/B/A）

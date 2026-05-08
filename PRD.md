# VBTrainer PRD（V1 终版）

> 创建日期：2026-05-08
> 负责人：Zexi
> 文档版本：V1.0（功能定稿）
> 后续 UI/交互细节由设计同学加入后单独出 Design Spec

---

## 0. 一句话定位

**Apple Watch + iPhone 的 VBT（基于速度的力量训练）数据采集与复盘工具。V1 让用户自己当教练，V2 接入 AI 当私教。**

---

## 1. 产品哲学

- **V1：数据采集 + 数据展示。用户自己承担教练职责。**
- **V2：AI 私教介入分析、推断、动态调整计划。**

V1 的所有数据采集都为 V2 的 AI 接入服务 —— 现在多收集一种数据，未来 AI 就多一个分析维度。

---

## 2. V1 功能模块总览

```
┌─────────────────────────────────────────────────────┐
│                    VBTrainer V1                      │
├─────────────────────────────────────────────────────┤
│ M1  首次启动引导（用户画像采集）                     │
│ M2  训练前状态评估（睡眠/HRV/CMJ 数据采集 + 展示）   │
│ M3  训练计划（用户自建模板）                         │
│ M4  训练采集（Watch 端 IMU + 心率 + Rep + 速度）     │
│ M5  智能震动反馈                                     │
│ M6  训练复盘（综合图表）                             │
│ M7  长期趋势分析                                     │
│ M8  个人记录 PR 追踪                                 │
│ M9  数据存储与导出                                   │
│ M10 设置                                             │
└─────────────────────────────────────────────────────┘
```

---

## 3. 模块详细设计

### M1 首次启动引导（用户画像采集）

首次启动收集，后续可在设置中修改。

**必填**：
- 年龄
- 性别
- 身高 / 体重
- 体型（瘦 / 标准 / 偏壮 / 健美 / 力量型）
- 训练年限（< 1 年 / 1-3 年 / 3-5 年 / > 5 年）
- 训练目标（增肌 / 力量 / 爆发 / 减脂 / 综合）

**可选**：
- 实测最大心率（不填用 Tanaka 公式 208 - 0.7×年龄 推算）
- 静息心率（不填从 HealthKit 自动读）

**HealthKit 权限请求**：
- 读：心率、HRV、静息心率、睡眠分析、手腕温度、呼吸率、血氧、VO2Max、活动能量、步数
- 写：Workout、心率（训练数据写回 Apple 健康）

---

### M2 训练前状态评估（核心差异化）

**目的**：V1 只采集和展示，不动态调整计划，用户自己看着办。

#### M2.1 静态身体准备度（HealthKit 数据）

训练开始前自动读取并展示：

```
┌──────────────────────────────────┐
│  今日身体准备度                   │
│  ─────────────────────────────  │
│  睡眠时长：7.5h（深睡 1.8h）     │
│  HRV：48ms（基线 52ms ↓ 8%）    │
│  静息心率：58bpm（基线 56 ↑ 4%） │
│  手腕温度：+0.2°C                │
│  呼吸率：14.5（基线 14.2）       │
│  ─────────────────────────────  │
│  Readiness Score: 72/100  🟡    │
│  （仅参考，自行决定训练强度）     │
└──────────────────────────────────┘
```

**Readiness Score 公式**（V1 规则版，论文权重）：
- HRV 偏离基线 50%
- 睡眠时长 + 深睡占比 25%
- RHR 偏离基线 20%
- 手腕温度偏移 5%

阈值映射：
- ≥ 80 → 🟢 绿灯（可按计划训练）
- 60-79 → 🟡 黄灯（按计划但建议保守）
- < 60 → 🔴 红灯（建议降低强度或休息）

**重要**：V1 只显示评分，**不自动调整任何训练参数**。

**论文依据**：
- Plews et al. (2013). *Training adaptation and heart rate variability in elite endurance athletes.* Sports Med 43(9):773-781. https://pubmed.ncbi.nlm.nih.gov/23852425/
- Flatt & Esco (2016). *Smartphone-Derived Heart-Rate Variability and Training Load.* Int J Sports Physiol Perform 11(8):994-1000. https://pubmed.ncbi.nlm.nih.gov/26869210/
- Watson et al. (2017). *Sleep and athletic performance.* Curr Sports Med Rep 16(6):413-418. https://pubmed.ncbi.nlm.nih.gov/29135639/
- Buchheit (2014). *Monitoring training status with HR measures.* Front Physiol 5:73. https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3936188/

#### M2.2 主动状态测试（CMJ 跳跃）⭐ 新增

训练开始前提醒用户做 CMJ 跳跃测试（Counter-Movement Jump）：

**测试流程**：
1. Watch 戴手腕（或裤兜，提供两种校准模式）
2. App 提示「跳 3 次最大努力 CMJ，每次间隔 10s」
3. Watch 自动检测 3 次跳跃
4. 计算每次跳跃的 **Jump Height**（基于飞行时间法 t² × g / 8）
5. 取 3 次最佳值

**用途（V1 仅展示，不自动调整）**：
- 与个人 7 天 / 30 天基线对比
- 偏离 > 10% 提示「神经系统疲劳，建议保守」
- 数据存档供 V2 AI 分析

**论文依据**：
- Claudino et al. (2017). *The countermovement jump to monitor neuromuscular status: A meta-analysis.* J Sci Med Sport 20(4):397-402. https://pubmed.ncbi.nlm.nih.gov/27663764/
- Watkins et al. (2017). *Determination of Vertical Jump as a Measure of Neuromuscular Readiness.* J Strength Cond Res 31(12):3305-3310. https://pubmed.ncbi.nlm.nih.gov/29189407/
- Linthorne (2001). *Analysis of standing vertical jumps using a force platform.* Am J Physics 69:1198. （飞行时间法理论基础）

**用户体验**：
- 是否做 CMJ 测试可在设置中关闭
- 每次训练前可跳过
- 不强制（避免每次开训都要先跳）

#### M2.3 V1 用户自决策

界面给用户三个数字 + 一个可选 CMJ + 一段历史趋势小图。**App 不替用户做决定**。

> 「今天 HRV 偏低 8%，CMJ 高度比基线低 12%。是否调整今天的训练强度由你自己决定。」

V2 接入 AI 后再做主动建议和计划调整。

---

### M3 训练计划（用户自建模板）

**V1 不内置任何模板**。参考训记 App 的手机端 + 手表端交互。

**M3.1 模板创建（iPhone）**：
- 命名
- 添加动作序列
- 每动作设置：目标组数 / 目标 reps / 目标重量 / 目标速度区间或 VL 阈值
- 模板可复制、修改、删除

**M3.2 计划执行**：
- 模板挂到日历某天
- iPhone 编辑后自动同步到 Watch
- Watch 端按计划逐项展示「下一项：深蹲 100kg × 5」
- 完成 / 跳过状态记录
- 实际数据自动回填到计划项

**M3.3 完成度追踪**：
- 单日计划达成率
- 实际 vs 计划对比表（重量、reps、速度差异）

---

### M4 训练采集（Watch 端核心）

#### M4.1 动作库（30 个）

**杠铃**（16 个）：深蹲 / 前蹲 / 高杠深蹲 / 低杠深蹲 / 卧推 / 上斜卧推 / 下斜卧推 / 窄距卧推 / 硬拉 / 相扑硬拉 / 罗马尼亚硬拉 / 站姿肩推 / 坐姿肩推 / 借力推 / 杠铃划船 / 杠铃弯举

**哑铃**（6 个）：哑铃推举 / 哑铃飞鸟 / 哑铃划船 / 哑铃弯举 / 哑铃肩推 / 保加利亚分腿蹲

**自重 / 器械**（8 个）：引体向上 / 俯卧撑 / 自重深蹲 / 双杠臂屈伸 / 高位下拉 / 坐姿划船 / 腿举 / CMJ 跳跃

每个动作内置元数据：
- 类型、首选测速变量（MV / PV / MPV）
- V1RM 参考速度（论文值）
- 推荐 VL 阈值
- 默认目标速度区间
- 是否单边

#### M4.2 实时数据流

- IMU 100Hz（Core Motion `userAcceleration`）
- 心率（HKWorkoutSession + HealthKit）
- 自动 rep 识别
- 每 rep 计算 MV / PV / MPV
- VL% 实时计算
- 组内累计：reps / avg 速度 / peak 速度

#### M4.3 训练结构

- 多组训练
- 组间 Digital Crown 调重量（档位 0.5 / 1 / 2.5 / 5 kg 可选）
- 组间休息倒计时（30 / 60 / 90 / 120 / 180s，默认 90s）
- 倒计时结束震动
- 下一组重量建议（基于上组 VL%，规则引擎）
- 单边动作左右分别记录
- 结束本组 / 结束训练独立按钮

---

### M5 智能震动反馈（核心差异化）

每个 rep 完成时根据速度触发不同震动模式：

```
★ 优秀（≥ 区间上限）        → 双击短震
✓ 达标（区间内）            → 单次中等震
⚠ 偏慢（区间下沿 5% 内）    → 单次长震
✗ 未达标（< 区间下限）      → 三次急促震
```

**用户配置项**：
- 每个动作独立目标速度区间
- 测速变量（MV / PV / MPV）
- VL% 警戒线（达到后强制停组震动）
- 默认值由论文推导，用户可改

---

### M6 训练复盘（iPhone 单次详情）

#### M6.1 基本信息
- 动作列表 / 日期 / 组数 / 总 reps / 总训练量（kg·reps）
- 备注 / 主观感受字段（RPE 1-10 可选填）

#### M6.2 综合图表（核心，一张图集中展示）⭐

```
横轴：训练全程时间线
纵轴 1（左）：心率 bpm
纵轴 2（右）：速度 m/s

图层叠加：
  ─── 心率曲线（红色）
  ●   每 rep 速度散点 / 折线（蓝色，按动作分色）
  ▮   动作切换标记（垂直分隔线 + 标签：深蹲 100kg / 卧推 80kg）
  ▒   组间休息区间（灰色背景区块）
  ┄   VL 警戒线（虚线）
```

可缩放 / 拖动；点击 rep 散点弹出详情（速度、index、所属组）。

#### M6.3 辅助图表
- 心率区间分布饼图（Z1-Z5）
- 每组数据表（重量 / reps / avg 速度 / peak 速度 / VL%）
- 每 rep 速度按组分色折线
- VL% 柱状图（每组一柱）

#### M6.4 条件性展示

**力速曲线（LVP）+ e1RM 估算**：
- 数据要求：≥ 5 组不同重量数据，覆盖 ≥ 30% 1RM 范围
- 不足时显示提示卡片：「再记录 N 组不同重量数据即可解锁 LVP 与 1RM 估算」
- 达标后自动展示散点 + 回归直线 + e1RM 数值

#### M6.5 训练前后状态对比
- 训练前：Readiness Score / 睡眠 / HRV / CMJ 高度
- 训练后：心率恢复曲线 / 平均训练强度 / VL% 分布

---

### M7 长期趋势分析（iPhone）

**单动作维度**：
- 最大重量进步曲线
- e1RM 进步曲线（数据足够后启用）
- 同负重下 avg 速度变化
- 训练量周聚合趋势
- VL% 分布趋势
- 力速曲线月度演变叠加
- 训练频率热力图（GitHub 风格）

**跨动作总览**：
- 训练量动作占比饼图
- 周 / 月训练时长趋势
- 心率区间累计时间

**身体状态趋势**：
- 7/30/90 天 HRV 基线变化
- 睡眠时长趋势
- CMJ 高度趋势
- Readiness Score 历史

---

### M8 个人记录 PR 追踪

自动追踪每个动作：
- 最大重量
- e1RM（数据足够后）
- 单次最大训练量
- 单 rep 最大速度
- CMJ 最高跳跃

**触发**：
- PR 时训练详情页打标
- 全 App 推送通知（可关）
- PR 历史列表

---

### M9 数据存储与导出

**存储**（V1 阶段）：
- SwiftData 本地持久化
- HealthKit 写回（Workout + 心率）
- **V1 不传服务器**（V1.5 起加 opt-in 云同步——见 §8.V1.5；HealthKit 原始数据始终不上云）

**导出**：
- CSV（含每 rep 原始数据）
- JSON（完整结构化数据）
- 本地备份 / 恢复

**不做**：
- ❌ Keep / 训记 数据导入（V2 再做）
- ❌ 云同步
- ❌ 多设备同步

---

### M10 设置

- 个人画像编辑（年龄 / 性别 / 体型 / 训练年限 / 目标 / HRmax / 静息心率）
- 单位（kg / lb）
- Digital Crown 重量档位
- 组间休息默认时长
- 每动作目标速度区间
- 震动等级阈值
- VL% 警戒线
- 训练前 CMJ 测试开关
- HealthKit 同步开关
- 导入 / 导出（CSV / JSON）
- 调试模式（原始 IMU 流可视化）

---

## 4. Watch / iPhone 通信架构

```
iPhone 端                              Watch 端
─────────                              ─────────
SwiftData 主库                         本地 SwiftData 缓存
计划 / 模板 / 用户画像          ────►  下发 + 同步
                                       
                                       训练中：本地缓存 IMU + rep
                                       （不实时回传，省电）
                                       
训练历史 / 长期统计           ◄────    训练结束：批量回传
HealthKit 数据                          
（睡眠 / HRV / CMJ）          ────►   训练前下发到 Watch 显示
```

---

## 5. 算法与论文依据汇总

### 5.1 Apple Watch 手腕戴 VBT 可行性
> Balshaw et al. (2023). *Validity of an Apple Watch for determining bench press velocity.* https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10383699/

手腕戴 ICC > 0.9，平均偏差 ±0.05–0.10 m/s。

### 5.2 Rep 识别（峰值检测 + 状态机）
> O'Reilly et al. (2018). *Wearable Inertial Sensor Systems for Lower Limb Exercise Detection.* Sports Med 48: 1221-1246. https://link.springer.com/article/10.1007/s40279-018-0878-4

基于 `userAcceleration.z` 过零检测 + 状态机（rest → eccentric → bottom → concentric → top）。

### 5.3 速度计算（积分 + ZUPT）
> Skog et al. (2010). *Zero-Velocity Detection—An Algorithm Evaluation.* IEEE Trans Biomed Eng, 57(11): 2657-2666. https://ieeexplore.ieee.org/document/5523938
>
> Foxlin (2005). *Pedestrian Tracking with Shoe-Mounted Inertial Sensors.* IEEE CG&A 25(6): 38-46. https://ieeexplore.ieee.org/document/1528433

时间积分得速度；rep 起止点 ZUPT 强制归零，避免漂移累积。

### 5.4 速度损失 VL%
> Sánchez-Medina & González-Badillo (2011). *Velocity loss as an indicator of neuromuscular fatigue during resistance training.* Med Sci Sports Exerc, 43(9): 1725-34. https://pubmed.ncbi.nlm.nih.gov/21311352/
>
> Pareja-Blanco et al. (2017). *Effects of velocity loss during resistance training.* Scand J Med Sci Sports, 27(7): 724-735. https://pubmed.ncbi.nlm.nih.gov/27038416/

`VL% = (V_first − V_current) / V_first × 100`

默认阈值：爆发 10% / 力量 20% / 增肌 30% / 肌耐力 40%+。

### 5.5 V1RM（1RM 时参考速度）
> González-Badillo & Sánchez-Medina (2010). *Movement velocity as a measure of loading intensity.* Int J Sports Med, 31(5): 347-352. https://pubmed.ncbi.nlm.nih.gov/20180176/

卧推 MPV 0.17 / 深蹲 MPV 0.30 / 硬拉 MV 0.15 m/s。

### 5.6 力速曲线 LVP + e1RM 估算
> Jidovtseff et al. (2011). *Using the load-velocity relationship for 1RM prediction.* J Strength Cond Res, 25(1): 267-270. https://pubmed.ncbi.nlm.nih.gov/19966589/
>
> García-Ramos et al. (2018). *Differences in the load-velocity profile between 4 bench-press variants.* Int J Sports Physiol Perform, 13(3): 326-331. https://pubmed.ncbi.nlm.nih.gov/28872384/

需 ≥ 5 组不同负重，覆盖 ≥ 30% 1RM 范围；线性回归 `v = a·load + b`；e1RM = (V1RM − b) / a。

### 5.7 测速变量选择 (MV / PV / MPV)
> Sánchez-Medina et al. (2010). *Importance of the propulsive phase in strength assessment.* Int J Sports Med, 31(2): 123-129. https://pubmed.ncbi.nlm.nih.gov/20222005/

含显著制动相的动作（卧推 / 肩推）用 MPV；深蹲用 MV；CMJ / 抓举用 PV。

### 5.8 心率区间 Z1-Z5
> Tanaka et al. (2001). *Age-predicted maximal heart rate revisited.* J Am Coll Cardiol, 37(1): 153-156. https://pubmed.ncbi.nlm.nih.gov/11153730/
>
> ACSM (2018). *Guidelines for Exercise Testing and Prescription, 10th ed.*

HRmax = 208 − 0.7×年龄（用户实测优先）。Z1 50-60% / Z2 60-70% / Z3 70-80% / Z4 80-90% / Z5 90-100% HRmax。

### 5.9 HRV / 睡眠 / 训练准备度
> Plews et al. (2013). *Training adaptation and heart rate variability in elite endurance athletes.* Sports Med 43(9):773-781. https://pubmed.ncbi.nlm.nih.gov/23852425/
>
> Flatt & Esco (2016). *Smartphone-Derived Heart-Rate Variability and Training Load.* Int J Sports Physiol Perform 11(8):994-1000. https://pubmed.ncbi.nlm.nih.gov/26869210/
>
> Buchheit (2014). *Monitoring training status with HR measures.* Front Physiol 5:73. https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3936188/
>
> Watson et al. (2017). *Sleep and athletic performance.* Curr Sports Med Rep 16(6):413-418. https://pubmed.ncbi.nlm.nih.gov/29135639/

### 5.10 CMJ 神经肌肉状态评估
> Claudino et al. (2017). *The countermovement jump to monitor neuromuscular status: A meta-analysis.* J Sci Med Sport 20(4):397-402. https://pubmed.ncbi.nlm.nih.gov/27663764/
>
> Watkins et al. (2017). *Determination of Vertical Jump as a Measure of Neuromuscular Readiness.* J Strength Cond Res 31(12):3305-3310. https://pubmed.ncbi.nlm.nih.gov/29189407/

跳跃高度 = 飞行时间² × g / 8。

### 5.11 重量建议规则（V1 非 AI）
基于上组 VL% + 论文阈值：
- VL < 10% 且达标 reps → +2.5kg
- VL 10-25% → 保持
- VL > 30% → -2.5kg
- 连续 3 次同重量达标 → 主动建议加重

依据：Sánchez-Medina (2011) + Pareja-Blanco (2017)。

---

## 6. V1 验收标准

1. ✅ 首次启动完成画像采集 + HealthKit 权限申请
2. ✅ 训练前展示 Readiness 卡片（睡眠 / HRV / RHR / 温度）
3. ✅ 可选 CMJ 测试，自动检测 3 次跳跃 + 计算高度
4. ✅ Watch 创建多组训练，rep 识别准确率 ≥ 95%
5. ✅ 速度区间内 / 外震动反馈正确触发
6. ✅ 训练完成数据传到 iPhone
7. ✅ iPhone 详情页综合图表（心率 + 速度 + 动作切换 + 休息区间叠加）
8. ✅ 5 组不同重量数据后 LVP + e1RM 自动解锁
9. ✅ 长期趋势图表展示至少 3 个动作的进步曲线
10. ✅ 用户可创建自定义计划模板，下发到 Watch 执行
11. ✅ 数据可导出 CSV / JSON
12. ✅ 所有算法在代码注释中标注论文 DOI / URL

---

## 7. V1 明确不做

- ❌ AI 复盘 / AI 计划生成 / AI 计划动态调整 → V2
- ❌ 基于 Readiness / CMJ 的自动计划调整 → V2
- ❌ Keep / 训记 数据导入 → V2
- ❌ 内置计划模板（用户自建）
- ❌ 用户账号 / 云同步 / 多设备
- ❌ 社交 / 排行榜 / 社区
- ❌ 支付 / 订阅
- ❌ 私教 SaaS
- ❌ 3D 杠铃轨迹
- ❌ 视频录制 / 姿势识别

---

## 8. V1.5 / V2 / V3 路线图（云架构 + AI 介入）

> V1 上线、自用 + 朋友试用 4-6 周后启动 V1.5；V1.5 上线后 4-6 周启动 V2。
>
> 详细技术架构见 [docs/CLOUD_ARCHITECTURE.md](docs/CLOUD_ARCHITECTURE.md)

### V1.5 云同步（M6 - M9）

**V1.5.1 鉴权 + 云后端**
- 后端：Supabase（海外起步）
- 鉴权：Sign in with Apple
- 仅海外区 App Store 上线

**V1.5.2 选择性云同步**
- Onboarding 第一个开关「启用云同步」（默认关）—— **作用：保存完整训练历史 + 跨设备恢复**
- 本地 SwiftData 仅保留最近 30 天热数据；30 天前的历史**只在开了云同步时**可见
- 设置页第二个开关「帮助改进 AI」（默认关）—— **独立 opt-in**，仅在云同步已开时显示
- 同步范围：Workout / Set / Rep / Template / PR 等训练衍生数据
- **不**同步 HealthKit 原始数据（心率/HRV/睡眠/温度）— Apple 红线
- 跨设备恢复：换手机后 Apple ID 登录即可恢复历史

**V1.5.3 隐私政策**
- 起草并发布 Privacy Policy
- App Store Review 重点说明 HealthKit 边界

### V2 核心：让 AI 当私教

**V2.1 训练前 AI 状态推断**
- 输入：Readiness 数据 + CMJ 历史 + 近 7 天训练量 + 主观 RPE
- 输出：今日训练强度建议 / 建议重量调整 / 建议是否改动作
- 模型：Claude API + 本地规则混合

**V2.2 训练中 AI 实时调整**
- 检测到 VL% 异常 / 心率过高 → AI 建议提前结束本组 / 调整下一组
- 自动调用 Claude API（流式）+ 本地缓存常见决策

**V2.3 训练后 AI 复盘**
- 综合本次训练 + 历史 + 状态数据生成中文复盘
- 输出：本次状态评价 / 长期进步评估 / 下次训练建议
- 用户可与 AI 对话追问

**V2.4 AI 计划生成**
- 用户输入目标（如「8 周增加深蹲 10kg」）+ 训练频率
- AI 生成完整周期化计划
- 每周根据实际数据自动调整下周计划

**V2.5 数据导入**
- Keep / 训记 / Hevy / Strong 等主流 App 数据导入
- 让用户带着历史训练量来用 VBTrainer

**V2.6 私教 SaaS 起步**
- 私教账号 + 学员管理
- 私教远程查看学员数据 + 调整计划
- 订阅模式：个人 ¥99/月 / 私教 ¥299/月

**V2.7 AI 训练数据池**
- 用户 opt-in 后，训练数据脱敏（k-匿名 + bucketing）进入 AI 训练池
- 用于持续改进 readiness 公式 / 计划生成质量 / 速度阈值校准
- **HealthKit 原始数据永远不进入此池**（仅训练衍生数据）

### V3 中国大陆扩张（M15+）

**V3.1 公司主体**
- 注册公司 / 个体工商户
- ICP 备案 + 网信办备案 + 算法备案

**V3.2 数据本地化**
- 中国大陆用户数据迁阿里云 RDS for PostgreSQL
- 双区域（海外 Supabase + 中国大陆阿里云）数据隔离

**V3.3 中国大陆 App Store 上架**
- 注册中国大陆 Apple Developer 账号
- 集成微信支付 / 支付宝
- 重新过审（中国 App Store 审核独立）

---

## 9. 开发节奏

```
V1 周期：6-8 周
  Week 1-2  Watch 端：传感器 / 算法 / 基础 UI
  Week 3-4  iPhone 端：UI / SwiftData / 基础图表
  Week 4-5  HealthKit 集成 / Readiness / CMJ 测试
  Week 6    计划模板 + Watch/iPhone 计划同步
  Week 7    长期趋势图表 / PR 追踪 / 导出
  Week 8    自用 + bug 修复 + 朋友试用

V2 周期：8-12 周（V1 验证后）
  AI 接入 + 数据导入 + 私教功能 + 服务端
```

---

## 10. 风险与备用方案

| 风险 | 备用方案 |
|------|---------|
| 100Hz 采样不稳定 | 降到 50Hz（论文常见也用） |
| Rep 识别准确率不达标 | 先做半自动（用户点确认） |
| WatchConnectivity 不稳定 | 写 HealthKit 走系统通道 |
| HealthKit 心率拿不到 | 训练后批量读取，不强求实时 |
| HRV 7 天基线建立慢 | 头 7 天显示「建立基线中」 |
| CMJ 检测不准 | 提供两种佩戴模式（手腕 / 裤兜）+ 手动确认起跳 |

---

## 文档结束

本 PRD 是 V1 的产品边界。任何超出此范围的功能在 V1 不做，记入 V2 backlog。

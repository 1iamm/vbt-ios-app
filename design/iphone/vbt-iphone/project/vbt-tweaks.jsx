// VBT Tweaks — three expressive controls that reshape the feel
// 1. 训练目标   — 力量 / 爆发 / 增肌 / 肌耐力 → VL%, accent, headline copy, default velocity
// 2. 数据密度   — 极简 / 标准 / 专业        → chart legends, axis labels, debug rows
// 3. Readiness  — 圆环 / 信号灯 / 论文式    → hero treatment on Today

const VBT_TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "goal":      "strength",
  "density":   "standard",
  "readiness": "ring"
}/*EDITMODE-END*/;

// ── Goal presets — drive accent color, VL%, headline language, default velocity zone
const GOAL_PRESETS = {
  power:    { label: '爆发', accent: '#FF453A', vl: 10, vmin: 0.85, vmax: 1.20, ePrescription: 'MPV ≥ 0.85 m/s · VL ≤ 10%', headline: '速度第一 · 神经募集' },
  strength: { label: '力量', accent: '#FF9500', vl: 20, vmin: 0.50, vmax: 0.75, ePrescription: 'MV ≥ 0.50 m/s · VL ≤ 20%', headline: '强度优先 · 最大力量' },
  hyper:    { label: '增肌', accent: '#BF5AF2', vl: 30, vmin: 0.35, vmax: 0.55, ePrescription: 'VL 25–30% · 6–12 reps',     headline: '机械张力 · 累积容量' },
  endur:    { label: '肌耐力', accent: '#30B0C7', vl: 40, vmin: 0.25, vmax: 0.45, ePrescription: 'VL ≥ 40% · 12–20 reps',    headline: '代谢压力 · 局部耐力' },
};

// Density presets — hide/show secondary chrome
const DENSITY = {
  minimal:  { showLegend: false, showGrid: false, showAxis: false, showDebug: false, showSubcards: false },
  standard: { showLegend: true,  showGrid: true,  showAxis: true,  showDebug: false, showSubcards: true  },
  pro:      { showLegend: true,  showGrid: true,  showAxis: true,  showDebug: true,  showSubcards: true  },
};

// Context propagation
const TweakCtx = React.createContext({
  goal: GOAL_PRESETS.strength,
  density: DENSITY.standard,
  readiness: 'ring',
  raw: VBT_TWEAK_DEFAULTS,
});
const useTweaksCtx = () => React.useContext(TweakCtx);

// Provider
const TweakProvider = ({ value, children }) => {
  const goal = GOAL_PRESETS[value.goal] || GOAL_PRESETS.strength;
  const density = DENSITY[value.density] || DENSITY.standard;
  return <TweakCtx.Provider value={{ goal, density, readiness: value.readiness, raw: value }}>{children}</TweakCtx.Provider>;
};

// ─────────────────────────────────────────────────────────────
// Tweakable Today hero — choice of three readiness treatments
// ─────────────────────────────────────────────────────────────
const ReadinessHero = ({ dark, score = 78 }) => {
  const { readiness } = useTweaksCtx();
  if (readiness === 'ring') return <ReadinessRing dark={dark} score={score}/>;
  if (readiness === 'light') return <ReadinessTrafficLight dark={dark} score={score}/>;
  return <ReadinessAcademic dark={dark} score={score}/>;
};

// Traffic-light variant (per PRD: 🟢🟡🔴 thresholds 80/60)
const ReadinessTrafficLight = ({ dark, score = 78 }) => {
  const t = T(dark);
  const status = score >= 80 ? 'green' : score >= 60 ? 'yellow' : 'red';
  const cfg = {
    green:  { color: '#34C759', label: '绿灯 · 可按计划',     dot: 0 },
    yellow: { color: '#FFCC00', label: '黄灯 · 建议保守',     dot: 1 },
    red:    { color: '#FF3B30', label: '红灯 · 降低强度',     dot: 2 },
  }[status];
  return (
    <div style={{ width: 240, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 18 }}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 14, padding: 20, borderRadius: 22, background: t.card, alignItems: 'center', minWidth: 200 }}>
        {[0,1,2].map(i => (
          <div key={i} style={{
            width: 56, height: 56, borderRadius: 28,
            background: i === cfg.dot ? cfg.color : t.fill2,
            boxShadow: i === cfg.dot ? `0 0 24px ${cfg.color}66` : 'none',
            border: i === cfg.dot ? `2px solid ${cfg.color}` : `2px solid ${t.fill2}`,
          }}/>
        ))}
      </div>
      <div style={{ textAlign: 'center' }}>
        <Numeric value={score} size={56} dark={dark} weight={500}/>
        <div style={{ fontSize: 13, color: cfg.color, fontWeight: 600, fontFamily: VBT.fontR, marginTop: 4 }}>{cfg.label}</div>
      </div>
    </div>
  );
};

// Academic variant — raw stats, no aggregate
const ReadinessAcademic = ({ dark, score = 78 }) => {
  const t = T(dark);
  const items = [
    { k: 'HRV',          v: '48',  u: 'ms',   d: '−8%',   c: '#FF9500', cite: 'Plews 2013' },
    { k: 'Sleep',        v: '7.5', u: 'h',    d: '深睡 1.8h', c: '#34C759', cite: 'Watson 2017' },
    { k: 'RHR',          v: '58',  u: 'bpm',  d: '+4%',   c: '#FF9500', cite: 'Buchheit 2014' },
    { k: 'Wrist Temp',   v: '+0.2', u: '°C',  d: '基线 +', c: t.secondary, cite: 'HealthKit' },
    { k: 'Resp Rate',    v: '14.5', u: '/m',  d: '基线 14.2', c: t.secondary, cite: 'Flatt 2016' },
  ];
  return (
    <div style={{ width: 360, padding: '0 8px' }}>
      <div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontM, letterSpacing: 0.6, marginBottom: 14, textTransform: 'uppercase' }}>READINESS · v1 RULE-BASED · n=5</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 0 }}>
        {items.map((it, i) => (
          <div key={it.k} style={{ display: 'grid', gridTemplateColumns: '90px 1fr 90px', alignItems: 'baseline', padding: '10px 0', borderTop: `0.5px solid ${t.sep}` }}>
            <div style={{ fontFamily: VBT.fontM, fontSize: 11, color: t.secondary, letterSpacing: 0.4, textTransform: 'uppercase', fontWeight: 600 }}>{it.k}</div>
            <div style={{ fontFamily: VBT.fontR, fontSize: 22, fontWeight: 600, letterSpacing: -0.4, fontVariantNumeric: 'tabular-nums' }}>
              {it.v}<span style={{ fontSize: 11, color: t.secondary, marginLeft: 3 }}>{it.u}</span>
            </div>
            <div style={{ fontFamily: VBT.fontM, fontSize: 10, color: it.c, textAlign: 'right', fontWeight: 500 }}>{it.d}</div>
          </div>
        ))}
        <div style={{ borderTop: `1px solid ${t.label}`, paddingTop: 12, marginTop: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <div style={{ fontFamily: VBT.fontM, fontSize: 11, color: t.secondary, letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600 }}>Σ Score</div>
          <Numeric value={score} unit="/100" size={32} dark={dark} weight={500}/>
        </div>
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────
// TWEAK-AWARE TODAY SCREEN
// ─────────────────────────────────────────────────────────────
const TodayScreenT = ({ dark = false }) => {
  const t = T(dark);
  const { goal, density } = useTweaksCtx();
  return (
    <Screen dark={dark}>
      <NavLarge title="今天" eyebrow={`周三 · 5 月 8 日 · ${goal.label}周期`} dark={dark}
        trailing={<div style={{
          width: 30, height: 30, borderRadius: 15,
          background: dark ? '#2C2C2E' : '#E5E5EA',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 13, fontWeight: 600, color: t.label, letterSpacing: -0.3,
          fontFamily: VBT.fontR,
        }}>L</div>}/>

      {/* Goal banner — only in standard / pro */}
      {density.showSubcards && (
        <div style={{ padding: '0 20px 8px', display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 6, height: 6, borderRadius: 3, background: goal.accent }}/>
          <div style={{ fontSize: 12, color: t.secondary, fontFamily: VBT.fontR, letterSpacing: 0.3 }}>
            <span style={{ color: t.label, fontWeight: 600 }}>{goal.headline}</span> · {goal.ePrescription}
          </div>
        </div>
      )}

      {/* Hero readiness */}
      <div style={{ padding: '20px 0 28px', display: 'flex', justifyContent: 'center' }}>
        <ReadinessHero dark={dark} score={78}/>
      </div>

      {/* Mini metrics — hide in minimal */}
      {density.showSubcards && (
        <div style={{
          margin: '0 16px 24px', padding: '16px 18px',
          background: t.card, borderRadius: 18,
          display: 'flex', gap: 18, alignItems: 'flex-start',
        }}>
          <MiniMetric dark={dark} label="HRV"   value="58"  unit="ms"  sub="+4 vs 7d"   color="#34C759"/>
          <div style={{ width: 0.5, background: t.sep, alignSelf: 'stretch' }}/>
          <MiniMetric dark={dark} label="睡眠" value="7:42"          sub="92% 效率"   color={t.secondary}/>
          <div style={{ width: 0.5, background: t.sep, alignSelf: 'stretch' }}/>
          <MiniMetric dark={dark} label="RHR"   value="52"  unit="bpm" sub="-1 vs 7d"   color="#34C759"/>
        </div>
      )}

      {/* CMJ test card — only in pro */}
      {density.showDebug && (
        <div style={{ margin: '0 16px 18px' }}>
          <Card dark={dark}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{ width: 38, height: 38, borderRadius: 10, background: '#FF950020', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon name="bolt" size={20} color={VBT.accent}/>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14, fontWeight: 600 }}>CMJ 神经测试</div>
                <div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontM, marginTop: 2 }}>飞行时间法 · t² × g / 8 · Claudino 2017</div>
              </div>
              <Numeric value="38.4" unit="cm" size={20} color={VBT.accent} dark={dark}/>
              <Icon name="chev-r" size={14} color={t.tertiary} stroke={2.2}/>
            </div>
          </Card>
        </div>
      )}

      {/* Today's plan */}
      <div style={{ padding: '0 20px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
        <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: -0.4 }}>今日训练</div>
        <div style={{ fontSize: 13, color: goal.accent, fontWeight: 500 }}>查看计划</div>
      </div>
      <div style={{ margin: '0 16px 18px' }}>
        <Card dark={dark} padded={false}>
          <div style={{ padding: '16px 18px' }}>
            <div style={{ fontSize: 12, color: t.secondary, letterSpacing: 0.3, fontWeight: 600, textTransform: 'uppercase', marginBottom: 4 }}>下肢 · {goal.label} · 周期 W3 D2</div>
            <div style={{ fontSize: 19, fontWeight: 600, letterSpacing: -0.4, marginBottom: 12 }}>深蹲 · 罗马尼亚硬拉 · 保加利亚分腿蹲</div>
            <div style={{ display: 'flex', gap: 16 }}>
              <div><Numeric value="48" unit="min" size={22} dark={dark}/><div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontR, marginTop: 2 }}>预计时长</div></div>
              <div style={{ width: 0.5, background: t.sep }}/>
              <div><Numeric value={`${goal.vmin}–${goal.vmax}`} unit="m/s" size={22} color={goal.accent} dark={dark}/><div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontR, marginTop: 2 }}>目标速度</div></div>
              {density.showDebug && <>
                <div style={{ width: 0.5, background: t.sep }}/>
                <div><Numeric value={goal.vl} unit="%" size={22} color={VBT.data.vl} dark={dark}/><div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontR, marginTop: 2 }}>VL 警戒</div></div>
              </>}
            </div>
          </div>
          <div style={{ borderTop: `0.5px solid ${t.sep}`, padding: '12px 18px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: t.secondary, fontFamily: VBT.fontR }}>
              <Icon name="watch" size={16} color={t.secondary}/>从 Watch 开始
            </div>
            <Icon name="chev-r" size={16} color={t.tertiary} stroke={2.2}/>
          </div>
        </Card>
      </div>

      {/* Last training */}
      {density.showSubcards && <>
        <div style={{ padding: '0 20px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: -0.4 }}>最近一次</div>
          <div style={{ fontSize: 13, color: t.secondary, fontFamily: VBT.fontR }}>2 天前</div>
        </div>
        <div style={{ margin: '0 16px 24px' }}>
          <Card dark={dark}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div>
                <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>上肢推 · 卧推日</div>
                <div style={{ fontSize: 12, color: t.secondary, fontFamily: VBT.fontR }}>52m · 心率峰值 168 · VL 22%</div>
              </div>
              <Spark data={[80,90,95,100,105,103,108,110]} color={goal.accent} fill/>
            </div>
            <div style={{ height: 1, background: t.sep, margin: '14px -16px 14px' }}/>
            <div style={{ display: 'flex', gap: 16 }}>
              <Stat dark={dark} label="总 Reps" value="64"/>
              <Stat dark={dark} label="平均速度" value="0.68" unit="m/s" color={VBT.data.vel}/>
              <Stat dark={dark} label="VL%" value="22" unit="%" color={VBT.data.vl}/>
            </div>
          </Card>
        </div>
      </>}

      {/* Heatmap */}
      <div style={{ padding: '0 20px 8px' }}>
        <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: -0.4 }}>训练频率</div>
      </div>
      <div style={{ margin: '0 16px 32px' }}>
        <Card dark={dark}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 14 }}>
            <div><Numeric value="58" unit="次" size={32} dark={dark}/><div style={{ fontSize: 12, color: t.secondary, fontFamily: VBT.fontR, marginTop: 2 }}>共 142 小时</div></div>
            <div style={{ textAlign: 'right' }}><div style={{ fontSize: 12, color: t.secondary, fontFamily: VBT.fontR }}>每周</div><Numeric value="3.2" size={20} dark={dark}/></div>
          </div>
          <HeatmapT dark={dark} accent={goal.accent}/>
        </Card>
      </div>
    </Screen>
  );
};

// Heatmap that takes accent color from goal
const HeatmapT = ({ dark, accent = VBT.accent }) => {
  const t = T(dark);
  const r = (() => { let s = 42; return () => { s = (s * 9301 + 49297) % 233280; return s / 233280; }; })();
  const cell = 14, gap = 4;
  const ramp = [t.fill2, `${accent}33`, `${accent}66`, `${accent}AA`, accent];
  return (
    <div>
      <div style={{ display: 'flex', gap }}>
        {Array.from({ length: 18 }, (_, w) => (
          <div key={w} style={{ display: 'flex', flexDirection: 'column', gap }}>
            {Array.from({ length: 7 }, (_, d) => {
              const v = r() < 0.55 ? Math.floor(r() * 4) + 1 : 0;
              return <div key={d} style={{ width: cell, height: cell, borderRadius: 3, background: ramp[v] }}/>;
            })}
          </div>
        ))}
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 10, fontSize: 11, color: t.secondary, fontFamily: VBT.fontR }}>
        <span>过去 18 周</span>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span>少</span>
          {ramp.map((c, i) => <div key={i} style={{ width: 9, height: 9, borderRadius: 2, background: c }}/>)}
          <span>多</span>
        </div>
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────
// TWEAK-AWARE DETAIL SCREEN — density controls subcards & VL line
// ─────────────────────────────────────────────────────────────
const DetailScreenT = ({ dark = false }) => {
  const t = T(dark);
  const { goal, density } = useTweaksCtx();
  const sectionTitle = (s) => (
    <div style={{ padding: '24px 20px 8px' }}>
      <div style={{ fontSize: 13, color: t.secondary, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase' }}>{s}</div>
    </div>
  );
  return (
    <Screen dark={dark} hideTabs>
      <NavInline dark={dark} title="2025 · 5 · 6"
        leading={<><Icon name="chev-l" size={18} color={goal.accent} stroke={2.4}/><span style={{ marginLeft: 2, color: goal.accent }}>历史</span></>}
        trailing={<Icon name="share" size={20} color={goal.accent} stroke={2}/>}/>

      <div style={{ padding: '20px 20px 16px' }}>
        <div style={{ fontSize: 13, color: t.secondary, fontWeight: 500, letterSpacing: 0.3, textTransform: 'uppercase', marginBottom: 4 }}>下肢 · {goal.label}周期</div>
        <div style={{ fontSize: 28, fontWeight: 700, letterSpacing: -0.6, lineHeight: '34px', marginBottom: 18 }}>深蹲 · 卧推 · 硬拉</div>
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8 }}>
          <div><Numeric value="64" size={42} dark={dark}/><div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontR, marginTop: 2, letterSpacing: 0.3, textTransform: 'uppercase' }}>总 reps</div></div>
          <div><Numeric value="0.68" unit="m/s" size={42} color={VBT.data.vel} dark={dark}/><div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontR, marginTop: 2, letterSpacing: 0.3, textTransform: 'uppercase' }}>{density.showDebug ? 'MV avg' : '平均速度'}</div></div>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8, marginTop: 18 }}>
          <div><Numeric value="22" unit="%" size={42} color={VBT.data.vl} dark={dark}/><div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontR, marginTop: 2, letterSpacing: 0.3, textTransform: 'uppercase' }}>VL · 警戒 {goal.vl}%</div></div>
          <div><Numeric value="62" unit="min" size={42} dark={dark}/><div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontR, marginTop: 2, letterSpacing: 0.3, textTransform: 'uppercase' }}>时长</div></div>
        </div>
      </div>

      {sectionTitle('综合时间轴')}
      <div style={{ margin: '0 16px' }}>
        <Card dark={dark} padded={false} style={{ overflow: 'hidden' }}>
          {density.showLegend && (
            <div style={{ padding: '12px 14px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', gap: 14, fontSize: 11, fontFamily: VBT.fontR, color: t.secondary }}>
                <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}><div style={{ width: 8, height: 2, background: VBT.data.hr, borderRadius: 1 }}/>心率</span>
                <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}><div style={{ width: 6, height: 6, background: VBT.data.vel, borderRadius: 3 }}/>速度</span>
                <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}><div style={{ width: 8, height: 0, borderTop: `1px dashed ${VBT.data.vl}` }}/>VL {goal.vl}%</span>
              </div>
              <Icon name="expand" size={14} color={t.tertiary} stroke={1.8}/>
            </div>
          )}
          <TimelineChart dark={dark} w={358} h={300}/>
          {density.showLegend && (
            <div style={{ padding: '10px 14px 12px', borderTop: `0.5px solid ${t.sep}`, fontSize: 11, color: t.tertiary, fontFamily: VBT.fontR, display: 'flex', justifyContent: 'space-between' }}>
              <span>双指缩放 · 单指拖动 · 点击 rep 查看详情</span>
              <span style={{ color: goal.accent, fontWeight: 500 }}>横屏查看</span>
            </div>
          )}
        </Card>
      </div>

      {/* IMU debug — only in pro */}
      {density.showDebug && (<>
        {sectionTitle('原始 IMU · DEBUG')}
        <div style={{ margin: '0 16px' }}>
          <Card dark={dark}>
            <div style={{ fontFamily: VBT.fontM, fontSize: 11, color: t.secondary, lineHeight: 1.7 }}>
              <div>sample_rate <span style={{ color: t.label }}>100 Hz</span> · drift <span style={{ color: t.label }}>0.03 m/s</span></div>
              <div>rep_detection <span style={{ color: t.label }}>peak + ZUPT · O'Reilly 2018</span></div>
              <div>velocity_method <span style={{ color: t.label }}>MV (深蹲) · MPV (卧推)</span></div>
              <div>v1rm_ref <span style={{ color: t.label }}>squat 0.30 · bench 0.17 m/s</span></div>
              <div>icc_baseline <span style={{ color: t.label }}>0.94 (Balshaw 2023)</span></div>
            </div>
          </Card>
        </div>
      </>)}

      {density.showSubcards && (<>
        {sectionTitle('心率分布')}
        <div style={{ margin: '0 16px' }}><Card dark={dark}><HRZoneDonut dark={dark}/></Card></div>

        {sectionTitle('每组 VL%')}
        <div style={{ margin: '0 16px' }}><Card dark={dark}><VLBars dark={dark} w={328} h={120}/></Card></div>

        {sectionTitle('每组数据')}
        <div style={{ margin: '0 16px' }}>
          <Card dark={dark} padded={false}>
            <div style={{
              display: 'grid', gridTemplateColumns: density.showDebug ? '28px 1fr 44px 50px 50px 50px' : '32px 1fr 50px 50px 50px',
              padding: '10px 16px', fontSize: 11, color: t.secondary,
              letterSpacing: 0.3, textTransform: 'uppercase', fontWeight: 600,
              borderBottom: `0.5px solid ${t.sep}`,
            }}>
              <div>#</div><div>动作 · 负荷</div>
              {density.showDebug && <div style={{ textAlign: 'right' }}>PV</div>}
              <div style={{ textAlign: 'right' }}>Reps</div><div style={{ textAlign: 'right' }}>Avg</div><div style={{ textAlign: 'right' }}>VL</div>
            </div>
            {[
              { n: 1, name: '深蹲',  load: '120 × 5', reps: 5, avg: '0.78', pv: '1.42', vl: '8%'  },
              { n: 2, name: '深蹲',  load: '125 × 5', reps: 5, avg: '0.71', pv: '1.31', vl: '12%' },
              { n: 3, name: '深蹲',  load: '130 × 4', reps: 4, avg: '0.66', pv: '1.22', vl: '18%' },
              { n: 4, name: '卧推',  load: '85 × 6',  reps: 6, avg: '0.62', pv: '1.18', vl: '15%' },
              { n: 5, name: '卧推',  load: '90 × 5',  reps: 5, avg: '0.58', pv: '1.04', vl: '22%' },
              { n: 6, name: '硬拉',  load: '160 × 3', reps: 3, avg: '0.51', pv: '0.96', vl: '28%' },
            ].map((row, i, a) => (
              <div key={i} style={{
                display: 'grid', gridTemplateColumns: density.showDebug ? '28px 1fr 44px 50px 50px 50px' : '32px 1fr 50px 50px 50px',
                padding: '12px 16px', alignItems: 'center', fontSize: 14,
                borderBottom: i === a.length - 1 ? 'none' : `0.5px solid ${t.sep}`,
                fontFamily: VBT.fontR,
              }}>
                <div style={{ color: t.tertiary, fontWeight: 500 }}>{row.n}</div>
                <div><span style={{ fontWeight: 500 }}>{row.name}</span><span style={{ color: t.secondary, marginLeft: 6 }}>{row.load}</span></div>
                {density.showDebug && <div style={{ textAlign: 'right', color: t.secondary, fontVariantNumeric: 'tabular-nums', fontFamily: VBT.fontM, fontSize: 12 }}>{row.pv}</div>}
                <div style={{ textAlign: 'right', color: t.label, fontWeight: 500, fontVariantNumeric: 'tabular-nums' }}>{row.reps}</div>
                <div style={{ textAlign: 'right', color: VBT.data.vel, fontWeight: 500, fontVariantNumeric: 'tabular-nums' }}>{row.avg}</div>
                <div style={{ textAlign: 'right', color: parseInt(row.vl) >= goal.vl ? VBT.data.vl : t.label, fontWeight: 500, fontVariantNumeric: 'tabular-nums' }}>{row.vl}</div>
              </div>
            ))}
          </Card>
        </div>
      </>)}

      <div style={{ height: 32 }}/>
    </Screen>
  );
};

// ─────────────────────────────────────────────────────────────
// TWEAKS PANEL
// ─────────────────────────────────────────────────────────────
const VBTTweaksPanel = ({ tweaks, setTweak }) => {
  return (
    <TweaksPanel title="Tweaks">
      <TweakSection label="训练目标"/>
      <div style={{ padding: '0 14px 4px', fontSize: 11, color: 'rgba(0,0,0,0.5)', lineHeight: 1.5 }}>
        影响主色、VL% 警戒线、目标速度区间、文案语气与每周动作分配。整个 App 跟着调性走。
      </div>
      <TweakRadio
        label="目标"
        value={tweaks.goal}
        onChange={(v) => setTweak('goal', v)}
        options={[
          { value: 'power',    label: '爆发' },
          { value: 'strength', label: '力量' },
          { value: 'hyper',    label: '增肌' },
          { value: 'endur',    label: '肌耐力' },
        ]}/>
      <div style={{ padding: '4px 14px 8px', fontSize: 11, color: 'rgba(0,0,0,0.5)', lineHeight: 1.5 }}>
        <div>{(GOAL_PRESETS[tweaks.goal] || GOAL_PRESETS.strength).headline}</div>
        <div style={{ marginTop: 2 }}>{(GOAL_PRESETS[tweaks.goal] || GOAL_PRESETS.strength).ePrescription}</div>
      </div>


    </TweaksPanel>
  );
};

Object.assign(window, {
  VBT_TWEAK_DEFAULTS, GOAL_PRESETS, DENSITY,
  TweakProvider, useTweaksCtx,
  TodayScreenT, DetailScreenT, ReadinessHero,
  VBTTweaksPanel,
});

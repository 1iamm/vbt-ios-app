// VBTrainer · watchOS 屏幕组件
// 45mm = 396×484 px (198×242 pt @2x). 全部黑底，遵循 watchOS HIG 公开原则。
// 视觉语言为 VBTrainer 原创：所有图形、布局、symbol 由本设计自行绘制。

const W = 396, H = 484;

const T = {
  bg:    '#000000',
  fg:    '#FFFFFF',
  sub:   '#8E8E93',
  orange:'#FF9500',
  green: '#30D158',
  red:   '#FF453A',
  font:  '-apple-system, BlinkMacSystemFont, "SF Pro Rounded", "SF Pro Display", "Helvetica Neue", system-ui, sans-serif',
};

// Watch screen frame — pure black with the actual watch corner radius.
function Watch({ dim, children, alwaysOn }) {
  return (
    <div style={{
      width: W, height: H, background: T.bg,
      borderRadius: 55, overflow: 'hidden',
      color: T.fg, position: 'relative',
      fontFamily: T.font,
      fontFeatureSettings: '"tnum","ss01"',
      WebkitFontSmoothing: 'antialiased',
      filter: alwaysOn ? 'brightness(0.32) contrast(0.85)' : (dim ? 'brightness(0.6)' : 'none'),
      boxShadow: 'inset 0 0 0 1px rgba(255,255,255,0.04)',
    }}>{children}</div>
  );
}

// Tiny uppercase label, tracked +0.5
function Label({ children, color = T.sub, size = 22, style }) {
  return (
    <div style={{
      fontSize: size, fontWeight: 500, color,
      letterSpacing: '0.06em', textTransform: 'uppercase',
      fontVariantNumeric: 'tabular-nums', ...style,
    }}>{children}</div>
  );
}

// Small chrome at top of every screen (time + tiny title), watchOS-style
function StatusBar({ title, time = '10:24', color = T.orange }) {
  return (
    <div style={{
      position:'absolute', top: 14, left: 0, right: 0,
      display:'flex', justifyContent:'space-between',
      padding:'0 32px', alignItems:'center',
      fontSize: 22, fontWeight: 600, color: T.sub,
    }}>
      <span style={{ color, fontWeight: 600 }}>{title}</span>
      <span style={{ color: T.fg }}>{time}</span>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// Original glyph set — flat 2px lines, single-color, watchOS-flavored.
// (Not SF Symbols. Not Apple icons. Drawn from primitives only.)
// ──────────────────────────────────────────────────────────────
const G = {
  bolt: (s=24, c=T.fg) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M14 2 L4 14 H11 L10 22 L20 10 H13 Z" stroke={c} strokeWidth="1.6" strokeLinejoin="round"/>
    </svg>),
  heart: (s=24, c=T.fg) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M12 20 C 4 14, 2 9, 6 6 C 9 4, 11 6, 12 8 C 13 6, 15 4, 18 6 C 22 9, 20 14, 12 20 Z" stroke={c} strokeWidth="1.6" strokeLinejoin="round"/>
    </svg>),
  bar: (s=24, c=T.fg) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <rect x="2"  y="9"  width="3" height="6"  rx="1" stroke={c} strokeWidth="1.6"/>
      <rect x="19" y="9"  width="3" height="6"  rx="1" stroke={c} strokeWidth="1.6"/>
      <rect x="6"  y="6"  width="2" height="12" rx="1" stroke={c} strokeWidth="1.6"/>
      <rect x="16" y="6"  width="2" height="12" rx="1" stroke={c} strokeWidth="1.6"/>
      <rect x="9"  y="11" width="6" height="2"  rx="1" stroke={c} strokeWidth="1.6"/>
    </svg>),
  arrow: (s=24, c=T.fg, dir='up') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none"
      style={{ transform: dir==='down' ? 'rotate(180deg)':'none' }}>
      <path d="M12 4 V20 M5 11 L12 4 L19 11" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>),
  check: (s=24, c=T.fg) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M5 12 L10 17 L19 7" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>),
  crown: (s=18, c=T.sub) => (
    <svg width={s} height={s*2} viewBox="0 0 18 36" fill="none">
      <rect x="3" y="2" width="12" height="32" rx="4" stroke={c} strokeWidth="1.5"/>
      <line x1="3" y1="10" x2="15" y2="10" stroke={c} strokeWidth="1"/>
      <line x1="3" y1="18" x2="15" y2="18" stroke={c} strokeWidth="1"/>
      <line x1="3" y1="26" x2="15" y2="26" stroke={c} strokeWidth="1"/>
    </svg>),
};

// SVG progress ring
function Ring({ size, stroke, progress, color, track = 'rgba(255,255,255,0.08)' }) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  return (
    <svg width={size} height={size} style={{ position:'absolute', inset: 0, transform:'rotate(-90deg)' }}>
      <circle cx={size/2} cy={size/2} r={r} stroke={track} strokeWidth={stroke} fill="none"/>
      <circle cx={size/2} cy={size/2} r={r} stroke={color} strokeWidth={stroke} fill="none"
        strokeDasharray={c} strokeDashoffset={c * (1 - progress)}
        strokeLinecap="round"/>
    </svg>
  );
}

// ──────────────────────────────────────────────────────────────
// Screens
// ──────────────────────────────────────────────────────────────

// 1. HOME
function Home({ alwaysOn }) {
  return (
    <Watch alwaysOn={alwaysOn}>
      <StatusBar title="VBT" />
      <div style={{ position:'absolute', inset:0, display:'flex', flexDirection:'column',
        alignItems:'center', justifyContent:'center', paddingTop: 20 }}>
        {/* Original circular start button: solid orange disc, single thin inset ring */}
        <button style={{
          width: 248, height: 248, borderRadius: '50%',
          background: T.orange, border: 'none',
          color: T.fg, fontSize: 44, fontWeight: 700,
          fontFamily: 'inherit', letterSpacing: '0.01em',
          display:'flex', alignItems:'center', justifyContent:'center',
          flexDirection:'column', gap: 6,
          boxShadow: 'inset 0 0 0 6px rgba(255,255,255,0.10)',
        }}>
          {G.bolt(38, T.fg)}
          <span>开始</span>
        </button>
        <div style={{ marginTop: 28, textAlign:'center' }}>
          <Label size={22}>上次</Label>
          <div style={{ fontSize: 28, fontWeight: 500, color: T.fg, marginTop: 4 }}>
            深蹲 · 100kg
          </div>
          <div style={{ fontSize: 24, fontWeight: 400, color: T.sub, marginTop: 2 }}>
            5×5 · MV 0.61
          </div>
        </div>
      </div>
    </Watch>
  );
}

// 2. READINESS — 5 metrics + 7-day baseline delta (论文权重: HRV50/睡眠25/RHR20/温度5)
function Readiness({ alwaysOn, score = 72 }) {
  const ringSize = 200;
  const scoreColor = score >= 80 ? T.green : score >= 60 ? T.orange : T.red;
  // [label, value, unit, deltaText, deltaColor]
  const metrics = [
    ['HRV',     '48',   'ms',  '↓ 8% vs 基线',  T.orange],
    ['睡眠',    '7.5',  'h',   '深 1.8h',       T.sub],
    ['静息心率', '58',   'bpm', '↑ 4% vs 基线',  T.orange],
    ['手腕温度', '+0.2', '°C',  '正常区间',      T.sub],
    ['呼吸率',  '14.5', '',    '+0.3 vs 基线',  T.sub],
  ];
  return (
    <Watch alwaysOn={alwaysOn}>
      <StatusBar title="今日"/>
      <div style={{ position:'absolute', top: 46, left: 0, right: 0,
        display:'flex', flexDirection:'column', alignItems:'center' }}>
        <div style={{ position:'relative', width: ringSize, height: ringSize,
          display:'flex', alignItems:'center', justifyContent:'center' }}>
          <Ring size={ringSize} stroke={12} progress={score/100} color={scoreColor}/>
          <div style={{ textAlign:'center' }}>
            <div style={{ fontSize: 100, fontWeight: 800, lineHeight: 1, color: scoreColor,
              fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.04em' }}>{score}</div>
            <Label size={16} style={{ marginTop: 2 }}>READINESS</Label>
          </div>
        </div>
        {/* 5 metric rows */}
        <div style={{ marginTop: 14, width: '100%', padding: '0 24px' }}>
          {metrics.map(([k,v,u,d,dc]) => (
            <div key={k} style={{ display:'grid',
              gridTemplateColumns:'auto 1fr auto', gap: 10,
              alignItems:'baseline', padding:'3px 0' }}>
              <span style={{ fontSize: 18, color: T.sub, fontWeight: 500 }}>{k}</span>
              <span style={{ fontSize: 22, fontWeight: 700, color: T.fg, textAlign:'left',
                fontVariantNumeric:'tabular-nums' }}>
                {v}<span style={{ fontSize: 14, color: T.sub, fontWeight: 500, marginLeft: 2 }}>{u}</span>
              </span>
              <span style={{ fontSize: 16, color: dc, fontWeight: 500, textAlign:'right' }}>{d}</span>
            </div>
          ))}
        </div>
      </div>
    </Watch>
  );
}

// 3a. CMJ — countdown state
function CMJCountdown({ alwaysOn, n = 3 }) {
  return (
    <Watch alwaysOn={alwaysOn}>
      <StatusBar title="CMJ" />
      <div style={{ position:'absolute', inset:0, display:'flex',
        flexDirection:'column', alignItems:'center', justifyContent:'center' }}>
        <Label size={22} style={{ marginBottom: 10 }}>准备 · 第 1 跳</Label>
        <div style={{ fontSize: 260, fontWeight: 800, lineHeight: 1, color: T.orange,
          letterSpacing:'-0.06em', fontVariantNumeric: 'tabular-nums' }}>{n}</div>
      </div>
    </Watch>
  );
}

// 3b. CMJ — go state
function CMJGo({ alwaysOn }) {
  return (
    <Watch alwaysOn={alwaysOn}>
      <StatusBar title="CMJ" />
      <div style={{ position:'absolute', inset:0, display:'flex',
        alignItems:'center', justifyContent:'center', flexDirection:'column' }}>
        <div style={{ fontSize: 140, fontWeight: 800, color: T.green,
          letterSpacing:'-0.04em' }}>跳</div>
        {G.arrow(56, T.green, 'up')}
      </div>
    </Watch>
  );
}

// 3c. CMJ — result
function CMJResult({ alwaysOn }) {
  const attempts = [42, 41, 43];
  const best = 43;
  return (
    <Watch alwaysOn={alwaysOn}>
      <StatusBar title="CMJ" />
      <div style={{ position:'absolute', top:60, left:0, right:0,
        display:'flex', flexDirection:'column', alignItems:'center' }}>
        <Label size={22}>最佳跳跃高度</Label>
        <div style={{ marginTop: 6, display:'flex', alignItems:'baseline', gap: 8 }}>
          <span style={{ fontSize: 160, fontWeight: 800, color: T.fg,
            letterSpacing:'-0.05em', lineHeight: 1, fontVariantNumeric:'tabular-nums' }}>{best}</span>
          <span style={{ fontSize: 36, fontWeight: 500, color: T.sub }}>cm</span>
        </div>
        <div style={{ marginTop: 22, display:'flex', gap: 28, alignItems:'baseline' }}>
          {attempts.map((a, i) => (
            <div key={i} style={{ textAlign:'center' }}>
              <div style={{ fontSize: 18, color: T.sub, fontWeight: 500, marginBottom: 2 }}>#{i+1}</div>
              <div style={{ fontSize: 30, color: a===best ? T.green : T.fg, fontWeight: 600 }}>{a}</div>
            </div>
          ))}
        </div>
      </div>
    </Watch>
  );
}

// 4. EXERCISE PICKER — scrolling list
function ExercisePicker({ alwaysOn }) {
  const items = [
    { name: '深蹲', en: 'Squat', icon: G.bar(28, T.orange) },
    { name: '卧推', en: 'Bench Press', icon: G.bar(28, T.fg) },
    { name: '硬拉', en: 'Deadlift', icon: G.bar(28, T.fg) },
    { name: '推举', en: 'OHP', icon: G.bar(28, T.fg) },
    { name: '划船', en: 'Row', icon: G.bar(28, T.fg) },
  ];
  return (
    <Watch alwaysOn={alwaysOn}>
      <StatusBar title="选动作" />
      <div style={{ position:'absolute', top: 50, left: 0, right: 0, bottom: 0,
        padding: '0 24px', overflow: 'hidden' }}>
        {items.map((it, i) => (
          <div key={it.en} style={{
            display:'flex', alignItems:'center', gap: 16,
            padding: '14px 14px',
            borderBottom: i < items.length-1 ? '1px solid rgba(255,255,255,0.07)' : 'none',
          }}>
            <div style={{ width: 40, height: 40, display:'flex',
              alignItems:'center', justifyContent:'center' }}>
              {it.icon}
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 30, fontWeight: 600, color: T.fg, lineHeight: 1.05 }}>
                {it.name}
              </div>
              <div style={{ fontSize: 18, fontWeight: 500, color: T.sub,
                letterSpacing: '0.04em', textTransform: 'uppercase', marginTop: 2 }}>
                {it.en}
              </div>
            </div>
            {i === 0 && <div style={{
              width: 8, height: 8, borderRadius:'50%', background: T.orange,
            }}/>}
          </div>
        ))}
      </div>
      {/* scroll hint right edge */}
      <div style={{ position:'absolute', right: 6, top: '50%', transform:'translateY(-50%)' }}>
        {G.crown(14, 'rgba(255,255,255,0.25)')}
      </div>
    </Watch>
  );
}

// 5. WEIGHT INPUT
function WeightInput({ alwaysOn }) {
  return (
    <Watch alwaysOn={alwaysOn}>
      <StatusBar title="深蹲" />
      <div style={{ position:'absolute', inset:0, display:'flex',
        flexDirection:'column', alignItems:'center', justifyContent:'center' }}>
        <Label size={22} style={{ marginBottom: 6 }}>负重</Label>
        <div style={{ display:'flex', alignItems:'baseline', gap: 14 }}>
          <span style={{ fontSize: 200, fontWeight: 800, color: T.fg,
            letterSpacing:'-0.05em', lineHeight: 1, fontVariantNumeric:'tabular-nums' }}>
            100
          </span>
          <span style={{ fontSize: 44, fontWeight: 500, color: T.sub }}>kg</span>
        </div>
        <div style={{ marginTop: 18, fontSize: 22, color: T.sub, fontWeight: 500 }}>
          上次 · 95 kg
        </div>
        <div style={{ marginTop: 10, fontSize: 18, color: T.sub, opacity: 0.7,
          letterSpacing:'0.06em', textTransform:'uppercase' }}>
          ↑↓ 2.5kg
        </div>
      </div>
      {/* Crown affordance: small bracket on right edge with up/down chevrons */}
      <div style={{ position:'absolute', right: 0, top: '50%', transform:'translateY(-50%)',
        display:'flex', flexDirection:'column', alignItems:'center', gap: 6,
        padding: '14px 6px',
      }}>
        <div style={{ width: 4, height: 26, borderRadius: 2, background: T.orange }}/>
        <div style={{ width: 4, height: 56, borderRadius: 2, background: 'rgba(255,255,255,0.18)' }}/>
        <div style={{ width: 4, height: 26, borderRadius: 2, background: 'rgba(255,255,255,0.18)' }}/>
      </div>
    </Watch>
  );
}

// 6. LIVE WORKOUT — parameterized by velocity state
// state: 'excellent' | 'good' | 'slow' | 'fail'
function LiveWorkout({ alwaysOn, state = 'good', velocity = '0.62', rep = 5, total = 8, hr = 142, mode = 'velocity', variant = 'MV', exercise = '深蹲', weight = 100, vl = 18 }) {
  const stateColor = {
    excellent: T.green,
    good: T.fg,
    slow: T.orange,
    fail: T.red,
  }[state];

  const stateBadge = {
    excellent: { text: '优秀', icon: G.arrow(28, T.green, 'up') },
    good:      { text: '达标', icon: null },
    slow:      { text: '偏慢', icon: G.arrow(28, T.orange, 'up') },
    fail:      { text: '未达标', icon: G.arrow(28, T.red, 'down') },
  }[state];

  const display = mode === 'velocity' ? (
    <div style={{ display:'flex', flexDirection:'column', alignItems:'center' }}>
      <div style={{ display:'flex', alignItems:'baseline', gap: 8 }}>
        <span style={{ fontSize: 200, fontWeight: 800, color: stateColor,
          letterSpacing:'-0.06em', lineHeight: 1, fontVariantNumeric:'tabular-nums' }}>
          {velocity}
        </span>
        <span style={{ fontSize: 36, fontWeight: 500, color: T.sub }}>m/s</span>
      </div>
      <div style={{ marginTop: -4, fontSize: 14, fontWeight: 600, color: T.sub,
        letterSpacing:'0.08em', textTransform:'uppercase' }}>
        {variant} · V1RM 0.30
      </div>
    </div>
  ) : mode === 'vl' ? (
    <div style={{ display:'flex', alignItems:'baseline', gap: 6 }}>
      <span style={{ fontSize: 200, fontWeight: 800, color: stateColor,
        letterSpacing:'-0.05em', lineHeight: 1 }}>{vl}</span>
      <span style={{ fontSize: 60, fontWeight: 600, color: stateColor }}>%</span>
    </div>
  ) : (
    <div style={{ display:'flex', alignItems:'baseline', gap: 8 }}>
      <span style={{ fontSize: 200, fontWeight: 800, color: T.red,
        letterSpacing:'-0.05em', lineHeight: 1 }}>{hr}</span>
      <span style={{ fontSize: 32, fontWeight: 500, color: T.sub }}>bpm</span>
    </div>
  );

  return (
    <Watch alwaysOn={alwaysOn}>
      {/* Top — exercise + weight, no border */}
      <div style={{ position:'absolute', top: 14, left: 0, right: 0,
        display:'flex', justifyContent:'space-between', padding:'0 32px' }}>
        <div style={{ fontSize: 22, fontWeight: 600, color: T.sub }}>
          {exercise} · {weight}kg
        </div>
        <div style={{ fontSize: 22, fontWeight: 600, color: T.fg }}>10:24</div>
      </div>

      {/* Rep label */}
      <div style={{ position:'absolute', top: 52, left: 0, right: 0, textAlign:'center' }}>
        <Label size={22} color={stateColor}>REP {rep}</Label>
      </div>

      {/* Big number */}
      <div style={{ position:'absolute', top: 92, left: 0, right: 0,
        display:'flex', flexDirection:'column', alignItems:'center' }}>
        {display}
        {/* state badge */}
        <div style={{ marginTop: 6, display:'flex', alignItems:'center', gap: 6 }}>
          {stateBadge.icon}
          <span style={{ fontSize: 22, fontWeight: 600, color: stateColor,
            letterSpacing:'0.04em', textTransform:'uppercase' }}>{stateBadge.text}</span>
        </div>
      </div>

      {/* Bottom row: rep counter + heart rate */}
      <div style={{ position:'absolute', bottom: 86, left: 0, right: 0,
        display:'flex', justifyContent:'space-around', alignItems:'center', padding:'0 32px' }}>
        <div style={{ textAlign:'center' }}>
          <Label size={18}>REPS</Label>
          <div style={{ fontSize: 38, fontWeight: 700, color: T.fg, marginTop: 2,
            fontVariantNumeric:'tabular-nums' }}>
            {rep}<span style={{ color: T.sub, fontWeight: 500 }}>/{total}</span>
          </div>
        </div>
        <div style={{ textAlign:'center', display:'flex', alignItems:'center', gap: 6 }}>
          {G.heart(22, T.red)}
          <div style={{ fontSize: 38, fontWeight: 700, color: T.fg,
            fontVariantNumeric:'tabular-nums' }}>{hr}</div>
        </div>
      </div>

      {/* End set button — pill, red, full bottom */}
      <button style={{
        position:'absolute', bottom: 18, left: 28, right: 28, height: 54,
        borderRadius: 27, border:'none', background: T.red, color: T.fg,
        fontFamily:'inherit', fontSize: 22, fontWeight: 600, letterSpacing:'0.02em',
      }}>结束本组</button>
    </Watch>
  );
}

// 7. REST TIMER — VL%-based weight suggestion (PRD §5.11 rule)
function Rest({ alwaysOn, secondsLeft = 83, total = 90, lastVL = 18, lastReps = 6, lastMV = '0.62' }) {
  const m = Math.floor(secondsLeft/60);
  const s = String(secondsLeft%60).padStart(2,'0');
  // PRD rule: VL<10 +2.5kg / 10-25 keep / >30 -2.5kg
  const rec = lastVL < 10 ? { delta: '+2.5', target: 102.5, color: T.green, label: '加重' }
    : lastVL > 30 ? { delta: '−2.5', target: 97.5, color: T.orange, label: '减重' }
    : { delta: '保持', target: 100, color: T.fg, label: '维持' };
  return (
    <Watch alwaysOn={alwaysOn}>
      <StatusBar title="休息" color={T.fg}/>
      {/* Top: previous-set summary — variant + VL% */}
      <div style={{ position:'absolute', top: 46, left: 0, right: 0, textAlign:'center' }}>
        <div style={{ fontSize: 20, fontWeight: 600, color: T.fg }}>
          上组 · {lastReps} reps
        </div>
        <div style={{ fontSize: 18, fontWeight: 500, color: T.sub, marginTop: 1 }}>
          MV {lastMV} · VL {lastVL}%
        </div>
      </div>

      {/* Center: countdown ring */}
      <div style={{ position:'absolute', top: 110, left: 0, right: 0,
        display:'flex', justifyContent:'center' }}>
        <div style={{ position:'relative', width: 240, height: 240,
          display:'flex', alignItems:'center', justifyContent:'center' }}>
          <Ring size={240} stroke={10} progress={1 - secondsLeft/total} color={T.orange}/>
          <div style={{ textAlign:'center' }}>
            <div style={{ fontSize: 100, fontWeight: 800, color: T.fg,
              letterSpacing:'-0.04em', lineHeight: 1, fontVariantNumeric:'tabular-nums' }}>
              {m}:{s}
            </div>
            <Label size={16} style={{ marginTop: 4 }}>剩余 · 共 {total}s</Label>
          </div>
        </div>
      </div>

      {/* Bottom: weight rule output */}
      <div style={{ position:'absolute', bottom: 22, left: 0, right: 0, textAlign:'center' }}>
        <Label size={15} color={rec.color}>下一组 · {rec.label}</Label>
        <div style={{ fontSize: 26, fontWeight: 700, color: rec.color, marginTop: 2 }}>
          {rec.delta === '保持' ? '保持 100kg' : `${rec.delta} → ${rec.target}kg`}
        </div>
        <div style={{ fontSize: 14, color: T.sub, fontWeight: 500, marginTop: 2,
          letterSpacing:'0.04em' }}>
          基于 VL {lastVL}% · 规则
        </div>
      </div>
    </Watch>
  );
}

// 8. SUMMARY
function Summary({ alwaysOn }) {
  const rows = [
    { label: '总 REPS',    val: '32',    sub: '4 组 × 8' },
    { label: '平均速度',    val: '0.58',  sub: 'm/s' },
    { label: 'VL%',         val: '16',    sub: '速度衰减' },
  ];
  return (
    <Watch alwaysOn={alwaysOn}>
      <StatusBar title="完成" color={T.green}/>
      <div style={{ position:'absolute', top: 50, left: 0, right: 0, bottom: 70,
        padding:'0 36px', display:'flex', flexDirection:'column',
        justifyContent:'space-evenly' }}>
        {rows.map((r, i) => (
          <div key={r.label}>
            <Label size={18}>{r.label}</Label>
            <div style={{ display:'flex', alignItems:'baseline', gap: 10, marginTop: 2 }}>
              <span style={{ fontSize: 76, fontWeight: 800, color: T.fg,
                letterSpacing:'-0.04em', lineHeight: 1, fontVariantNumeric:'tabular-nums' }}>
                {r.val}
              </span>
              <span style={{ fontSize: 22, fontWeight: 500, color: T.sub }}>{r.sub}</span>
            </div>
          </div>
        ))}
      </div>
      <button style={{
        position:'absolute', bottom: 18, left: 28, right: 28, height: 50,
        borderRadius: 25, border:'none', background:'rgba(48,209,88,0.18)',
        color: T.green, fontFamily:'inherit', fontSize: 22, fontWeight: 600,
      }}>完成</button>
    </Watch>
  );
}

// 9. PLAN PROGRESS — vertical timeline
function PlanProgress({ alwaysOn }) {
  const items = [
    { name: '深蹲',  sub: '5×5 · 100kg',     status: 'done' },
    { name: '卧推',  sub: '4×8 · 75kg',       status: 'current' },
    { name: '硬拉',  sub: '3×3 · 140kg',      status: 'pending' },
    { name: '引体向上', sub: '4×AMRAP',       status: 'pending' },
  ];
  return (
    <Watch alwaysOn={alwaysOn}>
      <StatusBar title="计划"/>
      <div style={{ position:'absolute', top: 50, left: 0, right: 0, bottom: 0,
        padding:'8px 28px', overflow:'hidden' }}>
        {items.map((it, i) => {
          const isLast = i === items.length-1;
          const dotColor = it.status==='done' ? T.sub
            : it.status==='current' ? T.orange : 'transparent';
          const dotBorder = it.status==='pending' ? '2px solid rgba(255,255,255,0.3)' : 'none';
          const titleColor = it.status==='done' ? T.sub
            : it.status==='current' ? T.fg : 'rgba(255,255,255,0.7)';
          return (
            <div key={it.name} style={{ display:'flex', gap: 14, position:'relative',
              paddingBottom: isLast ? 0 : 22 }}>
              {/* Connector + dot */}
              <div style={{ width: 24, position:'relative', flexShrink: 0 }}>
                {!isLast && <div style={{
                  position:'absolute', left: 11, top: 22, bottom: -22, width: 2,
                  background: 'rgba(255,255,255,0.12)',
                }}/>}
                <div style={{
                  width: 24, height: 24, borderRadius:'50%',
                  background: it.status==='current' ? T.orange : (it.status==='done' ? 'rgba(255,255,255,0.12)' : 'transparent'),
                  border: dotBorder,
                  display:'flex', alignItems:'center', justifyContent:'center',
                }}>
                  {it.status==='done' && G.check(16, T.fg)}
                  {it.status==='current' && (
                    <div style={{ width: 8, height: 8, background:'#fff', borderRadius:'50%' }}/>
                  )}
                </div>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 26, fontWeight: 600, color: titleColor,
                  textDecoration: it.status==='done' ? 'line-through' : 'none',
                  textDecorationColor: 'rgba(142,142,147,0.6)' }}>
                  {it.name}
                </div>
                <div style={{ fontSize: 18, fontWeight: 500, color: T.sub, marginTop: 1 }}>
                  {it.sub}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </Watch>
  );
}

Object.assign(window, {
  Watch, Label, T, G, Ring, StatusBar,
  Home, Readiness, CMJCountdown, CMJGo, CMJResult,
  ExercisePicker, WeightInput, LiveWorkout, Rest, Summary, PlanProgress,
});

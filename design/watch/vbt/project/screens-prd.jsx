// VBTrainer · PRD-driven additional screens
// PR · VL force-stop · Plan next · RPE · 单边动作 · iPhone 综合图表 · Onboarding

// ──────────────────────────────────────────────────────────────
// PR celebration — fired on detection of personal record (PRD §M8)
// ──────────────────────────────────────────────────────────────
function PRCelebration({ alwaysOn, type = 'velocity', value = '0.71', exercise = '深蹲', meta = 'MV 个人最佳' }) {
  return (
    <Watch alwaysOn={alwaysOn}>
      <StatusBar title="新纪录" color={T.orange}/>
      {/* subtle background gradient — only place we use one, justified by celebration semantic */}
      <div style={{ position:'absolute', inset: 0,
        background: 'radial-gradient(ellipse at top, rgba(255,149,0,0.16), transparent 60%)' }}/>
      <div style={{ position:'absolute', inset:0, display:'flex',
        flexDirection:'column', alignItems:'center', justifyContent:'center', gap: 6 }}>
        {/* Original PR mark — concentric arcs forming a target */}
        <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
          <circle cx="32" cy="32" r="6"  fill={T.orange}/>
          <circle cx="32" cy="32" r="14" stroke={T.orange} strokeWidth="2"/>
          <circle cx="32" cy="32" r="22" stroke={T.orange} strokeWidth="2" opacity="0.5"/>
          <circle cx="32" cy="32" r="30" stroke={T.orange} strokeWidth="2" opacity="0.2"/>
        </svg>
        <Label size={20} color={T.orange} style={{ marginTop: 4 }}>PR · 新纪录</Label>
        <div style={{ display:'flex', alignItems:'baseline', gap: 8 }}>
          <span style={{ fontSize: 130, fontWeight: 800, color: T.fg,
            letterSpacing:'-0.05em', lineHeight: 1, fontVariantNumeric:'tabular-nums' }}>
            {value}
          </span>
          <span style={{ fontSize: 30, fontWeight: 500, color: T.sub }}>m/s</span>
        </div>
        <div style={{ fontSize: 22, fontWeight: 600, color: T.fg, marginTop: 4 }}>
          {exercise}
        </div>
        <div style={{ fontSize: 18, fontWeight: 500, color: T.sub, marginTop: 1 }}>
          {meta}
        </div>
      </div>
      <div style={{ position:'absolute', bottom: 22, left: 0, right: 0, textAlign:'center',
        fontSize: 16, color: T.sub, fontWeight: 500, letterSpacing:'0.06em', textTransform:'uppercase' }}>
        3s 自动消失
      </div>
    </Watch>
  );
}

// ──────────────────────────────────────────────────────────────
// VL% force-stop warning — VL exceeds user-set ceiling (PRD §M5)
// ──────────────────────────────────────────────────────────────
function VLStopWarning({ alwaysOn, vl = 32, threshold = 30 }) {
  return (
    <Watch alwaysOn={alwaysOn}>
      <StatusBar title="VL 警戒" color={T.red}/>
      <div style={{ position:'absolute', top: 56, left: 0, right: 0, textAlign:'center' }}>
        <Label size={18} color={T.red}>速度衰减超过阈值</Label>
        <div style={{ display:'flex', alignItems:'baseline', justifyContent:'center', gap: 6, marginTop: 8 }}>
          <span style={{ fontSize: 160, fontWeight: 800, color: T.red,
            letterSpacing:'-0.05em', lineHeight: 1, fontVariantNumeric:'tabular-nums' }}>
            {vl}
          </span>
          <span style={{ fontSize: 56, fontWeight: 600, color: T.red }}>%</span>
        </div>
        <div style={{ fontSize: 18, fontWeight: 500, color: T.sub, marginTop: 6 }}>
          阈值 {threshold}% · 力量目标
        </div>
      </div>
      {/* Two buttons: continue vs end */}
      <div style={{ position:'absolute', bottom: 18, left: 16, right: 16,
        display:'flex', gap: 8 }}>
        <button style={{
          flex: 1, height: 50, borderRadius: 25, border:'none',
          background:'rgba(255,255,255,0.10)', color: T.fg,
          fontFamily:'inherit', fontSize: 18, fontWeight: 600,
        }}>继续</button>
        <button style={{
          flex: 1, height: 50, borderRadius: 25, border:'none',
          background: T.red, color: T.fg,
          fontFamily:'inherit', fontSize: 18, fontWeight: 600,
        }}>结束</button>
      </div>
    </Watch>
  );
}

// ──────────────────────────────────────────────────────────────
// Plan next-card — shown post-rest, before next exercise (PRD §M3.2)
// ──────────────────────────────────────────────────────────────
function PlanNext({ alwaysOn }) {
  return (
    <Watch alwaysOn={alwaysOn}>
      <StatusBar title="下一项 · 2/4" color={T.orange}/>
      <div style={{ position:'absolute', top: 62, left: 0, right: 0, textAlign:'center' }}>
        <Label size={16}>从计划</Label>
        <div style={{ fontSize: 60, fontWeight: 800, color: T.fg,
          marginTop: 6, letterSpacing:'-0.02em' }}>卧推</div>
        <div style={{ fontSize: 26, fontWeight: 600, color: T.fg, marginTop: 8 }}>
          75 kg
        </div>
        <div style={{ fontSize: 20, fontWeight: 500, color: T.sub, marginTop: 2 }}>
          4 组 × 8 reps
        </div>
        {/* target velocity range — driven by exercise metadata */}
        <div style={{ marginTop: 16, padding:'10px 22px', display:'inline-block',
          borderRadius: 18, background:'rgba(255,255,255,0.06)' }}>
          <div style={{ fontSize: 13, color: T.sub, fontWeight: 500,
            letterSpacing:'0.06em', textTransform:'uppercase' }}>目标 MPV</div>
          <div style={{ fontSize: 22, fontWeight: 700, color: T.green, marginTop: 2 }}>
            0.55 – 0.70 m/s
          </div>
        </div>
      </div>
      <button style={{
        position:'absolute', bottom: 18, left: 28, right: 28, height: 54,
        borderRadius: 27, border:'none', background: T.orange, color: T.fg,
        fontFamily:'inherit', fontSize: 22, fontWeight: 600,
      }}>开始本动作</button>
    </Watch>
  );
}

// ──────────────────────────────────────────────────────────────
// RPE post-set input — 1-10 via Crown (PRD §M6.1)
// ──────────────────────────────────────────────────────────────
function RPEInput({ alwaysOn, value = 8 }) {
  return (
    <Watch alwaysOn={alwaysOn}>
      <StatusBar title="RPE"/>
      <div style={{ position:'absolute', top: 50, left: 0, right: 0, textAlign:'center' }}>
        <Label size={16}>本组主观感受</Label>
        <div style={{ fontSize: 200, fontWeight: 800, color: T.orange, lineHeight: 1,
          letterSpacing:'-0.05em', marginTop: 4, fontVariantNumeric:'tabular-nums' }}>
          {value}
        </div>
        <div style={{ fontSize: 18, fontWeight: 500, color: T.sub, marginTop: -4 }}>
          / 10 · 还能再做 {10-value} 次
        </div>
      </div>
      {/* Scale: 10 dots showing position */}
      <div style={{ position:'absolute', bottom: 80, left: 0, right: 0,
        display:'flex', justifyContent:'center', gap: 6 }}>
        {Array.from({ length: 10 }).map((_, i) => (
          <div key={i} style={{
            width: 16, height: 6, borderRadius: 3,
            background: i < value ? (i < 7 ? T.green : i < 9 ? T.orange : T.red) : 'rgba(255,255,255,0.18)',
          }}/>
        ))}
      </div>
      <div style={{ position:'absolute', bottom: 26, left: 0, right: 0, textAlign:'center',
        fontSize: 16, color: T.sub, fontWeight: 500, letterSpacing:'0.06em', textTransform:'uppercase' }}>
        转动 Crown · 长按跳过
      </div>
      {/* crown bracket */}
      <div style={{ position:'absolute', right: 0, top: '50%', transform:'translateY(-50%)',
        display:'flex', flexDirection:'column', gap: 6, padding:'14px 6px' }}>
        <div style={{ width: 4, height: 26, borderRadius: 2, background: 'rgba(255,255,255,0.18)' }}/>
        <div style={{ width: 4, height: 56, borderRadius: 2, background: T.orange }}/>
        <div style={{ width: 4, height: 26, borderRadius: 2, background: 'rgba(255,255,255,0.18)' }}/>
      </div>
    </Watch>
  );
}

// ──────────────────────────────────────────────────────────────
// 单边动作 split-side display (e.g. 保加利亚分腿蹲) — PRD §M4.3
// ──────────────────────────────────────────────────────────────
function UnilateralLive({ alwaysOn }) {
  return (
    <Watch alwaysOn={alwaysOn}>
      <div style={{ position:'absolute', top: 14, left: 0, right: 0,
        display:'flex', justifyContent:'space-between', padding:'0 32px' }}>
        <div style={{ fontSize: 22, fontWeight: 600, color: T.sub }}>
          保加利亚 · 24kg
        </div>
        <div style={{ fontSize: 22, fontWeight: 600, color: T.fg }}>10:24</div>
      </div>
      <div style={{ position:'absolute', top: 56, left: 0, right: 0, textAlign:'center' }}>
        <Label size={20} color={T.orange}>REP 5 · 右</Label>
      </div>
      {/* Two halves: left + right, current side highlighted */}
      <div style={{ position:'absolute', top: 110, left: 0, right: 0,
        display:'flex', padding:'0 24px' }}>
        <div style={{ flex: 1, textAlign:'center', opacity: 0.45 }}>
          <Label size={14}>左</Label>
          <div style={{ fontSize: 80, fontWeight: 800, color: T.fg,
            letterSpacing:'-0.04em', lineHeight: 1.05, marginTop: 4,
            fontVariantNumeric:'tabular-nums' }}>0.58</div>
          <div style={{ fontSize: 13, color: T.sub, fontWeight: 500, marginTop: 2 }}>
            5 reps · MV
          </div>
        </div>
        <div style={{ width: 1, background: 'rgba(255,255,255,0.10)', margin: '8px 0' }}/>
        <div style={{ flex: 1, textAlign:'center' }}>
          <Label size={14} color={T.orange}>右 · 当前</Label>
          <div style={{ fontSize: 90, fontWeight: 800, color: T.green,
            letterSpacing:'-0.05em', lineHeight: 1.05, marginTop: 4,
            fontVariantNumeric:'tabular-nums' }}>0.62</div>
          <div style={{ fontSize: 13, color: T.sub, fontWeight: 500, marginTop: 2 }}>
            5 reps · MV
          </div>
        </div>
      </div>
      {/* Asymmetry indicator */}
      <div style={{ position:'absolute', bottom: 84, left: 0, right: 0, textAlign:'center' }}>
        <div style={{ fontSize: 14, color: T.sub, fontWeight: 500,
          letterSpacing:'0.06em', textTransform:'uppercase' }}>
          左右差异 6.5%
        </div>
      </div>
      <button style={{
        position:'absolute', bottom: 18, left: 28, right: 28, height: 50,
        borderRadius: 25, border:'none', background: T.red, color: T.fg,
        fontFamily:'inherit', fontSize: 20, fontWeight: 600,
      }}>结束本组</button>
    </Watch>
  );
}

// ──────────────────────────────────────────────────────────────
// Onboarding — first-launch user profile (PRD §M1)
// One screen showing the 体型 segmented picker, representative of flow
// ──────────────────────────────────────────────────────────────
function OnboardingBodyType({ alwaysOn }) {
  const types = ['瘦', '标准', '偏壮', '健美', '力量型'];
  const sel = 2;
  return (
    <Watch alwaysOn={alwaysOn}>
      <StatusBar title="3 / 6"/>
      <div style={{ position:'absolute', top: 50, left: 0, right: 0, padding:'0 28px' }}>
        <Label size={16}>个人画像</Label>
        <div style={{ fontSize: 36, fontWeight: 700, color: T.fg, marginTop: 4 }}>
          体型
        </div>
      </div>
      <div style={{ position:'absolute', top: 156, left: 28, right: 28,
        display:'flex', flexDirection:'column', gap: 8 }}>
        {types.map((t, i) => (
          <div key={t} style={{
            padding:'12px 18px', borderRadius: 16,
            background: i===sel ? T.orange : 'rgba(255,255,255,0.06)',
            color: i===sel ? T.fg : 'rgba(255,255,255,0.85)',
            fontSize: 22, fontWeight: 600,
            display:'flex', justifyContent:'space-between', alignItems:'center',
          }}>
            <span>{t}</span>
            {i===sel && G.check(20, T.fg)}
          </div>
        ))}
      </div>
      <div style={{ position:'absolute', right: 0, top: '50%', transform:'translateY(-50%)',
        display:'flex', flexDirection:'column', gap: 6, padding:'14px 6px' }}>
        <div style={{ width: 4, height: 56, borderRadius: 2, background: 'rgba(255,255,255,0.18)' }}/>
        <div style={{ width: 4, height: 26, borderRadius: 2, background: T.orange }}/>
        <div style={{ width: 4, height: 56, borderRadius: 2, background: 'rgba(255,255,255,0.18)' }}/>
      </div>
    </Watch>
  );
}

// ──────────────────────────────────────────────────────────────
// Crown weight-step selector — overlay shown when user long-presses
// the weight value during rest (PRD §M4.3 · 0.5/1/2.5/5)
// ──────────────────────────────────────────────────────────────
function CrownStepSelector({ alwaysOn }) {
  const steps = ['0.5', '1', '2.5', '5'];
  const sel = 2;
  return (
    <Watch alwaysOn={alwaysOn}>
      <StatusBar title="Crown 档位"/>
      <div style={{ position:'absolute', top: 60, left: 0, right: 0, textAlign:'center' }}>
        <Label size={16}>每齿增量</Label>
      </div>
      <div style={{ position:'absolute', top: 110, left: 28, right: 28 }}>
        {steps.map((s, i) => (
          <div key={s} style={{
            padding:'12px 18px', marginBottom: 8, borderRadius: 16,
            background: i===sel ? T.orange : 'rgba(255,255,255,0.06)',
            color: T.fg, fontSize: 24, fontWeight: 700,
            display:'flex', justifyContent:'space-between', alignItems:'baseline',
            fontVariantNumeric:'tabular-nums',
          }}>
            <span>{s} kg</span>
            <span style={{ fontSize: 14, color: i===sel ? 'rgba(255,255,255,0.7)' : T.sub,
              fontWeight: 500, letterSpacing:'0.06em', textTransform:'uppercase' }}>
              {s==='2.5' ? '默认' : s==='0.5' ? '微调' : s==='5' ? '快进' : '常规'}
            </span>
          </div>
        ))}
      </div>
    </Watch>
  );
}

// ──────────────────────────────────────────────────────────────
// iPhone companion · M6.2 综合训练图表
// 心率（左轴）+ 速度散点（右轴）+ 动作切换分隔 + 休息区间 + VL 警戒线
// ──────────────────────────────────────────────────────────────
function PhoneSummary() {
  const Wp = 393, Hp = 800;
  // Layout: header / chart / metrics
  // Generate fake but plausible data
  const reps = [];
  // 4 sets × 8 reps for 深蹲, 3 sets × 5 for 卧推
  const blocks = [
    { name: '深蹲', kg: 100, sets: 4, reps: 8, vBase: 0.62, vDecay: 0.045, color: '#0A84FF' },
    { name: '卧推', kg: 75,  sets: 3, reps: 5, vBase: 0.55, vDecay: 0.030, color: '#BF5AF2' },
  ];
  let t = 0;
  const setBoundaries = []; // [{ time, kind, label }]
  blocks.forEach((b, bi) => {
    if (bi > 0) {
      setBoundaries.push({ time: t, kind: 'exercise', label: `${b.name} · ${b.kg}kg` });
    } else {
      setBoundaries.push({ time: 0, kind: 'exercise', label: `${b.name} · ${b.kg}kg` });
    }
    for (let s = 0; s < b.sets; s++) {
      const setStart = t;
      // each rep ~3s
      for (let r = 0; r < b.reps; r++) {
        const v = b.vBase - r * b.vDecay + (Math.random() - 0.5) * 0.02;
        reps.push({ t: t, v, color: b.color });
        t += 3;
      }
      // rest after set (90s)
      const restEnd = t + 90;
      setBoundaries.push({ time: t, kind: 'restStart' });
      setBoundaries.push({ time: restEnd, kind: 'restEnd' });
      t = restEnd;
    }
  });
  const totalT = t;
  // Heart rate: simulate sawtooth — climbs during set, drops in rest
  const hrPts = [];
  let curHR = 95;
  for (let i = 0; i < totalT; i += 5) {
    // determine if in rest
    let inRest = false;
    setBoundaries.forEach(b => {
      if (b.kind === 'restStart' && i >= b.time) inRest = true;
      if (b.kind === 'restEnd' && i >= b.time) inRest = false;
    });
    if (inRest) curHR = Math.max(95, curHR - 3.5 + (Math.random()-0.5)*1.5);
    else curHR = Math.min(165, curHR + 4 + (Math.random()-0.5)*2);
    hrPts.push({ t: i, hr: curHR });
  }

  // Chart geometry
  const chartW = Wp - 48;
  const chartH = 280;
  const padL = 36, padR = 36, padT = 16, padB = 28;
  const innerW = chartW - padL - padR;
  const innerH = chartH - padT - padB;
  const xs = (tt) => padL + (tt / totalT) * innerW;
  const ysHR = (hr) => padT + ((165 - hr) / (165 - 80)) * innerH;
  const ysV = (v) => padT + ((1.0 - v) / (1.0 - 0.1)) * innerH;

  const hrPath = hrPts.map((p, i) =>
    `${i === 0 ? 'M' : 'L'} ${xs(p.t).toFixed(1)} ${ysHR(p.hr).toFixed(1)}`
  ).join(' ');

  return (
    <div style={{
      width: Wp, height: Hp, background: '#000', color: T.fg,
      fontFamily: T.font, position: 'relative', overflow: 'hidden',
      borderRadius: 50,
    }}>
      {/* Status bar mock */}
      <div style={{ position:'absolute', top: 14, left: 24, right: 24,
        display:'flex', justifyContent:'space-between', fontSize: 14, fontWeight: 600 }}>
        <span>10:24</span>
        <span>VBT</span>
      </div>
      {/* Header */}
      <div style={{ padding:'56px 24px 14px' }}>
        <Label size={11}>2026.05.08 · 周三</Label>
        <div style={{ fontSize: 28, fontWeight: 700, marginTop: 2 }}>训练详情</div>
        <div style={{ fontSize: 14, color: T.sub, fontWeight: 500, marginTop: 2 }}>
          深蹲 + 卧推 · 47 分钟
        </div>
      </div>

      {/* Chart card */}
      <div style={{ margin:'0 16px', padding: 16, borderRadius: 18,
        background: 'rgba(255,255,255,0.04)' }}>
        <div style={{ display:'flex', justifyContent:'space-between', alignItems:'baseline' }}>
          <Label size={10}>速度 + 心率 + 组间</Label>
          <div style={{ display:'flex', gap: 12, fontSize: 11, fontWeight: 500 }}>
            <span style={{ color: T.red }}>● 心率</span>
            <span style={{ color: '#0A84FF' }}>● 深蹲</span>
            <span style={{ color: '#BF5AF2' }}>● 卧推</span>
          </div>
        </div>

        <svg width={chartW} height={chartH} style={{ display:'block', marginTop: 6 }}>
          {/* rest region shading */}
          {(() => {
            const out = [];
            for (let i = 0; i < setBoundaries.length; i++) {
              if (setBoundaries[i].kind === 'restStart') {
                const next = setBoundaries.slice(i+1).find(b => b.kind === 'restEnd');
                if (next) {
                  out.push(<rect key={`r${i}`} x={xs(setBoundaries[i].time)} y={padT}
                    width={xs(next.time)-xs(setBoundaries[i].time)} height={innerH}
                    fill="rgba(255,255,255,0.03)"/>);
                }
              }
            }
            return out;
          })()}

          {/* exercise switch lines + labels */}
          {setBoundaries.filter(b => b.kind === 'exercise').map((b, i) => (
            <g key={`e${i}`}>
              <line x1={xs(b.time)} y1={padT} x2={xs(b.time)} y2={padT+innerH}
                stroke="rgba(255,255,255,0.18)" strokeDasharray="2 3"/>
              <text x={xs(b.time)+4} y={padT+12} fontSize="9" fill={T.sub}
                fontFamily={T.font} fontWeight="600">{b.label}</text>
            </g>
          ))}

          {/* VL warning line at v=0.50 (30% loss from 0.62 start) */}
          <line x1={padL} y1={ysV(0.50)} x2={padL+innerW} y2={ysV(0.50)}
            stroke="rgba(255,69,58,0.5)" strokeDasharray="3 4" strokeWidth="1"/>
          <text x={padL+innerW-4} y={ysV(0.50)-4} fontSize="9" fill={T.red}
            fontFamily={T.font} fontWeight="600" textAnchor="end">VL 30%</text>

          {/* HR line */}
          <path d={hrPath} stroke={T.red} strokeWidth="1.5" fill="none" opacity="0.85"/>

          {/* rep dots */}
          {reps.map((r, i) => (
            <circle key={i} cx={xs(r.t)} cy={ysV(r.v)} r="2.5"
              fill={r.color}/>
          ))}

          {/* Y axis labels */}
          <text x={padL-4} y={padT+6} fontSize="9" fill={T.sub} textAnchor="end" fontFamily={T.font}>1.0</text>
          <text x={padL-4} y={padT+innerH} fontSize="9" fill={T.sub} textAnchor="end" fontFamily={T.font}>0.1</text>
          <text x={padL+innerW+4} y={padT+6} fontSize="9" fill={T.sub} fontFamily={T.font}>165</text>
          <text x={padL+innerW+4} y={padT+innerH} fontSize="9" fill={T.sub} fontFamily={T.font}>80</text>
          <text x={padL-4} y={padT-4} fontSize="9" fill={T.sub} textAnchor="end" fontFamily={T.font}>m/s</text>
          <text x={padL+innerW+4} y={padT-4} fontSize="9" fill={T.red} fontFamily={T.font}>bpm</text>
        </svg>
      </div>

      {/* Stat strip */}
      <div style={{ margin:'14px 16px 0', display:'grid', gridTemplateColumns:'repeat(4,1fr)', gap: 8 }}>
        {[
          ['总 REPS', '52'],
          ['总训练量', '3.9t'],
          ['平均 MV', '0.58'],
          ['平均 VL', '14%'],
        ].map(([l,v]) => (
          <div key={l} style={{ padding:'10px 10px', borderRadius: 12,
            background:'rgba(255,255,255,0.04)' }}>
            <div style={{ fontSize: 9, fontWeight: 600, color: T.sub,
              letterSpacing:'0.08em', textTransform:'uppercase' }}>{l}</div>
            <div style={{ fontSize: 20, fontWeight: 700, color: T.fg, marginTop: 1,
              fontVariantNumeric:'tabular-nums' }}>{v}</div>
          </div>
        ))}
      </div>

      {/* HR zone ring + sets table */}
      <div style={{ margin:'14px 16px', padding: 14, borderRadius: 16,
        background:'rgba(255,255,255,0.04)' }}>
        <Label size={10}>本次组数据</Label>
        <div style={{ marginTop: 8, fontSize: 12, fontVariantNumeric:'tabular-nums' }}>
          <div style={{ display:'grid', gridTemplateColumns:'1fr 50px 50px 60px 50px',
            gap: 6, color: T.sub, fontWeight: 600, letterSpacing:'0.04em',
            paddingBottom: 6, borderBottom: '1px solid rgba(255,255,255,0.08)',
            fontSize: 10, textTransform:'uppercase' }}>
            <span>动作</span><span style={{ textAlign:'right' }}>kg</span>
            <span style={{ textAlign:'right' }}>reps</span>
            <span style={{ textAlign:'right' }}>MV</span>
            <span style={{ textAlign:'right' }}>VL%</span>
          </div>
          {[
            ['深蹲 #1', 100, 8, '0.62', 8],
            ['深蹲 #2', 100, 8, '0.59', 14],
            ['深蹲 #3', 100, 8, '0.55', 22],
            ['深蹲 #4', 100, 8, '0.52', 28],
            ['卧推 #1', 75,  5, '0.55', 6],
            ['卧推 #2', 75,  5, '0.52', 12],
            ['卧推 #3', 75,  5, '0.49', 18],
          ].map((r, i) => (
            <div key={i} style={{ display:'grid', gridTemplateColumns:'1fr 50px 50px 60px 50px',
              gap: 6, padding:'6px 0', fontSize: 12, fontWeight: 500, color: T.fg,
              borderBottom: i < 6 ? '1px solid rgba(255,255,255,0.04)' : 'none' }}>
              <span>{r[0]}</span>
              <span style={{ textAlign:'right' }}>{r[1]}</span>
              <span style={{ textAlign:'right' }}>{r[2]}</span>
              <span style={{ textAlign:'right' }}>{r[3]}</span>
              <span style={{ textAlign:'right',
                color: r[4] > 25 ? T.red : r[4] > 15 ? T.orange : T.green }}>
                {r[4]}%
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// PRD mapping legend — 9 watch screens × PRD module mapping
// ──────────────────────────────────────────────────────────────
function PRDMapping() {
  const rows = [
    ['Home',           'M0',     '入口'],
    ['Readiness',      'M2.1',   'HRV 50% · 睡眠 25% · RHR 20% · 温度 5%'],
    ['CMJ 测试',       'M2.2',   '飞行时间法 · 3 跳取最佳 · 与基线对比'],
    ['选动作',         'M4.1',   '30 动作库 · 元数据驱动'],
    ['输入重量',       'M4.3',   'Crown 0.5/1/2.5/5kg 档位'],
    ['训练中',         'M4.2 · M5', 'IMU 100Hz · MV/MPV/PV · 4 状态色 + 4 震动'],
    ['组间休息',       'M4.3 · 5.11', 'VL%-based 重量规则: <10%+2.5 · >30%−2.5'],
    ['训练总结',       'M6.1',   '基本统计 · 写回 HealthKit'],
    ['计划进度',       'M3.2 · 3.3', '模板执行 · 实际 vs 计划'],
    ['PR 庆祝',        'M8',     '速度 / 重量 / e1RM / CMJ PR 自动检测'],
    ['VL 警戒',        'M5',     '阈值触发强制停组'],
    ['下一项',         'M3.2',   '从计划下发 · 目标速度区间显示'],
    ['RPE 输入',       'M6.1',   'Crown 1-10 · 主观感受可选填'],
    ['单边动作',       'M4.3',   '左右分别记录 · 对称性指标'],
    ['Onboarding',     'M1',     '6 步画像采集 · HealthKit 权限'],
    ['iPhone 详情',    'M6.2',   '心率 + 速度 + 动作切换 + 休息 + VL 线'],
  ];
  return (
    <div style={{
      width: 720, padding: 28, borderRadius: 14,
      background: '#fafaf7', border: '1px solid rgba(0,0,0,0.05)',
      fontFamily: 'ui-sans-serif,-apple-system,system-ui,sans-serif', color:'#1c1c1e',
    }}>
      <div style={{ fontSize: 14, fontWeight: 600, color:'#8E8E93', letterSpacing:'0.08em',
        textTransform:'uppercase' }}>PRD Mapping</div>
      <div style={{ fontSize: 26, fontWeight: 600, marginTop: 4 }}>每屏 → PRD 模块映射</div>
      <div style={{ marginTop: 18 }}>
        {rows.map((r, i) => (
          <div key={r[0]} style={{ display:'grid', gridTemplateColumns:'140px 90px 1fr',
            gap: 14, padding:'9px 0', fontSize: 13, alignItems:'baseline',
            borderBottom: i < rows.length-1 ? '1px solid rgba(0,0,0,0.04)' : 'none' }}>
            <span style={{ fontWeight: 600, color:'#000' }}>{r[0]}</span>
            <span style={{ fontFamily:'ui-monospace,Menlo,monospace', fontSize: 12, color:'#FF9500',
              fontWeight: 600 }}>{r[1]}</span>
            <span style={{ color:'#444', lineHeight: 1.4 }}>{r[2]}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

Object.assign(window, {
  PRCelebration, VLStopWarning, PlanNext, RPEInput,
  UnilateralLive, OnboardingBodyType, CrownStepSelector,
  PhoneSummary, PRDMapping,
});

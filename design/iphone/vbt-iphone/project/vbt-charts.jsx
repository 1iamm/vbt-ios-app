// VBT Chart Kit — pure SVG, no deps. Bloomberg-restraint, journal aesthetic.
// All charts honor VBT.data palette; no fills beyond axis & low-alpha bands.

// ── Helpers
const lerp = (a, b, t) => a + (b - a) * t;
const range = (n) => Array.from({ length: n }, (_, i) => i);
// Smooth seeded noise for fake data
const seedRnd = (seed) => {
  let s = seed;
  return () => { s = (s * 9301 + 49297) % 233280; return s / 233280; };
};

// ── Readiness Ring — single thick arc + delta inside.
// Original take: SCORE 0-100 with optional sub-arc band.
const ReadinessRing = ({ score = 78, dark, size = 240, label = '准备度' }) => {
  const t = T(dark);
  const stroke = 18;
  const r = size / 2 - stroke;
  const c = 2 * Math.PI * r;
  const off = c * (1 - score / 100);
  const cx = size / 2;
  const angle = (-90 + (score / 100) * 360) * (Math.PI / 180);
  const tipX = cx + r * Math.cos(angle);
  const tipY = cx + r * Math.sin(angle);
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size}>
        <circle cx={cx} cy={cx} r={r} fill="none" stroke={t.fill2} strokeWidth={stroke}/>
        {/* tick marks at 25/50/75 */}
        {[0, 0.25, 0.5, 0.75].map((p, i) => {
          const a = (-90 + p * 360) * (Math.PI / 180);
          const x1 = cx + (r + stroke / 2 + 4) * Math.cos(a);
          const y1 = cx + (r + stroke / 2 + 4) * Math.sin(a);
          const x2 = cx + (r + stroke / 2 + 9) * Math.cos(a);
          const y2 = cx + (r + stroke / 2 + 9) * Math.sin(a);
          return <line key={i} x1={x1} y1={y1} x2={x2} y2={y2} stroke={t.tertiary} strokeWidth="1"/>;
        })}
        <circle cx={cx} cy={cx} r={r} fill="none" stroke={VBT.accent}
                strokeWidth={stroke} strokeLinecap="round"
                strokeDasharray={c} strokeDashoffset={off}
                transform={`rotate(-90 ${cx} ${cx})`}/>
        <circle cx={tipX} cy={tipY} r={stroke/2 - 1} fill="#fff" opacity="0.9"/>
      </svg>
      <div style={{
        position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center', gap: 2,
      }}>
        <div style={{ fontSize: 11, color: t.secondary, letterSpacing: 1.4, fontWeight: 500, textTransform: 'uppercase' }}>{label}</div>
        <Numeric value={score} size={84} color={t.label} dark={dark} weight={500}/>
        <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 13, color: '#34C759', fontFamily: VBT.fontR, fontWeight: 500 }}>
          <Icon name="arrow-up" size={12} color="#34C759" stroke={2.4}/>+6 较昨日
        </div>
      </div>
    </div>
  );
};

// ── Mini metric (HRV / Sleep / RHR row)
const MiniMetric = ({ label, value, unit, sub, color, dark }) => {
  const t = T(dark);
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 2 }}>
      <div style={{ fontSize: 11, color: t.secondary, fontWeight: 500, letterSpacing: 0.3, textTransform: 'uppercase' }}>{label}</div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 2 }}>
        <span style={{ fontFamily: VBT.fontR, fontSize: 24, fontWeight: 600, color: t.label, letterSpacing: -0.6 }}>{value}</span>
        {unit && <span style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontR }}>{unit}</span>}
      </div>
      {sub && <div style={{ fontSize: 11, color: color || t.tertiary, fontFamily: VBT.fontR, fontWeight: 500 }}>{sub}</div>}
    </div>
  );
};

// ── 30-day frequency heatmap. 5-step orange ramp, NO date labels (more restrained).
// Layout: rows = weekdays (M..S), cols = ~5 weeks.
const Heatmap = ({ dark, weeks = 18, density = 0.55 }) => {
  const t = T(dark);
  const r = seedRnd(42);
  const cell = 14, gap = 4;
  const ramp = [
    t.fill2,
    `${VBT.accent}33`,
    `${VBT.accent}66`,
    `${VBT.accent}AA`,
    `${VBT.accent}`,
  ];
  return (
    <div>
      <div style={{ display: 'flex', gap }}>
        {range(weeks).map(w => (
          <div key={w} style={{ display: 'flex', flexDirection: 'column', gap }}>
            {range(7).map(d => {
              const v = r() < density ? Math.floor(r() * 4) + 1 : 0;
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

// ── Sparkline (used inline in cards)
const Spark = ({ data, w = 80, h = 28, color = VBT.data.vel, fill = false }) => {
  const max = Math.max(...data), min = Math.min(...data);
  const span = max - min || 1;
  const pts = data.map((v, i) => [
    (i / (data.length - 1)) * w,
    h - ((v - min) / span) * h * 0.8 - h * 0.1,
  ]);
  const d = pts.map(([x, y], i) => (i === 0 ? `M${x},${y}` : `L${x},${y}`)).join(' ');
  return (
    <svg width={w} height={h} style={{ display: 'block' }}>
      {fill && <path d={`${d} L${w},${h} L0,${h} Z`} fill={color} opacity="0.12"/>}
      <path d={d} fill="none" stroke={color} strokeWidth="1.5" strokeLinejoin="round" strokeLinecap="round"/>
    </svg>
  );
};

// ─────────────────────────────────────────────────────────────
// THE CENTERPIECE — Combined Timeline Chart
// dual Y-axis, set bands, rest bands, VL warning line, tap popover.
// Designed for 358×260 portrait OR 800×360 landscape.
// ─────────────────────────────────────────────────────────────
const TimelineChart = ({ dark, w = 358, h = 280, landscape = false, showPopover = true }) => {
  const t = T(dark);

  // Synthesize a credible dataset — 5 sets, 4–6 reps each, with rests.
  const sets = [
    { name: '深蹲', label: '120 kg × 5', start: 0,    end: 0.13, color: '#0A84FF' },
    { name: '深蹲', label: '125 kg × 5', start: 0.18, end: 0.30, color: '#0A84FF' },
    { name: '深蹲', label: '130 kg × 4', start: 0.36, end: 0.46, color: '#0A84FF' },
    { name: '卧推', label: '85 kg × 6',  start: 0.55, end: 0.66, color: '#5E5CE6' },
    { name: '卧推', label: '90 kg × 5',  start: 0.72, end: 0.83, color: '#5E5CE6' },
    { name: '硬拉', label: '160 kg × 3', start: 0.90, end: 0.98, color: '#FF9F0A' },
  ];
  const innerL = 36, innerR = 36, innerT = 50, innerB = 32;
  const px = (n) => innerL + n * (w - innerL - innerR);
  const py = (n) => innerT + (1 - n) * (h - innerT - innerB);
  const yL = py;                                            // HR axis (left)
  const yR = py;                                            // velocity axis (right)

  // HR curve — undulating, peaks during sets, valleys during rest
  const hrPts = [];
  const N = 240;
  for (let i = 0; i < N; i++) {
    const t01 = i / (N - 1);
    const inSet = sets.find(s => t01 >= s.start && t01 <= s.end);
    let base = inSet ? 0.62 : 0.30;
    // ramp up at start of set
    if (inSet) {
      const local = (t01 - inSet.start) / (inSet.end - inSet.start);
      base = 0.42 + local * 0.30;
    }
    // recovery decay
    const noise = Math.sin(t01 * 60) * 0.02 + Math.sin(t01 * 13.7) * 0.015;
    hrPts.push([px(t01), yL(base + noise)]);
  }
  const hrPath = hrPts.map(([x, y], i) => (i === 0 ? `M${x},${y}` : `L${x},${y}`)).join(' ');

  // Velocity scatter — one dot per rep, slight downward trend within set (fatigue)
  const repsAll = [];
  sets.forEach((s, si) => {
    const span = s.end - s.start;
    const reps = parseInt(s.label.match(/× ?(\d+)/)?.[1] || 5);
    for (let r = 0; r < reps; r++) {
      const t01 = s.start + (r + 1) / (reps + 1) * span;
      const fatigue = r / Math.max(reps - 1, 1);
      const vel = 0.78 - fatigue * 0.18 + (Math.sin(si * 13 + r) * 0.02);
      repsAll.push({ x: px(t01), y: yR(vel * 0.95), v: (1.05 - fatigue * 0.32 + Math.sin(si + r) * 0.04).toFixed(2), set: si, rep: r });
    }
  });
  // Velocity per-rep line within each set
  const velSegs = sets.map((s, si) => repsAll.filter(r => r.set === si));

  // VL warning line (~25% velocity loss) — horizontal dashed
  const vlY = yR(0.5);

  return (
    <div style={{ position: 'relative' }}>
      <svg width={w} height={h} style={{ display: 'block' }}>
        {/* rest bands */}
        {sets.map((s, i) => {
          const next = sets[i + 1];
          if (!next) return null;
          return (
            <rect key={`rest${i}`} x={px(s.end)} y={innerT} width={px(next.start) - px(s.end)} height={h - innerT - innerB}
                  fill={dark ? 'rgba(255,255,255,0.025)' : 'rgba(0,0,0,0.025)'}/>
          );
        })}
        {/* gridlines (very faint) */}
        {[0.25, 0.5, 0.75].map((g, i) => (
          <line key={i} x1={innerL} x2={w - innerR} y1={py(g)} y2={py(g)}
                stroke={t.sep} strokeDasharray="0" strokeWidth="0.5"/>
        ))}
        {/* y axis labels — left (HR) */}
        {[
          { v: 0.2, label: '80'  },
          { v: 0.5, label: '120' },
          { v: 0.8, label: '160' },
        ].map((l, i) => (
          <text key={i} x={innerL - 6} y={py(l.v) + 3} textAnchor="end"
                fontFamily={VBT.fontR} fontSize="10" fill={t.secondary} fontWeight="500">{l.label}</text>
        ))}
        {/* y axis labels — right (velocity) */}
        {[
          { v: 0.3, label: '0.4' },
          { v: 0.6, label: '0.7' },
          { v: 0.9, label: '1.0' },
        ].map((l, i) => (
          <text key={i} x={w - innerR + 6} y={py(l.v) + 3} textAnchor="start"
                fontFamily={VBT.fontR} fontSize="10" fill={t.secondary} fontWeight="500">{l.label}</text>
        ))}
        {/* y-axis unit labels */}
        <text x={innerL - 6} y={innerT - 8} textAnchor="end" fontFamily={VBT.fontR} fontSize="9" fill={VBT.data.hr} fontWeight="600" letterSpacing="0.4">BPM</text>
        <text x={w - innerR + 6} y={innerT - 8} textAnchor="start" fontFamily={VBT.fontR} fontSize="9" fill={VBT.data.vel} fontWeight="600" letterSpacing="0.4">M/S</text>
        {/* x-axis labels (time) */}
        {[0, 0.25, 0.5, 0.75, 1].map((p, i) => {
          const m = Math.round(p * 62);
          return <text key={i} x={px(p)} y={h - 12} textAnchor="middle" fontFamily={VBT.fontR} fontSize="10" fill={t.tertiary} fontWeight="500">
            {`${m}m`}
          </text>;
        })}
        {/* HR curve */}
        <path d={hrPath} fill="none" stroke={VBT.data.hr} strokeWidth="1.6" strokeLinejoin="round"/>
        {/* per-set velocity lines */}
        {velSegs.map((pts, i) => (
          <path key={i} fill="none" stroke={VBT.data.vel} strokeWidth="1" strokeOpacity="0.4"
                d={pts.map((p, j) => (j === 0 ? `M${p.x},${p.y}` : `L${p.x},${p.y}`)).join(' ')}/>
        ))}
        {/* velocity dots */}
        {repsAll.map((r, i) => (
          <circle key={i} cx={r.x} cy={r.y} r="2.6" fill={VBT.data.vel} stroke={dark ? '#000' : '#fff'} strokeWidth="0.8"/>
        ))}
        {/* VL warning line */}
        <line x1={innerL} x2={w - innerR} y1={vlY} y2={vlY}
              stroke={VBT.data.vl} strokeWidth="1" strokeDasharray="3 3" opacity="0.7"/>
        <text x={w - innerR - 4} y={vlY - 4} textAnchor="end"
              fontFamily={VBT.fontR} fontSize="9" fill={VBT.data.vl} fontWeight="600" letterSpacing="0.3">VL 25%</text>
        {/* set bands top — colored markers + labels */}
        {sets.map((s, i) => {
          const x1 = px(s.start), x2 = px(s.end);
          return (
            <g key={`band${i}`}>
              <rect x={x1} y={20} width={x2 - x1} height={4} rx="2" fill={s.color}/>
              <text x={(x1 + x2) / 2} y={14} textAnchor="middle"
                    fontFamily={VBT.fontR} fontSize="9" fontWeight="600"
                    fill={t.secondary} letterSpacing="0.2">
                {s.label}
              </text>
            </g>
          );
        })}
        {/* tap popover — anchored on a rep dot */}
        {showPopover && (() => {
          const target = repsAll[7];
          const px0 = target.x, py0 = target.y;
          const pw = 138, ph = 70;
          const px1 = Math.min(w - innerR - pw, Math.max(innerL, px0 - pw / 2));
          const py1 = py0 - ph - 12;
          return (
            <g>
              <circle cx={px0} cy={py0} r="5" fill="none" stroke={VBT.data.vel} strokeWidth="1.5"/>
              <line x1={px0} x2={px0} y1={py0 - 6} y2={py1 + ph} stroke={t.tertiary} strokeWidth="0.5" strokeDasharray="2 2"/>
              <rect x={px1} y={py1} width={pw} height={ph} rx="10" fill={dark ? '#1C1C1E' : '#fff'} stroke={t.sep}/>
              <text x={px1 + 12} y={py1 + 16} fontFamily={VBT.fontR} fontSize="10" fill={t.secondary} fontWeight="500" letterSpacing="0.3">SET 2 · REP 3</text>
              <text x={px1 + 12} y={py1 + 38} fontFamily={VBT.fontR} fontSize="20" fontWeight="600" fill={t.label} letterSpacing="-0.4">0.71 m/s</text>
              <text x={px1 + 12} y={py1 + 56} fontFamily={VBT.fontR} fontSize="11" fill={t.secondary}>VL 8.4% · 125 kg</text>
            </g>
          );
        })()}
      </svg>
    </div>
  );
};

// ── HR zone donut (5 zones)
const HRZoneDonut = ({ dark, size = 120 }) => {
  const t = T(dark);
  const stroke = 14;
  const r = size / 2 - stroke / 2 - 1;
  const c = 2 * Math.PI * r;
  const zones = [
    { pct: 0.10, color: '#5E5CE6', name: 'Z1' },
    { pct: 0.22, color: '#30B0C7', name: 'Z2' },
    { pct: 0.38, color: '#34C759', name: 'Z3' },
    { pct: 0.22, color: '#FF9500', name: 'Z4' },
    { pct: 0.08, color: '#FF3B30', name: 'Z5' },
  ];
  let off = 0;
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
      <svg width={size} height={size}>
        {zones.map((z, i) => {
          const dash = c * z.pct;
          const el = <circle key={i} cx={size/2} cy={size/2} r={r} fill="none"
                             stroke={z.color} strokeWidth={stroke}
                             strokeDasharray={`${dash} ${c - dash}`}
                             strokeDashoffset={-off}
                             transform={`rotate(-90 ${size/2} ${size/2})`}/>;
          off += dash + 2; // 2px gap between segments
          return el;
        })}
        <text x={size/2} y={size/2 - 2} textAnchor="middle" fontFamily={VBT.fontR} fontSize="22" fontWeight="600" fill={t.label} letterSpacing="-0.5">142</text>
        <text x={size/2} y={size/2 + 14} textAnchor="middle" fontFamily={VBT.fontR} fontSize="10" fill={t.secondary} letterSpacing="0.3">AVG BPM</text>
      </svg>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 4, fontSize: 11 }}>
        {zones.map((z, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 6, color: t.secondary, fontFamily: VBT.fontR }}>
            <div style={{ width: 8, height: 8, borderRadius: 2, background: z.color }}/>
            <span style={{ width: 16, color: t.label, fontWeight: 500 }}>{z.name}</span>
            <span>{Math.round(z.pct * 100)}%</span>
          </div>
        ))}
      </div>
    </div>
  );
};

// ── VL bar chart — per set
const VLBars = ({ dark, w = 320, h = 100 }) => {
  const t = T(dark);
  const data = [8, 12, 18, 15, 22, 28]; // VL%
  const max = 35;
  const bw = (w - 40) / data.length - 8;
  return (
    <svg width={w} height={h}>
      {/* threshold line */}
      <line x1={28} x2={w - 12} y1={h - 24 - (25/max) * (h - 40)} y2={h - 24 - (25/max) * (h - 40)} stroke={VBT.data.vl} strokeWidth="1" strokeDasharray="3 3" opacity="0.6"/>
      <text x={w - 14} y={h - 24 - (25/max) * (h - 40) - 4} textAnchor="end" fontFamily={VBT.fontR} fontSize="9" fill={VBT.data.vl} fontWeight="600">25%</text>
      {data.map((v, i) => {
        const bh = (v / max) * (h - 40);
        return (
          <g key={i}>
            <rect x={28 + i * (bw + 8)} y={h - 24 - bh} width={bw} height={bh} rx="3" fill={v >= 25 ? VBT.data.vl : `${VBT.data.vl}80`}/>
            <text x={28 + i * (bw + 8) + bw/2} y={h - 8} textAnchor="middle" fontFamily={VBT.fontR} fontSize="10" fill={t.tertiary} fontWeight="500">{i + 1}</text>
            <text x={28 + i * (bw + 8) + bw/2} y={h - 28 - bh} textAnchor="middle" fontFamily={VBT.fontR} fontSize="9" fill={t.secondary} fontWeight="600">{v}%</text>
          </g>
        );
      })}
      <text x={4} y={14} fontFamily={VBT.fontR} fontSize="10" fill={t.secondary} fontWeight="500" letterSpacing="0.3">VL%</text>
    </svg>
  );
};

// ── LVP / Force-Velocity scatter + regression
const LVPChart = ({ dark, w = 320, h = 220, locked = false }) => {
  const t = T(dark);
  const innerL = 38, innerR = 18, innerT = 16, innerB = 32;
  const X = (kg) => innerL + ((kg - 60) / 100) * (w - innerL - innerR);
  const Y = (vel) => innerT + (1 - (vel - 0.2) / 1.0) * (h - innerT - innerB);
  // synthetic data points: heavier = slower
  const pts = [
    { kg: 80,  v: 0.92 },
    { kg: 95,  v: 0.81 },
    { kg: 110, v: 0.71 },
    { kg: 125, v: 0.59 },
    { kg: 140, v: 0.48 },
    { kg: 155, v: 0.36 },
  ];
  // Fitted line: v = 1.18 - 0.0053 * kg → solve for kg at v=0.3 (V1RM threshold)
  const m = -0.0053, b = 1.18;
  const e1RM = (0.30 - b) / m;  // ≈ 166kg
  const ax = X(60),  ay = Y(b + m * 60);
  const bx = X(170), by = Y(b + m * 170);
  return (
    <svg width={w} height={h}>
      {/* axes */}
      <line x1={innerL} x2={w - innerR} y1={h - innerB} y2={h - innerB} stroke={t.sep} strokeWidth="0.5"/>
      <line x1={innerL} x2={innerL} y1={innerT} y2={h - innerB} stroke={t.sep} strokeWidth="0.5"/>
      {/* y ticks */}
      {[0.3, 0.6, 0.9].map((v, i) => (
        <g key={i}>
          <text x={innerL - 6} y={Y(v) + 3} textAnchor="end" fontFamily={VBT.fontR} fontSize="9" fill={t.secondary}>{v.toFixed(1)}</text>
          <line x1={innerL - 2} x2={innerL} y1={Y(v)} y2={Y(v)} stroke={t.tertiary} strokeWidth="0.5"/>
        </g>
      ))}
      {/* x ticks */}
      {[80, 110, 140, 170].map((k, i) => (
        <text key={i} x={X(k)} y={h - 14} textAnchor="middle" fontFamily={VBT.fontR} fontSize="9" fill={t.secondary}>{k}</text>
      ))}
      {/* V1RM threshold */}
      <line x1={innerL} x2={w - innerR} y1={Y(0.3)} y2={Y(0.3)} stroke={t.tertiary} strokeWidth="0.8" strokeDasharray="3 3"/>
      <text x={w - innerR - 4} y={Y(0.3) - 4} textAnchor="end" fontFamily={VBT.fontR} fontSize="9" fill={t.tertiary} fontWeight="500">V1RM 0.30</text>
      {/* regression */}
      <line x1={ax} y1={ay} x2={bx} y2={by} stroke={VBT.accent} strokeWidth="1.6" opacity={locked ? 0.3 : 1}/>
      {/* scatter */}
      {pts.map((p, i) => (
        <circle key={i} cx={X(p.kg)} cy={Y(p.v)} r="4.5" fill={VBT.data.vel} stroke={dark ? '#000' : '#fff'} strokeWidth="1.4" opacity={locked ? 0.3 : 1}/>
      ))}
      {/* e1RM marker */}
      {!locked && (
        <g>
          <circle cx={X(e1RM)} cy={Y(0.3)} r="6" fill="none" stroke={VBT.accent} strokeWidth="1.5"/>
          <line x1={X(e1RM)} x2={X(e1RM)} y1={Y(0.3)} y2={h - innerB} stroke={VBT.accent} strokeWidth="0.6" strokeDasharray="2 2" opacity="0.5"/>
          <text x={X(e1RM)} y={h - 16} textAnchor="middle" fontFamily={VBT.fontR} fontSize="10" fill={VBT.accent} fontWeight="600">e1RM</text>
        </g>
      )}
      {/* axis labels */}
      <text x={4} y={innerT + 4} fontFamily={VBT.fontR} fontSize="9" fill={t.secondary} fontWeight="500" letterSpacing="0.3">M/S</text>
      <text x={w - innerR} y={h - 2} textAnchor="end" fontFamily={VBT.fontR} fontSize="9" fill={t.secondary} fontWeight="500" letterSpacing="0.3">KG</text>
    </svg>
  );
};

// ── e1RM trend line (large)
const TrendLine = ({ dark, w = 358, h = 240, color = VBT.accent, points }) => {
  const t = T(dark);
  const innerL = 38, innerR = 16, innerT = 16, innerB = 30;
  const data = points || [
    { d:  0, v: 152 }, { d:  6, v: 154 }, { d: 12, v: 153 }, { d: 18, v: 158 },
    { d: 24, v: 160 }, { d: 30, v: 159 }, { d: 36, v: 162 }, { d: 42, v: 165 },
    { d: 48, v: 164 }, { d: 54, v: 168 }, { d: 60, v: 170 }, { d: 66, v: 169 },
    { d: 72, v: 173 }, { d: 78, v: 176 }, { d: 84, v: 175 }, { d: 90, v: 178 },
  ];
  const max = 185, min = 145;
  const X = (d) => innerL + (d / 90) * (w - innerL - innerR);
  const Y = (v) => innerT + (1 - (v - min) / (max - min)) * (h - innerT - innerB);
  // smoothed regression line
  const reg = data.map(d => ({ d: d.d, v: 152 + d.d * 0.30 }));
  return (
    <svg width={w} height={h}>
      {/* gridlines */}
      {[155, 165, 175].map((v, i) => (
        <g key={i}>
          <line x1={innerL} x2={w - innerR} y1={Y(v)} y2={Y(v)} stroke={t.sep} strokeWidth="0.5"/>
          <text x={innerL - 6} y={Y(v) + 3} textAnchor="end" fontFamily={VBT.fontR} fontSize="10" fill={t.secondary} fontWeight="500">{v}</text>
        </g>
      ))}
      {/* x ticks */}
      {[0, 30, 60, 90].map((d, i) => (
        <text key={i} x={X(d)} y={h - 12} textAnchor="middle" fontFamily={VBT.fontR} fontSize="10" fill={t.tertiary} fontWeight="500">{`${d}d`}</text>
      ))}
      {/* regression band (subtle) */}
      <path
        d={`${reg.map((p, i) => (i === 0 ? `M${X(p.d)},${Y(p.v + 4)}` : `L${X(p.d)},${Y(p.v + 4)}`)).join(' ')}
            ${reg.slice().reverse().map(p => `L${X(p.d)},${Y(p.v - 4)}`).join(' ')} Z`}
        fill={color} opacity="0.06"/>
      {/* connecting line */}
      <path d={data.map((p, i) => (i === 0 ? `M${X(p.d)},${Y(p.v)}` : `L${X(p.d)},${Y(p.v)}`)).join(' ')}
            fill="none" stroke={color} strokeWidth="1.2" opacity="0.45"/>
      {/* dots */}
      {data.map((p, i) => (
        <circle key={i} cx={X(p.d)} cy={Y(p.v)} r="3" fill={color} stroke={dark ? '#000' : '#fff'} strokeWidth="1"/>
      ))}
      {/* y axis label */}
      <text x={4} y={innerT + 4} fontFamily={VBT.fontR} fontSize="10" fill={t.secondary} fontWeight="500" letterSpacing="0.3">e1RM · kg</text>
    </svg>
  );
};

Object.assign(window, { ReadinessRing, MiniMetric, Heatmap, Spark, TimelineChart, HRZoneDonut, VLBars, LVPChart, TrendLine });

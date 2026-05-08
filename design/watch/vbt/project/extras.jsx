// VBTrainer · 附加界面：Widget / Complications / 流程图 / 设计原则

// ──────────────────────────────────────────────────────────────
// Smart Stack Widget — iPhone Lock Screen / Smart Stack 训练中状态
// 标准 Smart Stack 尺寸：约 358×100 (system small) -> 这里设计为 medium 320×80
// ──────────────────────────────────────────────────────────────
function SmartStackWidget() {
  return (
    <div style={{
      width: 720, height: 170, borderRadius: 28,
      background: 'rgba(28,28,30,0.92)',
      backdropFilter: 'blur(20px)',
      padding: 22, display:'flex', alignItems:'center', gap: 22,
      fontFamily: T.font, color: T.fg, position:'relative',
      overflow:'hidden',
    }}>
      {/* Live indicator + label */}
      <div style={{ display:'flex', flexDirection:'column', justifyContent:'center', gap: 8, minWidth: 180 }}>
        <div style={{ display:'flex', alignItems:'center', gap: 8 }}>
          <div style={{ width: 10, height: 10, borderRadius:'50%', background: T.orange }}/>
          <Label size={20} color={T.orange}>训练中 · LIVE</Label>
        </div>
        <div style={{ fontSize: 36, fontWeight: 700, lineHeight: 1.05 }}>深蹲</div>
        <div style={{ fontSize: 22, color: T.sub, fontWeight: 500 }}>100kg · 第 2 组</div>
      </div>

      {/* Velocity */}
      <div style={{ flex: 1, textAlign:'center' }}>
        <Label size={18}>上一 REP</Label>
        <div style={{ fontSize: 78, fontWeight: 800, lineHeight: 1.05,
          letterSpacing: '-0.05em', color: T.green,
          fontVariantNumeric:'tabular-nums', marginTop: 2 }}>
          0.62
        </div>
        <div style={{ fontSize: 18, color: T.sub, marginTop: -2 }}>m/s</div>
      </div>

      {/* Reps + HR */}
      <div style={{ minWidth: 140, display:'flex', flexDirection:'column', gap: 12, alignItems:'flex-end' }}>
        <div style={{ display:'flex', alignItems:'center', gap: 8 }}>
          <Label size={18}>REPS</Label>
          <span style={{ fontSize: 28, fontWeight: 700, fontVariantNumeric:'tabular-nums' }}>
            5<span style={{ color: T.sub, fontWeight: 500 }}>/8</span>
          </span>
        </div>
        <div style={{ display:'flex', alignItems:'center', gap: 8 }}>
          {G.heart(20, T.red)}
          <span style={{ fontSize: 28, fontWeight: 700, fontVariantNumeric:'tabular-nums' }}>142</span>
        </div>
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// Complications — circular / rectangular / corner
// (Drawn on standalone watch face background tiles for context.)
// ──────────────────────────────────────────────────────────────
function CompCircular() {
  return (
    <div style={{
      width: 120, height: 120, borderRadius: '50%',
      background: T.bg, position:'relative',
      display:'flex', alignItems:'center', justifyContent:'center',
      fontFamily: T.font, color: T.fg,
    }}>
      <Ring size={120} stroke={6} progress={0.62} color={T.orange}/>
      <div style={{ textAlign:'center', position:'relative', zIndex: 1 }}>
        <div style={{ fontSize: 32, fontWeight: 800, lineHeight: 1,
          letterSpacing:'-0.04em', fontVariantNumeric:'tabular-nums' }}>0.62</div>
        <div style={{ fontSize: 10, color: T.sub, fontWeight: 600,
          letterSpacing:'0.08em', textTransform:'uppercase', marginTop: 2 }}>m/s</div>
      </div>
    </div>
  );
}

function CompRectangular() {
  return (
    <div style={{
      width: 320, height: 100, borderRadius: 18,
      background: T.bg, padding: '14px 18px',
      fontFamily: T.font, color: T.fg, display:'flex',
      flexDirection:'column', justifyContent:'space-between',
    }}>
      <div style={{ display:'flex', alignItems:'center', gap: 8 }}>
        {G.bolt(16, T.orange)}
        <Label size={14} color={T.orange}>VBT · 深蹲</Label>
      </div>
      <div style={{ display:'flex', justifyContent:'space-between', alignItems:'baseline' }}>
        <div>
          <span style={{ fontSize: 36, fontWeight: 800, letterSpacing:'-0.04em',
            fontVariantNumeric:'tabular-nums' }}>0.62</span>
          <span style={{ fontSize: 16, color: T.sub, marginLeft: 4 }}>m/s</span>
        </div>
        <div style={{ fontSize: 18, fontWeight: 600, color: T.sub }}>
          5/8 · 142 bpm
        </div>
      </div>
    </div>
  );
}

function CompCorner() {
  // Designed for the bottom-left curved corner — number anchored to inner edge
  return (
    <div style={{
      width: 140, height: 140, position:'relative',
      borderRadius: '0 100% 0 0',
      background: T.bg,
      fontFamily: T.font,
    }}>
      <div style={{ position:'absolute', left: 14, bottom: 14 }}>
        <div style={{ fontSize: 28, fontWeight: 800, color: T.orange,
          letterSpacing:'-0.04em', lineHeight: 1, fontVariantNumeric:'tabular-nums' }}>
          0.62
        </div>
        <div style={{ fontSize: 11, fontWeight: 600, color: T.sub,
          letterSpacing:'0.06em', textTransform:'uppercase', marginTop: 2 }}>
          MV · REP 5
        </div>
      </div>
      {/* curved arc */}
      <svg width="140" height="140" viewBox="0 0 140 140" style={{ position:'absolute', inset: 0 }}>
        <path d="M 8 132 A 124 124 0 0 1 132 8" stroke={T.orange} strokeWidth="3"
          strokeLinecap="round" fill="none" strokeDasharray="200" strokeDashoffset="76"/>
      </svg>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// Spec / context cards — these go in their own section
// ──────────────────────────────────────────────────────────────
const cardBase = {
  background: '#fafaf7', borderRadius: 14, padding: 28,
  fontFamily: 'ui-sans-serif, -apple-system, "Helvetica Neue", system-ui, sans-serif',
  color: '#1c1c1e', boxShadow: '0 1px 0 rgba(0,0,0,0.04)',
  border: '1px solid rgba(0,0,0,0.05)',
};

function PaletteCard() {
  const swatches = [
    ['Background', '#000000', '纯黑 · OLED'],
    ['Foreground', '#FFFFFF', '主文字'],
    ['Sub',        '#8E8E93', '次文字 / systemGray'],
    ['Accent',     '#FF9500', '主色 / 运动'],
    ['Success',    '#30D158', '达标 / 优秀'],
    ['Warn',       '#FF453A', '未达标 / 结束'],
  ];
  return (
    <div style={{ ...cardBase, width: 480 }}>
      <div style={{ fontSize: 14, fontWeight: 600, color:'#8E8E93', letterSpacing:'0.08em',
        textTransform:'uppercase' }}>Palette</div>
      <div style={{ fontSize: 26, fontWeight: 600, marginTop: 4 }}>6 颜色，仅此而已</div>
      <div style={{ marginTop: 18, display:'flex', flexDirection:'column', gap: 10 }}>
        {swatches.map(([n, h, d]) => (
          <div key={h} style={{ display:'flex', alignItems:'center', gap: 14 }}>
            <div style={{ width: 36, height: 36, borderRadius: 8, background: h,
              boxShadow: 'inset 0 0 0 1px rgba(0,0,0,0.08)' }}/>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15, fontWeight: 600 }}>{n}</div>
              <div style={{ fontSize: 13, color:'#666', fontFamily:'ui-monospace,Menlo,monospace' }}>{h}</div>
            </div>
            <div style={{ fontSize: 13, color:'#666' }}>{d}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function TypeCard() {
  return (
    <div style={{ ...cardBase, width: 540 }}>
      <div style={{ fontSize: 14, fontWeight: 600, color:'#8E8E93', letterSpacing:'0.08em',
        textTransform:'uppercase' }}>Type Scale</div>
      <div style={{ fontSize: 26, fontWeight: 600, marginTop: 4 }}>SF Pro Rounded · 5 级</div>
      <div style={{ marginTop: 18, display:'flex', flexDirection:'column', gap: 14 }}>
        {[
          ['DATA · XL',  '0.62', '90pt / 800',  '训练中速度 / 心率'],
          ['DATA · L',   '142',  '50pt / 700',  '组间倒计时 / 重量'],
          ['DATA · M',   '32',   '32pt / 700',  '总结数据 / Rep 计数'],
          ['TITLE',      '深蹲',  '18pt / 600',  '动作名 / 屏幕标题'],
          ['LABEL',      'REP 5','13pt / 500 +0.5', '全大写 + 字间距'],
        ].map(([t, s, m, d]) => (
          <div key={t} style={{ display:'flex', alignItems:'baseline', gap: 18 }}>
            <div style={{ width: 110, fontSize: 12, fontWeight: 600, color:'#8E8E93',
              letterSpacing:'0.08em', textTransform:'uppercase' }}>{t}</div>
            <div style={{ flex: 1, color:'#000' }}>
              <span style={{ fontSize: t==='DATA · XL' ? 56 : t==='DATA · L' ? 38 : t==='DATA · M' ? 28 : t==='TITLE' ? 22 : 16,
                fontWeight: t==='LABEL' ? 500 : 700,
                letterSpacing: t==='LABEL' ? '0.06em' : '-0.02em',
                textTransform: t==='LABEL' ? 'uppercase' : 'none',
                fontFamily: T.font }}>{s}</span>
            </div>
            <div style={{ width: 110, fontSize: 12, color:'#666',
              fontFamily:'ui-monospace,Menlo,monospace', textAlign:'right' }}>{m}</div>
            <div style={{ width: 130, fontSize: 12, color:'#666', textAlign:'right' }}>{d}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function HapticsCard() {
  const rows = [
    ['优秀',   '.success',     '双击',  '数字闪绿 + 上箭头微动画', T.green],
    ['达标',   '.click',       '单击',  '数字呈白色稳定',         T.fg],
    ['偏慢',   '.directionUp', '长震',  '数字闪橙',              T.orange],
    ['未达标', '.failure',     '三击',  '数字闪红 + 下箭头',      T.red],
    ['倒计时', '.start',       '尖音',  '全屏短暂泛白 0.2s',      T.fg],
  ];
  return (
    <div style={{ ...cardBase, width: 700 }}>
      <div style={{ fontSize: 14, fontWeight: 600, color:'#8E8E93', letterSpacing:'0.08em',
        textTransform:'uppercase' }}>Haptics × Visual</div>
      <div style={{ fontSize: 26, fontWeight: 600, marginTop: 4 }}>触感 + 视觉 · 同步设计</div>
      <div style={{ marginTop: 18 }}>
        <div style={{ display:'grid', gridTemplateColumns:'90px 160px 70px 1fr',
          gap: 12, fontSize: 12, fontWeight: 600, color:'#8E8E93',
          letterSpacing:'0.06em', textTransform:'uppercase', paddingBottom: 8,
          borderBottom:'1px solid rgba(0,0,0,0.08)' }}>
          <div>状态</div><div>WKHapticType</div><div>节奏</div><div>视觉</div>
        </div>
        {rows.map((r, i) => (
          <div key={r[0]} style={{ display:'grid', gridTemplateColumns:'90px 160px 70px 1fr',
            gap: 12, padding: '10px 0', alignItems:'center',
            borderBottom: i<rows.length-1 ? '1px solid rgba(0,0,0,0.05)' : 'none' }}>
            <div style={{ fontWeight: 600, color: r[4] === T.fg ? '#000' : r[4] }}>{r[0]}</div>
            <div style={{ fontFamily:'ui-monospace,Menlo,monospace', fontSize: 13 }}>{r[1]}</div>
            <div style={{ fontSize: 13, color:'#666' }}>{r[2]}</div>
            <div style={{ fontSize: 14 }}>{r[3]}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function GestureCard() {
  const rows = [
    ['Digital Crown',   '调节数值（重量、组数）；列表中滚动；倒计时跳过秒数（每齿 −5s）'],
    ['轻点全屏',       '训练中切换显示模式：速度 ↔ VL% ↔ 心率（除"结束本组"按钮）'],
    ['长按 1.5s',       '所有屏幕：呼出"暂停 · 跳过 · 结束训练"安全菜单'],
    ['左右滑动',       '组间休息：左滑跳过 / 右滑 +30s'],
    ['抬腕',            '激活当前训练页（跳过表盘），自动唤醒到上一次状态'],
    ['Side Button',     '紧急中止 → 回到首页（数据自动保存为草稿）'],
  ];
  return (
    <div style={{ ...cardBase, width: 700 }}>
      <div style={{ fontSize: 14, fontWeight: 600, color:'#8E8E93', letterSpacing:'0.08em',
        textTransform:'uppercase' }}>Gestures</div>
      <div style={{ fontSize: 26, fontWeight: 600, marginTop: 4 }}>单手操作语义</div>
      <div style={{ marginTop: 16 }}>
        {rows.map((r, i) => (
          <div key={r[0]} style={{ display:'grid', gridTemplateColumns:'160px 1fr',
            gap: 18, padding: '12px 0', alignItems:'baseline',
            borderBottom: i<rows.length-1 ? '1px solid rgba(0,0,0,0.05)' : 'none' }}>
            <div style={{ fontSize: 14, fontWeight: 600, color:'#000' }}>{r[0]}</div>
            <div style={{ fontSize: 14, color:'#333', lineHeight: 1.5 }}>{r[1]}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function PrinciplesCard() {
  const items = [
    ['一屏一信息', '巨字主导。其他都是辅助。让训练者抬腕 0.5 秒看到关键数。'],
    ['类型即层级', '不靠卡片、不靠分割线。字号字重 + 留白构建结构。'],
    ['色彩传状态', '颜色只代表"达标 / 警告"。装饰用颜色就是噪音。'],
    ['触感即文字', '震动是另一种语言，与视觉同步发生。手腕震动比眼睛更快。'],
    ['永远黑底',  'OLED 省电，户外可读。常亮模式不是另一套设计，是同一套设计的低功耗状态。'],
  ];
  return (
    <div style={{ ...cardBase, width: 700, background: '#1c1c1e', color: T.fg, border: 'none' }}>
      <div style={{ fontSize: 14, fontWeight: 600, color: T.orange, letterSpacing:'0.08em',
        textTransform:'uppercase' }}>5 Principles</div>
      <div style={{ fontSize: 30, fontWeight: 700, marginTop: 4, color: T.fg }}>
        Less, but better.
      </div>
      <div style={{ marginTop: 22 }}>
        {items.map((it, i) => (
          <div key={it[0]} style={{ display:'flex', gap: 18, padding: '14px 0',
            borderBottom: i<items.length-1 ? '1px solid rgba(255,255,255,0.08)' : 'none' }}>
            <div style={{ fontSize: 36, fontWeight: 800, color: T.orange,
              letterSpacing:'-0.04em', minWidth: 44, fontVariantNumeric:'tabular-nums' }}>
              {String(i+1).padStart(2,'0')}
            </div>
            <div>
              <div style={{ fontSize: 22, fontWeight: 600 }}>{it[0]}</div>
              <div style={{ fontSize: 15, color: T.sub, marginTop: 4, lineHeight: 1.5 }}>{it[1]}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function SpecCard({ title, lines }) {
  return (
    <div style={{ ...cardBase, width: 380, background:'#fff' }}>
      <div style={{ fontSize: 12, fontWeight: 600, color:'#8E8E93', letterSpacing:'0.08em',
        textTransform:'uppercase' }}>{title}</div>
      <div style={{ marginTop: 10 }}>
        {lines.map((l, i) => (
          <div key={i} style={{ fontSize: 13, color:'#333', padding:'5px 0',
            borderBottom: i<lines.length-1 ? '1px solid rgba(0,0,0,0.04)' : 'none',
            display:'flex', justifyContent:'space-between', gap: 14 }}>
            <span style={{ color:'#000', fontWeight: 500 }}>{l[0]}</span>
            <span style={{ color:'#666', fontFamily:'ui-monospace,Menlo,monospace', textAlign:'right' }}>{l[1]}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function SizingCard() {
  return (
    <div style={{ ...cardBase, width: 720 }}>
      <div style={{ fontSize: 14, fontWeight: 600, color:'#8E8E93', letterSpacing:'0.08em',
        textTransform:'uppercase' }}>Sizing</div>
      <div style={{ fontSize: 26, fontWeight: 600, marginTop: 4 }}>三尺寸自适应规则</div>
      <div style={{ marginTop: 18, display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap: 18 }}>
        {[
          { mm: '41mm', px: '352×430', scale: '0.89×', note: '基准缩放，最小留白 14pt' },
          { mm: '45mm', px: '396×484', scale: '1.00×', note: '设计基准，全部数字按 pt 标注', hl: true },
          { mm: '49mm', px: '410×502', scale: '1.04×', note: 'Ultra · 增加 2pt 内边距，按钮高 56pt' },
        ].map(s => (
          <div key={s.mm} style={{
            padding: 18, borderRadius: 12,
            background: s.hl ? '#000' : 'transparent',
            color: s.hl ? T.fg : '#000',
            border: s.hl ? 'none' : '1px solid rgba(0,0,0,0.08)',
          }}>
            <div style={{ fontSize: 28, fontWeight: 700, fontFamily: T.font }}>{s.mm}</div>
            <div style={{ fontSize: 14, color: s.hl ? T.sub : '#666', marginTop: 2,
              fontFamily:'ui-monospace,Menlo,monospace' }}>{s.px}</div>
            <div style={{ fontSize: 24, fontWeight: 700, marginTop: 14,
              color: s.hl ? T.orange : '#000' }}>{s.scale}</div>
            <div style={{ fontSize: 12, color: s.hl ? T.sub : '#666', marginTop: 8, lineHeight: 1.5 }}>
              {s.note}
            </div>
          </div>
        ))}
      </div>
      <div style={{ marginTop: 18, padding: 14, background:'rgba(255,149,0,0.08)',
        borderRadius: 10, fontSize: 13, color:'#444' }}>
        <strong style={{ color:'#000' }}>规则：</strong>
        所有数字字号、间距按 45mm pt 标注 · 41mm 整体缩放 0.89× · 49mm 缩放 1.04× · 按钮最小 44pt 不缩放
      </div>
    </div>
  );
}

// Flow diagram — SVG showing screen transitions
function FlowDiagram() {
  const node = (x, y, label, accent) => ({ x, y, label, accent });
  const nodes = [
    node(60,  60,  'Home',       T.orange),  // 0
    node(60,  200, 'Readiness',  T.green),   // 1
    node(60,  340, 'CMJ',        T.orange),  // 2
    node(280, 200, '选动作',      T.fg),     // 3
    node(500, 200, '输入重量',    T.fg),     // 4
    node(720, 200, '训练中',      T.orange), // 5
    node(720, 340, '组间休息',    T.fg),     // 6
    node(940, 200, '总结',        T.green),  // 7
    node(940, 60,  '计划进度',    T.fg),     // 8
  ];
  const W2 = 1100, H2 = 460;
  const N = (n, idx) => (
    <g key={idx} transform={`translate(${n.x},${n.y})`}>
      <rect x="0" y="0" width="160" height="60" rx="14" fill="#000" stroke={n.accent} strokeWidth="1.5"/>
      <text x="80" y="38" fill={T.fg} fontFamily={T.font} fontSize="20" fontWeight="600"
        textAnchor="middle">{n.label}</text>
    </g>
  );
  const edge = (a, b, label, dashed) => {
    const ax = nodes[a].x + 160, ay = nodes[a].y + 30;
    const bx = nodes[b].x,        by = nodes[b].y + 30;
    return (
      <g key={`${a}-${b}-${label||''}`}>
        <path d={`M ${ax} ${ay} C ${(ax+bx)/2} ${ay}, ${(ax+bx)/2} ${by}, ${bx} ${by}`}
          stroke="rgba(255,255,255,0.35)" strokeWidth="1.5" fill="none"
          strokeDasharray={dashed?'4 4':null} markerEnd="url(#arr)"/>
        {label && (
          <text x={(ax+bx)/2} y={(ay+by)/2 - 6} fontSize="11" fill={T.sub}
            fontFamily={T.font} textAnchor="middle">{label}</text>
        )}
      </g>
    );
  };
  // back edge (rest -> live)
  return (
    <div style={{ ...cardBase, width: W2 + 60, padding: 30, background:'#0d0d0f', color: T.fg }}>
      <div style={{ fontSize: 14, fontWeight: 600, color: T.orange, letterSpacing:'0.08em',
        textTransform:'uppercase' }}>Flow</div>
      <div style={{ fontSize: 26, fontWeight: 600, marginTop: 4, marginBottom: 18 }}>屏幕跳转</div>
      <svg width={W2} height={H2}>
        <defs>
          <marker id="arr" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto">
            <path d="M0 0 L8 4 L0 8 Z" fill="rgba(255,255,255,0.5)"/>
          </marker>
        </defs>
        {/* edges */}
        {edge(0, 1, '抬腕扫一眼')}
        {edge(0, 3, '点击开始 →')}
        {edge(1, 3, '✓ 准备好')}
        {edge(2, 3, 'CMJ 完成')}
        {edge(3, 4, '选定动作')}
        {edge(4, 5, '确认重量')}
        {edge(5, 6, '"结束本组"')}
        {edge(6, 5, '休息结束 / +重量', true)}
        {edge(5, 7, '所有组完成')}
        {edge(7, 8, '查看下一动作')}
        {edge(8, 3, '继续 →', true)}
        {nodes.map(N)}
      </svg>
      <div style={{ marginTop: 12, fontSize: 13, color: T.sub, display:'flex', gap: 22 }}>
        <span><span style={{ display:'inline-block', width:12, borderTop:'1.5px solid rgba(255,255,255,0.5)', verticalAlign:'middle', marginRight:6 }}/>主路径</span>
        <span><span style={{ display:'inline-block', width:12, borderTop:'1.5px dashed rgba(255,255,255,0.5)', verticalAlign:'middle', marginRight:6 }}/>循环 / 自动</span>
      </div>
    </div>
  );
}

Object.assign(window, {
  SmartStackWidget, CompCircular, CompRectangular, CompCorner,
  PaletteCard, TypeCard, HapticsCard, GestureCard, PrinciplesCard,
  SizingCard, SpecCard, FlowDiagram,
});

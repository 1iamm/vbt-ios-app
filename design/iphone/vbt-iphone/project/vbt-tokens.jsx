// VBT Design Tokens + primitives + tiny chart kit.
// Single source of truth. All screens consume from here.

const VBT = {
  // ── Core neutrals (light)
  L: {
    bg:       '#FFFFFF',           // systemBackground
    grouped:  '#F2F2F7',           // systemGroupedBackground
    card:     '#FFFFFF',
    raised:   '#FFFFFF',
    label:    '#000000',
    secondary:'rgba(60,60,67,0.60)',
    tertiary: 'rgba(60,60,67,0.30)',
    quaternary:'rgba(60,60,67,0.18)',
    sep:      'rgba(60,60,67,0.18)',
    fill:     'rgba(120,120,128,0.12)',
    fill2:    'rgba(120,120,128,0.08)',
  },
  // ── Core neutrals (dark — true OLED black)
  D: {
    bg:       '#000000',
    grouped:  '#000000',
    card:     '#1C1C1E',
    raised:   '#2C2C2E',
    label:    '#FFFFFF',
    secondary:'rgba(235,235,245,0.60)',
    tertiary: 'rgba(235,235,245,0.30)',
    quaternary:'rgba(235,235,245,0.18)',
    sep:      'rgba(84,84,88,0.65)',
    fill:     'rgba(120,120,128,0.24)',
    fill2:    'rgba(120,120,128,0.16)',
  },
  // ── Accent (training)
  accent: '#FF9500',
  // ── Data palette — only 5 colors, no others
  data: {
    hr:  '#FF3B30',  // 心率
    vel: '#0A84FF',  // 速度
    vol: '#FF9500',  // 训练量
    vl:  '#BF5AF2',  // VL%
    slp: '#5E5CE6',  // 睡眠
  },
  // ── Type
  font:  '-apple-system, "SF Pro Text", "SF Pro", system-ui, sans-serif',
  fontR: '"SF Pro Rounded", -apple-system, system-ui, sans-serif',  // numerics
  fontM: 'ui-monospace, "SF Mono", Menlo, monospace',
  // ── Spacing scale (4-pt)
  s: { xs: 4, sm: 8, md: 12, lg: 16, xl: 20, xxl: 24, xxxl: 32 },
  r: { sm: 8, md: 12, lg: 16, xl: 20, card: 14 },
};
const T = (dark) => dark ? VBT.D : VBT.L;

// ── Tiny SF-Symbol-ish icons (custom strokes; not asset copies)
const Icon = ({ name, size = 22, color = 'currentColor', stroke = 1.7 }) => {
  const p = { width: size, height: size, viewBox: '0 0 24 24', fill: 'none',
              stroke: color, strokeWidth: stroke, strokeLinecap: 'round',
              strokeLinejoin: 'round' };
  switch (name) {
    case 'today':    return (<svg {...p}><circle cx="12" cy="12" r="9"/><path d="M12 3a9 9 0 0 0 0 18"/></svg>);
    case 'train':    return (<svg {...p}><path d="M3 12h2M19 12h2M7 6v12M17 6v12M9 9h6v6H9z"/></svg>);
    case 'history':  return (<svg {...p}><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>);
    case 'profile':  return (<svg {...p}><circle cx="12" cy="9" r="3.5"/><path d="M5 20c1.5-3.5 4.5-5 7-5s5.5 1.5 7 5"/></svg>);
    case 'plus':     return (<svg {...p}><path d="M12 5v14M5 12h14"/></svg>);
    case 'chev-r':   return (<svg {...p}><path d="M9 5l7 7-7 7"/></svg>);
    case 'chev-l':   return (<svg {...p}><path d="M15 5l-7 7 7 7"/></svg>);
    case 'chev-d':   return (<svg {...p}><path d="M5 9l7 7 7-7"/></svg>);
    case 'chev-u':   return (<svg {...p}><path d="M5 15l7-7 7 7"/></svg>);
    case 'arrow-up': return (<svg {...p}><path d="M12 19V5M6 11l6-6 6 6"/></svg>);
    case 'arrow-dn': return (<svg {...p}><path d="M12 5v14M6 13l6 6 6-6"/></svg>);
    case 'share':    return (<svg {...p}><path d="M12 15V3M8 7l4-4 4 4M5 12v7h14v-7"/></svg>);
    case 'more':     return (<svg {...p}><circle cx="6" cy="12" r="1.3" fill={color} stroke="none"/><circle cx="12" cy="12" r="1.3" fill={color} stroke="none"/><circle cx="18" cy="12" r="1.3" fill={color} stroke="none"/></svg>);
    case 'lock':     return (<svg {...p}><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 1 1 8 0v3"/></svg>);
    case 'heart':    return (<svg {...p}><path d="M12 20s-7-4.5-7-10a4 4 0 0 1 7-2.5A4 4 0 0 1 19 10c0 5.5-7 10-7 10z"/></svg>);
    case 'bolt':     return (<svg {...p}><path d="M13 2L4 14h7l-1 8 9-12h-7l1-8z" fill={color} stroke="none"/></svg>);
    case 'bed':      return (<svg {...p}><path d="M3 17V7M21 17v-4a3 3 0 0 0-3-3H8M3 13h18"/></svg>);
    case 'pulse':    return (<svg {...p}><path d="M3 12h4l2-5 4 10 2-5h6"/></svg>);
    case 'cal':      return (<svg {...p}><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>);
    case 'watch':    return (<svg {...p}><rect x="6" y="6" width="12" height="12" rx="3"/><path d="M9 6V3h6v3M9 18v3h6v-3"/></svg>);
    case 'gear':     return (<svg {...p}><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 0 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1A2 2 0 1 1 4.3 17l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 0 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8L4.2 7A2 2 0 1 1 7 4.2l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 0 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1A2 2 0 1 1 19.7 7l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 0 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></svg>);
    case 'list':     return (<svg {...p}><path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"/></svg>);
    case 'expand':   return (<svg {...p}><path d="M4 14v6h6M20 10V4h-6M4 20l7-7M20 4l-7 7"/></svg>);
    case 'check':    return (<svg {...p}><path d="M5 13l4 4L19 7"/></svg>);
    case 'circle':   return (<svg {...p}><circle cx="12" cy="12" r="9"/></svg>);
    case 'flame':    return (<svg {...p}><path d="M12 2c0 4-5 4-5 10a5 5 0 0 0 10 0c0-2-1-3-1-5 0 0-1 1-2 1 0-3-2-3-2-6z"/></svg>);
    case 'square':   return (<svg {...p}><rect x="4" y="4" width="16" height="16" rx="2"/></svg>);
    case 'drag':     return (<svg {...p}><circle cx="9" cy="6" r="1.4" fill={color} stroke="none"/><circle cx="15" cy="6" r="1.4" fill={color} stroke="none"/><circle cx="9" cy="12" r="1.4" fill={color} stroke="none"/><circle cx="15" cy="12" r="1.4" fill={color} stroke="none"/><circle cx="9" cy="18" r="1.4" fill={color} stroke="none"/><circle cx="15" cy="18" r="1.4" fill={color} stroke="none"/></svg>);
    default: return null;
  }
};

// ── Status Bar (clone of starter, but lets us drop into custom layouts)
const StatusBar = ({ dark = false, time = '9:41' }) => {
  const c = dark ? '#fff' : '#000';
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '14px 30px 6px', height: 54, boxSizing: 'border-box',
      fontFamily: VBT.font, fontWeight: 600, fontSize: 16, color: c,
      position: 'relative', zIndex: 5,
    }}>
      <div style={{ width: 100 }}>{time}</div>
      <div style={{ width: 110, height: 32 }}/>{/* dyn island spacer */}
      <div style={{ width: 100, display: 'flex', justifyContent: 'flex-end', gap: 6, alignItems: 'center' }}>
        <svg width="17" height="11" viewBox="0 0 17 11"><rect x="0" y="6" width="2.6" height="4.5" rx=".7" fill={c}/><rect x="4.4" y="4" width="2.6" height="6.5" rx=".7" fill={c}/><rect x="8.8" y="2" width="2.6" height="8.5" rx=".7" fill={c}/><rect x="13.2" y="0" width="2.6" height="10.5" rx=".7" fill={c}/></svg>
        <svg width="22" height="11" viewBox="0 0 22 11"><rect x="0.5" y="0.5" width="19" height="10" rx="3" stroke={c} fill="none" opacity=".4"/><rect x="2" y="2" width="16" height="7" rx="1.5" fill={c}/><rect x="20" y="3.5" width="1.5" height="4" rx=".5" fill={c} opacity=".4"/></svg>
      </div>
    </div>
  );
};

// ── Tab bar — bottom (4 tabs)
const TabBar = ({ dark = false, active = 0 }) => {
  const t = T(dark);
  const items = [
    { name: 'today',    label: '今天' },
    { name: 'train',    label: '训练' },
    { name: 'history',  label: '历史' },
    { name: 'profile',  label: '我的' },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      paddingBottom: 28, paddingTop: 8,
      background: dark ? 'rgba(0,0,0,0.85)' : 'rgba(255,255,255,0.85)',
      backdropFilter: 'blur(20px) saturate(180%)',
      WebkitBackdropFilter: 'blur(20px) saturate(180%)',
      borderTop: `0.5px solid ${t.sep}`,
      display: 'flex', justifyContent: 'space-around',
      fontFamily: VBT.font, zIndex: 40,
    }}>
      {items.map((it, i) => {
        const on = i === active;
        const c = on ? VBT.accent : t.secondary;
        return (
          <div key={it.name} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center',
            gap: 3, color: c,
          }}>
            <Icon name={it.name} size={26} color={c} stroke={on ? 2.1 : 1.7}/>
            <div style={{ fontSize: 10, fontWeight: 500, letterSpacing: 0.05 }}>{it.label}</div>
          </div>
        );
      })}
    </div>
  );
};

// ── Reusable wrappers
const Screen = ({ dark = false, children, scrollable = true, hideTabs = false, padBottom = true }) => {
  const t = T(dark);
  return (
    <div style={{
      width: 402, height: 874, background: dark ? VBT.D.grouped : VBT.L.grouped,
      borderRadius: 48, overflow: 'hidden', position: 'relative',
      fontFamily: VBT.font, color: t.label,
      boxShadow: dark
        ? '0 30px 60px rgba(0,0,0,0.45), 0 0 0 1px rgba(0,0,0,0.6)'
        : '0 30px 60px rgba(0,0,0,0.13), 0 0 0 1px rgba(0,0,0,0.10)',
    }}>
      {/* dyn island */}
      <div style={{
        position: 'absolute', top: 11, left: '50%', transform: 'translateX(-50%)',
        width: 126, height: 37, borderRadius: 24, background: '#000', zIndex: 50,
      }} />
      <StatusBar dark={dark}/>
      <div style={{
        position: 'absolute', top: 54, left: 0, right: 0,
        bottom: hideTabs ? 0 : (padBottom ? 83 : 0),
        overflow: scrollable ? 'auto' : 'hidden',
      }}>
        {children}
      </div>
      {!hideTabs && <TabBar dark={dark} active={0}/>}
      {/* home indicator */}
      <div style={{
        position: 'absolute', bottom: 8, left: '50%', transform: 'translateX(-50%)',
        width: 139, height: 5, borderRadius: 100,
        background: dark ? 'rgba(255,255,255,0.85)' : 'rgba(0,0,0,0.35)', zIndex: 70,
      }}/>
    </div>
  );
};

// Large title nav bar (custom — no glass pills)
const NavLarge = ({ title, dark, trailing = null, leading = null, eyebrow = null }) => {
  const t = T(dark);
  return (
    <div style={{ padding: '4px 20px 8px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', height: 32, marginBottom: 4 }}>
        <div>{leading}</div>
        <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>{trailing}</div>
      </div>
      {eyebrow && <div style={{ fontSize: 13, color: t.secondary, fontWeight: 500, marginBottom: 2, letterSpacing: 0.2 }}>{eyebrow}</div>}
      <div style={{
        fontFamily: VBT.font, fontSize: 34, fontWeight: 700,
        letterSpacing: -0.4, lineHeight: '41px', color: t.label,
      }}>{title}</div>
    </div>
  );
};

// Inline (small) nav bar (used on sub-pages)
const NavInline = ({ title, dark, leading, trailing }) => {
  const t = T(dark);
  return (
    <div style={{
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      padding: '6px 12px', height: 44, borderBottom: `0.5px solid ${t.sep}`,
      background: dark ? 'rgba(0,0,0,0.6)' : 'rgba(242,242,247,0.7)',
      backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
    }}>
      <div style={{ minWidth: 60, display: 'flex', alignItems: 'center', color: VBT.accent, fontSize: 17 }}>
        {leading}
      </div>
      <div style={{ fontWeight: 600, fontSize: 17, color: t.label }}>{title}</div>
      <div style={{ minWidth: 60, display: 'flex', justifyContent: 'flex-end', alignItems: 'center', color: VBT.accent, fontSize: 17 }}>
        {trailing}
      </div>
    </div>
  );
};

// Card primitive
const Card = ({ children, dark, style = {}, padded = true, onClick }) => {
  const t = T(dark);
  return (
    <div onClick={onClick} style={{
      background: t.card, borderRadius: 18,
      padding: padded ? 16 : 0, ...style,
    }}>{children}</div>
  );
};

// Number — big rounded
const Numeric = ({ value, unit, size = 56, color, dark, weight = 600 }) => {
  const t = T(dark);
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, lineHeight: 1, color: color || t.label }}>
      <span style={{ fontFamily: VBT.fontR, fontSize: size, fontWeight: weight, letterSpacing: -1.2, fontVariantNumeric: 'tabular-nums' }}>{value}</span>
      {unit && <span style={{ fontFamily: VBT.fontR, fontSize: Math.max(13, size * 0.32), fontWeight: 500, color: t.secondary, letterSpacing: -0.3 }}>{unit}</span>}
    </div>
  );
};

// Row separator
const Sep = ({ dark, indent = 0 }) => {
  const t = T(dark);
  return <div style={{ height: 0.5, background: t.sep, marginLeft: indent }}/>;
};

// Segmented control (iOS style)
const Segmented = ({ items, active, dark, full = false }) => {
  const t = T(dark);
  return (
    <div style={{
      display: 'inline-flex', background: t.fill, borderRadius: 9,
      padding: 2, gap: 0, width: full ? '100%' : 'auto',
    }}>
      {items.map((label, i) => (
        <div key={label} style={{
          flex: 1, padding: '6px 12px', textAlign: 'center',
          fontSize: 13, fontWeight: i === active ? 600 : 500,
          background: i === active ? (dark ? '#636366' : '#fff') : 'transparent',
          color: t.label, borderRadius: 7,
          boxShadow: i === active ? '0 2px 6px rgba(0,0,0,0.06)' : 'none',
        }}>{label}</div>
      ))}
    </div>
  );
};

// Pill / chip
const Chip = ({ children, color, dark }) => {
  const t = T(dark);
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      padding: '3px 8px', borderRadius: 6,
      fontSize: 12, fontWeight: 500,
      color: color || t.secondary,
      background: color ? `${color}1F` : t.fill2,
      fontFamily: VBT.fontR, letterSpacing: 0,
    }}>{children}</span>
  );
};

// Stat block (label + big number)
const Stat = ({ label, value, unit, color, dark, sub }) => {
  const t = T(dark);
  return (
    <div>
      <div style={{ fontSize: 12, color: t.secondary, fontWeight: 500, marginBottom: 6, letterSpacing: 0.3, textTransform: 'uppercase' }}>{label}</div>
      <Numeric value={value} unit={unit} size={28} color={color} dark={dark} weight={600}/>
      {sub && <div style={{ fontSize: 12, color: t.tertiary, marginTop: 4, fontFamily: VBT.fontR }}>{sub}</div>}
    </div>
  );
};

Object.assign(window, { VBT, T, Icon, StatusBar, TabBar, Screen, NavLarge, NavInline, Card, Numeric, Sep, Segmented, Chip, Stat });

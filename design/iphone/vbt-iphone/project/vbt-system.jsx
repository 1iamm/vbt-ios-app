// Tokens reference + philosophy + Watch handoff summary cards.
// These render as tall artboards in the canvas (width 720).

const TokenSwatch = ({ name, hex, dark }) => {
  const t = T(dark);
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '8px 0', borderBottom: `0.5px solid ${t.sep}` }}>
      <div style={{ width: 36, height: 36, borderRadius: 8, background: hex, boxShadow: 'inset 0 0 0 0.5px rgba(0,0,0,0.15)' }}/>
      <div style={{ flex: 1, fontSize: 13, fontWeight: 500 }}>{name}</div>
      <div style={{ fontFamily: VBT.fontM, fontSize: 12, color: t.secondary }}>{hex}</div>
    </div>
  );
};

const TokenRow = ({ name, value, sample, dark }) => {
  const t = T(dark);
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 0', borderBottom: `0.5px solid ${t.sep}` }}>
      <div style={{ width: 140, fontSize: 13, fontWeight: 500 }}>{name}</div>
      <div style={{ flex: 1, fontFamily: VBT.fontM, fontSize: 11, color: t.secondary }}>{value}</div>
      <div style={{ minWidth: 120, textAlign: 'right' }}>{sample}</div>
    </div>
  );
};

const TokensSheet = ({ dark = false }) => {
  const t = T(dark);
  const W = 720, H = 1480;
  return (
    <div style={{
      width: W, height: H, background: dark ? VBT.D.bg : '#FFFFFF', color: t.label,
      fontFamily: VBT.font, padding: '40px 44px', boxSizing: 'border-box', overflow: 'hidden',
      borderRadius: 4,
    }}>
      <div style={{ fontSize: 11, color: t.secondary, letterSpacing: 1.2, fontWeight: 600, textTransform: 'uppercase', marginBottom: 6 }}>Design System · v1.0</div>
      <div style={{ fontSize: 38, fontWeight: 700, letterSpacing: -0.7, lineHeight: 1.05 }}>VBTrainer Tokens</div>
      <div style={{ fontSize: 14, color: t.secondary, fontFamily: VBT.fontR, marginTop: 8, maxWidth: 480, lineHeight: 1.5 }}>
        颜色、字体、间距、圆角、动效缓动 — 单一来源。所有屏幕从这里取值。
      </div>

      {/* Colors */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 28, marginTop: 32 }}>
        <div>
          <div style={{ fontSize: 13, color: t.secondary, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 6 }}>Light · Neutrals</div>
          <TokenSwatch dark={dark} name="systemBackground"      hex="#FFFFFF"/>
          <TokenSwatch dark={dark} name="systemGroupedBg"       hex="#F2F2F7"/>
          <TokenSwatch dark={dark} name="card"                  hex="#FFFFFF"/>
          <TokenSwatch dark={dark} name="label"                 hex="#000000"/>
          <TokenSwatch dark={dark} name="secondaryLabel · 60%"  hex="#3C3C435C"/>
          <TokenSwatch dark={dark} name="separator · 18%"       hex="#3C3C432E"/>
        </div>
        <div>
          <div style={{ fontSize: 13, color: t.secondary, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 6 }}>Dark · OLED</div>
          <TokenSwatch dark={dark} name="systemBackground"      hex="#000000"/>
          <TokenSwatch dark={dark} name="systemGroupedBg"       hex="#000000"/>
          <TokenSwatch dark={dark} name="card"                  hex="#1C1C1E"/>
          <TokenSwatch dark={dark} name="label"                 hex="#FFFFFF"/>
          <TokenSwatch dark={dark} name="secondaryLabel · 60%"  hex="#EBEBF599"/>
          <TokenSwatch dark={dark} name="separator · 65%"       hex="#54545858"/>
        </div>
      </div>

      <div style={{ marginTop: 32 }}>
        <div style={{ fontSize: 13, color: t.secondary, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 6 }}>Accent + Data Palette · 6 colors total</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 28px' }}>
          <TokenSwatch dark={dark} name="accent · 训练"     hex="#FF9500"/>
          <TokenSwatch dark={dark} name="data.hr · 心率"    hex="#FF3B30"/>
          <TokenSwatch dark={dark} name="data.vel · 速度"   hex="#0A84FF"/>
          <TokenSwatch dark={dark} name="data.vol · 训练量" hex="#FF9500"/>
          <TokenSwatch dark={dark} name="data.vl · VL%"     hex="#BF5AF2"/>
          <TokenSwatch dark={dark} name="data.slp · 睡眠"   hex="#5E5CE6"/>
        </div>
      </div>

      {/* Type ramp */}
      <div style={{ marginTop: 32 }}>
        <div style={{ fontSize: 13, color: t.secondary, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 14 }}>Type · SF Pro / SF Pro Rounded</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          <div>
            <div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontM }}>34 / 41 · Bold · -0.4</div>
            <div style={{ fontSize: 34, fontWeight: 700, lineHeight: '41px', letterSpacing: -0.4 }}>Large Title · 准备度</div>
          </div>
          <div>
            <div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontM }}>28 · Bold · -0.5</div>
            <div style={{ fontSize: 28, fontWeight: 700, letterSpacing: -0.5 }}>Title 1 · 章节标题</div>
          </div>
          <div>
            <div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontM }}>17 · Semibold · -0.4</div>
            <div style={{ fontSize: 17, fontWeight: 600, letterSpacing: -0.4 }}>Headline · 卡片标题</div>
          </div>
          <div>
            <div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontM }}>17 · Regular · -0.4</div>
            <div style={{ fontSize: 17, fontWeight: 400, letterSpacing: -0.4 }}>Body · 正文文案</div>
          </div>
          <div>
            <div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontM }}>13 · Regular · -0.1</div>
            <div style={{ fontSize: 13, fontWeight: 400 }}>Footnote · 次要说明</div>
          </div>
          <div>
            <div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontM }}>72 · Rounded · 600 · -2.0</div>
            <div style={{ fontFamily: VBT.fontR, fontSize: 72, fontWeight: 600, letterSpacing: -2, lineHeight: 1, fontVariantNumeric: 'tabular-nums' }}>178 <span style={{ fontSize: 22, color: t.secondary, fontWeight: 500 }}>kg</span></div>
          </div>
        </div>
      </div>

      {/* Spacing + radius */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 28, marginTop: 32 }}>
        <div>
          <div style={{ fontSize: 13, color: t.secondary, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 8 }}>Spacing · 4-pt</div>
          {[['xs · 4', 4], ['sm · 8', 8], ['md · 12', 12], ['lg · 16', 16], ['xl · 20', 20], ['xxl · 24', 24], ['xxxl · 32', 32]].map(([n, v]) => (
            <div key={n} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '5px 0' }}>
              <div style={{ width: 90, fontSize: 13, fontWeight: 500 }}>{n}</div>
              <div style={{ height: 8, width: v, background: VBT.accent, borderRadius: 1 }}/>
              <div style={{ fontFamily: VBT.fontM, fontSize: 11, color: t.secondary }}>{v}px</div>
            </div>
          ))}
        </div>
        <div>
          <div style={{ fontSize: 13, color: t.secondary, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 8 }}>Radius</div>
          {[['button · 14', 14], ['card · 18', 18], ['list · 14', 14], ['ring · 9999', 9999]].map(([n, v]) => (
            <div key={n} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '5px 0' }}>
              <div style={{ width: 110, fontSize: 13, fontWeight: 500 }}>{n}</div>
              <div style={{ width: 32, height: 22, background: t.fill, borderRadius: Math.min(v, 11) }}/>
              <div style={{ fontFamily: VBT.fontM, fontSize: 11, color: t.secondary }}>{v}px</div>
            </div>
          ))}
          <div style={{ fontSize: 13, color: t.secondary, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', margin: '20px 0 8px' }}>Motion</div>
          <TokenRow dark={dark} name="enter"     value="cubic(.2,.7,.3,1) · 280ms"   sample={null}/>
          <TokenRow dark={dark} name="exit"      value="cubic(.4,0,.7,.3) · 200ms"   sample={null}/>
          <TokenRow dark={dark} name="snap"      value="spring(0.7,30) · 350ms"      sample={null}/>
          <TokenRow dark={dark} name="ring fill" value="ease-out · 900ms · stagger"  sample={null}/>
        </div>
      </div>
    </div>
  );
};

// ── Philosophy summary
const PhilosophyCard = () => {
  const t = T(false);
  const tenets = [
    { n: '01', t: 'Content first, chrome last',    s: 'UI 让位于数据。0 装饰 chrome。' },
    { n: '02', t: 'One screen, one purpose',        s: '每页只解决一个核心问题。' },
    { n: '03', t: 'Hide complexity, expose power',  s: '一级入口极简，深入有专业能力。' },
    { n: '04', t: 'Hierarchy via type, not color',  s: '靠字体层级而非彩色色块分层。' },
    { n: '05', t: 'Charts as art',                   s: 'Bloomberg + 学术期刊的克制美感。' },
    { n: '06', t: 'Zero gimmicks',                   s: '没有 streak、没有奖章、没有 emoji。' },
    { n: '07', t: 'Privacy as identity',             s: '数据本地存储 — UI 显式传达。' },
  ];
  return (
    <div style={{
      width: 720, height: 1080, background: '#FFFFFF', color: '#000',
      fontFamily: VBT.font, padding: '64px 56px', boxSizing: 'border-box',
      borderRadius: 4,
    }}>
      <div style={{ fontSize: 11, color: t.secondary, letterSpacing: 1.2, fontWeight: 600, textTransform: 'uppercase', marginBottom: 6 }}>Design Philosophy</div>
      <div style={{ fontSize: 44, fontWeight: 700, letterSpacing: -0.8, lineHeight: 1.05, marginBottom: 14 }}>七条原则。<br/>不可妥协。</div>
      <div style={{ fontSize: 15, color: t.secondary, fontFamily: VBT.fontR, lineHeight: 1.5, maxWidth: 480, marginBottom: 36 }}>
        VBTrainer 是数据采集与展示工具，不是教练，不是社交，不是健身房 SaaS。它只做一件事：让严肃训练者看懂自己的训练。
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px 32px' }}>
        {tenets.map(p => (
          <div key={p.n} style={{ borderTop: `1px solid ${t.sep}`, paddingTop: 14 }}>
            <div style={{ fontFamily: VBT.fontR, fontSize: 13, color: VBT.accent, fontWeight: 600, letterSpacing: 0.4, marginBottom: 6 }}>{p.n}</div>
            <div style={{ fontSize: 19, fontWeight: 600, letterSpacing: -0.4, marginBottom: 6 }}>{p.t}</div>
            <div style={{ fontSize: 13, color: t.secondary, fontFamily: VBT.fontR, lineHeight: 1.5 }}>{p.s}</div>
          </div>
        ))}
      </div>
    </div>
  );
};

// ── Watch ↔ iPhone Handoff
const HandoffCard = () => {
  const t = T(false);
  return (
    <div style={{
      width: 720, height: 1080, background: '#FFFFFF', color: '#000',
      fontFamily: VBT.font, padding: '64px 56px', boxSizing: 'border-box', borderRadius: 4,
    }}>
      <div style={{ fontSize: 11, color: t.secondary, letterSpacing: 1.2, fontWeight: 600, textTransform: 'uppercase', marginBottom: 6 }}>Watch ↔ iPhone</div>
      <div style={{ fontSize: 44, fontWeight: 700, letterSpacing: -0.8, lineHeight: 1.05, marginBottom: 14 }}>采集与复盘<br/>的两端。</div>
      <div style={{ fontSize: 15, color: t.secondary, fontFamily: VBT.fontR, lineHeight: 1.5, maxWidth: 540, marginBottom: 36 }}>
        Watch = 训练当下。极简、抗误触、单手可用。<br/>
        iPhone = 训练之外。全数据、可探索、可决策。
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24 }}>
        <div style={{ background: '#000', borderRadius: 24, padding: 28, color: '#fff', minHeight: 240 }}>
          <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.5)', letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600 }}>Apple Watch</div>
          <div style={{ fontSize: 28, fontWeight: 700, marginTop: 6, letterSpacing: -0.5 }}>训练当下</div>
          <div style={{ marginTop: 24, display: 'flex', flexDirection: 'column', gap: 10, fontSize: 14, fontFamily: VBT.fontR, color: 'rgba(255,255,255,0.75)' }}>
            <div>· 自动检测组与 rep</div>
            <div>· 当前 rep 速度大字</div>
            <div>· VL% 警戒触感震动</div>
            <div>· Digital Crown 改重量</div>
            <div>· 组间倒计时</div>
          </div>
        </div>
        <div style={{ background: '#F2F2F7', borderRadius: 24, padding: 28, minHeight: 240 }}>
          <div style={{ fontSize: 11, color: t.secondary, letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600 }}>iPhone</div>
          <div style={{ fontSize: 28, fontWeight: 700, marginTop: 6, letterSpacing: -0.5 }}>训练之外</div>
          <div style={{ marginTop: 24, display: 'flex', flexDirection: 'column', gap: 10, fontSize: 14, fontFamily: VBT.fontR, color: t.secondary }}>
            <div>· 综合时间轴大图</div>
            <div>· 长期趋势 / e1RM</div>
            <div>· 计划与模板编辑</div>
            <div>· 力速曲线分析</div>
            <div>· 准备度评估</div>
          </div>
        </div>
      </div>

      <div style={{ marginTop: 32 }}>
        <div style={{ fontSize: 13, color: t.secondary, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 14 }}>分工原则</div>
        {[
          ['Watch 只显示当下需要的数字',          'iPhone 提供完整可探索的图表'],
          ['Watch 不展示历史与趋势',                'iPhone 是历史的归宿'],
          ['Watch 写入数据',                          'iPhone 读取并组合数据'],
          ['Watch 设置项 ≤ 5',                        'iPhone 承担所有偏好与配置'],
        ].map(([a, b], i) => (
          <div key={i} style={{ display: 'grid', gridTemplateColumns: '1fr 18px 1fr', gap: 14, padding: '10px 0', borderTop: `0.5px solid ${t.sep}`, fontSize: 14, alignItems: 'center', fontFamily: VBT.fontR }}>
            <div>{a}</div>
            <div style={{ color: t.tertiary, textAlign: 'center' }}>↔</div>
            <div style={{ color: t.secondary }}>{b}</div>
          </div>
        ))}
      </div>
    </div>
  );
};

// ── App icon mockup
const AppIconCard = () => {
  return (
    <div style={{
      width: 720, height: 720, background: '#0A0A0B', color: '#fff',
      fontFamily: VBT.font, padding: '56px', boxSizing: 'border-box', borderRadius: 4,
      display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
    }}>
      <div>
        <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.5)', letterSpacing: 1.2, fontWeight: 600, textTransform: 'uppercase', marginBottom: 6 }}>App Icon</div>
        <div style={{ fontSize: 36, fontWeight: 700, letterSpacing: -0.5, lineHeight: 1.1 }}>速度向量</div>
        <div style={{ fontSize: 14, color: 'rgba(255,255,255,0.5)', fontFamily: VBT.fontR, marginTop: 8, maxWidth: 360 }}>
          黑底 + 一个指向右上的速度箭头。代表「上推」「加速」。
        </div>
      </div>
      <div style={{ display: 'flex', gap: 32, alignItems: 'flex-end' }}>
        {[180, 120, 80, 60, 40].map((s, i) => (
          <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10 }}>
            <div style={{
              width: s, height: s, borderRadius: s * 0.22, background: '#000',
              boxShadow: 'inset 0 0 0 0.5px rgba(255,255,255,0.1)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <svg width={s * 0.6} height={s * 0.6} viewBox="0 0 60 60">
                <path d="M12 48 L30 14 L42 36 M30 28 L48 28" stroke={VBT.accent} strokeWidth="5" strokeLinecap="round" strokeLinejoin="round" fill="none"/>
              </svg>
            </div>
            <div style={{ fontFamily: VBT.fontM, fontSize: 10, color: 'rgba(255,255,255,0.4)' }}>{s}px</div>
          </div>
        ))}
      </div>
    </div>
  );
};

Object.assign(window, { TokensSheet, PhilosophyCard, HandoffCard, AppIconCard });

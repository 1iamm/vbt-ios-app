// VBT Screens — composed from tokens + charts
// Priority: TodayScreen, DetailScreen (portrait), DetailLandscape, TrendsScreen
// Lighter: TrainScreen, HistoryListScreen, ProfileScreen, OnboardingFlow

// ─────────────────────────────────────────────────────────────
// TODAY
// ─────────────────────────────────────────────────────────────
const TodayScreen = ({ dark = false }) => {
  const t = T(dark);
  return (
    <Screen dark={dark}>
      <NavLarge title="今天" eyebrow="周三 · 5 月 8 日" dark={dark}
        trailing={<div style={{
          width: 30, height: 30, borderRadius: 15,
          background: dark ? '#2C2C2E' : '#E5E5EA',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 13, fontWeight: 600, color: t.label, letterSpacing: -0.3,
          fontFamily: VBT.fontR,
        }}>L</div>}/>

      {/* Hero — readiness */}
      <div style={{ padding: '20px 0 28px', display: 'flex', justifyContent: 'center' }}>
        <ReadinessRing dark={dark} score={78}/>
      </div>

      {/* Mini metrics row */}
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

      {/* Today's plan */}
      <div style={{ padding: '0 20px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
        <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: -0.4 }}>今日训练</div>
        <div style={{ fontSize: 13, color: VBT.accent, fontWeight: 500 }}>查看计划</div>
      </div>
      <div style={{ margin: '0 16px 18px' }}>
        <Card dark={dark} padded={false}>
          <div style={{ padding: '16px 18px' }}>
            <div style={{ fontSize: 12, color: t.secondary, letterSpacing: 0.3, fontWeight: 600, textTransform: 'uppercase', marginBottom: 4 }}>下肢力量 · 周期 W3 D2</div>
            <div style={{ fontSize: 19, fontWeight: 600, letterSpacing: -0.4, marginBottom: 12 }}>深蹲 · 罗马尼亚硬拉 · 保加利亚分腿蹲</div>
            <div style={{ display: 'flex', gap: 16 }}>
              <div><Numeric value="48" unit="min" size={22} dark={dark}/><div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontR, marginTop: 2 }}>预计时长</div></div>
              <div style={{ width: 0.5, background: t.sep }}/>
              <div><Numeric value="3" unit="动作" size={22} dark={dark}/><div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontR, marginTop: 2 }}>共 14 组</div></div>
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

      {/* Last training summary */}
      <div style={{ padding: '0 20px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
        <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: -0.4 }}>最近一次</div>
        <div style={{ fontSize: 13, color: t.secondary, fontFamily: VBT.fontR }}>2 天前 · 周一</div>
      </div>
      <div style={{ margin: '0 16px 24px' }}>
        <Card dark={dark}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>上肢推 · 卧推日</div>
              <div style={{ fontSize: 12, color: t.secondary, fontFamily: VBT.fontR }}>52m · 心率峰值 168 · VL 22%</div>
            </div>
            <Spark data={[80,90,95,100,105,103,108,110]} color={VBT.data.vel} fill/>
          </div>
          <div style={{ height: 1, background: t.sep, margin: '14px -16px 14px' }}/>
          <div style={{ display: 'flex', gap: 16 }}>
            <Stat dark={dark} label="总 Reps" value="64"/>
            <Stat dark={dark} label="平均速度" value="0.68" unit="m/s" color={VBT.data.vel}/>
            <Stat dark={dark} label="VL%" value="22" unit="%" color={VBT.data.vl}/>
          </div>
        </Card>
      </div>

      {/* 18-week heatmap */}
      <div style={{ padding: '0 20px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
        <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: -0.4 }}>训练频率</div>
      </div>
      <div style={{ margin: '0 16px 32px' }}>
        <Card dark={dark}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 14 }}>
            <div>
              <Numeric value="58" unit="次" size={32} dark={dark}/>
              <div style={{ fontSize: 12, color: t.secondary, fontFamily: VBT.fontR, marginTop: 2 }}>共 142 小时</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: 12, color: t.secondary, fontFamily: VBT.fontR }}>每周</div>
              <Numeric value="3.2" size={20} dark={dark}/>
            </div>
          </div>
          <Heatmap dark={dark}/>
        </Card>
      </div>
    </Screen>
  );
};

// ─────────────────────────────────────────────────────────────
// SINGLE TRAINING DETAIL — portrait
// ─────────────────────────────────────────────────────────────
const DetailScreen = ({ dark = false }) => {
  const t = T(dark);
  const sectionTitle = (s) => (
    <div style={{ padding: '24px 20px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
      <div style={{ fontSize: 13, color: t.secondary, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase' }}>{s}</div>
    </div>
  );
  return (
    <Screen dark={dark} hideTabs>
      <NavInline dark={dark} title="2025 · 5 · 6"
        leading={<><Icon name="chev-l" size={18} color={VBT.accent} stroke={2.4}/><span style={{ marginLeft: 2 }}>历史</span></>}
        trailing={<Icon name="share" size={20} color={VBT.accent} stroke={2}/>}/>

      {/* Header summary */}
      <div style={{ padding: '20px 20px 16px' }}>
        <div style={{ fontSize: 13, color: t.secondary, fontWeight: 500, letterSpacing: 0.3, textTransform: 'uppercase', marginBottom: 4 }}>下肢力量 · 周一</div>
        <div style={{ fontSize: 28, fontWeight: 700, letterSpacing: -0.6, lineHeight: '34px', marginBottom: 18 }}>深蹲 · 卧推 · 硬拉</div>

        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8 }}>
          <div>
            <Numeric value="64" size={42} dark={dark}/>
            <div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontR, marginTop: 2, letterSpacing: 0.3, textTransform: 'uppercase' }}>总 reps</div>
          </div>
          <div>
            <Numeric value="0.68" unit="m/s" size={42} color={VBT.data.vel} dark={dark}/>
            <div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontR, marginTop: 2, letterSpacing: 0.3, textTransform: 'uppercase' }}>平均速度</div>
          </div>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8, marginTop: 18 }}>
          <div>
            <Numeric value="22" unit="%" size={42} color={VBT.data.vl} dark={dark}/>
            <div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontR, marginTop: 2, letterSpacing: 0.3, textTransform: 'uppercase' }}>VL</div>
          </div>
          <div>
            <Numeric value="62" unit="min" size={42} dark={dark}/>
            <div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontR, marginTop: 2, letterSpacing: 0.3, textTransform: 'uppercase' }}>时长</div>
          </div>
        </div>
      </div>

      {/* Timeline chart */}
      {sectionTitle('综合时间轴')}
      <div style={{ margin: '0 16px' }}>
        <Card dark={dark} padded={false} style={{ overflow: 'hidden' }}>
          <div style={{ padding: '12px 14px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ display: 'flex', gap: 14, fontSize: 11, fontFamily: VBT.fontR, color: t.secondary }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}><div style={{ width: 8, height: 2, background: VBT.data.hr, borderRadius: 1 }}/>心率</span>
              <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}><div style={{ width: 6, height: 6, background: VBT.data.vel, borderRadius: 3 }}/>速度</span>
              <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}><div style={{ width: 8, height: 0, borderTop: `1px dashed ${VBT.data.vl}` }}/>VL 警戒</span>
            </div>
            <Icon name="expand" size={14} color={t.tertiary} stroke={1.8}/>
          </div>
          <TimelineChart dark={dark} w={358} h={300}/>
          <div style={{ padding: '10px 14px 12px', borderTop: `0.5px solid ${t.sep}`, fontSize: 11, color: t.tertiary, fontFamily: VBT.fontR, display: 'flex', justifyContent: 'space-between' }}>
            <span>双指缩放 · 单指拖动 · 点击 rep 查看详情</span>
            <span style={{ color: VBT.accent, fontWeight: 500 }}>横屏查看</span>
          </div>
        </Card>
      </div>

      {/* HR zone donut */}
      {sectionTitle('心率分布')}
      <div style={{ margin: '0 16px' }}>
        <Card dark={dark}>
          <HRZoneDonut dark={dark}/>
        </Card>
      </div>

      {/* VL bars */}
      {sectionTitle('每组 VL%')}
      <div style={{ margin: '0 16px' }}>
        <Card dark={dark}>
          <VLBars dark={dark} w={328} h={120}/>
        </Card>
      </div>

      {/* Sets table */}
      {sectionTitle('每组数据')}
      <div style={{ margin: '0 16px' }}>
        <Card dark={dark} padded={false}>
          <div style={{
            display: 'grid', gridTemplateColumns: '32px 1fr 50px 50px 50px',
            padding: '10px 16px', fontSize: 11, color: t.secondary,
            letterSpacing: 0.3, textTransform: 'uppercase', fontWeight: 600,
            borderBottom: `0.5px solid ${t.sep}`,
          }}>
            <div>#</div><div>动作 · 负荷</div><div style={{ textAlign: 'right' }}>Reps</div><div style={{ textAlign: 'right' }}>Avg</div><div style={{ textAlign: 'right' }}>VL</div>
          </div>
          {[
            { n: 1, name: '深蹲',  load: '120 × 5', reps: 5, avg: '0.78', vl: '8%'  },
            { n: 2, name: '深蹲',  load: '125 × 5', reps: 5, avg: '0.71', vl: '12%' },
            { n: 3, name: '深蹲',  load: '130 × 4', reps: 4, avg: '0.66', vl: '18%' },
            { n: 4, name: '卧推',  load: '85 × 6',  reps: 6, avg: '0.62', vl: '15%' },
            { n: 5, name: '卧推',  load: '90 × 5',  reps: 5, avg: '0.58', vl: '22%' },
            { n: 6, name: '硬拉',  load: '160 × 3', reps: 3, avg: '0.51', vl: '28%' },
          ].map((row, i, a) => (
            <div key={i} style={{
              display: 'grid', gridTemplateColumns: '32px 1fr 50px 50px 50px',
              padding: '12px 16px', alignItems: 'center', fontSize: 14,
              borderBottom: i === a.length - 1 ? 'none' : `0.5px solid ${t.sep}`,
              fontFamily: VBT.fontR,
            }}>
              <div style={{ color: t.tertiary, fontWeight: 500 }}>{row.n}</div>
              <div><span style={{ fontWeight: 500 }}>{row.name}</span><span style={{ color: t.secondary, marginLeft: 6 }}>{row.load}</span></div>
              <div style={{ textAlign: 'right', color: t.label, fontWeight: 500, fontVariantNumeric: 'tabular-nums' }}>{row.reps}</div>
              <div style={{ textAlign: 'right', color: VBT.data.vel, fontWeight: 500, fontVariantNumeric: 'tabular-nums' }}>{row.avg}</div>
              <div style={{ textAlign: 'right', color: parseInt(row.vl) >= 25 ? VBT.data.vl : t.label, fontWeight: 500, fontVariantNumeric: 'tabular-nums' }}>{row.vl}</div>
            </div>
          ))}
        </Card>
      </div>

      {/* LVP locked card */}
      {sectionTitle('力速曲线 · LVP')}
      <div style={{ margin: '0 16px' }}>
        <Card dark={dark}>
          <div style={{ position: 'relative' }}>
            <div style={{ filter: 'blur(2px)', opacity: 0.35, pointerEvents: 'none' }}>
              <LVPChart dark={dark} w={328} h={180} locked/>
            </div>
            <div style={{
              position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column',
              alignItems: 'center', justifyContent: 'center', gap: 8,
            }}>
              <div style={{ width: 36, height: 36, borderRadius: 18, background: t.fill, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon name="lock" size={18} color={t.secondary} stroke={1.8}/>
              </div>
              <div style={{ fontSize: 15, fontWeight: 600 }}>再记录 2 组不同重量</div>
              <div style={{ fontSize: 12, color: t.secondary, fontFamily: VBT.fontR, textAlign: 'center', maxWidth: 260, lineHeight: 1.4 }}>
                LVP 需要至少 4 组负重 ≥ 5kg 差异的数据。<br/>当前 2/4 组。
              </div>
            </div>
          </div>
        </Card>
      </div>

      {/* before/after */}
      {sectionTitle('训前 → 训后')}
      <div style={{ margin: '0 16px 32px', display: 'flex', gap: 12 }}>
        <div style={{ flex: 1 }}>
          <Card dark={dark}>
            <div style={{ fontSize: 11, color: t.secondary, letterSpacing: 0.3, textTransform: 'uppercase', fontWeight: 600 }}>准备度</div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 8 }}>
              <Numeric value="78" size={32} dark={dark}/>
              <span style={{ color: t.tertiary, fontFamily: VBT.fontR }}>→</span>
              <Numeric value="62" size={32} color={t.secondary} dark={dark}/>
            </div>
            <div style={{ fontSize: 11, color: t.secondary, fontFamily: VBT.fontR, marginTop: 4 }}>−16 训练负担</div>
          </Card>
        </div>
        <div style={{ flex: 1 }}>
          <Card dark={dark}>
            <div style={{ fontSize: 11, color: t.secondary, letterSpacing: 0.3, textTransform: 'uppercase', fontWeight: 600 }}>HR 恢复</div>
            <div style={{ marginTop: 8 }}>
              <Numeric value="42" unit="bpm/min" size={28} color={VBT.data.hr} dark={dark}/>
            </div>
            <div style={{ marginTop: 6 }}>
              <Spark data={[168,162,150,140,128,118,108,102,98]} color={VBT.data.hr} w={80} h={26}/>
            </div>
          </Card>
        </div>
      </div>
    </Screen>
  );
};

// ─────────────────────────────────────────────────────────────
// DETAIL — landscape (full-screen timeline)
// Custom: rotated frame 874 × 402.
// ─────────────────────────────────────────────────────────────
const DetailLandscape = ({ dark = false }) => {
  const t = T(dark);
  const W = 874, H = 402;
  return (
    <div style={{
      width: W, height: H, borderRadius: 48, overflow: 'hidden', position: 'relative',
      background: dark ? VBT.D.grouped : VBT.L.grouped, fontFamily: VBT.font, color: t.label,
      boxShadow: dark
        ? '0 30px 60px rgba(0,0,0,0.45), 0 0 0 1px rgba(0,0,0,0.6)'
        : '0 30px 60px rgba(0,0,0,0.13), 0 0 0 1px rgba(0,0,0,0.10)',
    }}>
      {/* notch on left side (landscape) */}
      <div style={{
        position: 'absolute', left: 11, top: '50%', transform: 'translateY(-50%)',
        width: 37, height: 126, borderRadius: 24, background: '#000', zIndex: 50,
      }}/>
      {/* status bar — top right & top left */}
      <div style={{
        position: 'absolute', top: 14, right: 30, fontSize: 14, fontWeight: 600, color: dark ? '#fff' : '#000',
        display: 'flex', gap: 6, alignItems: 'center', zIndex: 5,
      }}>
        <span>9:41</span>
        <svg width="16" height="10" viewBox="0 0 17 11"><rect x="0" y="6" width="2.6" height="4.5" rx=".7" fill="currentColor"/><rect x="4.4" y="4" width="2.6" height="6.5" rx=".7" fill="currentColor"/><rect x="8.8" y="2" width="2.6" height="8.5" rx=".7" fill="currentColor"/><rect x="13.2" y="0" width="2.6" height="10.5" rx=".7" fill="currentColor"/></svg>
      </div>

      {/* content area — leave room for left notch (60px) */}
      <div style={{ position: 'absolute', left: 60, top: 14, right: 14, bottom: 14, display: 'flex', flexDirection: 'column' }}>
        {/* header strip */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '4px 12px 14px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <Icon name="chev-l" size={20} color={VBT.accent} stroke={2.4}/>
            <div>
              <div style={{ fontSize: 11, color: t.secondary, letterSpacing: 0.3, textTransform: 'uppercase', fontWeight: 600 }}>2025 · 5 · 6 · 下肢力量</div>
              <div style={{ fontSize: 19, fontWeight: 700, letterSpacing: -0.4 }}>深蹲 · 卧推 · 硬拉</div>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 18, alignItems: 'baseline' }}>
            <div><span style={{ fontFamily: VBT.fontR, fontSize: 22, fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>64</span><span style={{ fontSize: 10, color: t.secondary, marginLeft: 3, letterSpacing: 0.3, textTransform: 'uppercase' }}>reps</span></div>
            <div><span style={{ fontFamily: VBT.fontR, fontSize: 22, fontWeight: 600, color: VBT.data.vel, fontVariantNumeric: 'tabular-nums' }}>0.68</span><span style={{ fontSize: 10, color: t.secondary, marginLeft: 3, letterSpacing: 0.3, textTransform: 'uppercase' }}>m/s</span></div>
            <div><span style={{ fontFamily: VBT.fontR, fontSize: 22, fontWeight: 600, color: VBT.data.vl, fontVariantNumeric: 'tabular-nums' }}>22</span><span style={{ fontSize: 10, color: t.secondary, marginLeft: 3, letterSpacing: 0.3, textTransform: 'uppercase' }}>vl%</span></div>
            <div><span style={{ fontFamily: VBT.fontR, fontSize: 22, fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>62m</span></div>
            <Icon name="share" size={18} color={VBT.accent}/>
          </div>
        </div>
        {/* big timeline chart */}
        <div style={{ flex: 1, background: t.card, borderRadius: 18, position: 'relative', overflow: 'hidden' }}>
          <TimelineChart dark={dark} w={780} h={310} landscape/>
          {/* fade & legend bottom */}
          <div style={{
            position: 'absolute', bottom: 8, left: 14, right: 14,
            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            fontSize: 11, color: t.tertiary, fontFamily: VBT.fontR,
          }}>
            <div style={{ display: 'flex', gap: 18 }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: 5 }}><div style={{ width: 12, height: 2, background: VBT.data.hr, borderRadius: 1 }}/>心率</span>
              <span style={{ display: 'flex', alignItems: 'center', gap: 5 }}><div style={{ width: 7, height: 7, background: VBT.data.vel, borderRadius: 4 }}/>每 rep 速度</span>
              <span style={{ display: 'flex', alignItems: 'center', gap: 5 }}><div style={{ width: 14, height: 6, background: dark ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.05)', borderRadius: 1 }}/>组间休息</span>
              <span style={{ display: 'flex', alignItems: 'center', gap: 5 }}><div style={{ width: 12, borderTop: `1px dashed ${VBT.data.vl}` }}/>VL 25%</span>
            </div>
            <span>双指缩放 · 拖动 · 点击 rep</span>
          </div>
        </div>
      </div>
      {/* home indicator (landscape — right edge) */}
      <div style={{ position: 'absolute', right: 8, top: '50%', transform: 'translateY(-50%) rotate(90deg)', width: 139, height: 5, borderRadius: 100, background: dark ? 'rgba(255,255,255,0.85)' : 'rgba(0,0,0,0.35)', transformOrigin: 'center' }}/>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────
// LONG-TERM TRENDS
// ─────────────────────────────────────────────────────────────
const TrendsScreen = ({ dark = false }) => {
  const t = T(dark);
  return (
    <Screen dark={dark} hideTabs>
      <NavInline dark={dark} title="长期趋势"
        leading={<><Icon name="chev-l" size={18} color={VBT.accent} stroke={2.4}/><span style={{ marginLeft: 2 }}>历史</span></>}
        trailing={<Icon name="share" size={20} color={VBT.accent} stroke={2}/>}/>

      {/* action picker */}
      <div style={{ padding: '16px 16px 0' }}>
        <Segmented dark={dark} items={['深蹲', '卧推', '硬拉', '推举']} active={0} full/>
      </div>

      {/* hero number */}
      <div style={{ padding: '20px 20px 8px' }}>
        <div style={{ fontSize: 13, color: t.secondary, letterSpacing: 0.3, textTransform: 'uppercase', fontWeight: 600, marginBottom: 6 }}>e1RM · 深蹲</div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 12 }}>
          <Numeric value="178" unit="kg" size={64} dark={dark}/>
          <Chip color="#34C759" dark={dark}><Icon name="arrow-up" size={11} color="#34C759" stroke={2.4}/>+26 / 90d</Chip>
        </div>
        <div style={{ fontSize: 13, color: t.secondary, fontFamily: VBT.fontR, marginTop: 4 }}>共 16 个数据点 · R² 0.94</div>
      </div>

      {/* time range */}
      <div style={{ padding: '12px 20px' }}>
        <Segmented dark={dark} items={['7d', '30d', '90d', 'All']} active={2}/>
      </div>

      {/* main chart */}
      <div style={{ margin: '8px 16px 0' }}>
        <Card dark={dark}>
          <TrendLine dark={dark} w={328} h={200}/>
        </Card>
      </div>

      {/* sub-charts */}
      <div style={{ margin: '20px 16px 0' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', padding: '0 4px 8px' }}>
          <div style={{ fontSize: 13, color: t.secondary, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase' }}>平均速度 · 90d</div>
          <Numeric value="0.71" unit="m/s" size={16} color={VBT.data.vel} dark={dark}/>
        </div>
        <Card dark={dark}>
          <TrendLine dark={dark} w={328} h={120} color={VBT.data.vel}
            points={range(16).map(i => ({ d: i * 6, v: 0.65 + (i * 0.005) + Math.sin(i) * 0.04 + 65 }))}/>
        </Card>
      </div>

      <div style={{ margin: '16px 16px 0' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', padding: '0 4px 8px' }}>
          <div style={{ fontSize: 13, color: t.secondary, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase' }}>每周训练量 · tonnage</div>
          <Numeric value="14.2" unit="t" size={16} color={VBT.data.vol} dark={dark}/>
        </div>
        <Card dark={dark}>
          <VolumeBars dark={dark}/>
        </Card>
      </div>

      <div style={{ margin: '16px 16px 32px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', padding: '0 4px 8px' }}>
          <div style={{ fontSize: 13, color: t.secondary, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase' }}>力速曲线 · 月度叠加</div>
        </div>
        <Card dark={dark}>
          <LVPChart dark={dark} w={328} h={200}/>
          <div style={{ display: 'flex', gap: 14, fontSize: 11, fontFamily: VBT.fontR, color: t.secondary, marginTop: 8 }}>
            <span style={{ display: 'flex', alignItems: 'center', gap: 5 }}><div style={{ width: 8, height: 8, borderRadius: 4, background: VBT.data.vel, opacity: 0.4 }}/>3 月</span>
            <span style={{ display: 'flex', alignItems: 'center', gap: 5 }}><div style={{ width: 8, height: 8, borderRadius: 4, background: VBT.data.vel, opacity: 0.7 }}/>4 月</span>
            <span style={{ display: 'flex', alignItems: 'center', gap: 5 }}><div style={{ width: 8, height: 8, borderRadius: 4, background: VBT.data.vel }}/>5 月</span>
          </div>
        </Card>
      </div>
    </Screen>
  );
};

// volume bars (sub-chart helper)
const VolumeBars = ({ dark, w = 328, h = 100 }) => {
  const t = T(dark);
  const data = [9.2, 11.5, 10.8, 13.1, 14.8, 13.6, 14.2, 15.1, 12.4, 14.6, 15.8, 14.2];
  const max = 18;
  const bw = (w - 14) / data.length - 4;
  return (
    <svg width={w} height={h}>
      {data.map((v, i) => {
        const bh = (v / max) * (h - 22);
        return (
          <rect key={i} x={6 + i * (bw + 4)} y={h - 14 - bh} width={bw} height={bh} rx="2" fill={VBT.data.vol} opacity={i === data.length - 1 ? 1 : 0.5}/>
        );
      })}
      <text x={6} y={h - 2} fontFamily={VBT.fontR} fontSize="9" fill={t.tertiary} fontWeight="500">12 周</text>
    </svg>
  );
};

// ─────────────────────────────────────────────────────────────
// TRAIN — template list
// ─────────────────────────────────────────────────────────────
const TrainScreen = ({ dark = false }) => {
  const t = T(dark);
  const tpl = [
    { name: '推日 · 上肢', ex: '卧推 · 推举 · 三头', last: '2 天前', sets: 14 },
    { name: '拉日 · 上肢', ex: '引体 · 划船 · 二头', last: '4 天前', sets: 12 },
    { name: '腿日 · 力量', ex: '深蹲 · RDL · 分腿蹲', last: '今日', sets: 14 },
    { name: '腿日 · 速度', ex: '高翻 · 跳箱 · 阻力跑', last: '8 天前', sets: 10 },
    { name: '上肢力量', ex: '卧推 · 引体 · 推举',  last: '11 天前', sets: 16 },
  ];
  return (
    <Screen dark={dark}>
      <NavLarge title="训练" dark={dark}
        trailing={<Icon name="plus" size={26} color={VBT.accent} stroke={2.2}/>}/>
      <div style={{ padding: '0 16px 12px' }}>
        <Segmented dark={dark} items={['模板', '日历', '动作库']} active={0} full/>
      </div>
      <div style={{ margin: '0 16px' }}>
        <Card dark={dark} padded={false}>
          {tpl.map((row, i) => (
            <div key={i} style={{ padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 12, borderBottom: i === tpl.length - 1 ? 'none' : `0.5px solid ${t.sep}` }}>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 16, fontWeight: 600, letterSpacing: -0.3 }}>{row.name}</div>
                <div style={{ fontSize: 12, color: t.secondary, fontFamily: VBT.fontR, marginTop: 2 }}>{row.ex} · {row.sets} 组</div>
              </div>
              <div style={{ fontSize: 12, color: t.tertiary, fontFamily: VBT.fontR }}>{row.last}</div>
              <Icon name="chev-r" size={14} color={t.tertiary} stroke={2.2}/>
            </div>
          ))}
        </Card>
      </div>
      <div style={{ padding: '24px 20px 8px', fontSize: 13, color: t.secondary, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase' }}>本周计划</div>
      <div style={{ margin: '0 16px' }}>
        <Card dark={dark} padded={false}>
          {[
            { day: '周一', name: '腿日 · 力量', done: true },
            { day: '周二', name: '休息',         done: false, rest: true },
            { day: '周三', name: '腿日 · 力量', done: false, today: true },
            { day: '周四', name: '休息',         done: false, rest: true },
            { day: '周五', name: '推日 · 上肢', done: false },
            { day: '周六', name: '拉日 · 上肢', done: false },
            { day: '周日', name: '休息',         done: false, rest: true },
          ].map((row, i, a) => (
            <div key={i} style={{ padding: '13px 16px', display: 'flex', alignItems: 'center', gap: 12, borderBottom: i === a.length - 1 ? 'none' : `0.5px solid ${t.sep}` }}>
              <div style={{ width: 36, fontSize: 12, color: row.today ? VBT.accent : t.secondary, fontWeight: row.today ? 600 : 500, fontFamily: VBT.fontR, letterSpacing: 0.3 }}>{row.day}</div>
              <div style={{ flex: 1, fontSize: 15, color: row.rest ? t.secondary : t.label, fontWeight: 500 }}>{row.name}</div>
              {row.done && <Icon name="check" size={18} color="#34C759" stroke={2.2}/>}
              {row.today && <Chip color={VBT.accent} dark={dark}>今日</Chip>}
            </div>
          ))}
        </Card>
      </div>
    </Screen>
  );
};

// ─────────────────────────────────────────────────────────────
// HISTORY — list
// ─────────────────────────────────────────────────────────────
const HistoryScreen = ({ dark = false }) => {
  const t = T(dark);
  const groups = [
    { month: '5 月', items: [
      { date: '5 · 6', dow: '周一', name: '腿日 · 力量', dur: '62m', vel: '0.68', vl: 22, accent: VBT.data.vel },
      { date: '5 · 4', dow: '周六', name: '拉日 · 上肢', dur: '48m', vel: '0.72', vl: 18, accent: VBT.data.vel },
      { date: '5 · 2', dow: '周四', name: '推日 · 上肢', dur: '52m', vel: '0.70', vl: 21, accent: VBT.data.vel },
    ]},
    { month: '4 月', items: [
      { date: '4 · 30', dow: '周二', name: '腿日 · 速度', dur: '38m', vel: '0.94', vl: 8,  accent: VBT.data.vel },
      { date: '4 · 28', dow: '周日', name: '推日 · 上肢', dur: '54m', vel: '0.66', vl: 24, accent: VBT.data.vel },
      { date: '4 · 26', dow: '周五', name: '腿日 · 力量', dur: '65m', vel: '0.64', vl: 26, accent: VBT.data.vel },
    ]},
  ];
  return (
    <Screen dark={dark}>
      <NavLarge title="历史" dark={dark}
        trailing={<Icon name="cal" size={22} color={VBT.accent} stroke={2}/>}/>
      <div style={{ padding: '0 16px 12px' }}>
        <Segmented dark={dark} items={['列表', '日历']} active={0} full/>
      </div>
      {groups.map((g, gi) => (
        <div key={gi}>
          <div style={{ padding: '16px 20px 6px', fontSize: 13, color: t.secondary, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase' }}>{g.month}</div>
          <div style={{ margin: '0 16px 8px' }}>
            <Card dark={dark} padded={false}>
              {g.items.map((row, i, a) => (
                <div key={i} style={{ padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 14, borderBottom: i === a.length - 1 ? 'none' : `0.5px solid ${t.sep}` }}>
                  <div style={{ minWidth: 40, textAlign: 'left' }}>
                    <div style={{ fontFamily: VBT.fontR, fontSize: 17, fontWeight: 600, letterSpacing: -0.4, fontVariantNumeric: 'tabular-nums' }}>{row.date}</div>
                    <div style={{ fontSize: 11, color: t.tertiary, fontFamily: VBT.fontR }}>{row.dow}</div>
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 15, fontWeight: 600 }}>{row.name}</div>
                    <div style={{ fontSize: 12, color: t.secondary, fontFamily: VBT.fontR, marginTop: 2 }}>
                      {row.dur} · <span style={{ color: row.accent }}>{row.vel}</span> m/s · VL <span style={{ color: row.vl >= 25 ? VBT.data.vl : t.secondary }}>{row.vl}%</span>
                    </div>
                  </div>
                  <Icon name="chev-r" size={14} color={t.tertiary} stroke={2.2}/>
                </div>
              ))}
            </Card>
          </div>
        </div>
      ))}
      <div style={{ height: 24 }}/>
    </Screen>
  );
};

// ─────────────────────────────────────────────────────────────
// PROFILE
// ─────────────────────────────────────────────────────────────
const ProfileScreen = ({ dark = false }) => {
  const t = T(dark);
  const Group = ({ title, children }) => (
    <div style={{ marginBottom: 24 }}>
      <div style={{ padding: '0 36px 6px', fontSize: 12, color: t.secondary, letterSpacing: 0.4, textTransform: 'uppercase', fontWeight: 600 }}>{title}</div>
      <div style={{ margin: '0 16px', background: t.card, borderRadius: 14, overflow: 'hidden' }}>{children}</div>
    </div>
  );
  const Row = ({ label, value, last }) => (
    <div style={{ display: 'flex', alignItems: 'center', padding: '13px 16px', borderBottom: last ? 'none' : `0.5px solid ${t.sep}` }}>
      <div style={{ flex: 1, fontSize: 15, color: t.label }}>{label}</div>
      {value && <div style={{ fontSize: 14, color: t.secondary, fontFamily: VBT.fontR, marginRight: 8 }}>{value}</div>}
      <Icon name="chev-r" size={13} color={t.tertiary} stroke={2.2}/>
    </div>
  );
  return (
    <Screen dark={dark}>
      <NavLarge title="我的" dark={dark}/>
      {/* avatar */}
      <div style={{ padding: '8px 20px 24px', display: 'flex', alignItems: 'center', gap: 14 }}>
        <div style={{
          width: 60, height: 60, borderRadius: 30, background: t.fill,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: VBT.fontR, fontSize: 24, fontWeight: 600, color: t.label, letterSpacing: -0.5,
        }}>L</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 19, fontWeight: 600, letterSpacing: -0.3 }}>Liang Wei</div>
          <div style={{ fontSize: 13, color: t.secondary, fontFamily: VBT.fontR, marginTop: 2 }}>34 · 男 · 175cm · 78kg</div>
        </div>
        <Icon name="chev-r" size={14} color={t.tertiary} stroke={2.2}/>
      </div>
      <Group title="训练参数">
        <Row label="单位" value="kg"/>
        <Row label="Digital Crown 档位" value="0.05 m/s"/>
        <Row label="默认休息时长" value="2:30"/>
        <Row label="VL% 警戒线" value="25%"/>
        <Row label="目标速度区间" value="按动作"/>
        <Row label="震动等级阈值" value="中" last/>
      </Group>
      <Group title="数据">
        <Row label="HealthKit 同步" value="开"/>
        <Row label="导出" value="CSV · JSON"/>
        <Row label="备份" last/>
      </Group>
      <Group title="隐私">
        <Row label="数据存储位置" value="仅本设备"/>
        <Row label="HealthKit 用途说明" last/>
      </Group>
      <Group title="关于">
        <Row label="版本" value="1.0 (24)"/>
        <Row label="致谢"/>
        <Row label="参考论文" last/>
      </Group>
    </Screen>
  );
};

// ─────────────────────────────────────────────────────────────
// ONBOARDING — 4 stops in a row
// ─────────────────────────────────────────────────────────────
const OnboardingWelcome = () => (
  <Screen dark={true} hideTabs>
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', padding: '120px 32px 48px' }}>
      <div>
        <div style={{ width: 28, height: 28, marginBottom: 28 }}>
          <svg width="28" height="28" viewBox="0 0 28 28">
            <path d="M3 22 L11 6 L17 22 M14 14 L23 14" stroke={VBT.accent} strokeWidth="2.4" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
        <div style={{ fontSize: 40, fontWeight: 700, color: '#fff', letterSpacing: -1, lineHeight: 1.1 }}>用速度<br/>衡量训练。</div>
        <div style={{ fontSize: 16, color: 'rgba(255,255,255,0.5)', marginTop: 18, fontFamily: VBT.fontR, lineHeight: 1.5 }}>VBTrainer 把 Apple Watch 的传感器变成你的速度教练。</div>
      </div>
      <div>
        <div style={{ background: VBT.accent, borderRadius: 14, padding: '14px', textAlign: 'center', fontSize: 16, fontWeight: 600, color: '#000' }}>开始</div>
        <div style={{ textAlign: 'center', fontSize: 13, color: 'rgba(255,255,255,0.4)', marginTop: 16, fontFamily: VBT.fontR }}>已有账户？登录</div>
      </div>
    </div>
  </Screen>
);

const OnboardingValue = () => {
  const t = T(true);
  return (
    <Screen dark={true} hideTabs>
      <div style={{ height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', padding: '80px 32px 48px' }}>
        <div>
          <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 40 }}>
            <div style={{ width: 96, height: 96, borderRadius: 24, background: 'rgba(255,149,0,0.14)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Icon name="bolt" size={52} color={VBT.accent}/>
            </div>
          </div>
          <div style={{ fontSize: 32, fontWeight: 700, color: '#fff', textAlign: 'center', letterSpacing: -0.6, lineHeight: 1.2 }}>每一 rep 的速度<br/>都被记录。</div>
          <div style={{ fontSize: 15, color: 'rgba(255,255,255,0.55)', marginTop: 14, fontFamily: VBT.fontR, textAlign: 'center', lineHeight: 1.5, padding: '0 16px' }}>Watch 端被动采集，无需手动计组。<br/>训练强度自动量化。</div>
        </div>
        <div>
          <div style={{ display: 'flex', justifyContent: 'center', gap: 6, marginBottom: 24 }}>
            <div style={{ width: 6, height: 6, borderRadius: 3, background: 'rgba(255,255,255,0.2)' }}/>
            <div style={{ width: 18, height: 6, borderRadius: 3, background: '#fff' }}/>
            <div style={{ width: 6, height: 6, borderRadius: 3, background: 'rgba(255,255,255,0.2)' }}/>
          </div>
          <div style={{ background: '#fff', borderRadius: 14, padding: '14px', textAlign: 'center', fontSize: 16, fontWeight: 600, color: '#000' }}>下一步</div>
        </div>
      </div>
    </Screen>
  );
};

const OnboardingProfile = () => {
  const t = T(false);
  return (
    <Screen dark={false} hideTabs>
      <div style={{ padding: '60px 24px 0' }}>
        <div style={{ fontSize: 11, color: t.secondary, letterSpacing: 1, fontWeight: 600, textTransform: 'uppercase', marginBottom: 8 }}>步骤 3 / 5</div>
        <div style={{ fontSize: 32, fontWeight: 700, letterSpacing: -0.6, lineHeight: 1.15 }}>你的体重<br/>是多少？</div>
        <div style={{ fontSize: 14, color: t.secondary, fontFamily: VBT.fontR, marginTop: 10 }}>用于估算 e1RM 与训练量。</div>
      </div>
      {/* big roller */}
      <div style={{ position: 'absolute', top: 280, left: 0, right: 0, display: 'flex', justifyContent: 'center', alignItems: 'center', height: 240 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
          <div style={{ fontFamily: VBT.fontR, fontSize: 36, fontWeight: 500, color: t.tertiary, fontVariantNumeric: 'tabular-nums' }}>76</div>
          <div style={{ fontFamily: VBT.fontR, fontSize: 36, fontWeight: 500, color: t.secondary, fontVariantNumeric: 'tabular-nums' }}>77</div>
          <div style={{ fontFamily: VBT.fontR, fontSize: 96, fontWeight: 600, color: VBT.accent, letterSpacing: -2, fontVariantNumeric: 'tabular-nums' }}>78</div>
          <div style={{ fontFamily: VBT.fontR, fontSize: 36, fontWeight: 500, color: t.secondary, fontVariantNumeric: 'tabular-nums' }}>79</div>
          <div style={{ fontFamily: VBT.fontR, fontSize: 36, fontWeight: 500, color: t.tertiary, fontVariantNumeric: 'tabular-nums' }}>80</div>
        </div>
      </div>
      <div style={{ position: 'absolute', top: 380, left: 0, right: 0, textAlign: 'center', fontSize: 14, color: t.secondary, fontFamily: VBT.fontR }}>kg</div>
      {/* footer button */}
      <div style={{ position: 'absolute', bottom: 32, left: 24, right: 24 }}>
        <div style={{ background: VBT.accent, borderRadius: 14, padding: '14px', textAlign: 'center', fontSize: 16, fontWeight: 600, color: '#000' }}>继续</div>
        <div style={{ display: 'flex', justifyContent: 'center', gap: 4, marginTop: 18 }}>
          {[0,1,2,3,4].map(i => <div key={i} style={{ width: i === 2 ? 18 : 6, height: 6, borderRadius: 3, background: i === 2 ? VBT.accent : t.quaternary }}/>)}
        </div>
      </div>
    </Screen>
  );
};

const OnboardingPermissions = () => {
  const t = T(false);
  const items = [
    { icon: 'pulse',  label: '心率',   why: '识别训练中的强度区间' },
    { icon: 'heart',  label: 'HRV',    why: '计算每日准备度' },
    { icon: 'bed',    label: '睡眠',   why: '反映恢复状态' },
    { icon: 'flame',  label: '基础代谢',why: '估算训练消耗' },
  ];
  return (
    <Screen dark={false} hideTabs>
      <div style={{ padding: '60px 24px 0' }}>
        <div style={{ width: 56, height: 56, borderRadius: 14, background: '#FF3B301F', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 18 }}>
          <Icon name="heart" size={30} color="#FF3B30" stroke={1.6}/>
        </div>
        <div style={{ fontSize: 28, fontWeight: 700, letterSpacing: -0.5, lineHeight: 1.2 }}>授权 Apple 健康</div>
        <div style={{ fontSize: 14, color: t.secondary, fontFamily: VBT.fontR, marginTop: 8, lineHeight: 1.5 }}>VBTrainer 只读取以下数据，<br/>且永远不会上传到云端。</div>
      </div>
      <div style={{ margin: '24px 16px' }}>
        <Card dark={false} padded={false}>
          {items.map((it, i, a) => (
            <div key={i} style={{ padding: '14px 16px', display: 'flex', gap: 14, alignItems: 'center', borderBottom: i === a.length - 1 ? 'none' : `0.5px solid ${t.sep}` }}>
              <div style={{ width: 32, height: 32, borderRadius: 8, background: t.fill2, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon name={it.icon} size={18} color={VBT.data.hr}/>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 15, fontWeight: 500 }}>{it.label}</div>
                <div style={{ fontSize: 12, color: t.secondary, fontFamily: VBT.fontR, marginTop: 2 }}>{it.why}</div>
              </div>
              <Icon name="check" size={18} color="#34C759" stroke={2.2}/>
            </div>
          ))}
        </Card>
      </div>
      <div style={{ position: 'absolute', bottom: 32, left: 24, right: 24 }}>
        <div style={{ background: VBT.accent, borderRadius: 14, padding: '14px', textAlign: 'center', fontSize: 16, fontWeight: 600, color: '#000' }}>继续</div>
        <div style={{ textAlign: 'center', fontSize: 13, color: t.secondary, marginTop: 14, fontFamily: VBT.fontR }}>稍后在「我的」中调整</div>
      </div>
    </Screen>
  );
};

Object.assign(window, {
  TodayScreen, DetailScreen, DetailLandscape, TrendsScreen, TrainScreen,
  HistoryScreen, ProfileScreen,
  OnboardingWelcome, OnboardingValue, OnboardingProfile, OnboardingPermissions,
  VolumeBars,
});

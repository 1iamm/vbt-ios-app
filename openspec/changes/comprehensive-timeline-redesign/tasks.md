## 1. ComprehensiveChartView 重写

- [x] 1.1 顶部组带：chartOverlay + GeometryReader 渲染独立色块
- [x] 1.2 同动作同色（exerciseColorMap），首次出现加 small-caps 名字
- [x] 1.3 心率 LineMark（左 BPM 轴，可切换）
- [x] 1.4 速度 PointMark（映射 m/s → BPM 域，右轴显 m/s）
- [x] 1.5 VL% 段状虚线（每组一段，独立 series 标识）
- [x] 1.6 双层 X 轴（GeometryReader 5 等分采样：HH:mm + +Nm）
- [x] 1.7 图例可点击 Toggle（HR/Velocity/VL 各一）

## 2. 编译/验证（用户在 macOS 本机）
- [ ] 2.1 `xcodegen generate` + `xcodebuild` iOS target
- [ ] 2.2 真机：进训练详情 → "查看综合时间轴" → 顶部组带分色 + 双层时间轴 + 点击图例切换显隐

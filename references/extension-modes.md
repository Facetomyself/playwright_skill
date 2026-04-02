# Extension Modes (Playwright MCP)

本文件只描述扩展能力。默认流程继续以 `127.0.0.1:9224 + D:\chrome-mcp-pw` 为主，不主动偏离。

## 1. 多标签协同

适用场景：

- 主页面点击后打开新标签
- 需要在列表页和详情页之间来回切换
- 需要保留登录态并串行处理多个页面

推荐工具：

- `mcp__Playwright__browser_tabs(action=\"list\")`
- `mcp__Playwright__browser_tabs(action=\"select\", index=...)`
- `mcp__Playwright__browser_tabs(action=\"close\", index=...)`

规则：

- 每次切换前后都汇报当前标签索引和页面标题。
- 不在未知标签页上继续执行旧流程。

## 2. 文件上传

适用场景：

- 上传头像、附件、CSV、图片、PDF

推荐流程：

1. `browser_click` 触发上传入口
2. `browser_file_upload(paths=[\"C:/abs/path/file.ext\"])`
3. `browser_snapshot()` 或 `browser_wait_for(text=\"上传成功\")`

规则：

- 路径必须是绝对路径。
- 多文件上传时一次性传完整路径数组。

## 3. 控制台与网络取证

适用场景：

- 页面报错但 UI 不明显
- 点击按钮后怀疑接口没发出去
- 需要确认 4xx / 5xx、跨域或 JS 异常

推荐工具：

- `mcp__Playwright__browser_console_messages(level=\"info\")`
- `mcp__Playwright__browser_network_requests(requestBody=false, requestHeaders=false, static=false)`

规则：

- 抓取时机要贴着关键动作。
- 只看请求清单时，默认 `requestBody=false`、`requestHeaders=false`、`static=false`；需要深挖再显式打开对应开关。
- 输出摘要而不是整页原始噪声。

## 4. JS 兜底与复杂操作

适用场景：

- 标准快照无法稳定定位元素
- 需要读运行时变量、滚动容器、遍历列表
- 需要临时执行少量 Playwright 代码处理复杂交互

推荐工具：

- `mcp__Playwright__browser_evaluate`
- `mcp__Playwright__browser_run_code`

规则：

- 先说明为何标准工具不够用。
- 先做最小化脚本，不要一上来塞一大坨自定义代码。

## 5. 官方能力边界与默认流程的关系

2026-03-12 已核对官方文档，以下能力确实存在：

- Playwright MCP 官方 README 支持 `--browser <chrome|firefox|webkit|msedge>`、`--cdp-endpoint`、`--user-data-dir`、`--storage-state`、`--vision`、`--headless`、`--output-dir`、`--save-trace`、`--save-video`、`--isolated` 等参数。
- Playwright 官方 API 文档明确说明 `browserType.connectOverCDP` 主要用于连接基于 Chromium 的现有浏览器，但 fidelity 低于原生 Playwright 协议连接。
- Playwright MCP 官方 README 明确说明文件上传默认受 MCP roots 约束，只有服务端开启 `allowUnrestrictedFileAccess` 才能放开。
- Playwright MCP 官方 README 明确说明该服务不是 security boundary。

落地约束：

- 团队默认流程继续使用 `cdp-endpoint + 持久化 profile`，因为它更适合和其他工具共享同一个真实浏览器上下文。
- 若任务明确依赖 trace、video、isolated profile、headless 等扩展模式，再在汇报中说明偏离原因。

官方来源：

- Playwright MCP README：`https://github.com/microsoft/playwright-mcp`
- Playwright `connectOverCDP`：`https://playwright.dev/docs/api/class-browsertype#browser-type-connect-over-cdp`

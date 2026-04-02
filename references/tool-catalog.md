# Tool Catalog (Playwright MCP)

本文件用于在 `plyawright-skill` 中做快速选型，避免把默认主流程和扩展能力搅成一锅粥。

## A. 默认主流程工具

### 页面进入与标签页

- `mcp__Playwright__browser_navigate`：进入目标 URL，默认流程入口。
- `mcp__Playwright__browser_navigate_back`：回到上一页，适合验证跳转或退出详情页。
- `mcp__Playwright__browser_tabs`：列出、切换、新建、关闭标签页。
- `mcp__Playwright__browser_close`：关闭当前页面。

### 页面结构与验证

- `mcp__Playwright__browser_snapshot`：抓当前页面的可访问性快照，优先于“猜 DOM”。
- `mcp__Playwright__browser_wait_for`：等待文本出现、消失或显式等待几秒。
- `mcp__Playwright__browser_take_screenshot`：保存可视证据。

### 常规交互

- `mcp__Playwright__browser_click`：点击按钮、链接、选项。
- `mcp__Playwright__browser_hover`：悬停后再拿菜单项。
- `mcp__Playwright__browser_type`：输入单个控件，可选 `slowly` 与 `submit`。
- `mcp__Playwright__browser_fill_form`：批量填写表单，适合登录页和搜索表单。
- `mcp__Playwright__browser_select_option`：选择下拉框。
- `mcp__Playwright__browser_press_key`：发送键盘事件。
- `mcp__Playwright__browser_drag`：拖拽组件。
- `mcp__Playwright__browser_handle_dialog`：处理 alert / confirm / prompt。

## B. 扩展模式工具

### 上传、控制台、网络

- `mcp__Playwright__browser_file_upload`：上传单个或多个文件；先触发文件选择，再注入路径。官方 README 说明默认只允许 MCP roots 内的路径，除非服务端启用了 `allowUnrestrictedFileAccess`。
- `mcp__Playwright__browser_console_messages`：抓控制台日志，适合排查前端异常。
- `mcp__Playwright__browser_network_requests`：抓请求列表，适合确认接口是否真正发出；默认只看请求清单时用 `requestBody=false, requestHeaders=false, static=false`。

### 运行时兜底

- `mcp__Playwright__browser_evaluate`：在页面或元素上执行 JS 表达式，适合轻量读取状态。
- `mcp__Playwright__browser_run_code`：运行 Playwright 代码片段，适合复杂选择器、循环操作、特殊定位。
- `mcp__Playwright__browser_resize`：调整窗口尺寸，适合响应式验证。

## C. 默认路径与扩展路径的边界

默认路径：

- 假定 Playwright MCP 已接入 `http://127.0.0.1:9224`
- 复用 `D:\chrome-mcp-pw`
- 优先 `navigate -> snapshot -> act -> verify -> capture`，必要时再 `close`

扩展路径：

- 需要多标签协同、文件上传、复杂调试、网络/控制台取证时再开
- 需要 `evaluate` / `run_code` 时，先说明为什么常规工具不够
- 需要偏离 `9224` 固定浏览器时，先说明偏离原因

## D. 常见误用与修正

- 误用：不快照就直接点击旧 `ref`。  
  修正：先 `browser_snapshot()`，拿最新 `ref` 再交互。

- 误用：表单逐个乱填，事件触发不完整。  
  修正：字段明确时优先 `browser_fill_form()`，需要逐字触发时再换 `browser_type(..., slowly=true)`。

- 误用：页面没稳定就连续点击。  
  修正：先 `browser_wait_for(text=...)` 或 `browser_wait_for(time=...)`。

- 误用：一遇到复杂页面就上 `browser_run_code()`。  
  修正：先用标准交互工具，兜底代码只在必要时启用。

- 误用：把当前 MCP 当成自带 `browser_install()` 的环境。  
  修正：本 skill 当前只记录实际可用的 `mcp__Playwright__*` 工具面；默认模式复用本机 Chrome，若要改成独立浏览器启动链路，先确认服务端是否真的暴露了对应能力。

- 误用：上传任意绝对路径文件，结果工具没反应。  
  修正：先确认 MCP 配置是否允许超出 roots 的文件访问；没开就只能用允许范围内的文件。

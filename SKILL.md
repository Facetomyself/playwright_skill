---
name: plyawright-skill
description: 使用 Playwright MCP 执行网页自动化任务，默认复用本机真实 Chrome（127.0.0.1:9224 + D:\chrome-mcp-pw）并通过 mcp__Playwright__* 工具完成打开页面、分析 DOM、登录交互、表单填写、截图取证、多标签切换、上传文件、抓取网络与控制台信息等流程。用于 /play 风格命令，或用户明确要求通过 Playwright MCP 做页面访问、登录、点击、输入、截图、调试、取证时使用；默认遵循固定浏览器实例和受限场景主流程，只有在用户明确要求或默认路径受阻时才启用扩展模式。
---

# plyawright-skill

通过 `Playwright MCP` 统一编排浏览器自动化，目标是“默认流程稳定复用，扩展能力按需打开”。

## 浏览器实例约束（默认模式）

- 固定使用本机 Chrome：`C:\Program Files\Google\Chrome\Application\chrome.exe`
- 固定调试端口：`9224`
- 固定持久化目录：`D:\chrome-mcp-pw`
- 默认复用同一个已启动浏览器实例，不新建临时 profile，不默认改用 headless。
- 浏览器启动优先使用 PowerShell 脚本：`assets/start-local-chrome-9224.ps1`
- 默认认为 Playwright MCP 已通过 `--cdp-endpoint http://127.0.0.1:9224` 接入该浏览器实例。
- 扩展能力允许写入和使用，但不得覆盖默认主路径；只有用户明确要求，或默认主路径无法完成任务时，才切换到扩展模式。

推荐启动命令：

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\shang\.codex\skills\plyawright-skill\assets\start-local-chrome-9224.ps1"
```

## 0) 入口约束

- 仅调用 `mcp__Playwright__*` 前缀工具。
- 不混用其他命名空间的浏览器工具。
- 在调用工具前，先声明当前阶段（`NAVIGATE` / `SNAPSHOT` / `ACT` / `VERIFY` / `CAPTURE` / `CLOSE`）。
- 默认主流程只围绕“固定 9224 浏览器实例 + 当前页面任务”展开，不主动切换成隔离 profile、headless、录像、trace 等扩展模式。
- 若工具第一次调用失败，先按重试策略处理；不要立刻切换实现路径，更不要自作聪明改成别的浏览器方案。

## 1) 默认执行状态机（强约束）

按以下顺序执行，不跳步：

1. `NAVIGATE`：用 `browser_navigate` 打开目标 URL。
2. `SNAPSHOT`：用 `browser_snapshot` 读取页面结构，确认标题、URL、主要控件与登录态。
3. `ACT`：根据页面状态执行点击、输入、下拉、键盘、上传等交互。
4. `VERIFY`：再次快照，或用 `browser_wait_for`、`browser_network_requests`、`browser_console_messages` 验证结果。
5. `CAPTURE`：必要时保存截图、网络请求摘要、控制台输出或标签页状态，作为任务证据。
6. `CLOSE`（可选）：按任务需要关闭标签页、回到前页，或保留现场给用户继续操作。

若某一步失败，回到上一步重建页面状态；不要在过期的元素引用上硬闯。

## 2) 默认主流程模板

### 2.1 打开页面

首选模板：

```text
mcp__Playwright__browser_navigate(url="<target-url>")
mcp__Playwright__browser_snapshot()
```

说明：

- `browser_navigate` 是默认入口。
- `browser_snapshot` 用于生成结构化页面快照；官方 README 明确把它定位为基于 accessibility tree 的核心能力，工具说明也明确写了“这比 screenshot 更适合操作”。
- 若页面自动跳转到登录页，先识别表单与按钮，再决定是否继续。

### 2.2 登录与表单

优先级：

1. `browser_fill_form`：多个字段一起填写。
2. `browser_type`：单字段输入，或需要逐字触发前端事件时设置 `slowly=true`。
3. `browser_select_option`：选择下拉项。
4. `browser_click`：提交登录、打开菜单、确认操作。
5. `browser_handle_dialog`：处理 alert / confirm / prompt。

默认规则：

- 先快照，再拿 `ref`，再交互。
- 表单已自动填充时，先向用户汇报，再继续高风险动作。
- 页面需要等待时，优先用 `browser_wait_for(text=...)` 或 `browser_wait_for(time=...)`，不要靠连点碰运气。

### 2.3 验证与取证

优先级：

1. `browser_snapshot`：验证页面结构、标题、按钮状态、表单值变化。
2. `browser_wait_for`：等待文本出现、消失，或显式等待几秒。
3. `browser_take_screenshot`：需要可视证据时截图。
4. `browser_network_requests`：确认接口是否发出、状态是否正确；默认只看请求清单时使用 `requestBody=false, requestHeaders=false, static=false`。
5. `browser_console_messages`：确认前端错误、警告、日志。

### 2.4 默认输出模板

默认按以下结构汇报，不要整成流水账：

1. `phase`：当前阶段名。
2. `action`：调用了哪个工具、干了什么。
3. `evidence`：页面标题、URL、关键文本、截图文件、请求摘要、控制台摘要。
4. `decision`：为什么继续、重试、停下或切换扩展模式。
5. `next_action`：下一步动作。

固定模板见 `references/report-template.md`。

## 3) 工具分层（按职责调用）

### 3.1 Navigation / Session

- `mcp__Playwright__browser_navigate`
- `mcp__Playwright__browser_navigate_back`
- `mcp__Playwright__browser_tabs`
- `mcp__Playwright__browser_close`
- `mcp__Playwright__browser_resize`

### 3.2 Inspect / Observe

- `mcp__Playwright__browser_snapshot`
- `mcp__Playwright__browser_console_messages`
- `mcp__Playwright__browser_network_requests`
- `mcp__Playwright__browser_take_screenshot`

### 3.3 Interaction

- `mcp__Playwright__browser_click`
- `mcp__Playwright__browser_hover`
- `mcp__Playwright__browser_type`
- `mcp__Playwright__browser_fill_form`
- `mcp__Playwright__browser_select_option`
- `mcp__Playwright__browser_drag`
- `mcp__Playwright__browser_press_key`
- `mcp__Playwright__browser_handle_dialog`
- `mcp__Playwright__browser_file_upload`

### 3.4 Runtime / Debug

- `mcp__Playwright__browser_evaluate`
- `mcp__Playwright__browser_run_code`
- `mcp__Playwright__browser_wait_for`

更细的适用场景、参数建议和常见误用见 `references/tool-catalog.md`。
常见业务场景走法见 `references/scenario-cookbook.md`。

## 4) 重试与幂等策略

- `browser_navigate` 或 `browser_snapshot` 首次失败：立即原样重试 1 次。
- 元素交互失败：重新 `browser_snapshot` 获取最新 `ref` 后再重试 1 次。
- 页面未稳定：先 `browser_wait_for`，再重试动作；不允许在旧快照上反复点击。
- 网络/控制台抓取：只在关键步骤后抓，不把全量日志当默认输出。
- 多标签流程：每次切换前后都记录当前标签信息，避免串页。

## 5) 错误模型（必须归一化）

统一以以下错误码表达失败原因：

- `TOOL_UNAVAILABLE`
- `NAVIGATION_FAILED`
- `TIMEOUT`
- `ELEMENT_NOT_FOUND`
- `DIALOG_BLOCKED`
- `UPLOAD_FAILED`
- `NETWORK_ASSERTION_FAILED`
- `INTERNAL_ERROR`

详细判定与恢复动作见 `references/error-runbook.md`。

## 6) 观测与汇报规范

每轮流程输出结构化执行摘要，至少包含：

- `phase`：当前阶段。
- `tool`：调用的 `mcp__Playwright__*` 工具名。
- `result`：成功或失败。
- `key_fields`：`url`、`title`、`ref`、`text`、`request_count`、`screenshot`、`error.code` 等。
- `next_action`：下一步动作或恢复方案。

建议使用简短三段式：

1. 做了什么（阶段 + 工具）
2. 得到什么（关键字段）
3. 接下来做什么（继续、重试、回退）

## 7) 安全与边界

- 不在未确认页面上下文时执行高风险动作。
- 不默认调用 `browser_install`；默认模式下优先复用既有 Chrome 实例。
- `browser_evaluate` / `browser_run_code` 仅在常规工具不足以完成任务时使用。
- 文件上传默认受 MCP roots 限制；若环境未启用 `allowUnrestrictedFileAccess`，则只能上传允许范围内的绝对路径文件。
- Playwright MCP 官方 README 明确说明它不是 security boundary，别把它当沙箱神仙。
- 扩展模式能力允许使用，但必须在汇报里明确说明为什么偏离默认流程。

## 8) 扩展模式（仅按需启用）

以下内容只在用户明确要求，或默认主路径受阻时启用：

- 多标签复杂编排：见 `references/extension-modes.md`。
- 文件上传、下载代理链路：见 `references/extension-modes.md`。
- 控制台与网络取证：见 `references/extension-modes.md`。
- 运行时代码执行、复杂选择器、JS 兜底：见 `references/extension-modes.md`。
- 官方能力边界与来源：见 `references/official-capabilities.md`。

## 9) 完成定义（Definition of Done）

仅当以下条件都满足才视为任务完成：

- 已按默认状态机完成至少一个闭环（`NAVIGATE -> ... -> VERIFY`）。
- 输出中包含可验证证据（快照结论、截图文件、网络摘要、控制台摘要之一）。
- 若发生失败，已返回标准化错误码和下一步动作。
- 若启用了扩展模式，已明确说明触发原因和退出条件。
- 若执行了 `CLOSE`，已明确说明关闭了哪个标签页或保留了哪个现场。

## 10) 快速执行模板

最小可靠流程：

1. `mcp__Playwright__browser_navigate(url="...")`
2. `mcp__Playwright__browser_snapshot()`
3. `mcp__Playwright__browser_fill_form(...)` 或 `mcp__Playwright__browser_type(...)`
4. `mcp__Playwright__browser_click(...)`
5. `mcp__Playwright__browser_wait_for(text="..." 或 time=...)`
6. `mcp__Playwright__browser_snapshot()` 或 `mcp__Playwright__browser_take_screenshot(...)`

默认主流程是“先导航、再快照、后交互、最后验证”。别一上来就 `run_code` 硬掰，那味儿太冲。

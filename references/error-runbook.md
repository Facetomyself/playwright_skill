# Error Runbook

将执行异常统一映射为错误码，并给出建议恢复动作。

## `TOOL_UNAVAILABLE`

- 触发信号：`mcp__Playwright__*` 工具返回不可用、连接中断、调用失败。
- 恢复动作：
  1. 原样重试同一工具 1 次
  2. 若仍失败，确认默认 Chrome 已通过 `assets/start-local-chrome-9224.ps1` 启动
  3. 提示用户检查 Playwright MCP 与 `--cdp-endpoint http://127.0.0.1:9224`
  4. 不要直接切到别的浏览器方案

## `NAVIGATION_FAILED`

- 触发信号：打开页面失败、页面崩溃、跳转异常、目标 URL 不可达。
- 恢复动作：
  1. 重新执行 `browser_navigate`
  2. 若页面可恢复，立刻 `browser_snapshot`
  3. 输出当前 URL 与页面标题，避免盲猜

## `TIMEOUT`

- 触发信号：文本等待超时、页面迟迟不稳定、动作后无结果。
- 恢复动作：
  1. `browser_wait_for(time=2)` 或按页面信号等待文本
  2. 再次 `browser_snapshot`
  3. 若是异步页面，检查 `browser_network_requests` 或 `browser_console_messages`

## `ELEMENT_NOT_FOUND`

- 触发信号：点击、输入、选择时 `ref` 失效或目标元素不存在。
- 恢复动作：
  1. 重新 `browser_snapshot`
  2. 根据最新快照调整元素 `ref`
  3. 重试 1 次

## `DIALOG_BLOCKED`

- 触发信号：页面被 alert / confirm / prompt 卡住，后续动作失效。
- 恢复动作：
  1. 调用 `browser_handle_dialog`
  2. 若是 prompt，只有在用户授权后才填写内容
  3. 处理后重新验证页面状态

## `UPLOAD_FAILED`

- 触发信号：文件选择器未出现、路径无效、上传未生效。
- 恢复动作：
  1. 先触发上传按钮或输入框
  2. 再执行 `browser_file_upload(paths=[...])`
  3. 通过 `browser_snapshot` 或页面文本确认上传结果

## `NETWORK_ASSERTION_FAILED`

- 触发信号：请求未发出、状态码不符、网络日志与页面表现不一致。
- 恢复动作：
  1. 调用 `browser_network_requests(requestBody=false, requestHeaders=false, static=false)`
  2. 必要时结合 `browser_console_messages(level=\"info\")`
  3. 输出关键请求 URL、方法、状态码

## `INTERNAL_ERROR`

- 触发信号：未知异常、工具返回无法归类的信息。
- 恢复动作：
  1. 输出 `phase`、`tool`、`key_fields`
  2. 回退到上一个稳定阶段
  3. 若重复失败，给出替代路径（截图验收、手工步骤、保留现场）

# Official Capability Notes

本文件记录 `plyawright-skill` 设计时核对过的官方来源，避免把“本地默认约束”和“官方真实能力”混淆。

核对日期：`2026-03-12`

## 1. Playwright MCP 官方 README

来源：

- `https://github.com/microsoft/playwright-mcp`

已核对的能力点：

- 通过 `--cdp-endpoint` 连接现有 Chrome / Chromium 实例
- 通过 `--user-data-dir` 复用持久化 profile
- 通过 `--isolated` 使用临时 profile
- 支持 `--storage-state`、`--device`、`--vision`
- 支持 `--headless`、`--output-dir`、`--save-trace`、`--save-video`
- 文件上传默认受 MCP roots 限制，可通过 `allowUnrestrictedFileAccess` 放开
- README 明确说明 Playwright MCP 不是 security boundary

对 skill 的影响：

- 默认主流程保留 `9224 + D:\chrome-mcp-pw`，这是团队协同默认值，不是官方唯一用法。
- 扩展能力可写入 skill，但必须被明确标识为“按需启用”。

## 2. Playwright 官方 API：`connectOverCDP`

来源：

- `https://playwright.dev/docs/api/class-browsertype#browser-type-connect-over-cdp`

已核对的能力点：

- 允许连接现有 Chromium 浏览器
- 官方明确提示：该连接方式比原生 Playwright 协议 fidelity 更低

对 skill 的影响：

- 默认模式适合“复用真实浏览器、共享登录态、配合其他工具”。
- 涉及高级隔离、回放、trace、video、严格控制上下文时，应考虑扩展模式而不是假装默认路径啥都包圆。

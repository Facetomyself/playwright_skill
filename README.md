# plyawright-skill

`plyawright-skill` 是一个面向 Codex / MCP 工作流的 Playwright 浏览器自动化 skill。它的默认设计不是“每次临时起一个干净浏览器”，而是**复用本机真实 Chrome**，通过固定的 CDP 调试端口连接同一个浏览器实例，从而共享登录态、Cookie、站点缓存和人工操作现场。

默认约束如下：

- Chrome 可执行文件：`C:\Program Files\Google\Chrome\Application\chrome.exe`
- CDP 调试端口：`127.0.0.1:9224`
- 持久化用户目录：`D:\chrome-mcp-pw`
- 浏览器启动脚本：`assets/start-local-chrome-9224.ps1`
- 浏览器自动化工具命名空间：`mcp__Playwright__*`

如果你要的是“让模型稳定接管当前真实浏览器做页面访问、登录、点击、输入、截图、抓日志和抓请求”，这套 skill 就是干这个的。

---

## 1. 仓库结构

```text
plyawright-skill/
├─ README.md
├─ SKILL.md
├─ .gitattributes
├─ .gitignore
├─ agents/
│  └─ openai.yaml
├─ assets/
│  └─ start-local-chrome-9224.ps1
└─ references/
   ├─ error-runbook.md
   ├─ extension-modes.md
   ├─ official-capabilities.md
   ├─ report-template.md
   ├─ scenario-cookbook.md
   └─ tool-catalog.md
```

### 文件职责

- `SKILL.md`：skill 主契约，定义默认状态机、工具边界、错误模型、扩展模式和完成标准。
- `agents/openai.yaml`：给上层代理系统的展示信息和默认 prompt，决定这个 skill 被怎样路由和默认触发。
- `assets/start-local-chrome-9224.ps1`：本机 Chrome 启动 / 复用脚本。现在是幂等的，会先检查 `9224` 端口是否已可用，再决定是否启动浏览器。
- `references/*.md`：补充性说明，分别覆盖工具目录、扩展模式、业务场景、错误恢复和官方能力说明。

---

## 2. 前置要求

在开始之前，你至少得有下面这些东西：

- Windows 环境
- Node.js `18+`
- 本机已安装 Google Chrome
- 可用的 `npx`
- 已启用 MCP 的客户端或代理环境
- 能使用 `mcp__Playwright__*` 工具的运行环境

建议先自查：

```powershell
node -v
npx -v
```

再确认 Chrome 路径存在：

```powershell
Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe"
```

---

## 3. Playwright MCP 安装

### 3.1 官方最小安装方式

官方仓库给出的标准方式是直接通过 `npx` 运行 MCP server：

```powershell
npx @playwright/mcp@latest
```

如果你只是想确认包能拉起来，可以先跑：

```powershell
npx -y @playwright/mcp@latest --help
```

### 3.2 在 Codex 中添加 Playwright MCP

官方 README 给了 Codex CLI 的最小接入命令：

```powershell
codex mcp add playwright npx "@playwright/mcp@latest"
```

这条命令适合先把 Playwright MCP 挂进 Codex。  
但**本 skill 的默认玩法**不是让 Playwright MCP 自己临时起浏览器，而是让它连接到你已经准备好的本机 Chrome 调试实例，所以你后面还需要把 MCP server 的参数补成适合这套 skill 的形式。

### 3.3 Codex 的推荐配置文件写法

如果你更喜欢直接维护 `~/.codex/config.toml`，推荐把 Playwright MCP 配成这种形式：

```toml
[mcp_servers.playwright]
command = "npx"
args = [
  "@playwright/mcp@latest",
  "--cdp-endpoint",
  "http://127.0.0.1:9224"
]
```

如果你需要上传 workspace 外部文件，再加一项：

```toml
[mcp_servers.playwright]
command = "npx"
args = [
  "@playwright/mcp@latest",
  "--cdp-endpoint",
  "http://127.0.0.1:9224",
  "--allow-unrestricted-file-access"
]
```

### 3.4 本 skill 推荐的 MCP 参数

本 skill 的默认路径建议 Playwright MCP 连接到固定 CDP 端口：

```text
--cdp-endpoint http://127.0.0.1:9224
```

推荐的最小参数组合：

```text
npx @playwright/mcp@latest --cdp-endpoint http://127.0.0.1:9224
```

如果你需要上传超出 workspace roots 的文件，再额外打开：

```text
--allow-unrestricted-file-access
```

也就是：

```text
npx @playwright/mcp@latest --cdp-endpoint http://127.0.0.1:9224 --allow-unrestricted-file-access
```

> 注意：`--allow-unrestricted-file-access` 只是在文件访问上放宽限制，不是安全边界。

### 3.5 通用 MCP 配置片段

如果你的 MCP 客户端支持 JSON 方式配置服务器，推荐按下面这个思路配：

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--cdp-endpoint",
        "http://127.0.0.1:9224"
      ]
    }
  }
}
```

如果你需要跨 workspace 上传文件，可以改成：

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--cdp-endpoint",
        "http://127.0.0.1:9224",
        "--allow-unrestricted-file-access"
      ]
    }
  }
}
```

### 3.6 为什么默认只配 `--cdp-endpoint`

这里有个容易搞混的点，我直接给你掰开说：

- `D:\chrome-mcp-pw` 是**Chrome 启动脚本**用的持久化 profile 目录
- `--cdp-endpoint http://127.0.0.1:9224` 是**Playwright MCP**连接这个浏览器实例的方式

也就是说：

- Chrome 怎么起、profile 放哪儿：由 `assets/start-local-chrome-9224.ps1` 决定
- MCP 怎么接进这个浏览器：由 `--cdp-endpoint` 决定

别把这俩揉成一锅。要不然文档看着挺像那么回事，实际上链路是断的。

---

## 4. 启动本机共享 Chrome

本 skill 默认复用一份长期存在的真实 Chrome，而不是每次新开临时 profile。

### 4.1 启动命令

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\shang\.codex\skills\plyawright-skill\assets\start-local-chrome-9224.ps1"
```

### 4.2 当前脚本行为

脚本现在已经是幂等流程：

1. 检查 Chrome 可执行文件是否存在
2. 检查 `D:\chrome-mcp-pw` 是否存在，不存在就创建
3. 先探测 `127.0.0.1:9224` 是否已经在监听
4. 若已监听，则直接复用当前浏览器实例
5. 若未监听，则启动 Chrome 并等待调试端口起来
6. 若端口超时仍没起来，则明确报错

这能避免重复启动时撞上 profile lock，或者误以为浏览器已经可连接、实际 Playwright 根本 attach 不上的尴尬场面。

### 4.3 手工验证端口

你也可以手工确认 9224 是否真的开了：

```powershell
Test-NetConnection 127.0.0.1 -Port 9224
```

---

## 5. skill 安装与配置

### 5.1 skill 放置位置

这个仓库本质上是一个 Codex skill 目录。典型放置位置就是：

```text
C:\Users\shang\.codex\skills\plyawright-skill
```

只要这个目录保留 `SKILL.md`，并且宿主环境会扫描 `~/.codex/skills/` 下的 skill，一般就能被发现。

### 5.2 `SKILL.md` 负责什么

`SKILL.md` 是真正的执行契约，核心约束包括：

- 仅调用 `mcp__Playwright__*`
- 固定走 `NAVIGATE -> SNAPSHOT -> ACT -> VERIFY -> CAPTURE -> CLOSE（按需）`
- 默认不偏离 `9224 + D:\chrome-mcp-pw`
- 失败后先重试和重建快照，不乱切实现路径
- 扩展模式只在用户明确要求或默认路径受阻时启用

如果你要改行为边界，优先改 `SKILL.md`，别只改 README。

### 5.3 `agents/openai.yaml` 负责什么

这个文件给上层代理系统提供两类信息：

1. 展示信息
2. 默认 prompt

当前默认 prompt 会明确要求：

- 使用 `$plyawright-skill`
- 严格只调用 `mcp__Playwright__*`
- 默认先通过 PowerShell 脚本启动或确认 `9224` Chrome
- 复用 `D:\chrome-mcp-pw`
- 除非用户明确要求扩展模式，否则不要偏离默认流程

如果你想让 skill 更主动 / 更保守，或者调整默认说明语气，改这个文件。

### 5.4 推荐的 skill 触发方式

#### 显式触发

直接在任务里提：

```text
使用 $plyawright-skill 打开目标页面并检查登录态
```

#### 语义触发

也可以用自然语言描述这类任务：

- “用 Playwright MCP 打开这个页面”
- “帮我点一下这个按钮并截图”
- “检查这个页面的控制台报错和网络请求”
- “复用本机 Chrome 登录后继续操作”

---

## 6. 默认执行流

本 skill 的默认执行流非常明确：

1. `NAVIGATE`
2. `SNAPSHOT`
3. `ACT`
4. `VERIFY`
5. `CAPTURE`
6. `CLOSE`（按需）

最小闭环一般是：

```text
mcp__Playwright__browser_navigate(url="...")
mcp__Playwright__browser_snapshot()
mcp__Playwright__browser_fill_form(...) / mcp__Playwright__browser_type(...)
mcp__Playwright__browser_click(...)
mcp__Playwright__browser_wait_for(...)
mcp__Playwright__browser_snapshot() / mcp__Playwright__browser_take_screenshot(...)
```

### 为什么强制先 `snapshot`

因为这套工具的稳定性核心在于 accessibility snapshot，而不是拍脑袋猜 DOM。  
不先拿最新快照就直接拿旧 `ref` 点，十有八九要翻车。

---

## 7. 常用工具与用途

### 页面进入与会话

- `mcp__Playwright__browser_navigate`
- `mcp__Playwright__browser_navigate_back`
- `mcp__Playwright__browser_tabs`
- `mcp__Playwright__browser_close`

### 观察与验证

- `mcp__Playwright__browser_snapshot`
- `mcp__Playwright__browser_wait_for`
- `mcp__Playwright__browser_take_screenshot`
- `mcp__Playwright__browser_console_messages`
- `mcp__Playwright__browser_network_requests`

### 常规交互

- `mcp__Playwright__browser_click`
- `mcp__Playwright__browser_fill_form`
- `mcp__Playwright__browser_type`
- `mcp__Playwright__browser_select_option`
- `mcp__Playwright__browser_press_key`
- `mcp__Playwright__browser_drag`
- `mcp__Playwright__browser_handle_dialog`
- `mcp__Playwright__browser_file_upload`

### 运行时兜底

- `mcp__Playwright__browser_evaluate`
- `mcp__Playwright__browser_run_code`

---

## 8. 网络与控制台取证

默认推荐：

```text
mcp__Playwright__browser_console_messages(level="info")
mcp__Playwright__browser_network_requests(requestBody=false, requestHeaders=false, static=false)
```

注意这个工具签名别再写错了：

- 这里用的是 `requestBody`
- `requestHeaders`
- `static`

不是 `includeStatic`

如果只是想确认“请求发没发出去”，默认把 body / headers / static 资源都关掉最省噪声。

---

## 9. 文件上传说明

文件上传这块有两个限制最容易踩坑：

1. `mcp__Playwright__browser_file_upload(paths=[...])` 要求绝对路径
2. 默认情况下，Playwright MCP 只允许访问 workspace roots 内的文件

如果你要上传 workspace 外面的文件，要么：

- 把文件放进允许的 roots

要么：

- 在 MCP 启动参数里加 `--allow-unrestricted-file-access`

---

## 10. 常见问题

### Q1：为什么我已经开了 Chrome，MCP 还是连不上？

先查三件事：

1. `9224` 端口是否真的在监听
2. Chrome 是否真的是通过 `assets/start-local-chrome-9224.ps1` 起来的
3. MCP 配置是否真的带了 `--cdp-endpoint http://127.0.0.1:9224`

### Q2：为什么重复运行启动脚本没问题？

因为脚本已经做了端口探活。  
如果 `9224` 已经能连，它会直接复用当前实例，不会无脑再起一个。

### Q3：为什么不默认用 isolated / headless / trace / video？

因为这个 skill 的主目标是**复用真实浏览器现场**。  
如果你要的是隔离测试、录像、trace 或严格环境控制，那是扩展模式，不是默认模式。

### Q4：为什么通过 CDP 连接有时候不如纯 Playwright 稳？

因为官方文档明确提到 `connectOverCDP` 的 fidelity 低于 Playwright 原生协议连接。  
这不代表不能用，而是意味着：

- 共享真实浏览器上下文很方便
- 但高级隔离 / 高级调试场景别硬装它啥都能兜住

---

## 11. 维护建议

建议把修改分成几类小提交：

- `docs:` 文档修订
- `fix:` 工具面或脚本修复
- `chore:` Git / 配置 / 仓库维护

推荐提交流程：

```powershell
git status
git add .
git commit -m "docs: update README and MCP setup notes"
git push
```

如果你改了默认行为边界，记得同步检查：

- `README.md`
- `SKILL.md`
- `agents/openai.yaml`
- `references/tool-catalog.md`
- `references/extension-modes.md`

不然过两天就又会出现“主文档一套、参考文档一套、真实工具面又一套”的三国杀局面。

---

## 12. 官方参考

以下能力说明已和官方文档对齐，建议后续维护时优先参考这些来源：

- Playwright MCP 官方仓库：<https://github.com/microsoft/playwright-mcp>
- Playwright `BrowserType.connectOverCDP` 官方文档：<https://playwright.dev/docs/api/class-browsertype#browser-type-connect-over-cdp>

本仓库里的 `references/official-capabilities.md` 也记录了和本 skill 设计直接相关的官方能力点。

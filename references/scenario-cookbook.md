# Scenario Cookbook

本文件给 `plyawright-skill` 提供默认场景模板。默认优先走简单闭环，别一上来把流程演成连续剧。

## 1. 打开页面并确认登录态

适用场景：

- 用户说“打开这个链接看看”
- 用户说“进系统后帮我确认是不是已登录”

推荐流程：

1. `browser_navigate(url=...)`
2. `browser_snapshot()`
3. 如果页面明显是登录页，汇报表单和按钮状态
4. 如果页面已进入业务页，汇报标题、URL、首屏关键信息

验证重点：

- 当前 URL
- 页面标题
- 是否出现登录字段或用户头像/退出按钮

## 2. 登录页填写并提交

适用场景：

- 用户明确允许登录
- 字段结构稳定，适合标准控件交互

推荐流程：

1. `browser_snapshot()`
2. `browser_fill_form(fields=[...])`
3. `browser_click(ref=..., element=\"登录按钮\")`
4. `browser_wait_for(text=... 或 time=...)`
5. `browser_snapshot()`

注意：

- 自动填充已存在时先汇报，不要擅自提交。
- 验证码或二次验证出现时立即停下，转用户决策。

## 3. 搜索、筛选、列表点击

适用场景：

- 搜索框输入关键词
- 选择筛选项
- 点击结果列表第一项或指定项

推荐流程：

1. `browser_snapshot()`
2. `browser_type(...)` 或 `browser_fill_form(...)`
3. `browser_select_option(...)` 或 `browser_click(...)`
4. `browser_wait_for(text=... 或 time=...)`
5. 再次 `browser_snapshot()` 确认结果区域

注意：

- 需要逐字触发联想搜索时用 `browser_type(..., slowly=true)`。
- 结果区变化要靠新快照确认，别拿旧 `ref` 硬点。

## 4. 新标签页详情查看

适用场景：

- 点击结果后打开新标签
- 需要保留原列表页上下文

推荐流程：

1. 在列表页触发点击
2. `browser_tabs(action=\"list\")`
3. `browser_tabs(action=\"select\", index=...)`
4. `browser_snapshot()`
5. 处理详情后按需 `browser_tabs(action=\"close\", index=...)`

验证重点：

- 标签页索引是否正确
- 详情页标题与目标对象是否一致

## 5. 文件上传

适用场景：

- 上传附件、头像、导入文件

推荐流程：

1. `browser_click(...)` 打开文件选择器
2. `browser_file_upload(paths=[\"C:/abs/path/file.ext\"])`
3. `browser_wait_for(text=\"上传成功\")` 或 `browser_snapshot()`

注意：

- 官方 README 说明上传默认受 MCP roots 限制；如果路径不在允许范围，流程要显式报错，不要装死。

## 6. 取证排障

适用场景：

- 页面按钮没反应
- 用户说“看一下前端是不是报错了”
- 用户怀疑接口没调成功

推荐流程：

1. 执行关键动作
2. `browser_console_messages(level=\"info\")`
3. `browser_network_requests(includeStatic=false)`
4. 汇报摘要

注意：

- 只摘关键错误、关键请求，别把整坨日志倒给用户。

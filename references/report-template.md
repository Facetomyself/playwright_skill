# Report Template

默认汇报模板要短、硬、可执行，别扯成散文。

## 单步执行模板

```text
phase: <NAVIGATE|SNAPSHOT|ACT|VERIFY|CAPTURE|CLOSE>
action: <tool + purpose>
evidence:
- url: <current-url>
- title: <page-title>
- key_text: <critical text or state>
- artifact: <screenshot filename / request count / console summary / none>
decision: <continue | retry | stop | switch_extension_mode>
next_action: <next step>
```

## 失败模板

```text
phase: <phase>
action: <tool>
result: failed
error:
- code: <standardized error code>
- summary: <short reason>
- retryable: <true|false>
recovery:
- <recovery step 1>
- <recovery step 2>
next_action: <what happens now>
```

## 汇报要求

- 一个阶段只保留一条主结论。
- `evidence` 必须能支撑 `decision`，别空口白话。
- 如果切换扩展模式，必须在 `decision` 里写明触发原因。

# Sleep Coach Web Prototype

Throwaway prototype for validating the Sleep Coach V1.1 product flow before changing the native iOS implementation.

## Question

Does the corrected sleep coach flow feel usable and premium enough before implementation?

## Run

```sh
npm run prototype:sleep-coach
```

Then open:

```text
http://localhost:5174
```

## Prototype Scope

- First-run schedule setup
- Editable sleep schedule after setup
- Bedtime preparation notification simulation
- Bedtime preparation page with direct "我睡觉了" action
- Wake reminder simulation
- Wake confirmation with direct "我起床了" action
- Morning activation prompts
- Daily report and seven-day trend

No persistence, no backend, no real notification permission, no HealthKit, no account system.

## Self QA

Validated on 2026-06-05 with Chrome headless through the full product path:

```text
首次打开
  -> 开始设置
  -> 保存作息
  -> 修改作息
  -> 睡前准备
  -> 我睡觉了
  -> 起床确认
  -> 我起床了
  -> 查看今日报告
```

Validated outcomes:

- The prototype opens at `http://localhost:5174`.
- First-run setup saves bedtime, wake time, and preparation lead time.
- Home has a visible "修改作息" entry after setup.
- Bedtime flow directly shows "我睡觉了"; there is no "我开始准备了" intermediate button.
- Wake flow directly shows "我起床了".
- Morning activation makes "查看今日报告" the primary next action.
- Daily report shows manual confirmation times and sleep window:
  - 睡觉：23:28
  - 起床：07:34
  - 睡眠窗口：8 小时 6 分钟
- Default user view does not show prototype debug navigation or JSON state.

Screenshots captured during QA:

- `/tmp/sleep-coach-shots/v2-01-onboarding.png`
- `/tmp/sleep-coach-shots/v2-02-home.png`
- `/tmp/sleep-coach-shots/v2-03-bedtime.png`
- `/tmp/sleep-coach-shots/v3-04-morning.png`
- `/tmp/sleep-coach-shots/v3-05-report.png`

## Current Verdict

This prototype is usable enough for product review. It fixes the major flow issues called out in the PRD:

- Schedule can be edited after initial setup.
- Bedtime has a direct "我睡觉了" action.
- Wake has a direct "我起床了" action.
- Report is based on manual sleep/wake confirmations.
- The UI direction is materially more premium than the current iOS MVP.

Remaining product-review questions:

- Whether the home screen should make the current time-window action even more dominant.
- Whether the report should feel more poetic or more data-forward.
- Whether the dark bedtime surface is calm enough or slightly too heavy.

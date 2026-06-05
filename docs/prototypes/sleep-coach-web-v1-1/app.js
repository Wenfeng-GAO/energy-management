const app = document.querySelector("#app");

const initialState = {
  screen: "onboarding",
  bedtime: "23:30",
  wake: "07:30",
  prepLead: 45,
  notifications: true,
  sleepConfirmedAt: null,
  wakeConfirmedAt: null,
  lastNotification: null,
  reportViewed: false
};

let state = { ...initialState };

const debugMode = new URLSearchParams(window.location.search).has("debug");

const screens = [
  ["onboarding", "初始"],
  ["setup", "设置"],
  ["home", "首页"],
  ["bedtime", "睡前"],
  ["wake", "起床"],
  ["report", "报告"]
];

function prepTime() {
  const [hours, minutes] = state.bedtime.split(":").map(Number);
  const date = new Date(2026, 5, 5, hours, minutes);
  date.setMinutes(date.getMinutes() - state.prepLead);
  return `${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`;
}

function minutesBetween(start, end) {
  const [sh, sm] = start.split(":").map(Number);
  const [eh, em] = end.split(":").map(Number);
  let startM = sh * 60 + sm;
  let endM = eh * 60 + em;
  if (endM <= startM) endM += 24 * 60;
  return endM - startM;
}

function sleepWindowText() {
  const start = state.sleepConfirmedAt || state.bedtime;
  const end = state.wakeConfirmedAt || state.wake;
  const minutes = minutesBetween(start, end);
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return m === 0 ? `${h} 小时` : `${h} 小时 ${m} 分钟`;
}

function setScreen(screen) {
  state.screen = screen;
  render();
}

function updateState(patch) {
  state = { ...state, ...patch };
  render();
}

function saveSettings() {
  const bedtime = document.querySelector("#bedtime").value;
  const wake = document.querySelector("#wake").value;
  const prepLead = Number(document.querySelector("#prepLead").value);
  updateState({
    bedtime,
    wake,
    prepLead,
    notifications: document.querySelector("#notifications").value === "true",
    lastNotification: null,
    screen: "home"
  });
}

function confirmSleep() {
  updateState({
    sleepConfirmedAt: "23:28",
    lastNotification: null,
    screen: "sleepDone"
  });
}

function confirmWake() {
  updateState({
    wakeConfirmedAt: "07:34",
    lastNotification: null,
    screen: "wakeDone"
  });
}

function resetPrototype() {
  state = { ...initialState };
  render();
}

function tools() {
  if (!debugMode) return "";
  return `
    <nav class="prototype-tools" aria-label="原型跳转">
      ${screens
        .map(
          ([id, label]) =>
            `<button class="tool-button ${state.screen === id ? "active" : ""}" onclick="setScreen('${id}')">${label}</button>`
        )
        .join("")}
      <button class="tool-button" onclick="updateState({ lastNotification: 'bedtime', screen: 'bedtime' })">模拟睡前提醒</button>
      <button class="tool-button" onclick="updateState({ lastNotification: 'wake', screen: 'wake' })">模拟起床提醒</button>
      <button class="tool-button" onclick="resetPrototype()">重置</button>
    </nav>
  `;
}

function topbar(backTarget = null) {
  return `
    <header class="topbar">
      <div class="brand"><span class="mark" aria-hidden="true"></span><span>睡眠教练</span></div>
      ${backTarget ? `<button class="ghost-button" onclick="setScreen('${backTarget}')">返回</button>` : ""}
    </header>
  `;
}

function debugState() {
  if (!debugMode) return "";
  return `<section class="debug-panel" aria-label="原型状态">${JSON.stringify(state, null, 2)}</section>`;
}

function onboarding() {
  return `
    ${tools()}
    <section class="screen">
      ${topbar()}
      <div class="hero-space">
        <h1>建立一个安静、稳定的睡眠节律。</h1>
        <p class="body-text">好的睡眠节律，会让身体更容易恢复，也让第二天醒来时多一点清醒和掌控感。</p>
      </div>
      <button class="primary-action" onclick="setScreen('setup')">开始设置</button>
    </section>
  `;
}

function setup(editing = false) {
  return `
      ${tools()}
      <section class="screen">
        ${topbar(editing ? "home" : null)}
        <h2>${editing ? "修改你的睡眠节律" : "设置你的睡眠节律"}</h2>
      <form class="settings-form" onsubmit="event.preventDefault(); saveSettings();">
        <div class="field">
          <label for="bedtime">睡觉时间</label>
          <input id="bedtime" type="time" value="${state.bedtime}" />
        </div>
        <div class="field">
          <label for="wake">起床时间</label>
          <input id="wake" type="time" value="${state.wake}" />
        </div>
        <div class="field">
          <label for="prepLead">睡前准备</label>
          <p class="field-hint">在睡觉前留一小段缓冲时间，提醒自己放下屏幕，慢慢安静下来。</p>
          <select id="prepLead">
            ${[15, 30, 45, 60, 90]
              .map((value) => `<option value="${value}" ${state.prepLead === value ? "selected" : ""}>提前 ${value} 分钟</option>`)
              .join("")}
          </select>
        </div>
        <div class="reminder-row" role="button" tabindex="0" onclick="toggleNotificationSetting()" onkeydown="if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); toggleNotificationSetting(); }">
          <input id="notifications" type="hidden" value="${state.notifications ? "true" : "false"}" />
          <div>
            <p class="reminder-title">提醒</p>
            <p class="reminder-copy">${state.notifications ? "睡前准备和起床时轻轻提醒你。" : "关闭后，只在打开 App 时看到提示。"}</p>
          </div>
          <span class="switch ${state.notifications ? "on" : ""}" aria-hidden="true"></span>
        </div>
      </form>
      <button class="primary-action" onclick="saveSettings()">${editing ? "保存修改" : "保存并进入首页"}</button>
    </section>
  `;
}

function toggleNotificationSetting() {
  const input = document.querySelector("#notifications");
  if (!input) return;
  input.value = input.value === "true" ? "false" : "true";
  const row = input.closest(".reminder-row");
  const switchEl = row.querySelector(".switch");
  const copy = row.querySelector(".reminder-copy");
  const enabled = input.value === "true";
  switchEl.classList.toggle("on", enabled);
  copy.textContent = enabled ? "睡前准备和起床时轻轻提醒你。" : "关闭后，只在打开 App 时看到提示。";
}

function home() {
  const sleepDone = Boolean(state.sleepConfirmedAt);
  const wakeDone = Boolean(state.wakeConfirmedAt);
  return `
    ${tools()}
    <section class="screen">
      ${topbar()}
      <h2>今日睡眠</h2>
      <div class="time-display">
        <div class="time-panel">
          <p class="time-label">睡觉</p>
          <p class="time-value">${state.bedtime}</p>
        </div>
        <div class="time-panel">
          <p class="time-label">起床</p>
          <p class="time-value">${state.wake}</p>
        </div>
      </div>
      <p class="fine">睡前准备 ${prepTime()} 开始。${state.notifications ? "提醒已计划。" : "提醒未开启。"}</p>
      ${
        state.lastNotification === "bedtime"
          ? `<div class="notification"><strong>睡前准备时间到了</strong>现在开始远离屏幕，降低灯光。</div>`
          : ""
      }
      ${
        state.lastNotification === "wake"
          ? `<div class="notification"><strong>该起床了</strong>轻轻开始今天，不要先刷手机。</div>`
          : ""
      }
      <div class="action-row">
        <button class="secondary-action" onclick="setScreen('setupEdit')">修改作息</button>
        <button class="secondary-action" onclick="setScreen('bedtime')">睡前准备</button>
        <button class="secondary-action" onclick="setScreen('wake')">起床确认</button>
        <button class="secondary-action" onclick="setScreen('report')">查看报告</button>
      </div>
      ${debugState()}
    </section>
  `;
}

function bedtime() {
  return `
    ${tools()}
    <section class="screen night bedtime-screen">
      ${topbar("home")}
      <h2>睡前准备</h2>
      <p class="body-text">距离睡觉时间还有 ${state.prepLead} 分钟。先把环境调到更容易入睡的状态。</p>
      <section class="sleep-science" aria-label="睡眠建议">
        <article class="sleep-tip">
          <span>01</span>
          <div>
            <h3>降低光线刺激</h3>
            <p>睡前减少屏幕和强光，让大脑更容易接收到夜晚信号。</p>
          </div>
        </article>
        <article class="sleep-tip">
          <span>02</span>
          <div>
            <h3>让卧室安静、偏凉、偏暗</h3>
            <p>稳定的睡眠环境，比临时补救更能帮助身体进入休息。</p>
          </div>
        </article>
        <article class="sleep-tip">
          <span>03</span>
          <div>
            <h3>避开临睡前刺激</h3>
            <p>尽量远离咖啡因、酒精、大餐和激烈运动，把最后一段时间留给放松。</p>
          </div>
        </article>
      </section>
      <p class="bedtime-note">准备好上床时，直接确认睡觉。</p>
      <button class="primary-action sleep-action" onclick="confirmSleep()">我睡觉了</button>
    </section>
  `;
}

function sleepDone() {
  return `
    ${tools()}
    <section class="screen night sleep-complete ritual-screen">
      ${topbar("home")}
      <div class="sleep-ritual" aria-hidden="true">
        <span class="sleep-orbit"></span>
        <span class="sleep-center"></span>
      </div>
      <h2>可以安心睡了</h2>
      <p class="body-text">今天到这里就好。把手机放远一点，让身体慢慢进入休息。</p>
      <div class="sleep-summary">
        <span>明早起床</span>
        <strong>${state.wake}</strong>
      </div>
      <button class="primary-action" onclick="setScreen('home')">回到首页</button>
    </section>
  `;
}

function wake() {
  return `
    ${tools()}
    <section class="screen morning">
      ${topbar("home")}
      <h2>早安</h2>
      <p class="body-text">现在确认起床，开始恢复清醒。这个确认会用于今日睡眠报告。</p>
      <div class="state-band">
        <p class="state-title">目标起床 ${state.wake}</p>
        <p class="body-text">${state.sleepConfirmedAt ? `昨晚已记录 ${state.sleepConfirmedAt} 睡觉。` : "昨晚还没有手动睡觉记录，报告会标记为数据不完整。"}</p>
      </div>
      <button class="primary-action" onclick="confirmWake()">我起床了</button>
    </section>
  `;
}

function wakeDone() {
  return `
      ${tools()}
      <section class="screen morning wake-complete ritual-screen">
        ${topbar("home")}
      <div class="wake-ritual" aria-hidden="true">
        <span class="wake-sun"></span>
        <span class="wake-ray ray-one"></span>
        <span class="wake-ray ray-two"></span>
        <span class="wake-ray ray-three"></span>
      </div>
      <h2>开始清醒</h2>
      <p class="body-text">先做一件小事，让身体比手机先醒来。</p>
      <ul class="suggestions">
        <li>喝几口水</li>
        <li>拉开窗帘，让房间变亮</li>
        <li>站起来活动一分钟</li>
      </ul>
      <div class="action-row">
        <button class="secondary-action" onclick="setScreen('home')">回到首页</button>
      </div>
      <button class="primary-action" onclick="setScreen('report')">查看今日报告</button>
    </section>
  `;
}

function report() {
  const complete = state.sleepConfirmedAt && state.wakeConfirmedAt;
  return `
    ${tools()}
    <section class="screen">
      ${topbar("home")}
      <h2>今日睡眠报告</h2>
      <section class="report-hero">
        <p class="report-number">${complete ? sleepWindowText() : "待完整"}</p>
        <p class="body-text">${complete ? "这是昨晚手动确认形成的睡眠窗口，不是医学睡眠时长。" : "缺少睡觉或起床确认，今天的报告会保持克制，不伪造完整数据。"}</p>
      </section>
      <section class="report-grid">
        <div class="metric"><span>昨晚睡觉</span><strong>${state.sleepConfirmedAt || "未确认"}</strong></div>
        <div class="metric"><span>今早起床</span><strong>${state.wakeConfirmedAt || "未确认"}</strong></div>
        <div class="metric"><span>目标睡觉</span><strong>${state.bedtime}</strong></div>
        <div class="metric"><span>目标起床</span><strong>${state.wake}</strong></div>
      </section>
      <section class="trend">
        <h3>七日节律</h3>
        <p class="body-text">最近七天保持接近 8 小时睡眠窗口。今晚继续在 ${prepTime()} 开始准备。</p>
        <div class="bars" aria-label="七日趋势低保真图">
          ${[72, 84, 78, 92, 66, 88, 82].map((h) => `<span class="bar" style="height:${h}%"></span>`).join("")}
        </div>
      </section>
      ${debugState()}
    </section>
  `;
}

function render() {
  const map = {
    onboarding,
    setup: () => setup(false),
    setupEdit: () => setup(true),
    home,
    bedtime,
    sleepDone,
    wake,
    wakeDone,
    report
  };
  app.innerHTML = map[state.screen]();
}

render();

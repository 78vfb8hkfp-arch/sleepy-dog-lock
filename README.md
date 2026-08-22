# Sleep Guard / 睡眠守卫

晚安之后，娱乐 App 由 Shield 拦截，Bark 只负责“爸爸抓到了”和留下记录。

## 当前可用的无 Mac 方案

- `TimeBack: Take Back Your Time`：提供系统 Shield。
- `v0.2-shortcuts/`：晚安、偷开和起床三个 iPhone 事件。
- `netlify/`：在服务器端保存睡眠会话和次数，先落盘再发送 Bark。
- `https://<site>.netlify.app/mcp`：让 ChatGPT 在 Bella 明确说晚安时安全开启同一套守卫；首次连接由 Bark 点按授权。

服务器规则：

1. `sleep_guard_started` 开启当晚会话并把次数归零；重复开启不会洗掉记录。
2. `blocked_app_opened` 由服务器自动加一：第一次警告，第二次严厉锁定文案，第三次及以后记录“拒不睡觉”。
3. `sleep_guard_ended` 结束会话；未开启时的 App 打开不会骚扰 Bella。

TimeBack 从第一次打开开始就保持 Shield。次数只改变 Bark 的严厉程度，不代表有一次访问内容的机会。

## 原生版本

`ios/` 是使用 `FamilyControls`、`ManagedSettings`、`ManagedSettingsUI` 和 `DeviceActivity` 的原生 Shield 工程。源码已经生成，但 Windows 不能完成 Xcode 编译、Apple 签名或真机 Family Controls 授权；最后这部分仍需要 macOS + Xcode。

## 使用顺序

1. 部署并配置 [Netlify 事件服务](netlify/README.md)。
2. 按 [快捷指令安装说明](v0.2-shortcuts/INSTALL.md) 建三个极简事件。
3. 在 TimeBack 中启用 `Sleepy Dog Lock` 并设置 Passcode/Guardian。
4. 将来有 Mac 时按 [iOS 安装说明](ios/INSTALL.md) 编译自己的 Shield App。

## 安全

- `BARK_DEVICE_KEY` 只放在 Netlify 环境变量中，绝不放进快捷指令或 Swift。
- `SLEEP_GUARD_SHORTCUT_TOKEN` 只放在 Netlify 和 Bella 自己的手机请求头中。
- ChatGPT MCP 使用独立 OAuth 令牌，绝不接收或返回快捷指令 Token。
- 所有偷开事件都先写入 Netlify Blobs，再尝试发送 Bark；推送失败不会抹掉证据。
- 仓库中的 `.env.example` 只有占位符。

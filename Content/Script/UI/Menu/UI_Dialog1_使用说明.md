# UI_Dialog1 AI对话系统使用说明

## ✨ 功能简介

`UI_Dialog1` 是一个集成了 LLM AI 功能的对话界面，支持：

- 💬 **对话气泡界面**：玩家和 AI 的对话以气泡形式显示
- ⚡ **流式输出**：AI 回复采用打字机效果，逐字显示
- 🤖 **智能对话**：基于通义千问大模型，支持自然语言理解
- 🔒 **防重复发送**：AI 回复期间自动锁定，防止重复请求

---

## 📋 已实现功能

### 1. **LLM 初始化配置**
- 自动初始化 LlmManager
- 配置通义千问 API（qwen-max 模型）
- 设置游戏世界观和 AI 角色定位

### 2. **对话气泡管理**
- 添加玩家消息气泡
- 添加 AI 消息气泡
- 支持设置角色名称和头像

### 3. **AI 流式对话**
- 发送用户输入到 LLM
- 实时接收并显示 AI 流式回复
- 完成回调处理成功/失败状态

### 4. **错误处理**
- 检查 LLM 管理器是否可用
- 显示错误信息到对话气泡
- 防止 AI 回复期间重复发送

---

## 🚀 快速开始

### 1. 使用 GM_Home 打开界面

确保你的场景使用 `GM_Home` GameMode，它会：
- 自动初始化 GameContext
- 打开 UI_Dialog1 界面
- 驱动 LLM 的 Tick（流式响应必须）

### 2. 在 UE 编辑器中设置

在 `UI_Dialog1` 蓝图中，确保以下组件已正确设置：

- **VerticalBox_Dialogs**: 对话气泡容器
- **CW_DialogBubble**: 对话气泡预制体（Widget Class 类型）
- **CW_InputText**: 输入框组件

### 3. 运行测试

1. 在 UE 编辑器中打开场景
2. 点击 Play
3. 在输入框中输入消息
4. 点击发送，等待 AI 流式回复

---

## 🔧 配置说明

### API Key 配置

在 `UI_Dialog1.lua` 的 `InitializeLLM()` 方法中修改：

```lua
self.llmMgr:SetApiKey("你的API Key")  -- 替换为你的通义千问 API Key
self.llmMgr:UseProvider("qwen")       -- 使用通义千问
self.llmMgr:SetModel("qwen-max")      -- 选择模型
```

### 世界观设定

修改 `SetGameWorld()` 来自定义 AI 的角色和行为：

```lua
self.llmMgr:SetGameWorld([[
你是一个友好、乐于助人的AI助手。
你可以和玩家自由对话，提供帮助和建议。
]])
```

---

## 📊 核心方法说明

### `InitializeLLM()`
初始化 LLM 管理器并配置 API。

**执行时机：** `Construct()` 中自动调用

### `OnSendInputText(text)`
用户点击发送按钮时触发。

**功能：**
1. 添加玩家消息气泡
2. 添加 AI 消息气泡（初始为空）
3. 发送请求到 LLM
4. 防止 AI 回复期间重复发送

**参数：**
- `text`: 用户输入的文本

### `OnAITextStream(delta)`
AI 流式回复回调（打字机效果）。

**功能：**
- 累积接收到的文本片段
- 实时更新 AI 对话气泡

**参数：**
- `delta`: 新收到的文本片段

### `OnAIReplyComplete(success, result)`
AI 回复完成回调。

**功能：**
- 处理成功/失败状态
- 显示完整回复或错误信息
- 解除回复锁定

**参数：**
- `success`: 是否成功
- `result`: 完整文本（成功）或错误信息（失败）

---

## ⚠️ 重要注意事项

### 1. **必须驱动 Tick**

LLM 的流式响应需要在 GameMode 的 `ReceiveTick` 中驱动：

```lua
function M:ReceiveTick(DeltaSeconds)
    local llmMgr = GameContext:GetLlmManager()
    if llmMgr and llmMgr.Tick then
        llmMgr:Tick(DeltaSeconds)
    end
end
```

✅ `GM_Home.lua` 已经实现了 Tick 驱动

### 2. **API Key 安全**

⚠️ **生产环境中不要直接硬编码 API Key！**

建议：
- 从配置文件读取
- 使用环境变量
- 通过后端服务器中转请求

### 3. **网络连接**

LLM 请求需要网络连接，确保：
- 有稳定的网络环境
- API 服务可访问（国内访问通义千问）
- 防火墙未拦截

---

## 🐛 常见问题

### Q1: AI 不回复，界面卡住？

**原因：** GameMode 未驱动 Tick

**解决：** 确保使用 `GM_Home` 或在你的 GameMode 中添加 Tick 驱动

### Q2: 提示"LLM管理器未初始化"？

**原因：** GameContext 未正确初始化

**解决：** 在 GameMode 的 `ReceiveBeginPlay` 中：
```lua
if not GameContext._isInitialized then
    GameContext:initialize(self)
end
```

### Q3: 提示 API 错误？

**原因：** API Key 无效或网络问题

**解决：**
1. 检查 API Key 是否正确
2. 确认网络连接正常
3. 查看控制台详细错误信息

### Q4: 流式输出不显示，一次性出现？

**原因：** Tick 未驱动或回调有问题

**解决：**
1. 确认 GameMode 的 Tick 正在运行
2. 检查控制台是否有错误日志

---

## 📚 参考文档

- **LLM 系统完整文档**: `Content/Script/GameLayer/Llm/LLM系统文档.md`
- **通义千问快速指南**: `Content/Script/GameLayer/Llm/QWEN_QUICKSTART.md`
- **测试用例**: `Content/Script/Test/QwenTest.lua`

---

## 🎯 下一步扩展

你可以基于此实现进行扩展：

1. **添加对话历史**：实现多轮对话上下文
2. **角色切换**：让 AI 扮演不同 NPC 角色
3. **工具调用**：让 AI 调用游戏功能（如打开背包、查询任务）
4. **语音输入/输出**：集成语音识别和 TTS
5. **多语言支持**：支持中文、英文等多语言

---

## 📞 技术支持

遇到问题？
1. 查看控制台日志定位错误
2. 参考 LLM 系统文档的常见问题章节
3. 查看测试用例代码示例

---

**祝你使用愉快！🎉**


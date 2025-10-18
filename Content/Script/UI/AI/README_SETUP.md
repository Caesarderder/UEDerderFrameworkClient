# AI聊天界面设置指南

## 🎯 目标
在UE中创建一个AI聊天界面，支持流式显示通义千问的回复（打字机效果）

---

## 📋 前置条件

- ✅ LLM系统已完整实现
- ✅ 通义千问API Key已配置
- ✅ GameContext已注册LlmManager

---

## 🚀 快速开始（两个版本）

### 方案A：简化版（推荐测试）

#### 1. 创建UMG Widget：`WBP_AIChat_Simple`

组件结构：
```
Canvas Panel
├── VerticalBox
    ├── TextBlock (ChatDisplay)
    │   - 多行显示
    │   - 启用Auto Wrap
    │   - 大小：填充
    ├── EditableTextBox (InputBox)
    │   - 单行输入
    │   - 提示文本："输入你的问题..."
    └── Button (SendButton)
        └── TextBlock "发送"
```

#### 2. 绑定Lua脚本

在UMG Widget的 **Class Settings** 中：
- **Parent Class**: `UserWidget`
- **Lua File Path**: `UI.AI.WBP_AIChat_Simple`

#### 3. 创建测试GameMode

创建蓝图 `BP_AITestGameMode`，绑定 `GameMode/GM_AITest.lua`

#### 4. 设置关卡

在你的测试关卡（Level）中：
- **World Settings** → **GameMode Override**: 选择 `BP_AITestGameMode`

#### 5. 运行测试

点击 **Play**，应该会自动显示AI聊天界面！

---

### 方案B：完整版（美观界面）

#### 1. 创建UMG Widget：`WBP_AIChat`

更复杂的界面布局：

```
Canvas Panel
├── VerticalBox (主容器, Fill, 1.0)
    ├── ScrollBox (ScrollBox_Messages, Fill, 1.0)
    │   └── VerticalBox (消息容器，动态添加子项)
    ├── Spacer (10px)
    ├── HorizontalBox (输入区域)
    │   ├── EditableTextBox (InputBox, Multiline, Fill, 1.0)
    │   └── Button (SendButton, 80x40)
    └── Border (TextBlock_Status)
        - 初始隐藏
        - 显示"AI思考中..."
```

**样式设置：**
- ScrollBox设置自动滚动
- InputBox启用多行输入
- 所有组件设置合适的Padding

#### 2. 绑定Lua脚本

- **Lua File Path**: `UI.AI.WBP_AIChat`

---

## ⚙️ 关键配置点

### 1. GameMode必须驱动Tick

```lua
-- GM_AITest.lua
function M:ReceiveTick(DeltaSeconds)
    local llmMgr = GameContext:GetLlmManager()
    if llmMgr and llmMgr.Tick then
        llmMgr:Tick(DeltaSeconds)  -- 关键！
    end
end
```

**为什么重要？**
- 流式请求使用协程实现
- 协程需要每帧驱动才能继续执行
- 没有Tick，流式显示不会工作

### 2. API Key配置

在Lua脚本中：
```lua
function M:InitializeLLM()
    self.llmMgr:SetApiKey("sk-592ab9ea805f48b68940ece20b7afa39")
    self.llmMgr:UseProvider("qwen")
    self.llmMgr:SetModel("qwen-max")
end
```

### 3. 流式回调

```lua
self.llmMgr:Chat(Consts.ChatType.GENERAL_CHAT, {
    userInput = userInput
}, function(delta)
    -- 每次收到新文本片段时调用
    self.currentText = self.currentText .. delta
    self.ChatDisplay:SetText(UE.FText(self.currentText))
end, function(success, fullText)
    -- 完成时调用
    print("完成:", fullText)
end)
```

---

## 🧪 测试步骤

### 第一步：验证LLM系统

在控制台运行：
```lua
local QwenTest = require("Test.QwenTest")
QwenTest:MinimalExample()
```

应该看到：
- `[LlmManager] LLM管理器初始化完成`
- `[LlmProviderSystem] Provider系统初始化完成`
- 等系统初始化日志

### 第二步：测试UI显示

1. 启动游戏
2. 应该自动弹出AI聊天界面
3. 输入框和按钮可见

### 第三步：测试流式输出

1. 在输入框输入："你好"
2. 点击发送
3. 观察AI回复是否**逐字显示**（打字机效果）

**预期效果：**
- 文字一个一个出现
- 不是一次性全部显示

---

## ⚠️ 常见问题

### Q1: AI回复一次性全部显示，没有流式效果

**原因**: GameMode的Tick没有驱动

**解决**:
1. 确认GameMode继承正确
2. 确认Tick函数被调用（添加print测试）
3. 确认调用了 `llmMgr:Tick(DeltaSeconds)`

### Q2: 点击发送后没有反应

**检查**:
1. 控制台是否有错误
2. API Key是否正确
3. 网络是否连接

**调试**:
```lua
function M:OnSendClicked()
    print("[Debug] 发送按钮被点击")
    print("[Debug] 输入内容:", userInput)
    -- ... 其他代码
end
```

### Q3: 报错"无法获取LLM管理器"

**原因**: GameContext未初始化

**解决**: 在GameMode的BeginPlay中：
```lua
if not GameContext._isInitialized then
    GameContext:initialize(self)
end
```

### Q4: UI卡顿或闪烁

**原因**: UI更新过于频繁

**优化**: 添加更新限流
```lua
-- 在流式回调中
self.updateCounter = (self.updateCounter or 0) + 1
if self.updateCounter % 3 == 0 then  -- 每3个chunk更新一次
    self.ChatDisplay:SetText(UE.FText(self.currentText))
end
```

### Q5: 无法输入中文

**解决**: 
- UE编辑器设置中启用IME输入
- 或使用UE自带的虚拟键盘

---

## 📊 性能优化

### 1. 限制消息数量
```lua
-- 保持最近50条消息
if #self.messageWidgets > 50 then
    local oldWidget = table.remove(self.messageWidgets, 1)
    oldWidget:RemoveFromParent()
end
```

### 2. 控制流式更新频率
```lua
-- 累积多个delta后再更新
if #self.deltaBuffer > 5 then
    local combined = table.concat(self.deltaBuffer)
    self:UpdateDisplay(combined)
    self.deltaBuffer = {}
end
```

### 3. 异步加载Widget
```lua
-- 使用异步加载避免卡顿
UE.UAssetManager.GetStreamableManager():RequestAsyncLoad(
    widgetPath,
    function() -- 加载完成回调
        -- 创建Widget
    end
)
```

---

## 🎨 美化建议

### 消息气泡样式
```lua
-- 用户消息：绿色气泡，右对齐
local userBg = UE.FLinearColor(0.85, 0.95, 0.85, 1.0)

-- AI消息：蓝色气泡，左对齐
local aiBg = UE.FLinearColor(0.9, 0.95, 1.0, 1.0)

-- 系统消息：灰色，居中
local systemBg = UE.FLinearColor(0.95, 0.95, 0.95, 1.0)
```

### 打字机动画增强
```lua
-- 添加光标闪烁效果
self.currentText = self.currentText .. delta .. "▌"
```

### 滚动动画
```lua
-- 平滑滚动到底部
UE.UKismetSystemLibrary.Delay(self, 0.05, function()
    self.ScrollBox:ScrollToEnd()
end)
```

---

## 📝 完整示例代码

### 最小化测试代码

```lua
-- 在Command Console中测试
local GameContext = require("Core.GameContext")
local Consts = require("Util.Consts")
local llmMgr = GameContext:GetLlmManager()

llmMgr:SetApiKey("sk-592ab9ea805f48b68940ece20b7afa39")
llmMgr:UseProvider("qwen")

llmMgr:Chat(Consts.ChatType.GENERAL_CHAT, {
    userInput = "你好"
}, function(delta)
    print("流式:", delta)
end, function(success, result)
    print("完成:", result)
end)
```

---

## 🆘 技术支持

如果遇到问题：
1. 查看控制台日志
2. 检查 `Content/Script/GameLayer/Llm/README.md`
3. 参考测试用例 `Content/Script/Test/QwenTest.lua`

---

## ✅ 检查清单

测试前确认：
- [ ] LLM系统文件都已创建
- [ ] GameContext已注册LlmManager
- [ ] GameMode绑定了Lua脚本
- [ ] GameMode的Tick函数正确实现
- [ ] Widget创建了必要的组件
- [ ] Widget绑定了Lua脚本
- [ ] API Key正确配置
- [ ] 网络连接正常

---

现在你可以开始创建和测试你的AI聊天界面了！🎉


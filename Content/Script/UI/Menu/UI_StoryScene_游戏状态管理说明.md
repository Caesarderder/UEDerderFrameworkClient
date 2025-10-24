# UI_StoryScene 游戏状态管理功能说明

## 📋 功能概述

在执行场景关键抉择后，AI演绎完成，系统会自动检查游戏状态并执行相应操作：

1. **继续循环**：保持在角色对话界面，玩家可以继续输入对话
2. **开启新循环**：退回到地图界面，开始新的循环，并显示循环次数
3. **终止循环**：直接回退到 UI_Home 主菜单

## 🔧 技术实现

### 1. 数据层支持（BM_StoryRuntime）

新增了游戏结束状态管理方法：

```lua
-- 设置游戏结束状态
BM_StoryRuntime:SetGameEnded(isEnded, endingType, reason)

-- 获取游戏是否已结束
BM_StoryRuntime:IsGameEnded()

-- 获取结局类型（good/bad/neutral）
BM_StoryRuntime:GetEndingType()

-- 获取结束原因
BM_StoryRuntime:GetEndingReason()

-- 设置新循环标记
BM_StoryRuntime:SetShouldStartNewLoop(shouldStartNewLoop)

-- 获取是否应该开启新循环
BM_StoryRuntime:GetShouldStartNewLoop()
```

### 2. AI 工具调用（GameStoryTools）

AI 可以在演绎抉择叙事时调用以下工具：

#### 工具1：continue_cur_loop（继续当前循环）
```lua
{
    name = "continue_cur_loop",
    description = "继续当前循环，故事继续（抉择后果不触发循环重置）",
    parameters = {
        reason = "继续原因"
    }
}
```

#### 工具2：start_new_loop（开启新循环）
```lua
{
    name = "start_new_loop",
    description = "结束当前循环，开始新的一次循环（用于灾难/死亡事件）",
    parameters = {
        reason = "重置原因，如'灾难发生'、'玩家死亡'"
    }
}
```

#### 工具3：end_loop（终止循环）
```lua
{
    name = "end_loop",
    description = "结束循环，故事结束（玩家达成了终止循环的条件）",
    parameters = {
        reason = "结束原因",
        endingType = "结局类型：good/bad/neutral"
    }
}
```

### 3. UI 层响应（UI_StoryScene）

#### 关键方法：CheckAndHandleGameState()

在抉择叙事完成后自动调用，检查游戏状态并执行对应操作：

```lua
function M:CheckAndHandleGameState()
    local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
    
    -- 1. 检查游戏是否结束（优先级最高）
    if BM_StoryRuntime:IsGameEnded() then
        -- 延迟5秒后退回到 UI_Home
        self:AddTimer(5.0, function()
            self:BackToMainMenu()
        end, false)
        return
    end
    
    -- 2. 检查是否应该开启新循环
    if BM_StoryRuntime:GetShouldStartNewLoop() then
        -- 更新地图Widget的循环次数显示
        self:UpdateMapLoopCountDisplay(loopCount)
        
        -- 延迟3秒后返回地图
        self:AddTimer(3.0, function()
            self:BackToMap()
        end, false)
        return
    end
    
    -- 3. 默认：继续当前循环
    -- 延迟3秒自动隐藏对话覆盖层（玩家可以继续对话）
    self.dialogOverlayTimer = self:AddTimer(3.0, function()
        self:HideDialogOverlay()
    end, false)
end
```

#### 辅助方法：UpdateMapLoopCountDisplay()

更新地图Widget的循环次数显示：

```lua
function M:UpdateMapLoopCountDisplay(loopCount)
    -- 构建带循环次数的文本
    local loopPrefix = string.format("【第 %d 次循环】\n\n", loopCount)
    local fullText = loopPrefix .. self:BuildStoryInfoText(displayData)
    
    -- 更新 Text_Map
    self.currentStoryMapWidget.Text_Map:SetText(fullText)
end
```

## 🎮 使用流程

### 场景1：继续循环

1. 玩家执行抉择
2. AI生成叙事，调用 `continue_cur_loop` 工具
3. UI显示叙事内容
4. 3秒后自动隐藏对话覆盖层
5. 玩家可以继续在当前场景对话

### 场景2：开启新循环

1. 玩家执行抉择
2. AI判断触发循环重置（如死亡、灾难等），调用 `start_new_loop` 工具
3. `BM_StoryRuntime:StartNewLoop()` 执行循环重置
4. UI显示叙事内容（包含循环原因）
5. 更新地图Widget显示循环次数
6. 3秒后退回到地图界面
7. 玩家可以重新选择场景开始新循环

### 场景3：终止循环

1. 玩家执行抉择
2. AI判断达成终止条件，调用 `end_loop` 工具
3. `BM_StoryRuntime:SetGameEnded()` 设置游戏结束状态
4. UI显示结局叙事（带emoji和结局类型）
5. 5秒后自动返回 UI_Home 主菜单

## 📊 状态优先级

```
终止循环（end_loop） > 开启新循环（start_new_loop） > 继续循环（continue_cur_loop）
```

## 🔥 关键特性

1. **自动状态检测**：抉择叙事完成后自动检查游戏状态
2. **延迟处理**：给玩家足够时间阅读AI演绎内容
   - 继续循环：3秒后隐藏覆盖层
   - 开启新循环：3秒后返回地图
   - 终止循环：5秒后返回主菜单
3. **循环次数显示**：地图Widget自动显示当前循环次数
4. **状态持久化**：游戏状态保存在 `BM_StoryRuntime` 中

## 🎨 UI体验

- 继续循环：玩家可以无缝继续对话
- 开启新循环：清晰的循环次数提示 "【第 X 次循环】"
- 终止循环：带emoji的结局提示（🎉好结局/💔坏结局/🌟中性结局）

## 📝 注意事项

1. AI必须在演绎叙事时调用相应的工具（`continue_cur_loop`/`start_new_loop`/`end_loop`）
2. 如果AI没有调用任何工具，默认执行"继续循环"流程
3. 循环次数从1开始（第0次表示未开始循环）
4. 地图Widget必须有 `Text_Map` 组件才能显示循环次数

## 🔗 相关文件

- `DataLayer/Story/BM_StoryRuntime.lua` - 数据层状态管理
- `GameLayer/GameStory/GameStoryTools.lua` - AI工具注册
- `UI/Menu/UI_StoryScene.lua` - UI层响应逻辑
- `GameLayer/Story/SceneStateManager.lua` - 场景状态管理器

## 🚀 扩展建议

1. 可以添加更多结局类型
2. 可以在结局界面显示统计数据（总循环次数、完成时间等）
3. 可以添加音效和动画效果增强体验
4. 可以保存结局历史记录


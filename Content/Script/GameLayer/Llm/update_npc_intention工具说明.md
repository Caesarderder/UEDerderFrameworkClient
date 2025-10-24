# update_npc_intention 工具说明

## 功能
动态更新NPC的当前意图状态，让AI可以根据对话进展灵活调整NPC的态度和行为导向。

## 工具定义

```lua
{
    name = "update_npc_intention",
    description = "根据对话进展动态更新NPC的当前意图状态",
    parameters = {
        npcId = "NPC的ID",
        newIntention = "NPC的新意图（必填）",
        reason = "更新原因（可选）"
    }
}
```

## AI调用示例

### 场景1：从试探到信任
```json
{
  "npcId": "liwenshu",
  "newIntention": "主角展现出真诚，决定透露关于柳珩落榜的隐情",
  "reason": "主角承诺保护我的饭碗"
}
```

### 场景2：从掩饰到警觉
```json
{
  "npcId": "liuheng",
  "newIntention": "主角开始怀疑我，必须更加小心掩饰计划，同时准备应对方案",
  "reason": "主角问到了黄磷粉的事"
}
```

### 场景3：从恐惧到安心
```json
{
  "npcId": "zhangpopo",
  "newIntention": "官老爷解释了真相，不再那么害怕，愿意配合调查",
  "reason": "推官说帽妖是假的"
}
```

## 在提示词中启用

在ChatType的systemPrompt中添加此工具到tools列表：

```lua
-- LlmPromptConfig.lua
character_dialogue = {
    systemPrompt = [[...]],
    tools = {"unlock_choice", "update_npc_intention"},  -- 添加工具
    temperature = 0.8,
    maxTokens = 300
}
```

## 事件监听

UI层需要监听`OnNpcIntentionChanged`事件来处理实际更新：

```lua
-- UI_StoryScene.lua
EventSystem:RegisterEvent("OnNpcIntentionChanged", function(data)
    local npcId = data.npcId
    local newIntention = data.newIntention
    
    -- 更新缓存中的NPC信息
    if self.sceneCharactersCache[npcId] then
        self.sceneCharactersCache[npcId].currentIntention = newIntention
        print(string.format("[NPC意图更新] %s: %s", npcId, newIntention))
    end
end)
```

## 使用场景

### 1. 对话中态度转变
```
玩家：我知道柳珩的计划，但我想帮他
AI：*眼神闪烁* "你...真的想帮他？"
→ 调用update_npc_intention("liuheng", "主角表现出善意，开始犹豫是否可以信任")
```

### 2. 发现关键线索后
```
玩家：【出示证据】这是你的黄磷粉吧？
AI：*脸色骤变* "你...你怎么知道..."
→ 调用update_npc_intention("liuheng", "被识破了，必须立即警觉，考虑加速计划")
```

### 3. 成功说服后
```
玩家：其实我也经历过和你一样的不公...
AI：*沉默* "原来...你也..."
→ 调用update_npc_intention("liuheng", "主角的经历触动了我，开始反思自己的计划")
```

## 优势

1. **动态性**：AI可以根据对话实时调整NPC状态
2. **灵活性**：不需要预定义所有状态转换
3. **自然性**：AI自己判断何时该改变态度
4. **追踪性**：通过reason参数记录转变原因

## 注意事项

- 新意图应该简洁明确（1-2句话）
- 描述"想做什么"而非"是什么"
- 可以包含条件性的反应（"如果...则..."）


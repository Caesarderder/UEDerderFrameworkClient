local BusinessModule = require("Core.DataLayerBase.BusinessModule")
local DM_StoryConfig = require("DataLayer.Story.DM_StoryConfig")

---故事配置业务模块
---提供配置数据的读取和设置接口
---@class BM_StoryConfig : BusinessModule
---@type BM_StoryConfig
local BM_StoryConfig = {
    ---@type DM_StoryConfig
    dataModule = DM_StoryConfig
}

setmetatable(BM_StoryConfig, { __index = BusinessModule })

-- ==================== 游戏背景 ====================

---设置游戏背景
---@param background string 背景文本
---@param theme string|nil 主题
---@param mainConflict string|nil 主要冲突
function BM_StoryConfig:SetBackground(background, theme, mainConflict)
    self.dataModule.background = background
    if theme then self.dataModule.theme = theme end
    if mainConflict then self.dataModule.mainConflict = mainConflict end
end

---获取游戏背景（用于Prompt）
---@return string 背景描述
function BM_StoryConfig:GetBackgroundPrompt()
    local parts = {}
    table.insert(parts, "# 故事背景")
    table.insert(parts, self.dataModule.background)
    if self.dataModule.mainConflict ~= "" then
        table.insert(parts, "\n主要冲突: " .. self.dataModule.mainConflict)
    end
    return table.concat(parts, "\n")
end

-- ==================== 场景配置 ====================

---添加场景配置
---@param sceneConfig table 场景配置
function BM_StoryConfig:AddScene(sceneConfig)
    if not sceneConfig.id then
        print("[BM_StoryConfig] 错误：场景配置缺少id字段")
        return
    end
    self.dataModule.scenes[sceneConfig.id] = sceneConfig
end

---获取场景配置
---@param sceneId string 场景ID
---@return table|nil 场景配置
function BM_StoryConfig:GetScene(sceneId)
    return self.dataModule.scenes[sceneId]
end

---获取所有场景ID列表
---@return table 场景ID数组
function BM_StoryConfig:GetAllSceneIds()
    local ids = {}
    for id, _ in pairs(self.dataModule.scenes) do
        table.insert(ids, id)
    end
    return ids
end

---获取初始场景ID
---@return string 初始场景ID
function BM_StoryConfig:GetStartScene()
    return self.dataModule.startScene
end

---获取场景Prompt（用于LLM）
---@param sceneId string 场景ID
---@return string|nil 场景描述Prompt
function BM_StoryConfig:GetScenePrompt(sceneId)
    local scene = self.dataModule.scenes[sceneId]
    if not scene then return nil end
    
    local parts = {}
    table.insert(parts, "## 当前场景: " .. scene.name)
    table.insert(parts, scene.description)
    if scene.atmosphere then
        table.insert(parts, "\n氛围: " .. scene.atmosphere)
    end
    
    -- 添加可互动NPC列表
    if scene.npcIds and #scene.npcIds > 0 then
        table.insert(parts, "\n可互动角色: " .. table.concat(scene.npcIds, ", "))
    end
    
    return table.concat(parts, "\n")
end

---获取场景抉择生成指导Prompt（用于约束AI生成抉择）
---@param sceneId string 场景ID
---@return string|nil 抉择生成指导Prompt
function BM_StoryConfig:GetSceneChoiceGuidancePrompt(sceneId)
    local scene = self.dataModule.scenes[sceneId]
    if not scene or not scene.choiceGuidance then return nil end
    
    local guidance = scene.choiceGuidance
    local parts = {}
    
    table.insert(parts, "## 本场景抉择生成指导")
    table.insert(parts, "\n**重要：你在生成抉择时必须遵循以下规则！**")
    
    -- 允许的抉择类型
    if guidance.allowedTypes and #guidance.allowedTypes > 0 then
        table.insert(parts, "\n### 允许的抉择类型")
        for _, typeStr in ipairs(guidance.allowedTypes) do
            table.insert(parts, "- " .. typeStr)
        end
    end
    
    -- 约束条件
    if guidance.constraints and #guidance.constraints > 0 then
        table.insert(parts, "\n### 约束条件")
        for _, constraint in ipairs(guidance.constraints) do
            table.insert(parts, "- " .. constraint)
        end
    end
    
    -- 推荐示例
    if guidance.examples and #guidance.examples > 0 then
        table.insert(parts, "\n### 推荐的抉择示例（仅供参考）")
        table.insert(parts, "你可以参考以下示例，但不要照搬，要根据对话内容动态生成：")
        for _, example in ipairs(guidance.examples) do
            table.insert(parts, "- \"" .. example .. "\"")
        end
    end
    
    return table.concat(parts, "\n")
end

-- ==================== NPC模板 ====================

---添加NPC模板
---@param npcTemplate table NPC模板
function BM_StoryConfig:AddNPC(npcTemplate)
    if not npcTemplate.id then
        print("[BM_StoryConfig] 错误：NPC模板缺少id字段")
        return
    end
    self.dataModule.npcTemplates[npcTemplate.id] = npcTemplate
end

---获取NPC模板
---@param npcId string NPC ID
---@return table|nil NPC模板
function BM_StoryConfig:GetNPC(npcId)
    return self.dataModule.npcTemplates[npcId]
end

---获取NPC Prompt（用于LLM扮演角色）
---@param npcId string NPC ID
---@return string|nil NPC描述Prompt
function BM_StoryConfig:GetNPCPrompt(npcId)
    local npc = self.dataModule.npcTemplates[npcId]
    if not npc then return nil end
    
    local parts = {}
    table.insert(parts, "# 角色: " .. npc.name)
    table.insert(parts, "角色定位: " .. (npc.role or ""))
    table.insert(parts, "性格: " .. npc.personality)
    table.insert(parts, "动机: " .. npc.motivation)
    table.insert(parts, "对话风格: " .. npc.dialogueStyle)
    if npc.background and npc.background ~= "" then
        table.insert(parts, "\n背景故事:\n" .. npc.background)
    end
    
    return table.concat(parts, "\n")
end

---获取场景内所有NPC的Prompt
---@param sceneId string 场景ID
---@return string 所有NPC描述
function BM_StoryConfig:GetSceneNPCsPrompt(sceneId)
    local scene = self.dataModule.scenes[sceneId]
    if not scene or not scene.npcIds then return "" end
    
    local parts = {}
    table.insert(parts, "## 场景角色")
    
    for _, npcId in ipairs(scene.npcIds) do
        local npc = self.dataModule.npcTemplates[npcId]
        if npc then
            table.insert(parts, string.format(
                "\n### %s (%s)\n- 性格: %s\n- 动机: %s\n- 对话风格: %s",
                npc.name, npc.id, npc.personality, npc.motivation, npc.dialogueStyle
            ))
        end
    end
    
    return table.concat(parts, "\n")
end

-- ==================== 抉择模板 ====================

---添加抉择模板
---@param choiceTemplate table 抉择模板
function BM_StoryConfig:AddChoice(choiceTemplate)
    if not choiceTemplate.id then
        print("[BM_StoryConfig] 错误：抉择模板缺少id字段")
        return
    end
    self.dataModule.choiceTemplates[choiceTemplate.id] = choiceTemplate
end

---获取抉择模板
---@param choiceId string 抉择ID
---@return table|nil 抉择模板
function BM_StoryConfig:GetChoice(choiceId)
    return self.dataModule.choiceTemplates[choiceId]
end

---获取场景的所有抉择模板
---@param sceneId string 场景ID
---@return table 抉择模板数组
function BM_StoryConfig:GetSceneChoices(sceneId)
    local choices = {}
    for _, choice in pairs(self.dataModule.choiceTemplates) do
        if choice.sceneId == sceneId then
            table.insert(choices, choice)
        end
    end
    return choices
end

-- ==================== 批量导入/导出 ====================

-- ==================== 展示层（玩家可见） ====================

---获取展示内容（玩家可见的故事介绍）
---@return string|nil 格式化后的展示文本
function BM_StoryConfig:GetDisplayContent()
    if not self.dataModule.configData then
        print("[BM_StoryConfig] 错误：配置数据未加载")
        return nil
    end
    
    -- 如果配置提供了GetDisplayContent方法，直接调用
    if self.dataModule.configData.GetDisplayContent then
        return self.dataModule.configData.GetDisplayContent()
    end
    
    -- 否则返回display字段
    if self.dataModule.configData.display then
        return self.dataModule.configData.display
    end
    
    return nil
end

---获取展示层配置（用于自定义UI渲染）
---@return table|nil 展示层数据
function BM_StoryConfig:GetDisplayConfig()
    if not self.dataModule.configData then
        return nil
    end
    return self.dataModule.configData.display
end

-- ==================== 批量导入/导出 ====================

---从配置表批量导入（用于配置文件加载）
---@param configData table 配置数据
function BM_StoryConfig:ImportConfig(configData)
    -- 保存原始配置数据（包含display和GetDisplayContent）
    self.dataModule.configData = configData
    -- 导入背景
    if configData.background then
        self:SetBackground(
            configData.background.text or "",
            configData.background.theme,
            configData.background.mainConflict
        )
    end
    
    -- 导入场景
    if configData.scenes then
        local firstSceneId = nil
        for index, scene in ipairs(configData.scenes) do
            self:AddScene(scene)
            -- 记录第一个场景ID
            if index == 1 then
                firstSceneId = scene.id
            end
        end
        
        -- 设置初始场景
        if configData.startScene then
            -- 方式1：配置中明确指定了初始场景
            self.dataModule.startScene = configData.startScene
        elseif firstSceneId then
            -- 方式2：使用第一个定义的场景作为初始场景
            self.dataModule.startScene = firstSceneId
        end
    end
    
    -- 导入NPC
    if configData.npcs then
        for _, npc in ipairs(configData.npcs) do
            self:AddNPC(npc)
        end
    end
    
    -- 导入抉择
    if configData.choices then
        for _, choice in ipairs(configData.choices) do
            self:AddChoice(choice)
        end
    end
    
    self.dataModule.isConfigured = true
    print("[BM_StoryConfig] 配置导入完成")
    print(string.format("  - 场景数: %d", self:GetSceneCount()))
    print(string.format("  - NPC数: %d", self:GetNPCCount()))
    print(string.format("  - 抉择数: %d", self:GetChoiceCount()))
    if self.dataModule.startScene ~= "" then
        print(string.format("  - 初始场景: %s", self.dataModule.startScene))
    end
end

---获取场景数量
---@return number
function BM_StoryConfig:GetSceneCount()
    local count = 0
    for _ in pairs(self.dataModule.scenes) do count = count + 1 end
    return count
end

---获取NPC数量
---@return number
function BM_StoryConfig:GetNPCCount()
    local count = 0
    for _ in pairs(self.dataModule.npcTemplates) do count = count + 1 end
    return count
end

---获取抉择数量
---@return number
function BM_StoryConfig:GetChoiceCount()
    local count = 0
    for _ in pairs(self.dataModule.choiceTemplates) do count = count + 1 end
    return count
end

---清空所有配置
function BM_StoryConfig:Clear()
    self.dataModule.background = ""
    self.dataModule.theme = "时间循环"
    self.dataModule.mainConflict = ""
    self.dataModule.scenes = {}
    self.dataModule.npcTemplates = {}
    self.dataModule.choiceTemplates = {}
    self.dataModule.isConfigured = false
    print("[BM_StoryConfig] 配置已清空")
end

---调试打印（详细版）
function BM_StoryConfig:DebugPrint()
    print("\n" .. string.rep("=", 70))
    print("【固定数据层】BM_StoryConfig - 故事配置数据")
    print(string.rep("=", 70))
    
    -- 基本信息
    print("\n[基本信息]")
    print("  主题:", self.dataModule.theme)
    print("  配置完成:", self.dataModule.isConfigured)
    print("  主要冲突:", self.dataModule.mainConflict)
    
    -- 场景列表
    print("\n[场景配置] 共", self:GetSceneCount(), "个场景")
    local sceneIndex = 1
    for sceneId, scene in pairs(self.dataModule.scenes) do
        print(string.format("  %d. [%s] %s", sceneIndex, sceneId, scene.name))
        print(string.format("     描述: %s", scene.description or "无"))
        if scene.npcIds and #scene.npcIds > 0 then
            print(string.format("     NPC数: %d (%s)", #scene.npcIds, table.concat(scene.npcIds, ", ")))
        end
        if scene.choiceIds and #scene.choiceIds > 0 then
            print(string.format("     抉择数: %d", #scene.choiceIds))
        end
        sceneIndex = sceneIndex + 1
    end
    
    -- NPC模板
    print("\n[NPC模板] 共", self:GetNPCCount(), "个NPC")
    local npcIndex = 1
    for npcId, npc in pairs(self.dataModule.npcTemplates) do
        print(string.format("  %d. [%s] %s (%s)", npcIndex, npcId, npc.name, npc.role))
        print(string.format("     性格: %s", npc.personality))
        if npc.initialStates then
            local states = npc.initialStates
            print(string.format("     初始状态: trust=%d, emotion=%d, relation=%d", 
                states.trust or 0, states.emotion or 0, states.relation or 0))
        end
        npcIndex = npcIndex + 1
    end
    
    -- 抉择模板
    print("\n[抉择模板] 共", self:GetChoiceCount(), "个抉择")
    local choiceIndex = 1
    for choiceId, choice in pairs(self.dataModule.choiceTemplates) do
        print(string.format("  %d. [%s] %s", choiceIndex, choiceId, choice.name))
        print(string.format("     所属场景: %s", choice.sceneId))
        choiceIndex = choiceIndex + 1
    end
    
    print("\n" .. string.rep("=", 70) .. "\n")
end

return BM_StoryConfig


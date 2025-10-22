local BusinessModule = require("Core.DataLayerBase.BusinessModule")
local DM_GameStory = require("DataLayer.GameStory.DM_GameStory")

---游戏故事业务模块
---处理游戏故事相关的业务逻辑
---@class BM_GameStory : BusinessModule
---@type BM_GameStory
local BM_GameStory = {
    ---@type DM_GameStory
    dataModule = DM_GameStory
}

setmetatable(BM_GameStory, { __index = BusinessModule })

---保存游戏背景设定（第1步）
---@param backgroundText string 游戏背景文本
---@param sceneType string 场景类型
---@param disasterType string 灾难类型
function BM_GameStory:SaveGameBackground(backgroundText, sceneType, disasterType)
    -- 保存背景文本
    self.dataModule.gameBackground = backgroundText
    
    -- 保存场景和灾难类型
    self.dataModule.sceneType = sceneType
    self.dataModule.disasterType = disasterType
    
    print("[BM_GameStory] 游戏背景设定已保存")
    print("  - 场景类型:", sceneType)
    print("  - 灾难类型:", disasterType)
    print("  - 背景文本长度:", #backgroundText)
end

---保存完整的游戏故事数据（由AI生成）
---@param gameBackground string 游戏背景设定
---@param roleRelationShip string 角色关系网JSON字符串
---@param storyLine string 故事线文本
---@param keyStoryPoints string|nil 关键剧情点JSON字符串（可选）
---@return boolean success 是否保存成功
function BM_GameStory:SaveGameStory(gameBackground, roleRelationShip, storyLine, keyStoryPoints)
    local json = require("rapidjson")
    
    -- 保存游戏背景
    self.dataModule.gameBackground = gameBackground
    
    -- 解析并保存角色关系网
    local success, characters = pcall(json.decode, roleRelationShip)
    if success and characters then
        self.dataModule.characters = characters
        
        -- 分类存储角色（根据type字段）
        self:CategorizeCharacters(characters)
    else
        print("[BM_GameStory] 警告：角色关系网JSON解析失败")
    end
    
    -- 保存故事线
    self.dataModule.storyLine = storyLine
    
    -- 解析并保存关键剧情点（如果提供）
    if keyStoryPoints and keyStoryPoints ~= "" then
        local success2, points = pcall(json.decode, keyStoryPoints)
        if success2 and points then
            self.dataModule.keyStoryPoints = points
        end
    end
    
    -- 更新元数据
    self.dataModule.isGenerated = true
    self.dataModule.generatedTime = os.time()
    
    print("[BM_GameStory] 游戏故事数据已保存")
    return true
end

---分类存储角色
---@param characters table 角色列表
function BM_GameStory:CategorizeCharacters(characters)
    -- 清空现有分类
    self.dataModule.protagonist = nil
    self.dataModule.enemy = nil
    self.dataModule.mainNPCs = {}
    self.dataModule.minorNPCs = {}
    
    -- 遍历角色并分类
    for _, character in ipairs(characters) do
        local charType = character.type or character.role
        
        if charType == "protagonist" or charType == "主角" then
            self.dataModule.protagonist = character
        elseif charType == "enemy" or charType == "仇人" then
            self.dataModule.enemy = character
        elseif charType == "main_npc" or charType == "主要NPC" then
            table.insert(self.dataModule.mainNPCs, character)
        elseif charType == "minor_npc" or charType == "次要NPC" then
            table.insert(self.dataModule.minorNPCs, character)
        end
    end
end

---获取游戏背景
---@return string 游戏背景文本
function BM_GameStory:GetGameBackground()
    return self.dataModule.gameBackground
end

---获取所有角色
---@return table 角色列表
function BM_GameStory:GetAllCharacters()
    return self.dataModule.characters
end

---获取主角信息
---@return table|nil 主角数据
function BM_GameStory:GetProtagonist()
    return self.dataModule.protagonist
end

---获取仇人信息
---@return table|nil 仇人数据
function BM_GameStory:GetEnemy()
    return self.dataModule.enemy
end

---获取指定名称的角色
---@param name string 角色名称
---@return table|nil 角色数据
function BM_GameStory:GetCharacterByName(name)
    for _, character in ipairs(self.dataModule.characters) do
        if character.name == name then
            return character
        end
    end
    return nil
end

---获取故事线
---@return string 故事线文本
function BM_GameStory:GetStoryLine()
    return self.dataModule.storyLine
end

---获取关键剧情点
---@return table 关键剧情点列表
function BM_GameStory:GetKeyStoryPoints()
    return self.dataModule.keyStoryPoints
end

---获取指定索引的剧情点
---@param index number 剧情点索引
---@return table|nil 剧情点数据
function BM_GameStory:GetStoryPointByIndex(index)
    return self.dataModule.keyStoryPoints[index]
end

---检查游戏故事是否已生成
---@return boolean 是否已生成
function BM_GameStory:IsGenerated()
    return self.dataModule.isGenerated
end

---设置场景类型
---@param sceneType string 场景类型
function BM_GameStory:SetSceneType(sceneType)
    self.dataModule.sceneType = sceneType
end

---获取场景类型
---@return string 场景类型
function BM_GameStory:GetSceneType()
    return self.dataModule.sceneType
end

---设置灾难类型
---@param disasterType string 灾难类型
function BM_GameStory:SetDisasterType(disasterType)
    self.dataModule.disasterType = disasterType
end

---获取灾难类型
---@return string 灾难类型
function BM_GameStory:GetDisasterType()
    return self.dataModule.disasterType
end

---保存灾难计划详情
---@param planDetails string 灾难计划文本
function BM_GameStory:SaveDisasterPlan(planDetails)
    self.dataModule.disasterPlan = planDetails
end

---获取灾难计划详情
---@return string 灾难计划文本
function BM_GameStory:GetDisasterPlan()
    return self.dataModule.disasterPlan
end

---导出为JSON（用于保存/读档）
---@return string JSON字符串
function BM_GameStory:ExportToJSON()
    local json = require("rapidjson")
    
    local exportData = {
        gameBackground = self.dataModule.gameBackground,
        sceneType = self.dataModule.sceneType,
        disasterType = self.dataModule.disasterType,
        characters = self.dataModule.characters,
        storyLine = self.dataModule.storyLine,
        keyStoryPoints = self.dataModule.keyStoryPoints,
        disasterPlan = self.dataModule.disasterPlan,
        isGenerated = self.dataModule.isGenerated,
        generatedTime = self.dataModule.generatedTime,
        version = self.dataModule.version
    }
    
    return json.encode(exportData)
end

---从JSON导入（用于读档）
---@param jsonString string JSON字符串
---@return boolean success 是否导入成功
function BM_GameStory:ImportFromJSON(jsonString)
    local json = require("rapidjson")
    
    local success, data = pcall(json.decode, jsonString)
    if not success or not data then
        print("[BM_GameStory] JSON导入失败")
        return false
    end
    
    -- 恢复数据
    self.dataModule.gameBackground = data.gameBackground or ""
    self.dataModule.sceneType = data.sceneType or "校园"
    self.dataModule.disasterType = data.disasterType or "爆炸"
    self.dataModule.characters = data.characters or {}
    self.dataModule.storyLine = data.storyLine or ""
    self.dataModule.keyStoryPoints = data.keyStoryPoints or {}
    self.dataModule.disasterPlan = data.disasterPlan or ""
    self.dataModule.isGenerated = data.isGenerated or false
    self.dataModule.generatedTime = data.generatedTime or 0
    self.dataModule.version = data.version or "1.0"
    
    -- 重新分类角色
    if #self.dataModule.characters > 0 then
        self:CategorizeCharacters(self.dataModule.characters)
    end
    
    print("[BM_GameStory] 游戏故事数据已导入")
    return true
end

---清空所有数据
function BM_GameStory:Clear()
    self.dataModule.gameBackground = ""
    self.dataModule.characters = {}
    self.dataModule.protagonist = nil
    self.dataModule.enemy = nil
    self.dataModule.mainNPCs = {}
    self.dataModule.minorNPCs = {}
    self.dataModule.storyLine = ""
    self.dataModule.keyStoryPoints = {}
    self.dataModule.disasterPlan = ""
    self.dataModule.isGenerated = false
    self.dataModule.generatedTime = 0
    
    print("[BM_GameStory] 游戏故事数据已清空")
end

---打印调试信息
function BM_GameStory:DebugPrint()
    print("==================== 游戏故事数据 ====================")
    print("是否已生成:", self.dataModule.isGenerated)
    print("生成时间:", os.date("%Y-%m-%d %H:%M:%S", self.dataModule.generatedTime))
    print("场景类型:", self.dataModule.sceneType)
    print("灾难类型:", self.dataModule.disasterType)
    print("角色总数:", #self.dataModule.characters)
    print("  - 主角:", self.dataModule.protagonist and self.dataModule.protagonist.name or "未设置")
    print("  - 仇人:", self.dataModule.enemy and self.dataModule.enemy.name or "未设置")
    print("  - 主要NPC:", #self.dataModule.mainNPCs)
    print("  - 次要NPC:", #self.dataModule.minorNPCs)
    print("关键剧情点数:", #self.dataModule.keyStoryPoints)
    print("背景文本长度:", #self.dataModule.gameBackground)
    print("故事线文本长度:", #self.dataModule.storyLine)
    print("====================================================")
end

return BM_GameStory


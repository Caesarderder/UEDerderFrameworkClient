---GameStory初始化器
---展示如何初始化并使用GameStory系统

local GameContext = require("Core.GameContext")
local HereWeGoAgainConfig = require("Config.HereWeGoAgainConfig")
local GameStoryTools = require("GameLayer.GameStory.GameStoryTools")

local GameStoryInitializer = {}

---初始化GameStory系统
---@param apiKey string API密钥
---@param provider string Provider名称（"qwen"/"openai"/"claude"）
---@return boolean success 是否初始化成功
function GameStoryInitializer.Initialize(apiKey, provider)
    print("[GameStoryInitializer] 开始初始化GameStory系统...")
    
    -- 1. 获取LLM管理器
    local llmMgr = GameContext:GetLlmManager()
    if not llmMgr then
        print("[GameStoryInitializer] 错误：无法获取LLM管理器")
        return false
    end
    
    -- 2. 配置LLM
    llmMgr:SetApiKey(apiKey)
    llmMgr:UseProvider(provider or "qwen")
    llmMgr:SetModel("qwen-max")
    
    -- 3. 设置游戏世界观
    llmMgr:SetGameWorld(HereWeGoAgainConfig.gameWorld)
    llmMgr:SetGameRules(HereWeGoAgainConfig.gameRules)
    llmMgr:SetPlayerIdentity(HereWeGoAgainConfig.playerIdentity)
    
    -- 4. 注册GameStory相关的Tools
    GameStoryTools.RegisterAllTools(llmMgr)
    
    print("[GameStoryInitializer] GameStory系统初始化完成")
    return true
end

---生成游戏故事
---@param userInput string 用户需求描述
---@param sceneType string|nil 场景类型（可选）
---@param disasterType string|nil 灾难类型（可选）
---@param onStream function|nil 流式回调
---@param onComplete function|nil 完成回调
function GameStoryInitializer.GenerateStory(userInput, sceneType, disasterType, onStream, onComplete)
    local llmMgr = GameContext:GetLlmManager()
    if not llmMgr then
        print("[GameStoryInitializer] 错误：LLM管理器未初始化")
        if onComplete then
            onComplete(false, "LLM管理器未初始化")
        end
        return
    end
    
    print("[GameStoryInitializer] 开始生成游戏故事...")
    
    -- 调用generate_game_story ChatType
    llmMgr:Chat("generate_game_story", {
        userInput = userInput,
        sceneType = sceneType or "校园",
        disasterType = disasterType or "爆炸",
        specialRequirements = ""
    }, onStream, onComplete)
end

---获取生成的游戏故事数据
---@return table|nil 游戏故事数据
function GameStoryInitializer.GetGeneratedStory()
    local BM_GameStory = GameStoryTools.GetBusinessModule()
    
    if not BM_GameStory:IsGenerated() then
        print("[GameStoryInitializer] 游戏故事尚未生成")
        return nil
    end
    
    return {
        background = BM_GameStory:GetGameBackground(),
        protagonist = BM_GameStory:GetProtagonist(),
        enemy = BM_GameStory:GetEnemy(),
        mainNPCs = BM_GameStory.dataModule.mainNPCs,
        minorNPCs = BM_GameStory.dataModule.minorNPCs,
        storyLine = BM_GameStory:GetStoryLine(),
        keyPoints = BM_GameStory:GetKeyStoryPoints(),
        disasterPlan = BM_GameStory:GetDisasterPlan(),
        sceneType = BM_GameStory:GetSceneType(),
        disasterType = BM_GameStory:GetDisasterType()
    }
end

---查看游戏故事状态
function GameStoryInitializer.DebugPrintStory()
    local BM_GameStory = GameStoryTools.GetBusinessModule()
    BM_GameStory:DebugPrint()
end

return GameStoryInitializer


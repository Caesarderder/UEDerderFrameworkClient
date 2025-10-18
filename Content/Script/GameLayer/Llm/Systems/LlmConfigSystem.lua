---LLM配置管理系统
local SystemBase = require("Core.GameLayerBase.SystemBase")
local BM_LlmConfig = require("DataLayer.Llm.BM_LlmConfig")

---@class LlmConfigSystem : SystemBase
---@type LlmConfigSystem
local LlmConfigSystem = {}
setmetatable(LlmConfigSystem, { __index = SystemBase })

---初始化系统
function LlmConfigSystem:init()
    -- 先初始化DataModule的数据
    BM_LlmConfig.dataModule:init()
    -- 再初始化BusinessModule属性访问器
    BM_LlmConfig:initializeProperties()
    print("[LlmConfigSystem] 配置系统初始化完成")
end

---设置API密钥
---@param apiKey string API密钥
function LlmConfigSystem:SetApiKey(apiKey)
    BM_LlmConfig.ApiKey.set(apiKey)
end

---设置模型
---@param model string 模型名称
function LlmConfigSystem:SetModel(model)
    BM_LlmConfig.Model.set(model)
end

---设置温度
---@param temperature number 温度值
function LlmConfigSystem:SetTemperature(temperature)
    if temperature < 0 or temperature > 2 then
        print("[LlmConfigSystem] 温度值超出范围，已限制在[0, 2]")
        temperature = math.max(0, math.min(2, temperature))
    end
    BM_LlmConfig.Temperature.set(temperature)
end

---设置最大Token数
---@param maxTokens number 最大Token数
function LlmConfigSystem:SetMaxTokens(maxTokens)
    BM_LlmConfig.MaxTokens.set(maxTokens)
end

---使用预设配置
---@param preset string 预设名称(openai/claude/qwen/local)
---@param ... any 额外参数
function LlmConfigSystem:UsePreset(preset, ...)
    if preset == "openai" then
        BM_LlmConfig:SetPresetOpenAI()
    elseif preset == "claude" then
        BM_LlmConfig:SetPresetClaude()
    elseif preset == "qwen" then
        BM_LlmConfig:SetPresetQwen()
    elseif preset == "local" then
        local port = ...
        BM_LlmConfig:SetPresetLocal(port)
    else
        print("[LlmConfigSystem] 未知的预设: " .. preset)
    end
end

return LlmConfigSystem


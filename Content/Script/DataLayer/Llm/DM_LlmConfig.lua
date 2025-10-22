local DataModule = require("Core.DataLayerBase.DataModule")

---@class DM_LlmConfig : DataModule
---@type DM_LlmConfig
local DM_LlmConfig = {}
setmetatable(DM_LlmConfig, { __index = DataModule })

DM_LlmConfig.Fields = {
    -- API配置
    apiUrl = "https://api.openai.com/v1/chat/completions",  ---@type string API地址
    apiKey = "",                                             ---@type string API密钥
    model = "gpt-4",                                        ---@type string 模型名称
    
    -- 生成参数
    temperature = 0.7,      ---@type number 温度参数(0-2)
    maxTokens = 3000,       ---@type number 最大token数（默认3000，约2250汉字）
    topP = 1.0,            ---@type number top_p采样参数
    
    -- 请求配置
    timeout = 300,         ---@type number 请求超时时间(秒，默认5分钟，适合LLM长对话)
    retryCount = 3,        ---@type number 重试次数
}

return DM_LlmConfig



local BusinessModule = require("Core.DataLayerBase.BusinessModule")
local DM_LlmProvider = require("DataLayer.Llm.DM_LlmProvider")

---@class BM_LlmProvider : BusinessModule
---@type BM_LlmProvider
local BM_LlmProvider = {
    ---@type DM_LlmProvider
    dataModule = DM_LlmProvider
}

setmetatable(BM_LlmProvider, { __index = BusinessModule })

---注册Provider
---@param name string Provider名称
---@param providerInstance table Provider实例
function BM_LlmProvider:RegisterProvider(name, providerInstance)
    self.dataModule.providers[name] = providerInstance
    print("[BM_LlmProvider] 注册Provider: " .. name)
end

---切换Provider
---@param name string Provider名称
---@return boolean 是否切换成功
function BM_LlmProvider:SwitchProvider(name)
    if not self.dataModule.providers[name] then
        print("[BM_LlmProvider] Provider不存在: " .. name)
        return false
    end
    
    self.dataModule.currentProvider = name
    print("[BM_LlmProvider] 切换到Provider: " .. name)
    return true
end

---获取当前Provider实例
---@return table|nil Provider实例
function BM_LlmProvider:GetCurrentProvider()
    local providerName = self.dataModule.currentProvider
    return self.dataModule.providers[providerName]
end

---获取指定Provider实例
---@param name string Provider名称
---@return table|nil Provider实例
function BM_LlmProvider:GetProvider(name)
    return self.dataModule.providers[name]
end

return BM_LlmProvider


---@class UIManager
---UI管理器
local managerBase = require("Core.GameLayerBase.ManagerBase")
local uiLayerSystem = require("GameLayer.UI.Systems.UILayerSystem")
local consts = require("Util.Consts")

local uiManager = setmetatable({}, {__index = managerBase})

-- 常量定义
uiManager.ui_layer = {
    BACKGROUND = 1,    -- 背景层
    GAME = 2,         -- 游戏层
    HUD = 3,          -- HUD层
    WINDOW = 4,       -- 窗口层
    POPUP = 5,        -- 弹出层
}

---初始化
function uiManager:init()
    -- 调用父类init，初始化systems表
    managerBase.init(self)
    
    -- 注册层级系统
    self:registerSystem(consts.SystemType.UI_LAYER, uiLayerSystem)
end

---获取层级系统
---@return UILayerSystem
function uiManager:getLayerSystem()
    return self:getSystem(consts.SystemType.UI_LAYER)
end

--[[
    UI操作接口
--]]

-- 打开UI
---@param uiName string UI名称
---@param layer number 层级(可选)
---@param params table 参数(可选)
---@param worldContext userdata WorldContextObject（可选，首次调用需要提供）
function uiManager:openUI(uiName, layer, params, worldContext)
    -- 检查UI是否已经打开
    if self:getLayerSystem():isUIOpen(uiName) then
        self:focusUI(uiName)
        return
    end
    
    -- 加载并显示UI
    layer = layer or self.ui_layer.WINDOW
    local uiInstance = self:getLayerSystem():openUI(uiName, layer, params, worldContext)
    return uiInstance
end

-- 关闭UI
---@param uiName string UI名称
function uiManager:closeUI(uiName)
    self:getLayerSystem():closeUI(uiName)
end

-- 聚焦UI
---@param uiName string UI名称
function uiManager:focusUI(uiName)
    self:getLayerSystem():focusUI(uiName)
end

-- 检查UI是否已打开
---@param uiName string UI名称
---@return boolean 是否已打开
function uiManager:isUIOpen(uiName)
    return self:getLayerSystem():isUIOpen(uiName)
end

-- 获取UI实例
---@param uiName string UI名称
---@return userdata UI实例
function uiManager:getUIInstance(uiName)
    return self:getLayerSystem():getUIInstance(uiName)
end

return uiManager
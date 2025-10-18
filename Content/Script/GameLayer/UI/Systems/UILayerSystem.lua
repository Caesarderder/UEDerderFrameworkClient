---@class UILayerSystem
---UI层级系统
local systemBase = require("Core.GameLayerBase.SystemBase")
local gameContext = require("Core.GameContext")

local uiLayerSystem = setmetatable({}, {__index = systemBase})

-- 私有变量
local _layerContainers = {}  -- 层级容器表
local _uiInstances = {}      -- UI实例管理表

---初始化
function uiLayerSystem:init()
    -- 直接初始化系统
    if gameContext.worldContext then
        self:initializeSystem(gameContext.worldContext)
    end
    print("[UILayerSystem] 初始化完成")
end

---创建层级容器
---@param worldContext userdata WorldContextObject
function uiLayerSystem:initializeSystem(worldContext)
    if not worldContext then
        print("[UILayerSystem] Error: 需要提供WorldContextObject")
        return false
    end
    
    print("[UILayerSystem] UI层级系统初始化完成")
    return true
end

---打开UI
---@param uiName string UI名称（如 "Menu/UI_Test"）
---@param layer number 层级（用作ZOrder，数值越大越靠前）
---@param params table 可选参数
---@return userdata UI实例
function uiLayerSystem:openUI(uiName, layer, params)
    -- 检查系统是否已初始化
    if not gameContext.worldContext then
        print("[UILayerSystem] Error: UI层级系统未初始化，请确保GameContext已正确设置worldContext")
        return nil
    end
    
    -- 检查UI是否已经打开
    if _uiInstances[uiName] then
        print("[UILayerSystem] Warning: UI " .. uiName .. " 已经打开")
        return _uiInstances[uiName].instance
    end
    
    -- 构建资源路径（参考C++: "/Game/UI/WBP_MyWidget"）
    local assetPath = "/Game/UI/" .. uiName
    print("[UILayerSystem] 加载UI蓝图: " .. assetPath)
    
    -- 加载Widget蓝图类（对应C++的LoadClass<UUserWidget>）
    local widgetClass = UE.UClass.Load(assetPath)
    if not widgetClass then
        print("[UILayerSystem] Error: 无法加载UI蓝图类: " .. assetPath)
        print("[UILayerSystem] 提示: 请确保UI蓝图存在于 Content/UI/" .. uiName .. ".uasset")
        return nil
    end
    
    -- 获取World（对应C++的GetWorld()）
    local world = gameContext.worldContext
    if not world then
        print("[UILayerSystem] Error: 无法获取WorldContext")
        return nil
    end
    
    -- 创建Widget实例（对应C++的CreateWidget<UUserWidget>(GetWorld(), WidgetBPClass)）
    local widget = UE.UWidgetBlueprintLibrary.Create(world, widgetClass)
    if not widget then 
        print("[UILayerSystem] Error: 创建Widget实例失败: " .. uiName)
        print("[UILayerSystem] 检查蓝图类: " .. tostring(widgetClass))
        return nil 
    end
    
    -- 添加到视口，使用layer作为ZOrder控制层级（对应C++的AddToViewport()）
    -- ZOrder: 数值越大显示越靠前
    widget:AddToViewport(layer)
    
    -- 保存UI实例信息
    _uiInstances[uiName] = {
        instance = widget,
        layer = layer
    }
    
    -- 保存widget引用到对应层级（方便管理）
    if not _layerContainers[layer] then
        _layerContainers[layer] = {}
    end
    table.insert(_layerContainers[layer], widget)
    
    print("[UILayerSystem] ✓ UI已打开: " .. uiName .. " (Layer: " .. layer .. ")")
    
    return widget
end

---关闭UI
---@param uiName string UI名称
function uiLayerSystem:closeUI(uiName)
    local uiData = _uiInstances[uiName]
    if not uiData then 
        print("[UILayerSystem] Warning: 尝试关闭未打开的UI: " .. uiName)
        return 
    end
    
    local uiInstance = uiData.instance
    local layer = uiData.layer
    
    -- 检查UI实例是否有效
    if uiInstance and UE.UObject.IsValid(uiInstance) then
        -- 从视口移除（对应C++的RemoveFromParent()）
        uiInstance:RemoveFromParent()
    else
        print("[UILayerSystem] Warning: UI实例已释放: " .. uiName)
    end
    
    -- 从UI实例管理表中移除
    _uiInstances[uiName] = nil
    
    -- 从层级容器中移除widget引用
    if _layerContainers[layer] then
        for i, widget in ipairs(_layerContainers[layer]) do
            if widget == uiInstance then
                table.remove(_layerContainers[layer], i)
                break
            end
        end
    end
    
    print("[UILayerSystem] ✓ UI已关闭: " .. uiName)
end

---聚焦UI（将UI提升到最前）
---@param uiName string UI名称
function uiLayerSystem:focusUI(uiName)
    local uiData = _uiInstances[uiName]
    if not uiData then 
        print("[UILayerSystem] Warning: 尝试聚焦未打开的UI: " .. uiName)
        return 
    end
    
    local uiInstance = uiData.instance
    local layer = uiData.layer
    
    -- 检查UI实例是否有效
    if not uiInstance or not UE.UObject.IsValid(uiInstance) then
        print("[UILayerSystem] Warning: UI实例已释放: " .. uiName)
        _uiInstances[uiName] = nil  -- 清理无效的实例引用
        return
    end
    
    -- 重新添加到视口以提升到最前
    uiInstance:RemoveFromParent()
    uiInstance:AddToViewport(layer + 1000)  -- 提升ZOrder
    
    print("[UILayerSystem] UI已聚焦: " .. uiName)
end

---检查UI是否已打开
---@param uiName string UI名称
---@return boolean 是否已打开
function uiLayerSystem:isUIOpen(uiName)
    return _uiInstances[uiName] ~= nil
end

---获取UI实例
---@param uiName string UI名称
---@return userdata UI实例
function uiLayerSystem:getUIInstance(uiName)
    local uiData = _uiInstances[uiName]
    return uiData and uiData.instance or nil
end

return uiLayerSystem
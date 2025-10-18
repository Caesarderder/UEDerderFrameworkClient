package.path = package.path .. ";../../Content/Script/?.lua;../?.lua"

local testFramework = require("TestFramework")
local dataModule = require("Core.DataLayerBase.DataModule")
local businessModule = require("Core.DataLayerBase.BusinessModule")

-- 创建测试数据模块
---@class TestDataModule : DataModule
local testDataModule = {}
setmetatable(testDataModule, { __index = dataModule })

testDataModule.Fields = {
    coin = 0,      ---@type number 金币
    level = 1,     ---@type number 等级
    name = ""      ---@type string 名称
}

-- 创建测试业务模块
---@class TestBusinessModule : BusinessModule
local testBusinessModule = {
    dataModule = testDataModule
}
setmetatable(testBusinessModule, { __index = businessModule })

-- 在每个测试前运行
testFramework.beforeEach(function()
    testDataModule:init()
    testBusinessModule:initializeProperties()
end)

-- 测试数据模块基本功能
testFramework.test("DataModule - 点语法访问", function()
    -- 测试初始值
    testFramework.assertEqual(0, testDataModule.coin, "初始金币应该为0")
    
    -- 测试设置值
    testDataModule.coin = 100
    testFramework.assertEqual(100, testDataModule.coin, "设置金币后应该为100")
    
    -- 测试批量设置
    testDataModule:setBatch({coin = 200, level = 2})
    testFramework.assertEqual(200, testDataModule.coin, "批量设置后金币应该为200")
    testFramework.assertEqual(2, testDataModule.level, "批量设置后等级应该为2")
    
    -- 测试未定义字段
    local success, error = pcall(function()
        testDataModule.undefined = 1
    end)
    testFramework.assertEqual(false, success, "设置未定义字段应该抛出错误")
    
    -- 测试重置
    testDataModule:reset()
    testFramework.assertEqual(0, testDataModule.coin, "重置后金币应该为0")
end)

-- 测试业务模块属性访问
testFramework.test("BusinessModule - 属性访问", function()
    -- 测试获取值
    testFramework.assertEqual(0, testBusinessModule.Coin.get(), "初始金币应该为0")
    
    -- 测试设置值
    testBusinessModule.Coin.set(100)
    testFramework.assertEqual(100, testBusinessModule.Coin.get(), "设置金币后应该为100")
end)

-- 测试数据变更监听
testFramework.test("BusinessModule - 事件监听", function()
    local changeCount = 0
    local lastOldValue = nil
    local lastNewValue = nil
    
    -- 注册监听
    local handler = function(newValue, oldValue)
        changeCount = changeCount + 1
        lastOldValue = oldValue
        lastNewValue = newValue
    end
    testBusinessModule.Coin.addOnChange(handler)
    
    -- 触发变更
    testBusinessModule.Coin.set(100)
    testFramework.assertEqual(1, changeCount, "应该触发一次变更")
    testFramework.assertEqual(0, lastOldValue, "旧值应该为0")
    testFramework.assertEqual(100, lastNewValue, "新值应该为100")
    
    -- 取消监听
    testBusinessModule.Coin.removeOnChange(handler)
    testBusinessModule.Coin.set(200)
    testFramework.assertEqual(1, changeCount, "取消监听后不应该再触发变更")
end)

-- 运行所有测试
testFramework.run()
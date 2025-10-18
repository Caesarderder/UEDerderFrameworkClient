package.path = package.path .. ";../../Content/Script/?.lua;../?.lua"

local TestFramework = require("TestFramework")
local CoinManager = require("GameLayer.Coin.CoinManager")
local BM_Coin = require("DataLayer.BM_Coin")

-- 在每个测试前重置金币
TestFramework.beforeEach(function()
    BM_Coin:setCoinNum(0)
end)

-- 测试金币基本操作
TestFramework.test("CoinSystem - 基本操作", function()
    -- 测试初始值
    TestFramework.assertEqual(0, BM_Coin:getCoinNum(), "初始金币应该为0")
    
    -- 测试增加金币
    CoinManager.systems.main:AddCoin(100)
    TestFramework.assertEqual(100, BM_Coin:getCoinNum(), "增加金币后应该为100")
    
    -- 测试消耗金币
    local success = CoinManager.systems.main:ConsumeCoin(50)
    TestFramework.assertEqual(true, success, "消耗金币应该成功")
    TestFramework.assertEqual(50, BM_Coin:getCoinNum(), "消耗后金币应该为50")
    
    -- 测试金币不足
    success = CoinManager.systems.main:ConsumeCoin(100)
    TestFramework.assertEqual(false, success, "金币不足时消耗应该失败")
    TestFramework.assertEqual(50, BM_Coin:getCoinNum(), "金币不足时数量不应变化")
end)

-- 测试金币变更监听
TestFramework.test("CoinSystem - 事件监听", function()
    local changeCount = 0
    local lastOldValue = nil
    local lastNewValue = nil
    
    -- 注册监听
    local unsubscribe = CoinManager:RegisterCoinChangeCallback(function(newValue, oldValue)
        changeCount = changeCount + 1
        lastOldValue = oldValue
        lastNewValue = newValue
    end)
    
    -- 测试增加金币的事件
    CoinManager.systems.main:AddCoin(100)
    TestFramework.assertEqual(1, changeCount, "应该触发一次变更")
    TestFramework.assertEqual(0, lastOldValue, "旧值应该为0")
    TestFramework.assertEqual(100, lastNewValue, "新值应该为100")
    
    -- 测试消耗金币的事件
    CoinManager.systems.main:ConsumeCoin(50)
    TestFramework.assertEqual(2, changeCount, "应该触发第二次变更")
    TestFramework.assertEqual(100, lastOldValue, "旧值应该为100")
    TestFramework.assertEqual(50, lastNewValue, "新值应该为50")
    
    -- 取消监听后的测试
    unsubscribe()
    CoinManager.systems.main:AddCoin(100)
    TestFramework.assertEqual(2, changeCount, "取消监听后不应该再触发变更")
end)

-- 运行所有测试
TestFramework.run()

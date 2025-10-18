---@class TestFramework
---简单的测试框架
local TestFramework = {}

local tests = {}
local beforeEach = nil
local afterEach = nil

---添加测试用例
---@param name string 测试名称
---@param func function 测试函数
function TestFramework.test(name, func)
    table.insert(tests, {name = name, func = func})
end

---设置每个测试前运行的函数
---@param func function
function TestFramework.beforeEach(func)
    beforeEach = func
end

---设置每个测试后运行的函数
---@param func function
function TestFramework.afterEach(func)
    afterEach = func
end

---断言相等
---@param expected any 期望值
---@param actual any 实际值
---@param message string 错误消息
function TestFramework.assertEqual(expected, actual, message)
    if expected ~= actual then
        error(string.format("%s: expected %s but got %s", message or "Assertion failed", tostring(expected), tostring(actual)))
    end
end

---运行所有测试
function TestFramework.run()
    print("开始运行测试...")
    print("------------------------")
    
    local passCount = 0
    local failCount = 0
    
    for _, test in ipairs(tests) do
        local success = true
        if beforeEach then
            beforeEach()
        end
        
        print(string.format("测试用例: %s", test.name))
        local status, err = pcall(test.func)
        if not status then
            success = false
            print(string.format("❌ 失败: %s", err))
            failCount = failCount + 1
        else
            print("✅ 通过")
            passCount = passCount + 1
        end
        
        if afterEach then
            afterEach()
        end
        print("------------------------")
    end
    
    print(string.format("测试完成: %d 通过, %d 失败", passCount, failCount))
end

return TestFramework

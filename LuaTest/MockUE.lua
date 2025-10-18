---@class MockUE
---模拟UE环境
local MockUE = {}

-- 模拟UE的GameplayTag
MockUE.FGameplayTag = {
    new = function()
        return {
            TagName = ""
        }
    end
}

-- 模拟其他可能用到的UE类型和函数
MockUE.FSoftObjectPtr = function(class)
    return {
        class = class
    }
end

MockUE.UClass = {
    Load = function(path)
        return {
            Path = path
        }
    end
}

return MockUE

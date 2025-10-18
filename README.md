# UEDerderFrameworkClient
ue+unlua

## 存档系统说明

本框架提供了一个简单的本地存档系统，可以保存和加载游戏数据。

### 主要组件

1. **SaveManager** - 存档管理器，负责管理游戏的存档和读档功能
2. **GameContext** - 游戏上下文，提供底层的存档API
3. **SaveLifeCircleSystem** - 存档生命周期系统，处理游戏的保存和加载逻辑

### 如何使用

1. 获取存档管理器：
```lua
local saveManager = GameContext:GetSaveManager()
```

2. 保存游戏：
```lua
local success = saveManager:SaveGame("PlayerSave")
```

3. 加载游戏：
```lua
local saveObject = saveManager:LoadGame("PlayerSave")
```

4. 检查存档是否存在：
```lua
local exists = saveManager:DoesSaveGameExist("PlayerSave")
```

### 示例

请参考 [Test/SaveLoadTest.lua](Content/Script/Test/SaveLoadTest.lua) 文件了解如何使用存档系统。
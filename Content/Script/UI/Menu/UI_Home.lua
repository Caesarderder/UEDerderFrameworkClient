--
-- DESCRIPTION: 主菜单UI - 管理MainMenu和ChooseGame两个状态
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local GameContext = require("Core.GameContext")

---@type UI_Home_C
local M = UnLua.Class()

-- ==================== 状态定义 ====================

---UI主状态枚举
M.UIState = {
    MainMenu = "MainMenu",      -- 主菜单状态：显示开始/退出按钮
    ChooseGame = "ChooseGame"   -- 选择游戏状态：显示故事选择界面
}

---ChooseGame子状态枚举
M.ChooseGameSubState = {
    ChooseStory = "ChooseStory",           -- 选择故事：显示中国/校园/西部按钮
    StoryInfo = "StoryInfo",               -- 故事信息：显示故事详情和进入按钮
    ChooseCharacter = "ChooseCharacter"    -- 选择角色：显示角色选择界面
}

---故事ID映射表：UI按钮ID → 故事库ID
M.StoryIdMap = {
    china = "story_luoyang",      -- 中国故事 → 洛阳帽妖灾劫
    school = "story_school",      -- 校园故事 → 囧囧的校园奇遇
    western = "story_blackwater"  -- 西部故事 → 黑水镇纵火案
}

---故事配置路径映射表：故事库ID → 配置文件路径
M.StoryConfigMap = {
    story_luoyang = "Config.LuoyangStoryConfig",
    story_school = "Config.SchoolJojoConfig",
    story_blackwater = "Config.BlackwaterStoryConfig"
}

-- ==================== 生命周期 ====================

---构造函数：初始化UI状态
function M:Construct()
    print("[UI_Home] ========== UI初始化 ==========")
    
    -- 初始化当前状态
    self.currentState = nil
    self.currentSubState = nil      -- 当前子状态
    self.selectedStoryId = nil      -- 选中的故事ID（china/school/western）
    self.selectedCharacter = nil    -- 选中的角色（man/woman）
    
    -- 设置输入模式，确保鼠标始终可见
    self:SetInputMode()
    
    -- 检查必要组件
    self:CheckComponents()
    
    -- 设置初始状态为MainMenu
    self:SwitchToState(M.UIState.MainMenu)
    
    -- 绑定按钮事件
    self:BindButtonEvents()
    
    print("[UI_Home] ✅ UI初始化完成")
end

---设置输入模式：确保鼠标始终显示
function M:SetInputMode()
    -- 获取 PlayerController
    local playerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    
    if not playerController then
        print("[UI_Home] ⚠️ 警告：无法获取 PlayerController，无法设置输入模式")
        return
    end
    
    -- 设置输入模式为 UI Only（只响应UI输入）
    -- 参数：
    -- 1. PlayerController
    -- 2. Widget to Focus（要聚焦的Widget，传nil表示不聚焦特定Widget）
    -- 3. Mouse Lock Mode（鼠标锁定模式：DoNotLock = 不锁定）
    UE.UWidgetBlueprintLibrary.SetInputMode_UIOnlyEx(
        playerController,
        self,  -- 聚焦到当前UI
        UE.EMouseLockMode.DoNotLock  -- 不锁定鼠标
    )
    
    -- 显示鼠标光标
    playerController.bShowMouseCursor = true
    
    print("[UI_Home] ✅ 输入模式已设置：UI Only + 显示鼠标")
    
    --[[
        额外提示：如果背景图片仍然会遮挡鼠标，请在 UE 蓝图编辑器中：
        1. 选中背景 Image 组件
        2. 在 Details 面板找到 "Behavior" → "Visibility"
        3. 设置为 "Not Hit-Testable (Self & All Children)"
        
        这样背景图片就不会拦截鼠标事件了。
    --]]
end

-- ==================== 按钮事件绑定 ====================

---绑定所有按钮事件（使用 UMG 原生 Button 接口）
function M:BindButtonEvents()
    print("[UI_Home] === 绑定按钮事件 ===")
    
    -- ========== MainMenu 按钮 ==========
    if self.Button_Start then
        self.Button_Start.OnClicked:Add(self, self.OnStartClicked)
        print("[UI_Home] ✓ Button_Start 事件已绑定")
    end
    
    if self.Button_Quit then
        self.Button_Quit.OnClicked:Add(self, self.OnQuitClicked)
        print("[UI_Home] ✓ Button_Quit 事件已绑定")
    end
    
    -- ========== ChooseStory 按钮（选择故事）==========
    if self.Button_China then
        self.Button_China.OnClicked:Add(self, self.OnChinaClicked)
        print("[UI_Home] ✓ Button_China 事件已绑定")
    end
    
    if self.Button_School then
        self.Button_School.OnClicked:Add(self, self.OnSchoolClicked)
        print("[UI_Home] ✓ Button_School 事件已绑定")
    end
    
    if self.Button_Western then
        self.Button_Western.OnClicked:Add(self, self.OnWesternClicked)
        print("[UI_Home] ✓ Button_Western 事件已绑定")
    end
    
    -- ========== StoryInfo 按钮（进入游戏）==========
    if self.Button_Enter then
        self.Button_Enter.OnClicked:Add(self, self.OnEnterClicked)
        print("[UI_Home] ✓ Button_Enter 事件已绑定")
    end
    
    -- ========== 返回按钮 ==========
    if self.Button_Back_1 then
        self.Button_Back_1.OnClicked:Add(self, self.OnBackClicked)
        print("[UI_Home] ✓ Button_Back_1 事件已绑定")
    end
    
    -- ========== ChooseCharacter 按钮（选择角色）==========
    if self.Button_CharacterMan then
        self.Button_CharacterMan.OnClicked:Add(self, self.OnCharacterManClicked)
        print("[UI_Home] ✓ Button_CharacterMan 事件已绑定")
    end
    
    if self.Button_CharacterWoman then
        self.Button_CharacterWoman.OnClicked:Add(self, self.OnCharacterWomanClicked)
        print("[UI_Home] ✓ Button_CharacterWoman 事件已绑定")
    end
end

-- ==================== 组件检查 ====================

---检查UI组件是否存在
function M:CheckComponents()
    print("[UI_Home] === 组件检查 ===")
    
    -- 主状态组件
    if self.Canvas_MainMenu then
        print("[UI_Home] ✓ Canvas_MainMenu 存在")
    else
        print("[UI_Home] ❌ Canvas_MainMenu 不存在！")
    end
    
    if self.Overlay_ChooseGame then
        print("[UI_Home] ✓ Overlay_ChooseGame 存在")
    else
        print("[UI_Home] ❌ Overlay_ChooseGame 不存在！")
    end
    
    -- ChooseGame 子状态组件
    print("[UI_Home] --- ChooseGame 子组件检查 ---")
    
    if self.Canvas_ChooseStoryWidget then
        print("[UI_Home] ✓ Canvas_ChooseStoryWidget 存在")
    else
        print("[UI_Home] ⚠️ Canvas_ChooseStoryWidget 不存在")
    end
    
    if self.Canvas_StoryInfoWidget then
        print("[UI_Home] ✓ Canvas_StoryInfoWidget 存在")
    else
        print("[UI_Home] ⚠️ Canvas_StoryInfoWidget 不存在")
    end
    
    if self.Canvas_ChooseCharacterWidget then
        print("[UI_Home] ✓ Canvas_ChooseCharacterWidget 存在")
    else
        print("[UI_Home] ⚠️ Canvas_ChooseCharacterWidget 不存在")
    end
end

-- ==================== 状态切换 ====================

---切换UI状态
---@param newState string 新状态（使用 M.UIState 枚举）
function M:SwitchToState(newState)
    if self.currentState == newState then
        print(string.format("[UI_Home] 状态未改变，已经是 %s", newState))
        return
    end
    
    print(string.format("[UI_Home] 状态切换: %s -> %s", 
        self.currentState or "nil", newState))
    
    -- 根据状态显示/隐藏对应的Canvas
    if newState == M.UIState.MainMenu then
        self:ShowMainMenu()
    elseif newState == M.UIState.ChooseGame then
        self:ShowChooseGame()
    else
        print(string.format("[UI_Home] ❌ 错误：未知状态 %s", newState))
        return
    end
    
    -- 更新当前状态
    self.currentState = newState
    print(string.format("[UI_Home] ✅ 当前状态: %s", self.currentState))
end

---显示主菜单（隐藏选择游戏）
function M:ShowMainMenu()
    print("[UI_Home] 显示MainMenu，隐藏ChooseGame")
    
    -- 隐藏所有子状态 Widget
    self:HideAllSubStateWidgets()
    
    -- 显示 Canvas_MainMenu
    if self.Canvas_MainMenu then
        self.Canvas_MainMenu:SetVisibility(UE.ESlateVisibility.Visible)
        print("[UI_Home] ✓ Canvas_MainMenu 已显示")
    end
    
    -- 隐藏 Overlay_ChooseGame
    if self.Overlay_ChooseGame then
        self.Overlay_ChooseGame:SetVisibility(UE.ESlateVisibility.Collapsed)
        print("[UI_Home] ✓ Overlay_ChooseGame 已隐藏")
    end
end

---显示选择游戏（隐藏主菜单）
function M:ShowChooseGame()
    print("[UI_Home] 隐藏MainMenu，显示ChooseGame")
    
    -- 隐藏 Canvas_MainMenu
    if self.Canvas_MainMenu then
        self.Canvas_MainMenu:SetVisibility(UE.ESlateVisibility.Collapsed)
        print("[UI_Home] ✓ Canvas_MainMenu 已隐藏")
    end
    
    -- 显示 Overlay_ChooseGame
    if self.Overlay_ChooseGame then
        self.Overlay_ChooseGame:SetVisibility(UE.ESlateVisibility.Visible)
        print("[UI_Home] ✓ Overlay_ChooseGame 已显示")
    end
    
    -- 默认进入 ChooseStory 子状态
    self:SwitchToSubState(M.ChooseGameSubState.ChooseStory)
end

-- ==================== 子状态切换 ====================

---切换ChooseGame子状态
---@param newSubState string 新子状态（使用 M.ChooseGameSubState 枚举）
function M:SwitchToSubState(newSubState)
    if self.currentSubState == newSubState then
        print(string.format("[UI_Home] 子状态未改变，已经是 %s", newSubState))
        return
    end
    
    print(string.format("[UI_Home] 子状态切换: %s -> %s", 
        self.currentSubState or "nil", newSubState))
    
    -- 隐藏所有子状态Widget
    self:HideAllSubStateWidgets()
    
    -- 根据子状态显示对应的Widget
    if newSubState == M.ChooseGameSubState.ChooseStory then
        self:ShowChooseStoryWidget()
    elseif newSubState == M.ChooseGameSubState.StoryInfo then
        self:ShowStoryInfoWidget()
    elseif newSubState == M.ChooseGameSubState.ChooseCharacter then
        self:ShowChooseCharacterWidget()
    else
        print(string.format("[UI_Home] ❌ 错误：未知子状态 %s", newSubState))
        return
    end
    
    -- 更新当前子状态
    self.currentSubState = newSubState
    print(string.format("[UI_Home] ✅ 当前子状态: %s", self.currentSubState))
end

---隐藏所有子状态Widget
function M:HideAllSubStateWidgets()
    if self.Canvas_ChooseStoryWidget then
        self.Canvas_ChooseStoryWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    
    if self.Canvas_StoryInfoWidget then
        self.Canvas_StoryInfoWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    
    if self.Canvas_ChooseCharacterWidget then
        self.Canvas_ChooseCharacterWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---显示选择故事Widget
function M:ShowChooseStoryWidget()
    print("[UI_Home] 显示 ChooseStory 界面")
    
    if self.Canvas_ChooseStoryWidget then
        self.Canvas_ChooseStoryWidget:SetVisibility(UE.ESlateVisibility.Visible)
        print("[UI_Home] ✓ Canvas_ChooseStoryWidget 已显示")
    else
        print("[UI_Home] ⚠️ Canvas_ChooseStoryWidget 不存在")
    end
end

---显示故事信息Widget
function M:ShowStoryInfoWidget()
    print("[UI_Home] 显示 StoryInfo 界面")
    
    if self.Canvas_StoryInfoWidget then
        self.Canvas_StoryInfoWidget:SetVisibility(UE.ESlateVisibility.Visible)
        print("[UI_Home] ✓ Canvas_StoryInfoWidget 已显示")
        
        -- 更新故事信息内容
        self:UpdateStoryInfo(self.selectedStoryId)
    else
        print("[UI_Home] ⚠️ Canvas_StoryInfoWidget 不存在")
    end
end

---显示选择角色Widget
function M:ShowChooseCharacterWidget()
    print("[UI_Home] 显示 ChooseCharacter 界面")
    
    if self.Canvas_ChooseCharacterWidget then
        self.Canvas_ChooseCharacterWidget:SetVisibility(UE.ESlateVisibility.Visible)
        print("[UI_Home] ✓ Canvas_ChooseCharacterWidget 已显示")
    else
        print("[UI_Home] ⚠️ Canvas_ChooseCharacterWidget 不存在")
    end
end

---更新故事信息显示
---@param storyId string 故事ID（china/school/western）
function M:UpdateStoryInfo(storyId)
    if not storyId then
        print("[UI_Home] ⚠️ 未选择故事")
        return
    end
    
    print(string.format("[UI_Home] 更新故事信息: %s", storyId))
    
    -- 1. 将UI按钮ID转换为故事库ID
    local storyLibraryId = M.StoryIdMap[storyId]
    if not storyLibraryId then
        print(string.format("[UI_Home] ❌ 错误：未找到故事映射 %s", storyId))
        return
    end
    
    print(string.format("[UI_Home] 故事库ID: %s", storyLibraryId))
    
    -- 2. 获取故事配置路径
    local configPath = M.StoryConfigMap[storyLibraryId]
    if not configPath then
        print(string.format("[UI_Home] ❌ 错误：未找到配置路径 %s", storyLibraryId))
        return
    end
    
    print(string.format("[UI_Home] 加载配置: %s", configPath))
    
    -- 3. 加载故事配置
    local success, storyConfig = pcall(require, configPath)
    if not success then
        print(string.format("[UI_Home] ❌ 错误：无法加载配置文件 %s: %s", configPath, tostring(storyConfig)))
        return
    end
    
    -- 如果配置是函数，调用它获取配置数据
    if type(storyConfig) == "function" then
        storyConfig = storyConfig()
    end
    
    print("[UI_Home] ✓ 配置加载成功")
    
    -- 4. 提取故事背景文本
    local storyBackground = nil
    if storyConfig.display and storyConfig.display.storyBackground then
        storyBackground = storyConfig.display.storyBackground
        print("[UI_Home] ✓ 找到故事背景文本")
    else
        print("[UI_Home] ⚠️ 警告：配置中未找到 display.storyBackground")
    end
    
    -- 5. 更新UI显示
    self:DisplayStoryInfo(storyConfig, storyBackground)
end

---显示故事信息到UI组件
---@param storyConfig table 故事配置数据
---@param storyBackground string|nil 故事背景文本
function M:DisplayStoryInfo(storyConfig, storyBackground)
    -- 显示故事背景文本
    if self.Text_StoryProfile and storyBackground then
        self.Text_StoryProfile:SetText(storyBackground)
        print("[UI_Home] ✓ 已更新 Text_StoryProfile")
    elseif self.Text_StoryProfile then
        -- 如果没有背景文本，显示默认提示
        self.Text_StoryProfile:SetText("暂无故事简介")
        print("[UI_Home] ⚠️ Text_StoryProfile 存在，但没有故事背景文本")
    else
        print("[UI_Home] ⚠️ 警告：Text_StoryProfile 组件不存在")
    end
    
    -- TODO: 未来可以在这里添加更多UI更新
    -- 例如：更新标题、图片等
    -- if self.Text_StoryTitle and storyConfig.display and storyConfig.display.title then
    --     self.Text_StoryTitle:SetText(storyConfig.display.title)
    -- end
end

-- ==================== 公开接口 ====================

---获取当前状态
---@return string 当前UI状态
function M:GetCurrentState()
    return self.currentState
end

---切换到主菜单状态
function M:GotoMainMenu()
    -- 清除所有选择数据
    self.currentSubState = nil
    self.selectedStoryId = nil
    self.selectedCharacter = nil
    
    self:SwitchToState(M.UIState.MainMenu)
end

---切换到选择游戏状态
function M:GotoChooseGame()
    self:SwitchToState(M.UIState.ChooseGame)
end

---获取当前子状态
---@return string|nil 当前子状态
function M:GetCurrentSubState()
    return self.currentSubState
end

-- ==================== 按钮事件 ====================

---开始按钮点击事件
function M:OnStartClicked()
    print("[UI_Home] 点击开始按钮")
    -- 切换到选择游戏状态
    self:GotoChooseGame()
end

---退出按钮点击事件
function M:OnQuitClicked()
    print("[UI_Home] 点击退出按钮")
    print("[UI_Home] 正在退出游戏...")
    
    -- 获取 PlayerController
    local playerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    
    if playerController then
        -- 退出游戏
        UE.UKismetSystemLibrary.QuitGame(
            self,                                    -- WorldContextObject
            playerController,                        -- PlayerController
            UE.EQuitPreference.Quit,                -- QuitPreference (退出游戏)
            true                                    -- IgnorePlatformRestrictions
        )
        print("[UI_Home] ✅ 已发送退出游戏指令")
    else
        print("[UI_Home] ❌ 错误：无法获取 PlayerController")
    end
end

-- ========== ChooseStory 按钮事件 ==========

---中国故事按钮点击事件
function M:OnChinaClicked()
    print("[UI_Home] 点击中国故事按钮")
    self.selectedStoryId = "china"
    self:SwitchToSubState(M.ChooseGameSubState.StoryInfo)
end

---校园故事按钮点击事件
function M:OnSchoolClicked()
    print("[UI_Home] 点击校园故事按钮")
    self.selectedStoryId = "school"
    self:SwitchToSubState(M.ChooseGameSubState.StoryInfo)
end

---西部故事按钮点击事件
function M:OnWesternClicked()
    print("[UI_Home] 点击西部故事按钮")
    self.selectedStoryId = "western"
    self:SwitchToSubState(M.ChooseGameSubState.StoryInfo)
end

-- ========== StoryInfo 按钮事件 ==========

---进入游戏按钮点击事件
function M:OnEnterClicked()
    print("[UI_Home] 点击进入游戏按钮")
    print(string.format("[UI_Home] 进入故事: %s", self.selectedStoryId or "未选择"))
    
    -- 切换到选择角色界面
    self:SwitchToSubState(M.ChooseGameSubState.ChooseCharacter)
end

-- ========== ChooseCharacter 按钮事件 ==========

---男性角色按钮点击事件
function M:OnCharacterManClicked()
    print("[UI_Home] 点击男性角色按钮")
    self.selectedCharacter = "man"
    self:StartGame()
end

---女性角色按钮点击事件
function M:OnCharacterWomanClicked()
    print("[UI_Home] 点击女性角色按钮")
    self.selectedCharacter = "woman"
    self:StartGame()
end

---开始游戏：关闭UI_Home，打开UI_StoryScene
function M:StartGame()
    print("\n" .. string.rep("=", 70))
    print("[UI_Home] ========== 开始游戏 ==========")
    print(string.format("[UI_Home] 选中的故事: %s", self.selectedStoryId or "未选择"))
    print(string.format("[UI_Home] 选中的角色: %s", self.selectedCharacter or "未选择"))
    print(string.rep("=", 70))
    
    -- 验证选择
    if not self.selectedStoryId then
        print("[UI_Home] ❌ 错误：未选择故事")
        return
    end
    
    if not self.selectedCharacter then
        print("[UI_Home] ❌ 错误：未选择角色")
        return
    end
    
    -- 获取 UIManager
    local uiManager = GameContext:GetUIManager()
    if not uiManager then
        print("[UI_Home] ❌ 错误：无法获取 UIManager")
        return
    end
    
    -- 准备传递给 UI_StoryScene 的参数
    local params = {
        storyId = self.selectedStoryId,
        character = self.selectedCharacter
    }
    
    print(string.format("[UI_Home] 准备打开 UI_StoryScene，参数: storyId=%s, character=%s", 
        params.storyId, params.character))
    
    -- 关闭当前 UI_Home
    print("[UI_Home] 关闭 UI_Home...")
    uiManager:closeUI("Menu/HomeLevel/UI_Home.UI_Home_C")
    
    -- 打开 UI_StoryScene
    print("[UI_Home] 打开 UI_StoryScene...")
    local storySceneUI = uiManager:openUI(
        "Menu/GameLevel/UI_StoryScene.UI_StoryScene_C", 
        uiManager.ui_layer.WINDOW,
        params,
        self
    )
    
    if storySceneUI then
        print("[UI_Home] ✅ UI_StoryScene 打开成功")
    else
        print("[UI_Home] ⚠️ UI_StoryScene 打开失败（可能还未创建）")
    end
    
    print(string.rep("=", 70) .. "\n")
end

-- ========== 返回按钮事件 ==========

---返回按钮点击事件
function M:OnBackClicked()
    print("[UI_Home] 点击返回按钮")
    
    -- 根据当前状态决定返回行为
    if self.currentState == M.UIState.ChooseGame then
        -- 在 ChooseGame 状态下，根据子状态返回
        if self.currentSubState == M.ChooseGameSubState.ChooseCharacter then
            -- ChooseCharacter → StoryInfo
            print("[UI_Home] 从 ChooseCharacter 返回到 StoryInfo")
            self:SwitchToSubState(M.ChooseGameSubState.StoryInfo)
            
        elseif self.currentSubState == M.ChooseGameSubState.StoryInfo then
            -- StoryInfo → ChooseStory
            print("[UI_Home] 从 StoryInfo 返回到 ChooseStory")
            self.selectedStoryId = nil  -- 清除选中的故事
            self:SwitchToSubState(M.ChooseGameSubState.ChooseStory)
            
        elseif self.currentSubState == M.ChooseGameSubState.ChooseStory then
            -- ChooseStory → MainMenu
            print("[UI_Home] 从 ChooseStory 返回到 MainMenu")
            self:GotoMainMenu()
            
        else
            -- 未知子状态，直接返回 MainMenu
            print("[UI_Home] 未知子状态，返回到 MainMenu")
            self:GotoMainMenu()
        end
    else
        -- 其他状态下，返回到 MainMenu
        print("[UI_Home] 返回到 MainMenu")
        self:GotoMainMenu()
    end
end

-- ==================== 调试工具 ====================

---打印当前状态信息
function M:DebugPrintState()
    print("\n[UI_Home] ========== 状态信息 ==========")
    print(string.format("当前主状态: %s", self.currentState or "nil"))
    print(string.format("当前子状态: %s", self.currentSubState or "nil"))
    print(string.format("选中的故事: %s", self.selectedStoryId or "未选择"))
    print(string.format("选中的角色: %s", self.selectedCharacter or "未选择"))
    print("")
    print("--- 主状态组件可见性 ---")
    print(string.format("Canvas_MainMenu: %s", 
        self.Canvas_MainMenu and tostring(self.Canvas_MainMenu:GetVisibility()) or "不存在"))
    print(string.format("Overlay_ChooseGame: %s", 
        self.Overlay_ChooseGame and tostring(self.Overlay_ChooseGame:GetVisibility()) or "不存在"))
    print("")
    print("--- 子状态组件可见性 ---")
    print(string.format("Canvas_ChooseStoryWidget: %s", 
        self.Canvas_ChooseStoryWidget and tostring(self.Canvas_ChooseStoryWidget:GetVisibility()) or "不存在"))
    print(string.format("Canvas_StoryInfoWidget: %s", 
        self.Canvas_StoryInfoWidget and tostring(self.Canvas_StoryInfoWidget:GetVisibility()) or "不存在"))
    print(string.format("Canvas_ChooseCharacterWidget: %s", 
        self.Canvas_ChooseCharacterWidget and tostring(self.Canvas_ChooseCharacterWidget:GetVisibility()) or "不存在"))
    print("=========================================\n")
end

return M

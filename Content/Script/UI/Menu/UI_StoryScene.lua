--
-- DESCRIPTION: 故事场景UI - 根据故事ID加载对应的StoryMapWidget
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local GameContext = require("Core.GameContext")
local Consts = require("Util.Consts")
local StoryLibraryManager = require("GameLayer.StoryLibrary.StoryLibraryManager")
local GameStoryTools = require("GameLayer.GameStory.GameStoryTools")

---@type UI_StoryScene_C
local M = UnLua.Class()

-- 全局实例引用（供Tools访问，用于刷新UI）
M.Instance = nil

-- ==================== 故事地图Widget映射 ====================

-- ==================== 状态定义 ====================

---UI主状态枚举
M.UIState = {
    SceneMap = "SceneMap",      -- 场景地图状态：显示地图，可点击场景进入对话
    SceneChat = "SceneChat"     -- 场景对话状态：显示对话界面
}

---SceneChat子状态枚举
M.ChatSubState = {
    ChatSelect = "ChatSelect",           -- 对话选择：显示可对话的角色列表
    CharacterChat = "CharacterChat"      -- 角色对话：显示与具体角色的对话界面
}

---故事ID到StoryMapWidget的映射表
M.StoryMapWidgetMap = {
    china = "/Game/UI/Menu/GameLevel/StoryMapWidgets/CW_StoryMap1.CW_StoryMap1_C",      -- 中国故事（洛阳）
    school = "/Game/UI/Menu/GameLevel/StoryMapWidgets/CW_StoryMap2.CW_StoryMap2_C",     -- 校园故事
    western = "/Game/UI/Menu/GameLevel/StoryMapWidgets/CW_StoryMap3.CW_StoryMap3_C"     -- 西部故事（黑水镇）
}

---UI故事ID到故事库ID的映射表（与 UI_Home 一致）
M.StoryIdMap = {
    china = "story_luoyang",      -- 中国故事 → 洛阳帽妖灾劫
    school = "story_school",      -- 校园故事 → 囧囧的校园奇遇
    western = "story_blackwater"  -- 西部故事 → 黑水镇纵火案
}

---故事库ID到配置文件路径的映射表（从 StoryLibraryConfig 获取）
M.StoryConfigMap = {
    story_luoyang = "Config.LuoyangStoryConfig",
    story_school = "Config.SchoolJojoConfig",
    story_blackwater = "Config.BlackwaterStoryConfig"
}

---场景名称到场景图片资源路径的映射表
M.SceneImageMap = {
    -- 洛阳故事场景图片
    ["洛阳府衙·文书房"] = "/Game/Arts/Images/UI/Scenes/scene_yamen_office.scene_yamen_office",
    ["洛阳城南·贫民窟"] = "/Game/Arts/Images/UI/Scenes/scene_slum.scene_slum",
    ["洛阳西郊·古寺废墟"] = "/Game/Arts/Images/UI/Scenes/scene_temple.scene_temple",
    
    -- 可以继续添加其他故事的场景图片映射
    -- ["其他场景名称"] = "/Game/Arts/Images/UI/Scenes/xxx.xxx",
}

---角色名称到角色图片资源路径的映射表
M.CharacterImageMap = {
    -- 洛阳故事角色图片
    ["柳珩"] = "/Game/Arts/Images/UI/Character/liuheng.liuheng",
    ["李文书"] = "/Game/Arts/Images/UI/Character/liwenshu.liwenshu",
    ["王捕头"] = "/Game/Arts/Images/UI/Character/wangcaptain.wangcaptain",
    ["游方道士"] = "/Game/Arts/Images/UI/Character/daoist.daoist",
    ["张阿婆"] = "/Game/Arts/Images/UI/Character/zhangpopo.zhangpopo",
    ["摊贩"] = "/Game/Arts/Images/UI/Character/tanfan.tanfan",
    
    -- 可以继续添加其他故事的角色图片映射
    -- ["其他角色名称"] = "/Game/Arts/Images/UI/Character/xxx.xxx",
}

-- ==================== 生命周期 ====================

---构造函数：接收参数并加载对应的StoryMapWidget
---@param params table 参数表 {storyId: string, character: string}
function M:Construct()
    print("\n" .. string.rep("=", 70))
    print("[UI_StoryScene] ========== 故事场景UI初始化 ==========")
    
    -- 🔥 保存实例引用（供 GameStoryTools 的 unlock_choice 工具回调使用）
    M.Instance = self
    
    -- 初始化状态管理字段
    self.currentState = nil             -- 当前主状态
    self.currentChatSubState = nil      -- 当前对话子状态
    self.selectedScene = nil            -- 选中的场景ID
    self.selectedCharacter = nil        -- 选中的角色ID
    
    -- AI 对话相关变量
    self.isAIReplying = false           -- AI是否正在回复
    self.currentAIText = ""             -- 当前AI累积的文本
    self.currentNpcInfo = nil           -- 当前对话的NPC信息
    
    -- 场景角色缓存（在进入场景时初始化）
    self.sceneCharactersCache = {}      -- 当前场景的所有角色信息缓存
    
    -- 获取从UI_Home传递过来的参数
    local params = self:GetInitParams()
    
    if params then
        print(string.format("[UI_StoryScene] 接收到参数: storyId=%s, character=%s", 
            params.storyId or "nil", params.character or "nil"))
        
        -- 保存参数（storyId 用于选择地图Widget，不用于配置查询）
        self.storyId = params.storyId  -- 用于 StoryMapWidgetMap 映射
        self.character = params.character
    else
        print("[UI_StoryScene] ⚠️ 警告：未接收到参数，使用默认值")
        self.storyId = "china"  -- 默认值，用于选择地图Widget
        self.character = "man"
    end
    
    -- 🔥 根据 storyId 参数加载对应的故事（动态加载）
    local loadSuccess = self:LoadStoryByParam(self.storyId)
    
    if not loadSuccess then
        print("[UI_StoryScene] ❌ 故事加载失败，无法继续初始化")
        return
    end
    
    -- 🔥 检查故事是否已加载（参考 GM_Home 的初始化流程）
    -- 这里会设置 self.currentStoryId（从 StoryLibraryManager 获取）
    local storyLoaded = self:CheckStoryLoaded()
    
    if not storyLoaded then
        print("[UI_StoryScene] ❌ 故事未加载，无法继续初始化")
        return
    end
    
    -- 检查必要组件
    self:CheckComponents()
    
    -- 加载对应的StoryMapWidget
    self:LoadStoryMapWidget(self.storyId)
    
    -- 绑定按钮事件
    self:BindButtonEvents()
    
    -- 初始化 LLM 管理器（用于角色对话）
    self:InitializeLLM()
    
    -- 设置初始状态为 SceneMap
    self:SwitchToState(M.UIState.SceneMap)
    
    -- 设置输入模式
    self:SetInputMode()
    
    -- 🎬 显示故事介绍（包含所有设定信息）
    self:ShowStoryIntroduction()
    
    print("[UI_StoryScene] ✅ 故事场景UI初始化完成")
    print(string.rep("=", 70) .. "\n")
end

---设置输入模式：确保鼠标和键盘都可用
function M:SetInputMode()
    local playerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    
    if not playerController then
        print("[UI_StoryScene] ⚠️ 警告：无法获取 PlayerController")
        return
    end
    
    -- 设置为 Game and UI 模式（游戏和UI都响应输入）
    UE.UWidgetBlueprintLibrary.SetInputMode_GameAndUIEx(
        playerController,
        self,
        UE.EMouseLockMode.DoNotLock
    )
    
    -- 显示鼠标光标
    playerController.bShowMouseCursor = true
    
    print("[UI_StoryScene] ✅ 输入模式已设置：Game and UI + 显示鼠标")
end

-- ==================== 故事加载检查 ====================

---🔥 根据UI参数加载对应的故事
---@param uiStoryId string UI故事ID（china/school/western）
---@return boolean 是否加载成功
function M:LoadStoryByParam(uiStoryId)
    print(string.format("[UI_StoryScene] === 根据参数加载故事: %s ===", uiStoryId))
    
    -- 1. 将UI故事ID映射为故事库ID
    local storyLibraryId = M.StoryIdMap[uiStoryId]
    
    if not storyLibraryId then
        print(string.format("[UI_StoryScene] ❌ 错误：未知的故事ID: %s", uiStoryId))
        print("[UI_StoryScene] 💡 支持的故事ID: china, school, western")
        return false
    end
    
    print(string.format("[UI_StoryScene] UI故事ID: %s → 故事库ID: %s", uiStoryId, storyLibraryId))
    
    -- 2. 调用 StoryLibraryManager 加载故事
    local loadResult = StoryLibraryManager:LoadStory(storyLibraryId)
    
    if not loadResult.success then
        print(string.format("[UI_StoryScene] ❌ 错误：故事加载失败 - %s", loadResult.error or "未知错误"))
        return false
    end
    
    -- 3. 加载成功
    print(string.format("[UI_StoryScene] ✅ 故事加载成功: %s", loadResult.story.title))
    print(string.format("[UI_StoryScene]    - ID: %s", loadResult.story.id))
    print(string.format("[UI_StoryScene]    - 难度: %s", loadResult.story.difficulty))
    print(string.format("[UI_StoryScene]    - 预计时长: %s", loadResult.story.estimatedTime))
    
    return true
end

---检查故事是否已加载（参考 GM_Home:init_Story）
function M:CheckStoryLoaded()
    print("[UI_StoryScene] === 检查故事加载状态 ===")
    
    -- 获取当前故事
    local currentStory = StoryLibraryManager:GetCurrentStory()
    
    if not currentStory then
        print("[UI_StoryScene] ❌ 错误：未加载任何故事！")
        print("[UI_StoryScene] 💡 请确保 GM_Home:init_Story() 已执行")
        print("[UI_StoryScene] 💡 预期流程：")
        print("[UI_StoryScene]    1. GM_Home 初始化时调用 StoryLibraryManager:Initialize()")
        print("[UI_StoryScene]    2. GM_Home 加载故事 StoryLibraryManager:LoadStory('story_xxx')")
        print("[UI_StoryScene]    3. 然后才能打开 UI_StoryScene")
        return false
    end
    
    -- 🔥 保存当前加载的故事ID（用于后续配置查询）
    self.currentStoryId = currentStory.id
    
    print(string.format("[UI_StoryScene] ✓ 已加载故事: %s", currentStory.title))
    print(string.format("[UI_StoryScene]    - ID: %s", currentStory.id))
    print(string.format("[UI_StoryScene]    - 难度: %s", currentStory.difficulty))
    print(string.format("[UI_StoryScene]    - 预计时长: %s", currentStory.estimatedTime))
    
    return true
end

-- ==================== LLM 管理器初始化 ====================

---初始化 LLM 管理器（用于角色对话）
function M:InitializeLLM()
    print("[UI_StoryScene] === 初始化 LLM 管理器 ===")
    
    -- 获取 LLM 管理器
    self.llmMgr = GameContext:GetLlmManager()
    
    if not self.llmMgr then
        print("[UI_StoryScene] ❌ 错误：无法获取 LLM 管理器")
        return
    end
    
    -- 配置 LLM（使用通义千问）
    self.llmMgr:SetApiKey("sk-592ab9ea805f48b68940ece20b7afa39")
    self.llmMgr:UseProvider("qwen")
    self.llmMgr:SetModel("qwen-max")
    
    -- 🔥 使用 StoryLibraryManager 获取的故事ID，而非 StoryIdMap 映射
    if not self.currentStoryId then
        print("[UI_StoryScene] ⚠️ 警告：self.currentStoryId 未设置，跳过故事配置")
        print("[UI_StoryScene] ✅ LLM 管理器初始化完成（无故事配置）")
        return
    end
    
    print(string.format("[UI_StoryScene] 使用故事ID: %s", self.currentStoryId))
    
    local configPath = M.StoryConfigMap[self.currentStoryId]
    if not configPath then
        print(string.format("[UI_StoryScene] ❌ 错误：未找到配置路径 %s", self.currentStoryId))
        print("[UI_StoryScene] ✅ LLM 管理器初始化完成（无故事配置）")
        return
    end
    
    print(string.format("[UI_StoryScene] 配置路径: %s", configPath))
    
    local success, storyConfig = pcall(require, configPath)
    if success then
        if type(storyConfig) == "function" then
            storyConfig = storyConfig()
        end
        
        -- 设置游戏世界观（从故事配置的 background.text 获取）
        if storyConfig.background and storyConfig.background.text then
            self.llmMgr:SetGameWorld(storyConfig.background.text)
            print("[UI_StoryScene] ✓ 已设置游戏世界观")
        elseif storyConfig.background and type(storyConfig.background) == "string" then
            -- 兼容：如果 background 直接是字符串
            self.llmMgr:SetGameWorld(storyConfig.background)
            print("[UI_StoryScene] ✓ 已设置游戏世界观（字符串）")
        end
        
        -- 设置玩家身份（从 display.playerSetting 获取）
        if storyConfig.display and storyConfig.display.playerSetting then
            self.llmMgr:SetPlayerIdentity(storyConfig.display.playerSetting)
            print("[UI_StoryScene] ✓ 已设置玩家身份")
        elseif storyConfig.playerIdentity then
            -- 兼容：旧版配置
            self.llmMgr:SetPlayerIdentity(storyConfig.playerIdentity)
            print("[UI_StoryScene] ✓ 已设置玩家身份（旧版）")
        end
        
        -- 设置游戏规则（如果有）
        if storyConfig.gameRules then
            self.llmMgr:SetGameRules(storyConfig.gameRules)
            print("[UI_StoryScene] ✓ 已设置游戏规则")
        end
    else
        print(string.format("[UI_StoryScene] ❌ 错误：无法加载配置文件 %s", configPath))
        print(string.format("[UI_StoryScene] 错误详情: %s", tostring(storyConfig)))
    end
    
    -- 🔥 注册 GameStory 相关的 Tools（让AI能调用 unlock_choice 等工具）
    GameStoryTools.RegisterAllTools(self.llmMgr)
    print("[UI_StoryScene] ✅ GameStory Tools 已注册")
    
    print("[UI_StoryScene] ✅ LLM 管理器初始化完成")
end

-- ==================== 组件检查 ====================

---检查UI组件是否存在
function M:CheckComponents()
    print("[UI_StoryScene] === 组件检查 ===")
    
    -- 检查主要组件
    if self.SizeBox then
        print("[UI_StoryScene] ✓ SizeBox 存在")
    else
        print("[UI_StoryScene] ❌ SizeBox 不存在！")
    end
    
    if self.Canvas_ChatWidget then
        print("[UI_StoryScene] ✓ Canvas_ChatWidget 存在")
    else
        print("[UI_StoryScene] ⚠️ Canvas_ChatWidget 不存在")
    end
    
    if self.Button_Back then
        print("[UI_StoryScene] ✓ Button_Back 存在")
    else
        print("[UI_StoryScene] ⚠️ Button_Back 不存在")
    end
    
    -- 检查对话相关组件
    if self.Button_Submmit then
        print("[UI_StoryScene] ✓ Button_Submmit 存在")
    else
        print("[UI_StoryScene] ⚠️ Button_Submmit 不存在（需要用于发送消息）")
    end
    
    if self.EditText_Input then
        print("[UI_StoryScene] ✓ EditText_Input 存在")
    else
        print("[UI_StoryScene] ⚠️ EditText_Input 不存在（需要用于输入文本）")
    end
    
    if self.Overlay_Tint then
        print("[UI_StoryScene] ✓ Overlay_Tint 存在")
    else
        print("[UI_StoryScene] ⚠️ Overlay_Tint 不存在（需要用于显示对话）")
    end
    
    if self.Text_dialog then
        print("[UI_StoryScene] ✓ Text_dialog 存在")
    else
        print("[UI_StoryScene] ⚠️ Text_dialog 不存在（需要用于显示对话文本）")
    end
    
    -- 检查覆盖层关闭按钮（可选，用于点击关闭故事介绍等内容）
    if self.Button_OverlayClose then
        print("[UI_StoryScene] ✓ Button_OverlayClose 存在")
    else
        print("[UI_StoryScene] ⚠️ Button_OverlayClose 不存在（可选，用于点击关闭覆盖层）")
    end
    
    -- 检查场景背景图片组件
    if self.Image_Scene then
        print("[UI_StoryScene] ✓ Image_Scene 存在")
    else
        print("[UI_StoryScene] ⚠️ Image_Scene 不存在（用于显示场景背景图片）")
        print("[UI_StoryScene] 💡 请在蓝图中添加名为 Image_Scene 的 Image 组件")
    end
    
    -- 检查角色信息覆盖层组件
    if self.Overlay_CharacterInfo then
        print("[UI_StoryScene] ✓ Overlay_CharacterInfo 存在")
    else
        print("[UI_StoryScene] ⚠️ Overlay_CharacterInfo 不存在（用于显示角色介绍）")
        print("[UI_StoryScene] 💡 请在蓝图中添加名为 Overlay_CharacterInfo 的覆盖层组件")
    end
    
    if self.Text_CharacterInfo then
        print("[UI_StoryScene] ✓ Text_CharacterInfo 存在")
    else
        print("[UI_StoryScene] ⚠️ Text_CharacterInfo 不存在（用于显示角色介绍文本）")
        print("[UI_StoryScene] 💡 请在 Overlay_CharacterInfo 中添加名为 Text_CharacterInfo 的文本组件")
    end
end

-- ==================== 按钮事件绑定 ====================

---绑定所有按钮事件
function M:BindButtonEvents()
    print("[UI_StoryScene] === 绑定按钮事件 ===")
    
    -- 绑定返回按钮
    if self.Button_Back then
        self.Button_Back.OnClicked:Add(self, self.OnBackClicked)
        print("[UI_StoryScene] ✓ Button_Back 事件已绑定")
    else
        print("[UI_StoryScene] ⚠️ Button_Back 不存在，无法绑定事件")
    end
    
    -- 绑定提交按钮（用于发送对话）
    if self.Button_Submmit then
        print("[UI_StoryScene] Button_Submmit 类型: " .. tostring(type(self.Button_Submmit)))
        
        -- 检查是否有 OnClicked 事件
        if self.Button_Submmit.OnClicked then
            -- 使用一个包装函数来确保能捕获错误
            local clickHandler = function()
                print("\n[UI_StoryScene] !!!!! 按钮点击事件被触发 !!!!!")
                
                -- 使用 pcall 捕获可能的错误
                local success, err = pcall(function()
                    self:OnSubmitClicked()
                end)
                
                if not success then
                    print(string.format("[UI_StoryScene] ❌ OnSubmitClicked 执行失败: %s", tostring(err)))
                end
            end
            
            self.Button_Submmit.OnClicked:Add(self, clickHandler)
            print("[UI_StoryScene] ✅ Button_Submmit 事件已成功绑定")
            
            -- 测试：检查函数是否存在
            if self.OnSubmitClicked then
                print("[UI_StoryScene] ✓ OnSubmitClicked 函数存在")
            else
                print("[UI_StoryScene] ❌ OnSubmitClicked 函数不存在！")
            end
        else
            print("[UI_StoryScene] ❌ Button_Submmit 没有 OnClicked 事件")
        end
    else
        print("[UI_StoryScene] ❌ Button_Submmit 不存在，无法绑定事件")
        print("[UI_StoryScene] 💡 请在 UE 蓝图中添加名为 Button_Submmit 的按钮组件")
    end
    
    -- 绑定覆盖层关闭按钮（可选）
    if self.Button_OverlayClose then
        self.Button_OverlayClose.OnClicked:Add(self, self.OnOverlayCloseClicked)
        print("[UI_StoryScene] ✓ Button_OverlayClose 事件已绑定")
    else
        print("[UI_StoryScene] ⚠️ Button_OverlayClose 不存在（可选组件）")
        print("[UI_StoryScene] 💡 如需点击关闭覆盖层功能，请在蓝图的 Overlay_Tint 中添加名为 Button_OverlayClose 的按钮")
    end
end

-- ==================== 参数传递 ====================

---获取初始化参数（从UIManager传递）
---@return table|nil params 参数表
function M:GetInitParams()
    -- UIManager在创建UI时会将参数保存到UI实例的 InitParams 字段
    -- 这是UnLua框架约定的参数传递方式
    return self.InitParams
end

-- ==================== StoryMapWidget加载 ====================

---加载对应故事的StoryMapWidget
---@param storyId string 故事ID（china/school/western）
function M:LoadStoryMapWidget(storyId)
    print(string.format("[UI_StoryScene] === 加载StoryMapWidget: %s ===", storyId))
    
    -- 1. 检查SizeBox是否存在
    if not self.SizeBox then
        print("[UI_StoryScene] ❌ 错误：SizeBox 不存在！")
        return
    end
    
    print("[UI_StoryScene] ✓ SizeBox 存在")
    
    -- 2. 获取对应的Widget路径
    local widgetPath = M.StoryMapWidgetMap[storyId]
    if not widgetPath then
        print(string.format("[UI_StoryScene] ❌ 错误：未找到故事ID '%s' 对应的Widget路径", storyId))
        print("[UI_StoryScene] 可用的故事ID: china, school, western")
        return
    end
    
    print(string.format("[UI_StoryScene] Widget路径: %s", widgetPath))
    
    -- 3. 加载Widget蓝图类
    local widgetClass = UE.UClass.Load(widgetPath)
    if not widgetClass then
        print(string.format("[UI_StoryScene] ❌ 错误：无法加载Widget类: %s", widgetPath))
        print("[UI_StoryScene] 请确认蓝图文件是否存在")
        return
    end
    
    print("[UI_StoryScene] ✓ Widget类加载成功")
    
    -- 4. 创建Widget实例
    local world = UE.UGameplayStatics.GetGameInstance(self)
    if not world then
        print("[UI_StoryScene] ❌ 错误：无法获取WorldContext")
        return
    end
    
    local storyMapWidget = UE.UWidgetBlueprintLibrary.Create(world, widgetClass)
    if not storyMapWidget then
        print("[UI_StoryScene] ❌ 错误：创建Widget实例失败")
        return
    end
    
    print("[UI_StoryScene] ✓ Widget实例创建成功")
    
    -- 5. 添加到SizeBox
    self.SizeBox:AddChild(storyMapWidget)
    print("[UI_StoryScene] ✓ Widget已添加到SizeBox")
    
    -- 6. 保存Widget引用（方便后续操作）
    self.currentStoryMapWidget = storyMapWidget
    
    -- 7. 绑定地图点击事件
    self:BindMapClickEvent(storyMapWidget)
    
    -- 8. 🔥 设置地图介绍文本（显示完整故事配置）
    self:SetMapIntroductionText(storyMapWidget)
    
    print(string.format("[UI_StoryScene] ✅ StoryMapWidget '%s' 加载完成", storyId))
end

---绑定StoryMapWidget的点击事件
---@param mapWidget userdata StoryMapWidget实例
function M:BindMapClickEvent(mapWidget)
    if not mapWidget then
        print("[UI_StoryScene] ⚠️ 警告：mapWidget为空，无法绑定事件")
        return
    end
    
    -- 检查是否有 MapClickEvent
    if not mapWidget.MapClickEvent then
        print("[UI_StoryScene] ⚠️ 警告：mapWidget 没有 MapClickEvent")
        return
    end
    
    -- 绑定事件（蓝图事件使用 Add 方法绑定）
    mapWidget.MapClickEvent:Add(self, self.OnMapClickEvent)
    print("[UI_StoryScene] ✓ MapClickEvent 事件已绑定")
end

---设置地图介绍文本（显示完整故事配置）
---@param mapWidget userdata StoryMapWidget实例
function M:SetMapIntroductionText(mapWidget)
    print("[UI_StoryScene] === 设置地图介绍文本 ===")
    
    if not mapWidget then
        print("[UI_StoryScene] ⚠️ 警告：mapWidget为空")
        return
    end
    
    -- 检查 Text_Map 组件是否存在
    if not mapWidget.Text_Map then
        print("[UI_StoryScene] ⚠️ 警告：mapWidget 没有 Text_Map 组件")
        print("[UI_StoryScene] 💡 请在地图Widget蓝图中添加名为 Text_Map 的文本组件")
        return
    end
    
    print("[UI_StoryScene] ✓ Text_Map 组件存在")
    
    -- 获取故事配置
    local displayData = self:GetStoryDisplayData()
    
    if not displayData then
        print("[UI_StoryScene] ⚠️ 警告：无法获取故事配置数据")
        mapWidget.Text_Map:SetText("暂无故事简介")
        return
    end
    
    -- 构建完整的故事信息文本
    local storyInfoText = self:BuildStoryInfoText(displayData)
    
    -- 🔥 添加循环次数前缀（如果循环次数 > 0）
    local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
    local loopCount = BM_StoryRuntime:GetLoopCount()
    
    local fullText = storyInfoText
    if loopCount > 0 then
        local loopPrefix = string.format("【第 %d 次循环】\n\n", loopCount)
        fullText = loopPrefix .. storyInfoText
        print(string.format("[UI_StoryScene] ✓ 添加循环次数前缀: 第 %d 次", loopCount))
    end
    
    -- 设置到 Text_Map
    mapWidget.Text_Map:SetText(fullText)
    print("[UI_StoryScene] ✅ 已设置地图介绍文本（包含完整故事配置）")
end

---获取故事配置的display数据
---@return table|nil displayData 故事配置的display字段
function M:GetStoryDisplayData()
    print("[UI_StoryScene] 获取故事配置display数据...")
    
    -- 使用 self.currentStoryId（从 StoryLibraryManager 获取的实际故事ID）
    if not self.currentStoryId then
        print("[UI_StoryScene] ❌ 错误：self.currentStoryId 未设置")
        return nil
    end
    
    print(string.format("[UI_StoryScene] 故事库ID: %s", self.currentStoryId))
    
    -- 获取配置路径
    local configPath = M.StoryConfigMap[self.currentStoryId]
    if not configPath then
        print(string.format("[UI_StoryScene] ❌ 错误：未找到配置路径 %s", self.currentStoryId))
        return nil
    end
    
    print(string.format("[UI_StoryScene] 配置路径: %s", configPath))
    
    -- 加载故事配置
    local success, storyConfig = pcall(require, configPath)
    if not success then
        print(string.format("[UI_StoryScene] ❌ 错误：无法加载配置文件 %s: %s", configPath, tostring(storyConfig)))
        return nil
    end
    
    -- 如果配置是函数，调用它获取配置数据
    if type(storyConfig) == "function" then
        storyConfig = storyConfig()
    end
    
    print("[UI_StoryScene] ✓ 配置加载成功")
    
    -- 提取 display 字段
    if storyConfig.display then
        print("[UI_StoryScene] ✓ 找到故事配置display数据")
        return storyConfig.display
    else
        print("[UI_StoryScene] ⚠️ 警告：配置中未找到 display 字段")
        return nil
    end
end

---构建完整的故事信息文本（与 UI_Home 的 BuildStoryInfoText 一致）
---@param displayData table 故事配置的display数据
---@return string 格式化后的完整文本
function M:BuildStoryInfoText(displayData)
    local sections = {}
    
    -- 1. 故事背景
    if displayData.storyBackground then
        table.insert(sections, displayData.storyBackground)
    end
    
    -- 2. 玩家设定
    if displayData.playerSetting then
        table.insert(sections, "\n" .. displayData.playerSetting)
    end
    
    -- 3. 角色设定
    if displayData.characters and #displayData.characters > 0 then
        table.insert(sections, "\n【主要角色】")
        for i, character in ipairs(displayData.characters) do
            local charInfo = string.format(
                "\n%d. %s（%s）\n外貌：%s\n初见印象：%s",
                i,
                character.name or "未知",
                character.title or "未知",
                character.appearance or "未知",
                character.firstImpression or "未知"
            )
            table.insert(sections, charInfo)
        end
    end
    
    -- 4. 场景设定
    if displayData.locations and #displayData.locations > 0 then
        table.insert(sections, "\n\n【主要场景】")
        for i, location in ipairs(displayData.locations) do
            local locInfo = string.format(
                "\n%d. %s\n描述：%s\n氛围：%s\n活动：%s",
                i,
                location.name or "未知",
                location.description or "未知",
                location.atmosphere or "未知",
                location.activities or "未知"
            )
            table.insert(sections, locInfo)
        end
    end
    
    -- 5. 初始线索
    if displayData.initialClues and #displayData.initialClues > 0 then
        table.insert(sections, "\n\n【初始线索】")
        for i, clue in ipairs(displayData.initialClues) do
            table.insert(sections, string.format("\n· %s", clue))
        end
    end
    
    -- 6. 开局提示
    if displayData.openingHints and #displayData.openingHints > 0 then
        table.insert(sections, "\n\n【探索提示】")
        for i, hint in ipairs(displayData.openingHints) do
            table.insert(sections, string.format("\n· %s", hint))
        end
    end
    
    -- 合并所有部分
    return table.concat(sections, "")
end

---处理地图点击事件
function M:OnMapClickEvent()
    print("[UI_StoryScene] ========== 地图点击事件触发 ==========")
    
    -- 获取当前StoryMapWidget的LocationIndex
    if not self.currentStoryMapWidget then
        print("[UI_StoryScene] ❌ 错误：currentStoryMapWidget 为空")
        return
    end
    
    local locationIndex = self.currentStoryMapWidget.LocationIndex
    print(string.format("[UI_StoryScene] LocationIndex: %s", tostring(locationIndex)))
    
    -- 根据LocationIndex进入对应场景
    self:EnterSceneByIndex(locationIndex)
end

---根据LocationIndex进入对应场景
---@param locationIndex number 地点索引
function M:EnterSceneByIndex(locationIndex)
    print(string.format("[UI_StoryScene] 根据索引进入场景: %d", locationIndex))
    
    -- 从故事配置中获取场景信息
    local sceneInfo = self:GetSceneInfoByIndex(locationIndex)
    
    if sceneInfo then
        print(string.format("[UI_StoryScene] 进入场景: %s (索引: %d)", sceneInfo.name, locationIndex))
        
        -- 保存场景索引（用于后续查询）
        self.currentLocationIndex = locationIndex
        
        -- 🔥 设置场景背景图片
        self:SetSceneImage(sceneInfo.name)
        
        -- 进入场景（使用场景名称作为ID）
        self:EnterScene(sceneInfo.name)
    else
        print(string.format("[UI_StoryScene] ⚠️ 警告：未找到索引 %d 对应的场景", locationIndex))
    end
end

---设置场景背景图片
---@param sceneName string 场景名称
function M:SetSceneImage(sceneName)
    print(string.format("[UI_StoryScene] === 设置场景背景图片: %s ===", sceneName))
    
    -- 检查Image_Scene组件是否存在
    if not self.Image_Scene then
        print("[UI_StoryScene] ⚠️ 警告：Image_Scene 组件不存在，请在UE蓝图中添加")
        return
    end
    
    -- 从映射表获取图片资源路径
    local imagePath = M.SceneImageMap[sceneName]
    
    if not imagePath then
        print(string.format("[UI_StoryScene] ⚠️ 警告：未找到场景 '%s' 对应的图片资源", sceneName))
        print("[UI_StoryScene] 💡 请在 M.SceneImageMap 中添加场景图片映射")
        return
    end
    
    print(string.format("[UI_StoryScene] 图片资源路径: %s", imagePath))
    
    -- 加载纹理资源
    local texture = UE.UObject.Load(imagePath)
    
    if not texture then
        print(string.format("[UI_StoryScene] ❌ 错误：无法加载图片资源: %s", imagePath))
        print("[UI_StoryScene] 💡 请检查图片资源路径是否正确")
        return
    end
    
    print("[UI_StoryScene] ✓ 图片资源加载成功")
    
    -- 设置图片到Image_Scene
    local success = pcall(function()
        -- 尝试使用SetBrushFromTexture方法
        if self.Image_Scene.SetBrushFromTexture then
            self.Image_Scene:SetBrushFromTexture(texture)
            print("[UI_StoryScene] ✓ 使用 SetBrushFromTexture 设置图片")
        -- 尝试使用SetBrushResourceObject方法
        elseif self.Image_Scene.SetBrushResourceObject then
            self.Image_Scene:SetBrushResourceObject(texture)
            print("[UI_StoryScene] ✓ 使用 SetBrushResourceObject 设置图片")
        else
            print("[UI_StoryScene] ⚠️ Image_Scene 没有可用的图片设置方法")
        end
    end)
    
    if not success then
        print("[UI_StoryScene] ❌ 设置图片失败")
        return
    end
    
    -- 显示Image_Scene组件
    self.Image_Scene:SetVisibility(UE.ESlateVisibility.Visible)
    print("[UI_StoryScene] ✓ Image_Scene 已显示")
    
    print(string.format("[UI_StoryScene] ✅ 场景背景图片设置完成: %s", sceneName))
end

---设置角色图片
---@param characterName string 角色名称
function M:SetCharacterImage(characterName)
    print(string.format("[UI_StoryScene] === 设置角色图片: %s ===", characterName))
    
    -- 检查Image_Character组件是否存在
    if not self.Image_Character then
        print("[UI_StoryScene] ⚠️ 警告：Image_Character 组件不存在，请在UE蓝图中添加")
        return
    end
    
    -- 从映射表获取图片资源路径
    local imagePath = M.CharacterImageMap[characterName]
    
    if not imagePath then
        print(string.format("[UI_StoryScene] ⚠️ 警告：未找到角色 '%s' 对应的图片资源", characterName))
        print("[UI_StoryScene] 💡 请在 M.CharacterImageMap 中添加角色图片映射")
        -- 即使没有图片，也显示Image_Character容器（可能有默认图）
        self.Image_Character:SetVisibility(UE.ESlateVisibility.Visible)
        return
    end
    
    print(string.format("[UI_StoryScene] 角色图片资源路径: %s", imagePath))
    
    -- 加载纹理资源
    local texture = UE.UObject.Load(imagePath)
    
    if not texture then
        print(string.format("[UI_StoryScene] ❌ 错误：无法加载角色图片资源: %s", imagePath))
        print("[UI_StoryScene] 💡 请检查图片资源路径是否正确")
        -- 即使加载失败，也显示Image_Character容器
        self.Image_Character:SetVisibility(UE.ESlateVisibility.Visible)
        return
    end
    
    print("[UI_StoryScene] ✓ 角色图片资源加载成功")
    
    -- 设置图片到Image_Character
    local success = pcall(function()
        -- 尝试使用SetBrushFromTexture方法
        if self.Image_Character.SetBrushFromTexture then
            self.Image_Character:SetBrushFromTexture(texture)
            print("[UI_StoryScene] ✓ 使用 SetBrushFromTexture 设置角色图片")
        -- 尝试使用SetBrushResourceObject方法
        elseif self.Image_Character.SetBrushResourceObject then
            self.Image_Character:SetBrushResourceObject(texture)
            print("[UI_StoryScene] ✓ 使用 SetBrushResourceObject 设置角色图片")
        else
            print("[UI_StoryScene] ⚠️ Image_Character 没有可用的图片设置方法")
        end
    end)
    
    if not success then
        print("[UI_StoryScene] ❌ 设置角色图片失败")
        -- 即使设置失败，也显示Image_Character容器
        self.Image_Character:SetVisibility(UE.ESlateVisibility.Visible)
        return
    end
    
    -- 显示Image_Character组件
    self.Image_Character:SetVisibility(UE.ESlateVisibility.Visible)
    print("[UI_StoryScene] ✓ Image_Character 已显示")
    
    print(string.format("[UI_StoryScene] ✅ 角色图片设置完成: %s", characterName))
end

---根据索引获取场景信息（从故事配置中读取）
---@param locationIndex number 地点索引
---@return table|nil sceneInfo 场景信息
function M:GetSceneInfoByIndex(locationIndex)
    -- 获取故事配置路径
    local storyLibraryId = M.StoryIdMap[self.storyId]
    if not storyLibraryId then
        print(string.format("[UI_StoryScene] ❌ 错误：未找到故事映射 %s", self.storyId))
        return nil
    end
    
    local configPath = M.StoryConfigMap[storyLibraryId]
    if not configPath then
        print(string.format("[UI_StoryScene] ❌ 错误：未找到配置路径 %s", storyLibraryId))
        return nil
    end
    
    -- 加载故事配置
    local success, storyConfig = pcall(require, configPath)
    if not success then
        print(string.format("[UI_StoryScene] ❌ 错误：无法加载配置文件 %s", configPath))
        return nil
    end
    
    -- 如果配置是函数，调用它获取配置数据
    if type(storyConfig) == "function" then
        storyConfig = storyConfig()
    end
    
    -- 从配置中获取场景信息
    if storyConfig.display and storyConfig.display.locations then
        local locations = storyConfig.display.locations
        
        -- locationIndex 对应数组索引（索引从1开始）
        local arrayIndex = locationIndex + 1
        
        if locations[arrayIndex] then
            print(string.format("[UI_StoryScene] ✓ 找到场景: %s", locations[arrayIndex].name))
            return locations[arrayIndex]
        else
            print(string.format("[UI_StoryScene] ⚠️ 配置中没有索引 %d 的场景", locationIndex))
            return nil
        end
    else
        print("[UI_StoryScene] ⚠️ 配置中未找到 display.locations")
        return nil
    end
end

-- ==================== 状态切换 ====================

---切换UI主状态
---@param newState string 新状态（使用 M.UIState 枚举）
function M:SwitchToState(newState)
    if self.currentState == newState then
        print(string.format("[UI_StoryScene] 状态未改变，已经是 %s", newState))
        return
    end
    
    print(string.format("[UI_StoryScene] 状态切换: %s -> %s", 
        self.currentState or "nil", newState))
    
    -- 根据状态显示/隐藏对应的组件
    if newState == M.UIState.SceneMap then
        self:ShowSceneMap()
    elseif newState == M.UIState.SceneChat then
        self:ShowSceneChat()
    else
        print(string.format("[UI_StoryScene] ❌ 错误：未知状态 %s", newState))
        return
    end
    
    -- 更新当前状态
    self.currentState = newState
    print(string.format("[UI_StoryScene] ✅ 当前状态: %s", self.currentState))
end

---显示场景地图（隐藏对话界面）
function M:ShowSceneMap()
    print("[UI_StoryScene] 显示 SceneMap，隐藏 SceneChat")
    
    -- 显示 SizeBox（地图）
    if self.SizeBox then
        self.SizeBox:SetVisibility(UE.ESlateVisibility.Visible)
        print("[UI_StoryScene] ✓ SizeBox 已显示")
    end
    
    -- 隐藏 Canvas_ChatWidget（对话）
    if self.Canvas_ChatWidget then
        self.Canvas_ChatWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
        print("[UI_StoryScene] ✓ Canvas_ChatWidget 已隐藏")
    end
    
    -- 🔥 隐藏场景图片（回到地图时）
    if self.Image_Scene then
        self.Image_Scene:SetVisibility(UE.ESlateVisibility.Collapsed)
        print("[UI_StoryScene] ✓ Image_Scene 已隐藏")
    end
    
    -- 清空子状态
    self.currentChatSubState = nil
end

---显示场景对话（隐藏地图）
function M:ShowSceneChat()
    print("[UI_StoryScene] 隐藏 SceneMap，显示 SceneChat")
    
    -- 隐藏 SizeBox（地图）
    if self.SizeBox then
        self.SizeBox:SetVisibility(UE.ESlateVisibility.Collapsed)
        print("[UI_StoryScene] ✓ SizeBox 已隐藏")
    end
    
    -- 显示 Canvas_ChatWidget（对话）
    if self.Canvas_ChatWidget then
        self.Canvas_ChatWidget:SetVisibility(UE.ESlateVisibility.Visible)
        print("[UI_StoryScene] ✓ Canvas_ChatWidget 已显示")
    end
    
    -- 默认进入 ChatSelect 子状态
    self:SwitchToChatSubState(M.ChatSubState.ChatSelect)
end

-- ==================== 对话子状态切换 ====================

---切换SceneChat子状态
---@param newSubState string 新子状态（使用 M.ChatSubState 枚举）
function M:SwitchToChatSubState(newSubState)
    if self.currentChatSubState == newSubState then
        print(string.format("[UI_StoryScene] 子状态未改变，已经是 %s", newSubState))
        return
    end
    
    print(string.format("[UI_StoryScene] 子状态切换: %s -> %s", 
        self.currentChatSubState or "nil", newSubState))
    
    -- 根据子状态执行对应操作
    if newSubState == M.ChatSubState.ChatSelect then
        self:ShowChatSelect()
    elseif newSubState == M.ChatSubState.CharacterChat then
        self:ShowCharacterChat()
    else
        print(string.format("[UI_StoryScene] ❌ 错误：未知子状态 %s", newSubState))
        return
    end
    
    -- 更新当前子状态
    self.currentChatSubState = newSubState
    print(string.format("[UI_StoryScene] ✅ 当前子状态: %s", self.currentChatSubState))
end

---显示对话选择界面
function M:ShowChatSelect()
    print("[UI_StoryScene] 显示 ChatSelect 界面")
    
    -- 检查必要组件
    if not self.HorizontalBox_Character then
        print("[UI_StoryScene] ❌ 错误：HorizontalBox_Character 不存在")
        return
    end
    
    -- 设置场景名字（一直显示）
    self:SetSceneName()
    
    -- 隐藏对话相关组件（在选择角色时不需要显示）
    self:HideChatComponents()
    
    -- 显示场景描述（在Overlay_Tint中）- 放在HideChatComponents后面，避免被隐藏
    self:ShowSceneDescription()
    
    -- 显示角色选择按钮容器
    self:ShowCharacterButtons()
    
    -- 清空现有的角色按钮
    self:ClearCharacterButtons()
    
    -- 获取当前场景的角色列表
    local characters = self:GetSceneCharacters()
    
    if not characters or #characters == 0 then
        print("[UI_StoryScene] ⚠️ 当前场景无角色")
        return
    end
    
    -- 为每个角色创建按钮
    self:CreateCharacterButtons(characters)
end

---显示角色对话界面
function M:ShowCharacterChat()
    print("[UI_StoryScene] 显示 CharacterChat 界面")
    
    if not self.selectedCharacter then
        print("[UI_StoryScene] ⚠️ 警告：未选择角色")
        return
    end
    
    print(string.format("[UI_StoryScene] 与角色 %s 进行对话", self.selectedCharacter))
    
    -- 隐藏角色选择按钮（进入对话后不再显示角色列表）
    self:HideCharacterButtons()
    
    -- 更新UI组件显示状态
    self:UpdateChatComponents()
    
    -- 设置场景名字
    self:SetSceneName()
    
    -- 🔥 加载角色图片
    self:SetCharacterImage(self.selectedCharacter)
    
    -- 清空关键抉择列表
    self:ClearSceneChoices()
    
    -- 🔥 确保 Overlay_Tint 隐藏（初始时不显示对话覆盖层）
    self:HideDialogOverlay()
    
    -- 显示角色介绍（会显示在 Overlay_CharacterInfo 中）
    self:ShowCharacterIntroduction()
    
    -- 显示输入框（人物对话状态）
    self:ShowInputBox()
    
    -- 绑定输入框事件
    self:BindInputBoxEvents()
    
    print("[UI_StoryScene] ✅ CharacterChat 界面已显示")
end

-- ==================== 对话界面组件管理 ====================

---更新对话界面组件的显示状态
function M:UpdateChatComponents()
    print("[UI_StoryScene] 更新对话界面组件显示状态...")
    
    -- 显示场景名字文本
    if self.Text_SceneName then
        self.Text_SceneName:SetVisibility(UE.ESlateVisibility.Visible)
    end
    
    -- 显示角色图片（即使暂时不加载图片，也显示容器）
    if self.Image_Character then
        self.Image_Character:SetVisibility(UE.ESlateVisibility.Visible)
    end
    
    -- 显示关键抉择容器
    if self.VerticalBox_SceneChoices then
        self.VerticalBox_SceneChoices:SetVisibility(UE.ESlateVisibility.Visible)
    end
    
    print("[UI_StoryScene] ✓ 对话界面组件已更新")
end

---隐藏对话相关组件（在ChatSelect状态时使用）
function M:HideChatComponents()
    print("[UI_StoryScene] 隐藏对话相关组件...")
    
    -- Text_SceneName 始终显示，不隐藏
    
    -- 隐藏角色图片
    if self.Image_Character then
        self.Image_Character:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    
    -- 隐藏关键抉择容器
    if self.VerticalBox_SceneChoices then
        self.VerticalBox_SceneChoices:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    
    -- 隐藏对话覆盖层
    self:HideDialogOverlay()
    
    -- 🔥 隐藏角色信息覆盖层
    self:HideCharacterInfoOverlay()
    
    -- 隐藏输入框
    self:HideInputBox()
    
    print("[UI_StoryScene] ✓ 对话相关组件已隐藏（保持场景名字显示）")
end

---设置场景名字
function M:SetSceneName()
    if not self.Text_SceneName then
        print("[UI_StoryScene] ⚠️ 警告：Text_SceneName 不存在")
        return
    end
    
    if not self.selectedScene then
        print("[UI_StoryScene] ⚠️ 警告：未选择场景")
        return
    end
    
    -- 设置场景名字
    self.Text_SceneName:SetText(self.selectedScene)
    print(string.format("[UI_StoryScene] ✓ 场景名字已设置: %s", self.selectedScene))
end

---显示场景描述（在角色选择时显示）
function M:ShowSceneDescription()
    print("[UI_StoryScene] 显示场景描述...")
    
    if not self.selectedScene then
        print("[UI_StoryScene] ⚠️ 警告：未选择场景")
        return
    end
    
    -- 获取场景信息
    local sceneInfo = self:GetCurrentSceneInfo()
    
    if not sceneInfo then
        print("[UI_StoryScene] ❌ 错误：无法获取场景信息")
        return
    end
    
    -- 获取场景描述
    local description = sceneInfo.description or "暂无场景描述"
    
    -- 显示覆盖层并设置描述
    self:ShowDialogOverlay(description)
    
    print(string.format("[UI_StoryScene] ✓ 场景描述已显示: %s", description:sub(1, 50) .. "..."))
end

---显示故事介绍（在故事开始时显示所有设定）
function M:ShowStoryIntroduction()
    print("[UI_StoryScene] 显示故事介绍...")
    
    -- 获取 BM_StoryConfig
    local BM_StoryConfig = GameContext:GetBusinessModule("BM_StoryConfig")
    
    if not BM_StoryConfig then
        print("[UI_StoryScene] ❌ 错误：无法获取 BM_StoryConfig")
        return
    end
    
    -- 获取格式化的展示内容
    local displayContent = BM_StoryConfig:GetDisplayContent()
    
    if not displayContent then
        print("[UI_StoryScene] ⚠️ 警告：无法获取故事展示内容，可能配置未加载")
        return
    end
    
    -- 显示覆盖层并设置故事介绍
    self:ShowDialogOverlay(displayContent)
    
    print("[UI_StoryScene] ✅ 故事介绍已显示（包含背景、角色、场景、线索等所有设定）")
end

---显示角色介绍（在选择角色后显示）
function M:ShowCharacterIntroduction()
    print("[UI_StoryScene] 显示角色介绍...")
    
    if not self.selectedCharacter then
        print("[UI_StoryScene] ⚠️ 警告：未选择角色")
        return
    end
    
    -- 获取角色信息
    local characterInfo = self:GetCharacterInfo(self.selectedCharacter)
    
    if not characterInfo then
        print("[UI_StoryScene] ❌ 错误：无法获取角色信息")
        return
    end
    
    -- 构建角色介绍文本
    local introduction = string.format("【%s - %s】\n\n%s\n\n%s", 
        characterInfo.name or self.selectedCharacter,
        characterInfo.title or "未知",
        characterInfo.appearance or "",
        characterInfo.firstImpression or ""
    )
    
    -- 🔥 使用角色信息覆盖层显示介绍（而非对话覆盖层）
    self:ShowCharacterInfoOverlay(introduction)
    
    print(string.format("[UI_StoryScene] ✓ 角色介绍已显示在 Overlay_CharacterInfo 中: %s", characterInfo.name or self.selectedCharacter))
end

---获取角色信息
---@param characterName string 角色名字
---@return table|nil characterInfo 角色信息
function M:GetCharacterInfo(characterName)
    if not characterName then
        return nil
    end
    
    -- 获取故事配置路径
    local storyLibraryId = M.StoryIdMap[self.storyId]
    if not storyLibraryId then
        print(string.format("[UI_StoryScene] ❌ 错误：未找到故事映射 %s", self.storyId))
        return nil
    end
    
    local configPath = M.StoryConfigMap[storyLibraryId]
    if not configPath then
        print(string.format("[UI_StoryScene] ❌ 错误：未找到配置路径 %s", storyLibraryId))
        return nil
    end
    
    -- 加载故事配置
    local success, storyConfig = pcall(require, configPath)
    if not success then
        print(string.format("[UI_StoryScene] ❌ 错误：无法加载配置文件 %s", configPath))
        return nil
    end
    
    -- 如果配置是函数，调用它获取配置数据
    if type(storyConfig) == "function" then
        storyConfig = storyConfig()
    end
    
    -- 从配置中获取角色信息
    if not storyConfig.display or not storyConfig.display.characters then
        print("[UI_StoryScene] ❌ 错误：配置中未找到 display.characters")
        return nil
    end
    
    -- 查找角色
    for _, character in ipairs(storyConfig.display.characters) do
        if character.name == characterName then
            return character
        end
    end
    
    print(string.format("[UI_StoryScene] ⚠️ 警告：未找到角色配置: %s", characterName))
    return nil
end

---获取当前场景的完整信息
---@return table|nil sceneInfo 场景信息
function M:GetCurrentSceneInfo()
    if not self.selectedScene then
        return nil
    end
    
    -- 获取故事配置路径
    local storyLibraryId = M.StoryIdMap[self.storyId]
    if not storyLibraryId then
        print(string.format("[UI_StoryScene] ❌ 错误：未找到故事映射 %s", self.storyId))
        return nil
    end
    
    local configPath = M.StoryConfigMap[storyLibraryId]
    if not configPath then
        print(string.format("[UI_StoryScene] ❌ 错误：未找到配置路径 %s", storyLibraryId))
        return nil
    end
    
    -- 加载故事配置
    local success, storyConfig = pcall(require, configPath)
    if not success then
        print(string.format("[UI_StoryScene] ❌ 错误：无法加载配置文件 %s", configPath))
        return nil
    end
    
    -- 如果配置是函数，调用它获取配置数据
    if type(storyConfig) == "function" then
        storyConfig = storyConfig()
    end
    
    -- 从配置中获取场景信息
    if not storyConfig.display or not storyConfig.display.locations then
        print("[UI_StoryScene] ❌ 错误：配置中未找到 display.locations")
        return nil
    end
    
    -- 查找当前场景的配置
    for _, location in ipairs(storyConfig.display.locations) do
        if location.name == self.selectedScene then
            return location
        end
    end
    
    print(string.format("[UI_StoryScene] ❌ 错误：未找到场景配置: %s", self.selectedScene))
    return nil
end

---清空关键抉择按钮列表
function M:ClearSceneChoices()
    if not self.VerticalBox_SceneChoices then
        return
    end
    
    print("[UI_StoryScene] 清空关键抉择按钮")
    self.VerticalBox_SceneChoices:ClearChildren()
end

---加载场景关键抉择按钮
---@param choices table 抉择列表 {text: string, id: string}
function M:LoadSceneChoices(choices)
    if not choices or #choices == 0 then
        print("[UI_StoryScene] 当前场景无关键抉择")
        return
    end
    
    print(string.format("[UI_StoryScene] 开始加载 %d 个关键抉择...", #choices))
    
    -- 清空现有抉择
    self:ClearSceneChoices()
    
    -- 获取 PlayerController
    local GameContext = require("Core.GameContext")
    local playerController = GameContext:getPlayerController()
    
    if not playerController then
        print("[UI_StoryScene] ❌ 错误：无法获取 PlayerController")
        return
    end
    
    -- 加载 CW_NormalButton 蓝图类
    local buttonPath = "/Game/UI/CommonWidgets/Buttons/CW_NormalButton.CW_NormalButton_C"
    local buttonClass = UE.UClass.Load(buttonPath)
    
    if not buttonClass then
        print(string.format("[UI_StoryScene] ❌ 错误：无法加载按钮类: %s", buttonPath))
        return
    end
    
    -- 为每个抉择创建按钮
    for index, choice in ipairs(choices) do
        local success, buttonWidget = pcall(function()
            return UE.UWidgetBlueprintLibrary.Create(self, buttonClass, playerController)
        end)
        
        if success and buttonWidget then
            -- 添加到 VerticalBox
            local slot = self.VerticalBox_SceneChoices:AddChild(buttonWidget)
            
            -- 设置Slot样式
            if slot then
                slot:SetPadding(UE.FMargin(5, 5, 5, 5))
                slot:SetHorizontalAlignment(UE.EHorizontalAlignment.HAlign_Fill)
                slot:SetVerticalAlignment(UE.EVerticalAlignment.VAlign_Top)
            end
            
            -- 设置按钮文本
            if buttonWidget.Text_Button then
                buttonWidget.Text_Button:SetText(choice.text)
                print(string.format("  [%d] ✓ 已创建抉择按钮: %s", index, choice.text))
            end
            
            -- 绑定点击事件
            self:BindChoiceButtonClick(buttonWidget, choice)
        else
            print(string.format("  [%d] ❌ 创建抉择按钮失败", index))
        end
    end
    
    print(string.format("[UI_StoryScene] ✅ 关键抉择加载完成，共 %d 个", #choices))
end

---🔥 刷新场景抉择（当AI调用unlock_choice工具后）
---这个方法会被 GameStoryTools.unlock_choice 工具回调
function M:RefreshSceneDecisionOnly()
    print("\n" .. string.rep("=", 70))
    print("[UI_StoryScene] 🔄 RefreshSceneDecisionOnly 被调用")
    print(string.rep("=", 70))
    
    local BM_StoryConfig = require("DataLayer.Story.BM_StoryConfig")
    local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
    
    -- 获取当前场景ID
    local currentSceneId = BM_StoryRuntime:GetCurrentSceneId()
    print(string.format("[UI_StoryScene] 当前场景ID: %s", currentSceneId or "nil"))
    
    if not currentSceneId or currentSceneId == "" then
        print("[UI_StoryScene] ❌ 当前场景ID为空，无法刷新")
        print(string.rep("=", 70) .. "\n")
        return
    end
    
    -- 获取场景配置
    local sceneConfig = BM_StoryConfig:GetScene(currentSceneId)
    if not sceneConfig then
        print(string.format("[UI_StoryScene] ❌ 找不到场景配置: %s", currentSceneId))
        print(string.rep("=", 70) .. "\n")
        return
    end
    
    print(string.format("[UI_StoryScene] ✅ 找到场景配置: %s", sceneConfig.name or currentSceneId))
    
    -- 获取动态生成的抉择（AI解锁的）
    local dynamicChoices = BM_StoryRuntime:GetDynamicChoices(currentSceneId)
    print(string.format("[UI_StoryScene] 当前场景动态抉择数量: %d", #dynamicChoices))
    
    -- 清空现有抉择按钮
    self:ClearSceneChoices()
    
    if #dynamicChoices == 0 then
        print("[UI_StoryScene] ⚠️ 没有动态抉择需要显示")
        print(string.rep("=", 70) .. "\n")
        return
    end
    
    -- 重新加载抉择（转换为旧格式）
    local choicesForDisplay = {}
    for _, choice in ipairs(dynamicChoices) do
        table.insert(choicesForDisplay, {
            text = choice.name,
            id = choice.id,
            description = choice.description
        })
    end
    
    -- 调用 LoadSceneChoices 重新加载
    self:LoadSceneChoices(choicesForDisplay)
    
    print(string.format("[UI_StoryScene] ✅ 场景抉择已刷新，显示 %d 个动态抉择", #choicesForDisplay))
    print(string.rep("=", 70) .. "\n")
end

---绑定抉择按钮点击事件
---@param buttonWidget userdata 按钮Widget实例
---@param choice table 抉择数据
function M:BindChoiceButtonClick(buttonWidget, choice)
    if not buttonWidget or not buttonWidget.Button_Main then
        return
    end
    
    if buttonWidget.Button_Main.OnClicked then
        buttonWidget.Button_Main.OnClicked:Add(self, function()
            self:OnChoiceButtonClicked(choice)
        end)
        print(string.format("  └─ ✓ 已绑定抉择点击事件: %s", choice.text))
    end
end

---处理抉择按钮点击事件
---@param choice table 抉择数据 {text, id, description}
function M:OnChoiceButtonClicked(choice)
    print(string.format("\n[UI_StoryScene] ========== 点击关键抉择: %s ==========", choice.text))
    
    -- 防止重复点击（AI正在回复时）
    if self.isAIReplying then
        print("[UI_StoryScene] ⚠️ AI正在回复中，请稍候...")
        return
    end
    
    -- 检查 LLM 管理器是否可用
    if not self.llmMgr then
        print("[UI_StoryScene] ❌ 错误：LLM管理器未初始化")
        self:ShowDialogOverlay("❌ 错误：LLM管理器未初始化")
        return
    end
    
    -- 使用 SceneStateManager 执行抉择（如果有ID）
    if choice.id then
        local SceneStateManager = require("GameLayer.Story.SceneStateManager")
        local result = SceneStateManager.ExecuteChoice(choice.id)
        
        if not result.success then
            print(string.format("[UI_StoryScene] ❌ 执行抉择失败: %s", result.error or "未知错误"))
            self:ShowDialogOverlay("无法执行该抉择")
            print(string.rep("=", 70) .. "\n")
            return
        end
        
        print(string.format("[UI_StoryScene] ✅ 抉择执行成功，准备调用AI生成后续叙事"))
    end
    
    -- 🔥 点击抉择后，立即清空该抉择（暂存抉择）
    if choice.id then
        local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
        local currentSceneId = BM_StoryRuntime:GetCurrentSceneId()
        
        if currentSceneId and currentSceneId ~= "" then
            print(string.format("\n[UI_StoryScene] ========== 立即删除已使用的抉择 =========="))
            print(string.format("[UI_StoryScene] 场景ID: %s", currentSceneId))
            print(string.format("[UI_StoryScene] 抉择ID: %s", choice.id))
            print(string.format("[UI_StoryScene] 抉择名称: %s", choice.text))
            
            -- 从数据层删除动态抉择
            local removeResult = BM_StoryRuntime:RemoveDynamicChoice(currentSceneId, choice.id)
            
            if removeResult and removeResult.success then
                print(string.format("[UI_StoryScene] ✅ 已从数据层删除抉择: %s", choice.text))
                
                -- 立即刷新UI，移除该抉择按钮
                self:RefreshSceneDecisionOnly()
                print("[UI_StoryScene] ✅ UI已刷新，抉择按钮已移除")
            else
                print(string.format("[UI_StoryScene] ⚠️ 删除抉择失败: %s", 
                    removeResult and removeResult.error or "未知错误"))
            end
            
            print(string.rep("=", 70) .. "\n")
        end
    end
    
    -- 显示对话覆盖层，先显示玩家的抉择
    self:ShowDialogOverlay(string.format("【我的抉择】%s\n\n正在演绎中...", choice.text))
    
    -- 🔥 调用AI生成抉择后的叙事（参考 UI_Dialog1）
    self:GenerateChoiceNarrative(choice)
    
    print(string.rep("=", 70) .. "\n")
end

---🔥 生成抉择叙事（调用AI）
---@param choice table 抉择数据 {text, id, description}
function M:GenerateChoiceNarrative(choice)
    print("[UI_StoryScene] 开始生成抉择叙事...")
    
    -- 构建 TypeOptions（抉择的上下文信息）
    local typeOptions = self:BuildSceneChoiceTypeOptions(
        choice.text,
        choice.description or choice.text
    )
    
    -- 重置AI回复状态
    self.currentAIText = ""
    self.isAIReplying = true
    
    -- 🔥 禁用输入框和发送按钮（防止AI回复时被打断）
    if self.EditText_Input then
        self.EditText_Input:SetIsEnabled(false)
    end
    if self.Button_Submmit then
        self.Button_Submmit:SetIsEnabled(false)
    end
    
    -- 调用AI（使用SCENE_CHOICE类型）
    self.llmMgr:Chat(
        Consts.ChatType.SCENE_CHOICE,  -- ChatType
        typeOptions,                   -- TypeOptions：包含所有上下文信息
        {
            userInput = "",  -- SCENE_CHOICE 不需要用户输入
        },
        function(delta)  -- onStream: 流式回调
            -- 流式追加文本到覆盖层
            if delta and delta ~= "" then
                self.currentAIText = self.currentAIText .. delta
                
                -- 实时更新Text_dialog
                if self.Text_dialog then
                    local displayText = string.format("【我的抉择】%s\n\n%s", 
                        choice.text, 
                        self.currentAIText)
                    self.Text_dialog:SetText(displayText)
                end
            end
        end,
        function(success, result)  -- onComplete: 完成回调
            -- 🔥 传递完整的 choice 对象，而不只是 choice.text
            self:OnChoiceNarrativeComplete(success, result, choice)
        end
    )
    
    print("[UI_StoryScene] 已发送抉择叙事请求到AI")
end

---抉择叙事生成完成回调
---@param success boolean 是否成功
---@param result string 完整文本或错误信息
---@param choice table 抉择数据 {text, id, description}
function M:OnChoiceNarrativeComplete(success, result, choice)
    self.isAIReplying = false  -- 解除回复锁定
    
    -- 🔥 重新启用输入框和发送按钮
    if self.EditText_Input then
        self.EditText_Input:SetIsEnabled(true)
    end
    if self.Button_Submmit then
        self.Button_Submmit:SetIsEnabled(true)
    end
    
    local choiceName = choice.text or "未知抉择"
    local choiceId = choice.id
    
    print(string.format("[UI_StoryScene] 抉择叙事生成完成，成功: %s", tostring(success)))
    
    if not success then
        -- 失败：显示错误信息
        print(string.format("[UI_StoryScene] ❌ AI回复失败: %s", result))
        local errorMsg = string.format("【我的抉择】%s\n\n❌ 错误：%s", choiceName, result)
        if self.Text_dialog then
            self.Text_dialog:SetText(errorMsg)
        end
    else
        -- 成功：确保显示完整文本
        print(string.format("[UI_StoryScene] ✅ AI叙事生成完成，总计 %d 个字符", #result))
        
        -- 🔥 兜底机制：如果AI没有输出任何文字，显示默认消息
        local displayResult = result
        if not result or result == "" or result:match("^%s*$") then
            print("[UI_StoryScene] ⚠️ 警告：AI没有输出叙事文字，使用默认消息")
            displayResult = "（抉择的后果正在发生...）"
        end
        
        if self.Text_dialog then
            local finalText = string.format("【我的抉择】%s\n\n%s", choiceName, displayResult)
            self.Text_dialog:SetText(finalText)
        end
        
        -- 保存叙事到循环记忆（如果需要）
        local BM_LlmContext = require("DataLayer.Llm.BM_LlmContext")
        local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
        
        if result and result ~= "" then
            BM_LlmContext:AddLoopMemory({
                type = "choice_result",
                choiceName = choiceName,
                content = result,
                loopCount = BM_StoryRuntime:GetLoopCount()
            })
            print("[UI_StoryScene] 已保存抉择叙事到循环记忆")
        end
        
        -- 注意：抉择已经在点击时被删除了（OnChoiceButtonClicked中），这里不需要重复删除
    end
    
    -- 🔥🔥🔥 【关键】检查游戏状态，执行对应操作
    self:CheckAndHandleGameState()
    
    -- 清理
    self.currentAIText = ""
end

---检查并处理游戏状态（抉择叙事完成后）
function M:CheckAndHandleGameState()
    print("\n" .. string.rep("=", 70))
    print("[UI_StoryScene] ========== 检查游戏状态 ==========")
    print(string.rep("=", 70))
    
    local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
    
    -- 1. 检查游戏是否结束（优先级最高）
    if BM_StoryRuntime:IsGameEnded() then
        print("[UI_StoryScene] ✅ 检测到游戏结束标记")
        local endingType = BM_StoryRuntime:GetEndingType()
        local endingReason = BM_StoryRuntime:GetEndingReason()
        
        print(string.format("[UI_StoryScene]    结局类型: %s", endingType or "未知"))
        print(string.format("[UI_StoryScene]    结束原因: %s", endingReason or "未知"))
        
        -- 延迟5秒后退回到 UI_Home（给玩家时间阅读结局）
        self:AddTimer(5.0, function()
            print("[UI_StoryScene] ⏱️ 定时器触发：游戏结束，返回主菜单")
            self:BackToMainMenu()
        end, false)
        
        print("[UI_StoryScene] ⏱️ 已设置5秒后返回主菜单")
        print(string.rep("=", 70) .. "\n")
        return
    end
    
    -- 2. 检查是否应该开启新循环
    if BM_StoryRuntime:GetShouldStartNewLoop() then
        print("[UI_StoryScene] ✅ 检测到新循环标记")
        local loopCount = BM_StoryRuntime:GetLoopCount()
        print(string.format("[UI_StoryScene]    当前循环次数: %d", loopCount))
        
        -- 清除标记
        BM_StoryRuntime:SetShouldStartNewLoop(false)
        
        -- 更新地图Widget的循环次数显示
        self:UpdateMapLoopCountDisplay(loopCount)
        
        -- 延迟3秒后返回地图
        self:AddTimer(3.0, function()
            print("[UI_StoryScene] ⏱️ 定时器触发：开启新循环，返回地图")
            self:BackToMap()
        end, false)
        
        print("[UI_StoryScene] ⏱️ 已设置3秒后返回地图")
        print(string.rep("=", 70) .. "\n")
        return
    end
    
    -- 3. 默认：继续当前循环
    print("[UI_StoryScene] ✅ 继续当前循环（AI调用了 continue_cur_loop 或无状态变化）")
    
    -- 延迟3秒自动隐藏对话覆盖层（让玩家有时间阅读）
    if self.dialogOverlayTimer then
        self:StopTimer(self.dialogOverlayTimer)
    end
    
    self.dialogOverlayTimer = self:AddTimer(3.0, function()
        print("[UI_StoryScene] ⏱️ 定时器触发：自动隐藏对话覆盖层")
        self:HideDialogOverlay()
        self.dialogOverlayTimer = nil
    end, false)
    
    print("[UI_StoryScene] ⏱️ 已设置3秒后自动隐藏对话覆盖层（玩家可以继续对话）")
    print(string.rep("=", 70) .. "\n")
end

---更新地图Widget的循环次数显示
---@param loopCount number 当前循环次数
function M:UpdateMapLoopCountDisplay(loopCount)
    print(string.format("[UI_StoryScene] 更新地图Widget循环次数显示: 第 %d 次循环", loopCount))
    
    if not self.currentStoryMapWidget then
        print("[UI_StoryScene] ⚠️ 警告：currentStoryMapWidget 为空，无法更新")
        return
    end
    
    -- 检查 Text_Map 组件是否存在
    if not self.currentStoryMapWidget.Text_Map then
        print("[UI_StoryScene] ⚠️ 警告：currentStoryMapWidget 没有 Text_Map 组件")
        return
    end
    
    -- 获取原始的故事介绍文本
    local displayData = self:GetStoryDisplayData()
    
    if not displayData then
        print("[UI_StoryScene] ⚠️ 警告：无法获取故事配置数据")
        return
    end
    
    -- 构建带循环次数的文本
    local loopPrefix = string.format("【第 %d 次循环】\n\n", loopCount)
    local fullText = loopPrefix .. self:BuildStoryInfoText(displayData)
    
    -- 更新 Text_Map
    self.currentStoryMapWidget.Text_Map:SetText(fullText)
    print(string.format("[UI_StoryScene] ✅ 已更新地图Widget循环次数显示: 第 %d 次循环", loopCount))
end

---构建SCENE_CHOICE的完整TypeOptions参数（参考 UI_Dialog1）
---@param choiceName string 抉择名称
---@param choiceDescription string 抉择描述
---@return table TypeOptions参数
function M:BuildSceneChoiceTypeOptions(choiceName, choiceDescription)
    local BM_StoryConfig = require("DataLayer.Story.BM_StoryConfig")
    local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
    local LlmPromptConfig = require("Config.LlmPromptConfig")
    
    -- 获取当前场景信息
    local currentSceneId = BM_StoryRuntime:GetCurrentSceneId()
    local sceneInfo = BM_StoryConfig:GetScene(currentSceneId)
    
    -- 获取故事配置
    local storyConfig = self:GetCurrentStoryConfig()
    
    -- 获取循环次数
    local loopCount = BM_StoryRuntime:GetLoopCount()
    
    -- 🎮 根据循环次数获取动态策略
    local loopStrategy = LlmPromptConfig.GetLoopStrategy(loopCount)
    
    -- 构建参数
    local typeOptions = {
        -- 基础信息
        choiceName = choiceName,
        choiceDescription = choiceDescription or choiceName,
        loopCount = loopCount,
        
        -- 场景详情
        currentSceneName = sceneInfo and sceneInfo.name or currentSceneId or "未知场景",
        sceneDescription = sceneInfo and sceneInfo.description or "未知场景",
        sceneAtmosphere = sceneInfo and sceneInfo.atmosphere or "平静",
        
        -- 游戏背景
        gameBackground = storyConfig and storyConfig.background and storyConfig.background.text or "未设置游戏背景",
        
        -- 循环历史（简化）
        loopHistory = self:GetLoopHistorySummary(),
        
        -- 🎮 循环策略（根据循环次数动态调整）
        loopStrategy = loopStrategy,
        
        -- 场景NPC
        sceneNPCs = self:GetSceneNPCsSummary(currentSceneId),
        
        -- 玩家状态
        playerState = "玩家状态正常"
    }
    
    return typeOptions
end

---获取循环历史摘要
---@return string 循环历史文本
function M:GetLoopHistorySummary()
    local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
    local loopCount = BM_StoryRuntime:GetLoopCount()
    
    if loopCount == 1 then
        return "这是第一次循环，尚无历史记录"
    end
    
    -- 获取当前循环的选择历史
    local currentChoices = BM_StoryRuntime:GetCurrentLoopChoices()
    if #currentChoices == 0 then
        return "本次循环刚开始，尚未做出关键抉择"
    end
    
    local parts = {}
    for i, choice in ipairs(currentChoices) do
        table.insert(parts, string.format("%d. %s", i, choice.choiceId))
    end
    
    return "本次循环已做出的抉择：\n" .. table.concat(parts, "\n")
end

---获取场景NPC摘要
---@param sceneId string 场景ID
---@return string NPC摘要文本
function M:GetSceneNPCsSummary(sceneId)
    local BM_StoryConfig = require("DataLayer.Story.BM_StoryConfig")
    local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
    
    if not sceneId then
        return "场景中没有特定的关键角色"
    end
    
    -- 获取场景配置
    local sceneConfig = BM_StoryConfig:GetScene(sceneId)
    if not sceneConfig or not sceneConfig.npcIds or #sceneConfig.npcIds == 0 then
        return "场景中没有特定的关键角色"
    end
    
    local parts = {}
    for _, npcId in ipairs(sceneConfig.npcIds) do
        local npcInfo = BM_StoryConfig:GetNPC(npcId)
        local npcState = BM_StoryRuntime:GetNPCState(npcId)
        
        if npcInfo then
            local stateInfo = ""
            if npcState then
                stateInfo = string.format("（信任%d/情绪%d/关系%d）", 
                    npcState.trust or 0, 
                    npcState.emotion or 0, 
                    npcState.relation or 0)
            end
            
            table.insert(parts, string.format("- **%s**（%s）%s：%s", 
                npcInfo.name, 
                npcInfo.role or "未知", 
                stateInfo,
                npcInfo.personality or "性格未知"))
        end
    end
    
    return table.concat(parts, "\n")
end

---获取当前故事配置
---@return table|nil 故事配置
function M:GetCurrentStoryConfig()
    if not self.currentStoryId then
        return nil
    end
    
    local configPath = M.StoryConfigMap[self.currentStoryId]
    if not configPath then
        return nil
    end
    
    local success, storyConfig = pcall(require, configPath)
    if not success then
        return nil
    end
    
    if type(storyConfig) == "function" then
        storyConfig = storyConfig()
    end
    
    return storyConfig
end

---显示对话覆盖层（用于显示 NPC 消息和抉择叙事）
---@param dialogText string 对话文本
function M:ShowDialogOverlay(dialogText)
    if not self.Overlay_Tint then
        print("[UI_StoryScene] ⚠️ 警告：Overlay_Tint 不存在")
        return
    end
    
    -- 显示覆盖层
    self.Overlay_Tint:SetVisibility(UE.ESlateVisibility.Visible)
    
    -- 设置对话文本
    if self.Text_dialog then
        self.Text_dialog:SetText(dialogText)
        print(string.format("[UI_StoryScene] ✓ 显示对话覆盖层: %s", dialogText:sub(1, 50) .. "..."))
    end
end

---隐藏对话覆盖层
function M:HideDialogOverlay()
    if not self.Overlay_Tint then
        return
    end
    
    self.Overlay_Tint:SetVisibility(UE.ESlateVisibility.Collapsed)
    print("[UI_StoryScene] ✓ 隐藏对话覆盖层")
end

---显示角色信息覆盖层（用于显示角色介绍）
---@param characterInfoText string 角色信息文本
function M:ShowCharacterInfoOverlay(characterInfoText)
    if not self.Overlay_CharacterInfo then
        print("[UI_StoryScene] ⚠️ 警告：Overlay_CharacterInfo 不存在")
        print("[UI_StoryScene] 💡 请在 UE 蓝图中添加名为 Overlay_CharacterInfo 的覆盖层组件")
        return
    end
    
    -- 显示角色信息覆盖层
    self.Overlay_CharacterInfo:SetVisibility(UE.ESlateVisibility.Visible)
    
    -- 设置角色信息文本
    if self.Text_CharacterInfo then
        self.Text_CharacterInfo:SetText(characterInfoText)
        print(string.format("[UI_StoryScene] ✓ 显示角色信息覆盖层"))
    else
        print("[UI_StoryScene] ⚠️ 警告：Text_CharacterInfo 不存在，无法显示角色信息")
    end
end

---隐藏角色信息覆盖层
function M:HideCharacterInfoOverlay()
    if not self.Overlay_CharacterInfo then
        return
    end
    
    self.Overlay_CharacterInfo:SetVisibility(UE.ESlateVisibility.Collapsed)
    print("[UI_StoryScene] ✓ 隐藏角色信息覆盖层")
end

---显示输入框
function M:ShowInputBox()
    if not self.InputBox then
        print("[UI_StoryScene] ⚠️ 警告：InputBox 不存在")
        return
    end
    
    self.InputBox:SetVisibility(UE.ESlateVisibility.Visible)
    print("[UI_StoryScene] ✓ 显示输入框")
end

---隐藏输入框
function M:HideInputBox()
    if not self.InputBox then
        return
    end
    
    self.InputBox:SetVisibility(UE.ESlateVisibility.Collapsed)
    print("[UI_StoryScene] ✓ 隐藏输入框")
end

---绑定输入框事件（可选：如果需要支持回车提交）
function M:BindInputBoxEvents()
    -- 注意：EditText 通常没有 OnTextCommitted 事件
    -- 主要通过 Button_Submit 来提交
    -- 如果你的 EditText_Input 支持 OnTextCommitted，可以在这里绑定
    
    if not self.EditText_Input then
        print("[UI_StoryScene] ⚠️ 警告：EditText_Input 不存在")
        return
    end
    
    -- 尝试绑定回车提交事件（如果支持）
    if self.EditText_Input.OnTextCommitted then
        self.EditText_Input.OnTextCommitted:Add(self, function(text, commitMethod)
            print(string.format("[UI_StoryScene] ========== OnTextCommitted 事件触发 =========="))
            print(string.format("[UI_StoryScene] commitMethod: %s (0=Enter, 1=失去焦点)", tostring(commitMethod)))
            
            -- 🔥 关键：不要从事件参数中提取文本，直接从输入框获取！
            local textStr = ""
            
            local success, result = pcall(function()
                return self.EditText_Input:GetText()
            end)
            
            if success and result then
                if type(result) == "string" then
                    textStr = result
                elseif type(result) == "userdata" and result.ToString then
                    textStr = result:ToString()
                else
                    print(string.format("[UI_StoryScene] ⚠️ GetText() 返回未知类型: %s", type(result)))
                    return
                end
            else
                print(string.format("[UI_StoryScene] ❌ GetText() 调用失败: %s", tostring(result)))
                return
            end
            
            print(string.format("[UI_StoryScene] 获取到文本: [%s]", textStr))
            
            -- 检查文本是否为空
            if not textStr or textStr == "" then
                print("[UI_StoryScene] ⚠️ 文本为空，忽略")
                return
            end
            
            -- 🔥 立即处理，不管commitMethod是什么（用户按Enter就应该发送）
            print(string.format("[UI_StoryScene] 准备调用 OnInputSubmitted..."))
            self:OnInputSubmitted(textStr, commitMethod)
        end)
        print("[UI_StoryScene] ✓ 已绑定 EditText_Input 回车提交事件")
    else
        print("[UI_StoryScene] ℹ️ EditText_Input 不支持回车提交，请使用 Button_Submit")
    end
    
    -- 🔥 额外尝试：监听 OnKeyDown 事件，直接捕获 Enter 键
    if self.EditText_Input.OnKeyDownEvent then
        self.EditText_Input.OnKeyDownEvent:Bind(self, function(myGeometry, inKeyEvent)
            local key = inKeyEvent:GetKey()
            local keyName = key.KeyName:ToString()
            
            print(string.format("[UI_StoryScene] OnKeyDown: %s", keyName))
            
            -- 检查是否按下 Enter 键
            if keyName == "Enter" then
                print("[UI_StoryScene] 检测到 Enter 键，立即提交！")
                
                -- 立即获取文本并提交
                local textStr = ""
                local success, result = pcall(function()
                    return self.EditText_Input:GetText()
                end)
                
                if success and result then
                    if type(result) == "string" then
                        textStr = result
                    elseif type(result) == "userdata" and result.ToString then
                        textStr = result:ToString()
                    end
                end
                
                if textStr and textStr ~= "" then
                    self:OnInputSubmitted(textStr, 0)  -- commitMethod=0 表示 Enter
                    
                    -- 返回 UE.UWidgetBlueprintLibrary:Handled() 阻止事件继续传播
                    return UE.UWidgetBlueprintLibrary:Handled()
                end
            end
            
            -- 不处理其他键，继续传播
            return UE.UWidgetBlueprintLibrary:Unhandled()
        end)
        print("[UI_StoryScene] ✓ 已绑定 EditText_Input OnKeyDown 事件")
    end
end

---处理用户输入提交
---@param text string 用户输入的文本
---@param commitMethod number 提交方式（Enter键等）
function M:OnInputSubmitted(text, commitMethod)
    print(string.format("\n[UI_StoryScene] ========== 用户输入提交 =========="))
    print(string.format("[UI_StoryScene] 输入文本: %s", text))
    print(string.format("[UI_StoryScene] 提交方式: %s", tostring(commitMethod)))
    
    -- 🔥 用户发送新消息时，立即隐藏对话覆盖层（如果有）
    if self.Overlay_Tint and self.Overlay_Tint:GetVisibility() == UE.ESlateVisibility.Visible then
        print("[UI_StoryScene] 🔄 用户发送新消息，立即隐藏对话覆盖层")
        self:HideDialogOverlay()
        
        -- 取消延迟隐藏定时器（如果有）
        if self.dialogOverlayTimer then
            self:StopTimer(self.dialogOverlayTimer)
            self.dialogOverlayTimer = nil
        end
    end
    
    -- 检查文本是否为空
    if not text or text == "" then
        print("[UI_StoryScene] ⚠️ 输入为空，忽略")
        return
    end
    
    -- 防止重复发送（AI正在回复时）
    if self.isAIReplying then
        print("[UI_StoryScene] ⚠️ AI正在回复中，请稍候...")
        return
    end
    
    -- 检查是否选择了角色
    if not self.selectedCharacter then
        print("[UI_StoryScene] ⚠️ 警告：未选择角色")
        return
    end
    
    -- 清空输入框（使用 EditText_Input）
    if self.EditText_Input then
        -- 尝试清空输入框（SetText 可能接受 string 或 FText）
        local success, err = pcall(function()
            self.EditText_Input:SetText("")
        end)
        
        if success then
            print("[UI_StoryScene] ✓ 已清空输入框")
        else
            -- 如果直接设置空字符串失败，尝试使用 FText
            local success2, err2 = pcall(function()
                self.EditText_Input:SetText(UE.FText.FromString(""))
            end)
            
            if success2 then
                print("[UI_StoryScene] ✓ 已清空输入框（使用 FText）")
            else
                print(string.format("[UI_StoryScene] ⚠️ 清空输入框失败: %s", tostring(err2)))
            end
        end
    end
    
    -- 调用真实的 LLM API 获取角色回复
    self:SendMessageToCharacter(text)
    
    print(string.rep("=", 70) .. "\n")
end

---处理提交按钮点击
function M:OnSubmitClicked()
    print("\n" .. string.rep("=", 70))
    print("[UI_StoryScene] ========== Button_Submit 被点击 ==========")
    print(string.rep("=", 70))
    
    -- 检查输入框
    if not self.EditText_Input then
        print("[UI_StoryScene] ❌ 错误：EditText_Input 不存在")
        print("[UI_StoryScene] 请在 UE 蓝图中添加名为 EditText_Input 的输入框组件")
        return
    end
    
    print("[UI_StoryScene] ✓ EditText_Input 存在")
    print(string.format("[UI_StoryScene] EditText_Input 类型: %s", type(self.EditText_Input)))
    
    -- 获取输入文本（安全方式）
    local inputText = ""
    
    -- 尝试获取文本并转字符串
    local success, result = pcall(function()
        local textObj = self.EditText_Input:GetText()
        local textType = type(textObj)
        print(string.format("[UI_StoryScene] GetText() 返回类型: %s", textType))
        
        if not textObj then
            print("[UI_StoryScene] ⚠️ GetText() 返回 nil")
            return ""
        end
        
        -- 根据类型处理
        if textType == "string" then
            -- 已经是字符串，直接返回
            return textObj
        elseif textType == "userdata" and textObj.ToString then
            -- FText userdata，调用 ToString()
            return textObj:ToString()
        elseif textType == "table" then
            -- Lua 包装的 FText table
            print("[UI_StoryScene] GetText() 返回 table，尝试提取文本...")
            
            if textObj.ToString then
                local text = textObj:ToString()
                print(string.format("[UI_StoryScene] ✓ 通过 ToString() 获取: %s", text))
                return text
            elseif textObj.__tostring then
                local text = tostring(textObj)
                print(string.format("[UI_StoryScene] ✓ 通过 tostring() 获取: %s", text))
                return text
            else
                print("[UI_StoryScene] ❌ table 没有 ToString 方法")
                print("[UI_StoryScene] table 内容:")
                for k, v in pairs(textObj) do
                    print(string.format("  %s = %s", tostring(k), tostring(v)))
                end
                return ""
            end
        else
            print(string.format("[UI_StoryScene] ⚠️ GetText() 返回了未知类型: %s", textType))
            return ""
        end
    end)
    
    if success then
        inputText = result or ""
        print(string.format("[UI_StoryScene] ✅ 从 EditText_Input 获取到文本: [%s]", inputText))
    else
        print(string.format("[UI_StoryScene] ❌ 获取文本失败: %s", tostring(result)))
        print(string.rep("=", 70) .. "\n")
        return
    end
    
    -- 调用输入提交处理
    print("[UI_StoryScene] 准备调用 OnInputSubmitted...")
    self:OnInputSubmitted(inputText, 0)
    
    print(string.rep("=", 70) .. "\n")
end

---发送消息给角色（调用 LLM API）
---@param userInput string 用户输入的文本
function M:SendMessageToCharacter(userInput)
    print(string.format("[UI_StoryScene] 发送消息给角色: %s", self.selectedCharacter))
    
    -- 检查 LLM 管理器是否可用
    if not self.llmMgr then
        print("[UI_StoryScene] ❌ 错误：LLM管理器未初始化")
        self:ShowDialogOverlay("❌ 错误：LLM管理器未初始化")
        return
    end
    
    -- 使用已保存的角色信息（从 SelectCharacter 中保存的）
    if not self.currentNpcInfo then
        print("[UI_StoryScene] ❌ 错误：未选择角色或角色信息丢失")
        self:ShowDialogOverlay("❌ 错误：未选择角色")
        return
    end
    
    -- 获取场景信息（用于上下文）
    local sceneInfo = self:GetCurrentSceneInfo()
    
    -- 构建 typeArgs（CHARACTER_DIALOGUE 专属参数）
    -- 使用 currentNpcInfo 中的信息
    local typeArgs = {
        characterName = self.currentNpcInfo.name,
        personality = self.currentNpcInfo.personality,
        motivation = self.currentNpcInfo.motivation,
        dialogueStyle = self.currentNpcInfo.dialogueStyle,
        currentIntention = self.currentNpcInfo.currentIntention or "观察主角，根据对话内容做出自然反应",
        background = self.currentNpcInfo.background or "背景信息未知"
    }
    
    -- 构建 normalArgs（通用参数）
    local normalArgs = {
        userInput = userInput
    }
    
    -- 添加场景上下文
    if sceneInfo then
        normalArgs.unlockConditions = string.format(
            "当前场景：%s\n场景描述：%s",
            sceneInfo.name or "未知场景",
            sceneInfo.description or "暂无描述"
        )
    end
    
    print(string.format("[UI_StoryScene] 使用角色对话模式: %s", self.currentNpcInfo.name))
    print(string.format("[UI_StoryScene] 角色信息:"))
    print(string.format("  - personality: %s", typeArgs.personality))
    print(string.format("  - motivation: %s", typeArgs.motivation))
    print(string.format("  - dialogueStyle: %s", typeArgs.dialogueStyle:sub(1, 50) .. "..."))
    print(string.format("  - currentIntention: %s", typeArgs.currentIntention or "未设置"))
    print(string.format("  - background: %s", (typeArgs.background or "未设置"):sub(1, 50) .. "..."))
    
    -- 标记AI正在回复
    self.currentAIText = ""
    self.isAIReplying = true
    
    -- 🔥 禁用输入框和发送按钮（防止AI回复时被打断）
    if self.EditText_Input then
        self.EditText_Input:SetIsEnabled(false)
    end
    if self.Button_Submmit then
        self.Button_Submmit:SetIsEnabled(false)
    end
    
    -- 发送到 LLM
    self.llmMgr:Chat(Consts.ChatType.CHARACTER_DIALOGUE, typeArgs, normalArgs, function(delta)
        -- 流式回调：每收到一段文字就调用
        self:OnAITextStream(delta)
    end, function(success, result)
        -- 完成回调：AI回复完成
        self:OnAIReplyComplete(success, result)
    end)
    
    print(string.format("[UI_StoryScene] 已发送请求到AI，等待回复..."))
end

---AI 流式文本回调
---@param delta string 新收到的文本片段
function M:OnAITextStream(delta)
    -- 累积文本
    self.currentAIText = self.currentAIText .. delta
    
    -- 实时更新对话覆盖层
    self:ShowDialogOverlay(self.currentAIText)
end

---AI 回复完成回调
---@param success boolean 是否成功
---@param result string 完整文本（成功）或错误信息（失败）
function M:OnAIReplyComplete(success, result)
    self.isAIReplying = false  -- 解除回复锁定
    
    -- 🔥 重新启用输入框和发送按钮
    if self.EditText_Input then
        self.EditText_Input:SetIsEnabled(true)
    end
    if self.Button_Submmit then
        self.Button_Submmit:SetIsEnabled(true)
    end
    
    if not success then
        -- 失败：显示错误信息
        print("[UI_StoryScene] ❌ AI回复失败:", result)
        local errorMsg = "❌ 错误：" .. result
        self:ShowDialogOverlay(errorMsg)
    else
        -- 成功：确保显示完整文本
        print("[UI_StoryScene] ✅ AI回复完成，总计 " .. #result .. " 个字符")
        self:ShowDialogOverlay(result)
    end
    
    -- 清理
    self.currentAIText = ""
end

-- ==================== 角色按钮管理 ====================

---清空角色按钮列表
function M:ClearCharacterButtons()
    if not self.HorizontalBox_Character then
        return
    end
    
    print("[UI_StoryScene] 清空角色按钮")
    self.HorizontalBox_Character:ClearChildren()
end

---隐藏角色选择按钮容器
function M:HideCharacterButtons()
    if not self.HorizontalBox_Character then
        return
    end
    
    self.HorizontalBox_Character:SetVisibility(UE.ESlateVisibility.Collapsed)
    print("[UI_StoryScene] ✓ 隐藏角色选择按钮")
end

---显示角色选择按钮容器
function M:ShowCharacterButtons()
    if not self.HorizontalBox_Character then
        return
    end
    
    self.HorizontalBox_Character:SetVisibility(UE.ESlateVisibility.Visible)
    print("[UI_StoryScene] ✓ 显示角色选择按钮")
end

---获取当前场景的角色列表
---@return table|nil characters 角色名字列表
function M:GetSceneCharacters()
    print("[UI_StoryScene] 获取当前场景的角色列表...")
    
    -- 检查是否有选中的场景
    if not self.selectedScene then
        print("[UI_StoryScene] ⚠️ 警告：未选择场景")
        return nil
    end
    
    -- 获取故事配置路径
    local storyLibraryId = M.StoryIdMap[self.storyId]
    if not storyLibraryId then
        print(string.format("[UI_StoryScene] ❌ 错误：未找到故事映射 %s", self.storyId))
        return nil
    end
    
    local configPath = M.StoryConfigMap[storyLibraryId]
    if not configPath then
        print(string.format("[UI_StoryScene] ❌ 错误：未找到配置路径 %s", storyLibraryId))
        return nil
    end
    
    -- 加载故事配置
    local success, storyConfig = pcall(require, configPath)
    if not success then
        print(string.format("[UI_StoryScene] ❌ 错误：无法加载配置文件 %s", configPath))
        return nil
    end
    
    -- 如果配置是函数，调用它获取配置数据
    if type(storyConfig) == "function" then
        storyConfig = storyConfig()
    end
    
    -- 从配置中获取场景信息
    if not storyConfig.display or not storyConfig.display.locations then
        print("[UI_StoryScene] ❌ 错误：配置中未找到 display.locations")
        return nil
    end
    
    -- 查找当前场景的配置
    local sceneConfig = nil
    for _, location in ipairs(storyConfig.display.locations) do
        if location.name == self.selectedScene then
            sceneConfig = location
            break
        end
    end
    
    if not sceneConfig then
        print(string.format("[UI_StoryScene] ❌ 错误：未找到场景配置: %s", self.selectedScene))
        return nil
    end
    
    -- 获取场景中的角色列表
    if not sceneConfig.characters or #sceneConfig.characters == 0 then
        print(string.format("[UI_StoryScene] ⚠️ 场景 %s 中无角色", self.selectedScene))
        return nil
    end
    
    print(string.format("[UI_StoryScene] ✓ 找到 %d 个角色", #sceneConfig.characters))
    return sceneConfig.characters
end

---创建角色按钮
---@param characters table 角色名字列表
function M:CreateCharacterButtons(characters)
    if not characters or #characters == 0 then
        return
    end
    
    print(string.format("[UI_StoryScene] 开始创建 %d 个角色按钮...", #characters))
    
    -- 获取 PlayerController（创建Widget需要）
    local GameContext = require("Core.GameContext")
    local playerController = GameContext:getPlayerController()
    
    if not playerController then
        print("[UI_StoryScene] ❌ 错误：无法获取 PlayerController")
        return
    end
    
    -- 加载 CW_NormalButton 蓝图类
    local buttonPath = "/Game/UI/CommonWidgets/Buttons/CW_NormalButton.CW_NormalButton_C"
    local buttonClass = UE.UClass.Load(buttonPath)
    
    if not buttonClass then
        print(string.format("[UI_StoryScene] ❌ 错误：无法加载按钮类: %s", buttonPath))
        return
    end
    
    print("[UI_StoryScene] ✓ CW_NormalButton 类加载成功")
    
    -- 为每个角色创建按钮
    for index, characterName in ipairs(characters) do
        local success, buttonWidget = pcall(function()
            return UE.UWidgetBlueprintLibrary.Create(self, buttonClass, playerController)
        end)
        
        if success and buttonWidget then
            -- 添加到 HorizontalBox（触发 Construct）
            local slot = self.HorizontalBox_Character:AddChild(buttonWidget)
            
            -- 设置Slot样式
            if slot then
                -- 设置Padding（左、上、右、下的间距）
                slot:SetPadding(UE.FMargin(10, 5, 10, 5))
                
                -- 设置水平对齐方式（居中）
                slot:SetHorizontalAlignment(UE.EHorizontalAlignment.HAlign_Center)
                
                -- 设置垂直对齐方式（居中）
                slot:SetVerticalAlignment(UE.EVerticalAlignment.VAlign_Center)
                
                -- 设置自动大小
                slot:SetSize(UE.FSlateChildSize(UE.ESlateSizeRule.Automatic, 1.0))
            end
            
            -- 设置按钮文本（假设按钮有 Text_Button 组件）
            if buttonWidget.Text_Button then
                buttonWidget.Text_Button:SetText(characterName)
                print(string.format("  [%d] ✓ 已创建角色按钮: %s", index, characterName))
            else
                print(string.format("  [%d] ⚠️ 按钮没有 Text_Button 组件: %s", index, characterName))
            end
            
            -- 绑定点击事件
            self:BindCharacterButtonClick(buttonWidget, characterName)
        else
            print(string.format("  [%d] ❌ 创建角色按钮失败: %s", index, characterName))
        end
    end
    
    print(string.format("[UI_StoryScene] ✅ 角色按钮创建完成，共 %d 个", #characters))
end

---绑定角色按钮点击事件
---@param buttonWidget userdata 按钮Widget实例
---@param characterName string 角色名字
function M:BindCharacterButtonClick(buttonWidget, characterName)
    if not buttonWidget then
        return
    end
    
    -- 检查 Button_Main 组件是否存在
    if not buttonWidget.Button_Main then
        print(string.format("  └─ ⚠️ 警告：按钮没有 Button_Main 组件: %s", characterName))
        return
    end
    
    -- 绑定 Button_Main 的点击事件
    if buttonWidget.Button_Main.OnClicked then
        buttonWidget.Button_Main.OnClicked:Add(self, function()
            self:OnCharacterButtonClicked(characterName)
        end)
        print(string.format("  └─ ✓ 已绑定 Button_Main 点击事件: %s", characterName))
    else
        print(string.format("  └─ ⚠️ 警告：Button_Main 没有 OnClicked 事件: %s", characterName))
    end
end

---处理角色按钮点击事件
---@param characterName string 角色名字
function M:OnCharacterButtonClicked(characterName)
    print(string.format("\n[UI_StoryScene] ========== 点击角色按钮: %s ==========", characterName))
    
    -- 选择该角色并进入对话
    self:SelectCharacter(characterName)
    
    print(string.rep("=", 70) .. "\n")
end

-- ==================== 公开接口 ====================

---获取当前主状态
---@return string 当前UI主状态
function M:GetCurrentState()
    return self.currentState
end

---获取当前对话子状态
---@return string|nil 当前对话子状态
function M:GetCurrentChatSubState()
    return self.currentChatSubState
end

---获取当前故事ID
---@return string storyId 当前故事ID
function M:GetStoryId()
    return self.storyId
end

---获取当前角色
---@return string character 当前角色
function M:GetCharacter()
    return self.character
end

---获取当前StoryMapWidget实例
---@return userdata|nil widget StoryMapWidget实例
function M:GetCurrentStoryMapWidget()
    return self.currentStoryMapWidget
end

-- ==================== 场景与角色操作 ====================

---进入指定场景的对话
---@param sceneId string 场景ID
function M:EnterScene(sceneId)
    print(string.format("[UI_StoryScene] 进入场景: %s", sceneId))
    
    self.selectedScene = sceneId
    
    -- 🔥 关键：初始化该场景的所有角色信息（缓存）
    self:InitializeSceneCharacters(sceneId)
    
    -- 切换到对话状态
    self:SwitchToState(M.UIState.SceneChat)
end

---初始化场景的所有角色信息（缓存）
---@param sceneId string 场景ID
function M:InitializeSceneCharacters(sceneId)
    print(string.format("\n[UI_StoryScene] ========== 初始化场景角色信息: %s ==========", sceneId))
    
    -- 清空旧缓存
    self.sceneCharactersCache = {}
    
    -- 获取场景中的角色列表
    local characters = self:GetSceneCharacters()
    
    if not characters or #characters == 0 then
        print("[UI_StoryScene] ⚠️ 当前场景无角色")
        return
    end
    
    print(string.format("[UI_StoryScene] 场景中有 %d 个角色需要初始化", #characters))
    
    -- 🔥 使用 StoryLibraryManager 获取当前故事配置（参考 GM_Home）
    local currentStory = StoryLibraryManager:GetCurrentStory()
    
    if not currentStory then
        print("[UI_StoryScene] ❌ 错误：未找到当前故事，请确保已在 GM_Home 中初始化故事")
        print("[UI_StoryScene] 💡 提示：请检查 GM_Home:init_Story() 是否已执行")
        return
    end
    
    print(string.format("[UI_StoryScene] ✓ 获取到当前故事: %s", currentStory.title))
    
    -- 🔥 使用 self.currentStoryId（从 StoryLibraryManager 获取的实际故事ID）
    if not self.currentStoryId then
        print("[UI_StoryScene] ❌ 错误：self.currentStoryId 未设置")
        print("[UI_StoryScene] 💡 请确保 CheckStoryLoaded() 已在 Construct 中执行")
        return
    end
    
    print(string.format("[UI_StoryScene] 故事库ID: %s", self.currentStoryId))
    
    local configPath = M.StoryConfigMap[self.currentStoryId]
    if not configPath then
        print(string.format("[UI_StoryScene] ❌ 错误：未找到配置路径 %s", self.currentStoryId))
        return
    end
    
    print(string.format("[UI_StoryScene] 配置路径: %s", configPath))
    
    -- 加载故事配置
    local success, storyConfig = pcall(require, configPath)
    if not success then
        print(string.format("[UI_StoryScene] ❌ 错误：无法加载配置文件 %s", configPath))
        print(string.format("[UI_StoryScene] 错误详情: %s", tostring(storyConfig)))
        return
    end
    
    -- 如果配置是函数，调用它获取配置数据
    if type(storyConfig) == "function" then
        storyConfig = storyConfig()
        print("[UI_StoryScene] ✓ 已调用配置函数获取数据")
    end
    
    -- 从配置中获取角色信息
    if not storyConfig.display or not storyConfig.display.characters then
        print("[UI_StoryScene] ❌ 错误：配置中未找到 display.characters")
        print(string.format("[UI_StoryScene] 配置结构: %s", type(storyConfig)))
        if storyConfig.display then
            print("[UI_StoryScene] display 存在但 characters 不存在")
        else
            print("[UI_StoryScene] display 不存在")
        end
        return
    end
    
    print(string.format("[UI_StoryScene] ✓ 配置中有 %d 个角色定义", #storyConfig.display.characters))
    
    -- 遍历场景中的所有角色，构建缓存
    print(string.format("[UI_StoryScene] 开始缓存角色信息..."))
    
    for index, characterName in ipairs(characters) do
        print(string.format("  [%d] 正在查找角色: %s", index, characterName))
        
        -- 从配置中查找角色
        local characterInfo = nil
        for _, char in ipairs(storyConfig.display.characters) do
            if char.name == characterName then
                characterInfo = char
                break
            end
        end
        
        if characterInfo then
            -- 构建完整的角色信息（包含对话所需的所有字段）
            self.sceneCharactersCache[characterName] = {
                name = characterInfo.name or characterName,
                title = characterInfo.title or "未知",
                appearance = characterInfo.appearance or "",
                firstImpression = characterInfo.firstImpression or "",
                personality = characterInfo.personality or characterInfo.firstImpression or "性格未知",
                motivation = characterInfo.motivation or "动机未知",
                dialogueStyle = characterInfo.dialogueStyle or characterInfo.firstImpression or "说话风格未知",
                currentIntention = characterInfo.currentIntention or "观察主角，根据对话内容做出自然反应",
                background = characterInfo.background or ""
            }
            
            print(string.format("  [%d] ✅ 已缓存角色: %s (%s)", index, characterInfo.name, characterInfo.title))
            print(string.format("       - personality: %s", 
                (characterInfo.personality or characterInfo.firstImpression or "性格未知"):sub(1, 30) .. "..."))
        else
            -- 即使没有找到配置，也创建默认信息
            self.sceneCharactersCache[characterName] = {
                name = characterName,
                title = "未知",
                appearance = "",
                firstImpression = "",
                personality = "性格未知",
                motivation = "动机未知",
                dialogueStyle = "说话风格未知",
                currentIntention = "观察主角，根据对话内容做出自然反应",
                background = ""
            }
            
            print(string.format("  [%d] ⚠️ 未找到角色配置，使用默认值: %s", index, characterName))
        end
    end
    
    print(string.format("\n[UI_StoryScene] ✅ 角色信息缓存完成，共 %d 个", #characters))
    print("[UI_StoryScene] 缓存内容:")
    for name, info in pairs(self.sceneCharactersCache) do
        print(string.format("  - %s: %s (%s)", name, info.name, info.title))
    end
    print(string.rep("=", 70) .. "\n")
end

---选择对话角色
---@param characterId string 角色ID
function M:SelectCharacter(characterId)
    print(string.format("\n[UI_StoryScene] ========== 选择角色: %s ==========", characterId))
    
    self.selectedCharacter = characterId
    
    -- 🔥 关键：直接从缓存中获取角色信息
    local cachedInfo = self.sceneCharactersCache[characterId]
    
    if cachedInfo then
        -- 使用缓存的角色信息（已经包含所有需要的字段）
        self.currentNpcInfo = cachedInfo
        
        print(string.format("[UI_StoryScene] ✅ 从缓存获取角色信息: %s (%s)", 
            self.currentNpcInfo.name, 
            self.currentNpcInfo.title))
        print(string.format("[UI_StoryScene]    - personality: %s", self.currentNpcInfo.personality))
        print(string.format("[UI_StoryScene]    - motivation: %s", self.currentNpcInfo.motivation))
        print(string.format("[UI_StoryScene]    - dialogueStyle: %s", 
            self.currentNpcInfo.dialogueStyle:sub(1, 50) .. "..."))
    else
        print(string.format("[UI_StoryScene] ❌ 错误：缓存中未找到角色信息: %s", characterId))
        print("[UI_StoryScene] 💡 请确保已调用 InitializeSceneCharacters")
        
        -- 兜底：创建默认信息
        self.currentNpcInfo = {
            name = characterId,
            title = "未知",
            appearance = "",
            firstImpression = "",
            personality = "性格未知",
            motivation = "动机未知",
            dialogueStyle = "说话风格未知",
            currentIntention = "观察主角，根据对话内容做出自然反应",
            background = ""
        }
        
        print("[UI_StoryScene] ⚠️ 使用默认角色信息")
    end
    
    -- ⚠️ 暂时不使用 SwitchToCharacter，避免触发 BM_StoryConfig 查询
    -- 原因：LuoyangStoryConfig 的结构与 BM_StoryConfig 期望的不同
    print(string.format("[UI_StoryScene] ℹ️ 使用简化对话模式（无历史记录）"))
    
    print(string.rep("=", 70) .. "\n")
    
    -- 切换到角色对话子状态
    self:SwitchToChatSubState(M.ChatSubState.CharacterChat)
end

---返回到地图
function M:BackToMap()
    print("[UI_StoryScene] 返回到地图")
    
    -- 🔥 隐藏所有覆盖层
    self:HideDialogOverlay()
    self:HideCharacterInfoOverlay()
    
    -- 清空选择
    self.selectedScene = nil
    self.selectedCharacter = nil
    self.currentNpcInfo = nil
    
    -- 切换到地图状态
    self:SwitchToState(M.UIState.SceneMap)
end

---返回到角色选择
function M:BackToChatSelect()
    print("[UI_StoryScene] 返回到角色选择")
    
    -- ⚠️ 暂时不使用 ExitCharacterMode
    -- 原因：使用简化对话模式，无历史记录功能
    
    -- if self.llmMgr and self.currentNpcInfo then
    --     self.llmMgr:ExitCharacterMode()
    --     print(string.format("[UI_StoryScene] ✅ 已保存与 %s 的对话历史", self.currentNpcInfo.name))
    -- end
    
    if self.currentNpcInfo then
        print(string.format("[UI_StoryScene] 结束与 %s 的对话", self.currentNpcInfo.name))
    end
    
    -- 🔥 隐藏所有覆盖层
    self:HideDialogOverlay()
    self:HideCharacterInfoOverlay()
    
    -- 🔥 退出角色对话时，清空当前场景的所有动态抉择
    local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
    local currentSceneId = BM_StoryRuntime:GetCurrentSceneId()
    
    if currentSceneId and currentSceneId ~= "" then
        print(string.format("\n[UI_StoryScene] ========== 退出对话，清空所有动态抉择 =========="))
        print(string.format("[UI_StoryScene] 场景ID: %s", currentSceneId))
        
        -- 获取当前场景的所有动态抉择
        local dynamicChoices = BM_StoryRuntime:GetDynamicChoices(currentSceneId)
        
        if dynamicChoices and #dynamicChoices > 0 then
            print(string.format("[UI_StoryScene] 找到 %d 个动态抉择，准备清空", #dynamicChoices))
            
            -- 清空所有动态抉择
            local clearResult = BM_StoryRuntime:ClearDynamicChoices(currentSceneId)
            
            if clearResult and clearResult.success then
                print(string.format("[UI_StoryScene] ✅ 已清空 %d 个动态抉择", #dynamicChoices))
                
                -- 刷新UI，移除所有抉择按钮
                self:RefreshSceneDecisionOnly()
                print("[UI_StoryScene] ✅ UI已刷新，所有抉择按钮已移除")
            else
                print(string.format("[UI_StoryScene] ⚠️ 清空动态抉择失败: %s", 
                    clearResult and clearResult.error or "未知错误"))
            end
        else
            print("[UI_StoryScene] ℹ️ 当前场景没有动态抉择，无需清空")
        end
        
        print(string.rep("=", 70) .. "\n")
    end
    
    -- 清空选中的角色和NPC信息
    self.selectedCharacter = nil
    self.currentNpcInfo = nil
    
    -- 切换到对话选择子状态
    self:SwitchToChatSubState(M.ChatSubState.ChatSelect)
end

-- ==================== 按钮事件处理 ====================

---覆盖层关闭按钮点击事件（可以关闭对话覆盖层或角色信息覆盖层）
function M:OnOverlayCloseClicked()
    print("[UI_StoryScene] 点击关闭覆盖层按钮")
    
    -- 🔥 检查哪个覆盖层可见，然后关闭它
    local closedAny = false
    
    -- 尝试关闭角色信息覆盖层
    if self.Overlay_CharacterInfo and self.Overlay_CharacterInfo:GetVisibility() == UE.ESlateVisibility.Visible then
        self:HideCharacterInfoOverlay()
        closedAny = true
    end
    
    -- 尝试关闭对话覆盖层
    if self.Overlay_Tint and self.Overlay_Tint:GetVisibility() == UE.ESlateVisibility.Visible then
        self:HideDialogOverlay()
        closedAny = true
    end
    
    if closedAny then
        print("[UI_StoryScene] ✅ 已关闭可见的覆盖层")
    else
        print("[UI_StoryScene] ℹ️ 没有可见的覆盖层需要关闭")
    end
end

---返回按钮点击事件
function M:OnBackClicked()
    print("\n[UI_StoryScene] ========== 点击返回按钮 ==========")
    print(string.format("[UI_StoryScene] 当前主状态: %s", self.currentState or "nil"))
    print(string.format("[UI_StoryScene] 当前子状态: %s", self.currentChatSubState or "nil"))
    
    -- 根据当前状态决定返回行为
    if self.currentState == M.UIState.SceneChat then
        -- 在场景对话状态下，需要根据子状态判断
        if self.currentChatSubState == M.ChatSubState.CharacterChat then
            -- CharacterChat → ChatSelect（返回到角色选择）
            print("[UI_StoryScene] 从 CharacterChat 返回到 ChatSelect（角色选择）")
            self:BackToChatSelect()
            
        elseif self.currentChatSubState == M.ChatSubState.ChatSelect then
            -- ChatSelect → SceneMap（返回到地图）
            print("[UI_StoryScene] 从 ChatSelect 返回到 SceneMap（地图界面）")
            self:BackToMap()
            
        else
            -- 未知子状态，默认返回地图
            print("[UI_StoryScene] 未知子状态，返回到 SceneMap")
            self:BackToMap()
        end
        
    elseif self.currentState == M.UIState.SceneMap then
        -- 在地图状态下，返回到主菜单（UI_Home）
        print("[UI_StoryScene] 从 SceneMap 返回到主菜单（UI_Home）")
        self:BackToMainMenu()
        
    else
        -- 未知状态，默认返回地图
        print("[UI_StoryScene] 未知状态，返回到 SceneMap")
        self:BackToMap()
    end
    
    print(string.rep("=", 70) .. "\n")
end

---返回到主菜单（UI_Home）
function M:BackToMainMenu()
    print("[UI_StoryScene] 准备返回主菜单...")
    
    -- 获取 UIManager
    local uiManager = GameContext:GetUIManager()
    if not uiManager then
        print("[UI_StoryScene] ❌ 错误：无法获取 UIManager")
        return
    end
    
    -- 关闭当前 UI_StoryScene
    print("[UI_StoryScene] 关闭 UI_StoryScene...")
    uiManager:closeUI("Menu/GameLevel/UI_StoryScene.UI_StoryScene_C")
    
    -- 打开 UI_Home
    print("[UI_StoryScene] 打开 UI_Home...")
    local homeUI = uiManager:openUI(
        "Menu/HomeLevel/UI_Home.UI_Home_C",
        uiManager.ui_layer.WINDOW,
        nil,
        self
    )
    
    if homeUI then
        print("[UI_StoryScene] ✅ UI_Home 打开成功")
    else
        print("[UI_StoryScene] ⚠️ UI_Home 打开失败")
    end
end

-- ==================== 调试工具 ====================

---打印当前状态信息
function M:DebugPrintState()
    print("\n[UI_StoryScene] ========== 状态信息 ==========")
    print(string.format("当前主状态: %s", self.currentState or "nil"))
    print(string.format("当前对话子状态: %s", self.currentChatSubState or "nil"))
    print(string.format("故事ID: %s", self.storyId or "nil"))
    print(string.format("角色: %s", self.character or "nil"))
    print(string.format("当前地点索引: %s", self.currentLocationIndex and tostring(self.currentLocationIndex) or "未选择"))
    print(string.format("选中的场景: %s", self.selectedScene or "未选择"))
    print(string.format("选中的角色: %s", self.selectedCharacter or "未选择"))
    print("")
    print("--- UI组件状态 ---")
    print(string.format("SizeBox: %s", 
        self.SizeBox and tostring(self.SizeBox:GetVisibility()) or "不存在"))
    print(string.format("Canvas_ChatWidget: %s", 
        self.Canvas_ChatWidget and tostring(self.Canvas_ChatWidget:GetVisibility()) or "不存在"))
    print(string.format("StoryMapWidget实例: %s", tostring(self.currentStoryMapWidget)))
    print("=============================================\n")
end

return M

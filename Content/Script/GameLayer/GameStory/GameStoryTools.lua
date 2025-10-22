---GameStory工具注册器
---为LLM系统注册游戏故事相关的Tools

local BM_GameStory = require("DataLayer.GameStory.BM_GameStory")
local SceneStateManager = require("GameLayer.Story.SceneStateManager")

local GameStoryTools = {}

---注册所有游戏故事相关的Tools
---@param llmMgr LlmManager LLM管理器实例
function GameStoryTools.RegisterAllTools(llmMgr)
    if not llmMgr then
        error("[GameStoryTools] 注册Tools失败：LLM管理器为空")
    end
    
    print("[GameStoryTools] 开始注册游戏故事Tools...")
    
    -- Tool: save_game_background - 保存游戏背景设定（第1步）
    llmMgr:RegisterTool({
        name = "save_game_background",
        description = "保存AI生成的游戏背景设定",
        parameters = {
            type = "object",
            properties = {
                backgroundText = {
                    type = "string",
                    description = "游戏背景设定的完整文本"
                },
                sceneType = {
                    type = "string",
                    description = "场景类型（如：校园、公司、太空站等）"
                },
                disasterType = {
                    type = "string",
                    description = "灾难类型（如：爆炸、中毒、机械故障等）"
                }
            },
            required = {"backgroundText", "sceneType", "disasterType"}
        },
        execute = function(args)
            print("[Tool] save_game_background 被调用")
            
            -- 初始化BusinessModule（如果还没有初始化）
            if not BM_GameStory.dataModule._isInitialized then
                BM_GameStory.dataModule:init()
                BM_GameStory:initializeProperties()
            end
            
            -- 保存背景数据
            BM_GameStory:SaveGameBackground(
                args.backgroundText,
                args.sceneType,
                args.disasterType
            )
            
            return {
                success = true,
                message = "游戏背景设定已保存！",
                data = {
                    sceneType = args.sceneType,
                    disasterType = args.disasterType,
                    backgroundLength = #args.backgroundText
                }
            }
        end
    })
    
    -- Tool: genrate_game - 生成并保存完整游戏故事
    llmMgr:RegisterTool({
        name = "genrate_game",
        description = "保存AI生成的完整游戏故事数据，包括游戏背景、角色关系网、故事线和关键剧情点",
        parameters = {
            type = "object",
            properties = {
                gameBackground = {
                    type = "string",
                    description = "游戏背景设定的完整文本，包括场景、环境、世界观等"
                },
                roleRelationShip = {
                    type = "string",
                    description = "角色关系网的JSON字符串，包含所有角色的详细信息"
                },
                StoryLine = {
                    type = "string",
                    description = "故事线和关键剧情点的完整文本描述"
                },
                keySotryPoints = {
                    type = "string",
                    description = "关键剧情点列表的JSON字符串（可选）"
                }
            },
            required = {"gameBackground", "roleRelationShip", "StoryLine"}
        },
        execute = function(args)
            print("[Tool] genrate_game 被调用")
            
            -- 初始化BusinessModule（如果还没有初始化）
            if not BM_GameStory.dataModule._isInitialized then
                BM_GameStory.dataModule:init()
                BM_GameStory:initializeProperties()
            end
            
            -- 保存数据到BusinessModule
            local success = BM_GameStory:SaveGameStory(
                args.gameBackground,
                args.roleRelationShip,
                args.StoryLine,
                args.keySotryPoints
            )
            
            if success then
                -- 打印调试信息
                BM_GameStory:DebugPrint()
                
                return {
                    success = true,
                    message = "游戏世界已创建完成！",
                    data = {
                        charactersCount = #BM_GameStory:GetAllCharacters(),
                        hasProtagonist = BM_GameStory:GetProtagonist() ~= nil,
                        hasEnemy = BM_GameStory:GetEnemy() ~= nil,
                        storyPointsCount = #BM_GameStory:GetKeyStoryPoints()
                    }
                }
            else
                return {
                    success = false,
                    message = "游戏故事保存失败"
                }
            end
        end
    })
    
    -- Tool: get_character_info - 获取指定角色的信息
    llmMgr:RegisterTool({
        name = "get_character_info",
        description = "获取指定角色的详细信息",
        parameters = {
            type = "object",
            properties = {
                characterName = {
                    type = "string",
                    description = "角色名称"
                }
            },
            required = {"characterName"}
        },
        execute = function(args)
            if not BM_GameStory:IsGenerated() then
                return {
                    success = false,
                    message = "游戏故事尚未生成"
                }
            end
            
            local character = BM_GameStory:GetCharacterByName(args.characterName)
            if character then
                local json = require("rapidjson")
                return {
                    success = true,
                    characterData = json.encode(character)
                }
            else
                return {
                    success = false,
                    message = "未找到角色：" .. args.characterName
                }
            end
        end
    })
    
    -- Tool: get_story_point - 获取指定的剧情点
    llmMgr:RegisterTool({
        name = "get_story_point",
        description = "获取指定索引的关键剧情点信息",
        parameters = {
            type = "object",
            properties = {
                index = {
                    type = "number",
                    description = "剧情点索引（从1开始）"
                }
            },
            required = {"index"}
        },
        execute = function(args)
            if not BM_GameStory:IsGenerated() then
                return {
                    success = false,
                    message = "游戏故事尚未生成"
                }
            end
            
            local storyPoint = BM_GameStory:GetStoryPointByIndex(args.index)
            if storyPoint then
                local json = require("rapidjson")
                return {
                    success = true,
                    storyPoint = json.encode(storyPoint)
                }
            else
                return {
                    success = false,
                    message = "剧情点索引超出范围"
                }
            end
        end
    })
    
    -- Tool: save_disaster_plan - 保存灾难计划详情
    llmMgr:RegisterTool({
        name = "save_disaster_plan",
        description = "保存仇人的灾难计划详细信息",
        parameters = {
            type = "object",
            properties = {
                planDetails = {
                    type = "string",
                    description = "灾难计划的完整描述"
                }
            },
            required = {"planDetails"}
        },
        execute = function(args)
            if not BM_GameStory.dataModule._isInitialized then
                BM_GameStory.dataModule:init()
                BM_GameStory:initializeProperties()
            end
            
            BM_GameStory:SaveDisasterPlan(args.planDetails)
            
            return {
                success = true,
                message = "灾难计划已保存"
            }
        end
    })
    
    -- Tool: unlock_choice - 动态生成并解锁场景抉择（在对话中）
    llmMgr:RegisterTool({
        name = "unlock_choice",
        description = [[在对话过程中动态生成并解锁一个场景抉择，让玩家可以执行该抉择。
        
【重要】：你可以根据对话内容自由创造抉择，不需要受限于配置中的固定选项。
配置中的抉择只是参考示例，你应该基于实际对话情况生成更合适的抉择。

通常在对话达到特定条件时调用，例如：
- 玩家问到了关键问题
- NPC透露了重要信息或线索
- 玩家获得了NPC的信任
- 触发了剧情的转折点]],
        parameters = {
            type = "object",
            properties = {
                choiceName = {
                    type = "string",
                    description = "抉择的名称，简短有力，如 '调查雷克斯的活动'、'向镇长告发'、'暗中跟踪'"
                },
                description = {
                    type = "string",
                    description = "抉择的详细描述，解释这个抉择会做什么，如 '前往雷克斯经常出没的地方调查他的可疑行为'"
                },
                reason = {
                    type = "string",
                    description = "解锁这个抉择的原因，如 '老乔透露了雷克斯的可疑之处'"
                }
            },
            required = {"choiceName", "description"}
        },
        execute = function(args)
            print("\n" .. string.rep("=", 70))
            print(string.format("[Tool] 🔧 unlock_choice 被调用 - 动态抉择"))
            print(string.rep("=", 70))
            
            -- 错误检查
            if not args then
                print("[Tool] ❌ 错误：args 为 nil")
                return {success = false, message = "参数为空"}
            end
            
            if not args.choiceName then
                print("[Tool] ❌ 错误：choiceName 为空")
                return {success = false, message = "抉择名称为空"}
            end
            
            if not args.description then
                print("[Tool] ❌ 错误：description 为空")
                return {success = false, message = "抉择描述为空"}
            end
            
            print(string.format("[Tool] 抉择名称: %s", tostring(args.choiceName)))
            print(string.format("[Tool] 抉择描述: %s", tostring(args.description)))
            if args.reason then
                print(string.format("[Tool] 解锁原因: %s", tostring(args.reason)))
            end
            
            -- 动态生成抉择ID（基于名称和时间戳）
            local timestamp = os.time()
            local choiceId = string.format("dynamic_choice_%d", timestamp)
            
            print(string.format("[Tool] 生成抉择ID: %s", choiceId))
            
            -- 使用 SceneStateManager 动态解锁抉择
            local result = SceneStateManager.UnlockDynamicChoice({
                id = choiceId,
                name = args.choiceName,
                description = args.description,
                isDynamic = true,
                unlockReason = args.reason
            })
            
            if result.success then
                print(string.format("[Tool] ✅ 动态抉择已生成并解锁"))
                print(string.format("[Tool]    抉择ID: %s (动态生成)", choiceId))
                print(string.format("[Tool]    抉择名称: %s", args.choiceName))
                
                -- 通知UI刷新抉择按钮
                local UI_Dialog1 = require("UI.Menu.UI_Dialog1")
                print(string.format("[Tool] 检查UI实例: Instance=%s", tostring(UI_Dialog1.Instance)))
                
                if UI_Dialog1.Instance then
                    print("[Tool] ✅ UI实例存在，调用刷新方法...")
                    
                    if UI_Dialog1.Instance.RefreshSceneDecisionOnly then
                        UI_Dialog1.Instance:RefreshSceneDecisionOnly()
                        print("[Tool] ✅ UI抉择按钮已刷新")
                    else
                        print("[Tool] ❌ RefreshSceneDecisionOnly 方法不存在")
                    end
                else
                    print("[Tool] ❌ UI_Dialog1.Instance 为 nil，无法刷新UI")
                end
                
                print(string.rep("=", 70) .. "\n")
                
                local message = string.format("✨ 解锁新抉择: %s", args.choiceName)
                if args.reason then
                    message = message .. string.format("\n   原因: %s", args.reason)
                end
                
                return {
                    success = true,
                    message = message,
                    choiceInfo = {
                        id = choiceId,
                        name = args.choiceName,
                        description = args.description,
                        isDynamic = true
                    }
                }
            else
                print(string.format("[Tool] ❌ 解锁动态抉择失败: %s", result.error))
                print(string.rep("=", 70) .. "\n")
                return {
                    success = false,
                    message = result.error
                }
            end
        end
    })
    
    -- ==================== 新增：场景抉择后的判定工具 ====================
    
    -- 工具：开始新循环
    llmMgr:RegisterTool({
        name = "start_new_loop",
        description = "结束当前循环，开始新的一次循环（用于灾难/死亡事件）",
        parameters = {
            type = "object",
            properties = {
                reason = {
                    type = "string",
                    description = "重置原因，如'灾难发生'、'玩家死亡'"
                }
            },
            required = {"reason"}
        },
        execute = function(args)
            print("\n" .. string.rep("=", 70))
            print(string.format("[Tool] 🔧 start_new_loop 被调用: %s", args.reason or "未知原因"))
            print(string.rep("=", 70))
            
            -- 使用 SceneStateManager 开始新循环
            local result = SceneStateManager.StartNewLoop(args.reason)
            
            if result.success then
                print(string.format("[Tool] ✅ 成功开始第 %d 次循环", result.newLoopCount))
                print(string.format("[Tool]    重置原因: %s", args.reason or "未知"))
                
                -- 通知UI显示新循环信息
                local UI_Dialog1 = require("UI.Menu.UI_Dialog1")
                if UI_Dialog1.Instance then
                    UI_Dialog1.Instance:AddSystemMessage(string.format("【新循环】第 %d 次循环开始", result.newLoopCount))
                    UI_Dialog1.Instance:ShowSceneInfo()
                    UI_Dialog1.Instance:RefreshCharacterSelectionAndSceneDecision()
                end
                
                print(string.rep("=", 70) .. "\n")
                
                return {
                    success = true,
                    message = string.format("开始第 %d 次循环", result.newLoopCount),
                    newLoopCount = result.newLoopCount
                }
            else
                print(string.format("[Tool] ❌ 开始新循环失败: %s", result.error))
                print(string.rep("=", 70) .. "\n")
                
                return {
                    success = false,
                    message = result.error
                }
            end
        end
    })
    
    -- 工具：切换场景
    llmMgr:RegisterTool({
        name = "switch_scene",
        description = "切换到另一个场景",
        parameters = {
            type = "object",
            properties = {
                sceneId = {
                    type = "string",
                    description = "目标场景ID，如'scene_park'"
                },
                reason = {
                    type = "string",
                    description = "切换原因，如'追踪雷克斯'"
                }
            },
            required = {"sceneId"}
        },
        execute = function(args)
            print("\n" .. string.rep("=", 70))
            print(string.format("[Tool] 🔧 switch_scene 被调用: %s", args.sceneId))
            print(string.rep("=", 70))
            
            -- 使用 SceneStateManager 切换场景
            local result = SceneStateManager.EnterScene(args.sceneId)
            
            if result.success then
                print(string.format("[Tool] ✅ 成功切换到场景: %s", result.sceneInfo.name))
                print(string.format("[Tool]    场景ID: %s", args.sceneId))
                if args.reason then
                    print(string.format("[Tool]    切换原因: %s", args.reason))
                end
                
                -- 通知UI更新
                local UI_Dialog1 = require("UI.Menu.UI_Dialog1")
                if UI_Dialog1.Instance then
                    if args.reason then
                        UI_Dialog1.Instance:AddSystemMessage(string.format("【场景切换】%s", args.reason))
                    end
                    UI_Dialog1.Instance:ShowSceneInfo()
                    UI_Dialog1.Instance:RefreshCharacterSelectionAndSceneDecision()
                end
                
                print(string.rep("=", 70) .. "\n")
                
                return {
                    success = true,
                    message = string.format("已切换到：%s", result.sceneInfo.name),
                    sceneInfo = {
                        id = result.sceneInfo.id,
                        name = result.sceneInfo.name
                    }
                }
            else
                print(string.format("[Tool] ❌ 切换场景失败: %s", result.error))
                print(string.rep("=", 70) .. "\n")
                
                return {
                    success = false,
                    message = result.error
                }
            end
        end
    })
    
    -- 工具：继续当前循环（SceneChoice专用）
    llmMgr:RegisterTool({
        name = "continue_cur_loop",
        description = "【SceneChoice专用】继续当前循环，故事继续（抉择后果不触发循环重置）",
        parameters = {
            type = "object",
            properties = {
                reason = {
                    type = "string",
                    description = "继续原因，说明为什么这个抉择不触发重置，如'获得了线索但未触发灾难'"
                }
            },
            required = {"reason"}
        },
        execute = function(args)
            print("\n" .. string.rep("=", 70))
            print(string.format("[Tool] 🔧 continue_cur_loop 被调用"))
            print(string.rep("=", 70))
            
            print(string.format("[Tool] ✅ 继续当前循环"))
            print(string.format("[Tool]    原因: %s", args.reason or "未知"))
            
            -- 通知UI刷新（抉择可能有变化）
            local UI_Dialog1 = require("UI.Menu.UI_Dialog1")
            if UI_Dialog1.Instance then
                UI_Dialog1.Instance:AddSystemMessage(string.format("【故事继续】%s", args.reason))
                -- 刷新抉择按钮（可能有新的抉择解锁）
                UI_Dialog1.Instance:RefreshSceneDecisionOnly()
            end
            
            print(string.rep("=", 70) .. "\n")
            
            return {
                success = true,
                message = "继续当前循环",
                action = "continue_loop",
                reason = args.reason
            }
        end
    })
    
    -- 工具：结束循环（SceneChoice专用）
    llmMgr:RegisterTool({
        name = "end_loop",
        description = "【SceneChoice专用】结束循环，故事结束（玩家达成了终止循环的条件）",
        parameters = {
            type = "object",
            properties = {
                reason = {
                    type = "string",
                    description = "结束原因，说明为什么循环终止，如'玩家成功说服仇人放弃计划'"
                },
                endingType = {
                    type = "string",
                    description = "结局类型：good（好结局）、bad（坏结局）、neutral（中性结局）"
                }
            },
            required = {"reason"}
        },
        execute = function(args)
            print("\n" .. string.rep("=", 70))
            print(string.format("[Tool] 🔧 end_loop 被调用 - 故事结束"))
            print(string.rep("=", 70))
            
            local endingType = args.endingType or "neutral"
            print(string.format("[Tool] ✅ 时间循环结束"))
            print(string.format("[Tool]    结束原因: %s", args.reason or "未知"))
            print(string.format("[Tool]    结局类型: %s", endingType))
            
            -- 设置游戏结束标记
            local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
            BM_StoryRuntime:SetGameEnded(true, endingType, args.reason)
            
            -- 通知UI显示结局
            local UI_Dialog1 = require("UI.Menu.UI_Dialog1")
            if UI_Dialog1.Instance then
                local endingEmoji = {
                    good = "🎉",
                    bad = "💔",
                    neutral = "🌟"
                }
                local emoji = endingEmoji[endingType] or "🌟"
                UI_Dialog1.Instance:AddSystemMessage(string.format("%s【游戏结束】%s", emoji, args.reason))
                
                -- 显示结局界面（可以后续实现）
                if UI_Dialog1.Instance.ShowEndingScreen then
                    UI_Dialog1.Instance:ShowEndingScreen(endingType, args.reason)
                end
            end
            
            print(string.rep("=", 70) .. "\n")
            
            return {
                success = true,
                message = string.format("时间循环结束 - %s结局", endingType),
                action = "end_loop",
                endingType = endingType,
                reason = args.reason
            }
        end
    })
    
    print("[GameStoryTools] Tools注册完成，共注册 11 个工具")
end

---获取BusinessModule实例（供外部访问）
---@return BM_GameStory
function GameStoryTools.GetBusinessModule()
    return BM_GameStory
end

return GameStoryTools


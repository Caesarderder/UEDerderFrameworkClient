---LLM工具调用系统
local SystemBase = require("Core.GameLayerBase.SystemBase")
local BM_LlmTool = require("DataLayer.Llm.BM_LlmTool")
local json = require("rapidjson")

---@class LlmToolSystem : SystemBase
---@type LlmToolSystem
local LlmToolSystem = {}
setmetatable(LlmToolSystem, { __index = SystemBase })

---初始化系统
function LlmToolSystem:init()
    -- 先初始化DataModule的数据
    BM_LlmTool.dataModule:init()
    -- 再初始化BusinessModule属性访问器
    BM_LlmTool:initializeProperties()
    
    -- 注册内置工具
    self:RegisterBuiltInTools()
    
    print("[LlmToolSystem] 工具系统初始化完成")
end

---注册内置工具
function LlmToolSystem:RegisterBuiltInTools()
    -- 示例：生成图片工具
    self:RegisterTool({
        name = "generate_image",
        description = "根据描述生成游戏内图片",
        parameters = {
            type = "object",
            properties = {
                description = {
                    type = "string",
                    description = "图片描述"
                },
                style = {
                    type = "string",
                    enum = {"realistic", "cartoon", "pixel"},
                    description = "图片风格"
                }
            },
            required = {"description"}
        },
        execute = function(args)
            print("[Tool] 生成图片:", args.description, "风格:", args.style or "default")
            return {
                success = true,
                imageUrl = "generated_image_url",
                message = "图片生成成功"
            }
        end
    })
    
    -- 示例：角色行为工具
    self:RegisterTool({
        name = "character_action",
        description = "让游戏角色执行特定行为",
        parameters = {
            type = "object",
            properties = {
                characterName = {
                    type = "string",
                    description = "角色名称"
                },
                action = {
                    type = "string",
                    enum = {"walk", "run", "jump", "talk", "attack"},
                    description = "行为类型"
                },
                target = {
                    type = "string",
                    description = "行为目标（可选）"
                }
            },
            required = {"characterName", "action"}
        },
        execute = function(args)
            print("[Tool] 角色行为:", args.characterName, args.action, args.target or "")
            return {
                success = true,
                message = string.format("%s 执行了 %s", args.characterName, args.action)
            }
        end
    })
    
    -- 示例：触发事件工具
    self:RegisterTool({
        name = "trigger_event",
        description = "触发游戏事件，改变故事节奏",
        parameters = {
            type = "object",
            properties = {
                eventType = {
                    type = "string",
                    enum = {"combat", "dialogue", "puzzle", "cutscene"},
                    description = "事件类型"
                },
                intensity = {
                    type = "number",
                    description = "事件强度(1-10)"
                }
            },
            required = {"eventType"}
        },
        execute = function(args)
            print("[Tool] 触发事件:", args.eventType, "强度:", args.intensity or 5)
            return {
                success = true,
                message = "事件已触发"
            }
        end
    })
    
    -- 示例：查询玩家背包
    self:RegisterTool({
        name = "get_player_inventory",
        description = "获取玩家背包中的物品列表",
        parameters = {
            type = "object",
            properties = {},
            required = {}
        },
        execute = function(args)
            -- 这里应该从游戏数据中获取
            local inventory = {
                { name = "铁剑", count = 1 },
                { name = "生命药水", count = 5 },
                { name = "金币", count = 100 }
            }
            return {
                success = true,
                items = inventory
            }
        end
    })
    
    -- 更新NPC当前意图
    self:RegisterTool({
        name = "update_npc_intention",
        description = "根据对话进展动态更新NPC的当前意图状态",
        parameters = {
            type = "object",
            properties = {
                npcId = {
                    type = "string",
                    description = "NPC的ID"
                },
                newIntention = {
                    type = "string",
                    description = "NPC的新意图状态（描述NPC现在想做什么、引导主角做什么）"
                },
                reason = {
                    type = "string",
                    description = "更新意图的原因（可选）"
                }
            },
            required = {"npcId", "newIntention"}
        },
        execute = function(args)
            print(string.format("[Tool] 更新NPC意图: %s -> %s", args.npcId, args.newIntention))
            if args.reason then
                print(string.format("  原因: %s", args.reason))
            end
            
            -- 触发事件通知，由UI层处理实际更新
            local EventSystem = require("GameLayer.Event.EventSystem")
            EventSystem:TriggerEvent("OnNpcIntentionChanged", {
                npcId = args.npcId,
                newIntention = args.newIntention,
                reason = args.reason
            })
            
            return {
                success = true,
                message = string.format("NPC[%s]的意图已更新", args.npcId)
            }
        end
    })
end

---注册工具
---@param toolDef table 工具定义
function LlmToolSystem:RegisterTool(toolDef)
    BM_LlmTool:RegisterTool(toolDef)
    print("[LlmToolSystem] 注册工具: " .. toolDef.name)
end

---获取工具定义（用于请求）
---@return table 工具定义列表
function LlmToolSystem:GetToolsForRequest()
    return BM_LlmTool:GetToolsForRequest()
end

---执行工具调用
---@param toolCalls table 工具调用列表（来自LLM响应）
---@return table 执行结果列表
function LlmToolSystem:ExecuteToolCalls(toolCalls)
    local results = {}
    
    for i, toolCall in ipairs(toolCalls) do
        print(string.format("[LlmToolSystem] 执行工具 #%d:", i))
        print(string.format("  - toolCall.id: %s", tostring(toolCall.id)))
        print(string.format("  - toolCall.type: %s", tostring(toolCall.type)))
        
        local toolName = toolCall["function"].name
        local argumentsJson = toolCall["function"].arguments
        
        print(string.format("  - 工具名: %s", tostring(toolName)))
        print(string.format("  - 参数JSON类型: %s", type(argumentsJson)))
        print(string.format("  - 参数JSON内容(原始): %s", tostring(argumentsJson)))
        
        -- 🔥 清理 argumentsJson：移除可能存在的 userdata 后缀
        if type(argumentsJson) == "string" then
            -- 移除 "userdata: xxxxx" 这种后缀
            argumentsJson = argumentsJson:match("^(.-)userdata:") or argumentsJson
            -- 移除可能的尾部空白
            argumentsJson = argumentsJson:match("^%s*(.-)%s*$") or argumentsJson
            print(string.format("  - 参数JSON内容(清理后): %s", argumentsJson))
        end
        
        -- 解析参数（增加错误处理）
        local arguments = {}  -- 🔥 默认使用空table
        
        if type(argumentsJson) == "string" then
            local success, decoded = pcall(json.decode, argumentsJson)
            if success and decoded ~= nil then
                arguments = decoded
                print(string.format("  - ✅ JSON解析成功，参数类型: %s", type(decoded)))
            else
                print(string.format("  - ❌ JSON解析失败或返回nil: %s", tostring(decoded)))
                arguments = {}  -- 使用空table作为后备
            end
        elseif type(argumentsJson) == "table" then
            print("  - ℹ️ 参数已经是table，无需解析")
            arguments = argumentsJson
        else
            print(string.format("  - ⚠️ 参数类型异常 (%s)，使用空table", type(argumentsJson)))
            arguments = {}
        end
        
        -- 🔥 最后的保险：确保 arguments 不为 nil
        if arguments == nil then
            print("  - ⚠️ 警告：arguments 为 nil，使用空table")
            arguments = {}
        end
        
        -- 执行工具
        print(string.format("  - 调用工具执行函数，参数类型: %s", type(arguments)))
        if type(arguments) == "table" then
            print(string.format("  - 参数内容: choiceName=%s, description=%s", 
                tostring(arguments.choiceName), 
                tostring(arguments.description)))
        end
        
        local success, result = BM_LlmTool:ExecuteTool(toolName, arguments)
        
        if not success then
            print(string.format("  - ❌ 工具执行失败: %s", tostring(result)))
        else
            print(string.format("  - ✅ 工具执行成功"))
        end
        
        table.insert(results, {
            tool_call_id = toolCall.id,
            role = "tool",
            name = toolName,
            content = json.encode(result)
        })
    end
    
    return results
end

return LlmToolSystem


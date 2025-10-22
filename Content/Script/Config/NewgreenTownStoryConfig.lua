---新绿镇故事配置
---这是一个完整的故事配置示例，展示如何配置时间循环叙事游戏
---@return table 故事配置数据
local function GetNewgreenTownConfig()
    return {
        -- ==================== 游戏背景 ====================
        background = {
            text = [[
在一个名为"新绿镇"（Newgreen）的架空小镇上，生活着一群性格鲜明的居民。
你和你的"宿敌"——前同事兼死对头"雷克斯·普鲁特"（Rex Prout）——因一场职场争执结下梁子。
雷克斯是个自诩"天才"的偏执狂，坚信世界需要"重置"，而新绿镇就是他理想的实验场。

某日，雷克斯秘密策划了一场"生态净化灾难"：他打算释放一种他研发的"超级除草剂"到镇上的供水系统，
声称这能让"人类回归自然"，实则会导致全镇居民在48小时内陷入植物化昏迷。

你意外得知计划，试图阻止，但失败，与全镇人一同"叶化"死亡。
然后——你重生了。
更糟的是，雷克斯也记得一切。

于是，你们陷入一场"宿命般的喜剧对决"：你阻止他搞事，他变着花样搞事，
直到某一次，你让他意识到：也许世界不需要"净化"，只需要一个朋友。
]],
            theme = "时间循环喜剧",
            mainConflict = "阻止宿敌的荒诞灾难计划，并最终化解心结"
        },
        
        -- ==================== 场景配置 ====================
        scenes = {
            -- 场景1：社区中心
            {
                id = "scene_center",
                name = "新绿镇社区中心",
                description = "多功能社区空间，有咖啡角、公告板、雷克斯的'天才实验室'（用纸箱和LED灯搭成）。",
                atmosphere = "背景播放轻快爵士乐，墙上贴着'本周环保挑战：不用塑料吸管！'",
                npcIds = {"rex", "maggie", "bean"},
                
                -- 【新增】场景抉择生成指导
                choiceGuidance = {
                    -- 允许的抉择类型
                    allowedTypes = {
                        "调查类",  -- 调查环境、物品、可疑痕迹
                        "对话类",  -- 深入询问某个NPC
                        "行动类",  -- 在场景内执行某个行动
                        "转场类"   -- 前往其他场景
                    },
                    
                    -- 抉择生成约束
                    constraints = {
                        "抉择必须与社区中心的环境相关",
                        "可以调查雷克斯的实验室及其可疑装置",
                        "可以询问玛吉阿姨关于镇上的八卦消息",
                        "可以偷听小豆（鹦鹉）的吐槽获取线索",
                        "不能生成与公园、户外活动相关的抉择（那属于其他场景）"
                    },
                    
                    -- 推荐的抉择示例（供AI参考）
                    examples = {
                        "调查实验室",    -- 调查雷克斯的天才实验室
                        "询问玛吉",      -- 询问玛吉阿姨最近的八卦
                        "偷看笔记",      -- 偷看雷克斯的实验笔记
                        "跟踪雷克斯",    -- 暗中跟踪雷克斯的行动
                        "搭讪小豆",      -- 试图从鹦鹉那里套话
                        "前往公园"       -- 转场到中央公园调查
                    }
                }
            },
            
            -- 场景2：中央公园
            {
                id = "scene_park",
                name = "新绿镇中央公园",
                description = "绿树成荫的公园，有喷泉、长椅、儿童游乐区。角落有个'生态冥想亭'（雷克斯搭建的可疑装置）。",
                atmosphere = "背景有松鼠在偷吃游客三明治",
                npcIds = {"rex", "old_joe", "pigeons"},
                
                -- 【新增】场景抉择生成指导
                choiceGuidance = {
                    -- 允许的抉择类型
                    allowedTypes = {
                        "调查类",  -- 调查生态冥想亭等可疑装置
                        "对话类",  -- 询问老乔或鸽子群
                        "行动类",  -- 破坏装置、设置陷阱等
                        "转场类"   -- 前往其他场景
                    },
                    
                    -- 抉择生成约束
                    constraints = {
                        "抉择必须与公园环境和户外活动相关",
                        "可以调查雷克斯的生态冥想亭装置",
                        "可以询问老乔关于天气异常的观察",
                        "可以试图从鸽子群获取神秘信息",
                        "不能生成室内调查类抉择（那属于社区中心）"
                    },
                    
                    -- 推荐的抉择示例
                    examples = {
                        "调查冥想亭",    -- 检查生态冥想亭装置
                        "询问老乔",      -- 问老乔关于异常的观察
                        "跟鸽子谈判",    -- 试图从鸽子群获取情报
                        "破坏装置",      -- 破坏雷克斯的可疑装置
                        "埋伏守候",      -- 在公园埋伏等雷克斯出现
                        "回社区中心"     -- 转场回社区中心
                    }
                }
            }
        },
        
        -- ==================== NPC模板 ====================
        npcs = {
            -- 主要NPC：雷克斯·普鲁特
            {
                id = "rex",
                name = "雷克斯·普鲁特",
                role = "enemy",
                personality = "偏执狂天才，自诩拯救世界但内心孤独",
                motivation = "通过'净化世界'证明自己的价值，渴望被认同",
                background = [[
前同事，因职场争执与玩家结怨。
童年时常被嘲笑为"怪胎"，从此偏执地追求"完美世界"。
实际上他只是想要一个朋友，但不知道如何表达。
]],
                dialogueStyle = "挑衅、炫耀成就、偶尔流露孤独和脆弱",
                initialStates = {
                    trust = -20,    -- 初始不信任玩家
                    emotion = -10,  -- 略微焦虑
                    relation = -50  -- 敌对关系
                },
                tags = {"genius", "lonely", "dangerous"}
            },
            
            -- 次要NPC：玛吉阿姨
            {
                id = "maggie",
                name = "玛吉阿姨",
                role = "ally",
                personality = "热心但糊涂的邻居阿姨",
                motivation = "关心镇上的每个人（尽管经常帮倒忙）",
                background = "镇上的'消息中转站'，喜欢八卦但也会提供关键线索。",
                dialogueStyle = "热情、啰嗦、经常说错话但本意善良",
                initialStates = {
                    trust = 50,
                    emotion = 20,
                    relation = 60
                },
                tags = {"helpful", "gossipy"}
            },
            
            -- 次要NPC：小豆（鹦鹉）
            {
                id = "bean",
                name = "小豆",
                role = "neutral",
                personality = "毒舌鹦鹉，雷克斯的宠物",
                motivation = "吃瓜子，吐槽主人",
                background = "雷克斯领养的鹦鹉，是唯一了解他内心的'朋友'。",
                dialogueStyle = "吐槽、讽刺、偶尔泄露秘密",
                initialStates = {
                    trust = 0,
                    emotion = 0,
                    relation = 0
                },
                tags = {"sarcastic", "know_secrets"}
            },
            
            -- 次要NPC：老乔
            {
                id = "old_joe",
                name = "老乔",
                role = "neutral",
                personality = "退休气象学家，喜欢讲冷笑话",
                motivation = "观察天气异常，保护小镇",
                background = "总穿雨衣（即使晴天），对环境变化敏锐。",
                dialogueStyle = "冷静、专业、时不时讲个冷笑话",
                initialStates = {
                    trust = 30,
                    emotion = 10,
                    relation = 20
                },
                tags = {"observant", "knowledgeable"}
            },
            
            -- 次要NPC：公园鸽群
            {
                id = "pigeons",
                name = "公园鸽子群",
                role = "neutral",
                personality = "集体说话，语调整齐如合唱团",
                motivation = "传递加密信息，偶尔绑架玩家帽子",
                background = "神秘的鸽子群，似乎知道一些秘密。",
                dialogueStyle = "整齐划一、神秘、偶尔恶作剧",
                initialStates = {
                    trust = 0,
                    emotion = 0,
                    relation = 0
                },
                tags = {"mysterious", "prankster"}
            }
        }
        
        -- ==================== 抉择模板 ====================
        -- 注意：场景抉择现在全部由AI动态生成，不再使用固定配置
        -- 以下为参考的抉择示例（已禁用）：
        --[[
        choices = {
            -- 示例：揭发雷克斯的计划
            {
                id = "choice_reveal_plan",
                name = "揭发雷克斯的计划",
                description = "向镇长揭发雷克斯的灾难计划，试图让他被捕。",
                effects = {
                    npcStates = { rex = { trust = -20, emotion = -30 } }
                }
            }
        }
        --]]
    }
end

return GetNewgreenTownConfig()


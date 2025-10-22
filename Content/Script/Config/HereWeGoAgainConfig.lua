---HereWeGoAgain 游戏配置
---定义游戏的世界观、规则和初始化参数

local HereWeGoAgainConfig = {
    -- 游戏世界观设定（System级别，所有AI都会携带）【已精简】
    gameWorld = [[
# 时间循环游戏
玩家和仇人陷入轮回，双方保留记忆。仇人制造灾难让所有人死亡，玩家需阻止。
- 灾难发生→重生；灾难阻止但仇人自杀→重生；仇人放弃→游戏结束
- 风格：幽默荒诞，紧张中带轻松
]],

    -- 游戏规则（AI行为约束）【已精简】
    gameRules = [[
## AI规则
- 幽默优先，避免沉重和恐怖
- 保持悬念，给予线索
- 尊重记忆设定（玩家和仇人记得，NPC不记得）
- 回复简洁（1-3句话）
]],

    -- 玩家初始身份【已精简】
    playerIdentity = [[
普通人，保留循环记忆。目标：阻止灾难，让仇人放弃。
]],

    -- 仇人初始设定
    enemyDefault = {
        name = "???(未知)",  -- 第一次循环时，玩家不知道是谁
        personality = "狡猾、执着、带点神经质，但也有可笑的一面",
        motive = "对世界的绝望和报复心理，但具体原因未知",
        initialMemory = "这是我的计划的第一次执行...这次一定要成功。"
    },

    -- 游戏初始参数
    initialState = {
        loopCount = 1,           -- 初始循环次数
        sceneType = "校园",      -- 默认场景类型，可选："校园"/"公司"/"社区"/"架空世界"
        disasterType = "爆炸",   -- 默认灾难类型，可选："爆炸"/"中毒"/"灾害"/"其他"
        relationship = "陌生",   -- 玩家与仇人的初始关系
        difficulty = "normal"    -- 难度：easy/normal/hard
    },

    -- ChatType 使用场景映射（便于开发者理解）
    chatTypeUsage = {
        loop_disaster_generate = "每次循环开始时，生成本次的灾难计划",
        enemy_interaction = "玩家与仇人对话或交互",
        investigation = "玩家调查线索、搜索环境",
        critical_choice = "玩家做出关键决策（阻止灾难、对抗仇人等）",
        loop_summary = "循环结束时的总结和重生提示",
        npc_chat = "与普通NPC对话，获取信息"
    },

    -- 调试选项
    debug = {
        enabled = false,          -- 是否开启调试模式
        startLoop = 1,            -- 从第几次循环开始
        skipIntro = false,        -- 是否跳过开场
        showAllClues = false,     -- 是否显示所有线索
        godMode = false           -- 无敌模式（测试用）
    }
}

return HereWeGoAgainConfig


-- Story Library Configuration
-- Define all available stories metadata
-- 故事库配置 - 定义所有可用故事的元数据

return {
    stories = {
        -- Story 1: 囧囧的校园循环解谜（校园社死时间循环）
        {
            id = "story_school",
            title = "囧囧的校园奇遇",
            titleEn = "Jojo's Campus Loop",
            description = "你是大一新生囧囧，在迎新晚会抽中大奖却遭遇史诗级社死！更离奇的是，你陷入了时间循环，反复经历这场噩梦。唯一的出路：揪出策划这一切的凶手，打破循环！",
            descriptionDetail = [[
【故事背景】校园 | 现代 | ACG文化
【核心冲突】抽奖大奖竟是低俗漫画原稿 → 全校社死 → 时间循环
【主要角色】文艺委员小雅（唯一凶手）、班长阿明、漫画社小峰等
【解谜机制】搜集证据、识破伪装、揭穿阴谋、摧毁循环媒介
【情感主题】无心冒犯的代价、创作理念的冲突、社交恐惧与成长]],
            tags = {"time_loop", "campus", "mystery", "social_death", "single_culprit", "modern_china", "acg_culture"},
            difficulty = "Medium",
            estimatedTime = "2-3小时",
            configPath = "Config.SchoolJojoConfig",
            thumbnail = "",
            
            -- 额外元数据
            playerCharacter = "囧囧（大一新生，漫画爱好者）",
            mainAntagonist = "小雅（文艺委员，魔法使用者）",
            loopMechanic = "单人循环（只有玩家记得）",
            endingCondition = "找出凶手、搜集证据、揭穿阴谋、摧毁循环媒介",
            themes = {"社交恐惧", "创作理念冲突", "无心伤害的后果", "校园人际关系"},
            recommended = true  -- 推荐新手从这个故事开始
        },
        
        -- Story 2: 洛阳帽妖灾劫（古代时间循环悬疑喜剧）
        {
            id = "story_luoyang",
            title = "洛阳帽妖灾劫",
            titleEn = "Luoyang Hat Demon Disaster",
            description = "大唐开元年间，你是洛阳府衙九品推官沈砚。城中突发'帽妖食人'流言引发全城暴乱，你与全城官吏葬身火海。重生后发现文书柳珩也带着记忆循环，他要借流言复仇，你必须在七日内阻止灾难！",
            descriptionDetail = [[
【故事背景】唐朝洛阳 | 古代官场 | 民间流言
【核心冲突】帽妖流言 → 全城暴乱 → 府衙被围 → 火海覆灭
【主要角色】柳珩（落榜文书，带记忆）、李文书（老油条）、王捕头（粗线条衙役）
【双循环机制】你与柳珩都记得循环，明暗对抗，斗智斗勇
【情感主题】前世误会、科举冤屈、玉石俱焚的执念、化解仇怨]],
            tags = {"time_loop", "ancient_china", "revenge", "dual_memory", "mystery", "historical", "comedy"},
            difficulty = "Medium",
            estimatedTime = "2-3小时",
            configPath = "Config.LuoyangStoryConfig",
            thumbnail = "",
            
            -- 额外元数据
            playerCharacter = "沈砚（九品推官，寒门学子）",
            mainAntagonist = "柳珩（府衙文书，落榜书生，带记忆）",
            loopMechanic = "双人循环（你与柳珩都记得，明暗对抗）",
            endingCondition = "阻止帽妖流言传播、化解前世仇怨、拆穿复仇计划",
            themes = {"科举冤屈", "前世孽缘", "流言的力量", "复仇与救赎", "官场人情"},
            recommended = false
        },
        
        -- Story 3: 黑水镇纵火案（美国小镇连环纵火悬疑）
        {
            id = "story_blackwater",
            title = "黑水镇·1998",
            titleEn = "Blackwater Arson Case",
            description = "1998年，美国中西部工业废镇。你是菜鸟警员艾登，刚报到就遭遇连环纵火案。旧书店老板艾萨克以'审判者'自居，计划引爆煤气站毁灭全镇。你们都带着循环记忆，这是一场猫鼠游戏！",
            descriptionDetail = [[
【故事背景】1998美国 | 工业废镇 | 破败社区
【核心冲突】连环纵火 → 煤气站爆炸 → 全镇覆灭
【主要角色】艾萨克（旧书店老板，带记忆）、杰克（搭档，会牺牲）、铜哨（流浪汉头目）
【双循环机制】你与艾萨克都记得循环，他享受你挣扎的过程，故意留线索
【解谜核心】不是暴力破解密码，而是理解他的心理创伤，找到他的真实生日
【情感主题】贫民窟童年创伤、自我毁灭、救赎与理解]],
            tags = {"time_loop", "arson", "cat_and_mouse", "dual_memory", "psychological", "america_1998", "tragedy"},
            difficulty = "Hard",
            estimatedTime = "3-4小时",
            configPath = "Config.BlackwaterStoryConfig",
            thumbnail = "",
            
            -- 额外元数据
            playerCharacter = "艾登·莫里斯（菜鸟警员，24岁）",
            mainAntagonist = "艾萨克·格雷（旧书店老板，高智商纵火犯，带记忆）",
            loopMechanic = "双人循环（你与艾萨克都记得，猫鼠游戏）",
            endingCondition = "理解艾萨克的心理创伤、推导出密码（真实生日）、解除定时装置",
            themes = {"童年创伤", "自我毁灭", "心理博弈", "理解与救赎", "小镇悲歌"},
            recommended = false  -- 难度较高，适合有经验的玩家
        }
    },
    
    -- ==================== 故事库元信息 ====================
    meta = {
        version = "1.0.0",
        lastUpdate = "2025-10-21",
        totalStories = 3,
        
        -- 推荐游玩顺序
        recommendedOrder = {
            "story_school_jojo",    -- 推荐首玩：难度适中，机制简单，故事轻松
            "story_luoyang",         -- 进阶：双循环机制，古代背景
            "story_blackwater"       -- 挑战：高难度，心理博弈，解谜复杂
        },
        
        -- 难度说明
        difficultyLevels = {
            Easy = "简单 - 适合新手，线索明显，机制简单",
            Medium = "中等 - 需要一定推理能力，多次循环试错",
            Hard = "困难 - 复杂解谜，心理博弈，需深度理解角色"
        },
        
        -- 循环机制类型说明
        loopMechanics = {
            single = "单人循环 - 只有玩家记得循环内容",
            dual_cooperative = "双人循环·合作 - 玩家与NPC都记得，合作破局",
            dual_antagonistic = "双人循环·对抗 - 玩家与敌对NPC都记得，明暗博弈"
        }
    }
}

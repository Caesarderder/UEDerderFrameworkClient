---囧囧的校园循环解谜故事配置
---@return table 故事配置数据
local function GetSchoolJojoConfig()
    return {
        -- ==================== 展示层（玩家可见） ====================
        display = {
            storyBackground = [[
【囧囧的校园奇遇】
大一新生囧囧，ACG爱好者，参加学校迎新晚会。据说抽奖大奖是"24k纯金硬币"，全校沸腾。
你刚整理完漫画社的收藏，准备去碰碰运气...总觉得今晚会发生什么特别的事。
]],
            
            playerSetting = [[
【身份】囧囧，18岁，大一新生，漫画社成员，ACG爱好者，有点社恐
【特点】收藏小众漫画，有"不想让人知道"的创作；期待晚会，想认识朋友
【日常】上课、社团活动、整理收藏、熬夜补番
]],
            
            characters = {
                { name = "小雅", title = "文艺委员", firstImpression = "你曾点评她作品'有点刻意'，她笑着说没关系，但气氛微妙。最近很积极帮晚会布置。" },
                { name = "阿明", title = "班长", firstImpression = "认真负责，关心同学。提醒你别沉迷漫画。最近忙晚会组织工作。" },
                { name = "小峰", title = "漫画社成员", firstImpression = "热血漫画风，觉得你'太小众'，你觉得他'太商业'。正常理念分歧。" },
                { name = "张老师", title = "辅导员", firstImpression = "严格，曾没收你的漫画原稿。说'大学不是来玩的'。" },
                { name = "漫画社社长", title = "社团负责人", firstImpression = "大三学长，认识赞助商，说'金硬币不简单'。对社员很照顾。" }
            },
            
            locations = {
                { name = "迎新晚会礼堂", description = "舞台中央抽奖箱，同学们讨论金硬币", atmosphere = "热闹期待", characters = {"小雅", "阿明", "小峰", "同学"} },
                { name = "囧囧的宿舍", description = "书桌漫画手办，柜子藏私密收藏", atmosphere = "私密空间", characters = {"室友"} },
                { name = "漫画社活动室", description = "海报、作品、复印机。纸张墨水味", atmosphere = "创意自由", characters = {"小雅", "小峰", "社长"} },
                { name = "校园论坛", description = "线上社交，热议晚会和金硬币", atmosphere = "虚拟热闹", characters = {"全校匿名"} }
            },
            
            initialClues = {
                "迎新晚会抽奖大奖是24k纯金硬币", "社长说硬币不简单", "小雅最近很积极帮晚会", 
                "阿明负责晚会组织", "小峰觉得你太小众", "张老师没收过你漫画", "宿舍藏私密收藏"
            },
            
            openingHints = {

                                "晚会是认识朋友的好机会", "金硬币引起全校关注", "小雅态度有点奇怪", "收藏别让太多人知道"
            }
        },
        
        background = {
            text = [[
你抽中"金硬币"大奖，打开却是你的低俗漫画原稿！全校社死，照片传遍论坛。
第二天醒来时间回到晚会当天早上！陷入循环。

真相：文艺委员小雅是凶手，因你点评她"风格刻意"怀恨在心。她掌握神秘学能力，精心策划：
偷宿舍原稿→伪造抽奖箱→金硬币是循环媒介。阿明、小峰、张老师是干扰项。
必须循环搜证，揭穿小雅，摧毁循环媒介！
]],
            theme = "校园时间循环悬疑",
            mainConflict = "找出凶手小雅，揭穿阴谋，摧毁循环媒介"
        },
        
        scenes = {
            {
                id = "scene_party_hall",
                name = "迎新晚会礼堂",
                description = "舞台中央抽奖箱，同学窃窃私语。小雅在人群中看向舞台，嘴角微笑",
                atmosphere = "热闹兴奋暗藏危机，循环触发点",
                npcIds = {"xiaoya", "aming", "xiaofeng", "students"},
                initialState = [[
【当前状态】你中奖了！主持人递来礼盒，沉甸甸的。
- 全校同学期待看着你
- 主持人等你拆奖拍照
- 后排举起手机拍视频
- 你心跳加速，紧张兴奋
]],
                defaultChoice = {
                    text = "当场打开礼盒（在众人注视下拆开大奖）",
                    type = "行动类",
                consequence = "触发社死事件，但能第一时间观察小雅和周围人的反应你抽中'金硬币'大奖，打开却是你的低俗漫画原稿！全校社死，照片传遍论坛。第二天醒来时间回到晚会当天早上！陷入循环。",
                    isDestructive = true
                },
                choiceGuidance = {
                    types = {"观察类", "对话类", "行动类", "取证类", "转场类"},
                    focus = "晚会抽奖环节，观察小雅反应，检查抽奖箱经手人，是否当场拆奖"
                }
            },
            
            {
                id = "scene_dorm",
                name = "囧囧的宿舍",
                description = "书桌漫画画稿，柜子藏低俗原稿。桌上礼盒（如果带回来）",
                atmosphere = "私密安全，也是小雅潜入的犯罪现场",
                npcIds = {"roommates"},
                initialState = [[
【当前状态】回到宿舍，室友还在外面
- 书桌：漫画收藏、画稿、海报
- 柜子：私密收藏
- 桌上礼盒（如果带回）
]],
                defaultChoice = {
                    text = "在宿舍里打开礼盒（私密空间，避免公开场合）",
                    type = "行动类",
                    consequence = "避免社死但失去观察小雅反应的机会，不过能安全地查看内容物",
                    isDestructive = false
                },
                choiceGuidance = {
                    types = {"调查类", "取证类", "对话类", "行动类", "转场类"},
                    focus = "检查原稿细节(蝴蝶标记)，门锁痕迹，安装监控，询问室友可疑人"
                }
            },
            
            {
                id = "scene_club_room",
                name = "校园漫画社活动室",
                description = "海报，作品展示架，老旧复印机(使用登记)。小雅、小峰的手稿，你的存放柜",
                atmosphere = "创意自由，暗藏线索，小雅接触原稿和复印机的关键场所",
                npcIds = {"xiaoya", "xiaofeng", "president"},
                initialState = [[
【当前状态】进入活动室
- 小雅整理手稿、小峰翻漫画、社长处理事务
- 复印机有使用登记、你的存放柜在窗边
]],
                defaultChoice = {
                    text = "检查自己的存放柜（确认漫画原稿是否被动过）",
                    type = "调查类",
                    consequence = "可能发现原稿被偷的证据，但要小心不要引起其他人的注意",
                    isDestructive = false
                },
                choiceGuidance = {
                    types = {"调查类", "对话类", "取证类", "行动类", "转场类"},
                    focus = "复印机使用记录，小雅手稿对比风格，询问社长赞助商，检查存放柜"
                }
            },
            
            {
                id = "scene_forum",
                name = "校园论坛/社交平台",
                description = "虚拟空间，匿名实名讨论。社死后刷屏嘲讽。小雅可能有隐藏账号",
                atmosphere = "虚拟喧嚣，舆论传播和线索挖掘场所",
                npcIds = {"xiaoya_anonymous", "students_online"},
                initialState = [[
【当前状态】打开论坛
如果社死：刷屏嘲讽照片，私信爆炸
如果未发生：讨论晚会期待金硬币
你可以：小号发帖引导，搜索账号，破解相册，下载证据
]],
                defaultChoice = {
                    text = "搜索关键词（搜索与抽奖、漫画、小雅相关的帖子）",
                    type = "调查类",
                    consequence = "可能发现隐藏的线索或可疑的匿名账号",
                    isDestructive = false
                },
                choiceGuidance = {
                    types = {"调查类", "对话类", "取证类", "行动类", "转场类"},
                    focus = "小号引导讨论风格，搜索小雅账号，破解隐藏相册，分析匿名回复"
                }
            }
        },
        
        npcs = {
            {
                id = "xiaoya",
                name = "小雅",
                role = "enemy",
                personality = "表面温柔，实则偏执敏感，极在意创作评价，受挫报复",
                motivation = "因囧囧评'风格刻意'怀恨，策划时间循环让囧囧反复社死",
                background = "文艺委员，掌握神秘学。策划：偷配钥匙潜入偷原稿→替换抽奖箱→仿制金硬币(循环媒介)→复印机留蝴蝶标记→制造社死+时间循环。利用阿明、小峰、张老师做干扰项",
                dialogueStyle = "温柔轻声，谈创作露偏执，戳穿后崩溃",
                initialStates = { trust = 20, emotion = -30, relation = -70 },
                tags = {"mastermind", "vengeful", "magic_user"}
            },
            
            { id = "aming", name = "阿明", role = "neutral", personality = "认真负责单纯，易被利用，关心同学",
                motivation = "履行班长职责，关心囧囧（被小雅误导）", background = "班长负责晚会。被小雅利用协助处理抽奖箱成嫌疑人。不知阴谋，可拉拢",
                dialogueStyle = "认真诚恳，像老妈子唠叨", initialStates = { trust = 50, emotion = 10, relation = 40 }, tags = {"ally_potential"} },
            { id = "xiaofeng", name = "小峰", role = "neutral", personality = "热血冲动直接自负",
                motivation = "证明热血漫画才是王道", background = "漫画社活跃，与囧囧理念冲突。小雅嫁祸他复印机。干扰项嫌疑人",
                dialogueStyle = "说话快语气冲易激动，嘴硬心软", initialStates = { trust = 10, emotion = 0, relation = -10 }, tags = {"red_herring"} },
            { id = "zhangteacher", name = "张老师", role = "neutral", personality = "严格，为学生好但方式直接",
                motivation = "希望学生专注学业", background = "辅导员，没收过囧囧漫画。小雅利用这矛盾制造'老师报复'假象。干扰项",
                dialogueStyle = "严肃教育口吻恨铁不成钢", initialStates = { trust = 30, emotion = -5, relation = 20 }, tags = {"red_herring"} },
            { id = "president", name = "漫画社社长", role = "ally", personality = "随和友善人脉广",
                motivation = "经营社团，维护赞助商关系", background = "大三学长，小雅远亲。通过他小雅了解赞助商和金硬币。被蒙鼓里",
                dialogueStyle = "笑呵呵随和，爱分享八卦", initialStates = { trust = 60, emotion = 15, relation = 50 }, tags = {"informative"} },
            { id = "xiaoya_anonymous", name = "神秘网友", role = "enemy", personality = "匿名大胆，过度了解内幕",
                motivation = "观察舆论，享受操控", background = "小雅隐藏账号。隐藏相册有偷拍照片和循环实验日志(铁证)",
                dialogueStyle = "匿名犀利，露破绽", initialStates = { trust = 0, emotion = -20, relation = -70 }, tags = {"evidence_holder"} },
            { id = "students", name = "围观同学", role = "neutral", personality = "八卦跟风", motivation = "看热闹传八卦",
                background = "社死围观者传播者", dialogueStyle = "嘈杂跟风", initialStates = { trust = 20, emotion = 10, relation = 20 }, tags = {"crowd"} }
        },
        
        relationships = {
            { from = "player", to = "xiaoya", type = "无心冒犯", desc = "点评'刻意'触发报复", intensity = -70 },
            { from = "xiaoya", to = "player", type = "报复目标", desc = "策划循环让其反复社死", intensity = -90 },
            { from = "xiaoya", to = "aming", type = "利用", desc = "以帮囧囧为由让他处理抽奖箱成嫌疑人", intensity = 40 },
            { from = "aming", to = "xiaoya", type = "信任", desc = "认为是热心委员", intensity = 50 },
            { from = "player", to = "aming", type = "班长同学", desc = "关心自己，可拉拢", intensity = 40 },
            { from = "aming", to = "player", type = "关心", desc = "担心沉迷漫画(被误导)", intensity = 45 },
            { from = "player", to = "xiaofeng", type = "理念分歧", desc = "觉得他太商业", intensity = -10 },
            { from = "xiaofeng", to = "player", type = "看不惯", desc = "觉得你太小众", intensity = -15 },
            { from = "xiaoya", to = "xiaofeng", type = "嫁祸", desc = "冒用复印机权限", intensity = 20 },
            { from = "player", to = "zhangteacher", type = "师生", desc = "被没收过漫画", intensity = 20 },
            { from = "xiaoya", to = "zhangteacher", type = "烟雾弹", desc = "制造老师报复假象", intensity = 15 },
            { from = "player", to = "president", type = "社团", desc = "可信任学长", intensity = 50 },
            { from = "xiaoya", to = "president", type = "远亲", desc = "通过他了解赞助商金硬币", intensity = 45 },
            { from = "students", to = "player", type = "围观", desc = "八卦传播", intensity = 10 }
        }
    }
end

local function GetDisplayContent()
    local cfg = GetSchoolJojoConfig().display
    return table.concat({
        "━━ 📖 囧囧的校园奇遇 ━━\n", cfg.storyBackground, "\n━━ 👤 你的身份 ━━\n", cfg.playerSetting,
        "\n━━ 🎭 人物 ━━\n", table.concat((function() local t={} for _,c in ipairs(cfg.characters) do table.insert(t, c.name.."("..c.title..")："..c.firstImpression) end return t end)(), "\n"),
        "\n━━ 🏫 地点 ━━\n", table.concat((function() local t={} for _,l in ipairs(cfg.locations) do table.insert(t, l.name.."："..l.description) end return t end)(), "\n"),
        "\n━━ 🔍 已知线索 ━━\n", table.concat(cfg.initialClues, "；"),
        "\n━━ 💡 提示 ━━\n", table.concat(cfg.openingHints, "；"),
        "\n\n💬 你的校园故事，从这里开始..."
    }, "")
end

local exports = GetSchoolJojoConfig()
exports.GetDisplayContent = GetDisplayContent
return exports


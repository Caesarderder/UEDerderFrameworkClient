---黑水镇纵火案故事配置
---@return table 故事配置数据
local function GetBlackwaterStoryConfig()
    return {
        display = {
            storyBackground = [[
【黑水镇·1998】美国中西部，被工业遗弃的破败小镇。
你是新人警员艾登·莫里斯，警校毕业被"发配"到这。废弃钢铁厂、破败社区、煤烟阴雨、犯罪率高。
警长约翰逊冷脸扔给你案卷。你的工作：维持这座垂死小镇的秩序。
]],
            playerSetting = [[
【身份】艾登·莫里斯(Aiden Morris)，24岁，警署巡警，警校毕业
【性格】有正义感但缺经验，渴望证明自己
【日常】处理案卷、巡逻、整理报告
【困扰】镇子比想象破败，警长不看好学院派，搭档杰克说活下来最重要，居民不信任警察
]],
            
            characters = {
                { name = "警长约翰逊", title = "警长", firstImpression = "干了20年的老警察，对学院派冷淡。说'这里没英雄，只有活下来的人'" },
                { name = "杰克·汤普森", title = "同期警员", firstImpression = "搭档，比你早来3个月。乐观友好，你的第一个朋友" },
                { name = "艾萨克·格雷", title = "旧书店老板", firstImpression = "唯一的知识分子，芝加哥大学高材生却回破镇开书店。礼貌但疏离" },
                { name = "铜哨", title = "流浪汉头目", firstImpression = "脖挂铜哨，第一次见是因偷钱包。狡猾但照顾营地流浪汉和孩子" },
                { name = "老麦克", title = "酒馆老板", firstImpression = "'生锈马蹄'酒馆老板，消息灵通，对警察友好，透露小道消息" }
            },
            
            locations = {
                { name = "黑水镇警署", description = "红砖小楼，破旧办公桌，通缉令地图，窗外煤气站", atmosphere = "压抑陈旧，安全区信息点", characters = {"约翰逊", "杰克", "居民"} },
                { name = "'静默之页'旧书店", description = "小巷书店，书架林立，油墨霉味，艾萨克读书", atmosphere = "安静古旧，知识避难所", characters = {"艾萨克"} },
                { name = "废弃钢铁厂仓库区", description = "锈迹厂房，废油桶木材，流浪汉简陋住所", atmosphere = "破败混乱，法律灰色地带", characters = {"铜哨", "流浪汉"} },
                { name = "'生锈马蹄'酒馆", description = "老旧酒馆，烟雾吵闹，老麦克认识所有人", atmosphere = "嘈杂烟火气，打探消息", characters = {"老麦克", "工人"} },
                { name = "中心煤气站", description = "白色储气罐，铁丝网警告标识，机器嗡嗡声", atmosphere = "空旷肃杀不安", characters = {"维修工"} }
            },
            
            initialClues = {
                "犯罪率高，偷窃斗殴", "钢铁厂流浪汉，警长让睁眼闭眼", "书店老板名校高材生回破镇", 
                "杰克说镇子没救但认真巡逻", "警长失去希望"
            },
            
            openingHints = {
                "熟悉街道居民", "跟杰克巡逻了解情况", "警长经验有帮助", "镇子穷但人们努力生活", "也许能做改变"
            }
        },
        
        background = {
            text = [[
菜鸟警员艾登报到遭遇连环纵火案。旧书店老板艾萨克是"审判者"极端分子，策划烧"污秽地"(妓院赌场流浪汉营地)，
最终引爆煤气站让全镇"净化"。煤气站爆炸全镇覆灭。

睁眼重生！艾萨克也带记忆重生，当成"猫鼠游戏"！
他是芝大化学系高材生，因"堕落者应被火焰净化"极端言论被退学。贫民窟童年，父缺母冷，憎恶出身，视黑水镇为罪恶温床，
通过毁灭救赎。你俩循环重生带完整记忆，他享受你挣扎，留线索引导"猜谜"。
你必须阻止他，找密码——煤气站定时装置密码是他心结：真实生日，他想毁灭的是自己。
]],
            theme = "时间循环悬疑推理心理博弈",
            mainConflict = "阻止纵火和爆炸，破解心理创伤，找密码"
        },
        
        scenes = {
            {
                id = "scene_police_station",
                name = "黑水镇警署",
                description = "红砖小楼，办公区，案卷，地图，传真机，窗外煤气站",
                atmosphere = "起点信息枢纽，循环开始",
                npcIds = {"johnson", "jack", "residents"},
                initialState = "【首日8AM】警长冷眼，杰克热情'欢迎新人'，案卷堆桌，地图标区域，窗外煤气站压抑，传真机偶尔响",
                defaultChoice = {
                    text = "与杰克交谈（了解小镇情况和今日任务）",
                    type = "对话类",
                    consequence = "从搭档那里了解黑水镇的基本情况，建立信任关系",
                    isDestructive = false
                },
                choiceGuidance = {
                    types = {"调查类", "对话类", "行动类", "转场类"},
                    focus = "查传真机圣经预言，与杰克商量分开/一起，申请资源，分析纵火案，审讯艾萨克(后期)"
                }
            },
            
            {
                id = "scene_bookstore",
                name = "'静默之页'旧书店",
                description = "小巷书店，书架林立，艾萨克读书，书架后暗格(计划本照片)，化学书籍，刺鼻味",
                atmosphere = "表面平静实则暗藏杀机，心理博弈场",
                npcIds = {"isaac"},
                initialState = "艾萨克柜台读书，温和微笑说'Welcome'，书架后隐约藏东西，化学书籍，刺鼻药品味",
                defaultChoice = {
                    text = "与艾萨克交谈（以借书为由接近他）",
                    type = "对话类",
                    consequence = "开始与艾萨克的心理博弈，可能获取线索，但也可能暴露你的意图",
                    isDestructive = false
                },
                choiceGuidance = {
                    types = {"调查类", "对话类", "行动类", "转场类"},
                    focus = "心理博弈核心，试探动机童年，找书架机关暗格，他知你记得循环会暗示，摊牌'我知道你记得'"
                }
            },
            
            {
                id = "scene_steel_factory",
                name = "废弃钢铁厂仓库区",
                description = "锈迹厂房仓库，油桶木材迷宫，流浪汉破布木板家，铜哨照顾老人孩子，金属锈味柴火烟味，火灾浓烟地狱",
                atmosphere = "破败危险，火灾炼狱",
                npcIds = {"copperWhistle", "homeless"},
                
                -- 场景初始状态
                initialState = [[
【Current Status】Patrolling the abandoned steel factory area

你和杰克一起来到镇西侧的废弃钢铁厂仓库区。
锈迹斑斑的厂房、废弃的油桶和木材、破败的住所映入眼帘。

此时废弃钢铁厂的情况：
- 流浪汉们的简陋住所散落在仓库之间，用破布和木板围成"家"
- 铜哨（脖子上挂着铜哨的年轻流浪汉）正在照顾营地里的孩子
- 空气中弥漫着金属锈味和柴火烟味
- 几个老人坐在破旧的椅子上，神情麻木
- 仓库结构复杂如迷宫，光线昏暗

环境细节：
- 堆满的废弃油桶，有些已经生锈漏油
- 木材和易燃物随处可见
- 破败的结构让这里成为火灾的高危区域
- 阴沉的天空让气氛更加压抑

杰克低声对你说："这里的人都很穷，警长让我们睁一只眼闭一只眼。"
"但你得小心，这里鱼龙混杂，什么人都有。"

作为警员，你来这里可以：
- 与铜哨交谈，了解流浪汉营地的情况
- 例行检查，观察是否有安全隐患
- 询问流浪汉是否见过可疑人员
- 注意任何异常的气味或迹象

你感觉这里隐藏着什么危险...
]],
                
                -- 默认抉择
                defaultChoice = {
                    text = "与铜哨交谈（了解流浪汉营地的情况）",
                    type = "对话类",
                    consequence = "建立与底层社会的联系，铜哨可能成为你的情报员",
                    isDestructive = false
                },
                
                choiceGuidance = {
                    allowedTypes = {
                        "调查类",  -- 调查可疑迹象、燃气味、定时装置
                        "对话类",  -- 与铜哨、流浪汉交流
                        "行动类",  -- 搜救、疏散、调查起火点
                        "转场类"   -- 前往其他场景
                    },
                    
                    constraints = {
                        "抉择必须与钢铁厂和流浪汉营地相关",
                        "可以通过'非做饭时间闻到燃气'判断异常",
                        "可以选择与杰克分开调查（会更快获得线索但杰克可能牺牲）",
                        "可以让铜哨疏散更多人或去调查起火点",
                        "火灾发生后要在浓烟中做出生死抉择",
                        "铜哨可能成为你的情报员和朋友",
                        "不能生成与书店或警署内部相关的抉择（那属于其他场景）"
                    },
                    
                    examples = {
                        "巡逻时注意异常的燃气味",
                        "与铜哨建立信任关系",
                        "询问流浪汉是否见过可疑人员",
                        "发现异常后选择：与杰克分开调查",
                        "火灾发生时：疏散人群还是追踪纵火者",
                        "让铜哨帮忙疏散还是调查起火点",
                        "返回警署报告火灾情况"
                    }
                }
            },
            
            -- 场景4：中心煤气站（终极决战地）
            {
                id = "scene_gas_station",
                name = "中心煤气站",
                description = [[
巨大的白色储气罐矗立在空地上，周围只有铁丝网和警告标识。
这是黑水镇的能源命脉，一旦爆炸，半个镇子会被夷为平地。
后期循环中，你会发现艾萨克在这里安装了定时点火装置。
装置面板上有密码锁——不是普通的数字，而是日期格式。
空旷的场地，巨大的储气罐，滴答作响的定时器，这是最后的战场。
]],
                atmosphere = "空旷、压迫、末日般的紧张感，与时间赛跑",
                npcIds = {"isaac_phantom", "workers"},
                
                -- 场景初始状态
                initialState = [[
【Current Status】Final showdown at the Gas Station

你站在中心煤气站前。
巨大的白色储气罐矗立在空地上，在阴沉的天空下显得格外压抑。

此时煤气站的情况（根据循环进度不同）：
【早期循环】
- 你第一次来到煤气站，只是例行巡逻
- 白色的储气罐静静矗立，周围只有铁丝网和警告标识
- 偶尔能看到维修工人在检查设备
- 一切看起来正常，但你总觉得这里将成为关键

【后期循环】
- 经过多次循环，你终于找到了艾萨克安装的定时点火装置
- 装置就藏在储气罐的维护舱内，伪装得很隐蔽
- 面板上有密码锁——不是普通的数字，而是日期格式（MM/DD/YYYY）
- 定时器滴答作响，显示距离爆炸还有不到30分钟
- 你必须输入正确的密码才能解除装置

环境细节：
- 空旷的场地，除了储气罐几乎没有遮蔽物
- 铁丝网上挂着"危险：易燃易爆"的警告标识
- 远处能看到小镇的轮廓，一旦爆炸，半个镇子会被夷为平地
- 风吹过，发出呜呜的声音，像是末日的哀鸣

你回忆起与艾萨克的所有对话：
- 他的童年创伤：贫民窟长大，父亲缺席，母亲冷漠
- 他对"堕落者"的憎恶
- 他说过的话："火焰是唯一的净化..."
- 暗格中的笔记：他使用的是伪造的身份
- 他的真实生日是...？

这是最后的时刻，你必须做出选择...
]],
                
                -- 默认抉择
                defaultChoice = {
                    text = "调查定时装置（尝试理解密码的含义）",
                    type = "调查类",
                    consequence = "需要综合所有循环的信息，理解艾萨克的心理创伤才能推导出密码",
                    isDestructive = false
                },
                
                choiceGuidance = {
                    allowedTypes = {
                        "调查类",  -- 调查定时装置、密码机制
                        "对话类",  -- 自言自语回忆艾萨克的心理创伤
                        "行动类",  -- 疏散居民、尝试解密、拆除装置
                        "转场类"   -- 前往其他场景（如果还有时间）
                    },
                    
                    constraints = {
                        "抉择必须与煤气站爆炸和终极决战相关",
                        "这是最终场景，需要综合前面所有循环的信息",
                        "密码不是暴力破解，而是理解艾萨克的心理创伤",
                        "可以选择疏散居民（减少伤亡但不能阻止循环）",
                        "可以通过回忆艾萨克的童年故事推导出密码",
                        "密码是他的真实生日（使用的是伪造的身份）",
                        "成功解密需要完成：与杰克同行、多次解密圣经、发现暗格、审讯时聊童年"
                    },
                    
                    examples = {
                        "尝试疏散附近居民",
                        "仔细观察定时装置的密码格式",
                        "回忆与艾萨克的所有对话",
                        "回忆暗格中的照片和笔记",
                        "思考：他想毁灭的到底是什么",
                        "输入他的真实生日（XX/XX/XXXX）",
                        "成功或失败后的选择"
                    }
                }
            }
        },
        
        -- ==================== NPC模板 ====================
        npcs = {
            -- 主要NPC：艾萨克·格雷（纵火犯，仇人）
            {
                id = "isaac",
                name = "艾萨克·格雷",
                role = "enemy",
                personality = "高智商、偏执、以'审判者'自居，表面斯文有礼实则极端扭曲，享受心理博弈",
                motivation = "用火焰'净化'他眼中的'污秽之地'，实际上是在审判和毁灭自己的过去",
                background = [[
芝加哥大学化学系高材生，因发表极端言论被退学。
童年在贫民窟长大，父亲缺席、母亲冷漠，凭借天赋考入名校。
无法摆脱过去的阴影，憎恶自己的出身，将黑水镇视为"罪恶的温床"。
计划用连环纵火案烧毁"污秽之地"，最终引爆煤气站让全镇覆灭。
他也带着完整的循环记忆，把这当成与你的"猫鼠游戏"，享受你挣扎的过程。
每次犯案后会留下圣经名言暗示下次爆炸的时间地点。
]],
                dialogueStyle = "斯文有礼，说话慢条斯理，话里藏着哲学意味和暗示，偶尔流露出对'堕落'的憎恶",
                initialStates = {
                    trust = -50,    -- 极度不信任，视你为游戏对手
                    emotion = 0,    -- 冷静、理性、享受游戏
                    relation = -70  -- 对立关系，但有某种"欣赏"
                },
                tags = {"genius", "pyromaniac", "remember_loop", "twisted", "tragic"}
            },
            
            -- 主要NPC：杰克·汤普森（搭档，会牺牲的朋友）
            {
                id = "jack",
                name = "杰克·汤普森",
                role = "ally",
                personality = "乐观、勇敢、忠诚，虽然知道镇子没救但还是尽职尽责",
                motivation = "保护镇民，帮助新人搭档，做好自己的工作",
                background = [[
比你早来三个月的警员，对小镇很熟悉。
性格乐观开朗，是你在这里的第一个朋友。
每次循环都会在救人时牺牲（如果你选择分开行动）。
他的牺牲是你坚持阻止灾难的重要动力之一。
不记得循环，每次都是全新的杰克。
]],
                dialogueStyle = "爽朗、直接，说话带点幽默，关键时刻很可靠",
                initialStates = {
                    trust = 70,
                    emotion = 20,   -- 友好、热情
                    relation = 60
                },
                tags = {"ally", "brave", "loyal", "tragic"}
            },
            
            -- 次要NPC：警长约翰逊（老警察）
            {
                id = "johnson",
                name = "警长约翰逊",
                role = "neutral",
                personality = "疲惫、经验丰富、对镇子已失去希望但仍坚守岗位",
                motivation = "维持基本秩序，保住饭碗，等待退休",
                background = [[
在黑水镇干了二十年的老警察，见惯了黑暗面。
对新人态度冷淡，但会在关键时刻给出有用建议。
他知道很多小镇的秘密和人际关系。
可以提供资源支持，但需要你展示能力和决心。
不记得循环。
]],
                dialogueStyle = "简短、直接，带着疲惫和讽刺，偶尔会说些老警察的经验之谈",
                initialStates = {
                    trust = 30,
                    emotion = -10,  -- 疲惫、冷漠
                    relation = 20
                },
                tags = {"experienced", "tired", "authority"}
            },
            
            -- 次要NPC：铜哨（流浪汉头目）
            {
                id = "copperWhistle",
                name = "铜哨",
                role = "ally",
                personality = "狡猾但善良，照顾弱者，对社会有不信任但本质不坏",
                motivation = "保护营地的流浪汉们，尤其是孩子们，活下去",
                background = [[
废弃钢铁厂流浪汉营地的'头目'，脖子上挂着一个铜哨。
你第一次遇见他是因为他偷钱包，后来发现是给营地孩子治病。
他可以成为你的情报员和朋友，提供底层社会的消息。
在火灾中你可以救他，或让他帮忙疏散。
不记得循环。
]],
                dialogueStyle = "狡黠、警惕，说话带街头俚语，关键时刻会展现出义气",
                initialStates = {
                    trust = 10,     -- 初始不信任警察
                    emotion = 5,
                    relation = 0
                },
                tags = {"street_smart", "kind", "informant"}
            },
            
            -- 次要NPC：老麦克（酒馆老板，消息灵通人士）
            {
                id = "oldMike",
                name = "老麦克",
                role = "neutral",
                personality = "消息灵通、爱八卦、老练圆滑但本质不坏",
                motivation = "做生意、打探八卦、与各方保持良好关系",
                background = [[
'生锈马蹄'酒馆老板，认识镇上几乎每个人。
可以提供各种小道消息和八卦，是重要的信息源。
对警察态度友好（只要你买酒），乐于分享消息。
不记得循环。
]],
                dialogueStyle = "大嗓门、爱聊天、说话带夸张，喜欢讲故事",
                initialStates = {
                    trust = 40,
                    emotion = 10,
                    relation = 30
                },
                tags = {"talkative", "informant", "neutral"}
            },
            
            -- 特殊状态NPC：艾萨克的心理投影（煤气站自言自语时）
            {
                id = "isaac_phantom",
                name = "心中的艾萨克",
                role = "neutral",
                personality = "是你对艾萨克的理解和推演，帮助你破解他的心结",
                motivation = "作为你的思考工具，帮助你回忆和推导密码",
                background = [[
这不是真实的NPC，而是你在煤气站最终决战时的内心独白。
通过回忆与艾萨克的所有对话、暗格中的笔记、审讯时的童年故事，
你试图理解他的心理创伤，从而推导出密码——他的真实生日。
这是游戏的核心机制：理解仇人，才能阻止灾难。
]],
                dialogueStyle = "这是你的内心独白，回忆和推理的过程",
                initialStates = {
                    trust = 0,
                    emotion = 0,
                    relation = 0
                },
                tags = {"phantom", "puzzle_key"}
            }
        },
        
        -- ==================== 角色关系网 ====================
        relationships = {
            -- 核心关系：艾登 ←→ 艾萨克
            {
                from = "player",
                to = "isaac",
                type = "对手",
                description = "猫鼠游戏的双方，互相知道对方记得循环，心理博弈是核心",
                intensity = -70,
                tags = {"core_conflict", "remember_loop", "cat_and_mouse"}
            },
            {
                from = "isaac",
                to = "player",
                type = "游戏对象",
                description = "将艾登视为游戏对手，享受他挣扎和推理的过程，会故意留线索",
                intensity = -60,
                tags = {"core_conflict", "remember_loop", "enjoys_game"}
            },
            
            -- 搭档关系：艾登 ←→ 杰克
            {
                from = "player",
                to = "jack",
                type = "搭档",
                description = "信任的搭档和朋友，杰克的每次牺牲都是艾登坚持的动力",
                intensity = 70,
                tags = {"ally", "friend", "tragic"}
            },
            {
                from = "jack",
                to = "player",
                type = "搭档",
                description = "友好的同事，愿意帮助新人，信任艾登",
                intensity = 70,
                tags = {"ally", "loyal"}
            },
            
            -- 上下级关系：艾登 ←→ 警长
            {
                from = "player",
                to = "johnson",
                type = "下属",
                description = "需要向警长申请资源和支持，但要先证明自己的能力",
                intensity = 30,
                tags = {"authority", "resource"}
            },
            {
                from = "johnson",
                to = "player",
                type = "上司",
                description = "对新人态度冷淡但会在关键时刻提供帮助，可拉拢",
                intensity = 20,
                tags = {"superior", "experienced"}
            },
            
            -- 信任关系：艾登 ←→ 铜哨
            {
                from = "player",
                to = "copperWhistle",
                type = "从对立到朋友",
                description = "从抓小偷到理解和帮助，铜哨可以成为底层社会的情报员",
                intensity = 40,
                tags = {"ally_potential", "informant", "trust_building"}
            },
            {
                from = "copperWhistle",
                to = "player",
                type = "从警惕到信任",
                description = "初始不信任警察，但如果艾登展现善意会成为朋友",
                intensity = 30,
                tags = {"street_smart", "trust_building"}
            },
            
            -- 信息关系：艾登 ←→ 老麦克
            {
                from = "player",
                to = "oldMike",
                type = "信息来源",
                description = "老麦克是重要的消息渠道，可以提供各种八卦和线索",
                intensity = 40,
                tags = {"informant", "gossip"}
            },
            {
                from = "oldMike",
                to = "player",
                type = "客人",
                description = "警察也是客人，愿意分享消息（尤其是买酒的时候）",
                intensity = 30,
                tags = {"neutral", "talkative"}
            },
            
            -- 仇视关系：艾萨克 ←→ 黑水镇
            {
                from = "isaac",
                to = "town",
                type = "憎恶",
                description = "将黑水镇视为'罪恶的温床'，是他童年阴影的投射",
                intensity = -90,
                tags = {"hatred", "projection", "trauma"}
            }
        },
        
        -- ==================== 关系网可视化数据（可选，供UI展示） ====================
        relationshipGraph = {
            nodes = {
                { id = "player", label = "艾登·莫里斯·菜鸟警员", type = "player" },
                { id = "isaac", label = "艾萨克·格雷·审判者·纵火犯", type = "enemy" },
                { id = "jack", label = "杰克·汤普森·搭档·会牺牲", type = "ally" },
                { id = "johnson", label = "警长约翰逊·老警察·疲惫", type = "neutral" },
                { id = "copperWhistle", label = "铜哨·流浪汉头目·可拉拢", type = "ally" },
                { id = "oldMike", label = "老麦克·酒馆老板·消息灵通", type = "neutral" }
            },
            edges = {
                { from = "player", to = "isaac", label = "猫鼠游戏·心理博弈", color = "red" },
                { from = "player", to = "jack", label = "搭档·朋友·牺牲是动力", color = "green" },
                { from = "player", to = "johnson", label = "下属·需证明能力", color = "blue" },
                { from = "player", to = "copperWhistle", label = "从对立到朋友·情报员", color = "yellow" },
                { from = "player", to = "oldMike", label = "信息来源·八卦", color = "orange" },
                { from = "isaac", to = "player", label = "游戏对象·享受挣扎", color = "red" }
            }
        },
        
        -- ==================== 循环故事线（供LLM参考） ====================
        loopTimeline = {
            {
                loopNumber = 1,
                description = "第一次循环：不知情，被动应对",
                keyEvents = {
                    "报到第一天，不知道即将发生什么",
                    "与杰克一起巡逻，熟悉小镇",
                    "废弃钢铁厂发生火灾，第一次感受到灾难",
                    "连环纵火案爆发，每次都留下圣经名言",
                    "无法阻止，煤气站爆炸，全镇覆灭",
                    "重生，意识到时间循环"
                },
                outcome = "失败，进入第二次循环"
            },
            {
                loopNumber = 2,
                description = "第二次循环：发现艾萨克也记得，意识到这是'游戏'",
                keyEvents = {
                    "重生后意识到循环存在",
                    "试图提前阻止第一场火灾",
                    "发现艾萨克改变了计划（时间和地点都变了）",
                    "意识到艾萨克也有记忆，这是猫鼠游戏",
                    "尝试抓捕艾萨克，成功关押",
                    "但煤气站仍然爆炸（定时装置早已设置）"
                },
                outcome = "失败，意识到必须解除定时装置"
            },
            {
                loopNumber = "3-N",
                description = "多次循环：探索、试错、收集信息",
                keyEvents = {
                    "尝试不同策略：与杰克同行/分开，查看传真机，解密圣经",
                    "去旧书店与艾萨克博弈，寻找书架机关",
                    "发现暗格中的计划本和照片（但本次无法细看）",
                    "下次循环偷看暗格，了解更多信息",
                    "抓捕艾萨克后选择审讯童年而非逼问密码",
                    "逐渐理解他的心理创伤：贫民窟童年、父亲缺席、母亲冷漠"
                },
                outcome = "收集到足够信息，准备最终破局"
            },
            {
                loopNumber = "N+1",
                description = "最终循环：理解艾萨克，破解密码，阻止灾难",
                keyEvents = {
                    "完成所有前置条件：与杰克同行、多次解密圣经、发现暗格、审讯童年",
                    "在煤气站前回忆所有与艾萨克的对话",
                    "理解他想毁灭的不是镇子，而是自己的过去",
                    "推导出密码：他的真实生日（不是伪造身份的生日）",
                    "成功解除定时装置",
                    "循环结束，进入下一个世界"
                },
                outcome = "成功，循环结束"
            }
        }
    }
end

---获取格式化的展示内容（用于UI展示）
---@return string 格式化后的展示文本
local function GetDisplayContent()
    local config = GetBlackwaterStoryConfig()
    local display = config.display
    
    local content = {}
    
    -- 1. 故事背景
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(content, "📖 STORY BACKGROUND")
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(content, display.storyBackground)
    table.insert(content, "")
    
    -- 2. 玩家设定
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(content, "👤 YOUR IDENTITY")
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(content, display.playerSetting)
    table.insert(content, "")
    
    -- 3. 角色介绍
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(content, "🎭 PEOPLE YOU'LL MEET")
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    for i, char in ipairs(display.characters) do
        table.insert(content, string.format("\n【%d. %s】· %s", i, char.name, char.title))
        table.insert(content, string.format("外貌：%s", char.appearance))
        table.insert(content, string.format("第一印象：%s", char.firstImpression))
    end
    table.insert(content, "")
    
    -- 4. 场景介绍
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(content, "🏛️ LOCATIONS")
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    for i, loc in ipairs(display.locations) do
        table.insert(content, string.format("\n【%d. %s】", i, loc.name))
        table.insert(content, loc.description)
        table.insert(content, string.format("氛围：%s", loc.atmosphere))
        table.insert(content, string.format("可遇见：%s", table.concat(loc.characters, "、")))
        table.insert(content, string.format("可以做：%s", loc.activities))
    end
    table.insert(content, "")
    
    -- 5. 初始线索
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(content, "🔍 WHAT YOU KNOW")
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    for i, clue in ipairs(display.initialClues) do
        table.insert(content, string.format("%d. %s", i, clue))
    end
    table.insert(content, "")
    
    -- 6. 开局提示
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(content, "💡 YOUR INSTINCT TELLS YOU...")
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    for i, hint in ipairs(display.openingHints) do
        table.insert(content, string.format("· %s", hint))
    end
    table.insert(content, "")
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(content, "")
    table.insert(content, "💬 Your story begins here...")
    table.insert(content, "")
    table.insert(content, "[ Press START to begin your first day at Blackwater Police Department ]")
    
    return table.concat(content, "\n")
end

-- 导出配置和展示内容
local exports = GetBlackwaterStoryConfig()
exports.GetDisplayContent = GetDisplayContent

return exports


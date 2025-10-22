---洛阳帽妖灾劫故事配置
---这是一个中国古代背景的时间循环叙事游戏
---@return table 故事配置数据
local function GetLuoyangStoryConfig()
    return {
        -- ==================== 展示层（玩家可见） ====================
        display = {
            -- 故事背景（玩家初始视角，不知灾难）
            storyBackground = [[
【洛阳帽妖灾劫】

大唐开元年间，洛阳城。

你是洛阳府衙新上任的九品推官【沈砚】，寒窗十年苦读，终于混得一官半职。
今日是你上任的第三天，府衙的日常公务看起来平静如常——
处理百姓纠纷、审阅案卷、与同僚寒暄...

然而，这座繁华的古都之下，似乎暗流涌动。
城南贫民窟最近流传着奇怪的传闻，有人说夜里见到了"帽妖"的影子...
你的同僚文书柳珩，袖口总是沾着黄色粉末，行为颇为可疑...

这一切，究竟意味着什么？
]],
            
            -- 玩家设定（初始状态）
            playerSetting = [[
【你的身份】
- 姓名：沈砚
- 年龄：二十七岁
- 职位：洛阳府衙九品推官
- 背景：寒门学子，科举五次才中，刚上任三日
- 职责：处理府衙文书、审案断案、维护地方治安
- 性格：谨慎细致，略显书呆子气，但内心正直

【你的日常】
- 上午：在文书房处理公文，与文书们共事
- 下午：巡视城区，了解民情
- 傍晚：回府衙整理案卷，准备次日公务

【你当前的困扰】
- 刚上任不久，对洛阳的人情世故还不太熟悉
- 同僚柳珩似乎对你有些冷淡，不知为何
- 城南最近流传的"帽妖"传闻，不知是否需要调查
]],
            
            -- 角色设定（第一印象，玩家初见时的感受）
            characters = {
                {
                    name = "柳珩",
                    title = "府衙文书",
                    appearance = "书生模样，面容清秀，二十五六岁，常着青衫",
                    firstImpression = "与你同在文书房办公，文笔极佳，但对你态度冷淡。袖口时常沾着黄色粉末，像是某种药材或颜料。最近他总是神神秘秘的，夜里偷偷外出..."
                },
                {
                    name = "李文书",
                    title = "老文书",
                    appearance = "五十岁上下，须发半白，眼神精明，一副见多识广的样子",
                    firstImpression = "在府衙工作二十多年的老油条，对洛阳的人情世故了如指掌。他似乎知道很多官场秘闻，但从不主动说破。对你还算客气，偶尔会点拨几句。"
                },
                {
                    name = "王捕头",
                    title = "衙役头领",
                    appearance = "身材魁梧，络腮胡，大嗓门，腰间挂着佩刀",
                    firstImpression = "负责府衙治安的武官，办事干脆利落但头脑简单。最近总是紧张兮兮，说城南出现了'帽妖'，要求增派人手巡逻。对你这个新来的推官还算尊重。"
                },
                {
                    name = "游方道士",
                    title = "江湖术士",
                    appearance = "道袍破旧，手持拂尘，眼神闪烁不定",
                    firstImpression = "最近出现在城南贫民窟，搭台吆喝兜售'驱邪符'。据说他声称城中有'帽妖食人'，吓得百姓人心惶惶。你怀疑他是江湖骗子，但还没来得及调查。"
                },
                {
                    name = "张阿婆",
                    title = "城南居民",
                    appearance = "年过五旬，满脸皱纹，爱唠叨，嗓门很大",
                    firstImpression = "城南贫民窟的老住户，是当地的'消息灵通人士'。她最近逢人就讲'帽妖食人'的故事，弄得街坊邻居都不敢晚上出门。"
                }
            },
            
            -- 场景设定
            locations = {
                {
                    name = "洛阳府衙·文书房",
                    description = "你的日常办公场所。三间灰瓦房，书案、文牍、墨砚整齐摆放。墙角堆着旧案卷，空气里飘着墨香和纸张的霉味。窗外能听到衙役操练的呼喝声，偶尔有百姓喊冤的声音传来。",
                    atmosphere = "肃穆但不失人情味，是你了解府衙人事的起点",
                    characters = {"柳珩", "李文书", "王捕头"},
                    activities = "处理公文、审阅案卷、与同僚交谈、调查可疑线索"
                },
                {
                    name = "洛阳城南·贫民窟",
                    description = "洛阳城的贫困区域。低矮的土坯房密集排列，街巷狭窄泥泞，空气中混杂着柴火烟味。最近这里流传着'帽妖食人'的传闻，破庙前的空地上时常有游方道士搭台吆喝。",
                    atmosphere = "嘈杂、混乱，百姓们最近似乎有些恐慌",
                    characters = {"游方道士", "张阿婆", "形形色色的贫民"},
                    activities = "巡视民情、调查流言、询问百姓、拆穿骗局"
                },
                {
                    name = "洛阳西郊·古寺废墟",
                    description = "城外西郊的一座废弃古寺，年久失修，香火断绝。断壁残垣，杂草丛生，平时少有人迹。不过，最近夜里似乎有人在那里活动...",
                    atmosphere = "荒凉、神秘，可能隐藏着什么秘密",
                    characters = {"???（需调查后才知）"},
                    activities = "秘密调查、跟踪可疑人物后可能发现此地"
                }
            },
            
            -- 初始线索（玩家开局时已知的信息）
            initialClues = {
                "城南贫民窟最近流传'帽妖食人'的传闻",
                "柳珩袖口时常沾着黄色粉末，行为可疑",
                "王捕头最近神经兮兮，要求增派巡逻",
                "有个游方道士在城南兜售驱邪符",
                "张阿婆逢人就讲帽妖的故事，弄得人心惶惶"
            },
            
            -- 开局提示（引导玩家探索方向）
            openingHints = {
                "作为新任推官，你需要尽快熟悉府衙的工作和同僚",
                "城南的流言可能需要调查，以免引发民众恐慌",
                "柳珩的态度很奇怪，也许可以从李文书那里打听些消息",
                "王捕头虽然迷信，但他的直觉有时很准",
                "这座城市看似平静，但似乎暗流涌动..."
            }
        },
        
        -- ==================== 系统层（LLM使用，玩家不可见） ====================
        -- 游戏背景（完整版，含剧透）
        background = {
            text = [[
你是洛阳府衙的九品推官【沈砚】，寒窗十年才混得一官半职，却在上任第三日遭遇"帽妖灾劫"——
城中突发"席帽精食人"流言，百姓夜不闭户引发骚乱，最终你与全城官吏被失控民众围堵在府衙，葬身火海。

再次睁眼，你竟重生回灾劫发生前七日！
更惊悚的是，你发现同衙的文书【柳珩】也带着记忆重生了！

柳珩本是才华横溢的书生，三次科举落榜后性情大变，认定是朝廷"清流"官员埋没人才，
竟想借"帽妖"流言制造全城混乱，让那些轻视他的权贵一同赴死（暗合"白马之祸"的复仇逻辑）。

而你俩前世的孽缘更妙：上一世你为查案误抓了柳珩的好友，导致其含冤而死，
柳珩便把你也归为"该陪葬的腐朽官吏"。

如今两人带着完整记忆循环重生，他铁了心要复刻灾难，你则必须在七日之内阻止他，
还要掰正他"玉石俱焚"的死脑筋——毕竟每次循环被炸死、烧死、踩踏死的滋味，谁也不想再尝！
]],
            theme = "古代时间循环悬疑喜剧",
            mainConflict = "阻止文书柳珩的帽妖流言计划，化解前世仇怨，避免全城死于暴乱"
        },
        
        -- ==================== 场景配置 ====================
        scenes = {
            -- 场景1：洛阳府衙·文书房（循环初始点）
            {
                id = "scene_yamen_office",
                name = "洛阳府衙·文书房",
                description = [[
三间灰瓦房，书案、文牍、墨砚整齐摆放。柳珩的书桌靠窗，
时常能看到他袖口沾着黄色粉末，桌下藏着卷起的草稿。
墙角堆着旧案卷，空气里飘着墨香和纸张的霉味。
窗外能听到衙役操练的呼喝声，偶尔有百姓喊冤的声音传来。
]],
                atmosphere = "肃穆中带着公务的琐碎感，柳珩总是一脸温和地磨墨抄写，但眼神时而阴郁",
                npcIds = {"liuheng", "liwenshu", "wangcaptain"},
                
                -- 场景初始状态
                initialState = [[
【当前状态】上任第三日，辰时三刻，文书房日常办公

你坐在自己的书案前，案上摆着今日需要处理的文牍。
晨光透过窗格洒在书桌上，墨香和纸张的霉味混杂在空气中。

此时文书房里：
- 柳珩在靠窗的位置磨墨抄写，神情温和，但你注意到他袖口又沾着黄色粉末
- 李文书在整理旧案卷，偶尔抬头看你一眼，似乎有话想说
- 王捕头刚从外面巡逻回来，正向你汇报昨夜城南的情况

环境细节：
- 窗外传来衙役操练的呼喝声
- 墙角堆着成摞的旧案卷
- 柳珩的书桌下似乎藏着卷起的草稿纸

作为新任九品推官，你今日的工作：
- 审阅和处理各类文书案卷
- 与同僚商议府衙事务
- 若有需要，可巡视城区了解民情

柳珩今日看起来比往常更加沉默，你感觉气氛有些微妙...
]],
                
                -- 默认抉择
                defaultChoice = {
                    text = "处理日常公文（开始今日的公务）",
                    type = "行动类",
                    consequence = "按部就班地进行日常工作，但可能错过观察柳珩的机会",
                    isDestructive = false
                },
                
                -- 场景抉择生成指导
                choiceGuidance = {
                    allowedTypes = {
                        "调查类",  -- 调查柳珩的书桌、案卷、可疑物品
                        "对话类",  -- 与柳珩、李文书、王捕头对话
                        "行动类",  -- 搜查证据、拉拢盟友、设置陷阱
                        "转场类"   -- 前往其他场景
                    },
                    
                    constraints = {
                        "抉择必须与府衙文书房的公务环境相关",
                        "可以试探柳珩的计划进度或态度",
                        "可以从李文书处打听官场秘闻和柳珩落榜隐情",
                        "可以借王捕头的职权调查或调走柳珩",
                        "可以搜查柳珩的书桌或案卷寻找证据",
                        "不能生成与城南贫民窟或西郊古寺相关的抉择（那属于其他场景）"
                    },
                    
                    examples = {
                        "直接戳穿柳珩",       -- 摊牌对质
                        "假装抱怨官场黑暗",   -- 套近乎试探
                        "借查案调走柳珩",     -- 利用王捕头
                        "搜查柳珩书桌",       -- 寻找流言草稿
                        "向李文书打听",       -- 了解柳珩落榜内幕
                        "前往城南贫民窟"      -- 转场调查流言源头
                    }
                }
            },
            
            -- 场景2：洛阳城南·贫民窟（流言发源地）
            {
                id = "scene_slum",
                name = "洛阳城南·贫民窟",
                description = [[
低矮的土坯房密集排列，街巷狭窄泥泞，空气中混杂着柴火烟味和腐臭。
破庙前的空地上，时常有游方道士（或和尚）搭台吆喝，兜售"驱邪符"。
墙角贴着告示："近日城中频传帽妖食人，诸位百姓务必小心！"
居民们围在一起窃窃私语，神色惶恐，张阿婆总是第一个传播小道消息。
]],
                atmosphere = "惶恐、迷信、谣言四起，百姓易受煽动，气氛压抑躁动",
                npcIds = {"daoist", "zhangpopo", "liuheng_disguised"},
                
                -- 场景初始状态
                initialState = [[
【当前状态】你来到城南贫民窟巡视

踏入城南贫民窟，泥泞的街巷、密集的土坯房、混浊的空气扑面而来。
这里是洛阳最贫困的区域，也是流言传播最快的地方。

此时贫民窟的情况：
- 破庙前的空地上，一个游方道士（或和尚）正在搭台吆喝
- 道士高声叫卖："驱邪符！护身符！帽妖凶恶，诸位千万小心！"
- 墙角贴着手写的告示："近日城中频传帽妖食人，诸位百姓务必小心！"
- 居民们三五成群聚在一起，窃窃私语，神色惶恐不安

人物动态：
- 张阿婆正逢人就讲"帽妖食人"的故事，绘声绘色
- 有个货郎推着小车叫卖，但你总觉得他的眼神有些闪躲
- 几个孩童躲在屋角，不敢出门玩耍

作为推官，你可以：
- 询问百姓了解流言的具体内容和来源
- 调查那个游方道士是否在蛊惑人心
- 观察周围是否有可疑人员

空气中弥漫着恐慌的气息，你感觉必须尽快查明真相...
]],
                
                -- 默认抉择
                defaultChoice = {
                    text = "询问张阿婆（了解流言的详细内容）",
                    type = "对话类",
                    consequence = "获取流言传播的第一手信息，但可能被她的迷信思维误导",
                    isDestructive = false
                },
                
                choiceGuidance = {
                    allowedTypes = {
                        "调查类",  -- 调查流言来源、假符纸、可疑人员
                        "对话类",  -- 询问道士、张阿婆、伪装的柳珩
                        "行动类",  -- 拆穿骗局、安抚民众、跟踪可疑人员
                        "转场类"   -- 前往其他场景
                    },
                    
                    constraints = {
                        "抉择必须与贫民窟和流言传播相关",
                        "可以当众拆穿道士/和尚的假符纸骗局",
                        "可以向张阿婆讲解帽妖真相（黄磷粉幻象）",
                        "可以识破乔装成货郎的柳珩并对峙",
                        "可以调查流言传播的具体手段和时间线",
                        "不能生成与府衙公务或古寺据点相关的抉择（那属于其他场景）"
                    },
                    
                    examples = {
                        "当众拆穿道士假符",   -- 揭露骗局
                        "给张阿婆讲真相",     -- 科普黄磷粉幻象
                        "假装买货接近柳珩",   -- 识破伪装后对质
                        "跟踪道士找幕后黑手", -- 顺藤摸瓜
                        "散发辟谣告示",       -- 对抗流言
                        "前往西郊废弃古寺"    -- 转场到柳珩据点
                    }
                }
            },
            
            -- 场景3：洛阳西郊·废弃古寺（柳珩的秘密据点）
            {
                id = "scene_temple",
                name = "洛阳西郊·废弃古寺",
                description = [[
断壁残垣，佛像无头，杂草丛生。大殿中央摆着简陋的机关装置：
由连环翻板改造，踩中会弹出"帽妖"形状的纸人，同时释放黄磷粉制造火光幻象。
墙角堆着大量写有谣言的传单，柳珩正对着一张图纸发呆（图纸上是更复杂的机关设计）。
地上散落着科举落榜的榜单，墨迹已褪色，但仍能看出"柳珩"二字落榜在孙山之外。
]],
                atmosphere = "荒凉、诡异、充满柳珩的执念与不甘，空气中弥漫着黄磷的刺鼻味道",
                npcIds = {"liuheng"},
                
                -- 场景初始状态
                initialState = [[
【当前状态】你潜入西郊废弃古寺

经过一番追踪调查，你终于找到了柳珩的秘密据点——西郊这座废弃的古寺。

眼前的景象让你震惊：
- 断壁残垣的大殿中央，摆着一个简陋但精巧的机关装置
- 连环翻板、纸人、黄磷粉...这就是制造"帽妖幻象"的工具！
- 墙角堆着大量手写的谣言传单，笔迹工整，显然经过精心准备
- 地上散落着科举落榜的榜单，"柳珩"二字落榜在孙山之外，墨迹已褪色

柳珩就在这里：
- 他正对着一张图纸发呆，图纸上是更复杂的机关设计
- 神情憔悴但眼神坚定，完全沉浸在自己的世界里
- 空气中弥漫着黄磷的刺鼻味道
- 他似乎已经察觉到你的到来，但没有回头

这是你与柳珩摊牌的关键场所：
- 你可以销毁机关装置，直接阻止他的计划
- 你可以与他深入对话，探究他的动机和心结
- 你可以拿出自己的落榜榜单，尝试情感共鸣
- 你可以承诺帮他申诉考官舞弊的冤情

这里是柳珩的执念所在，也是化解仇怨的最佳场所...
]],
                
                -- 默认抉择
                defaultChoice = {
                    text = "与柳珩对话（尝试了解他的动机和心结）",
                    type = "对话类",
                    consequence = "可能打开他的心扉，但也可能激怒他；这是化解仇怨的关键",
                    isDestructive = false
                },
                
                choiceGuidance = {
                    allowedTypes = {
                        "调查类",  -- 调查机关装置、图纸、落榜榜单
                        "对话类",  -- 与柳珩深入对话，探究动机
                        "行动类",  -- 销毁机关、承诺帮助、情感共鸣
                        "转场类"   -- 返回其他场景
                    },
                    
                    constraints = {
                        "抉择必须与柳珩的内心世界和复仇动机相关",
                        "这里是唯一能与柳珩深度对话的场景，需探究其心结",
                        "可以销毁机关装置阻止计划（但会触发柳珩的激烈反应）",
                        "可以拿出自己的落榜榜单产生情感共鸣",
                        "可以承诺帮他申诉考官舞弊的冤情",
                        "这是核心场景，抉择应围绕'化解仇怨'和'阻止极端行为'展开"
                    },
                    
                    examples = {
                        "销毁机关装置",       -- 直接破坏，激怒柳珩
                        "拿出自己的落榜榜单", -- 情感共鸣
                        "承诺帮他申诉冤情",   -- 提供希望
                        "劝他科举不是唯一出路", -- 价值观引导
                        "揭露考官舞弊内幕",   -- 如果掌握了证据
                        "回府衙文书房"        -- 转场继续调查
                    }
                }
            }
        },
        
        -- ==================== NPC模板 ====================
        npcs = {
            -- 主要NPC：柳珩（文书，仇人）
            {
                id = "liuheng",
                name = "柳珩",
                role = "enemy",
                personality = "才华横溢但怀才不遇，表面温和实则偏执，三次落榜后性情大变，对世道不公充满怨恨",
                motivation = "借'帽妖'流言制造全城混乱，让轻视他的权贵和腐朽官吏一同赴死，为好友和自己的冤屈复仇",
                background = [[
前同事，本是才华横溢的书生，三次科举落榜（其中一次疑似考官舞弊）后性情大变。
上一世，沈砚为查案误抓了柳珩的好友，导致其含冤屈打致死。
柳珩从此把沈砚也归为"该陪葬的腐朽官吏"，认定只有毁灭才能重生。
他也带着完整的循环记忆，会根据玩家的行动不断调整计划。
]],
                dialogueStyle = "表面温和客气，话里藏刀，偶尔流露出对科举制度的愤恨和对好友之死的悲痛",
                initialStates = {
                    trust = -30,    -- 极度不信任玩家
                    emotion = -20,  -- 愤怒与悲痛
                    relation = -60  -- 深仇大恨
                },
                tags = {"genius", "vengeful", "remember_loop", "tragic"}
            },
            
            -- 次要NPC：李文书（老油条同事）
            {
                id = "liwenshu",
                name = "李文书",
                role = "ally",
                personality = "老练圆滑，知晓官场八卦，明哲保身但本质不坏",
                motivation = "保住饭碗，不愿卷入麻烦，但若玩家展现能力可拉拢为盟友",
                background = [[
在府衙摸爬滚打二十年的老文书，什么事都见过，什么人都认识。
知道柳珩落榜的隐情（考官收贿舞弊），也知道沈砚误抓柳珩好友的案件细节。
可以提供关键信息，但需要玩家付出代价或展现信任。
不记得循环，但每次循环的对话内容可能略有不同（基于玩家前几次的行动）。
]],
                dialogueStyle = "圆滑世故，说话留三分，喜欢打太极，但关键时刻会透露有用信息",
                initialStates = {
                    trust = 20,
                    emotion = 0,
                    relation = 30
                },
                tags = {"knowledgeable", "cautious", "informant"}
            },
            
            -- 次要NPC：王捕头（粗线条衙役）
            {
                id = "wangcaptain",
                name = "王捕头",
                role = "neutral",
                personality = "粗线条，武艺不错但头脑简单，极度迷信鬼神",
                motivation = "维护治安，但容易被流言煽动，也容易被权威命令",
                background = [[
府衙武力担当，听从推官命令但不会深究原因。
极度迷信，听到"帽妖"流言会恐慌，但也可能因此被利用。
可以被玩家差遣去调查、抓人或调走柳珩，是可利用的工具人。
不记得循环。
]],
                dialogueStyle = "大嗓门，直来直去，说话带江湖气，容易被唬住",
                initialStates = {
                    trust = 40,     -- 对推官有职业信任
                    emotion = 10,
                    relation = 50
                },
                tags = {"strong", "superstitious", "obedient"}
            },
            
            -- 次要NPC：游方道士/和尚（柳珩的帮凶）
            {
                id = "daoist",
                name = "游方道士",
                role = "enemy",
                personality = "江湖骗子，唯利是图，胆小怕事",
                motivation = "收了柳珩的钱，负责散布谣言和兜售假符，但若被拆穿会立刻逃跑",
                background = [[
收了柳珩一笔钱，按他的指示在城南贫民窟散布"帽妖食人"谣言。
兜售的"驱邪符"是用草纸和红泥冒充的假货。
每次循环可能会换个身份（道士、和尚、算命先生等），但本质是同一个骗子。
若被当众拆穿，柳珩会换其他帮凶。
不记得循环。
]],
                dialogueStyle = "油腔滑调，装神弄鬼，被拆穿后立刻认怂逃跑",
                initialStates = {
                    trust = -10,
                    emotion = 5,    -- 略显紧张（怕露馅）
                    relation = -20
                },
                tags = {"liar", "coward", "hireling"}
            },
            
            -- 次要NPC：张阿婆（流言传播者）
            {
                id = "zhangpopo",
                name = "张阿婆",
                role = "neutral",
                personality = "迷信、爱传小道消息，但本质善良",
                motivation = "关心邻里安危，但容易轻信谣言并四处传播",
                background = [[
城南贫民窟的居民，是第一个传播"帽妖食人"流言的人。
她并非恶意，只是出于恐慌和"好心提醒"。
若玩家能科学解释帽妖真相（黄磷粉幻象），她会半信半疑但不再主动传播。
若被柳珩威胁（某些循环中），她会不敢见玩家。
不记得循环。
]],
                dialogueStyle = "啰嗦、紧张、容易被说服，说话带浓重的市井口音",
                initialStates = {
                    trust = 30,
                    emotion = -15,  -- 恐慌
                    relation = 20
                },
                tags = {"superstitious", "gossip", "kind"}
            },
            
            -- 特殊状态NPC：乔装的柳珩（需识破）
            {
                id = "liuheng_disguised",
                name = "乔装货郎",
                role = "enemy",
                personality = "伪装状态下语气敷衍，眼神闪躲",
                motivation = "在贫民窟监视流言传播效果，确保计划顺利进行",
                background = [[
柳珩乔装成货郎在城南贫民窟活动，监视流言传播情况。
若玩家未识破，他会假装卖货敷衍了事。
若玩家识破（需要足够的观察力或前几次循环的经验），可以直接对质。
这是一个动态NPC，只在特定条件下出现。
实际上就是柳珩本人，共享状态。
]],
                dialogueStyle = "刻意压低声音，假装吆喝，被识破后立刻恢复本来语气",
                initialStates = {
                    trust = -30,
                    emotion = -10,
                    relation = -60
                },
                tags = {"disguised", "watchful", "dangerous"}
            }
        },
        
        -- ==================== 角色关系网 ====================
        relationships = {
            -- 说明：定义角色之间的初始关系
            -- 格式：{ from = "角色A", to = "角色B", type = "关系类型", description = "关系描述", intensity = 强度值 }
            
            -- 核心关系：沈砚 ←→ 柳珩
            {
                from = "player",
                to = "liuheng",
                type = "仇人",
                description = "前世误抓柳珩好友致其含冤而死，今生成为生死仇敌，双方都保留循环记忆",
                intensity = -80,
                tags = {"core_conflict", "remember_loop", "past_grudge"}
            },
            {
                from = "liuheng",
                to = "player",
                type = "复仇目标",
                description = "将沈砚视为腐朽官吏的代表，是必须一同陪葬的对象之一",
                intensity = -80,
                tags = {"core_conflict", "vengeful", "remember_loop"}
            },
            
            -- 衙门关系：沈砚 ←→ 李文书
            {
                from = "player",
                to = "liwenshu",
                type = "同事",
                description = "同在府衙文书房共事，可拉拢为盟友，能提供关键情报",
                intensity = 30,
                tags = {"ally_potential", "informant"}
            },
            {
                from = "liwenshu",
                to = "player",
                type = "上司",
                description = "沈砚是九品推官，李文书是文书，有上下级关系但不明显",
                intensity = 30,
                tags = {"subordinate", "cautious"}
            },
            
            -- 衙门关系：沈砚 ←→ 王捕头
            {
                from = "player",
                to = "wangcaptain",
                type = "上下级",
                description = "推官可以命令捕头办事，是可利用的执行力量",
                intensity = 50,
                tags = {"authority", "tool"}
            },
            {
                from = "wangcaptain",
                to = "player",
                type = "上司",
                description = "听从推官命令，有职业上的服从和信任",
                intensity = 50,
                tags = {"obedient", "loyal"}
            },
            
            -- 隐秘关系：柳珩 ←→ 李文书
            {
                from = "liuheng",
                to = "liwenshu",
                type = "知情者",
                description = "李文书知道柳珩落榜的隐情（考官舞弊）和好友被误抓的案件细节",
                intensity = 10,
                tags = {"knows_secret", "witness"}
            },
            {
                from = "liwenshu",
                to = "liuheng",
                type = "同情但明哲保身",
                description = "知道柳珩的冤屈但不愿深究，保持距离",
                intensity = 10,
                tags = {"knows_secret", "cautious"}
            },
            
            -- 雇佣关系：柳珩 ←→ 游方道士
            {
                from = "liuheng",
                to = "daoist",
                type = "雇主",
                description = "花钱雇佣道士散布帽妖谣言，是幕后黑手",
                intensity = 40,
                tags = {"mastermind", "hireling"}
            },
            {
                from = "daoist",
                to = "liuheng",
                type = "雇员",
                description = "收钱办事，按柳珩指示散布流言和兜售假符",
                intensity = 40,
                tags = {"hired", "accomplice"}
            },
            
            -- 传播链：游方道士 ←→ 张阿婆
            {
                from = "daoist",
                to = "zhangpopo",
                type = "传播者",
                description = "利用张阿婆的迷信和八卦特性，让她成为流言的二级传播者",
                intensity = 20,
                tags = {"manipulator", "spreader"}
            },
            {
                from = "zhangpopo",
                to = "daoist",
                type = "受骗者",
                description = "被道士的假符和恐吓话术欺骗，成为流言传播的帮凶",
                intensity = 20,
                tags = {"victim", "believer"}
            },
            
            -- 监视关系：柳珩伪装 ←→ 张阿婆
            {
                from = "liuheng_disguised",
                to = "zhangpopo",
                type = "暗中观察",
                description = "乔装成货郎监视流言在贫民窟的传播效果",
                intensity = 15,
                tags = {"surveillance", "disguised"}
            },
            
            -- 对立关系：沈砚 ←→ 游方道士
            {
                from = "player",
                to = "daoist",
                type = "调查目标",
                description = "怀疑道士是流言传播的关键人物，需拆穿其骗局",
                intensity = -30,
                tags = {"investigation", "suspect"}
            },
            {
                from = "daoist",
                to = "player",
                type = "威胁",
                description = "推官若调查太深会威胁到他的财路，能跑就跑",
                intensity = -30,
                tags = {"fear", "avoidance"}
            },
            
            -- 劝说关系：沈砚 ←→ 张阿婆
            {
                from = "player",
                to = "zhangpopo",
                type = "劝说者",
                description = "试图向张阿婆解释帽妖真相，阻止流言传播",
                intensity = 25,
                tags = {"persuasion", "education"}
            },
            {
                from = "zhangpopo",
                to = "player",
                type = "半信半疑",
                description = "对推官的话将信将疑，但出于对官府的敬畏会考虑",
                intensity = 25,
                tags = {"uncertain", "respectful"}
            }
        },
        
        -- ==================== 关系网可视化数据（可选，供UI展示） ====================
        relationshipGraph = {
            nodes = {
                { id = "player", label = "沈砚·府衙推官", type = "player" },
                { id = "liuheng", label = "柳珩·落榜冤情", type = "enemy" },
                { id = "liwenshu", label = "李文书·老油条·知官场秘闻", type = "ally" },
                { id = "wangcaptain", label = "王捕头·粗线条·迷信鬼神", type = "neutral" },
                { id = "daoist", label = "游方道士/和尚·散布谣言", type = "enemy" },
                { id = "zhangpopo", label = "张阿婆·谣言受众", type = "neutral" }
            },
            edges = {
                { from = "player", to = "liuheng", label = "前世误抓其好友·今生仇人", color = "red" },
                { from = "player", to = "liwenshu", label = "同事·可拉拢", color = "green" },
                { from = "player", to = "wangcaptain", label = "上下级·可利用", color = "blue" },
                { from = "liuheng", to = "liwenshu", label = "知情", color = "yellow" },
                { from = "liuheng", to = "daoist", label = "雇佣·帮凶", color = "red" },
                { from = "daoist", to = "zhangpopo", label = "利用·传播者", color = "orange" },
                { from = "zhangpopo", to = "daoist", label = "被误导", color = "gray" }
            }
        }
    }
end

---获取格式化的展示内容（用于UI展示）
---@return string 格式化后的展示文本
local function GetDisplayContent()
    local config = GetLuoyangStoryConfig()
    local display = config.display
    
    local content = {}
    
    -- 1. 故事背景
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(content, "📖 故事背景")
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(content, display.storyBackground)
    table.insert(content, "")
    
    -- 2. 玩家设定
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(content, "👤 你的身份与日常")
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(content, display.playerSetting)
    table.insert(content, "")
    
    -- 3. 角色介绍（第一印象）
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(content, "🎭 你遇到的人们")
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    for i, char in ipairs(display.characters) do
        table.insert(content, string.format("\n【%d. %s】· %s", i, char.name, char.title))
        table.insert(content, string.format("外貌：%s", char.appearance))
        table.insert(content, string.format("第一印象：%s", char.firstImpression))
    end
    table.insert(content, "")
    
    -- 4. 场景介绍
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(content, "🏛️ 你可以去的地方")
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
    table.insert(content, "🔍 你已知的线索")
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    for i, clue in ipairs(display.initialClues) do
        table.insert(content, string.format("%d. %s", i, clue))
    end
    table.insert(content, "")
    
    -- 6. 开局提示
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(content, "💡 你的直觉告诉你...")
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    for i, hint in ipairs(display.openingHints) do
        table.insert(content, string.format("· %s", hint))
    end
    table.insert(content, "")
    table.insert(content, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(content, "")
    table.insert(content, "💬 你的故事，从这里开始...")
    
    return table.concat(content, "\n")
end

-- 导出配置和展示内容
local exports = GetLuoyangStoryConfig()
exports.GetDisplayContent = GetDisplayContent

return exports


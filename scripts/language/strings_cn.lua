STRINGS = GLOBAL.STRINGS

STRINGS.NAMES.DEVOURER_PACK = "吞噬者背包" -- 物体在游戏中显示的名字
-- 皮肤名称
STRINGS.SKIN_NAMES.devourer_cats = "吞噬者猫猫"
-- 中文神话版
STRINGS.NAMES.DEVOURER_PACK_NAMES = {
    [1] = "饕餮噬渊者",
    [2] = "烛阴吞界使",
    [3] = "归墟终噬主",
}

STRINGS.CHARACTERS.GENERIC.DESCRIBE.DEVOURER_PACK = "春雨、夏暑、秋凉、冬寒、月亮、暗影" -- 物体的检查描述
STRINGS.RECIPE_DESC.DEVOURER_PACK = "吞噬、吸收、进化。我即是世界" -- 物体的制作栏描述
STRINGS.DP_DEVOUR_ACTION = "吞噬"

STRINGS.DEVOURER_CONTROLS = {
    -- 范围攻击：开关
    AreaAttack = {
        name = "范围攻击",
        options = {
            { text = "关闭", value = 1 },
            { text = "开启", value = 2 }
        },
        order = 1,
        default = 2  -- 默认开启
    },

    -- 反伤：关闭/单体/群体/全开
    Reflect = {
        name = "反伤模式",
        options = {
            { text = "关闭", value = 1 },
            { text = "单体反伤", value = 2 },
            { text = "群体反伤", value = 3 },
            { text = "全开", value = 4 }
        },
        order = 2,
        default = 4  -- 默认全开
    },

    -- 精神状态变化：关闭/暗影/启迪
    SanityChange = {
        name = "精神状态变化",
        options = {
            { text = "关闭", value = 1 },
            { text = "启迪模式", value = 2 },
            { text = "暗影模式", value = 3 }
        },
        order = 3,
        default = 1  -- 默认关闭
    },

    -- 踏水：开关
    TreadWater = {
        name = "踏水能力",
        options = {
            { text = "关闭", value = 1 },
            { text = "开启", value = 2 }
        },
        order = 4,
        default = 1  -- 默认关闭
    },

    -- 召唤猪人：开关
    PigSummon = {
        name = "召唤猪人",
        options = {
            { text = "关闭", value = 1 },
            { text = "开启", value = 2 }
        },
        order = 5,
        default = 1  -- 默认关闭
    },

    -- 视觉显示：关闭/发光/夜视
    NightVision = {
        name = "夜视",
        options = {
            { text = "关闭", value = 1 },
            { text = "发光", value = 2 },
            { text = "夜视", value = 3 },
            { text = "全开", value = 4 }
        },
        order = 6,
        default = 2  -- 默认发光
    },

    -- 保持温度：自动/保暖/隔热
    KeepTemp = {
        name = "温度调节",
        options = {
            { text = "自动适应", value = 1 },
            { text = "保暖优先", value = 2 },
            { text = "隔热优先", value = 3 }
        },
        order = 7,
        default = 1  -- 默认自动适应
    },

    -- 额外伤害：开关
    ExtraDamage = {
        name = "额外伤害",
        options = {
            { text = "关闭", value = 1 },
            { text = "开启", value = 2 },
            -- { text = "月灵助攻", value = 3 },
            -- { text = "全开", value = 4 }
        },
        order = 8,
        default = 2,  -- 默认开启
        reason = {
            owner_no_combat = "没有战斗组件，无法使用额外伤害功能",
        }
    },

    -- 杀人蜂开关：开关
    DevourerBee = {
        name = "杀人蜂友好",
        options = {
            { text = "关闭", value = 1 },
            { text = "开启", value = 2 }
        },
        order = 9,
        default = 2  -- 默认开启
    },

    -- 电击：开关
    Electric = {
        name = "电击能力",
        options = {
            { text = "关闭", value = 1 },
            { text = "开启", value = 2 }
        },
        order = 10,
        default = 2  -- 默认开启
    },

    GestaltAttack = {
        name = "月灵助攻",
        options = {
            { text = "关闭", value = 1 },
            { text = "开启", value = 2 }
        },
        order = 11,
        default = 2  -- 默认开启
    },

    StopDrop = {
        name = "装备击落保护",
        options = {
            { text = "关闭", value = 1, desc = "背包掉了，你确定自己能活吗？" },
            { text = "开启", value = 2, desc = "头盔/武器保护需解锁对应功能" }
        },
        order = 12,
        default = 2  -- 默认开启
    },

    Luck = {
        name = "幸运值",
        options = {
            { text = "关闭", value = 1 },
            { text = "幸运", value = 2 },
            { text = "霉运", value = 3 }
        },
        order = 13,
        default = 2  -- 默认幸运
    },

    RainProtect = {
        name = "防雨保护",
        options = {
            { text = "关闭", value = 1 },
            { text = "开启", value = 2 }
        },
        order = 14,
        default = 2  -- 默认开启
    }
}

STRINGS.DEVOURER_PIG_ELITE_SUMMONED = "吞噬者！好人！保护！"
-- 猪人风格提示
STRINGS.DEVOURER_PIG_MESSAGES = {
    PREFIX = "保护！更强！",
    EAT_PREFIX = "好吃！更强！",
    LV = "LV%d",
    EXP = "%d/%d",
    ATTACK = "攻击+%.1f",
    PLANAR_ATK = "位面攻击+%.1f",
    PLANAR_DEF = "位面防御+%.1f",
    DEFENSE = "减伤+%.1f%%",
    RUN_SPEED = "跑速%.1f",
    WALK_SPEED = "走速%.1f",
    RANGE = "攻击距离+%.1f",
    FREEZE_RESIST = "冰冻抗性+%.1f",
    BLOOD_SUCKING = "吸血+%.1f%%",
    AREA_ATTACK = "范围伤害+%.1f%%",
    HEALTH = "血量+%d",
    SIZE = "体型x%.2f",
    COMBO = "连击x%d",
    ATK_SPD = "间隔%d帧",
    DEATH = "猪人守护者死亡，经验值减少20%",
    WORK_EXP = "工作+%d经验",
    SURVIVAL_EXP = "生存+%d经验",
    -- 突破条件描述（%s = 进度/目标，如 "15/20"）
    BREAKTHROUGH_TOTAL_KILLS = "累计击杀%s只生物",
    BREAKTHROUGH_EAT_COUNT = "累计吃%s次食物",
    BREAKTHROUGH_SURVIVAL_DAYS = "连续生存%s天",
    BREAKTHROUGH_KILL_ELITE = "累计击杀%s只精英生物",
    BREAKTHROUGH_WORK_COUNT = "累计完成%s次工作",
    BREAKTHROUGH_EAT_FAVORITE = "累计吃%s种最爱料理",
    BREAKTHROUGH_BOSS_KILL = "累计击杀%s种Boss",
    BREAKTHROUGH_KILL_LARGE = "累计击杀%s只大型生物",
    BREAKTHROUGH_PLANAR_BOSS = "击杀突变三王 %s",
}
STRINGS.DEVOURER_PIG_TALK_HELP_CHOP_WOOD = {
    "砍死这逼树！",
    "草！给老子倒！",
    "妈的，看俺的拳头！",
    "这树真他妈的欠揍！",
    "操，这树比俺脑袋还硬！",
    "狗日的树不服管教！",
    "俺今天就跟这树杠上了！",
    "砍了你当柴烧！",
    "破树！吃俺一拳！",
    "树也要挨揍，没商量！",
}

STRINGS.DEVOURER_PIG_TALK_ATTACK = {
    "老子弄死你丫的！",
    "吃俺一蹄子！",
    "砸爆你狗头！",
    "操！往死里打！",
    "嗷嗷嗷嗷！干他！",
    "你完蛋了傻逼！",
    "再过来俺揍死你！",
    "小样的，弄你！",
    "我今天干死你！",
    "跟你拼了！！",
}

-- 吞噬者背包升级效果描述
STRINGS.DP_DevourerPack = {
    NOT_IN_RECIPE = "这东西不在我的食谱里面",
    ALREADY_MAX = "这东西我已经吃腻了",
    DELICIOUS_BASE = "还不错~",
    POWER_UP = "我变得更强了，",
    TREADWATER_ON = "踏水模式开启！饥饿消耗增加%d%%",
    TREADWATER_OFF = "踏水模式已关闭",
    NOT_TREADWATER = "尚未解锁踏水能力",
    TREADWATER_ON_CAVE = "虚空行走模式开启！饥饿消耗增加%d%%",
    TREADWATER_OFF_CAVE = "虚空行走模式已关闭",
    NOT_TREADWATER_CAVE = "尚未解锁虚空行走能力",
    STEAL_RES = "你偷你妈呢？",
    WAIT_UNLOCK = "装备功能升级后解锁",
    SANITY_CHANGE = {
        NOT = "尚未开启对应精神状态模式",
        TO_ZERO = "要么拥抱暗影，要么死于黑暗",
        TO_NORMAL = "已恢复正常",
        TO_LUNAR = "一轮新月正在冉冉升起",
    },
    KeepTemp = {
        disabled = "尚未解锁保持温度能力",
        auto = "自动根据体温变化保温/隔热",
        warm = "保温模式开启",
        cool = "隔热模式开启",
    },
    ExtraDamage = {
        disabled = "尚未解锁额外伤害能力",
        open = "额外伤害/攻击倍率/虚灵攻击开启",
        electric = "额外伤害/攻击倍率/虚灵攻击/电击模式开启",
        close = "额外伤害关闭",
    },
    DevourerBee = {
        disabled = "尚未解锁蜜蜂之友能力",
        open = "蜜蜂之友开启",
        close = "蜜蜂之友关闭",
    },
    MOD = {
        MEDAL = "能力勋章",
    },
    EVENT = {
        YOTP = "猪王之年",
        YOTR = "兔人之年",
        CARNIVAL = "盛夏鸦年华",
        HALLOWED_NIGHTS = "万圣节",
        WINTERS_FEAST = "冬季盛宴",
        YOTH = "发条骑士之年",
    },
    ChangeKeyBindFun = {
        [1] = "切换至范围伤害开关",
        [2] = "切换至范围反伤开关",
        [3] = "切换至精神状态开关",
        [4] = "切换至踏水/虚空行走开关",
        [5] = "切换至猪人召唤",
        [6] = "切换至发光开关",
        [7] = "切换至温度控制",
        [8] = "切换至额外伤害控制",
        [9] = "切换至蜜蜂之友控制",
    },
    LEVEL_UP_MSG = {
        [2] = "，已解锁部分效果",
        [3] = "，已解锁全部效果",
        UP = "升级至 -> ",
        SUIT_UNLOCK = "(未完成)",
        LV1_ACTIVE = "1级效果：",
        LV2_ACTIVE = "2级效果：",
        LV3_ACTIVE = "3级效果：",
        LV2_LOCKED = "2级效果（未解锁）：", 
        LV3_LOCKED = "3级效果（未解锁）：",
        NO_ACTIVE_EFFECTS = "当前无生效效果",
        UP_LV2_UNLOCK = "(Lv2解锁)",
        UP_LV3_UNLOCK = "(Lv3解锁)",
    },
    UI = {
        UPGRADE_MATERIALS = "【进化材料】",
        OTHER_MATERIALS = "【随机推荐】",
        MORE_TIMES = "(%d次)",
        FULLY_UPGRADED = "已无可用进化材料",
        OTHER_ITEMS = "【其他推荐】",
        UPGRADE_SAY = "我的胃说它想要个【%s】当点心",
    },

    OTHERS = {
        REBIRTH = "别再死了，我可不是重生护符",
    },
    DROP = {
        PACK = "战斗，爽！",
        HAND = "战斗，武器！",
        HEAD = "战斗，头盔！",
        REPEAT = "有我还不够吗？",
        ToPack = "你觉得自己很聪明?",
    },
    
    -- 效果描述
    EFFECTS = {
        speed = "移动速度+%d%%",               
        waterproof = "防水效果+%d%%",
        hunger_rate = "饥饿速度-%d%%",
        preserver = "食物腐烂-%g%%",
        defense = "防御力+%d%%",
        externaldamage = "攻击倍率+%d%%",
        saresistance = "理智下降抗性+%d%%",
        bloodsucking = "攻击吸血+%d%%",
        firedreduction = "火焰伤害减免+%d%%",
        minework = "挖矿效率+%d%%",
        chopwork = "砍树效率+%d%%",
        hammerwork = "锤子效率+%d%%",
        mightiness = "力量流失-%g%%",
        ingredientmod = "建造消耗-%g%%",
        food_add = "进食恢复+%g%%",

        -- 非百分比属性
        kw = "保暖+%d",                       
        kc = "隔热+%d",                       
        light = "发光+%g格",                    
        insulated = "绝缘",                    
        dapperness = "每分钟理智+%g",               
        resistance = "骨甲免伤",              
        shadowdominance = "影怪之友",       
        planardefense = "位面防御+%g",           
        heavyarmor = "免疫击退",              
        bramble_resistant = "荆棘抗性",           
        goggles = "防风沙",                    
        gestaltprotection = "月灵之友",        
        gestaltattack = "月灵助攻",            
        acidrainimmune = "酸雨免疫",
        stacksize = "无限堆叠",
        forcefield = "力场护盾",
        junk = "垃圾堆伤害免疫",
        health = "每分钟生命恢复+%g",
        extraview = "视野距离+%d",
        beefalo = "牛牛伪装",
        moonstormevent_detector = "显示瓦格斯塔夫",
        creep = "蜘蛛巢不减速",
        keepondrown = "溺水不掉落",
        keepondeath = "死亡不掉落",
        rebirth = "复活",
        sleep_res = "昏睡抗性+%g",
        manrabbitscarer = "兔人恐惧",
        spiderdisguise = "蜘蛛之友",
        electricattack = "以雷霆击碎黑暗",
        freeze_res = "冰冻抗性+%g",
        rabbitdisguise = "兔子之友",
        treadwater = "踏水",
        voidwalk = "虚空行走",
        add_slot_cols = "背包格子行数+%g",
        basereflect = "物理反射伤害+%g",
        planarreflect = "位面反射伤害+%g",
        specialreflect = "攻击者生命反射伤害+%g%%(5s)",
        aoereflect = "AOE反射伤害(%gs)",
        damage = "伤害+%g",
        spdamage = "位面伤害+%g",
        predamage = "百分比伤害+%g%%(5s)",
        souljar = "灵魂罐",
        ghost_ally = "幽灵朋友",
        walksinkhole = "如履平地",
        walkice = "踏雪无痕",
        lunar = "启迪效果增强",
        zerosanity = "暗影模式",
        shadowlevel = "暗影等级+%g",
        master_crewman = "海盗水手",
        boat_health_buffer = "海盗船长",
        tend = "自动照料农作物（10s）",
        hidesmeats = "肉类隐藏",
        fightpig = "猪人守护",
        bravery_buff = "勇气Buff",
        houndfriend = "猎犬之友",
        devourer_bee = "蜜蜂之友",
        except = "互斥物品",
        -- devourer_pig_friend = "猪人之友",
        -- mermdisguise = "鱼人伪装",
        fire_slot = "加热格",
        snow_slot = "制冷格",
        repair_slot = "修复格+%d%%(60s)",
        luck = "幸运值+%s",
        badluck = "霉运值+%s",

        
        hp = "血量上限+%g",
        sanity = "精神值上限+%g",
        hunger = "饱食度上限+%g",


        miasmaimmune = "瘴气免疫",
        monkey_token = "诅咒免疫",
        ruins = "不屈意志(恢复惩罚血条)",
        season = "四季之灵(保温/隔热翻倍)",
        overlord = "霸者神威",
        season_fish = "四季轮转(腐烂-40%)",
        terraria = "泰拉瑞亚(饥饿-20%)",
        shadow = "暗影之力(范围伤害)",
        stronghead = "不朽头冠(帽子耐久不减少)",
        stronggrip = "强握",
        snail = "蜗牛之盾(免伤+5%)",
        warbis = "科技之力(移速+5%攻击倍率+5%)",
        nightvision = "夜视",
        fastbuilder = "快速制作",
        repair_suit = "修理专家",
        princess_suit = "公主的庇护",
        knight_suit = "骑士的守护",
        princessandknight = "公主和骑士",
        mightiness_mighty = "强壮",
        vegetarian = "素食者",
        carnivore = "肉食者",
        appetizer = "开胃菜",

        lunarplant = "暗影敌对",
        dreadstone = "月亮敌对",

        -- 勋章兼容
        chaos_damage = "混沌伤害",
        chaos_defense = "混沌防御",
        chaos_bonus = "混沌倍率+%g",

        -- 棱镜兼容
        siv_blood_l_reducer = "窃血抵抗+%g%%",


        recipe1 = "科学机器",
        recipe1_boat = "智囊团",
        recipe1_magic = "灵子分解器",
        recipe2 = "炼金引擎",
        recipe2_magic = "暗影操控器",
        recipe1_moon = "天体宝珠",
        recipe_ancient = "远古伪科学站",
        recipe_lunar = "辉煌铁匠铺",
        recipe_shadow = "暗影术基座",
        recipe2_moon = "天体2级",
    }
}

STRINGS.DP_DevourerPack.MOONROCK_CHECK = "月岩映照出吞噬者的力量："
STRINGS.DP_DevourerPack.MAX_LEVEL_REACHED = "%s似乎发现了吞噬者的究极奥义..."
STRINGS.DP_DevourerPack.COOLDOWN = {
    moonrock = "月岩的能量尚未恢复...",
    gold = "等会儿...",
}
STRINGS.DP_DevourerPack.AOE_REFLECT = {
    one = "单体反射伤害开启",
    aoe = "单体/AOE反射伤害开启",
    off = "反射伤害关闭",
    disabled = "尚未解锁AOE反射伤害",
}
STRINGS.DP_DevourerPack.AOE_ATTACK = {
    on = "范围攻击开启",
    off = "范围攻击关闭",
    disabled = "尚未解锁范围攻击",
}
STRINGS.DP_DevourerPack.PIG_SUMMON = {
    disabled = "请使用猪鼻铸币召唤猪人守护",
    death = "猪猪已经阵亡，请使用猪鼻铸币复活他",
    cooldown = "猪猪需要休息，%d秒后再尝试吧"
}
STRINGS.DP_DevourerPack.Light = {
    disabled = "尚未解锁发光能力",
    disabled_nightvision = "尚未解锁夜视能力",
    close = "发光关闭",
    light = "发光打开",
    nightvision = "夜视",
}


-- 吞噬者背包说话
STRINGS.DP_DEVOURERPACK_SAYS = {
    "面如霜下雪，吻如雪上霜",
    "谁知我知你，我知你知深",
    "何以与君识，无言泪千行",
    "谎言不会伤人，真相才是快刀",
    "如果真相带来痛苦，谎言只会雪上加霜",
    "天下万般兵刃，唯有过往伤人最深",
    "有些人的路是选择，有些人的路却是刑罚",
    "你总以为我的世界很大，但你不在的时候我都是一个人",
    "执迷于梦想的人丢弃了现实，也就迷失了自己",
    "想休息，不想睡觉",
    "人生得意须尽欢，莫使金樽空对月",
    "此恨经年深，此情度日久",
    "你若三冬来，换我一城雪白，想吃广东菜",
    "有这么一个游戏，里面的人都喜欢搞饥，猜猜是哪个游戏",
    "我是会说话的背包！",
    "我会吞噬一切！",
    "背上我感觉如何？",
    "我里面装了好多东西呢",
    "饥荒两界十三地都在我的肩上扛着，我才是饥荒举重冠军",
    "装得下，世界就是你的。",
    "别看我方，我肚子里有墨水。",
    "轻点放，我可是文化背包。",
    "知识就是重量，你感受到了吗？",
    "装得下你的梦想，装不下你的零食",
    "知识太重？那是因为你装得太少",
    "我可不是普通的背包，我是有内涵的背包",
    "轻拿轻放，里面装着你的诗和远方",
    "胃袋空转中...需要补给",
    "营养饱和...进入休眠优化",
    "当前吞噬等级：美食家",
    "我，即是饕餮的化身",
    "吞噬与被吞噬...永恒的命题",
    "每个装备都藏着一段故事",
    "所谓进化，不过是精心设计的暴食",
    "我的胃袋里装着整个文明史",
    "刚才那个护甲...辣椒味的",
    "建议下次撒点孜然",
    "正在将敌人转化为朋友...通过消化",
    "根据《吞噬者礼仪》第3条：要细嚼慢咽",
    "杀戮是为了更好的进食",
    -- 古代名言
    "天行健，君子以自强不息；地势坤，君子以厚德载物。",
    "不积跬步，无以至千里；不积小流，无以成江海。",
    "己所不欲，勿施于人。",
    "知之为知之，不知为不知，是知也。",
    
    "人生自古谁无死，留取丹心照汗青。",
    "海内存知己，天涯若比邻。",
    "会当凌绝顶，一览众山小。",
    "采菊东篱下，悠然见南山。",
    "长风破浪会有时，直挂云帆济沧海。",

    "世上无难事，只要肯登攀。",
    "为中华之崛起而读书。",
    "时间就像海绵里的水，只要愿挤，总还是有的。",
    "生活就像海洋，只有意志坚强的人，才能到达彼岸。",

    "物极必反，否极泰来。",
    "塞翁失马，焉知非福。",
    "大道至简，大巧若拙。",
    "静水流深，智者无言。",

    "装得下，世界就是你的。",
    "别看我方，我肚子里有墨水。",
    "轻点放，我可是文化背包。",
    "知识就是重量，你感受到了吗？",

    "等闲识得东风面，万紫千红总是春。",
    "接天莲叶无穷碧，映日荷花别样红。",
    "落霞与孤鹜齐飞，秋水共长天一色。",
    "忽如一夜春风来，千树万树梨花开。",

    "一日之计在于晨",
    "正午阳光正好",
    "夜来风雨声，花落知多少",

    "民以食为天",
    "知足常乐",
    "千磨万击还坚劲，任尔东西南北风",
    "滴水穿石，非一日之功",

    "君子藏器于身，待时而动",
    "水至清则无鱼，人至察则无徒",
    "临渊羡鱼，不如退而结网",
    "欲速则不达，见小利则大事不成",

    "溪云初起日沉阁，山雨欲来风满楼",
    "醉后不知天在水，满船清梦压星河",
    "疏影横斜水清浅，暗香浮动月黄昏",
    "我见青山多妩媚，料青山见我应如是",

    "生命不是要超越别人，而是要超越自己",
    "最困难之时，就是离成功不远之日",
    "真正的平静，不是避开车马喧嚣，而是在心中修篱种菊",
    "世界以痛吻我，要我报之以歌",

    "大智若愚，大巧若拙",
    "与其临渊羡鱼，不如退而结网",
    "不鸣则已，一鸣惊人",
    "桃李不言，下自成蹊",

    "装得下你的梦想，装不下你的零食",
    "知识太重？那是因为你装得太少",
    "我可不是普通的背包，我是有内涵的背包",
    "轻拿轻放，里面装着你的诗和远方",
    
    -- 新季节物语
    "春风又绿江南岸",
    "小荷才露尖尖角，早有蜻蜓立上头",
    "空山新雨后，天气晚来秋",
    "千山鸟飞绝，万径人踪灭",

    -- 新时间感悟
    "晨兴理荒秽，带月荷锄归",
    "夕阳无限好，只是近黄昏",
    "夜深知雪重，时闻折竹声",

    -- 新状态反应
    "腹有诗书气自华，可惜现在是空的",
    "欲戴王冠，必承其重",
    "野火烧不尽，春风吹又生",
    "黑夜给了我黑色的眼睛，我却用它寻找光明",

    -- 新哲理短句
    "无用之用，方为大用",
    "得之坦然，失之淡然",
    "不忘初心，方得始终",
    "淡泊明志，宁静致远",

    -- 冷门但惊艳的诗词
    "山中何事？松花酿酒，春水煎茶", -- 元·张可久
    "何时杖尔看南雪，我与梅花两白头", -- 清·查冬荣
    "一笑相逢蓬海路，人间风月如尘土", -- 宋·周邦彦
    "醉后不知天在水，满船清梦压星河", -- 元·唐珙

    -- 诸子百家冷门箴言
    "不慕往，不闵来，无邑怜之心", -- 荀子
    "欲刚，必以柔守之；欲强，必以弱保之", -- 列子
    "江河合水而为大", -- 尸子
    "善游者溺，善骑者堕", -- 淮南子

    -- 当代作家金句
    "人生如逆旅，我亦是行人", -- 余光中
    "岁月不饶人，我亦未曾饶过岁月", -- 木心
    "世间好物不坚牢，彩云易散琉璃脆", -- 杨绛
    "玻璃晴朗，橘子辉煌", -- 北岛

    -- 趣味改编版
    "背包之大，一个屏幕装不下",
    "三人行，必有我装的物资",
    "知我者谓我心忧，不知我者谓我何求——求你别再塞石头了",
    "有朋自远方来，必先清空背包",

    -- 节气特供
    "春雨惊春清谷天", -- 立春
    "夏满芒夏暑相连", -- 立夏
    "秋处露秋寒霜降", -- 立秋
    "冬雪雪冬小大寒", -- 立冬

    -- 武侠风
    "乾坤一袋装",
    "十步装一物，千里不留行",
    "重剑无锋，大包不工",
    "侠之大者，为国为民；包之大者，为装为容",

    -- 禅意语录
    "一花一世界，一叶一菩提",
    "万古长空，一朝风月",
    "行到水穷处，坐看云起时",
    "若无闲事挂心头，便是人间好时节",

    -- 游戏情境版
    "九死南荒吾不恨，兹游奇绝冠平生", -- 苏轼（适合冒险时）
    "饥来吃饭倦来眠", -- 王阳明（适合生存时）
    "不经一番寒彻骨，怎得梅花扑鼻香", -- 黄蘖禅师（适合冬季）
    "千淘万漉虽辛苦，吹尽狂沙始到金", -- 刘禹锡（适合挖矿时）
    
    -- 佛法禅机
    "万般带不走，唯有业随身，而我，连业也替你装着。",
    "菩提本无树，明镜亦非台，本来无一物，何必装尘埃。",
    "应无所住，而生其心，但行李，还是要住的。",
    "色即是空，空即是色，装满时是色，倒空时是空。",

    -- 公案新解
    "万法归一，一归何处？——归我侧袋第三格。",
    "如何是佛？——干粮分人一半时。",

    -- 物我之境
    "天地一背包，万物一刍狗。",
    "大音希声，大象无形，大包，无拉链。",
    "吾有三宝：一曰慈，二曰俭，三曰能装。",
    "上善若水，水善利万物而不争，包善容万物而不语。",

    -- 文人禅
    "行到水穷处，坐看云起时，起前，检查干粮。",
    "采菊东篱下，悠然见南山，菊在左袋，茶在右囊。",
    "夜深知雪重，时闻折竹声，知否？帐篷在夹层。",
    "人生如逆旅，我亦是行人，行人，记得系紧背带。",

    -- 生活禅
    "饥来吃饭，困来眠，雨来有我自然足。",
    "春有百花秋有月，夏有凉风冬有雪，若无闲事挂心头，便是整理好行装。",
    "运水搬柴，无非妙道，装东装西，尽是禅机。",
    "莫嫌布袋无珍重，曾为如来解寂寥。",
    "犹豫就会败北，果断就会白给",  -- 只狼梗
    "不是坎普斯要不起，而是吞噬者更有性价比",  -- 消费降级梗

    
    -- 哲学思考中文梗
    "如果我掉在永恒领域，会变成切斯特吗？",  -- 游戏世界观
    "背着我的时候，到底是谁在背包谁？",  -- 哲学思考
    "在饥荒世界里，背包才是真正的生存专家！",  -- 幽默自夸

    -- 实用技巧中文梗
    "重要道具放第一格是常识！",  -- 实用建议

    -- 幽默自嘲中文梗
    "论重要性，我比切斯特差在哪？",  -- 与切斯特对比
}
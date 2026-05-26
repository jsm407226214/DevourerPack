-- 吞噬者背包 - 猪人配置（独立配置模块）
local config = {}

-- ============================================
-- 猪人名字池（搞笑/不文明风格）
-- ============================================
config.pig_names = {
    "社会你猪哥",
    "村口一霸",
    "拱白菜专业户",
    "槽里横",
    "天蓬元帅下凡",
    "猪突猛进",
    "泥浆里打滚的",
    "佩奇她二舅",
    "猪八戒的远亲",
    "红烧肉预备役",
    "五花肉在逃",
    "猪中豪杰",
    "猪猪侠本侠",
    "吃饱就睡",
    "横冲直撞",
    "獠牙利齿",
    "猪圈悍匪",
    "拱就完事了",
    "从不减肥",
    "猪队友终结者",
    "你不要过来啊",
    "俺是正经猪",
    "祖传獠牙",
    "别跟我谈瘦肉精",
    "槽中霸主",
    "一拱到底",
    "今天也很暴躁",
    "想吃我一蹄子吗",
    "猪突猛进改",
    "老母猪克星",
    "二师兄本兄",
    "高老庄在逃女婿",
    "卷毛不是我的错",
    "见到我说明你完了",
    "猪中之霸",
    "泥坑是我家",
    "别抢我的泔水",
    "我拱死你",
    "哼哼哈兮",
    "快使用双截棍",
    "又菜又爱拱",
    "我是你猪爷爷",
    "咱村最靓的猪",
    "腚大腰圆",
    "只会往前冲",
    "吃饭第一名",
    "干活就装死",
    "打架不要命",
    "全村の希望",
    "无敌旋风猪",
    "拱翻一切",
    "鼻孔朝天哼",
    "獠牙比你命长",
    "十里八乡第一拱",
    "啥都吃就对了",
    "踩不死的小强猪",
    "鬃毛倒竖",
    "猪突豨勇",
    "河坝战神",
    "吃饱了再跟你算账",
    "被窝里放屁能手",
    "大耳呼扇扇",
    "踩泥坑冠军",
    "你家猪爷爷来了",
    "歪嘴战神",
    "见谁拱谁",
    "路过就得挨一蹄子",
}

-- ============================================
-- 猪人属性成长配置
-- ============================================
config.growth = {
    -- ========== 经验与等级 ==========
    max_level = 30,                   -- 最大等级
    min_eat_interval = 240,           -- 自动找食物吃间隔（秒）

    -- ========== 经验与等级 ==========
    -- 分段经验曲线（1-10级平缓，11-20级中等，21-30级陡峭）
    -- 这样设计让前期升级快给玩家正反馈，后期升级慢让死亡更有代价
    getExpPerLevel = function(level)
        if level <= 10 then
            -- 1-10级: 基础150，每级+20
            return 150 + (level - 1) * 20
        elseif level <= 20 then
            -- 11-20级: 基础250，每级+30
            return 250 + (level - 11) * 30
        else
            -- 21-30级: 基础450，每级+40
            return 450 + (level - 21) * 40
        end
    end,

    -- 击杀经验动态公式
    kill_exp_base = 2,                -- 基础击杀经验
    kill_exp_hp_pow = 0.5,            -- HP指数（平方根）
    kill_exp_atk_pow = 0.3,           -- 攻击力指数
    kill_exp_boss_multiplier = 4,     -- Boss倍率
    kill_exp_max = 200,               -- 单次击杀经验上限

    -- 工作/生存经验
    work_exp = 2,                     -- 砍树/挖矿经验（每次完成增加）
    survival_exp_interval = 120,      -- 生存经验间隔（秒）
    survival_exp = 5,                 -- 每2分钟+5经验

    -- 进食经验
    eat_exp_raw_meat = 2,
    eat_exp_raw_veggie = 1,
    eat_exp_prepared_meat = 5,
    eat_exp_prepared_veggie = 3,
    eat_exp_favorite = 10,

    -- 猪人最爱料理
    favorite_foods = {
        bonestew = true,        -- 炖肉汤
        baconeggs = true,       -- 培根煎蛋
        honeyham = true,        -- 蜜汁火腿
        turkeydinner = true,    -- 火鸡正餐
        meatballs = true,       -- 肉丸
        perogies = true,        -- 波兰水饺
        fishsticks = true,      -- 炸鱼排
        meatysalad = true,      -- 牛肉绿叶菜
        leafloaf = true,        -- 叶肉糕
    },

    -- ========== 基础属性（1级时） ==========
    base_health = 300,
    base_attack = 20,
    base_run_speed = 6,
    base_walk_speed = 3,
    base_range = 2,
    base_defense = 0,
    base_freeze_resist = 0,
    base_blood_sucking = 0,
    base_area_attack = 0,
    base_planar_attack = 0,
    base_planar_defense = 0,

    -- ========== 每级增量 ==========
    health_per_level = 80,            -- 每级+80生命
    attack_per_level = 2.5,           -- 每级+2.5攻击
    range_per_level = 0.05,           -- 每级+0.05攻击距离
    max_attack_range = 3.5,           -- 攻击距离上限
    freeze_resist_per_level = 0.5,    -- 每级+0.5冰冻抗性

    -- 防御曲线（10级前线性，之后衰减，上限90%）
    defense_growth = {
        per_level = 0.04,
        diminish_start = 10,
        diminish_rate = 0.5,
        max_defense = 0.90,
    },
    max_defense = 0.90,               -- 兼容旧引用

    -- 速度
    run_speed_per_level = 0.3,        -- 每级+0.3跑速
    max_run_speed = 12,
    walk_speed_per_level = 0.15,       -- 每级+0.15走速
    max_walk_speed = 6,

    -- 吸血（3级解锁，每级+0.5%，上限15%）
    unlock_blood_sucking = 3,
    blood_sucking_per_level = 0.005,
    max_blood_sucking = 0.15,

    -- 范围伤害（5级解锁，每级+3%，上限60%）
    unlock_area_attack = 5,
    area_attack_per_level = 0.03,
    max_area_attack = 0.60,

    -- 位面属性（8级解锁，每级+1.2，上限25）
    unlock_planar = 8,
    planar_attack_per_level = 1.2,
    max_planar_attack = 25,
    planar_defense_per_level = 1.2,
    max_planar_defense = 25,

    -- 攻击速度（基础8帧，每4级-1帧，最低3帧）
    attack_interval_base = 8,
    attack_interval_per_levels = 4,
    attack_interval_min = 3,
}

-- 预计算累加经验（GetPigLevel 查表用）
config._cum_exp = { [1] = 0 }
do
    local total = 0
    for lv = 2, config.growth.max_level do
        total = total + config.growth.getExpPerLevel(lv)
        config._cum_exp[lv] = total
    end
end

-- 死亡惩罚节点（这些等级死亡时节点标记，但不额外多掉）
config.death_penalty_nodes = { [5] = true, [10] = true, [15] = true, [20] = true, [25] = true, [30] = true }

-- ============================================
-- 等级突破条件
-- ============================================
-- 位面Boss列表（用于位面击杀判定）
config.planar_boss_list = {
    mutatedbearger = true,
    mutateddeerclops = true,
    mutatedwarg = true,
}
config.level_breakthrough = {
    [5] = {
        conditions = {
            { type = "total_kills", count = 20, desc = "BREAKTHROUGH_TOTAL_KILLS" },
            { type = "eat_count", count = 10, desc = "BREAKTHROUGH_EAT_COUNT" },
            { type = "survival_days", count = 5, desc = "BREAKTHROUGH_SURVIVAL_DAYS" },
        },
        desc = "掌握基础生存能力",
    },
    [10] = {
        conditions = {
            { type = "kill_elite", count = 5, desc = "BREAKTHROUGH_KILL_ELITE" },
            { type = "work_count", count = 30, desc = "BREAKTHROUGH_WORK_COUNT" },
            { type = "survival_days", count = 10, desc = "BREAKTHROUGH_SURVIVAL_DAYS" },
        },
        desc = "证明自己的价值",
    },
    [15] = {
        conditions = {
            { type = "kill_elite", count = 15, desc = "BREAKTHROUGH_KILL_ELITE" },
            { type = "eat_favorite_count", count = 5, desc = "BREAKTHROUGH_EAT_FAVORITE" },
            { type = "survival_days", count = 15, desc = "BREAKTHROUGH_SURVIVAL_DAYS" },
        },
        desc = "面对强敌的勇气",
    },
    [20] = {
        conditions = {
            { type = "boss_kill", count = 1, desc = "BREAKTHROUGH_BOSS_KILL" },
            { type = "kill_large", count = 8, desc = "BREAKTHROUGH_KILL_LARGE" },
            { type = "total_kills", count = 150, desc = "BREAKTHROUGH_TOTAL_KILLS" },
            { type = "survival_days", count = 20, desc = "BREAKTHROUGH_SURVIVAL_DAYS" },
        },
        desc = "独当一面的战士",
    },
    [25] = {
        conditions = {
            { type = "eat_favorite_count", count = 10, desc = "BREAKTHROUGH_EAT_FAVORITE" },
            { type = "boss_kill", count = 3, desc = "BREAKTHROUGH_BOSS_KILL" },
            { type = "total_kills", count = 300, desc = "BREAKTHROUGH_TOTAL_KILLS" },
            { type = "survival_days", count = 25, desc = "BREAKTHROUGH_SURVIVAL_DAYS" },
        },
        desc = "挑战更强大的敌人",
    },
    [30] = {
        conditions = {
            { type = "survival_days", count = 30, desc = "BREAKTHROUGH_SURVIVAL_DAYS" },
            { type = "planar_boss", count = 1, desc = "BREAKTHROUGH_PLANAR_BOSS" },
            { type = "boss_kill", count = 5, desc = "BREAKTHROUGH_BOSS_KILL" },
            { type = "total_kills", count = 500, desc = "BREAKTHROUGH_TOTAL_KILLS" },
        },
        desc = "传说中的猪人战士",
    },
}

-- ============================================
-- 30级后无限成长
-- ============================================
config.infinite_growth = {
    enabled = true,
    exp_per_hp = 10,     -- 每100经验+1生命上限
    max_hp_cap = 10000,   -- 最高生命上限
}

-- ============================================
-- 猪人体型配置
-- ============================================
-- 体型公式：scale = min(base + (level-1) * per_level, max_scale)
-- 例：Lv1=1.0, Lv10=1.18, Lv50=1.98, Lv100=2.98(若max_scale=5则截断于5.0)
config.size = {
    base_scale = 1.0,           -- 基础体型
    scale_per_level = 0.02,     -- 每级+2%
    get_max_scale = function()
        return TUNING.DEVOURER_PIG_MAX_SCALE or 5.0
    end,
}

-- ============================================
-- 猪人台词
-- ============================================
config.dialogue = {
    summoned = {
        "吞噬者！好人！保护！",
        "来了来了！谁他妈在惹事？",
        "你爹来了！都给我闪开！",
    },

    attack = {
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
    },

    chop_work = {
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
    },

    eat = {
        "吧唧吧唧……香！",
        "草！真他妈好吃！",
        "妈的，爽死了！",
        "狗日的真带劲！",
        "好吃得俺想哭！",
        "肉！俺的肉！",
        "干饭时间到了！",
        "嘿嘿嘿好吃！",
        "这他妈人间美味！",
        "俺的牙都要香掉了！",
    },

    death = "猪人守护者阵亡！等级下降！",
}

return config

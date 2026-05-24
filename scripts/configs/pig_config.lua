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
-- 猪人属性成长配置（无限成长体系）
-- ============================================
config.growth = {
    -- 经验与等级
    exp_per_level = 500,        -- 每级所需经验
    kill_exp_normal = 2,        -- 普通击杀经验
    kill_exp_medium = 6,        -- 中型怪（HP≥200）
    kill_exp_large = 10,        -- 大型怪（HP≥1000）
    kill_exp_monster = 40,      -- Boss/史诗生物击杀
    min_eat_interval = 240,     -- 最少吃东西间隔（秒）
    work_exp = 1,               -- 砍树/挖矿经验（每次）
    work_exp_interval = 10,     -- 每N次工作才+1经验（一颗大树约+1~2）

    -- 进食经验
    eat_exp_raw_meat = 2,       -- 生肉
    eat_exp_raw_veggie = 1,     -- 生素
    eat_exp_prepared_meat = 5,  -- 肉料理
    eat_exp_prepared_veggie = 3,-- 素料理
    eat_exp_favorite = 10,      -- 最爱料理

    -- 猪人最爱料理（吃这些额外+10经验）
    favorite_foods = {
        bonestew = true,        -- 炖肉汤
        baconeggs = true,       -- 培根煎蛋
        honeyham = true,        -- 蜜汁火腿
        turkeydinner = true,    -- 火鸡正餐
    },

    -- 基础属性
    base_health = 300,
    base_attack = 20,
    base_run_speed = 9,
    base_walk_speed = 3,
    base_range = 2,
    base_defense = 0,
    base_freeze_resist = 0,
    base_blood_sucking = 0,
    base_area_attack = 0,
    base_planar_attack = 0,
    base_planar_defense = 0,

    -- === 无限成长属性（每级增量） ===
    attack_per_level = 2,               -- 攻击力
    planar_attack_per_level = 1,        -- 位面攻击（解锁后）
    planar_defense_per_level = 1,       -- 位面防御（解锁后）
    range_per_level = 0.1,              -- 攻击距离
    freeze_resist_per_level = 1,        -- 冰冻抗性
    blood_sucking_per_level = 0.002,    -- 吸血比例（0.2%/级）
    area_attack_per_level = 0.02,       -- 范围伤害比例（2%/级）

    -- 属性解锁等级（达到该等级后才能获得对应属性增长）
    unlock_planar = 5,                  -- 位面攻击/防御解锁等级
    unlock_blood_sucking = 3,           -- 吸血解锁等级
    unlock_area_attack = 10,            -- 范围伤害解锁等级

    -- === 有上限的属性 ===
    defense_per_level = 0.02,           -- 每级+2%伤害吸收
    max_defense = 0.95,                 -- 伤害吸收上限95%
    run_speed_per_level = 0.3,          -- 跑步速度每级增量
    walk_speed_per_level = 0.1,         -- 走路速度每级增量
    max_run_speed = 10,                 -- 跑步速度上限
    max_walk_speed = 4,                 -- 走路速度上限
    max_attack_range = 5,               -- 攻击距离上限
    health_per_level = 100,             -- 每级生命值增量

    -- === 连击（普攻次数，不含终结击） ===
    combo_base = 1,                     -- 基础普攻次数（终结击始终追加在最后）
    combo_per_levels = 3,               -- 每N级+1普攻
    combo_max = 5,                      -- 最大普攻次数

    -- === 攻击速度（连击间隔递减） ===
    attack_interval_base = 8,           -- 基础连击间隔（帧）
    attack_interval_per_levels = 5,     -- 每N级间隔-1帧
    attack_interval_min = 2,            -- 最小连击间隔（帧，不会到0，多个DoAttack挤在同一帧无意义）
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

    death = "猪人守护者阵亡！经验值减少20%",
}

return config

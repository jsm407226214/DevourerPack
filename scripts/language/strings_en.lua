STRINGS = GLOBAL.STRINGS

STRINGS.NAMES.DEVOURER_PACK = "DevourerPack" -- 物体在游戏中显示的名字
-- 皮肤名称
STRINGS.SKIN_NAMES.devourer_cats = "DevourerCats"
-- Pig names now random from pig_config.lua pool, below as fallback
STRINGS.NAMES.DEVOURER_PIG1 = "Piggy Smalls"
STRINGS.NAMES.DEVOURER_PIG2 = "Sir Oinksalot"
STRINGS.NAMES.DEVOURER_PIG3 = "Hammibal Lecter"
STRINGS.NAMES.DEVOURER_PIG4 = "Kevin Bacon"
STRINGS.NAMES.DEVOURER_PACK_NAMES = {
    [1] = "Jörmungandr Devourer",
    [2] = "Typhon's Maw Devourer",
    [3] = "Apep Omega Devourer",
}
STRINGS.CHARACTERS.GENERIC.DESCRIBE.DEVOURER_PACK = "Spring’s rain, summer’s scorch, autumn’s chill, winter’s frost, moon cycle, shadow magic" -- 物体的检查描述
STRINGS.RECIPE_DESC.DEVOURER_PACK = "Devour. Absorb. Evolve. The world’s power is mine to claim." -- 物体的制作栏描述
STRINGS.DP_DEVOUR_ACTION = "Devour"

STRINGS.DEVOURER_CONTROLS = {
    -- 范围攻击
    AreaAttack = {
        name = "Area Attack",
        options = {
            { text = "Off", value = 1 },
            { text = "On", value = 2 }
        },
        order = 1,
        default = 2  -- 默认开启
    },

    -- 反伤：关闭/单体/群体/全开
    Reflect = {
        name = "Reflection Mode",
        options = {
            { text = "Off", value = 1 },
            { text = "Single Target", value = 2 },
            { text = "AoE", value = 3 },
            { text = "All On", value = 4 }
        },
        order = 2,
        default = 4  -- 默认全开
    },

    -- 精神状态变化：关闭/暗影/启迪
    SanityChange = {
        name = "Sanity State",
        options = {
            { text = "Off", value = 1 },
            { text = "Enlightened Mode", value = 2 },  -- 与中文版"启迪模式"对应
            { text = "Shadow Mode", value = 3 }         -- 与中文版"暗影模式"对应
        },
        order = 3,
        default = 1  -- 默认关闭
    },

    -- 踏水
    TreadWater = {
        name = "Water Treading",
        options = {
            { text = "Off", value = 1 },
            { text = "On", value = 2 }
        },
        order = 4,
        default = 1  -- 默认关闭
    },

    -- 召唤猪人
    PigSummon = {  -- 保持键名与中文版一致
        name = "Summon Pigmen",
        options = {
            { text = "Off", value = 1 },
            { text = "On", value = 2 }
        },
        order = 5,
        default = 1  -- 默认关闭
    },

    -- 视觉显示：关闭/发光/夜视/全开
    NightVision = {
        name = "Visual Display",
        options = {
            { text = "Off", value = 1 },
            { text = "Glow", value = 2 },
            { text = "Night Vision", value = 3 },
            { text = "All On", value = 4 }  -- 补充"全开"选项
        },
        order = 6,
        default = 2  -- 默认发光
    },

    -- 保持温度：自动/保暖/隔热
    KeepTemp = {
        name = "Temperature Control",
        options = {
            { text = "Auto Adapt", value = 1 },
            { text = "Prioritize Warmth", value = 2 },
            { text = "Prioritize Cooling", value = 3 }
        },
        order = 7,
        default = 1  -- 默认自动适应
    },

    -- 额外伤害
    ExtraDamage = {
        name = "Extra Damage",
        options = {
            { text = "Off", value = 1 },
            { text = "On", value = 2 },
            -- 可根据需要补充：
            -- { text = "Gestalt Assist", value = 3 },
            -- { text = "All On", value = 4 }
        },
        order = 8,
        default = 2,
        reason = {
            owner_no_combat = "No combat component, cannot use extra damage function"  -- 补充英文提示
        }
    },

    -- 杀人蜂开关
    DevourerBee = {
        name = "Killer Bee Friendly",
        options = {
            { text = "Off", value = 1 },
            { text = "On", value = 2 }
        },
        order = 9,
        default = 2
    },

    -- 电击
    Electric = {
        name = "Electric Shock Ability",
        options = {
            { text = "Off", value = 1 },
            { text = "On", value = 2 }
        },
        order = 10,
        default = 2
    },

    -- 月灵助攻
    GestaltAttack = {
        name = "Gestalt Assist",  -- "月灵"译为"Gestalt"（符合饥荒术语习惯）
        options = {
            { text = "Off", value = 1 },
            { text = "On", value = 2 }
        },
        order = 11,
        default = 2
    },

    StopDrop = {
        name = "Equipment Drop Protection",
        options = {
            { text = "Disabled", value = 1, desc = "The pack will not drop arbitrarily." },
            { text = "Enabled", value = 2, desc = "Helmet/Weapon protection requires unlocking the corresponding features." }
        },
        order = 12,
        default = 2  -- Enabled by default
    },

    Luck = {
        name = "Luck",
        options = {
            { text = "Off", value = 1 },
            { text = "On", value = 2 }
        },
        order = 13,
        default = 2  -- 默认开启
    },

    RainProtect = {
        name = "Rain Protection",
        options = {
            { text = "Off", value = 1 },
            { text = "On", value = 2 }
        },
        order = 14,
        default = 2  -- Enabled by default
    }
}

STRINGS.DEVOURER_PIG_ELITE_SUMMONED = "Devourer! Good! Protect!"
STRINGS.DEVOURER_PIG_MESSAGES = {
    PREFIX = "Protect! Stronger!",
    EAT_PREFIX = "Delicious! Stronger!",
    LV = "LV%d",
    EXP = "%d/%d",
    ATTACK = "ATK+%.1f",
    PLANAR_ATK = "Planar ATK+%.1f",
    PLANAR_DEF = "Planar DEF+%.1f",
    DEFENSE = "DEF+%.1f%%",
    RUN_SPEED = "Run %.1f",
    WALK_SPEED = "Walk %.1f",
    RANGE = "Range+%.1f",
    FREEZE_RESIST = "Freeze Res+%.1f",
    BLOOD_SUCKING = "Lifesteal+%.1f%%",
    AREA_ATTACK = "AOE+%.1f%%",
    HEALTH = "HP+%d",
    SIZE = "Size x%.2f",
    COMBO = "Combo x%d",
    ATK_SPD = "Int %df",
    DEATH = "Pig Guardian Killed! EXP reduced by 20%",
}
STRINGS.DEVOURER_PIG_TALK_HELP_CHOP_WOOD = {
    "Die, you stupid tree!",
    "Timber! Hahaha!",
    "Take that, you overgrown weed!",
    "Why won't you fall?!",
    "My fists are stronger than any axe!",
    "Stupid tree, meet my fist!",
}
STRINGS.DEVOURER_PIG_TALK_ATTACK = {
    "I'll smash your face in!",
    "Eat my hoof!",
    "You're dead meat, idiot!",
    "Come get some!",
    "Ora ora ora ora!",
    "Muda muda muda muda!",
    "I'll mess you up!",
    "You asked for this!",
    "Raaargh! Die!",
    "Time to meet your maker!",
}

-- Devourer Pack upgrade effects
STRINGS.DP_DevourerPack = {
    NOT_IN_RECIPE = "This is not in my recipe",
    ALREADY_MAX = "I'm already tired of eating this",
    DELICIOUS_BASE = "Great~",
    POWER_UP = "I've become stronger, ",
    TREADWATER_ON = "Tread Water Mode On! Hunger consumption increased by %d%%",
    TREADWATER_OFF = "Tread Water Closed",
    NOT_TREADWATER = "Not Unlocked Tread Water Ability",
    TREADWATER_ON_CAVE = "Void Walk Mode On! Hunger consumption increased by %d%%",
    TREADWATER_OFF_CAVE = "Void Walk Closed",
    NOT_TREADWATER_CAVE = "Not Unlocked Void Walk Ability",
    STEAL_RES = "Stealing? Go fuck yourself.",
    WAIT_UNLOCK = "Upgrade to Unlock Effects",
    SANITY_CHANGE = {
        NOT = "The shadow or lunar transformation has not been activated yet",
        TO_ZERO = "Embrace the shadows… or die in darkness.",
        TO_NORMAL = "Returned To Normal",
        TO_LUNAR = "A new moon is rising."
    },
    KeepTemp = {
        disabled = "Temperature regulation ability not unlocked yet",
        auto = "Automatically insulates based on body temperature changes",
        warm = "Heat retention mode activated",
        cool = "Heat insulation mode activated",
    },
    ExtraDamage = {
        disabled = "Extra damage ability not unlocked yet",
        open = "Extra damage/attack multiplier activated",
        electric = "Extra damage/attack multiplier/electric shock mode activated",
        close = "Extra damage deactivated",
    },
    DevourerBee = {
        disabled = "Bee Friend ability not unlocked yet",
        open = "Bee Friend On",
        close = "Bee Friend Off",
    },
    MOD = {
        MEDAL = "Functional Medal",
    },   
    EVENT = {
        YOTP = "Year of the Pig King",
        YOTR = "Year of the Bunnyman",
        CARNIVAL = "Midsummer Cawnival",
        HALLOWED_NIGHTS = "Hallowed Nights",
        WINTERS_FEAST = "Winter's Feast",
        YOTH = "Year of the Clockwork Knight",
    }, 
    ChangeKeyBindFun = {
        [1] = "Switch to Area Damage Mode",
        [2] = "Switch to Aoe Reflect Mode",
        [3] = "Switch to Sanity Mode", 
        [4] = "Switch to TreadWater/Void Walk Mode",
        [5] = "Switch to Pig Summon",
        [6] = "Switch to Light Change",
        [7] = "Switch to Temperature Control",
        [8] = "Switch to Extra Damage Control",
        [9] = "Switch to Bee Friend Control",
    },
    LEVEL_UP_MSG = {
        [2] = ", Partial Effects Unlocked",
        [3] = ", All Effects Unlocked",
        UP = "Upgraded to -> ",
        SUIT_UNLOCK = "(Unfinished)",
        LV1_ACTIVE = "Level 1 Effects:",
        LV2_ACTIVE = "Level 2 Effects:",
        LV3_ACTIVE = "Level 3 Effects:",
        LV2_LOCKED = "Level 2 Effects (Locked):",
        LV3_LOCKED = "Level 3 Effects (Locked):",
        NO_ACTIVE_EFFECTS = "No active effects",
        UP_LV2_UNLOCK = "(Lv2 Unlock)",
        UP_LV3_UNLOCK = "(Lv3 Unlock)",
    },
    
    UI = {
        UPGRADE_MATERIALS = "【Evolution Recommendations】",
        OTHER_MATERIALS = "【Random Recommendations】",
        MORE_TIMES = "(%d times)",
        FULLY_UPGRADED = "No available evolution Recommendations",
        OTHER_ITEMS = "【Other Recommendations】",
        UPGRADE_SAY = "My stomach demands 【%s】 for snack time!",
    },
    
    OTHERS = {
        REBIRTH = "Don't die again,I am not Life Giving Amulet",
    },
    DROP = {
        PACK = "Fight, Fun!",
        HAND = "Fight, Weapon!",
        HEAD = "Fight, Helmet!",
        REPEAT = "Have I not been enough?",
        ToPack = "Do you think yourself is so smart?",
    },
    
    -- Effect descriptions
    EFFECTS = {
        speed = "Movement speed +%d%%",
        waterproof = "Waterproof +%d%%",
        hunger_rate = "Hunger rate -%d%%",
        preserver = "Delay food spoilage +%g%%",
        defense = "Defense +%d%%",
        externaldamage = "Attack multiplier +%d%%",
        saresistance = "Sanity Aura Resistance%d%%",
        bloodsucking = "Attack Bloodsucking +%d%%",
        firedreduction = "Fired Reduction +%d%%",
        minework = "Mining Efficiency +%d%%",
        chopwork = "Chopping Efficiency +%d%%",
        hammerwork = "Hammering Efficiency +%d%%",
        mightiness = "Mightiness Drain-%g%%",
        ingredientmod = "Build Cost-%g%%",
        food_add = "Food Restores+%g%%",

        -- non-percentage attributes
        kw = "Warmth +%d",
        kc = "Cooling +%g",
        light = "Light +%d level",
        insulated = "Gained insulation",
        dapperness = "Sanity +%d/min",
        resistance = "Gained damage resistance",
        shadowdominance = "Gained shadow dominance",
        planardefense = "Gained %d planar defense",
        heavyarmor = "Gained knockback immunity",
        bramble_resistant = "Gained bramble resistance",
        goggles = "Gained sandstorm protection",
        gestaltprotection = "Gained gestalt attack immunity",
        gestaltattack = "Gained gestalt follower attack",
        acidrainimmune = "Gained acid rain immunity",
        stacksize = "Gained stack expansion",
        forcefield = "Gained force field shield",
        junk = "Gained junk damage immunity",
        health = "Health regen +%d/min",
        extraview = "Increases field of view by %d distance units",
        beefalo = "Beefalo Disguise",
        moonstormevent_detector = "Show Grainy Transmission",
        creep = "Immune to spider den slowdown",
        keepondrown = "Keep Pack When Drown",
        keepondeath = "Keep Pack When Death",
        rebirth = "Rebirth",
        sleep_res = "Sleeper Resistance +%g",
        manrabbitscarer = "Rabbit Man Scarer",
        spiderdisguise = "Spider Disguise",
        electricattack = "The Brightest Star in the Night Sky",
        freeze_res = "Freeze Resistance +%g",
        rabbitdisguise = "Rabbit Disguise",
        treadwater = "Tread Water (Teleporting and Wormholes May Cause Failure)",
        voidwalk = "Void Walk (Teleporting and Wormholes May Cause Failure)",
        add_slot_cols = "Backpack Slot Columns+%g",
        basereflect = "Physical reflect damage +%g",
        planarreflect = "Planar reflect damage +%g",
        specialreflect = "Attacker MaxHealth reflect damage +%g(5s)",
        aoereflect = "AOE reflect damage(%gs)",
        damage = "Physical damage +%g",
        spdamage = "Plannar damage +%g",
        predamage = "Percentage maxHealth damage +%g%%(5s)",
        souljar = "Soul Jar",
        ghost_ally = "Ghost Friend",
        walksinkhole = "Walk SinkHole",
        walkice = "Walk Ice",
        lunar = "Lunar Effects Improve",
        zerosanity = "Shadow Mode",
        shadowlevel = "Shadow Level+%g",
        master_crewman = "Pirate Sailor",
        boat_health_buffer = "Pirate Captain",
        tend = "Auto Tend Crops(10s)",
        hidesmeats = "Hide Meats",
        fightpig = "Pig Protected",
        bravery_buff = "Bravery Buff",
        houndfriend = "Hound Friend",
        devourer_bee = "Bee Friend",
        -- devourer_pig_friend = "Pig Friend",
        -- mermdisguise = "Merm Disguise",
        fire_slot = "Fire Slot",
        snow_slot = "Snow Slot",
        repair_slot = "Repair Slot+%d%%(60s)",
        luck = "Luck+%d",
        
        hp = "maximum Health+%g",
        sanity = "maximum Sanity+%g",
        hunger = "maximum Hunger+%g",
        

        miasmaimmune = "Miasma Immune",
        monkey_token = "Curse Analysis",
        ruins = "The Unyielding will from ancient",
        season = "Season Spirit",
        overlord = "Obtain Overlord's Might",
        season_fish = "Season fish",
        terraria = "Terraria",
        shadow = "Shadow Power",
        stronggrip = "Strong Grip",
        stronghead = "Infinite Crown (hat durability does not decrease)",
        snail = "Snail Shield",
        warbis = "The Power of Technology",
        nightvision = "Night Vision",
        fastbuilder = "Fast Builder",
        repair_suit = "Repair Expert",
        princess_suit = "Princess's Protection",
        knight_suit = "Knight's Protection",
        princessandknight = "Princess and Knight",
        mightiness_mighty = "Mightiness",
        vegetarian = "Vegetarian",
        carnivore = "Carnivore",
        appetizer = "Appetizer",

        lunarplant = "Anti-shadow",
        dreadstone = "Anti-lunar",

        -- 勋章兼容
        chaos_damage = "Medal Chaos Damage",
        chaos_defense = "Medal Chaos Defense",
        chaos_bonus = "Medal Chaos Bonus+%g",

        -- 棱镜兼容
        siv_blood_l_reducer = "Siving Blood Sucking Reducer+%g%%",

        
        recipe1 = "Science Machine",
        recipe1_boat = "Think Tank",
        recipe1_magic = "Prestihatitator",
        recipe2 = "Alchemy Engine",
        recipe2_magic = "Shadow Manipulator",
        recipe1_moon = "Celestial Orb",
        recipe_ancient = "Ancient Pseudoscience Station",
        recipe_lunar = "Brightsmithy",
        recipe_shadow = "Shadowcraft Plinth",
        recipe2_moon = "Celestial Sanctum",
    }
}
STRINGS.DP_DevourerPack.MOONROCK_CHECK = "Moonrock reveals the devourer's power:"
STRINGS.DP_DevourerPack.MAX_LEVEL_REACHED = "%s seem to have found the ultimate secret of the Devourer..."

STRINGS.DP_DevourerPack.COOLDOWN = {
    moonrock = "Moonrock cooldowning...",
    gold = "Waiting...",
}

STRINGS.DP_DevourerPack.AOE_REFLECT = {
    on = "AOE Reflect Damage On",
    one = "Single Target Reflect Damage On",
    aoe = "Single Target/AOE Reflect Damage On",
    disabled = "AOE Reflect Damage Not Unlocked",
}
STRINGS.DP_DevourerPack.AOE_ATTACK = {
    on = "Area Attack On",
    off = "Area Attack Off",
    disabled = "Area Attack Not Unlocked",
}
STRINGS.DP_DevourerPack.PIG_SUMMON = {
    disabled = "Pig Protected Not Unlocked, Use Pig Coin Unlock",
    death = "Your pig has fallen! Use a Pig Coin to revive him",
    cooldown = "Pig need relax, after %d seconds try it again"
}
STRINGS.DP_DevourerPack.Light = {
    disabled = "Not Unlocked Light",
    close = "Light Closed",
    open = "Light Opened",
    nightvision = "Night Vision Opened",
}


-- 吞噬者背包说话
STRINGS.DP_DEVOURERPACK_SAYS = {
    "A smooth sea never made a skilled mariner.",
    -- 经典名人名言
    "The only way to do great work is to love what you do. - Steve Jobs",
    "In the middle of difficulty lies opportunity. - Albert Einstein",
    "Be the change you wish to see in the world. - Mahatma Gandhi",
    "Life is what happens when you're busy making other plans. - John Lennon",

    -- 哲学智慧
    "I think, therefore I am. - René Descartes",
    "The unexamined life is not worth living. - Socrates",
    "Whereof one cannot speak, thereof one must be silent. - Wittgenstein",
    "Man is born free, and everywhere he is in chains. - Rousseau",

    -- 文学名句
    "All happy families are alike; each unhappy family is unhappy in its own way. - Tolstoy",
    "To be, or not to be: that is the question. - Shakespeare",
    "It was the best of times, it was the worst of times. - Dickens",
    "Not all those who wander are lost. - Tolkien",

    -- 现代励志
    "Success is not final, failure is not fatal: It is the courage to continue that counts. - Churchill",
    "If you're going through hell, keep going. - Winston Churchill",
    "Your time is limited, don't waste it living someone else's life. - Steve Jobs",
    "The only limit to our realization of tomorrow is our doubts of today. - FDR",

    -- 科学思想
    "The important thing is not to stop questioning. - Einstein",
    "Nothing in life is to be feared, it is only to be understood. - Marie Curie",
    "Science is magic that works. - Kurt Vonnegut",
    "The universe is under no obligation to make sense to you. - Neil deGrasse Tyson",

    -- 幽默搞笑
    "I'm not lazy, I'm in energy-saving mode.",
    "Error 404: Motivation not found",
    "I put the 'pro' in procrastination",
    "My backpack is like the universe - constantly expanding",
    "Heavy? That's just the weight of knowledge",
    "This is not clutter, it's a collection",
    "I'd explain quantum physics but we're both not in the right state",
    "Warning: Contents may be awesome",

    -- 游戏相关幽默
    "Inventory full... just like my schedule",
    "Carry weight exceeded? Blame Newton!",
    "I contain multitudes... and snacks",
    "This isn't hoarding, it's strategic resource management",

    -- 深度思考
    "We are what we repeatedly do. Excellence, then, is not an act, but a habit. - Aristotle",
    "The only true wisdom is in knowing you know nothing. - Socrates",
    "We don't see things as they are, we see them as we are. - Anaïs Nin",
    "Reality is merely an illusion, albeit a very persistent one. - Einstein",

    -- 生存智慧
    "Adapt what is useful, reject what is useless. - Bruce Lee",
    "Fortune favors the prepared mind. - Louis Pasteur",
    "By failing to prepare, you are preparing to fail. - Benjamin Franklin",
    "Hope for the best, prepare for the worst. - English proverb",

    -- 随机智慧
    "The journey of a thousand miles begins with one step. - Lao Tzu",
    "When the winds of change blow, some build walls, others build windmills. - Chinese proverb",
    "You miss 100% of the shots you don't take. - Wayne Gretzky",
    "The obstacle is the path. - Zen proverb",

    -- 状态相关
    "Abundance is the secret of the universe",
    "Nature abhors a vacuum... and so do I",
    "Scars are just stories written on the body",
    "Water is the softest thing, yet it can penetrate mountains - Lao Tzu",

    -- 新增名人名言
    "The greatest glory in living lies not in never falling, but in rising every time we fall. - Nelson Mandela",
    "If you look at what you have in life, you'll always have more. - Oprah Winfrey",
    "The future belongs to those who believe in the beauty of their dreams. - Eleanor Roosevelt",
    "Strive not to be a success, but rather to be of value. - Albert Einstein",

    -- 新增哲学思考
    "We are too soon old and too late smart. - Dutch proverb",
    "The mind is everything. What you think you become. - Buddha",
    "He who has a why to live can bear almost any how. - Nietzsche",
    "Knowing yourself is the beginning of all wisdom. - Aristotle",

    -- 新增文学精选
    "It is never too late to be what you might have been. - George Eliot",
    "We are all in the gutter, but some of us are looking at the stars. - Oscar Wilde",
    "The only way out is through. - Robert Frost",
    "You can never be overdressed or overeducated. - Oscar Wilde",

    -- 新增科学趣谈
    "Imagination is more important than knowledge. - Albert Einstein",
    "The science of today is the technology of tomorrow. - Edward Teller",
    "Facts are stubborn things, but statistics are pliable. - Mark Twain",
    "Art is the tree of life. Science is the tree of death. - William Blake",

    -- 新增幽默语句
    "I'm not arguing, I'm just explaining why I'm right",
    "I don't need anger management, I need people to stop annoying me",
    "I'm not short, I'm concentrated awesome",
    "I'm not procrastinating, I'm prioritizing fun",
    "This bag is 90% hope and 10% actual useful items",
    "I contain 15% useful stuff and 85% 'just in case' items",
    "My organizational system is called 'organized chaos'",
    "This isn't junk, it's potential crafting materials",

    -- 新增游戏双关
    "Warning: May contain traces of adventure",
    "This bag runs on coffee and poor decisions",
    "Carry weight limit is just a suggestion",
    "I'm not loot hoarding, I'm resource optimizing",

    -- 新增生存智慧
    "Smooth seas do not make skillful sailors. - African proverb",
    "It's not the load that breaks you down, it's the way you carry it. - Lou Holtz",
    "The best time to plant a tree was 20 years ago. The second best time is now. - Chinese proverb",
    "He who cannot endure the bad will not live to see the good. - Jewish proverb",

    -- 新增随机智慧
    "The man who moves a mountain begins by carrying away small stones. - Confucius",
    "A wise man adapts himself to circumstances, as water shapes itself to the vessel. - Chinese proverb",
    "The gem cannot be polished without friction, nor man perfected without trials. - Confucius",
    "When the student is ready, the teacher will appear. - Buddhist proverb",

    -- 新增状态反应
    "What doesn't kill you makes you stronger... or gives you back problems",
    "Freedom is just another word for nothing left to carry",
    "Chaos controlled is civilization achieved",
    "This isn't disorder, it's creative arrangement",

    -- 新增科技梗
    "Ctrl+Alt+Del your problems away",
    "This bag is powered by caffeine and bad code",
    "Error: Inventory overflow. Solution: More pockets",
    "Warning: Contents may exceed expectations",

    -- 基础状态
    "Stomach chamber idling... nutrients required",
    "Nutrition saturation achieved... entering dormancy optimization",
    "Current Devour Tier: Gourmet",
    "I... am the incarnation of Gluttony",

    -- 哲学思考
    "To devour and be devoured... the eternal paradox",
    "Every gear carries its own legend",
    "Evolution is but carefully orchestrated gluttony",
    "My gastric vault contains entire civilizations",

    -- 幽默吐槽
    "That last armor... had a spicy aftertaste",
    "Recommend adding cumin seasoning next time",
    "Converting enemies to allies... through digestion",
    "Article 3 of 《Devourer's Etiquette》: Chew thoroughly",

    -- 战斗渴望
    "Slaughter is merely optimized feeding",
    "My recipe book needs updating... with your equipment",

    -- 新增哲理语句（宇宙级）
    "We are star-stuff contemplating the stars - Carl Sagan", 
    "The universe is not required to be in perfect harmony with human ambition - Stephen Hawking",
    "Every atom in your body came from a star that exploded - Neil deGrasse Tyson",
    
    -- 新增存在主义
    "Man is condemned to be free - Jean-Paul Sartre",
    "There is only one serious philosophical problem, and that is suicide - Albert Camus",
    "Hell is other people's backpacks - Sartre (parodied)",
    
    -- 新增计算机幽默
    "Error 418: I'm a teapot, not a backpack",
    "Ctrl+Z my life choices please",
    "This bag runs on coffee and bad decisions",
    "RAM upgrade needed to handle my inventory",
    
    -- 新增文学魔改
    "To carry or not to carry, that is the inventory question",
    "Call me Ishmael... and help me close this overstuffed bag",
    "It was the best of items, it was the worst of clutter",
    
    -- 新增游戏玩家梗
    "Loot first, ask questions while looting",
    "My carrying capacity is over 9000!",
    "This isn't hoarding, it's 'strategic resource allocation'",
    "Weight limit is just the game's way of saying 'git gud'",
    
    -- 新增伪科学
    "Studies show 93% of adventurers forget to empty side pockets",
    "According to Einstein's Backpack Theory, E=mc² (Empty=more carry²)",
    "Quantum physics proves items both exist and don't exist in my pockets",
    
    -- 新增黑暗幽默
    "I'd kill for more inventory space... literally",
    "My organizational system is called 'denial'",
    "This bag contains my hopes, dreams, and several unidentified fungi",
    
    -- 新增诗意瞬间
    "The weight we carry is the weight we choose - Thoreau (adapted)",
    "These fragments I have shored against my ruins - T.S. Eliot (in a backpack)",
    "I contain multitudes... and three broken compasses - Whitman (remixed)",
    
    -- 新增元幽默
    "This message will self-destruct... unlike the junk in my bag",
    "I'd make a joke about repetition, but I already said that",
    "Help! I'm trapped in a string table!",

    -- 日漫梗
    "Notice me senpai! My capacity is over 9000!",  -- 经典战力梗+前辈文化
    "Bankai! Spatial Expansion Release!",  -- 《死神》卍解梗
    "This pocket leads to Dr. Stone's laboratory",  -- 《石纪元》科学梗
    "NANI?! How did that fit inside?!",  -- 经典震惊梗

    -- 美漫梗
    "Wubba Lubba Dub Dub! That's how dimensions work!",  -- 《瑞克和莫蒂》
    "By Azura! By Azura! By Azura! (Elder Scrolls reference)",  -- 美式RPG梗
    "MY LEG! (Just kidding, I don't have legs)",  -- 《海绵宝宝》梗
    "Bazinga! Quantum storage activated",  -- 《生活大爆炸》梗

    -- 奇幻冒险
    "You shall not pass... my weight limit",  -- 《魔戒》甘道夫梗
    "Fly you fools... to my expanded compartments",  
    "Winter is coming... better pack more supplies",  -- 《权游》梗
    "Mugiwara no Backpack ready for adventure!",  -- 《海贼王》草帽梗

    -- 机甲科幻
    "GUNDAM storage system online: Beam saber compartment unlocked",  
    "Evangelion synchronization: 400% storage efficiency",  -- 《EVA》梗
    "Titanfall detected... deploying pocket titan",  
    "Warning: Psycho-Pass contamination level rising",  -- 《心理测量者》

    -- 黑暗幽默
    "I contain multitudes... and several dead anime protagonists",  
    "This pocket is darker than Berserk's eclipse",  -- 《剑风传奇》
    "More tragic than Clannad's ending scene",  
    "Storage void deeper than Lain's cyberworld",  -- 《玲音》

    -- 游戏联动
    "Critical storage! Would you like to reload last save?",  
    "New quest: Collect 10 mushrooms (already got 37)",  -- RPG梗
    "Fatality! Inventory full...ality!",  -- 《真人快打》
    "Pocket Monster storage system activated",  -- 宝可梦梗

    -- 萌系文化
    "Notice: Kawaii overload in section 3B",  
    "UwU what's this? Another hidden pocket?",  
    "Nya~ventory at maximum capacity",  
    "Doki doki storage crisis!",  -- 心跳文学梗

    -- 经典反派
    "All according to keikaku (storage plan)",  -- 《死亡笔记》计划梗
    "I am inevitable... and so is my capacity",  -- 灭霸梗
    "KONO DIO DA! (In pocket form)",  -- 《JOJO》迪奥梗
    "Just as planned... muhahaha",  -- 《反叛的鲁路修》

    -- 次元故障
    "Error 404: Anime logic not found",  
    "Buffering... loading shonen power",  
    "Plot armor storage at 120%",  
    "Isekai transition in progress... please wait",  -- 异世界转生梗

    -- 欧美流行梗
    "That's not a backpack... THIS is a backpack! (Crocodile Dundee style)",  -- 澳大利亚电影梗
    "Bri'ish mode activated: Tea compartment at 110%",  -- 英国梗
    "As seen on TV! Now with 50% more space!",  -- 美式广告梗
    "Canadian apology: Sorry for being too spacious",  
    
    -- 日本二次元梗
    "Ora ora ora ora storage rush! (JoJo reference)",  
    "Notice me senpai! My pockets are desu~",  -- 萌系日语混杂
    "Yamete! That tickles my inner compartments!",  -- 奇怪play警告
    "Nani?! Impossible storage technique!",  -- 经典震惊梗
    
    -- 韩国流行文化
    "Oppa storage style! (K-drama mode)",  
    "BTS Dynamite-proof compartment unlocked",  -- 防弹少年团梗
    "Squid Game alert: Red light means stop stuffing",  
    "Gangnam Style pocket: Classy but full",  
    
    -- 德国梗
    "Achtung! Über-capacity detected (but still efficient)",  
    "Precision engineering: 99.9% space utilization",  
    "Autobahn speed loading system engaged",  
    "Bavarian beer hall song: 'In my pocket lies a pretzel'",  
    
    -- 法国梗
    "Ooh la la! Fashion storage à la mode",  
    "Baguette emergency compartment activated",  
    "Hon hon! Zis is art storage!",  
    "Le sigh... another day of being magnifique",  
    
    -- 俄罗斯梗
    "In Soviet Russia, backpack stores YOU!",  -- 经典反转梗
    "Cyka blyat! Why so heavy?",  -- 游戏玩家梗
    "Babushka approved storage (fits 10 more scarves)",  
    "Glorious Motherland compression algorithm",  
    
    -- 意大利梗
    "Mamma mia! That's a spicy meatball pocket!",  
    "Bellissimo storage! Chef's kiss perfection",  
    "Roman empire mode: All roads lead to my pockets",  
    "Vespazine fuel: 95% pasta powered",  
    
    -- 北欧联合梗
    "Hygge storage: Cozy but functional",  -- 丹麦
    "Lagom capacity: Not too full, not too empty",  -- 瑞典
    "Sisu endurance: Will carry forever",  -- 芬兰
    "Thor's hammer? More like Thor's storage unit",  -- 挪威
    
    -- 国际组织梗
    "UN-approved peacekeeping storage",  
    "NASA-level space management",  
    "FIFA complaint: Too many balls in one pocket",  
    "WHO warning: Excessive hoarding detected",  
    
    -- 多国混搭
    "Arigato, merci, danke for stuffing me",  
    "Eurovision storage: Extra points for drama",  
    "Schengen area: No border control between pockets",  
    "Brexit means Brexit... except for tea storage",

    -- 哲学智慧
    "The unexamined life is not worth living. - Socrates",
    "Whereof one cannot speak, thereof one must be silent. - Wittgenstein",
    "Man is born free, and everywhere he is in chains. - Rousseau",
    "We are what we repeatedly do. Excellence, then, is not an act, but a habit. - Aristotle",

    -- 文学经典
    "All that we see or seem is but a dream within a dream. - Edgar Allan Poe",
    "The only way out is through. - Robert Frost",
    "It is never too late to be what you might have been. - George Eliot",
    "We are all in the gutter, but some of us are looking at the stars. - Oscar Wilde",

    -- 科学思想
    "The most incomprehensible thing about the world is that it is comprehensible. - Einstein",
    "Nothing in life is to be feared, it is only to be understood. - Marie Curie",
    "Science is not only compatible with spirituality; it is a profound source of spirituality. - Carl Sagan",
    "The universe is under no obligation to make sense to you. - Neil deGrasse Tyson",

    -- 艺术感悟
    "Art washes away from the soul the dust of everyday life. - Picasso",
    "Creativity takes courage. - Matisse",
    "The purpose of art is to make the invisible visible. - Paul Klee",
    "Art is the lie that enables us to realize the truth. - Picasso",

    -- 政治社会
    "The only thing necessary for the triumph of evil is for good men to do nothing. - Burke",
    "Injustice anywhere is a threat to justice everywhere. - Martin Luther King Jr.",
    "Freedom is nothing else but a chance to be better. - Camus",
    "The measure of a society is how it treats its weakest members. - Gandhi",

    -- 心灵成长
    "Knowing yourself is the beginning of all wisdom. - Aristotle",
    "He who has a why to live can bear almost any how. - Nietzsche",
    "The wound is the place where the Light enters you. - Rumi",
    "Out of difficulties grow miracles. - Jean de La Bruyère",

    -- 幽默智慧
    "The trouble with having an open mind is that people keep putting things in it. - Oscar Wilde",
    "I am so clever that sometimes I don't understand a single word of what I am saying. - Oscar Wilde",
    "Always forgive your enemies; nothing annoys them so much. - Oscar Wilde",
    "The only way to get rid of temptation is to yield to it. - Oscar Wilde",

    -- 现代思想
    "The future belongs to those who believe in the beauty of their dreams. - Eleanor Roosevelt",
    "Do one thing every day that scares you. - Eleanor Roosevelt",
    "We don't see things as they are, we see them as we are. - Anaïs Nin",
    "You must be the change you wish to see in the world. - Gandhi",

    -- 存在主义
    "Man is condemned to be free. - Sartre",
    "There is only one serious philosophical problem, and that is suicide. - Camus",
    "Hell is other people. - Sartre",
    "Life has to be given a meaning because of the obvious fact that it has no meaning. - Henry Miller",

    -- 全新哲学思考
    "To understand is to perceive patterns. - Isaiah Berlin",
    "The limits of my language mean the limits of my world. - Wittgenstein",
    "We are all fragments of what we could have been. - Schopenhauer",
    "The greatest wealth is to live content with little. - Plato",

    -- 科学新视角
    "The atoms that make up your body were forged in the hearts of stars. - Tyson",
    "Mathematics is the language in which God has written the universe. - Galileo",
    "The most exciting phrase in science is not 'Eureka!' but 'That's funny...' - Asimov",
    "Biology is the study of complicated things that give the appearance of design. - Dawkins",

    -- 文学新选
    "We read to know we're not alone. - C.S. Lewis",
    "The only way out is through. - Robert Frost",
    "You can never get a cup of tea large enough or a book long enough to suit me. - Lewis",
    "A reader lives a thousand lives before he dies. - George R.R. Martin",

    -- 现代智慧
    "Your time is limited, don't waste it living someone else's life. - Jobs",
    "The future depends on what you do today. - Gandhi",
    "If you want to go fast, go alone. If you want to go far, go together. - African proverb",
    "The best way to predict the future is to invent it. - Alan Kay",

    -- 幽默新梗
    "I'm not arguing, I'm just explaining why I'm right.",
    "I don't need anger management, I need people to stop annoying me.",
    "My organizational system is called 'organized chaos'",
    "Error 404: Motivation not found",

    -- 艺术新解
    "Art is the signature of civilizations. - Beverly Sills",
    "Creativity is intelligence having fun. - Einstein",
    "Every artist was first an amateur. - Emerson",
    "Design is not just what it looks like, design is how it works. - Jobs",

    -- 心理学洞见
    "The mind is its own place, and in itself can make a heaven of hell, a hell of heaven. - Milton",
    "We are what we pretend to be, so we must be careful what we pretend to be. - Vonnegut",
    "Between stimulus and response there is a space. In that space is our power. - Frankl",
    "The curious paradox is that when I accept myself just as I am, then I can change. - Rogers",

    -- 环境思考
    "We do not inherit the earth from our ancestors, we borrow it from our children. - Proverb",
    "What we are doing to the forests is but a mirror reflection of what we are doing to ourselves. - Gandhi",
    "There are no passengers on Spaceship Earth. We are all crew. - Fuller",
    "The earth has music for those who listen. - Shakespeare",

    -- 科技反思
    "Technology is anything that wasn't around when you were born. - Kay",
    "The real danger is not that computers will begin to think like men, but that men will begin to think like computers. - Hoffer",
    "Privacy is dead, and social media holds the smoking gun. - Wozniak",
    "The advance of technology is based on making it fit in so that you don't really notice it. - Cooper",

    -- 经典游戏梗
    "Warning: Inventory full (Tetris PTSD triggered)",  -- 俄罗斯方块
    "Insert 25¢ to continue storage expansion",  -- 街机梗
    "Konami code detected: ↑↑↓↓←→←→BA... more space unlocked!",  -- 魂斗罗
    "All your base are belong to us... especially your loot",  -- 零翼战机

    -- 开放世界梗
    "Another settlement needs your... oh wait wrong game",  -- 辐射4
    "Fast travel unavailable: I'm overencumbered with awesome",  -- 老滚5
    "GTA VI loading... meanwhile enjoy my storage capacity",  
    "Climbing stamina depleted (BotW style)",  -- 塞尔达

    -- RPG梗
    "D20 roll for storage: Natural 20! Critical capacity!",  -- DND
    "New side quest: Find my missing socks (check pocket #13)",  
    "Charisma check failed to convince me to hold more",  
    "Achievement unlocked: Hoarder of the Century",  -- Steam成就

    -- 生存游戏
    "Day 327: Still pretending sticks are valuable",  -- 森林
    "Warning: Food will spoil faster than in reality",  -- 饥荒
    "This rock will DEFINITELY be useful later",  -- 通用生存梗
    "Zombies hate this one simple storage trick",  -- 点击诱饵梗

    -- 射击游戏
    "Hitbox smaller than Call of Duty's",  -- FPS梗
    "360 no-scope storage management",  
    "Camping detected in pocket #7",  
    "Press F to pay respects... to your lost inventory space",  -- 战地

    -- 策略游戏
    "Microtransactions won't save you now",  -- 手游梗
    "GG EZ (Good Game Easy Storage)",  -- 电竞梗
    "APM too low to organize this mess",  -- 星际梗
    "Tech tree unlocked: Advanced Pocketology",  -- 文明

    -- 独立游戏
    "Pixel-perfect space utilization",  -- 像素游戏
    "This pocket is a metaphor for capitalism",  -- 独立游戏深度梗
    "Roguelike mode: Lose everything on death",  
    "Made with Unity (and 100% recycled pixels)",  -- 引擎梗

    -- 多人游戏
    "PvP enab: Pocket vs Player",  
    "LFG (Looking For more Goods)",  -- MMO术语
    "Teabag detected in lunchbox compartment",  -- FPS羞辱动作
    "Server lag caused by my overwhelming contents",  

    -- 怀旧游戏
    "Blowing into my pockets like an NES cartridge",  -- 红白机
    "Insert Disk 2 to access hidden compartments",  -- 光盘时代
    "This texture took 16 whole bits to render",  -- 画质梗
    "High score: 999,999 inventory items",  -- 街机

    -- 未来游戏
    "Ray-traced pocket shadows",  -- 光追
    "Loading... (just kidding, SSDs eliminated that joke)",  -- 硬件梗
    "NFT detected - immediately ejected",  -- 区块链梗
    "Cloud storage literally in the clouds now",  -- 云游戏

    "It's dangerous to go alone! Take this. - The Legend of Zelda",
    "War... war never changes. - Fallout",
    "The cake is a lie. - Portal",
    "Do a barrel roll! - Star Fox 64",
    "All your base are belong to us. - Zero Wing",
    "Would you kindly? - BioShock",
    "Finish him! - Mortal Kombat",
    "Stay awhile and listen. - Diablo",
    "I used to be an adventurer like you, then I took an arrow in the knee. - Skyrim",
    "You must construct additional pylons. - StarCraft",
    "It's-a me! - Super Mario 64",
    "The right man in the wrong place can make all the difference in the world. - Half-Life 2",
    "What is a man? A miserable little pile of secrets! - Castlevania: Symphony of the Night",
    "I'm Commander Shepard, and this is my favorite store on the Citadel. - Mass Effect 2",
    "The numbers, Mason! What do they mean? - Call of Duty: Black Ops",
    "Snake? Snake?! SNAAAAAKE!!! - Metal Gear Solid",
    "You died. - Dark Souls",
    "Praise the sun! \\[T]/ - Dark Souls",
    "No cost too great. - Hollow Knight",
    "Boy! - God of War (2018)",

    -- 经典角色梗 (Classic Character Quotes)  
    "Careful, I'm not fireproof! (Unlike Willow...)",  -- "小心点，我可不像薇洛那样防火！"  
    "If you starve, I'll just... eat your stuff.",  -- "如果你饿死了，我就……吃掉你的东西。"  
    "I miss the old WX-78... before the 'upgrades'.",  -- "我怀念以前的WX-78……在升级之前。"  
    "Wendy's ghost sister is cooler than you.",  -- "温蒂的幽灵妹妹比你酷多了。"  

    -- 游戏机制梗 (Game Mechanic Jokes)  
    "Sanity low? Maybe stop staring into the abyss.",  -- "精神值低了？别老盯着深渊看了。"  
    "I can hold 8 items, but you still overpack...",  -- "我能装8个物品，可你还是塞爆我……"  
    "Winter is coming. And so is Deerclops.",  -- "凛冬将至……独眼巨鹿也是。"  
    "Pro tip: Don't eat the gears. (Looking at you, WX.)",  -- "友情提示：别吃齿轮。（说的就是你，WX。）"  

    -- 联机版梗 (DST Multiplayer Jokes)  
    "I bet your teammate 'accidentally' burns me.",  -- "我打赌你的队友会‘不小心’烧了我。"  
    "Respawn penalty? More like free inventory space!",  -- "复活惩罚？不如说是免费清包服务！"  
    "Why does everyone fight over the Walking Cane?",  -- "为什么大家都抢步行手杖？"  
    "If you die, I'm going to the next player. No loyalty here.",  -- "如果你死了，我就换主人。毫无忠诚可言。"  

    -- Boss战吐槽 (Boss Fight Taunts)  
    "Bee Queen? More like 'Why are there so many bees?!'",  -- "蜂后？不如叫‘哪来这么多蜜蜂？！’"  
    "Fighting Klaus? Good luck explaining the loot split.",  -- "打克劳斯？祝你们分赃愉快。"  
    "Fuelweaver's loot is cool, but have you tried... running?",  -- "织影者的战利品是不错，但你们试过……逃跑吗？"  

    -- 生存小贴士 (Survival "Advice")  
    "Yes, eat the Meatballs. No, don't eat the Monster Lasagna.",  -- "肉丸可以吃，怪物千层面？算了。"  
    "If you plant too many trees, I swear...",  -- "你要是再种那么多树，我发誓……"  
    "A backpack's worst nightmare: 40 Berries, no space.",  -- "背包的噩梦：40个浆果，没格子了。"  

    -- 角色专属梗 (Character-Specific Jokes)
    -- "Wilson's beard has more storage than I do...",  -- "威尔逊的胡子比我的容量还大..."
    -- "Stop putting living logs in me, Wormwood!",  -- "别再把活木塞进来了，沃姆伍德！"
    -- "Wickerbottom's books weigh a ton... literally.",  -- "薇克巴顿的书真的重得要命..."
    -- "I'm not a fridge, Warly. Stop stuffing ingredients in me!",  -- "我不是冰箱，沃利！别再把食材塞进来了！"
    
    -- 季节吐槽 (Seasonal Complaints)
    "Summer heat? At least I won't spontaneously combust...",  -- "夏天很热？至少我不会自燃..."
    "Your winter gear takes up half my space!",  -- "你的冬装占了我一半空间！"
    "Spring rains make me smell like wet socks...",  -- "春雨让我闻起来像湿袜子..."
    
    -- 生物互动 (Creature Interactions)
    "No, I won't hold your pet Rock Lobster.",  -- "不，我不会帮你拿宠物石龙虾的"
    "Stop trying to store Volt Goats in me!",  -- "别想把伏特羊塞进来！"
    "If you put another Ewelet in here, I'm leaving.",  -- "要是你再塞只小羊进来，我就走人"
    
    -- 生存建议 (Questionable Survival Tips)
    "Pro tip: You can eat food directly from the ground!",  -- "生存技巧：你可以直接从地上捡食物吃！"
    "Carrying 40 twigs doesn't make you prepared...",  -- "带40根树枝不代表你准备充分..."
    "Maybe don't fight Dragonfly with a spear next time?",  -- "下次也许别用长矛打龙蝇？"
    
    -- 联机版专属 (DST Multiplayer Exclusive)
    "I've been passed around more than a football...",  -- "我比足球传得还勤..."
    "Your 'friend' just stole my best items... again.",  -- "你的'朋友'又偷走了我的好东西..."
    "Respawned 3 times today... I'm getting dizzy.",  -- "今天复活了3次...我头晕了"
    
    -- 特殊事件 (Special Events)
    "Your Winter's Feast presents are crushing me...",  -- "你的冬季盛宴礼物快压死我了..."
    "Too many Gorge ingredients... I smell like garlic.",  -- "太多暴食食材了...我浑身大蒜味"
    "Why do you need 30 Hallowed Nights candies?!",  -- "你要30个万圣节糖果干嘛？！"
    
    -- 哲学思考 (Philosophical Musings)
    "If a backpack drops in the forest... do I exist?",  -- "如果背包掉在森林里...我存在吗？"
    "We're all just containers for Charlie's darkness...",  -- "我们都只是查理黑暗的容器..."
    "Is my purpose just to hold your 37 pieces of flint?",  -- "我的存在意义就是装你的37块燧石吗？"
    
    -- 开发者梗 (Developer Jokes)
    "Klei forgot to give me a 'drop all' button...",  -- "Klei忘了给我'全部丢弃'按钮..."
    "Even the Scaled Chest gets more respect than me...",  -- "就连鳞片箱都比我受尊重..."
    "In the next update, can I get pockets please?",  -- "下次更新能给我加几个口袋吗？"

    -- 更多角色梗 (More Character Jokes)
    "Maxwell's shadow magic is cheating... I want some too!",  -- "麦斯威尔的暗影魔法是作弊...我也想要！"
    -- "Wigfrid keeps putting bloody weapons in me...",  -- "薇格弗德总把血淋淋的武器塞进来..."
    "Webber's spider friends keep crawling in uninvited!",  -- "韦伯的蜘蛛朋友总是不请自来！"

    -- 更多季节梗 (More Seasonal Jokes)
    "Your summer fashion is just... wearing me?",  -- "你的夏日穿搭就是...背着我？"
    "Autumn leaves? In my pockets? Again?",  -- "又往我口袋里塞落叶？"
    "Spring allergies are bad enough without you sneezing on me!",  -- "春天过敏已经够糟了，别对着我打喷嚏！"

    -- 更多生物梗 (More Creature Jokes)
    "That Catcoon just stole from me! Help!",  -- "浣猫刚偷了我的东西！救命！"
    "No, I don't want to hold your pet Glommer...",  -- "不，我不想帮你拿格罗姆..."
    "Stop using me as bait for Hound attacks!",  -- "别拿我当猎犬袭击的诱饵！"

    -- 更多生存建议 (More Survival Tips)
    "Maybe build a chest instead of overstuffing me?",  -- "与其塞爆我，不如造个箱子？"
    "Carrying rot is just asking for trouble...",  -- "带着腐烂物就是自找麻烦..."
    "You know food spoils faster in me, right?",  -- "你知道食物在我这里坏得更快吧？"

    -- 更多联机梗 (More Multiplayer Jokes)
    "I've been through more owners than a used car!",  -- "我换的主人比二手车还多！"
    "Stop arguing over who gets to carry me!",  -- "别争谁该背我了！"
    "Your 'sharing system' is just stealing from me!",  -- "你们的'共享系统'就是偷我东西！"

    -- 更多Boss梗 (More Boss Jokes)
    "You want to fight Fuelweaver with just a spear? Good luck!",  -- "你想用长矛打织影者？祝好运！"
    "Ancient Guardian's roar makes my seams rattle...",  -- "远古守护者的吼叫震得我接缝都在响..."
    "Bee Queen's buzzing is giving me a headache...",  -- "蜂后的嗡嗡声让我头疼..."

    -- 更多哲学思考 (More Philosophical Musings)
    "If you die with me, do we respawn together?",  -- "如果你带着我死了，我们会一起重生吗？"
    "Am I just a tool, or do I have feelings too?",  -- "我只是个工具，还是也有感情？"
    "In another life, maybe I was a Chester...",  -- "在另一个世界，也许我是切斯特..."

    -- 特殊物品梗 (Special Item Jokes)
    "Stop putting Thermal Stones in me, I'm not a microwave!",  -- "别把暖石塞进来，我又不是微波炉！"
    "A stack of 40 logs? Do I look like a lumberyard?",  -- "40个木头？我看起来像木材厂吗？"
    "Your 20 gears are clanking around... make it stop!",  -- "你的20个齿轮叮叮当当响...快停下！"

    -- 食物相关梗 (Food-Related Jokes)
    "Your spoiled meat is making me nauseous...",  -- "你的腐烂肉让我想吐..."
    "Why do you need 10 meatballs RIGHT NOW?",  -- "你为什么现在就需要10个肉丸？"
    "Pineapples from the Gorge? Really? In THIS economy?",  -- "暴食的菠萝？认真的？这年头？"

    -- 建造相关梗 (Building-Related Jokes)
    "Carrying a full base's worth of materials? Dream on!",  -- "想带着整个基地的材料？做梦！"
    "Your 30 cut reeds are poking me from inside!",  -- "你的30个割下的芦苇从里面戳我！"
    "Stop using me as a mobile crafting station!",  -- "别把我当移动制作站用！"

    -- 活动限定梗 (Event-Exclusive Jokes)
    "Your Hallowed Nights candy wrappers are everywhere!",  -- "你的万圣节糖果包装纸到处都是！"
    "Too many Winter's Feast ornaments... I'm glowing!",  -- "太多冬季盛宴装饰品...我在发光！"
    "The Year of the Carrat left me covered in fur...",  -- "胡萝卜鼠年让我浑身是毛..."

    -- 航海相关梗 (Seafaring Jokes)
    "Seawater got in me... now everything's soggy!",  -- "海水进到我里面了...现在所有东西都湿了！"
    "Your boat repair kits are poking my sides!",  -- "你的船修理工具包在戳我的侧面！"
    "If you sink with me, do we become Davy Jones' locker?",  -- "如果你带着我沉船，我们会变成戴维·琼斯的储物柜吗？"

    -- 洞穴探险梗 (Caving Jokes)
    "The ruins' thulecite is giving me a weird glow...",  -- "远古遗迹的铥矿让我发出奇怪的光..."
    "Stop putting nightmare fuel in me, it tickles!",  -- "别把噩梦燃料放进来，好痒！"
    "Your 15 glow berries are lighting up my insides!",  -- "你的15个发光浆果照亮了我的内部！"

    -- 更多哲学思考 (Even More Philosophy)
    "If you drop me in the ocean, do I become a boat?",  -- "如果你把我扔进海里，我会变成船吗？"
    "Is my existence just to enable your hoarding?",  -- "我的存在只是为了满足你的囤积癖吗？"
    "In another timeline, maybe I was a Piggyback...",  -- "在另一个时间线，也许我是猪猪包..."
    
    -- 开发者梗续集 (More Developer Jokes)
    "Klei pls nerf backpack capacity... it's too much!",  -- "Klei求削弱背包容量...太多了！"
    "Even the Insulated Pack gets more love than me!",  -- "就连保温包都比我受宠！"
    "Next update: Backpack emotes when?",  -- "下次更新：背包表情什么时候出？"

    -- 特殊状态梗 (Special Condition Jokes)
    "Your wet items are making me all soggy...",  -- "你的湿物品让我浑身湿漉漉的..."
    "Too many frozen items... I'm becoming an icebox!",  -- "太多冷冻物品...我要变成冰盒了！"
    "The cursed items from the archives are whispering...",  -- "档案馆的诅咒物品在低语..."

    -- 角色互动梗 (Character Interaction Jokes)
    "Wurt keeps trying to store merm friends in me... illegal!",  -- "沃特总想把鱼人朋友塞进来...这是违法的！"
    "Walter's slingshot ammo keeps rolling around in me...",  -- "沃尔特的弹弓弹药在我里面滚来滚去..."
    "Wanda's age potions are leaking... I feel younger!",  -- "旺达的年龄药水漏了...我感觉变年轻了！"

    -- 食物储存梗 (Food Storage Jokes)
    "Your 20 honey hams are attracting bees... help!",  -- "你的20个蜂蜜火腿引来蜜蜂了...救命！"
    "Stop using me as a butter churner while running!",  -- "别在跑步时把我当黄油搅拌器用！"
    "Your garlic powder from the Gorge is making me sneeze!",  -- "你暴食带来的大蒜粉让我打喷嚏！"

    -- 战斗相关梗 (Combat-Related Jokes)
    "Your 10 weather pains are giving me a headache!",  -- "你的10个唤星法杖让我头疼！"
    "Stop using me as a shield against Deerclops!",  -- "别拿我当独眼巨鹿的盾牌！"
    "The constant weapon switching is making me dizzy...",  -- "不停地换武器让我头晕..."

    -- 季节BOSS梗 (Seasonal Boss Jokes)
    "Bearger's drool got on me... it won't come off!",  -- "熊獾的口水沾我身上了...擦不掉！"
    "Moose/Goose feathers are tickling my seams!",  -- "鹿鸭的羽毛在挠我的接缝！"
    "Antlion's sand is getting in all my pockets...",  -- "蚁狮的沙子进到我所有口袋里了..."

    -- 联机专属梗 (Multiplayer Exclusive Jokes)
    "I've been passed around more than a Wortox soul!",  -- "我比沃拓克斯的灵魂传递得还快！"
    "Your team's 'emergency supplies' are just my stuff!",  -- "你们队伍的'应急物资'就是我的东西！"
    "Stop using me as a trade post between bases!",  -- "别把我当基地间的贸易站用！"

    -- 洞穴探险梗续 (More Caving Jokes)
    "The ruins' ancient wall carvings are scratching me!",  -- "遗迹的远古墙雕在刮我！"
    "Your 15 thulecite fragments are glowing suspiciously...",  -- "你的15个铥矿碎片在可疑地发光..."
    "Stop storing nightmare creatures in me!",  -- "别把梦魇生物存在我这里！"

    -- 航海梗续 (More Seafaring Jokes)
    "Salt crystals from the ocean are making me thirsty!",  -- "海里的盐晶让我口渴！"
    "Your boat patches keep sticking to my lining!",  -- "你的船补丁总粘在我的内衬上！"
    "If a shark bites me, do I become a shark backpack?",  -- "如果鲨鱼咬我，我会变成鲨鱼背包吗？"

    -- 活动限定梗续 (More Event Jokes)
    "Too many Winter's Feast lights... I'm blinding!",  -- "太多冬季盛宴的灯...我要亮瞎了！"
    "The Year of the Catcoon left me covered in furballs!",  -- "浣猫年让我浑身毛球！"
    "Hallowed Nights candy corn is stuck in my seams!",  -- "万圣节的糖果玉米卡在我接缝里了！"

    -- 哲学思考终极版 (Final Philosophy)
    "If Maxwell can summon me, am I real or just code?",  -- "如果麦斯威尔能召唤我，我是真实的还是代码？"
    "Do backpacks dream of electric sheep?",  -- "背包会梦见电子羊吗？"
    "In the Constant's grand scheme, what's my purpose?",  -- "在永恒领域的宏大计划中，我的目的是什么？"
    
    -- 开发者梗终章 (Final Developer Jokes)
    "Klei pls add backpack customization options!",  -- "Klei求添加背包自定义选项！"
    "Even the Scaled Chest gets seasonal skins...",  -- "就连鳞片箱都有季节皮肤..."
    "Next update: Backpack voice pack when?",  -- "下次更新：背包语音包什么时候出？"

    -- 特殊状态梗续 (More Condition Jokes)
    "Your overheating thermal stone is burning me!",  -- "你过热的暖石在烫我！"
    "The full moon makes my contents feel... weird.",  -- "满月让我里面的东西感觉...怪怪的。"
    "Charlie's darkness is seeping into my fabric...",  -- "查理的黑暗在渗入我的布料..."
}
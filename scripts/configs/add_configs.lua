local config = {}

config.percent_effects = {
    speed = true,               -- 移动速度
    waterproof = true,          -- 防水
    hunger_rate = true,         -- 饥饿速度
    preserver = true,           -- 食物保鲜
    defense = true,             -- 防御力
    externaldamage = true,      -- 额外伤害
    saresistance = true,        -- 理智抗性
    bloodsucking = true,        -- 吸血
    firedreduction = true,      -- 火焰抗性
    specialreflect = true,      -- 百分比攻击者生命值反射伤害
    predamage = true,           -- 百分比生命值攻击伤害
    chopwork = true,            -- 砍树工作效率
    minework = true,            -- 挖矿工作效率
    hammerwork = true,          -- 锤击工作效率
    mightiness = true,          -- 力量流失减少
    food_add = true,            -- 进食恢复
    ingredientmod = true,       -- 建造消耗减少

    siv_blood_l_reducer = true, -- 窃血抵抗
}
config.slot_specical_items = {
    dragonflyfurnace = true,  -- 龙鳞火炉/Scaled Furnace
    deerclopseyeball_sentryward_kit = true,  -- 冰眼结晶器套装/Ice Crystaleyezer Kit
    wagpunkbits_kit = true,  -- 自动修理机/Auto-Mat-O-Chanic
    voidcloth_kit = true,  -- 虚空修补套件/Void Repair Kit
    lunarplant_kit = true,  -- 亮茄修补套件/Brightshade Repair Kit
    -- gelblob_storage_kit = true, -- 恶液储存箱套件/Icker Preserve Kit
    -- gelblob_storage = true, -- 恶液储存箱/Icker Preserve
    chester_eyebone = true, -- 眼骨/Eye Bone
    hutch_fishbowl = true, -- 星空/Star-sky
    icepack = true,         -- 保鲜背包/Insulated Pack
    spicepack = true,       -- 厨师袋/Chef Pouch
    piggyback = true,        -- 猪皮包/Piggyback
    krampus_sack = true,     -- 坎普斯背包/Krampus Sack
}
config.SPECIAL_FOOD = {
    deerclops_eyeball = true,
    minotaurhorn = true,
}
-- 不受超过100%防御影响的属性
config.excluded_extra_defense =  {
    defense = true,
    add_slot_cols = true,
    -- shadowlevel = true,
    season = true,
    ruins = true,
    skeleton = true,
    lunarplant = true,
    dreadstone = true,
    miasmaimmune = true,
    overlord = true,
    monkey_token = true,
    terraria = true,
    season_fish = true,
    shadow = true,
    stronggrip = true,
    stronghead = true,
    snail = true,
    warbis = true,
    nightvision = true,
    fastbuilder = true,
    recipe1 = true,
    recipe1_boat = true,
    recipe1_magic = true,
    recipe2 = true,
    recipe2_magic = true,
    recipe1_moon = true,
    recipe_ancient = true,
    recipe_lunar = true,
    recipe_shadow = true,
    recipe2_moon = true,
    repair_slot = true,
    luck = true,
    badluck = true,
}

config.level_up = {
    lv1 = {
        item = {
            -- goose_feather = true,               -- 麋鹿鹅羽毛/Down Feather
            -- dragon_scales = true,               -- 鳞片/Scales
            -- bearger_fur = true,                 -- 熊皮/Thick Fur
            -- deerclops_eyeball = true,           -- 独眼巨鹿眼球/Deerclops Eyeball

            heatrock = true,                    -- 暖石/Thermal Stone
            tentaclespike = true,               -- 触手尖刺/Tentacle Spike
            hambat = true,                      -- 火腿棒/Ham Bat
            amulet = true,                      -- 重生护符/Life Giving Amulet
            blueamulet = true,                  -- 寒冰护符/Chilled Amulet
            purpleamulet = true,                -- 梦魇护符/Nightmare Amulet
            batbat = true,                      -- 蝙蝠棒/Bat Bat
            nightstick = true,                  -- 晨星锤/Morning Star
            icestaff = true,                    -- 冰魔杖/Ice Staff
            firestaff = true,                   -- 火魔杖/Fire Staff
            panflute = true,                    -- 排箫/Pan Flute
            raincoat = true,                    -- 雨衣/Rain Coat
            armor_sanity = true,                -- 暗夜甲/Night Armor
            nightsword = true,                  -- 暗夜剑/Dark Sword
            armormarble = true,                 -- 大理石甲/Marble Suit
        },
        effect = {
            tend = true,                        -- 照顾农作物
            defense = true,                     -- 基础防御
            waterproof = true,                  -- 防水
            speed = true,                       -- 移动速度
            insulated = true,                   -- 绝缘
            kw = true,                          -- 保暖
            kc = true,                          -- 隔热
            light = true,                       -- 发光
            rebirth = true,                     -- 复活
            dapperness = true,                  -- 精神恢复
            add_slot_cols = true,                -- 背包栏位
            mightiness = true,                  -- 力量流失减缓
            souljar = true,                     -- 灵魂罐
            ghost_ally = true,                  -- 幽灵朋友
            chopwork = true,                    -- 砍树工作效率
            minework = true,                    -- 挖矿工作效率
            hammerwork = true,                  -- 锤击工作效率
            damage = true,                      -- 额外固定伤害
            basereflect = true,                 -- 物理反弹伤害
            zerosanity = true,                  -- 0精神状态
            food_add = true,                    -- 进食恢复
            shadowlevel = true,                 -- 暗影等级
            hidesmeats = true,                  -- 肉类隐藏
            fightpig = true,                    -- 猪人保护
            bravery_buff = true,                -- 勇气buff
            chaos_damage = true,                -- 混沌伤害开关
            chaos_defense = true,               -- 混沌防御开关
            chaos_bonus = true,                 -- 混沌伤害/防御倍率
            siv_blood_l_reducer = true,         -- 窃血抵抗
            recipe1 = true,                     -- 科学机器
            recipe1_boat = true,                -- 智囊团
            recipe1_magic = true,               -- 灵子分解器
            repair_slot = true,                 -- 自动修理
            repair_suit = true,                 -- 修理套装
            luck = true,                        -- 幸运值
            princess_suit = true,               -- 公主套装(幸运翻倍，移速+5%)
            knight_suit = true,                 -- 骑士套装(幸运翻倍，免伤+5%)
            princessandknight = true,           -- 公主和骑士（公主和骑士套加成翻倍）
            slot_lv = true,                     -- 用来在格子变化的时候同步给客户端的，不放在1级会被代码过滤掉
            vegetarian = true,                  -- 素食者（女武神可以吃素食）
            carnivore = true,                   -- 肉食者（小鱼妹可以吃肉食）
            appetizer = true,                   -- 开胃菜（不挑食）
            badluck = true,                     -- 霉运
        }
    },
    lv2 = {
        item = {
            -- shadowheart = true,                  -- 暗影心房/Shadow Atrium
            -- minotaurhorn = true,                 -- 守护者之角/Guardian's Horn
            
            -- armorskeleton = true,               -- 骨头盔甲/Bone Armor
            -- skeletonhat = true,                 -- 骨头头盔/Bone Helm
            -- thurible = true,                    --暗影香炉/Shadow Thurible
            -- greenamulet = true,                 -- 建造护符/Construction Amulet

            cane = true,                        -- 步行手杖/Walking Cane
            molehat = true,                     -- 鼹鼠帽/Moggles
            walrushat = true,                   -- 贝雷帽/Tam o' Shanter
            orangestaff = true,                 -- 懒人魔杖/The Lazy Explorer
            multitool_axe_pickaxe = true,       -- 多用斧镐/Pick/Axe
            cookiecutterhat = true,             -- 饼干切割机帽子/Cookie Cutter Cap
            armorruins = true,                  -- 铥矿甲/Thulecite Suit
            ruinshat = true,                    -- 铥矿皇冠/Thulecite Crown

            staff_tornado = true,               -- 天气风向标/Weather Pain
            featherfan = true,                  -- 羽毛扇/Luxury Fan
            armordragonfly = true,              -- 鳞甲/Scalemail
            beargervest = true,                 -- 熊皮背心/Hibearnation Vest
            eyebrellahat = true,                -- 眼球伞/Eyebrella
            spiderhat = true,                   -- 蜘蛛帽/Spiderhat

            yellowstaff = true,                 -- 唤星者魔杖/Star Caller's Staff
            opalstaff = true,                   -- 唤月者魔杖/Moon Caller's Staff
            orangeamulet = true,                -- 懒人护符/The Lazy Forager
            deserthat = true,                   -- 沙漠护目镜/Desert Goggles
            antlionhat = true,                  -- 刮地皮头盔/Turf-Raiser Helm
        },
        effect = {
            freeze_res = true,                  -- 冰冻抗性
            monkey_token = true,                -- 诅咒解析
            planardefense = true,               -- 位面防御
            saresistance = true,                -- 理智下降抗性
            preserver = true,                   -- 减缓腐烂
            heavyarmor = true,                  -- 免疫击退
            shadowdominance = true,             -- 影怪无仇恨
            beefalo = true,                     -- 发情牛不攻击
            creep = true,                       -- 蜘蛛巢不减速
            bloodsucking = true,                -- 吸血
            firedreduction = true,              -- 火焰伤害减免
            sleep_res = true,                   -- 催眠抗性
            manrabbitscarer = true,             -- 兔人不攻击
            
            planarreflect = true,               -- 位面反弹伤害
            spdamage = true,                    -- 额外位面伤害
            forcefield = true,                  -- 力场护盾（铥矿头）
            health = true,                      -- 自动回复血量
            rabbitdisguise = true,              -- 兔子伪装
            electricattack = true,              -- 电击攻击
            goggles = true,                     -- 防风沙
            bramble_resistant = true,           -- 免疫荆棘伤害
            ingredientmod = true,               -- 建造消耗减少
            walksinkhole = true,                -- 如履平地
            walkice = true,                     -- 踏雪无痕
            season = true,                      -- 四季套装
            ruins = true,                       -- 铥矿套装
            terraria = true,                    -- 泰拉瑞亚套装
            season_fish = true,                 -- 四季鱼套装
            master_crewman = true,              -- 海盗水手
            boat_health_buffer = true,          -- 海盗船长
            shadow = true,                      -- 暗影套装（aoe攻击）
            lunarplant = true,                  -- 亮茄套装
            dreadstone = true,                  -- 绝望石套装
            miasmaimmune = true,                -- 虚空套装
            stronggrip = true,                  -- 武器套装（强握，武器不会被击落）
            stronghead = true,                  -- 帽子套装（头部装备不会被击落，减伤+5%）
            snail = true,                       -- 蜗牛套装（减伤+5%）
            warbis = true,                      -- warbis套装（移速+5%，攻击倍率+5%）
            nightvision = true,                 -- 夜视套装
            fastbuilder = true,                 -- 护符套装，加快制作速度
            houndfriend = true,                 -- 狗狗朋友
            devourer_bee = true,                -- 蜜蜂之友
            insect = true,                      -- 蜜蜂之友（两个组合在一起的，一个让杀人蜂和采摘蜂箱不打你，一个让普通春天蜜蜂不打你）
            spiderdisguise = true,              -- 蜘蛛伪装
            -- devourer_pig_friend = true,         -- 猪人之友
            recipe2 = true,                     -- 炼金引擎
            recipe2_magic = true,               -- 暗影操控器
            recipe1_moon = true,                -- 天体宝珠
            fire_slot = true,                   -- 加热格子
            -- snow_slot = true,                   -- 制冷格子
        }
    },
    lv3 = {
        item = {
        },
        effect = {
            
        }
    }
}

config.excluded_attrs =  {
    enab = true,
    max = true,
    cur = true,
    mod = true,
    role = true,
    show = true,
    except = true,
}
config.NotShowUnItems = {
    rocks = true,               -- 石头/Rocks
    -- flint = {  },            -- 燧石/Flint
    goldnugget = true,          -- 金块/Gold Nugget
    moonrocknugget = true,      -- 月岩/Moon Rock
    stinger = true,             -- 蜂刺/Stinger
    houndstooth = true,         -- 犬牙/Hound's Tooth
    nightmarefuel = true,       -- 噩梦燃料/Nightmare Fuel
    pigskin = true,             -- 猪皮/Pig Skin
}

-- 升级物品效果表（哈希表结构方便快速查询）
config.upgrade_effects = {
    goldnugget = {  }, -- 金块/Gold Nugget
    moonrocknugget = {  }, -- 月岩/Moon Rock
    -- rocks = {  }, -- 石头/Rocks
    -- -- flint = {  }, -- 燧石/Flint
    -- stinger = {  }, -- 蜂刺/Stinger
    -- nightmarefuel = {  }, -- 噩梦燃料/Nightmare Fuel
    -- houndstooth = {  }, -- 犬牙/Hound's Tooth
    -- pigskin = {},       -- 猪皮/Pig Skin

    boat_cannon_kit = { monkey_token = 1 }, -- 大炮套装/Cannon Kit
    cannonball_rock_item = { monkey_token = 1 }, -- 炮弹/Cannonball
    dock_kit = { monkey_token = 1 }, -- 码头套装/Dock Kit
    dock_woodposts_item = { monkey_token = 1 }, -- 码头桩/Dock Piling
    turf_monkey_ground = { monkey_token = 1 }, -- 月亮码头海滩地皮/Moon Quay Beach Turf
    
    heatrock = { kw = 30, kc = 30 },         -- 暖石/Thermal Stone
    
    cane = { speed = 0.10 },         -- 步行手杖/Walking Cane


    siving_mask = { siv_blood_l_reducer = 0.125, mod = "legion" }, -- 子圭·汲
    siving_boxopener = { siv_blood_l_reducer = 0.125, dapperness = 1, mod = "legion" }, -- 子圭·系
    siving_mask_gold = { siv_blood_l_reducer = 0.25, mod = "legion" }, -- 子圭·歃


    opalpreciousgem = { kw = 60, kc = 60, light = 1, preserver = 0.1, speed = 0.05, dapperness = 1, health = 1, saresistance = 0.1, nightvision = 1   }, -- 彩虹宝石/Iridescent Gem
    blueamulet = { kc = 30, firedreduction = 0.25, fastbuilder = 1 },            -- 寒冰护符/Chilled Amulet
    
    raincoat = { waterproof = 0.5 },  -- 雨衣/Rain Coat
    walrushat = { kw = 30, dapperness = 1, stronghead = 1 },  -- 贝雷帽/Tam o' Shanter
    yellowstaff = { kw = 60, dapperness = 1, freeze_res = 1 },  -- 唤星者魔杖/Star Caller's Staff
    opalstaff = { kc = 60, dapperness = 1, firedreduction = 0.25 },  -- 唤月者魔杖/Moon Caller's Staff

    molehat = { light = 1, nightvision = 1 },  -- 鼹鼠帽/Moggles

    strawhat = { stronghead = 1 },  -- 草帽/Straw Hat
    flowerhat = { stronghead = 1 },  -- 花环/Flower Hat
    earmuffshat = { stronghead = 1, kw = 5 },  -- 兔耳罩/Earmuffs
    tophat = { stronghead = 1 },  -- 高礼帽/Top Hat
    rainhat = { stronghead = 1 },  -- 雨帽/Rain Hat
    featherhat = { stronghead = 1, morebird = true },  -- 羽毛帽/Feather Hat
    watermelonhat = { stronghead = 1, kc = 15 },  -- 西瓜帽/Watermelon Hat
    minerhat = { stronghead = 1, light = 0.5 },  -- 矿工头盔/Miner Hat
    catcoonhat = { stronghead = 1, kw = 5 },  -- 猫帽/Cat Cap
    beefalohat = { stronghead = 1, kw = 30 },               -- 牛角帽/Beefalo Hat
    icehat = { stronghead = 1, kc = 30 },                   -- 冰帽/Ice Cube
    bushhat = { stronghead = 1 },  -- 灌木丛帽/Bush Hat
    winterhat = { stronghead = 1, kw = 5 },  -- 冬帽/Winter Hat

    
    -- pig_token = { devourer_pig_friend = true },
    
    armorslurper = { hunger_rate = 0.2 },-- 饥饿腰带/Belt of Hunger

    beargerfur_sack = { preserver = 0.5 },  -- 极地熊獾桶/Polar Bearger Bin
    -- gears = { preserver = 0.01, max = 20},-- 齿轮/Gears
    -- saltrock = { preserver = 0.01, max = 20 },-- 盐晶/Salt Crystals
    
    orangestaff = { speed = 0.15 },  -- 懒人魔杖/The Lazy Explorer
    
    slurtlehat = { defense = 0.05, snail = 1, stronghead = 1 },  -- 背壳头盔/Shelmet
    armorsnurtleshell = { defense = 0.05, snail = 1 },  -- 蜗壳护甲/Snurtle Shell Armor
    armorskeleton = { defense = 0.05, resistance = true, shadow = 1, overlord = 1 },  -- 骨头盔甲/Bone Armor
    skeletonhat = { defense = 0.05, shadowdominance = true, shadow = 1, overlord = 1 },    -- 骨头头盔/Bone Helm
    lunarplanthat = { defense = 0.05, planardefense = 2.5, lunarplant = 1, overlord = 1 },  -- 亮茄头盔/Brightshade Helm
    armor_lunarplant = { defense = 0.05, planardefense = 2.5, lunarplant = 1, overlord = 1 },-- 亮茄盔甲/Brightshade Armor
    armormarble = { defense = 0.05, heavyarmor = true }, -- 大理石甲/Marble Suit
    dreadstonehat = { defense = 0.05, planardefense = 2.5, dreadstone = 1, overlord = 1 },  -- 绝望石头盔/Dreadstone Helm
    armordreadstone = { defense = 0.05, planardefense = 2.5, dreadstone = 1, overlord = 1 },-- 绝望石盔甲/Dreadstone Armor
    armor_sanity = { defense = 0.05, shadow = 1 },-- 暗夜甲/Night Armor
    armorruins = { defense = 0.05, dapperness = 1, ruins = 1, overlord = 1 },     -- 铥矿甲/Thulecite Suit
    ruinshat = { defense = 0.05, forcefield = true, ruins = 1, overlord = 1, stronghead = 1 },       -- 铥矿皇冠/Thulecite Crown
    voidclothhat = { defense = 0.05, planardefense = 2.5, miasmaimmune = 1, overlord = 1 },   -- 虚空风帽/Void Cowl
    armor_voidcloth = { defense = 0.05, planardefense = 2.5, miasmaimmune = 1, overlord = 1 },-- 虚空长袍/Void Robe
    hivehat = { defense = 0.05, dapperness = 1, saresistance = 0.1,devourer_bee = true, insect = true, stronghead = 1 }, -- 蜂王冠/Bee Queen Crown
    wagpunkhat = { defense = 0.05, externaldamage = 0.05, warbis = 1 }, -- W.A.R.B.I.S.头戴齿轮/W.A.R.B.I.S. Head Gear
    armorwagpunk = { defense = 0.05, speed = 0.05, warbis = 1 }, -- W.A.R.B.I.S.盔甲/W.A.R.B.I.S. Armor
    shieldofterror = { defense = 0.05, hunger_rate = 0.1, terraria = 1 }, -- 恐怖盾牌/Shield of Terror
    eyemaskhat = { defense = 0.05, hunger_rate = 0.1, terraria = 1, stronghead = 1 }, -- 眼面具/Eye Mask
    cookiecutterhat = { defense = 0.05, basereflect = 5, aoereflect = 1, stronghead = 1 }, -- 饼干切割机帽子/Cookie Cutter Cap
    scraphat = { defense = 0.05, junk = true, preserver = 0.1 }, -- 拾荒尖帽/Scrappy Chapauldron


    -- sculpture_knightbody = { mightiness_mighty = 1,not_remove = true, no_move = true }, --大理石雕像/Marble Sculpture
    -- sculpture_bishopbody = { mightiness_mighty = 1,not_remove = true, no_move = true }, --大理石雕像/Marble Sculpture
    -- sculpture_rookbody = { mightiness_mighty = 1,not_remove = true, no_move = true }, --大理石雕像/Marble Sculpture

    
    staff_tornado = { externaldamage = 0.05, damage = 1 }, -- 天气风向标/Weather Pain
    featherfan = { kc = 30, saresistance = 0.1, season = 1 },            -- 羽毛扇/Luxury Fan
    armordragonfly = { defense = 0.05, kw = 30, saresistance = 0.1, freeze_res = 1, season = 1 }, -- 鳞甲/Scalemail
    beargervest = { kw = 30, hunger_rate = 0.1, saresistance = 0.1, season = 1 }, -- 熊皮背心/Hibearnation Vest
    eyebrellahat = { waterproof = 0.5, insulated = true, kc = 30, saresistance = 0.1, firedreduction = 0.25, season = 1, stronghead = 1 }, -- 眼球伞/Eyebrella


    gelblob_bottle = { preserver = 0.1 },                  -- 恶液罐/Icker Jar
    gelblob_storage_kit = { preserver = 0.1, except = "gelblob_storage" }, -- 恶液储存箱套件/Icker Preserve Kit
    gelblob_storage = { no_move = true, preserver = 0.1, except = "gelblob_storage_kit" }, -- 恶液储存箱/Icker Preserve
    chester_eyebone = { add_slot_cols = 1, not_remove = true }, -- 眼骨/Eye Bone
    hutch_fishbowl = { add_slot_cols = 1, not_remove = true }, -- 星空/Star-sky
    oceanfish_small_7_inv = { waterproof = 0.5, season_fish = 1 },      -- 花朵金枪鱼/Bloomfin Tuna
    oceanfish_small_8_inv = { kw = 30, season_fish = 1 },               -- 炽热太阳鱼/Scorching Sunfish
    oceanfish_small_6_inv = { hunger_rate = 0.1, season_fish = 1 },       -- 落叶比目鱼/Fallounder
    oceanfish_medium_8_inv = { kc = 30, season_fish = 1 },              -- 冰鲷鱼/Ice Bream
    oceanfish_medium_4_inv = { badluck = 0.1, max = 30 },             -- 黑鲶鱼/Black Catfish
    bootleg = { walkice = true },                                       -- 出逃腿靴/Bootleg Getaway



    ruins_bat = { damage = 1, stronggrip = 1 },    -- 铥矿棒/Thulecite Club
    tentaclespike = { damage = 1, stronggrip = 1 },  -- 触手尖刺/Tentacle Spike
    hambat = { damage = 1, stronggrip = 1 },  -- 火腿棒/Ham Bat
    glasscutter = { damage = 1 },  -- 玻璃刀/Glass Cutter
    multitool_axe_pickaxe = { chopwork = 0.1,minework = 0.1 },  --多用斧镐/Pick/Axe
    moonglassaxe = { chopwork = 0.2 },  --月光玻璃斧/Moon Glass Axe
    shadow_battleaxe = { chopwork = 0.15, bloodsucking = 0.02 },  --暗影槌/Shadow Maul
    thurible = { predamage = 0.005, shadowlevel = 1, shadow = 1 },  --暗影香炉/Shadow Thurible
    voidcloth_scythe = { spdamage = 1, shadowlevel = 1 },  --暗影收割者/Shadow Reaper
    voidcloth_boomerang = { spdamage = 1, damage = 1 }, -- 阴郁回旋镖/Gloomerang

    pickaxe_lunarplant = { minework = 0.1, hammerwork = 0.1  },  -- 亮茄粉碎者/Brightshade Smasher
    -- shovel_lunarplant = { spdamage = 1  },  -- 亮茄锄铲/Brightshade Shoevel
    sword_lunarplant = { spdamage = 1 },  -- 亮茄剑/Brightshade Sword
    staff_lunarplant = { spdamage = 1 },  -- 亮茄魔杖/Brightshade Staff
    houndstooth_blowpipe = { damage = 1, spdamage = 1 },              -- 嚎弹炮/Howlitzer


    nightsword = { damage = 1, shadowlevel = 1, shadow = 1, stronggrip = 1  }, -- 暗夜剑/Dark Sword
    rabbitkingspear = { manrabbitscarer = true, predamage = 0.005  }, -- 兔王棍/Rabbit King Cudgel
    trident = { externaldamage = 0.05, predamage = 0.005, treadwater = 1 }, -- 刺耳三叉戟/Strident Trident
    batbat = { bloodsucking = 0.01, stronggrip = 1 }, -- 蝙蝠棒/Bat Bat
    nightstick = { electricattack = true, light = 1, stronggrip = 1, nightvision = 1 }, -- 晨星锤/Morning Star
    
    armor_carrotlure = { hidesmeats = true },         -- 胡萝卜外套/Coat of Carrots
    deserthat = { goggles = true, stronghead = 1 },          -- 沙漠护目镜/Desert Goggles
    moonstorm_goggleshat = { goggles = true, moonstormevent_detector = true }, -- 星象护目镜/Astroggles
    yellowamulet = { speed = 0.1, light = 1, nightvision = 1, fastbuilder = 1 }, -- 魔光护符/Magiluminescence
    chestupgrade_stacksize = { stacksize = true }, -- 弹性空间制造器/Elastispacer
    voidcloth_umbrella = { acidrainimmune = true }, -- 暗影伞/Umbralla
    amulet = { health = 1, rebirth = true, fastbuilder = 1 }, -- 重生护符/Life Giving Amulet
    orangeamulet = { dapperness = 1, fastbuilder = 1 }, -- 懒人护符/The Lazy Forager
    greenamulet = { ingredientmod = 0.05, max = 10, fastbuilder = 1 }, -- 建造护符/Construction Amulet
    purpleamulet = { zerosanity = true, shadowlevel = 1, shadow = 1, fastbuilder = 1 }, -- 梦魇护符/Nightmare Amulet
    scrap_monoclehat = { extraview = 5, max = 3 }, -- 视界扩展器/Horizon Expandinator
    spiderhat = { creep = true, spiderdisguise = true, stronghead = 1 }, -- 蜘蛛帽/Spiderhat
    icestaff = { firedreduction = 0.25 }, -- 冰魔杖/Ice Staff
    firestaff = { freeze_res = 1 }, -- 火魔杖/Fire Staff
    rabbithat = { rabbitdisguise = true }, -- 洞穴花环/Warren Wreath
    lavae_egg = { freeze_res = 1 }, -- 岩浆虫卵/Lavae Egg
    -- lavae_egg_cracked = { freeze_res = 1 }, -- 正在孵化的岩浆虫卵/Lavae Egg
    malbatross_feathered_weave = { treadwater = 1 }, -- 羽毛帆布/Feathery Canvas
    shadowheart = { voidwalk = 1 }, -- 暗影心房/Shadow Atrium
    shadowheart_infused = { voidwalk = 1 }, -- 附身暗影心房/Possessed Shadow Atrium
    panflute = { sleep_res = 5 }, -- 排箫/Pan Flute
    atrium_key = { voidwalk = 1, not_remove = true }, -- 远古钥匙/Ancient Key
    antlionhat = { walksinkhole = true, stronghead = 1 }, -- 刮地皮头盔/Turf-Raiser Helm
    wagdrone_rolling = { chopwork = 0.2, minework = 0.2 },   -- 螨地爬/Terramite
    
    alterguardianhat = { dapperness = 1, gestaltprotection = true, light = 1, gestaltattack = true, saresistance = 0.1 }, -- 启迪之冠/Enlightened Crown
    lunar_seed = { lunar = 1, max = 5 },     -- 天体珠宝/Celestial Jewel

    
    monkey_smallhat = { master_crewman = true, stronghead = 1 },     -- 海盗头巾/Pirate's Bandana
    monkey_mediumhat = { boat_health_buffer = true, stronghead = 1 },     -- 船长的三角帽/Captain's Tricorn
    onemanband = { tend = true },     -- 独奏乐器/One-man Band
    

    -- 沃拓克斯专属（小恶魔）
    wortox_nabbag = { damage = 1, role = "wortox" },  -- 强抢袋/Knabsack
    wortox_souljar = { souljar = true, role = "wortox" }, -- 灵魂罐/Soul Jar

    -- 薇格弗德专属（女武神）
    spear_wathgrithr = { damage = 1, role = "wathgrithr" },  -- 战斗长矛/Battle Spear
    wathgrithr_shield = { damage = 1, role = "wathgrithr" },  -- 战斗圆盾/Battle Rönd
    wathgrithr_improvedhat = { defense = 0.05, role = "wathgrithr"  },  -- 统帅头盔/Commander's Helm
    spear_wathgrithr_lightning = { damage = 1, role = "wathgrithr" },  -- 奔雷矛/Elding Spear
    spear_wathgrithr_lightning_charged = { spdamage = 2, role = "wathgrithr" },  -- 充能奔雷矛/Elding Spear Charged

    -- 沃尔夫冈专属（大力士）
    dumbbell_gem = { mightiness = 0.2, role = "wolfgang"  }, -- 宝石哑铃/Gembell
    dumbbell_heat = { kc = 5,kw = 5, mightiness = 0.1, role = "wolfgang"  }, -- 热铃/Thermbell
    dumbbell_redgem = { kw = 10, mightiness = 0.1, role = "wolfgang"  }, -- 火铃/Firebell
    dumbbell_bluegem = { kc = 10, mightiness = 0.1, role = "wolfgang"  }, -- 冰铃/Icebell

    -- 伍迪专属
    lucy = { chopwork = 0.2, damage = 1,not_remove = true, role = "woodie"  },  --露西斧/Lucy the Axe
    woodcarvedhat = { defense = 0.05, role = "woodie"  },  -- 硬木帽/Hardwood Hat
    walking_stick = { speed = 0.05, role = "woodie"  },  -- 木手杖/Wooden Walking Stick

    -- 旺达专属
    pocketwatch_weapon = { damage = 2, role = "wanda"  },  -- 警钟/Alarming Clock

    -- 沃尔特专属
    slingshot = { damage = 1, role = "walter" },  -- 可靠的弹弓/Trusty Slingshot

    -- 温蒂专属
    ghostflowerhat = { ghost_ally = true, role = "wendy"  }, -- 幽魂花冠/Wraith's Wreath

    -- WX78专属
    wx78module_light = { light = 1, role = "wx78"  }, -- 照明电路/Illumination Circuit
    wx78module_nightvision = { light = 1, role = "wx78"  }, -- 光电电路/Optoelectronic Circuit
    wx78module_taser = { insulated = true, basereflect = 5,  role = "wx78"  }, -- 电气化电路/Electrification Circuit
    wx78module_cold = { kw = 30, role = "wx78"  }, -- 制冷电路/Refrigerant Circuit
    wx78module_heat = { kc = 30, role = "wx78"  }, -- 热能电路/Thermal Circuit
    wx78module_movespeed2 = { speed = 0.1, role = "wx78"  }, -- 超级加速电路/Super-Acceleration Circuit
    wx78module_movespeed = { speed = 0.05, role = "wx78"  }, -- 加速电路/Acceleration Circuit

    -- 沃特专属（小鱼妹）
    -- mermhat = { mermdisguise = true },-- 聪明的伪装/Clever Disguise

    -- 沃姆伍德专属（植物人）
    armor_bramble = { defense = 0.05, bramble_resistant = true, basereflect = 5, aoereflect = 1, role = "wormwood"  }, -- 荆棘外壳/Bramble Husk
    armor_lunarplant_husk = { defense = 0.05, planardefense = 5, basereflect = 5, planarreflect = 5, specialreflect = 0.01, role = "wormwood"  }, -- 荆棘茄甲/Brambleshade Armor

    -- 薇洛
    lighter = { freeze_res = 1, light = 1, role = "willow" },  -- 薇洛的打火机/Willow's Lighter

    -- 沃利
    -- spicepack = { preserver = 0.1 }  -- 厨师袋/Chef Pouch
    portableblender_item = { food_add = 0.1, role = "warly"  },  -- 便携研磨器/Portable Grinding Mill
    portablespicer_item = { food_add = 0.1, role = "warly"  },  -- 便携香料站/Portable Seasoning Station
    portablecookpot_item = { food_add = 0.1, role = "warly"  },  -- 便携烹饪锅/Portable Crock Pot

    -- 麦斯威尔
    waxwelljournal = { damage = 1, spdamage = 1, shadowlevel = 1, role = "waxwell"  },  --暗影秘典/Codex Umbra

    
    hermit_pearl = { light = 1, saresistance = 0.1, dapperness = 1, waterproof = 0.5, kw = 30, kc = 30, speed = 0.05, health = 1, treadwater = 1, not_remove = true, except = "hermit_cracked_pearl" }, -- 珍珠的珍珠/Pearl's Pearl
    
    hermit_cracked_pearl = { light = 1, saresistance = 0.1, dapperness = 1, waterproof = 0.5, kw = 30, kc = 30, speed = 0.05, health = 1, treadwater = 1, not_remove = true, except = "hermit_pearl" }, -- 开裂珍珠/Cracked Pearl
    

    -- goose_feather = { level = 1, kc = 10 }, -- 麋鹿鹅羽毛/Down Feather
    -- dragon_scales = { level = 1, kw = 10 }, -- 鳞片/Scales
    -- bearger_fur = { level = 1, kw = 10 }, -- 熊皮/Thick Fur
    -- deerclops_eyeball = { level = 1, kc = 10 }, -- 独眼巨鹿眼球/Deerclops Eyeball
    minotaurhorn = { beefalo = true, saresistance = 0.1 }, -- 守护者之角/Guardian's Horn


    trunkvest_winter = { kw = 30 },         -- 松软背心/Puffy Vest

    pig_coin = { fightpig = true },         -- 猪鼻铸币/Pig Coin

    
    sweatervest = { houndfriend = true },  -- 犬牙背心/Dapper Vest


    -- 勋章兼容
    sanityrock_mace = { chaos_damage = 1, mod = "medal" }, -- 方尖锏
    armor_medal_obsidian = { chaos_defense = 1, mod = "medal" }, -- 红晶甲
    armor_blue_crystal = { chaos_defense = 1, mod = "medal" }, -- 蓝晶甲
    immortal_gem = { chaos_bonus = 1,max = 5, mod = "medal"},-- 不朽宝石

    -- SPECIAL_EVENTS =
    -- {
    --     NONE = "none",
    --     HALLOWED_NIGHTS = "hallowed_nights",
    --     WINTERS_FEAST = "winters_feast",
    --     CARNIVAL = "crow_carnival",
    --     YOTG = "year_of_the_gobbler",
    --     YOTV = "year_of_the_varg",
    --     YOTP = "year_of_the_pig",
    --     YOTC = "year_of_the_carrat",
    --     YOTB = "year_of_the_beefalo",
    --     YOT_CATCOON = "year_of_the_catcoon",
    --     YOTR = "year_of_the_bunnyman",
    --     YOTD = "year_of_the_dragonfly",
    --     YOTS = "year_of_the_snake",
    -- }

    -- 万圣节活动物品
    halloweenpotion_bravery_large = { bravery_buff = true, event = "HALLOWED_NIGHTS" },  -- 终止恐惧的药液/Brew of Phobic Abrogation

    -- 鸦年华活动物品
    carnival_vest_a = { kw = 15, event = "CARNIVAL" },  -- 叽叽喳喳围巾/Chirpy Scarf
    carnival_vest_b = { kc = 30, event = "CARNIVAL" },  -- 叽叽喳喳斗篷/Chirpy Cloak
    carnival_vest_c = { kc = 30, event = "CARNIVAL" },  -- 叽叽喳喳小披肩/Chirpy Capelet

    mask_princesshat = { princess_suit = 1, princessandknight = 1, event = "YOTH" },  -- 公主面具/Princess Mask
    costume_princess_body = { princess_suit = 1, princessandknight = 1, event = "YOTH" },      -- 公主服/Princess Costume
    yoth_knighthat = { knight_suit = 1, defense = 0.05,princessandknight = 1, event = "YOTH" },      -- 镀金骑士头盔/Golden Knight Helm
    armor_yoth_knight = { knight_suit = 1, defense = 0.05, princessandknight = 1, event = "YOTH" },      -- 镀金骑士胸甲/Golden Knight Armor
    yoth_lance = { speed = 0.05, damage = 1,event = "YOTH" }, -- 冲锋骑枪/
    horseshoe = { luck = 0.05, max = 15, event = "YOTH" },  -- 幸运马蹄铁/Horseshoe


    -- 不可移动的物品
    icepack = { no_move = true, preserver = 0.1, add_slot_cols = 1 },         -- 保鲜背包/Insulated Pack
    spicepack = { no_move = true, preserver = 0.1, add_slot_cols = 1 },       -- 厨师袋/Chef Pouch
    piggyback = { no_move = true, add_slot_cols = 1 },        -- 猪皮包/Piggyback
    krampus_sack = { no_move = true, add_slot_cols = 2 },     -- 坎普斯背包/Krampus Sack
    -- backpack = { no_move = true },          -- 背包/Backpack
    
    stafflight = { no_move = true, kw = 30, dapperness = 0.5, light = 0.5 }, -- 矮星
    staffcoldlight = { no_move = true, kc = 30, dapperness = 0.5, light = 0.5 }, -- 极光

    
    dragonflyfurnace = { fire_slot = true, kw = 60, no_move = true, slot_lv = 1 },  -- 龙鳞火炉/Scaled Furnace
    deerclopseyeball_sentryward_kit = { snow_slot = true, kc = 60, slot_lv = 1 },  -- 冰眼结晶器套装/Ice Crystaleyezer Kit
    wagpunkbits_kit = { repair_slot = 1, repair_suit = 1, slot_lv = 1 },  -- 自动修理机/Auto-Mat-O-Chanic
    voidcloth_kit = { repair_slot = 2, repair_suit = 1, slot_lv = 1 },  -- 虚空修补套件/Void Repair Kit
    lunarplant_kit = { repair_slot = 2, repair_suit = 1, slot_lv = 1 },  -- 亮茄修补套件/Brightshade Repair Kit

    
    researchlab = { no_move = true, recipe1 = true, base_science = true }, -- 科学机器/Science Machine
    seafaring_prototyper = { no_move = true, recipe1_boat = true, base_science = true }, -- 智囊团/Think Tank
    researchlab4 = { no_move = true, recipe1_magic = true, base_science = true }, -- 灵子分解器/Prestihatitator

    researchlab2 = { no_move = true, recipe2 = true, base_science = true }, -- 炼金引擎/Alchemy Engine
    researchlab3 = { no_move = true, recipe2_magic = true, base_science = true }, -- 暗影操控器/Shadow Manipulator
    moonrockseed = { recipe1_moon = true, not_remove = true, not_create = true }, -- 天体宝球/Celestial Orb

    -- ancient_altar_broken = { no_move = true, ancient_altar = true }, -- 损坏的远古伪科学站/Broken Ancient Pseudoscience Station
    ancient_altar = { no_move = true, recipe_ancient = true, not_remove = true }, -- 远古伪科学站/Ancient Pseudoscience Station
    lunar_forge = { no_move = true, recipe_lunar = true }, -- 辉煌铁匠铺/Brightsmithy
    shadow_forge = { no_move = true, recipe_shadow = true }, -- 暗影术基座/Shadowcraft Plinth
    -- lunar_forge_kit = { lunar_forge = true, except = "lunar_forge" }, -- 辉煌铁匠铺套装/Brightsmithy Kit
    moon_altar_astral = { no_move = true, recipe2_moon = true, except = "moon_altar", not_remove = true, not_create = true }, -- 天体圣殿/Celestial Sanctum
    moon_altar = { no_move = true, recipe2_moon = true, except = "moon_altar_astral", not_remove = true, not_create = true }, -- 天体祭坛/Celestial Altar
}
config.food_effects = {
    baconeggs = { hunger = 1.1, hp = 0.5 },  -- 培根煎蛋/Bacon and Eggs
    bananajuice = { hunger = 0.5, hp = 0.3, sanity = 0.7 },  -- 香蕉奶昔/Banana Shake
    bananapop = { kc = 5, hunger = 0.3, hp = 0.5, sanity = 0.7 },  -- 香蕉冻/Banana Pop
    barnaclepita = { hunger = 0.7, hp = 0.5 },  -- 藤壶皮塔饼/Barnacle Pita
    barnaclestuffedfishhead = { hunger = 1.1, hp = 0.5 },  -- 酿鱼头/Stuffed Fish Heads
    barnaclesushi = { hunger = 0.7, hp = 0.8, sanity = 0.4 },  -- 藤壶握寿司/Barnacle Nigiri
    barnaclinguine = { hunger = 1.1, hp = 0.6, sanity = 0.5 },  -- 藤壶中细面/Barnacle Linguine
    bonestew = { hunger = 1.7, hp = 0.4 },  -- 炖肉汤/Meaty Stew
    bunnystew = { hunger = 0.7, hp = 0.5 },  -- 炖兔子/Bunny Stew
    butterflymuffin = { hunger = 0.7, hp = 0.5 },  -- 蝴蝶松饼/Butter Muffin
    californiaroll = { hunger = 0.7, hp = 0.5, sanity = 0.3 },  -- 加州卷/California Roll
    ceviche = { hunger = 0.5, hp = 0.5 },  -- 酸橘汁腌鱼/Ceviche
    dragonpie = { hunger = 1.1, hp = 0.8 },  -- 火龙果派/Dragonpie
    figatoni = { hunger = 0.9, hp = 0.6, sanity = 0.4 },  -- 无花果意面/Figatoni
    figkabab = { hunger = 0.7, hp = 0.5, sanity = 0.3 },  -- 无花果烤串/Figkabab
    fishsticks = { hunger = 0.7, hp = 0.8 },  -- 炸鱼排/Fishsticks
    fishtacos = { hunger = 0.7, hp = 0.5 }, -- 鱼肉玉米卷/Fish Tacos
    flowersalad = { hunger = 0.3, hp = 0.8 },  -- 花沙拉/Flower Salad
    frogglebunwich = { hunger = 0.7, hp = 0.5 },  -- 蛙腿三明治/Froggle Bunwich
    frognewton = { hunger = 0.5, hp = 0.5 },  -- 无花果蛙腿三明治/Figgy Frogwich
    frozenbananadaiquiri = { hunger = 0.4, hp = 0.6, sanity = 0.4 },  -- 冰香蕉冻唇蜜/Frozen Banana Daiquiri
    fruitmedley = { hunger = 0.5, hp = 0.5 },  -- 水果圣代/Fruit Medley
    guacamole = { hunger = 0.7, hp = 0.5 },  -- 鳄梨酱/Guacamole
    honeyham = { hunger = 1.1, hp = 0.6 },  -- 蜜汁火腿/Honey Ham
    honeynuggets = { hunger = 0.7, hp = 0.5 },  -- 蜜汁卤肉/Honey Nuggets
    hotchili = { kw = 5, hunger = 0.7, hp = 0.5 },  -- 辣椒炖肉/Spicy Chili
    icecream = { hunger = 0.5, sanity = 1.0 }, -- 冰淇淋/Ice Cream 
    jammypreserves = { hunger = 0.7 }, -- 果酱/Fist Full of Jam 
    justeggs = { hunger = 0.8 },  -- 普通煎蛋/Plain Omelette
    kabobs = { hunger = 0.7 },  -- 肉串/Kabobs
    koalefig_trunk = { hunger = 1.7, hp = 1.0, sanity = 0.4 },  -- 无花果酿象鼻/Fig-Stuffed Trunk
    leafloaf = { hunger = 0.7, hp = 0.3 },  -- 叶肉糕/Leafy Meatloaf
    leafymeatburger = { hunger = 0.7, hp = 0.6, sanity = 0.7 },  -- 素食堡/Veggie Burger
    leafymeatsouffle = { hunger = 0.7, sanity = 1.0 },  -- 果冻沙拉/Jelly Salad
    lobsterbisque = { hunger = 0.5, hp = 1.0, sanity = 0.3 },  -- 龙虾浓汤/Lobster Bisque
    lobsterdinner = { hunger = 0.7, hp = 1.0, sanity = 1.0 },  -- 龙虾正餐/Lobster Dinner
    mandrakesoup = { sleep_res = 1, hunger = 1.7, hp = 1.4 },  -- 曼德拉草汤/Mandrake Soup
    mashedpotatoes = { hunger = 0.7, hp = 0.5, sanity = 0.7 },  -- 奶油土豆泥/Creamy Potato Purée
    meatballs = { hunger = 0.9 },  -- 肉丸/Meatballs
    meatysalad = { hunger = 1.1, hp = 0.8 },  -- 牛肉绿叶菜/Beefy Greens
    monsterlasagna = { hunger = 0.7 },  -- 怪物千层面/Monster Lasagna
    pepperpopper = { hunger = 0.5, hp = 0.6 },  -- 爆炒填馅辣椒/Stuffed Pepper Poppers
    perogies = { hunger = 0.7, hp = 0.8 },  -- 波兰水饺/Pierogi
    potatotornado = { hunger = 0.7, sanity = 0.4 },  -- 花式回旋块茎/Fancy Spiralled Tubers
    pumpkincookie = { hunger = 0.7, sanity = 0.4 },  -- 南瓜饼干/Pumpkin Cookies
    ratatouille = { hunger = 0.5 },  -- 蔬菜杂烩/Ratatouille
    salsa = { hunger = 0.5, sanity = 0.7 },  -- 生鲜萨尔萨酱/Salsa Fresca
    seafoodgumbo = { hunger = 0.7, hp = 0.8, sanity = 0.5 },  -- 海鲜浓汤/Seafood Gumbo
    shroombait = { sleep_res = 1, hunger = 0.4 }, -- 酿夜帽/Stuffed Night Cap 
    shroomcake = { sleep_res = 1, hunger = 0.5, sanity = 0.3 },  -- 蘑菇蛋糕/Mushy Cake
    stuffedeggplant = { hunger = 0.7 },  -- 酿茄子/Stuffed Eggplant
    surfnturf = { hunger = 0.7, hp = 1.0, sanity = 0.7 },  -- 海鲜牛排/Surf 'n' Turf
    taffy = { hunger = 0.5, sanity = 0.4 }, -- 太妃糖/Taffy
    talleggs = { hunger = 1.7, hp = 1.0 },  -- 苏格兰高鸟蛋/Tall Scotch Eggs
    turkeydinner = { hunger = 1.1, hp = 0.5 },  -- 火鸡正餐/Turkey Dinner
    unagi = { hunger = 0.7, hp = 0.5 },  -- 鳗鱼料理/Unagi
    veggieomlet = { hunger = 0.7, hp = 0.5 },  -- 早餐锅/Breakfast Skillet
    vegstinger = { hunger = 0.5, sanity = 0.7 },  -- 蔬菜鸡尾酒/Vegetable Stinger
    waffles = { hunger = 0.7, hp = 1.0 },  -- 华夫饼/Waffles
    asparagussoup = { hunger = 0.4, hp = 0.5 },  -- 芦笋汤/Asparagus Soup
    watermelonicle = { hunger = 0.3, sanity = 0.5 },  -- 西瓜冰棍/Melonsicle
    trailmix = { hunger = 0.3, hp = 0.6 },  -- 什锦干果/Trail Mix

    -- 大厨料理,加成翻倍
    frogfishbowl = { hunger = 1.3, hp = 1.0 }, -- 蓝带鱼排/Fish Cordon Bleu
    voltgoatjelly = { hunger = 1.3, sanity = 0.7, externaldamage = 0.01 }, -- 伏特羊肉冻/Volt Goat Chaud-Froid
    dragonchilisalad = { hunger = 1.0, sanity = 0.7, kw = 10 }, -- 辣龙椒沙拉/Hot Dragon Chili Salad
    gazpacho = { hunger = 1.0, sanity = 0.7, kc = 10 }, -- 芦笋冷汤/Asparagazpacho
    glowberrymousse = { hunger = 1.3, sanity = 0.7, light = 0.3 }, -- 发光浆果慕斯/Glow Berry Mousse
    moqueca = { hunger = 2.7, hp = 2.0, sanity = 1.5 }, -- 海鲜杂烩/Moqueca
    bonesoup = { hunger = 3.3, hp = 1.3 }, -- 骨头汤/Bone Bouillon
    monstertartare = { hunger = 1.9 }, -- 怪物鞑靼/Monster Tartare
    potatosouffle = { hunger = 1.3, hp = 1.0, sanity = 0.9 }, -- 蓬松土豆蛋奶酥/Puffed Potato Soufflé
    freshfruitcrepes = { hunger = 3.3, hp = 2.0, sanity = 0.9 }, -- 鲜果可丽饼/Fresh Fruit Crepes
    nightmarepie = { sanity = 1.0, hp = 1.0 }, -- 恐怖国王饼/Grim Galette

    -- 特殊食物，固定加成
    powcake = { hunger = 0.2 },  -- 芝士蛋糕/Powdercake
    beefalofeed = { hunger = 0.2 },  -- 蒸树枝/Steamed Twigs
    beefalotreat = { hunger = 0.2 },  -- 皮弗娄牛零食/Beefalo Treats
    sweettea = { sanity = 0.5 },  -- 舒缓茶/Soothing Tea
    wetgoop = { hunger = 0.2 },  -- 潮湿黏糊/Wet Goop
    batnosehat = { sanity = 1 },  -- 牛奶帽/Milkmade Hat
    dustmeringue = { hp = 1, sanity = 1, hunger = 1 }, -- 琥珀美食/Amberosia  
    jellybean = { hp = 1, health = 0.1 },  -- 彩虹糖豆/Jellybeans
    
    -- 冬季盛宴菜肴
    berrysauce = { hp = 0.5, sanity = 0.5, hunger = 0.5, event = "WINTERS_FEAST" }, -- 快乐浆果酱/Merry Berrysauce
    bibingka = { hp = 0.5, sanity = 0.5, hunger = 0.5, event = "WINTERS_FEAST" }, -- 比宾卡米糕/Bibingka
    cabbagerolls = { hp = 0.5, sanity = 0.5, hunger = 0.5, event = "WINTERS_FEAST" }, -- 白菜卷/Cabbage Rolls
    festivefish = { hp = 0.5, sanity = 0.5, hunger = 0.5, event = "WINTERS_FEAST" }, -- 节庆鱼料理/Festive Fish Dish
    gravy = { hp = 0.5, sanity = 0.5, hunger = 0.5, event = "WINTERS_FEAST" }, -- 好肉汁/Good Gravy
    latkes = { hp = 0.5, sanity = 0.5, hunger = 0.5, event = "WINTERS_FEAST" }, -- 土豆饼/Latkes
    lutefisk = { hp = 0.5, sanity = 0.5, hunger = 0.5, event = "WINTERS_FEAST" }, -- 苏打鱼/Lutefisk
    mulleddrink = { hp = 0.5, sanity = 0.5, hunger = 0.5, event = "WINTERS_FEAST" }, -- 香料潘趣酒/Mulled Punch
    panettone = { hp = 0.5, sanity = 0.5, hunger = 0.5, event = "WINTERS_FEAST" }, -- 托尼甜面包/Panettone
    pavlova = { hp = 0.5, sanity = 0.5, hunger = 0.5, event = "WINTERS_FEAST" }, -- 巴甫洛娃蛋糕/Pavlova
    pickledherring = { hp = 0.5, sanity = 0.5, hunger = 0.5, event = "WINTERS_FEAST" }, -- 腌鲱鱼/Pickled Herring
    polishcookie = { hp = 0.5, sanity = 0.5, hunger = 0.5, event = "WINTERS_FEAST" }, -- 波兰饼干/Polish Cookies
    pumpkinpie = { hp = 0.5, sanity = 0.5, hunger = 0.5, event = "WINTERS_FEAST" }, -- 南瓜派/Pumpkin Pie
    roastturkey = { hp = 0.5, sanity = 0.5, hunger = 0.5, event = "WINTERS_FEAST" }, -- 烤火鸡/Roasted Turkey
    stuffing = { hp = 0.5, sanity = 0.5, hunger = 0.5, event = "WINTERS_FEAST" }, -- 烤火鸡面包馅/Stuffing
    sweetpotato = { hp = 0.5, sanity = 0.5, hunger = 0.5, event = "WINTERS_FEAST" }, -- 红薯焗饭/Sweet Potato Casserole
    tamales = { hp = 0.5, sanity = 0.5, hunger = 0.5, event = "WINTERS_FEAST" }, -- 塔马利/Tamales
    tourtiere = { hp = 0.5, sanity = 0.5, hunger = 0.5, event = "WINTERS_FEAST" }, -- 饕餮馅饼/Tourtiere


    -- 兔人之年
    yotr_food1 = { hp = 0.3, sanity = 0.1, hunger = 1.1, event = "YOTR" },    -- 兔子卷/Bunny Roll
    yotr_food2 = { hp = 1, sanity = 0.1, hunger = 0.3, event = "YOTR" },    -- 月饼/Moon Cake
    yotr_food3 = { hp = 0.3, sanity = 0.7, hunger = 0.3, event = "YOTR" },    -- 月冻/Moon Jelly

    -- 猪王之年
    yotp_food1 = { hunger = 1.7, event = "YOTP" },    -- 贡品烤肉/Tribute Roast
    yotp_food2   = { hunger = 1.7, event = "YOTP" },    -- 八宝泥馅饼/Eight Treasure Mud Pie
    yotp_food3 = { hunger = 1.1, event = "YOTP" },    -- 鱼头串/Fish Heads on a Stick
}
if TUNING.DEVOURER_PACK_FOOD_MAX > 0 then
    for prefab, effect in pairs(config.food_effects) do
        effect.enab = false
        effect.max = TUNING.DEVOURER_PACK_FOOD_MAX
        if not effect.cr then 
            effect.cur = 0
        end
        config.upgrade_effects[prefab] = effect
    end
end

-- 初始化 enab,show 字段
for prefabKey, effect in pairs(config.upgrade_effects) do
    effect.enab = false
    if effect.max and not effect.cur then
        effect.cur = 0
    end
    -- 默认 show = false（除非至少有一个 key 通过）
    effect.show = false
    if config.NotShowUnItems[prefabKey] or config.level_up.lv1.item[prefabKey] or config.level_up.lv2.item[prefabKey] then
        effect.show = true-- 开关类物品默认开启
    end
    -- 遍历 effect 的所有 key（如 kw, kc, light 等）
    for effectKey, _ in pairs(effect) do
        if not config.excluded_attrs[effectKey] then
            -- 获取 TUNING.DEVOURER_PACK_EFFECT 里的对应值
            local tuning_key
            local tuning_value
            if effectKey == "hp" or effectKey == "hunger" or effectKey == "sanity" then
                tuning_value = TUNING.DEVOURER_PACK_FOOD_MAX
            else  
                tuning_key = string.upper(effectKey)
                tuning_value = TUNING.DEVOURER_PACK_EFFECT[tuning_key]
            end
            local passKey
            -- 判断是否通过：
            -- 1. 如果 tuning_value 不存在 → 默认通过
            -- 2. 如果 tuning_value 是 true → 通过
            -- 3. 如果 tuning_value 是数值且 ≠ 0 → 通过
            -- 其他情况（false 或 0）→ 不通过
            local is_passed = false
            if tuning_value == nil then
                is_passed = true  -- 不存在默认通过
                passKey = effectKey
            elseif tuning_value == true then
                is_passed = true  -- true 通过
                passKey = effectKey
            elseif type(tuning_value) == "number" and tuning_value ~= 0 then
                is_passed = true  -- 非零数值通过
                passKey = effectKey
            end
            
            -- 如果当前 key 通过，则整个 effect.show = true
            if is_passed then
                effect.show = true
                break  -- 只要有一个 key 通过，就可以跳出循环
            end
        end
    end
    
    -- 记录最终的show状态
    -- print("[DevourerPack] Final show status for " .. prefabKey .. ": " .. tostring(effect.show))
end

config.suits = {
    season = 4,
    ruins = 2,
    skeleton = 2,
    lunarplant = 2,
    dreadstone = 2,
    miasmaimmune = 2,
    overlord = 10,
    monkey_token = 5,
    terraria = 2,
    season_fish = 4,
    shadow = 6,
    stronggrip = 6,
    stronghead = 25,
    snail = 2,
    warbis = 2,
    nightvision = 4,
    fastbuilder = 6,
    repair_suit = 3,
    princess_suit = 2,
    knight_suit = 2,
    princessandknight = 4,
    mightiness_mighty = 3,
    -- slot_lv = 5,
    vegetarian = 32,
    carnivore = 32,
    appetizer = 11,
}
config.pack_slot_set = {
    [1] = Vector3(3,9,1),
    [2] = Vector3(3,8,1),
    [3] = Vector3(3,7,1),
    [4] = Vector3(3,6,1),
    [5] = Vector3(3,5,1),
    [6] = Vector3(2,9,1),
    [7] = Vector3(2,8,1),
    [8] = Vector3(2,7,1),
}
config.mod_check = {
    medal = "",    -- 能力勋章
}
config.mod_icon = {
    [1] = "devourer_pack",  -- 坨坨脸
    [2] = "devourer_cats",  -- 太极猫猫

}
--AOE伤害不造成伤害清单
config.ignoreList={
	"INLIMBO",--在容器里的
	"notarget",--无法选中目标的
	"noattack",--无法攻击的
	"flight",--飞行中的
	"invisible",--看不见的
	"playerghost",--玩家变成的鬼
	"abigail",--阿比盖尔
	"glommer",--格罗姆
	"companion",--同伴
    "player",
}
config.key_binds = {
    AreaAttack = 1,     -- 范围攻击
    Reflect = 2,        -- 范围反伤
    SanityChange = 3,   -- 精神状态变化
    TreadWater = 4,     -- 踏水
    Summon = 5,         -- 召唤猪人
    NightVision = 6,         -- 夜视
    KeepTemp = 7,         -- 保持温度
    ExtraDamge = 8,         -- 额外伤害
    DevourerBee = 9,         -- 杀人蜂开关
}
-- 反向映射表（索引 -> 功能名）
config.key_binds_by_index = {}
for name, index in pairs(config.key_binds) do
    config.key_binds_by_index[index] = name
end

config.pack_control_list = {
    AreaAttack = {"area_attack_on", "area_attack_off"},
    Reflect = {"reflect_on", "reflect_off"},
}

-- 为升级效果创建简写映射表
config.upgrade_effects_short_names = {}
config.upgrade_effects_by_short_name = {}
local index = 1

-- 为升级效果物品分配简写名称
for prefab, _ in pairs(config.upgrade_effects) do
    local short_name = "k" .. tostring(index)
    config.upgrade_effects_short_names[prefab] = short_name
    config.upgrade_effects_by_short_name[short_name] = prefab
    index = index + 1
end

-- 1. 定义数组型表：核心存储，方便随机获取
config.alchemy_change_items_array = {
    "cutgrass","twigs","log","cutreeds","driftwood_log","foliage","petals", "petals_evil","lightbulb","wormlight","wormlight_lesser", -- 植物系列
    "flint", "rocks", "nitre", "goldnugget", "gears", "saltrock", "nightmarefuel", "marble","fossil_piece","townportaltalisman", -- 矿石系列
    "redgem", "bluegem", "greengem", "orangegem", "yellowgem", "purplegem", "opalpreciousgem", -- 宝石系列
    "spore_medium","spore_small","spore_tall","spore_moon", -- 孢子系列
    "purebrilliance","moonglass_charged","lunarplant_husk","moonglass","moonrocknugget","lunar_seed", -- 月亮系列
    "voidcloth","horrorfuel","dreadstone","shadowheart","shadowheart_infused", -- 黑暗系列
    "thulecite","thulecite_pieces", -- 远古系列
    --  "transistor", "cutstone","rope","boards", -- 合成材料系列
    -- "ghostflower","beardhair","silk", -- 角色材料
    "spoiled_food","bird_egg","meat","smallmeat","trunk_summer","trunk_winter","monstermeat","honey","seeds","plantmeat","royal_jelly",
        "fig","barnacle","froglegs","cave_banana","berries","berries_juicy","fishmeat","fishmeat_small","milkywhites","red_cap","green_cap","blue_cap","moon_cap", -- 食物材料
    "steelwool","silk","houndstooth","feather_crow","feather_robin","feather_robin_winter","stinger","tentaclespots",
        "coontail","cutlichen","slurtleslime","slurtle_shellpieces","slurtlehusk","slurtle_mucus","deer_antler","walrus_tusk",
        "feather_canary","beefalowool","livinglog","boneshard","pigskin","manrabbit_tail","pig_token","slurper_pelt","gnarwail_horn", -- 生物材料
    "goose_feather","malbatross_feather","dragon_scales","bearger_fur","furtuft","deerclops_eyeball","minotaurhorn","shroom_skin","klaussackkey", -- Boss材料
    "pig_coin","trinket_6","wagpunk_bits","spidereggsack", -- 特殊材料
    "alterguardianhat","eyemaskhat","shieldofterror","scrap_monoclehat","spiderhat","malbatross_beak","hivehat","blowdart_pipe","walrushat","ghostflowerhat",
    "rabbitkingspear","armor_carrotlure","rabbithat","rabbitkinghorn", -- 装备
}

-- 2. 自动生成哈希表：用于快速判断存在性（无需手动维护）
config.alchemy_change_items_map = {}
for _, item in ipairs(config.alchemy_change_items_array) do
    config.alchemy_change_items_map[item] = true
end

return config
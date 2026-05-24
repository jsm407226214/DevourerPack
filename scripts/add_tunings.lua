-- 语言
TUNING.DEVOURER_PACK_CHECK = true -- 用于其他模组校验判断吞噬者背包是否加载，这个配置项无实际意义，只做标记用，不会移除变动

TUNING.MOD_LANGUAGE = GetModConfigData("mod_language")
-- 图标
TUNING.DEVOURER_ICON = GetModConfigData("devourer_icon")
-- 吞噬者背包最大格子
TUNING.DEVOURER_PACK_MAX_SLOTS = GetModConfigData("devourer_pack_max_slots") or 1
-- 吞噬者背包制作难度
TUNING.RECIPE_DIFFICULTY = GetModConfigData("recipe_difficulty")
-- 可吞噬食物的最大次数
TUNING.DEVOURER_PACK_FOOD_MAX = GetModConfigData("devourer_pack_food_max")
-- 背包说话
TUNING.DEVOURER_PACK_SAY = GetModConfigData("devourer_pack_say")
-- 打印日志
TUNING.DEVOURER_DEBUG = GetModConfigData("devourer_pack_debug")
-- 功能切换
TUNING.DEVOURER_PACK_FUNCTION_KEY = GetModConfigData("devourer_pack_function_key")
-- 状态切换
TUNING.DEVOURER_PACK_STATUS_KEY = GetModConfigData("devourer_pack_status_key")

TUNING.DEVOURER_PIG_KING_MODIFY = GetModConfigData("devourer_pig_king_modify")
TUNING.DEVOURER_PIG_MAX_SCALE = GetModConfigData("devourer_pig_max_scale") or 2.0

TUNING.DEVOURER_PACK_DEFAULT_LEVEL = GetModConfigData("devourer_pack_default_level") or 1

TUNING.DEVOURER_PACK_MIN_COLS = 2 -- 背包最小列数（2列是最小功能背包）
TUNING.DEVOURER_PACK_BASE_ROWS = GetModConfigData("devourer_pack_base_rows") or 2

TUNING.DEVOURER_TECH = GetModConfigData("devourer_tech")

TUNING.DEVOURER_PACK_EFFECT = {
    SPEED = GetModConfigData("devourer_pack_effect_speed") or -1,
    WATERPROOF = GetModConfigData("devourer_pack_effect_waterproof"),
    HUNGER_RATE = GetModConfigData("devourer_pack_effect_hunger_rate"),
    PRESERVER = GetModConfigData("devourer_pack_effect_preserver"),
    DEFENSE = GetModConfigData("devourer_pack_effect_defense") or 0.95,
    EXTERNALDAMAGE = GetModConfigData("devourer_pack_effect_externaldamage"),
    SARESISTANCE = GetModConfigData("devourer_pack_effect_saresistance"),
    BLOODSUCKING = GetModConfigData("devourer_pack_effect_bloodsucking"),
    FIREDREDUCTION = GetModConfigData("devourer_pack_effect_firedreduction"),
    MINWORK = GetModConfigData("devourer_pack_effect_minework"),
    CHOPWORK = GetModConfigData("devourer_pack_effect_chopwork"),
    HAMMERWORK = GetModConfigData("devourer_pack_effect_hammerwork"),
    MIGHTINESS = GetModConfigData("devourer_pack_effect_mightiness"),
    INGREDIENTMOD = GetModConfigData("devourer_pack_effect_ingredientmod"),
    FOOD_ADD = GetModConfigData("devourer_pack_effect_food_add"),
    
    KW = GetModConfigData("devourer_pack_effect_kw"),
    KC = GetModConfigData("devourer_pack_effect_kc"),
    LIGHT = GetModConfigData("devourer_pack_effect_light"),
    INSULATED = GetModConfigData("devourer_pack_effect_insulated"),
    DAPPERNESS = GetModConfigData("devourer_pack_effect_dapperness"),
    RESISTANCE = GetModConfigData("devourer_pack_effect_resistance"),
    SHADOWDOMINANCE = GetModConfigData("devourer_pack_effect_shadowdominance"),
    PLANARDEFENSE = GetModConfigData("devourer_pack_effect_planardefense"),
    HEAVYARMOR = GetModConfigData("devourer_pack_effect_heavyarmor"),
    BRIER_RESISTANT = GetModConfigData("devourer_pack_effect_brier_resistant"),
    GOGGLES = GetModConfigData("devourer_pack_effect_goggles"),
    GESTALTPROTECTION = GetModConfigData("devourer_pack_effect_gestaltprotection"),
    GESTALTATTACK = GetModConfigData("devourer_pack_effect_gestaltattack"),
    ACIDRAINIMMUNE = GetModConfigData("devourer_pack_effect_acidrainimmune"),
    STACKSIZE = GetModConfigData("devourer_pack_effect_stacksize"),
    FORCEFIELD = GetModConfigData("devourer_pack_effect_forcefield"),
    JUNK = GetModConfigData("devourer_pack_effect_junk"),
    HEALTH = GetModConfigData("devourer_pack_effect_health"),
    EXTRAVIEW = GetModConfigData("devourer_pack_effect_extraview") or -1,
    BEEFALO = GetModConfigData("devourer_pack_effect_beefalo"),
    moonstormevent_detector = GetModConfigData("devourer_pack_effect_moonstormevent_detector"),
    CREEP = GetModConfigData("devourer_pack_effect_creep"),
    KEEPDROWN = GetModConfigData("devourer_pack_effect_keepdrown"),
    KEEPODEATH = GetModConfigData("devourer_pack_effect_keepondeath"),
    REBIRTH = GetModConfigData("devourer_pack_effect_rebirth"),
    SLEEP_RES = GetModConfigData("devourer_pack_effect_sleep_res"),
    MANRABBITSCARER = GetModConfigData("devourer_pack_effect_manrabbitscarer"),
    SPIDERDISGUISE = GetModConfigData("devourer_pack_effect_spiderdisguise"),
    ELECTRICATTACK = GetModConfigData("devourer_pack_effect_electricattack"),
    FREEZE_RES = GetModConfigData("devourer_pack_effect_freeze_res"),
    RABBITDISGUISE = GetModConfigData("devourer_pack_effect_rabbitdisguise"),
    TREADWATER = GetModConfigData("devourer_pack_effect_treadwater"),
    VOIDWALK = GetModConfigData("devourer_pack_effect_voidwalk"),
    BASEREFLECT = GetModConfigData("devourer_pack_effect_baserelfect"),
    PLANARREFLECT = GetModConfigData("devourer_pack_effect_planarreflect"),
    SPECIALREFLECT = GetModConfigData("devourer_pack_effect_specialreflect"),
    AOEREFLECT = GetModConfigData("devourer_pack_effect_aoereflect"),
    DAMAGE = GetModConfigData("devourer_pack_effect_damage"),
    SPDAMAGE = GetModConfigData("devourer_pack_effect_spdamage"),
    PREDAMAGE = GetModConfigData("devourer_pack_effect_predamage"),
    SOULJAR = GetModConfigData("devourer_pack_effect_souljar"),
    GHOST_ALLY = GetModConfigData("devourer_pack_effect_ghost_ally"),
    WALKSINKHOLE = GetModConfigData("devourer_pack_effect_walksinkhole"),
    WALKICE = GetModConfigData("devourer_pack_effect_walkice"),
    LUNAR = GetModConfigData("devourer_pack_effect_lunar"),
    ZEROSANITY = GetModConfigData("devourer_pack_effect_zerosanity"),
    SHADOWLEVEL = GetModConfigData("devourer_pack_effect_shadowlevel"),
    MASTER_CREWMAN = GetModConfigData("devourer_pack_effect_master_crewman"),
    BOAT_HEALTH_BUFFER = GetModConfigData("devourer_pack_effect_boat_health_buffer"),
    TEND = GetModConfigData("devourer_pack_effect_tend"),
    HIDESMEATS = GetModConfigData("devourer_pack_effect_hidesmeats"),
    FIGHTPIG = GetModConfigData("devourer_pack_effect_fightpig"),
    BRAVERY_BUFF = GetModConfigData("devourer_pack_effect_bravery_buff"),
    HOUNDFRIEND = GetModConfigData("devourer_pack_effect_houndfriend"),
    DEVOURER_BEE = GetModConfigData("devourer_pack_effect_devourer_bee"),
    FIRE_SLOT = GetModConfigData("devourer_pack_effect_fire_slot"),
    SNOW_SLOT = GetModConfigData("devourer_pack_effect_snow_slot"),
    REPAIR_SLOT = GetModConfigData("devourer_pack_effect_repair_slot"),
    LUCK = GetModConfigData("devourer_pack_effect_luck"),
    
    -- HP = GetModConfigData("devourer_pack_effect_hp"),
    -- SANITY = GetModConfigData("devourer_pack_effect_sanity"),
    -- HUNGER = GetModConfigData("devourer_pack_effect_hunger"),
    MIASMAIMMUNE = GetModConfigData("devourer_pack_effect_miasmaimmune"),
    MONKEY_TOKEN = GetModConfigData("devourer_pack_effect_monkey_token"),
    RUINS = GetModConfigData("devourer_pack_effect_ruins"),
    SEASON = GetModConfigData("devourer_pack_effect_season"),
    OVERLORD = GetModConfigData("devourer_pack_effect_overlord"),
    SEASON_FISH = GetModConfigData("devourer_pack_effect_season_fish"),
    TERRARIA = GetModConfigData("devourer_pack_effect_terraria"),
    SHADOW = GetModConfigData("devourer_pack_effect_shadow"),
    STRONGGRIP = GetModConfigData("devourer_pack_effect_stronggrip"),
    SNAIL = GetModConfigData("devourer_pack_effect_snail"),
    WARBIS = GetModConfigData("devourer_pack_effect_warbis"),
    NIGHTVISION = GetModConfigData("devourer_pack_effect_nightvision"),
    FASTBUILDER = GetModConfigData("devourer_pack_effect_fastbuilder"),
    REPAIR_SUIT = GetModConfigData("devourer_pack_effect_repair_suit"),
    PRINCESS_SUIT = GetModConfigData("devourer_pack_effect_princess_suit"),
    KNIGHT_SUIT = GetModConfigData("devourer_pack_effect_knight_suit"),
    PRINCESSANDKNIGHT = GetModConfigData("devourer_pack_effect_princessandknight"),
    MIGHTINESS_MIGHTY = GetModConfigData("devourer_pack_effect_mightiness_mighty"),

    
    LUNARPLANT = GetModConfigData("devourer_pack_effect_lunarplant"),
    DREADSTONE = GetModConfigData("devourer_pack_effect_dreadstone"),
    
    -- 勋章兼容
    -- CHAOS_DAMAGE = GetModConfigData("devourer_pack_effect_chaos_damage"),
    -- CHAOS_DEFENSE = GetModConfigData("devourer_pack_effect_chaos_defense"),
    -- CHAOS_BONUS = GetModConfigData("devourer_pack_effect_chaos_bonus"),
}

TUNING.DEVOURER_PACK_SOURCE = "devourer_pack"

TUNING.DEVOURER_PACK_WEAPON_BONUS = 
{
    MEDAL_DAMAGE_MULT = 3,
    KEY = "devourer_pack_weapon",
    VS_SHADOW = 1.1,
    VS_LUNAR = 1.1,
}

-- 猪人配置已迁移至 scripts/pig_config.lua
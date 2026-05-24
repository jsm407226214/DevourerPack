--是否为中文
local isCh = locale == "zh" or locale == "zhr"
-- Mod的名字
name = isCh and "吞噬者背包" or "Devourer Pack"
-- 作者名
author = "江湖书生敏而好学" 
-- Mod版本，可以自由设定任何值，但如果要在Steam更新自己的Mod，就必须和已经上传的Mod版本有差别。
version = "1.9.2"
-- mod描述
description = isCh and ([[
[版本: %s]
一个神奇的背包。
• 吞噬者并不是普通背包的功能升级，而是一个全新的背包，容器制作栏，无科技即可制作
• 通过吞噬指定物品提升背包等级，逐步解锁特殊功能
• 给金子会给你升级物品提示（进化材料全部吞噬就可以升级）+ 随机推荐物品（可能会推荐未生效效果物品）
• 给月岩可以告诉你目前的能力
• 踏水和虚空行走功能解锁之后，给予石头开关
• 范围反伤解锁之后，使用针刺开关（默认开启）
• 精神状态转换开启之后，使用噩梦燃料切换
• 请注意，即便没有解锁效果，物品也可以吞噬
    小心不要吞噬掉含有未解锁特殊效果的物品（譬如建造护符）

• 配置可以开启和关闭这些功能的使用，如果一个物品的所有功能都被关闭，则无法吞噬相关物品
]]):format(version)
or ([[
[Version: %s]
A magical backpack.
• Progressively unlock powers by consuming specific resources
• Gold Can Show LevelUp Items
• Moon Rock displays current abilities
• Rocks toggle TreadWater/VoidWalk
• Stinger toggles AoE reflect when unlocked
• After the sanity transformation is activated, use Nightmare Fuel to switch
• Warning: You can consume items even if they have no unlocked effects.
    Avoid consuming items with unusable effects.
]]):format(version)


-- Mod在klei论坛的地址，没有可以留空，但不可删除
forumthread = ""
-- Mod的API版本，当前联机版固定为10
api_version = 10
-- 兼容联机版，因为我们是做联机版Mod，所以此项为true
dst_compatible = true
-- 要求所有客户端都下载此Mod。当有需要发送给客户端的自定义数据时，此项为true。所谓自定义数据有两类，一是自定义动画和图片，二是自定义的网络变量。
all_clients_require_mod = true
-- Mod的图标xml文档路径，需要有对应文件存在，否则Mod图标会显示为空白。
icon_atlas = "modicon.xml"
-- Mod图标文件名称
icon = "modicon.tex"


-- 服务器过滤标签，会在其他人使用标签筛选功能时起作用，标签可以写英文也可以写中文，可以添加多个标签。
server_filter_tags = { 
    "背包"
} 

-- 越低加载越慢，如果有需要前置mod的，要比前置mod的优先级低
priority = 1

local function AddOpt(desc, data, hover)
	return { description = desc, data = data, hover = hover }
end
local thePanelKeys = {
	AddOpt("关闭", false),
	AddOpt("B", 98),
	AddOpt("C", 99),
	AddOpt("G", 103),
	AddOpt("H", 104),
	AddOpt("I", 105, "该项是饥荒检查自身皮肤的默认按键, 不怕冲突可以选"),
	AddOpt("J", 106),
	AddOpt("K", 107),
	AddOpt("L", 108),
	AddOpt("N", 110),
	AddOpt("O", 111),
	AddOpt("P", 112),
	AddOpt("R", 114),
	AddOpt("T", 116),
	AddOpt("V", 118),
	AddOpt("X", 120),
	AddOpt("Z", 122),
	AddOpt("减号-", 45),
	AddOpt("加号+", 61),
	AddOpt("鼠标 侧键A", 1005, "不同鼠标可能不生效"),
	AddOpt("鼠标 侧键B", 1006, "不同鼠标可能不生效"),
	AddOpt("关闭", false, " ↑↑↑ 上面不是有关闭按钮嘛 ↑↑↑ ,干嘛要在这里关"),
	AddOpt("<", 44, "小于号或者逗号"),
	AddOpt(">", 46, "大于号或者小数点"),
	AddOpt(":", 59, "冒号或者分号"),
	AddOpt("'", 39, "单引号或者双引号"),
	AddOpt("[", 91, "左括号"),
	AddOpt("]", 93, "右括号"),
	AddOpt("\\", 92, "右斜杠"),
	AddOpt("F1", 282),
	AddOpt("F2", 283),
	AddOpt("F3", 284),
	AddOpt("F4", 285),
	AddOpt("F5", 286),
	AddOpt("F6", 287),
	AddOpt("F7", 288),
	AddOpt("F8", 289),
	AddOpt("F9", 290),
	AddOpt("F10", 291),
	AddOpt("F11", 292),
	AddOpt("方向键(↑)", 273),
	AddOpt("方向键(↓)", 274),
	AddOpt("方向键(←)", 276),
	AddOpt("方向键(→)", 275),
	AddOpt("关闭", false, " ↑↑↑ 上面不是有关闭按钮嘛 ↑↑↑ ,干嘛要在这里关"),
	AddOpt("PageUp", 280, "PageUp"),
	AddOpt("PageDown", 281, "PageDown"),
	AddOpt("Home", 278, "Home"),
	AddOpt("Insert", 277, "Insert"),
	AddOpt("Delete", 127, "Delete"),
	AddOpt("End", 279, "End"),
	AddOpt("Pause", 19, "Pause"),
	AddOpt("Scroll Lock", 145, "Scroll Lock"),
	AddOpt("CAPSLOCK大写锁定", 301, "CAPSLOCK大写锁定"),
	AddOpt("左ALT", 308, "游戏默认的检查键, 请确保不冲突再使用此按键"),
	AddOpt("右ALT", 307, "游戏默认的检查键, 请确保不冲突再使用此按键"),
	AddOpt("左CTRL", 306, "左CTRL"),
	AddOpt("右CTRL", 305, "右CTRL"),
	AddOpt("右Shift", 303, "右Shift"),
	AddOpt("小键盘0", 256, "小键盘0"),
	AddOpt("小键盘1", 257, "小键盘1"),
	AddOpt("小键盘2", 258, "小键盘2"),
	AddOpt("小键盘3", 259, "小键盘3"),
	AddOpt("小键盘4", 260, "小键盘4"),
	AddOpt("小键盘5", 261, "小键盘5"),
	AddOpt("小键盘6", 262, "小键盘6"),
	AddOpt("小键盘7", 263, "小键盘7"),
	AddOpt("小键盘8", 264, "小键盘8"),
	AddOpt("小键盘9", 265, "小键盘9"),
	AddOpt("小键盘 .", 266, "小键盘 ."),
	AddOpt("小键盘 /", 267, "小键盘 /"),
	AddOpt("小键盘 *", 268, "小键盘 *"),
	AddOpt("小键盘 -", 269, "小键盘 -"),
	AddOpt("小键盘 +", 270, "小键盘 +"),
	AddOpt("关闭", false, " ↑↑↑ 上面不是有关闭按钮嘛 ↑↑↑ ,干嘛要在这里关"),
}

-- 首先定义boolKeys数组，包含true和false两个选项
local boolKeys = {
    { description = isCh and "开启" or "Enabled", data = true },
    { description = isCh and "关闭" or "Disabled", data = false }
}

-- 手动定义所有 Effect 的中英文名称
local effectNames = {
    kw = {zh = "保暖", en = "Warmth"},
    kc = {zh = "隔热", en = "Cooling"},
    light = {zh = "发光", en = "Light"},
    insulated = {zh = "绝缘", en = "Insulated"},
    dapperness = {zh = "理智恢复", en = "Sanity Restore"},
    resistance = {zh = "骨甲免伤", en = "Bone Armor Damage Reduction"},
    shadowdominance = {zh = "影怪无仇恨（影怪不主动攻击）", en = "Shadow Creatures No Aggro"},
    planardefense = {zh = "位面防御", en = "Planar Defense"},
    heavyarmor = {zh = "免疫击退", en = "Knockback Immunity"},
    bramble_resistant = {zh = "荆棘抗性", en = "Bramble Resistance"},
    goggles = {zh = "防风沙", en = "Sandstorm Protection"},
    gestaltprotection = {zh = "月灵忽视", en = "Ghost Ignored"},
    gestaltattack = {zh = "月灵助攻", en = "Ghost Assistance"},
    acidrainimmune = {zh = "酸雨免疫", en = "Acid Rain Immunity"},
    stacksize = {zh = "无限堆叠", en = "Infinite Stack Size"},
    forcefield = {zh = "力场护盾", en = "Force Field"},
    junk = {zh = "垃圾堆伤害免疫", en = "Junk Heap Damage Immunity"},
    health = {zh = "生命恢复", en = "Health Restore"},
    beefalo = {zh = "牛牛伪装（牛发情时不主动攻击）", en = "Beefalo Disguise"},
    moonstormevent_detector = {zh = "显示瓦格斯塔夫", en = "Show Wickerbottom"},
    creep = {zh = "蜘蛛巢不减速", en = "Spider Den No Slow"},
    rebirth = {zh = "复活", en = "Rebirth"},
    sleep_res = {zh = "昏睡抗性", en = "Sleep Resistance"},
    bloodsucking = {zh = "吸血", en = "Bloodsucking"},
    manrabbitscarer = {zh = "兔人恐惧（兔人不主动攻击，并且会主动远离）", en = "Rabbitman Fear"},
    spiderdisguise = {zh = "蜘蛛伪装（蜘蛛不主动攻击）", en = "Spider Disguise"},
    electricattack = {zh = "夜空中最亮的星（电击Buff）", en = "Brightest Star in the Night Sky"},
    freeze_res = {zh = "冰冻抗性", en = "Freeze Resistance"},
    rabbitdisguise = {zh = "兔子伪装（兔子不逃离）", en = "Rabbit Disguise"},
    treadwater = {zh = "踏水", en = "Tread Water"},
    voidwalk = {zh = "虚空行走", en = "Void Walk"},
    basereflect = {zh = "物理反射伤害", en = "Physical Reflect Damage"},
    planarreflect = {zh = "位面反射伤害", en = "Planar Reflect Damage"},
    specialreflect = {zh = "攻击者生命值反射伤害", en = "Attacker HP Reflect Damage"},
    aoereflect = {zh = "AOE反射伤害", en = "AOE Reflect Damage"},
    damage = {zh = "额外伤害", en = "Attack Damage"},
    spdamage = {zh = "额外位面伤害", en = "Planar Damage"},
    predamage = {zh = "额外百分比生命值伤害", en = "Percentage Health Damage"},
    -- souljar = {zh = "灵魂罐", en = "Soul Jar"},
    ghost_ally = {zh = "幽灵朋友", en = "Ghost Ally"},
    walksinkhole = {zh = "如履平地（蚁狮陷坑不减速）", en = "Walk on Sinkholes"},
    walkice = {zh = "踏雪无痕（冰面不打滑）", en = "Walk on Ice"},
    lunar = {zh = "启迪效果增强（天体珠宝吞噬效果，5颗可开启永久启迪状态，需要快捷键或者噩梦燃料切换）", en = "Lunar Enlightenment Boost"},
    zerosanity = {zh = "暗影模式（0精神模式）", en = "Zero Sanity Mode"},
    shadowlevel = {zh = "暗影等级", en = "Shadow Level"},
    master_crewman = {zh = "海盗水手", en = "Master Crewman"},
    boat_health_buffer = {zh = "海盗船长", en = "Boat Health Buffer"},
    tend = {zh = "自动照料农作物", en = "Auto Tend Crops"},
    hidesmeats = {zh = "肉类隐藏（兔人不主动攻击）", en = "Hide Meats"},
    fightpig = {zh = "猪人守护（猪王年没有对应物品可以吞噬）", en = "Fight Pigs"},
    bravery_buff = {zh = "勇气Buff", en = "Bravery Buff"},
    houndfriend = {zh = "狗狗朋友（猎犬不主动攻击）", en = "Hound Friend"},
    devourer_bee = {zh = "蜜蜂之友", en = "Bee Friend"},
    fire_slot = {zh = "加热格子", en = "Fire Slot"},
    snow_slot = {zh = "制冷格子", en = "Snow Slot"},
    repair_slot = {zh = "自动修复", en = "Auto Repair"},
    luck = {zh = "幸运值", en = "Luck Value"},

    -- 套装效果
    miasmaimmune = {zh = "瘴气免疫", en = "Miasma Immunity"},
    monkey_token = {zh = "诅咒免疫（免疫变猴诅咒和诅咒物品）", en = "Curse Analysis"},
    ruins = {zh = "不屈意志（自动恢复生命值上限，即黑血）", en = "The Unyielding will from ancient"},
    season = {zh = "四季之灵（保温/隔热翻倍）", en = "Season Spirit"},
    overlord = {zh = "霸者神威（免疫被攻击僵直）", en = "Overlord's Might"},
    season_fish = {zh = "四季轮转（减缓腐烂40%）", en = "Seasonal Fish"},
    terraria = {zh = "泰拉瑞亚（减缓饥饿20%）", en = "Terraria"},
    shadow = {zh = "暗影之力（范围伤害）", en = "Shadow Power"},
    stronggrip = {zh = "强握（武器不脱手，非官方的Boss可能失效）", en = "Strong Grip"},
    snail = {zh = "蜗牛之盾（减伤+5%）", en = "Snail Shield"},
    warbis = {zh = "科技之力（移速+5%，伤害倍率+5%）", en = "The Power of Technology"},
    lunarplant = {zh = "暗影敌对（攻击暗影生物增伤）", en = "Anti-shadow"},
    dreadstone = {zh = "月亮敌对（攻击月亮生物增伤）", en = "Anti-lunar"},
    nightvision = {zh = "夜视（使用快捷键切换控制）", en = "Night Vision"},
    fastbuilder = {zh = "快速制作", en = "Fast Builder"},
    repair_suit = {zh = "修理小能手", en = "Repair Expert"},
    princess_suit = {zh = "公主的庇护", en = "Princess's Protection"},
    knight_suit = {zh = "骑士的守护", en = "Knight's Protection"},
    princessandknight = {zh = "公主和骑士", en = "Princess and Knight"},
    mightiness_mighty = {zh = "强壮", en = "Mightiness"},
}

-- 通用方法：添加一个 Effect 开关选项（自动中英文切换）
local function AddEffectOption(effectKey)
    local effect = effectNames[effectKey]
    -- 根据当前语言选择显示名称
    local effectName = isCh and effect.zh or effect.en
    
    -- 构造配置项
    local option = {
        name = "devourer_pack_effect_" .. effectKey,
        label = effectName,  -- 中文或英文名称
        hover = isCh and ("开启或关闭 " .. effectName) or ("Enable or disable " .. effectName),
        options = {
            { description = isCh and "开启" or "Enable", data = true },
            { description = isCh and "关闭" or "Disable", data = false }
        },
        default = true  -- 默认开启
    }
    
    return option
end

-- 标题选项
local function headeritem(label, hover, disablehover)
    return {name = "", label = label, hover = hover, options = {{description = "", hover = disablehover, data = false}}, default = false}
end

-- 配置选项
configuration_options = {
    {
        name = "mod_language",
        label = isCh and "语言" or "Language",
        hover = isCh and "改变显示语言" or "Change display language",
        options = {
            { description = isCh and "自动" or "Auto", data = "auto" },
            { description = "English", data = "_en" },
            { description = "简体中文", data = "_cn" }
        },
        default = "auto"
    },
    {
        name = "devourer_pack_default_level",
        label = isCh and "背包初始等级" or "Default Backpack Level",
        hover = isCh and "设置吞噬者背包的初始等级，背包的格子和效果受等级影响" or "Set the initial level of the Devourer Pack, which affects the backpack's slots and effects",
        options = {
            { description = 1, data = 1 },
            { description = 2, data = 2 },
            { description = 3, data = 3 }
        },
        default = 1
    },
    {
        name = "devourer_pack_base_rows",
        label = isCh and "背包初始格子行数" or "Backpack Base Slot Rows",
        hover = isCh and "设置背包的初始格子行数,请注意这会受到最大格子的限制" or "Set the initial number of backpack slot rows, please note that this will be limited by the maximum slots.",
        options = {
            { description = "1行", data = 1 },
            { description = "2行", data = 2 },
            { description = "3行", data = 3 },
            { description = "4行", data = 4 }
        },
        default = 1
    },
    {
        name = "devourer_pack_control_panel_key",
        label = isCh and "控制面板" or "Panel Switch Key",
        hover = isCh and "功能控制面板的显示开关" or "Control Panel Toggle Key",
        options = thePanelKeys,
        default = 288 -- 默认F7
    },
    {
        name = "devourer_pack_switch_key",
        label = isCh and "功能切换键" or "Function Switch Key",
        hover = isCh and "切换当前绑定的功能" or "Switch the currently bound function",
        options = thePanelKeys,
        default = 289 -- 默认F8
    },
    {
        name = "devourer_pack_execute_key",
        label = isCh and "功能执行键" or "Function Execute Key",
        hover = isCh and "执行当前绑定的功能" or "Execute the currently bound function",
        options = thePanelKeys,
        default = 290 -- 默认F9
    },
    {
        name = "devourer_icon",
        label = isCh and "图标变更" or "Icon Change",
        hover = isCh and "改变显示图标" or "Change display Icon",
        options = {
            { description = isCh and "坨坨脸" or "Trickcal Revive", data = 1 },
            { description = isCh and "太极猫猫" or "YING AND YANG CATS", data = 2 }
        },
        default = 1
    },
    {
        name = "devourer_pack_max_slots",
        label = isCh and "最大格子" or "Max Slots",
        hover = isCh and "背包设置融合布局，可以通过限制格子来使页面美观，不过这会牺牲背包的格子功能" 
            or "The backpack's ​fusion layout​ can improve visual appeal by restricting grid slots, but this sacrifices some of the backpack's storage functionality",
        options = {
            { description = "3*9", data = 1 },
            { description = "3*8", data = 2 },
            { description = "3*7", data = 3 },
            { description = "3*6", data = 4 },
            { description = "3*5", data = 5 },
            { description = "2*9", data = 6 },
            { description = "2*8", data = 7 },
            { description = "2*7", data = 8 },
        },
        default = 1
    },
    {
        name = "devourer_pack_say",
        label = isCh and "背包对话" or "Backpack Chatter",
        hover = isCh and "控制背包的说话频率" or "Controls how often the backpack speaks",
        options = {
            { description = isCh and "关闭" or "Disabled", data = 0 },
            { description = isCh and "无声" or "Minimal", data = 1 },
            { description = isCh and "正常" or "Default", data = 2 },
        },
        default = 1
    },
    {
        name = "devourer_pig_king_modify",
        label = isCh and "猪王修改" or "Pig King Modification",
        hover = isCh and "猪王年掉落猪鼻铸币，修复开启 '永不妥协' 后不可以进行猪王游戏的Bug" or "Pig King Year drops Pig Coins, fixes the bug where 'Uncompromising Mode' prevents playing Pig King games",
        options = boolKeys,
        default = true
    },
    {
        name = "devourer_tech",
        label = isCh and "背包科技" or "Pack Tech",
        hover = isCh and "可以通过吞噬科技使装备背包解锁科技" or "Can Devour Somethings Unlock Tech",
        options = boolKeys,
        default = true
    },
    
    headeritem(isCh and "基础效果" or "Base Effect",isCh and "直接吞噬装备即可启用，部分效果需要背包升级才能解锁" or "Effects that can be enabled by directly consuming equipment. Some effects require the backpack level to be unlocked."),
    
    {
        name = "devourer_pack_effect_defense",
        label = isCh and "最大防御" or "Max Defense",
        hover = isCh and "吞噬者背包的最大防御" or "Maximum damage reduction percentage",
        options = {
            -- { description = "100%", data = 1.0 },
            { description = "99%", data = 0.99 },
            { description = "98%", data = 0.98 },
            { description = "95%", data = 0.95 },
            { description = "90%", data = 0.9 },
            { description = "85%", data = 0.85 },
            { description = "80%", data = 0.8 },
            { description = "75%", data = 0.75 },
            { description = "70%", data = 0.7 },
            { description = "65%", data = 0.65 },
            { description = "60%", data = 0.6 },
            { description = "55%", data = 0.55 },
            { description = "50%", data = 0.5 },
            { description = isCh and "关闭" or "Closed", data = 0 },
        },
        default = 0.95
    },
    {
        name = "devourer_pack_effect_speed",
        label = isCh and "最大移速" or "Max Speed",
        options = {
            { description = isCh and "无限制" or "Not Limit", data = -1 },
            { description = "45%", data = 0.45 },
            { description = "40%", data = 0.4 },
            { description = "30%", data = 0.3 },
            { description = "20%", data = 0.2 },
            { description = isCh and "关闭" or "Closed", data = 0 },
        },
        default = -1
    },
    {
        name = "devourer_pack_effect_extraview",
        label = isCh and "最大视野" or "Max Extraview",
        options = {
            { description = isCh and "无限制" or "Not Limit", data = -1 },
            { description = "15", data = 15 },
            { description = "10", data = 10 },
            { description = "5", data = 5 },
            { description = isCh and "关闭" or "Closed", data = 0 },
        },
        default = -1
    },
    {
        name = "devourer_pack_food_max",
        label = isCh and "吞噬食物" or "Food Devouring",
        hover = isCh and "可吞噬食物的最大次数，特殊物品固定为1，设置为0则属性增加关闭（食物吞噬之后会增加三维上限，即生命值，饱食度，理智）" 
               or "Max food consumption attempts (special items fixed at 1). Set to 0 to disable stat boosts",
        options = {
            { description = "10", data = 10 },
            { description = "8", data = 8 },
            { description = "5", data = 5 },
            { description = "3", data = 3 },
            { description = isCh and "关闭" or "Closed", data = 0 },
        },
        default = 5
    },
    {
        name = "devourer_pig_max_scale",
        label = isCh and "猪人体型上限" or "Pig Max Size",
        hover = isCh and "猪人随等级增长的最大体型倍数（范围2~10倍，默认5倍）" or "Max scale multiplier for pig size growth (range 2~10x, default 5x)",
        options = {
            {description = "2.0x", data = 2.0},
            {description = "3.0x", data = 3.0},
            {description = "4.0x", data = 4.0},
            {description = "5.0x", data = 5.0},
            {description = "7.0x", data = 7.0},
            {description = "10.0x", data = 10.0},
        },
        default = 5.0
    },
    AddEffectOption("kw"),
    AddEffectOption("kc"),
    AddEffectOption("light"),
    AddEffectOption("insulated"),
    AddEffectOption("dapperness"),
    AddEffectOption("resistance"),
    AddEffectOption("shadowdominance"),
    AddEffectOption("planardefense"),
    AddEffectOption("heavyarmor"),
    AddEffectOption("bramble_resistant"),
    AddEffectOption("goggles"),
    AddEffectOption("gestaltprotection"),
    AddEffectOption("gestaltattack"),
    AddEffectOption("acidrainimmune"),
    AddEffectOption("stacksize"),
    AddEffectOption("forcefield"),
    AddEffectOption("junk"),
    AddEffectOption("health"),
    AddEffectOption("beefalo"),
    AddEffectOption("moonstormevent_detector"),
    AddEffectOption("creep"),
    AddEffectOption("rebirth"),
    AddEffectOption("sleep_res"),
    AddEffectOption("bloodsucking"),
    AddEffectOption("manrabbitscarer"),
    AddEffectOption("spiderdisguise"),
    AddEffectOption("electricattack"),
    AddEffectOption("freeze_res"),
    AddEffectOption("rabbitdisguise"),
    AddEffectOption("treadwater"),
    AddEffectOption("voidwalk"),
    AddEffectOption("basereflect"),
    AddEffectOption("planarreflect"),
    AddEffectOption("specialreflect"),
    AddEffectOption("aoereflect"),
    AddEffectOption("damage"),
    AddEffectOption("spdamage"),
    AddEffectOption("predamage"),
    -- AddEffectOption("souljar"),
    AddEffectOption("ghost_ally"),
    AddEffectOption("walksinkhole"),
    AddEffectOption("walkice"),
    AddEffectOption("lunar"),
    AddEffectOption("zerosanity"),
    AddEffectOption("shadowlevel"),
    AddEffectOption("master_crewman"),
    AddEffectOption("boat_health_buffer"),
    AddEffectOption("tend"),
    AddEffectOption("hidesmeats"),
    AddEffectOption("fightpig"),
    AddEffectOption("bravery_buff"),
    AddEffectOption("lunarplant"),
    AddEffectOption("dreadstone"),
    AddEffectOption("houndfriend"),
    AddEffectOption("devourer_bee"),
    AddEffectOption("fire_slot"),
    AddEffectOption("snow_slot"),
    AddEffectOption("repair_slot"),
    AddEffectOption("luck"),


    headeritem(isCh and "套装效果" or "Suit Effect",isCh and "部分装备含有套装效果，集齐可生效" or "Some equipment has suit effects that activate when collected"),
    AddEffectOption("miasmaimmune"),
    AddEffectOption("monkey_token"),
    AddEffectOption("ruins"),
    AddEffectOption("season"),
    AddEffectOption("overlord"),
    AddEffectOption("season_fish"),
    AddEffectOption("terraria"),
    AddEffectOption("shadow"),
    AddEffectOption("stronggrip"),
    AddEffectOption("snail"),
    AddEffectOption("warbis"),
    AddEffectOption("nightvision"),
    AddEffectOption("fastbuilder"),
    AddEffectOption("repair_suit"),
    AddEffectOption("princess_suit"),
    AddEffectOption("knight_suit"),
    AddEffectOption("princessandknight"),
    -- AddEffectOption("mightiness_mighty"),

    {
        name = "devourer_pack_debug",
        label = isCh and "调试日志" or "Debug Mode",
        hover = isCh and "启用调试日志输出" or "Enable debug logging",
        options = boolKeys,
        default = false
    },
}
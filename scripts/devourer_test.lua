-- 吞噬者背包 - 测试模块
-- 使用方式：按 ~ 打开控制台，输入以下命令：
--   c_piglevel    猪人升1级
--   c_pack2       背包升到2级（吞噬所有1级所需物品）
--   c_pack3       背包升到3级（吞噬所有1级+2级所需物品）
--   c_packall     背包吞噬全部可吞噬物品

local add_utils = require("utils/add_utils")
local add_configs = require("configs/add_configs")
local pig_config = require("configs/pig_config")

-- Boss 击杀测试池（真实的史诗生物 prefab）
local BOSS_PREFABS = { "moose", "dragonfly", "bearger", "deerclops", "minotaur", "toadstool",
    "antlion", "beequeen", "klaus", "stalker_atrium", "alterguardian_phase3", "daywalker",
    "crabking", "malbatross", "eyeofterror", "twinofterror1", "twinofterror2",
    "shadow_rook", "shadow_knight", "shadow_bishop", "lordfruitfly" }

-- 获取玩家装备的吞噬者背包
local function get_pack()
    local player = ConsoleCommandPlayer()
    if not player then return nil, "找不到玩家" end
    local pack = add_utils.GetDevourerPack(player)
    if not pack or not pack.components.devourer then
        return nil, "未装备吞噬者背包"
    end
    return pack.components.devourer, nil, pack
end

-- 猪人设置等级（用法: c_piglevel() → 升1级, c_piglevel(15) → 直接到15级）
GLOBAL.c_piglevel = function(target_lv)
    local dev, err = get_pack()
    if err then print(err) return end

    local ps = dev.pig_state
    local pig = ps.pig
    local cur_lv = dev:GetPigLevel(ps.total_exp)
    local new_lv = target_lv or (cur_lv + 1)
    new_lv = math.max(1, math.min(new_lv, 30))

    ps.total_exp = pig_config._cum_exp[new_lv] or 0
    ps.level_exp = ps.total_exp - (pig_config._cum_exp[new_lv] or 0)

    -- 自动满足所有突破条件
    -- ps.total_kills = 500
    -- ps.kill_elite = 50
    -- ps.kill_large = 30
    -- ps.boss_assist = 10
    -- ps.boss_kill = 5
    -- for i = 1, 5 do
    --     ps.boss_kill_list[BOSS_PREFABS[i] or "deerclops"] = true
    -- end
    -- ps.planar_boss = 2
    -- ps.eat_count = 50
    -- ps.eat_favorite_count = 10
    -- ps.work_count = 100
    -- ps.survival_days = 20
    -- for i = 1, new_lv do
    --     ps.level_up_monsters[BOSS_PREFABS[i] or "deerclops"] = 1
    -- end

    if pig and pig:IsValid() then
        pig:ProcessKill(false, ps.total_exp)
        print(string.format("[测试] 猪人 LV%d → LV%d，经验=%d，攻=%.1f 血=%d 连击=%d",
            cur_lv, dev:GetPigLevel(ps.total_exp), ps.total_exp,
            pig.components.combat.defaultdamage, pig.components.health.maxhealth,
            pig._combo_count or 2))
    else
        print(string.format("[测试] 猪人未召唤，经验已设为 LV%d（经验=%d），召唤后自动应用",
            dev:GetPigLevel(ps.total_exp), ps.total_exp))
    end
end

-- 给猪人加经验（用法: c_pigexp(50) → +50经验，正常判定升级/突破条件）
GLOBAL.c_pigexp = function(add_exp)
    local dev, err = get_pack()
    if err then print(err) return end

    local ps = dev.pig_state
    local pig = ps.pig
    local addExp = tonumber(add_exp) or 50
    if addExp <= 0 then print("[测试] 经验值必须大于0") return end

    local oldLevel = dev:GetPigLevel(ps.total_exp)
    ps.total_exp = ps.total_exp + addExp
    local newLevel = dev:GetPigLevel(ps.total_exp)
    ps.level_exp = ps.total_exp - (pig_config._cum_exp[newLevel] or 0)

    -- 突破条件检查
    if newLevel > oldLevel then
        for lv = oldLevel + 1, newLevel do
            if not dev:CheckBreakthrough(lv) then
                ps.total_exp = pig_config._cum_exp[oldLevel + 1] or pig_config._cum_exp[pig_config.growth.max_level]
                ps.level_exp = ps.total_exp - (pig_config._cum_exp[oldLevel] or 0)
                print(string.format("[测试] LV%d突破条件未满足，经验封顶于%d", lv, ps.total_exp))
                break
            end
        end
    end

    if pig and pig:IsValid() then
        pig:ProcessKill(false, ps.total_exp)
        print(string.format("[测试] +%d经验，总经验=%d，LV%d → LV%d",
            addExp, ps.total_exp, oldLevel, dev:GetPigLevel(ps.total_exp)))
    else
        print(string.format("[测试] 猪人未召唤，经验已加（总经验=%d，LV%d）",
            ps.total_exp, dev:GetPigLevel(ps.total_exp)))
    end
end

-- 吞噬指定列表中的物品
local function devour_items(dev, item_list)
    local count = 0
    for prefab, _ in pairs(item_list) do
        local effect = dev.upgrade_effects[prefab]
        if effect and not effect.enab then
            effect.enab = true
            if effect.max then effect.cur = effect.max end
            count = count + 1
        end
    end
    return count
end

-- 背包升到2级
GLOBAL.c_pack2 = function()
    local dev, err = get_pack()
    if err then print(err) return end

    local count = devour_items(dev, add_configs.level_up.lv1.item)
    dev.packlv.level = 2
    dev:Upgrade()
    dev:SetPackState()
    dev:_SyncUpgradeEffects()

    local name = STRINGS.NAMES.DEVOURER_PACK_NAMES[2] or "LV2"
    print(string.format("[测试] 背包已升到 %s，吞噬了 %d 个物品", name, count))
    TheNet:Announce(string.format("[测试] 背包已升到 %s", name))
end

-- 背包升到3级
GLOBAL.c_pack3 = function()
    local dev, err = get_pack()
    if err then print(err) return end

    local count1 = devour_items(dev, add_configs.level_up.lv1.item)
    local count2 = devour_items(dev, add_configs.level_up.lv2.item)
    dev.packlv.level = 3
    dev:Upgrade()
    dev:SetPackState()
    dev:_SyncUpgradeEffects()

    local name = STRINGS.NAMES.DEVOURER_PACK_NAMES[3] or "LV3"
    print(string.format("[测试] 背包已升到 %s，吞噬了 %d 个物品", name, count1 + count2))
    TheNet:Announce(string.format("[测试] 背包已升到 %s", name))
end

-- 吞噬全部可吞噬物品
GLOBAL.c_packall = function()
    local dev, err = get_pack()
    if err then print(err) return end

    local total = 0
    for _ in pairs(dev.upgrade_effects) do total = total + 1 end
    print(string.format("[c_packall] upgrade_effects 总key数=%d", total))
    local skipped_enab = 0
    local count = 0
    for prefab, effect in pairs(dev.upgrade_effects) do
        if effect.enab then
            skipped_enab = skipped_enab + 1
        else
            effect.enab = true
            if effect.max then effect.cur = effect.max end
            count = count + 1
            print(string.format("[c_packall] 启用: %s max=%s cur=%s",
                prefab, tostring(effect.max), tostring(effect.cur)))
        end
    end
    print(string.format("[c_packall] 新启用=%d 已启用跳过=%d packlv前=%d",
        count, skipped_enab, dev.packlv.level))

    dev.packlv.level = 3
    print(string.format("[c_packall] packlv设为3, 调用Upgrade..."))
    dev:Upgrade()
    print(string.format("[c_packall] Upgrade完成, 调用SetPackState..."))
    dev:SetPackState()
    print(string.format("[c_packall] SetPackState完成, 调用_SyncUpgradeEffects..."))
    dev:_SyncUpgradeEffects()
    print(string.format("[c_packall] 全部完成, 共吞噬%d个物品", count))

    TheNet:Announce(string.format("[测试] 已吞噬全部物品（%d个），背包升至满级！", count))
end

print("[DevourerPack] 测试模块已加载：c_piglevel / c_pack2 / c_pack3 / c_packall")

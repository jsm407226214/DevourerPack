local add_utils = require("utils/add_utils")
local add_configs = require("configs/add_configs")
local pig_config = require("configs/pig_config")

local assets = {
    Asset("ANIM", "anim/ds_pig_basic.zip"),
    Asset("ANIM", "anim/ds_pig_actions.zip"),
    Asset("ANIM", "anim/ds_pig_attacks.zip"),
    Asset("ANIM", "anim/ds_pig_elite.zip"),
    Asset("ANIM", "anim/ds_pig_elite_intro.zip"),
    Asset("ANIM", "anim/pig_elite_build.zip"),
    Asset("ANIM", "anim/pig_guard_build.zip"),
    Asset("ANIM", "anim/ds_pig_attacks_combo.zip"),
    Asset("ANIM", "anim/slide_puff.zip"),
    Asset("SOUND", "sound/pig.fsb"),
}

local prefabs = { "slide_puff" }
local brain = require("brains/devourer_pigbrain")

-- ============================================
-- 工具函数
-- ============================================

local function GetPigLevel(totalExp)
    if not totalExp or totalExp <= 0 then return 1 end
    local cum = pig_config._cum_exp
    for lv = pig_config.growth.max_level, 2, -1 do
        if totalExp > cum[lv] then return lv end
    end
    return 1
end

local function SyncPigLevelExp(dev)
    local lv = dev:GetPigLevel(dev.pig_state.total_exp)
    dev.pig_state.level_exp = dev.pig_state.total_exp - (pig_config._cum_exp[lv] or 0)
end

local function ShouldSleep() return false end
local function ShouldWake() return true end

local function ontalk(inst, script)
    inst.SoundEmitter:PlaySound(
        (inst.sg:HasStateTag("intropose") or inst.sg:HasStateTag("endpose"))
            and "dontstarve/pig/attack" or "dontstarve/pig/grunt"
    )
end

local function PushMusic(inst)
    if ThePlayer ~= nil and ThePlayer:IsNear(inst, 30) then
        ThePlayer:PushEvent("triggeredevent", { name = "pigking", duration = 1 })
    end
end

-- ============================================
-- 属性计算（无限成长核心）
-- ============================================

local function ApplyLevelStats(inst, level)
    local cfg = pig_config.growth
    local sz = pig_config.size

    inst._pig_level = level

    -- 攻击力
    inst.components.combat:SetDefaultDamage(cfg.base_attack + (level - 1) * cfg.attack_per_level)

    -- 位面攻击（8级解锁，有上限）
    if level >= cfg.unlock_planar then
        inst.components.planardamage:SetBaseDamage(
            math.min((level - cfg.unlock_planar + 1) * cfg.planar_attack_per_level, cfg.max_planar_attack)
        )
    end

    -- 位面防御（8级解锁，有上限）
    if level >= cfg.unlock_planar then
        inst.components.planardefense:SetBaseDefense(
            math.min((level - cfg.unlock_planar + 1) * cfg.planar_defense_per_level, cfg.max_planar_defense)
        )
    end

    -- 伤害吸收（曲线：10级前线性+4%，之后每级减半，上限90%）
    local dg = cfg.defense_growth
    local defense
    if level <= dg.diminish_start then
        defense = (level - 1) * dg.per_level
    else
        defense = dg.diminish_start * dg.per_level
        local remaining = level - dg.diminish_start
        local growth = dg.per_level
        for _ = 1, remaining do
            growth = growth * dg.diminish_rate
            defense = defense + growth
            if defense >= dg.max_defense then break end
        end
    end
    defense = math.min(defense, dg.max_defense)
    inst.components.health:SetAbsorptionAmount(defense)

    -- 移动速度
    inst.components.locomotor.runspeed = math.min(
        cfg.base_run_speed + (level - 1) * cfg.run_speed_per_level, cfg.max_run_speed
    )
    inst.components.locomotor.walkspeed = math.min(
        cfg.base_walk_speed + (level - 1) * cfg.walk_speed_per_level, cfg.max_walk_speed
    )

    -- 攻击距离
    inst.components.combat:SetRange(
        math.min(cfg.base_range + (level - 1) * cfg.range_per_level, cfg.max_attack_range)
    )

    -- 冰冻抗性
    if inst.components.freezable then
        inst.components.freezable:SetResistance(
            cfg.base_freeze_resist + (level - 1) * cfg.freeze_resist_per_level
        )
    end

    -- 吸血（3级解锁，每级+0.5%，上限15%）
    inst.bloodsucking = level >= cfg.unlock_blood_sucking
        and math.min((level - cfg.unlock_blood_sucking + 1) * cfg.blood_sucking_per_level, cfg.max_blood_sucking)
        or 0

    -- 范围伤害（5级解锁，每级+3%，上限60%）
    inst.areaattack = level >= cfg.unlock_area_attack
        and math.min((level - cfg.unlock_area_attack + 1) * cfg.area_attack_per_level, cfg.max_area_attack)
        or 0

    -- 生命值（含30级后无限成长）
    local pct = inst.components.health:GetPercent()
    local base_max = cfg.base_health + (level - 1) * cfg.health_per_level
    if level >= cfg.max_level and pig_config.infinite_growth.enabled then
        local max_exp = pig_config._cum_exp[cfg.max_level]
        local extra = (inst.totalExp or 0) - max_exp
        if extra > 0 then
            local bonus = math.floor(extra / pig_config.infinite_growth.exp_per_hp)
            base_max = math.min(base_max + bonus, pig_config.infinite_growth.max_hp_cap)
        end
    end
    inst.components.health:SetMaxHealth(base_max)
    inst.components.health:SetPercent(pct, false)

    -- 连击数（固定三连击）,这里2+最终一击=3
    inst._combo_count = 2

    -- 攻击速度
    inst._attack_interval = math.max(
        cfg.attack_interval_base - math.floor((level - 1) / cfg.attack_interval_per_levels),
        cfg.attack_interval_min
    )

    -- 体型
    local scale = math.min(sz.base_scale + (level - 1) * sz.scale_per_level, sz.get_max_scale())
    inst.Transform:SetScale(scale, scale, scale)
    inst.scale = scale
    inst.DynamicShadow:SetSize(1.5 * scale, 0.75 * scale)
    inst:SetPhysicsRadiusOverride(0.5 * scale)

    -- 额外属性表（用于显示）
    local run_spd = math.min(cfg.base_run_speed + (level - 1) * cfg.run_speed_per_level, cfg.max_run_speed)
    local walk_spd = math.min(cfg.base_walk_speed + (level - 1) * cfg.walk_speed_per_level, cfg.max_walk_speed)
    inst.extra_stats = {
        ATTACK = (level - 1) * cfg.attack_per_level,
        PLANAR_ATK = level >= cfg.unlock_planar
            and math.min((level - cfg.unlock_planar + 1) * cfg.planar_attack_per_level, cfg.max_planar_attack) or 0,
        PLANAR_DEF = level >= cfg.unlock_planar
            and math.min((level - cfg.unlock_planar + 1) * cfg.planar_defense_per_level, cfg.max_planar_defense) or 0,
        DEFENSE = math.floor(defense * 100),
        RANGE = math.min(cfg.base_range + (level - 1) * cfg.range_per_level, cfg.max_attack_range) - cfg.base_range,
        FREEZE_RESIST = cfg.base_freeze_resist + (level - 1) * cfg.freeze_resist_per_level,
        BLOOD_SUCKING = inst.bloodsucking > 0 and math.floor(inst.bloodsucking * 100) or 0,
        AREA_ATTACK = inst.areaattack > 0 and math.floor(inst.areaattack * 100) or 0,
        RUN_SPEED = run_spd,
        WALK_SPEED = walk_spd,
    }
end

-- ============================================
-- 消息构建
-- ============================================

local function BuildPigLevelMsg(inst)
    local msgs = {}
    local level = GetPigLevel(inst.totalExp or 0)
    local needed = pig_config.growth.getExpPerLevel(level + 1)
        or pig_config.growth.getExpPerLevel(pig_config.growth.max_level)

    -- 获取当前等级段经验（优先从 pig_state.level_exp 读）
    local current_exp = 0
    local ps = nil
    local leader = inst.components.follower and inst.components.follower.leader
    if leader and leader:HasTag("player") then
        local pack = add_utils.GetDevourerPack(leader)
        if pack and pack.components.devourer then
            ps = pack.components.devourer.pig_state
            current_exp = ps.level_exp or 0
        end
    end
    if not ps then
        local cum_before = pig_config._cum_exp[level] or 0
        current_exp = (inst.totalExp or 0) - cum_before
    end

    table.insert(msgs, STRINGS.DEVOURER_PIG_MESSAGES.PREFIX)
    table.insert(msgs, string.format("LV%d %d/%d", level, current_exp, needed))

    local is_capped = false
    -- 经验封顶 + 下一级有突破门 → 追加升级条件
    if current_exp >= needed then
        local next_level = level + 1
        local bt = pig_config.level_breakthrough[next_level]
        if bt then
            is_capped = true
            if ps then
                local parts = {}
                for _, cond in ipairs(bt.conditions) do
                    local current
                    if cond.type == "boss_kill" then
                        current = 0
                        for _ in pairs(ps.boss_kill_list or {}) do current = current + 1 end
                    elseif cond.type == "eat_favorite_count" then
                        current = 0
                        for _ in pairs(ps.eat_favorite_types or {}) do current = current + 1 end
                    else
                        current = ps[cond.type] or 0
                    end
                    current = math.min(current, cond.count)
                    local desc_key = cond.desc or ""
                    local desc = STRINGS.DEVOURER_PIG_MESSAGES[desc_key] or desc_key
                    local result = string.format(desc, current .. "/" .. cond.count)
                    table.insert(parts, result)
                end
                table.insert(msgs, table.concat(parts, "\n"))
            end
        end
    end

    return table.concat(msgs, "\n"), is_capped
end

local function BuildExtraStatsMsg(inst)
    local lines = {}
    local current_line = ""
    local count = 0

    for key, value in pairs(inst.extra_stats) do
        if value > 0 and STRINGS.DEVOURER_PIG_MESSAGES[key] then
            if current_line ~= "" then current_line = current_line .. " " end
            current_line = current_line .. string.format(STRINGS.DEVOURER_PIG_MESSAGES[key], value)
            count = count + 1
            if count >= 3 then
                table.insert(lines, current_line)
                current_line = ""
                count = 0
            end
        end
    end

    if current_line ~= "" then table.insert(lines, current_line) end
    return #lines > 0 and table.concat(lines, "\n") or ""
end

-- ============================================
-- 击杀/成长处理
-- ============================================

local function ProcessKill(inst, isshow, newKill)
    inst.totalExp = newKill or 0
    local level = GetPigLevel(inst.totalExp)
    ApplyLevelStats(inst, level)

    if not isshow and inst.components.talker then
        local msg, is_capped = BuildPigLevelMsg(inst)
        if not is_capped then
            local stats_msg = BuildExtraStatsMsg(inst)
            if stats_msg ~= "" then msg = msg .. "\n" .. stats_msg end
        end
        inst.components.talker:Say(msg)
    end
end

-- ============================================
-- 战斗事件
-- ============================================

local function OnAttacked(inst, data)
    local attacker = data and data.attacker
    if attacker then
        if inst.components.follower and inst.components.follower:GetLeader() == attacker then
            PreventTargetingOnAttacked(inst, attacker, "player")
        elseif attacker.components.combat and not inst.components.combat:HasTarget() then
            inst.components.combat:SetTarget(attacker)
        end
    end
end

local function BloodSucking(inst, data)
    if inst.bloodsucking and inst.bloodsucking > 0
        and inst.components.health and not inst.components.health:IsDead() then
        local damage = data and data.damage
        if damage and damage > 0 then
            inst.components.health:DoDelta(damage * inst.bloodsucking)
        end
    end
end

local AREAATTACK_MUST_TAGS = { "_combat" }

local function AreaAttack(inst, data)
    if not (inst.areaattack and inst.areaattack > 0) then return end
    local x, y, z = data.target.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 3, AREAATTACK_MUST_TAGS, add_configs.ignoreList)
    for i, ent in ipairs(ents) do
        if ent ~= data.target and ent ~= inst
            and ent.components.combat
            and inst.components.combat:IsValidTarget(ent) then
            inst:PushEvent("onareaattackother", { target = ent, weapon = nil, stimuli = "shadow" })
            local dmg, spdmg = inst.components.combat:CalcDamage(ent, nil, inst.areaattack)
            ent.components.combat:GetAttacked(inst, dmg, nil, "shadow", spdmg)
        end
    end
end

local function OnHit(inst, data)
    BloodSucking(inst, data)
end

local function OnAttack(inst, data)
    local current_time = GetTime()
    if current_time - (inst.last_say_time or 0) >= 5 and math.random(4) <= 1 then
        local lines = STRINGS.DEVOURER_PIG_TALK_ATTACK
        if lines and #lines > 0 then
            inst.components.talker:Say(lines[math.random(#lines)])
            inst.last_say_time = current_time
        end
    end
end

-- ============================================
-- 食物/头盔交易
-- ============================================

local function OnEat(inst, food)
    if food.components.edible ~= nil then
        if food.components.edible.foodtype == FOODTYPE.VEGGIE then
            SpawnPrefab("poop").Transform:SetPosition(inst.Transform:GetWorldPosition())
        elseif food.components.edible.foodtype == FOODTYPE.MEAT
            and inst.components.werebeast ~= nil
            and not inst.components.werebeast:IsInWereState()
            and food.components.edible:GetHealth(inst) < 0 then
            inst.components.werebeast:TriggerDelta(1)
        end
    end
end

local function OnDevourerEatItem(inst, item)
    local cfg = pig_config.growth
    local foodtype = item.components.edible and item.components.edible.foodtype
    local is_prepared = item:HasTag("preparedfood")
    local is_favorite = cfg.favorite_foods[item.prefab]

    -- 经验计算：最爱 > 肉料理 > 素料理 > 生肉 > 生素
    local addExp
    if is_favorite then
        addExp = cfg.eat_exp_favorite
    elseif is_prepared and foodtype == FOODTYPE.MEAT then
        addExp = cfg.eat_exp_prepared_meat
    elseif is_prepared and foodtype == FOODTYPE.VEGGIE then
        addExp = cfg.eat_exp_prepared_veggie
    elseif foodtype == FOODTYPE.MEAT then
        addExp = cfg.eat_exp_raw_meat
    elseif foodtype == FOODTYPE.VEGGIE then
        addExp = cfg.eat_exp_raw_veggie
    end

    local addExpMsg = ""
    if addExp then
        local leader = inst.components.follower and inst.components.follower.leader
        if leader and leader:HasTag("player") then
            local pack = add_utils.GetDevourerPack(leader)
            if pack and pack.components.devourer then
                local dev = pack.components.devourer
                local oldCount = dev.pig_state.total_exp
                dev.pig_state.total_exp = dev.pig_state.total_exp + addExp
                -- 等级突破条件检查：不满足突破条件的等级不能跨越
                if dev:IsPigLevelUp(oldCount, dev.pig_state.total_exp) then
                    local newLevel = dev:GetPigLevel(dev.pig_state.total_exp)
                    if not dev:CheckBreakthrough(newLevel) then
                        local oldLevel = dev:GetPigLevel(oldCount)
                        dev.pig_state.total_exp = pig_config._cum_exp[oldLevel + 1] or pig_config._cum_exp[pig_config.growth.max_level]
                    end
                end
                SyncPigLevelExp(dev)
                -- 进食统计
                dev.pig_state.eat_count = (dev.pig_state.eat_count or 0) + 1
                if is_favorite then
                    dev.pig_state.eat_favorite_count = (dev.pig_state.eat_favorite_count or 0) + 1
                    dev.pig_state.eat_favorite_types = dev.pig_state.eat_favorite_types or {}
                    dev.pig_state.eat_favorite_types[item.prefab] = true
                end
                inst:ProcessKill(true, dev.pig_state.total_exp)
                addExpMsg = STRINGS.DEVOURER_PIG_MESSAGES.EAT_PREFIX
            end
        end
    end

    local level_msg, is_capped = BuildPigLevelMsg(inst)
    local stats_msg = BuildExtraStatsMsg(inst)

    if inst.components.talker and not inst.sg:HasStateTag("busy") then
        local msg = addExpMsg .. level_msg
        if not is_capped and stats_msg ~= "" then msg = msg .. "\n" .. stats_msg end
        inst.components.talker:Say(msg)
    end
end

-- ============================================
-- 领袖变更 / 移除
-- ============================================

local function OnChangedLeader(inst, new_leader, prev_leader)
    if not (new_leader and new_leader:HasTag("player")) then
        if new_leader and new_leader.components.devourer and new_leader.components.devourer.Unsummon then
            new_leader.components.devourer:Unsummon()
        else
            ErodeAway(inst)
        end
    end
end

-- ============================================
-- 变体配置
-- ============================================

local BUILD_VARIATIONS = {
    ["1"] = { "pig_ear", "pig_head", "pig_skirt", "pig_torso", "spin_bod" },
    ["2"] = { "pig_arm", "pig_ear", "pig_head", "pig_skirt", "pig_torso", "spin_bod" },
    ["3"] = { "pig_arm", "pig_ear", "pig_head", "pig_skirt", "pig_torso", "spin_bod" },
    ["4"] = { "pig_head", "pig_skirt", "pig_torso", "spin_bod" },
}

-- ============================================
-- 主预制件工厂
-- ============================================

local function MakePigEliteFighter(variation)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        inst.entity:AddNetwork()

        inst:SetPhysicsRadiusOverride(0.5)
        MakeCharacterPhysics(inst, 50, inst.physicsradiusoverride)

        inst.DynamicShadow:SetSize(1.5, 0.75)
        inst.Transform:SetFourFaced()

        inst:AddTag("character")
        inst:AddTag("pig")
        inst:AddTag("devourer_pig")
        inst:AddTag("companion")
        inst:AddTag("pigelite")
        inst:AddTag("scarytoprey")
        inst:AddTag("noepicmusic")
        inst:AddTag("ignorewalkableplatformdrowning")

        inst.AnimState:SetBank("pigman")
        inst.AnimState:SetBuild("pig_guard_build")
        inst.AnimState:AddOverrideBuild("slide_puff")
        inst.AnimState:PlayAnimation("idle_loop", true)
        inst.AnimState:Hide("hat")
        inst.AnimState:Hide("ARM_carry")
        inst.AnimState:Hide("ARM_carry_up")

        -- 应用变体外观
        local var = variation or tostring(math.random(4))
        local build_data = BUILD_VARIATIONS[var] or BUILD_VARIATIONS["2"]
        for _, v in ipairs(build_data) do
            inst.AnimState:OverrideSymbol(v, "pig_elite_build", v .. "_" .. var)
        end
        inst.pig_variation = var

        -- 说话组件
        inst:AddComponent("talker")
        inst.components.talker.fontsize = 35
        inst.components.talker.font = TALKINGFONT
        inst.components.talker.offset = Vector3(0, -400, 0)
        inst.components.talker:MakeChatter()

        if not TheNet:IsDedicated() then
            inst:DoPeriodicTask(0.5, PushMusic, 0)
        end

        -- 碰撞
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.GROUND)
        for _, mask in ipairs({ COLLISION.OBSTACLES, COLLISION.SMALLOBSTACLES, COLLISION.CHARACTERS, COLLISION.GIANTS }) do
            inst.Physics:CollidesWith(mask)
        end
        inst.Physics:Teleport(inst.Transform:GetWorldPosition())

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end
        
        inst:AddComponent("named")

        -- 状态变量
        inst.totalExp = 0
        inst.last_say_time = 0
        inst.scale = 1.0

        inst.components.talker.ontalk = ontalk

        -- 移动
        inst:AddComponent("locomotor")
        inst.components.locomotor.runspeed = pig_config.growth.base_run_speed
        inst.components.locomotor.walkspeed = pig_config.growth.base_walk_speed
        inst.components.locomotor:SetAllowPlatformHopping(true)
        inst:AddComponent("embarker")

        -- 进食
        inst:AddComponent("eater")
        inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODGROUP.OMNI })
        inst.components.eater:SetCanEatHorrible()
        inst.components.eater:SetCanEatRaw()
        inst.components.eater:SetStrongStomach(true)
        inst.components.eater:SetOnEatFn(OnEat)

        -- 生命
        inst:AddComponent("health")
        inst.components.health:SetMaxHealth(pig_config.growth.base_health)

        -- 非战斗回血
        inst:DoPeriodicTask(5, function()
            if inst.components.health and not inst.components.health:IsDead()
                and inst.components.health.currenthealth < inst.components.health:GetMaxWithPenalty() then
                local is_in_combat = inst.components.combat
                    and (inst.components.combat:HasTarget()
                        or GetTime() - inst.components.combat:GetLastAttackedTime() < 10)
                if not is_in_combat then
                    inst.components.health:DoDelta(inst.components.health.maxhealth * 0.1 / 12)
                end
            end
        end)

        -- 战斗
        inst:AddComponent("combat")
        inst.components.combat.hiteffectsymbol = "pig_torso"
        inst.components.combat:SetRange(pig_config.growth.base_range)
        inst.components.combat:SetDefaultDamage(pig_config.growth.base_attack)
        inst.components.combat:SetAttackPeriod(0.5)

        inst:AddComponent("planardamage")
        inst:AddComponent("planardefense")

        -- 跟随
        inst:AddComponent("follower")
        inst.components.follower:KeepLeaderOnAttacked()
        inst.components.follower.OnChangedLeader = OnChangedLeader

        -- 其他组件
        inst:AddComponent("inventory")
        inst:AddComponent("inspectable")
        inst:AddComponent("entitytracker")
        inst:AddComponent("sleeper")
        inst.components.sleeper:SetResistance(3)
        inst.components.sleeper:SetSleepTest(ShouldSleep)
        inst.components.sleeper:SetWakeTest(ShouldWake)

        MakeMediumFreezableCharacter(inst, "pig_torso")
        inst.components.freezable:SetDefaultWearOffTime(0)
        inst.components.freezable.diminishingreturns = true

        MakeMediumBurnableCharacter(inst, "pig_torso")
        MakeHauntablePanic(inst)

        inst:SetBrain(brain)
        inst:SetStateGraph("SGdevourer_pig")

        inst.sg.mem.variation = var

        -- 初始化属性
        inst.extra_stats = {}
        ApplyLevelStats(inst, 1)

        -- 交易组件（接受头盔和所有食物类型）
        inst:AddComponent("trader")
        inst.components.trader:SetAcceptTest(function(inst, item)
            if item.components.equippable and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
                return true
            end
            if item.components.edible ~= nil then
                local ft = item.components.edible.foodtype
                return ft == FOODTYPE.MEAT or ft == FOODTYPE.VEGGIE or ft == FOODTYPE.HORRIBLE
            end
            return false
        end)
        inst.components.trader.onaccept = function(inst, giver, item)
            if item.components.equippable and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
                local current = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
                if current then inst.components.inventory:DropItem(current) end
                inst.components.inventory:Equip(item)
                inst.AnimState:Show("hat")
            end
            if item.components.edible then OnDevourerEatItem(inst, item) end
        end
        inst.components.trader.onrefuse = function(inst, item)
            inst.sg:GoToState("refuse")
        end
        inst.components.trader.deleteitemonaccept = false

        -- 事件监听
        inst:ListenForEvent("attacked", OnAttacked)
        inst:ListenForEvent("blocked", OnAttacked)
        inst:ListenForEvent("onattackother", OnAttack)
        inst:ListenForEvent("onhitother", OnHit)

        -- 工作获得经验（砍树/挖矿完成时触发）
        inst:ListenForEvent("finishedwork", function(pig, data)
            local action = data and data.action
            if not action or (action.id ~= "CHOP" and action.id ~= "MINE") then
                return
            end
            local leader = pig.components.follower and pig.components.follower.leader
            if leader and leader:HasTag("player") then
                local pack = add_utils.GetDevourerPack(leader)
                if pack and pack.components.devourer then
                    local dev = pack.components.devourer
                    local cfg = pig_config.growth
                    local oldCount = dev.pig_state.total_exp
                    dev.pig_state.total_exp = dev.pig_state.total_exp + cfg.work_exp
                    if dev:IsPigLevelUp(oldCount, dev.pig_state.total_exp) then
                        local newLevel = dev:GetPigLevel(dev.pig_state.total_exp)
                        if not dev:CheckBreakthrough(newLevel) then
                            local oldLevel = dev:GetPigLevel(oldCount)
                            dev.pig_state.total_exp = pig_config._cum_exp[oldLevel + 1] or pig_config._cum_exp[pig_config.growth.max_level]
                        end
                    end
                    SyncPigLevelExp(dev)
                    dev.pig_state.work_count = (dev.pig_state.work_count or 0) + 1
                    pig:ProcessKill(true, dev.pig_state.total_exp)
                    if pig.components.talker then
                        pig.components.talker:Say(
                            string.format(STRINGS.DEVOURER_PIG_MESSAGES.WORK_EXP, cfg.work_exp))
                    end
                end
            end
        end)

        -- 出场台词
        inst:DoTaskInTime(5, function()
            inst.components.talker:Say(STRINGS.DEVOURER_PIG_ELITE_SUMMONED)
        end)

        -- 验证猪人归属（压平后的逻辑：如果不是背包记录的猪，就消失）
        inst:DoTaskInTime(0.1, function()
            local leader = inst.components.follower and inst.components.follower.leader
            local should_die = false

            if not leader or not leader:HasTag("player") then
                should_die = true
            else
                local pack = add_utils.GetDevourerPack(leader)
                if not pack or not pack.components.devourer then
                    should_die = true
                else
                    local pig = pack.components.devourer.pig_state and pack.components.devourer.pig_state.pig
                    if not (pig and pig:IsValid() and pig.GUID == inst.GUID) then
                        should_die = true
                    end
                end
            end

            if should_die then
                ErodeAway(inst)
            end
        end)

        inst.ProcessKill = ProcessKill
        inst.persists = false
        return inst
    end

    return Prefab("devourer_pig" .. variation, fn, assets, prefabs)
end

return MakePigEliteFighter("1"),
    MakePigEliteFighter("2"),
    MakePigEliteFighter("3"),
    MakePigEliteFighter("4")

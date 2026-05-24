local containers = require("containers")
local add_configs = require('configs/add_configs')
local add_utils = require('utils/add_utils')
local shared = require("components/devourer/shared")
local RESISTANCES =
{
    "_combat",
    "explosive",
    "quakedebris",
    "lunarhaildebris",
    "caveindebris",
    "trapdamage",
}
local treadwater_hungerrate = 12
local voidwalk_hungerrate = 12

local function HasComponentCanAdd(inst, compname)
    -- 先检查已添加
    if inst.components[compname] then return true end

    -- 尝试添加（临时的），并检测
    local ok = pcall(function()
        inst:AddComponent(compname)
    end)
    -- 无论成败都删掉
    if ok then
        -- -- 如果没抛错，说明组件有效，立即移除，避免带来副作用
        inst:RemoveComponent(compname)
        return true
    else
        -- 添加失败
        return false
    end
end
-- 二分递减法，逐级递减
local function Get_Reduce(n)
    return 2 - 0.5^(n-1)
end
local function CheckCooldown(self, type)
    local now = GetStaticTime() or GetTime()  -- 优先使用静态时间
    local cooldown_timer = self._cooldown_timers[type]
    local last_time = cooldown_timer.last_time or 0
    local cooldown = cooldown_timer.cooldown or 10
    
    -- 精确到小数点后2位比较
    return now - last_time >= cooldown - 0.01, now
end

-- 铥矿头免疫伤害功能（原版5秒冷却，这里增加，因为有骨头盔甲配合的）
local function CreatePseudoInvincibilitySystem(self, owner)
    local inst = self.inst
    -- 参数说明：
    -- inst: 装备实体
    -- owner: 装备持有者（玩家）

    -- 默认配置（可覆盖）
    local config = {
        proc_chance = 0.2,                  -- 触发概率 (20%)
        duration = 3,                       -- 免伤持续时间 (秒)
        cooldown = 25,                      -- 冷却时间 (秒)
        fx_prefab = "forcefieldfx",         -- 力场特效Prefab名
        fx_offset = Vector3(0, 0.2, 0),     -- 特效位置偏移
        sanity_cost_ratio = 0.5,            -- 伤害转精神值扣除的比例 (50%)
    }

    -- 内部状态
    local _state = {
        fx = nil,       -- 特效实例
        task = nil,     -- 计时器任务
        is_active = false,
    }
    
    -- 关闭伪免疫
    local function Deactivate()
        if not _state.is_active then return end
        _state.is_active = false
        -- 1. 移除特效
        if _state.fx ~= nil then
            _state.fx:Remove()
            _state.fx = nil
        end
        -- 2. 恢复默认护甲
        if inst.components.armor ~= nil then
            local defense = math.min(self.stats.defense or 0, TUNING.DEVOURER_PACK_EFFECT.DEFENSE)
            inst.components.armor:SetAbsorption(defense)
            inst.components.armor.ontakedamage = nil
        end
        -- 3. 进入冷却
        _state.task = inst:DoTaskInTime(config.cooldown, function()
            _state.task = nil
        end)
    end

    -- 激活伪免疫
    local function Activate()
        -- add_utils.debug_print("Activate")
        if _state.is_active then return end
        if owner == nil or (owner.components.health and owner.components.health:IsDead()) then return end
        _state.is_active = true

        -- 1. 生成力场特效
        if _state.fx ~= nil then
            _state.fx:Remove()
        end
        _state.fx = SpawnPrefab(config.fx_prefab)
        _state.fx.entity:SetParent(owner.entity)
        _state.fx.Transform:SetPosition(config.fx_offset:Get())

        -- 2. 设置100%免伤
        if inst.components.armor == nil then
            inst:AddComponent("armor")
        end
        inst.components.armor:SetAbsorption(1.0)  -- 100%吸收

        -- 3. 伤害转精神值扣除
        inst.components.armor.ontakedamage = function(_, damage_amount)
            local defense = math.min(self.stats.defense or 0, TUNING.DEVOURER_PACK_EFFECT.DEFENSE)
            if owner == nil or (owner.components.health and owner.components.health:IsDead()) then return end
            if owner.components.sanity ~= nil and defense < 1 then
                local cost_ratio = config.sanity_cost_ratio or 0.5
                if defense > 0.95 then
                    cost_ratio = (1 - defense) * 10  -- 超过95%防御，免伤率越高，扣除精神值越少,96为0.4,97为0.3,98为0.2,99为0.1
                end
                owner.components.sanity:DoDelta(-damage_amount * cost_ratio)
            end
        end

        -- 4. 定时结束
        _state.task = inst:DoTaskInTime(config.duration, Deactivate)
    end

    -- 外部调用接口
    return {
        TryActivate = function(attack_data)
            if _state.task == nil and not attack_data.redirected then
                if math.random() < config.proc_chance then
                    Activate()
                end
            end
        end,
        ForceDeactivate = Deactivate,
        IsActive = function() return _state.is_active end,
    }
end

-- 骨头头盔免疫伤害功能
local function SetupResistanceSystem(inst)
    -- add_utils.debug_print("SetupResistanceSystem")
    
    -- 确保组件存在
    if not inst.components.resistance then
        inst:AddComponent("resistance")
    end
    if not inst.components.cooldown then
        inst:AddComponent("cooldown")
    end
    -- 默认配置（可覆盖）
    local config = {
        duration = 10 * FRAMES,             -- 护盾持续时间
        cooldown = 20,                      -- 冷却时间 (秒)
        variations = 3,                      -- 护盾变体数量
        shield_cd = 1.2                     -- 主护盾冷却（秒）
    }
    -- 设置全局冷却时间
    inst.components.cooldown.cooldown_duration = config.cooldown

    -- 选择护盾类型的本地函数
    local function PickShield()
        local t = GetTime()
        local flipoffset = math.random() < .5 and config.variations or 0

        -- 类型3是主护盾
        local dt = t - inst.lastmainshield
        if dt >= config.shield_cd then
            inst.lastmainshield = t
            return flipoffset + 3
        end

        local rnd = math.random()
        if rnd < dt / config.shield_cd then
            inst.lastmainshield = t
            return flipoffset + 3
        end

        return flipoffset + (rnd < dt / (config.shield_cd * 2) + .5 and 2 or 1)
    end

    -- 护盾结束时的处理
    local function OnShieldOver(originalCallback)
        -- add_utils.debug_print("OnShieldOver")
        if inst and inst.task then
            inst.task:Cancel()
            inst.task = nil
        end
        
        -- 移除所有抵抗类型
        for _, resistanceType in ipairs(RESISTANCES) do
            inst.components.resistance:RemoveResistance(resistanceType)
        end
        
        -- 恢复原来的伤害抵抗回调
        if originalCallback then
            inst.components.resistance:SetOnResistDamageFn(originalCallback)
        end
    end

    -- 当抵抗伤害时生成特效
    local function OnResistDamage(inst)
        -- 冷却状态检查
        if inst.components.cooldown:IsCharging() then
            return
        end
        
        local owner = inst.components.inventoryitem:GetGrandOwner() or inst
        local shieldType = PickShield()
        local fx = SpawnPrefab("shadow_shield"..tostring(shieldType))
        fx.entity:SetParent(owner.entity)

        if inst and inst.task then
            inst.task:Cancel()
            inst.task = nil
        end
        inst.task = inst:DoTaskInTime(config.duration, OnShieldOver, OnResistDamage)
        inst.components.resistance:SetOnResistDamageFn(nil)
        
        -- 启动冷却
        inst.components.cooldown:StartCharging()
    end

    -- 判断是否应该抵抗伤害(没日志)
    local function ShouldResistFn(inst)
        if not inst.components.equippable then
            inst:AddComponent("equippable")
        end
        if not (inst.components.equippable and inst.components.equippable.IsEquipped and inst.components.equippable:IsEquipped()) then
            return false
        end
        
        local owner = inst.components.inventoryitem.owner
        return owner ~= nil and not (owner.components.inventory and owner.components.inventory:EquipHasTag("forcefield"))
    end

    -- 充能完成时的回调
    local function OnChargedFn(inst)
        if inst and inst.task then
            inst.task:Cancel()
            inst.task = nil
        end
        
        -- 设置抵抗伤害回调
        inst.components.resistance:SetOnResistDamageFn(OnResistDamage)
        
        -- 添加所有抵抗类型
        for _, resistanceType in ipairs(RESISTANCES) do
            inst.components.resistance:AddResistance(resistanceType)
        end
    end

     -- 初始化
     inst.lastmainshield = 0
     inst.components.resistance:SetShouldResistFn(ShouldResistFn)
     inst.components.resistance:SetOnResistDamageFn(OnResistDamage)
 
     return {
         OnChargedFn = OnChargedFn,
         OnResistDamage = OnResistDamage,
         ShouldResistFn = ShouldResistFn
     }
end

-- 虚灵跟随攻击
local function activate_alterguardian(inst, owner)
    if inst._is_active then return end
    inst._is_active = true
end

local function deactivate_alterguardian(inst, owner)
    if not inst._is_active then return end
    inst._is_active = false
end

local function on_sanity_change(inst, owner)
    local sanity = owner.components.sanity ~= nil and owner.components.sanity:GetPercentWithPenalty() or 0
    if sanity > TUNING.SANITY_BECOME_ENLIGHTENED_THRESH then
        activate_alterguardian(inst, owner) -- 高精神值激活
    else
        deactivate_alterguardian(inst, owner) -- 低精神值停用
    end
end

local function spawn_gestalt(self, owner, target)
    local inst = self and self.inst
    if not self or not inst or not inst._is_active then return end
    if owner == nil or (owner.components.health and owner.components.health:IsDead()) then return end
    if not target or target == owner or not target:IsValid() or 
       (target.components.health and target.components.health:IsDead()) or
       target:HasTag("structure") or target:HasTag("wall") then
        return
    end
    -- 设置冷却
    inst._is_active = false
    inst:DoTaskInTime(1, function() 
        inst._is_active = true
    end)
    -- 生成虚灵
    local gestalt = SpawnPrefab("alterguardianhat_projectile")
    local x, y, z = target.Transform:GetWorldPosition()
    local r = GetRandomMinMax(3, 5)
    local delta_angle = GetRandomMinMax(-90, 90)
    local angle = (owner:GetAngleToPoint(x, y, z) + delta_angle) * DEGREES
    gestalt.Transform:SetPosition(x + r * math.cos(angle), y, z + r * -math.sin(angle))
    gestalt:ForceFacePoint(x, y, z)
    gestalt:SetTargetPosition(Vector3(x, y, z))
    
    -- 设置跟随
    if gestalt.components.follower then
        gestalt.components.follower:SetLeader(owner)
    end
    -- 月灵伤害计算（完全保留官方公式，仅替换格子相关参数）
    local lunarseedscount = self.stats and self.stats.lunar or 0
    if lunarseedscount > 0 then
        local conversioncount = TUNING.ALTERGUARDIANHAT_SEEDCOUNT_FOR_FULL_PLANAR_CONVERSION or 3
        local max_slots = self.upgrade_effects.lunar_seed.max or 5
        
        -- 完全保留官方计算公式
        local lunarseedplanarconversionmult = (math.min(lunarseedscount, conversioncount) / conversioncount) * (TUNING.ALTERGUARDIANHAT_MAX_PLANAR_CONVERSION or 0.25)
        local lunarseedbonusbasephysicaldamage = (math.max(lunarseedscount - conversioncount, 0) / (max_slots - conversioncount)) * TUNING.ALTERGUARDIANHAT_SEEDCOUNT_EXTRA_DAMAGE_MAX

        local physicaldamage = gestalt.components.combat.defaultdamage + lunarseedbonusbasephysicaldamage
        local planardamage = physicaldamage * lunarseedplanarconversionmult
        physicaldamage = physicaldamage * (1 - lunarseedplanarconversionmult)
        
        gestalt.components.combat:SetDefaultDamage(physicaldamage)
        if planardamage > 0 then
            if not gestalt.components.planardamage then
                gestalt:AddComponent("planardamage")
            end
            gestalt.components.planardamage:SetBaseDamage(planardamage)
        end
    end

    -- 消耗Sanity
    if owner.components.sanity then
        owner.components.sanity:DoDelta(-1, true)
    end
end

local function AoeReflect(owner, data, self)
    local inst = self and self.inst
    if not inst.aoe_refl and data ~= nil and not data.redirected then
        local aoe_refl = (self._cooldown_timers.aoereflect or 4) - self.stats.aoereflect
        inst.aoe_refl = true -- 立即标记冷却状态
        inst:DoTaskInTime(aoe_refl, function()
            inst.aoe_refl = nil
        end) -- 延迟重置
        SpawnPrefab("bramblefx_armor"):SetFXOwner(owner)-- 设置aoe特效，官方特效，官方实现了特效对应的伤害处理
        if owner.SoundEmitter ~= nil then   -- 播放音效
            owner.SoundEmitter:PlaySound("dontstarve/common/together/armor/cactus")
        end
    end
end

-- 发光
local function create_light(self, owner)
    local inst = self.inst
    if not inst._light and owner then
        inst._light = SpawnPrefab("alterguardianhatlight") -- 使用游戏内预设光源
        inst._light.entity:SetParent(owner.entity)
        inst._light.Light:SetColour(180/255, 195/255, 150/255) -- 固定为矿工帽颜色
        -- 调整光照范围
        inst._light.Light:SetRadius(self.stats.light)  -- 数值越大，光照范围越广
    end
end
local function remove_light(inst, owner)
    if inst and inst._light ~= nil then
        inst._light:Remove()
        inst._light = nil
    end
end
local function add_nightvision(inst, owner)
    if not inst:HasTag("nightvision") then
        inst:AddTag("nightvision")
    end
    -- 刷新装备,不执行这个会导致显示有问题
    local slot = inst.components.equippable.equipslot
    owner:PushEvent("unequip", {item=inst,eslot=slot})
    owner:PushEvent('equip', {item=inst,eslot=slot,no_animation=true})
end

local function remove_nightvision(inst, owner, push)
    if inst:HasTag("nightvision") then
        inst:RemoveTag("nightvision")
    end
    if push then -- 卸下装备也会执行这个，但是这时候就不需要推送事件了
        -- 刷新装备
        local slot = inst.components.equippable.equipslot
        if owner == nil then return end
        owner:PushEvent("unequip", {item=inst,eslot=slot})
        owner:PushEvent('equip', {item=inst,eslot=slot,no_animation=true})
    end
end

local function RemoveMonkeyCurse(owner)
    -- 1. 强制解除诅咒状态（服务端执行）
    if owner.components.cursable and TheWorld.ismastersim then
        owner.components.cursable:RemoveCurse("MONKEY", 999) -- 超大数字，用来强制恢复
    end
end

local function BuildEffectMessage(self, numeric_totals, boolean_effects, current_lv)
    local effects_by_level = { [1] = {}, [2] = {}, [3] = {} }
    
    -- 合并处理数值和布尔效果
    local function ProcessEffect(stat, formatted_str)
        local effect_level
        if add_configs.level_up.lv1.effect[stat] then
            effect_level = 1
        elseif add_configs.level_up.lv2.effect[stat] then
            effect_level = 2
        else
            effect_level = 3
        end
        table.insert(effects_by_level[effect_level], formatted_str)
    end

    -- 处理数值效果
    for stat, total in pairs(numeric_totals) do
        if STRINGS.DP_DevourerPack.EFFECTS[stat] and total > 0 then
            local display_value = add_configs.percent_effects[stat] and (total * 100) or total
            if stat == "aoereflect" then
                display_value = self._cooldown_timers.aoereflect - total
            end
            local formatted_str
            
            -- 套装效果特殊处理
            if add_configs.suits[stat] then
                local suit_cur = self.stats[stat] or 0
                if suit_cur > 0 then
                    formatted_str = string.format("%s%d/%d", STRINGS.DP_DevourerPack.EFFECTS[stat], suit_cur, add_configs.suits[stat])
                else
                    formatted_str = STRINGS.DP_DevourerPack.EFFECTS[stat]..STRINGS.DP_DevourerPack.LEVEL_UP_MSG.SUIT_UNLOCK
                end
            else
                formatted_str = string.format(STRINGS.DP_DevourerPack.EFFECTS[stat], display_value)
            end
            
            ProcessEffect(stat, formatted_str)
        end
    end

    -- 处理布尔效果
    for stat, effect_str in pairs(boolean_effects) do
        ProcessEffect(stat, effect_str)
    end

    -- 构建分组消息
    local lines = {}
    
    -- 1级效果（始终显示）
    if #effects_by_level[1] > 0 then
        table.insert(lines, STRINGS.DP_DevourerPack.LEVEL_UP_MSG.LV1_ACTIVE)
        table.insert(lines, table.concat(effects_by_level[1], ", "))
    end
    
    -- 2级效果（动态标题）
    if #effects_by_level[2] > 0 then
        local header = (current_lv >= 2) and STRINGS.DP_DevourerPack.LEVEL_UP_MSG.LV2_ACTIVE or STRINGS.DP_DevourerPack.LEVEL_UP_MSG.LV2_LOCKED
        table.insert(lines, header)
        table.insert(lines, table.concat(effects_by_level[2], ", "))
    end
    
    -- 3级效果（动态标题）
    if #effects_by_level[3] > 0 then
        local header = (current_lv >= 3) and STRINGS.DP_DevourerPack.LEVEL_UP_MSG.LV3_ACTIVE or STRINGS.DP_DevourerPack.LEVEL_UP_MSG.LV3_LOCKED
        table.insert(lines, header)
        table.insert(lines, table.concat(effects_by_level[3], ", "))
    end

    -- 处理无效果情况
    return #lines > 0 and 
        STRINGS.DP_DevourerPack.MOONROCK_CHECK.."\n"..table.concat(lines, "\n") or
        STRINGS.DP_DevourerPack.MOONROCK_CHECK.."\n"..STRINGS.DP_DevourerPack.LEVEL_UP_MSG.NO_ACTIVE_EFFECTS
end

local function ModCompat(container, widget, lv_x, lv_y, lv_fire, lv_ice, lv_repair)
	--remove them from read only so that we can update them
	removesetter(container, "widget")
	removesetter(container, "numslots")

	container.widget = widget
	container.numslots = widget.slotpos ~= nil and #widget.slotpos or 0
    add_utils.debug_print("Devourer ModCompat next replica UpdateWidget")
    container.inst.replica.devourer:UpdateWidget(lv_x, lv_y, lv_fire, lv_ice, lv_repair)

	--make them read only again after update
	makereadonly(container, "widget")
	makereadonly(container, "numslots")
end

-- 幸运值系统（基于官方幸运值系统，增加了事件加成和套装加成）
local function GetLuckFn(inst, owner)
    local devourer = inst.components.devourer
    add_utils.debug_print("GetLuckFn called:", "owner=", owner and owner:GetDisplayName(), "devourer_stats=", devourer and devourer.stats and devourer.stats.luck or "nil")
    if not devourer then return 0 end
    local stats = devourer.stats or {}
    local event_mult = devourer.event.YOTH and TUNING.HORSESHOE_EVENT_LUCK_MULTIPLIER or 1 -- 活动期间幸运值翻3倍
    local base_luck = (stats.luck or 0) * TUNING.HORSESHOE_LUCK
    local suit_mult = EntityHasSetBonus(owner, EQUIPMENTSETNAMES.YOTH_KNIGHT) and 2 or 1 -- 骑士套装幸运值翻倍
    add_utils.debug_print("Luck calculation:", "base_luck=", base_luck, "event_mult=", event_mult, "suit_mult=", suit_mult)
    return base_luck * event_mult * suit_mult
end

local function MakeAncientBroken(item, owner)
    -- 特殊处理：将完整的远古伪科学站变成损坏状态
    local pos = item:GetPosition()
    local broken = SpawnPrefab("ancient_altar_broken")
    broken.Transform:SetPosition(pos:Get())
    broken.components.workable:SetWorkLeft(TUNING.ANCIENT_ALTAR_BROKEN_WORK)
    TheWorld:PushEvent("ms_sendlightningstrike", pos)
    SpawnPrefab("collapse_small").Transform:SetPosition(pos:Get())
    
    -- 触发随机事件，和官方锤子破坏时一样
    local spawns = {
        tentacle_pillar_arm = { weight = 1 },
        monkey = { weight = 1 },
        bat = { weight = 1 },
        trinket = { weight = 1 },
        spider_hider = { weight = 1 },
        spider_spitter = { weight = 1 },
        stafflight = { weight = 1 },
    }
    
    local actions = {
        tentacle_pillar_arm = { amt = 6, var = 1, radius = 3 },
        monkey = { amt = 3, var = 1 },
        bat = { amt = 5 },
        trinket = { amt = 4 },
        spider_hider = { amt = 2 },
        spider_spitter = { amt = 2 },
        stafflight = { amt = 1 },
    }
    
    local function weighted_random_choice(t) 
        local total_weight = 0
        for _, item in pairs(t) do
            total_weight = total_weight + item.weight
        end
        local r = math.random() * total_weight
        local count = 0
        for k, v in pairs(t) do
            count = count + v.weight
            if r <= count then
                return k
            end
        end
        return next(t)
    end
    
    local function SpawnCritter(critter, pos, player)
        player:DoTaskInTime(math.random() * 0.8 + 1, function()
            TheWorld:PushEvent("ms_sendlightningstrike", pos)
            SpawnPrefab("collapse_small").Transform:SetPosition(pos:Get())
            local spawn = SpawnPrefab(critter)
            if spawn ~= nil then
                spawn.Transform:SetPosition(pos:Get())
                if spawn.components.combat ~= nil then
                    spawn.components.combat:SetTarget(player)
                end
            end
        end)
    end
    
    local function NoHoles(pt) return not TheWorld.Map:IsPointNearHole(pt) end
    
    local function PickRandomTrinket()
        local trinkets = {}
        for i = 1, 45 do
            if math.random() < 0.3 then -- 30% chance to include each trinket
                table.insert(trinkets, "trinket_"..i)
            end
        end
        return #trinkets > 0 and trinkets[math.random(#trinkets)] or "trinket_1"
    end
    
    local function DoRandomThing(inst, pos, count, target)
        count = count or 1
        pos = pos or inst:GetPosition()
        
        for doit = 1, count do
            local item_type = weighted_random_choice(spawns)
            local doaction = actions[item_type]
            
            local amt = doaction ~= nil and doaction.amt or 1
            local radius = doaction ~= nil and doaction.radius or 4
            
            for i = 1, amt do
                local offset = FindWalkableOffset(pos, math.random() * 6.28, radius, 8, true, false, NoHoles)
                if offset ~= nil then
                    offset.x = offset.x + pos.x
                    offset.z = offset.z + pos.z
                    if item_type == "trinket" then
                        local trinket_prefab = PickRandomTrinket()
                        if trinket_prefab ~= nil then
                            SpawnCritter(trinket_prefab, offset, owner)
                        end
                    else
                        SpawnCritter(item_type, offset, owner)
                    end
                end
            end
        end
    end
    
    -- 调用随机事件函数
    DoRandomThing(item, pos, 1, owner)
    
    item:PushEvent("onprefabswaped", {newobj = broken})
    item:Remove()
end

-- 功能1：随机获取一个炼金物品
local function get_random_alchemy_item()
    -- 初始化随机数种子（避免每次随机结果相同）
    math.randomseed(os.time())
    -- 生成1到数组长度的随机索引
    local random_index = math.random(1, #add_configs.alchemy_change_items_array)
    return add_configs.alchemy_change_items_array[random_index]
end

-- 功能2：判断物品是否在炼金列表中
local function is_item_in_alchemy_list(item_name)
    -- 哈希表直接查询，O(1)效率
    return add_configs.alchemy_change_items_map[item_name] == true
end


-- 周期性检查特殊升温降温格子
local function CheckSpecialSlots(inst, ticks)
    if not inst.components.container then return end
    
    -- 获取当前格子总数
    local num_slots = inst.components.container:GetNumSlots()
    
    -- 获取吞噬者组件和 stats
    local devourer = inst.components.devourer
    local stats = devourer and devourer.stats or {}

    -- 1. 处理修理格子（倒数第1个格子）
    if stats.repair_slot and stats.repair_slot > 0 and ticks % 6 == 0 then
        local repair_slot = num_slots
        local repair_item = inst.components.container:GetItemInSlot(repair_slot)
        if repair_item and repair_item:IsValid() then
            local repair_rate = stats.repair_slot * 0.01  -- 每级+1%修理效果
            local function OverRepair(comp_name, max_field)
                local comp = repair_item.components[comp_name]
                if not comp then return end
                local pct = comp:GetPercent()
                local new_pct = pct + repair_rate
                if new_pct > 1 and comp[max_field] then
                    -- 溢出部分转为增加上限: 120% → max × 1.2
                    comp[max_field] = comp[max_field] * new_pct
                    comp:SetPercent(1)
                else
                    comp:SetPercent(math.min(new_pct, 1))
                end
            end

            OverRepair("armor", "maxcondition")                -- 护甲
            OverRepair("fueled", "maxfuel")                    -- 燃料（提灯等）
            OverRepair("finiteuses", "total")                  -- 有耐久工具
            -- 新鲜度不超修（没有可扩展上限）
            if repair_item.components.perishable then
                local pct = repair_item.components.perishable:GetPercent()
                repair_item.components.perishable:SetPercent(math.min(pct + repair_rate, 1))
            end
        end
    end

    -- 2. 处理升温格子（倒数第2个格子）
    if stats.fire_slot then
        local heating_slot = num_slots - 1
        local heating_item = inst.components.container:GetItemInSlot(heating_slot)
        if heating_item and heating_item:IsValid() then
            -- 检查是否是食物且可以烤
            if heating_item.components.edible and heating_item.components.cookable then
                -- 自动烤熟食物
                local cooked_food = heating_item.components.cookable.product
                if cooked_food then
                    -- 获取原食物的堆叠数量（如果没有堆叠组件，默认1）
                    local stack_num = heating_item.components.stackable and heating_item.components.stackable:StackSize() or 1
                    -- 生成烤好的食物预制件
                    local cooked = SpawnPrefab(cooked_food)
                    if cooked then
                        -- 设置烤好食物的堆叠数量为原数量
                        if cooked.components.stackable then
                            cooked.components.stackable:SetStackSize(stack_num)
                        end
                        -- 移除原食物（整个堆叠）
                        inst.components.container:RemoveItemBySlot(heating_slot)
                        -- 放入对应数量的烤好食物
                        inst.components.container:GiveItem(cooked, heating_slot)
                        if inst.SoundEmitter then
                            inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_finish")
                        end
                    end
                end
            -- 检查是否是木头
            elseif heating_item.prefab == "log" then
                -- 获取原木头的堆叠数量（如果没有堆叠组件，默认1）
                local stack_num = heating_item.components.stackable and heating_item.components.stackable:StackSize() or 1
                -- 木头变成木炭
                local charcoal = SpawnPrefab("charcoal")
                if charcoal then
                    -- 设置木炭的堆叠数量为原木头数量
                    if charcoal.components.stackable then
                        charcoal.components.stackable:SetStackSize(stack_num)
                    end
                    -- 移除原木头（整个堆叠）
                    inst.components.container:RemoveItemBySlot(heating_slot)
                    -- 放入对应数量的木炭
                    inst.components.container:GiveItem(charcoal, heating_slot)
                    if inst.SoundEmitter then
                        inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
                    end
                end
            -- 检查是否是冰块，是的话，每隔10s降低20%新鲜度
            elseif heating_item.prefab == "ice" then
                if heating_item.components.perishable then
                    local old_percent = heating_item.components.perishable:GetPercent()
                    local new_percent = math.max(0, old_percent-0.2)
                    heating_item.components.perishable:SetPercent(new_percent)
                end
            -- 处理温度物品（如暖石）
            elseif heating_item.components.temperature then
                local current_temp = heating_item.components.temperature:GetCurrent()
                local max_temp = heating_item.components.temperature.maxtemp or 100
                if current_temp < max_temp then
                    heating_item.components.temperature:SetTemperature(math.min(current_temp + 30, max_temp))
                end
            end
        end
    end
    
    -- 3. 处理降温格子（倒数第3个格子）
    if stats.snow_slot then
        local cooling_slot = num_slots - 2
        local cooling_item = inst.components.container:GetItemInSlot(cooling_slot)
        
        -- 检查是否需要产生冰 (every 60 seconds)
        if ticks % 6 == 0 then
            if not cooling_item or (cooling_item and cooling_item.prefab == "ice") then
                -- 先声明冰的变量，默认nil
                local ice = nil
                -- 优先处理已有冰块的情况
                if cooling_item and cooling_item.prefab == "ice" then
                    -- 1. 恢复冰块的新鲜度到满
                    if cooling_item.components.perishable then
                        cooling_item.components.perishable:SetPercent(1) -- 新鲜度设为100%
                    end

                    -- 2. 检查堆叠是否未满，未满则+1，满了则不处理
                    if cooling_item.components.stackable then
                        local stack_size = cooling_item.components.stackable:StackSize()
                        if stack_size < cooling_item.components.stackable.maxsize then
                            -- 堆叠未满，增加1个
                            cooling_item.components.stackable:SetStackSize(stack_size + 1)
                            ice = cooling_item -- 这里把冰块赋值给 ice 变量，表示我们修改了冰块
                        end
                        -- 堆叠已满则什么都不做，跳过后续放置逻辑
                    end
                else
                    -- 格子空着，生成冰并放到指定格子
                    ice = SpawnPrefab("ice")
                    if ice then
                        inst.components.container:GiveItem(ice, cooling_slot)
                    end
                end

                -- -- 播放音效（仅在实际生成/修改了冰块时播放）
                -- if ice ~= nil and inst.SoundEmitter then
                --     inst.SoundEmitter:PlaySound("dontstarve/common/iceboulder_smash")
                -- end
            end
        end
        
        -- 处理温度物品（如暖石）
        if cooling_item and cooling_item:IsValid() and cooling_item.components.temperature then
            local current_temp = cooling_item.components.temperature:GetCurrent()
            local min_temp = cooling_item.components.temperature.mintemp or -20
            if current_temp > min_temp then
                cooling_item.components.temperature:SetTemperature(math.max(current_temp - 30, min_temp))
            end
        end
    end
    
    -- 3. 处理炼金格子（倒数第4个格子）30秒一次，随机变换格子内物品，在一个大的列表里面随机选一个，概率完全一样
    if devourer.max_level and ticks % 3 == 0 then
        local alchemy_slot = num_slots - 3
        local alchemy_item = inst.components.container:GetItemInSlot(alchemy_slot)
        -- 物品有效，才进行转换
        if alchemy_item and alchemy_item:IsValid() 
        -- and is_item_in_alchemy_list(alchemy_item.prefab) -- 只有当物品在炼金列表中时才转换
        then
            local random_prefab = get_random_alchemy_item()
            local new_item = SpawnPrefab(random_prefab)
            if new_item then
                -- 移除原物品（整个堆叠）
                -- inst.components.container:RemoveItemBySlot(alchemy_slot)
                alchemy_item:Remove()
                -- 放入新物品
                inst.components.container:GiveItem(new_item, alchemy_slot)
                -- if inst.SoundEmitter then
                --     inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_finish")
                -- end
            end
        end
    end
end

-- 定时轮询任务总方法
local function MainPeriodicTask(inst)
    if not inst.components.devourer then return end
    
    local self = inst.components.devourer
    local stats = self.stats
    local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner

    if not owner or not owner:IsValid() or (owner.components.health and owner.components.health:IsDead()) then return end
    
    -- Track time in 10-second ticks
    if not inst._task_ticks then
        inst._task_ticks = 0
    end
    inst._task_ticks = inst._task_ticks + 1
    local ticks = inst._task_ticks
    
    -- 1. 自动照顾农作物（10s）
    if stats.tend and owner and owner:IsValid() then
        local x, y, z = owner.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, TUNING.ONEMANBAND_RANGE, nil, {"INLIMBO"}, {"farm_plant"})
        for _, v in ipairs(ents) do
            if v.components.farmplanttendable ~= nil then
                v.components.farmplanttendable:TendTo(owner)
            end
        end
    end
    
    -- 2. 加热格子（10s）
    -- 3. 冷冻格子（10s）
    -- 4. 自动修复格子（60s）
    CheckSpecialSlots(inst, ticks)
    
    -- 5. Random talk (every 60 seconds)
    if TUNING.DEVOURER_PACK_SAY > 0 and ticks % 6 == 0 then
        if inst.components.talker then
            local msg = ""
            -- 10% chance for special message
            if math.random() <= 0.1 then
                if inst.components.devourer then
                    local devourer = inst.components.devourer
                    local disabled_items = {}
                    local current_lv = devourer.packlv.level
                    if current_lv == 3 then
                        -- If level 3, suggest random unconsumed item
                        for prefab, data in pairs(devourer.upgrade_effects) do
                            if not data.mod and (data.enab == false or (data.max and data.max > data.cur)) and not add_configs.NotShowUnItems[prefab] then
                                table.insert(disabled_items, prefab)
                            end
                        end
                    else
                        -- If not level 3, suggest upgrade materials
                        local items = add_configs.level_up["lv"..current_lv].item
                        for prefab,_ in pairs(items) do
                            if devourer.upgrade_effects[prefab] and devourer.upgrade_effects[prefab].enab == false then
                                table.insert(disabled_items, prefab)
                            end
                        end
                    end
                    -- If there are eligible items, choose one randomly
                    if #disabled_items > 0 then
                        local random_prefab = disabled_items[math.random(#disabled_items)]
                        local item_name = STRINGS.NAMES[string.upper(random_prefab)] or random_prefab
                        msg = string.format(STRINGS.DP_DevourerPack.UI.UPGRADE_SAY, item_name)
                    end
                end
            end
            if msg == "" then -- Normal message
                msg = STRINGS.DP_DEVOURERPACK_SAYS[math.random(#STRINGS.DP_DEVOURERPACK_SAYS)]
            end
            
            inst.components.talker:Say(msg)
            
            if TUNING.DEVOURER_PACK_SAY > 1 then
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/firesupressor_warningbell")
            end
        end
    end
    
    -- 6. 自动恢复被诅咒的生命（每60秒）
    if self:CheckSuit("ruins") and owner and owner.components.health and ticks % 6 == 0 then
        local health = owner.components.health
        if health and not health:IsDead() and health.penalty > 0 then
            -- 计算当前被惩罚的血量
            local penalized_health = health.maxhealth * health.penalty
            -- 计算恢复量：最大生命值的2%，且不小于1
            local recovery_amount = math.max(1, health.maxhealth * 0.02)
            -- 计算新的被惩罚血量
            local new_penalized_health = math.max(0, penalized_health - recovery_amount)
            -- 计算新的penalty值
            local new_penalty = new_penalized_health / health.maxhealth
            -- 设置新的penalty值
            health:SetPenalty(new_penalty)
            -- 强制更新HUD显示
            health:ForceUpdateHUD(true)
        end
    end
    
    -- 7. 自动恢复生命（每60秒）
    if stats.health and stats.health > 0 and owner and owner.components.health and ticks % 6 == 0 then
        owner.components.health:DoDelta(stats.health)
    end
end

local function StartMainTask(inst)
    if inst._main_task then
        inst._main_task:Cancel()
    end
    inst._main_task = inst:DoPeriodicTask(10, MainPeriodicTask) -- 10秒检查一次
end

local function StopMainTask(inst)
    if inst._main_task then
        inst._main_task:Cancel()
        inst._main_task = nil
    end
    inst._task_ticks = nil
end

local Devourer = Class(function(self, inst) 
    self.inst = inst
    self:OnInit()
end, nil, {})

-- 加载猪人管理模块（Mixin）
require("components/devourer/pig")(Devourer)

-- 加载控制功能模块（Mixin）
require("components/devourer/control")(Devourer)

-- 初始化方法
function Devourer:OnInit()
    self.stats = { }
	self.packlv = {
        level = TUNING.DEVOURER_PACK_DEFAULT_LEVEL,
        extra_rows = 0,
        fire = 0,
        ice = 0,
        repair = 0
    }
    self.upgrade_effects = add_utils.deepcopy(add_configs.upgrade_effects)
    self._allowed_effects = {
        [1] = add_utils.ShallowCopy(add_configs.level_up.lv1.effect),
        [2] = add_utils.MergeTables(add_configs.level_up.lv1.effect, add_configs.level_up.lv2.effect)
    }
    self._cooldown_timers = {
        gold = {
            last_time = 0,
            cooldown = 10,
        },
        moonrock = {
            last_time = 0,
            cooldown = 10,
        },
        aoereflect = 4, -- AOE反射冷却时间（秒,实际使用应该是这个数字-stats.aoereflect秒）
        extradamage = {
            all = 0.3,
            pre = 5
        },
    }
    -- 判断Mod是否开启
    self.mod = {
        medal = HasComponentCanAdd(self.inst, "medal_chaosdamage"),
        legion = HasComponentCanAdd(self.inst, "lifebender"),
        random_blueprint = TUNING.RANDOM_BLUEPRINT_CHECK, -- 无科技随机蓝图
    }
    -- IsModEnabledAny("modname") 也可以用来判断是否启用某个模组，modname是workshop-创意工坊id，不确定steam和wegame是否一致，所以不用这个方法
    self.event = {
        YOTP = IsSpecialEventActive(SPECIAL_EVENTS.YOTP),  -- 是否开启猪王年
        YOTR = IsSpecialEventActive(SPECIAL_EVENTS.YOTR),  -- 是否开启兔人年
        CARNIVAL = IsSpecialEventActive(SPECIAL_EVENTS.CARNIVAL),  -- 是否开启盛夏鸦年华
        HALLOWED_NIGHTS = IsSpecialEventActive(SPECIAL_EVENTS.YOTP),  -- 是否开启万圣节
        WINTERS_FEAST = IsSpecialEventActive(SPECIAL_EVENTS.YOTP),  -- 是否开启冬季盛宴
        YOTH = IsSpecialEventActive(SPECIAL_EVENTS.YOTH),  -- 是否开启发条骑士年
    }
    -- 模组物品是否展示
    for prefab, effect in pairs(self.upgrade_effects) do
        if (effect.mod and not self.mod[effect.mod]) or (effect.event and not self.event[effect.event]) then -- 活动或模组未开启，则隐藏
            effect.show = false
        end
        if effect.base_science and self.mod.random_blueprint then -- 无科技随机蓝图开启，则基础科技隐藏
            effect.show = false
        end
    end
    self.tags = {}

    self.PLAYER = {}

    -- 猪人状态（统一管理）
    self.pig_state = {
        pig = nil,                  -- 猪人实体引用
        kill_count = 0,             -- 击杀计数（经验）
        health = nil,               -- 召回时保存的血量
        max_health = 300,           -- 与 pig_config.growth.base_health 保持一致
        health_regen_task = nil,    -- 血量恢复定时器
        hat_data = nil,             -- 头盔保存数据
        name = nil,                 -- 猪人名字（持久化，首次召唤后不变）
        variation = nil,            -- 猪人变体/颜色（持久化，首次召唤后不变）
        alive = nil,                -- nil=未召唤过, true=活着, false=已死亡（需消耗猪鼻铸币复活）
        spawn_task = nil,           -- 生成定时器
        level_up_monsters = {},     -- Boss击杀追踪
    }
    self._onpigdeath = function(pig, data) self:PigDeath() end
    self._onpigkilled = function(pig, data) self:PigKilled(pig, data) end
    
    -- 初始化配置数据（写死，无需外部传入）
    local config_control_data = STRINGS.DEVOURER_CONTROLS or {}
    
    -- 存储当前值（基于default初始化）
    self.control_switch = {}
    for key, cfg in pairs(config_control_data) do
        self.control_switch[key] = cfg.default
    end
    
    -- 当前绑定的功能键（用于快捷键执行，需要持久化）
    self.current_bound_function = "AreaAttack"  -- 默认绑定范围攻击
    
    -- 同步event和mod状态到客户端
    if TheWorld.ismastersim then
        self:_SyncModsndEventsShow()
    end
end



function Devourer:CheckControlSwitch(switch_name, check_value)
    local switch = self.control_switch[switch_name]
    if switch == nil then
        add_utils.debug_print("CheckControlSwitch: 无效的开关名称", switch_name)
        return false
    end
    
    return switch >= check_value  -- 数字值大于等于检查值则视为开启
end

function Devourer:ChangeExtraDamage()
    local stats = self.stats
    local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner
    local inst = self.inst
    if not owner or not owner.components.combat then
        return STRINGS.DEVOURER_CONTROLS.ExtraDamage.reason.owner_no_combat
    end
    add_utils.debug_print("ChangeExtraDamage extra_damage:", self.control_switch.ExtraDamage)
    if stats and stats.externaldamage and stats.externaldamage > 0 then
        if self:CheckControlSwitch("ExtraDamage", 2) then 
            owner.components.combat.externaldamagemultipliers:SetModifier(inst, 1 + stats.externaldamage)
        else
            owner.components.combat.externaldamagemultipliers:RemoveModifier(inst)
        end
    end
    return nil
end

function Devourer:ChangeElectric()
    add_utils.debug_print("ChangeElectric value:", self.control_switch.Electric)
    local stats = self.stats
    local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner
    if not owner or not owner.components.combat then
        return STRINGS.DEVOURER_CONTROLS.ExtraDamage.reason.owner_no_combat
    end
    -- 电击伤害（打树精亮茄会着火，导致材料被烧掉）
    if self.control_switch.Electric == 1 and stats.electricattack and owner:HasDebuff("buff_electricattack") then
        owner:RemoveDebuff("buff_electricattack")
    end
end

function Devourer:ChangeLight(new_status)
    local inst = self.inst
    local owner = inst.components.inventoryitem.owner
    if new_status == nil then
        new_status = self.control_switch.NightVision or 2
    end
    if (new_status == 2 or new_status == 4) and not(self.stats and self.stats.light and self.stats.light > 0) then
        return STRINGS.DP_DevourerPack.Light.disabled
    end
    if new_status >= 3 and not self:CheckSuit("nightvision") then -- 如果夜视未开启，则在发光和关闭之间切换
        new_status = self.control_switch.NightVision == 2 and 1 or 2
    end
    self.control_switch.NightVision = new_status
    add_utils.debug_print("切换光照状态:", new_status)
    if new_status == 1 then
        remove_light(inst, owner)
        remove_nightvision(inst, owner, true)
        -- self.inst.components.talker:Say(STRINGS.DP_DevourerPack.Light.close)
    elseif new_status == 2 then
        create_light(self, owner)
        remove_nightvision(inst, owner, true)
        -- self.inst.components.talker:Say(STRINGS.DP_DevourerPack.Light.light)
    elseif new_status == 3 then
        remove_light(inst, owner)
        add_nightvision(inst, owner)
        -- self.inst.components.talker:Say(STRINGS.DP_DevourerPack.Light.nightvision)
    elseif new_status == 4 then
        create_light(self, owner)
        add_nightvision(inst, owner)
    end
end

function Devourer:CheckEnable(prefab)
    return self and self.upgrade_effects and self.upgrade_effects[prefab] and self.upgrade_effects[prefab].enab or false
end

function Devourer:Check(item)
    -- 初始日志：记录检查开始和传入的物品信息
    add_utils.debug_print("[Devourer Check] 开始检查物品是否可吞噬")
    add_utils.debug_print(string.format("  传入物品: %s", tostring(item and item.prefab or "nil")))

    -- 检查物品和升级效果表是否存在
    if item and item.prefab and self.upgrade_effects and self.upgrade_effects[item.prefab] and self.upgrade_effects[item.prefab].show then
        local tempcheck = self.upgrade_effects[item.prefab]
        add_utils.debug_print(string.format(" [Devourer Check] %s: max=%s, current=%s, enab=%s, show=%s", item.prefab,
            tostring(tempcheck.max),
            tostring(tempcheck.cur),
            tostring(tempcheck.enab),
            tostring(tempcheck.show)))

        if item.prefab == "nightmarefuel" then
            local current_lv = self.packlv.level >= 3
            local lunar_open = current_lv and self.upgrade_effects.alterguardianhat and self.upgrade_effects.alterguardianhat.enab 
                and self.upgrade_effects.lunar_seed and self.upgrade_effects.lunar_seed.enab and self.upgrade_effects.lunar_seed.cur >= 5 or false
            local zero_open = self:CheckEnable("purpleamulet")
            if not lunar_open and not zero_open then
                return false
            end
        end

        if tempcheck.except then
            local except_open = self:CheckEnable(tempcheck.except)
            if except_open then
                return false
            end
        end

        if item.prefab == "pigskin" then
            local pig_open = self:CheckEnable("pig_coin")
            if not pig_open then
                return false
            end
        end

        if tempcheck.max ~= nil then
            -- 有数量限制的升级材料检查
            add_utils.debug_print("  处理有数量限制的材料...")
            local result = tempcheck.max > tempcheck.cur
            add_utils.debug_print(string.format("[Devourer Check] 检查结果: max:%s - current:%s" ,tempcheck.max ,tempcheck.cur))
            return result
        else
            -- 无数量限制的检查
            add_utils.debug_print("  处理无数量限制的材料...")
            local result = tempcheck.enab ~= true
            add_utils.debug_print(string.format("[Devourer Check] 检查结果: enab:%s" ,tostring(tempcheck.enab)))
            return result
        end
    end

    -- 默认情况日志
    if not item then
        add_utils.debug_print("[Devourer Check] 检查失败: 物品对象为nil")
    elseif not item.prefab then
        add_utils.debug_print("[Devourer Check] 检查失败: 物品prefab为nil")
    elseif not self.upgrade_effects then
        add_utils.debug_print("[Devourer Check] 检查失败: upgrade_effects表为nil")
    elseif not self.upgrade_effects[item.prefab] then
        add_utils.debug_print(string.format("[Devourer Check] 检查失败: 物品%s不在升级效果表中", item.prefab))
    elseif not self.upgrade_effects[item.prefab].show then
        add_utils.debug_print(string.format("[Devourer Check] 检查失败: 物品%s的Show字段为false", item.prefab))
    end

    return false
end
-- 额外伤害，物理，位面，百分比物理
function Devourer:ExtraDamage(owner, target)
    if self and target and target.components.combat then
        local stats = self.stats
        local inst = self.inst
        local damage = stats.damage or 0
        local spdamage = { planar = stats.spdamage or 0 }
        local predamage = stats.predamage or 0
        
        if predamage > 0 and not inst.etd_pre_cooldown then
            local etd_pre_cooldown = self._cooldown_timers.extradamage.pre or 5
            inst.etd_pre_cooldown = true
            inst:DoTaskInTime(etd_pre_cooldown, function()
                inst.etd_pre_cooldown = nil
            end)
            local pre_damage = math.max(target.components.health.maxhealth * predamage, 1)
            damage = damage + pre_damage
        end
        target.components.combat:GetAttacked(owner, damage, nil, nil, spdamage)
    end
end
-- 百分比吸血
function Devourer:BloodSucking(player, data)
    if self and self.stats and self.stats.bloodsucking and self.stats.bloodsucking > 0 
        and player and player.components.health and not player.components.health:IsDead() then
        local damage = data and data.damage
        if damage and damage > 0 then
            player.components.health:DoDelta(damage * self.stats.bloodsucking)
        end
    end
end
local AREAATTACK_MUST_TAGS = { "_combat" }
-- 范围攻击
function Devourer:AreaAttack(player, data)
    local weapon = data.weapon
    -- player.components.combat:DoAreaAttack(
    --     data.target, 
    --     3,  -- 攻击范围
    --     weapon,  -- 武器
    --     nil,             -- 可选：自定义目标筛选函数
    --     "shadow",             -- 可选：攻击特效（stimuli）
    --     add_configs.ignoreList  -- 排除Aoe伤害的标签
    -- )
    local x, y, z = data.target.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 3, AREAATTACK_MUST_TAGS, add_configs.ignoreList)
    for i, ent in ipairs(ents) do
        if ent ~= data.target and ent ~= self.inst and ent.components.combat and player.components.combat:IsValidTarget(ent) then
            player:PushEvent("onareaattackother", { target = ent, weapon = weapon, stimuli = "shadow" })
            local dmg, spdmg = player.components.combat:CalcDamage(ent, weapon, 0.5)    -- 0.5的范围伤害倍率
            ent.components.combat:GetAttacked(player, dmg, weapon, "shadow", spdmg)
        end
    end
    -- 生成特效
    local fx = SpawnPrefab("shadow_merm_smacked_poof_fx")
    fx.Transform:SetPosition(x, y, z)
    player.components.sanity:DoDelta(-1, true)
end
-- 攻击事件监听（这时候还没击中，只是攻击动作起手）
function Devourer:On_Attack(player, data)
    -- add_utils.debug_print("[Devourer OnHit] 触发攻击事件")
    if self and data and data.target ~= nil and data.target:IsValid() and not data.redirected then
        local stats = self.stats
        if stats then
            if stats.gestaltattack and self:CheckControlSwitch("GestaltAttack", 2) then
                spawn_gestalt(self, player, data.target)
            end
        end
    end
    -- add_utils.debug_print("[Devourer OnHit] 触发攻击事件结束")
end
-- 击中事件监听
function Devourer:On_Hit(player, data)
    -- add_utils.debug_print("[Devourer OnHit] 触发击中事件")
    if self and data and data.target ~= nil and data.target:IsValid() and not data.redirected and not self._attack_hit then
        self._attack_hit = true
        
        local stats = self.stats
        local inst = self.inst
        if stats then
            if stats.bloodsucking and stats.bloodsucking > 0 then
                self:BloodSucking(player, data)
            end
            if self:CheckSuit("shadow") and self:CheckControlSwitch("AreaAttack", 2) then
                self:AreaAttack(player, data)
            end
            if not inst.damage_cooldown and ((stats.damage and stats.damage > 0) or (stats.spdamage and stats.spdamage > 0) or (stats.predamage and stats.predamage > 0))
                and self:CheckControlSwitch("ExtraDamage", 2) then
                inst.damage_cooldown = true -- 增加额外伤害冷却，避免有些mod导致的无限伤害循环
                inst:DoTaskInTime(0.3, function()
                    inst.damage_cooldown = nil
                end)
                self:ExtraDamage(player, data.target)
            end
        end
        self._attack_hit = false  -- 标记攻击状态，避免重复触发
    end
    -- add_utils.debug_print("[Devourer OnHit] 触发击中事件结束")
end
-- 被击中事件监听
function Devourer:On_Attacked(player, data)
    -- add_utils.debug_print("[Devourer OnHit] 触发被击中事件")
    if self and data and not data.redirected and player and player.components.health and not player.components.health:IsDead() then
        local stats = self.stats
        local inst = self.inst
        if stats and inst then
            if stats.aoereflect and stats.aoereflect > 0 and self.control_switch.Reflect >= 3 then   -- aoe反伤
                AoeReflect(player, data, self)
            end
            if stats.forcefield and inst._pseudo_invincible then    -- 铥矿头无敌
                inst._pseudo_invincible.TryActivate(data)
            end
        end
    end
    -- add_utils.debug_print("[Devourer OnHit] 触发被击中事件结束")
end
-- 复活
function Devourer:Rebirth(player)
    if player and player:HasTag("player") and player:HasTag("playerghost") then    
        player:PushEvent("respawnfromghost")  -- 强制复活
        self.inst.components.talker:Say(STRINGS.DP_DevourerPack.OTHERS.REBIRTH)
        if self.inst.components.hauntable then
            self.inst:RemoveComponent("hauntable")
        end
        self:SetEnabFalse("amulet", true)
    end
end

function Devourer:CheckSuit(suitKey, stats) -- 检查套装是否启用
    -- 检查 self 和 self.stats 是否存在
    if not self or not suitKey then
        return false
    end
    if not stats then
        stats = self.stats or {}
    end
    -- 检查套装配置是否存在
    local requiredCount = add_configs.suits[suitKey]
    if not requiredCount then
        return false
    end
    -- 检查当前套装数量是否足够
    local currentCount = stats[suitKey] or 0
    -- 检查是否满足等级或允许效果
    local allowed = false
    if self.packlv.level == 3 then
        allowed = true
    elseif self._allowed_effects and self._allowed_effects[self.packlv.level] then
        allowed = self._allowed_effects[self.packlv.level][suitKey] or false
    end
    -- 最终判断
    local result = (currentCount >= requiredCount) and allowed
    -- add_utils.debug_print(string.format("[Devourer CheckSuit] 套装检查: %s, 当前数量: %d, 需要数量: %d, 允许效果: %s, 结果: %s",suitKey, currentCount, requiredCount, tostring(allowed), tostring(result)))

    return result
end

-- 解绑武器加成
local function UnbindWeaponBonus(owner, inst)
    if owner._dev_equip_weapon and owner._dev_equip_weapon:IsValid() then
        if owner._dev_equip_weapon.components.damagetypebonus then
            owner._dev_equip_weapon.components.damagetypebonus:RemoveBonus("shadow_aligned", inst, TUNING.DEVOURER_PACK_WEAPON_BONUS.KEY)
            owner._dev_equip_weapon.components.damagetypebonus:RemoveBonus("lunar_aligned", inst, TUNING.DEVOURER_PACK_WEAPON_BONUS.KEY)
        end
    end
    owner._dev_equip_weapon = nil
end
-- 解绑空手加成
local function UnbindOwnerBonus(owner, inst)
    if owner.components.damagetypebonus then
        owner.components.damagetypebonus:RemoveBonus("shadow_aligned", inst, TUNING.DEVOURER_PACK_WEAPON_BONUS.KEY)
        owner.components.damagetypebonus:RemoveBonus("lunar_aligned", inst, TUNING.DEVOURER_PACK_WEAPON_BONUS.KEY)
    end
end
local function AddDevourerBouns(self, weapon)
    local stats = self.stats
    local inst = self.inst
    if self:CheckSuit("dreadstone", stats) then
        if not weapon.components.damagetypebonus then
            weapon:AddComponent("damagetypebonus")
        end
        weapon.components.damagetypebonus:AddBonus("lunar_aligned", inst, TUNING.DEVOURER_PACK_WEAPON_BONUS.VS_LUNAR, TUNING.DEVOURER_PACK_WEAPON_BONUS.KEY)
    end
    if self:CheckSuit("lunarplant", stats) then
        if not weapon.components.damagetypebonus then
            weapon:AddComponent("damagetypebonus")
        end
        weapon.components.damagetypebonus:AddBonus("shadow_aligned", inst, TUNING.DEVOURER_PACK_WEAPON_BONUS.VS_SHADOW, TUNING.DEVOURER_PACK_WEAPON_BONUS.KEY)
    end
end
-- 装备物品时：绑定武器加成、保护帽子耐久
function Devourer:OnEquipItem(owner, inst, data)
    if not (self and self.stats) then return end

    if data and data.eslot == EQUIPSLOTS.HANDS then
        add_utils.debug_print("[OnEquipItem] HANDS equip, item=" .. tostring(data.item))
        UnbindWeaponBonus(owner, inst)
        UnbindOwnerBonus(owner, inst)
        local weapon = owner.components.inventory and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if weapon then
            AddDevourerBouns(self, weapon)
        else
            AddDevourerBouns(self, owner)
        end
        owner._dev_equip_weapon = weapon
    end

    if data and data.eslot == EQUIPSLOTS.HEAD then
        add_utils.debug_print("[OnEquipItem] HEAD equip, item=" .. tostring(data.item) .. ", stronghead=" .. tostring(self:CheckSuit("stronghead")))
        if self:CheckSuit("stronghead") then
            local hat = data.item
            if hat then
                self:ProtectHatDurability(hat)
                owner._dev_protected_hat = hat
            end
        end
    end
end

-- 卸下物品时：解绑武器加成、恢复帽子耐久
function Devourer:OnUnequipItem(owner, inst, data)
    if not (self and self.stats) then return end

    if data and data.eslot == EQUIPSLOTS.HANDS then
        add_utils.debug_print("[OnUnequipItem] HANDS unequip, item=" .. tostring(data.item))
        UnbindWeaponBonus(owner, inst)
        UnbindOwnerBonus(owner, inst)
        local weapon = owner.components.inventory and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if weapon then
            AddDevourerBouns(self, weapon)
        else
            AddDevourerBouns(self, owner)
        end
        owner._dev_equip_weapon = weapon
    end

    if data and data.eslot == EQUIPSLOTS.HEAD then
        add_utils.debug_print("[OnUnequipItem] HEAD unequip, item=" .. tostring(data.item))
        local hat = owner._dev_protected_hat
        if hat and (hat._dev_original_maxfuel or hat._dev_original_totaluses
            or hat._dev_original_perish_time or hat._dev_original_armor_max) then
            add_utils.debug_print("[OnUnequipItem] restoring hat durability for " .. tostring(hat))
            self:RestoreHatDurability(hat)
        end
        owner._dev_protected_hat = nil
    end
end

-- 保护帽子耐久度：装备时放大耐久上限
function Devourer:ProtectHatDurability(hat)
    add_utils.debug_print("[ProtectHatDurability] called, hat=" .. tostring(hat) .. ", prefab=" .. tostring(hat and hat.prefab)
        .. ", already_protected=" .. tostring(hat and (hat._dev_original_maxfuel or hat._dev_original_totaluses or hat._dev_original_perish_time or hat._dev_original_armor_max)))
    -- 如果已经保护过，不覆盖原始值（避免 EquipUpdate 多次调用时把 math.huge 存成"原始值"）
    if hat._dev_original_maxfuel or hat._dev_original_totaluses or hat._dev_original_perish_time or hat._dev_original_armor_max then
        add_utils.debug_print("[ProtectHatDurability] already protected, skip")
        return
    end

    if hat.components.fueled and hat.components.fueled.maxfuel > 0 then
        add_utils.debug_print("[ProtectHatDurability] fueled: saving maxfuel=" .. tostring(hat.components.fueled.maxfuel) .. ", percent=" .. tostring(hat.components.fueled:GetPercent()))
        hat._dev_original_maxfuel = hat.components.fueled.maxfuel
        hat._dev_original_fuel_percent = hat.components.fueled:GetPercent()
        hat.components.fueled.maxfuel = math.huge
        hat.components.fueled:SetPercent(hat._dev_original_fuel_percent)
    end

    if hat.components.finiteuses and hat.components.finiteuses.maxuses > 0 then
        add_utils.debug_print("[ProtectHatDurability] finiteuses: saving total=" .. tostring(hat.components.finiteuses.total) .. ", percent=" .. tostring(hat.components.finiteuses:GetPercent()))
        hat._dev_original_totaluses = hat.components.finiteuses.total
        hat._dev_original_uses_percent = hat.components.finiteuses:GetPercent()
        hat.components.finiteuses:SetMaxUses(math.huge)
        hat.components.finiteuses:SetPercent(hat._dev_original_uses_percent)
    end

    if hat.components.perishable and hat.components.perishable.perishtime > 0 then
        add_utils.debug_print("[ProtectHatDurability] perishable: saving perishtime=" .. tostring(hat.components.perishable.perishtime) .. ", percent=" .. tostring(hat.components.perishable:GetPercent()))
        hat._dev_original_perish_time = hat.components.perishable.perishtime
        hat._dev_original_perish_percent = hat.components.perishable:GetPercent()
        hat.components.perishable:SetPerishTime(math.huge)
        hat.components.perishable:SetPercent(hat._dev_original_perish_percent)
    end

    if hat.components.armor and hat.components.armor.maxcondition > 0 then
        add_utils.debug_print("[ProtectHatDurability] armor: saving maxcondition=" .. tostring(hat.components.armor.maxcondition) .. ", condition=" .. tostring(hat.components.armor.condition))
        hat._dev_original_armor_max = hat.components.armor.maxcondition
        hat._dev_original_armor_percent = hat.components.armor.condition / hat.components.armor.maxcondition
        hat.components.armor.maxcondition = math.huge
        hat.components.armor.condition = math.huge
    end
    add_utils.debug_print("[ProtectHatDurability] done, saved flags: maxfuel=" .. tostring(hat._dev_original_maxfuel) .. ", totaluses=" .. tostring(hat._dev_original_totaluses) .. ", perish=" .. tostring(hat._dev_original_perish_time) .. ", armor=" .. tostring(hat._dev_original_armor_max))
end

-- 恢复帽子原始耐久度：卸下时恢复
function Devourer:RestoreHatDurability(hat)
    add_utils.debug_print("[RestoreHatDurability] called, hat=" .. tostring(hat) .. ", prefab=" .. tostring(hat and hat.prefab)
        .. ", saved_maxfuel=" .. tostring(hat and hat._dev_original_maxfuel)
        .. ", saved_totaluses=" .. tostring(hat and hat._dev_original_totaluses)
        .. ", saved_perish=" .. tostring(hat and hat._dev_original_perish_time)
        .. ", saved_armor=" .. tostring(hat and hat._dev_original_armor_max))
    if hat.components.fueled and hat._dev_original_maxfuel then
        add_utils.debug_print("[RestoreHatDurability] restoring fueled: maxfuel=" .. tostring(hat._dev_original_maxfuel) .. ", percent=" .. tostring(hat._dev_original_fuel_percent))
        hat.components.fueled.maxfuel = hat._dev_original_maxfuel
        hat.components.fueled:SetPercent(hat._dev_original_fuel_percent)
        hat._dev_original_maxfuel = nil
        hat._dev_original_fuel_percent = nil
    end

    if hat.components.finiteuses and hat._dev_original_totaluses then
        add_utils.debug_print("[RestoreHatDurability] restoring finiteuses: total=" .. tostring(hat._dev_original_totaluses) .. ", percent=" .. tostring(hat._dev_original_uses_percent))
        hat.components.finiteuses:SetMaxUses(hat._dev_original_totaluses)
        hat.components.finiteuses:SetPercent(hat._dev_original_uses_percent)
        hat._dev_original_totaluses = nil
        hat._dev_original_uses_percent = nil
    end

    if hat.components.perishable and hat._dev_original_perish_time then
        add_utils.debug_print("[RestoreHatDurability] restoring perishable: perishtime=" .. tostring(hat._dev_original_perish_time) .. ", percent=" .. tostring(hat._dev_original_perish_percent))
        -- 恢复到原始腐烂时间
        hat.components.perishable:SetPerishTime(hat._dev_original_perish_time)
        hat.components.perishable:SetPercent(hat._dev_original_perish_percent)
        hat._dev_original_perish_time = nil
        hat._dev_original_perish_percent = nil
    end

    -- 恢复护甲类头部装备
    if hat.components.armor and hat._dev_original_armor_max then
        add_utils.debug_print("[RestoreHatDurability] restoring armor: maxcondition=" .. tostring(hat._dev_original_armor_max) .. ", percent=" .. tostring(hat._dev_original_armor_percent))
        hat.components.armor.maxcondition = hat._dev_original_armor_max
        hat.components.armor.condition = hat._dev_original_armor_max * hat._dev_original_armor_percent
        hat._dev_original_armor_max = nil
        hat._dev_original_armor_percent = nil
    end
    add_utils.debug_print("[RestoreHatDurability] done")
end
-- 新增：定义存储多来源修改值的表结构
local function InitSourceTables(owner)
    if not owner.slipperyfeet_sources then
        owner.slipperyfeet_sources = {
            decay_accel = {},  -- 存储各来源的decay_accel值
            threshold = {}     -- 存储各来源的threshold值
        }
    end
end


-- 开启特殊效果
function Devourer:EquipUpdate(inst, owner)
    local stats = self and self.stats
    -- if devourer_pack_upgrade and stats then
    if stats then
        -- self.equipe_enabled = true
        local attackother = false
        local hitother = false
        local attacked = false
        local equip = false
        local phasechange = false
        if not inst then 
            inst = self.inst
        end
        if inst and not owner then 
            owner = inst.components.inventoryitem.owner
        end
        if not (inst and owner and owner:HasTag("player")) then
            return
        end
        add_utils.debug_print("EquipUpdate owner:",owner.GUID,",player:",owner:HasTag("player"),",prefab:",owner.prefab or "nil")
        if not self.PLAYER[owner.GUID] then
            self.PLAYER[owner.GUID] = {}
        end

        if stats.planardefense and stats.planardefense > 0 then
            if not owner.components.planardefense then
                owner:AddComponent("planardefense")
            end
            owner.components.planardefense:AddBonus(inst, stats.planardefense, "devourer_pack")
        end

        if stats.externaldamage and stats.externaldamage > 0 and owner and owner.components.combat then
            owner.components.combat.externaldamagemultipliers:SetModifier(inst, 1 + stats.externaldamage)
        end

        -- 发光
        if stats.light and stats.light > 0 then
            self:ChangeLight()  -- 开启光照
        end

        -- 饥饿速度
        if stats.hunger_rate and stats.hunger_rate > 0 and owner.components.hunger then
            local hunger_rate = stats.hunger_rate
            hunger_rate = math.max(1 - hunger_rate, 0.1)
            owner.components.hunger.burnratemodifiers:SetModifier(inst, hunger_rate, "devourer_pack")
        end

        -- 保暖/隔热
        if (stats.kw and stats.kw > 0) or (stats.kc and stats.kc > 0) and owner.components.temperature then
            shared.monitor_temperature(self, owner)
        end

        -- 85%以上精神值，攻击有虚影跟随攻击，onattackother表示攻击开始时（动画阶段）
        if stats.gestaltattack then
            attackother = true
            if inst._onsanity then
                inst:RemoveEventCallback("sanitydelta", inst._onsanity, owner)
                inst._onsanity = nil
            end
            if owner.components.sanity then
                inst._onsanity = function() on_sanity_change(inst, owner) end
                inst:ListenForEvent("sanitydelta", inst._onsanity, owner)
                -- 初始检查精神值状态
                local sanity = owner.components.sanity:GetPercent() or 0
                if sanity > TUNING.SANITY_BECOME_ENLIGHTENED_THRESH then
                    activate_alterguardian(inst, owner)
                end
            end
        end

        -- 力场护盾(铥矿头)，attacked表示被攻击
        if stats.forcefield then
            attacked = true
            if inst._pseudo_invincible then
                inst._pseudo_invincible = nil
            end
            -- 初始化铥矿头功能
            inst._pseudo_invincible = CreatePseudoInvincibilitySystem(self, owner)
        end
        
        -- 骨头盔甲免伤
        if stats.resistance then
            local resistanceSystem = SetupResistanceSystem(inst)
            inst.components.cooldown.onchargedfn = resistanceSystem.OnChargedFn
            
            -- 卸下再装备上5秒冷却，正常使用20秒冷却
            inst.components.cooldown:StartCharging(5)
        end

        -- 增加视野距离
        if stats.extraview and stats.extraview > 0 and owner.isplayer and TUNING.DEVOURER_PACK_EFFECT.EXTRAVIEW > 0 then
            local max_extraview = stats.extraview
            if TUNING.DEVOURER_PACK_EFFECT.EXTRAVIEW >= 0 then
                max_extraview = math.min(TUNING.DEVOURER_PACK_EFFECT.EXTRAVIEW, stats.extraview)
            end
            owner:AddCameraExtraDistance(inst, max_extraview, "devourer_pack")
        end

        -- 理智下降抗性
        if stats.saresistance and stats.saresistance > 0 and owner.components.sanity then
            local saresistance = math.max(1 - stats.saresistance, 0) -- 这里的值是百分比，0-1之间，0.1即是只受到10%影响，譬如原本每分钟下降10，现在下降1
            owner.components.sanity.neg_aura_modifiers:SetModifier(inst, saresistance)
        end

        -- 蜘蛛巢不减速
        if stats.creep and owner.components.locomotor then
            owner.components.locomotor:SetTriggersCreep(false)
        end

        -- 吸血,onhitother表示攻击命中后（伤害计算完成）
        if stats.bloodsucking and stats.bloodsucking > 0 then
            hitother = true
        end

        -- 食物限制解除
        if stats.vegetarian or stats.carnivore or stats.cookperson then
            -- 保存原始饮食设置
            if not self.PLAYER[owner.GUID].original_diet then
                self.PLAYER[owner.GUID].original_diet = {
                    caneat = owner.components.eater and owner.components.eater.caneat or nil,
                    preferseating = owner.components.eater and owner.components.eater.preferseating or nil
                }
            end
            
            -- 临时修改饮食设置
            if owner.components.eater then
                -- 根据角色类型和背包属性来修改饮食设置
                local original_caneat = self.PLAYER[owner.GUID].original_diet.caneat or {}
                local original_preferseating = self.PLAYER[owner.GUID].original_diet.preferseating or {}
                
                -- 创建新的饮食设置，包含原始类型
                local new_caneat = {}
                local new_preferseating = {}
                
                -- 添加原始类型
                for _, v in ipairs(original_caneat) do
                    table.insert(new_caneat, v)
                end
                for _, v in ipairs(original_preferseating) do
                    table.insert(new_preferseating, v)
                end
                
                -- 根据角色类型和背包属性添加相应的食物类型
                local player_prefab = owner.prefab
                
                -- 薇格弗德：添加素食
                if player_prefab == "wigfrid" and stats.vegetarian then
                    local has_vegetarian = false
                    for _, v in ipairs(new_caneat) do
                        if v == FOODGROUP.VEGETARIAN then
                            has_vegetarian = true
                            break
                        end
                    end
                    if not has_vegetarian then
                        table.insert(new_caneat, FOODGROUP.VEGETARIAN)
                    end
                    
                    has_vegetarian = false
                    for _, v in ipairs(new_preferseating) do
                        if v == FOODGROUP.VEGETARIAN then
                            has_vegetarian = true
                            break
                        end
                    end
                    if not has_vegetarian then
                        table.insert(new_preferseating, FOODGROUP.VEGETARIAN)
                    end
                end
                
                -- 沃特：添加肉食
                if player_prefab == "wurt" and stats.carnivore then
                    local has_meat = false
                    for _, v in ipairs(new_caneat) do
                        if v == FOODGROUP.MEAT then
                            has_meat = true
                            break
                        end
                    end
                    if not has_meat then
                        table.insert(new_caneat, FOODGROUP.MEAT)
                    end
                    
                    has_meat = false
                    for _, v in ipairs(new_preferseating) do
                        if v == FOODGROUP.MEAT then
                            has_meat = true
                            break
                        end
                    end
                    if not has_meat then
                        table.insert(new_preferseating, FOODGROUP.MEAT)
                    end
                end
                
                -- 不挑食：允许所有食物
                if stats.cookperson then
                    owner.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODGROUP.OMNI })
                else
                    -- 应用修改后的饮食设置
                    owner.components.eater:SetDiet(new_caneat, new_preferseating)
                end
            end
        end

        -- 添加血量上限
        if stats.hp and stats.hp > 0 and owner.components.health ~= nil then
            local old_add = self.PLAYER[owner.GUID].add_hp or 0
            local new_add = stats.hp
            local percent = owner.components.health:GetPercent()
            local max = owner.components.health.maxhealth
            if old_add > 0 and max <= (self.PLAYER[owner.GUID].base_hp or 0) then
                old_add = 0
            end
            owner.components.health:SetMaxHealth(max - old_add + new_add)
            owner.components.health:SetPercent(percent, false)-- 保持当前比例
            self.PLAYER[owner.GUID].add_hp = new_add
            if not self.PLAYER[owner.GUID].base_hp then
                self.PLAYER[owner.GUID].base_hp = max
            end
            add_utils.debug_print(string.format("Health - base: %d, old: %d, new: %d, oldmax: %d, newmax: %d, percent: %.2f", 
                self.PLAYER[owner.GUID].base_hp, old_add, new_add, max, owner.components.health.maxhealth, percent))
        end
        -- 添加精神上限
        if stats.sanity and stats.sanity > 0 and owner.components.sanity then
            local old_add = self.PLAYER[owner.GUID].add_sanity or 0
            local new_add = stats.sanity
            local percent = owner.components.sanity:GetPercent()
            local max = owner.components.sanity.max
            if old_add > 0 and max <= (self.PLAYER[owner.GUID].base_sanity or 0) then
                old_add = 0
            end
            owner.components.sanity:SetMax(max - old_add + new_add)
            owner.components.sanity:SetPercent(percent, false)-- 保持当前比例
            self.PLAYER[owner.GUID].add_sanity = new_add
            if not self.PLAYER[owner.GUID].base_sanity then
                self.PLAYER[owner.GUID].base_sanity = max
            end
            add_utils.debug_print(string.format("Sanity - base: %d, old: %d, new: %d, oldmax: %d, newmax: %d, percent: %.2f", 
                self.PLAYER[owner.GUID].base_sanity, old_add, new_add, max, owner.components.sanity.max, percent))
        end
        -- 添加饱食度上限
        if stats.hunger and stats.hunger > 0 and owner.components.hunger then
            local old_add = self.PLAYER[owner.GUID].add_hunger or 0
            local new_add = stats.hunger
            local percent = owner.components.hunger:GetPercent()
            local max = owner.components.hunger.max
            if old_add > 0 and max <= (self.PLAYER[owner.GUID].base_hunger or 0) then
                old_add = 0
            end
            owner.components.hunger:SetMax(max - old_add + new_add)
            owner.components.hunger:SetPercent(percent, false)-- 保持当前比例
            self.PLAYER[owner.GUID].add_hunger = new_add
            if not self.PLAYER[owner.GUID].base_hunger then
                self.PLAYER[owner.GUID].base_hunger = max
            end
            add_utils.debug_print(string.format("Hunger - base: %d, old: %d, new: %d, oldmax: %d, newmax: %d, percent: %.2f", 
                self.PLAYER[owner.GUID].base_hunger, old_add, new_add, max, owner.components.hunger.max, percent))
        end

        -- 火焰伤害减免
        if stats.firedreduction and stats.firedreduction > 0 and owner.components.health ~= nil and owner.components.health.externalfiredamagemultipliers then
            local firedrate = math.max(1 - stats.firedreduction, 0)
            owner.components.health.externalfiredamagemultipliers:SetModifier(inst, firedrate)
        end

        -- 昏睡抗性
        if stats.sleep_res and stats.sleep_res > 0 and owner.components.grogginess then
            owner.components.grogginess:AddResistanceSource("devourer_pack", stats.sleep_res)
        end
        
        -- 带电攻击，每天夜晚给予一次buff，大概四分钟（游戏里面的半天）
        if stats.electricattack then
            phasechange = true
            -- 初始检查当前时间阶段
            if self:CheckControlSwitch("Electric", 2) and TheWorld.state.isnight then
                owner:AddDebuff("buff_electricattack", "buff_electricattack")
            end
        end

        -- 冰冻抗性
        if stats.freeze_res and stats.freeze_res > 0 and owner.components.freezable then
            if not inst._original_freeze_res then
                inst._original_freeze_res = owner.components.freezable.resistance or 1
            end
            owner.components.freezable:SetResistance(inst._original_freeze_res + stats.freeze_res) 
        end

        -- 诅咒解析
        if self:CheckSuit("monkey_token") then
            -- 设置诅咒物品清除，初始化检查物品栏
            local function DestroyCursedTokens()
                if not owner or not owner.components.inventory then return end
                local has_monkey_token = false
                for k, item in pairs(owner.components.inventory.itemslots) do
                    if item:HasTag("monkey_token") then
                        has_monkey_token = true
                        break
                    end
                end
                if has_monkey_token or owner:HasTag("wonkey") then
                    RemoveMonkeyCurse(owner)
                end
            end
            -- 首次检查
            DestroyCursedTokens()
            -- 监听后续进入物品栏的物品
            if not inst._token_destroy_listener then
                inst._token_destroy_listener = function(owner, data)
                    if data and data.item and data.item:HasTag("monkey_token") then
                        RemoveMonkeyCurse(owner)
                    end
                end
                owner:ListenForEvent("itemget", inst._token_destroy_listener)
            end
        end
        
        -- aoe反伤
        if stats.aoereflect and stats.aoereflect > 0 then
            attacked = true
        end

        if owner.components.combat and 
        ((stats.damage and stats.damage > 0) or (stats.spdamage and stats.spdamage > 0) or (stats.predamage and stats.predamage > 0))  then
            -- attackother = true
            hitother = true
        end

        -- 工作效率提升
        if stats.chopwork and stats.chopwork > 0 and owner.components.workmultiplier then
            local chopwork = 1 + stats.chopwork
            owner.components.workmultiplier:AddMultiplier(ACTIONS.CHOP, chopwork, inst)
        end
        if stats.minework and stats.minework > 0 and owner.components.workmultiplier then
            local minework = 1 + stats.minework
            owner.components.workmultiplier:AddMultiplier(ACTIONS.MINE, minework, inst)
        end
        if stats.hammerwork and stats.hammerwork > 0 and owner.components.workmultiplier then
            local hammerwork = 1 + stats.hammerwork
            owner.components.workmultiplier:AddMultiplier(ACTIONS.HAMMER, hammerwork, inst)
        end
        -- 沃尔夫冈力量流失
        if stats.mightiness and stats.mightiness > 0 and owner.components.mightiness then
            local mightiness_rate = math.max(1-stats.mightiness, 0)
            owner.components.mightiness.ratemodifiers:SetModifier(inst, mightiness_rate, "devourer_pack")
        end
        -- 建造消耗减少
        if stats.ingredientmod and stats.ingredientmod > 0 and owner.components.builder then
            local ingredientmod_rate = math.max(1-stats.ingredientmod, 0)
            -- 确保值合法，取最接近的预设值（因为官方的这个建造消耗减少固定是0,0.25,0.5,0.75,1，不是这几个会报错）
            if ingredientmod_rate > 0.75 then
                ingredientmod_rate = INGREDIENT_MOD_LOOKUP[4]
            elseif ingredientmod_rate > 0.5 then
                ingredientmod_rate = INGREDIENT_MOD_LOOKUP[3]
            elseif ingredientmod_rate > 0.25 then
                ingredientmod_rate = INGREDIENT_MOD_LOOKUP[2]
            elseif ingredientmod_rate > 0 then
                ingredientmod_rate = INGREDIENT_MOD_LOOKUP[1]
            else
                ingredientmod_rate = INGREDIENT_MOD_LOOKUP[0]
            end
            owner.components.builder.ingredientmod = ingredientmod_rate
        end
        -- 如履平地（蚁狮陷坑不减速）
        if stats.walksinkhole and owner.components.carefulwalker then
            if not inst.original_careful_speed then-- 记录原始值
                inst.original_careful_speed = owner.components.carefulwalker.carefulwalkingspeedmult
            end
            -- 设置速度为1（无减速）
            owner.components.carefulwalker:SetCarefulWalkingSpeedMultiplier(1)
        end
        -- -- 踏雪无痕（冰面不打滑）这里改为有个original记录，避免和吞噬者手杖的冲突
        -- if stats.walkice and owner.components.slipperyfeet then
        --     if not owner.original_sf_decay_accel and owner.components.slipperyfeet.decay_accel then-- 记录原始值
        --         owner.original_sf_decay_accel = owner.components.slipperyfeet.decay_accel
        --     end
        --     -- 禁用滑行衰减加速
        --     owner.components.slipperyfeet.decay_accel = 0
        --     if not owner.original_sf_threshold and owner.components.slipperyfeet.threshold then-- 记录原始值
        --         owner.original_sf_threshold = owner.components.slipperyfeet.threshold
        --     end
        --     owner.components.slipperyfeet.threshold = 10000
        -- end
        -- 赋值逻辑：添加来源并取最大值
        -- 踏雪无痕（冰面不打滑）
        if stats.walkice and owner.components.slipperyfeet then
            InitSourceTables(owner)
            local sourceKey = "devourerpack"  -- 当前来源标识，可根据实际来源命名
            
            -- 处理decay_accel
            if not owner.original_sf_decay_accel then
                -- 首次记录原始值
                owner.original_sf_decay_accel = owner.components.slipperyfeet.decay_accel
            end
            -- 记录当前来源的值（这里0是该来源要设置的值）
            owner.slipperyfeet_sources.decay_accel[sourceKey] = 0
            -- 计算所有来源中的最大值并应用
            local max_decay = owner.original_sf_decay_accel
            for _, v in pairs(owner.slipperyfeet_sources.decay_accel) do
                if v > max_decay then
                    max_decay = v
                end
            end
            owner.components.slipperyfeet.decay_accel = max_decay

            -- 处理threshold
            if not owner.original_sf_threshold then
                -- 首次记录原始值
                owner.original_sf_threshold = owner.components.slipperyfeet.threshold
            end
            -- 记录当前来源的值（这里10000是该来源要设置的值）
            owner.slipperyfeet_sources.threshold[sourceKey] = 10000
            -- 计算所有来源中的最大值并应用
            local max_threshold = owner.original_sf_threshold
            for _, v in pairs(owner.slipperyfeet_sources.threshold) do
                if v > max_threshold then
                    max_threshold = v
                end
            end
            owner.components.slipperyfeet.threshold = max_threshold
        end
        -- ================================================
        -- 灵魂罐功能配置（仅对小恶魔角色有效）
        -- ================================================
        -- 说明：灵魂罐标签和canonlygoinpocket属性允许灵魂物品放入背包
        -- 这部分必须在装备方法中处理，因为非小恶魔角色使用会导致背包无法打开
        if owner.prefab == "wortox" and stats.souljar and not inst:HasTag("souljar") then
            -- 添加灵魂罐标签，允许灵魂放入
            inst:AddTag("souljar")
            inst.components.inventoryitem.canonlygoinpocket = true -- 灵魂物品会检查此属性
            
        elseif owner.prefab ~= "wortox" then
            -- 非小恶魔角色，移除灵魂罐功能
            inst:RemoveTag("souljar")
            inst.components.inventoryitem.canonlygoinpocket = false
        end

        -- 进食恢复 
        if owner.components.eater and stats.food_add and stats.food_add > 0 then
            if owner._devourer_set_food_add then    -- 如果是已经设置过的，则恢复原函数，因为这里会设置多次，如果不先恢复，会导致无限循环报错
                owner.components.eater.custom_stats_mod_fn = owner._original_eater_fn_devourer
                owner._original_eater_fn_devourer = nil
            end
            owner._devourer_set_food_add = true
            -- 保存原始函数
            if not owner._original_eater_fn_devourer and owner.components.eater.custom_stats_mod_fn then
                owner._original_eater_fn_devourer = owner.components.eater.custom_stats_mod_fn
            end
            -- 设置新的食物效果修改函数
            owner.components.eater.custom_stats_mod_fn = function(owner, health, hunger, sanity, food, feeder)
                -- 如果有原始函数且不是我们自己，防止无限循环报错
                if owner._original_eater_fn_devourer ~= nil then
                    health, hunger, sanity = owner._original_eater_fn_devourer(owner, health, hunger, sanity, food, feeder)
                end
                local food_add = 1 + stats.food_add
                -- 仅对正值应用加成
                return 
                    health and health > 0 and health * food_add or health,
                    hunger and hunger > 0 and hunger * food_add or hunger,
                    sanity and sanity > 0 and sanity * food_add or sanity
            end
        end

        if self:CheckSuit("shadow") then
            hitother = true
        end
        
        if self:CheckSuit("lunarplant") or self:CheckSuit("dreadstone") or self:CheckSuit("stronghead") then
            equip = true
        end
        
       if stats.health_absor and owner.components.health then
            -- 1. 计算当前应叠加的减伤总量（蜗牛套5% + 千层帽5%，最多10%）

            -- 2. 取当前玩家的实时总减伤（含所有效果：我们的叠加、变身、其他装备等）
            local current_total_absorb = owner.components.health.absorb or 0
            -- 反推“无当前装备叠加”的实时基础减伤（确保非负）
            local old_add = self._add_health_absor or 0
            local real_base_absorb = current_total_absorb - old_add

            -- 3. 核心判断：区分“原减伤超95%”的两种情况
            local new_total_absorb = current_total_absorb -- 默认保持当前值，避免打断逻辑
            if real_base_absorb < 0.95 then
                -- 情况1：玩家自身基础减伤 <95% → 正常叠加，上限95%
                new_total_absorb = math.min(real_base_absorb + stats.health_absor, 0.95)
                -- 应用新减伤（仅当需要修改时才执行）
                owner.components.health:SetAbsorptionAmount(new_total_absorb)
                -- 精准记录实际生效的叠加值（避免clamp后偏差）
                self._add_health_absor = new_total_absorb - real_base_absorb
            else
                -- 情况2：玩家自身基础减伤 ≥95% → 我们的叠加不生效，重置记录
                self._add_health_absor = nil
                -- 不修改减伤，保持玩家原有状态（避免覆盖其他效果叠加的结果）
            end
        end
        
        -- 终止恐惧buff
        if stats.bravery_buff then
            phasechange = true
            -- 初始检查当前时间阶段
            if TheWorld.state.isday and not owner:HasDebuff("halloweenpotion_bravery_buff") then
                owner:AddDebuff("halloweenpotion_bravery_buff", "halloweenpotion_bravery_large_buff")
            end
        end

        if stats.steal then
            hitother = true
        end

        -- 精神状态恢复
        if self.control_switch.SanityChange and self.control_switch.SanityChange ~= 1 then -- 退出重进的时候才有用，因为脱掉的时候会直接重置为关闭，但是退出重进不会重置
            self:ChangeSanityStatus(self.control_switch.SanityChange)
        end

        -- 勋章兼容
        if stats.chaos_damage and stats.chaos_damage > 0 and stats.chaos_bonus and stats.chaos_bonus > 0 and self.mod.medal then
            if not owner.components.medal_chaosdamage then
                owner:AddComponent("medal_chaosdamage")
            end
            local medal_damage = stats.chaos_damage * stats.chaos_bonus * TUNING.DEVOURER_PACK_WEAPON_BONUS.MEDAL_DAMAGE_MULT
            inst.medal_CalcChaosDamage = function()
                return medal_damage
            end
            owner.components.medal_chaosdamage:SetCalcBonusDamageFn(inst.medal_CalcChaosDamage, TUNING.DEVOURER_PACK_WEAPON_BONUS.KEY)
        end

        -- 窃血抵抗：和棱镜mod兼容，叠加生效
        if stats.siv_blood_l_reducer and stats.siv_blood_l_reducer > 0 and self.mod.legion then
            local resist_value = stats.siv_blood_l_reducer -- 你的固定抵抗值，比如0.3
            local source_key = "devourer_pack" -- 你的装备唯一标识，避免和原mod冲突

            -- 1. 初始化窃血抵抗表（和原mod结构保持一致）
            if owner.siv_blood_l_reducer == nil then
                owner.siv_blood_l_reducer = {}
            end

            -- 2. 记录当前装备的抵抗值（独立来源，不覆盖原mod数据）
            owner.siv_blood_l_reducer[source_key] = resist_value

            -- 3. 计算叠加后的总抵抗值（模仿原mod加法逻辑）
            local total_resist = 0
            for _, v in pairs(owner.siv_blood_l_reducer) do
                total_resist = total_resist + v
            end

            -- 4. 赋值给总和字段，供原mod窃血逻辑读取
            owner.siv_blood_l_reducer_v = total_resist > 0 and total_resist or nil

            add_utils.debug_print(string.format("[窃血抵抗] 装备添加：来源=%s，固定值=%.2f，当前叠加总和=%.2f", 
                source_key, resist_value, total_resist))
        end
        
        -- 添加特殊标签
        local function AddTagWithLog(tag, desc)
            if stats[tag] and not owner:HasTag(tag) then
                self.tags[tag] = true
                owner:AddTag(tag)
                add_utils.debug_print(string.format("[角色标签] 已添加: %s (%s)", tag, desc))
            end
        end
        AddTagWithLog("moonstormevent_detector", "显示瓦格斯特夫")
        if self:CheckSuit("overlord") then
            AddTagWithLog("overlord", "霸者神威")
        end
        AddTagWithLog("beefalo" ,"牛牛伪装")
        AddTagWithLog("spiderdisguise" ,"蜘蛛伪装")
        AddTagWithLog("rabbitdisguise" ,"兔子伪装")
        AddTagWithLog("ghost_ally", "幽灵盟友")
        AddTagWithLog("master_crewman", "海盗水手")
        AddTagWithLog("boat_health_buffer", "海盗船长")   
        if self:CheckSuit("stronggrip") then
            AddTagWithLog("stronggrip", "强握")
        end
        if self:CheckSuit("fastbuilder") then
            AddTagWithLog("fastbuilder", "快速制作")
        end
        AddTagWithLog("houndfriend", "狗狗朋友") 
        AddTagWithLog("shadowdominance", "影怪无仇恨") 
        AddTagWithLog("insect", "蜜蜂之友")
        if self:CheckSuit("mightiness_mighty") then
            AddTagWithLog("mightiness_mighty", "强壮") 
        end
        if self:CheckSuit("princess_suit") then
            AddTagWithLog("chessfriend", "发条生物朋友") 
        end
        
        if attackother then -- 攻击事件监听
            if inst._onattack then -- 安全移除之前的回调（如果存在）
                inst:RemoveEventCallback("onattackother", inst._onattack, owner)
                inst._onattack = nil
            end
            inst._onattack = function(_, data) self:On_Attack(owner, data) end
            inst:ListenForEvent("onattackother", inst._onattack, owner)
        end
        
        if hitother then    -- 击中事件监听
            if inst._onhit then -- 每次加载的时候去掉之前的，因为这个可以重复，避免多个一起导致数据异常
                owner:RemoveEventCallback("onhitother", inst._onhit)
                inst._onhit = nil
            end
            inst._onhit = function(owner, data) 
                self:On_Hit(owner, data) 
            end
            owner:ListenForEvent("onhitother", inst._onhit)
        end

        if attacked then    -- 被击中事件监听
            if inst._on_attacked then
                inst:RemoveEventCallback("attacked", inst._on_attacked, owner)
                inst._on_attacked = nil
            end
            inst._on_attacked = function(owner, data)
                self:On_Attacked(owner, data)
            end
            inst:ListenForEvent("attacked", inst._on_attacked, owner)
        end

        if equip then    -- 切换装备监听
            add_utils.debug_print("[EquipUpdate] equip=true, setting up equip/unequip listeners, inst=" .. tostring(inst))
            -- 清理旧的装备监听
            if inst._on_equip then
                add_utils.debug_print("[EquipUpdate] old _on_equip exists, removing first")
                inst:RemoveEventCallback("equip", inst._on_equip, owner)
                inst._on_equip = nil
            end
            if inst._on_unequip then
                add_utils.debug_print("[EquipUpdate] old _on_unequip exists, removing first")
                inst:RemoveEventCallback("unequip", inst._on_unequip, owner)
                inst._on_unequip = nil
            end
            -- 注册装备回调
            inst._on_equip = function(owner, data)
                self:OnEquipItem(owner, inst, data)
            end
            inst:ListenForEvent("equip", inst._on_equip, owner)
            -- 注册卸下回调
            inst._on_unequip = function(owner, data)
                self:OnUnequipItem(owner, inst, data)
            end
            inst:ListenForEvent("unequip", inst._on_unequip, owner)
            local current_hat = owner.components.inventory and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
            add_utils.debug_print("[EquipUpdate] current_hat=" .. tostring(current_hat) .. ", stronghead=" .. tostring(self:CheckSuit("stronghead")))
            if current_hat and self:CheckSuit("stronghead") then
                -- 套装启用，保护帽子
                add_utils.debug_print("[EquipUpdate] calling ProtectHatDurability for " .. tostring(current_hat))
                self:ProtectHatDurability(current_hat)
                owner._dev_protected_hat = current_hat
            elseif current_hat and (current_hat._dev_original_maxfuel or current_hat._dev_original_totaluses
                or current_hat._dev_original_perish_time or current_hat._dev_original_armor_max) then
                -- 套装禁用，恢复帽子
                add_utils.debug_print("[EquipUpdate] stronghead disabled, restoring hat " .. tostring(current_hat))
                self:RestoreHatDurability(current_hat)
                owner._dev_protected_hat = nil
            end

            -- 初始化武器加成：装备背包时立即应用当前手部武器的加成
            UnbindWeaponBonus(owner, inst)
            UnbindOwnerBonus(owner, inst)
            local current_weapon = owner.components.inventory and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if current_weapon then
                add_utils.debug_print("[EquipUpdate] initial weapon bonus on " .. tostring(current_weapon))
                AddDevourerBouns(self, current_weapon)
            else
                add_utils.debug_print("[EquipUpdate] initial weapon bonus on owner (empty hand)")
                AddDevourerBouns(self, owner)
            end
            owner._dev_equip_weapon = current_weapon
        else
            add_utils.debug_print("[EquipUpdate] equip=false, _on_equip listener NOT set up")
        end

        if phasechange then
            -- 移除可能存在的旧监听器
            if inst._on_phase_changed then
                inst:RemoveEventCallback("phasechanged", inst._on_phase_changed, TheWorld)
                inst._on_phase_changed = nil
            end
            -- 定义时间阶段变化回调
            inst._on_phase_changed = function(src, phase)
                add_utils.debug_print("[PhaseChanged] 当前阶段:", phase)
                if phase == "night" and stats.electricattack and self.control_switch.Electric == 2 then   -- 每天夜晚给一个带电buff
                    owner:AddDebuff("buff_electricattack", "buff_electricattack")
                elseif phase == "day" then
                    if stats.bravery_buff then
                        owner:AddDebuff("halloweenpotion_bravery_buff", "halloweenpotion_bravery_large_buff")
                    end
                end
            end
            inst:ListenForEvent("phasechanged", inst._on_phase_changed, TheWorld)
        end
        
        -- 解锁科技，使用官方builder组件的原生属性
        if TUNING.DEVOURER_TECH and owner.components.builder then
            local builder = owner.components.builder
            
            -- 记录原始加成值，以便卸下时恢复
            if not self._original_tech_bonuses then
                self._original_tech_bonuses = {
                    science_bonus = builder.science_bonus or 0,
                    magic_bonus = builder.magic_bonus or 0,
                    seafaring_bonus = builder.seafaring_bonus or 0,
                    ancient_bonus = builder.ancient_bonus or 0,
                    -- mashturfcrafting_bonus = builder.mashturfcrafting_bonus or 0, -- 暂时未使用
                    celestial_bonus = builder.celestial_bonus or 0,
                    shadowforging_bonus = builder.shadowforging_bonus or 0,
                    lunarforging_bonus = builder.lunarforging_bonus or 0
                }
            end
            
            -- 科学机器和炼金引擎 - 科学科技加成
            if stats.recipe1 then
                builder.science_bonus = math.max(builder.science_bonus or 0, 1)
            end
            if stats.recipe2 then
                builder.science_bonus = math.max(builder.science_bonus or 0, 2)
            end
            
            -- 智囊团 - 航海科技加成
            if stats.recipe1_boat then
                builder.seafaring_bonus = math.max(builder.seafaring_bonus or 0, 2)
            end
            
            -- 灵子分解器和暗影操控器 - 魔法科技加成
            if stats.recipe1_magic then
                builder.magic_bonus = math.max(builder.magic_bonus or 0, 2)
            end
            if stats.recipe2_magic then
                builder.magic_bonus = math.max(builder.magic_bonus or 0, 3)
            end
            
            -- 远古伪科学站 - 古代科技加成
            if stats.recipe_ancient then
                builder.ancient_bonus = math.max(builder.ancient_bonus or 0, 4)
            end
            
            -- 天体宝珠、天体圣殿/天体祭坛 - 天体科技加成
            if stats.recipe1_moon then
                builder.celestial_bonus = math.max(builder.celestial_bonus or 0, 1)
            end
            if stats.recipe2_moon then
                builder.celestial_bonus = math.max(builder.celestial_bonus or 0, 3)
            end
            
            -- 辉煌铁匠铺 - 月面锻造科技加成
            if stats.recipe_lunar then
                builder.lunarforging_bonus = math.max(builder.lunarforging_bonus or 0, 2)
            end
            
            -- 暗影术基座 - 暗影锻造科技加成
            if stats.recipe_shadow then
                builder.shadowforging_bonus = math.max(builder.shadowforging_bonus or 0, 2)
            end
            
            -- 触发科技树变化事件，更新制作栏
            owner:PushEvent("refreshcrafting")

            add_utils.debug_print(string.format("[科技解锁] 科技加成 - 科学: %d, 魔法: %d, 航海: %d, 远古: %d, 天体: %d, 月面锻造: %d, 暗影锻造: %d",
                builder.science_bonus or 0,
                builder.magic_bonus or 0,
                builder.seafaring_bonus or 0,
                builder.ancient_bonus or 0,
                builder.celestial_bonus or 0,
                builder.lunarforging_bonus or 0,
                builder.shadowforging_bonus or 0
            ))
        end

        self:UpdateLeader(owner)

        StartMainTask(inst)
    end
end

-- 关闭特殊效果
function Devourer:UnEquipUpdate(inst, owner)
    local stats = self and self.stats
    -- if devourer_pack_upgrade and stats then
    if stats then
        local attackother = false
        local hitother = false
        local attacked = false
        if not inst then 
            inst = self.inst
        end
        if inst and not owner then 
            owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
        end
        if not (inst and owner and owner:HasTag("player")) then
            return
        end

        if stats.planardefense and stats.planardefense > 0 then
            if not owner.components.planardefense then
                owner:AddComponent("planardefense")
            end
            owner.components.planardefense:RemoveBonus(inst, "devourer_pack")
        end

        -- 额外伤害
        if stats.externaldamage and stats.externaldamage > 0 and owner and owner.components.combat then
            owner.components.combat.externaldamagemultipliers:RemoveModifier(inst)
        end
        
        -- 停止发光
        remove_light(inst, owner)
        remove_nightvision(inst, owner)
    
        -- 饥饿速度恢复正常
        if owner.components.hunger ~= nil then 
            owner.components.hunger.burnratemodifiers:RemoveModifier(inst, "devourer_pack")
        end
    
        -- 保暖/隔热
        if (stats.kw and stats.kw > 0) or (stats.kc and stats.kc > 0) then
            shared.stop_monitor_temperature(inst)
        end

        -- 虚灵攻击
        if stats.gestaltattack then
            attackother = true
            if inst._onsanity then
                inst:RemoveEventCallback("sanitydelta", inst._onsanity, owner)
                inst._onsanity = nil
            end
        end
    
        -- 力场护盾
        if stats.forcefield and inst._pseudo_invincible ~= nil then
            inst._pseudo_invincible.ForceDeactivate()
            attacked = true
        end
        
        -- 骨头盔甲免伤
        if stats.resistance then
            if not inst.components.cooldown then
                inst:AddComponent("cooldown")
            end
            if not inst.components.resistance then
                inst:AddComponent("resistance")
            end
            inst.components.cooldown.onchargedfn = nil
            
            local resistanceSystem = SetupResistanceSystem(inst)
            if inst and inst.task ~= nil then
                inst.task:Cancel()
                inst.task = nil
                inst.components.resistance:SetOnResistDamageFn(resistanceSystem.OnResistDamage)
            end
            for i, v in ipairs(RESISTANCES) do
                inst.components.resistance:RemoveResistance(v)
            end
        end

        -- 增加视野距离
        if owner.isplayer then
            owner:RemoveCameraExtraDistance(inst, "devourer_pack")
        end

        -- 理智下降抗性
        if owner.components.sanity then
            owner.components.sanity.neg_aura_modifiers:RemoveModifier(inst)
        end
        
        -- 移除科技解锁，恢复原始科技加成值
        if TUNING.DEVOURER_TECH and owner.components.builder then
            local builder = owner.components.builder
            
            -- 恢复原始的科技加成值
            if self._original_tech_bonuses then
                for bonus_name, original_value in pairs(self._original_tech_bonuses) do
                    builder[bonus_name] = original_value
                end
                -- 清空原始加成记录
                self._original_tech_bonuses = nil
            end
            
            -- 触发科技树变化事件，更新制作栏
            owner:PushEvent("refreshcrafting")
        end

        -- 蜘蛛巢不减速
        if stats.creep and owner.components.locomotor then
            owner.components.locomotor:SetTriggersCreep(true)
        end

        -- 吸血
        if stats.bloodsucking and stats.bloodsucking > 0 then
            hitother = true
        end
        
        -- 血量上限
        if stats.hp and stats.hp > 0 and owner.components.health ~= nil and self.PLAYER[owner.GUID].add_hp then
            local old_add =  self.PLAYER[owner.GUID].add_hp
            local percent = owner.components.health:GetPercent()
            local max = owner.components.health.maxhealth
            local new_max = math.max(max - old_add, self.PLAYER[owner.GUID].base_hp or 1)
            owner.components.health:SetMaxHealth(new_max)
            owner.components.health:SetPercent(percent, false)-- 保持当前比例
            self.PLAYER[owner.GUID].add_hp = nil
            add_utils.debug_print(string.format("Health Remove - old: %d, oldmax: %d, newmax: %d, percent: %.2f", 
                old_add, max, owner.components.health.maxhealth, percent))
        end
        -- 精神上限
        if stats.sanity and stats.sanity > 0 and owner.components.sanity and self.PLAYER[owner.GUID].add_sanity then
            local old_add = self.PLAYER[owner.GUID].add_sanity
            local percent = owner.components.sanity:GetPercent()
            local max = owner.components.sanity.max
            local new_max = math.max(max - old_add, self.PLAYER[owner.GUID].base_sanity or 1)
            owner.components.sanity:SetMax(new_max)
            owner.components.sanity:SetPercent(percent, false)-- 保持当前比例
            self.PLAYER[owner.GUID].add_sanity = nil
            add_utils.debug_print(string.format("Sanity Remove - old: %d, oldmax: %d, newmax: %d, percent: %.2f", 
                old_add, max, owner.components.hunger.max, percent))
        end
        -- 饱食度上限
        if stats.hunger and stats.hunger > 0 and owner.components.hunger and self.PLAYER[owner.GUID].add_hunger then
            local old_add = self.PLAYER[owner.GUID].add_hunger
            local percent = owner.components.hunger:GetPercent()
            local max = owner.components.hunger.max
            local new_max = math.max(max - old_add, self.PLAYER[owner.GUID].base_hunger or 1)
            owner.components.hunger:SetMax(new_max)
            owner.components.hunger:SetPercent(percent, false)-- 保持当前比例
            self.PLAYER[owner.GUID].add_hunger = nil
            add_utils.debug_print(string.format("Hunger Remove - old: %d, oldmax: %d, newmax: %d, percent: %.2f", 
                old_add, max, owner.components.hunger.max, percent))
        end
        
        -- 火焰伤害减免
        if stats.firedreduction and stats.firedreduction > 0 and owner.components.health ~= nil and owner.components.health.externalfiredamagemultipliers then
            owner.components.health.externalfiredamagemultipliers:RemoveModifier(inst)
        end

        -- 昏睡抗性
        if stats.sleep_res and stats.sleep_res > 0 and owner.grogginess then
            owner.components.grogginess:RemoveResistanceSource("devourer_pack")
        end

        -- 冰冻抗性
        if stats.freeze_res and stats.freeze_res > 0 and owner.components.freezable and inst._original_freeze_res then
            owner.components.freezable:SetResistance(inst._original_freeze_res) 
            inst._original_freeze_res = nil
        end

        -- 踏水关闭
        if (stats.treadwater and stats.treadwater > 0) or (stats.voidwalk and stats.voidwalk > 0) then
            self:SetTreadWater(false)  -- 这会自动处理饥饿修正和碰撞恢复
        end
        
        -- 诅咒解析,移除诅咒物品监听器
        if stats.monkey_token and stats.monkey_token >= 5 and inst._token_destroy_listener then
            owner:RemoveEventCallback("itemget", inst._token_destroy_listener)
            inst._token_destroy_listener = nil
        end

        -- aoe反伤
        if stats.aoereflect and stats.aoereflect > 0 and inst._on_aoe_devour_reflect then
            attacked = true
        end

        -- 恢复原始饮食设置
        if self.PLAYER[owner.GUID] and self.PLAYER[owner.GUID].original_diet then
            if owner.components.eater then
                local original_diet = self.PLAYER[owner.GUID].original_diet
                if original_diet.caneat and original_diet.preferseating then
                    owner.components.eater:SetDiet(original_diet.caneat, original_diet.preferseating)
                end
            end
            self.PLAYER[owner.GUID].original_diet = nil
        end
        
        if owner.components.combat and 
        ((stats.damage and stats.damage > 0) or (stats.spdamage and stats.spdamage > 0) or (stats.predamage and stats.predamage > 0))  then
            -- attackother = true
            hitother = true
        end

        if stats.chopwork and stats.chopwork > 0 and owner.components.workmultiplier then
            owner.components.workmultiplier:RemoveMultiplier(ACTIONS.CHOP, inst)
        end
        if stats.minework and stats.minework > 0 and owner.components.workmultiplier then
            owner.components.workmultiplier:RemoveMultiplier(ACTIONS.MINE, inst)
        end
        if stats.hammerwork and stats.hammerwork > 0 and owner.components.workmultiplier then
            owner.components.workmultiplier:RemoveMultiplier(ACTIONS.HAMMER, inst)
        end

        if stats.mightiness and stats.mightiness > 0 and owner.components.mightiness then
            owner.components.mightiness.ratemodifiers:RemoveModifier(inst, "devourer_pack")
        end

        if stats.ingredientmod and stats.ingredientmod > 0 and owner.components.builder then
            owner.components.builder.ingredientmod = 1
        end
        -- 如履平地（蚁狮陷坑不减速）
        if stats.walksinkhole and owner.components.carefulwalker then
            local original_careful_speed = inst.original_careful_speed or TUNING.CAREFUL_SPEED_MOD or 0.3
            owner.components.carefulwalker:SetCarefulWalkingSpeedMultiplier(original_careful_speed)
            inst.original_careful_speed = nil
        end
        -- 移除逻辑：移除指定来源并重新计算最大值
        -- 踏雪无痕（冰面不打滑）
        if stats.walkice and owner.components.slipperyfeet and owner.slipperyfeet_sources then
            local sourceKey = "devourerpack"  -- 要移除的来源标识，需与添加时一致
            
            -- 处理decay_accel
            owner.slipperyfeet_sources.decay_accel[sourceKey] = nil  -- 移除当前来源
            -- 重新计算最大值
            local max_decay = owner.original_sf_decay_accel or TUNING.WILSON_RUN_SPEED * 2 or 12
            for _, v in pairs(owner.slipperyfeet_sources.decay_accel) do
                if v > max_decay then
                    max_decay = v
                end
            end
            owner.components.slipperyfeet.decay_accel = max_decay
            -- 如果没有任何来源了，清除原始值记录
            if next(owner.slipperyfeet_sources.decay_accel) == nil then
                owner.original_sf_decay_accel = nil
            end

            -- 处理threshold
            owner.slipperyfeet_sources.threshold[sourceKey] = nil  -- 移除当前来源
            -- 重新计算最大值
            local max_threshold = owner.original_sf_threshold or TUNING.WILSON_RUN_SPEED * 4 or 24
            for _, v in pairs(owner.slipperyfeet_sources.threshold) do
                if v > max_threshold then
                    max_threshold = v
                end
            end
            owner.components.slipperyfeet.threshold = max_threshold
            -- 如果没有任何来源了，清除原始值记录
            if next(owner.slipperyfeet_sources.threshold) == nil then
                owner.original_sf_threshold = nil
            end
        end

        -- 精神状态恢复
        if self.control_switch.SanityChange and self.control_switch.SanityChange ~= 1 then
            self:ChangeSanityStatus(1)
        end

        -- 进食恢复 
        if owner.components.eater and stats.food_add and stats.food_add > 0 then
            owner.components.eater.custom_stats_mod_fn = owner._original_eater_fn_devourer
            owner._original_eater_fn_devourer = nil
            owner._devourer_set_food_add = false
        end
        
        if self:CheckSuit("shadow") then
            hitother = true
        end

        if stats.health_absor and self._add_health_absor then
            local old_add = self._add_health_absor or 0
            local max = owner.components.health and owner.components.health.absorb or 0
            owner.components.health:SetAbsorptionAmount(max - old_add)
            self._add_health_absor = nil
        end

        -- 勋章兼容
        if stats.chaos_damage and stats.chaos_damage > 0 and stats.chaos_bonus and stats.chaos_bonus > 0 and self.mod.medal and owner.components.medal_chaosdamage then
            owner.components.medal_chaosdamage:SetCalcBonusDamageFn(nil, TUNING.DEVOURER_PACK_WEAPON_BONUS.KEY)
        end

        -- 移除窃血抵抗（和棱镜mod兼容）
        if stats.siv_blood_l_reducer and stats.siv_blood_l_reducer > 0 and self.mod.legion then
            local source_key = "devourer_pack" -- 必须和装备时的标识一致

            -- 1. 存在抵抗表才处理
            if owner.siv_blood_l_reducer ~= nil then
                -- 2. 移除当前装备的抵抗值
                owner.siv_blood_l_reducer[source_key] = nil

                -- 3. 重新计算叠加后的总抵抗值
                local total_resist = 0
                local has_other = false -- 标记是否还有其他来源的抵抗值
                for _, v in pairs(owner.siv_blood_l_reducer) do
                    total_resist = total_resist + v
                    has_other = true
                end

                -- 4. 更新总和字段（无其他抵抗时置空，和原mod逻辑一致）
                if has_other and total_resist > 0 then
                    owner.siv_blood_l_reducer_v = total_resist
                else
                    owner.siv_blood_l_reducer_v = nil
                    -- 无任何抵抗时清空表，避免冗余
                    owner.siv_blood_l_reducer = nil
                end

                add_utils.debug_print(string.format("[窃血抵抗] 装备移除：来源=%s，剩余叠加总和=%.2f", 
                    source_key, total_resist))
            end
        end
        
        -- 移除特殊标签
        local function RemovePlayerTag(tag, desc)
            if owner:HasTag(tag) and self.tags[tag] then
                owner:RemoveTag(tag)
            end
        end
        RemovePlayerTag("moonstormevent_detector")
        RemovePlayerTag("overlord")
        RemovePlayerTag("beefalo")
        RemovePlayerTag("spiderdisguise")
        RemovePlayerTag("rabbitdisguise")
        RemovePlayerTag("ghost_ally")
        RemovePlayerTag("master_crewman")
        RemovePlayerTag("boat_health_buffer")
        RemovePlayerTag("stronggrip")
        RemovePlayerTag("fastbuilder")
        RemovePlayerTag("houndfriend")
        RemovePlayerTag("shadowdominance")
        RemovePlayerTag("insect")
        RemovePlayerTag("mightiness_mighty")
        RemovePlayerTag("chessfriend")

        if inst._onattack then -- 安全移除之前的回调（如果存在）
            inst:RemoveEventCallback("onattackother", inst._onattack, owner)
            inst._onattack = nil
        end
    
        if inst._onhit then -- 每次加载的时候去掉之前的，因为这个可以重复，避免多个一起导致数据异常
            owner:RemoveEventCallback("onhitother", inst._onhit)
            inst._onhit = nil
        end

        if inst._on_attacked then
            inst:RemoveEventCallback("attacked", inst._on_attacked, owner)
            inst._on_attacked = nil
        end

        add_utils.debug_print("[UnEquipUpdate] checking listeners, _on_equip=" .. tostring(inst._on_equip ~= nil) .. ", _on_unequip=" .. tostring(inst._on_unequip ~= nil) .. ", inst=" .. tostring(inst))
        if inst._on_equip then
            add_utils.debug_print("[UnEquipUpdate] removing _on_equip listener")
            inst:RemoveEventCallback("equip", inst._on_equip, owner)
            inst._on_equip = nil
        end
        if inst._on_unequip then
            add_utils.debug_print("[UnEquipUpdate] removing _on_unequip listener")
            inst:RemoveEventCallback("unequip", inst._on_unequip, owner)
            inst._on_unequip = nil
        end
        -- 始终解绑武器加成和帽子恢复（不依赖监听器是否存在）
        UnbindWeaponBonus(owner, inst)
        UnbindOwnerBonus(owner, inst)

        -- 恢复被保护的帽子耐久度（使用缓存引用，不依赖 _on_equip）
        local hat_to_restore = owner._dev_protected_hat
        if not (hat_to_restore and hat_to_restore:IsValid()) then
            -- 缓存引用失效时，尝试从当前头部装备查找
            hat_to_restore = owner.components.inventory and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        end
        add_utils.debug_print("[UnEquipUpdate] hat_to_restore=" .. tostring(hat_to_restore)
            .. ", has_maxfuel=" .. tostring(hat_to_restore and hat_to_restore._dev_original_maxfuel ~= nil)
            .. ", has_totaluses=" .. tostring(hat_to_restore and hat_to_restore._dev_original_totaluses ~= nil)
            .. ", has_perish=" .. tostring(hat_to_restore and hat_to_restore._dev_original_perish_time ~= nil)
            .. ", has_armor=" .. tostring(hat_to_restore and hat_to_restore._dev_original_armor_max ~= nil))
        if hat_to_restore and (hat_to_restore._dev_original_maxfuel or hat_to_restore._dev_original_totaluses
            or hat_to_restore._dev_original_perish_time or hat_to_restore._dev_original_armor_max) then
            add_utils.debug_print("[UnEquipUpdate] restoring hat durability via cached reference")
            self:RestoreHatDurability(hat_to_restore)
        else
            add_utils.debug_print("[UnEquipUpdate] no hat with saved durability data found")
        end
        owner._dev_protected_hat = nil

        if inst._on_phase_changed then
            inst:RemoveEventCallback("phasechanged", inst._on_phase_changed, TheWorld)
            inst._on_phase_changed = nil
            if stats.bravery_buff and owner:HasDebuff("halloweenpotion_bravery_buff") then
                owner:RemoveDebuff("halloweenpotion_bravery_buff")
            end
            if stats.electricattack and owner:HasDebuff("buff_electricattack") then
                owner:RemoveDebuff("buff_electricattack")
            end
        end

        self:UpdateLeader()
        
        StopMainTask(inst)
    end
end

-- 检查某个效果是否应该被应用
function Devourer:CheckEffect(effectKey)
    -- 获取配置值（大写键名）
    local tuning_value
    if effectKey == "hp" or effectKey == "hunger" or effectKey == "sanity" then
        tuning_value = TUNING.DEVOURER_PACK_FOOD_MAX
    else  
        local tuning_key = string.upper(effectKey)
        tuning_value = TUNING.DEVOURER_PACK_EFFECT[tuning_key]
    end
    
    -- 记录调试信息
    add_utils.debug_print(string.format("[CheckEffect] 检查效果: %s (配置值: %s)", 
        effectKey, 
        tostring(tuning_value)
    ))
    
    -- 判断逻辑：
    -- 1. 如果配置不存在 → 正常处理（返回 true）
    -- 2. 如果配置存在且为 true → 正常处理（返回 true）
    -- 3. 如果配置存在且为非零数值 → 正常处理（返回 true）
    -- 4. 如果配置存在且为 false 或 0 → 跳过（返回 false）
    if tuning_value == nil then
        add_utils.debug_print(string.format("[CheckEffect] 效果 %s 未被配置，默认允许", effectKey))
        return true  -- 配置不存在，正常处理
    elseif tuning_value == true then
        add_utils.debug_print(string.format("[CheckEffect] 效果 %s 配置为 true，允许", effectKey))
        return true  -- 配置为 true，正常处理
    elseif type(tuning_value) == "number" and tuning_value ~= 0 then
        add_utils.debug_print(string.format("[CheckEffect] 效果 %s 配置为数值 %s，允许", effectKey, tostring(tuning_value)))
        return true  -- 配置为非零数值，正常处理
    else
        add_utils.debug_print(string.format("[CheckEffect] 效果 %s 配置为 %s，跳过", effectKey, tostring(tuning_value)))
        return false -- 其他情况（false 或 0），跳过
    end
end

function Devourer:ChangeSingleReflect(change)
    local inst = self.inst
    if not change then
        if inst.components.damagereflect then
            inst:RemoveComponent("damagereflect")
        end
        return
    end
    -- 添加反弹伤害组件
    if not inst.components.damagereflect then
        inst:AddComponent("damagereflect")
    end
    inst.components.damagereflect:SetDefaultDamage(0)  -- 默认为0
    -- 清理旧的反伤特效函数
    if inst._on_reflect_damage then
        inst:RemoveEventCallback("onreflectdamage", inst._on_reflect_damage)
        inst._on_reflect_damage = nil
    end
    -- 在inst或组件中添加冷却时间变量
    if not inst.last_special_reflect_time then
        inst.last_special_reflect_time = 0  -- 初始化冷却时间
    end
    if not inst.special_reflect_cooldown then
        inst.special_reflect_cooldown = 5  -- 5秒冷却
    end
    -- 设置反弹伤害函数
    local function ReflectDamageFn(inst, attacker, damage, weapon, stimuli, spdamage)
        -- 检查反射开关是否开启（1为单体反射，2为AOE反射）
        local devourer = inst.components.devourer
        add_utils.debug_print("[Devourer] CheckControlSwitch Reflect:", devourer and devourer:CheckControlSwitch("Reflect", 2) or "nil")
        if not (devourer and (devourer.control_switch.Reflect == 2 or devourer.control_switch.Reflect == 4)) then
            -- add_utils.debug_print("[Devourer] 反射未开启，返回0伤害")
            return 0, {planar = 0}  -- 反射未开启
        end
        -- add_utils.debug_print("[Devourer] 反射开启，计算伤害")
        -- 计算反弹伤害
        local stats = devourer.stats or {}
        local reflect_damage = stats.basereflect or 0
        local planar_reflect = stats.planarreflect or 0
        local special_reflect = stats.specialreflect or 0
        
        -- 如果有百分比反弹伤害，检查冷却时间，增加到物理反伤上
        if special_reflect > 0 then
            local current_time = GetTime()
            local last_time = inst.last_special_reflect_time or 0
            local cooldown = inst.special_reflect_cooldown or 5
            
            if current_time - last_time < cooldown then
                -- 冷却中，不应用特殊反弹
                special_reflect = 0
            else
                -- 应用特殊反弹并更新冷却时间
                local health = attacker and attacker.components.health and attacker.components.health.maxhealth or 0
                local spreflect = math.max(health * special_reflect, 1)
                reflect_damage = reflect_damage + spreflect
                inst.last_special_reflect_time = current_time
            end
        end
        -- 返回反弹伤害和位面反弹伤害
        return reflect_damage, {planar = planar_reflect}
    end
    
    inst._on_reflect_damage = function(inst, data)
        if data ~= nil and data.attacker ~= nil and data.attacker:IsValid() then
            SpawnPrefab("hitsparks_reflect_fx"):Setup(inst.components.inventoryitem.owner or inst, data.attacker)
        end
    end
    
    inst.components.damagereflect:SetReflectDamageFn(ReflectDamageFn)
    inst:ListenForEvent("onreflectdamage", inst._on_reflect_damage)
end

-- 更新数据
function Devourer:Upgrade()
    -- if not self.upgrade_effects or not devourer_pack_upgrade then
    if not self.upgrade_effects then
        add_utils.debug_print("[警告] 无升级效果数据或未启用升级功能")
        return 
    end
    local current_lv = self.packlv.level
    local allowed_effects = self._allowed_effects[current_lv] or{} 
    local inst = self.inst
    local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
    local stats = {
        defense = 0,               -- 基础防御力（百分比）
        planardefense = 0,         -- 位面防御（固定值）
        resistance = false,        -- 骨甲免伤
        waterproof = 0,            -- 防水
        speed = 0,                 -- 移动速度加成
        preserver = 0,             -- 减缓食物腐烂速度
        insulated = false,         -- 是否绝缘（防电击）
        dapperness = 0,            -- 精神值恢复
        stacksize = false,         -- 是否影响堆叠数量（弹性空间制造器）
        heavyarmor = false,        -- 免疫击退
        goggles = false,           -- 防风沙
        gestaltprotection = false, -- 免疫月灵攻击
        shadowdominance = false,   -- 影怪无仇恨
        acidrainimmune = false,    -- 是否免疫酸雨伤害
        bramble_resistant = false, -- 免疫荆棘伤害
        hunger_rate = 0,           -- 饥饿速率调整
        kw = 0,                    -- 保暖值（对抗寒冷环境）
        kc = 0,                    -- 隔热值（对抗炎热环境）
        light = 0,                 -- 光照范围（提供光源的强度）
        gestaltattack = false,     -- 月灵跟随攻击
        externaldamage = 0,        -- 额外伤害加成
        forcefield = false,        -- 力场护盾（铥矿头）
        junk = false,              -- 免疫垃圾堆伤害（拾荒疯猪丢的垃圾）
        health = 0,                -- 自动回复血量
        extraview = 0,             -- 增加视野距离
        saresistance = 0,          -- 理智下降抗性
        beefalo = false,           -- 发情牛不攻击
        moonstormevent_detector = false, -- 显示瓦格斯塔夫
        creep = false,          -- 蜘蛛巢不减速
        bloodsucking = 0,       -- 吸血
        rebirth = false,        -- 复活
        firedreduction = 0,     -- 火焰伤害减免
        sleep_res = 0,          -- 催眠抗性
        manrabbitscarer = false,-- 兔人恐惧
        spiderdisguise = false, -- 蜘蛛伪装
        electricattack = false, -- 电击攻击
        freeze_res = 0,         -- 冰冻抗性
        rabbitdisguise = false, -- 兔子伪装
        treadwater = 0,         -- 水面行走
        voidwalk = 0,           -- 虚空行走
        monkey_token = 0,       -- 诅咒解析
        add_slot_cols = 1,       -- 背包格子行数，默认1，也就是2*2，如果0的话就是2*1
        basereflect = 0,        -- 物理反弹伤害
        planarreflect = 0,      -- 位面反弹伤害
        specialreflect = 0,     -- 百分比当前生命值反弹伤害（最低1）
        aoereflect = 0,         -- aoe反伤
        damage = 0,             -- 额外固定伤害
        spdamage = 0,           -- 额外位面伤害
        predamage = 0,          -- 额外百分比生命值伤害（最低1）
        chopwork = 0,           -- 砍树工作效率
        minework = 0,           -- 挖矿工作效率
        hammerwork = 0,         -- 锤击工作效率
        souljar = false,        -- 灵魂罐
        mightiness = 0,         -- 力量流失减缓
        ghost_ally = false,     -- 幽灵朋友
        ingredientmod = 0,      -- 建造消耗减少
        walksinkhole = false,   -- 如履平地
        walkice = false,        -- 踏雪无痕
        lunar = 0,              -- 启迪加成（5则为强制启迪状态，可以用噩梦燃料开关）
        zerosanity = false,     -- 0精神状态
        food_add = 0,           -- 进食恢复
        shadowlevel = 0,        -- 暗影等级
        master_crewman = false, -- 海盗水手 
        boat_health_buffer = false, -- 海盗船长
        tend = false,           -- 自动照顾农作物
        hidesmeats = false,     -- 肉类隐藏
        fightpig = false,       -- 猪人守护
        bravery_buff = false,   -- 勇气Buff
        houndfriend = false,    -- 狗狗朋友
        devourer_bee = false,   -- 蜜蜂之友
        insect = false,
        fire_slot = false,      -- 加热格子
        snow_slot = false,      -- 制冷格子
        repair_slot = 0,        -- 修理格子
        luck = 0,               -- 幸运值
        health_absor = 0,       -- 伤害吸收（不同于背包的防御，这个是作用于玩家身上的）
        mightiness_mighty = 0,  -- 强壮（重物不减移速）
        -- vegetarian = false,        -- 素食主义者（可以吃素）
        -- carnivore = false,          -- 肉食主义者（可以吃肉）
        -- cookperson = false,           -- 大厨（不挑食）
        
        
        hp = 0,                 -- 血量
        sanity = 0,             -- 精神
        hunger = 0,             -- 饱食度

        -- 套装效果
        season = 0,             -- 四季套装，保温隔热翻倍
        shadow = 0,             -- 暗影套装，范围伤害
        lunarplant = 0,         -- 亮茄套装（暗影敌对）
        dreadstone = 0,         -- 绝望石套装（月亮敌对）
        ruins = 0,              -- 铥矿套装，恢复惩罚血量
        miasmaimmune = 0,       -- 虚空套装（瘴气免疫）
        overlord = 0,           -- 受击无僵直(上面五个套装)
        warbis = 0,             -- W.A.R.B.I.S套装
        terraria = 0,           -- 泰拉瑞亚联动套装
        season_fish = 0,        -- 四季鱼套装
        stronggrip = 0,         -- 武器套装（强握，武器不脱手）
        stronghead = 0,         -- 头盔套装（强头，头盔不掉落）
        snail = 0,              -- 蜗牛套装（减伤+5%）
        nightvision = 0,        -- 夜视
        fastbuilder = 0,        -- 护符套装（快速制作）
        repair_suit = 0,        -- 修理套装（修理效率+100%）
        princess_suit = 0,      -- 公主套装（幸运翻倍，移速+5%）
        knight_suit = 0,        -- 骑士套装(幸运翻倍，免伤+5%)
        princessandknight = 0,  -- 公主与骑士套装（幸运翻倍，移速+5%，免伤+5%）
        slot_lv = 0,            -- 这个是用来同步给客户端，更新特殊格子的




        -- 勋章兼容
        chaos_damage = 0,            -- 混沌伤害开关
        chaos_defense = 0,           -- 混沌防御开关
        chaos_bonus = 0,            -- 混沌伤害/防御倍率

        -- 棱镜兼容
        siv_blood_l_reducer = 0,     -- 窃血抵抗

        recipe1 = false,          -- 科学机器
        recipe1_boat = false,          -- 智囊团
        recipe1_magic = false,          -- 灵子分解器
        recipe2 = false,          -- 炼金引擎
        recipe2_magic = false,          -- 暗影操控器
        recipe1_moon = false,          -- 天体宝球
        recipe_ancient = false,          -- 远古伪科学站
        recipe_lunar = false,          -- 辉煌铁匠铺
        recipe_shadow = false,          -- 暗影术基座
        recipe2_moon = false,          -- 天体2级
    }
    add_utils.debug_print("[背包升级] 已初始化属性统计表")

    -- 遍历升级效果
    local enab_effects = 0
    for prefab, effect in pairs(self.upgrade_effects) do
        if effect.enab and (not effect.max or effect.cur > 0) then
            enab_effects = enab_effects + 1
            local current = effect.cur or 0
            add_utils.debug_print(string.format("[详细] 处理物品 %s (数量: %d)", prefab, current))
            if effect.except and self:CheckEnable(effect.except) then
                add_utils.debug_print(string.format("排除物品 %s 因为 %s 已启用，两者互斥", prefab, effect.except))
            else
                for attr, value in pairs(effect) do
                    if self:CheckEffect(attr) and not add_configs.excluded_attrs[attr] then
                        if current_lv == 3 or allowed_effects[attr] then
                            --- 处理普通属性
                            if stats[attr] ~= nil then
                                local old_value = stats[attr]
                                if type(value) == "boolean" then
                                    stats[attr] = stats[attr] or value
                                    add_utils.debug_print(string.format("[属性] %s: %s → %s (布尔或)", 
                                        attr, tostring(old_value), tostring(stats[attr])))
                                else
                                    local delta = current > 0 and (value or 0) * current or (value or 0)
                                    stats[attr] = stats[attr] + delta
                                    add_utils.debug_print(string.format("[属性] %s: %.2f + %.2f = %.2f", 
                                        attr, old_value, delta, stats[attr]))
                                end
                            end
                        elseif add_configs.suits[attr] then -- 这段代码是为了在等级没解锁也能显示套装的进度，不然套装不+1，对应的stats的属性为0，GetEff方法就是0/4这样
                            local delta = current > 0 and (value or 0) * current or (value or 0)
                            stats[attr] = stats[attr] + delta
                        end
                    end
                end
            end
        end
    end
    add_utils.debug_print(string.format("[背包升级] 已处理 %d 个生效的升级效果", enab_effects))

    -- 应用防御属性
    if stats.defense and stats.defense > 0 then
        local defense = math.min(stats.defense, TUNING.DEVOURER_PACK_EFFECT.DEFENSE)
        if not inst.components.armor then
            inst:AddComponent("armor")
            add_utils.debug_print("[组件] 添加护甲组件")
        end
        inst.components.armor:InitIndestructible(defense)
        add_utils.debug_print(string.format("[防御] 设置伤害减免: %.0f%%", defense * 100))
    end

    -- 界限突破，每2点超出的防御，都会增加1%其他效果
    local extra_defense = stats.defense - 1
    if extra_defense > 0 then
        local boost_multiplier = 1 + (math.floor(extra_defense * 100 / 2) * 0.01) -- 每2点增加1%
        add_utils.debug_print(string.format("[界限突破] 额外防御: %.2f, 属性加成系数: %.2f", extra_defense, boost_multiplier))
        -- 遍历所有数值型属性进行加成
        for attr, value in pairs(stats) do
            if type(value) == "number" and value > 0 and not add_configs.excluded_extra_defense[attr] then
                -- 计算加成后的值并限制到小数点后两位
                local boosted_value = math.floor((value * boost_multiplier) * 100 + 0.5) / 100
                stats[attr] = boosted_value
                add_utils.debug_print(string.format("[属性加成] %s: %.4f → %.4f", attr, value, boosted_value))
            end
        end
    end
    -- 单独处理三维属性（取整，因为有些显示mod，不取整的话，会导致显示多出1点，即使卸下背包数据正常也多出1点）
    if stats.hp and stats.hp > 0 then
        stats.hp = math.floor(stats.hp)
    end
    if stats.sanity and stats.sanity > 0 then
        stats.sanity = math.floor(stats.sanity)
    end
    if stats.hunger and stats.hunger > 0 then
        stats.hunger = math.floor(stats.hunger)
    end
    -- 套装效果不吃界限突破的加成
    if self:CheckSuit("warbis", stats) then
        stats.speed = stats.speed + 0.05
        stats.externaldamage = stats.externaldamage + 0.05
        add_utils.debug_print("[Warbis套装] 移速+5% 攻击倍率+5%")
    end
    if self:CheckSuit("season_fish", stats) then
        stats.preserver = stats.preserver + 0.4 -- 四季鱼套装+40%
        add_utils.debug_print("[四季鱼套装] 腐败率-40%")
    end
    if self:CheckSuit("terraria", stats) then
        stats.hunger_rate = stats.hunger_rate + 0.2
    end
    if self:CheckSuit("repair_suit", stats) then
        stats.repair_slot = stats.repair_slot * 2
    end
    -- if self:CheckSuit("princess_suit", stats) then
    --     stats.luck = stats.luck * 2
    --     stats.speed = stats.speed + 0.05
    -- end
    if self:CheckSuit("knight_suit", stats) then
        stats.luck = stats.luck * 2
    end
    if self:CheckSuit("princessandknight", stats) then
        stats.luck = stats.luck * 2
        stats.speed = stats.speed + 0.05
        stats.health_absor = stats.health_absor + 0.05
    end
    if self:CheckSuit("snail") then 
        stats.health_absor = stats.health_absor + 0.05
    end
    if self:CheckSuit("stronghead") then 
        stats.health_absor = stats.health_absor + 0.05
    end

    -- 应用位面防御，因为饥荒联机版本身有bug，如果同时存在三个位面防御装备，被位面伤害打会导致无限循环卡死的bug
    -- 所以背包不能直接加，直接给背包携带者增加，弄成携带buff
    -- if stats.planardefense and stats.planardefense > 0 then
    --     if not inst.components.planardefense then
    --         inst:AddComponent("planardefense")
    --         add_utils.debug_print("[组件] 添加位面防御组件")
    --     end
    --     inst.components.planardefense:SetBaseDefense(stats.planardefense)
    --     add_utils.debug_print(string.format("[位面防御] 设置防御值: %.1f", stats.planardefense))
    -- end

    -- 应用防水（受防雨控制开关控制）
    if stats.waterproof and stats.waterproof > 0 then
        if not inst.components.waterproofer then
            inst:AddComponent("waterproofer")
            add_utils.debug_print("[组件] 添加防水组件")
        end
        local rain_enabled = self.control_switch and self.control_switch.RainProtect == 2
        inst.components.waterproofer:SetEffectiveness(rain_enabled and stats.waterproof or 0)
        add_utils.debug_print(string.format("[防水] 设置效果: %.0f%% (开关: %s)", rain_enabled and stats.waterproof * 100 or 0, rain_enabled and "开" or "关"))
    end

    -- 应用移速
    if stats.speed and stats.speed > 0 then
        if not inst.components.equippable then
            inst:AddComponent("equippable")
            add_utils.debug_print("[Devourer] 可装备组件被其他Mod移除，重新添加避免报错")
        end
        local maxSpeed = TUNING.DEVOURER_PACK_EFFECT.SPEED > 0 and TUNING.DEVOURER_PACK_EFFECT.SPEED or 9999
        local speed = 1 + math.min(stats.speed, maxSpeed)
        inst.components.equippable.walkspeedmult = speed
        add_utils.debug_print(string.format("[移速] 设置加成: %.0f%%", (speed - 1) * 100))
    end

    -- 应用保鲜
    if stats.preserver and stats.preserver > 0 then
        if not inst.components.preserver then
            inst:AddComponent("preserver")
            add_utils.debug_print("[组件] 添加保鲜组件")
        end
        local rate = 1 - stats.preserver -- 转换为腐败率
        inst.components.preserver:SetPerishRateMultiplier(rate)
        add_utils.debug_print(string.format("[保鲜] 设置腐败率: %.0f%%", rate * 100))
    end

    -- 应用防雷
    if stats.insulated then
        if not inst.components.equippable then
            inst:AddComponent("equippable")
            add_utils.debug_print("[Devourer] 可装备组件被其他Mod移除，重新添加避免报错")
        end
        inst.components.equippable.insulated = true
        add_utils.debug_print("已启用防雷效果")
    end

    -- 应用精神恢复
    if stats.dapperness and stats.dapperness > 0 then
        if not inst.components.equippable then
            inst:AddComponent("equippable")
            add_utils.debug_print("[Devourer] 可装备组件被其他Mod移除，重新添加避免报错")
        end
        local rate = stats.dapperness / 0.9 / 60
        inst.components.equippable.dapperness = rate
        add_utils.debug_print(string.format("[精神] 每分钟恢复: %.1f", stats.dapperness))
    end

    -- ================================================
    -- 无限堆叠功能（弹性空间制作器）
    -- ================================================
    -- 问题1：EnableInfiniteStackSize 只设置 maxsize = math.huge，但 originalmaxsize 仍为20
    --        IsOverStacked() 检查的是 originalmaxsize，导致超出的灵魂会被强制缩减
    -- 问题2：灵魂的 originalmaxsize 是只读属性，不能直接赋值
    -- 解决方案：使用 rawget 获取 Stackable 内部表，直接修改 _[.originalmaxsize[1]]
    if stats.stacksize then
        inst.components.container:EnableInfiniteStackSize(true)
        local container_ = rawget(inst.components.container, "_")
        if container_ then
            for i = 1, inst.components.container.numslots do
                local item = inst.components.container.slots[i]
                if item and item.components.stackable and item.components.inventoryitem and 
                   item.components.inventoryitem.canonlygoinpocketorpocketcontainers then
                    local stackable = item.components.stackable
                    local stackable_ = rawget(stackable, "_")
                    if stackable_ then
                        local current_max = stackable_.maxsize[1]
                        if current_max and current_max < math.huge then
                            -- 使用 rawget 直接修改内部存储的 originalmaxsize
                            stackable_.originalmaxsize[1] = math.huge
                        end
                    end
                end
            end
        end
        add_utils.debug_print("[功能] 已启用无限堆叠")
    else
        inst.components.container:EnableInfiniteStackSize(false)
    end

    -- 作祟复活
    if stats.rebirth then
        if not inst.components.hauntable then
            inst:AddComponent("hauntable")
        end
        inst.components.hauntable.onhaunt = function(inst, doer)
            if TheWorld.ismastersim then
                self:Rebirth(doer) -- 触发复活
            end
        end
    elseif inst.components.hauntable then
        inst:RemoveComponent("hauntable")
    end

    if (stats.basereflect and stats.basereflect > 0) or (stats.planarreflect and stats.planarreflect > 0) or (stats.specialreflect and stats.specialreflect > 0) then
        self:ChangeSingleReflect(self.control_switch.Reflect == 2 or self.control_switch.Reflect == 4)
    end

    if stats.shadowlevel and stats.shadowlevel > 0 then 
        if not inst.components.shadowlevel then
            inst:AddComponent("shadowlevel")
        end
        inst.components.shadowlevel:SetDefaultLevel(stats.shadowlevel)
    end
    if stats.luck and stats.luck > 0 then
        add_utils.debug_print(string.format("[幸运] 幸运值: %d", stats.luck))
        if not inst.components.luckitem then
            inst:AddComponent("luckitem")
        end
        inst.components.luckitem:SetLuck(GetLuckFn) -- 如果没被装备
        inst.components.luckitem:SetEquippedLuck(GetLuckFn) -- 如果被装备了
    end

    -- 添加特殊标签
    local function AddTagWithLog(tag, desc)
        if stats[tag] and not inst:HasTag(tag) then
            inst:AddTag(tag)
            add_utils.debug_print(string.format("[标签] 已添加: %s (%s)", tag, desc))
        end
    end
    AddTagWithLog("goggles", "防沙尘暴/星象风暴")
    AddTagWithLog("shadowdominance", "影怪无仇恨")
    AddTagWithLog("gestaltprotection", "免疫月灵攻击")
    AddTagWithLog("heavyarmor", "免疫击飞")
    AddTagWithLog("acidrainimmune", "免疫酸雨")
    AddTagWithLog("bramble_resistant", "免疫荆棘伤害")
    AddTagWithLog("junk", "免疫垃圾堆伤害")
    AddTagWithLog("manrabbitscarer", "兔人恐惧")
    AddTagWithLog("rabbitdisguise", "兔子伪装")
    AddTagWithLog("hidesmeats", "肉类隐藏")
    if self:CheckSuit("miasmaimmune", stats) then
        AddTagWithLog("miasmaimmune", "黑暗瘴气免疫")
    end
    -- if self:CheckSuit("overlord") then
    --     AddTagWithLog("overlord", "霸者神威")
    -- end
    AddTagWithLog("devourer_bee", "蜜蜂之友")
    -- AddTagWithLog("devourer_pig_friend", "猪人之友")
    
    -- 食物限制解除标签
    if stats.vegetarian then
        AddTagWithLog("devourer_vegetarian", "素食解除")
    end
    if stats.carnivore then
        AddTagWithLog("devourer_carnivore", "肉食解除")
    end
    if stats.cookperson then
        AddTagWithLog("devourer_cookperson", "不挑食解除")
    end

    -- 勋章兼容
    if stats.chaos_defense and stats.chaos_defense > 0 and stats.chaos_bonus and stats.chaos_bonus > 0 then
        if self.mod.medal then
            add_utils.debug_print("[Devourer] medal_chaosdefense组件已注册，可以用！")
            
            if not inst.components.medal_chaosdefense then
                inst:AddComponent("medal_chaosdefense")
            end
            if inst.components.medal_chaosdefense.SetBaseDefense then
                local chaos_defense = Get_Reduce(stats.chaos_defense) * stats.chaos_bonus * 2.5
                inst.components.medal_chaosdefense:SetBaseDefense(chaos_defense)
            end
        else
            add_utils.debug_print("[Devourer] medal_chaosdefense未注册！")
        end
    end

    self.stats = stats
    -- add_utils.debug_print("[背包升级] 属性统计表已保存")

    add_utils.debug_print("[Debug] stats preserver:", stats and stats.preserver or "nil")
    -- 刷新装备状态
    if inst.components.equippable and inst.components.equippable:IsEquipped() then
        if owner and inst.is_loaded then
            -- add_utils.debug_print("[装备] 正在刷新装备者状态")
            self:EquipUpdate(inst, owner)
        else
            -- add_utils.debug_print("[信息] 当前没有装备者，无法刷新装备属性")
        end
    else
        -- add_utils.debug_print("[信息] 背包未装备，跳过属性刷新")
    end

    self.packlv.extra_rows = self.stats.add_slot_cols or 1
    self.packlv.fire = self.stats.fire_slot and 1 or 0
    self.packlv.ice = self.stats.snow_slot and 1 or 0
    self.packlv.repair = self.stats.repair_slot or 0
    -- -- 背包等级提升会增加列数和行数，除此之外的格子增加只能通过吞噬物品的额外列数self.stats.add_slot_cols这个参数提升
    -- if self.stats.add_slot_cols > self.packlv.extra_rows then
    --     -- self.packlv.extra_rows = self.stats.add_slot_cols
    --     return self.stats.add_slot_cols
    -- end

    -- add_utils.debug_print("[背包升级] 升级处理完成")
end

local function InsertLevelEffectDesc(effectKey, effects, new_desc, current_lv, allowed_effects)
    if current_lv == 3 or allowed_effects[effectKey] then
        table.insert(effects, new_desc)
    else
        if add_configs.level_up.lv2.effect[effectKey] then
            table.insert(effects, new_desc..STRINGS.DP_DevourerPack.LEVEL_UP_MSG.UP_LV2_UNLOCK)
        else
            table.insert(effects, new_desc..STRINGS.DP_DevourerPack.LEVEL_UP_MSG.UP_LV3_UNLOCK)
        end
    end
end
function Devourer:GetEffectDescription(prefab, to_consume)
    if not self or not self.upgrade_effects or not self.upgrade_effects[prefab] then
        return STRINGS.DP_DevourerPack.WAIT_UNLOCK or "等待解锁"
    end
    local effect = self.upgrade_effects[prefab]
    local current_lv = self.packlv.level
    local allowed_effects = self._allowed_effects[current_lv] or {}  -- 防御性处理

    local effects = {}

    -- 数值效果处理（添加调试日志）
    for k, v in pairs(effect) do
        if self:CheckEffect(k) and not add_configs.excluded_attrs[k] then
            local formatStr = STRINGS.DP_DevourerPack.EFFECTS[k]
            if formatStr then
                -- 数值处理
                if type(v) == "number" then
                    local displayValue = add_configs.percent_effects[k] and v * 100 or v
                    if to_consume and to_consume > 1 then
                        displayValue = displayValue * to_consume
                    end
                    if k == "aoereflect" then
                        displayValue = self._cooldown_timers.aoereflect - (self.stats.aoereflect or 0)
                    end
                    if add_configs.suits[k] and add_configs.suits[k] > 0 then
                        local suit_max = add_configs.suits[k]
                        local suit_cur = self.stats[k] or 1
                        if suit_max > suit_cur then
                            local step_des = formatStr..tostring(suit_cur).."/"..tostring(suit_max)
                            InsertLevelEffectDesc(k, effects, step_des, current_lv, allowed_effects)
                        else
                            InsertLevelEffectDesc(k, effects, formatStr, current_lv, allowed_effects)
                        end
                    else
                        -- table.insert(effects, formatStr:format(displayValue))
                        InsertLevelEffectDesc(k, effects, formatStr:format(displayValue), current_lv, allowed_effects)
                    end
                elseif v == true then
                    -- table.insert(effects, formatStr)
                    InsertLevelEffectDesc(k, effects, formatStr, current_lv, allowed_effects)
                end
            end
        end
    end

    return #effects > 0 and table.concat(effects, "，") or STRINGS.DP_DevourerPack.WAIT_UNLOCK
end

-- 创建缓存表
local cached_roles = {}
local cached_mods = {}
-- 预定义文本格式化函数（不依赖局部变量）
local function formatItemText(base_name, extra_info, remaining)
    if extra_info and extra_info ~= "" then
        extra_info = "(" .. extra_info .. ")"
    else
        extra_info = ""
    end
    return base_name .. extra_info .. (remaining or "")
end

function Devourer:ShowUnDevouredItems()
    local cooldown_type = "gold"
    local can_use, now = CheckCooldown(self, cooldown_type)
    if not can_use then
        self.inst.components.talker:Say(STRINGS.DP_DevourerPack.COOLDOWN[cooldown_type])
        return 
    end
    self._cooldown_timers[cooldown_type].last_time = now

    local STRINGS_UI = STRINGS.DP_DevourerPack.UI
    local current_lv = self.packlv.level
    local msg_lines = {}

    -- 1. 获取当前等级所需材料
    local lv_key = "lv"..current_lv
    local required_items = add_configs.level_up[lv_key] and add_configs.level_up[lv_key].item or {}

    local owner = self.inst.components.inventoryitem:GetGrandOwner()
    local owner_role = owner and owner.prefab
    
    -- 2. 优先收集当前等级进化材料
    local priority_items = {}
    for prefab in pairs(required_items) do
        local effect = self.upgrade_effects[prefab]
        if effect and (not effect.enab or (effect.max and (effect.cur or 0) < effect.max)) then
            local item_name = STRINGS.NAMES[string.upper(prefab)] or prefab
            local remaining = effect.max and STRINGS_UI.MORE_TIMES:format(effect.max - (effect.cur or 0)) or ""
            table.insert(priority_items, item_name .. remaining)
            if #priority_items >= 10 then break end
        end
    end

    -- 3. 随机收集其他物品
    local raw_other_items = {}
    if #priority_items < 10 then
        local candidate_keys = {}
        -- 收集候选key
        for prefab, effect in pairs(self.upgrade_effects or {}) do
            -- 排除食物（检查是否有 hp/sanity/hunger 属性）
            local is_food = (effect.hp or effect.sanity or effect.hunger) and true or false
            local is_except = effect.except and self:CheckEffect(effect.except) or false
            -- 排除模组、角色专属、食物
            if not required_items[prefab] -- 排除进化材料
            and not add_configs.NotShowUnItems[prefab] -- 排除不显示的物品
            and not effect.mod -- 排除Mod物品
            and not is_food  -- 排除食物
            and (not effect.event or self.event[effect.event]) -- 已开启活动的物品，或者非活动物品
            and (not effect.role or not owner or effect.role == owner_role)
            and not is_except -- 部分物品是互斥的，只能吞噬一个，另一个不能吞噬，譬如珍珠的珍珠 和 开裂的珍珠
                then
                if not effect.enab or (effect.max and (effect.cur or 0) < effect.max) then
                    table.insert(candidate_keys, prefab)
                end
            end
        end
        -- 随机选择
        for i = #candidate_keys, math.max(1, #candidate_keys - (10 - #priority_items) + 1), -1 do
            local rand_idx = math.random(i)
            local prefab = candidate_keys[rand_idx]
            local effect = self.upgrade_effects[prefab]
            local item_name = STRINGS.NAMES[string.upper(prefab)] or prefab
            local remaining = effect.max and STRINGS_UI.MORE_TIMES:format(effect.max - (effect.cur or 0)) or ""
            local event = effect.event and "(" .. STRINGS.DP_DevourerPack.EVENT[effect.event] .. ")" or ""
            table.insert(raw_other_items, item_name .. event .. remaining)
            candidate_keys[rand_idx] = candidate_keys[i]
        end
    end

    -- 4. 合并显示列表
    local display_items = {}
    for _, item in ipairs(priority_items) do table.insert(display_items, item) end
    for _, item in ipairs(raw_other_items) do table.insert(display_items, item) end

    -- 5. 构建消息
    if #display_items == 0 then
        table.insert(msg_lines, STRINGS_UI.FULLY_UPGRADED)
    else
        if #priority_items > 0 then
            -- local next_desc
            -- if current_lv < 3 and STRINGS.NAMES.DEVOURER_PACK_NAMES[(current_lv+1)] then
            --     next_desc = " -> "..STRINGS.NAMES.DEVOURER_PACK_NAMES[(current_lv+1)]
            -- end
            table.insert(msg_lines, STRINGS_UI.UPGRADE_MATERIALS)
            table.insert(msg_lines, table.concat(priority_items, "，"))
        end
        if #display_items > #priority_items then
            table.insert(msg_lines, #priority_items > 0 and STRINGS_UI.OTHER_MATERIALS or STRINGS_UI.OTHER_MATERIALS)
            table.insert(msg_lines, table.concat({unpack(display_items, #priority_items + 1)}, "，"))
        end
    end

    -- 6. 补充推荐物品（优先模组→角色→食物）
    if #display_items < 10 then
        local recommended_items = {}
        local needed = math.min(5, 10 - #display_items)
        
        -- 分类收集候选
        local mod_candidates = {}   -- 模组物品
        local role_candidates = {}  -- 角色物品
        local food_candidates = {}  -- 食物物品
        for prefab, effect in pairs(self.upgrade_effects or {}) do
            -- 模组物品
            if not effect.enab or (effect.max and (effect.cur or 0) < effect.max) then
                if effect.mod and add_configs.mod_check[effect.mod] then
                    if not cached_mods[effect.mod] then
                        cached_mods[effect.mod] = self.mod[effect.mod]
                    end
                    if cached_mods[effect.mod] then
                        table.insert(mod_candidates, {
                            prefab = prefab,
                            mod_name = STRINGS.DP_DevourerPack.MOD[effect.mod] or effect.mod
                        })
                    end
                -- 其他角色物品
                elseif effect.role and owner_role and effect.role ~= owner_role then
                    table.insert(role_candidates, {
                        prefab = prefab,
                        role_name = cached_roles[effect.role] or (STRINGS.NAMES[string.upper(effect.role)] or effect.role)
                    })
                    cached_roles[effect.role] = role_candidates[#role_candidates].role_name
                -- 食物类物品，需要判断是否活动，活动未开启则不显示
                elseif (effect.hp or effect.sanity or effect.hunger) and (not effect.event or self.event[effect.event]) then
                    table.insert(food_candidates, {
                        prefab = prefab
                    })
                end
            end
        end

        -- (1) 优先模组物品
        local selected = 0
        for i = #mod_candidates, math.max(1, #mod_candidates - needed + 1), -1 do
            local rand_idx = math.random(i)
            local candidate = mod_candidates[rand_idx]
            local effect = self.upgrade_effects[candidate.prefab]
            local remaining = effect.max and STRINGS_UI.MORE_TIMES:format(effect.max - (effect.cur or 0)) or ""
            table.insert(recommended_items, formatItemText(
                STRINGS.NAMES[string.upper(candidate.prefab)] or candidate.prefab,
                candidate.mod_name, -- 模组名称
                remaining
            ))
            mod_candidates[rand_idx] = mod_candidates[i]
            selected = selected + 1
            if selected >= needed then break end
        end

        -- (2) 补充食物
        if selected < needed then
            for i = #food_candidates, math.max(1, #food_candidates - (needed - selected) + 1), -1 do
                local rand_idx = math.random(i)
                local candidate = food_candidates[rand_idx]
                local effect = self.upgrade_effects[candidate.prefab]
                local remaining = effect.max and STRINGS_UI.MORE_TIMES:format(effect.max - (effect.cur or 0)) or ""
                local event = effect.event and STRINGS.DP_DevourerPack.EVENT[effect.event] or ""
                table.insert(recommended_items, formatItemText(
                    STRINGS.NAMES[string.upper(candidate.prefab)] or candidate.prefab,
                    event, -- 部分食物可能是活动食物
                    remaining
                ))
                food_candidates[rand_idx] = food_candidates[i]
                selected = selected + 1
                if selected >= needed then break end
            end
        end

        -- (3) 补充其他角色
        if selected < needed then
            for i = #role_candidates, math.max(1, #role_candidates - (needed - selected) + 1), -1 do
                local rand_idx = math.random(i)
                local candidate = role_candidates[rand_idx]
                local effect = self.upgrade_effects[candidate.prefab]
                local remaining = effect.max and STRINGS_UI.MORE_TIMES:format(effect.max - (effect.cur or 0)) or ""
                table.insert(recommended_items, formatItemText(
                    STRINGS.NAMES[string.upper(candidate.prefab)] or candidate.prefab,
                    candidate.role_name,    -- 角色名称
                    remaining
                ))
                role_candidates[rand_idx] = role_candidates[i]
                selected = selected + 1
                if selected >= needed then break end
            end
        end

        if #recommended_items > 0 then
            table.insert(msg_lines, STRINGS_UI.OTHER_ITEMS)
            table.insert(msg_lines, table.concat(recommended_items, "，"))
        end
    end

    -- 7. 发送公告
    TheNet:Announce(table.concat(msg_lines, "\n"))
end

function Devourer:_SyncUpgradeEffects(key, enab, cur)
    -- 单个key同步（无需分片）
    if key then
        if enab == nil then
            enab = true
        end
        local sync_data = {
            [key] = {
                e = enab,
                c = cur
            }
        }
        add_utils.debug_print("Devourer _SyncUpgradeEffects key:",key,",enab:",enab,",cur:",cur)
        self.inst.replica.devourer:_SyncUpgradeEffects(sync_data)
        return
    end
    -- 全量同步
    local batch = {}
    for prefab, effect in pairs(self.upgrade_effects) do
        if effect.enab then
            -- 使用简写名称进行全量同步，避免过长的key导致超过网络消息长度限制
            local short_name = add_configs.upgrade_effects_short_names[prefab]
            if short_name then
                batch[short_name] = {
                    e = true,
                    c = effect.cur
                }
            else
                -- 万一没有简写名称，使用原始名称作为 fallback
                batch[prefab] = {
                    e = true,
                    c = effect.cur
                }
            end
        end
    end
    self.inst.replica.devourer:_SyncUpgradeEffects(batch)
end

function Devourer:_SyncModsndEventsShow()
    -- 全量同步
    local batch = {}
    for prefab, effect in pairs(self.upgrade_effects) do
        if effect.mod or effect.event then
            batch[prefab] = {
                s = effect.show
            }
        end
    end
    self.inst.replica.devourer:_SyncUpgradeShows(batch)
end

function Devourer:SetTreadWater(enable)
    local owner = self and self.inst.components.inventoryitem:GetGrandOwner()
    if not owner or not owner.Physics then
        return
    end
    -- ===== 物理系统设置（通用逻辑） =====
    owner.Physics:ClearCollisionMask()
    owner.Physics:CollidesWith(enable and COLLISION.GROUND or COLLISION.WORLD)
    for _, mask in ipairs({COLLISION.OBSTACLES, COLLISION.SMALLOBSTACLES, COLLISION.CHARACTERS, COLLISION.GIANTS}) do
        owner.Physics:CollidesWith(mask)
    end
    owner.Physics:Teleport(owner.Transform:GetWorldPosition())

    -- 溺水组件控制
    if owner.components.drownable then
        owner.components.drownable.enabled = not enable
    end
    -- 没有饥饿组件则不处理
    if not owner.components.hunger then
        return
    end
    -- ===== 饥饿系统（分洞穴/非洞穴） =====
    if enable then
        -- -- 先移除，避免出问题
        -- owner.components.hunger.burnratemodifiers:RemoveModifier(
        --     self.inst,
        --     "devourer_pack_treadwater"
        -- )
        local is_cave = TheWorld:HasTag("cave")
        local hunger_rate = is_cave and voidwalk_hungerrate or treadwater_hungerrate
        local reduce_hunger = is_cave and self.stats.voidwalk or self.stats.treadwater
        local cost_multiplier = math.max(hunger_rate - reduce_hunger, 1)

        -- 调试输出
        add_utils.debug_print(string.format("[Devourer] %s踏水状态 - 类型: %s 饥饿倍率: %.2f",
            owner.name,
            is_cave and "洞穴" or "地表",
            cost_multiplier))
        -- 设置饥饿消耗倍率
        owner.components.hunger.burnratemodifiers:SetModifier(
            self.inst,
            cost_multiplier,
            "devourer_pack_treadwater" 
        )
        
        self.control_switch.TreadWater = 2
    else
        owner.components.hunger.burnratemodifiers:RemoveModifier(
            self.inst,
            "devourer_pack_treadwater"
        )
        self.control_switch.TreadWater = 1
    end
end

-- 应用防水开关（运行时切换）
function Devourer:ApplyWaterproof(enable)
    local inst = self.inst
    if not inst.components.waterproofer then return end
    local effectiveness = enable and (self.stats.waterproof or 0) or 0
    inst.components.waterproofer:SetEffectiveness(effectiveness)
end

-- 月岩检查已生效属性
function Devourer:_HandleMoonrockCheck()
    local cooldown_type = "moonrock"
    local can_use, now = CheckCooldown(self, cooldown_type)
    if not can_use then
        self.inst.components.talker:Say(STRINGS.DP_DevourerPack.COOLDOWN[cooldown_type])
        return
    end
    self._cooldown_timers[cooldown_type].last_time = now

    local numeric_totals = {}
    local boolean_effects = {}

    -- 统一处理效果累加
    for prefab_name, effect_data in pairs(self.upgrade_effects) do
        if effect_data.enab and (not effect_data.max or effect_data.cur > 0) then
            if effect_data.except and self:CheckEnable(effect_data.except) then
                -- 排除效果，不计算
                add_utils.debug_print(string.format("[月岩检查] 排除物品 %s 因为 %s 已启用，两者互斥", prefab_name, effect_data.except))
            else
                for stat, value in pairs(effect_data) do
                    if self:CheckEffect(stat) and not add_configs.excluded_attrs[stat] then
                        if type(value) == "number" then
                            numeric_totals[stat] = (numeric_totals[stat] or 0) + (value * (effect_data.cur or 1))
                        elseif type(value) == "boolean" and value then
                            local effect_str = STRINGS.DP_DevourerPack.EFFECTS[stat]
                            if effect_str and not boolean_effects[stat] then
                                boolean_effects[stat] = effect_str
                            end
                        end
                    end
                end
            end
        end
    end

    local current_lv = self.packlv.level
    -- 生成显示文本
    local msg = BuildEffectMessage(self, numeric_totals, boolean_effects ,current_lv)
    -- self.inst.components.talker:Say(msg)
    TheNet:Announce(msg)
end

-- 处理踏水功能
function Devourer:_HandleTreadWater(value)
    local owner = self and self.inst.components.inventoryitem:GetGrandOwner()
    if not owner then return end
    local is_cave = TheWorld:HasTag("cave")
    if is_cave and (not self.stats.voidwalk or self.stats.voidwalk <= 0) then
        -- self.inst.components.talker:Say(STRINGS.DP_DevourerPack.NOT_TREADWATER_CAVE)
        return STRINGS.DP_DevourerPack.NOT_TREADWATER_CAVE
    elseif not is_cave and (not self.stats.treadwater or self.stats.treadwater <= 0) then
        -- self.inst.components.talker:Say(STRINGS.DP_DevourerPack.NOT_TREADWATER)
        return STRINGS.DP_DevourerPack.NOT_TREADWATER
    end
    -- -- 切换踏水状态
    -- local new_state = self.control_switch.TreadWater == 1 and 2 or 1
    -- self.control_switch.TreadWater = new_state
    
    -- 设置实际效果
    self:SetTreadWater(value == 2)
    return nil
    
    -- -- 不同状态提示
    -- if value == 2 then
    --     local hunger_rate = is_cave and voidwalk_hungerrate or treadwater_hungerrate
    --     local reduce_hunger = is_cave and self.stats.voidwalk or self.stats.treadwater
    --     local cost_multiplier = math.max(hunger_rate - reduce_hunger, 1)
    --     if is_cave then
    --         self.inst.components.talker:Say(STRINGS.DP_DevourerPack.TREADWATER_ON_CAVE:format((cost_multiplier - 1) * 100))
    --     else
    --         self.inst.components.talker:Say(STRINGS.DP_DevourerPack.TREADWATER_ON:format((cost_multiplier - 1) * 100))
    --     end
    -- else
    --     if is_cave then
    --         self.inst.components.talker:Say(STRINGS.DP_DevourerPack.TREADWATER_OFF_CAVE)
    --     else
    --         self.inst.components.talker:Say(STRINGS.DP_DevourerPack.TREADWATER_OFF)
    --     end
    -- end
end

function Devourer:GetLv()
	return self.packlv.level, self.packlv.extra_rows, self.packlv.fire, self.packlv.ice, self.packlv.repair
end

function Devourer:SetPackState(level, extra_rows, fire, ice, repair)
	local container = self.inst.components.container
	if container ~= nil then 
        if level and self.inst.components.named then -- 传了说明升级了，升级则更改名称
            self.inst.components.named:SetName(STRINGS.NAMES.DEVOURER_PACK_NAMES[level])
        end
        self.packlv.level = level or self.packlv.level
        self.packlv.extra_rows = extra_rows or self.packlv.extra_rows
        self.packlv.fire = fire or self.packlv.fire
        self.packlv.ice = ice or self.packlv.ice
        self.packlv.repair = repair or self.packlv.repair
        self.inst.replica.devourer:SetPackState(self.packlv)
        self:UpdateWidget()
		return true
	end
	return false
end
function Devourer:GetSlot()
    local level, extra_rows, lv_fire, lv_ice, lv_repair = self:GetLv() -- level:背包等级，extra_rows:额外行数
    local slot_set = add_configs.pack_slot_set[TUNING.DEVOURER_PACK_MAX_SLOTS]
    -- 列数受到最大格子限制，总列数是 初始列数 + x + y之和，请注意饥荒官方背包格子最大数有限制，超过会报错
    local base_cols = TUNING.DEVOURER_PACK_BASE_ROWS
    -- if level >= 2 and base_cols == 1 then -- 如果初始为1列（增加难度），则等级2提升时增加1列，保持最终列数不变
    --     base_cols = base_cols + 1
    -- end
    local lv_y = math.min(base_cols + (level - 1) + extra_rows, slot_set.y) -- 受到最终列数限制
    -- 初始列数是2，等级2增加行数，等级3增加列数，所以需要判断是否大于2,1级2级都是2列，3级是3列
    level = math.min(level >= 3 and 3 or 2, slot_set.x) -- 行数受到最大行数限制
    add_utils.debug_print("[Devourer GetSlot]: level", level, "extra_rows", extra_rows,"base_cols", base_cols, 
        "lv_y", lv_y, "lv_fire", lv_fire, "lv_ice", lv_ice, "lv_repair", lv_repair)
    return level, lv_y, lv_fire, lv_ice, lv_repair
end
local params = {}
function Devourer:UpdateWidget()
	local container = self.inst.components.container
	if container == nil then return end

    local lv_x, lv_y, lv_fire, lv_ice, lv_repair = self:GetSlot()
    
    add_utils.debug_print("[Replica:UpdateWidget] 计算背包格子: ", lv_x, "列 x ", lv_y, "行 (等级:" .. self.packlv.level .. ",额外列数:" .. self.packlv.extra_rows .. ",初始增加:" .. TUNING.DEVOURER_PACK_BASE_ROWS .. ")")
    local widget = setmetatable({}, {__index = container.widget})
	local lv_code = lv_x + bit.lshift(lv_y, 6)

    if params[self.inst.prefab] == nil then
        params[self.inst.prefab] = {}
    end

    if widget.slotbg ~= nil and widget.slotbg[1] ~= nil then
        local generic = widget.slotbg[1]
        for k, v in pairs(widget.slotbg) do
            if v.image ~= generic.image or v.atlas ~= generic.atlas then
                generic = nil
            end
        end
        --container.widget.slotbg.generic = generic
        if generic then
            widget.slotbg = generic
            widget.slotbg.generic = true
        end
    end

    -- 我这里直接用固定的坎普斯背包的这些参数
    local sep = Vector3(75.00, 75.00, 0.00)
    local shift_offset = Vector3(124.50, -15.00, -0.00)
    local scale_offset = Vector3(1.00, 1.00, 0.00)
    
    -- 背包达到最大格子，等级达到3级，特殊格子效果全部解锁，则增加第四排格子，变成4*9格子背包
    if lv_x==3 and lv_y==9 and self.packlv.level==3 
        and lv_fire >= 1 and lv_ice >= 1 and lv_repair >= 3 then
        lv_x = 4
        if not self.max_level then
            self.max_level = true
            self.max_level_reached = true
        end
    end

    widget.pos = Vector3(0, widget.pos.y, 0)
    widget.pos.x = math.floor((self.inst.baselv.x - lv_x) * 23) - 92

    local lv_x_fix = (lv_x > self.inst.baselv.x) and (lv_x - self.inst.baselv.x) or 0
    local lv_y_fix = lv_x_fix > 0 and (-8 * lv_x_fix) or ((lv_x > 1) and (lv_x-1) * 3 or 0)
    -- x轴，负数为右移背景，正数为左移背景
    widget.bgshift = Vector3(lv_x / self.inst.baselv.x * shift_offset.x + lv_y_fix, lv_y / self.inst.baselv.y * shift_offset.y + 100 + lv_y * 0.5, 1)
    widget.bgscale = Vector3(lv_x / self.inst.baselv.x * scale_offset.x - (lv_x_fix * 0.1), lv_y / self.inst.baselv.y * scale_offset.y, 1)

    local init_x = -(lv_x + 1) * math.floor(sep.x / 2)
    local init_y = -(lv_y + 1) * math.floor(sep.y / 2)
    
    local current_slots = self.inst.components.container and self.inst.components.container.GetNumSlots and self.inst.components.container:GetNumSlots()
        or self.inst.replica.container and self.inst.replica.container.GetNumSlots and self.inst.replica.container:GetNumSlots() or 4
    add_utils.debug_print("[Devourer:UpdateWidget] 当前格子数: ", current_slots, " 预期格子数: ", lv_x * lv_y)

    widget.slotpos = {}
    for y = lv_y, 1, -1 do
        for x = 1, lv_x do
            table.insert(widget.slotpos, Vector3(x * sep.x + init_x, y * sep.y + init_y + 100, 0))
        end
    end
    
    -- -- 动态设置特殊格子背景（最后两个格子）
    -- widget.slotbg = {}

    -- local num_slots = #widget.slotpos
    -- local repair_slot = num_slots       -- 倒数第1个格子，预留给修理格，1级效果
    -- local heating_slot = num_slots - 1  -- 倒数第2个格子，预留给加热格，2级效果
    -- local cooling_slot = num_slots - 2  -- 倒数第3个格子，预留给制冷格，3级效果
    -- local max_slot = num_slots - 3  -- 倒数第4个格子，预留给背包格子满级解锁，4级效果
    -- -- 自动修理器，虚空修补套件，亮茄修补套件（任选其一）升级后显示修理格子背景
    -- if (self.upgrade_effects.wagpunkbits_kit and self.upgrade_effects.wagpunkbits_kit.enab) 
    --     or (self.upgrade_effects.voidcloth_kit and self.upgrade_effects.voidcloth_kit.enab) 
    --     or (self.upgrade_effects.lunarplant_kit and self.upgrade_effects.lunarplant_kit.enab) then
    --     widget.slotbg[repair_slot] = { image = "slot_bg_tool.tex", atlas = "images/slot_bg_tool.xml" }
    -- end
    -- if self.upgrade_effects.dragonflyfurnace and self.upgrade_effects.dragonflyfurnace.enab then
    --     widget.slotbg[heating_slot] = { image = "slot_bg_fire.tex", atlas = "images/slot_bg_fire.xml" }
    -- end
    -- if self.upgrade_effects.deerclopseyeball_sentryward_kit and self.upgrade_effects.deerclopseyeball_sentryward_kit.enab then
    --     widget.slotbg[cooling_slot] = { image = "slot_bg_snow.tex", atlas = "images/slot_bg_snow.xml" }
    -- end
    -- if lv_x==4 then
    --     widget.slotbg[max_slot] = { image = "slot_bg_alchemy.tex", atlas = "images/slot_bg_alchemy.xml" }
    -- end
	container:Close()
	ModCompat(container, widget, lv_x, lv_y, lv_fire, lv_ice, lv_repair)

    local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner()
    add_utils.debug_print("[Devourer:UpdateWidget] 更新背包格子，当前拥有者: ", owner and owner.name or owner and owner.userid or "无")
    if owner and container.Open then
        local ok = pcall(function()
            container.Open(owner)
        end)
        if not ok then
            add_utils.debug_print("Devourer 更新格子之后打开报错")
        end
    end
end
-- 精神状态切换
function Devourer:ChangeSanityStatus(new_status)
    local owner = self and self.inst.components.inventoryitem:GetGrandOwner()
    if not owner or owner.components.sanity == nil or not self.inst then 
        return STRINGS.DP_DevourerPack.SANITY_CHANGE.NOT
    end

    -- 提前校验传入的固定状态是否合法（避免非法状态切换）
    if new_status ~= nil then
        -- 校验启迪模式（2）和暗影模式（3）的开启条件
        local is_valid = true
        if new_status == 2 then
            is_valid = self.upgrade_effects.alterguardianhat.enab and self.stats.lunar and self.stats.lunar >= 5
        elseif new_status == 3 then
            is_valid = self.stats.zerosanity
        end
        if not is_valid then
            return STRINGS.DP_DevourerPack.SANITY_CHANGE.NOT
        end
    end

    -- local msg
    -- 无固定状态时，按开启的模式组合顺序切换
    if not new_status then
        local lunar_open = self.upgrade_effects.alterguardianhat.enab and self.stats.lunar and self.stats.lunar >= 5 -- 启迪模式是否开启
        local zero_open = self.stats.zerosanity -- 暗影模式是否开启

        -- 两种模式都没开启，返回错误
        if not lunar_open and not zero_open then
            return STRINGS.DP_DevourerPack.SANITY_CHANGE.NOT
        end

        -- 获取当前状态，默认1（正常）
        local current_status = self.control_switch.SanityChange or 1
        new_status = current_status -- 初始化新状态

        -- 核心：按开启的模式组合处理切换顺序
        if lunar_open and zero_open then
            -- 两者都开启：1→2→3→1 循环
            if current_status == 1 then
                new_status = 2 -- 正常 → 启迪
            elseif current_status == 2 then
                new_status = 3 -- 启迪 → 暗影
            elseif current_status == 3 then
                new_status = 1 -- 暗影 → 正常
            end
        elseif lunar_open then
            -- 仅启迪开启：1↔2 切换
            new_status = current_status == 1 and 2 or 1
        elseif zero_open then
            -- 仅暗影开启：1↔3 切换
            new_status = current_status == 1 and 3 or 1
        end

        add_utils.debug_print("Devourer:ChangeSanityStatus current_status:", current_status, "new_status:", new_status)
    end

    -- 更新状态到开关控制
    self.control_switch.SanityChange = new_status

    -- 统一处理Sanity效果
    self:ApplySanityEffects(self.inst, owner, new_status)

    -- 如需提示信息，可打开下面注释
    -- if msg then
    --     self.inst.components.talker:Say(msg)
    --     TheNet:Announce(msg)
    -- end
end

function Devourer:ApplySanityEffects(inst, owner, new_status)
    -- 清除所有残留效果
    owner.components.sanity:SetInducedLunacy(inst, false)
    owner.components.sanity:EnableLunacy(false, "lunacyhat")
    inst:RemoveTag("lunarseedmaxed")
    owner.components.sanity:SetInducedInsanity(inst, false)
    -- 应用新状态
    if new_status == 3 then
        owner.components.sanity:SetInducedInsanity(self.inst, true)
        local stats = inst.components.devourer and inst.components.devourer.stats
        if stats and stats.shadowdominance and not owner:HasTag("shadowdominance") then
            owner:AddTag("shadowdominance")
            add_utils.debug_print("[标签] shadowdominance已添加")
        end
    elseif new_status == 2 then
        owner.components.sanity:SetInducedLunacy(self.inst, true)
        owner.components.sanity:EnableLunacy(true, "lunacyhat")
        inst:AddTag("lunarseedmaxed")
    end
end
function Devourer:ChangeAreaAttackStatus()
    if not self:CheckSuit("shadow")  then
        self.inst.components.talker:Say(STRINGS.DP_DevourerPack.AOE_ATTACK.disabled)
        return
    end
	self.control_switch.AreaAttack = self.control_switch.AreaAttack == 1 and 2 or 1
    local msg = self.control_switch.AreaAttack == 2 and STRINGS.DP_DevourerPack.AOE_ATTACK.on or STRINGS.DP_DevourerPack.AOE_ATTACK.off
    self.inst.components.talker:Say(msg)
    TheNet:Announce(msg)
end

-- 吞噬
function Devourer:OnDevourer(item, owner)
    if not item or not item.prefab or not self.upgrade_effects then
        return false
    end
    local prefab = item.prefab
    local inst = self.inst
    -- 处理特殊物品
    if prefab == "goldnugget" then
        self:ShowUnDevouredItems()          -- 随机推荐物品
        return true
    elseif prefab == "moonrocknugget" then
        self:_HandleMoonrockCheck()         -- 检查已有属性
        return true
    end

    local effect = self.upgrade_effects[prefab]
    local inst = self.inst
    if not effect then
        -- add_utils.debug_print(string.format("[升级系统] 错误: 物品%s不在升级配方中", prefab))
        inst.components.talker:Say(STRINGS.DP_DevourerPack.NOT_IN_RECIPE)
        return true
    end
    
    if effect.enab == true then
        if effect.max == nil or effect.cur >= effect.max then
            -- add_utils.debug_print("[升级系统] 错误: 已达到最大升级次数")
            inst.components.talker:Say(STRINGS.DP_DevourerPack.ALREADY_MAX)
            return true
        end
    end
    -- 计算需要消耗的数量（核心逻辑）
    local to_consume = 1  -- 默认消耗1个（非堆叠物品）
    if item.components.stackable and item.components.stackable:StackSize() > 1 then
        -- 堆叠物品：可以消耗多个
        if self.upgrade_effects[prefab].max ~= nil then
            -- 有max限制时，计算最多能消耗多少个
            local remaining = self.upgrade_effects[prefab].max - (self.upgrade_effects[prefab].cur or 0)
            to_consume = math.min(remaining, item.components.stackable:StackSize())
        end
    end

    -- 更新cur值（仅在max存在时）
    if self.upgrade_effects[prefab].max ~= nil then
        self.upgrade_effects[prefab].cur = (self.upgrade_effects[prefab].cur or 0) + to_consume
    end

    -- 处理物品销毁（仅在not_remove为false时）
    if not effect.not_remove then
        if item.components.stackable and item.components.stackable:StackSize() > 1 then
            item.components.stackable:Get(to_consume):Remove()  -- 移除指定数量
        else
            item:Remove()  -- 非堆叠物品直接销毁
        end
    else
        if prefab == "ancient_altar" then
            MakeAncientBroken(item, owner)
        end
    end

    -- 始终标记为已启用
    self.upgrade_effects[prefab].enab = true
    
    -- 检查是否满足升级条件
    local calc_level = self:CalcLevel()
    local can_level_up = calc_level > self.packlv.level
    if can_level_up then
        self.packlv.level = calc_level
    end
    
    -- 执行升级（属性应用）,owner不传进去，因为需要背着才生效属性，吞噬物品可以不用背着，这个owner是操作者，而不是Upgrade里面所需要的装备背包的人
    self:Upgrade()
    
    if prefab == "pig_coin" then
        self:Summon(true) -- 最开始直接召唤猪人
    end

    -- 生成特效
    local x, y, z = inst.Transform:GetWorldPosition()
    local fx
    if can_level_up then
        fx = SpawnPrefab("fx_book_light_upgraded")
    else
        if effect.add_slot_cols and effect.add_slot_cols > 1 then
            fx = SpawnPrefab("fx_book_research_station")
        elseif effect.stacksize then
            fx = SpawnPrefab("chestupgrade_stacksize_taller_fx")-- 弹性空间制造器特效
        else
            fx = SpawnPrefab("fx_book_temperature")
        end
    end
    fx.Transform:SetPosition(x, y, z)
    -- 生成效果描述
    local effectDesc = self:GetEffectDescription(prefab, to_consume)
    
    local msg = STRINGS.DP_DevourerPack.DELICIOUS_BASE
    if effectDesc and effectDesc ~= "" then
        msg = msg .. effectDesc
    else
        msg = STRINGS.DP_DevourerPack.WAIT_UNLOCK
    end
    TheNet:Announce(msg)
    -- 更新后同步（主机端执行）
    if TheWorld.ismastersim then
        -- -- 这些物品升级后会更新背包格子样式，必须先关闭背包再同步状态，否则会因为前后端格子数不匹配导致崩溃
        -- if add_configs.slot_specical_items[prefab] then
        --     add_utils.debug_print("OnDevourer next UpdateWidget")
        --     self:UpdateWidget() 
        -- end
        self:_SyncUpgradeEffects(prefab, true, self.upgrade_effects[prefab].cur) -- 同步数据
    end
    if can_level_up or add_configs.slot_specical_items[prefab] then --升级或者更新背包的特殊物品
        local target_level = can_level_up and calc_level or self.packlv.level
        self:SetPackState(target_level) -- 同步等级，更新背包样式
        if can_level_up then
            local current_lv = self.packlv.level
            local upgrade_msg = STRINGS.DP_DevourerPack.LEVEL_UP_MSG.UP .. STRINGS.NAMES.DEVOURER_PACK_NAMES[current_lv] .. STRINGS.DP_DevourerPack.LEVEL_UP_MSG[current_lv]
            TheNet:Announce(upgrade_msg)
        end
    end
    if self.max_level_reached then
        -- 获取玩家名称
        local player_name = "未知玩家"
        local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner
        if owner and owner:HasTag("player") then
            player_name = owner:GetDisplayName() or owner.name or "未知玩家"
        end
        local announce_msg = string.format(STRINGS.DP_DevourerPack.MAX_LEVEL_REACHED, player_name)
        TheNet:Announce(announce_msg)
        self.max_level_reached = nil-- 通知之后删掉，避免重复通知
    end
    return true
end

-- 检查是否满足升级条件
function Devourer:CheckAllLevel(current_lv)
    if current_lv >= 3 then  -- lv3 不处理
        return false
    end
    local new_level = current_lv
    local can_level_up = true
    if current_lv == 2 then
        for prefab, _ in pairs(add_configs.level_up["lv"..2].item) do
            -- 检查物品是否在 upgrade_effects 中，并且 enab 为 true
            if not self.upgrade_effects[prefab] or not self.upgrade_effects[prefab].enab then
                can_level_up = false
                break  -- 只要有一个不满足，直接退出循环
            end
        end
    elseif current_lv == 1 then
        for prefab, _ in pairs(add_configs.level_up["lv"..1].item) do
            -- 检查物品是否在 upgrade_effects 中，并且 enab 为 true
            if not self.upgrade_effects[prefab] or not self.upgrade_effects[prefab].enab then
                can_level_up = false
                break  -- 只要有一个不满足，直接退出循环
            end
        end
    end
    -- 如果满足条件，升级
    if can_level_up then
        local new_level = current_lv + 1
        if new_level == 2 then-- 判断下1升级2的是否需要2升级3
            for prefab, _ in pairs(add_configs.level_up["lv"..2].item) do
                -- 检查物品是否在 upgrade_effects 中，并且 enab 为 true
                if not self.upgrade_effects[prefab] or not self.upgrade_effects[prefab].enab then
                    can_level_up = false
                    break  -- 只要有一个不满足，直接退出循环
                end
            end
            if can_level_up then
                new_level = new_level + 1
            end
        end
        self.packlv.level = new_level
        self.inst.components.named:SetName(STRINGS.NAMES.DEVOURER_PACK_NAMES[new_level])
        return true
    end
    return false
end

-- 通过计算获取等级
function Devourer:CalcLevel()
    local current_lv = 1
    local lvup_to2 = true
    for prefab, _ in pairs(add_configs.level_up["lv"..1].item) do
        -- 检查物品是否在 upgrade_effects 中，并且 enab 为 true
        if not self.upgrade_effects[prefab] or not self.upgrade_effects[prefab].enab then
            lvup_to2 = false
            break  -- 只要有一个不满足，直接退出循环
        end
    end
    if lvup_to2 then
        current_lv = 2
        local lvup_to3 = true
        for prefab, _ in pairs(add_configs.level_up["lv"..2].item) do
            -- 检查物品是否在 upgrade_effects 中，并且 enab 为 true
            if not self.upgrade_effects[prefab] or not self.upgrade_effects[prefab].enab then
                lvup_to3 = false
                break  -- 只要有一个不满足，直接退出循环
            end
        end
        if lvup_to3 then
            current_lv = 3
        end
    end
    return current_lv
end

function Devourer:SetEnabFalse(prefab, upgrade)
    self.upgrade_effects[prefab].enab = false
    if upgrade then
        self:Upgrade()
    end
    -- 更新后同步（主机端执行）
    if TheWorld.ismastersim then
        self:_SyncUpgradeEffects(prefab, false)
    end
end

-- 保存存档
function Devourer:OnSave()
    local ps = self.pig_state
    local pig = ps.pig
    local data = {
        packlv = self.packlv,
        upgrade_effects = {},
        pig_kill_count = ps.kill_count,
        pig_health = pig and pig:IsValid() and not IsEntityDead(pig) and pig.components.health.currenthealth or ps.health,
        pig_max_health = pig and pig:IsValid() and not IsEntityDead(pig) and pig.components.health.maxhealth or ps.max_health,
        pig_data = pig and pig:IsValid() and pig:GetSaveRecord() or nil,
        pig_hat = ps.hat_data,
        pig_name = ps.name,
        pig_variation = ps.variation,
        pig_alive = ps.alive,
        pig_level_up_monsters = ps.level_up_monsters,
        control_switch = self.control_switch or {},
        max_level = self.max_level,
        current_bound_function = self.current_bound_function or "AreaAttack",
    }
    if self.upgrade_effects then
        for prefab, effect in pairs(self.upgrade_effects) do
            -- 只保存启用状态和有使用次数的条目
            if effect.enab and effect.max then
                data.upgrade_effects[prefab] = {
                    enab = true,
                    cur = math.min(effect.cur or 0, effect.max) -- 确保不超上限
                }
            elseif effect.enab then
                -- 无使用次数限制的只保存启用标记
                data.upgrade_effects[prefab] = { enab = true }
            end
        end
    end
    return data
end

-- 加载游戏时将保存的数据加载进来
function Devourer:OnLoad(data)
    if not data then return end
    self.max_level = data.max_level
    if data.control_switch then
        -- 恢复控制开关状态
        for key, value in pairs(data.control_switch) do
            if self.control_switch[key] ~= nil then
                self.control_switch[key] = value
            end
        end
    end
    -- 恢复当前绑定的功能键
    if data.current_bound_function then
        self.current_bound_function = data.current_bound_function
    end
    if data.upgrade_effects then
        for prefab, saved in pairs(data.upgrade_effects) do
            -- 确保效果表存在（兼容新增物品）
            if self.upgrade_effects[prefab] then
                -- 恢复启用状态
                self.upgrade_effects[prefab].enab = saved.enab or saved.enabled
                -- 恢复使用次数（仅限有max的条目）
                if self.upgrade_effects[prefab].max and (saved.cur or saved.current) then
                    self.upgrade_effects[prefab].cur = math.min(saved.cur or saved.current, self.upgrade_effects[prefab].max)
                end
            end
        end
    end
    -- 优先度:计算等级 > 初始等级 ，不过若初始>计算，则使用初始
    -- local save_x = data and data.packlv and data.packlv.level or 1 -- 保存等级
    -- local save_y = data and data.packlv and data.packlv.extra_rows or 0
    local calc_level = self:CalcLevel() -- 计算等级
    local default_level = self.packlv.level or self.packlv.x or 1 -- 初始等级
    local save_level = default_level
    if default_level < calc_level then
        save_level = calc_level
    end
    self.packlv.level = save_level
    -- self.packlv.extra_rows = save_y  -- 先保存，因为后面的Upgrade需要用到
    -- self.packlv.fire = data.packlv.fire or self.packlv.fire
    -- self.packlv.ice = data.packlv.ice or self.packlv.ice
    -- self.packlv.repair = data.packlv.repair or self.packlv.repair
    self:Upgrade()          -- 计算属性加成
    self.inst.components.named:SetName(STRINGS.NAMES.DEVOURER_PACK_NAMES[self.packlv.level])
    -- 加载后同步
    if TheWorld.ismastersim then
        self:_SyncUpgradeEffects()
    end
    self:SetPackState()        -- 恢复背包格子数，这里不需要传，因为前面存了，不传默认原有的
    -- 恢复猪人状态（兼容旧存档 key 名）
    self.pig_state.kill_count = data.pig_kill_count or data.pigKillCount or self.pig_state.kill_count or 0
    self.pig_state.health = data.pig_health or self.pig_state.health
    self.pig_state.max_health = data.pig_max_health or 300
    self.pig_state.hat_data = data.pig_hat
    self.pig_state.name = data.pig_name
    self.pig_state.variation = data.pig_variation
    self.pig_state.alive = data.pig_alive
    if data.pig_level_up_monsters or data.pig_level_up_monster then
        self.pig_state.level_up_monsters = data.pig_level_up_monsters or data.pig_level_up_monster
    end
    local saved_pig_data = data.pig_data or data.pigdata
    if saved_pig_data then
        if self.control_switch and self.control_switch.PigSummon == 2 then
            self.inst:DoTaskInTime(0, function() self:ChangePigSummon(2) end)
        else
            self:StartPigHealthRegen()
        end
    end
    -- 服务器重启后开关为开启但猪不存在且未死亡 → 自动重新召唤
    if self.control_switch and self.control_switch.PigSummon == 2
        and not (self.pig_state.pig and self.pig_state.pig:IsValid())
        and self.pig_state.alive ~= false then
        self.inst:DoTaskInTime(0.5, function() self:Summon() end)
    end
    self:_SyncControlsToReplica() -- 同步控制面板数据到Replica，确保客户端状态正确
end

-- 同步控制配置到客户端
function Devourer:_SyncControlsToReplica()
    self.inst.replica.devourer:_SyncControls(self.control_switch)
end

-- 同步控制配置到客户端
function Devourer:ChangeLuck(stats)
    if not stats then
        stats = self.stats
    end
    if stats.luck and stats.luck > 0 and self:CheckControlSwitch("Luck", 2) then
        -- add_utils.debug_print(string.format("[幸运] 幸运值: %d", stats.luck))
        if not self.inst.components.luckitem then
            self.inst:AddComponent("luckitem")
        end
        self.inst.components.luckitem:SetLuck(GetLuckFn) -- 如果没被装备
        self.inst.components.luckitem:SetEquippedLuck(GetLuckFn) -- 如果被装备了
    elseif self.inst.components.luckitem then
        self.inst.components.luckitem:SetLuck(0) -- 如果没被装备
        self.inst.components.luckitem:SetEquippedLuck(0) -- 如果被装备了
    end
end

-- 开关控制
return Devourer
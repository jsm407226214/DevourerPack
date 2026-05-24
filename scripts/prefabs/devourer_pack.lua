-- ============================================
-- 吞噬者背包 - 预制件
-- ============================================

local containers = require("containers")
local add_configs = require("configs/add_configs")
local add_utils = require("utils/add_utils")

-- ============================================
-- 资源
-- ============================================
local assets = {
    Asset("ANIM", "anim/devourer_pack.zip"),
    Asset("ANIM", "anim/devourer_cats.zip"),
    Asset("IMAGE", "images/inventoryimages/devourer_pack.tex"),
    Asset("ATLAS", "images/inventoryimages/devourer_pack.xml"),
    Asset("IMAGE", "images/inventoryimages/devourer_cats.tex"),
    Asset("ATLAS", "images/inventoryimages/devourer_cats.xml"),
}

-- ============================================
-- 皮肤缓存
-- ============================================
local PLAYER_SKIN_CACHE = {}

local function RefreshSkinCache(owner)
    if not owner or not owner.userid then return { "default" } end
    local krampus_skins = PREFAB_SKINS["krampus_sack"] and #PREFAB_SKINS["krampus_sack"] or 0
    local backpack_skins = PREFAB_SKINS["backpack"] and #PREFAB_SKINS["backpack"] or 0
    local total = 1 + krampus_skins + backpack_skins
    if PLAYER_SKIN_CACHE[owner.userid] and #PLAYER_SKIN_CACHE[owner.userid] >= total then
        return PLAYER_SKIN_CACHE[owner.userid]
    end
    PLAYER_SKIN_CACHE[owner.userid] = { "default" }
    for _, skin in pairs(PREFAB_SKINS["krampus_sack"] or {}) do
        if TheInventory:CheckClientOwnership(owner.userid, skin) then
            table.insert(PLAYER_SKIN_CACHE[owner.userid], skin)
        end
    end
    for _, skin in pairs(PREFAB_SKINS["backpack"] or {}) do
        if TheInventory:CheckClientOwnership(owner.userid, skin) then
            table.insert(PLAYER_SKIN_CACHE[owner.userid], skin)
        end
    end
    return PLAYER_SKIN_CACHE[owner.userid]
end

-- ============================================
-- 防掉落（强握/强头 + 背包自身保护）
-- ============================================
local function NewDropItem(inst, owner)
    if not owner.components.inventory then return end
    if not owner.components.inventory._OriginalDropItem then
        owner.components.inventory._OriginalDropItem = owner.components.inventory.DropItem
    end
    owner.components.inventory.DropItem = function(self, item, wholestack, randomdir, pos, keepoverstacked)
        if not owner or not owner:IsValid() or owner:HasTag("playerghost")
            or (owner.components.health and (owner.components.health:IsDead() or owner.components.health.currenthealth == 0))
            or owner._devourer_switch_character then
            return self:_OriginalDropItem(item, wholestack, randomdir, pos, keepoverstacked)
        end
        local dev = inst.components.devourer
        -- 背包自身保护
        if item and item.prefab == "devourer_pack" and item.is_drop and dev.control_switch.StopDrop == 2 then
            inst.components.talker:Say(STRINGS.DP_DevourerPack.DROP.PACK)
            return nil
        end
        -- 投掷武器不受保护
        if item and (item.components.projectile or item.components.oceanthrowable
            or item.components.complexprojectile or item:HasTag("projectile")) then
            return self:_OriginalDropItem(item, wholestack, randomdir, pos, keepoverstacked)
        end
        -- 已装备物品保护
        if item and item.components.equippable then
            local slot = item.components.equippable.equipslot
            local equipped = owner.components.inventory:GetEquippedItem(slot)
            if equipped and item:IsValid() and equipped:IsValid() and item.GUID == equipped.GUID then
                if slot == EQUIPSLOTS.HANDS and dev:CheckSuit("stronggrip") and dev.control_switch.StopDrop == 2 then
                    if item.prefab ~= "torch" then
                        inst.components.talker:Say(STRINGS.DP_DevourerPack.DROP.HAND)
                    end
                    return nil
                elseif slot == EQUIPSLOTS.HEAD and dev:CheckSuit("stronghead") and dev.control_switch.StopDrop == 2 then
                    inst.components.talker:Say(STRINGS.DP_DevourerPack.DROP.HEAD)
                    return nil
                end
            end
        end
        return self:_OriginalDropItem(item, wholestack, randomdir, pos, keepoverstacked)
    end
    -- 监听角色切换
    if not owner._devourer_pack_listeners then
        owner._devourer_pack_listeners = {
            switching = owner:ListenForEvent("ms_playerreroll", function()
                owner._devourer_switch_character = true
            end),
        }
    end
end

--[[
    强制移除装备并掉落物品的通用方法
    
    参数:
        inst - 物品实例（被装备的物品）
        owner - 装备者（玩家）
        equip_slot - 装备槽位（如 EQUIPSLOTS.HANDS, EQUIPSLOTS.HEAD, EQUIPSLOTS.BODY）
        message_key - 提示文字的字符串key（可选）
        play_sound - 是否播放音效（可选，默认true）
        play_animation - 是否播放受击动画（可选，默认true）
]]
local function ForceUnequipAndDrop(drop_pack, existing_pack, message_key, play_sound, play_animation)
    -- 获取物品所有者
    local owner = drop_pack.components.inventoryitem and drop_pack.components.inventoryitem.owner
    if not owner or not owner:IsValid() then return end
    play_sound = play_sound ~= nil and play_sound or true
    play_animation = play_animation ~= nil and play_animation or true
    if message_key == nil then
        message_key = STRINGS.DP_DevourerPack.DROP.ToPack
    end

    -- 使用 DoTaskInTime(0) 延迟一帧执行，确保操作完成后再处理
    drop_pack:DoTaskInTime(0, function()
        -- 获取装备槽位
        local equip_slot = drop_pack.components.equippable and drop_pack.components.equippable.equipslot or nil
        
        -- 检查物品是否已装备
        local is_equipped = equip_slot and owner.components.inventory:GetEquippedItem(equip_slot) == drop_pack
        
        if is_equipped then
            -- 已装备：先卸下，再尝试放回背包，最后掉落
            owner.components.inventory:Unequip(equip_slot)
            -- local was_given = owner.components.inventory:GiveItem(inst)
            local was_given = false
            if not was_given then
                if owner.components.inventory._OriginalDropItem then
                    owner.components.inventory:_OriginalDropItem(drop_pack)
                else
                    owner.components.inventory:DropItem(drop_pack)
                end
            end
        else
            -- 未装备（在物品栏中）：直接掉落
            if owner.components.inventory._OriginalDropItem then
                owner.components.inventory:_OriginalDropItem(drop_pack, true, true, owner:GetPosition())
            else
                owner.components.inventory:DropItem(drop_pack, true, true, owner:GetPosition())
            end
        end
        
        -- 显示提示文字
        if message_key ~= nil and owner.components.talker ~= nil then
            existing_pack.components.talker:Say(message_key)
        end
        
        -- 播放音效
        if play_sound then
            owner.SoundEmitter:PlaySound("dontstarve_DLC001/common/HUD_hot_level1")
        end
        
        -- 播放受击动画
        if play_animation and owner.sg ~= nil then
            owner.sg:GoToState("hit")
        end
    end)
end

-- ============================================
-- 装备 / 卸下
-- ============================================
local function onequip(inst, owner)
    if inst._is_equipped then return end
    -- 检查玩家是否已经有其他吞噬者背包（排除当前物品）
    local existing_pack = add_utils.GetDevourerPack(owner, inst)
    if existing_pack then
        -- 强制卸下当前吞噬者背包（如果已装备）或直接掉落（如果在物品栏）
        ForceUnequipAndDrop(inst, existing_pack)
        return
    end
    inst._is_equipped = true
    NewDropItem(inst, owner)

    -- 随机皮肤
    local available_skins = RefreshSkinCache(owner)
    local target_type = available_skins[math.random(#available_skins)]
    if target_type == "default" then
        owner.AnimState:OverrideSymbol("backpack", "swap_krampus_sack", "backpack")
        owner.AnimState:OverrideSymbol("swap_body", "swap_krampus_sack", "swap_body")
    else
        owner.AnimState:OverrideItemSkinSymbol("backpack", target_type, "backpack", inst.GUID, "swap_krampus_sack")
        owner.AnimState:OverrideItemSkinSymbol("swap_body", target_type, "swap_body", inst.GUID, "swap_krampus_sack")
        inst.skin_name = target_type
    end

    if inst.is_loaded then
        inst.components.devourer:EquipUpdate(inst, owner)
    end

    -- 重装备时自动恢复猪人召唤
    local dev = inst.components.devourer
    if dev and dev.control_switch.PigSummon == 2
        and not (dev.pig_state.pig and dev.pig_state.pig:IsValid()) then
        dev:Summon()
    end

    -- 新背包先修正布局再打开，避免闪烁 36 格
    if not inst.is_create then
        inst.is_create = true
        dev:SetPackState()
    end
    inst.components.container:Open(owner)
end

local function onunequip(inst, owner)
    inst._is_equipped = false
    if owner.components.inventory and owner.components.inventory._OriginalDropItem then
        owner.components.inventory.DropItem = owner.components.inventory._OriginalDropItem
    end
    if owner._devourer_pack_listeners then
        for _, listener in pairs(owner._devourer_pack_listeners) do
            if listener then owner:RemoveEventCallback(listener) end
        end
        owner._devourer_pack_listeners = nil
    end
    owner._devourer_switch_character = nil
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.AnimState:ClearOverrideSymbol("backpack")

    if inst.is_loaded then
        inst.components.devourer:UnEquipUpdate(inst, owner)
    end
    inst.components.container:Close(owner)
end

-- ============================================
-- 容器音效
-- ============================================
local function OnOpen(inst, doer)
    local sound = inst.skin_name and SKIN_SOUND_FX[inst.skin_name] and SKIN_SOUND_FX[inst.skin_name].open_ui
        or (inst.components.container.widget and inst.components.container.widget.opensound)
        or (inst.components.container:IsSideWidget() and "dontstarve/wilson/backpack_open")
        or "dontstarve/HUD/Together_HUD/container_open"
    inst.SoundEmitter:PlaySound(sound)
end

local function OnClose(inst, doer)
    local sound = inst.skin_name and SKIN_SOUND_FX[inst.skin_name] and SKIN_SOUND_FX[inst.skin_name].close_ui
        or (inst.components.container.widget and inst.components.container.widget.closesound)
        or (inst.components.container:IsSideWidget() and "dontstarve/wilson/backpack_close")
        or "dontstarve/HUD/Together_HUD/container_close"
    inst.SoundEmitter:PlaySound(sound)
end

-- ============================================
-- 防偷窃（火药猴 nosteal 标记）
-- ============================================
local function ItemGained(inst, data)
    if data and data.item and not data.item:HasTag("nosteal") then
        data.item:AddTag("nosteal")
        data.item._devourer_nosteal = true
    end
end

local function ItemLost(inst, data)
    if data and data.prev_item and data.prev_item._devourer_nosteal then
        data.prev_item:RemoveTag("nosteal")
    end
end

-- ============================================
-- 存档 / 读档（entity 层，早于组件 OnLoad）
-- ============================================
local function OnSave(inst, data)
    if not data then data = {} end
    data.is_create = inst.is_create or false
    data.is_drop = inst.is_drop or false
    if inst.components.devourer then
        data.packlv = inst.components.devourer.packlv
    end
end

local function OnLoad(inst, data)
    if not data then return end
    inst.is_create = data.is_create or false
    inst.is_drop = data.is_drop or false
    if data.packlv and inst.components.devourer then
        local dev = inst.components.devourer
        if not dev then return end
        -- 兼容旧存档 key 名（x/y → level/extra_rows，注意 Lua 中 0 是真值）
        dev.packlv.level = data.packlv.level or data.packlv.x or 1
        dev.packlv.extra_rows = data.packlv.extra_rows or data.packlv.y or 0
        dev.packlv.fire = data.packlv.fire or 0
        dev.packlv.ice = data.packlv.ice or 0
        dev.packlv.repair = data.packlv.repair or 0
        dev:SetPackState()
    end
end

-- ============================================
-- 预制件工厂
-- ============================================
local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("devourer_pack.tex")
    inst.MiniMapEntity:SetEnabled(true)

    MakeInventoryPhysics(inst)

    local devourer_icon = add_configs.mod_icon[TUNING.DEVOURER_ICON]
    inst.AnimState:SetBank(devourer_icon)
    inst.AnimState:SetBuild(devourer_icon)
    inst.AnimState:PlayAnimation("idle")
    inst.foleysound = "dontstarve/movement/foley/krampuspack"

    inst:AddTag("backpack")
    inst:AddTag("devourer_pack")
    inst:AddTag("nosteal")  -- 火药猴禁止偷窃标记
    inst:AddTag("donotautopick") -- 禁止自动拾取

    MakeInventoryFloatable(inst, "med", 0.1, 0.65, nil, nil, { bank = "backpack1", anim = "anim" })

    inst.entity:SetPristine()
    inst:AddComponent("talker")
    inst.baselv = Vector3(2, 7, 1)

    if not TheWorld.ismastersim then return inst end

    -- ---- 基础组件 ----
    inst:AddComponent("named")
    inst.components.named:SetName(STRINGS.NAMES.DEVOURER_PACK_NAMES[1])
    inst:AddComponent("inspectable")

    -- ---- 物品栏 ----
    local inventoryitem = inst:AddComponent("inventoryitem")
    -- inventoryitem.canonlygoinpocket = true -- 这个不起作用，先不删吧
    inventoryitem:SetOnPutInInventoryFn(function(item, owner)
        item.prevcontainer = nil
        item.prevslot = nil
        
        -- 不允许放入非玩家容器
        if owner and not owner:HasTag("player") then
            inst:DoTaskInTime(0, function()
                local drop_pos = owner:GetPosition()
                local grand = owner.components.inventoryitem and owner.components.inventoryitem:GetGrandOwner()
                if grand and grand:HasTag("player") then
                    drop_pos = grand:GetPosition()
                end
                if owner.components.container then
                    local removed = owner.components.container:RemoveItem(item)
                    if removed then
                        removed.components.inventoryitem:OnRemoved()
                        removed.Transform:SetPosition(drop_pos:Get())
                        removed.components.inventoryitem:OnDropped(true)
                    end
                elseif owner.components.inventory then
                    local removed = owner.components.inventory:RemoveItem(item)
                    if removed then
                        removed.components.inventoryitem:OnRemoved()
                        removed.Transform:SetPosition(drop_pos:Get())
                        removed.components.inventoryitem:OnDropped(true)
                    end
                end
                inst.components.talker:Say(STRINGS.DP_DevourerPack.DROP.ToPack)
            end)
            return
        end
        
        -- 禁止玩家持有多个吞噬者背包
        if owner and owner:HasTag("player") then
            local existing_pack = add_utils.GetDevourerPack(owner, item)
            if existing_pack then
                inst:DoTaskInTime(0, function()
                    inst.components.talker:Say(STRINGS.DP_DevourerPack.DROP.REPEAT)
                    -- 使用原始的 DropItem 方法，绕过防丢弃保护
                    if owner.components.inventory._OriginalDropItem then
                        owner.components.inventory:_OriginalDropItem(item, true, true, owner:GetPosition())
                    else
                        owner.components.inventory:DropItem(item, true, true, owner:GetPosition())
                    end
                end)
                return
            end
        end
    end)

    inst.components.inventoryitem.imagename = devourer_icon
    inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. devourer_icon .. ".xml"

    -- ---- 容器 + 吞噬者组件 ----
    inst:AddComponent("container")
    inst:AddComponent("devourer")
    inst.components.container:WidgetSetup("devourer_pack")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose

    
    -- 初始化启用灵魂罐功能，实际根据组件管理
    inst:AddTag("souljar")
    inst.components.inventoryitem.canonlygoinpocket = true
    inst.components.container:EnableInfiniteStackSize(true) -- 开启无限堆叠，这是为了重启服务器不丢东西，实际有组件管理

    -- 猴子/水獭偷窃提示（冷却 5 秒）
    inst._laststealresTime = 0
    inst:ListenForEvent("onitemstolen", function(inst, data)
        if data.thief and (data.thief.prefab == "monkey" or data.thief.prefab == "otter") then
            local now = GetTime()
            if now - (inst._laststealresTime or 0) >= 5 then
                inst:DoTaskInTime(0.1, function()
                    inst.components.talker:Say(STRINGS.DP_DevourerPack.STEAL_RES)
                end)
                inst._laststealresTime = now
            end
        end
    end)

    -- ---- 可装备 ----
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BACK or EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    -- 禁止装备第二个吞噬者背包
    local orig_IsRestricted = inst.components.equippable.IsRestricted
    inst.components.equippable.IsRestricted = function(self, target)
        if orig_IsRestricted(self, target) then return true end
        if target and target:HasTag("player") and target.components.inventory then
            for _, v in pairs(target.components.inventory.itemslots) do
                if v.prefab == inst.prefab and v.GUID ~= inst.GUID then return true end
            end
        end
        return false
    end

    -- ---- 事件 ----
    inst:ListenForEvent("itemlose", ItemLost)
    inst:ListenForEvent("itemget", ItemGained)
    inst:AddComponent("leader")
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    -- ---- 延迟初始化 ----
    -- 新背包首次装备时修正布局
    inst:DoTaskInTime(0.03, function()
        inst.is_drop = true
        if not inst.is_create and inst.components.devourer and inst.replica.devourer
            and inst.components.container then
            inst.components.devourer:SetPackState()
            inst.is_create = true
        end
    end)

    -- 1 秒后触发装备更新（等待 owner 绑定）
    inst:DoTaskInTime(1, function()
        inst.is_loaded = true
        local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
        if owner then
            inst.components.devourer:EquipUpdate(inst, owner)
        end
    end)

    return inst
end

return Prefab("devourer_pack", fn, assets)
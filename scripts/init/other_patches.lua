-- 其它相关补丁

local add_utils = require("utils/add_utils")

-- 劫持官方的新鲜度系统，吞噬者背包如果吞噬了蛤蟆皮，则可以特殊腐烂效果（毒菌蟾蜍&其它）
AddComponentPostInit("perishable", function(self)
    local original_ReducePercent = self.ReducePercent
    
    function self:ReducePercent(amount)
        local devourer_pack = self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner
        
        add_utils.debug_print("Perishable ReducePercent called for", self.inst.prefab, "with owner", devourer_pack and devourer_pack.prefab or "nil")
        -- 直接检查 owner 是否是 devourer_pack
        -- 无论背包被背着还是放地上，这个判断都成立
        if devourer_pack and devourer_pack.prefab == "devourer_pack" then
            add_utils.debug_print("Owner is devourer_pack, checking for spore immunity. Devourer pack has tag dp_spore_immunity:"
            , devourer_pack and devourer_pack:HasTag("dp_spore_immunity"))
            local should_ignore = devourer_pack and devourer_pack:HasTag("dp_spore_immunity")
            if should_ignore then
                return  -- 免疫
            end
        end
        
        return original_ReducePercent(self, amount)
    end
end)



-- 睡觉逻辑
local function SetSleeperSleepState(inst)
    if inst.components.grue ~= nil then
        inst.components.grue:AddImmunity("sleeping")
    end
    if inst.components.talker ~= nil then
        inst.components.talker:IgnoreAll("sleeping")
    end
    if inst.components.firebug ~= nil then
        inst.components.firebug:Disable()
    end
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:EnableMapControls(false)
        inst.components.playercontroller:Enable(false)
    end
    inst:OnSleepIn()
    inst.components.inventory:Hide()
    inst:PushEvent("ms_closepopups")
    inst:ShowActions(false)
end

local function SetSleeperAwakeState(inst)
    if inst.components.grue ~= nil then
        inst.components.grue:RemoveImmunity("sleeping")
    end
    if inst.components.talker ~= nil then
        inst.components.talker:StopIgnoringAll("sleeping")
    end
    if inst.components.firebug ~= nil then
        inst.components.firebug:Enable()
    end
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:EnableMapControls(true)
        inst.components.playercontroller:Enable(true)
    end
    inst:OnWakeUp()
    inst.components.inventory:Show()
    inst:ShowActions(true)
    
    -- 统一在这里取消恢复任务！
    inst:DoTaskInTime(0, function()
        add_utils.StopSleepHeal(inst)
    end)
end

-- 服务端视觉状态
local devourer_pack_bedroll = GLOBAL.State({
    name = "devourer_pack_bedroll",
    tags = { "bedroll", "busy", "nomorph" },

    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("action_uniqueitem_pre")
        inst.AnimState:PushAnimation("bedroll", false)
        if inst.components.talker then
             inst.components.talker:Say(STRINGS.DP_DevourerPack.SLEEP.sleep_msg)
        end
        SetSleeperSleepState(inst)
    end,

    timeline = {
        TimeEvent(20 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/use_bedroll")
        end),
    },

    events = {
        EventHandler("firedamage", function(inst)
            if inst.sg:HasStateTag("sleeping") then
                inst.sg.statemem.iswaking = true
                inst.sg:GoToState("wakeup")
            end
        end),
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                if (inst.components.health ~= nil and inst.components.health.takingfiredamage) or
                    (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
                    inst:PushEvent("performaction", { action = inst.bufferedaction })
                    inst:ClearBufferedAction()
                    inst.sg.statemem.iswaking = true
                    inst.sg:GoToState("wakeup")
                else
                    inst.sg:AddStateTag("sleeping")
                    inst.sg:AddStateTag("silentmorph")
                    inst.sg:RemoveStateTag("nomorph")
                    inst.sg:RemoveStateTag("busy")
                    inst.AnimState:PlayAnimation("bedroll_sleep_loop", true)
                end
            end
        end),
    },

    onexit = function(inst)
        add_utils.debug_print("Exiting bedroll state, waking up")
        if inst.sleepingbag ~= nil then
            inst.sleepingbag.components.sleepingbag:DoWakeUp(true)
            inst.sleepingbag = nil
        end
        SetSleeperAwakeState(inst)

        -- 同步背包的睡觉开关状态：被攻击/强制醒来后重置为未睡觉
        local pack = add_utils.GetDevourerPack(inst)
        if pack and pack.components.devourer then
            local devourer = pack.components.devourer
            devourer.control_switch["SleepAnywhere"] = 0
            devourer:_SyncControlsToReplica()
        end

        -- 延迟一帧显示醒来消息，避免被 wakeup 状态的 onenter 清除
        inst:DoTaskInTime(0.3, function()
            if inst.components.talker then
                inst.components.talker:Say(STRINGS.DP_DevourerPack.SLEEP.wakeup_msg)
            end
        end)
    end,
})
AddStategraphState("wilson", devourer_pack_bedroll)

-- 客户端视觉状态
local devourer_pack_bedroll_c = GLOBAL.State({
    name = "devourer_pack_bedroll",
    tags = { "bedroll", "busy" },

    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("action_uniqueitem_pre")
        inst.AnimState:PushAnimation("action_uniqueitem_lag", false)
        inst:PerformPreviewBufferedAction()
    end,

    onupdate = function(inst)
        if inst:HasTag("busy") or inst:HasTag("sleeping") then
            if inst.entity:FlattenMovementPrediction() then
                inst.sg:GoToState("idle", "noanim")
            end
        elseif inst.bufferedaction == nil then
            inst.sg:GoToState("idle")
        end
    end,

    ontimeout = function(inst)
        inst:ClearBufferedAction()
        inst.sg:GoToState("idle")
    end,
})
AddStategraphState("wilson_client", devourer_pack_bedroll_c)

-- ============================================================
-- 被攻击自动醒来 + 取消恢复
-- ============================================================

AddStategraphEvent("wilson", EventHandler("attacked", function(inst, data)
    add_utils.debug_print("Player attacked, checking if sleeping. Current state tags:", inst.sg and inst.sg:HasStateTag("sleeping") or "nil")
    if inst.sg:HasStateTag("sleeping") then
        inst.sg.statemem.iswaking = true
        inst.sg:GoToState("wakeup")
    end
end))
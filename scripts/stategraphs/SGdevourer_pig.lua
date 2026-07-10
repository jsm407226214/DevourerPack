require("stategraphs/commonstates")

local actionhandlers = {
    ActionHandler(ACTIONS.EAT, "eat"),
    ActionHandler(ACTIONS.CHOP, "chop"),
    ActionHandler(ACTIONS.PICKUP, "pickup"),
    ActionHandler(ACTIONS.EQUIP, "pickup"),
    ActionHandler(ACTIONS.ADDFUEL, "pickup"),
    ActionHandler(ACTIONS.TAKEITEM, "pickup"),
    ActionHandler(ACTIONS.UNPIN, "pickup"),
    ActionHandler(ACTIONS.DROP, "dropitem"),
    ActionHandler(ACTIONS.MARK, "dropitem"),
}

local POSING_MASS = 200
local DEFAULT_MASS = 50

local events = {
    CommonHandlers.OnAttack(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnSleepEx(),
    CommonHandlers.OnWakeEx(),
    CommonHandlers.OnLocomote(true, true),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnHop(),

    EventHandler("doaction", function(inst, data)
        if data.action == ACTIONS.CHOP and not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            inst.sg:GoToState("chop", data.target)
        end
    end),

    EventHandler("despawn", function(inst)
        if inst.sg:HasStateTag("idle") and (inst.components.health == nil or not inst.components.health:IsDead()) then
            inst.sg:GoToState("despawn")
        end
    end),

    EventHandler("onsink", function(inst)
        if inst.components.health == nil or not inst.components.health:IsDead() then
            inst.sg:GoToState("despawn")
        end
    end),
}

local function go_to_idle(inst)
    inst.sg:GoToState("idle")
end

-- 基础 1 击（timeline 固定，剩余普攻+终结击由 onenter 动态追加）
local function BuildComboTimeline()
    return {
        TimeEvent(12 * FRAMES, function(inst)
            inst.components.combat:DoAttack()
            inst.SoundEmitter:PlaySound("dontstarve/pig/attack")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
        end),
    }
end

-- 登场动画超时（用查表替代 if-elseif）
local SPAWNIN_TIMEOUT = {
    ["1"] = 36, ["2"] = 36, ["3"] = 34, ["4"] = 34,
}

local states = {
    State {
        name = "idle",
        tags = { "idle", "canrotate" },
        onenter = function(inst)
            if inst.sg.mem.sleeping then
                inst.sg:GoToState("sleep")
            else
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("idle_object_loop", true)
            end
        end,
    },

    State {
        name = "attack",
        tags = { "attack", "busy" },
        onenter = function(inst)
            inst.components.combat:StartAttack()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk_combo")

            -- _combo_count = 普攻次数（不含终结击），_attack_interval = 连击间隔帧数
            local normals = inst._combo_count or 1      -- 普攻总次数
            local interval = inst._attack_interval or 8  -- 普攻之间间隔
            local extra = normals - 1                    -- 第1击已由 timeline 完成
            -- 动画加速：combo 越多越快
            inst.AnimState:SetDeltaTimeMultiplier(1 + extra * 0.15)

            -- 额外普攻
            for i = 1, extra do
                inst:DoTaskInTime((12 + i * interval) * FRAMES, function()
                    if inst.sg:HasStateTag("attack") then
                        inst.components.combat:DoAttack()
                        inst.SoundEmitter:PlaySound("dontstarve/pig/attack")
                        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
                    end
                end)
            end

            -- 终结击（特殊动作，所有普攻之后，间隔稍长以示区分）
            local finisher_frame = 12 + extra * interval + math.max(interval + 4, 13)
            inst:DoTaskInTime(finisher_frame * FRAMES, function()
                if inst.sg:HasStateTag("attack") then
                    inst.components.combat:DoAttack()
                    inst.SoundEmitter:PlaySound("dontstarve/pig/attack")
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
                end
            end)

            -- 清除 busy 标签
            local end_frame = finisher_frame + 12
            inst:DoTaskInTime(end_frame * FRAMES, function()
                inst.sg:RemoveStateTag("attack")
                inst.sg:RemoveStateTag("busy")
            end)
        end,
        timeline = BuildComboTimeline(),

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State {
        name = "chop",
        tags = { "chopping" },
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")
        end,
        timeline = {
            TimeEvent(13 * FRAMES, function(inst) inst:PerformBufferedAction() end),
        },
        events = {
            EventHandler("animover", go_to_idle),
        },
    },

    State {
        name = "eat",
        tags = { "busy" },
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat")
        end,
        timeline = {
            TimeEvent(10 * FRAMES, function(inst) inst:PerformBufferedAction() end),
            TimeEvent(2 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/pig/eat") end),
            TimeEvent(11 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/beefalo/chew") end),
            TimeEvent(21 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/beefalo/chew") end),
        },
        events = {
            EventHandler("animover", go_to_idle),
        },
    },

    State {
        name = "hit",
        tags = { "busy" },
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/pig/oink")
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,
        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "death",
        tags = { "busy" },
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/pig/grunt")
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
        end,
    },

    State {
        name = "spawnin",
        tags = { "intropose", "busy", "nofreeze", "nosleep", "noattack", "jumping" },
        onenter = function(inst, data)
            inst.AnimState:PlayAnimation(inst.sg.mem.variation == "3" and "side_lob" or "front_lob")
            inst.AnimState:PushAnimation("pose" .. inst.sg.mem.variation .. "_pre", false)
            inst.AnimState:PushAnimation("pose" .. inst.sg.mem.variation .. "_pst", false)
            inst.SoundEmitter:PlaySound("dontstarve/movement/twirl_LP", "twirl")
            if data and data.dest then
                ToggleOffAllObjectCollisions(inst)
                inst:ForceFacePoint(data.dest)
                inst.Physics:SetMotorVelOverride(
                    math.sqrt(inst:GetDistanceSqToPoint(data.dest)) / (22 * FRAMES), 0, 0
                )
                inst.Physics:SetMass(POSING_MASS)
            end
            local frames = SPAWNIN_TIMEOUT[inst.sg.mem.variation] or 34
            inst.sg:SetTimeout(frames * FRAMES)
        end,
        timeline = {
            TimeEvent(20.5 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt") end),
            TimeEvent(21.5 * FRAMES, PlayFootstep),
            TimeEvent(22 * FRAMES, function(inst)
                inst.SoundEmitter:KillSound("twirl")
                if inst.sg.mem.isobstaclepassthrough then
                    inst.Physics:ClearMotorVelOverride()
                    inst.Physics:Stop()
                    local x, y, z = inst.Transform:GetWorldPosition()
                    ToggleOnAllObjectCollisionsAt(inst, x, z)
                end
                inst.sg:RemoveStateTag("jumping")
            end),
        },
        ontimeout = function(inst)
            inst.components.talker:Chatter("PIG_ELITE_FIGHTER_INTRO", tonumber(inst.sg.mem.variation))
        end,
        events = {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end
            end),
        },
        onexit = function(inst)
            if inst.sg.mem.isobstaclepassthrough then
                inst.Physics:ClearMotorVelOverride()
                inst.Physics:Stop()
                local x, y, z = inst.Transform:GetWorldPosition()
                ToggleOnAllObjectCollisionsAt(inst, x, z)
            end
            inst.SoundEmitter:KillSound("twirl")
            inst.Physics:SetMass(DEFAULT_MASS)
        end,
    },

    State {
        name = "despawn",
        tags = { "endpose", "busy", "nofreeze", "nosleep", "noattack", "jumping" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:AddOverrideBuild("player_superjump")
            inst.AnimState:PlayAnimation("superjump_pre")
            inst.AnimState:PushAnimation("superjump", false)
            ToggleOffAllObjectCollisions(inst)
            inst.components.talker:Chatter("PIG_ELITE_FIGHTER_OUTRO", tonumber(inst.sg.mem.variation))
        end,
        timeline = {
            TimeEvent(5 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt", nil, 0.4)
                inst.SoundEmitter:PlaySound("dontstarve/common/deathpoof")
            end),
        },
        events = {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then inst:Remove() end
            end),
        },
    },
}

CommonStates.AddWalkStates(states, {
    walktimeline = {
        TimeEvent(0, PlayFootstep),
        TimeEvent(12 * FRAMES, PlayFootstep),
    },
})

CommonStates.AddRunStates(states)

CommonStates.AddSleepExStates(states, {
    starttimeline = {
        TimeEvent(13 * FRAMES, function(inst) inst.sg:RemoveStateTag("caninterrupt") end),
    },
    sleeptimeline = {
        TimeEvent(35 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/pig/sleep") end),
    },
}, {
    onsleep = function(inst) inst.sg:AddStateTag("caninterrupt") end,
})

CommonStates.AddSimpleState(states, "refuse", "pig_reject", { "busy" })
CommonStates.AddFrozenStates(states)
CommonStates.AddHopStates(states, true, { pre = "boat_jump_pre", loop = "boat_jump_loop", pst = "boat_jump_pst" })

return StateGraph("devourer_pig", states, events, "idle", actionhandlers)

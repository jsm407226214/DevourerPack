if TUNING.DEVOURER_PIG_KING_MODIFY then

    local function PushMusic(inst)
        if ThePlayer ~= nil and ThePlayer:IsNear(inst, 30) then
            ThePlayer:PushEvent("triggeredevent", { name = "pigking" })
        end
    end

    local function OnMusicDirty(inst)
        --Dedicated server does not need to trigger music
        if not TheNet:IsDedicated() then
            if inst._musictask ~= nil then
                inst._musictask:Cancel()
            end
            inst._musictask = inst._music:value() and inst:DoPeriodicTask(1, PushMusic, 0) or nil
        end
    end

    local function StartMusic(inst)
        if not inst._music:value() then
            inst._music:set(true)
            OnMusicDirty(inst)
        end
    end

    local function StopMusic(inst)
        if inst._music:value() then
            inst._music:set(false)
            OnMusicDirty(inst)
        end
    end

    -- 修改猪王判断逻辑
    local BLOCKING_ONEOF_OBJECTS = {"fire", "structure", "minigameitem", "CHOP_workable", "HAMMER_workable", "MINE_workable"}
    local BLOCKING_CANT_OBJECTS = {"INLIMBO"}
    local ALLOWED_MINIGAME_ENTITIES = {
        pigking = true,
        insanityrock = true,
        sanityrock = true,
        pigking_pigtorch = true,  -- 动态添加
    }
    local function IsAreaClearForMinigame(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, TUNING.PIG_MINIGAME_ARENA_RADIUS, nil, BLOCKING_CANT_OBJECTS, BLOCKING_ONEOF_OBJECTS)
        
        for _, ent in ipairs(ents) do
            if not ALLOWED_MINIGAME_ENTITIES[ent.prefab] then
                return false
            end
        end
        return true
    end

    local AREACLEAR_IGNORE_PLAYERS = {"player"}
    local AREACLEAR_CHECK_FOR_HOSTILES = {"hostile", "monster"}
    local AREACLEAR_COMBAT = {"_combat"}
    local function IsAreaSafeForMinigame(inst, giver)
        -- print("[PigKing] Checking area safety...")
        
        -- 检查猎犬袭击
        local hounded = TheWorld.components.hounded
        if hounded ~= nil and (hounded:GetWarning() or hounded:GetAttacking()) then
            -- print("[PigKing] Area unsafe: hound attack in progress or imminent")
            return false
        end
        
        -- 检查给予者燃烧状态
        if giver ~= nil then
            local burnable = giver.components.burnable
            if burnable ~= nil and (burnable:IsBurning() or burnable:IsSmoldering()) then
                -- print("[PigKing] Area unsafe: giver is on fire or smoldering")
                return false
            end
        end

        -- 检查敌对生物
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, TUNING.PIG_MINIGAME_ARENA_RADIUS * 2, nil, AREACLEAR_IGNORE_PLAYERS, AREACLEAR_CHECK_FOR_HOSTILES)
        -- print(string.format("[PigKing] Found %d hostile/monster entities", #ents))
        if #ents > 0 then
            -- print("[PigKing] Area unsafe: hostile entities present")
            for i, ent in ipairs(ents) do
                -- print(string.format("[PigKing] Hostile entity %d: %s (prefab: %s)", i, tostring(ent), ent.prefab))
            end
            return false
        end

        -- 检查战斗状态
        local combat_ents = TheSim:FindEntities(x, y, z, TUNING.PIG_MINIGAME_ARENA_RADIUS * 2, nil, nil, AREACLEAR_COMBAT)
        -- print(string.format("[PigKing] Found %d entities in combat", #combat_ents))
        for _, ent in ipairs(combat_ents) do
            if ent.components.combat:HasTarget() then
                -- print(string.format("[PigKing] Combat entity: %s (prefab: %s) has target", tostring(ent), ent.prefab))
                return false
            end
        end

        -- print("[PigKing] Area is safe for minigame")
        return true
    end

    local function CanStartMinigame(inst, giver)
        -- print("[PigKing] Checking if minigame can start...")
        
        -- 检查时间条件
        if TheWorld.net ~= nil and TheWorld.net.components.clock ~= nil then
            local time_until_night = TheWorld.net.components.clock:GetTimeUntilPhase("night")
            -- print(string.format("[PigKing] Time until night: %.1f, required: %.1f", time_until_night, TUNING.PIG_MINIGAME_REQUIRED_TIME))
            if time_until_night <= TUNING.PIG_MINIGAME_REQUIRED_TIME or inst.sg.mem.sleeping then
                -- print("[PigKing] Cannot start: too close to night or pig king is sleeping")
                return false, "PIGKINGGAME_TOOLATE"
            end
        end
        
        -- 检查区域清理
        if not IsAreaClearForMinigame(inst) then
            -- print("[PigKing] Cannot start: area is not clear")
            return false, "PIGKINGGAME_MESSY"
        end
        
        -- 检查安全条件
        if not IsAreaSafeForMinigame(inst, giver) then
            -- print("[PigKing] Cannot start: area is not safe")
            return false, "PIGKINGGAME_DANGER"
        end
        
        -- 检查是否已有小游戏进行
        if next(inst._minigame_elites) ~= nil then
            -- print("[PigKing] Cannot start: minigame already in progress")
            return false
        end
        
        -- print("[PigKing] All conditions met, minigame can start")
        return true
    end

    local function OnRefuseItem(inst, giver, item)
        -- print(string.format("[PigKing] Refusing item: %s from %s", item.prefab, giver.prefab))
        inst.sg:GoToState("unimpressed")
    end

    local function AbleToAcceptTest(inst, item, giver)
        -- print(string.format("[PigKing] AbleToAcceptTest for item: %s from %s", item.prefab, giver and giver.prefab or "nil"))
        
        if item.prefab == "pig_token" then
            local success, reason = CanStartMinigame(inst, giver)
            if not success then
                -- print(string.format("[PigKing] Cannot accept pig_token: %s", reason or "minigame already in progress"))
                OnRefuseItem(inst, giver, item)
            end
            return success, reason
        end
        
        -- print("[PigKing] Accepting non-pig_token item")
        return true
    end


    -- 修改猪王小游戏奖励
    local function OnRestoreItemPhysics(item)
        item.Physics:CollidesWith(COLLISION.OBSTACLES)
    end

    local function LaunchGameItem(inst, item, angle, minorspeedvariance)
        local x, y, z = inst.Transform:GetWorldPosition()
        local spd = 3.5 + math.random() * (minorspeedvariance and 1 or 3.5)
        if bit.band(item.Physics:GetCollisionMask(), COLLISION.OBSTACLES) ~= 0 then
            item.Physics:ClearCollidesWith(COLLISION.OBSTACLES)
            item:DoTaskInTime(0.6, OnRestoreItemPhysics)
        end
        item.Physics:Teleport(x, 2.5, z)
        item.Physics:SetVel(math.cos(angle) * spd, 11.5, math.sin(angle) * spd)
        item:PushEvent("knockbackdropped", { owner = inst, knocker = inst, delayinteraction = .75, delayplayerinteraction = .5 })

        --#WARNING: you probably don't want this last part if you copy pasta this function!--
        if item.components.burnable ~= nil then
            inst:ListenForEvent("onignite", function()
                for k, v in pairs(inst._minigame_elites) do
                    k:SetCheatFlag()
                end
            end, item)
        end
        -------------------------------------------------------------------------------------
    end

    local PROP_MUST_TAGS = { "minigameitem", "propweapon" }
    local PROP_CANT_TAGS = { "INLIMBO", "fire", "burnt" }
    local function OnTossGameItems(inst)
        local items = {}
        local x, y, z = inst.Transform:GetWorldPosition()
        local numplayers = #FindPlayersInRange(x, y, z, 16, true)
        local mingold = math.min(6, 2 + math.floor(numplayers / 2))
        local numgold = math.random(mingold, mingold + 2)
        local numprops = 0
        if #TheSim:FindEntities(x, y, z, 12, PROP_MUST_TAGS, PROP_CANT_TAGS) < numplayers + 4 then
            local maxprops = 2 + math.floor(numplayers / 2)
            numprops = math.max(numgold > 2 and 1 or 2, math.random(maxprops - (maxprops > 2 and numgold > mingold and 2 or 1), maxprops))
            for i = 1, numprops do
                table.insert(items, "propsign")
            end
        elseif numgold < 3 then
            numgold = 3
        end
        for i = 1, numgold do
            table.insert(items, MINIGAME_ITEM)
        end
        inst._minigame_gold_tossed = inst._minigame_gold_tossed + numgold
        local angle = math.random() * TWOPI
        local delta = TWOPI / (numgold + numprops + 1) --purposely leave a random gap
        local variance = delta * .4
        while #items > 0 do
            local item = SpawnPrefab(table.remove(items, math.random(#items)))
            if item.OnCancelMinigame ~= nil then
                item:ListenForEvent("ms_cancelminigame", item.OnCancelMinigame, inst)
                item:ListenForEvent("onremove", item.OnCancelMinigame, inst)
            end
            LaunchGameItem(inst, item, GetRandomWithVariance(angle, variance))
            angle = angle + delta
        end
        if numgold > 0 then
            inst.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
        end
    end
    -- 修改奖励分发函数
    local function LaunchRewards(inst, level, minigame_players)
        local x, y, z = inst.Transform:GetWorldPosition()
        local pouches = {}
        local num_players = math.max(1, #minigame_players)

        if IsSpecialEventActive(SPECIAL_EVENTS.YOTP) then
            -- 猪王年活动奖励
            -- local num_player_pounches = num_players * ((level == 4 or level == 2) and 2 or 1)
            
            -- 1. 调整后的福袋（金子数量-1）
            for ip = 1, math.max(1, level) do
                local items = {}
                -- 福袋金块（比原版少1个）
                -- local gold_in_pouch = (level >= 3 and 3 or 1)  -- 原为4，现改为3
                local gold_in_pouch = math.random(1, math.max(level, 1)) -- 随机幸运金块数量，最少1个
                for i = 1, gold_in_pouch do
                    table.insert(items, SpawnPrefab("lucky_goldnugget"))
                end
                local pouch = SpawnPrefab("redpouch_yotp")
                pouch.Transform:SetPosition(x, 4.5, z)
                pouch.components.unwrappable:WrapItems(items)
                table.insert(pouches, pouch)
            end

            -- 2. 超过2级，每级给一个铸币
            for i = 1, math.max(0, (level - 1)) do
                table.insert(pouches, SpawnPrefab("pig_coin"))
            end
        else
            -- 非活动奖励（完全原版）
            for i = 1, 2 + (level * 2) do
                table.insert(pouches, SpawnPrefab("goldnugget"))
            end
            for i = 1, math.max(0, (level - 1) * 2) do
                table.insert(pouches, SpawnPrefab("pig_coin"))
            end
        end

        -- 抛出奖励（原版物理逻辑）
        for i, item in ipairs(pouches) do
            local angle
            local target = minigame_players[((i-1) % num_players) + 1]
            if target ~= nil and target:IsValid() then
                angle = 180 - target:GetAngleToPoint(x, 0, z)
            else
                local down = TheCamera:GetDownVec()
                angle = math.atan2(down.z, down.x) / DEGREES
            end
            LaunchGameItem(inst, item, GetRandomWithVariance(angle, 25))
        end
    end

    local function OnPickupCheat(inst, data)
        if data ~= nil and data.cheater ~= nil and data.item ~= nil and data.cheater:HasTag("player") and data.item:HasTag("minigameitem") then
            for k, v in pairs(inst._minigame_elites) do
                k:SetCheatFlag()
            end
        end
    end

    local NUM_ROUNDS = 10
    local ROUND_TIME = 6

    local function GameComplete(inst)
        local minigame_players = {}
        for i, v in ipairs(AllPlayers) do
            if v.components.minigame_participator ~= nil and v.components.minigame_participator:GetMinigame() == inst then
                table.insert(minigame_players, v)
            end
        end

        inst.CancelGame(inst)
        inst.sg:GoToState("cointoss")

        inst:DoTaskInTime(2 / 3, LaunchRewards, inst.GetMinigameScore(inst), minigame_players)
    end

    local function CheckElitesPosing(inst)
        for k, v in pairs(inst._minigame_elites) do
            if not k.sg:HasStateTag("endpose") then
                return
            end
        end
        inst._minigametask:Cancel()
        inst._minigametask = inst:DoTaskInTime(1.5, GameComplete)
        StopMusic(inst)
    end

    local function GameCompleteFocus(inst)
        TheWorld:PushEvent("unpausehounded", { source = inst })
        inst:EnableCameraFocus(true)
        inst._minigametask = inst:DoPeriodicTask(.1, CheckElitesPosing)
    end

    local function FlagGameComplete(inst)
        inst.components.minigame:SetIsOutro()

        inst.sg:GoToState("unimpressed")
        for k, v in pairs(inst._minigame_elites) do
            k.flagmatchover = true
        end
        inst._minigametask = inst:DoTaskInTime(1, GameCompleteFocus)
    end

    local function DoGameRound(inst, roundsleft)
        inst.sg:GoToState("cointoss")
        if inst._minigametosstask ~= nil then
            inst._minigametosstask:Cancel()
        end
        inst._minigametosstask = inst:DoTaskInTime(2 / 3, OnTossGameItems)
        inst._minigametask =
            roundsleft > 1 and
            inst:DoTaskInTime(ROUND_TIME, DoGameRound, roundsleft - 1) or
            inst:DoTaskInTime(ROUND_TIME, FlagGameComplete)

        inst.components.minigame:SetIsPlaying()
        inst.components.minigame:RecordExcitement()
    end

    local function StartMinigame(inst)
        if inst._minigametask == nil then
            MINIGAME_ITEM = IsSpecialEventActive(SPECIAL_EVENTS.YOTP) and "lucky_goldnugget" or "goldnugget"

            inst._minigame_score = nil
            inst._minigame_gold_tossed = 0
            inst.components.minigame:Activate()
            inst.components.minigame:RecordExcitement()
            inst.sg:GoToState("intro")
            inst._minigametask = inst:DoTaskInTime(5, DoGameRound, NUM_ROUNDS)
            inst:ListenForEvent("pickupcheat", OnPickupCheat)
        end
        StartMusic(inst)
    end


    AddPrefabPostInit("pigking", function(inst)
        if not TheWorld.ismastersim then
            return
        end
        inst.components.trader:SetAbleToAcceptTest(AbleToAcceptTest)

        local _OnAcceptOld = inst.components.trader.onaccept
        local function OnGetItemFromPlayer(inst, giver, item)
            if item and item.prefab == "pig_token" then
                StartMinigame(inst)
            else
                _OnAcceptOld(inst, giver, item)
            end
        end
        inst.components.trader.onaccept = OnGetItemFromPlayer
    end)
    
end
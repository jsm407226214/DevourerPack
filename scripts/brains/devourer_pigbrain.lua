require("behaviours/chaseandattackandavoid")
require("behaviours/leashandavoid")
require("behaviours/panicandavoid")
require("behaviours/standstill")
require("behaviours/wander")
require("behaviours/doaction")

local BrainCommon = require("brains/braincommon")
local pig_config = require("configs/pig_config")

-- 跟随距离：猪在 MIN~MAX 之间活动，TARGET 是最佳距离
-- 超过 MAX 会跑回 leader，小于 MIN 会退开
local MIN_FOLLOW_DIST = 2     -- 最近距离（不挤到玩家）
local TARGET_FOLLOW_DIST = 8  -- 目标距离
local MAX_FOLLOW_DIST = 20    -- 最远距离（超过就跑回来）
local SEE_FOOD_DIST = 15
local MAX_CHASE_TIME = 15
local MAX_CHASE_DIST = 40     -- 追击距离
local KEEP_CHOPPING_DIST = 16 -- 砍树范围
local SEE_TREE_DIST = 20

-- 挖矿
local MINE_TAGS = { "MINE_workable" }
local MINE_CANT_TAGS = { "carnivalgame_part", "event_trigger", "waxedplant" }

local function FindMineEnt(finder, finddist)
    return FindEntity(finder, finddist, function(ent)
        return not ent.components.growable or ent.components.growable.stage == #(ent.components.growable.stages or {})
    end, MINE_TAGS, MINE_CANT_TAGS)
end

local function FindNewMine(inst, leaderdist, finddist)
    local target = FindMineEnt(inst, finddist)
    if target == nil and inst.components.follower.leader ~= nil then
        target = FindMineEnt(inst.components.follower.leader, finddist)
    end
    if target ~= nil then
        return BufferedAction(inst, target, ACTIONS.MINE)
    end
end

local FORBIDDEN_FOODS = {
    glommerfuel = true,
    deerclops_eyeball = true,
    minotaurhorn = true,
    wereitem_goose = true,
    wereitem_beaver = true,
    wereitem_moose = true,
    oceanfish_small_7_inv = true,
    oceanfish_small_8_inv = true,
    oceanfish_small_6_inv = true,
    oceanfish_medium_8_inv = true,
}

local DevourerPigBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetLeader(inst)
    return inst.components.follower.leader
end

local function FindFoodAction(inst)
    if inst.sg:HasStateTag("busy") then return end

    -- 先从物品栏找
    if inst.components.inventory and inst.components.eater then
        local target = inst.components.inventory:FindItem(function(item)
            return inst.components.eater:CanEat(item)
        end)
        if target then
            return BufferedAction(inst, target, ACTIONS.EAT)
        end
    end

    -- 控制进食频率
    local time_since_eat = inst.components.eater:TimeSinceLastEating()
    if time_since_eat and time_since_eat <= pig_config.growth.min_eat_interval then
        return
    end

    -- 从地面找食物
    local target = FindEntity(inst, SEE_FOOD_DIST, function(item)
        if FORBIDDEN_FOODS[item.prefab] then return false end
        return item:GetTimeAlive() >= 8
            and item.components.edible ~= nil
            and item:IsOnPassablePoint()
            and inst.components.eater:CanEat(item)
    end, nil, { "outofreach" })

    if target then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end
end

function DevourerPigBrain:OnStart()
    local root = PriorityNode({
        WhileNode(function() return self.inst.sg:HasStateTag("jumping") end, "Standby",
            ActionNode(function() end)),

        WhileNode(function() return self.inst._should_despawn end, "Standby",
            ParallelNode {
                StandStill(self.inst),
                LoopNode { ActionNode(function() self.inst:PushEvent("despawn") end) },
            }),

        ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),

        BrainCommon.NodeAssistLeaderDoAction(self, {
            action = "CHOP",
            chatterstring = "COMBO_PIG_TALK_HELP_CHOP_WOOD",
            keepgoing_leaderdist = KEEP_CHOPPING_DIST,
            finder_finddist = SEE_TREE_DIST,
        }),
        BrainCommon.NodeAssistLeaderDoAction(self, {
            action = "MINE",
            chatterstring = "COMBO_PIG_TALK_HELP_CHOP_WOOD",
            keepgoing_leaderdist = KEEP_CHOPPING_DIST,
            finder_finddist = SEE_TREE_DIST,
            finder = FindNewMine,
        }),

        DoAction(self.inst, FindFoodAction),
        Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
        Wander(self.inst),
    }, 0.5)

    self.bt = BT(self.inst, root)
end

return DevourerPigBrain

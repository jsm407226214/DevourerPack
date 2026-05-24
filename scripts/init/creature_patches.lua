-- 生物相关补丁：蜜蜂之友、蜈蚣崩溃修复

local add_utils = require("utils/add_utils")

-- 杀人蜂巢：蜜蜂之友不触发
AddPrefabPostInit("wasphive", function(inst)
    local old_onnear = inst.components.playerprox and inst.components.playerprox.onnear or nil

    local function new_onnear(inst, target)
        local devourer_pack = add_utils.GetDevourerPack(target)
        local should_ignore = target and target.components.inventory
            and target.components.inventory:EquipHasTag("devourer_bee")
            and devourer_pack and devourer_pack.components.devourer
            and devourer_pack.components.devourer.control_switch.DevourerBee == 2
        if should_ignore then return end
        if old_onnear then
            old_onnear(inst, target)
        elseif inst.components.childspawner then
            inst.components.childspawner:ReleaseAllChildren(target, "killerbee")
        end
    end

    if inst.components.playerprox then
        inst.components.playerprox:SetOnPlayerNear(new_onnear)
    end
end)

-- 蜂箱：蜜蜂之友采收不触发蜜蜂
local levels = {
    { amount = 6, idle = "honey3", hit = "hit_honey3" },
    { amount = 3, idle = "honey2", hit = "hit_honey2" },
    { amount = 1, idle = "honey1", hit = "hit_honey1" },
    { amount = 0, idle = "bees_loop", hit = "hit_idle" },
}

local function setlevel(inst, level)
    if not inst:HasTag("burnt") then
        if inst.anims == nil then
            inst.anims = { idle = level.idle, hit = level.hit }
        else
            inst.anims.idle = level.idle
            inst.anims.hit = level.hit
        end
        inst.AnimState:PlayAnimation(inst.anims.idle)
    end
end

local function updatelevel(inst)
    if not inst:HasTag("burnt") then
        for k, v in pairs(levels) do
            if inst.components.harvestable.produce >= v.amount then
                setlevel(inst, v)
                break
            end
        end
    end
end

local function BlockBeesOnHarvest(inst)
    if not inst.components.harvestable then return end
    local old_OnHarvest = inst.components.harvestable.onharvestfn

    inst.components.harvestable.onharvestfn = function(inst, picker, produce)
        if picker and picker.components.inventory
            and picker.components.inventory:EquipHasTag("devourer_bee") then
            if inst:HasTag("burnt") then return end
            if inst.components.harvestable then
                inst.components.harvestable:SetGrowTime(nil)
                inst.components.harvestable.pausetime = nil
                inst.components.harvestable:StopGrowing()
            end
            if produce == levels[1].amount then
                AwardPlayerAchievement("honey_harvester", picker)
            end
            updatelevel(inst)
            return
        end
        return old_OnHarvest and old_OnHarvest(inst, picker, produce)
    end
end

AddPrefabPostInit("beebox", BlockBeesOnHarvest)
AddPrefabPostInit("beebox_hermit", BlockBeesOnHarvest)

-- 修复暗影蜈蚣崩溃（ForceKill 缺失）
local function FixCentipedeHealth(inst)
    if inst and inst.components and inst.components.health then
        if not inst.components.health.ForceKill and inst.components.health.Kill then
            inst.components.health.ForceKill = function(self)
                self:Kill()
            end
        end
    end
end

AddPrefabPostInit("shadowthrall_centipede_head", FixCentipedeHealth)
AddPrefabPostInit("shadowthrall_centipede_body", FixCentipedeHealth)

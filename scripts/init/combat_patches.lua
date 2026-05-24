-- 战斗相关补丁

local add_utils = require("utils/add_utils")

-- AOE 攻击时武器可能为 nil，导致 CalcDamage 报错
AddComponentPostInit("combat", function(self)
    local oldCalcDamage = self.CalcDamage
    self.CalcDamage = function(self, target, weapon, multiplier, ...)
        local damage, spdamage
        if oldCalcDamage ~= nil then
            if weapon and weapon.components.weapon == nil then
                weapon = nil
            end
            damage, spdamage = oldCalcDamage(self, target, weapon, multiplier, ...)
        end
        return damage, spdamage
    end
end)

-- 跳跃后恢复踏水状态
local ToggleOnPhysics = nil
AddStategraphPostInit("wilson", function(sg)
    if ToggleOnPhysics == nil then
        if sg.states and sg.states.jumpout and sg.states.jumpout.onexit then
            local oldonexit = sg.states.jumpout.onexit
            if oldonexit ~= nil then
                ToggleOnPhysics = add_utils.Get(oldonexit, "ToggleOnPhysics")
                if ToggleOnPhysics ~= nil then
                    add_utils.Set(oldonexit, "ToggleOnPhysics", function(inst)
                        ToggleOnPhysics(inst)
                        if inst and inst._is_treading_water_active then
                            local dev_item = add_utils.GetDevourerPack(inst)
                            if dev_item and dev_item.components.devourer then
                                dev_item.components.devourer:SetTreadWater(true)
                            end
                        end
                    end)
                end
            end
        end
    end
end)

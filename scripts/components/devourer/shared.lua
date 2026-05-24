-- 吞噬者背包 - 共享函数模块
-- 存放需要在多个文件中共享的辅助函数

local shared = {}

-- ============================================
-- 温度控制相关函数
-- ============================================

-- 移除温度组件
function shared.change_back_for_temperature(inst)
	if inst then
		inst:RemoveComponent("insulator")
	end
end

-- 设置冬季保温
function shared.set_winter(self, inst, double)
    if not inst then
        inst = self.inst
    end
	if inst and not inst.components.insulator then
		inst:AddComponent("insulator")
	end
    if self.stats.kw > 0 then
        local temperature = self.stats.kw
        if double then
            temperature = temperature * 2
        end
        inst.components.insulator:SetInsulation(temperature)
        inst.components.insulator:SetWinter()
    else
        shared.change_back_for_temperature(inst)
    end
end

-- 设置夏季隔热
function shared.set_summer(self, inst, double)
    if not inst then
        inst = self.inst
    end
	if inst and not inst.components.insulator then
		inst:AddComponent("insulator")
	end
    if self.stats.kc > 0 then 
        local temperature = self.stats.kc
        if double then
            temperature = temperature * 2
        end
        inst.components.insulator:SetInsulation(temperature)
        inst.components.insulator:SetSummer()
    else
        shared.change_back_for_temperature(inst)
    end
end

-- 监控温度变化
function shared.monitor_temperature(self, owner)
    if not owner.components.temperature then return end
    local inst = self.inst
    if inst and inst.monitor_temperature_task then
        inst.monitor_temperature_task:Cancel()
        inst.monitor_temperature_task = nil
    end
    local double = false
    if self:CheckSuit("season") then
        double = true  -- 四季Boss套装效果：保温/隔热效果翻倍
    end
    if self.control_switch.KeepTemp == 1 then -- 自动变化
        inst.monitor_temperature_task = inst:DoPeriodicTask(1, function()
            local owner_temp = owner.components.temperature and owner.components.temperature.GetCurrent and owner.components.temperature:GetCurrent()
            
            if owner_temp and owner_temp < 35 then
                shared.set_winter(self, inst, double)  -- self 是 Devourer 组件，inst 是背包实体
            elseif owner_temp and owner_temp > 35 then
                shared.set_summer(self, inst, double)
            elseif owner_temp then
                shared.change_back_for_temperature(inst)
            end
        end, 0)
    elseif self.control_switch.KeepTemp == 2 then
        shared.set_winter(self, inst, double)  -- 保温
    elseif self.control_switch.KeepTemp == 3 then
        shared.set_summer(self, inst, double)  -- 隔热
    end
end

-- 停止温度监控
function shared.stop_monitor_temperature(inst)
    if inst and inst.monitor_temperature_task then 
        inst.monitor_temperature_task:Cancel()
        inst.monitor_temperature_task = nil
        shared.change_back_for_temperature(inst)
    end
end

-- ============================================
-- 装备刷新函数
-- ============================================

-- 刷新装备状态，确保属性更新生效
function shared.RefreshEquip(inst, owner)
    if not inst then return end
    if owner == nil then
        owner = inst.components.inventoryitem.owner
    end
    if owner and owner:IsValid() then
        local slot = inst.components.equippable.equipslot
        owner:PushEvent("unequip", {item=inst,eslot=slot})
        owner:PushEvent('equip', {item=inst,eslot=slot,no_animation=true})
    end
end

return shared
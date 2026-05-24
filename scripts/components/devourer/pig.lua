-- 吞噬者背包 - 猪人管理模块（Mixin）
-- 通过 devourer.lua 入口加载：require("components/devourer/pig")(Devourer)

local add_utils = require("utils/add_utils")
local pig_config = require("configs/pig_config")

return function(Devourer)

-- ============================================
-- 局部辅助函数
-- ============================================

local function SavePigHat(self)
    local pig = self.pig_state.pig
    if not (pig and pig:IsValid() and pig.components.inventory) then
        self.pig_state.hat_data = nil
        return
    end
    local hat = pig.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    if hat then
        self.pig_state.hat_data = { prefab = hat.prefab, save_record = hat:GetSaveRecord() }
    else
        self.pig_state.hat_data = nil
    end
end

local function GetPigFromLeader(owner)
    if not (owner and owner.components.leader and owner.components.leader.followers) then return end
    for pig, bool in pairs(owner.components.leader.followers) do
        if pig and pig:IsValid() and pig.prefab and string.find(pig.prefab, "devourer_pig") and bool then
            return pig
        end
    end
end

local function LinkPig(self, pig, owner)
    if not (pig and pig:IsValid()) then return end

    -- 设置名字（持久化）
    if self.pig_state.name then
        pig.displayname = self.pig_state.name
    else
        local names = pig_config.pig_names
        self.pig_state.name = names[math.random(#names)]
        pig.displayname = self.pig_state.name
    end

    pig:ProcessKill(true, self.pig_state.kill_count)

    if owner then
        owner.components.leader:AddFollower(pig)
    else
        self.inst.components.leader:AddFollower(pig)
    end

    -- 恢复血量
    if self.pig_state.health then
        local percent = math.min(1, self.pig_state.health / pig.components.health.maxhealth)
        pig.components.health:SetPercent(percent)
    end

    -- 恢复头盔
    if self.pig_state.hat_data and self.pig_state.hat_data.save_record then
        local hat = SpawnSaveRecord(self.pig_state.hat_data.save_record)
        if hat and pig.components.inventory then
            pig.components.inventory:Equip(hat)
        end
        pig.AnimState:Show("hat")
        self.pig_state.hat_data = nil
    elseif pig.components.inventory and pig.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) then
        pig.AnimState:Show("hat")
    end

    self.inst:ListenForEvent("death", self._onpigdeath, pig)
    self.inst:ListenForEvent("killed", self._onpigkilled, pig)
    self.pig_state.pig = pig
end

local function TrySpawnPig(inst, self, owner)
    local pig
    if self.pig_state.save_data then
        pig = SpawnSaveRecord(self.pig_state.save_data)
        self.pig_state.save_data = nil
    end
    if not pig or not pig:IsValid() then
        local var = self.pig_state.variation or tostring(math.random(4))
        self.pig_state.variation = var
        pig = SpawnPrefab("devourer_pig" .. var)
    end

    LinkPig(self, pig, owner)

    local pos = owner and owner:GetPosition() or inst:GetPosition()
    if owner then
        pos.y = (owner.components.rider and owner.components.rider:IsRiding()) and 3 or 0
    else
        pos.y = 0
    end
    pig.Transform:SetPosition(pos.x, pos.y, pos.z)

    local theta = math.random() * PI2
    local offset = FindWalkableOffset(pos, theta, 2.5, 16, true, true, nil, false, true)
        or FindWalkableOffset(pos, theta, 2.5, 16, false, false, nil, false, true)
        or Vector3(0, 0, 0)

    pos.x, pos.y, pos.z = pos.x + offset.x, 0, pos.z + offset.z
    pig.sg:GoToState("spawnin", { dest = pos })

    if self.pig_state.spawn_task then
        self.pig_state.spawn_task:Cancel()
        self.pig_state.spawn_task = nil
    end
end

-- ============================================
-- 猪人等级计算
-- ============================================

function Devourer:GetPigLevel(count)
    if not count or count <= 0 then return 1 end
    return math.floor((count - 1) / pig_config.growth.exp_per_level) + 1
end

function Devourer:IsPigLevelUp(oldCount, newCount)
    return self:GetPigLevel(oldCount) < self:GetPigLevel(newCount)
end

-- ============================================
-- 猪人经验与升级
-- ============================================

function Devourer:PigEat(pig)
    local oldCount = self.pig_state.kill_count
    self.pig_state.kill_count = self.pig_state.kill_count + 1
    local newCount = self.pig_state.kill_count

    if self:IsPigLevelUp(oldCount, newCount) then
        self.pig_state.kill_count = oldCount
        return false
    end

    pig:ProcessKill(true, self.pig_state.kill_count)
    return true
end

function Devourer:PigKilled(inst, data)
    if not (data and data.victim and data.victim.components.health
        and data.victim.components.health.maxhealth >= 50
        and not data.victim:HasTag("wall")) then
        return
    end

    local victim = data.victim
    local prefab = victim.prefab
    local oldCount = self.pig_state.kill_count
    local hp = victim.components.health.maxhealth
    -- 击杀经验分层：Boss > 大型 > 中型 > 小型
    local addKill
    if victim:HasTag("epic") then
        addKill = pig_config.growth.kill_exp_monster
    elseif hp >= 1000 then
        addKill = pig_config.growth.kill_exp_large
    elseif hp >= 200 then
        addKill = pig_config.growth.kill_exp_medium
    else
        addKill = pig_config.growth.kill_exp_normal
    end
    self.pig_state.kill_count = self.pig_state.kill_count + addKill
    local newCount = self.pig_state.kill_count

    if victim:HasTag("epic") then
        self.pig_state.level_up_monsters[prefab] = (self.pig_state.level_up_monsters[prefab] or 0) + 1
    end

    -- ============================================
    -- Boss 等级突破机制：
    --   猪人获得经验后会检查是否升级。
    --   升级条件：击杀过 ≥(目标等级-1) 种不同 Boss。
    --   例：升到 LV2 需要杀过 1 种 Boss，升到 LV5 需要杀过 4 种。
    --   不满足条件 → 经验锁定在当前等级上限，无法升级。
    --   Boss 种类记录在 pig_state.level_up_monsters[prefab] 中。
    -- ============================================
    if self:IsPigLevelUp(oldCount, newCount) then
        local newLevel = self:GetPigLevel(newCount)
        local requiredBossCount = newLevel - 1   -- 需要击杀的不同 Boss 数量
        local currentBossCount = 0
        for _, count in pairs(self.pig_state.level_up_monsters) do
            if count > 0 then currentBossCount = currentBossCount + 1 end
        end
        if currentBossCount < requiredBossCount then
            -- 不满足条件，经验锁定于当前等级上限
            self.pig_state.kill_count = self:GetPigLevel(oldCount) * pig_config.growth.exp_per_level
        end
    end

    inst:ProcessKill(false, self.pig_state.kill_count)
end

function Devourer:PigDeath()
    TheNet:Announce(pig_config.dialogue.death)
    self.pig_state.kill_count = math.floor(self.pig_state.kill_count * 0.8)
    self.pig_state.alive = false
    self:Unsummon()  -- 面板显示关闭
    self:SetEnabFalse("pig_coin")
    self:_SyncControlsToReplica()
end

-- ============================================
-- 领袖关联
-- ============================================

function Devourer:UpdateLeader(owner)
    if not (self.pig_state.pig and self.pig_state.pig:IsValid()) then return end
    if owner and owner.components.leader then
        owner.components.leader:AddFollower(self.pig_state.pig)
    else
        self:Unsummon(true)  -- 卸装保留标志，重装备自动恢复
    end
end

-- ============================================
-- 召唤 / 召回
-- ============================================

function Devourer:Summon(synctoreplica)
    if self.pig_state.pig and self.pig_state.pig:IsValid() then return end
    self.pig_state.alive = true
    local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner
    if not self.pig_state.spawn_task then
        self.pig_state.spawn_task = self.inst:DoPeriodicTask(1, function()
            TrySpawnPig(self.inst, self, owner)
        end, 0)
    end
    self.control_switch.PigSummon = 2
    self:CancelPigHealthRegen()
    if synctoreplica then
        self:_SyncControlsToReplica()
    end
end

function Devourer:Unsummon(keep_flag)
    local pig = self.pig_state.pig
    if pig and pig:IsValid() and not IsEntityDead(pig) then
        self.pig_state.health = pig.components.health.currenthealth
        self.pig_state.max_health = pig.components.health.maxhealth
        self.pig_state.name = pig.displayname or self.pig_state.name
        self.pig_state.variation = pig.pig_variation or self.pig_state.variation
        SavePigHat(self)
        pig._should_despawn = true
        if self.pig_state.health < self.pig_state.max_health then
            self:StartPigHealthRegen()
        end
    else
        self.pig_state.health = nil
    end
    if not keep_flag then
        self.control_switch.PigSummon = 1
    end
    self.pig_state.pig = nil
end

function Devourer:ChangePigSummon(value)
    if value == 2 then
        if self.pig_state.alive == false then
            return STRINGS.DP_DevourerPack.PIG_SUMMON.death
        end
        if not (self.stats and self.stats.fightpig) then
            return STRINGS.DP_DevourerPack.PIG_SUMMON.disabled
        end
    end
    if self.pig_state.pig and self.pig_state.pig:IsValid() and value == 1 then
        self:Unsummon()
    elseif value == 2 and self.pig_state.pig == nil then
        self:Summon()
    end
end

-- ============================================
-- 猪人血量恢复（召回后）
-- ============================================

function Devourer:StartPigHealthRegen()
    if self.pig_state.health_regen_task
        or (self.pig_state.health and self.pig_state.health >= self.pig_state.max_health) then
        return
    end
    self.pig_state.health_regen_task = self.inst:DoPeriodicTask(60, function()
        if not self.pig_state.health then return end
        local regen_amount = self.pig_state.max_health * 0.05
        self.pig_state.health = math.min(self.pig_state.health + regen_amount, self.pig_state.max_health)
        if self.pig_state.health >= self.pig_state.max_health then
            self:CancelPigHealthRegen()
        end
    end)
end

function Devourer:CancelPigHealthRegen()
    if self.pig_state.health_regen_task then
        self.pig_state.health_regen_task:Cancel()
        self.pig_state.health_regen_task = nil
    end
end

end -- 返回的函数结束

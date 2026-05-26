-- 吞噬者背包 - 猪人管理模块（Mixin）
-- 通过 devourer.lua 入口加载：require("components/devourer/pig")(Devourer)

local add_utils = require("utils/add_utils")
local pig_config = require("configs/pig_config")

return function(Devourer)

-- ============================================
-- 局部辅助函数
-- ============================================

local function SyncLevelExp(self)
    local lv = self:GetPigLevel(self.pig_state.total_exp)
    self.pig_state.level_exp = self.pig_state.total_exp - (pig_config._cum_exp[lv] or 0)
end

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

local function LinkPig(self, pig, owner)
    if not (pig and pig:IsValid()) then return end

    -- 设置名字（持久化）
    if self.pig_state.name then
        pig.components.named:SetName(self.pig_state.name)
    else
        local names = pig_config.pig_names
        self.pig_state.name = names[math.random(#names)]
        pig.components.named:SetName(self.pig_state.name)
    end

    pig:ProcessKill(true, self.pig_state.total_exp)

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
    self.inst:ListenForEvent("onhitother", self._onpighit, pig)
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
    local cum = pig_config._cum_exp
    for lv = pig_config.growth.max_level, 2, -1 do
        if count > cum[lv] then return lv end
    end
    return pig_config.growth.max_level
end

function Devourer:IsPigLevelUp(oldCount, newCount)
    return self:GetPigLevel(oldCount) < self:GetPigLevel(newCount)
end

-- 获取单个突破条件的当前进度
local function GetBreakthroughProgress(ps, cond)
    if cond.type == "boss_kill" then
        -- 种类判定：boss_kill_list 去重计数
        local count = 0
        for _ in pairs(ps.boss_kill_list or {}) do count = count + 1 end
        return count
    elseif cond.type == "eat_favorite_count" then
        -- 种类判定：eat_favorite_types 去重计数
        local count = 0
        for _ in pairs(ps.eat_favorite_types or {}) do count = count + 1 end
        return count
    else
        return ps[cond.type] or 0
    end
end

-- 检查等级突破条件
function Devourer:CheckBreakthrough(target_level)
    local bt = pig_config.level_breakthrough[target_level]
    if not bt then return true end
    for _, cond in ipairs(bt.conditions) do
        local current = GetBreakthroughProgress(self.pig_state, cond)
        if current < cond.count then
            local desc_key = cond.desc or ""
            local desc = STRINGS.DEVOURER_PIG_MESSAGES[desc_key] or desc_key
            return false, string.format(desc, current .. "/" .. cond.count)
        end
    end
    return true
end

-- 30级后无限成长：超出经验每N点+1血上限
local function GetInfiniteBonusHP(count)
    local max_exp = pig_config._cum_exp[pig_config.growth.max_level]
    if not pig_config.infinite_growth.enabled or count <= max_exp then return 0 end
    return math.floor((count - max_exp) / pig_config.infinite_growth.exp_per_hp)
end

-- ============================================
-- 猪人经验与升级
-- ============================================

function Devourer:PigEat(pig, food)
    local oldCount = self.pig_state.total_exp
    self.pig_state.total_exp = self.pig_state.total_exp + 1
    local newCount = self.pig_state.total_exp

    if self:IsPigLevelUp(oldCount, newCount) then
        local newLevel = self:GetPigLevel(newCount)
        if not self:CheckBreakthrough(newLevel) then
            self.pig_state.total_exp = oldCount
            SyncLevelExp(self)
            return false
        end
    end

    SyncLevelExp(self)
    self.pig_state.eat_count = (self.pig_state.eat_count or 0) + 1
    if food and pig_config.growth.favorite_foods[food.prefab] then
        self.pig_state.eat_favorite_count = (self.pig_state.eat_favorite_count or 0) + 1
        self.pig_state.eat_favorite_types = self.pig_state.eat_favorite_types or {}
        self.pig_state.eat_favorite_types[food.prefab] = true
    end

    pig:ProcessKill(true, self.pig_state.total_exp)
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
    local oldCount = self.pig_state.total_exp
    local hp = victim.components.health.maxhealth
    local atk = (victim.components.combat and victim.components.combat.defaultdamage) or 20
    local is_boss = victim:HasTag("epic")

    -- 动态击杀经验
    local cfg = pig_config.growth
    local hp_factor = math.pow(hp / 100, cfg.kill_exp_hp_pow)
    local atk_factor = math.pow(atk / 20, cfg.kill_exp_atk_pow)
    local boss_factor = is_boss and cfg.kill_exp_boss_multiplier or 1
    local addKill = math.min(math.floor(cfg.kill_exp_base * hp_factor * atk_factor * boss_factor), cfg.kill_exp_max)

    self.pig_state.total_exp = self.pig_state.total_exp + addKill
    local newCount = self.pig_state.total_exp
    SyncLevelExp(self)

    -- 宠物统计
    self.pig_state.total_kills = (self.pig_state.total_kills or 0) + 1
    if hp >= 200 then self.pig_state.kill_elite = (self.pig_state.kill_elite or 0) + 1 end
    if hp >= 800 then self.pig_state.kill_large = (self.pig_state.kill_large or 0) + 1 end

    if is_boss then
        self.pig_state.level_up_monsters[prefab] = (self.pig_state.level_up_monsters[prefab] or 0) + 1
        self.pig_state.boss_kill = (self.pig_state.boss_kill or 0) + 1
        self.pig_state.boss_kill_list[prefab] = true
        if not self.pig_state._boss_hit_set then self.pig_state._boss_hit_set = {} end
        if not self.pig_state._boss_hit_set[victim.GUID] then
            self.pig_state._boss_hit_set[victim.GUID] = true
            self.pig_state.boss_assist = (self.pig_state.boss_assist or 0) + 1
        end
        if pig_config.planar_boss_list[victim.prefab] then
            self.pig_state.planar_boss = (self.pig_state.planar_boss or 0) + 1
        end
    end

    -- 等级突破条件检查
    if self:IsPigLevelUp(oldCount, newCount) then
        local newLevel = self:GetPigLevel(newCount)
        if not self:CheckBreakthrough(newLevel) then
            local oldLevel = self:GetPigLevel(oldCount)
            self.pig_state.total_exp = pig_config._cum_exp[oldLevel + 1] or pig_config._cum_exp[pig_config.growth.max_level]
            SyncLevelExp(self)
        end
    end

    inst:ProcessKill(false, self.pig_state.total_exp)
end

function Devourer:PigDeath()
    TheNet:Announce(pig_config.dialogue.death)
    local current_level = self:GetPigLevel(self.pig_state.total_exp)
    if current_level <= 1 then
        self.pig_state.total_exp = 0
    else
        local new_level = current_level - 1
        self.pig_state.total_exp = pig_config._cum_exp[new_level] or 0
    end
    SyncLevelExp(self)
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
    self:StartPigSurvivalTimer()
    if synctoreplica then
        self:_SyncControlsToReplica()
    end
end

function Devourer:Unsummon(keep_flag)
    local pig = self.pig_state.pig
    if pig and pig:IsValid() and not IsEntityDead(pig) then
        self.pig_state.health = pig.components.health.currenthealth
        self.pig_state.max_health = pig.components.health.maxhealth
        self.pig_state.name = self.pig_state.name
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
    self:CancelPigSurvivalTimer()
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

-- 生存计时（每120秒+5经验，+1生存天数）
function Devourer:StartPigSurvivalTimer()
    if self.pig_state._survival_watcher_set then return end
    self.pig_state._survival_watcher_set = true
    self.inst:WatchWorldState("cycles", function(inst, cycles)
        local pig = self.pig_state.pig
        if not (pig and pig:IsValid() and not IsEntityDead(pig)) then return end
        if cycles == self.pig_state._last_survival_cycle then return end
        self.pig_state._last_survival_cycle = cycles
        local oldCount = self.pig_state.total_exp
        self.pig_state.total_exp = self.pig_state.total_exp + pig_config.growth.survival_exp
        if self:IsPigLevelUp(oldCount, self.pig_state.total_exp) then
            local newLevel = self:GetPigLevel(self.pig_state.total_exp)
            if not self:CheckBreakthrough(newLevel) then
                local oldLevel = self:GetPigLevel(oldCount)
                self.pig_state.total_exp = pig_config._cum_exp[oldLevel + 1] or pig_config._cum_exp[pig_config.growth.max_level]
            end
        end
        SyncLevelExp(self)
        self.pig_state.survival_days = (self.pig_state.survival_days or 0) + 1
        pig:ProcessKill(true, self.pig_state.total_exp)
        if pig.components.talker then
            pig.components.talker:Say(
                string.format(STRINGS.DEVOURER_PIG_MESSAGES.SURVIVAL_EXP, pig_config.growth.survival_exp))
        end
    end)
end

function Devourer:CancelPigSurvivalTimer()
    -- WatchWorldState 无需取消，仅在 Unsummon 时清空追踪状态
    self.pig_state._last_survival_cycle = nil
end

end -- 返回的函数结束

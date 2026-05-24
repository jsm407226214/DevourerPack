-- 标签优化系统（摘抄自能力勋章）
-- 采用标签拦截 + net_bool 存储方式，优化 mod 内标签管理，减轻服务器/客户端压力

local add_utils = require("utils/add_utils")

local DEVOURER_TAG_KEY = "devourer_tag"
local DevourerTags = {}
local HashToTags = {}

if TUNING.DevourerTagReg == nil then
    TUNING.DevourerTagReg = {}
end

local function RegDevourerTag(tag)
    tag = string.lower(tag)
    if not TUNING.DevourerTagReg[tag] then
        TUNING.DevourerTagReg[tag] = DEVOURER_TAG_KEY
        DevourerTags[tag] = true
        HashToTags[hash(tag)] = tag
    end
end

-- 注册需要优化的标签（仅 HasTag 类查询的标签，FindEntities 等不适用）
local devourer_used_tags = {
    "overlord",
    "moonstormevent_detector",
    "ghost_ally",
    "master_crewman",
    "stronggrip",
    "fastbuilder",
    "shadowdominance",
}

for _, tag in ipairs(devourer_used_tags) do
    RegDevourerTag(tag)
end

local function OverrideTagMethods(inst)
    inst[DEVOURER_TAG_KEY] = {
        AddTag = inst.AddTag,
        RemoveTag = inst.RemoveTag,
        HasTag = inst.HasTag,
        HasTags = inst.HasTags,
        HasOneOfTags = inst.HasOneOfTags,
        AddOrRemoveTag = inst.AddOrRemoveTag,
        Tags = {},
    }

    inst.AddTag = function(self, stag, ...)
        if not self or not stag then return end
        local tag = type(stag) == "number" and HashToTags[stag] or string.lower(stag)
        if DevourerTags[tag] then
            if self[DEVOURER_TAG_KEY].Tags[tag] then
                self[DEVOURER_TAG_KEY].Tags[tag]:set_local(false)
                self[DEVOURER_TAG_KEY].Tags[tag]:set(true)
            end
        else
            return self[DEVOURER_TAG_KEY].AddTag(self, stag, ...)
        end
    end

    inst.RemoveTag = function(self, stag, ...)
        if not self or not stag then return end
        local tag = type(stag) == "number" and HashToTags[stag] or string.lower(stag)
        if DevourerTags[tag] then
            if self[DEVOURER_TAG_KEY].Tags[tag] then
                self[DEVOURER_TAG_KEY].Tags[tag]:set_local(true)
                self[DEVOURER_TAG_KEY].Tags[tag]:set(false)
            end
        else
            return self[DEVOURER_TAG_KEY].RemoveTag(self, stag, ...)
        end
    end

    inst.HasTag = function(self, stag, ...)
        if not self or not stag then return false end
        local tag = type(stag) == "number" and HashToTags[stag] or string.lower(stag)
        if DevourerTags[tag] and self[DEVOURER_TAG_KEY].Tags[tag] then
            return self[DEVOURER_TAG_KEY].Tags[tag]:value()
        else
            return self[DEVOURER_TAG_KEY].HasTag(self, stag, ...)
        end
    end

    inst.HasTags = function(self, ...)
        local tags = type(...) == "table" and ... or { ... }
        for _, tag in ipairs(tags) do
            if not self:HasTag(tag) then return false end
        end
        return true
    end

    inst.HasOneOfTags = function(self, ...)
        local tags = type(...) == "table" and ... or { ... }
        for _, tag in ipairs(tags) do
            if self:HasTag(tag) then return true end
        end
        return false
    end

    inst.HasAllTags = inst.HasTags
    inst.HasAnyTag = inst.HasOneOfTags

    inst.AddOrRemoveTag = function(self, stag, condition, ...)
        if not self or not stag then return end
        local tag = type(stag) == "number" and HashToTags[stag] or string.lower(stag)
        if DevourerTags[tag] then
            if condition then self:AddTag(tag, ...)
            else self:RemoveTag(tag, ...) end
        else
            return self[DEVOURER_TAG_KEY].AddOrRemoveTag(self, stag, condition, ...)
        end
    end

    for tag, _ in pairs(DevourerTags) do
        inst[DEVOURER_TAG_KEY].Tags[tag] = net_bool(
            inst.GUID,
            DEVOURER_TAG_KEY .. "." .. tag,
            DEVOURER_TAG_KEY .. "." .. tag .. "dirty"
        )
        if inst[DEVOURER_TAG_KEY].HasTag(inst, tag) then
            inst[DEVOURER_TAG_KEY].RemoveTag(inst, tag)
            inst[DEVOURER_TAG_KEY].Tags[tag]:set(true)
        else
            inst[DEVOURER_TAG_KEY].Tags[tag]:set(false)
        end
    end
end

AddPlayerPostInit(function(inst)
    OverrideTagMethods(inst)
end)

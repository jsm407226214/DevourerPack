--@author: 绯世行
--欢迎其他开发者直接使用，但是强烈谴责搬用代码后对搬用代码加密的行为！
--使用案例及最新版：https://n77a3mjegs.feishu.cn/docx/K9bUdpb5Qo85j2xo8XkcOsU1nuh?from=from_copylink

--初始化一些数据结构

local FN = {}
local _source = debug.getinfo(1, 'S').source
local KEY = "_" .. _source:match(".*scripts[/\\](.*)%.lua"):gsub("[/\\]", "_") .. "_"
local Utils = require(_source:match(".*scripts[/\\](.*[/\\])") .. "utils")

--- 修复Inventory的GetItemsWithTag方法bug，无法正确获取手上物品
function FN.RepairInventoryGetItemsWithTag()
    local Inventory = require("components/inventory")
    function Inventory:GetItemsWithTag(tag)
        local items = {}
        for k, v in pairs(self.itemslots) do
            if v and v:HasTag(tag) then
                table.insert(items, v)
            end
        end

        if self.activeitem and self.activeitem:HasTag(tag) then
            table.insert(items, self.activeitem) --修复这里
        end

        local overflow = self:GetOverflowContainer()
        if overflow ~= nil then
            local overflow_items = overflow:GetItemsWithTag(tag)
            for _, item in ipairs(overflow_items) do
                table.insert(items, item)
            end
        end

        return items
    end
end

---添加方法AddToHistoryCanRepeat(sender_name, message, colour, icondata, ...)，使其支持图标的同时还能显示重复内容
function FN.ChatHistoryAddToHistoryCanRepeat()
    function ChatHistory:AddToHistoryCanRepeat(sender_name, message, colour, icondata, ...)
        local old = self.NPC_CHATTER_MAX_CHAT_NO_DUPES
        self.NPC_CHATTER_MAX_CHAT_NO_DUPES = 0 --移除对重复内容的判断

        self:AddToHistory(ChatTypes.ChatterMessage, nil, nil, sender_name, message, colour, icondata, ...)

        self.NPC_CHATTER_MAX_CHAT_NO_DUPES = old
    end
end

local tempTagKey = "_tempTags"

---监听标签的添加和移除，并添加AddTempTag和RemoveTempTag两个方法支持临时标签
function FN.AddTempTagMethod()
    Utils.FnDecorator(EntityScript, "RemoveTag", function(self, tag)
        local tags = self[tempTagKey]
        if not tags or not tags[tag] then return end

        if tags[tag].isForbidRemove then return nil, true end

        tags[tag] = nil
        if GetTableSize(tags) <= 0 then
            self[tempTagKey] = nil
        end
    end)

    ---添加临时标签
    ---@param isForbidRemove boolean|nil 是否禁止使用RemoveTag移除该标签，默认为false，为true时只能使用RemoveTempTag来移除标签
    function EntityScript:AddTempTag(tag, isForbidRemove)
        self[tempTagKey] = self[tempTagKey] or {}
        self[tempTagKey][tag] = { isForbidRemove = isForbidRemove }
        self:AddTag(tag)
    end

    function EntityScript:RemoveTempTag(tag)
        local d = self[tempTagKey] and self[tempTagKey][tag]
        if d then
            d.isForbidRemove = nil
            self:RemoveTag(tag)
        end
    end
end

----------------------------------------------------------------------------------------------------

--- 使含有drawable组件的物品（比如小木牌、画框）支持显示mod物品，要求是inventoryimages目录下的
function FN.RegisterDrawable()
    local MOD_ITEM_PRE = "images/inventoryimages/"
    local Drawable = require("components/drawable")
    Utils.FnDecorator(Drawable, "OnDrawn", nil,
        function(retTab, self, imagename, imagesource, atlasname)
            if atlasname and string.match(atlasname, "^" .. MOD_ITEM_PRE) then --非mod物品一般atlasname为空，而且也不可能有inventoryimages目录
                self.inst.AnimState:OverrideSymbol("SWAP_SIGN",
                    resolvefilepath(MOD_ITEM_PRE .. imagename .. ".xml"), imagename .. ".tex")
            end
        end)
end

local COMPONENT_ACTIONS = Utils.ChainFindUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS")
    or Utils.ChainFindUpvalue(EntityScript.IsActionValid, "COMPONENT_ACTIONS")

--- 修复preventunequipping的bug，当给equippable.preventunequipping设置为true让装备无法脱下时，鼠标拿取法杖仍能施法，但是施法后法杖跑到坐标原
--- 点，相当于直接消失了，这里禁止施法
function FN.FixPreventUnequipping()
    if COMPONENT_ACTIONS then
        --禁止施法
        Utils.FnDecorator(COMPONENT_ACTIONS.POINT, "spellcaster", function(inst, doer, pos, actions, right)
            local item = doer.replica.inventory and doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if item and item ~= inst and item.replica.equippable and item.replica.equippable:ShouldPreventUnequipping() then
                return nil, true
            end
        end)
    else
        -- print("获取不到COMPONENT_ACTIONS，preventunequipping和法杖的冲突修复失败")
    end
end

return FN

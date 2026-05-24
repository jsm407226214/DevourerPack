-- UI 相关补丁：护目镜黑边、容器背景缩放、灵魂物品取出限制

local add_utils = require("utils/add_utils")

-- 修复灵魂物品取出限制（客户端）
-- 问题：从吞噬者背包取出灵魂时，官方的 DesiredMaxTakeCountFunction 会限制数量
-- 解决方案：hook invslot.lua 的 OnControl 方法，绕过灵魂限制
AddClassPostConstruct("widgets/invslot", function(self)
    local old_OnControl = self.OnControl
    function self:OnControl(control, down, ...)
        -- 检查是否是点击操作
        if control == CONTROL_ACCEPT and not down then
            -- 检查是否是从吞噬者背包取出灵魂
            local container = self.container
            local container_item = self.container_item
            
            if container and container_item and container_item.prefab == "wortox_soul" then
                -- 检查容器是否是吞噬者背包
                if container.inst and container.inst.prefab == "devourer_pack" then
                    -- 直接调用取出方法，绕过数量限制
                    container:TakeActiveItemFromCountOfSlot(self.slot_number, 20)
                    TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/click_object")
                    return true
                end
            end
        end
        
        -- 默认行为
        return old_OnControl(self, control, down, ...)
    end
end)

-- 去除护目镜黑边（吞噬者背包自带夜视，不需要护目镜效果）
AddClassPostConstruct("widgets/gogglesover", function(self)
    local oldToggleGoggles = self.ToggleGoggles
    function self:ToggleGoggles(show, ...)
        if self.owner and self.owner.replica.inventory
            and self.owner.replica.inventory:EquipHasTag("devourer_pack") then
            show = false
        end
        return oldToggleGoggles(self, show, ...)
    end
end)

-- 容器背景缩放（动态背包格子时调整背景尺寸）
local function BGReScale(self, widget)
    if widget.bgshift ~= nil then
        self.bganim:SetPosition(widget.bgshift)
        self.bgimage:SetPosition(widget.bgshift)
    end
    if widget.bgscale ~= nil then
        self.bganim:SetScale(widget.bgscale)
        self.bgimage:SetScale(widget.bgscale)
    end
end

local function NEW_Open(self, container, doer, ...)
    local devourer = container.replica.devourer
    if devourer == nil then return end
    local widget = container.replica.container:GetWidget()
    BGReScale(self, widget)
end

AddClassPostConstruct("widgets/containerwidget", function(self)
    local OLD_Open = self.Open
    function self:Open(...)
        OLD_Open(self, ...)
        NEW_Open(self, ...)
    end
end)

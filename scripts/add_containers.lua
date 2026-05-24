local containers = require("containers")

-- ================================================
-- 吞噬者背包容器扩展
-- ================================================

--------------------------------------------------------------------------
--[[ 容器数据设定 ]]
--------------------------------------------------------------------------
local params = {}
params.devourer_pack = {
    widget = {
        slotpos = {},
        slotbg = {},
        animbank = "ui_krampusbag_2x8",
        animbuild = "ui_krampusbag_2x8",
        pos = Vector3(-5, -130, 0),
    },
    issidewidget = true,
    type = "backpack",
    openlimit = 1,
}
for y = 0, 8 do
    table.insert(params.devourer_pack.widget.slotpos, Vector3(-162, -75 * y + 240, 0))
    table.insert(params.devourer_pack.widget.slotpos, Vector3(-162 + 75, -75 * y + 240, 0))
    table.insert(params.devourer_pack.widget.slotpos, Vector3(-162 + 150, -75 * y + 240, 0))
    table.insert(params.devourer_pack.widget.slotpos, Vector3(-162 + 225, -75 * y + 240, 0))
end

--------------------------------------------------------------------------
--[[ 布局注册到容器里面，就是把2x2,3x3什么的布局和对应的key绑定在一起，key不能重复，否则会报错 ]]
--------------------------------------------------------------------------
for k, v in pairs(params) do
    containers.params[k] = v
    --更新容器格子数量的最大值
    containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, 36)
end
params = nil

--------------------------------------------------------------------------
--[[ 调整融合背包布局下,大于14格的排列 ]]
--------------------------------------------------------------------------

-- 布局参数定义
local W = 68 -- 格子宽度，用于计算对齐点
local SEP = 12 -- 水平间距，用于计算格子间距
local YSEP = 8 -- 垂直间距，用于计算对齐点

-- 重建融合背包布局
-- @param self: inventorybar实例
-- @param inventory: 玩家物品栏组件
-- @param overflow: 背包容器（溢出容器）
-- @param do_integrated_backpack: 是否启用融合背包模式
-- @param equipitem: 当前装备的物品（用于检查特殊格子状态）
local function RebuildLayout(self, inventory, overflow, do_integrated_backpack, equipitem)
    if do_integrated_backpack then
        -- 获取背包总格子数
        local num = overflow:GetNumSlots()
        -- print("packslot num = ", num, ",equipslot num = ", #self.equipslotinfo, ",inv num = ", #self.inv)
        
        -- 计算可用总格子数：物品栏 + 装备栏
        local total_available_slots = #self.inv + #self.equipslotinfo
        
        -- 计算是否需要第三行
        local need_third_row = num > total_available_slots
        
        -- -- 第三行的Y坐标偏移
        -- local third_row_y = W + SEP + YSEP -- 低于现有两行
        
        -- 遍历每个背包格子
        for k = 1, num do
            -- 获取当前背包格子
            local slot = self.backpackinv[k]

            -- 设置格子的顶部对齐点
            -- 确保所有格子在垂直方向上对齐一致
            slot.top_align_tip = W * 1.5 + YSEP * 2

            if k <= #self.inv then
                -- 前#self.inv个格子：与物品栏对齐（第一行）
                slot:SetPosition(
                    self.inv[k]:GetPosition().x, -- 使用物品栏对应位置的x坐标
                    0, -- y坐标固定为0
                    0
                )
            elseif k <= total_available_slots then
                -- 接下来的#self.equipslotinfo个格子：与装备栏对齐（第二行）
                local extra_slot = k - #self.inv
                local equipslotinfo = self.equipslotinfo[extra_slot]
                slot:SetPosition(
                    self.equip[equipslotinfo.slot]:GetPosition().x, -- 使用装备栏对应位置的x坐标
                    0, -- y坐标固定为0
                    0
                )
            else
                -- 超出的格子：使用第三行
                local third_row_slot = k - total_available_slots
                local x
                
                if third_row_slot <= #self.inv then
                    -- 第三行前#self.inv个格子：使用物品栏对应位置的x坐标
                    x = self.inv[third_row_slot]:GetPosition().x
                else
                    -- 第三行超出物品栏的格子：使用装备栏对应位置的x坐标
                    local extra_equip_slot = third_row_slot - #self.inv
                    if extra_equip_slot <= #self.equipslotinfo then
                        local equipslotinfo = self.equipslotinfo[extra_equip_slot]
                        x = self.equip[equipslotinfo.slot]:GetPosition().x
                    else
                        -- 如果还不够，继续从物品栏开始循环
                        local loop_slot = (third_row_slot - 1) % (#self.inv + #self.equipslotinfo) + 1
                        if loop_slot <= #self.inv then
                            x = self.inv[loop_slot]:GetPosition().x
                        else
                            local loop_equip_slot = loop_slot - #self.inv
                            local equipslotinfo = self.equipslotinfo[loop_equip_slot]
                            x = self.equip[equipslotinfo.slot]:GetPosition().x
                        end
                    end
                end
                
                slot:SetPosition(
                    x, -- 计算第三行的x坐标
                    -75, -- y坐标为第三行位置
                    0
                )
            end

        end

        -- 如果需要第三行，调整背景和布局位置
        if need_third_row then
            -- -- 调整背景位置以容纳第三行
            self.bg:SetPosition(0, 50) -- 向上移动背景
            -- self.bgcover:SetPosition(0, 55) -- 向下移动背景覆盖
            
            -- -- 调整顶部行和底部行的位置
            self.toprow:SetPosition(0, 115) -- 向上移动顶部行
            self.bottomrow:SetPosition(0, 40) -- 中间行
        end

        -- 融合模式下显示最后四个特殊格子
        -- 获取背包的devourer组件，用于检查特殊格子是否启用
        local devourer = equipitem and equipitem.replica and equipitem.replica.devourer
        if devourer then
            local num_slots = overflow:GetNumSlots()
            local repair_slot = num_slots       -- 倒数第1个格子，预留给修理格，1级效果
            local heating_slot = num_slots - 1  -- 倒数第2个格子，预留给加热格，2级效果
            local cooling_slot = num_slots - 2  -- 倒数第3个格子，预留给制冷格，3级效果
            local alchemy_slot = num_slots - 3  -- 倒数第4个格子，预留给背包格子满级解锁，转换格子，隐藏的4级效果
            
            -- 获取特殊格子的启用状态
            local lv_x, lv_y, lv_fire, lv_ice, lv_repair = devourer:GetSlot()
            local packlv = devourer.packlv
            
            -- 设置特殊格子背景
            for k = 1, num_slots do
                local slot = self.backpackinv[k]
                if slot then
                    -- 尝试不同的属性名来设置背景图像
                    local bg_element = slot.bg or slot.background or slot.bgimage or slot.image
                    -- 打印slot对象的属性，以便确定正确的属性名
                    print("DevourerPack: Slot properties for slot " .. k .. ":")
                    for key, value in pairs(slot) do
                        if type(value) ~= "function" then
                            print("  " .. key .. ": " .. tostring(value))
                        else
                            print("  " .. key .. ": [function]")
                        end
                    end
                    if bg_element and bg_element.SetTexture then
                        -- 重置背景
                        bg_element:SetTexture("images/ui.xml", "inv_slot.tex")
                        
                        -- 修复格：等级>=1并且repair>=1
                        if k == repair_slot and packlv.level >= 1 and lv_repair >= 1 then
                            bg_element:SetTexture("images/slot_bg_tool.xml", "slot_bg_tool.tex")
                        -- 加热格：等级>=2并且fire>=1
                        elseif k == heating_slot and packlv.level >= 2 and lv_fire >= 1 then
                            bg_element:SetTexture("images/slot_bg_fire.xml", "slot_bg_fire.tex")
                        -- 冰冻格：等级>=3并且ice>=1
                        elseif k == cooling_slot and packlv.level >= 3 and lv_ice >= 1 then
                            bg_element:SetTexture("images/slot_bg_snow.xml", "slot_bg_snow.tex")
                        -- 炼金格：背包达到最大格子，等级达到3级，特殊格子效果全部解锁时显示
                        elseif k == alchemy_slot and lv_x == 3 and devourer.packlv.level == 3 and lv_fire >= 1 and lv_ice >= 1 and lv_repair >= 3 then
                            bg_element:SetTexture("images/slot_bg_alchemy.xml", "slot_bg_alchemy.tex")
                        end
                    else
                        -- 如果没有找到背景元素，输出调试信息
                        print("Warning: Could not find background element for slot ", k)
                    end
                end
            end
        end
    end

end

AddGlobalClassPostConstruct("widgets/inventorybar", "Inv", function(self)
    local old_Rebuild = self.Rebuild
    self.Rebuild = function(self)
        local inventory = self.owner.replica.inventory
        local overflow = inventory and inventory:GetOverflowContainer()
        overflow = (overflow ~= nil and overflow:IsOpenedBy(self.owner)) and overflow or nil
        local equipitem = self.owner.replica.inventory and self.owner.replica.inventory:GetEquippedItem(EQUIPSLOTS.BACK or EQUIPSLOTS.PACK or EQUIPSLOTS.BODY)
        old_Rebuild(self)
        if equipitem and equipitem.prefab == "devourer_pack" and Profile:GetIntegratedBackpack() and overflow then
            RebuildLayout(self, inventory, overflow, true, equipitem)
        end
    end
end)

--------------------------------------------------------------------------
--[[ 调整容器优先级 ]]
--------------------------------------------------------------------------
local function FindBestContainer(self, item, containers, exclude_containers)
    if item == nil or containers == nil then
        return
    end

    --Construction containers
    --NOTE: reusing containerwithsameitem variable
    local containerwithsameitem = self.owner ~= nil and self.owner.components.constructionbuilderuidata ~= nil and self.owner.components.constructionbuilderuidata:GetContainer() or nil
    if containerwithsameitem ~= nil then
        if containers[containerwithsameitem] ~= nil and (exclude_containers == nil or not exclude_containers[containerwithsameitem]) then
            local slot = self.owner.components.constructionbuilderuidata:GetSlotForIngredient(item.prefab)
            if slot ~= nil then
                local container = containerwithsameitem.replica.container
                if container ~= nil and container:CanTakeItemInSlot(item, slot) then
                    local existingitem = container:GetItemInSlot(slot)
                    if existingitem == nil or (container:AcceptsStacks() and existingitem.replica.stackable ~= nil and not existingitem.replica.stackable:IsFull()) then
                        return containerwithsameitem
                    end
                end
            end
        end
        containerwithsameitem = nil
    end

    --local containerwithsameitem = nil --reused with construction containers code above
    local containerwithemptyslot
    local containerwithnonstackableslot
    local current_container = self.container.inst
    for k, v in pairs(containers) do
        if current_container ~= k then
            local container = k.replica.container or k.replica.inventory
            if container ~= nil and container:CanTakeItemInSlot(item) then
                local isfull = container:IsFull()
                if container:AcceptsStacks() then
                    if not isfull and containerwithemptyslot == nil and (exclude_containers == nil or not exclude_containers[k]) then
                        containerwithemptyslot = k
                    end
                    if item.replica.equippable ~= nil and container == k.replica.inventory then
                        local equip = container:GetEquippedItem(item.replica.equippable:EquipSlot())
                        if equip ~= nil and equip.prefab == item.prefab and equip.skinname == item.skinname then
                            if equip.replica.stackable ~= nil and not equip.replica.stackable:IsFull() then
                                return k
                            elseif not isfull and (containerwithsameitem == nil or exclude_containers and exclude_containers[containerwithsameitem] and not exclude_containers[k]) then
                                containerwithsameitem = k
                            end
                        end
                    end
                    for _, v1 in pairs(container:GetItems()) do
                        if v1.prefab == item.prefab and v1.skinname == item.skinname then
                            if (not isfull or v1.replica.stackable ~= nil and not v1.replica.stackable:IsFull()) and (containerwithsameitem == nil or exclude_containers and exclude_containers[containerwithsameitem] and not exclude_containers[k]) then
                                containerwithsameitem = k
                                break
                            end
                        end
                    end
                elseif not isfull and containerwithnonstackableslot == nil and (exclude_containers == nil or not exclude_containers[k]) then
                    containerwithnonstackableslot = k
                end
            end
        end
    end

    local isBodyContainer = containerwithemptyslot and containerwithemptyslot.replica.inventoryitem and containerwithemptyslot.replica.inventoryitem:IsGrandOwner(ThePlayer)
    if exclude_containers and exclude_containers[containerwithsameitem] and not isBodyContainer then
        return containerwithnonstackableslot or containerwithemptyslot or containerwithsameitem
    end

    local container = containerwithnonstackableslot and containerwithnonstackableslot.replica.container

    local isInBody = containerwithnonstackableslot and containerwithnonstackableslot.replica.inventoryitem and containerwithnonstackableslot.replica.inventoryitem:IsGrandOwner(ThePlayer)

    if isInBody and container and container.usespecificslotsforitems and (containerwithemptyslot or containerwithsameitem) then
        containerwithnonstackableslot = nil
    end

    return containerwithnonstackableslot or containerwithsameitem or containerwithemptyslot
end

local function TradeItem(self, stack_mod)
    local slot_number = self.num
    local character = ThePlayer
    local inventory = character and character.replica.inventory or nil
    local container = self.container
    local container_item = container and container:GetItemInSlot(slot_number) or nil

    if character ~= nil and inventory ~= nil and container_item ~= nil then
        local opencontainers = inventory:GetOpenContainers()
        if next(opencontainers) == nil then
            return
        end
        local devourer_container = {}
        for k in pairs(opencontainers) do
            if k:HasTag("devourer_pack") or k.replica.inventoryitem and k.replica.inventoryitem:IsGrandOwner(character) then
                devourer_container[k] = true
            end
        end
        if next(devourer_container) then
            local overflow = inventory:GetOverflowContainer()
            local backpack
            if overflow ~= nil and overflow:IsOpenedBy(character) then
                backpack = overflow.inst
                overflow = backpack.replica.container
                if overflow == nil then
                    backpack = nil
                end
            else
                overflow = nil
            end

            --find our destination container
            local dest_inst
            if container == inventory then
                local playercontainers = backpack ~= nil and { [backpack] = true } or nil
                if backpack ~= nil then
                    devourer_container[backpack] = true
                end
                dest_inst = FindBestContainer(self, container_item, opencontainers, devourer_container)
                        or FindBestContainer(self, container_item, devourer_container, playercontainers)
                        or FindBestContainer(self, container_item, playercontainers)
            elseif container == overflow then
                if backpack ~= nil then
                    devourer_container[backpack] = true
                end
                dest_inst = FindBestContainer(self, container_item, opencontainers, devourer_container)
                        or FindBestContainer(self, container_item, devourer_container, { [backpack] = true })
                        or (inventory:IsOpenedBy(character) and FindBestContainer(self, container_item, { [character] = true }) or nil)
            else
                local exclude_containers = { [container.inst] = true }
                devourer_container[container.inst] = true
                if backpack ~= nil then
                    exclude_containers[backpack] = true
                    devourer_container[backpack] = true
                end
                dest_inst = FindBestContainer(self, container_item, opencontainers, devourer_container)
                        or inventory:IsOpenedBy(character) and FindBestContainer(self, container_item, { [character] = true })
                        or backpack ~= nil and FindBestContainer(self, container_item, { [backpack] = true })
                        or FindBestContainer(self, container_item, devourer_container, exclude_containers)
            end

            --if a destination container/inv is found...
            if dest_inst ~= nil then
                if stack_mod and
                        container_item.replica.stackable ~= nil and
                        container_item.replica.stackable:IsStack() then
                    container:MoveItemFromHalfOfSlot(slot_number, dest_inst)
                else
                    container:MoveItemFromAllOfSlot(slot_number, dest_inst)
                end
                TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/click_object")
            else
                TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/click_negative")
            end

        else
            self:Devourer_TradeItem(stack_mod)
        end
    end
end
-- 重写快捷移动功能，目前不知道为什么在背包关闭的时候，快捷移动不了
AddClassPostConstruct("widgets/invslot", function(self)
    self.Devourer_TradeItem = self.TradeItem
    self.TradeItem = TradeItem
end)

--设置箱子的默认类型为prefab
local function container(self)
    self.inst:DoTaskInTime(0, function()
        if self.inst and not self.type then
            removesetter(self, "type")
            self.type = self.inst.prefab
            makereadonly(self, "type")
        end
    end)

    -- ================================================
    -- 修复1：处理灵魂在无限堆叠容器中的移动问题
    -- ================================================
    -- 问题：当容器启用无限堆叠时，灵魂的 originalmaxsize 被设置为 math.huge
    --       IsOverStacked() 永远返回 false，导致无法正常取出
    -- 解决方案：对于特殊物品（灵魂等），在无限堆叠模式下按默认堆叠大小取出
    --           例如：堆叠40个时取出20个，堆叠15个时取出15个，保持默认分组行为
    
    -- Hook TakeActiveItemFromCountOfSlot
    -- 问题：灵魂物品在无限堆叠容器中取出时，takecount 可能被限制为0或很小的数字
    -- 解决方案：对于吞噬者背包中的灵魂，强制设置 takecount 为默认堆叠大小（20）
    local original_TakeActiveItemFromCountOfSlot = self.TakeActiveItemFromCountOfSlot
    self.TakeActiveItemFromCountOfSlot = function(container_self, slot, count, opener)
        local item = container_self:GetItemInSlot(slot)
        if item and item.prefab == "wortox_soul" then
            local is_devourer = container_self.inst and container_self.inst.prefab == "devourer_pack"
            if is_devourer then
                local stack_size = item.components.stackable:StackSize()
                local default_max_size = 20
                count = math.min(stack_size, default_max_size)
            end
        end
        return original_TakeActiveItemFromCountOfSlot(container_self, slot, count, opener)
    end
    
    -- Hook TakeActiveItemFromAllOfSlot
    local original_TakeActiveItemFromAllOfSlot = self.TakeActiveItemFromAllOfSlot
    self.TakeActiveItemFromAllOfSlot = function(container_self, slot, opener)
        local item = container_self:GetItemInSlot(slot)
        
        if item and item.components.stackable and item.components.inventoryitem and 
           item.components.inventoryitem.canonlygoinpocketorpocketcontainers then
            
            local container_ = rawget(container_self, "_")
            if container_ and container_.infinitestacksize and container_.infinitestacksize[1] then
                local stack_size = item.components.stackable:StackSize()
                local default_max_size = 20
                local take_count = math.min(stack_size, default_max_size)
                
                local taken_stack = item.components.stackable:Get(take_count)
                taken_stack.prevslot = slot
                taken_stack.prevcontainer = container_self
                opener.components.inventory:GiveActiveItem(taken_stack)
                return
            end
        end
        
        return original_TakeActiveItemFromAllOfSlot(container_self, slot, opener)
    end

    -- ================================================
    -- 修复2：处理灵魂放入无限堆叠容器时的堆叠上限设置
    -- ================================================
    -- 问题：EnableInfiniteStackSize 只设置 maxsize = math.huge，但 originalmaxsize 仍为20
    --       IsOverStacked() 检查的是 originalmaxsize，导致灵魂仍被认为是超堆叠
    -- 解决方案：当灵魂放入启用无限堆叠的容器时，同步设置 originalmaxsize = math.huge
    -- 注意：originalmaxsize 是只读属性，必须使用 rawget 直接修改内部表
    local original_GiveItem = self.GiveItem
    self.GiveItem = function(give_item_self, item, slot, src_pos, drop_on_fail)
        -- 调用原始函数放入物品
        local result = original_GiveItem(give_item_self, item, slot, src_pos, drop_on_fail)
        
        -- 如果放入成功，且物品是需要特殊处理的物品
        if result and item and item.components.stackable and item.components.inventoryitem and 
           item.components.inventoryitem.canonlygoinpocketorpocketcontainers then
            
            -- 检查容器是否启用了无限堆叠
            local container_ = rawget(give_item_self, "_")
            if container_ and container_.infinitestacksize and container_.infinitestacksize[1] then
                -- 使用 rawget 直接修改内部存储的 originalmaxsize（只读属性不能直接赋值）
                local stackable_ = rawget(item.components.stackable, "_")
                if stackable_ then
                    local current_original_max = stackable_.originalmaxsize[1]
                    if current_original_max and current_original_max < math.huge then
                        stackable_.originalmaxsize[1] = math.huge
                    end
                end
            end
        end
        return result
    end
end
AddComponentPostInit("container", container)

---设置一下replica的type，防止宣告判断type为空当成人物物品栏来处理
local function container_replica(self)
    self.inst:DoTaskInTime(0, function()
        if self.inst and not self.type then
            self.type = self.inst.prefab
        end
    end)
end
AddClassPostConstruct("components/container_replica", container_replica)

-- ================================================
-- 修复3：让吞噬者背包中的灵魂独立于玩家物品栏上限
-- ================================================
-- 问题：官方 GetSouls() 函数会搜索玩家所有物品栏空间（包括背包）
--       导致吞噬者背包和玩家物品栏共享20个灵魂上限
-- 解决方案：Hook CheckForOverload，让物品栏和吞噬者背包独立计算上限
-- 
-- 独立上限规则：
--   - 玩家物品栏：默认20个上限（受灵魂罐加成影响）
--   - 吞噬者背包：独立计算，不受物品栏上限限制
--   - 吞噬者背包无限堆叠：灵魂可以无限堆叠
--   - 灵魂罐：保持原有逻辑，增加总上限
AddPrefabPostInit("wortox", function(inst)
    -- 仅在服务端执行
    if not TheWorld.ismastersim then return end
    
    -- 保存原始函数引用
    local original_CheckForOverload = inst.CheckForOverload
    
    -- 重写灵魂上限检查函数
    inst.CheckForOverload = function(inst, souls, count)
        -- ================================================
        -- 步骤1：分别计算物品栏和吞噬者背包中的灵魂数量
        -- ================================================
        
        -- 计算玩家物品栏中的灵魂数量（不包括背包容器）
        local inventory_soul_count = 0
        local inventory_souls = {}
        inst.components.inventory:ForEachItemSlot(function(item)
            if item.prefab == "wortox_soul" then
                table.insert(inventory_souls, item)
                inventory_soul_count = inventory_soul_count + (item.components.stackable and item.components.stackable:StackSize() or 1)
            end
        end)
        
        -- 计算吞噬者背包中的灵魂数量（独立计算）
        local devourer_soul_count = 0
        local equipped_backpack = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BACK or EQUIPSLOTS.PACK)
        if equipped_backpack and equipped_backpack.prefab == "devourer_pack" and equipped_backpack.components.container then
            -- 遍历吞噬者背包的所有格子
            for i = 1, equipped_backpack.components.container.numslots do
                local item = equipped_backpack.components.container:GetItemInSlot(i)
                if item and item.prefab == "wortox_soul" then
                    devourer_soul_count = devourer_soul_count + (item.components.stackable and item.components.stackable:StackSize() or 1)
                end
            end
        end
        
        -- ================================================
        -- 步骤2：计算物品栏的灵魂上限（保持原有逻辑）
        -- ================================================
        local max_count = TUNING.WORTOX_MAX_SOULS -- 默认20
        
        -- 如果解锁了灵魂罐技能，每个灵魂罐增加上限
        if inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated("wortox_souljar_2") then
            local souljars = 0
            inst.components.inventory:ForEachItemSlot(function(item)
                if item.prefab == "wortox_souljar" then
                    souljars = souljars + 1
                end
            end)
            -- 检查手持物品
            local activeitem = inst.components.inventory:GetActiveItem()
            if activeitem and activeitem.prefab == "wortox_souljar" then
                souljars = souljars + 1
            end
            -- 每个灵魂罐增加固定数量的上限
            max_count = max_count + souljars * TUNING.SKILLS.WORTOX.FILLED_SOULJAR_SOULCAP_INCREASE_PER
        end
        
        -- ================================================
        -- 步骤3：只对物品栏中的灵魂进行上限检查
        -- ================================================
        
        if inventory_soul_count > max_count then
            local dooverload = true
            if inst.wortox_inclination == "naughty" and not inst.wortox_souloverload_forceoverloading then
                -- 复制官方的 CreateOverloadingFX 逻辑
                if inst.wortox_souloverload_stoppertask == nil then
                    inst.wortox_souloverload_stoppertask = inst:DoTaskInTime(TUNING.SKILLS.WORTOX.NAUGHTY_OVERLOAD_STOP_TIME, function()
                        inst.wortox_souloverload_forceoverloading = true
                        local _, total_count = inst:GetSouls()
                        original_CheckForOverload(inst, nil, total_count)
                        inst.wortox_souloverload_forceoverloading = nil
                    end)
                    local overloading_fx = SpawnPrefab("wortox_overloading_fx")
                    if overloading_fx then
                        overloading_fx.entity:SetParent(inst.entity)
                        overloading_fx.Follower:FollowSymbol(inst.GUID, inst.components.combat.hiteffectsymbol, 0, 0, 0)
                        inst.wortox_souloverload_fx = overloading_fx
                    end
                    inst:PushEvent("souloverloadwarning")
                end
                dooverload = false
            end
            
            if dooverload then
                if inst._souloverloadtask then
                    inst._souloverloadtask:Cancel()
                    inst._souloverloadtask = nil
                end
                inst._souloverloadtask = inst:DoTaskInTime(TUNING.WORTOX_SOUL_HEAL_DELAY + 0.1, function()
                    inst._souloverloadtask = nil
                end)
                
                local dropcount = inventory_soul_count - math.floor(max_count / 2) + math.random(0, 2) - 1
                
                -- 只从物品栏中掉落灵魂，不影响背包
                if #inventory_souls > 0 then
                    -- 复制官方的 DropSouls 逻辑，但只对 inventory_souls 操作
                    table.sort(inventory_souls, function(a, b)
                        local a_size = a.components.stackable and a.components.stackable:StackSize() or 1
                        local b_size = b.components.stackable and b.components.stackable:StackSize() or 1
                        return a_size < b_size
                    end)
                    
                    local pos = inst:GetPosition()
                    local remaining_to_drop = dropcount
                    
                    for _, item in ipairs(inventory_souls) do
                        if remaining_to_drop <= 0 then
                            break
                        end
                        
                        local stack_size = item.components.stackable and item.components.stackable:StackSize() or 1
                        
                        if stack_size <= remaining_to_drop then
                            inst.components.inventory:DropItem(item, true, true, pos)
                            remaining_to_drop = remaining_to_drop - stack_size
                        else
                            local dropped = item.components.stackable:Get(remaining_to_drop)
                            dropped.Transform:SetPosition(pos:Get())
                            dropped.components.inventoryitem:OnDropped(true)
                            remaining_to_drop = 0
                        end
                    end
                end
                
                inventory_soul_count = inventory_soul_count - dropcount
                local sanitydelta = -TUNING.SANITY_MEDLARGE * math.ceil(dropcount / max_count)
                inst.components.sanity:DoDelta(sanitydelta)
                inst:PushEvent("souloverload")
            end
        else
            if inventory_soul_count > max_count * TUNING.WORTOX_WISECRACKER_TOOMANY then
                inst:PushEvent("soultoomany")
            end
            if inst.wortox_souloverload_stoppertask then
                -- 复制官方的 DestroyOverloadingFX 逻辑
                if inst.wortox_souloverload_stoppertask then
                    inst.wortox_souloverload_stoppertask:Cancel()
                    inst.wortox_souloverload_stoppertask = nil
                end
                if inst.wortox_souloverload_fx then
                    if inst.wortox_souloverload_fx:IsValid() then
                        inst.wortox_souloverload_fx:Remove()
                    end
                    inst.wortox_souloverload_fx = nil
                end
                inst:PushEvent("souloverloadavoided")
            end
        end
        
        -- 计算总灵魂数
        local souljar_count = 0
        inst.components.inventory:ForEachItemSlot(function(item)
            if item.prefab == "wortox_souljar" then
                souljar_count = souljar_count + (item.soulcount or 0)
            end
        end)
        local activeitem = inst.components.inventory:GetActiveItem()
        if activeitem and activeitem.prefab == "wortox_souljar" then
            souljar_count = souljar_count + activeitem.soulcount
        end
        
        inst.soulcount = inventory_soul_count + devourer_soul_count + souljar_count
    end
end)

-- ================================================
-- 修复5：重写灵魂的 DesiredMaxTakeCountFunction
-- ================================================
-- 问题：官方的函数会检查玩家所有物品栏空间的灵魂数量
--       当物品栏+背包灵魂总数 >= 20时，返回0，阻止取出
-- 解决方案：移除限制，允许自由取出

local SetDesiredMaxTakeCountFunction = GLOBAL.SetDesiredMaxTakeCountFunction

if SetDesiredMaxTakeCountFunction then
    SetDesiredMaxTakeCountFunction("wortox_soul", function(player, inventory, container_item, container)
        -- 对于吞噬者背包中的灵魂，返回默认堆叠大小
        if container and container.inst and container.inst.prefab == "devourer_pack" then
            return 20
        end
        return 20
    end)
end

-- Hook GetDesiredMaxTakeCountFunction 确保客户端也使用我们的函数
local original_GetDesiredMaxTakeCountFunction = GLOBAL.GetDesiredMaxTakeCountFunction
GLOBAL.GetDesiredMaxTakeCountFunction = function(prefab)
    return original_GetDesiredMaxTakeCountFunction(prefab)
end

-- 在客户端也注册（使用 AddPlayerPostInit）
if AddPlayerPostInit then
    AddPlayerPostInit(function(player)
        if SetDesiredMaxTakeCountFunction then
            SetDesiredMaxTakeCountFunction("wortox_soul", function(player, inventory, container_item, container)
                if container and container.inst and container.inst.prefab == "devourer_pack" then
                    return 20
                end
                return 20
            end)
        end
    end)
end
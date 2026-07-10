-- 初始化组件
local containers = require("containers")
-- local devourer_pack_upgrade = TUNING.DEVOURER_PACK_UPGRADE
local add_configs = require('configs/add_configs')
local add_utils = require('utils/add_utils')

local function OnPackLv(inst)
	local devourer = inst.replica.devourer
	local plv_json = devourer._net_devourer_plv:value()
    
    -- 记录接收到的JSON字符串
    add_utils.debug_print("[OnPackLv] 接收到的JSON:", plv_json)
    
    -- 解析JSON字符串
    local plv_data = json.decode(plv_json) or {}
    devourer.packlv = plv_data
	devourer:UpdateWidget()
end

local function OnUpgradeEffects(inst)
	local devourer = inst.replica.devourer
    local json_data = devourer._net_devourer_effects:value()
    -- local update_special_slot = false
    -- local update_count = 0
    if json_data and json_data ~= "" then
        local sync_data = json.decode(json_data) or {}
        -- 转换简写名称为原始prefab名称
        local converted_sync_data = {}
        for key, effect in pairs(sync_data) do
            -- 检查是否是简写名称
            local original_prefab = add_configs.upgrade_effects_by_short_name[key]
            if original_prefab then
                -- 使用原始prefab名称
                converted_sync_data[original_prefab] = effect
                add_utils.debug_print("[客户端] OnUpgradeEffects: 转换简写key", key, "到原始key", original_prefab)
            else
                -- 不是简写名称，直接使用
                converted_sync_data[key] = effect
                add_utils.debug_print("[客户端] OnUpgradeEffects: 直接使用原始key", key)
            end
        end
        for prefab, effect in pairs(converted_sync_data) do
            -- update_count = update_count + 1
            if devourer.upgrade_effects[prefab] then
                devourer.upgrade_effects[prefab].enab = effect.e
                if effect.c then
                    devourer.upgrade_effects[prefab].cur = effect.c
                end
            end
            -- if add_configs.slot_specical_items[prefab] and effect.e then
            --     update_special_slot = true
            -- end
            add_utils.debug_print("[客户端] OnUpgradeEffects:", prefab,",enab:", effect.e,",cur:", effect.c or "nil")
        end
        -- if update_count == 1 and update_special_slot then
        --     add_utils.debug_print("[客户端] 需要更新特殊格子显示")
        --     devourer:UpdateWidget()
        -- end
        add_utils.debug_print("[客户端] 升级数据已同步")
        -- 触发升级效果更新事件，通知控制面板刷新
        -- 直接在背包实体上触发事件，因为控制面板的监听器已经绑定到背包实体上
        -- inst:PushEvent("devourer_upgrade_effects_updated")
        -- add_utils.debug_print("[客户端] 已在背包实体上触发升级效果更新事件")
    end
end

local function OnUpgradeShows(inst)
	local devourer = inst.replica.devourer
    local json_data = devourer._net_devourer_shows:value()
    if json_data and json_data ~= "" then
        local sync_data = json.decode(json_data) or {}
        for prefab, effect in pairs(sync_data) do
            if devourer.upgrade_effects[prefab] then -- 传过来的参数没有mod和event，不能用这个判断，需要使用replica的来判断
                devourer.upgrade_effects[prefab].show = effect.s
            end
            add_utils.debug_print("[客户端] OnUpgradeShows:", prefab,",show:", devourer.upgrade_effects[prefab].show)
        end
        add_utils.debug_print("[客户端] OnUpgradeShows数据已同步")
    end
end

local function OnUpgradeControls(inst)
    local devourer = inst.replica.devourer
    local json_data = devourer._net_devourer_controls:value()
    if json_data and json_data ~= "" then
        local sync_data = json.decode(json_data) or {}
        devourer.control_switch = sync_data
        add_utils.debug_print("[客户端] 控制数据已全量同步到客户端")
    end
end

local Devourer = Class(function(self, inst)
    self.inst = inst
    self.maxlevel = 3
	self.packlv = {
        level = TUNING.DEVOURER_PACK_DEFAULT_LEVEL,
        extra_rows = 1,
        fire = 0,
        ice = 0,
        repair = 0
    }
    self.upgrade_effects = add_utils.deepcopy(add_configs.upgrade_effects)
    -- 初始化配置数据（写死，无需外部传入）
    local config_control_data = STRINGS.DEVOURER_CONTROLS or {}
    -- 存储当前值（基于default初始化）
    self.control_switch = {}
    for key, cfg in pairs(config_control_data) do
        self.control_switch[key] = cfg.default
    end
    -- 初始化event和mod状态，将从服务端同步
    self._net_devourer_plv = net_string(self.inst.GUID, "devourer.plv", "devourer_plv_dirty")
    self._net_devourer_effects = net_string(inst.GUID, "devourer.upgrade_effects", "devourer_effects_dirty")
    self._net_devourer_shows = net_string(inst.GUID, "devourer.upgrade_shows", "devourer_shows_dirty")
    self._net_devourer_controls = net_string(inst.GUID, "devourer.controls", "devourer_controls_dirty")

	if not TheWorld.ismastersim then
        inst:ListenForEvent("devourer_plv_dirty", function() OnPackLv(inst) end)
        inst:ListenForEvent("devourer_effects_dirty", function() OnUpgradeEffects(inst) end)
        inst:ListenForEvent("devourer_shows_dirty", function() OnUpgradeShows(inst) end)
        inst:ListenForEvent("devourer_controls_dirty", function() OnUpgradeControls(inst) end)
    end
end, nil, {})

function Devourer:_SyncUpgradeEffects(sync_data)
    if not sync_data or type(sync_data) ~= "table" then return end
    local string_data = json.encode(sync_data) -- 把table转成字符串，用于数据同步
    -- -- 直接修改仅本人客户端有用，但是其他玩家看不到，所以需要NetVar同步,直接改是1对1，NetVar是1对多（自己+其他玩家的客户端）
	local devourer = self.inst.replica.devourer
    -- 直接使用传入的数据更新本地表（可能包含简写名称）
    for key, effect in pairs(sync_data) do
        -- 检查是否是简写名称
        local prefab = add_configs.upgrade_effects_by_short_name[key] or key
        if devourer.upgrade_effects[prefab] then
            devourer.upgrade_effects[prefab].enab = effect.e
            if effect.c then
                devourer.upgrade_effects[prefab].cur = effect.c
            end
        end
        add_utils.debug_print("[客户端] _SyncUpgradeEffects:", prefab,",enab:", effect.e,",cur:", effect.c or "nil")
    end
    devourer._net_devourer_effects:set(string_data)
end

function Devourer:_SyncUpgradeShows(sync_data)
    if not sync_data or type(sync_data) ~= "table" then return end
    local string_data = json.encode(sync_data) -- 把table转成字符串，用于数据同步
    -- -- 直接修改仅本人客户端有用，但是其他玩家看不到，所以需要NetVar同步,直接改是1对1，NetVar是1对多（自己+其他玩家的客户端）
	local devourer = self.inst.replica.devourer
    for prefab, effect in pairs(sync_data) do
        if devourer.upgrade_effects[prefab] then -- 传过来的参数没有mod和event，不能用这个判断，需要使用replica的来判断
            devourer.upgrade_effects[prefab].show = effect.s
            add_utils.debug_print("[客户端] _SyncUpgradeShows:", prefab,",show:", effect.s)
        end
    end
    devourer._net_devourer_shows:set(string_data)
end

function Devourer:_SyncControls(sync_data)
    local string_data = json.encode(sync_data) -- 把table转成字符串，用于数据同步
    -- -- 直接修改仅本人客户端有用，但是其他玩家看不到，所以需要NetVar同步,直接改是1对1，NetVar是1对多（自己+其他玩家的客户端）
	local devourer = self.inst.replica.devourer
    devourer._net_devourer_controls:set(string_data)
end

function Devourer:CheckEnable(prefab)
    return self and self.upgrade_effects and self.upgrade_effects[prefab] and self.upgrade_effects[prefab].enab or false
end

function Devourer:Check(item)
    if TheWorld.ismastersim then
        return self.inst.components.devourer:Check(item)
    end
    -- 初始日志：记录检查开始和传入的物品信息
    add_utils.debug_print("[Replica Check] 开始检查物品是否可吞噬")
    add_utils.debug_print(string.format("  传入物品: %s", tostring(item and item.prefab or "nil")))

    -- 检查物品和升级效果表是否存在
    local upgrade_effects = self.inst.replica.devourer.upgrade_effects
    -- 原本show字段也过滤，现在去掉，因为show只是控制UI显示的，不应该影响功能判断
    if item and item.prefab and upgrade_effects and upgrade_effects[item.prefab] then
        local tempcheck = upgrade_effects[item.prefab]
        add_utils.debug_print(string.format(" [Replica Check] %s: max=%s, cur=%s, enab=%s, show=%s", item.prefab,
            tostring(tempcheck.max),
            tostring(tempcheck.cur),
            tostring(tempcheck.enab),
            tostring(tempcheck.show)))
            
        if item.prefab == "nightmarefuel" then
            local current_lv = self.packlv.level >= 3
            local lunar_open = current_lv and self.upgrade_effects.alterguardianhat and self.upgrade_effects.alterguardianhat.enab 
                and self.upgrade_effects.lunar_seed and self.upgrade_effects.lunar_seed.enab and self.upgrade_effects.lunar_seed.cur >= 5 or false
            local zero_open = self:CheckEnable("purpleamulet")
            if not lunar_open and not zero_open then
                return false
            end
        end

        if tempcheck.except then
            local except_open = self:CheckEnable(tempcheck.except)
            if except_open then
                return false
            end
        end

        if item.prefab == "pigskin" then
            local pig_open = self:CheckEnable("pig_coin")
            if not pig_open then
                return false
            end
        end

        if tempcheck.max ~= nil then
            -- 有数量限制的升级材料检查
            local result = tempcheck.max > tempcheck.cur
            add_utils.debug_print(string.format("[Replica Check] 检查结果: max:%s , current:%s" ,tempcheck.max ,tempcheck.cur))
            return result
        else
            -- 无数量限制的检查
            add_utils.debug_print("  处理无数量限制的材料...")
            local result = tempcheck.enab ~= true
            add_utils.debug_print(string.format("[Replica Check] 检查结果: enab:%s" ,tostring(tempcheck.enab)))
            return result
        end
    end

    -- 默认情况日志
    if not item then
        add_utils.debug_print("[Replica Check] 检查失败: 物品对象为nil")
    elseif not item.prefab then
        add_utils.debug_print("[Replica Check] 检查失败: 物品prefab为nil")
    elseif not self.upgrade_effects then
        add_utils.debug_print("[Replica Check] 检查失败: upgrade_effects表为nil")
    elseif not self.upgrade_effects[item.prefab] then
        add_utils.debug_print(string.format("[Replica Check] 检查失败: 物品%s不在升级效果表中", item.prefab))
    elseif not self.upgrade_effects[item.prefab].show then
        add_utils.debug_print(string.format("[Replica Check] 检查失败: 物品%s的Show字段为false", item.prefab))
    end

    return false
end

function Devourer:GetLv()
	return self.packlv.level, self.packlv.extra_rows, self.packlv.fire, self.packlv.ice, self.packlv.repair
end

function Devourer:SetPackState(packlv)
    -- 更新本地packlv
    self.packlv = packlv
    local plv_json = json.encode(packlv)
    -- 记录JSON字符串
    add_utils.debug_print("[Replica SetPackState] 生成的JSON:", plv_json)
    self._net_devourer_plv:set(plv_json)
end

local function ModCompat(container, widget)
	container.widget = widget

	container:SetNumSlots(widget.slotpos ~= nil and #widget.slotpos or 0)

	if container.classified and container.classified.InitializeSlots and container.GetNumSlots then
        local num_slots = container:GetNumSlots()
        add_utils.debug_print("ModCompat: 更新格子数量:", num_slots)
		container.classified:InitializeSlots(num_slots)
	end
end

function Devourer:GetSlot()
    local level, extra_rows, lv_fire, lv_ice, lv_repair = self:GetLv() -- level:背包等级，extra_rows:额外行数
    local slot_set = add_configs.pack_slot_set[TUNING.DEVOURER_PACK_MAX_SLOTS]
    -- 列数受到最大格子限制，总列数是 初始列数 + x + y之和，请注意饥荒官方背包格子最大数有限制，超过会报错
    local base_cols = TUNING.DEVOURER_PACK_BASE_ROWS
    -- if level >= 2 and base_cols == 1 then -- 如果初始为1列（增加难度），则等级2提升时增加1列，保持最终列数不变
    --     base_cols = base_cols + 1
    -- end
    local lv_y = math.min(base_cols + (level - 1) + extra_rows, slot_set.y) -- 受到最终列数限制
    -- 初始列数是2，等级2增加行数，等级3增加列数，所以需要判断是否大于2,1级2级都是2列，3级是3列
    level = math.min(level >= 3 and 3 or 2, slot_set.x) -- 行数受到最大行数限制
    add_utils.debug_print("[Replica GetSlot]: level", level, "extra_rows", extra_rows,"base_cols", base_cols, 
        "lv_y", lv_y, "lv_fire", lv_fire, "lv_ice", lv_ice, "lv_repair", lv_repair)
    return level, lv_y, lv_fire, lv_ice, lv_repair
end

local params = {}
function Devourer:UpdateWidget(lv_x_p, lv_y_p, lv_fire_p, lv_ice_p, lv_repair_p)
	local container = self.inst.replica.container
	if container == nil then return end
    
    -- 记录传进来的参数和我们自己查的参数
    add_utils.debug_print("[Replica:UpdateWidget] 开始更新背包 - 传参:", 
        "lv_x_p:", lv_x_p, 
        "lv_y_p:", lv_y_p, 
        "lv_fire_p:", lv_fire_p, 
        "lv_ice_p:", lv_ice_p, 
        "lv_repair_p:", lv_repair_p)
    local lv_x, lv_y, lv_fire, lv_ice, lv_repair = self:GetSlot()
    lv_x = lv_x_p or lv_x
    lv_y = lv_y_p or lv_y
    lv_fire = lv_fire_p or lv_fire
    lv_ice = lv_ice_p or lv_ice
    lv_repair = lv_repair_p or lv_repair
    add_utils.debug_print("[Replica:UpdateWidget] 最终使用的参数 - lv_x:", lv_x, "lv_y:", lv_y, "lv_fire:", lv_fire, "lv_ice:", lv_ice, "lv_repair:", lv_repair)
	local widget = setmetatable({}, {__index = container.widget})
	-- local lv_code = lv_x + bit.lshift(lv_y, 6)

    if params[self.inst.prefab] == nil then
        params[self.inst.prefab] = {}
    end

    if widget.slotbg ~= nil and widget.slotbg[1] ~= nil then
        local generic = widget.slotbg[1]
        for k, v in pairs(widget.slotbg) do
            if v.image ~= generic.image or v.atlas ~= generic.atlas then
                generic = nil
            end
        end
        --container.widget.slotbg.generic = generic
        if generic then
            widget.slotbg = generic
            widget.slotbg.generic = true
        end
    end

    -- 我这里直接用固定的坎普斯背包的这些参数    
    local sep = Vector3(75.00, 75.00, 0.00)
    local shift_offset = Vector3(124.50, -15.00, -0.00)
    local scale_offset = Vector3(1.00, 1.00, 0.00)

    -- 背包达到最大格子，等级达到3级，特殊格子效果全部解锁，则增加第四排格子，变成4*9格子背包
    if lv_x==3 and lv_y==9 and self.packlv.level==3 
        and lv_fire >= 1 and lv_ice >= 1 and lv_repair >= 3 then
        lv_x = 4
    end

    widget.pos = Vector3(0, widget.pos.y, 0)
    widget.pos.x = math.floor((self.inst.baselv.x - lv_x) * 23) - 92

    local lv_x_fix = (lv_x > self.inst.baselv.x) and (lv_x - self.inst.baselv.x) or 0
    local lv_y_fix = lv_x_fix > 0 and (-8 * lv_x_fix) or ((lv_x > 1) and (lv_x-1) * 3 or 0)
    -- x轴，负数为右移背景，正数为左移背景
    widget.bgshift = Vector3(lv_x / self.inst.baselv.x * shift_offset.x + lv_y_fix, lv_y / self.inst.baselv.y * shift_offset.y + 100 + lv_y * 0.5, 1)
    widget.bgscale = Vector3(lv_x / self.inst.baselv.x * scale_offset.x - (lv_x_fix * 0.1), lv_y / self.inst.baselv.y * scale_offset.y, 1)

    local init_x = -(lv_x + 1) * math.floor(sep.x / 2)
    local init_y = -(lv_y + 1) * math.floor(sep.y / 2)
    
    local current_slots = self.inst.replica.container and self.inst.replica.container.GetNumSlots and self.inst.replica.container:GetNumSlots() 
        or self.inst.components.container and self.inst.components.container.GetNumSlots and self.inst.components.container:GetNumSlots() 
        or 36
    add_utils.debug_print("[Replica:UpdateWidget] 当前格子数: ", current_slots, " 预期格子数: ", lv_x * lv_y)

    widget.slotpos = {}
    for y = lv_y, 1, -1 do
        for x = 1, lv_x do
            table.insert(widget.slotpos, Vector3(x * sep.x + init_x, y * sep.y + init_y + 100, 0))
        end
    end
    
    -- 动态设置特殊格子背景
    widget.slotbg = {}

    local num_slots = #widget.slotpos
    local repair_slot = num_slots       -- 倒数第1个格子，预留给修理格，1级效果
    local heating_slot = num_slots - 1  -- 倒数第2个格子，预留给加热格，2级效果
    local cooling_slot = num_slots - 2  -- 倒数第3个格子，预留给制冷格，3级效果
    local alchemy_slot = num_slots - 3  -- 倒数第4个格子，预留给背包格子满级解锁，转换格子，隐藏的4级效果
    -- 使用新的fire、ice、repair字段进行判断
    -- 修复格：等级>=1并且repair>=1
    if self.packlv.level >= 1 and lv_repair >= 1 then
        widget.slotbg[repair_slot] = { image = "slot_bg_tool.tex", atlas = "images/slot_bg_tool.xml" }
    end
    -- 加热格：等级>=2并且fire>=1
    if self.packlv.level >= 2 and lv_fire >= 1 then
        widget.slotbg[heating_slot] = { image = "slot_bg_fire.tex", atlas = "images/slot_bg_fire.xml" }
    end
    -- 冰冻格：等级>=3并且ice>=1
    if self.packlv.level >= 3 and lv_ice >= 1 then
        widget.slotbg[cooling_slot] = { image = "slot_bg_snow.tex", atlas = "images/slot_bg_snow.xml" }
    end
    if lv_x==4 then
        widget.slotbg[alchemy_slot] = { image = "slot_bg_alchemy.tex", atlas = "images/slot_bg_alchemy.xml" }
    end

	ModCompat(container, widget)
end

return Devourer
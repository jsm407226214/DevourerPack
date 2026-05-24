-- 吞噬者背包 - 控制功能模块（Mixin）
-- 通过 devourer.lua 入口加载：require("components/devourer/control")(Devourer)

local add_utils = require("utils/add_utils")
local shared = require("components/devourer/shared")

return function(Devourer)

-- ============================================
-- 控制功能相关方法
-- ============================================

-- 更改控制开关状态
function Devourer:ChangeControlSwitch(key, value)
    local result = { success = false, reason = "", key = key, value = value }
    -- 根据当前功能调用对应的处理函数
    if key == "AreaAttack" then
        self.control_switch[key] = value
        result.success = true
    elseif key == "Reflect" then
        self.control_switch[key] = value
        self:ChangeSingleReflect(value == 2 or value == 4) -- 单体反伤
        result.success = true
    elseif key == "SanityChange" then
        result.reason = self:ChangeSanityStatus()           -- 精神状态变更（0，正常，启迪max）
        result.success = result.reason == nil and true or false
        result.value = self.control_switch[key]  -- 返回实际应用的状态,因为精神变化有点特殊，没有对应开启就顺序变化的
    elseif key == "TreadWater" then
        result.reason = self:_HandleTreadWater(value) -- 开关踏水
        result.success = result.reason == nil and true or false
    elseif key == "PigSummon" then
        result.reason = self:ChangePigSummon(value)              -- 召唤猪人
        result.success = result.reason == nil and true or false
    elseif key == "NightVision" then
        result.reason = self:ChangeLight(value)-- 夜视
        result.success = result.reason == nil and true or false
        result.value = self.control_switch[key]  -- 返回实际应用的状态
    elseif key == "KeepTemp" then
        self.control_switch[key] = value
        local owner = self.inst.components.inventoryitem.owner
        shared.monitor_temperature(self, owner)  -- 使用 shared 模块的函数
        result.success = true
    elseif key == "ExtraDamage" then
        self.control_switch[key] = value
        result.reason = self:ChangeExtraDamage()-- 额外伤害
        result.success = result.reason == nil and true or false
    elseif key == "DevourerBee" then
        self.control_switch[key] = value
        result.success = true
    elseif key == "Electric" then
        self.control_switch[key] = value
        self:ChangeElectric() -- 电击开关（因为会着火烧家）
        result.success = true
    elseif key == "GestaltAttack" then
        self.control_switch[key] = value
        result.success = true
    elseif key == "StopDrop" then
        self.control_switch[key] = value
        result.success = true
    elseif key == "Luck" then
        self.control_switch[key] = value
        self:ChangeLuck() -- 幸运开关
        result.success = true
    elseif key == "RainProtect" then
        self.control_switch[key] = value
        self:ApplyWaterproof(value == 2)
        result.success = true
    else
        result.reason = "未知的控制开关键:"..key
        result.success = false
    end
    return result
end

-- 获取可控制的功能列表（从STRINGS.DEVOURER_CONTROLS获取，并按order排序）
function Devourer:GetControlFunctions()
    local functions = {}
    for key, cfg in pairs(STRINGS.DEVOURER_CONTROLS) do
        if cfg.order then
            table.insert(functions, { key = key, name = cfg.name, options = cfg.options, order = cfg.order })
        end
    end
    table.sort(functions, function(a, b) return (a.order or 999) < (b.order or 999) end)
    return functions
end

-- 切换当前绑定的功能（快捷键调用）
-- 返回值：{success = true/false, current_func = 当前功能信息}
function Devourer:SwitchControlFunction()
    local control_functions = self:GetControlFunctions()
    if #control_functions == 0 then
        add_utils.debug_print("[Devourer:SwitchControlFunction] 没有可切换的功能")
        return { success = false, reason = "没有可切换的功能" }
    end
    
    -- 找到当前绑定功能的索引
    local current_index = 1
    for i, func in ipairs(control_functions) do
        if func.key == self.current_bound_function then
            current_index = i
            break
        end
    end
    
    -- 循环切换到下一个功能
    current_index = current_index % #control_functions + 1
    local current_func = control_functions[current_index]
    
    -- 保存当前绑定的功能
    self.current_bound_function = current_func.key
    
    -- 显示切换提示
    if self.inst.components.talker then
        self.inst.components.talker:Say(string.format("已绑定：%s", current_func.name))
    end
    
    add_utils.debug_print("[Devourer:SwitchControlFunction] 切换功能: " .. current_func.key .. " (" .. current_func.name .. ")")
    return { success = true, current_func = current_func }
end

-- 执行当前绑定的功能（快捷键调用）
-- 返回值：{success = true/false, key = 功能键, value = 新值, reason = 原因}
function Devourer:ExecuteControlFunction()
    local control_functions = self:GetControlFunctions()
    if #control_functions == 0 then
        add_utils.debug_print("[Devourer:ExecuteControlFunction] 没有可执行的功能")
        return { success = false, reason = "没有可执行的功能" }
    end
    
    local current_func_key = self.current_bound_function or control_functions[1].key
    
    -- 获取当前功能配置
    local control_config = STRINGS.DEVOURER_CONTROLS[current_func_key]
    if not control_config then
        add_utils.debug_print("[Devourer:ExecuteControlFunction] 无效的功能键: " .. current_func_key)
        return { success = false, reason = "无效的功能键" }
    end
    
    -- 获取当前值
    local current_value = self.control_switch[current_func_key] or control_config.default or 1
    
    -- 计算下一个值（循环切换）
    local options = control_config.options
    if not options or #options == 0 then
        add_utils.debug_print("[Devourer:ExecuteControlFunction] 功能 " .. current_func_key .. " 没有可切换的选项")
        return { success = false, reason = "该功能没有可切换的选项" }
    end
    
    -- 找到当前值的索引
    local current_index = 1
    for i, opt in ipairs(options) do
        if opt.value == current_value then
            current_index = i
            break
        end
    end
    
    -- 切换到下一个选项
    local next_index = current_index % #options + 1
    local next_value = options[next_index].value
    
    -- 调用SetControl方法执行切换（is_hotkey = true）
    local result = self:SetControl(current_func_key, next_value, nil, true)
    
    add_utils.debug_print("[Devourer:ExecuteControlFunction] 执行功能: " .. current_func_key .. ", 值: " .. current_value .. " -> " .. next_value)
    return result or { success = true, key = current_func_key, value = next_value }
end

-- 设置控制开关（带权限验证和结果反馈）
-- @param key 控制开关的键名
-- @param value 要设置的值
-- @param callback_id 客户端回调ID（用于面板）
-- @param is_hotkey 是否是快捷键调用（布尔值），如果是则通知玩家切换结果
function Devourer:SetControl(key, value, callback_id, is_hotkey)
    local result = self:ChangeControlSwitch(key, value)

    result.callback_id = callback_id  -- 客户端传来的唯一标识

    -- 成功则更新服务端数据并同步到Replica
    if result.success then
        add_utils.debug_print("[Devourer:SetControl] 成功更新，key:", key, " value:", value)
        self:_SyncControlsToReplica()  -- 同步到Replica（你已实现的逻辑）
    end

    -- 如果是快捷键调用，通知玩家切换结果
    if is_hotkey and result.success then
        local control_config = STRINGS.DEVOURER_CONTROLS[key]
        if control_config then
            local option_text = ""
            for _, opt in ipairs(control_config.options or {}) do
                if opt.value == value then
                    option_text = opt.text
                    break
                end
            end
            if self.inst.components.talker and option_text ~= "" then
                self.inst.components.talker:Say(string.format("已切换至：%s [%s]", control_config.name, option_text))
            end
        end
    elseif is_hotkey and not result.success then
         -- 快捷键调用但失败，通知玩家原因
        self.inst.components.talker:Say(result.reason or "无法切换功能")
    end

    -- 发送完整结果到客户端（包含success和reason）
    local owner = self.inst.components.inventoryitem.owner
    shared.RefreshEquip(self.inst, owner) -- 使用 shared 模块的函数刷新装备状态
    if owner and owner:IsValid() then
        add_utils.debug_print("[Devourer:SetControl] 发送结果到客户端，key:", key, " value:", result.value, " success:", result.success, " reason:", result.reason, " callback_id:", result.callback_id)
        
        SendModRPCToClient(
            CLIENT_MOD_RPC["devourer_pack"]["OnControlUpdated"],
            owner.userid, -- 精准指定玩家
            owner,       -- 目标实体
            -- 拆分result的字段，逐个传递（均为基础类型）
            result.success,    -- 布尔值
            result.key,        -- 字符串
            result.value,      -- 数字/字符串（基础类型）
            result.reason,     -- 字符串
            result.callback_id -- 数字
        )
    else
        add_utils.debug_print("[Devourer:SetControl] 无有效拥有者，无法发送结果到客户端")
    end
end

end

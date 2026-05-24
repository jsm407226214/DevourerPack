-- 网络 RPC 注册：吞噬者背包控制面板通信

local add_utils = require("utils/add_utils")
local MOD_NAME = "devourer_pack"

-- 服务端：接收客户端控制请求
AddModRPCHandler(MOD_NAME, "SetControl", function(player, key, value, callback_id, is_hotkey)
    add_utils.debug_print("[服务端RPC] SetControl", player, key, value, callback_id, is_hotkey)
    if not (player and player:IsValid()) then return end

    local devourer_pack = add_utils.GetDevourerPack(player)
    if devourer_pack and devourer_pack.components.devourer then
        devourer_pack.components.devourer:SetControl(key, value, callback_id, is_hotkey)
    end
end)

-- 服务端：接收客户端功能切换快捷键请求
AddModRPCHandler(MOD_NAME, "SwitchControlFunction", function(player)
    add_utils.debug_print("[服务端RPC] SwitchControlFunction", player)
    if not (player and player:IsValid()) then return end

    local devourer_pack = add_utils.GetDevourerPack(player)
    if devourer_pack and devourer_pack.components.devourer then
        devourer_pack.components.devourer:SwitchControlFunction()
    end
end)

-- 服务端：接收客户端功能执行快捷键请求
AddModRPCHandler(MOD_NAME, "ExecuteControlFunction", function(player)
    add_utils.debug_print("[服务端RPC] ExecuteControlFunction", player)
    if not (player and player:IsValid()) then return end

    local devourer_pack = add_utils.GetDevourerPack(player)
    if devourer_pack and devourer_pack.components.devourer then
        devourer_pack.components.devourer:ExecuteControlFunction()
    end
end)

-- 客户端：接收服务端控制更新通知
AddClientModRPCHandler(MOD_NAME, "OnControlUpdated", function(player, success, key, value, reason, callback_id)
    local result = {
        success = success,
        key = key,
        value = value,
        reason = reason,
        callback_id = callback_id,
    }
    if player and player:IsValid() then
        player:PushEvent("devourer_control_updated", result)
    end
end)

-- ============================================
-- 吞噬者背包 - 快捷键绑定
-- ============================================
local add_utils = require('utils/add_utils')

-- ============================================
-- 面板快捷键配置
-- ============================================
local control_key = GetModConfigData("devourer_pack_control_panel_key")

-- 面板快捷键触发函数：通过HUD实例调用切换方法
local function OnKeyDownControl()
    if ThePlayer and ThePlayer.HUD then
        ThePlayer.HUD:ToggleDevourerPackControlPanel()
    end
end

-- 绑定面板快捷键
TheInput.onkeydown:AddEventHandler(control_key, OnKeyDownControl)

-- ============================================
-- HUD 面板 PostConstruct
-- ============================================
local DevourerPackControlPanel = require "widgets/devourerpackcontrolpanel"

AddClassPostConstruct("screens/playerhud", function(self)
    self.devourerpack_control_panel = nil  -- 初始化面板实例

    function self:ToggleDevourerPackControlPanel()
        if self.devourerpack_control_panel and self.devourerpack_control_panel.isopen then
            self.devourerpack_control_panel:OnClose()
        else
            add_utils.debug_print("打开吞噬者背包控制面板")   
            if not ThePlayer then add_utils.debug_print("RefreshConfigData 没有ThePlayer,返回") return end
            
            local devourer_pack = add_utils.GetDevourerPack(ThePlayer)
            if not (devourer_pack and devourer_pack.replica.devourer) then
                add_utils.debug_print("RefreshConfigData 未找到吞噬者背包，使用默认配置")
                add_utils.debug_print("未找到吞噬者背包，使用默认配置")
                return
            end
            
            if not self.devourerpack_control_panel then
                self.devourerpack_control_panel = self:AddChild(DevourerPackControlPanel(devourer_pack))
            end
            if self.devourerpack_control_panel and not self.devourerpack_control_panel.isopen then
                self.devourerpack_control_panel:OnOpen(devourer_pack)
            end
        end
    end
end)




-- ============================================
-- 功能切换/执行快捷键配置
-- ============================================
local switch_key = GetModConfigData("devourer_pack_switch_key")
local execute_key = GetModConfigData("devourer_pack_execute_key")

-- 功能切换：通过RPC调用服务端的SwitchControlFunction方法
local function OnKeyDownSwitch()
    if not ThePlayer then 
        return 
    end
    SendModRPCToServer(MOD_RPC["devourer_pack"]["SwitchControlFunction"])
end

-- 功能执行：通过RPC调用服务端的ExecuteControlFunction方法
local function OnKeyDownExecute()
    if not ThePlayer then 
        return 
    end
    SendModRPCToServer(MOD_RPC["devourer_pack"]["ExecuteControlFunction"])
end

-- 绑定功能切换键
if switch_key ~= false then
    TheInput.onkeydown:AddEventHandler(switch_key, OnKeyDownSwitch)
end

-- 绑定功能执行键
if execute_key ~= false then
    TheInput.onkeydown:AddEventHandler(execute_key, OnKeyDownExecute)
end
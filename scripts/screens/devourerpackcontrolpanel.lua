local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local TextBtn = require "widgets/textbutton"
local PopupDialogScreen = require "screens/redux/popupdialog"
local add_utils = require "add_utils"

-- 引入工具类
local t_util = require "devourer_utils/tableutil"
local h_util = require "devourer_utils/hudutil"

-- 吞噬者背包控制面板
local DevourerPackControlPanel = Class(Screen, function(self, devourer_pack)
    Screen._ctor(self, "DevourerPackControlPanel")
    
    -- 保存参数
    self.devourer_pack = devourer_pack
    self.player = ThePlayer  -- 获取玩家实例，用于绑定监听器
    
    -- 固定标题
    self.title_text = "吞噬者背包控制面板"
    
    -- 初始化配置数据
    self.config_data = STRINGS.DEVOURER_CONTROLS or {}
    
    -- 存储当前值
    self.current_values = {}
    for key, cfg in pairs(self.config_data) do
        self.current_values[key] = cfg.default
    end
    
    -- 初始化唯一ID计数器和回调映射（遵循EquipUpdate的存储风格）
    self.callback_id = 0
    self.callback_map = {}  -- 存储回调函数
    self.active_tasks = {}  -- 存储活跃任务
    
    -- 面板尺寸与字体设置
    self.w = 800 * h_util.rate_w
    self.h = 500 * h_util.rate_h
    self.font_size = 35 * h_util.rate_w
    self.page = 1  -- 当前页码
    self.items_per_page = 10  -- 每页显示10项
    
    -- 构建UI
    self:BuildRoot()
    self:BuildTitleBar()
    self:BuildContentArea()
    
    -- 注册全局监听器（绑定到玩家身上）
    self:RegisterGlobalListener()
    
    -- 执行原OnOpen的逻辑
    self:RefreshConfigData(devourer_pack)
    self:RefreshContent()
    self.isopen = true
    add_utils.debug_print("开启吞噬者背包控制面板")
end)

-- 注册全局监听器（模仿EquipUpdate的监听注册方式）
function DevourerPackControlPanel:RegisterGlobalListener()
    -- 先移除可能存在的旧监听器（安全检查）
    if self.player._devourer_pack_control_updated then
        self.player:RemoveEventCallback("devourer_control_updated", self.player._devourer_pack_control_updated)
        self.player._devourer_pack_control_updated = nil
    end
    
    -- 定义监听器并存储在实例上
    self.player._devourer_pack_control_updated = function(_, result)
        -- 校验结果合法性（必须包含callback_id）
        if not result or not result.callback_id then
            add_utils.debug_print("[客户端] 无效事件：缺少callback_id")
            return
        end
        add_utils.debug_print("[客户端] 收到控制更新事件，callback_id:", result.callback_id, 
              ", key:", result.key or "nil", 
              ", value:", result.value or "nil", 
              ", success:", result.success or "nil", 
              ", reason:", result.reason or "nil")
        -- 匹配客户端的回调映射（用callback_id找到对应处理函数）
        if self.callback_map[result.callback_id] then
            -- 执行回调，传入完整结果（含success、reason等）
            self.callback_map[result.callback_id](result)
            -- 移除已处理的回调（避免重复执行）
            self.callback_map[result.callback_id] = nil
        end

        -- 清理对应的超时任务
        if self.active_tasks[result.callback_id] then
            self.active_tasks[result.callback_id]:Cancel()
            self.active_tasks[result.callback_id] = nil
        end
    end
    
    -- 注册监听器到玩家身上
    self.player:ListenForEvent("devourer_control_updated", self.player._devourer_pack_control_updated)
end

-- 生成唯一ID
function DevourerPackControlPanel:GenerateUniqueID()
    self.callback_id = self.callback_id + 1
    return self.callback_id
end

-- 构建根节点和背景
function DevourerPackControlPanel:BuildRoot()
    -- 半透明背景遮罩（点击关闭）
    self.black = self:AddChild(ImageButton("images/global.xml", "square.tex"))
    self.black:SetOnClick(function() 
        self:OnClose()
    end)
    self.black.image:SetVAnchor(ANCHOR_MIDDLE)
    self.black.image:SetHAnchor(ANCHOR_MIDDLE)
    self.black.image:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black.image:SetTint(0, 0, 0, 0.5)
    
    -- 面板根节点
    self.root = self:AddChild(Widget("root"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    
    -- 背景图
    self.bg = self.root:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_menu_bg.tex"))
    self.bg:SetSize(self.w, self.h)
end

-- 构建标题栏
function DevourerPackControlPanel:BuildTitleBar()
    -- 标题文字
    self.title = self.root:AddChild(Text(HEADERFONT, self.font_size, self.title_text, {0, 0, 0, 1}))
    self.title:SetPosition(0, self.h/2 - self.font_size)
    self.title:SetHAlign(ANCHOR_MIDDLE)
    
    -- 标题下划线
    self.title_line = self.title:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_line_break.tex"))
    self.title_line:SetPosition(0, -self.font_size + 5)
    self.title_line:SetScale(self.w / 600, 1)
    
    -- 分页箭头（左）
    self.arr_l = self.title:AddChild(ImageButton("images/frontend.xml", "turnarrow_icon.tex", "turnarrow_icon_over.tex"))
    self.arr_l:Hide()
    self.arr_l:SetPosition(-self.w/5.5, 0)
    self.arr_l:SetScale(1, 0.4, 0.6)
    self.arr_l:SetHoverText("上一页")
    h_util:ActivateBtnScale(self.arr_l, 40)
    self.arr_l:SetOnClick(function()
        if self.page > 1 then
            self.page = self.page - 1
            self:RefreshContent()
        end
    end)
    
    -- 分页箭头（右）
    self.arr_r = self.title:AddChild(ImageButton("images/frontend.xml", "turnarrow_icon.tex", "turnarrow_icon_over.tex"))
    self.arr_r:SetPosition(self.w/5.5, 0)
    self.arr_r:SetScale(-1, 0.4, 0.6)
    self.arr_r:SetHoverText("下一页")
    h_util:ActivateBtnScale(self.arr_r, 40)
    self.arr_r:SetOnClick(function()
        local max_page = self:GetMaxPage()
        if self.page < max_page then
            self.page = self.page + 1
            self:RefreshContent()
        end
    end)
end

-- 构建内容区域
function DevourerPackControlPanel:BuildContentArea()
    self.content = self.root:AddChild(Widget("content"))
    self.content:SetPosition(-0.18 * self.w, 0.18 * self.h)
end

-- 计算最大页数
function DevourerPackControlPanel:GetMaxPage()
    local sorted_keys = self:GetSortedKeys()
    return math.ceil(#sorted_keys / self.items_per_page)
end

-- 获取按order排序的配置键名
function DevourerPackControlPanel:GetSortedKeys()
    local temp = {}
    for key, cfg in pairs(self.config_data) do
        table.insert(temp, {
            key = key,
            order = cfg.order or 999
        })
    end
    table.sort(temp, function(a, b) return a.order < b.order end)
    
    local sorted_keys = {}
    for _, item in ipairs(temp) do
        table.insert(sorted_keys, item.key)
    end
    return sorted_keys
end

-- 刷新内容
function DevourerPackControlPanel:RefreshContent()
    -- 清除现有内容（模仿EquipUpdate中先检查再清理的方式）
    if self.buttons_container then
        self.buttons_container:Kill()
        self.buttons_container = nil
    end
    self.buttons_container = self.content:AddChild(Widget("buttons_container"))
    
    -- 获取排序后的配置键
    local sorted_keys = self:GetSortedKeys()
    local max_page = self:GetMaxPage()
    
    -- 计算当前页显示范围
    local start_idx = (self.page - 1) * self.items_per_page + 1
    local end_idx = math.min(start_idx + self.items_per_page - 1, #sorted_keys)
    
    -- 2列布局参数
    local col_spacing = self.w / 2.5
    local row_spacing = 70 * h_util.rate_h
    
    -- 创建当前页的文本按钮
    for i = start_idx, end_idx do
        local idx = i - start_idx + 1
        local key = sorted_keys[i]
        local cfg = self.config_data[key]
        if not cfg then break end
        
        -- 计算位置（2列布局）
        local col = (idx - 1) % 2
        local row = math.floor((idx - 1) / 2)
        local x = (col - 0.5) * col_spacing
        local y = -row * row_spacing
        
        -- 创建按钮
        local widget = self:CreateTextButton(key, cfg)
        self.buttons_container:AddChild(widget)
        widget:SetPosition(x, y)
    end
    
    -- 控制上一页按钮（arr_l）的显示/隐藏
    if self.page > 1 then
        self.arr_l:Show()  -- 当页码大于1时，显示上一页按钮
    else
        self.arr_l:Hide()  -- 当页码为1时，隐藏上一页按钮（第一页无前置页）
    end

    -- 控制下一页按钮（arr_r）的显示/隐藏
    if self.page < max_page then
        self.arr_r:Show()
    else
        self.arr_r:Hide()
    end
end

-- 创建文本按钮（核心实现，遵循EquipUpdate的监听器管理风格）
function DevourerPackControlPanel:CreateTextButton(key, cfg)
    local widget = Widget("textbtn_" .. key)
    
    -- 1. 左侧说明文本
    local label = widget:AddChild(Text(HEADERFONT, self.font_size - 2, cfg.name, {0, 0, 0, 1}))
    local label_width = label:GetRegionSize()
    label:SetPosition(label_width / 2 - 15, 0)
    
    -- 2. 右侧可点击文本框
    local text_btn = widget:AddChild(TextBtn())
    text_btn:SetFont(HEADERFONT)
    text_btn:SetTextSize(self.font_size - 5)
    text_btn:SetColour({0.3, 0.15, 0, 1})
    
    -- 初始化显示文本
    local function updateDisplayText()
        local current_val = self.current_values[key]
        local display_text = "未设置"
        local display_desc = nil
        for _, opt in ipairs(cfg.options) do
            if opt.value == current_val then
                display_text = opt.text
                display_desc = opt.desc
                break
            end
        end
        add_utils.debug_print("更新显示文本，key:", key, ", 当前值:", current_val, ", 显示文本:", display_text)
        text_btn:SetText(display_text)
        if display_desc ~= nil then
            widget:SetHoverText(display_desc, { font = NEWFONT_OUTLINE, offset_y = 90 })
        else
            widget:SetHoverText("点击切换选项", { font = NEWFONT_OUTLINE, offset_y = 90 })
        end
    end
    updateDisplayText()
    
    -- 3. 文本框背景与下划线
    local textbox_width = self.w * 0.25
    text_btn:SetPosition(textbox_width, 0)
    
    -- 透明背景
    local bg = text_btn:AddChild(Image("images/quagmire_recipebook.xml", "cookbook_known.tex"))
    bg:SetSize(textbox_width, 40)
    bg:SetTint(0, 0, 0, 0)
    
    -- 下划线
    local line = text_btn:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_bar.tex"))
    line:SetSize(5, textbox_width)
    line:SetRotation(90)
    line:SetPosition(0, -23)

    -- 4. 点击事件（切换选项）
    text_btn:SetOnClick(function()
        add_utils.debug_print("点击控制项按钮，key:", key)
            
        -- 1. 计算期望切换到的下一个值
        local current_idx = 1
        for i, opt in ipairs(cfg.options) do
            if opt.value == self.current_values[key] then
                current_idx = i
                break
            end
        end
        local next_idx = current_idx % #cfg.options + 1
        local desired_value = cfg.options[next_idx].value

        -- 2. 生成唯一ID
        local callback_id = self:GenerateUniqueID()

        -- 3. 发送RPC请求服务端执行修改，带上唯一ID
        SendModRPCToServer(
            MOD_RPC["devourer_pack"]["SetControl"],
            key, 
            desired_value,
            callback_id  -- 传递唯一ID
        )

        -- 4. 临时禁用按钮，避免重复点击
        text_btn:Disable()

        -- 5. 注册回调函数（模仿EquipUpdate的回调存储方式）
        self.callback_map[callback_id] = function(result)
            text_btn:Enable()  -- 重新启用按钮

            add_utils.debug_print("收到控制结果事件，key:", result and result.key or "nil", 
                  ", value:", result and result.value or "nil", 
                  ", success:", result and result.success or "nil")

            if result and result.key == key then
                if result.success then
                    self.current_values[key] = result.value
                    updateDisplayText()
                else
                    if result.reason and result.reason ~= "" then
                        h_util.CreatePopupWithClose(
                            "操作失败", 
                            result.reason, 
                            {
                                {
                                    text = "确定",
                                    cb = function() end
                                }
                            }
                        )
                    end
                    -- updateDisplayText()
                end
            end
        end
        
        -- 6. 超时处理（仅恢复按钮可点击，不显示提示）
        -- 模仿EquipUpdate中任务的创建和存储方式
        if self.active_tasks[callback_id] then
            self.active_tasks[callback_id]:Cancel()
            self.active_tasks[callback_id] = nil
        end
        self.active_tasks[callback_id] = self.inst:DoTaskInTime(3, function()
            if self.callback_map[callback_id] then
                self.callback_map[callback_id] = nil  -- 移除回调
                text_btn:Enable()  -- 恢复按钮
            end
            self.active_tasks[callback_id] = nil  -- 清理任务引用
        end)
    end)
    
    -- -- 5. 悬停提示
    -- widget:SetHoverText("点击切换选项", { font = NEWFONT_OUTLINE, offset_y = 90 })
    
    return widget
end

-- 从devourer组件刷新最新配置数据
function DevourerPackControlPanel:RefreshConfigData(devourer_pack)
    local saved_controls = devourer_pack.replica.devourer.control_switch or {}
    
    for key, cfg in pairs(self.config_data) do
        if saved_controls[key] ~= nil then
            self.current_values[key] = saved_controls[key]
        else
            self.current_values[key] = cfg.default
        end
    end
end

-- 关闭（模仿EquipUpdate的监听器和任务清理方式）
function DevourerPackControlPanel:OnClose()
    TheFrontEnd:PopScreen(self)

    -- 清理全局监听器（先检查再移除）
    if self.player._devourer_pack_control_updated then
        self.player:RemoveEventCallback("devourer_control_updated", self.player._devourer_pack_control_updated)
        self.player._devourer_pack_control_updated = nil
    end
    
    -- 清理所有回调和任务（模仿EquipUpdate的清理逻辑）
    self.callback_map = {}
    
    for id, task in pairs(self.active_tasks) do
        if task then
            task:Cancel()
        end
    end
    self.active_tasks = {}

    -- 清理按钮容器
    if self.buttons_container then
        self.buttons_container:Kill()
        self.buttons_container = nil
    end

    self.isopen = false
    add_utils.debug_print("关闭吞噬者背包控制面板，已清理所有监听器和任务")
end

-- 处理ESC关闭
function DevourerPackControlPanel:OnControl(control, down)
    if Screen._base.OnControl(self, control, down) then return true end
    if not down and control == CONTROL_CANCEL then
        self:OnClose()
        return true
    end
end

return DevourerPackControlPanel
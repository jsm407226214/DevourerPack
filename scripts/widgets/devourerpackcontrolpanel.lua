local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local TextButton = require "widgets/textbutton"
local add_utils = require "utils/add_utils"
local add_configs = require("configs/add_configs")

local h_util = require "utils/hudutil"

-- 吞噬者背包控制面板
local DevourerPackControlPanel = Class(Widget, function(self, devourer_pack)
    Widget._ctor(self, "DevourerPackControlPanel")
    
    self.player = ThePlayer  -- 获取玩家实例，用于绑定监听器
    
    -- 固定标题
    self.title_text = "吞噬者背包控制面板"

    self.suits_config = add_configs.suits
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
    
    -- 页面类型
    self.current_page = "control" -- control, devour_list, devour_effects
    
    -- 为每个页面添加独立的页码记录
    self.pages = {
        control = 1,  -- 控制面板当前页码
        devour_list = 1,  -- 吞噬列表当前页码
        devour_effects = 1  -- 已有效果当前页码
    }
    
    -- 不同页面的每页数量设置
    self.items_per_page_map = {
        control = 10,  -- 控制面板每页10项
        devour_list = 16,  -- 吞噬列表每页16项 4*4
        devour_effects = 10  -- 已有效果每页10项
    }
    
    -- 构建UI
    self:BuildRoot()
    self:BuildTitleBar()
    self:BuildPageTabs()
    self:BuildContentArea()

    self:OnOpen(devourer_pack) -- 调用开启方法
end)

-- 注册全局监听器（模仿EquipUpdate的监听注册方式）
function DevourerPackControlPanel:RegisterGlobalListener()
    -- 先移除可能存在的旧监听器（安全检查）
    if self.player._devourer_pack_control_updated then
        self.player:RemoveEventCallback("devourer_control_updated", self.player._devourer_pack_control_updated)
        self.player._devourer_pack_control_updated = nil
    end
    
    -- 定义控制更新监听器
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
    
    -- 注册控制更新监听器
    self.player:ListenForEvent("devourer_control_updated", self.player._devourer_pack_control_updated)
    
    -- 先移除可能存在的旧升级效果监听器
    if self.devourer_pack and self.devourer_pack._devourer_pack_upgrade_updated then
        self.devourer_pack:RemoveEventCallback("devourer_upgrade_effects_updated", self.devourer_pack._devourer_pack_upgrade_updated)
        self.devourer_pack._devourer_pack_upgrade_updated = nil
    end
    
    -- -- 定义升级效果更新监听器
    -- self.devourer_pack._devourer_pack_upgrade_updated = function()
    --     add_utils.debug_print("[客户端] 收到升级效果更新事件，刷新面板")
    --     -- 只有当前页面是吞噬列表或已有效果时，才刷新内容
    --     if self.current_page == "devour_list" or self.current_page == "devour_effects" then
    --         self:RefreshContent()
    --     end
    -- end
    
    -- -- 注册升级效果更新监听器到背包实体上
    -- if self.devourer_pack then
    --     self.devourer_pack:ListenForEvent("devourer_upgrade_effects_updated", self.devourer_pack._devourer_pack_upgrade_updated)
    -- end
end

-- 生成唯一ID
function DevourerPackControlPanel:GenerateUniqueID()
    self.callback_id = self.callback_id + 1
    return self.callback_id
end

-- 构建根节点和背景
function DevourerPackControlPanel:BuildRoot()
    -- 面板根节点
    self.root = self:AddChild(Widget("root"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    
    -- 背景图
    self.bg = self.root:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_menu_bg.tex")) -- 这是群鸟绘卷的一个页面的背景
    self.bg:SetSize(self.w, self.h)
    -- 设置背景透明度，参考hx_maincover.lua的设置
    self.bg:SetTint(1, 1, 1, 0.6)
end

-- 构建页面切换标签，参考InsightMenu的标签样式
function DevourerPackControlPanel:BuildPageTabs()
    -- 标签容器
    self.tabs = self.root:AddChild(Widget("tabs"))
    self.tabs:SetPosition(0, self.h/2 - 55) -- 调整标签位置到弹窗顶部
    
    -- 标签数据
    local tabs = {
        {id = "control", text = "控制面板", order = 1},
        {id = "devour_list", text = "吞噬列表", order = 2},
        {id = "devour_effects", text = "已有效果", order = 3}
    }
    
    -- 排序标签
    table.sort(tabs, function(a, b) return a.order < b.order end)
    
    -- 计算可用标签空间
    local headerw = self.w - 80
    local available_tab_space = headerw
    local tab_width = available_tab_space / #tabs
    local tab_height = 60
    
    -- 创建标签按钮
    self.page_tabs = tabs
    self.tab_buttons = {}
    
    for i, tab in ipairs(tabs) do
        local x = -headerw/2 + tab_width/2 + (tab_width * (i-1))

        
        
        -- -- 使用与InsightMenu相同的ImageButton标签样式
        -- local tab_btn = self.tabs:AddChild(ImageButton("images/dst/frontend_redux.xml",
        --     "listitem_thick_normal.tex", -- normal
        --     nil, -- focus
        --     nil,
        --     nil,
        --     "listitem_thick_selected.tex" -- selected
        -- ))
        
        -- -- 外观设置
        -- tab_btn.scale_on_focus = false
        -- tab_btn:UseFocusOverlay("listitem_thick_hover.tex")
        -- tab_btn:ForceImageSize(tab_width, tab_height)
        -- tab_btn:SetPosition(x, 0)
        -- tab_btn:SetText(tab.text)
        -- tab_btn:SetFont(UIFONT)
        -- tab_btn:SetTextSize(25)
        -- tab_btn:SetTextColour(unpack(WHITE))
        -- tab_btn:SetTextFocusColour(unpack(WHITE))
        -- tab_btn:SetTextSelectedColour(unpack(WHITE))
        -- tab_btn.name = tab.id
        
        -- -- 添加自定义边框，未选中状态下透明度为0.1
        -- local border = tab_btn:AddChild(Image("images/dst/scoreboard.xml", "scoreboard_frame.tex"))
        -- border:SetSize(tab_width, tab_height)
        -- border:SetTint(1, 1, 1, 0) -- 0.1透明度边框
        -- border:MoveToBack()


        -- 使用简单的文本按钮，不设置大小，通过边框控制尺寸
        local tab_btn = self.tabs:AddChild(TextButton())
        tab_btn:SetPosition(x, 0)
        tab_btn:SetText(tab.text)
        tab_btn:SetFont(HEADERFONT)
        tab_btn:SetTextSize(25)
        tab_btn:SetColour(0, 0, 0, 1) -- 黑色文字
        tab_btn.name = tab.id
        
        -- 移除默认背景和边框
        if tab_btn.bg then
            tab_btn.bg:Hide()
        end
        if tab_btn.focusimage then
            tab_btn.focusimage:Hide()
        end
        
        -- 完全自定义的边框和背景
        local tab_container = tab_btn:AddChild(Widget("tab_container"))
        
        -- 添加边框
        local border = tab_container:AddChild(Image("images/scoreboard.xml", "scoreboard_frame.tex"))
        border:SetSize(tab_width, tab_height)
        border:SetTint(1, 1, 1, 0.1) -- 0.1透明度边框
        
        -- 添加选中状态
        tab_btn.selected_border = tab_container:AddChild(Image("images/scoreboard.xml", "scoreboard_frame.tex"))
        tab_btn.selected_border:SetSize(tab_width - 5, tab_height - 5)
        tab_btn.selected_border:SetPosition(0, 0)
        tab_btn.selected_border:SetTint(0, 0, 0, 0.5) -- 半透明选中边框
        tab_btn.selected_border:Hide()
        -- 将容器移到最底层，确保文本显示在上面
        tab_container:MoveToBack()
        
        -- 点击事件
        tab_btn:SetOnClick(function()
            self.current_page = tab.id
            self:RefreshContent()
            self:UpdateTabVisuals()
        end)
        
        -- 存储标签按钮
        self.tab_buttons[tab.id] = tab_btn
    end
    
    -- 更新标签视觉效果
    self:UpdateTabVisuals()
end

-- 更新标签视觉效果
function DevourerPackControlPanel:UpdateTabVisuals()
    for _, tab in ipairs(self.page_tabs) do
        local tab_btn = self.tab_buttons[tab.id]
        if tab_btn then
            if self.current_page == tab.id then
                -- 显示选中状态
                if tab_btn.selected_border then
                    tab_btn.selected_border:Show()
                end
                tab_btn:Select()
            else
                -- 隐藏选中状态
                if tab_btn.selected_border then
                    tab_btn.selected_border:Hide()
                end
                tab_btn:Unselect()
            end
        end
    end
end

-- 构建标题栏
function DevourerPackControlPanel:BuildTitleBar()
    -- 标题文字暂时移除，改为使用标签页标题
    -- self.title = self.root:AddChild(Text(HEADERFONT, self.font_size, self.title_text, {0, 0, 0, 1}))
    -- self.title:SetPosition(0, self.h/2 - self.font_size)
    -- self.title:SetHAlign(ANCHOR_MIDDLE)
    
    -- 标题下划线暂时移除
    -- self.title_line = self.title:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_line_break.tex"))
    -- self.title_line:SetPosition(0, -self.font_size + 5)
    -- self.title_line:SetScale(self.w / 600, 1)
end

-- 构建内容区域
function DevourerPackControlPanel:BuildContentArea()
    self.content = self.root:AddChild(Widget("content"))
    self.content:SetPosition(-0.18 * self.w, 0.20 * self.h) -- 向下移动，为标签页腾出空间
    
    -- 分页箭头（左），放置在页面左侧
    self.arr_l = self.root:AddChild(ImageButton("images/frontend.xml", "turnarrow_icon.tex", "turnarrow_icon_over.tex"))
    self.arr_l:Hide()
    self.arr_l:SetPosition(-self.w/2 + 30, 0) -- 页面左侧中间位置
    self.arr_l:SetScale(1, 1, 1)
    self.arr_l:SetHoverText("上一页")
    h_util:ActivateBtnScale(self.arr_l, 40)
    self.arr_l:SetOnClick(function()
            if self.pages[self.current_page] > 1 then
                self.pages[self.current_page] = self.pages[self.current_page] - 1
                self:RefreshContent()
            end
        end)
        
        -- 分页箭头（右），放置在页面右侧
        self.arr_r = self.root:AddChild(ImageButton("images/frontend.xml", "turnarrow_icon.tex", "turnarrow_icon_over.tex"))
        self.arr_r:Hide()
        self.arr_r:SetPosition(self.w/2 - 30, 0) -- 页面右侧中间位置
        self.arr_r:SetScale(-1, 1, 1)
        self.arr_r:SetHoverText("下一页")
        h_util:ActivateBtnScale(self.arr_r, 40)
        self.arr_r:SetOnClick(function()
            local max_page = self:GetMaxPage()
            if self.pages[self.current_page] < max_page then
                self.pages[self.current_page] = self.pages[self.current_page] + 1
                self:RefreshContent()
            end
        end)
end

-- 计算最大页数（仅用于分页箭头点击事件）
function DevourerPackControlPanel:GetMaxPage()
    local items_per_page = self.items_per_page_map[self.current_page] or 10
    
    if self.current_page == "control" then
        local sorted_keys = self:GetSortedKeys()
        return math.ceil(#sorted_keys / items_per_page)
    elseif self.current_page == "devour_list" then
        -- 简化版本：仅获取show为true的数据，不考虑event和mod条件
        -- 因为event和mod条件可能会变化，而分页箭头点击事件需要快速响应
        local show_items = {} 
        if self.devourer_pack and self.devourer_pack.replica.devourer then
            local upgrade_effects = self.devourer_pack.replica.devourer.upgrade_effects or {}
            for key, effect in pairs(upgrade_effects) do
                if effect.show then
                    table.insert(show_items, {key = key, effect = effect})
                end
            end
        end
        return math.ceil(#show_items / items_per_page)
    elseif self.current_page == "devour_effects" then
        -- 计算最大页数，需要先获取所有效果并进行与ShowDevourEffectsPage相同的处理
        local all_effects = {} 
        if self.devourer_pack and self.devourer_pack.replica.devourer then
            all_effects = self.devourer_pack.replica.devourer.upgrade_effects or {}
        end
        
        -- 统计效果数量，与ShowDevourEffectsPage保持一致的逻辑
        local numeric_totals = {}
        local boolean_effects = {}
        for prefab, effect_data in pairs(all_effects) do
            if effect_data.enab and (not effect_data.max or effect_data.cur > 0) then
                for stat, value in pairs(effect_data) do
                    if stat ~= "max" and stat ~= "cur" and stat ~= "show" and stat ~= "enab" and stat ~= "name" then
                        if not add_configs.excluded_attrs[stat] then
                            if type(value) == "number" then
                                numeric_totals[stat] = (numeric_totals[stat] or 0) + (value * (effect_data.cur or 1))
                            elseif type(value) == "boolean" and value then
                                boolean_effects[stat] = true
                            end
                        end
                    end
                end
            end
        end
        
        local effect_count = 0
        -- 计算数值效果数量
        for stat, total in pairs(numeric_totals) do
            if STRINGS.DP_DevourerPack.EFFECTS[stat] and total > 0 then
                effect_count = effect_count + 1
            end
        end
        
        -- 计算布尔效果数量
        for stat, _ in pairs(boolean_effects) do
            if STRINGS.DP_DevourerPack.EFFECTS[stat] then
                effect_count = effect_count + 1
            end
        end
        
        return math.ceil(effect_count / items_per_page)
    end
    
    return 1
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
    
    -- 根据当前页面显示不同内容
    if self.current_page == "control" then
        self:ShowControlPage()
    elseif self.current_page == "devour_list" then
        self:ShowDevourListPage()
    elseif self.current_page == "devour_effects" then
        self:ShowDevourEffectsPage()
    end
end

-- 显示控制页面
function DevourerPackControlPanel:ShowControlPage()
    -- 获取排序后的配置键
    local sorted_keys = self:GetSortedKeys()
    local items_per_page = self.items_per_page_map[self.current_page] or 10
    -- 直接根据sorted_keys的长度计算max_page，避免重复代码
    local max_page = math.ceil(#sorted_keys / items_per_page)
    
    -- 计算当前页显示范围
    local start_idx = (self.pages[self.current_page] - 1) * items_per_page + 1
    local end_idx = math.min(start_idx + items_per_page - 1, #sorted_keys)
    
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
    if self.pages[self.current_page] > 1 then
        self.arr_l:Show()  -- 当页码大于1时，显示上一页按钮
    else
        self.arr_l:Hide()  -- 当页码为1时，隐藏上一页按钮（第一页无前置页）
    end

    -- 控制下一页按钮（arr_r）的显示/隐藏
    if self.pages[self.current_page] < max_page then
        self.arr_r:Show()
    else
        self.arr_r:Hide()
    end
end

-- 显示吞噬列表页面
function DevourerPackControlPanel:ShowDevourListPage()
    -- add_utils.debug_print("刷新吞噬列表页面内容")
    -- 调整内容容器位置，解决整体偏左和偏下问题
    -- 第一个参数：水平偏移，正数向右，负数向左
    -- 第二个参数：垂直偏移，正数向上，负数向下
    self.buttons_container:SetPosition(140 * h_util.rate_w, 10 * h_util.rate_h)
    
    -- 4*4布局参数
    local col_spacing = self.w / 5  -- 水平间距，数值越大间距越大
    local row_spacing = 100 * h_util.rate_h  -- 垂直间距，数值越大间距越大
    
    -- 获取upgrade_effects数据并筛选show为true的数据
    local show_items = {} 
    if self.devourer_pack and self.devourer_pack.replica.devourer then
        local devourer_replica = self.devourer_pack.replica.devourer
        self.upgrade_effects = devourer_replica.upgrade_effects or {}
        for key, effect in pairs(self.upgrade_effects) do
            -- 检查是否显示，金块和月岩块除外，因为这两个是显示用的
            if effect.show and key ~= "moonrocknugget" and key ~= "goldnugget" then
                -- 检查是否为套装效果，支持多个套装
                local is_suit = false
                local suits = {}
                for suit_key, max_val in pairs(self.suits_config) do
                    if effect[suit_key] then
                        is_suit = true
                        table.insert(suits, {name = suit_key, max = max_val})
                    end
                end
                table.insert(show_items, {key = key, effect = effect, is_suit = is_suit, suits = suits})
            end
        end

        local level_up_config = add_configs.level_up or {}
        local lv1_items = level_up_config.lv1 and level_up_config.lv1.item or {}
        local lv2_items = level_up_config.lv2 and level_up_config.lv2.item or {}
        
        -- 排序吞噬列表：
        -- 1. 没有特殊字段的物品
        --    a. lv1的item的key排到最前面
        --    b. 然后是lv2的item的key
        --    c. 其他没有特殊字段的物品排后面
        -- 2. 有特殊字段的物品，按指定顺序排序：role > event > mod > hp=sanity=hunger
        table.sort(show_items, function(a, b)
            -- 定义需要特殊处理的字段
            local special_fields = {"hunger", "hp", "sanity", "event", "mod", "role"}
            
            -- 检查物品是否包含任何特殊字段
            local function has_special_fields(item)
                for _, field in ipairs(special_fields) do
                    if item.effect[field] ~= nil then
                        return true
                    end
                end
                return false
            end
            
            local a_has_special = has_special_fields(a)
            local b_has_special = has_special_fields(b)
            
            -- 没有特殊字段的物品排在前面
            if not a_has_special and b_has_special then
                return true
            elseif a_has_special and not b_has_special then
                return false
            end
            
            -- 两者都没有特殊字段，按lv1 > lv2 > 其他的顺序排序
            if not a_has_special and not b_has_special then
                -- 检查a和b是否在lv1_items中
                local a_in_lv1 = lv1_items[a.key] == true
                local b_in_lv1 = lv1_items[b.key] == true
                
                if a_in_lv1 and not b_in_lv1 then
                    return true
                elseif not a_in_lv1 and b_in_lv1 then
                    return false
                end
                
                -- 检查a和b是否在lv2_items中
                local a_in_lv2 = lv2_items[a.key] == true
                local b_in_lv2 = lv2_items[b.key] == true
                
                if a_in_lv2 and not b_in_lv2 then
                    return true
                elseif not a_in_lv2 and b_in_lv2 then
                    return false
                end
                
                -- 都不在lv1或lv2中，按物品key字典序排序
                return a.key < b.key
            end
            
            -- 两者都有特殊字段，按指定顺序排序：role > event > mod > hp=sanity=hunger
            -- 注意：这里的优先级是从高到低，所以有role字段的物品应该排在最前面
            if a_has_special and b_has_special then
                -- 检查role字段
                local a_has_role = a.effect.role ~= nil
                local b_has_role = b.effect.role ~= nil
                if a_has_role and not b_has_role then return true end
                if not a_has_role and b_has_role then return false end
                
                -- 检查event字段
                local a_has_event = a.effect.event ~= nil
                local b_has_event = b.effect.event ~= nil
                if a_has_event and not b_has_event then return true end
                if not a_has_event and b_has_event then return false end
                
                -- 检查mod字段
                local a_has_mod = a.effect.mod ~= nil
                local b_has_mod = b.effect.mod ~= nil
                if a_has_mod and not b_has_mod then return true end
                if not a_has_mod and b_has_mod then return false end
                
                -- 检查hp、sanity、hunger字段
                local a_has_hs = a.effect.hp ~= nil or a.effect.sanity ~= nil or a.effect.hunger ~= nil
                local b_has_hs = b.effect.hp ~= nil or b.effect.sanity ~= nil or b.effect.hunger ~= nil
                if a_has_hs and not b_has_hs then return true end
                if not a_has_hs and b_has_hs then return false end
                
                -- 最后按物品key字典序排序，保持稳定
                return a.key < b.key
            end
        end)
    end
    
    -- 统计不同类型物品的数量（按用户要求分类）
    local stat = {
        normal = 0,           -- 正常物品数量
        role_exclusive = 0,   -- 角色专属物品数量
        mod_items = 0,        -- 模组物品数量
        food_items = 0,       -- 食物数量
        event_items = 0       -- 活动物品数量
    }
    
    local special_food = add_configs.SPECIAL_FOOD or {}
    
    -- 遍历所有显示物品，进行统计
    for _, item_data in ipairs(show_items) do
        local prefab = item_data.key
        local effect = item_data.effect
        
        -- 检查角色专属物品（有role字段）
        if effect.role ~= nil then
            stat.role_exclusive = stat.role_exclusive + 1
        -- 检查模组物品（有mod字段）
        elseif effect.mod ~= nil then
            stat.mod_items = stat.mod_items + 1
        -- 检查活动物品（有event字段）
        elseif effect.event ~= nil then
            stat.event_items = stat.event_items + 1
        -- 检查食物（根据SPECIAL_FOOD配置或名称判断）
        elseif effect.hp ~= nil or effect.sanity ~= nil or effect.hunger ~= nil then
            stat.food_items = stat.food_items + 1
        -- 正常物品（没有特殊字段的物品）
        else
            stat.normal = stat.normal + 1
        end
    end
    
    -- 输出统计日志
    add_utils.debug_print("[吞噬列表统计] ===================================")
    add_utils.debug_print(string.format("[吞噬列表统计] 总物品数: %d", #show_items))
    add_utils.debug_print(string.format("[吞噬列表统计] 正常物品数量: %d", stat.normal))
    add_utils.debug_print(string.format("[吞噬列表统计] 角色专属物品数量: %d", stat.role_exclusive))
    add_utils.debug_print(string.format("[吞噬列表统计] 模组物品数量: %d", stat.mod_items))
    add_utils.debug_print(string.format("[吞噬列表统计] 食物数量: %d", stat.food_items))
    add_utils.debug_print(string.format("[吞噬列表统计] 活动物品数量: %d", stat.event_items))
    add_utils.debug_print("[吞噬列表统计] ===================================")
    
    -- 如果没有数据，显示提示
    if next(show_items) == nil then
        local no_data_text = self.buttons_container:AddChild(Text(HEADERFONT, self.font_size - 5, "暂无可吞噬物品", {0, 0, 0, 1}))
        no_data_text:SetPosition(0, 0)
        return
    end
    
    local items_per_page = self.items_per_page_map[self.current_page] or 16  -- 4*4=16项/页
    -- 直接根据show_items的长度计算max_page，避免重复代码
    local max_page = math.ceil(#show_items / items_per_page)
    
    -- 计算当前页显示范围
    local start_idx = (self.pages[self.current_page] - 1) * items_per_page + 1
    local end_idx = math.min(start_idx + items_per_page - 1, #show_items)
    
    -- 创建吞噬列表项
    for i = start_idx, end_idx do
        local idx = i - start_idx + 1
        local item_data = show_items[i]
        if not item_data then break end
        
        -- 计算位置（4列布局）
        local col = (idx - 1) % 4
        local row = math.floor((idx - 1) / 4)
        local x = (col - 1.5) * col_spacing  -- 调整x偏移使4列居中
        local y = -row * row_spacing
        
        -- 创建吞噬列表项
        local widget = self:CreateDevourListItem(item_data.key, item_data.effect, item_data.is_suit, item_data.suits)
        self.buttons_container:AddChild(widget)
        widget:SetPosition(x, y)
    end
    
    -- 控制分页按钮显示
    if self.pages[self.current_page] > 1 then
        self.arr_l:Show()
    else
        self.arr_l:Hide()
    end
    
    if self.pages[self.current_page] < max_page then
        self.arr_r:Show()
    else
        self.arr_r:Hide()
    end
end

-- 检查图集是否有效
local function checkAtlas(xml, tex)
    -- 尝试解析 xml 路径，避免路径不合法
    xml = xml and resolvefilepath_soft(xml) or xml
    -- 确认 atlas 文件存在并且包含 tex
    return xml and TheSim:AtlasContains(xml, tex) and xml
end

-- 根据 prefab 名字获取该物品的 atlas（图集）和 tex（贴图）
-- 这里只获取 tex 文件名
local function GetTexAsset(prefab)
    local tex = prefab .. ".tex"
    local xml = GetInventoryItemAtlas(tex)

    add_utils.debug_print("尝试通过GetInventoryItemAtlas获取图集：", "prefab=", prefab, " atlas=", xml, " image=", tex)
    if checkAtlas(xml, tex) then
        return tex
    end

    local p_data = Prefabs[prefab]
    if p_data then
        local p_assets = p_data.assets
        for _, asset in ipairs(p_assets) do
            local img = tex

            if asset.type == "INV_IMAGE" then
                img = asset.file .. ".tex"
                if checkAtlas(GetInventoryItemAtlas(img), img) then
                    return img
                end
                -- 暴食物品
                local qimg = "quagmire." .. asset.file .. ".tex"
                if checkAtlas(GetInventoryItemAtlas(qimg), qimg) then
                    return qimg
                end
            elseif asset.type == "IMAGE" then
                -- 取文件名部分
                img = asset.file
                img = string.reverse(img:reverse():sub(1, string.find(img:reverse(), "/") - 1))
                return img
            end
        end
    end
end

-- 创建吞噬列表项
function DevourerPackControlPanel:CreateDevourListItem(prefab, effect, is_suit, suits)
    local widget = Widget("devour_list_item")
    
    local suits_config = add_configs.suits or {}
    local percent_effects = add_configs.percent_effects or {}
    
    
    -- 物品图标，使用新的GetItemImage方法获取
    local atlas, image = self:GetItemImage(prefab)
    add_utils.debug_print("物品图标路径：", "prefab=", prefab, "  atlas=", atlas, "  image=", image)
    
    -- 创建图标
    local icon = widget:AddChild(Image(atlas, image))
    add_utils.debug_print("创建吞噬列表项图标：", "prefab=", prefab, " atlas=", atlas, " image=", image)
    icon:SetSize(40, 40) -- 缩小图片尺寸
    icon:SetPosition(-25, 10) -- 调整图标位置，减小与名称的间距
    
    local level_up_config = add_configs.level_up or {}
    local lv1_items = level_up_config.lv1 and level_up_config.lv1.item or {}
    local lv2_items = level_up_config.lv2 and level_up_config.lv2.item or {}
    
    -- 检查物品所属等级，并添加对应的等级标识
    if lv1_items[prefab] == true then
        -- lv1的物品，显示lv2标识
        local level_text = widget:AddChild(Text(HEADERFONT, self.font_size - 20, "lv2", {1, 1, 0, 1}))
        level_text:SetPosition(-5, 25) -- 图标右上角
        level_text:SetHAlign(ANCHOR_MIDDLE)
    elseif lv2_items[prefab] == true then
        -- lv2的物品，显示lv3标识
        local level_text = widget:AddChild(Text(HEADERFONT, self.font_size - 20, "lv3", {1, 0, 0, 1}))
        level_text:SetPosition(-5, 25) -- 图标右上角
        level_text:SetHAlign(ANCHOR_MIDDLE)
    end
    
    -- 物品名称（从STRINGS.NAMES获取友好名称）
    local item_name = STRINGS.NAMES[string.upper(prefab)] or prefab
    local name_text = widget:AddChild(Text(HEADERFONT, self.font_size - 15, item_name, {0, 0, 0, 1}))
    name_text:SetPosition(0, -28) -- 减小与图片的间距
    name_text:SetHAlign(ANCHOR_MIDDLE)
    
    -- 右边始终显示当前数量/最大数量，不管是否为套装效果
    local cur = effect.cur
    -- add_utils.debug_print("effect.cur:", cur or "nil", "effect.enab:", effect.enab or "nil")
    if cur == nil and effect.enab then
        -- add_utils.debug_print("警告：effect.cur为nil，但effect.enab为true，强制将cur设为1")
        cur = 1
    end
    if cur == nil then
        cur = 0
    end
    -- 处理except字段的特殊情况，部分互斥物品是只能吞噬一个的，另一个就无法吞噬
    if effect.except and self.upgrade_effects and self.upgrade_effects[effect.except] and self.upgrade_effects[effect.except].enab then
        cur = 1
    end
    local max = effect.max or 1
    local count_text = string.format("%d/%d", cur, max)
    
    -- 根据进度设置不同颜色
    local color = {0, 0, 0, 1} -- 默认黑色
    if cur == 0 then
        -- 进度0，显示黑色
        color = {0, 0, 0, 1}
    elseif cur < max then
        -- 进度中，显示黄色
        color = {1, 1, 0, 1}
    else
        -- 进度完成，显示白色
        color = {1, 1, 1, 1}
    end
    
    local count_label = widget:AddChild(Text(HEADERFONT, self.font_size - 12, count_text, color))
    count_label:SetPosition(40, 10) -- 图片右侧显示
    
    -- 生成悬浮提示文本
    local tooltip_text = ""
    
    -- 先处理套装效果，显示为【套装名称】当前数量/套装最大数量，支持多个套装
    if is_suit and suits and #suits > 0 then
        for _, suit in ipairs(suits) do
            if STRINGS.DP_DevourerPack.EFFECTS[suit.name] then
                local suit_display_name = STRINGS.DP_DevourerPack.EFFECTS[suit.name]
                tooltip_text = tooltip_text .. string.format("【%s】1/%d\n", suit_display_name, suit.max)
            end
        end
    end
    
    -- 然后处理其他效果
    for key, value in pairs(effect) do
        -- 跳过不需要显示的字段
        if key ~= "max" and key ~= "cur" and key ~= "show" and key ~= "enab" and key ~= "name" then
            -- 检查是否是套装标识字段，如果是则跳过，因为已经在前面显示了
            local is_suit_key = false
            if is_suit and suits and #suits > 0 then
                for _, suit in ipairs(suits) do
                    if key == suit.name then
                        is_suit_key = true
                        break
                    end
                end
            end
            
            if not is_suit_key then
                if STRINGS.DP_DevourerPack.EFFECTS[key] then
                    local effect_desc = STRINGS.DP_DevourerPack.EFFECTS[key]
                    
                    if type(value) == "boolean" then
                        -- 布尔值：只显示效果名称，不显示值
                        if value then
                            tooltip_text = tooltip_text .. effect_desc .. "\n"
                        end
                    else
                        -- 数值：处理格式化字符串
                        local display_text = effect_desc
                        local display_value = value
                        
                        -- 检查是否为百分比效果
                        local is_percent = percent_effects[key] or false
                        
                        -- 百分比效果先乘以100
                        if is_percent then
                            display_value = display_value * 100
                        end
                        
                        -- 检查是否包含格式化占位符
                        if string.find(display_text, "%%d") or string.find(display_text, "%%g") or string.find(display_text, "%%s") then
                            -- 包含占位符：替换
                            if type(display_value) == "number" then
                                display_text = string.format(display_text, display_value)
                            else
                                display_text = string.format(display_text, tostring(display_value))
                            end
                        -- 不包含占位符：只显示效果名称，不添加数值后缀
                        -- 有替换就替换，没替换不需要硬给弄个+1之类的
                        end
                        -- add_utils.debug_print("key:" .. key .. " value:" .. tostring(value) .. " display_text:" .. display_text)
                        tooltip_text = tooltip_text .. display_text .. "\n"
                    end
                elseif key == "mod" and STRINGS.DP_DevourerPack.MOD[value] then
                    -- 处理mod字段
                    local mod_desc = STRINGS.DP_DevourerPack.EFFECTS[key] or "模组"
                    tooltip_text = tooltip_text .. string.format("%s: %s\n", mod_desc, STRINGS.DP_DevourerPack.MOD[value])
                end
            end
        end
    end
    
    -- 设置悬浮提示
    if tooltip_text ~= "" then
        widget:SetHoverText(tooltip_text, { font = NEWFONT_OUTLINE, offset_y = 90 })
    end
    
    return widget
end

-- 显示已吞噬效果页面
function DevourerPackControlPanel:ShowDevourEffectsPage()
    -- 初始化等级标签页状态
    self.effect_level_tab = self.effect_level_tab or 1 -- 默认显示1级效果
    local maxlevel = 3 -- 最大等级
    local font_size = self.font_size - 7
    
    -- 获取背包等级
    local pack_level = 1
    if self.devourer_pack and self.devourer_pack.replica.devourer then
        pack_level = self.devourer_pack.replica.devourer.packlv and self.devourer_pack.replica.devourer.packlv.level or 1
    end
    
    -- 获取已吞噬效果数据
    local all_effects = {} 
    if self.devourer_pack and self.devourer_pack.replica.devourer then
        all_effects = self.devourer_pack.replica.devourer.upgrade_effects or {}
    end
    
    -- 统一处理效果累加，参考_HandleMoonrockCheck
    local numeric_totals = {}
    local boolean_effects = {}
    local suit_counts = {} -- 存储套装效果的当前数量
    for prefab, effect_data in pairs(all_effects) do
        if effect_data.enab and (not effect_data.max or effect_data.cur > 0) then
            -- 计算该物品对套装效果的贡献值（没有cur就默认1）
            local contribution = effect_data.cur or 1
            
            for stat, value in pairs(effect_data) do
                -- 跳过不需要显示的字段
                if stat ~= "max" and stat ~= "cur" and stat ~= "show" and stat ~= "enab" and stat ~= "name" then
                    if not add_configs.excluded_attrs[stat] then
                        if type(value) == "number" then
                            -- 数值效果：累加
                            numeric_totals[stat] = (numeric_totals[stat] or 0) + (value * contribution)
                        elseif type(value) == "boolean" and value then
                            -- 布尔效果：只添加一次
                            if not boolean_effects[stat] then
                                boolean_effects[stat] = STRINGS.DP_DevourerPack.EFFECTS[stat] or stat
                            end
                        end
                    end
                end
            end
            
            -- 检查该物品是否属于任何套装效果
            for suit_key, _ in pairs(self.suits_config) do
                if effect_data[suit_key] then
                    -- 该物品属于套装效果，累加贡献值
                    suit_counts[suit_key] = (suit_counts[suit_key] or 0) + contribution
                end
            end
        end
    end
    
    -- -- 调试：打印套装效果计数
    -- add_utils.debug_print("套装效果计数：")
    -- for suit_key, count in pairs(suit_counts) do
    --     local suit_name = STRINGS.DP_DevourerPack.EFFECTS[suit_key] or suit_key
    --     local suit_max = self.suits_config[suit_key] or 1
    --     add_utils.debug_print(string.format("  %s: %d/%d", suit_name, count, suit_max))
    -- end
    
    -- 按等级分组效果，参考BuildEffectMessage
    local effects_by_level = { [1] = {}, [2] = {}, [3] = {} }
    
    -- 处理数值效果
    for stat, total in pairs(numeric_totals) do
        if STRINGS.DP_DevourerPack.EFFECTS[stat] and total > 0 and not suit_counts[stat] then
            -- 确定效果的等级要求
            local effect_level
            if add_configs.level_up.lv1.effect[stat] then
                effect_level = 1
            elseif add_configs.level_up.lv2.effect[stat] then
                effect_level = 2
            else
                effect_level = 3
            end
            
            -- 处理显示值
            local display_value = add_configs.percent_effects[stat] and (total * 100) or total
            
            -- 格式化效果文本
            local formatted_str = string.format(STRINGS.DP_DevourerPack.EFFECTS[stat], display_value)
            add_utils.debug_print("效果:", stat, "总值:", total, "显示值:", display_value, "格式化文本:", formatted_str)
            table.insert(effects_by_level[effect_level], formatted_str)
        end
    end
    
    -- 处理布尔效果
    for stat, effect_str in pairs(boolean_effects) do
        if STRINGS.DP_DevourerPack.EFFECTS[stat] and not suit_counts[stat] then
            -- 确定效果的等级要求
            local effect_level
            if add_configs.level_up.lv1.effect[stat] then
                effect_level = 1
            elseif add_configs.level_up.lv2.effect[stat] then
                effect_level = 2
            else
                effect_level = 3
            end
            
            table.insert(effects_by_level[effect_level], STRINGS.DP_DevourerPack.EFFECTS[stat])
        end
    end
    
    -- 处理套装效果
    for suit_key, count in pairs(suit_counts) do
        if STRINGS.DP_DevourerPack.EFFECTS[suit_key] then
            local suit_name = STRINGS.DP_DevourerPack.EFFECTS[suit_key]
            local suit_max = self.suits_config[suit_key] or 1
            
            -- 格式化套装效果文本：效果名称 当前数量/套装所需数量
            local formatted_suit_effect = suit_name
            if count < suit_max then
                formatted_suit_effect = string.format("%s %d/%d", suit_name, count, suit_max)
            end
            
            -- 确定效果的等级要求
            local effect_level
            if add_configs.level_up.lv1.effect[suit_key] then
                effect_level = 1
            elseif add_configs.level_up.lv2.effect[suit_key] then
                effect_level = 2
            else
                effect_level = 3
            end
            
            add_utils.debug_print(string.format("添加套装效果到等级%d：%s", effect_level, formatted_suit_effect))
            table.insert(effects_by_level[effect_level], formatted_suit_effect)
        end
    end
    
    -- 检查是否有效果
    local has_effects = false
    for level = 1, 3 do
        if #effects_by_level[level] > 0 then
            has_effects = true
            break
        end
    end
    
    -- 如果没有效果数据，显示提示
    if not has_effects then
        local no_data_text = self.buttons_container:AddChild(Text(HEADERFONT, font_size, "暂无激活效果", {0, 0, 0, 1}))
        no_data_text:SetPosition(0, 0)
        return
    end
    
    -- === 预先格式化所有等级的效果文本 ===
    local effect_data = {}
    for level = 1, 3 do
        local effects = effects_by_level[level]
        if #effects > 0 then
            -- 设置颜色：生效白色，未生效黑色
            local is_active = pack_level >= level
            -- local color = is_active and {1, 1, 1, 1} or {0, 0, 0, 1}
            local color = {1, 1, 1, 1} -- 统一白色显示，避免误导用户
            
            -- 格式化效果文本的参数配置
            local line_effect_count = 5 -- 所有行都显示n条效果
            
            -- 格式化效果文本，所有行都显示n条效果
            local formatted_effects = {}
            for i, effect in ipairs(effects) do
                table.insert(formatted_effects, effect)
            
                if i < #effects then
                    table.insert(formatted_effects, "   ")
                end
                -- -- 每n条效果换行
                -- if i % line_effect_count == 0 and i < #effects then
                --     table.insert(formatted_effects, "\n")
                -- else
                --     -- 不是当前行的最后一个，添加两个空格
                --     if i < #effects then
                --         table.insert(formatted_effects, "  ")
                --     end
                -- end
            end
            
            -- 保存格式化后的效果文本和颜色
            effect_data[level] = {
                text = table.concat(formatted_effects),
                color = color
            }
        end
    end
    
    -- === 创建等级标签页 ===
    local tab_container = self.buttons_container:AddChild(Widget("effect_tabs"))
    tab_container:SetPosition(0, self.h * 0.25) -- 调整标签页位置，避免显示在大按钮上面
    
    -- 标签页数据
    local level_tabs = {
        {level = 1, has_effects = #effects_by_level[1] > 0, is_unlocked = pack_level >= 1},
        {level = 2, has_effects = #effects_by_level[2] > 0, is_unlocked = pack_level >= 2},
        {level = 3, has_effects = #effects_by_level[3] > 0, is_unlocked = pack_level >= 3}
    }
    
    -- 筛选有效果的标签页
    local active_tabs = {}
    for _, tab_data in ipairs(level_tabs) do
        -- if tab_data.has_effects then
        --     table.insert(active_tabs, tab_data)
        -- end
        table.insert(active_tabs, tab_data)
    end
    
    -- 标签页配置
    local tab_width = 100
    local tab_height = 40
    local tab_spacing = 120
    local total_width = (math.max(#active_tabs - 1, 0)) * tab_spacing
    local effect_level_text = effect_data[self.effect_level_tab] and effect_data[self.effect_level_tab].text or "无效果"
    local effect_level_color = effect_data[self.effect_level_tab] and effect_data[self.effect_level_tab].color or {0,0,0,1}
    
    local effect_text = tab_container:AddChild(TextButton())
    effect_text:SetText(effect_level_text)
    effect_text:SetFont(HEADERFONT)
    effect_text:SetTextSize(font_size-2)
    effect_text:SetTextColour(unpack(effect_level_color))
    
    -- 移除默认背景和边框，使其只显示文本
    if effect_text.bg then effect_text.bg:Hide() end
    if effect_text.focusimage then effect_text.focusimage:Hide() end
    
    -- 设置文本左对齐
    effect_text.text:SetHAlign(ANCHOR_LEFT) -- 强制左对齐
    effect_text.text:SetVAlign(ANCHOR_TOP) -- 顶部对齐
    effect_text.text:EnableWordWrap(true) -- 启用自动换行
    effect_text.text:SetRegionSize(650, 320) -- 设置文本宽度和高度限制
    
    -- 保存所有标签页按钮，用于后续更新高亮状态
    local tab_buttons = {}
    
    -- 创建标签页按钮
    for i, tab_data in ipairs(active_tabs) do
        -- 获取标签页名称
        local tab_name = STRINGS.NAMES.DEVOURER_PACK_NAMES[tab_data.level] or (tab_data.level .. "级效果")
        
        -- 创建标签页按钮
        local tab_btn = tab_container:AddChild(TextButton())
        tab_btn:SetText(tab_name)
        tab_btn:SetFont(HEADERFONT)
        tab_btn:SetTextSize(20)
        tab_btn:SetTextColour(unpack(WHITE))
        -- 计算并设置标签页位置
        local tab_x = -total_width/2 + (i-1)*tab_spacing - 35
        local tab_y = -85
        tab_btn:SetPosition(tab_x, tab_y)
        -- tab_btn:SetPosition(0, 0)
        
        -- 添加标签页坐标和尺寸日志
        local level_tab_pos = tab_btn:GetPosition()
        local level_tab_size = tab_btn:GetSize() -- 获取按钮本身的尺寸
        local level_tab_text_size = tab_btn.text:GetRegionSize() -- 获取内部文本的尺寸
        add_utils.debug_print("等级标签页:", tab_name, ", 坐标:", level_tab_pos, ", 按钮尺寸:", level_tab_size, ", 文本尺寸:", level_tab_text_size)
        tab_btn.name = "effect_level_tab_" .. tab_data.level
        
        -- 移除默认背景和边框
        if tab_btn.bg then tab_btn.bg:Hide() end
        if tab_btn.focusimage then tab_btn.focusimage:Hide() end
        
        -- 添加自定义边框
        local border = tab_btn:AddChild(Image("images/scoreboard.xml", "scoreboard_frame.tex"))
        border:SetSize(tab_width, tab_height)
        border:SetTint(1, 1, 1, tab_data.level == self.effect_level_tab and 0.5 or 0.1) -- 选中状态高亮
        
        -- 添加未解锁标识
        if not tab_data.is_unlocked then
            local lock_icon = tab_btn:AddChild(Image("images/hud.xml", "craft_slot_locked.tex"))
            lock_icon:SetSize(15, 15)
            lock_icon:SetPosition(tab_width/2 - 10, tab_height/2 - 10)
        end
        
        -- 保存标签页按钮和边框
        tab_buttons[tab_data.level] = {
            button = tab_btn,
            border = border
        }
        
        -- 点击事件：直接更新效果文本
        tab_btn:SetOnClick(function()
            local target_level = tab_data.level
            
            -- 更新当前选中的标签页
            self.effect_level_tab = target_level
            local new_level_text = effect_data[target_level] and effect_data[target_level].text or "无效果"
            local new_level_color = effect_data[target_level] and effect_data[target_level].color or {0,0,0,1}
            
            -- 更新效果文本
            effect_text:SetText(new_level_text)
            effect_text:SetTextColour(unpack(new_level_color))
            
            add_utils.debug_print("切换到效果等级标签页:", target_level, 
                    ", 效果文本:", new_level_text)
            -- 更新所有标签页的高亮状态
            for level, tab_info in pairs(tab_buttons) do
                if level == target_level then
                    tab_info.border:SetTint(1, 1, 1, 0.5) -- 选中状态高亮
                else
                    tab_info.border:SetTint(1, 1, 1, 0.1) -- 未选中状态
                end
            end
            -- if tab_data.is_unlocked then -- 只有已解锁的等级才能切换
            -- else
            --     add_utils.debug_print("尝试切换到未解锁的效果等级:", tab_data.level)
            -- end
        end)
    end
    
    local text_region_w, text_region_h = effect_text.text:GetRegionSize() -- 获取内部文本的尺寸
    -- local text_region_w, text_region_h = effect_text:GetRegionSize()
    -- effect_text:SetPosition(text_region_w + 45, -85-text_region_h) -- 调整到标签页下方
    effect_text:SetPosition(125, -285) -- 调整到标签页下方
    
    -- 添加效果文本坐标和尺寸日志
    local text_pos = effect_text:GetPosition()
    local text_size = effect_text:GetSize() -- 获取按钮本身的尺寸
    add_utils.debug_print("效果文本,坐标:", text_pos, ", 按钮尺寸:", text_size, ", 文本尺寸:", text_region_w, text_region_h)
    
    -- 控制分页按钮显示，当前版本暂不分页
    self.arr_l:Hide()
    self.arr_r:Hide()
end

-- 创建文本按钮（核心实现，遵循EquipUpdate的监听器管理风格）
function DevourerPackControlPanel:CreateTextButton(key, cfg)
    local widget = Widget("textbtn_" .. key)
    
    -- 1. 左侧说明文本
    local label = widget:AddChild(Text(HEADERFONT, self.font_size - 2, cfg.name, {0, 0, 0, 1}))
    local label_width = label:GetRegionSize()
    label:SetPosition(label_width / 2 - 15, 0)
    
    -- 2. 右侧可点击文本框
    local text_btn = widget:AddChild(TextButton())
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
        -- add_utils.debug_print("更新显示文本，key:", key, ", 当前值:", current_val, ", 显示文本:", display_text)
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
        -- is_hotkey = false 表示这是面板调用，不是快捷键调用
        SendModRPCToServer(
            MOD_RPC["devourer_pack"]["SetControl"],
            key, 
            desired_value,
            callback_id,  -- 传递唯一ID
            false         -- is_hotkey: 面板调用不需要额外通知
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

function DevourerPackControlPanel:OnOpen(devourer_pack)
    add_utils.debug_print("进入OnOpen，准备开启吞噬者背包控制面板")
    self.devourer_pack = devourer_pack
    -- 注册全局监听器（绑定到玩家身上）
    self:RegisterGlobalListener()
    
    -- 执行原OnOpen的逻辑
    self:RefreshConfigData(devourer_pack)
    self:RefreshContent()
    self:Show() -- 显示面板
    self.isopen = true
    add_utils.debug_print("开启吞噬者背包控制面板完毕")
end

-- 关闭（模仿EquipUpdate的监听器和任务清理方式）
function DevourerPackControlPanel:OnClose()
    -- 隐藏面板
    self:Hide()

    -- 清理全局监听器（先检查再移除）
    if self.player._devourer_pack_control_updated then
        self.player:RemoveEventCallback("devourer_control_updated", self.player._devourer_pack_control_updated)
        self.player._devourer_pack_control_updated = nil
    end
    
    -- -- 清理背包上的升级效果监听器
    -- if self.devourer_pack and self.devourer_pack._devourer_pack_upgrade_updated then
    --     self.devourer_pack:RemoveEventCallback("devourer_upgrade_effects_updated", self.devourer_pack._devourer_pack_upgrade_updated)
    --     self.devourer_pack._devourer_pack_upgrade_updated = nil
    -- end
    
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
    add_utils.debug_print("关闭吞噬者背包控制面板")
end

-- 检查atlas是否包含指定纹理
local function checkAtlas(xml, tex)
    xml = xml and resolvefilepath_soft(xml) or xml
    return xml and TheSim:AtlasContains(xml, tex) and xml
end

-- 获取物品图片的灵活实现，基于群鸟绘卷的逻辑
function DevourerPackControlPanel:GetItemImage(prefab)
    if not prefab then
        return resolvefilepath_soft("modicon.xml"), "modicon.tex"
    end
    
    local tex = prefab .. ".tex"
    local atlas = GetInventoryItemAtlas(tex)
    
    -- 1. 检查默认atlas是否包含纹理
    if checkAtlas(atlas, tex) then
        return atlas, tex
    end
    
    -- 2. 检查GetTexAsset返回的结果
    local gettex_asset = GetTexAsset(prefab)
    if gettex_asset then
        local gettex_atlas = GetInventoryItemAtlas(gettex_asset)
        if checkAtlas(gettex_atlas, gettex_asset) then
            return gettex_atlas, gettex_asset
        end
    end
    
    -- 3. 检查prefab的assets列表
    local p_data = Prefabs[prefab]
    if p_data then
        local p_assets = p_data.assets
        for _, asset in ipairs(p_assets) do
            local alt, img
            local skip_current = false
            
            if asset.type == "INV_IMAGE" then
                img = asset.file .. '.tex'
                alt = GetInventoryItemAtlas(img)
            elseif asset.type == "ATLAS" then
                alt = asset.file
                img = tex
            elseif asset.type == "IMAGE" then
                -- 提取文件名
                img = asset.file
                local file_name = string.match(img, "([^/]+)$")
                if file_name then
                    img = file_name
                    alt = GetInventoryItemAtlas(img)
                else
                    skip_current = true
                end
            end
            
            if not skip_current then
                if alt and img and checkAtlas(alt, img) then
                    return alt, img
                end
                
                -- 额外检查INV_IMAGE的quagmire前缀情况
                if asset.type == "INV_IMAGE" then
                    img = 'quagmire_' .. asset.file .. '.tex'
                    alt = GetInventoryItemAtlas(img)
                    if checkAtlas(alt, img) then
                        return alt, img
                    end
                end
            end
        end
    end
    
    -- 4. 检查所有可能的官方图集
    local official_atlases = {
        "images/inventoryimages1.xml",
        "images/inventoryimages2.xml",
        "images/inventoryimages3.xml",
        "images/inventoryimages4.xml",
        "images/inventoryimages5.xml",
        "images/quagmire_recipebook.xml",
        "images/quagmire_recipebook_2.xml",
        "images/quagmire_recipebook_3.xml",
    }
    
    -- 尝试使用不同的图片文件名变体
    local image_variants = {
        prefab .. ".tex",
        gettex_asset or prefab .. ".tex",
        prefab .. ".png"
    }
    
    for _, img in ipairs(image_variants) do
        for _, official_atlas in ipairs(official_atlases) do
            if checkAtlas(official_atlas, img) then
                return official_atlas, img
            end
        end
    end
    
    -- 5. 检查mod常见图集路径
    local mod_atlases = {
        "images/inventoryimages/inventoryimages.xml",
        "images/inventoryimages/"..prefab..".xml",
        "images/"..prefab..".xml"
    }
    
    for _, img in ipairs(image_variants) do
        for _, mod_atlas in ipairs(mod_atlases) do
            if checkAtlas(mod_atlas, img) then
                return mod_atlas, img
            end
        end
    end
    
    -- 6. 检查scrapbook图标
    local scrapbook_atlas = GetScrapbookIconAtlas(tex)
    if checkAtlas(scrapbook_atlas, tex) then
        return scrapbook_atlas, tex
    end
    
    -- 7. 检查modicon.xml作为最后后备
    local modicon_atlas = resolvefilepath_soft("modicon.xml")
    if modicon_atlas and checkAtlas(modicon_atlas, "modicon.tex") then
        return modicon_atlas, "modicon.tex"
    end
    
    -- 最后返回默认的unknown纹理
    return "images/inventoryimages.xml", "unknown.tex"
end

return DevourerPackControlPanel
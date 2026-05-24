local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"

-- 本地常量定义（替代h_util中的配置）
local LOCAL_CONFIG = {
    -- 屏幕尺寸（直接使用游戏分辨率）
    screen_x = RESOLUTION_X,
    screen_y = RESOLUTION_Y,
    -- 颜色定义（原h_util中的RGB数据）
    RGB = {
        ["白色"] = {1, 1, 1, 1},
        ["沙棕色"] = {0.8, 0.6, 0.4, 1}, -- 沙棕色高亮
        ["黑色"] = {0, 0, 0, 1}
    },
    -- 图标搜索路径（原h_util.xml_path）
    xml_path = {
        "hx_icons1.xml", "hx_icons2.xml", "button_icons.xml", 
        "button_icons2.xml", "serverplaystyles.xml", "quagmire_recipebook.xml",
        "skilltree.xml", "global_redux.xml", "crafting_menu_icons.xml"
    },
    -- 默认图标（找不到时使用）
    default_icon = {xml = "images/ui.xml", tex = "unknown.tex"}
}

-- 吞噬者背包控制面板（独立版本）
local DevourerPackItemPanel = Class(Screen, function(self, owner)
    Screen._ctor(self, "DevourerPackItemPanel")
    self.owner = owner
    self.isopen = false
    self.page = 1  -- 当前页码

    -- 基础设置（与原代码一致）
    self:SetScaleMode(SCALEMODE_FIXEDPROPORTIONAL)
    self:SetMaxPropUpscale(MAX_HUD_SCALE)
    self:SetPosition(0, 0, 0)
    self:SetVAnchor(ANCHOR_MIDDLE)
    self:SetHAnchor(ANCHOR_MIDDLE)

    -- 创建缩放根节点
    self.scalingroot = self:AddChild(Widget("DevourerPackItemPanelscalingroot"))
    self.scalingroot:SetScale(TheFrontEnd:GetHUDScale())

    -- 创建UI根节点
    self.root = self.scalingroot:AddChild(Widget("root"))

    -- 面板尺寸配置（完全复制原代码比例）
    self.height = LOCAL_CONFIG.screen_y * 0.82
    self.width = self.height * 0.78
    self.spacing_y = self.width / 5.8
    self.split_height = 35
    self.margin_x = self.width / 66
    self.margin_y = self.width / 14
    self.num_line = math.floor((self.height - self.split_height) / self.spacing_y) + 1
    self.btn_size = self.width / 10.1
    self.num_col = 6  -- 列数

    -- 初始化界面
    self:MakeFrame()
    self:MakeButtons()

    -- 初始隐藏
    self:Hide()
end)

-- 检查图集是否包含指定纹理（替代h_util中的检查逻辑）
local function CheckAtlas(xml, tex)
    if not xml or not tex then return false end
    local resolved_xml = resolvefilepath_soft(xml)
    return resolved_xml and TheSim:AtlasContains(resolved_xml, tex)
end

-- 获取图标资源（替代h_util:GetPrefabAsset）
function DevourerPackItemPanel:GetIconAsset(prefab)
    if not prefab then return nil, nil end
    prefab = prefab:gsub("%.tex$", ""):gsub("%.png$", "")  -- 移除文件后缀
    
    -- 尝试从物品图集获取
    local tex = prefab .. ".tex"
    local xml = GetInventoryItemAtlas(tex)
    if CheckAtlas(xml, tex) then
        return xml, tex
    end
    
    -- 尝试从本地配置的图集路径搜索
    for _, path in ipairs(LOCAL_CONFIG.xml_path) do
        local full_xml = "images/" .. path
        if CheckAtlas(full_xml, tex) then
            return full_xml, tex
        end
    end
    
    -- 尝试从预制体资源中获取
    local prefab_data = Prefabs[prefab]
    if prefab_data and prefab_data.assets then
        for _, asset in ipairs(prefab_data.assets) do
            if asset.type == "INV_IMAGE" then
                local inv_tex = asset.file .. ".tex"
                local inv_xml = GetInventoryItemAtlas(inv_tex)
                if CheckAtlas(inv_xml, inv_tex) then
                    return inv_xml, inv_tex
                end
            elseif asset.type == "ATLAS" then
                local atlas_tex = prefab .. ".tex"
                if CheckAtlas(asset.file, atlas_tex) then
                    return asset.file, atlas_tex
                end
            end
        end
    end
    
    -- 找不到时返回默认图标
    return LOCAL_CONFIG.default_icon.xml, LOCAL_CONFIG.default_icon.tex
end

-- 创建面板框架（独立实现原h_util:BuildFrame）
function DevourerPackItemPanel:MakeFrame()
    local width, height = self.width, self.height
    local atlas = resolvefilepath(CRAFTING_ATLAS)

    -- 创建框架容器
    local w = Widget("huxi_menu_frame")
    
    -- 背景填充
    w.fill = w:AddChild(Image(atlas, "backing.tex"))
    w.fill:ScaleToSize(width + 10, height + 18)
    w.fill:SetTint(1, 1, 1, 0.3)  -- 半透明白色背景
    
    -- 边框元素
    w.left = w:AddChild(Image(atlas, "side.tex"))
    w.right = w:AddChild(Image(atlas, "side.tex"))
    w.top = w:AddChild(Image(atlas, "top.tex"))
    w.bottom = w:AddChild(Image(atlas, "bottom.tex"))

    -- 边框定位和尺寸
    w.left:SetPosition(-width / 2 - 8, 1)
    w.right:SetPosition(width / 2 + 8, 1)
    w.top:SetPosition(0, height / 2 + 10)
    w.bottom:SetPosition(0, -height / 2 - 8)

    w.left:ScaleToSize(-26, -(height - 20))
    w.right:ScaleToSize(26, height - 20)
    w.top:ScaleToSize(width + 33, 38)
    w.bottom:ScaleToSize(width + 33, 38)

    -- 标题栏
    self.title_panel = w:AddChild(Text(UIFONT, 28, "吞噬者背包吞噬列表", LOCAL_CONFIG.RGB["白色"]))
    self.title_panel:SetPosition(0, height / 2 - 13)

    -- 分割线
    local splitline_y = height / 2 - self.split_height
    local itemlist_split = w:AddChild(Image(atlas, "horizontal_bar.tex"))
    itemlist_split:SetPosition(0, splitline_y)
    itemlist_split:ScaleToSize(width, 15)

    -- 分页箭头按钮
    self.arr_l = w:AddChild(ImageButton("images/frontend.xml", "turnarrow_icon.tex", "turnarrow_icon_over.tex", nil,
        nil, nil, {1, 1}, {0, 0}))
    self.arr_r = w:AddChild(ImageButton("images/frontend.xml", "turnarrow_icon.tex", "turnarrow_icon_over.tex", nil,
        nil, nil, {1, 1}, {0, 0}))
    local arrow_size = self.arr_l:GetSize()
    local arrow_scale = 40 / arrow_size
    self.arr_r:SetNormalScale(arrow_scale)
    self.arr_r:SetFocusScale(arrow_scale * 1.2)
    self.arr_l:SetNormalScale(arrow_scale)
    self.arr_l:SetFocusScale(arrow_scale * 1.2)
    self.arr_r:SetHoverText("下一页")
    self.arr_l:SetHoverText("上一页")

    local move_x, move_y = self.width/2.5, self.split_height/2 + splitline_y + 3
    self.arr_l:SetPosition(-move_x, move_y)
    self.arr_l:SetScale(1, .5, 1)
    self.arr_r:SetPosition(move_x, move_y)
    self.arr_r:SetScale(-1, .5, 1)

    -- 分页按钮事件
    self.arr_l:SetOnClick(function()
        self.page = self.page - 1
        self:MakeButtons()
    end)
    self.arr_r:SetOnClick(function()
        self.page = self.page + 1
        self:MakeButtons()
    end)

    self.title_panel:MoveToFront()
    self.frame = self.root:AddChild(w)
end

-- 创建功能按钮
function DevourerPackItemPanel:MakeButtons()
    if self.btns then
        self.btns:Kill()
    end
    self.btns = self.root:AddChild(Widget("function_buttons"))
    
    -- 计算按钮布局
    local num_col = self.num_col
    local spacing_x = (self.width - 2 * self.margin_x) / num_col
    local x_init = self.margin_x + spacing_x / 2
    local y_init = -self.margin_y
    local num_icon = self.num_line * num_col

    -- 按钮数据（使用prefab名称）
    local buttons_data = {
        {name = "物品整理", imgdata = "package", text = "整理背包物品", func_left = function() print("执行物品整理") end},
        {name = "自动吞噬", imgdata = "meat", text = "自动吞噬物品", func_left = function() print("开启自动吞噬") end},
        {name = "背包扩容", imgdata = "backpack", text = "扩展背包格子", func_left = function() print("执行背包扩容") end},
        {name = "设置面板", imgdata = "settings", text = "打开设置界面", func_left = function() print("打开设置") end},
        {name = "帮助说明", imgdata = "help", text = "查看帮助信息", func_left = function() print("显示帮助") end},
        {name = "丢弃物品", imgdata = "trashcan", text = "快速丢弃物品", func_left = function() print("执行丢弃") end},
        {name = "批量使用", imgdata = "potion_red", text = "批量使用物品", func_left = function() print("批量使用") end},
        {name = "锁定物品", imgdata = "lock", text = "锁定重要物品", func_left = function() print("锁定物品") end},
    }

    -- 控制分页显示
    self.arr_l:Show()
    self.arr_r:Show()
    local page = self.page
    if page <= 1 then
        self.arr_l:Hide()
    end
    if page * num_icon >= #buttons_data then
        self.arr_r:Hide()
    end

    -- 创建当前页按钮
    for i = 1, num_icon do
        local nodot = (page - 1) * num_icon + i
        local icon = buttons_data[nodot]
        if not icon then break end
        
        local x_pos = x_init + ((i - 1) % num_col) * spacing_x
        local y_pos = y_init - math.floor((i - 1) / num_col) * self.spacing_y
        local cus_btn = self.btns:AddChild(self:CustomButton(icon))
        cus_btn:SetPosition(x_pos, y_pos)
    end
    self.btns:SetPosition(-self.width / 2, self.height / 2 - 30)
end

-- 创建自定义按钮
function DevourerPackItemPanel:CustomButton(icon)
    local w = Widget("custom_button")
    
    -- 获取图标资源（使用本地实现的GetIconAsset）
    icon.xml, icon.tex = self:GetIconAsset("unknown")  -- 默认图标
    local icondata = icon.imgdata
    
    if type(icondata) == "table" then
        local xml, tex = icondata.xml, icondata.tex
        if type(xml) == "string" and type(tex) == "string" and CheckAtlas(xml, tex) then
            icon.xml, icon.tex = xml, tex
        end
    elseif type(icondata) == "string" then
        local xml, tex = self:GetIconAsset(icondata)
        if xml then
            icon.xml, icon.tex = xml, tex
        end
    end
    
    -- 创建图标按钮
    w.img = w:AddChild(ImageButton(icon.xml, icon.tex))
    self:SetButtonSize(w.img)
    
    -- 按钮文字
    w.destxt = w:AddChild(Text(UIFONT, self.btn_size / 2 * 10 * 0.1, icon.name, LOCAL_CONFIG.RGB["白色"]))
    w.destxt:SetPosition(0, -self.btn_size * 0.85)
    
    -- 鼠标事件
    local _OnMouseButton = w.img.OnMouseButton
    w.img.OnMouseButton = function(ui, press, down, ...)
        local result = _OnMouseButton(ui, press, down, ...)
        if not down then
            if press == MOUSEBUTTON_LEFT and type(icon.func_left) == "function" then
                icon.func_left()
            elseif press == MOUSEBUTTON_RIGHT and type(icon.func_right) == "function" then
                icon.func_right()
            end
        end
        return result
    end
    
    -- 焦点事件
    local _OnGainFocus = w.img.OnGainFocus
    w.img.OnGainFocus = function(...)
        _OnGainFocus(w.img, ...)
        w.destxt:SetColour(unpack(LOCAL_CONFIG.RGB["沙棕色"]))  -- 沙棕色高亮
        self.title_panel:SetText(icon.text or icon.name)
    end
    local _OnLoseFocus = w.img.OnLoseFocus
    w.img.OnLoseFocus = function(...)
        _OnLoseFocus(w.img, ...)
        w.destxt:SetColour(unpack(LOCAL_CONFIG.RGB["白色"]))
    end

    return w
end

-- 设置按钮大小
function DevourerPackItemPanel:SetButtonSize(img)
    local sizeX, sizeY = img:GetSize()
    local trans_scale = math.min(self.btn_size / sizeX, self.btn_size / sizeY)
    img:SetNormalScale(trans_scale)
    img:SetFocusScale(trans_scale * 1.2)
end

-- 打开面板
function DevourerPackItemPanel:Open()
    if not self.isopen then
        self.isopen = true
        self:Show()
        TheFrontEnd:PushScreen(self)
    end
end

-- 关闭面板
function DevourerPackItemPanel:Close()
    if self.isopen then
        self.isopen = false
        TheFrontEnd:PopScreen(self)
    end
end

-- 处理ESC键关闭
function DevourerPackItemPanel:OnControl(control, down)
    if Screen.OnControl(self, control, down) then return true end
    if not down and control == CONTROL_CANCEL then
        self:Close()
        return true
    end
end

return DevourerPackItemPanel
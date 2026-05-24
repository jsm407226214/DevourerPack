-- 引入必要的模板库（解决 TEMPLATES 未声明错误）
local TEMPLATES = require "widgets/redux/templates"
local PopupDialogScreen = require "screens/redux/popupdialog"

local h_util = {}

-- 屏幕分辨率适配参数
h_util.screen_w, h_util.screen_h = TheSim:GetScreenSize()
h_util.rate_w = h_util.screen_w / 1920  -- 宽度缩放比例（基准1920）
h_util.rate_h = h_util.screen_h / 1080  -- 高度缩放比例（基准1080）
h_util.btn_size = 50 * h_util.rate_w    -- 按钮默认尺寸

-- 激活按钮缩放效果（悬停放大）
function h_util.ActivateBtnScale(UI, size)
    size = size or h_util.btn_size
    if UI and UI.GetSize then
        local x, y = UI:GetSize()
        local nscale = math.min(size * h_util.rate_w / x, size * h_util.rate_w / y)
        UI:SetNormalScale(nscale)
        UI:SetFocusScale(nscale * 1.2)  -- 悬停时放大1.2倍
    end
end

-- 创建图片按钮（复用原版样式逻辑）
function h_util.CreateImageButton(info)
    local xml, tex = info.xml or "images/quagmire_recipebook.xml", info.tex or "cookbook_known.tex"
    local sizes = type(info.size) == "table" and info.size 
        or (type(info.size) == "number" and {info.size, info.size}) 
        or {60, 60}
    
    -- 使用TEMPLATES创建标准按钮（已引入TEMPLATES）
    local btn = TEMPLATES.StandardButton(nil, nil, sizes, {xml, tex})
    
    -- 悬停提示
    if info.hover then
        btn:SetHoverText(info.hover, info.hover_meta or {offset_y = -sizes[1]})
    end
    
    -- 设置位置
    if info.pos then
        btn:SetPosition(info.pos[1], info.pos[2] or 0)
    end
    
    -- 绑定点击事件
    if info.fn then
        btn:SetOnClick(function() info.fn(btn) end)
    end
    
    return btn
end

-- 创建带关闭按钮的弹窗
function h_util.CreatePopupWithClose(title, bodytext, btns)
    -- 处理按钮回调，自动添加关闭逻辑
    local processed_btns = {}
    for _, btn in ipairs(btns or {}) do
        -- print("处理弹窗按钮，文本:", btn.text or "nil")
        table.insert(processed_btns, {
            text = btn.text or "确定",
            cb = function()
                -- 执行按钮自身的回调
                if type(btn.cb) == "function" then
                    btn.cb()
                end
                -- 关闭当前弹窗
                TheFrontEnd:PopScreen()
            end
        })
    end
    
    -- 创建弹窗并显示
    local popup = PopupDialogScreen(title, bodytext, processed_btns)
    TheFrontEnd:PushScreen(popup)
    return popup
end

-- 检查UI是否有效
function h_util.IsValid(ui)
    return ui and ui.inst and ui.inst.widget
end

-- 设置UI位置（支持数组或table格式）
function h_util.SetUIPosition(ui, pos)
    if type(pos) == "table" and (pos[1] or pos.x) then
        ui:SetPosition(Vector3(pos[1] or pos.x, pos[2] or pos.y or 0))
    end
end

local Sounds = {
    learn_map = "dontstarve/HUD/Together_HUD/learn_map",
    research_available = "dontstarve/HUD/research_available",
    click_move = "dontstarve/HUD/click_move",
    click_object = "dontstarve/HUD/click_object",
    click_negative = "dontstarve/HUD/click_negative",
    respec = "wilson_rework/ui/respec",
    research_unlock = "dontstarve/HUD/research_unlock"
}


function h_util:PlaySound(sound)
    sound = Sounds[sound] or sound
    TheFrontEnd:GetSound():PlaySound(sound)
    
end

return h_util
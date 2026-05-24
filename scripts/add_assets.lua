-- 物品名称
PrefabFiles = {
    "devourer_pack", -- 吞噬者背包
    "devourer_pig",
}
-- 物品图标样式
Assets =
{
    Asset("ANIM", "anim/devourer_pack.zip"),
    -- Asset("ANIM", "anim/swap_krampus_sack.zip"),
    Asset("IMAGE", "images/inventoryimages/devourer_pack.tex"),
    Asset("ATLAS", "images/inventoryimages/devourer_pack.xml"),
    
    -- 背包格子背景资源
    Asset("IMAGE", "images/slot_bg_snow.tex"),
    Asset("ATLAS", "images/slot_bg_snow.xml"),
    Asset("IMAGE", "images/slot_bg_fire.tex"),
    Asset("ATLAS", "images/slot_bg_fire.xml"),
    Asset("IMAGE", "images/slot_bg_tool.tex"),
    Asset("ATLAS", "images/slot_bg_tool.xml"),
    Asset("IMAGE", "images/slot_bg_alchemy.tex"),
    Asset("ATLAS", "images/slot_bg_alchemy.xml"),
    Asset("IMAGE", "images/slot_bg_alchemy1.tex"),
    Asset("ATLAS", "images/slot_bg_alchemy1.xml"),
}
-- 物品小地图图标样式
AddMinimapAtlas("images/inventoryimages/devourer_pack.xml")
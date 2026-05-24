local Prefab = require("prefabs")
local Recipe = require("recipe")

local assets = {
    Asset("ANIM", "anim/devourer_food_amulet.zip"),
    Asset("ATLAS", "images/inventoryimages/devourer_food_amulet.xml"),
}

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_amulet", "devourer_food_amulet", "swap_amulet")
    
    -- 保存原始设置
    if owner.components.foodmemory then
        owner._original_foodmemory = {
            duration = owner.components.foodmemory.duration,
            mults = owner.components.foodmemory.mults,
        }
        -- 临时禁用食物记忆效果
        owner.components.foodmemory.mults = {1, 1, 1, 1, 1}
    end
    
    if owner.components.eater then
        owner._original_caneat = owner.caneat
        owner._original_preferseating = owner.preferseating
        -- 临时允许吃所有食物
        owner.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODGROUP.OMNI })
    end
    
    if owner.components.foodaffinity then
        owner._original_foodaffinity = true
        -- 这里可以添加临时修改食物亲和力的代码
    end
    
    owner:AddTag("devourer_food_amulet_equipped")
end

local function OnUnequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_amulet")
    
    -- 恢复原始设置
    if owner._original_foodmemory and owner.components.foodmemory then
        owner.components.foodmemory.duration = owner._original_foodmemory.duration
        owner.components.foodmemory.mults = owner._original_foodmemory.mults
        owner._original_foodmemory = nil
    end
    
    if owner._original_caneat and owner.components.eater then
        owner.components.eater:SetDiet(owner._original_caneat, owner._original_preferseating)
        owner._original_caneat = nil
        owner._original_preferseating = nil
    end
    
    if owner._original_foodaffinity then
        -- 恢复食物亲和力设置
        owner._original_foodaffinity = nil
    end
    
    owner:RemoveTag("devourer_food_amulet_equipped")
end

local function fn()
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    
    MakeInventoryPhysics(inst)
    
    inst.AnimState:SetBank("devourer_food_amulet")
    inst.AnimState:SetBuild("devourer_food_amulet")
    inst.AnimState:PlayAnimation("idle")
    
    inst:AddTag("amulet")
    inst:AddTag("devourer_food_amulet")
    
    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/devourer_food_amulet.xml"
    
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.NECK
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("tradable")
    
    return inst
end

return Prefab("devourer_food_amulet", fn, assets)

local add_configs = require('configs/add_configs')
local add_utils = require('utils/add_utils')

-- 给指定的可升级物品添加升级组件
if add_configs and add_configs.upgrade_effects then
    for prefab_name, effect in pairs(add_configs.upgrade_effects) do
        AddPrefabPostInit(prefab_name, function(inst)
            -- 不可移动的物品添加标签，用于使用背包吞噬时判定
            add_utils.debug_print("Init upgrade_effects for prefab:", prefab_name, ", no_move:", effect and effect.no_move and "yes" or "no")
            if effect and effect.no_move then
                if inst and not inst:HasTag("devourer_no_move") then
                    inst:AddTag("devourer_no_move")
                end

            -- 可移动的物品就直接添加升级组件，拿着物品右键给背包
            else
                -- 仅服务器端执行
                if not GLOBAL.TheWorld.ismastersim then
                    return
                end
                -- 防止重复添加
                if not inst.components.devourer_pack_up then
                    inst:AddComponent("devourer_pack_up")
                end
            end
        end)
    end
end


GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

-- ============================================
-- 核心配置与资源导入
-- ============================================
modimport("scripts/add_tunings.lua")
modimport("scripts/language/language.lua")
modimport("scripts/add_assets.lua")

AddReplicableComponent("devourer")
modimport("scripts/add_recipes.lua")
modimport("scripts/add_containers.lua")
modimport("scripts/add_actions.lua")
modimport("scripts/add_sgs.lua")
modimport("scripts/add_keybind.lua")

-- ============================================
-- 初始化补丁（按功能分门别类放在 scripts/init/）
-- ============================================
modimport("scripts/init/pigking.lua")
modimport("scripts/init/devourer_items_init.lua")
modimport("scripts/init/ui_patches.lua")
modimport("scripts/init/combat_patches.lua")
modimport("scripts/init/creature_patches.lua")
modimport("scripts/init/tag_optimization.lua")
modimport("scripts/init/network_rpc.lua")

-- ============================================
-- 测试模块（仅调试模式）
-- ============================================
if TUNING.DEVOURER_DEBUG then
    modimport("scripts/devourer_test.lua")
end

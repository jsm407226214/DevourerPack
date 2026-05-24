local recipe_type = TUNING.RECIPE_DIFFICULTY

local easy = 
{
    Ingredient("pigskin", 5),                   -- 猪皮
    Ingredient("houndstooth", 5),               -- 犬牙/Hound's Tooth
    Ingredient("silk", 5),                      -- 蜘蛛丝/Silk
    Ingredient("nightmarefuel", 5),             -- 噩梦燃料/Nightmare Fuel
    Ingredient("gears", 5),                     -- 齿轮/Gears
    -- Ingredient("moonrocknugget", 10),           -- 月岩/Moon Rock
    -- Ingredient("goldnugget", 20),               -- 金块/Gold Nugget
}
local ingredientsData = easy
-- local normal =
-- {
--     Ingredient("goose_feather", 1),         -- 麋鹿鹅羽毛
--     Ingredient("dragon_scales", 1),         -- 鳞片
--     Ingredient("bearger_fur", 1),           -- 熊皮
--     Ingredient("deerclops_eyeball", 1),     -- 独眼巨鹿眼球
-- }
-- local hard = 
-- {
--     Ingredient("goose_feather", 1),         -- 麋鹿鹅羽毛
--     Ingredient("dragon_scales", 1),         -- 鳞片
--     Ingredient("bearger_fur", 1),           -- 熊皮
--     Ingredient("deerclops_eyeball", 1),     -- 独眼巨鹿眼球
--     Ingredient("minotaurhorn", 1),          -- 守护者之角
--     Ingredient("shadowheart", 1)            -- 暗影心房
-- }
-- -- 默认正常难度
-- if recipe_type ~= nil then
--     if recipe_type == "easy" then
--         ingredientsData = easy
--     elseif recipe_type == "normal" then
--         ingredientsData = normal
--     elseif recipe_type == "hard" then
--         ingredientsData = hard
--     end
-- else
--     ingredientsData = normal
-- end

-- 吞噬者背包
local devourer_pack_recipe = {
    name = "devourer_pack",
    ingredients = {
        ingredientsData, -- 配方材料
    },
    -- tech = TECH.SCIENCE_TWO, -- 改为炼金引擎（二级科技）
    tech = TECH.NONE, -- 改为炼金引擎（二级科技）
    config = {
        atlas = "images/inventoryimages/devourer_pack.xml",
    },
    filter = { "CONTAINERS" },-- 过滤器，即分类
}
AddRecipe2(devourer_pack_recipe.name, devourer_pack_recipe.ingredients[1], devourer_pack_recipe.tech, devourer_pack_recipe.config, devourer_pack_recipe.filter)
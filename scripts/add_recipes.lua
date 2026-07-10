local recipe_type = TUNING.DP_RECIPE_DIFFICULTY

local easy = 
{
    Ingredient("cutgrass", 10),                  -- 草/Cut Grass
    Ingredient("twigs", 10),                     -- 树枝/Twigs
}
local normal = 
{
    Ingredient("pigskin", 5),                    -- 猪皮
    Ingredient("houndstooth", 5),                -- 犬牙/Hound's Tooth
    Ingredient("silk", 5),                       -- 蜘蛛丝/Silk
    Ingredient("nightmarefuel", 5),              -- 噩梦燃料/Nightmare Fuel
    Ingredient("gears", 5),                      -- 齿轮/Gears
}
local hard = 
{
    Ingredient("goose_feather", 1),              -- 麋鹿鹅羽毛
    Ingredient("dragon_scales", 1),              -- 鳞片
    Ingredient("bearger_fur", 1),                -- 熊皮
    Ingredient("deerclops_eyeball", 1),          -- 独眼巨鹿眼球
}
local nightmare = 
{
    Ingredient("goose_feather", 1),              -- 麋鹿鹅羽毛
    Ingredient("dragon_scales", 1),              -- 鳞片
    Ingredient("bearger_fur", 1),                -- 熊皮
    Ingredient("deerclops_eyeball", 1),          -- 独眼巨鹿眼球
    Ingredient("minotaurhorn", 1),               -- 守护者之角
    Ingredient("shadowheart", 1),                -- 暗影心房
}

-- 根据难度选择配方和科技
local ingredientsData = normal
local techLevel = TECH.NONE
if recipe_type ~= nil then
    if recipe_type == "easy" then
        ingredientsData = easy
        techLevel = TECH.NONE
    elseif recipe_type == "normal" then
        ingredientsData = normal
        techLevel = TECH.NONE
    elseif recipe_type == "hard" then
        ingredientsData = hard
        techLevel = TECH.SCIENCE_ONE
    elseif recipe_type == "nightmare" then
        ingredientsData = nightmare
        techLevel = TECH.SCIENCE_TWO
    end
end

-- 吞噬者背包
local devourer_pack_recipe = {
    name = "devourer_pack",
    ingredients = {
        ingredientsData, -- 配方材料
    },
    tech = techLevel,
    config = {
        atlas = "images/inventoryimages/devourer_pack.xml",
    },
    filter = { "CONTAINERS" },-- 过滤器，即分类
}
AddRecipe2(devourer_pack_recipe.name, devourer_pack_recipe.ingredients[1], devourer_pack_recipe.tech, devourer_pack_recipe.config, devourer_pack_recipe.filter)
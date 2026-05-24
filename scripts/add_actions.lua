local require = require
local add_configs = require('configs/add_configs')
local add_utils = require('utils/add_utils')

-- 系统定义的场景有5个，分别使用不同的参数

-- SCENE：参数inst, doer, actions, right。这一场景指的是在游戏主界面上对着实体的操作。比如右键点击收获浆果。
-- USEITEM：参数inst, doer, target, actions, right。这一场景是选取一件物品，再点击地图上的东西或装备栏的物品，比如给篝火添加燃料
-- POINT：参数inst, doer, pos, actions, right。这一场景指的是对地图上任意一点执行的操作，比如装备传送法杖后，你可以右键点击地板，传送过去。
-- EQUIPPED：参数inst, doer, target, actions, right。这一场景指的是装备了一件物品后，可以实施的操作，比如装备斧头后可以砍树。
-- INVENTORY：参数inst, doer, actions, right。这一场景是点击物品栏执行的操作。比如右键点击物品栏里的木甲，就会自动装备到身上。
-- ISVALID：参数inst, action, right。这个不是定义的场景，是用于检测动作是否合法的，我们可以忽略它。

-- testcomponent：指定组件名，比如“inventoryitem”，如果是USEITEM，表示只有当实体(testfn的inst)有这个组件时，才会触发这个动作。譬如我使用背包吞噬物品，背包必须有devourer组件
local devourer_pack_action = function(actionid, actionstr, actionfn, actionconfig, actionsg, testtype, testcomponent, testfn)
    local act = Action(actionconfig)
    act.id = actionid
    act.str = actionstr
    act.fn = actionfn
    AddAction(act)
    AddComponentAction(testtype, testcomponent, testfn)

    AddStategraphActionHandler("wilson",ActionHandler(ACTIONS[actionid], actionsg))
    AddStategraphActionHandler("wilson_client",ActionHandler(ACTIONS[actionid], actionsg))
end
local actionList = {
    -- 使用物品右键给吞噬者背包，增加背包的功能和升级
    {
        actionid = "DEVOURER_PACK_UP",
        actionstr = STRINGS.DP_DEVOUR_ACTION,
        actionfn = function(act)
            -- 验证必需组件
            local item = act.invobject -- 物品（升级物品）
            local doer = act.doer -- 执行者（玩家）
            local target = act.target -- 目标（吞噬者背包）
            if not (target and item and doer) then
                local missing = {}
                if not act.target then table.insert(missing, "目标") end
                if not act.invobject then table.insert(missing, "物品") end
                if not act.doer then table.insert(missing, "执行者") end
                return false 
            end
            -- 检查必需函数
            if not act.target.components.devourer and act.target.components.devourer.OnDevourer ~= nil then
                return false
            end
            -- 执行升级
            -- 【服务端逻辑】决定你“点完后这个功能（升级/消耗/属性变化）最终能不能成功”
            local success = act.target.components.devourer:OnDevourer(item, doer)
            return success
        end,
        actionconfig = {priority = 100, mount_valid = true},
        actionsg = "give",
        testtype = "USEITEM",
        testcomponent = "devourer_pack_up",
        testfn = function(inst, doer, target, actions, right)
            if target:HasTag("devourer_pack") then
                local check -- UI判定用 replica（Check）
                -- 【客户端逻辑】决定你“能不能看到/点到这个按钮”
                if target.replica.devourer and target.replica.devourer.Check then
                    check = target.replica.devourer:Check(inst)
                end
                if check then
                    table.insert(actions, ACTIONS.DEVOURER_PACK_UP)
                end
            end
        end
    },
    -- 使用吞噬者背包去右键吞噬物品（可以吞噬部分不能移动/不能拿着的建筑或者生物或者装备）
    {
        actionid = "DEVOUR_NO_MOVE",
        actionstr = STRINGS.DP_DEVOUR_ACTION,
        actionfn = function(act)
            -- 验证必需组件
            local target = act.target -- 目标（升级物品）
            local inst = act.invobject -- 物品（吞噬者物品）
            local doer = act.doer -- 执行者（玩家）
            add_utils.debug_print("Action DEVOUR, target:", target and target.prefab or "nil", ",inst:",inst and inst.prefab or "nil",",doer:",doer and doer.prefab or "nil")
            -- 验证必需数据
            if not (target and inst and doer) then
                return false
            end
            local devourer = inst.components.devourer
            -- 检查必需函数
            if not (devourer and devourer.OnDevourer) then
                -- print("No OnDevourer")
                return false
            end
            -- 执行升级
            -- 【服务端逻辑】决定你“点完后这个功能（升级/消耗/属性变化）最终能不能成功”
            local success = devourer:OnDevourer(target, doer)
            return success
        end,
        actionconfig = {priority = 99, mount_valid = true},
        actionsg = "give",
        testtype = "USEITEM",
        testcomponent = "devourer",
        testfn = function(inst, doer, target, actions, right)
            add_utils.debug_print("Action TEST DEVOUR, target:", target and target.prefab or "nil", ",inst:",inst and inst.prefab or "nil",",doer:",doer and doer.prefab or "nil")
            add_utils.debug_print("Target has tag devourer_no_move:", target and target:HasTag("devourer_no_move") and "yes" or "no")
            if target:HasTag("devourer_no_move") then --必须具备无法移动的可吞噬物品标签，才可以吞噬
                local check -- UI判定用 replica（Check）
                -- 【客户端逻辑】决定你“能不能看到/点到这个按钮”
                local devourer = inst.replica.devourer
                add_utils.debug_print("Replica devourer:", devourer and "yes" or "no")
                if devourer and devourer.Check then
                    check = devourer:Check(target)
                end
                if check then
                    table.insert(actions, ACTIONS.DEVOUR_NO_MOVE)
                end
            end
        end
    },
    -- 可以继续添加其他动作...
}
for _,v in pairs(actionList) do
    devourer_pack_action(v.actionid, v.actionstr, v.actionfn, v.actionconfig, v.actionsg, v.testtype, v.testcomponent, v.testfn)
end
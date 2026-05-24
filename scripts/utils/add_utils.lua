local utils = {}
function utils.debug_print(...)
    -- TUNING.DEVOURER_DEBUG = true
    if TUNING.DEVOURER_DEBUG then
        print(...)
    end
end

function utils.deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

-- 浅拷贝（只复制第一层）
function utils.ShallowCopy(original)
    if type(original) ~= "table" then return original end
    local copy = {}
    for k, v in pairs(original) do
        copy[k] = v
    end
    return copy
end

-- 合并多个表（覆盖式）
function utils.MergeTables(...)
    local result = {}
    for i = 1, select('#', ...) do
        local t = select(i, ...)
        if t then
            for k, v in pairs(t) do
                result[k] = v
            end
        end
    end
    return result
end

-- function utils.GetDevourerPack(player)
--     if not player or not player:HasTag("player") then
-- 		utils.debug_print("GetDevourerPack: 无效的玩家实体")
--         return
--     end
--     -- 检查装备栏
--     if player.components.inventory and player.components.inventory.equipslots then
--         for _, item in pairs(player.components.inventory.equipslots) do
--             if item and item.prefab == "devourer_pack" then
--                 return item
--             end
--         end
-- 	else
-- 		utils.debug_print("GetDevourerPack: 玩家没有装备栏组件")
--     end
-- end
function utils.GetDevourerPack(player, exclude_item)
    if not player or not player:HasTag("player") then
        utils.debug_print("GetDevourerPack: 无效的玩家实体")
        return nil
    end

    local inventory = nil
    if TheWorld.ismastersim then
        inventory = player.components.inventory
        if not inventory then
            utils.debug_print("GetDevourerPack: 服务端未找到 inventory")
            return nil
        end
    else
        inventory = player.replica.inventory
        if not inventory then
            utils.debug_print("GetDevourerPack: 客户端未找到 inventoryreplica")
            return nil
        end
    end

    if inventory then
        if TheWorld.ismastersim then
            if inventory.equipslots then
                for _, item in pairs(inventory.equipslots) do
                    if item and item.prefab == "devourer_pack" and item ~= exclude_item then
                        return item
                    end
                end
            end
            if inventory.itemslots then
                for _, item in pairs(inventory.itemslots) do
                    if item and item.prefab == "devourer_pack" and item ~= exclude_item then
                        return item
                    end
                end
            end
        else
            local slots = {EQUIPSLOTS.HEAD, EQUIPSLOTS.BODY, EQUIPSLOTS.BACK, EQUIPSLOTS.HANDS}
            for _, slot in ipairs(slots) do
                local item = inventory:GetEquippedItem(slot)
                if item and item.prefab == "devourer_pack" and item ~= exclude_item then
                    return item
                end
            end
        end
    else
        utils.debug_print("GetDevourerPack: 未找到装备栏组件")
    end

    return nil
end
--[[作者:风铃
版本:v0.2
需要的自提
]]
--调用示例 获取upvalue
--[[
	local upvaluehelper = require "utils/upvaluehelp"
	local containers = require "containers"
	local params = upvaluehelper.Get(containers.widgetsetup,"params")  --获取containers.widgetsetup的名为 params的upvalue 必须在containers.widgetsetup 或者他调用的程序里使用到了 params 
	if params then
		params.cookpot.itemtestfn = function() ... end					--因为返回值是表 可以直接操作 否则需要使用Set
	end
]]--
local visit = {}    --保存已经访问的 防止有嵌套
local visitnum = 0
local function TryToClose(name,value,level)
    if name  or value then      --一旦有返回值了 代表找到了 
        visit = {}
        visitnum = 0
        return value
    end
    if level == 1 then          --只有没找到才会执行到这儿
        visit = {}
        visitnum = 0
    end
end
function utils.Get(fn,name,file)	
    local level = visitnum + 1
	if type(fn) ~= "function" then TryToClose(nil,nil,level) return end
    if visit[fn] then TryToClose(nil,nil,level) return end      --已访问过就返回
    visit[fn] = 1
    visitnum = visitnum + 1
    local i = 1
	while true do
		local upname,upvalue = debug.getupvalue(fn,i)
        if not upname then break end    --已经没了 跳出
		if upname and upname == name then
			if file and type(file) == "string" then			--限定文件 防止被别人提前hook导致取错
				local fninfo = debug.getinfo(fn)
				if fninfo.source and fninfo.source:match(file) then
					return TryToClose(upname,upvalue,level)
				end
			else
				return TryToClose(upname,upvalue,level)
			end
		end
		if upvalue and type(upvalue) == "function" and not visit[upvalue] then  --没有访问过的
			local upupvalue  = Get(upvalue,name,file) --找不到就递归查找
			if upupvalue then return TryToClose(name,upupvalue,level) end
		end
        i = i + 1
	end
    TryToClose(nil,nil,level)   --都没找到也要清除缓存
end

--调用示例 设置upvalue
--[[
local upvaluehelper = require "utils/upvaluehelp"
	local containers = require "containers"
	local newtable = {}
	local params = upvaluehelper.Set(containers.widgetsetup,"params",newtable)  --获取containers.widgetsetup的名为 params的upvalue 

]]--

function utils.Set(fn,name,set,file)
    local level = visitnum + 1
    if type(fn) ~= "function" then TryToClose(nil,nil,level) return end
    if visit[fn] then TryToClose(nil,nil,level) return end      --已访问过就返回
    visit[fn] = 1
    visitnum = visitnum + 1
    local i = 1
	while true do
		local upname,upvalue = debug.getupvalue(fn,i)
        if not upname then break end    --已经没了 退出
		if upname and upname == name then
			if file and type(file) == "string" then			--限定文件 防止被别人提前hook导致取错
				local fninfo = debug.getinfo(fn)
				if fninfo.source and fninfo.source:match(file) then
					return TryToClose(debug.setupvalue(fn,i,set),nil,level)
				end
			else
				return TryToClose(debug.setupvalue(fn,i,set),nil,level)
			end
		end
		if upvalue and type(upvalue) == "function" and not visit[upvalue] then
			local upupvalue  = Set(upvalue,name,set,file) --找不到就递归查找
			if upupvalue then return TryToClose(upupvalue,nil,level) end
		end
        i = i + 1
	end
    TryToClose(nil,nil,level)   --都没找到也要清除缓存
end

local function FunctionTest(fn,file,test,source,listener)
	if fn and type(fn) ~= "function" then return false end
	local data = debug.getinfo(fn)
	if file and type(file) == "string" then		--文件名判定
		local matchstr = "/"..file..".lua" 
		if not data.source or not data.source:match(matchstr) then
			return false
		end
	end
	if test and type(test) == "function" and  not test(data,source,listener) then return false end	--测试通过
	return true
end

--调用示例 获取指定事件的函数 并移除
--[[
	local upvaluehelper = require "utils/upvaluehelp"
	local fn = upvaluehelper.GetEventHandle(TheWorld,"ms_lightwildfireforplayer","components/wildfires")
	
	
	if fn then
		TheWorld:RemoveEventCallback("ms_lightwildfireforplayer",fn)
	end
	
]]--

function utils.GetEventHandle(inst,event,file,test)
	if type(inst) == "table" then
		if inst.event_listening and inst.event_listening[event] then		--遍历他在监听的事件 我在监听谁
			local listenings = inst.event_listening[event]
			for listening,fns in pairs(listenings) do		--遍历被监听者
				if fns and type(fns)=="table" then
					for _,fn in pairs(fns) do
						if FunctionTest(fn,file,test,listening,inst) then	--寻找成功就返回
							return fn
						end
					end
				end
			end
		end
	
	
		if inst.event_listeners and inst.event_listeners[event] then	--遍历监听他的事件的	谁在监听我
			local listeners = inst.event_listeners[event]
			for listener,fns in pairs(listeners) do		--遍历监听者
				if fns and type(fns)=="table" then
					for _,fn in pairs(fns) do
						if FunctionTest(fn,file,test,inst,listener) then	--寻找成功就返回
							return fn
						end
					end
				end
			end
		end
	end
end

function utils.MakeUnlimitStackSize(inst)
    -- inst:AddTag("maxstacksize2hm")
    -- if inst.replica and inst.replica.stackable then processstackablereplica(inst.replica.stackable) end
    if not TheWorld.ismastersim then return end
    -- inst:ListenForEvent("stacksizechange", stack_size_changed)
    -- if inst.components.stackable then inst.components.stackable.maxsize = maxsize end
    if inst.components.stackable and inst.components.inventoryitem and inst.components.inventoryitem.canonlygoinpocket then
        inst.components.stackable:SetIgnoreMaxSize(true)
        inst.components.stackable.SetIgnoreMaxSize = nilfn
    end
end

-- 返回模块
return utils
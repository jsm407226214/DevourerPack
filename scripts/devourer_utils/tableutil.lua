local t_util = {}

-- 遍历数组，返回第一个符合条件的元素
function t_util.IGetElement(t, func)
    for _, v in ipairs(t) do
        local ret = func(v)
        if ret then return ret end
    end
end

-- 遍历键值对，返回第一个符合条件的元素
function t_util.GetElement(t, func)
    for k, v in pairs(t) do
        local ret = func(k, v)
        if ret then return ret end
    end
end

-- 数组过滤（返回符合条件的元素组成的新数组）
function t_util.IPairFilter(t, func)
    local _t = {}
    for _, v in ipairs(t) do
        local re = func(v)
        if re then table.insert(_t, re) end
    end
    return _t
end

-- 合并多个表（键值对）
function t_util.MergeMap(...)
    local m = {}
    for _, map in ipairs({...}) do
        for k, v in pairs(map) do m[k] = v end
    end
    return m
end

-- 递归获取表中的值（支持"a.b.c"格式的路径）
function t_util.GetRecur(t, ipt)
    if type(t) ~= "table" then return end
    if type(ipt) == "string" then
        local ret = {}
        for w in ipt:gmatch("[^%.]+") do
            local num = tonumber(w)
            table.insert(ret, num and num or w)
        end
        ipt = ret
    end
    local pt = t
    local function getrecur(num)
        if num > #ipt then return pt end
        pt = pt[ipt[num]]
        return pt and getrecur(num + 1)
    end
    return getrecur(1)
end

-- 检查元素是否在数组中
function t_util.Contains(t, elem)
    for _, v in ipairs(t) do
        if v == elem then return true end
    end
    return false
end

return t_util
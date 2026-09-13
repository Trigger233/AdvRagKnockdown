-- Name: sh_saveestuffs_Savee_ARKD.FunctionHooks.lua
-- Author: Savee14702(Savee)/Savee39672(Nellie)
-- Purpose: Add meta function hooks(so you dont have to modify the functions)
-- DOES NOT SUPPORT DYNAMIC HOOKS(Using Entity as identifier)

-- 始终记得动Meta的严重后果
-- 如果这玩意坏了 你的游戏(这一局)就坏了
--
-- 参考(100%)了luaJIT的skid_detours.lua(就是基于那个)
-- Link: https://github.com/vurvdev/Lua/blob/master/LuaJIT/Libraries/skid_detours.lua
-- 以及感谢我一位Steam好友的指导让我发现了这玩意

Savee_ARKD.FunctionHooks = {}

local targetMetas = {
    "Entity",
    "NPC",
    "Player",
    "Weapon",
    "Vehicle",
    "CSEnt",
    "NextBot",
    "PhysObj",
    "Vector",
    "Angle",
}
local metas = {
    util = util,
    _G = _G,
}
local hooks = {}
local hooksPost = {}

for _, metaName in pairs(targetMetas) do
    local meta = FindMetaTable(metaName)
    if not meta then continue end
    metas[metaName] = meta
end

local rawFunctions = {}

-- 实际上我并不知道detour是啥
-- 查了一下说是"为了避免某物/顺路拜访什么东西而绕路"
-- 我猜这是顺路拜访, 有些玩意就暂时用这个名字吧
--

local function getKeys(tbl)
    local keys, i = {}, 0

    for k in pairs(tbl) do
        i = i + 1
        keys[i] = k
    end

    return keys
end

local function SortedPairs(pTable, Desc)
    local keys = getKeys(pTable)

    if (Desc) then
        table.sort(keys, function(a, b)
            local a1 = tostring(a)
            local b1 = tostring(b)
            return a1 > b1
        end)
    else
        table.sort(keys, function(a, b)
            local a1 = tostring(a)
            local b1 = tostring(b)
            return a1 < b1
        end)
    end

    local i, key = 1, nil
    return function()
        key, i = keys[i], i + 1
        return key, pTable[key]
    end
end


-- 喜报: 这是local值
-- 你要重启114514遍游戏了

local meta = {
    __index = _G,
    __newindex = _G,  
}

-- 理论上不会有人去把xxx.yyy作为一个key(有了我也懒得做支持.jpg)
local function hasRawFunction(name)
    local tbl = string.Explode(".", name)
    if #tbl == 0 then return end

    local prog = rawFunctions

    -- 发现空值马上扼杀在摇篮(CrackleCradle...????????)
    for i = 1, #tbl do
        prog = prog[tbl[i]]
        if not prog then return false end
    end
    -- 就给个表何意味?
    if not isfunction(prog) then return false end
    return true, prog
end
local function getRawFunction(name)
    local has, func = hasRawFunction(name)

    if has then return func end

    local tbl = string.Explode(".", name)
    if #tbl == 0 then return end

    local prog = metas
    local rawProg = rawFunctions

    for _, str in ipairs(tbl) do
        --print(_)
        prog = prog[str]
        if not prog then return end
        rawProg[str] = isfunction(prog) and prog or rawProg[str] or {}
        rawProg = rawProg[str]
    end
    if not isfunction(prog) then return false end
    return prog
end
-- 琪露诺性值得商榷
local function getCurFunction(name)
    local tbl = string.Explode(".", name)
    if #tbl == 0 then return end

    local prog = metas

    for _, str in ipairs(tbl) do
        prog = prog[str]
        if not prog then return end
    end
    if not isfunction(prog) then return false end
    return prog
end

-- SWAP ALPHA
-- 哦什么没有人啊, 那你REFORM BODY吧
local function reformFunction(name)
    --do return end

    local function func()
        local funcs = {}

        local raw = getRawFunction(name)
        local tbl = string.Explode(".", name)
        if #tbl == 0 then return end
        --print(name)

        local prog = metas
        local hooks = hooks
        local hooksPost = hooksPost

        local funcID = tbl[#tbl]
        for i = 1, #tbl do
            local str = tbl[i]
            hooks[str] = hooks[str] or {}
            hooks = hooks[str]
            hooksPost[str] = hooksPost[str] or {}
            hooksPost = hooksPost[str]

            if i == #tbl then continue end
            prog[str] = prog[str] or {}
            prog = prog[str]
        end
        --prog[funcID] = raw
        prog[funcID] = function(ent, inp, ...)
            --print(ent, inp, ...)
            --if SERVER then print(name .. "_Post_Final") end
            return ...
        end

        --PrintTable(metas.Entity)
        --print(prog[funcID])
        --do return end

        local function addFunction(key, func)
            local tbl = {
                __raw = raw,
                __undetoured = prog[funcID],
            }
            setmetatable(tbl, meta)
            if isentity(key) then
                local oldFunc = func
                setfenv(oldFunc, tbl)
                func = function(...)
                    if not IsValid(key) then return __undetoured(...) end
                    --if SERVER then print(name .. "_RUN_" .. tostring(key)) end
                    return oldFunc(...)
                end
            end
            setfenv(func, tbl)
            funcs[func] = true
            prog[funcID] = func
        end

        for key, func in SortedPairs(hooksPost, true) do
            if isentity(key) and not IsValid(key) then continue end

            if funcs[func] then continue end
            addFunction(key, func)
        end

        addFunction(nil, function(ent, ...)
            local inputs = { ... }
            --if SERVER then print(name .. "_RAW") end
            return __undetoured(ent, inputs, raw(ent, ...))
        end)

        for key, func in SortedPairs(hooks, true) do
            if isentity(key) and not IsValid(key) then continue end

            if funcs[func] then continue end

            addFunction(key, func)
        end
    end

    -- 防止出事, 隔一个tick执行
    -- 虽然对性能没啥大影响吧(真的吗)
    -- 不得不隔一tick进行
    timer.Create("SAVEESTUFFS_FUNCHOOK_REFORM_" .. name, 0, 1, func)
end
-- 修改function
---**始终记得**在末尾引用原function
---@param name string 要修改的函数, 如要修改Player:EyePos()就填Player.EyePos
---@param id string 标识符, 会替换已存在项
---@param func function 函数
---@overload fun(func: fun(caller: any, input: any, ...))
function Savee_ARKD.FunctionHooks.Add(name, id, func)
    --id = tostring(id)

    if isfunction(name) then
        return
    end

    -- 琪露诺性值得商榷
    local tbl = string.Explode(".", name)
    if #tbl == 0 then return end

    local prog = hooks

    for _, str in ipairs(tbl) do
        prog[str] = prog[str] or {}
        prog = prog[str]
    end
    prog[id] = func

    reformFunction(name)

    --PrintTable(hooks)
end

function Savee_ARKD.FunctionHooks.Remove(name, id, func, noReform)
    id = tostring(id)

    -- 琪露诺性值得商榷
    local tbl = string.Explode(".", name)
    if #tbl == 0 then return end

    local prog = hooks

    for _, str in ipairs(tbl) do
        prog[str] = prog[str] or {}
        prog = prog[str]
    end
    prog[id] = nil

    reformFunction(name)

    --PrintTable(hooks)
end

-- 修改function的结果
---@param name string 要修改的函数, 如要修改Player:EyePos()就填Player.EyePos
---@param id string 标识符, 会替换已存在项
---@param func function 函数, 在做最后的判定(不跳到下一级)**只需**返还results  对于utils这样没有实体的lua, 最好直接调用results
---@overload fun(func: fun(caller: any, inputs: table?, results: any, ...))
function Savee_ARKD.FunctionHooks.AddPost(name, id, func)
    --id = tostring(id)

    if isfunction(name) then
        return
    end

    -- 琪露诺性值得商榷
    local tbl = string.Explode(".", name)
    if #tbl == 0 then return end

    local prog = hooksPost

    for _, str in ipairs(tbl) do
        prog[str] = prog[str] or {}
        prog = prog[str]
    end
    prog[id] = func

    reformFunction(name)

    --PrintTable(hooks)
end

function Savee_ARKD.FunctionHooks.RemovePost(name, id, func, noReform)
    id = tostring(id)

    -- 琪露诺性值得商榷
    local tbl = string.Explode(".", name)
    if #tbl == 0 then return end

    local prog = hooksPost

    for _, str in ipairs(tbl) do
        prog[str] = prog[str] or {}
        prog = prog[str]
    end
    prog[id] = nil

    reformFunction(name)

    --PrintTable(hooks)
end

function Savee_ARKD.FunctionHooks.HasFunction(name, id)
    --getRawFunction(name)

    -- 琪露诺性值得商榷
    local tbl = string.Explode(".", name)
    if #tbl == 0 then return end

    local prog = hooks

    for _, str in ipairs(tbl) do
        prog[str] = prog[str] or {}
        prog = prog[str]
    end

    return isfunction(prog[id])

    --PrintTable(hooks)
end

function Savee_ARKD.FunctionHooks.HasPostFunction(name, id)
    --getRawFunction(name)

    -- 琪露诺性值得商榷
    local tbl = string.Explode(".", name)
    if #tbl == 0 then return end

    local prog = hooksPost

    for _, str in ipairs(tbl) do
        prog[str] = prog[str] or {}
        prog = prog[str]
    end

    return isfunction(prog[id])

    --PrintTable(hooks)
end

function Savee_ARKD.FunctionHooks.GetRawFunction(name)
    return getRawFunction(name)

    --PrintTable(hooks)
end

--[[

-- EXAMPLE, 也可参见被参考(复制)的代码

Savee_ARKD.FunctionHooks.AddFunction("Entity.EyePos", "test", function(self, ...)

    --print("Ciall3o~")
    -- 不经过任何修改
    print(__raw(self, ...))

    return __undetoured(self, ...)

end)
]]
--PrintTable(rawFunctions)

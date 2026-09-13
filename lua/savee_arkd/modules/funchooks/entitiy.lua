local getController = Savee_ARKD.getController
local handPosDelta = Vector(16, 0, -4)

local entTypeCheck = Savee_ARKD.entTypeCheck
local tickInterval = engine.TickInterval

Savee_ARKD.FunctionHooks.Add("Player.GetShootPos", "Savee_AdvRagKnockdown_Sync", function(ply, raw, ...)
    --if SERVER then print(__undetoured(ply)) end
    --do return __undetoured(ply, ...) end

    local ctrl = getController(ply)
    if raw or not IsValid(ctrl) then return __undetoured(ply, raw, ...) end
    local rag = ctrl:GetRagdoll()

    local wep = ply:GetActiveWeapon()
    local nonFirearm = Savee_ARKD.Shared.DoOriginalHTs[IsValid(wep) and wep:GetHoldType() or ""]
    if nonFirearm then return ply:EyePos(raw, ...) end
    --print(nonFirearm)
    local mtx = rag:GetBoneMatrix(rag:LookupBone("ValveBiped.Bip01_R_Hand"))

    -- 多门游戏支持
    if not mtx then return __undetoured(ply, raw, ...) end
    local pos, ang = mtx:GetTranslation(), mtx:GetAngles()

    local newpos, newang = LocalToWorld(handPosDelta, Angle(), pos, ang)
    local tr = util.TraceLine({
        start = pos,
        endpos = newpos,
        filter = { ply, rag },
        mask = MASK_SHOT,
    })
    --print(tr.Entity)


    return tr.HitPos
end)

--
Savee_ARKD.FunctionHooks.Add("NPC.GetShootPos", "Savee_AdvRagKnockdown_Sync", function(ply, ...)
    --if SERVER then print(__undetoured(ply)) end
    --do return __undetoured(ply, ...) end

    local ctrl = getController(ply)
    if not IsValid(ctrl) then return __undetoured(ply, ...) end
    local rag = ctrl:GetRagdoll()
    local mtx = rag:GetBoneMatrix(rag:LookupBone("ValveBiped.Bip01_R_Hand") or
        rag:LookupBone("ValveBiped.Bip01_R_Forearm"))
    local pos, ang = mtx:GetTranslation(), mtx:GetAngles()

    local newpos, newang = LocalToWorld(handPosDelta, Angle(), pos, ang)
    local tr = util.TraceLine({
        start = pos,
        endpos = newpos,
        filter = { ply, rag },
        mask = MASK_SHOT,
    })
    --print(tr.Entity)


    return tr.HitPos
end)




Savee_ARKD.FunctionHooks.Add("Entity.SetOwner", "Savee_AdvRagKnockdown_AntiBadCollision", function(ent, own, raw, ...)
    if raw or not entTypeCheck(own) then return __undetoured(ent, own, raw, ...) end
    local ctrl = getController(own)

    if not IsValid(ctrl) then return __undetoured(ent, own, raw, ...) end
    local rag = ctrl:GetRagdoll()

    ctrl.OwnerModifiedEnts[ent] = true

    return __undetoured(ent, rag, raw, ...)
end)

Savee_ARKD.FunctionHooks.AddPost("Entity.GetOwner", "Savee_AdvRagKnockdown_AntiBadCollision",
    function(ent, inputs, own, ...)
        local raw = inputs[1]
        if raw or not entTypeCheck(own) then return __undetoured(ent, inputs, own, ...) end

        local ctrl = getController(own)
        if not IsValid(ctrl) or not ctrl.OwnerModifiedEnts[ent] then return __undetoured(ent, inputs, own, ...) end

        return __undetoured(ent, inputs, __raw(ctrl), ...)
    end)

local INE = math.IsNearlyEqual

local lastSysTime_EyePos = -1
Savee_ARKD.FunctionHooks.Add("Entity.EyePos", "Savee_AdvRagKnockdown_Sync", function(ply, raw, ...)
    --do return __undetoured(ply, ...) end
    --error(1)
    --if SERVER then print(1) end
    if raw or not entTypeCheck(ply) then return __undetoured(ply, raw, ...) end

    local ctrl = getController(ply)
    if not IsValid(ctrl) then return __undetoured(ply, raw, ...) end
    local sysTime = SysTime()

    local cache = ctrl.VarCaches["EyePos"]
    if lastSysTime_EyePos >= sysTime and cache then
        return cache
    end
    lastSysTime_EyePos = sysTime + tickInterval()

    local rag = ctrl:GetRagdoll()

    local bone = rag:LookupBone("ValveBiped.Bip01_R_Hand")
    if not bone then return __undetoured(ply, raw, ...) end

    local tr

    local delta = math.Clamp(CLIENT and ctrl.SmoothedRArmDelta or (ctrl:GetRArmDelta() - 0.03) * 10, 0, 1)

    if ctrl:GetAimingWeapon() and delta <= 0.15 then
        local eyeatt = rag:LookupAttachment("eyes")
        if eyeatt == 0 then return __undetoured(ply, raw, ...) end

        local eyepos = rag:GetAttachment(eyeatt).Pos
        local eyeang = rag:GetAttachment(eyeatt).Ang

        tr = util.TraceLine({
            start = eyepos,
            endpos = eyepos + eyeang:Forward() * 5 * (rag.Savee_AdvRagKnockdown_ModelScale or 1),
            filter = { ply, rag },
            mask = MASK_SHOT,
        })
    else
        local pos, ang = rag:GetBonePosition(bone)
        local newhandpos = LocalToWorld(handPosDelta, Angle(), pos, ang)
        tr = util.TraceLine({
            start = pos,
            endpos = newhandpos,
            filter = { ply, rag },
            mask = MASK_SHOT,
        })
    end

    --local wep = ply:GetActiveWeapon()

    -- 简单的解法, 极致的脑瘫
    local final = tr.HitPos - ctrl:GetAimEyeAngles():Forward()

    ctrl.VarCaches["EyePos"] = final
    --print(final)

    return final
end)

local lastSysTime_EyeAngles = -1

Savee_ARKD.FunctionHooks.Add("Entity.EyeAngles", "Savee_AdvRagKnockdown_Sync", function(ply, raw, ...)
    --do return __undetoured(ply, ...) end
    --error(1)
    --if SERVER then print(1) end
    if raw or not entTypeCheck(ply) then return __undetoured(ply, raw, ...) end

    local ctrl = getController(ply)
    local sysTime = SysTime()

    -- 神秘多人游戏bug
    if not IsValid(ctrl) or not ctrl.GetAimEyeAngles then return __undetoured(ply, raw, ...) end

    --print(sysTime - lastSysTime_EyeAngles)
    local cache = ctrl.VarCaches["EyeAng"]
    if lastSysTime_EyeAngles >= sysTime and cache then
        return Angle(cache.p, cache.y, cache.r)
    end


    lastSysTime_EyeAngles = sysTime + tickInterval() * 0.01

    local ea = ctrl:GetAimEyeAngles()
    ea.z = 0
    ea:Normalize()

    local final = SERVER and ea or LerpAngle(FrameTime(), ctrl.LastEyeAng or ea, ea)
    --print(final)
    ctrl.VarCaches["EyeAng"] = final

    return final
end)

-- AI给我提了个醒(是的有人很自恋)
-- 这玩意得留着, 因为大多数SetEyeAngles都是在强健你EyeAngles的Roll(到0)
Savee_ARKD.FunctionHooks.Add("Player.SetEyeAngles", "Savee_AdvRagKnockdown_Sync", function(ply, ang, raw, ...)
    --do return __undetoured(ply, ...) end
    --error(1)
    --if SERVER then print(1) end
    if raw or not entTypeCheck(ply) then return __undetoured(ply, ang, raw, ...) end

    local ctrl = getController(ply)
    if not IsValid(ctrl) then return __undetoured(ply, ang, raw, ...) end
    local oldAng = ctrl:GetAimEyeAngles()
    local roll = oldAng.r

    --[[local delta = ang - oldAng
    delta:RotateAroundAxis(oldAng:Forward(), roll)

    ang = oldAng + delta]]

    ang.r = roll

    return __undetoured(ply, ang, raw, ...)
end)

Savee_ARKD.FunctionHooks.Add("Entity.GetVelocity", "Savee_AdvRagKnockdown_Sync", function(ply, ...)
    if not entTypeCheck(ply) then return __undetoured(ply, ...) end

    local ctrl = getController(ply)
    if not IsValid(ctrl) then return __undetoured(ply, ...) end

    local rag = ctrl:GetRagdoll()

    local vel = SERVER and rag:GetPhysicsObjectNum(0):GetVelocity() or rag:GetVelocity()

    if vel:LengthSqr() <= 64 then
        vel = Vector()
    end
    return vel
end)

Savee_ARKD.FunctionHooks.Add("Entity.GetPos", "Savee_AdvRagKnockdown_Sync", function(ent, raw, ...)
    if raw or not entTypeCheck(ent) then return __undetoured(ent, raw, ...) end
    local ctrl = getController(ent)
    if not IsValid(ctrl) then return __undetoured(ent, raw, ...) end
    local rag = ctrl:GetRagdoll()
    local bone = rag:GetPos()

    return bone
end)
Savee_ARKD.FunctionHooks.Add("Entity.GetAngles", "Savee_AdvRagKnockdown_Sync", function(ent, raw, ...)
    if raw or not entTypeCheck(ent) then return __undetoured(ent, raw, ...) end
    local ctrl = getController(ent)

    if not IsValid(ctrl) then return __undetoured(ent, raw, ...) end
    local rag = ctrl:GetRagdoll()
    local _, ang = rag:GetBonePosition(0)

    return (ang:Up()):Angle()
end)

Savee_ARKD.FunctionHooks.AddPost("Entity.SetPos", "Savee_AdvRagKnockdown_Sync", function(ply, inputs, ...)
    local raw = inputs[2]
    if raw or not entTypeCheck(ply) then return __undetoured(ply, inputs, ...) end

    local ctrl = getController(ply)

    -- 神秘多人游戏bug
    if not IsValid(ctrl) then return __undetoured(ply, inputs, ...) end
    ctrl:CancelGetUp()
    local pos = inputs[1]

    local oldPos = ply:GetPos()
    for _, data in pairs(ctrl.RagPObjs) do
        local pObj = data.pObj
        if not data.physBone or not IsValid(pObj) then continue end
        local wtl = pObj:GetPos() - oldPos

        local oldState = pObj:IsMotionEnabled()

        pObj:EnableMotion(false)
        pObj:SetPos(pos + wtl)
        pObj:EnableMotion(oldState)
    end

    return __undetoured(ply, inputs, ...)
end)

Savee_ARKD.FunctionHooks.Add("Entity.ManipulateBoneAngles", "Savee_AdvRagKnockdown_Sync", function(ply, ...)
    --do return __undetoured(ply, ...) end
    --error(1)
    --if SERVER then print(1) end
    if not ply:IsPlayer() then return __undetoured(ply, ...) end

    local ctrl = getController(ply)
    if not IsValid(ctrl) then return __undetoured(ply, ...) end
    local rag = ctrl:GetRagdoll()

    rag:ManipulateBoneAngles(...)

    return __undetoured(ply, ...)
end)
Savee_ARKD.FunctionHooks.Add("Entity.ManipulateBonePosition", "Savee_AdvRagKnockdown_Sync", function(ply, ...)
    --do return __undetoured(ply, ...) end
    --error(1)
    --if SERVER then print(1) end
    if not ply:IsPlayer() then return __undetoured(ply, ...) end

    local ctrl = getController(ply)
    if not IsValid(ctrl) then return __undetoured(ply, ...) end
    local rag = ctrl:GetRagdoll()

    rag:ManipulateBonePosition(...)

    return __undetoured(ply, ...)
end)

Savee_ARKD.FunctionHooks.Add("Entity.IsOnGround", "Savee_AdvRagKnockdown_Sync", function(ent, ...)
    if ent:IsRagdoll() then return __undetoured(ent, ...) end

    local ctrl = getController(ent)
    if not IsValid(ctrl) then return __undetoured(ent, ...) end

    return ctrl:GetRagdoll():IsOnGround(...)
end)
Savee_ARKD.FunctionHooks.Add("Entity.OnGround", "Savee_AdvRagKnockdown_Sync", function(ent, ...)
    if ent:IsRagdoll() then return __undetoured(ent, ...) end

    local ctrl = getController(ent)
    if not IsValid(ctrl) then return __undetoured(ent, ...) end

    return ctrl:GetRagdoll():OnGround(...)
end)

Savee_ARKD.FunctionHooks.Add("Player.GetAimVector", "Savee_AdvRagKnockdown_Sync", function(ply, raw, ...)
    --do return __undetoured(ply, ...) end

    local ctrl = getController(ply)
    if not IsValid(ctrl) then return __undetoured(ply, raw, ...) end
    local rag = ctrl:GetRagdoll()
    local bone = rag:LookupBone("ValveBiped.Bip01_R_Hand")

    local eyeatt = rag:LookupAttachment("eyes")
    if not bone or eyeatt == 0 then return __undetoured(ply, raw, ...) end

    local eyepos = rag:GetAttachment(eyeatt).Pos

    local handpos, handang = rag:GetBonePosition(bone)
    handpos, handang = LocalToWorld(handPosDelta, Angle(), handpos, handang)

    --[[local tr = util.TraceLine({
        start = eyepos,
        endpos = eyepos + ctrl:GetAimEyeAngles():Forward() * 65536,
        filter = {ply, rag},
        mask = MASK_SHOT,
    })]]

    local finalAV = CLIENT and ctrl.LastEyeAng or ctrl:GetAimEyeAngles()
    --finalAV.r = 0
    --finalAV:Normalize()
    finalAV = finalAV:Forward()


    local av = raw and __raw(ply, ...) or finalAV --(tr.HitPos - eyepos):GetNormalized()
    --print(rDelta)


    return LerpVector(CLIENT and ctrl.SmoothedRArmDelta or math.Clamp((ctrl:GetRArmDelta() - 0.03) * 10, 0, 1), av,
        handang:Forward())
end)


--[[Savee_ARKD.FunctionHooks.Add("Player.IsPlayingTaunt", "Savee_AdvRagKnockdown_TauntOverride", function(ply, ...)

    --do return __undetoured(ply, ...) end

    local ctrl = getController(ply)
    if not IsValid(ctrl) or true then return __undetoured(ply, ...) end

    -- TODO: 把IN_USE检测换了
    return false


end)]]

Savee_ARKD.FunctionHooks.Add("CUserCmd.SetViewAngles", "Savee_AdvRagKnockdown_RecoilCorrection",
    function(cmd, ang, raw, ...)
        if not raw and handlingKnockdownedCmd then
            local oldAng = cmd:GetViewAngles()
            local roll = oldAng.r

            local delta = ang - oldAng
            oldAng:RotateAroundAxis(oldAng:Right(), -delta.p)
            oldAng:RotateAroundAxis(oldAng:Forward(), delta.y)
            oldAng:RotateAroundAxis(oldAng:Up(), delta.r)

            ang = oldAng
        end
        return __undetoured(cmd, ang, raw, ...)
    end)

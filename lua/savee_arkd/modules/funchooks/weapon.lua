-- 武器支持
local getController = Savee_ARKD.getController
local getBoneMatrixPosAng = Savee_ARKD.getBoneMatrixPosAng
local cv_kd_damagecalc_usetakedamage = GetConVar("savee_advragknockdown_knockdown_usetakedamage")
local handPosDelta = Vector(16, 0, -4)

local isSP = game.SinglePlayer()
hook.Add("EntityFireBullets", "Savee_AdvRagKnockdown_HitScanMod", function(ent, bullet)
    --local wep = ent
    if ent:IsWeapon() then ent = ent:GetOwner() end

    if SERVER then
        local cb = bullet.Callback
        bullet.Callback = function(attacker, btr, di)
            local rag = btr.Entity


            local ctrl = getController(rag)
            if IsValid(ctrl) and IsValid(rag) and rag:IsRagdoll() then
                local own = ctrl:GetOwner()

                local tr = util.TraceHull({
                    start = btr.HitPos,
                    endpos = btr.HitPos,
                    whitelist = true,
                    filter = rag,
                    getRaw = true,
                    mask = MASK_ALL,
                    mins = Vector(-2, -2, -2),
                    maxs = Vector(2, 2, 2),
                })
                local bone = rag:TranslatePhysBoneToBone(tr.PhysicsBone)
                local hitGroup = rag.Savee_AdvRagKnockdown_HitGroups[bone]

                -- 神秘Bug, 我忘记重名的事了
                btr.HitBoxBone = bone
                btr.HitBox = rag.Savee_AdvRagKnockdown_HitBoxes[bone] or btr.HitBox
                btr.HitGroup = hitGroup or
                    btr.HitGroup --own:GetHitBoxHitGroup(rag.Savee_AdvRagKnockdown_HitBoxes[bone], 0)
                btr.Entity = own
            end
            local result

            if cb then
                result = cb(attacker, btr, di)
            end

            --local ent = btr.Entity
            if SERVER and cv_kd_damagecalc_usetakedamage:GetBool() and IsValid(rag) then
                if rag:IsRagdoll() then
                    Savee_AdvRagKnockdown_DoRagDamage(rag, di, di:GetDamage() > 0)
                else
                    Savee_AdvRagKnockdown_DMGKnockdown(rag, di, di:GetDamage() > 0)
                end
            end

            return 
        end
    end

    ---@type Entity
    local ctrl = getController(ent)
    --print(ent)
    if not IsValid(ctrl) then return  end
    --print("ccc")

    local rag = ctrl:GetRagdoll()
    --[[local eyeatt = rag:LookupAttachment("eyes")

    local eyepos = rag:GetAttachment(eyeatt).Pos]]

    --print(bullet.Src, ent:EyePos(), ent:GetShootPos())

    local shootPos = ent:GetShootPos()
    local eyePos = ent:EyePos()

    local rHD = ctrl:GetRArmDelta()
    --print(rHD)

    local wep = bullet.Inflictor or bullet.Attacker

    --print(rHD, bullet.Src, eyePos, shootPos)
    if (IsValid(wep) and not wep:IsScripted() or bullet.Src == shootPos) and rHD <= 0.15 then
        bullet.Src = eyePos
        --print(1)
    elseif rHD > 0.15 and bullet.Src == eyePos then
        bullet.Src = shootPos
    end

    --bullet.Src = eyePos

    local handpos, handang = getBoneMatrixPosAng(rag, "ValveBiped.Bip01_R_Hand")
    handpos, handang = LocalToWorld(handPosDelta, Angle(), handpos, handang)

    --[[local tr = util.TraceLine({
        start = eyepos,
        endpos = eyepos + ctrl:GetAimEyeAngles():Forward() * 65536,
        filter = {ent, rag},
        mask = MASK_SHOT,
    })]]
    --local actualav = (tr.HitPos - shootPos):GetNormalized()
    local av = CLIENT and bullet.Dir or ent:GetAimVector(true)
    -- 神秘Bug修复
    local bDir = (isSP or SERVER) and bullet.Dir or av

    --print(bDir:Angle(), av:Angle(), ent:GetAimVector(true):Angle(), ent:EyeAngles(true))
    local _, dDir = WorldToLocal(vector_origin, bDir:Angle(), vector_origin, av:Angle())

    --print(dDir)
    --bDir = ctrl:GetAimEyeAngles():Forward()
    --bDir:Rotate(dDir)

    local hAngFwd = handang:Forward()
    --hAngFwd:Rotate(Angle(0, 0, 0))
    hAngFwd:Rotate(dDir)
    --bDir = LocalToWorld(dDir, angle_zero, ctrl:GetAimEyeAngles():Forward(), angle_zero)
    --dDir = LocalToWorld(dDir, angle_zero, handang:Forward(), handang)
    --dDir:Normalize()


    --print(rDelta)

    --print(bullet.IgnoreEntity)
    --print(bullet.Src, ent:EyePos(), ent:GetShootPos())
    --print(math.Clamp((rHD - 0.03), 0, 1))
    bullet.Dir = LerpVector(math.Clamp((rHD - 0.03) * 10, 0, 1), bDir, hAngFwd)

    --[[local tr = util.TraceLine({
        start = bullet.Src,
        endpos = bullet.Src + bullet.Dir * 65536,
        filter = {ent, rag},
        mask = MASK_SHOT,
    })]]
    local aimDir = ctrl:GetAimEyeAngles():Forward()
    local aimTr = util.TraceLine({
        start = eyePos + aimDir * 15,
        endpos = eyePos + aimDir * 65536,
        filter = ent,
        mask = MASK_SHOT,
        getRaw = true,
    })
    --util.QuickTrace(eyePos, ctrl:GetAimEyeAngles():Forward() * 1000)
    --print(aimTr.Entity)
    -- 确认你不是机器人
    -- 有效防止MTM Neutrino Cannon 把你囊死的问题
    if not IsValid(bullet.IgnoreEntity) and rHD <= 0.15 and (aimTr.Entity ~= rag or whitelistedBones[rag:GetBoneName(rag:TranslatePhysBoneToBone(aimTr.PhysicsBone) or -1)]) then
        bullet.IgnoreEntity = ctrl:GetRagdoll()
        --else
        --print(IsValid(bullet.IgnoreEntity), rHD, rag:GetBoneName(rag:TranslatePhysBoneToBone(aimTr.PhysicsBone)), aimTr.Entity ~= rag)
    end

   -- return true --__undetoured(ent, bullet)
    return  --__undetoured(ent, bullet)
end)
if SERVER then
    Savee_ARKD.FunctionHooks.Add("NPC.GetAimVector", "Savee_AdvRagKnockdown_Sync", function(ply, raw, ...)
        local ctrl = getController(ply)
        if not IsValid(ctrl) then return __undetoured(ply, raw, ...) end
        local rag = ctrl:GetRagdoll()
        local bone = rag:LookupBone("ValveBiped.Bip01_R_Hand")

        local handpos, handang = rag:GetBonePosition(bone)
        handpos, handang = LocalToWorld(handPosDelta, Angle(), handpos, handang)

        --[[local tr = util.TraceLine({
            start = eyepos,
            endpos = eyepos + ctrl:GetAimEyeAngles():Forward() * 65536,
            filter = {ply, rag},
            mask = MASK_SHOT,
        })]]

        local av = raw and __raw(ply, ...) or ctrl:GetAimEyeAngles():Forward() --(tr.HitPos - eyepos):GetNormalized()
        --print(rDelta)


        return LerpVector(math.Clamp((ctrl:GetRArmDelta() - 0.03) * 10, 0, 1), av, handang:Forward())
    end)
end

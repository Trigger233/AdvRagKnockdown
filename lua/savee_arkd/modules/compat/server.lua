if CLIENT then return end
local getController = Savee_ARKD.getController

hook.Add("BSMod_KillMoveStarted", "Savee_AdvRagKnockdown_PosCorrection", function(ply, tar)
    local plyCtrl = getController(ply)
    local tarCtrl = getController(tar)
    if IsValid(plyCtrl) then plyCtrl:RemoveSelf() end
    if IsValid(tarCtrl) then tarCtrl:RemoveSelf() end
end)

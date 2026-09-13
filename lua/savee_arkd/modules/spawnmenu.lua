if not CLIENT then return end
-- savee_arkd_spawnmenu.lua
local cvPrefix = "savee_advragknockdown_"

local function main(PANEL)
    -- 基础开关组
    PANEL:Help("基础设置")
    PANEL:ControlHelp("启用/禁用整个系统")
    PANEL:CheckBox("启用击倒系统", cvPrefix .. "enabled")

    PANEL:ControlHelp("是否击倒载具内的玩家（会强制其离开载具）")
    PANEL:CheckBox("击倒载具内玩家", cvPrefix .. "knockdown_playerinvehicle")

    PANEL:ControlHelp("计算伤害时使用TakeDamageInfo并修改BulletTable")
    PANEL:CheckBox("使用TakeDamageInfo计算伤害", cvPrefix .. "damagecalc_usetakedamage")

    PANEL:ControlHelp("在玩家转动视角时使用玩家目前的头部朝向计算（会导致无法翻滚）")
    PANEL:CheckBox("使用头部朝向计算视角", cvPrefix .. "control_useheadangles")

    PANEL:ControlHelp("禁用默认的瞄准方法（按住E瞄准），可能对某些服务器自定义设置有帮助")
    PANEL:CheckBox("禁用默认瞄准按键", cvPrefix .. "cl_control_disabledefaultkeybind")

    PANEL:ControlHelp("按住E时取消瞄准而不是进行瞄准")
    PANEL:CheckBox("反转瞄准模式", cvPrefix .. "cl_control_reversedaiming")

    PANEL:Help("目标类型")
    PANEL:ControlHelp("是否允许玩家被击倒")
    PANEL:CheckBox("允许击倒玩家", cvPrefix .. "enableply")

    PANEL:ControlHelp("是否允许NPC被击倒")
    PANEL:CheckBox("允许击倒NPC", cvPrefix .. "enablenpc")

    PANEL:Help("性能设置")
    PANEL:ControlHelp("下次统一运行控制器Tick()的时间间隔，值越大布娃娃效果越差但性能越好，不建议大于0.03")
    PANEL:NumSlider("Tick间隔时间", cvPrefix .. "performance_luacode_nexttick", 0.001, 0.05, 3)

    PANEL:ControlHelp("查找Trace的层数，越高越'广泛'，操作涉及布娃娃的面越广，但有潜在性能消耗")
    PANEL:NumSlider("Trace层数", cvPrefix .. "performance_luacode_tracelevel", 0, 5, 0)

    PANEL:Help("NPC相关设置")
    PANEL:ControlHelp("在NPC被击倒时调用CreateEntityRagdoll")
    PANEL:CheckBox("NPC击倒时创建布娃娃", cvPrefix .. "npc_usehook_createentityragdoll")

    PANEL:ControlHelp("在NPC假死时调用CreateEntityRagdoll")
    PANEL:CheckBox("NPC假死时创建布娃娃", cvPrefix .. "playdead_npc_usehook_createentityragdoll")

    PANEL:Help("伤害系数 - NPC")
    PANEL:ControlHelp("NPC体力伤害乘数")
    PANEL:NumSlider("NPC体力伤害乘数", cvPrefix .. "statcalc_npc_staminadmgmul", 0, 5, 1)

    PANEL:ControlHelp("NPC意识伤害乘数")
    PANEL:NumSlider("NPC意识伤害乘数", cvPrefix .. "statcalc_npc_conscdmgmul", 0, 5, 1)

    PANEL:Help("伤害系数 - 玩家")
    PANEL:ControlHelp("玩家体力伤害乘数")
    PANEL:NumSlider("玩家体力伤害乘数", cvPrefix .. "statcalc_ply_staminadmgmul", 0, 5, 1)

    PANEL:ControlHelp("玩家意识伤害乘数")
    PANEL:NumSlider("玩家意识伤害乘数", cvPrefix .. "statcalc_ply_conscdmgmul", 0, 5, 1)

    PANEL:Help("客户端设置")
    PANEL:ControlHelp("击倒时默认开启瞄准（0：关闭，1：仅主动击倒，2：任何情况被击倒）")
    PANEL:ComboBox("默认瞄准模式", cvPrefix .. "cl_control_autoaim", {
        { label = "关闭", value = "0" },
        { label = "仅主动击倒", value = "1" },
        { label = "任何情况被击倒", value = "2" }
    })

    PANEL:ControlHelp("是否使用武器的CalcViewModelView，可能有神秘小Bug")
    PANEL:CheckBox("使用CalcViewModelView", cvPrefix .. "cl_performance_luacode_usecalcviewmodelview")

    PANEL:Help("操作提示")
    PANEL:Help("击倒自己: 控制台输入 savee_advragknockdown_doknockdown")
    PANEL:Help("切换瞄准模式: 控制台输入 savee_advragknockdown_toggleaimweapon")
    PANEL:Help("按住E瞄准: +advragknockdown_aimweapon / -advragknockdown_aimweapon")
    PANEL:Help("切换低姿态: savee_advragknockdown_toggleaimlowpose")
end

hook.Add("PopulateToolMenu", "ARKV_Spawnmenu", function(panel)
    spawnmenu.AddToolMenuOption("ARKV", "ARKV_Setting", "savee_advragknockdown_spawnmenu",
        "高级击倒/布娃娃系统", "", "", function(PANEL)
            PANEL:ClearControls()
            main(PANEL)
        end)
end)

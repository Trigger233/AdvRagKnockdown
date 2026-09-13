AddCSLuaFile()

Savee_ARKD = {}

function Savee_ARKD:Include(dir, EnabledSubInclude)
    local files, folders = file.Find(dir .. '/*', "LUA")

    for _, fileName in ipairs(files) do
        if string.EndsWith(fileName, ".lua") then
            local fullPath = dir..'/' .. fileName
            AddCSLuaFile(fullPath)
            include(fullPath)
            print("ARKD_Modules_Loaded :", fullPath)
        end
    end

    if ! EnabledSubInclude then return end

    for _, folderName in ipairs(folders) do
        self:Include(dir .. '/' .. folderName, EnabledSubInclude)
    end
end 

Savee_ARKD:Include("savee_arkd/modules", true)

concommand.Add("savee_arkd_reload_files", function(ply)
    AddCSLuaFile('autorun/savee_arkd_loader.lua')
    include('autorun/savee_arkd_loader.lua')
    ply:SendLua("include('autorun/savee_arkd_loader.lua')")
end)

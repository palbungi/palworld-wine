-- made by caites

local palConfig = require "config"

-- Prints the mod successful loading message in red
print(palConfig.palRedColorWrapperFront .. palConfig.palModName .. " version " .. palConfig.palModVersion .. " loaded for game version " .. palConfig.palGameVersion .. palConfig.palRedColorWrapperBack)

-- Register the new modifiers and print a successful change message in red
RegisterHook("/Script/Engine.PlayerController:ClientRestart", function()
    if palConfig.palCheckRestart ~= 1 then
        local items = FindAllOf("PalGameSetting")
        if items then
            for _, item in ipairs(items) do                
				item.CharacterMaxLevel = palConfig.CharacterMaxLevel
				item.GuildCharacterMaxLevel = palConfig.GuildCharacterMaxLevel				
            end
        end
        print(palConfig.palRedColorWrapperFront .. "[" .. palConfig.palModName .. "] Character Max Level set to " .. palConfig.CharacterMaxLevel .. palConfig.palRedColorWrapperBack)
		print(palConfig.palRedColorWrapperFront .. "[" .. palConfig.palModName .. "] Guild Character Max Level set to " .. palConfig.GuildCharacterMaxLevel .. palConfig.palRedColorWrapperBack)
		
    end
    palConfig.palCheckRestart = 1
end)

RegisterHook("/Script/Engine.PlayerController:ServerAcknowledgePossession", function(Context)
    if not palConfig.serverAcknowledgedPossession then
        local items = FindAllOf("PalGameSetting")
        if items then
            for _, item in ipairs(items) do
                item.CharacterMaxLevel  = palConfig.CharacterMaxLevel
                item.GuildCharacterMaxLevel  = palConfig.GuildCharacterMaxLevel
            end
        end
        print(palConfig.palRedColorWrapperFront .. "[" .. palConfig.palModName .. "] Character Max Level set to " .. palConfig.CharacterMaxLevel .. palConfig.palRedColorWrapperBack)
        print(palConfig.palRedColorWrapperFront .. "[" .. palConfig.palModName .. "] Guild Character Max Level set to " .. palConfig.GuildCharacterMaxLevel .. palConfig.palRedColorWrapperBack)
    end
    palConfig.serverAcknowledgedPossession = true
end)
local isSpawned, isDead, isInPauseMenu, isTalking = false, false, false, false
local minimapWidth = nil

-- Config
local forceHidden = false

local uiStatuses = {
    uiStatusMicrophone = true,
    uiStatusHealth = 100,
    uiStatusArmour = 100,
    uiStatusHunger = 100,
    uiStatusThirst = 100,
    uiStatusStamina = 100,
    uiStatusOxygen = 100,
    uiStatusStress = 0,
    uiStatusDrunk = 0,
}

AddEventHandler('playerSpawned',function ()
    Citizen.CreateThread(function()
        Citizen.Wait(500)
            SendNUIMessage({action = "enableUi"})
            SendNUIMessage({action = "toggleUi", value = true})
            SendNUIMessage({action = "toggleUiStatus", uiStatuses = uiStatuses})
            SendNUIMessage({action = "setData", voiceRange = 8})
    end)
end)

-- Citizen.CreateThread(function()
--     Citizen.Wait(500)
--         SendNUIMessage({action = "enableUi"})
--         SendNUIMessage({action = "toggleUi", value = true})
--         SendNUIMessage({action = "toggleUiStatus", uiStatuses = uiStatuses})
--         SendNUIMessage({action = "setData", voiceRange = 8})
-- end)

AddEventHandler("pma-voice:setTalkingMode", function(mode)
    if mode == 1 then
        SendNUIMessage({action = "setData", voiceRange = 5})
    elseif mode == 2 then
        SendNUIMessage({action = "setData", voiceRange = 8})
    elseif mode == 3 then
        SendNUIMessage({action = "setData", voiceRange = 15})
    end
end)


AddEventHandler("esx_status:onTick", function(data)
    local hunger, thirst
    for i = 1, #data do
        if data[i].name == "thirst" then
            SendNUIMessage({action = "setNeeds", need = 'thirst', value = math.floor(data[i].percent)})
        end
        if data[i].name == "hunger" then
            SendNUIMessage({action = "setNeeds", need = 'hunger', value = math.floor(data[i].percent)})
        end
    end
end)


Citizen.CreateThread(
    function()
        local isInPauseMenu = false

        while true do
            Citizen.Wait(0)

            if IsPauseMenuActive() then -- ESC Key
                if not isInPauseMenu then
                    isInPauseMenu = true
                    SendNUIMessage({action = "toggleUi", value = false})
                end
            else
                if isInPauseMenu then
                    calculateWidth()
                    isInPauseMenu = false

                    if not forceHidden then
                        SendNUIMessage({action = "toggleUi", value = true})
                    end
                end

                HideHudComponentThisFrame(1) -- Wanted Stars
                HideHudComponentThisFrame(2) -- Weapon Icon
                HideHudComponentThisFrame(3) -- Cash
                HideHudComponentThisFrame(4) -- MP Cash
                HideHudComponentThisFrame(6) -- Vehicle Name
                HideHudComponentThisFrame(7) -- Area Name
                HideHudComponentThisFrame(8) -- Vehicle Class
                HideHudComponentThisFrame(9) -- Street Name
                HideHudComponentThisFrame(13) -- Cash Change
                HideHudComponentThisFrame(14) -- Crosshair
                HideHudComponentThisFrame(17) -- Save Game
                HideHudComponentThisFrame(20) -- Weapon Stats
            end
        end
    end
)

function sendUserData()
    local playerPed = PlayerPedId()
    local health = GetEntityHealth(playerPed) - 100
    local armor = GetPedArmour(playerPed)
    local stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
    local oxygen = GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10.00
    isTalking = NetworkIsPlayerTalking(PlayerId())

    if not minimapWidth then
        calculateWidth()
    end

    SendNUIMessage({action = "setData", health = health, armor = armor, stamina = stamina, oxygen = oxygen, dead = isDead, minimapWidth = minimapWidth, talking = isTalking})
end

Citizen.CreateThread(
    function()
        while true do
            sendUserData()
            if IsPedDeadOrDying(PlayerPedId(),true) then isDead = true else isDead = false end
            Citizen.Wait(500)
        end
    end
)

function calculateWidth()
    local aspect_ratio = GetAspectRatio(0)
    local res_x, res_y = GetActiveScreenResolution()
    local xscale = 1.0 / res_x
    minimapWidth = xscale * (res_x / (2.8 * aspect_ratio))
end

RegisterNetEvent("hud:change:power", function (power)
    if power then
        SendNUIMessage({action = "toggleUi", value = true})
    else
        SendNUIMessage({action = "toggleUi", value = false})
    end
end)
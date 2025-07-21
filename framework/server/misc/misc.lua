Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        -- Désactiver l'affichage du HUD des armes
        HideHudComponentThisFrame(2) -- WEAPON_WHEEL
        HideHudComponentThisFrame(20) -- WEAPON_WHEEL_STATS
    end
end)
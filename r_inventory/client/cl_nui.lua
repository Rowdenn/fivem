RegisterNUICallback('closeInventory', function(data, cb)
    CloseInventory()
    cb('ok')
end)

RegisterNUICallback('useItem', function(data, cb)
    TriggerServerEvent('r_inventory:useItem', data.slot, data.item)
    cb('ok')
end)

RegisterNUICallback('dropItem', function(data, cb)
    TriggerServerEvent('r_inventory:dropItem', data.item, data.count, data.slot)
    cb('ok')
end)

RegisterNUICallback('giveItem', function(data, cb)
    if data.targetId then
        TriggerServerEvent('r_inventory:giveItem', data.slot, data.item, data.count or 1, data.targetId)
    end
    cb('ok')
end)

RegisterNUICallback('moveItem', function(data, cb)
    TriggerServerEvent('r_inventory:moveItem', data.fromSlot, data.fromType, data.toSlot, data.toType)
    cb('ok')
end)

RegisterNUICallback('pickupItem', function(data, cb)
    TriggerServerEvent('r_inventory:pickupItem', data.groundItemId, data.toSlot)
    cb('ok')
end)

RegisterNUICallback('sortInventory', function(data, cb)
    TriggerServerEvent('r_inventory:sortInventory')
    cb('ok')
end)

RegisterNUICallback('getItemInfo', function(data, cb)
    TriggerServerEvent('r_inventory:getItemInfo', data.item)
    cb('ok')
end)

RegisterNUICallback('stackGroundToPlayer', function(data, cb)
    TriggerServerEvent('r_inventory:stackGroundToPlayer', data.groundItemId, data.toSlot, data.count)
    cb('ok')
end)

-- RegisterNUICallback('updateCharacterDisplay', function(data, cb)
--     UpdateCharacterDisplay()
--     cb('ok')
-- end)
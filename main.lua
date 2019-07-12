RegisterCommand('stretcher', function()
	LoadModel('v_med_bed2')

	local stretcher = CreateObject(GetHashKey('v_med_bed2'), GetEntityCoords(PlayerPedId()), true)
end, false)

RegisterCommand('removestretcher', function()
	local stretcher = GetClosestObjectOfType(GetEntityCoords(PlayerPedId()), 10.0, GetHashKey('v_med_bed2'))

	if DoesEntityExist(stretcher) then
		DeleteEntity(stretcher)
	end
end, false)

Citizen.CreateThread(function()
	while true do
		local sleep = 500

		local ped = PlayerPedId()
		local pedCoords = GetEntityCoords(ped)

		local closestObject = GetClosestObjectOfType(pedCoords, 3.0, GetHashKey("v_med_bed2"), false)

		if DoesEntityExist(closestObject) then
			sleep = 5

			local stretcherCoords = GetEntityCoords(closestObject)
			local stretcherForward = GetEntityForwardVector(closestObject)
			
			local sitCoords = (stretcherCoords + stretcherForward * - 0.5)
			local pickupCoords = (stretcherCoords + stretcherForward * 0.3)

			if GetDistanceBetweenCoords(pedCoords, sitCoords, true) <= 1.4 then
				DrawText3Ds(sitCoords, "[E] Sit", 0.6)

				if IsControlJustPressed(0, 38) then
					Sit(closestObject)
				end
			end

			if GetDistanceBetweenCoords(pedCoords, pickupCoords, true) <= 1.4 then
				DrawText3Ds(pickupCoords, "[E] Pick up", 0.6)

				if IsControlJustPressed(0, 38) then
					PickUp(closestObject)
				end
			end
		end

		Citizen.Wait(sleep)
	end
end)

Sit = function(stretcherObject)
	local closestPlayer, closestPlayerDist = GetClosestPlayer()

	if closestPlayer ~= nil and closestPlayerDist <= 1.5 then
		if IsEntityPlayingAnim(GetPlayerPed(closestPlayer), 'anim@gangops@morgue@table@', 'ko_front', 3) then
			ShowNotification("Somebody is already using the stretcher!")
			return
		end
	end

	LoadAnim("anim@gangops@morgue@table@")

	AttachEntityToEntity(PlayerPedId(), stretcherObject, 0, 0, 0.0, 1.35, 0.0, 0.0, 180.0, 0.0, false, false, false, false, 2, true)

	local heading = GetEntityHeading(stretcherObject)

	while IsEntityAttachedToEntity(PlayerPedId(), stretcherObject) do
		Citizen.Wait(5)

		if IsPedDeadOrDying(PlayerPedId()) then
			DetachEntity(PlayerPedId(), true, true)
		end

		if not IsEntityPlayingAnim(PlayerPedId(), 'anim@gangops@morgue@table@', 'ko_front', 3) then
			TaskPlayAnim(PlayerPedId(), 'anim@gangops@morgue@table@', 'ko_front', 8.0, 8.0, -1, 69, 1, false, false, false)
		end

		if IsControlPressed(0, 32) then
			local x, y, z  = table.unpack(GetEntityCoords(stretcherObject) + GetEntityForwardVector(stretcherObject) * -0.02)
			SetEntityCoords(stretcherObject, x,y,z)
			PlaceObjectOnGroundProperly(stretcherObject)
		end

		if IsControlPressed(1,  34) then
			heading = heading + 0.4

			if heading > 360 then
				heading = 0
			end

			SetEntityHeading(stretcherObject,  heading)
		end

		if IsControlPressed(1,  9) then
			heading = heading - 0.4

			if heading < 0 then
				heading = 360
			end

			SetEntityHeading(stretcherObject,  heading)
		end

		if IsControlJustPressed(0, 73) then
			DetachEntity(PlayerPedId(), true, true)

			local x, y, z = table.unpack(GetEntityCoords(stretcherObject) + GetEntityForwardVector(stretcherObject) * - 0.7)

			SetEntityCoords(PlayerPedId(), x,y,z)
		end
	end
end

PickUp = function(stretcherObject)
	local closestPlayer, closestPlayerDist = GetClosestPlayer()

	if closestPlayer ~= nil and closestPlayerDist <= 1.5 then
		if IsEntityPlayingAnim(GetPlayerPed(closestPlayer), 'anim@heists@box_carry@', 'idle', 3) then
			ShowNotification("Somebody is already driving the stretcher!")
			return
		end
	end

	NetworkRequestControlOfEntity(stretcherObject)

	LoadAnim("anim@heists@box_carry@")

	AttachEntityToEntity(stretcherObject, PlayerPedId(), GetPedBoneIndex(PlayerPedId(),  28422), -0.00, -1.12, -0.90, 195.0, 180.0, 180.0, 0.0, false, false, true, false, 2, true)

	while IsEntityAttachedToEntity(stretcherObject, PlayerPedId()) do
		Citizen.Wait(5)

		if not IsEntityPlayingAnim(PlayerPedId(), 'anim@heists@box_carry@', 'idle', 3) then
			TaskPlayAnim(PlayerPedId(), 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)
		end

		if IsPedDeadOrDying(PlayerPedId()) then
			DetachEntity(stretcherObject, true, true)
		end

		if IsControlJustPressed(0, 73) then
			DetachEntity(stretcherObject, true, true)
		end
	end
end

DrawText3Ds = function(coords, text, scale)
	local x,y,z = coords.x, coords.y, coords.z
	local onScreen, _x, _y = World3dToScreen2d(x, y, z)
	local pX, pY, pZ = table.unpack(GetGameplayCamCoords())

	SetTextScale(scale, scale)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextEntry("STRING")
	SetTextCentre(1)
	SetTextColour(255, 255, 255, 215)

	AddTextComponentString(text)
	DrawText(_x, _y)

	local factor = (string.len(text)) / 370

	DrawRect(_x, _y + 0.0150, 0.030 + factor, 0.025, 41, 11, 41, 100)
end

GetPlayers = function()
    local players = {}

    for i = 0, 31 do
        if NetworkIsPlayerActive(i) then
            table.insert(players, i)
        end
    end

    return players
end

GetClosestPlayer = function()
	local players = GetPlayers()
	local closestDistance = -1
	local closestPlayer = -1
	local ply = GetPlayerPed(-1)
	local plyCoords = GetEntityCoords(ply, 0)
	
	for index,value in ipairs(players) do
		local target = GetPlayerPed(value)
		if(target ~= ply) then
			local targetCoords = GetEntityCoords(GetPlayerPed(value), 0)
			local distance = Vdist(targetCoords["x"], targetCoords["y"], targetCoords["z"], plyCoords["x"], plyCoords["y"], plyCoords["z"])
			if(closestDistance == -1 or closestDistance > distance) then
				closestPlayer = value
				closestDistance = distance
			end
		end
	end
	
	return closestPlayer, closestDistance
end

LoadAnim = function(dict)
	while not HasAnimDictLoaded(dict) do
		RequestAnimDict(dict)
		
		Citizen.Wait(1)
	end
end

LoadModel = function(model)
	while not HasModelLoaded(model) do
		RequestModel(model)
		
		Citizen.Wait(1)
	end
end

ShowNotification = function(msg)
	SetNotificationTextEntry('STRING')
	AddTextComponentSubstringWebsite(msg)
	DrawNotification(false, true)
end
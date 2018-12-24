local IsJailed 		= false
local unjail		= false
local JailTime		= 0
local fastTimer		= 0
local PlayerData	= {}

ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer
end)



RegisterNetEvent('esx_jailer:jail')
AddEventHandler('esx_jailer:jail', function(jailTime, group, name)
	if IsJailed then
		return
    end

    JailTime = jailTime
    
    local playerPed = PlayerPedId()
    local name = name

	if group == 'cop' then
		Jail = Config.CopJail
		UnJail = Config.CopUnJail
	elseif group == 'admin' then
		Jail = Config.AdminJail
		UnJail = Config.AdminUnJail
    end
    
	if DoesEntityExist(playerPed) then
        Citizen.CreateThread(function()
            
			TriggerEvent('skinchanger:getSkin', function(skin)
				if skin.sex == 0 then
					TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms['prison_wear'].male)
				else
					TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms['prison_wear'].female)
				end
			end)

			SetPedArmour(playerPed, 0)
			ClearPedBloodDamage(playerPed)
			ResetPedVisibleDamage(playerPed)
			ClearPedLastWeaponDamage(playerPed)
			ResetPedMovementClipset(playerPed, 0)

			TriggerEvent('esx_basicneeds:healPlayer')
			
			SetEntityCoords(playerPed, Jail.x, Jail.y, Jail.z)
			IsJailed = true
            unjail = false
            
            while JailTime > 0 and not unjail do
                playerPed = PlayerPedId()
                
				RemoveAllPedWeapons(playerPed, true)
				if IsPedInAnyVehicle(playerPed, false) then
					ClearPedTasksImmediately(playerPed)
				end

				if JailTime % 120 == 0 then
					TriggerServerEvent('esx_jailer:updateRemaining', JailTime)
				end

				Citizen.Wait(20000)

				if group == 'cop' then
					Jail = Config.CopJail
					UnJail = Config.CopUnJail

					if GetDistanceBetweenCoords(GetEntityCoords(playerPed), Jail.x, Jail.y, Jail.z) > 10 then
						TriggerServerEvent('esx_jailer:run', name)
						TriggerServerEvent('esx_jailer:unjailTime', -1)
						JailTime = 0
						IsJailed = false
						return
					end
				elseif group == 'admin' then
					Jail = Config.AdminJail
					UnJail = Config.AdminUnJail

					ESX.SetTimeout(4000, function()
						ESX.TriggerServerCallback('esx_jailer:getDeathStatus', function(isDead)
							if isDead then
								TriggerEvent('esx_ambulancejob:revive', -1)
							end
						end)
					end)

					if GetDistanceBetweenCoords(GetEntityCoords(playerPed), Jail.x, Jail.y, Jail.z) > 10 then
						SetEntityCoords(playerPed, Jail.x, Jail.y, Jail.z)
					end
                end
                
                JailTime = JailTime - 20
            end
            
			TriggerServerEvent('esx_jailer:unjailTime', -1)
			SetEntityCoords(playerPed, UnJail.x, UnJail.y, UnJail.z)
			IsJailed = false

			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
				TriggerEvent('skinchanger:loadSkin', skin)
			end)
		end)
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)

		if JailTime > 0 and IsJailed then
			if fastTimer < 0 then
				fastTimer = JailTime
			end

			draw2dText(_U('remaining_msg', ESX.Round(fastTimer)), { 0.1735, 0.970 } )
			fastTimer = fastTimer - 0.01
		else
			Citizen.Wait(1000)
		end
	end
end)

RegisterNetEvent('esx_jailer:unjail')
AddEventHandler('esx_jailer:unjail', function(source)
	unjail = true
	JailTime = 0
	fastTimer = 0
end)

AddEventHandler('playerSpawned', function(spawn)
	if IsJailed then
		SetEntityCoords(GetPlayerPed(-1), Jail.x, Jail.y, Jail.z)
	else
		TriggerServerEvent('esx_jailer:checkJail')
	end
end)


Citizen.CreateThread(function()
	Citizen.Wait(2000)
	TriggerServerEvent('esx_jailer:checkJail')
end)

function draw2dText(text, pos)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextScale(0.45, 0.45)
	SetTextColour(255, 255, 255, 255)
	SetTextDropShadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()

	BeginTextCommandDisplayText('STRING')
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(table.unpack(pos))
end

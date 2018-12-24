ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

TriggerEvent('es:addGroupCommand', 'jail', 'admin', function(source, args, user)
	if args[1] and GetPlayerName(args[1]) ~= nil and tonumber(args[2]) then
		TriggerEvent('esx_jailer:sendToJail', tonumber(args[1]), tonumber(args[2] * 60), 'admin')
	else
		TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Player ID inválido ou tempo de prisão inválido!!' } } )
	end
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Permissões insuficientes.' } })
end, {help = "Coloque um jogador na prisão", params = {{name = "id", help = "ID do Player"}, {name = "time", help = "tempo de prisão em minutos"}}})

TriggerEvent('es:addGroupCommand', 'unjail', 'admin', function(source, args, user)
	if args[1] then
		if GetPlayerName(args[1]) ~= nil then
			TriggerEvent('esx_jailer:unjailQuest', tonumber(args[1]))
		else
			TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'ID do Player inválido' } } )
		end
	else
		TriggerEvent('esx_jailer:unjailQuest', source)
	end
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Permissões insuficientes.' } })
end, {help = "Retire uma pessoa da prisão", params = {{name = "id", help = "Player ID"}}})

RegisterServerEvent('esx_jailer:sendToJail')
AddEventHandler('esx_jailer:sendToJail', function(target, jailTime, group)
    local identifier = GetPlayerIdentifiers(target)[1]
    local name = GetCharacterName(target)
    local _group = group

	MySQL.Async.fetchAll('SELECT * FROM jail WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)
		if result[1] then
			MySQL.Async.execute('UPDATE jail SET jail_time = @jail_time WHERE identifier = @identifier', {
				['@identifier'] = identifier,
				['@jail_time'] = jailTime
			})
		else
			MySQL.Async.execute('INSERT INTO jail (identifier, jail_time) VALUES (@identifier, @jail_time)', {
				['@identifier'] = identifier,
				['@jail_time'] = jailTime
			})
		end
	end)
	
	TriggerClientEvent('esx_policejob:unrestrain', target)
	TriggerClientEvent('esx_jailer:jail', target, jailTime, _group, name)
end)

RegisterServerEvent('esx_jailer:checkJail')
AddEventHandler('esx_jailer:checkJail', function()
    local _source = source
    local identifier = GetPlayerIdentifiers(_source)[1]
    MySQL.Async.fetchAll('SELECT * FROM jail WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)
		if result[1] ~= nil then
			TriggerClientEvent('esx_jailer:jail', _source, tonumber(result[1].jail_time))
		end
	end)
end)

RegisterServerEvent('esx_jailer:run')
AddEventHandler('esx_jailer:run', function(name)
	local xPlayers = ESX.GetPlayers()
	for i=1, #xPlayers, 1 do
		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
		if xPlayer.job.name == 'police' then
			TriggerClientEvent('esx:showNotification', xPlayer.source,'O suspeito ~r~'.. name .. " ~s~acabou de fugir da prisão.")
		end
	end
end)

RegisterServerEvent('esx_jailer:unjailQuest')
AddEventHandler('esx_jailer:unjailQuest', function(source)
	if source ~= nil then
		unjail(source)
	end
end)

RegisterServerEvent('esx_jailer:unjailTime')
AddEventHandler('esx_jailer:unjailTime', function()
	unjail(source)
end)

RegisterServerEvent('esx_jailer:updateRemaining')
AddEventHandler('esx_jailer:updateRemaining', function(jailTime)
	local identifier = GetPlayerIdentifiers(source)[1]
	MySQL.Async.fetchAll('SELECT * FROM jail WHERE identifier=@id', {['@id'] = identifier}, function(result)
		if result[1] ~= nil then
			MySQL.Async.execute("UPDATE jail SET jail_time=@jt WHERE identifier=@id", {['@id'] = identifier, ['@jt'] = jailTime})
		end
	end)
end)

ESX.RegisterServerCallback('esx_jailer:getDeathStatus', function(source, cb)
	local identifier = GetPlayerIdentifiers(source)[1]

	MySQL.Async.fetchScalar('SELECT isDead FROM users WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(isDead)
		cb(isDead)
	end)
end)

function unjail(target)
	local identifier = GetPlayerIdentifiers(target)[1]
	MySQL.Async.fetchAll('SELECT * FROM jail WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)
		if result[1] then
			MySQL.Async.execute('DELETE from jail WHERE identifier = @identifier', {
				['@identifier'] = identifier
			})
		end
	end)

	TriggerClientEvent('esx_jailer:unjail', target)
end

function unjail(target)
	local identifier = GetPlayerIdentifiers(target)[1]
	MySQL.Async.fetchAll('SELECT * FROM jail WHERE identifier=@id', {['@id'] = identifier}, function(result)
		if result[1] ~= nil then
			MySQL.Async.execute('DELETE from jail WHERE identifier = @id', {['@id'] = identifier})
		end
	end)

	TriggerClientEvent('esx_jailer:unjail', target)
end

function GetCharacterName(source)
	local result = MySQL.Sync.fetchAll('SELECT * FROM users WHERE identifier = @identifier',
	{
		['@identifier'] = GetPlayerIdentifiers(source)[1]
	})

	if result[1] ~= nil and result[1].firstname ~= nil and result[1].lastname ~= nil then
		if Config.OnlyFirstname then
			return result[1].firstname
		else
			return result[1].firstname .. ' ' .. result[1].lastname
		end
	else
		return GetPlayerName(source)
	end
end

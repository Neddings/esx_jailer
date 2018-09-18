# esx_jailer
Modified Version of [esx_jailer](https://github.com/ESX-PUBLIC/esx_jailer)

# Features
- Admins can jail people in a different jail
- "Protection" vs cheaters that try to get out of the admin jail
- Then someone "escapes" from the police prison, all the cops online receive a notification with the player name.

# Requirements
- ES
- ESX
- esx_policejob
- skinchanger
- MySQL Async
- esx_identity

# Based off
- [Original script](https://github.com/ESX-PUBLIC/esx_jailer)

# Add to menu

Example in `esx_policejob: client/main.lua`:

```
		{label = _U('fine'),			value = 'fine'},
		{label = _U('jail'),			value = 'jail'}
		
		
		if data2.current.value == 'jail' then
			JailPlayer(GetPlayerServerId(closestPlayer))
		end

---

function JailPlayer(player)
	ESX.UI.Menu.Open(
		'dialog', GetCurrentResourceName(), 'jail_menu',
		{
			title = _U('jail_menu_info'),
		},
	function (data2, menu)
		local jailTime = tonumber(data2.value)
		if jailTime == nil then
			ESX.ShowNotification(_U('invalid_amount'))
		else
			TriggerServerEvent("esx_jailer:sendToJail", player, jailTime * 60, 'cop')
			menu.close()
		end
	end,
	function (data2, menu)
		menu.close()
	end
	)
end
```

local _resource_name = '__'..GetCurrentResourceName()..'__'
local _ServerCallbacks = {}
ESX = nil

Framework = {}

if IsDuplicityVersion() then
	local _TriggerClientEvent = TriggerClientEvent
	Framework.RegisterServerCallback = function(name, callback)
	    _ServerCallbacks[name] = callback
	end
	RegisterNetEvent(_resource_name..'TriggerServerCallback', function(name, id, ...)
		local _source = source
		if _ServerCallbacks[name] then
			_ServerCallbacks[name](_source, function(...)
				_TriggerClientEvent(_resource_name..'TriggerServerCallback', _source, id, ...)
			end, ...)
		end
	end)
	TriggerEvent('esx:getSharedObject', function(esx) 
		ESX = esx 
	end)
else
	local _TriggerServerEvent = TriggerServerEvent
	local _callbackId = 0
	Framework.TriggerServerCallback = function(name, callback, ...)
	    _callbackId = _callbackId < 65000 and _callbackId + 1 or 1
	    _ServerCallbacks[_callbackId] = callback
	    _TriggerServerEvent(_resource_name..'TriggerServerCallback', name, _callbackId, ...)
	end
	RegisterNetEvent(_resource_name..'TriggerServerCallback', function(id, ...)
	    _ServerCallbacks[id](...)
	    _ServerCallbacks[id] = nil
	end)
	local _AddEventHandler = AddEventHandler
	local _RegisterNuiCallbackType = RegisterNuiCallbackType
	local _pcall = pcall
	local _Trace = Citizen.Trace
	Framework.RegisterNUICallback = function(name, callback)
	    _RegisterNuiCallbackType(name)
	    local event = _AddEventHandler('__cfx_nui:' .. name, function(body, resultCallback)
	        local status, err = _pcall(function()
	            callback(body, resultCallback)
	        end)

	        if err then
	            _Trace("error during NUI callback " .. name .. ": " .. err .. "\n")
	        end
	    end)
	    return event    
	end
	TriggerEvent('esx:getSharedObject', function(esx) 
		ESX = esx 
	end)
end
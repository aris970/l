local Class = {}

Class.Smash_And_Grab = function()
    local self = {
        -- Localization --
        GetZoneAtCoords = GetZoneAtCoords,
        GetEntityCoords = GetEntityCoords,
        PlayerPedId = PlayerPedId,
        Vdist2 = Vdist2,
        Table_Insert = table.insert,
        Table_Remove = table.remove,
        CreateThread = Citizen.CreateThread,
        Wait = Citizen.Wait,
        SetTextFont = SetTextFont,
        SetTextProportional = SetTextProportional,
        SetTextScale = SetTextScale,
        SetTextDropShadow = SetTextDropShadow,
        SetTextEdge = SetTextEdge,
        SetTextDropShadow = SetTextDropShadow,
        SetTextOutline = SetTextOutline,
        SetTextCentre = SetTextCentre,
        AddTextEntry = AddTextEntry,
        BeginTextCommandDisplayText = BeginTextCommandDisplayText,
        EndTextCommandDisplayText = EndTextCommandDisplayText,
        GetSelectedPedWeapon = GetSelectedPedWeapon,
        IsControlJustReleased = IsControlJustReleased,
        GetLastInputMethod = GetLastInputMethod,
        TaskTurnPedToFaceCoord = TaskTurnPedToFaceCoord,
        RequestAnimDict = RequestAnimDict,
        HasAnimDictLoaded = HasAnimDictLoaded,
        TaskPlayAnim = TaskPlayAnim,
        SetCurrentPedWeapon = SetCurrentPedWeapon,
        GetAnimDuration = GetAnimDuration,
        GetGameTimer = GetGameTimer,
        IsEntityPlayingAnim = IsEntityPlayingAnim,
        ClearPedTasksImmediately = ClearPedTasksImmediately,
        RemoveAnimDict = RemoveAnimDict,
        GetSoundId = GetSoundId,
        RequestScriptAudioBank = RequestScriptAudioBank,
        PlaySoundFromCoord = PlaySoundFromCoord,
        StopSound = StopSound,
        ReleaseSoundId = ReleaseSoundId,
        TriggerServerEvent = TriggerServerEvent,
        GetStreetNameAtCoord = GetStreetNameAtCoord,
        GetStreetNameFromHashKey = GetStreetNameFromHashKey,
        String_Format = string.format,
        GetPlayerName = GetPlayerName,
        PlayerId = PlayerId,
        AnimpostfxPlay = AnimpostfxPlay,
        Math_Random = math.random,
        DrawRect = DrawRect
        -- End Localization --         
    }

    self.Hash = {
        WEAPON_CROWBAR = `WEAPON_CROWBAR`,
        WEAPON_UNARMED = `WEAPON_UNARMED`,
    }  

    self.Containers = {}
    self.Container_Lookup = {}
    self.Delay = 1000
    self.Alarm = false

    self.Initialize = function()
        self.CreateThread(function()
            while not ESX or not ESX.IsPlayerLoaded() do
                self.Wait(1000)
            end
            math.randomseed(GetGameTimer())
            self.Prepare_Registers()
            self.Store_Monitor_Initialize()
        end)
    end

    self.DrawBottom = function(text, x, y, scale)
        self.SetTextFont(0)
        self.SetTextProportional(0)
        self.SetTextScale(scale, scale)
        self.SetTextDropShadow(0, 0, 0, 0,255)
        self.SetTextEdge(1, 0, 0, 0, 255)
        self.SetTextDropShadow()
        self.SetTextOutline()
        self.SetTextCentre(1)
        self.AddTextEntry('fivestar_containers', text)
        self.BeginTextCommandDisplayText('fivestar_containers')
        self.EndTextCommandDisplayText(x, y) 
    end

    self.Prepare_Registers = function()
        local containers = GlobalState.FS_Containers__Containers
        for i = 1, #containers do
            local zone = self.GetZoneAtCoords(containers[i])
            if not self.Containers[zone] then
                self.Containers[zone] = {}
            end
            self.Table_Insert(self.Containers[zone],containers[i])
            if not self.Container_Lookup[zone] then
                self.Container_Lookup[zone] = {}
            end
            self.Container_Lookup[zone][#self.Containers[zone]] = i            
        end
    end

    self.Store_Monitor_Initialize = function()
        self.CreateThread(function()
            while true do
                ::start::
                self.Wait(self.Delay)
                local pos = self.GetEntityCoords(self.PlayerPedId())
                local zone = self.GetZoneAtCoords(pos)
                if self.Containers[zone] then
                    for i = 1, #self.Containers[zone] do
                        if self.Vdist2(pos, self.Containers[zone][i]) < 2.5 then
                            if self.GetSelectedPedWeapon(self.PlayerPedId()) ~= self.Hash.WEAPON_CROWBAR then
                                self.Delay = 1000
                                goto start
                            elseif GlobalState.PlayerJobsCount.police < GlobalState.FS_Containers__Police_Required then
                                ESX.ShowNotification('~o~All areas are on lockdown due to a lack of police')
                                self.Delay = 5000
                                goto start
                            elseif GlobalState.FS_Containers__Cooldown then
                                ESX.ShowNotification('~o~All commercial areas are on high alert due to a recent robbery')
                                self.Delay = 5000
                                goto start
                            end
                            ESX.ShowHelpNotification('Press ~INPUT_CONTEXT~ to ~g~search~s~ the ~o~Container')
                            self.Delay = 1
                            if self.IsControlJustReleased(0, 51) and self.GetLastInputMethod(0) then
                                local finished = false
                                Framework.TriggerServerCallback('start_robbery', function(canrob)
                                    if canrob then
                                        local streetName,_ = self.GetStreetNameAtCoord(pos.x,pos.y,pos.z)
                                        streetName = self.GetStreetNameFromHashKey(streetName)
                                        self.TriggerServerEvent('LogSource', self.String_Format('`%s` has started robbing the containers at `%s`', self.GetPlayerName(self.PlayerId()), streetName), "16747520", 'containers')
                                        self.TriggerServerEvent('esx_outlawalert:commercialBreakInProgress', pos, streetName, self.playerGender)
                                        self.TaskTurnPedToFaceCoord(self.PlayerPedId(), self.Containers[zone][i], 1500)
                                        self.Wait(1500)    
                                        self.RequestAnimDict('amb@prop_human_parking_meter@male@idle_a') 
                                        while not self.HasAnimDictLoaded('amb@prop_human_parking_meter@male@idle_a') do
                                            self.Wait(1)
                                        end 
                                        -- self.SetCurrentPedWeapon(self.PlayerPedId(), self.Hash.WEAPON_UNARMED, true)
                                        self.TaskPlayAnim(self.PlayerPedId(), 'amb@prop_human_parking_meter@male@idle_a', 'idle_a', 3.0, 1.0, -1, 16, 0, 0, 0, 0)
                                        if not self.Alarm then self.TriggerServerEvent('__fivestarr_containers__alarm', pos) end
                                        self.AnimpostfxPlay('CamPushInNeutral', 0, 0)
                                        
                                        local progress = 0
                                        local keys = {
                                            [172] = '~INPUT_CELLPHONE_UP~', 
                                            [173] = '~INPUT_CELLPHONE_DOWN~', 
                                            [174] = '~INPUT_CELLPHONE_LEFT~',
                                            [175] = '~INPUT_CELLPHONE_RIGHT~'
                                        }
                                        local combination = {}
                                        local last_random = 0
                                        local new_random = 0
                                        for i = 1, 400 do
                                            repeat
                                                new_random = self.Math_Random(172,175)
                                            until new_random ~= last_random
                                            last_random = new_random
                                            self.Table_Insert(combination, new_random)
                                        end
                                        while #combination > 0 do
                                            ESX.ShowHelpNotification('Press '..keys[combination[1]]..' to ~r~search the container')
                                            self.DrawBottom('Press ~y~E~w~ to ~r~cancel the search', 0.45, 0.9, 0.4)
                                            if not self.IsEntityPlayingAnim(self.PlayerPedId(), 'amb@prop_human_parking_meter@male@idle_a', 'idle_a', 16) then
                                                self.TaskPlayAnim(self.PlayerPedId(), 'amb@prop_human_parking_meter@male@idle_a', 'idle_a', 3.0, 1.0, -1, 16, 0, 0, 0, 0)
                                            end                                            
                                            local progress = 1 - (#combination / 400)
                                            local w = 0.1 * progress
                                            local x = 0.45 - (0.1-w) / 2
                                            self.DrawRect(0.45, 0.95, 0.1, 0.025, 0, 0, 0, 100) -- backbar
                                            self.DrawRect(x, 0.95, w, 0.0125, 208, 33, 51, 200) -- progress            
                                            
                                            if self.IsControlJustReleased(0, combination[1]) and self.GetLastInputMethod(0) then
                                                self.Table_Remove(combination, 1)
                                            elseif self.IsControlJustReleased(0, 38) and self.GetLastInputMethod(0) then
                                                Framework.TriggerServerCallback('cancel_robbery', function() end, self.Container_Lookup[zone][i])
                                                break
                                            end
                                            self.Wait(1)
                                        end
                                        self.ClearPedTasksImmediately(self.PlayerPedId())
                                        if #combination == 0 then
                                            Framework.TriggerServerCallback('complete_robbery', function() end, self.Container_Lookup[zone][i])
                                        end
                                        self.RemoveAnimDict('amb@prop_human_parking_meter@male@idle_a')
                                    end
                                    finished = true
                                end)
                                while not finished do
                                    self.Wait(1000)
                                end
                            end
                        end
                    end
                else
                    self.Delay = 5000
                end
            end
        end)
    end

    self.Start_Alarm = function(coords)
        if not self.Alarm then
            self.CreateThread(function()
                self.Alarm = true
                local soundId = self.GetSoundId()
                while not self.RequestScriptAudioBank('SCRIPT/ALARM_KLAXON_06', false, -1) do
                    self.Wait(1)
                end
                self.PlaySoundFromCoord(soundId, 'Klaxon_06', coords, 'ALARMS_SOUNDSET', false, 0, false)
                local alarm_end = self.GetGameTimer() + (GlobalState.FS_Containers__Alarm_Time * 1000)
                while self.GetGameTimer() < alarm_end do
                    self.Wait(1000)
                end
                self.StopSound(soundId)
                self.ReleaseSoundId(soundId)
                self.Alarm = false
            end)
        end
    end    

    self.Initialize()

    return self
end

local SmashAndGrab = Class.Smash_And_Grab()

RegisterNetEvent('__fivestarr_containers__alarm', function(coords)
    SmashAndGrab.Start_Alarm(coords)
end)

AddEventHandler('skinchanger:loadSkin', function(character)
    SmashAndGrab.playerGender = character.sex
end)
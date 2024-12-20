AddEventHandler("OnPluginStart", function(event)
    db = Database("gloves")
    if not db:IsConnected() then return end

    db:QueryBuilder():Table("gloves"):Create({
        steamid = "string|max:128|unique",
        t = "string|max:128|unique",
        ct = "string|max:128|unique",
        gloves_data = "json|default:{}"
    }):Execute(function (err, result)
        if #err > 0 then
            print("ERROR: " .. err)
        end
    end)

    local jsonData = json.decode(files:Read(GetPluginPath(GetCurrentPluginName()) .. "/data/skins.json"))
    if not jsonData then return end

    local glovesIndexTbl = {
        ["studded_bloodhound_gloves"] = 5027,
        ["studded_brokenfang_gloves"] = 4725,
        ["studded_hydra_gloves"] = 5035,
        ["sporty_gloves"] = 5030,
        ["leather_handwraps"] = 5032,
        ["slick_gloves"] = 5031,
        ["specialist_gloves"] = 5034,
        ["motorcycle_gloves"] = 5033
    }

    for i = 1, #jsonData do
        if jsonData[i].category.id == "sfui_invpanel_filter_gloves" then
            table.insert(GlovesData,
                { id = jsonData[i].id, paint_index = jsonData[i].paint_index, name = jsonData[i].name })

            GloveWeaponIdx[jsonData[i].id] = {
                itemdef = glovesIndexTbl[jsonData[i].weapon.id],
                paint_index = jsonData[i].paint_index,
                name = jsonData[i].name
            }
        end
    end

    for i = 1, playermanager:GetPlayerCap() do
        local player = GetPlayer(i - 1)
        if player then
            LoadGlovesPlayerData(player)
        end
    end

    config:Create("gloves", {
        prefix = "[{lime}Gloves{default}]",
        color = "00B869",
    })

    for i = 1, #AgentsModelPath do
        precacher:PrecacheModel(AgentsModelPath[i])
    end
end)

AddEventHandler("OnPlayerTeam", function (event)
    local player = GetPlayer(event:GetInt("userid"))
    if not player then return end
    if not player:IsValid() then return end

    player:SetVar("gloves.spawned", nil)
end)

AddEventHandler("OnPlayerConnectFull", function(event)
    local playerid = event:GetInt("userid")
    local player = GetPlayer(playerid)
    if not player then return end

    LoadGlovesPlayerData(player)
end)

AddEventHandler("OnClientChat", function(event, playerid, text, teamonly)
    local player = GetPlayer(playerid)
    if not player then return end

    if player:GetVar("gloves.manualseed") == true then
        if tonumber(text) then
            player:ExecuteCommand("sw_gloves_setseed \"" ..
                player:GetVar("gloves.gloveid") .. "\" manual " .. text)

            event:SetReturn(false)
            return EventResult.Handled
        end
    elseif player:GetVar("gloves.manualwear") == true then
        if tonumber(text) then
            player:ExecuteCommand("sw_gloves_setwear \"" ..
                player:GetVar("gloves.gloveid") .. "\" manual " .. text)

            event:SetReturn(false)
            return EventResult.Handled
        end
    end

    return EventResult.Continue
end)

AddEventHandler("OnPlayerSpawn", function(event)
    local player = GetPlayer(event:GetInt("userid"))
    if not player then return end
    if not player:IsValid() then return end
    if player:IsFirstSpawn() then return end

    GiveGloves(player)
end)

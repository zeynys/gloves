--- @param player Player
function LoadGlovesPlayerData(player)
    if player:IsFakeClient() then return end
    if not db:IsConnected() then return end

    db:QueryParams("select * from gloves where steamid = '@steamid' limit 1", { steamid = player:GetSteamID() },
        function(err, result)
            if #err > 0 then
                return print("ERROR: " .. err)
            end

            if #result == 0 then
                player:SetVar("gloves.t", "")
                player:SetVar("gloves.ct", "")
                player:SetVar("gloves.data", "{}")
            else
                player:SetVar("gloves.t", result[1].t)
                player:SetVar("gloves.ct", result[1].ct)
                player:SetVar("gloves.data", result[1].gloves_data)
            end
        end)
end

--- @param player Player
function GetPlayerGloves(player)
    return {
        t = (player:GetVar("gloves.t") or ""),
        ct = (player:GetVar("gloves.ct") or ""),
        data = (json.decode(player:GetVar("gloves.data") or "{}") or {})
    }
end

--- @param player Player
--- @param team "t"|"ct"
--- @param gloveidx string
function UpdatePlayerGloves(player, team, gloveidx)
    if player:IsFakeClient() then return end
    if not db:IsConnected() then return end
    if team ~= "t" and team ~= "ct" then return end

    player:SetVar("gloves." .. team, gloveidx)

    local params = {
        steamid = player:GetSteamID(),
        t = "",
        ct = "",
    }

    db:QueryParams(
        "insert ignore into gloves (steamid, t, ct, gloves_data) values ('@steamid', '@t', '@ct', '{}')",
        params
    )

    params = {
        steamid = player:GetSteamID(),
        team = team,
        gloveidx = gloveidx
    }

    db:QueryParams("update gloves set `@team` = '@gloveidx' where `steamid` = '@steamid' limit 1", params)

    GiveGloves(player)
end

--- @param player Player
--- @param gloveidx string
--- @param field "seed"|"wear"
--- @param value number
function UpdatePlayerGlovesData(player, gloveidx, field, value)
    if player:IsFakeClient() then return end
    if not db:IsConnected() then return end

    if not player:GetVar("gloves.data") then
        player:SetVar("gloves.data", "{}")
    end

    local glovesData = json.decode(player:GetVar("gloves.data") or "{}") or {}
    if not glovesData[gloveidx] then
        math.randomseed(math.floor(server:GetTickCount()))
        glovesData[gloveidx] = {
            wear = 0.0,
            seed = math.random(0, 1000)
        }
    end

    if glovesData[gloveidx][field] then
        glovesData[gloveidx][field] = value
    end

    player:SetVar("gloves.data", json.encode(glovesData))

    db:QueryParams(
        "insert ignore into gloves (steamid, t, ct, gloves_data) values ('@steamid', '', '', '{}')",
        { steamid = player:GetSteamID() }
    )

    db:QueryParams("update gloves set gloves_data = '@glovesdata' where steamid = '@steamid' limit 1",
        { glovesdata = json.encode(glovesData), steamid = player:GetSteamID() })

    GiveGloves(player)
end

function IsPistolRound()
    local gameRules = GetCCSGameRules()
    if gameRules == nil then return false end
    if gameRules.WarmupPeriod then return false end
    return gameRules.TotalRoundsPlayed == 0 or gameRules.RoundsPlayedThisPhase == 0 or (gameRules.SwitchingTeamsAtRoundReset and gameRules.OvertimePlaying == 0) or gameRules.GameRestart;
end

--- @param player Player
function GiveGloves(player)
    local gloves = GetPlayerGloves(player)
    if not player:CBaseEntity():IsValid() then return end
    if player:CBaseEntity().TeamNum ~= Team.CT and player:CBaseEntity().TeamNum ~= Team.T then return end

    local team = player:CBaseEntity().TeamNum == Team.CT and "ct" or "t"
    local glove = gloves[team]

    if GloveWeaponIdx[glove or ""] then
        if player:GetVar("gloves.spawned") and not IsPistolRound() then
            --- @type CSkeletonInstance
            local instance = player:CBaseEntity().CBodyComponent.SceneNode:GetSkeletonInstance()
            local modelentity = CBaseModelEntity(player:CBaseEntity():ToPtr())
            if instance:IsValid() then
                if instance.ModelState:IsValid() then
                    local model = instance.ModelState.ModelName
                    modelentity:SetModel(
                        "characters/models/tm_jumpsuit/tm_jumpsuit_varianta.vmdl")
                    NextTick(function()
                        modelentity:SetModel(model)
                        UpdateGloves(player, gloves, glove)
                    end)
                end
            end
        else
            player:SetVar("gloves.spawned", true)
            UpdateGloves(player, gloves, glove)
        end
    end
end

--- @param player Player
--- @param gloves table
--- @param glove string
function UpdateGloves(player, gloves, glove)
    NextTick(function()
        local weaponIdx = GloveWeaponIdx[glove].itemdef
        local paint_index = GloveWeaponIdx[glove].paint_index
        local seed = (gloves.data[glove] or { seed = math.random(0, 1000) }).seed
        local wear = (gloves.data[glove] or { wear = 0.0 }).wear

        if not player:CCSPlayerPawn():IsValid() then return end

        local glvs = player:CCSPlayerPawn().EconGloves
        glvs.ItemDefinitionIndex = weaponIdx
        glvs.ItemIDLow = -1
        glvs.ItemIDHigh = (16384 & 0xFFFFFFFF)
        glvs.Initialized = true

        NextTick(function()
            glvs.NetworkedDynamicAttributes:SetOrAddAttributeValueByName("set item texture prefab",
                paint_index + 0.0)
            glvs.NetworkedDynamicAttributes:SetOrAddAttributeValueByName("set item texture seed",
                seed + 0.0)
            glvs.NetworkedDynamicAttributes:SetOrAddAttributeValueByName("set item texture wear", wear)

            CBaseModelEntity(player:CCSPlayerPawn():ToPtr()):SetBodygroup("default_gloves", 1)
        end)
    end)
end
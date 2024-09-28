commands:Register("gloves", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end

    local menuOptions = {}
    local registeredCategories = {}

    for i = 1, #GlovesData do
        local category = GlovesData[i].name:split("|")[1]:trim()
        if not registeredCategories[category] then
            registeredCategories[category] = true
            table.insert(menuOptions, { category, "sw_selectcategory_gloves \"" .. category .. "\"" })
        end
    end

    local menuid = "glove_menu_" .. GetTime()
    menus:RegisterTemporary(menuid, FetchTranslation("gloves.menu.title"),
        config:Fetch("gloves.color"), menuOptions)

    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("selectcategory_gloves", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc ~= 1 then return end

    local menuOptions = {}
    local glovesCategory = args[1]

    for i = 1, #GlovesData do
        local category = GlovesData[i].name:split("|")[1]:trim()
        if category == glovesCategory then
            local name = GlovesData[i].name:split("|")[2]:trim()

            table.insert(menuOptions, { name, "sw_selectglove \"" .. GlovesData[i].id .. "\"" })
        end
    end

    local menuid = "select_gloves_menu_" .. GetTime()
    menus:RegisterTemporary(menuid, glovesCategory, config:Fetch("gloves.color"), menuOptions)

    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("selectglove", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc ~= 1 then return end

    local gloveid = args[1]
    if not GloveWeaponIdx[gloveid] then return end

    local menuid = "select_glove_menu_" .. GetTime()
    menus:RegisterTemporary(menuid, GloveWeaponIdx[gloveid].name, config:Fetch("gloves.color"), {
        { FetchTranslation("gloves.menu.equipfor"), "sw_gloves_equipfor \"" .. gloveid .. "\"" },
        { FetchTranslation("gloves.menu.setseed"),  "sw_gloves_setseedfor \"" .. gloveid .. "\"" },
        { FetchTranslation("gloves.menu.setwear"),  "sw_gloves_setwearfor \"" .. gloveid .. "\"" },
        { FetchTranslation("core.menu.back"),       "sw_selectcategory_gloves \"" .. GloveWeaponIdx[gloveid].name:split("|")[1]:trim() .. "\"" }
    })

    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("gloves_equipfor", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc ~= 1 then return end

    local gloveid = args[1]
    if not GloveWeaponIdx[gloveid] then return end

    local data = GetPlayerGloves(player)

    local menuid = "equipfor_glove_menu_" .. GetTime()
    menus:RegisterTemporary(menuid, GloveWeaponIdx[gloveid].name .. " - " .. FetchTranslation("gloves.menu.equip"),
        config:Fetch("gloves.color"), {
            { "[" .. (data.ct == gloveid and "✔️" or "❌") .. "] " .. FetchTranslation("gloves.menu.ct"), "sw_gloves_equip \"" .. gloveid .. "\" ct" },
            { "[" .. (data.t == gloveid and "✔️" or "❌") .. "] " .. FetchTranslation("gloves.menu.t"), "sw_gloves_equip \"" .. gloveid .. "\" t" },
            { FetchTranslation("core.menu.back"), "sw_selectglove \"" .. gloveid .. "\"" }
        })

    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("gloves_equip", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc ~= 2 then return end

    local gloveid = args[1]
    if not GloveWeaponIdx[gloveid] then return end

    local team = args[2]
    if team ~= "t" and team ~= "ct" then return end

    local data = GetPlayerGloves(player)
    local equipped = (data[team] == gloveid)

    if equipped then
        UpdatePlayerGloves(player, team, "")
        ReplyToCommand(playerid, config:Fetch("gloves.prefix"),
            FetchTranslation("gloves.unequip"):gsub("{NAME}", GloveWeaponIdx[gloveid].name):gsub("{TEAM}",
                FetchTranslation("gloves.menu." .. team)))
    else
        UpdatePlayerGloves(player, team, gloveid)
        ReplyToCommand(playerid, config:Fetch("gloves.prefix"),
            FetchTranslation("gloves.equip"):gsub("{NAME}", GloveWeaponIdx[gloveid].name):gsub("{TEAM}",
                FetchTranslation("gloves.menu." .. team)))
    end

    player:ExecuteCommand("sw_gloves_equipfor \"" .. gloveid .. "\"")
end)

commands:Register("gloves_setseedfor", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc ~= 1 then return end

    local gloveid = args[1]
    if not GloveWeaponIdx[gloveid] then return end

    local menuid = "select_seed_menu_" .. GetTime()
    menus:RegisterTemporary(menuid, GloveWeaponIdx[gloveid].name, config:Fetch("gloves.color"), {
        { FetchTranslation("gloves.menu.random"), "sw_gloves_setseed \"" .. gloveid .. "\" random" },
        { FetchTranslation("gloves.menu.manual"), "sw_gloves_setseed \"" .. gloveid .. "\" manual" },
        { FetchTranslation("core.menu.back"),     "sw_selectglove \"" .. gloveid .. "\"" }
    })

    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("gloves_setseed", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc < 2 then return end

    local gloveid = args[1]
    if not GloveWeaponIdx[gloveid] then return end

    local mode = args[2]
    if mode == "manual" then
        local seed = tonumber(args[3] or 0)
        if args[3] and seed then
            if seed < 0 or seed > 1000 then
                return ReplyToCommand(playerid, config:Fetch("gloves.prefix"),
                    FetchTranslation("gloves.invalid"):gsub("{LIMIT}", "0-1000"):gsub("{CATEGORY}", "seed"))
            end

            player:SetVar("gloves.manualseed", false)
            UpdatePlayerGlovesData(player, gloveid, "seed", seed)
            ReplyToCommand(playerid, config:Fetch("gloves.prefix"),
                FetchTranslation("gloves.update"):gsub("{CATEGORY}", "seed"):gsub("{VALUE}", seed))
            player:ExecuteCommand("sw_selectglove \"" .. gloveid .. "\"")
            if player:GetVar("gloves.timerid") then
                StopTimer(player:GetVar("gloves.timerid"))
                player:SetVar("gloves.timerid", nil)
            end
        else
            player:SetVar("gloves.manualseed", true)
            local timerid = SetTimer(4500, function()
                player:SendMsg(MessageType.Center,
                    FetchTranslation("gloves.type_in_chat"):gsub("{COLOR}", config:Fetch("gloves.color")):gsub(
                        "{CATEGORY}", "seed"):gsub("{LIMIT}", "0-1000"))
            end)
            player:SetVar("gloves.gloveid", gloveid)
            player:SetVar("gloves.timerid", timerid)
            player:HideMenu()
            player:SendMsg(MessageType.Center,
                FetchTranslation("gloves.type_in_chat"):gsub("{COLOR}", config:Fetch("gloves.color")):gsub(
                    "{CATEGORY}", "seed"):gsub("{LIMIT}", "0-1000"))
        end
    else
        math.randomseed(math.floor(server:GetTickCount()))
        local seed = math.random(0, 1000)

        UpdatePlayerGlovesData(player, gloveid, "seed", seed)

        ReplyToCommand(playerid, config:Fetch("gloves.prefix"),
            FetchTranslation("gloves.update"):gsub("{CATEGORY}", "seed"):gsub("{VALUE}", seed))
    end
end)

commands:Register("gloves_setwearfor", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc ~= 1 then return end

    local gloveid = args[1]
    if not GloveWeaponIdx[gloveid] then return end

    local menuid = "select_seed_menu_" .. GetTime()
    menus:RegisterTemporary(menuid, GloveWeaponIdx[gloveid].name, config:Fetch("gloves.color"), {
        { "Factory New",                          "sw_gloves_setwear \"" .. gloveid .. "\" manual 0.0" },
        { "Minimal Wear",                         "sw_gloves_setwear \"" .. gloveid .. "\" manual 0.08" },
        { "Field Tested",                         "sw_gloves_setwear \"" .. gloveid .. "\" manual 0.16" },
        { "Well-Worn",                            "sw_gloves_setwear \"" .. gloveid .. "\" manual 0.40" },
        { "Battle-Scared",                        "sw_gloves_setwear \"" .. gloveid .. "\" manual 0.45" },
        { FetchTranslation("gloves.menu.random"), "sw_gloves_setwear \"" .. gloveid .. "\" random" },
        { FetchTranslation("gloves.menu.manual"), "sw_gloves_setwear \"" .. gloveid .. "\" manual" },
        { FetchTranslation("core.menu.back"),     "sw_selectglove \"" .. gloveid .. "\"" }
    })

    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("gloves_setwear", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc < 2 then return end

    local gloveid = args[1]
    if not GloveWeaponIdx[gloveid] then return end

    local mode = args[2]
    if mode == "manual" then
        local wear = tonumber(args[3] or 0.0)
        if args[3] and wear then
            if wear < 0.0 or wear > 1.0 then
                return ReplyToCommand(playerid, config:Fetch("gloves.prefix"),
                    FetchTranslation("gloves.invalid"):gsub("{LIMIT}", "0.0-1.0"):gsub("{CATEGORY}", "wear"))
            end

            player:SetVar("gloves.manualwear", false)
            UpdatePlayerGlovesData(player, gloveid, "wear", wear)
            ReplyToCommand(playerid, config:Fetch("gloves.prefix"),
                FetchTranslation("gloves.update"):gsub("{CATEGORY}", "wear"):gsub("{VALUE}", wear))
            player:ExecuteCommand("sw_selectglove \"" .. gloveid .. "\"")

            if player:GetVar("gloves.timerid") then
                StopTimer(player:GetVar("gloves.timerid"))
                player:SetVar("gloves.timerid", nil)
            end
        else
            player:SetVar("gloves.manualwear", true)
            local timerid = SetTimer(4500, function()
                player:SendMsg(MessageType.Center,
                    FetchTranslation("gloves.type_in_chat"):gsub("{COLOR}", config:Fetch("gloves.color")):gsub(
                        "{CATEGORY}", "wear"):gsub("{LIMIT}", "0.0-1.0"))
            end)
            player:SetVar("gloves.gloveid", gloveid)
            player:SetVar("gloves.timerid", timerid)
            player:HideMenu()
            player:SendMsg(MessageType.Center,
                FetchTranslation("gloves.type_in_chat"):gsub("{COLOR}", config:Fetch("gloves.color")):gsub(
                    "{CATEGORY}", "wear"):gsub("{LIMIT}", "0.0-1.0"))
        end
    else
        math.randomseed(math.floor(server:GetTickCount()))
        local wear = math.random()

        UpdatePlayerGlovesData(player, gloveid, "wear", wear)

        ReplyToCommand(playerid, config:Fetch("gloves.prefix"),
            FetchTranslation("gloves.update"):gsub("{CATEGORY}", "wear"):gsub("{VALUE}", wear))
    end
end)

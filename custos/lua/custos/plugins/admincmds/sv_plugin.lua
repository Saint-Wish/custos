local PLUGIN = PLUGIN

local bans = {}

function PLUGIN:BanPlayer(admin, ply, time, reason)
	local time = utilx.CheckTypeStrict(time, "number")

	local steamid32 = ply:SteamID()
	local steamid64 = ply:SteamID64()
	local reason = reason or "No reason specified"
	local startTime = os.time()
	local endTime = time or 0;
	local _admin

	if utilx.IsValidSteamID(ply) then
		steamid32 = ply
		steamid32 = util.SteamIDTo64(steamid32)
	end

	if utilx.CheckType(admin, "Player") then
		_admin = admin:SteamID()
	else
		_admin = "Console"
	end

	bwsql:EasyQuery("INSERT INTO `cu_bans` (steamid32, steamid64, reason, startTime, endTime, admin) VALUES('%s', '%s', '%s', %i, %i, '%s')",
		steamid32, steamid64, reason, startTime, endTime, _admin)

	bans[steamid32] = {
		steamid64 = steamid64,
		reason = reason,
		startTime = startTime,
		endTime = endTime,
		admin = _admin
	}

	cu.log.Write("ADMIN", "%s(%s) banned %s(%s) for %s until %s",
		cu.util.PlayerName(ply), _admin, cu.util.PlayerName(target), steamid32, reason, string.NiceTime(endTime))

	if utilx.CheckType(ply, "Player") then
		ply:Kick( "Banned: "..reason.." for "..string.NiceTime(endTime) )
	end
end

function PLUGIN:UnbanPlayer(steamid, ply)
	local steamid = utilx.CheckTypeStrict(steamid, "string")

	if ply and IsValid(ply) then
		cu.log.Write("ADMIN", "%s(%s) unbanned %s", cu.util.PlayerName(ply), ply:SteamID(), str)
	end

	if utilx.IsValidSteamID(steamid) then
		bwsql:EasyQuery("DELETE FROM `cu_bans` WHERE steamid32 = '%s'", steamid, function(result, status, err)
			if result then
				cu.G.Bans[steamid] = nil
			end
		end)
	end
end

PLUGIN:AddCommand("ban", {
  description = "Ban a player.",
  help = "Ban <player> <time> <reason>",
  permission = "cu_ban",
  chat = "ban",
  OnRun = function(ply, name, time, reason)
    if !utilx.CheckType(name, "string") or !CheckType(tonumber(time), "number") then
  		return false, "Usage: <player|steamid> <time in minutes> <reason>"
  	end

  	local time = tonumber(time) * 60

  	local target = cu.util.FindPlayer(name, ply, false)

  	if target then
  		cu.util.Broadcast(ply:GetGroupColor(), cu.util.PlayerName(ply), cu.color_text, " banned ", target:GetGroupColor(), cu.util.PlayerName(target), cu.color_text, " for ", cu.color_reason, reason)
  		PLUGIN:BanPlayer(ply, target, tonumber(time), reason)
  	end
  end
})

PLUGIN:AddCommand("unban", {
  description = "Unban a player.",
  help = "Unban <steamid>",
  permission = "cu_unban",
  chat = "unban",
  OnRun = function(ply, str)
    if PLUGIN:UnbanPlayer(str, ply) then
  		cu.util.Broadcast(ply:GetGroupColor(), cu.util.PlayerName(ply), cu.color_text, " unbanned ", cu.color_player, str)
  	end
  end
})

PLUGIN:AddCommand("kick", {
	description = "Kick a specfic player.",
	help = "Kick <player> <reason>",
	permission = "cu_kick",
	chat = "kick",
	OnRun = function(ply, name, reason)
		if utilx.IsValidSteamID(name) then
			return false, "Usage: <player> <reason>"
		end

		local reason = reason or "No reason specified."

		local target = cu.util.FindPlayer(name, ply, true)

		if target then
			cu.log.Write("ADMIN", "%s(%s) kicked %s(%s) for %s", cu.util.PlayerName(ply), cu.util.GetSteamID(ply), cu.util.PlayerName(target), target:SteamID(), reason)
			cu.util.Broadcast(cu.util.GetGroupColor(ply), cu.util.PlayerName(ply), cu.color_text, " kicked ", cu.util.GetGroupColor(target), cu.util.PlayerName(target), cu.color_text, " for ", cu.color_reason, reason)
			target:Kick(reason)
		end
	end
})

PLUGIN:AddHook("CU_PluginUnregister", "cu_ClearBanTable", function()
	bans = nil
end)

PLUGIN:AddHook("BWSQL_DBConnected", "cu_BanLoader", function()
	bwsql:EasyQuery("SELECT * FROM `cu_bans`", function(result, status, err)
		if !result then return; end

		for k,v in pairs(result) do
			if (v.endTime != 0) and (v.endTime <= os.time()) then
				bwsql:EasyQuery("DELETE FROM `cu_bans` WHERE steamid32 = '%s'", v.steamid32)
			end

			bans[v.steamid32] = {
				steamid64 = v.steamid64,
				reason = v.reason,
				startTime = v.startTime,
				endTime = v.endTime,
				admin = v.admin
			}
		end
	end)
end)

PLUGIN:AddHook("CheckPassword", "cu_BanCheck", function(steamid)
	local steamid32 = util.SteamIDFrom64(steamid)
	local data = bans[steamid32]

	if data then
		if tonumber(data.endTime) != 0 then
			if tonumber(data.endTime) + tonumber(data.startTime) <= os.time() then
				PLUGIN:UnbanPlayer(steamid32)
			else
				return false, "You're banned\n Reason: "..data.reason.."\n Duration: "..string.NiceTime(data.endTime).."\n"
			end

		else
			return false, "Banned: "..data.reason.." - permanent"
		end
	end
end)

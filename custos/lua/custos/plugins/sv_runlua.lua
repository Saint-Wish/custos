--[[
	 _____           _
	/  __ \         | |
	| /  \/_   _ ___| |_ ___  ___
	| |   | | | / __| __/ _ \/ __|
	| \__/\ |_| \__ \ || (_) \__ \
	 \____/\__,_|___/\__\___/|___/

	~https://github.com/BadWolfGames/custos
]]
local PLUGIN = PLUGIN

PLUGIN.Name = "Run Lua"
PLUGIN.Author = "Wishbone"
PLUGIN.Desc = "Run lua code."

PLUGIN:AddPermissions({
	["cu_runlua"] = "Run Lua"
})

PLUGIN:AddCommand("runlua", {
  description = "Allows users to run lua code."
  help = "lua"
  permission = "cu_runlua"
  chat = "lua"
  OnRun = function(ply, str)
    local res = CompileString(str, "CU RunLua["..ply:SteamID().."]", false)
  	local env = {
  		me = ply,
  		trace = ply:GetEyeTrace(),
  		this = ply:GetEyeTrace().Entity,
  		there = ply:GetEyeTrace().HitPos,
  		here = ply:GetPos(),
  		phys = IsValid(ply:GetEyeTrace().Entity) and ply:GetEyeTrace().Entity:GetPhysicsObject(),
  		PrintTable = function(...) ply:PlayerPrintTable(...) end,
  		print = function(...) ply:PrintToPlayer(...) end,
  	}

  	setmetatable(env, {
  		__index = _G,
  		__newindex = function(self, k, v)
  			rawset(_G, k, v)
  		end
  	})

  	if utilx.CheckType(res, "string") then
  		chat.AddText(ply, "[RunLua] Compile error: "..res)
  		return
  	end

  	setfenv(res, env)

  	local function pcall_err(f)
  		return f.."\n"..debug.traceback()
  	end

  	local run, err = xpcall(res, pcall_err)
  	if run then
  		chat.AddText(ply, "[RunLua] Ouput: "..tostring(run))
  	else
  		chat.AddText(ply, "[RunLua] Error: "..tostring(err))
  	end
  end
})

PLUGIN:Register()

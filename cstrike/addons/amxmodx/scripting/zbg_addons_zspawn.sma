#include <amxmodx>
#include <fakemeta>
#include <zombieplague>

#define PLUGIN "[ZP] Server addon: ZSpawn System"
#define VERSION "5.3"
#define AUTHOR "Game over & Fintok!"

new bool: g_IsZspawned[33]
new g_iRoundNum, g_LastRound[33], ip[24], ips[33][24], configsdir[64]
new z_spawn_time, z_spawn_mode, z_spawn_infection, z_spawn_team_infection, z_spawn_swarm, z_spawn_team_swarm, z_spawn_plague, z_spawn_team_plague, z_spawn_nemesis, z_spawn_team_nemesis, z_spawn_survivor, z_spawn_team_survivor, z_spawn_client_settings, z_spawn_client_rate, z_spawn_client_cmdrate, z_spawn_client_updaterate, z_spawn_antireconnect

public plugin_init() 
{
        new mapname[32]
        get_mapname(mapname, charsmax(mapname))
        if(containi(mapname, "cs_assault_necro") != -1)
        {
        pause("ad")
        return
        }
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar(PLUGIN, VERSION, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY)
	
	z_spawn_time = register_cvar("zp_spawn_time", "5")
	z_spawn_mode = register_cvar("zp_spawn_mode", "2")
	z_spawn_infection = register_cvar("zp_spawn_infection", "1")
	z_spawn_team_infection = register_cvar("zp_spawn_team_infection", "0")
	z_spawn_swarm = register_cvar("zp_spawn_swarm", "1")
	z_spawn_team_swarm = register_cvar("zp_spawn_team_swarm", "0")
	z_spawn_plague = register_cvar("zp_spawn_plague", "1")
	z_spawn_team_plague = register_cvar("zp_spawn_team_plague", "0")
	z_spawn_nemesis = register_cvar("zp_spawn_nemesis", "1")
	z_spawn_team_nemesis = register_cvar("zp_spawn_team_nemesis", "0")
	z_spawn_survivor = register_cvar("zp_spawn_survivor", "1")
	z_spawn_team_survivor = register_cvar("zp_spawn_team_survivor", "0")
	z_spawn_client_settings = register_cvar("zp_spawn_client_settings", "1")
	z_spawn_client_rate = register_cvar("zp_spawn_client_rate", "15000")
	z_spawn_client_cmdrate = register_cvar("zp_spawn_client_cmdrate", "71")
	z_spawn_client_updaterate = register_cvar("zp_spawn_client_updaterate", "71")
	z_spawn_antireconnect = register_cvar("zp_spawn_antireconnect", "1")

	register_logevent("evStartRound", 2, "1=Round_Start")

	register_event("TeamInfo", "evTeamInfo", "a", "2=TERRORIST", "2=CT")
}

public plugin_cfg()
{
	get_localinfo("amxx_configsdir", configsdir, 63)
	return server_cmd("exec %s/zp_zspawn_system.cfg", configsdir)
}

public client_putinserver(id)
{
	if(is_user_hltv(id) || is_user_bot(id))
		return PLUGIN_HANDLED

	if(get_pcvar_num(z_spawn_antireconnect))
	{
		get_user_ip(id, ip, 23, 0)

		if(equali(ip, ips[id]))
		{
			if(g_iRoundNum != g_LastRound[id])
				g_IsZspawned[id] = false
		}
		else
		{
			g_IsZspawned[id] = false
			set_task(1.0, "ClientSettings", id)
		}
	}
	else
	{
		g_IsZspawned[id] = false
		set_task(1.0, "ClientSettings", id)
	}
	return PLUGIN_HANDLED
}

public ClientSettings(id)
{
	if(get_pcvar_num(z_spawn_client_settings))
	{
		client_cmd(id, "fakelag 0")
		client_cmd(id, "fakeloss 0")
		client_cmd(id, "rate %d", get_pcvar_num(z_spawn_client_rate))
		client_cmd(id, "cl_cmdrate %d", get_pcvar_num(z_spawn_client_cmdrate))
		client_cmd(id, "cl_updaterate %d", get_pcvar_num(z_spawn_client_updaterate))
		client_cmd(id, "cl_allowupload 1")
		client_cmd(id, "cl_allowdownload 1")
		client_cmd(id, "cl_corpsestay 60")
	}
}

public evTeamInfo()
{
	static id
	id = read_data(1)

	if(!g_IsZspawned[id])
	{
		set_task(get_pcvar_float(z_spawn_time), "ZSpawnMode", id)
		g_IsZspawned[id] = true
	}
}

public ZSpawnMode(id)
{
	if(is_user_alive(id))
		return PLUGIN_HANDLED

	switch(get_pcvar_num(z_spawn_mode))
	{
		case 1: set_task(0.1, "ZSpawn", id)
		case 2:
		{
			set_task(0.1, "ZSpawn", id)
			set_task(0.3, "FuncTeleport", id)
		}
	}
	return PLUGIN_HANDLED
}

public ZSpawn(id) 
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED
	
	if(zp_is_nemesis_round() && get_pcvar_num(z_spawn_nemesis)) 
	{
		switch(get_pcvar_num(z_spawn_team_nemesis)) 
		{
			case 0: zp_respawn_user(id, ZP_TEAM_ZOMBIE)
			case 1: zp_respawn_user(id, ZP_TEAM_HUMAN)
			case 2:
			{
				switch(random_num(0, 1))
				{
					case 0: zp_respawn_user(id, ZP_TEAM_ZOMBIE)
					case 1: zp_respawn_user(id, ZP_TEAM_HUMAN)
				}
			}
		}
	} 
	else if(zp_is_survivor_round() && get_pcvar_num(z_spawn_survivor)) 
	{
		switch(get_pcvar_num(z_spawn_team_survivor))
		{
			case 0: zp_respawn_user(id, ZP_TEAM_ZOMBIE)
			case 1: zp_respawn_user(id, ZP_TEAM_HUMAN)
			case 2:
			{
				switch(random_num(0, 1))
				{
					case 0: zp_respawn_user(id, ZP_TEAM_ZOMBIE)
					case 1: zp_respawn_user(id, ZP_TEAM_HUMAN)
				}
			}
		}
	} 
	else if(zp_is_swarm_round() && get_pcvar_num(z_spawn_swarm)) 
	{
		switch(get_pcvar_num(z_spawn_team_swarm)) 
		{
			case 0: zp_respawn_user(id, ZP_TEAM_ZOMBIE)
			case 1: zp_respawn_user(id, ZP_TEAM_HUMAN)
			case 2:
			{
				switch(random_num(0, 1))
				{
					case 0: zp_respawn_user(id, ZP_TEAM_ZOMBIE)
					case 1: zp_respawn_user(id, ZP_TEAM_HUMAN)
				}
			}
		}
	} 
	else if(zp_is_plague_round() && get_pcvar_num(z_spawn_plague))
	{
		switch(get_pcvar_num(z_spawn_team_plague))
		{
			case 0: zp_respawn_user(id, ZP_TEAM_ZOMBIE)
			case 1: zp_respawn_user(id, ZP_TEAM_HUMAN)
			case 2:
			{
				switch(random_num(0, 1))
				{
					case 0: zp_respawn_user(id, ZP_TEAM_ZOMBIE)
					case 1: zp_respawn_user(id, ZP_TEAM_HUMAN)
				}
			}
		}
	} 
	else if(zp_has_round_started() && get_pcvar_num(z_spawn_infection) && !zp_is_nemesis_round() && !zp_is_survivor_round() && !zp_is_swarm_round() && !zp_is_plague_round()) 
	{
		switch(get_pcvar_num(z_spawn_team_infection)) 
		{
			case 0: zp_respawn_user(id, ZP_TEAM_ZOMBIE)
			case 1: zp_respawn_user(id, ZP_TEAM_HUMAN)
			case 2:
			{
				switch(random_num(0, 1))
				{
					case 0: zp_respawn_user(id, ZP_TEAM_ZOMBIE)
					case 1: zp_respawn_user(id, ZP_TEAM_HUMAN)
				}
			}
		}
	}
	return PLUGIN_HANDLED
}

public FuncTeleport(id)
{
	if(!is_user_alive(id))
		return
	
	static Float:iOrigin[3]
	pev(id, pev_origin, iOrigin)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, iOrigin, 0)
	write_byte(TE_TELEPORT)
	engfunc(EngFunc_WriteCoord, iOrigin[0])
	engfunc(EngFunc_WriteCoord, iOrigin[1])
	engfunc(EngFunc_WriteCoord, iOrigin[2])
	message_end()
}

public client_disconnect(id)
{
	if(is_user_hltv(id) || is_user_bot(id))
		return PLUGIN_HANDLED
	
	if(task_exists(id))
		remove_task(id)

	if(get_pcvar_num(z_spawn_antireconnect))
	{
		get_user_ip(id, ips[id], 23, 0)
		g_LastRound[id] = g_iRoundNum
	}
	return PLUGIN_HANDLED
}

public evStartRound()
{
	if(get_pcvar_num(z_spawn_antireconnect))
		g_iRoundNum++
}
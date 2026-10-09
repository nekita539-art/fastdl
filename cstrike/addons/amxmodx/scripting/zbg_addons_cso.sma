#include < amxmodx >
#include < hamsandwich >
#include < zombieplague >
#include < fun >
#include < fakemeta >
#include < cstrike >

#define PLUGIN		"VIP"
#define VERSION 	"0.1"
#define AUTHOR 		"SNAFFY"

#define VIP_CSO 	ADMIN_LEVEL_F
const DMG_HEGRENADE = (1<<24)

new szTwoJump[33], szJump[33], szDoJump[33]

new Float:g_damage[33]

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_event("ResetHUD", "ResetHUD", "be")

	register_clcmd("priveleges", "buy_motd")

	RegisterHam(Ham_Spawn, "player", "SpawnPlayer", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")

	register_forward(FM_PlayerPreThink, "TwoJump")
	register_forward(FM_PlayerPostThink, "PostTwoJump")
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	
	if(victim == attacker)
		return HAM_IGNORED
		
	if(damage_type & DMG_HEGRENADE)
		return HAM_IGNORED
		
	if(!is_user_connected(attacker))
		return HAM_IGNORED
	
	if(zp_get_user_zombie(attacker) || zp_get_user_survivor(attacker))
		return HAM_IGNORED

	if(~get_user_flags(attacker) & VIP_CSO)
		return HAM_IGNORED

	g_damage[attacker]+damage

	if(g_damage[attacker] > 500.0) 
	{
		zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker)+1)
		g_damage[attacker] -= 500.0
	}

	return HAM_IGNORED	
}

public buy_motd(id)
{
	show_motd(id,"vip.txt","Покупка привелегий")
	return PLUGIN_HANDLED;   
}

public zp_user_infected_post(id, infector, nemesis)
{
	if(is_user_alive(infector))
	{
		if(get_user_flags(infector) & VIP_CSO)
			set_user_health(infector, get_user_health(infector) + 1000)
	}
}

public SpawnPlayer(id)
{
	if(!is_user_alive(id))
		return

	if(~get_user_flags(id) & VIP_CSO)
		return

	set_user_armor(id, 100)
	szTwoJump[id] = true
}

public TwoJump(id)
{
	if(szTwoJump[id] && (get_user_flags(id) & VIP_CSO) && !zp_get_user_zombie(id) && !zp_get_user_survivor(id))  
	{
		new szButton = pev(id, pev_button)
		new szOldButton = pev(id, pev_oldbuttons)

		if((szButton & IN_JUMP) && !(pev(id, pev_flags) & FL_ONGROUND) && !(szOldButton & IN_JUMP))
		{
			if((szJump[id] < 2) && (get_user_flags(id) & ADMIN_LEVEL_F))
			{
				szDoJump[id] = true
				szJump[id]++

				return PLUGIN_CONTINUE
			}
		
			if(szJump[id] < 2)
			{
				szDoJump[id] = true
				szJump[id]++

				return PLUGIN_CONTINUE
			}
		}
		if((pev(id, pev_flags) & FL_ONGROUND))
		{
			szJump[id] = 0
		}
	}
	return PLUGIN_CONTINUE
}

public PostTwoJump(id)
{
	if(szTwoJump[id] && get_user_flags(id) & VIP_CSO)
	{
		if(!is_user_alive(id) || zp_get_user_zombie(id) || zp_get_user_survivor(id)) 
			return PLUGIN_CONTINUE

		if(szDoJump[id])
		{
			new Float:szVelocity[3]  

			pev(id, pev_velocity, szVelocity)

			szVelocity[2] = random_float(295.0,305.0)
			set_pev(id, pev_velocity, szVelocity)

			szDoJump[id] = false

			return PLUGIN_CONTINUE
		}
	}      

	return PLUGIN_CONTINUE
}	

public client_connect(id) 
	g_damage[id] = 0.0

public client_disconnect(id)
	g_damage[id] = 0.0

public ResetHUD(id) 
	set_task(0.5, "VIP", id + 6910)

public VIP(TaskID)
{
	new id = TaskID - 6910
	
	if(get_user_flags(id) & VIP_CSO)
	{
		message_begin(MSG_ALL, get_user_msgid("ScoreAttrib"))
		write_byte(id)
		write_byte(4)
		message_end()
	}
	return PLUGIN_HANDLED
}
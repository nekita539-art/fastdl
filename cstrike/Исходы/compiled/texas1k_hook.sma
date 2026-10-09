#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <zombieplague>

#define DL_FLAGS			ADMIN_SLAY
#define MAXPLAYERS			32

#define RANDOM_NUM			random_num(0, 255)

new bool: ishooked[32]
new hookorigin[32][3]

new g_laserbeam
new g_ball

new HumanHook[33], ZombieHook[33], HookTime[33]

public plugin_init()
{
	register_clcmd("+hook", "hook_on")
	register_clcmd("-hook", "hook_off")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
}

public event_round_start(id)
{
	for(new i; i < MAXPLAYERS + 1; i++)
	{
		HumanHook[i] = 0
		ZombieHook[i] = 0
		HookTime[i] = 0
	}
}

public plugin_precache() 
{
	precache_sound("texas1k/hook.wav")
	
	g_laserbeam = precache_model("sprites/laserbeam.spr")
	g_ball = precache_model("sprites/muz4.spr")
}

public client_disconnect(id)
{
	remove_hook(id)
}

public client_putinserver(id)
{
	remove_hook(id)
}

public hook_on(id)
{
	if(!is_user_alive(id))
	{
		color_chat(id, "!g[ZP] !tХук !yзапрещён")
		return PLUGIN_HANDLED
	}
	if(zp_get_user_zombie(id))
	{
		color_chat(id, "!g[ZP] !tХук !yзапрещён")
		return PLUGIN_HANDLED
	}
	if(zp_get_user_survivor(id))
	{
		color_chat(id, "!g[ZP] !tХук !yзапрещён")
		return PLUGIN_HANDLED
	}
	if(zp_is_swarm_round())
	{
		color_chat(id, "!g[ZP] !tХук !yзапрещён")
		return PLUGIN_HANDLED
	}
	if(zp_is_plague_round())
	{
		color_chat(id, "!g[ZP] !tХук !yзапрещён")
		return PLUGIN_HANDLED
	}
	if(get_user_flags(id) & DL_FLAGS)
	{
		if(zp_get_user_zombie(id))
		{
			if(ZombieHook[id] < 0)
			{
				ZombieHook[id] += 0
				color_chat(id, "!g[ZP] !yЛимит !tHook(а) !yчерез !g%d !yраз(а)", 0 - ZombieHook[id])
			}
			else
			{
				return PLUGIN_HANDLED
			}
		}
		else
		{
			if(HumanHook[id] < 10)
			{
				HumanHook[id] += 1
				color_chat(id, "!g[ZP] !yЛимит !tHook(а) !yчерез !g%d !yраз(а)", 10 - HumanHook[id])
			}
			else
			{
				return PLUGIN_HANDLED
			}
		}
		
		get_user_origin(id, hookorigin[id-1], 3)
		
		ishooked[id-1] = true
		
		emit_sound(id, CHAN_STATIC, "texas1k/hook.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		HookTime[id] = 100
		set_task(0.1, "hook_task", id, "", 0, "ab")
		hook_task(id)
	}
	else
	{
		color_chat(id, "!g[ZP] !tHook !yтолько для !g[DIAMOND]")
		color_chat(id, "!g[ZP] !yКупить !tHook !yможно тут !gvk.com/golovorez1337")
	}
	return PLUGIN_HANDLED
}

public is_hooked(id)
{
	return ishooked[id-1]
}

public hook_off(id)
{
	remove_hook(id)
	
	return PLUGIN_HANDLED
}

public hook_task(id)
{
	if(!is_user_connected(id) || !is_user_alive(id) || HookTime[id] == 0)
	{
		remove_hook(id)
		remove_beam(id)
	}
	else
	{
		remove_beam(id)
		draw_hook(id)
	}
	
	HookTime[id] -= 1
	new origin[3], Float: velocity[3]
	get_user_origin(id, origin)
	new distance = get_distance(hookorigin[id-1], origin)
	
	if(distance > 25)
	{
		velocity[0] = (hookorigin[id-1][0] - origin[0]) * (2.0 * 350 / distance)
		velocity[1] = (hookorigin[id-1][1] - origin[1]) * (2.0 * 350 / distance)
		velocity[2] = (hookorigin[id-1][2] - origin[2]) * (2.0 * 350 / distance)
		
		entity_set_vector(id, EV_VEC_velocity, velocity)
	}
	else
	{
		entity_set_vector(id, EV_VEC_velocity, Float: {0.0, 0.0, 0.0})
		remove_hook(id)
	}
}

public draw_hook(id)
{
	if(get_user_flags(id) & DL_FLAGS)
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(1)
		write_short(id)
		write_coord(hookorigin[id-1][0])
		write_coord(hookorigin[id-1][1])
		write_coord(hookorigin[id-1][2])
		write_short(g_laserbeam)
		write_byte(0)
		write_byte(0)
		write_byte(1)
		write_byte(40)
		write_byte(50)
		
		if(zp_get_user_zombie(id))
		{
			write_byte(RANDOM_NUM)
			write_byte(RANDOM_NUM)
			write_byte(RANDOM_NUM)
		}
		else
		{
			write_byte(RANDOM_NUM)
			write_byte(RANDOM_NUM)
			write_byte(RANDOM_NUM)
		}
		
		write_byte(150)
		write_byte(0)
		message_end()
	}
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPRITE)
	write_coord(hookorigin[id-1][0])
	write_coord(hookorigin[id-1][1])
	write_coord(hookorigin[id-1][2])
	write_short(g_ball)
	write_byte(20)
	write_byte(164)
	message_end()
}

public remove_hook(id)
{
	if(task_exists(id))
		remove_task(id)
	
	remove_beam(id)
	ishooked[id-1] = false
}

public remove_beam(id)
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(99)
	write_short(id)
	message_end()
}

stock color_chat(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)
	
	replace_all(msg, 190, "!g", "^4")
	replace_all(msg, 190, "!y", "^1")
	replace_all(msg, 190, "!t", "^3")
	
	if(id) players[0] = id; else get_players(players, count, "ch")
	{
		for(new i = 0; i < count; i++)
		{
			if(is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
				write_byte(players[i])
				write_string(msg)
				message_end()
			}
		}
	}
}
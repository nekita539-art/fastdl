#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <zombieplague>

#define PLUGIN "[ZBG] Zombie: Ghost"
#define VERSION "0.1"
#define AUTHOR "SNAFFY"

new const zclass_name[] = "Детка"
new const zclass_info[] = "\d|\yПризрак\d| \r'G'"
new const zclass_model[] = "zbg_ghost"
new const zclass_clawmodel[] = "zombie/v_knife_cosspeed1.mdl"
new const zclass_clawmodel_invi[] = "models/zbg/zombie/v_knife_cosspeed1_inv.mdl"
const zclass_health = 3600
const zclass_speed = 295
const Float:zclass_gravity = 0.7
const Float:zclass_knockback = 6.0

new const zombie_sound_invisible[] = "zbg/zombie/zombi_pressure_female.wav"

new idclass
const Float:invisible_time = 10.0
const Float:invisible_timewait = 10.0
const invisible_dmg = 200
const Float:invisible_speed = 215.0
const Float:invisible_gravity = 0.9
const invisible_alpha = 10

new g_invisible[33], g_invisible_wait[33]

new g_msgSayText
new g_maxplayers
new g_roundend

enum (+= 100)
{
	TASK_INVISIBLE = 2000,
	TASK_WAIT_INVISIBLE,
	TASK_INVISIBLE_SOUND,
	TASK_BOT_USE_SKILL
}

#define ID_INVISIBLE (taskid - TASK_INVISIBLE)
#define ID_WAIT_INVISIBLE (taskid - TASK_WAIT_INVISIBLE)
#define ID_INVISIBLE_SOUND (taskid - TASK_INVISIBLE_SOUND)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "Death", "a")
	register_event("CurWeapon", "EventCurWeapon", "be", "1=1")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	register_clcmd("drop", "cmd_invisible")
	
	g_msgSayText = get_user_msgid("SayText")
	g_maxplayers = get_maxplayers()
}

public plugin_precache()
{
	precache_model(zclass_clawmodel_invi)
	precache_sound(zombie_sound_invisible)
	
	idclass = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
}

public client_putinserver(id)
{
	reset_value_player(id)
}

public client_disconnect(id)
{
	reset_value_player(id)
}

public event_round_start()
{
	g_roundend = 0
	
	for (new id=1; id<=g_maxplayers; id++)
	{
		if (!is_user_connected(id)) continue;
		
		reset_value_player(id)
	}
}

public logevent_round_end()
{
	g_roundend = 1
}

public Death()
{
	new victim = read_data(2) 
	reset_value_player(victim)
}

public EventCurWeapon(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;
	
	if(g_invisible[id]) set_user_maxspeed(id, invisible_speed);
	
	return PLUGIN_CONTINUE;
}

public zp_user_infected_post(id)
{
	reset_value_player(id)
	
	if(zp_get_user_nemesis(id)) return;
	
	if(zp_get_user_zombie_class(id) == idclass)
	{
		if(is_user_bot(id))
		{
			set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
			return
		}
		
		zp_colored_print(id, "^x04[ZBG]^x01 Your skill is^x04 Stealth^x01. Cooldown^x04 %.1f ^x01seconds.", invisible_timewait)
	}
}

public zp_user_humanized_post(id)
{
	reset_value_player(id)
}

public zp_user_unfrozen(id)
{
	if(g_invisible[id])
	{
		set_user_rendering(id,kRenderFxGlowShell,20,20,20,kRenderTransAlpha, invisible_alpha)
		set_user_maxspeed(id, invisible_speed)
		set_user_gravity(id, invisible_gravity)
	}
}

public cmd_invisible(id)
{
	if (g_roundend) return PLUGIN_CONTINUE
	
	if (!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_nemesis(id)) return PLUGIN_CONTINUE

	new health = get_user_health(id) - invisible_dmg
	if (zp_get_user_zombie_class(id) == idclass && health>0 && !g_invisible[id] && !g_invisible_wait[id])
	{
		g_invisible[id] = 1
		
		set_wpnmodel(id)
		set_user_health(id, health)
		set_user_rendering(id,kRenderFxGlowShell,20,20,20,kRenderTransAlpha, invisible_alpha)
		set_user_footsteps(id, 1)
		set_user_maxspeed(id, invisible_speed)
		set_user_gravity(id, invisible_gravity)
		PlayEmitSound(id, zombie_sound_invisible)
		
		set_task(invisible_time, "RemoveInvisible", id+TASK_INVISIBLE)
		set_task(2.0, "InvisibleSound", id+TASK_INVISIBLE_SOUND, _, _, "b")

		zp_colored_print(id, "^x04[ZBG]^x01 You will^x04 Stealth^x01 for^x04 %.1f ^x01seconds.", invisible_time)
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	
	if (!is_user_alive(id)) return;

	cmd_invisible(id)
	
	set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

public InvisibleSound(taskid)
{
	new id = ID_INVISIBLE_SOUND
	
	if (g_invisible[id]) PlayEmitSound(id, zombie_sound_invisible)
	else remove_task(taskid)
}

public RemoveInvisible(taskid)
{
	new id = ID_INVISIBLE
	
	g_invisible[id] = 0
	
	set_wpnmodel(id)
	set_user_rendering(id)
	set_user_footsteps(id, 0)
	set_user_maxspeed(id, float(zclass_speed))
	set_user_gravity(id, zclass_gravity)
	zp_colored_print(id, "^x04[ZBG]^x01 Your^x04 Stealth^x01 skill is over.")
	
	g_invisible_wait[id] = 1
	
	set_task(invisible_timewait, "RemoveWaitInvisible", id+TASK_WAIT_INVISIBLE)
}

public RemoveWaitInvisible(taskid)
{
	new id = ID_WAIT_INVISIBLE
	
	g_invisible_wait[id] = 0
	
	zp_colored_print(id, "^x04[ZBG]^x01 Your skill^x04 Stealth^x01 is ready.")
}

set_wpnmodel(id)
{
	if (!is_user_alive(id)) return;
	
	if (get_user_weapon(id) == CSW_KNIFE)
	{
		if (g_invisible[id])
		{
			set_pev(id, pev_viewmodel2, zclass_clawmodel_invi)
		}
		else
		{
			static temp[100]
			format(temp, charsmax(temp), "models/zbg/%s", zclass_clawmodel)
			set_pev(id, pev_viewmodel2, temp)
		}
	}	
}

PlayEmitSound(id, const sound[])
{
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

reset_value_player(id)
{
	g_invisible[id] = 0
	g_invisible_wait[id] = 0
	
	remove_task(id+TASK_INVISIBLE)
	remove_task(id+TASK_WAIT_INVISIBLE)
	remove_task(id+TASK_BOT_USE_SKILL)
}

zp_colored_print(target, const message[], any:...)
{
	static buffer[512], i, argscount
	argscount = numargs()
	
	if (!target)
	{
		static player
		for (player = 1; player <= g_maxplayers; player++)
		{
			if (!is_user_connected(player))
				continue;
			
			static changed[5], changedcount
			changedcount = 0
			
			for (i = 2; i < argscount; i++)
			{
				if (getarg(i) == LANG_PLAYER)
				{
					setarg(i, 0, player)
					changed[changedcount] = i
					changedcount++
				}
			}
			
			vformat(buffer, charsmax(buffer), message, 3)
			
			message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, player)
			write_byte(player)
			write_string(buffer)
			message_end()
			
			for (i = 0; i < changedcount; i++)
				setarg(changed[i], 0, LANG_PLAYER)
		}
	}
	else
	{
		vformat(buffer, charsmax(buffer), message, 3)
		
		message_begin(MSG_ONE, g_msgSayText, _, target)
		write_byte(target)
		write_string(buffer)
		message_end()
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/

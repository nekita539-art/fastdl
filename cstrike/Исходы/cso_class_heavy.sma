#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <xs>
#include <hamsandwich>
#include <zombieplague>
#include <dhudmessage>

#define PLUGIN_NAME	"[CSO:Heavy Zombie]"
#define PLUGIN_VERSION	"1.1"
#define PLUGIN_AUTHOR	"Jim/4e/|"

//#define SUPPORT_BOT_TO_USE		

#define TASK_SET_TRAP		1234
#define TASK_REMOVE_TRAP 	4321

// Zombie Attributes
new const zclass_name[] = { "• Толстяк" } 
new const zclass_info[] = { "\rЛовушка R •" } 
new const zclass_model[] = { "strong_heavy2_z7p" }
new const zclass_clawmodel[] = { "v_strong_heavy2_fix.mdl" }
const zclass_health = 12000		
const zclass_speed = 245		
const Float:zclass_gravity = 0.85		
const Float:zclass_knockback = 0.0

new g_chance[33]
new g_msgScreenFade
const FFADE_IN = 0x0000
const FFADE_STAYOUT = 0x0004
const UNIT_SECOND = (1<<12)

new is_cooldown_time[33] = 0
new is_cooldown[33] = 0

// Models
new const Trap_Model[] = { "models/zombie_plague/zombie_trap.mdl" }	

// Sounds
new const TrapTrigger_Sound[] = { "common/bodysplat.wav" }	
new const PlayerCatched_Sound[] = { "Reega_kz/zombie_trap_cathed.wav" } 	
new const CantPlantTrap_Sound[] = { "common/wpn_denyselect.wav" } 

// Settings
const Max_Traps = 3	

// Weapons Offsets (win32)
const OFFSET_flNextPrimaryAttack = 46
const OFFSET_flNextSecondaryAttack = 47
const OFFSET_flTimeWeaponIdle = 48

// Linux diff's
const OFFSET_LINUX_WEAPONS = 4 

// Zombie id
new g_zclass_heavy

new Float:g_revenge_cooldown = 30.0 
new g_chance_to_cast = 20 
new const sound_sleep[] = "Reega_kz/zombi_sleeped.wav" //cast sound

// Vars
new cvar_TrapSetTime, cvar_TrapAffectTime
new g_TrapPromptSpr, g_PlayerCatchedSpr
new g_msgScreenShake, g_msgBarTime
new g_maxplayers
new user_has_traps[33]
new user_traps_ent[33][Max_Traps]
new bool:user_set_trap[33], set_trap_ent[33], Float:set_trap_origin[33][3]
new bool:user_be_catched[33], catched_trap_ent[33]

#if defined SUPPORT_BOT_TO_USE
new Float:bot_next_check_time[33]
#endif

public plugin_init()
{
        register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	
	cvar_TrapSetTime = register_cvar("zp_heavy_trap_settime", "1.0")		
	cvar_TrapAffectTime = register_cvar("zp_heavy_trap_affecttime", "6.0")	
	

	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_maxplayers = get_maxplayers()
	register_logevent("roundStart", 2, "1=Round_Start")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_StartFrame, "fw_StartFrame")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_Think, "fw_Think")      
	
	register_event("ResetHUD", "event_NewSpawn", "be")
	register_event("HLTV", "event_RoundStart", "a", "1=0", "2=0")
	
	#if defined SUPPORT_BOT_TO_USE
	register_event("Damage", "event_Damage", "be", "2>0")
	#endif
	
	g_msgScreenShake = get_user_msgid("ScreenShake")
	g_msgBarTime = get_user_msgid("BarTime")
	g_maxplayers = get_maxplayers()
	//register_event("CurWeapon", "Event_CurrentWeapon", "be", "1=1")
	
	register_dictionary("cso_classes.txt")
}
public plugin_precache()
{
	precache_sound(sound_sleep)
	precache_model(Trap_Model)
	
	precache_sound(TrapTrigger_Sound)
	precache_sound(PlayerCatched_Sound)
	precache_sound(CantPlantTrap_Sound)
   
	
	g_TrapPromptSpr = precache_model("sprites/effects/trap.spr")
	g_PlayerCatchedSpr = precache_model("sprites/effects/trap_prompt.spr")
	
	g_zclass_heavy = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
}

public client_damage(attacker,victim)
{
	if ((zp_get_user_zombie_class(victim) == g_zclass_heavy) && zp_get_user_zombie(victim) && !zp_get_user_nemesis(victim) && !zp_get_user_zombie(attacker) && victim != attacker && (is_cooldown[victim] == 0))
	{
		g_chance[victim] = random_num(0, 999)
		if (g_chance[victim] < g_chance_to_cast)
		{
			message_begin(MSG_ONE, g_msgScreenFade, _, attacker)
			write_short(4) // duration
			write_short(4) // hold time
			write_short(FFADE_STAYOUT) // fade type
			write_byte(0) // red
			write_byte(0) // green
			write_byte(0) // blue
			write_byte(255) // alpha
			message_end()
			
			set_user_health(victim, get_user_health(victim) + ( get_user_health(victim) / 10 ) )
			
			set_task(4.0,"wake_up",attacker)
			set_task(1.0, "ShowHUD", victim, _, _, "a",is_cooldown_time[victim])
			set_task(g_revenge_cooldown,"reset_cooldown",victim)
			
			emit_sound(attacker, CHAN_STREAM, sound_sleep, 1.0, ATTN_NORM, 0, PITCH_NORM);
			
			is_cooldown[victim] = 1
		}
	}
}

public reset_cooldown(id)
{
	if ((zp_get_user_zombie_class(id) == g_zclass_heavy) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{
		is_cooldown[id] = 0
		is_cooldown_time[id] = floatround(g_revenge_cooldown)

		color_chat(id, "%L", id, "CSO_CLASS_HEAVY_YOU_AVILITY")
	}
}

public ShowHUD(id)
{
	if(is_user_alive(id))
	{
		is_cooldown_time[id] = is_cooldown_time[id] - 1;
		set_dhudmessage(200, 100, 0, 0.80, 0.87, 0, 1.0, 1.1, 0.0, 0.0, -1)
		show_dhudmessage(id, "%L", id, "CSO_CLASS_RELOAD", is_cooldown_time[id])
	}else{
		remove_task(id)
	}
}

public wake_up(id)
{
	message_begin(MSG_ONE, g_msgScreenFade, _, id)
	write_short(UNIT_SECOND) // duration
	write_short(0) // hold time
	write_short(FFADE_IN) // fade type
	write_byte(0) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(255) // alpha
	message_end()
}

public zp_user_infected_post(id, infector, player)
{
	if (user_be_catched[id])
	{
		clear_user_sprite(id)
		set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
	}
	
	reset_vars(id)
	
	if (zp_get_user_zombie_class(id) == g_zclass_heavy && !zp_get_user_nemesis(id))
	{
		
		is_cooldown[id] = 0
		is_cooldown_time[id] = floatround(g_revenge_cooldown)

		//new note_cooldown = floatround(g_revenge_cooldown)

		color_chat(id, "%L", id, "CSO_CLASS_HEAVY_YOU_ABILITY2", Max_Traps)
		
		user_has_traps[id] = Max_Traps
	}

	remove_task(id)
	is_cooldown[id] = 0
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;
	
	if (!zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_heavy || zp_get_user_nemesis(id))
		return FMRES_IGNORED;
	
	#if defined SUPPORT_BOT_TO_USE
	if (is_user_bot(id))
	{
		bot_use_traps(id)
		return FMRES_IGNORED;
	}
	#endif
	
	static button, oldbutton
	button = get_uc(uc_handle, UC_Buttons)
	oldbutton = pev(id, pev_oldbuttons)
	
	if (!user_set_trap[id])
	{
		if ((button & IN_RELOAD) && !(oldbutton & IN_RELOAD))
		{
			do_set_trap(id)
		}
	}
	else
	{
		static user_flags, Float:user_origin[3], Float:fdistance
		user_flags = pev(id, pev_flags)
		pev(id, pev_origin, user_origin)
		user_origin[2] -= (user_flags & FL_DUCKING) ? 18.0 : 36.0
		fdistance = get_distance_f(user_origin, set_trap_origin[id])
		
		if (!(button & IN_RELOAD) || fdistance > 18.0)
		{
			stop_set_trap(id)
		}
	}
	
	return FMRES_HANDLED;
}

public fw_StartFrame()
{
	static Float:time, Float:next_check_time, id, i, classname[32], Float:origin1[3], Float:origin2[3]
	
	time = get_gametime()
	
	if (time >= next_check_time)
	{
		for (id = 1; id <= g_maxplayers; id++)
		{
			if (!is_user_connected(id) || !is_user_alive(id))
				continue;
			
			if (!zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_heavy || zp_get_user_nemesis(id))
				continue;
			
			for (i = 0; i < Max_Traps; i++)
			{
				if (user_traps_ent[id][i] <= 0)
					continue;
				
				if (!pev_valid(user_traps_ent[id][i]))
				{
					user_traps_ent[id][i] = 0
					continue;
				}
				
				pev(user_traps_ent[id][i], pev_classname, classname, charsmax(classname))
				if (!equal(classname, "ZOMBIE_TRAP_ENT"))
				{
					user_traps_ent[id][i] = 0
					continue;
				}
				
				if (pev(user_traps_ent[id][i], pev_iuser3) == 1)
					continue;
				
				pev(user_traps_ent[id][i], pev_origin, origin1)
				xs_vec_copy(origin1, origin2)
				origin2[2] += 30.0
				if (fm_is_point_visible(id, origin1, 1) || fm_is_point_visible(id, origin2, 1))
				{
					origin1[2] += 30.0
					create_user_sprite(id, origin1, g_TrapPromptSpr, 7)
				}
			}
		}
		
		next_check_time = time + 0.1
	}
	
	return FMRES_IGNORED;
}

public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;
	
	if (zp_get_user_zombie(id))
	{
		if (zp_get_user_zombie_class(id) != g_zclass_heavy || zp_get_user_nemesis(id))
			return FMRES_IGNORED;
		
		if (user_set_trap[id])
		{
			freeze_user_attack(id)
		}
	}
	else
	{
		if (user_be_catched[id] && pev_valid(catched_trap_ent[id]))
		{
			static classname[32]
			pev(catched_trap_ent[id], pev_classname, classname, charsmax(classname))
			if (!equal(classname, "ZOMBIE_TRAP_ENT"))
				return FMRES_IGNORED;
			
			set_pev(id, pev_velocity, Float:{ 0.0, 0.0, -200.0 })
			set_pev(id, pev_maxspeed, 1.0)
			
			static Float:user_origin[3], Float:ent_origin[3], Float:temp_origin[3]
			pev(id, pev_origin, user_origin)
			pev(catched_trap_ent[id], pev_origin, ent_origin)
			xs_vec_copy(ent_origin, temp_origin)
			temp_origin[2] += 18.0
			if (get_distance_f(user_origin, temp_origin) > 18.0)
			{
				temp_origin[2] += ((pev(id, pev_flags) & FL_DUCKING) ? 0.0 : 18.0)
				set_pev(id, pev_origin, temp_origin)
			}
		}
	}
	
	return FMRES_IGNORED;
}

public fw_Touch(ptr, ptd)
{
	if (!pev_valid(ptr) || !pev_valid(ptd))
		return FMRES_IGNORED;
	
	static classname[32]
	pev(ptr, pev_classname, classname, charsmax(classname))
	if (!equal(classname, "ZOMBIE_TRAP_ENT"))
		return FMRES_IGNORED;
	
	if (!(1 <= ptd <= g_maxplayers) || !is_user_alive(ptd) || zp_get_user_zombie(ptd))
		return FMRES_IGNORED;
	
	if (pev(ptr, pev_iuser2) == 0)
		return FMRES_IGNORED;

	if (pev(ptr, pev_iuser3) == 0 && !user_be_catched[ptd])
	{
		PlaySound(ptd, TrapTrigger_Sound)
		engfunc(EngFunc_EmitSound, ptd, CHAN_VOICE, PlayerCatched_Sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		user_screen_shake(ptd, 4, 2, 5)
		show_user_sprite(ptd, g_PlayerCatchedSpr)
		
		static Float:origin[3]
		pev(ptr, pev_origin, origin)
		origin[2] += ((pev(ptd, pev_flags) & FL_DUCKING) ? 18.0 : 36.0)
		set_pev(ptd, pev_origin, origin)
		set_pev(ptd, pev_velocity, Float:{ 0.0, 0.0, 0.0 })
		client_print(ptd, print_center, "%L", ptd, "CSO_CLASS_HEAVY_STOPED")
		
		set_pev(ptr, pev_iuser3, 1) 	
		set_pev(ptr, pev_iuser4, ptd)
		user_be_catched[ptd] = true	
		catched_trap_ent[ptd] = ptr	
		fm_set_rendering(ptr, kRenderFxNone, 0,0,0, kRenderNormal, 255)
		set_pev(ptr, pev_nextthink, get_gametime() + 0.05)
		
		static owner
		owner = pev(ptr, pev_iuser1)
		if (1 <= owner <= g_maxplayers) 
		client_print(owner, print_center, "%L", owner, "CSO_CLASS_HEAVY_TROPED")
		
		static Float:trap_affect_time
		trap_affect_time = get_pcvar_float(cvar_TrapAffectTime)
		if (trap_affect_time > 0.0)
		{
			static args[1]
			args[0] = ptr
			set_task(trap_affect_time, "remove_trap", TASK_REMOVE_TRAP, args, 1)
		}
	}
	
	return FMRES_IGNORED;
}

public fw_Think(ent)
{
	if (pev_valid(ent))
	{
		static classname[32]
		pev(ent, pev_classname, classname, charsmax(classname))
		if (equal(classname, "ZOMBIE_TRAP_ENT"))
		{
			if (pev(ent, pev_sequence) != 1)
			{
				set_pev(ent, pev_sequence, 1)
				set_pev(ent, pev_frame, 0.0)
			}
			else
			{
				if (pev(ent, pev_frame) > 241.0)
					set_pev(ent, pev_frame, 20.0)
				else
					set_pev(ent, pev_frame, pev(ent, pev_frame) + 1.0)
			}
			
			static catched_player
			catched_player = pev(ent, pev_iuser4)
			if (!user_be_catched[catched_player] || catched_trap_ent[catched_player] != ent)
			{
				engfunc(EngFunc_RemoveEntity, ent)
				return FMRES_IGNORED;
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.05)
		}
	}
	
	return FMRES_IGNORED;
}

freeze_user_attack(id)
{
	new weapon, weapon_name[32], weapon_ent
	weapon = get_user_weapon(id)
	if (weapon <= 0) 
	{
		return;
	}
	get_weaponname(weapon, weapon_name, charsmax(weapon_name))
	weapon_ent = fm_find_ent_by_owner(-1, weapon_name, id)
	
	if (get_weapon_next_pri_attack(weapon_ent) <= 0.1)
		set_weapon_next_pri_attack(weapon_ent, 0.5)
	
	if (get_weapon_next_sec_attack(weapon_ent) <= 0.1)
		set_weapon_next_sec_attack(weapon_ent, 0.5)
	
	if (weapon == CSW_XM1014 || weapon == CSW_M3)
	{
		if (get_weapon_idle_time(weapon_ent) <= 0.1)
			set_weapon_idle_time(weapon_ent, 0.5)
	}
}

do_set_trap(id)
{
	if (!user_set_trap[id])
	{
		if (set_a_trap(id, set_trap_ent[id], set_trap_origin[id]) == 1)
		{
			user_set_trap[id] = true
			
			new Float:velocity[3]
			pev(id, pev_velocity, velocity)
			velocity[0] = velocity[1] = 0.0
			set_pev(id, pev_velocity, velocity)
			
			new Float:set_trap_time, task_time
			set_trap_time = get_pcvar_float(cvar_TrapSetTime)
			task_time = floatround(set_trap_time, floatround_floor) + (floatfract(set_trap_time) >= 0.5 ? 1 : 0)
			set_task(set_trap_time, "trap_complete", (id + TASK_SET_TRAP))
			show_user_taskbar(id, task_time)
			
			client_print(id, print_center, "%L", id, "CSO_CLASS_HEAVY_UINSTALL")
			
			return 1;
		}
	}
	
	return 0;
}

stop_set_trap(id)
{
	if (user_set_trap[id])
	{
		client_print(id, print_center, "")
		
		if (pev_valid(set_trap_ent[id]))
			engfunc(EngFunc_RemoveEntity, set_trap_ent[id])
		
		user_set_trap[id] = false
		set_trap_ent[id] = 0
		remove_task(id + TASK_SET_TRAP)
		show_user_taskbar(id, 0)
	}
}

set_a_trap(id, &trap_entity, Float:trap_origin[3])
{
	if (user_has_traps[id] <= 0)
	{
		engfunc(EngFunc_EmitSound, id, CHAN_ITEM, CantPlantTrap_Sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		client_print(id, print_center, "%L", id, "CSO_CLASS_HEAVY_NO_TRAP")
		return 0;
	}
	
	new user_flags = pev(id, pev_flags)
	if (!(user_flags & FL_ONGROUND))
	{
		engfunc(EngFunc_EmitSound, id, CHAN_ITEM, CantPlantTrap_Sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		client_print(id, print_center, "%L", id, "CSO_CLASS_HEAVY_NO_GROUND")
		return 0;
	}
	
	new Float:origin[3]
	pev(id, pev_origin, origin)
	origin[2] -= (user_flags & FL_DUCKING) ? 18.0 : 36.0
	
	if (get_too_close_traps(origin))
	{
		engfunc(EngFunc_EmitSound, id, CHAN_ITEM, CantPlantTrap_Sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		client_print(id, print_center, "%L", id, "CSO_CLASS_HEAVY_BLIZKO")
		return 0;
	}
	
	client_print(id, print_center, "")
	
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if (!ent) return -1;
	
	// Set trap data
	set_pev(ent, pev_classname, "ZOMBIE_TRAP_ENT")
	set_pev(ent, pev_solid, SOLID_TRIGGER)
	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	set_pev(ent, pev_sequence, 0)
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_iuser1, id) 	
	set_pev(ent, pev_iuser2, 0)	
	set_pev(ent, pev_iuser3, 0)	
	set_pev(ent, pev_iuser4, 0)	
	
	// Set trap size
	new Float:mins[3] = { -20.0, -20.0, 0.0 }
	new Float:maxs[3] = { 20.0, 20.0, 30.0 }
	engfunc(EngFunc_SetSize, ent, mins, maxs)
	
	// Set trap model
	engfunc(EngFunc_SetModel, ent, Trap_Model)
	
	// Make trap invisible
	fm_set_rendering(ent, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
	
	// Set trap position
	set_pev(ent, pev_origin, origin)
	
	// Return trap entity id
	trap_entity = ent
	
	// Return trap position
	xs_vec_copy(origin, trap_origin)
	
	return 1;
}

public trap_complete(taskid)
{
	new id = taskid - TASK_SET_TRAP
	
	show_user_taskbar(id, 0)
	
	if (pev_valid(set_trap_ent[id]))
	{
		set_pev(set_trap_ent[id], pev_iuser2, 1) 
		user_has_traps[id]--
		set_user_traps_data(id, set_trap_ent[id])
		
		client_print(id, print_center, "%L", id, "CSO_CLASS_HEAVY_UINSTALL_END")
	}
	
	#if defined SUPPORT_BOT_TO_USE
	if (is_user_bot(id))
	{
		set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
		bot_next_check_time[id] = get_gametime() + 10.0	
	}
	#endif
	
	user_set_trap[id] = false
	set_trap_ent[id] = 0
}

public remove_trap(args[1])
{
	new ent = args[0]
	
	if (pev_valid(ent))
	{
		new classname[32]
		pev(ent, pev_classname, classname, charsmax(classname))
		if (!equal(classname, "ZOMBIE_TRAP_ENT"))
			return;
		
		new catched_player = pev(ent, pev_iuser4)
		if (user_be_catched[catched_player] && catched_trap_ent[catched_player] == ent)
		{
			clear_user_sprite(catched_player)
			set_pev(catched_player, pev_flags, (pev(catched_player, pev_flags) & ~FL_FROZEN))
			user_be_catched[catched_player] = false
			catched_trap_ent[catched_player] = 0
		}
		
		engfunc(EngFunc_RemoveEntity, ent)
	}
}

public zp_user_humanized_post(id)
{
	if (user_set_trap[id])
	{
		stop_set_trap(id)
		
		#if defined SUPPORT_BOT_TO_USE
		if (pev(id, pev_flags) & FL_FROZEN)
			set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
		#endif
	}
	
	reset_traps_owner(id)
	reset_vars(id)

}

public client_connect(id)
{
	reset_vars(id)
}

public client_disconnect(id)
{
	if (user_set_trap[id])
	{
		stop_set_trap(id)
		
		#if defined SUPPORT_BOT_TO_USE
		if (pev(id, pev_flags) & FL_FROZEN)
			set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
		#endif
	}
	
	if (user_be_catched[id])
	{
		clear_user_sprite(id)
		set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
	}
	
	reset_vars(id)
}

public event_NewSpawn(id)
{
	if (user_set_trap[id])
	{
		stop_set_trap(id)
		
		#if defined SUPPORT_BOT_TO_USE
		if (pev(id, pev_flags) & FL_FROZEN)
			set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
		#endif
	}
	
	if (user_be_catched[id])
	{
		clear_user_sprite(id)
		set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
	}
	
	reset_vars(id)
}

public event_Death()
{
	new id = read_data(2)
	if (!(1 <= id <= g_maxplayers))
		return;
	
	if (user_set_trap[id])
	{
		stop_set_trap(id)
		
		#if defined SUPPORT_BOT_TO_USE
		if (pev(id, pev_flags) & FL_FROZEN)
			set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
		#endif
	}
	
	if (user_be_catched[id])
	{
		clear_user_sprite(id)
		set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
	}
	
	reset_traps_owner(id)
	reset_vars(id)
}

public event_RoundStart()
{
	remove_task(TASK_REMOVE_TRAP)
	remove_all_traps()
}

get_too_close_traps(const Float:origin[3])
{
	new bool:find, ent, Float:ent_origin[3]
	find = false
	ent = -1
	while ((ent = fm_find_ent_by_class(ent, "ZOMBIE_TRAP_ENT")))
	{
		if (pev(ent, pev_iuser2) == 1)
		{
			pev(ent, pev_origin, ent_origin)
			if (get_distance_f(origin, ent_origin) <= 50.0) 
				find = true
		}
	}
	
	if (!find) return 0;
	
	return 1;
}

set_user_traps_data(id, trap_ent)
{
	new bool:find = false
	
	for (new i = 0; i < Max_Traps; i++)
	{
		if (user_traps_ent[id][i] == 0)
		{
			user_traps_ent[id][i] = trap_ent
			find = true
			break;
		}
	}
	
	if (!find) return 0;
	
	return 1;
}

reset_traps_owner(id)
{
	new classname[32], owner
	for (new i = 0; i < Max_Traps; i++)
	{
		if (user_traps_ent[id][i] > 0 && pev_valid(user_traps_ent[id][i]))
		{
			pev(user_traps_ent[id][i], pev_classname, classname, charsmax(classname))
			owner = pev(user_traps_ent[id][i], pev_iuser1)
			
			if (equal(classname, "ZOMBIE_TRAP_ENT") && owner == id)
				set_pev(user_traps_ent[id][i], pev_iuser1, 0)
		}
	}
}

remove_all_traps()
{
	new ent = -1
	while ((ent = fm_find_ent_by_class(ent, "ZOMBIE_TRAP_ENT")))
	{
		engfunc(EngFunc_RemoveEntity, ent)
	}
}

reset_vars(id)
{
	user_has_traps[id] = 0
	user_set_trap[id] = false
	set_trap_ent[id] = 0
	user_be_catched[id] = false
	catched_trap_ent[id] = 0
	
	for (new i = 0; i < Max_Traps; i++)
		user_traps_ent[id][i] = 0
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);
	
	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, RenderColor);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, float(amount));
	
	return 1;
}

stock fm_find_ent_by_class(index, const classname[])
{
	return engfunc(EngFunc_FindEntityByString, index, "classname", classname) 
}

stock PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}

stock user_screen_shake(id, amplitude = 4, duration = 2, frequency = 10)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
	write_short((1<<12)*amplitude) 
	write_short((1<<12)*duration)
	write_short((1<<12)*frequency) 
	message_end()
}

stock show_user_taskbar(id, time)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgBarTime, _, id)
	write_short(time) // time (second) [0=clear]
	message_end()
}

stock show_user_sprite(id, const sprite_index)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(TE_PLAYERATTACHMENT) // TE_PLAYERATTACHMENT (124)
	write_byte(id) // player id
	write_coord(45) // vertical offset (attachment origin.z = player origin.z + vertical offset)
	write_short(sprite_index) // sprite entity index
	write_short(32767) // life (scale in 0.1's)
	message_end()
}

stock clear_user_sprite(id)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(TE_KILLPLAYERATTACHMENTS) // TE_KILLPLAYERATTACHMENTS (125)
	write_byte(id) // player id
	message_end()
}

stock bool:fm_is_point_visible(index, const Float:point[3], ignoremonsters = 1)
{
	new Float:start[3], Float:dest[3];
	pev(index, pev_origin, start);
	pev(index, pev_view_ofs, dest);
	xs_vec_add(start, dest, start);
	
	engfunc(EngFunc_TraceLine, start, point, ignoremonsters, index, 0);
	
	new Float:fraction;
	get_tr2(0, TR_flFraction, fraction);
	if (fraction == 1.0)
		return true;
	
	get_tr2(0, TR_vecEndPos, dest);
	if ((dest[0] == point[0]) && (dest[1] == point[1]) && (dest[2] == point[2]))
		return true;
	
	return false;
}

stock create_user_sprite(id, const Float:originF[3], sprite_index, scale)
{
	message_begin(MSG_ONE, SVC_TEMPENTITY, _, id)
	write_byte(TE_SPRITE) // TE id (Additive sprite, plays 1 cycle)
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	write_short(sprite_index) // sprite index
	write_byte(scale) // scale in 0.1's
	write_byte(200) // brightness
	message_end()
}

stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && (pev(entity, pev_owner) != owner)) {}
	
	return entity;
}

stock Float:get_weapon_next_pri_attack(entity)
{
	return get_pdata_float(entity, OFFSET_flNextPrimaryAttack, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_next_pri_attack(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flNextPrimaryAttack, time, OFFSET_LINUX_WEAPONS)
}

stock Float:get_weapon_next_sec_attack(entity)
{
	return get_pdata_float(entity, OFFSET_flNextSecondaryAttack, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_next_sec_attack(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flNextSecondaryAttack, time, OFFSET_LINUX_WEAPONS)
}

stock Float:get_weapon_idle_time(entity)
{
	return get_pdata_float(entity, OFFSET_flTimeWeaponIdle, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_idle_time(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flTimeWeaponIdle, time, OFFSET_LINUX_WEAPONS)
}

#if defined SUPPORT_BOT_TO_USE
public bot_use_traps(id)
{
	//if (!is_user_alive(id))
	//	return;
	
	//if (!zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_Brutalheavy || zp_get_user_nemesis(id))
	//	return;
	
	static target, hitzone, distance
	target = get_valid_aim_target(id, hitzone, distance)
	
	if (!user_set_trap[id])
	{
		static Float:time
		time = get_gametime()
		
		if (target > 0 && (500 <= distance <= 1000) && time >= bot_next_check_time[id])
		{
			if (random_num(1, 100) > 85) 
			{
				if (do_set_trap(id)) 
					set_pev(id, pev_flags, (pev(id, pev_flags) | FL_FROZEN))
			}
			
			bot_next_check_time[id] = time + 1.0
		}
	}
	else
	{
		static Float:user_origin[3], Float:fdistance
		pev(id, pev_origin, user_origin)
		user_origin[2] = set_trap_origin[id][2]
		fdistance = get_distance_f(user_origin, set_trap_origin[id])
		
 		if ((target > 0 && distance <= 200) || fdistance > 18.0)
		{
			stop_set_trap(id)
			set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
		}
	}
}

public event_Damage(id)
{
	new attacker, weapon, hitzone
	attacker = get_user_attacker(id, weapon, hitzone)
	
	if (!(1 <= attacker <= g_maxplayers) || !is_user_connected(attacker) || !is_user_alive(attacker) 
	|| attacker == id)
		return;
	
	new damage = read_data(2)
	
	if (is_user_bot(id) && damage > 0)
	{
		new Float:origin1[3], Float:origin2[3], distance
		pev(id, pev_origin, origin1)
		pev(attacker, pev_origin, origin2)
		distance = floatround(get_distance_f(origin1, origin2))
		
		if (distance < 500 || damage > 100)
		{
			if (user_set_trap[id])
			{
				stop_set_trap(id)
				set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
			}
		}
	}
}

get_valid_aim_target(id, &hitzone, &distance)
{
	new target, aim_hitzone
	get_user_aiming(id, target, aim_hitzone)
	if (!(1 <= target <= g_maxplayers) || !is_user_alive(target) || zp_get_user_zombie(target))
		return 0;
	
	hitzone = aim_hitzone
	new Float:origin1[3], Float:origin2[3]
	pev(id, pev_origin, origin1)
	pev(target, pev_origin, origin2)
	distance = floatround(get_distance_f(origin1, origin2), floatround_round)
	
	return target;
}
#endif

public roundStart()
{
	for (new i = 1; i <= g_maxplayers; i++)
	{
		is_cooldown[i] = 0
		is_cooldown_time[i] = floatround(g_revenge_cooldown)
		remove_task(i)
	}
}

stock color_chat(const id, const input[], any:...)
{
	new count = 1, players[32];
	static msg[191];
	vformat(msg, 190, input, 3);
	
	replace_all(msg, 190, "!g", "^4");
	replace_all(msg, 190, "!y", "^1");
	replace_all(msg, 190, "!t", "^3");
	
	if (id) players[0] = id; else get_players(players, count, "ch");
	{
		for (new i = 0; i < count; i++)
		{
			if (is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}
}
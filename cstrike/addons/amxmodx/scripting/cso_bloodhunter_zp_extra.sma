#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <xs>

// Zombie Plague
#include <zombieplague>

#define PLUGIN "[CSO] DEAGLE CRIMSON HUNTER (BLOOD HUNTER)"
#define VERSION "1.0"
#define AUTHOR "AsepKhairulAnam@CS:ZPMI || -RequiemID- || Facebook.com/asepdwa11"

// CONFIGURATION WEAPON
#define system_name		"bloodhunter"
#define system_base		"fiveseven"

#define DRAW_TIME		0.5
#define RELOAD_TIME		3.5

#define CSW_BASE		CSW_FIVESEVEN
#define WEAPON_KEY 		2123131000

#define OLD_MODEL		"models/w_fiveseven.mdl"
#define ANIMEXT			"dualpistols_1"

// ALL MACRO
#define ENG_NULLENT		-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)
#define TASK_THROW_GRENADE	4292919
#define GRENADE_CLASSNAME	"bloodhunter_grenade"
#define BLOOD_CLASSNAME		"bloodhunter_effect"

// ALL ANIM
#define ANIM_IDLE		0
#define ANIM_SHOOT_EFFECT	3
#define ANIM_SHOOT		7
#define ANIM_THROW		11
#define ANIM_RELOAD		15
#define ANIM_DRAW		19

// MODE
#define MODE_NORMAL		0
#define MODE_A			1
#define MODE_B			2
#define MODE_C			3

// Extra Items Configuration
#define NAME_EXTRA_ITEMS	"Deagle Crimson Hunter"
#define TEAM_EXTRA_ITEMS	ZP_TEAM_HUMAN
#define COST_EXTRA_ITEMS	40

// All Models Of The Weapon
new V_MODEL[64] = "models/v_bloodhunter.mdl"
new P_MODEL[64] = "models/p_bloodhunter.mdl"
new W_MODEL[64] = "models/w_bloodhunter.mdl"
new W_MODEL_2[64] = "models/w_bloodhunter_grenade.mdl"

new const WeaponResources[][] =
{
	"sprites/asep/640hud7_2.spr",
	"sprites/asep/640hud145_2.spr"
}

new const WeaponSprites[][] =
{
	"sprites/asep/ef_bloodhunter1.spr",
	"sprites/asep/ef_bloodhunter2.spr",
	"sprites/asep/ef_bloodhunter3.spr"
}

// You Can Add Fire Sound Here
new const Fire_Sounds[][] = { "weapons/bloodhunter-1.wav", "weapons/bloodhunter-explode.wav", "weapons/grenade_hit1.wav" }

// All Vars Here
new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }
new cvar_dmg, cvar_recoil, cvar_clip, cvar_spd, cvar_ammo, g_item
new g_maxplayers, g_orig_event, g_primary_attack_tmp[33], Float:cl_pushangle[33][3], g_InTempingAttack[33]
new g_has_weapon[33], g_clip_ammo[33], g_weapon_TmpClip[33], oldweap[33], g_mode[33], g_hit[33], explode_effect

// Macros Again :v
new weapon_name_buffer[512]
new weapon_base_buffer[512]
		
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

// START TO CREATE PLUGINS || AMXMODX FORWARD
public plugin_init()
{
	formatex(weapon_name_buffer, sizeof(weapon_name_buffer), "weapon_%s_asep", system_name)
	formatex(weapon_base_buffer, sizeof(weapon_base_buffer), "weapon_%s", system_base)
	
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Event And Message
	register_event("CurWeapon", "Event_CurrentWeapon", "be", "1=1")
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
	
	// Ham Forward (Entity) || Ham_Use
	RegisterHam(Ham_Use, "func_tank", "Forward_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "Forward_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "Forward_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "Forward_UseStationary_Post", 1)
	
	// Ham Forward (Entity) || Ham_TraceAttack
	RegisterHam(Ham_TraceAttack, "player", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "worldspawn", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "Forward_TraceAttack", 1)
	
	// Ham Forward (Weapon)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_base_buffer, "Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_base_buffer, "Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_base_buffer, "Weapon_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, weapon_base_buffer, "Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_base_buffer, "Weapon_Reload_Post", 1)
	RegisterHam(Ham_Item_AddToPlayer, weapon_base_buffer, "Weapon_AddToPlayer")
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_base_buffer, "Weapon_Idle")
	
	// Ham Forward (Player)
	RegisterHam(Ham_TakeDamage, "player", "Forward_TakeDamage")
	
	for(new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if(WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "Weapon_Deploy_Post", 1)
	
	// Fakemeta Forward
	register_forward(FM_SetModel, "Forward_SetModel")
	register_forward(FM_PlaybackEvent, "Forward_PlaybackEvent")
	register_forward(FM_UpdateClientData, "Forward_UpdateClientData_Post", 1)
	register_forward(FM_EmitSound, "Forward_EmitSound")
	
	// Engine Forward
	register_touch(GRENADE_CLASSNAME, "*", "Forward_GrenadeTouch")
	register_think(GRENADE_CLASSNAME, "Forward_GrenadeThink")
	register_think(BLOOD_CLASSNAME, "Forward_BloodEffectThink")
	
	// All Some Cvar
	cvar_clip = register_cvar("bloodhunter_clip", "30")
	cvar_spd = register_cvar("bloodhunter_speed", "2.5")
	cvar_ammo = register_cvar("bloodhunter_ammo", "120")
	cvar_dmg = register_cvar("bloodhunter_damage", "3.0")
	cvar_recoil = register_cvar("bloodhunter_recoil", "0.9")
	
	g_maxplayers = get_maxplayers()
	g_item = zp_register_extra_item("[Пистолет] \ybloodhun", 45, ZP_TEAM_HUMAN)
}

public plugin_precache()
{
	formatex(weapon_name_buffer, sizeof(weapon_name_buffer), "weapon_%s_asep", system_name)
	formatex(weapon_base_buffer, sizeof(weapon_base_buffer), "weapon_%s", system_base)
	
	precache_model(V_MODEL)
	precache_model(P_MODEL)
	precache_model(W_MODEL)
	precache_model(W_MODEL_2)
	
	new Buffer[512]
	formatex(Buffer, sizeof(Buffer), "sprites/%s.txt", weapon_name_buffer)
	precache_generic(Buffer) // EG: Output "sprites/weapon_buffm4_asep.txt"
	
	for(new i = 0; i < sizeof(Fire_Sounds); i++)
		precache_sound(Fire_Sounds[i])
	for(new i = 0; i < sizeof(WeaponResources); i++)
		precache_model(WeaponResources[i])
	for(new i = 0; i < sizeof(WeaponSprites); i++)
	{
		if(i == 2) explode_effect = precache_model(WeaponSprites[i])
		else precache_model(WeaponSprites[i])
	}
	
	precache_viewmodel_sound(V_MODEL)
	formatex(Buffer, sizeof(Buffer), "get_%s", system_name)
	register_clcmd(Buffer, "give_item")
	register_clcmd(weapon_name_buffer, "weapon_hook")
	register_forward(FM_PrecacheEvent, "Forward_PrecacheEvent_Post", 1)
}

public plugin_natives()
{
	new Buffer[512]
	formatex(Buffer, sizeof(Buffer), "get_%s", system_name)
	register_native(Buffer, "give_item", 1) // EG: Output "give_buffm4"
	formatex(Buffer, sizeof(Buffer), "remove_%s", system_name)
	register_native(Buffer, "remove_item", 1) // EG: Output "remove_buffm4"
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid != g_item)
		return

	give_item(id)
}

public client_connect(id) remove_item(id)
public client_disconnect(id) remove_item(id)
public zp_user_infected_post(id) remove_item(id)
public zp_user_humanized_post(id) remove_item(id)
/* ========= START OF REGISTER HAM TO SUPPORT BOTS FUNC ========= */
new g_HamBot
public client_putinserver(id)
{
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Do_RegisterHam", id)
	}
}

public Do_RegisterHam(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "Forward_TraceAttack", 1)
	RegisterHamFromEntity(Ham_TakeDamage, id, "Forward_TakeDamage")
}

public Forward_PrecacheEvent_Post(type, const name[])
{
	new Buffer[512]
	formatex(Buffer, sizeof(Buffer), "events/%s.sc", system_base)
	if(equal(Buffer, name, 0))
	{
		g_orig_event = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public Forward_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED
	
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
		
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, OLD_MODEL))
	{
		static iStoredAugID
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, weapon_base_buffer, entity)
			
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED

		if(g_has_weapon[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, WEAPON_KEY)
			g_has_weapon[iOwner] = 0
			entity_set_model(entity, W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public Forward_UseStationary_Post(entity, caller, activator, use_type)
{
	if(!use_type && is_user_connected(caller))
		replace_weapon_models(caller, get_user_weapon(caller))
}

public Forward_UpdateClientData_Post(id, SendWeapons, CD_Handle)
{
	if(!is_user_alive(id) || (get_user_weapon(id) != CSW_BASE || !g_has_weapon[id]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public Forward_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if((eventid != g_orig_event) || !g_primary_attack_tmp[invoker])
		return FMRES_IGNORED
	if(!(1 <= invoker <= g_maxplayers))
		return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public Forward_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_user_connected(id))
		return FMRES_IGNORED
	if(!g_InTempingAttack[id])
		return FMRES_IGNORED
		
	if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
	{
		if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
			return FMRES_SUPERCEDE
		if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't')
		{
			if (sample[17] == 'w')  return FMRES_SUPERCEDE
			else  return FMRES_SUPERCEDE
		}
		if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
			return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED
}

/* ================= END OF ALL FAKEMETA FORWARD ================= */
/* ================= START OF ALL ENGINE FORWARD ================ */
public Forward_GrenadeThink(grenade)
{
	if(!pev_valid(grenade))
		return
		
	new Float:Angles[3]
	Angles[0] = random_float(0.0, 360.0)
	Angles[1] = random_float(0.0, 360.0)
	Angles[2] = random_float(0.0, 360.0)
	set_pev(grenade, pev_angles, Angles)
	set_pev(grenade, pev_nextthink, get_gametime() + 0.01)
}

public Forward_BloodEffectThink(blood)
{
	if(!pev_valid(blood))
		return
		
	new owner = pev(blood, pev_owner)
	if(get_user_weapon(owner) != CSW_BASE)
	{
		remove_entity(blood)
		return
	}
	
	new Float:fFrame
	pev(blood, pev_frame, fFrame)
	
	new Float:BloodOrigin[3]
	get_position(pev(blood, pev_owner), 15.0, 0.0, 0.0, BloodOrigin)
	set_pev(blood, pev_origin, BloodOrigin)
	
	fFrame += 0.5
	if(fFrame >= 44.0)
	{
		remove_entity(blood)
		return
	}
	
	set_pev(blood, pev_frame, fFrame)
	set_pev(blood, pev_nextthink, get_gametime() + 0.01)
}

public Forward_GrenadeTouch(grenade, touched)
{
	if(!pev_valid(grenade))
		return
	
	static Float:VelocityGrenade[3]
	pev(grenade, pev_velocity, VelocityGrenade)
	
	new Float:origin[3]
	pev(grenade, pev_origin, origin)
		
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2] + 20.0)
	write_short(explode_effect)
	write_byte(50 * pev(grenade, pev_iuser3))
	write_byte(150)
	message_end()
		
	emit_sound(grenade, CHAN_WEAPON, Fire_Sounds[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	for(new i = 0; i < g_maxplayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(entity_range(i, grenade) > 120.0)
			continue
		if(get_user_team(i) == pev(grenade, pev_iuser1))
			continue
		
		ExecuteHamB(Ham_TakeDamage, i, 0, pev(grenade, pev_owner), random_float(40.0, 50.0) * (float(pev(grenade, pev_iuser3))*0.5), DMG_GENERIC)
		
		new Float:Velocity[3]
		Velocity[0] = random_float(-750.0, 750.0)
		Velocity[1] = random_float(-750.0, 750.0)
		Velocity[2] = 400.0 * float(pev(grenade, pev_iuser3))
		set_pev(i, pev_velocity, Velocity)
	}
		
	remove_entity(grenade)
}
/* ================== END OF ALL ENGINE FORWARD ================ */
/* ================= START OF ALL MESSAGE FORWARD ================ */
public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
	
	if(equal(szTruncatedWeapon, system_base) && get_user_weapon(iAttacker) == CSW_BASE)
	{
		if(g_has_weapon[iAttacker])
			set_msg_arg_string(4, system_name)
	}
	return PLUGIN_CONTINUE
}
/* ================== END OF ALL MESSAGE FORWARD ================ */
/* ================== START OF ALL EVENT FORWARD ================ */
public Event_NewRound()
{
	remove_entity_name(GRENADE_CLASSNAME)
}

public Event_CurrentWeapon(id)
{
	replace_weapon_models(id, read_data(2))
     
	if(!is_user_alive(id))
		return
	if(read_data(2) != CSW_BASE || !g_has_weapon[id])
		return
	
	static weapon[32], weapon_entity
	get_weaponname(read_data(2), weapon, 31)
	weapon_entity = find_ent_by_owner(-1, weapon, id)
	if(pev_valid(weapon_entity))
	{
		static Float:Delay
		Delay = get_pdata_float(weapon_entity, 46, 4) * get_pcvar_float(cvar_spd)
		if(Delay > 0.0) set_pdata_float(weapon_entity, 46, Delay, 4)
	}
}

/* ================== END OF ALL EVENT FORWARD =================== */
/* ================== START OF ALL HAM FORWARD =================== */
public Forward_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_BASE)
		{
			if(g_has_weapon[attacker])
			{
				if(damagebits & DMG_BULLET)
				{
					SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg))
				}
			}
		}
	}
}

public Forward_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker) || !is_user_connected(iAttacker))
		return
	if(get_user_weapon(iAttacker) != CSW_BASE || !g_has_weapon[iAttacker])
		return

	static Float:flEnd[3], Float:WallVector[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	get_tr2(ptr, TR_vecPlaneNormal, WallVector)
	
	if(iEnt)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		write_short(iEnt)
		message_end()
	}
	else
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		message_end()
	}
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_STREAK_SPLASH)
	engfunc(EngFunc_WriteCoord, flEnd[0])
	engfunc(EngFunc_WriteCoord, flEnd[1])
	engfunc(EngFunc_WriteCoord, flEnd[2])
	engfunc(EngFunc_WriteCoord, WallVector[0] * random_float(25.0,30.0))
	engfunc(EngFunc_WriteCoord, WallVector[1] * random_float(25.0,30.0))
	engfunc(EngFunc_WriteCoord, WallVector[2] * random_float(25.0,30.0))
	write_byte(1)
	write_short(20)
	write_short(3)
	write_short(90)	
	message_end()
	
	if(is_user_connected(iEnt) && is_user_alive(iEnt)
	&& get_user_team(iEnt) != get_user_team(iAttacker) && g_mode[iAttacker] < MODE_C)
	{	
		if(g_hit[iAttacker] >= 2)
		{
			set_weapons_timeidle(iAttacker, CSW_BASE, 1.5)
			
			g_mode[iAttacker] ++
			g_hit[iAttacker] = 0
			set_weapon_anim(iAttacker, ANIM_SHOOT_EFFECT + g_mode[iAttacker])
			
			new blood = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
			if(pev_valid(blood))
			{
				new Float:BloodOrigin[3]
				get_position(iAttacker, 15.0, 0.0, -5.0, BloodOrigin)
				set_pev(blood, pev_classname, BLOOD_CLASSNAME)
				engfunc(EngFunc_SetModel, blood, WeaponSprites[random_num(0,1)])
				set_pev(blood, pev_origin, BloodOrigin)
				set_pev(blood, pev_movetype, MOVETYPE_FLY)
				set_pev(blood, pev_rendermode, kRenderTransAdd)
				set_pev(blood, pev_renderamt, 255.0)
				set_pev(blood, pev_owner, iAttacker)
				set_pev(blood, pev_frame, 0.0)
				set_pev(blood, pev_skin, 1)
				set_pev(blood, pev_scale, 0.075)
				set_pev(blood, pev_nextthink, get_gametime() + 0.01)
				dllfunc(DLLFunc_Spawn, blood)
			}
		}
		else
		{
			g_hit[iAttacker] ++
			set_weapon_anim(iAttacker, ANIM_SHOOT + g_mode[iAttacker])
		}
	}
	else set_weapon_anim(iAttacker, ANIM_SHOOT + g_mode[iAttacker])
}

public Weapon_Idle(weapon_entity)
{
	if(get_pdata_float(weapon_entity, 48, 4) > 0.0)
		return HAM_IGNORED
		
	new id = get_pdata_cbase(weapon_entity, 41, 4)
	
	if(!is_user_alive(id))
		return HAM_IGNORED
		
	set_pdata_float(weapon_entity, 48, 2.0, 4)
	set_weapon_anim(id, g_mode[id])
	
	return HAM_IGNORED
}

public Weapon_Deploy_Post(weapon_entity)
{
	static owner
	owner = fm_cs_get_weapon_ent_owner(weapon_entity)
	
	static weaponid
	weaponid = cs_get_weapon_id(weapon_entity)
	
	replace_weapon_models(owner, weaponid)
}

public Weapon_AddToPlayer(weapon_entity, id)
{
	if(!is_valid_ent(weapon_entity) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(weapon_entity, EV_INT_WEAPONKEY) == WEAPON_KEY)
	{
		g_has_weapon[id] = true
		entity_set_int(weapon_entity, EV_INT_WEAPONKEY, 0)
		set_weapon_list(id, true)
		return HAM_HANDLED
	}
	else
	{
		set_weapon_list(id, false)
	}
	
	return HAM_IGNORED
}

public Weapon_PrimaryAttack(weapon_entity)
{
	new id = get_pdata_cbase(weapon_entity, 41, 4)
	
	if(!g_has_weapon[id])
		return
	
	g_primary_attack_tmp[id] = 1
	pev(id, pev_punchangle, cl_pushangle[id])
	
	g_clip_ammo[id] = cs_get_weapon_ammo(weapon_entity)
}

public Weapon_PrimaryAttack_Post(weapon_entity)
{
	new id = get_pdata_cbase(weapon_entity, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(id, szClip, szAmmo)
	
	if(!is_user_alive(id))
		return
	if(g_clip_ammo[id] <= cs_get_weapon_ammo(weapon_entity))
		return
		
	if(g_has_weapon[id])
	{
		g_primary_attack_tmp[id] = 0
		
		if(!g_clip_ammo[id])
		{
			ExecuteHam(Ham_Weapon_PlayEmptySound, weapon_entity)
			return
		}

		new Float:push[3]
		pev(id, pev_punchangle, push)
		xs_vec_sub(push, cl_pushangle[id], push)
		xs_vec_mul_scalar(push, get_pcvar_float(cvar_recoil), push)
		xs_vec_add(push, cl_pushangle[id], push)
		set_pev(id, pev_punchangle, push)
		emit_sound(id, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
}

public Weapon_ItemPostFrame(weapon_entity) 
{
	if(!pev_valid(weapon_entity))
		return HAM_IGNORED
	new id = pev(weapon_entity, pev_owner)
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!g_has_weapon[id])
		return HAM_IGNORED

	static iClipExtra
	iClipExtra = get_pcvar_num(cvar_clip)
	new Float:flNextAttack = get_pdata_float(id, 83, 5)

	new iBpAmmo = cs_get_user_bpammo(id, CSW_BASE)
	new iClip = get_pdata_int(weapon_entity, 51, 4)

	new fInReload = get_pdata_int(weapon_entity, 54, 4) 
	if(fInReload && flNextAttack <= 0.0)
	{
		new j = min(iClipExtra - iClip, iBpAmmo)
	
		set_pdata_int(weapon_entity, 51, iClip + j, 4)
		cs_set_user_bpammo(id, CSW_BASE, iBpAmmo-j)
		
		set_pdata_int(weapon_entity, 54, 0, 4)
		fInReload = 0
	}
	else if(!fInReload)
	{
		if(flNextAttack <= 0.0 && g_mode[id])
		{
			if(pev(id, pev_button) & IN_ATTACK2)
				throw_grenade(id)
		}
	}
	
	return HAM_IGNORED
}

public Weapon_Reload(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!g_has_weapon[id])
		return HAM_IGNORED

	static iClipExtra
	if(g_has_weapon[id])
		iClipExtra = get_pcvar_num(cvar_clip)

	g_weapon_TmpClip[id] = -1

	new iBpAmmo = cs_get_user_bpammo(id, CSW_BASE)
	new iClip = get_pdata_int(weapon_entity, 51, 4)

	if(iBpAmmo <= 0)
		return HAM_SUPERCEDE

	if(iClip >= iClipExtra)
		return HAM_SUPERCEDE

	g_weapon_TmpClip[id] = iClip

	return HAM_IGNORED
}

public Weapon_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!g_has_weapon[id])
		return HAM_IGNORED
	if(g_weapon_TmpClip[id] == -1)
		return HAM_IGNORED
	
	set_pdata_int(weapon_entity, 51, g_weapon_TmpClip[id], 4)
	set_pdata_float(weapon_entity, 48, RELOAD_TIME, 4)
	set_pdata_float(id, 83, RELOAD_TIME, 5)
	set_pdata_int(weapon_entity, 54, 1, 4)
	
	set_weapon_anim(id, ANIM_RELOAD + g_mode[id])
	set_pdata_string(id, (492) * 4, ANIMEXT, -1 , 20)
	
	return HAM_IGNORED
}

/* ===================== END OF ALL HAM FORWARD ====================== */
/* ================= START OF OTHER PUBLIC FUNCTION  ================= */
public give_item(id)
{
	drop_weapons(id, 2)
	new iWeapon = fm_give_item(id, weapon_base_buffer)
	if(iWeapon > 0)
	{
		cs_set_weapon_ammo(iWeapon, get_pcvar_num(cvar_clip))
		cs_set_user_bpammo(id, CSW_BASE, get_pcvar_num(cvar_ammo))
		emit_sound(id, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		
		set_weapon_anim(id, ANIM_DRAW)
		set_pdata_float(id, 83, DRAW_TIME, 5)
		
		set_weapon_list(id, true)
		set_pdata_string(id, (492) * 4, ANIMEXT, -1 , 20)
		set_pdata_int(iWeapon, 74, MODE_A)
	}
	
	g_has_weapon[id] = true
	g_mode[id] = MODE_NORMAL
	g_hit[id] = 0
}

public remove_item(id)
{
	g_has_weapon[id] = false
	g_mode[id] = MODE_NORMAL
	g_hit[id] = 0
}

public weapon_hook(id)
{
	engclient_cmd(id, weapon_base_buffer)
	return PLUGIN_HANDLED
}

public replace_weapon_models(id, weaponid)
{	
	switch(weaponid)
	{
		case CSW_BASE:
		{
			if(g_has_weapon[id])
			{
				set_pev(id, pev_viewmodel2, V_MODEL)
				set_pev(id, pev_weaponmodel2, P_MODEL)
				
				if(oldweap[id] != CSW_BASE) 
				{
					set_weapon_anim(id, ANIM_DRAW + g_mode[id])
					set_player_nextattackx(id, DRAW_TIME)
					set_weapons_timeidle(id, CSW_BASE, DRAW_TIME)
					set_weapon_list(id, true)
					set_pdata_string(id, (492) * 4, ANIMEXT, -1 , 20)
				}
			}
		}
	}
	
	oldweap[id] = weaponid
}

public throw_grenade(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return
	if(!g_has_weapon[id] || !g_mode[id] || get_user_weapon(id) != CSW_BASE)
		return
		
	create_fakeattack(id)
	set_weapon_anim(id, ANIM_THROW + g_mode[id])
	set_player_nextattackx(id, 0.83)
	set_weapons_timeidle(id, CSW_BASE, 0.83)
	set_task(0.3, "do_throw_grenade", id+TASK_THROW_GRENADE)
}

public do_throw_grenade(id)
{
	id -= TASK_THROW_GRENADE
	
	if(!is_user_alive(id) || !is_user_connected(id))
		return
	if(!g_has_weapon[id] || !g_mode[id] || get_user_weapon(id) != CSW_BASE)
		return

	new grenade = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(grenade))
		return
	
	static Float:grenade_origin[3], Float:angles[3]
	get_position(id, 10.0, 0.0, 10.0, grenade_origin)
	pev(id, pev_angles, angles)
	
	set_pev(grenade, pev_movetype, MOVETYPE_BOUNCE)
	set_pev(grenade, pev_solid, SOLID_BBOX)
	set_pev(grenade, pev_classname, GRENADE_CLASSNAME)
	engfunc(EngFunc_SetModel, grenade, W_MODEL_2)
	set_pev(grenade, pev_origin, grenade_origin)
	set_pev(grenade, pev_angles, angles)
	set_pev(grenade, pev_owner, id)
	set_pev(grenade, pev_iuser1, get_user_team(id))
	set_pev(grenade, pev_iuser2, 0)
	set_pev(grenade, pev_iuser3, g_mode[id])
	set_pev(grenade, pev_gravity, 0.8)
	set_pev(grenade, pev_animtime, get_gametime())
	set_pev(grenade, pev_framerate, 1.0)
	set_pev(grenade, pev_nextthink, get_gametime() + 0.1)
	
	static Float:velocity[3], Float:target_origin[3]
	fm_get_aim_origin(id, target_origin)
	get_speed_vector(grenade_origin, target_origin, 800.0, velocity)
	velocity[2] += 150.0
	
	set_pev(grenade, pev_velocity, velocity)
	g_mode[id] = MODE_NORMAL
	
	set_task(0.53, "re_draw", id)
}

public re_draw(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return
	if(!g_has_weapon[id] || get_user_weapon(id) != CSW_BASE)
		return
	
	set_weapon_anim(id, ANIM_DRAW)
}

public create_fakeattack(id)
{
	static Ent
	Ent = fm_get_user_weapon_entity(id, CSW_KNIFE)
	
	if(!pev_valid(Ent))
		return
	
	g_InTempingAttack[id] = 1
	ExecuteHamB(Ham_Weapon_PrimaryAttack, Ent)
	
	static iAnimDesired,  szAnimation[64]

	formatex(szAnimation, charsmax(szAnimation), (pev(id, pev_flags) & FL_DUCKING) ? "crouch_shoot_grenade" : "ref_shoot_grenade")
	if((iAnimDesired = lookup_sequence(id, szAnimation)) == -1)
		iAnimDesired = 0
	
	set_pev(id, pev_sequence, iAnimDesired)
	g_InTempingAttack[id] = 0
}

/* ============= END OF OTHER PUBLIC FUNCTION (Weapon) ============= */
/* ================= START OF ALL STOCK TO MACROS ================== */
stock set_weapon_list(id, bool:set)
{
	if(!is_user_connected(id))
		return
	
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id)
	write_string(!set ? weapon_base_buffer : weapon_name_buffer)
	write_byte(7)
	write_byte(70)
	write_byte(-1)
	write_byte(-1)
	write_byte(1)
	write_byte(6)
	write_byte(CSW_BASE)
	write_byte(0)
	message_end()
}

stock drop_weapons(id, dropwhat)
{
	static weapons[32], num = 0, i, weaponid
	get_user_weapons(id, weapons, num)
     
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
          
		if(dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM))
		{
			static wname[32]
			get_weaponname(weaponid, wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock set_player_nextattackx(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, 83, nexttime, 5)
}

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, 4)
	set_pdata_float(entwpn, 47, TimeIdle, 4)
	set_pdata_float(entwpn, 48, TimeIdle + 1.0, 4)
}

stock set_weapons_timeidlex(id, Float:TimeIdle, Float:Idle)
{
	new entwpn = fm_get_user_weapon_entity(id, CSW_BASE)
	if(!pev_valid(entwpn)) 
		return
	
	set_pdata_float(entwpn, 46, TimeIdle, 4)
	set_pdata_float(entwpn, 47, TimeIdle, 4)
	set_pdata_float(entwpn, 48, Idle, 4)
}

stock set_weapon_anim(const id, const Sequence)
{
	set_pev(id, pev_weaponanim, Sequence)
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = id)
	write_byte(Sequence)
	write_byte(pev(id, pev_body))
	message_end()
}

stock precache_viewmodel_sound(const model[]) // I Get This From BTE
{
	new file, i, k
	if((file = fopen(model, "rt")))
	{
		new szsoundpath[64], NumSeq, SeqID, Event, NumEvents, EventID
		fseek(file, 164, SEEK_SET)
		fread(file, NumSeq, BLOCK_INT)
		fread(file, SeqID, BLOCK_INT)
		
		for(i = 0; i < NumSeq; i++)
		{
			fseek(file, SeqID + 48 + 176 * i, SEEK_SET)
			fread(file, NumEvents, BLOCK_INT)
			fread(file, EventID, BLOCK_INT)
			fseek(file, EventID + 176 * i, SEEK_SET)
			
			// The Output Is All Sound To Precache In ViewModels (GREAT :V)
			for(k = 0; k < NumEvents; k++)
			{
				fseek(file, EventID + 4 + 76 * k, SEEK_SET)
				fread(file, Event, BLOCK_INT)
				fseek(file, 4, SEEK_CUR)
				
				if(Event != 5004)
					continue
				
				fread_blocks(file, szsoundpath, 64, BLOCK_CHAR)
				
				if(strlen(szsoundpath))
				{
					strtolower(szsoundpath)
					engfunc(EngFunc_PrecacheSound, szsoundpath)
				}
			}
		}
	}
	fclose(file)
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, 41, 4)
}

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp)
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward)
	angle_vector(vAngle, ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle, ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock is_wall_between_points(Float:start[3], Float:end[3], ignore_ent)
{
	static ptr
	ptr = create_tr2()

	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ignore_ent, ptr)
	
	static Float:EndPos[3]
	get_tr2(ptr, TR_vecEndPos, EndPos)

	free_tr2(ptr)
	return floatround(get_distance_f(end, EndPos))
} 

stock get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	static Float:vfEnd[3], viEnd[3] 
	get_user_origin(id, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	static Float:fOrigin[3], Float:fAngle[3]
	
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	static Float:fAttack[3]
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	static Float:fRate
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	xs_vec_add(fOrigin, fAttack, output)
}

stock get_angle_to_target(id, const Float:fTarget[3], Float:TargetSize = 0.0)
{
	static Float:fOrigin[3], iAimOrigin[3], Float:fAimOrigin[3], Float:fV1[3]
	pev(id, pev_origin, fOrigin)
	get_user_origin(id, iAimOrigin, 3) // end position from eyes
	IVecFVec(iAimOrigin, fAimOrigin)
	xs_vec_sub(fAimOrigin, fOrigin, fV1)
	
	static Float:fV2[3]
	xs_vec_sub(fTarget, fOrigin, fV2)
	
	static iResult; iResult = get_angle_between_vectors(fV1, fV2)
	if(TargetSize > 0.0)
	{
		static Float:fTan; fTan = TargetSize / get_distance_f(fOrigin, fTarget)
		static fAngleToTargetSize; fAngleToTargetSize = floatround(floatatan(fTan, degrees))
		iResult -= (iResult > 0) ? fAngleToTargetSize : -fAngleToTargetSize
	}
	
	return iResult
}

stock get_angle_between_vectors(const Float:fV1[3], const Float:fV2[3])
{
	static Float:fA1[3], Float:fA2[3]
	engfunc(EngFunc_VecToAngles, fV1, fA1)
	engfunc(EngFunc_VecToAngles, fV2, fA2)
	
	static iResult; iResult = floatround(fA1[1] - fA2[1])
	iResult = iResult % 360
	iResult = (iResult > 180) ? (iResult - 360) : iResult
	
	return iResult
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num; num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}

/* ================= END OF ALL STOCK AND PLUGINS CREATED ================== */

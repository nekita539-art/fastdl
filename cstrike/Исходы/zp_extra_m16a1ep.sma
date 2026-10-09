#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>

#define ENG_NULLENT			-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define m16a1_WEAPONKEY 		4309
#define MAX_PLAYERS  		32

const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4

#define WEAP_LINUX_XTRA_OFF		4
#define m_fKnown					44
#define m_flNextPrimaryAttack 		46
#define m_flTimeWeaponIdle			48
#define m_iClip					51
#define m_fInReload				54
#define PLAYER_LINUX_XTRA_OFF	5
#define m_flNextAttack				83

#define m16a1_RELOAD_TIME 	3.1
#define m16a1_SHOOT1		1
#define m16a1_SHOOT2		2
#define m16a1_RELOAD		5
#define m16a1_DRAW		6

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

new const Fire_Sounds[][] = { "texas1k_extra/m16a1-1.wav", "texas1k_extra/m16a1-2.wav" }

new m16a1_V_MODEL[64] = "models/texas1k_extra/v_m16a1ep.mdl"
new m16a1_P_MODEL[64] = "models/texas1k_extra/p_m16a1ep.mdl"
new m16a1_W_MODEL[64] = "models/texas1k_extra/w_m16a1ep.mdl"
new m16a1_SHELL_MODEL[64] = "models/rshell.mdl"

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new g_itemid_m16a1, cvar_clip_m16a1, cvar_m16a1_ammo, cvar_shellshealth_m16a1, shells_model
new g_MaxPlayers, g_orig_event_m16a1, g_IsInPrimaryAttack
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_has_m16a1[33], g_clip_ammo[33], g_m16a1_TmpClip[33], oldweap[33], g_isconnected[33], g_isalive[33], g_mode[33]
new gmsgWeaponList

new Float:cvar_dmg_m16a1 = 1.3
new Float:cvar_dmg_m16a1_2 = 1.5
new Float:cvar_recoil_m16a1 = 1.0
new Float:cvar_spd_m16a1_2 = 0.002
new Float:cvar_spd_m16a1 = 1.0

#define is_user_valid_connected(%1) (1 <= %1 <= g_MaxPlayers && g_isconnected[%1])

const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

public plugin_init()
{
	register_plugin("[ZP] Extra: M16A1", "1.0", "Crock / =) (Poprogun4ik) / PbI)I(Uu'")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_galil", "fw_m16a1_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
	if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil", "fw_m16a1_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil", "fw_m16a1_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_galil", "m16a1_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, "weapon_galil", "m16a1_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_galil", "m16a1_Reload_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)

	cvar_clip_m16a1 = register_cvar("zp_m16a1_clip", "31")
	cvar_m16a1_ammo = register_cvar("zp_m16a1_ammo", "90")
	cvar_shellshealth_m16a1 = register_cvar("zp_m16a1_shellslife", "2")
	
	g_itemid_m16a1 = zp_register_extra_item("\r[А] \wM16A1 EP", 99, ZP_TEAM_HUMAN)
	g_MaxPlayers = get_maxplayers()
	gmsgWeaponList = get_user_msgid("WeaponList")
}

public plugin_precache()
{
	precache_model(m16a1_V_MODEL)
	precache_model(m16a1_P_MODEL)
	precache_model(m16a1_W_MODEL)
	shells_model = precache_model(m16a1_SHELL_MODEL)
	for(new i = 0; i < sizeof Fire_Sounds; i++)
	precache_sound(Fire_Sounds[i])
	precache_sound("texas1k_extra/m16a1_deploy.wav")
	precache_sound("texas1k_extra/m16a1_clipout.wav")
	precache_sound("texas1k_extra/m16a1_clipin.wav")
	precache_sound("texas1k_extra/m16a1_boltpull.wav")
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	precache_generic("sprites/weapon_m16a1.txt")
   	precache_generic("sprites/640hud79.spr")
    	precache_generic("sprites/640hud7.spr")
	
        register_clcmd("weapon_m16a1", "weapon_hook")	

	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

public weapon_hook(id)
{
    	engclient_cmd(id, "weapon_galil")
    	return PLUGIN_HANDLED
}

public fw_PlayerSpawn_Post(id)
{
	if(is_user_alive(id))
		g_isalive[id] = true
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!g_isalive[id] || !g_has_m16a1[id] || get_user_weapon(id) != CSW_GALIL) 
		return PLUGIN_HANDLED

	static button; button = get_uc(uc_handle, UC_Buttons)
	static oldbutton; oldbutton = pev(id, pev_oldbuttons)

	if((button & IN_ATTACK2) && !(oldbutton & IN_ATTACK2))
	{
		switch(g_mode[id])
		{
			case 0: g_mode[id] = 1
			case 1: g_mode[id] = 0
		}
		mode_message(id)
	}
	return PLUGIN_HANDLED
}

public mode_message(id)
{
	switch(g_mode[id])
	{
		case 0: client_print(id, print_center, "Switch to Auto-Mode")
		case 1: client_print(id, print_center, "Switch to Normal-Mode")
	}
}

public fw_PlayerKilled(victim, attacker, shouldgib) g_isalive[victim] = false

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_valid_connected(iAttacker))
		return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_GALIL) return
	
	if(!g_has_m16a1[iAttacker]) return

	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	
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
	write_byte(TE_GUNSHOTDECAL)
	write_coord_f(flEnd[0])
	write_coord_f(flEnd[1])
	write_coord_f(flEnd[2])
	write_short(iAttacker)
	write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
	message_end()
}

public zp_user_humanized_post(id) g_has_m16a1[id] = false

public plugin_natives ()
{
	register_native("give_weapon_m16a1", "native_give_weapon_add", 1)
}
public native_give_weapon_add(id)
{
	give_m16a1(id)
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/galil.sc", name))
	{
		g_orig_event_m16a1 = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_putinserver(id) g_isconnected[id] = true

public client_disconnect(id)
{
	g_has_m16a1[id] = false
	g_isconnected[id] = false
	g_isalive[id] = false
	g_mode[id] = 0
}

public zp_user_infected_post(id) g_has_m16a1[id] = false

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED
	
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
		
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, "models/w_galil.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_galil", entity)
	
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED
	
		if(g_has_m16a1[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, m16a1_WEAPONKEY)
			
			g_has_m16a1[iOwner] = false
			
			entity_set_model(entity, m16a1_W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_m16a1(id)
{
	drop_weapons(id, 1)
	new iWep2 = fm_give_item(id,"weapon_galil")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_m16a1))
		cs_set_user_bpammo (id, CSW_GALIL, get_pcvar_num(cvar_m16a1_ammo))		
		UTIL_PlayWeaponAnimation(id, m16a1_DRAW)
		set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)

		message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
		write_string("weapon_m16a1")
		write_byte(4)
		write_byte(90)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(17)
		write_byte(CSW_GALIL)
		message_end()
	}
	g_has_m16a1[id] = true
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid != g_itemid_m16a1)
		return

	give_m16a1(id)
	g_mode[id] = 0
}

public fw_m16a1_AddToPlayer(m16a1, id)
{
	if(!is_valid_ent(m16a1) || !g_isconnected[id])
		return HAM_IGNORED
	
	if(entity_get_int(m16a1, EV_INT_WEAPONKEY) == m16a1_WEAPONKEY)
	{
		g_has_m16a1[id] = true
		g_mode[id] = 0
		
		entity_set_int(m16a1, EV_INT_WEAPONKEY, 0)

		message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
		write_string("weapon_m16a1")
		write_byte(4)
		write_byte(90)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(17)
		write_byte(CSW_GALIL)
		message_end()
		
		return HAM_HANDLED
	}
	else
	{
		message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
		write_string("weapon_galil")
		write_byte(4)
		write_byte(90)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(17)
		write_byte(CSW_GALIL)
		message_end()
	}
	return HAM_IGNORED
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{
	if (use_type == USE_STOPPED && is_user_valid_connected(caller))
		replace_weapon_models(caller, get_user_weapon(caller))
}

public fw_Item_Deploy_Post(weapon_ent)
{
	static owner
	owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	
	replace_weapon_models(owner, weaponid)
}

public CurrentWeapon(id)
{
	replace_weapon_models(id, read_data(2))

	if(read_data(2) != CSW_GALIL || !g_has_m16a1[id])
		return
     
	static Float:iSpeed

	switch(g_mode[id])
	{
		case 0: iSpeed = cvar_spd_m16a1
		case 1: iSpeed = cvar_spd_m16a1_2
	}
     
	static weapon[32],Ent
	get_weaponname(read_data(2),weapon,31)
	Ent = find_ent_by_owner(-1,weapon,id)
	if(Ent)
	{
		static Float:Delay
		Delay = get_pdata_float( Ent, 46, 4) * iSpeed
		if (Delay > 0.0)
		{
			set_pdata_float(Ent, 46, Delay, 4)
		}
	}
}

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_GALIL:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return
			
			if(g_has_m16a1[id])
			{
				set_pev(id, pev_viewmodel2, m16a1_V_MODEL)
				set_pev(id, pev_weaponmodel2, m16a1_P_MODEL)
				if(oldweap[id] != CSW_GALIL) 
				{
					UTIL_PlayWeaponAnimation(id, m16a1_DRAW)
					set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)

					message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
					write_string("weapon_m16a1")
					write_byte(4)
					write_byte(90)
					write_byte(-1)
					write_byte(-1)
					write_byte(0)
					write_byte(17)
					write_byte(CSW_GALIL)
					message_end()
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!g_isalive[Player] || (get_user_weapon(Player) != CSW_GALIL || !g_has_m16a1[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_m16a1_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_m16a1[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_m16a1) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_m16a1_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!g_isalive[Player])
		return

	if(g_has_m16a1[Player])
	{
		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		xs_vec_mul_scalar(push,cvar_recoil_m16a1,push)

		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)

		if(g_mode[Player] == 1)
		{
			switch(szClip)
			{
				case 31: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 30: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 29: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 28: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 27: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 26: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 25: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 24: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 23: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 22: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 21: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 20: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 19: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 18: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 17: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 16: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 15: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 14: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 13: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 12: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 11: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 10: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 9: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 8: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 7: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 6: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 5: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 4: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 3: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 2: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
				case 1: set_pdata_float(Player, m_flNextAttack, 0.6, PLAYER_LINUX_XTRA_OFF)
			}
		}
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, random_num(m16a1_SHOOT1, m16a1_SHOOT2))
		make_shell(Player)
	}
}


public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_valid_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_GALIL)
		{
			if(g_has_m16a1[attacker])
			{
				switch(g_mode[attacker])
				{
					case 0: SetHamParamFloat(4, damage * cvar_dmg_m16a1)
					case 1,2: SetHamParamFloat(4, damage * cvar_dmg_m16a1_2)
				}
			}
		}
	}
}


public message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
	
	if(equal(szTruncatedWeapon, "galil") && get_user_weapon(iAttacker) == CSW_GALIL)
	{
		if(g_has_m16a1[iAttacker])
			set_msg_arg_string(4, "m16a1")
	}
	return PLUGIN_CONTINUE
}

stock fm_cs_get_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX)
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

public m16a1_ItemPostFrame(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!g_isconnected[id] || !g_has_m16a1[id])
          return HAM_IGNORED

     static iClipExtra
     
     iClipExtra = get_pcvar_num(cvar_clip_m16a1)
     new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

     new iBpAmmo = cs_get_user_bpammo(id, CSW_GALIL)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

     if( fInReload && flNextAttack <= 0.0 )
     {
	     new j = min(iClipExtra - iClip, iBpAmmo)
	
	     set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
	     cs_set_user_bpammo(id, CSW_GALIL, iBpAmmo-j)
		
	     set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
	     fInReload = 0
     }
     return HAM_IGNORED
}

public m16a1_Reload(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!g_isconnected[id])
          return HAM_IGNORED

     if (!g_has_m16a1[id])
          return HAM_IGNORED

     static iClipExtra

     if(g_has_m16a1[id])
          iClipExtra = get_pcvar_num(cvar_clip_m16a1)

     g_m16a1_TmpClip[id] = -1

     new iBpAmmo = cs_get_user_bpammo(id, CSW_GALIL)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     if (iBpAmmo <= 0)
          return HAM_SUPERCEDE

     if (iClip >= iClipExtra)
          return HAM_SUPERCEDE

     g_m16a1_TmpClip[id] = iClip

     return HAM_IGNORED
}

public m16a1_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!g_isconnected[id] || !g_has_m16a1[id] || g_m16a1_TmpClip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, m_iClip, g_m16a1_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, m16a1_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, m16a1_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	UTIL_PlayWeaponAnimation(id, m16a1_RELOAD)

	return HAM_IGNORED
}

public make_shell(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id))
		return;
	
	if(get_user_weapon(id) != CSW_GALIL) 
		return;
	
	if(!g_has_m16a1[id])
		return;
	
	static Float:player_origin[3], Float:origin[3], Float:origin2[3], Float:gunorigin[3], Float:oldangles[3], Float:v_forward[3], Float:v_forward2[3], Float:v_up[3], Float:v_up2[3], Float:v_right[3], Float:v_right2[3], Float:viewoffsets[3];
	pev(id,pev_v_angle, oldangles)
	pev(id,pev_origin,player_origin)
	pev(id, pev_view_ofs, viewoffsets);
	
	engfunc(EngFunc_MakeVectors, oldangles);
	
	global_get(glb_v_forward, v_forward);
	global_get(glb_v_up, v_up);
	global_get(glb_v_right, v_right);
	
	global_get(glb_v_forward, v_forward2);
	global_get(glb_v_up, v_up2);
	global_get(glb_v_right, v_right2);
	
	xs_vec_add(player_origin, viewoffsets, gunorigin);
	
	xs_vec_mul_scalar(v_forward, 10.3, v_forward);
	xs_vec_mul_scalar(v_right, 2.9, v_right);
	xs_vec_mul_scalar(v_up, -3.7, v_up);
	
	xs_vec_mul_scalar(v_forward2, 10.0, v_forward2);
	xs_vec_mul_scalar(v_right2, 3.0, v_right2);
	xs_vec_mul_scalar(v_up2, -4.0, v_up2);
	
	xs_vec_add(gunorigin, v_forward, origin);
	xs_vec_add(gunorigin, v_forward2, origin2);
	xs_vec_add(origin, v_right, origin);
	xs_vec_add(origin2, v_right2, origin2);
	xs_vec_add(origin, v_up, origin);
	xs_vec_add(origin2, v_up2, origin2);
	
	new Float:velocity[3]
	get_speed_vector(origin2, origin, random_float(140.0, 160.0), velocity)
	
	new angle = random_num(0, 360)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id)
	write_byte(TE_MODEL)
	write_coord_f(origin[0])
	write_coord_f(origin[1])
	write_coord_f(origin[2])
	write_coord_f(velocity[0])
	write_coord_f(velocity[1])
	write_coord_f(velocity[2])
	write_angle(angle)
	write_short(shells_model)
	write_byte(1)
	write_byte(get_pcvar_num(cvar_shellshealth_m16a1) * 10)
	message_end()
	
	new Float:origin3[3]
	origin3 = origin
	
	xs_vec_mul_scalar(v_forward, 3.9, v_forward);
	xs_vec_add(origin, v_forward, origin);
	
	for(new i; i <= 32; i++)
	{
		if(!is_user_connected(i) || i == id) continue;
		
		if(!is_user_alive(i) && pev(i, pev_iuser2) == id && pev(i, pev_iuser1) == 4)
		{
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, i)
			write_byte(TE_MODEL)
			write_coord_f(origin3[0])
			write_coord_f(origin3[1])
			write_coord_f(origin3[2])
			write_coord_f(velocity[0])
			write_coord_f(velocity[1])
			write_coord_f(velocity[2])
			write_angle(angle)
			write_short(shells_model)
			write_byte(1)
			write_byte(get_pcvar_num(cvar_shellshealth_m16a1) * 10)
			message_end()	
		}
		else
		{
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, i)
			write_byte(TE_MODEL)
			write_coord_f(origin[0])
			write_coord_f(origin[1])
			write_coord_f(origin[2])
			write_coord_f(velocity[0])
			write_coord_f(velocity[1])
			write_coord_f(velocity[2])
			write_angle(angle)
			write_short(shells_model)
			write_byte(1)
			write_byte(get_pcvar_num(cvar_shellshealth_m16a1) * 10)
			message_end()	
		}
	}
}

stock get_speed_vector(const Float:origin1[3], const Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed * speed / (new_velocity[0] * new_velocity[0] + new_velocity[1] * new_velocity[1] + new_velocity[2] * new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}

stock drop_weapons(id, dropwhat)
{
     static weapons[32], num, i, weaponid
     num = 0
     get_user_weapons(id, weapons, num)
     
     for (i = 0; i < num; i++)
     {
          weaponid = weapons[i]
          
          if (dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
          {
               static wname[32]
               get_weaponname(weaponid, wname, sizeof wname - 1)
               engclient_cmd(id, "drop", wname)
          }
     }
}

stock fm_give_item(index, const item[]) {
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0

	new ent = create_entity(item)
	if (!pev_valid(ent))
		return 0

	new Float:origin[3]
	pev(index, pev_origin, origin)
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)

	new save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, index)
	if (pev(ent, pev_solid) != save)
		return ent

	engfunc(EngFunc_RemoveEntity, ent)

	return -1
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/

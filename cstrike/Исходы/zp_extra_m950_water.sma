#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>

#define ENG_NULLENT			-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define m950_WEAPONKEY 	320
#define MAX_PLAYERS  		32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)

const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4

const m_iShotsFired = 64

#define WEAP_LINUX_XTRA_OFF		4
#define m_fKnown					44
#define m_flNextPrimaryAttack 		46
#define m_flNextSecondaryAttack 		47 
#define m_flTimeWeaponIdle			48
#define m_iClip					51
#define m_fInReload				54
#define PLAYER_LINUX_XTRA_OFF	5
#define m_flNextAttack				83

#define m950_RELOAD_TIME 		3.5
#define m950_SHOOT1			2
#define m950_SHOOT2			3
#define m950_SHOOT_EMPTY	5
#define m950_RELOAD			6
#define m950_DRAW			7

#define UP_SCALE				-6.0    //ВВЕРХ
#define FORWARD_SCALE		6.5     //ВПЕРЕД
#define RIGHT_SCALE			6.5     //ВПРАВО
#define TE_BOUNCE_SHELL		1

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

new const Fire_Sounds[][] = { "texas1k_extra/m950_coil1-1.wav" }
new const Sound_Zoom[] = { "weapons/zoom.wav" }

new m950_V_MODEL[64] = "models/texas1k_extra/v_m950_water.mdl"
new m950_P_MODEL[64] = "models/texas1k_extra/p_m950_water.mdl"
new m950_W_MODEL[64] = "models/texas1k_extra/w_m950_water.mdl"

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new const m950_name[] = "YouTuber_m950"

new const m950_spr[][] = 
{ 
	"sprites/YouTuber/640hud123.spr", 
	"sprites/YouTuber/640hud7.spr",
	"sprites/YouTuber/scope_snipers2.spr"
}

new g_itemid_m950
new cvar_dmg_m950, cvar_recoil_m950, cvar_clip_m950, cvar_spd_m950, cvar_m950_ammo, cvar_dmg_m950_z, cvar_recoil_m950_z, cvar_spd_m950_z
new g_MaxPlayers, g_orig_event_m950, g_IsInPrimaryAttack, g_iClip
new Float:cl_pushangle[MAX_PLAYERS + 1][3]
new g_has_m950[33], g_clip_ammo[33], g_m950_TmpClip[33], oldweap[33], g_hasZoom[33]
new g_hamczbots, cvar_botquota
new gmsgWeaponList

const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10", "weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_deagle", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
"weapon_ak47", "weapon_knife", "weapon_p90" }

public plugin_init()
{
	register_plugin("[ZP] Extra: M950 Attack", "1.0", "inf")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_deagle", "fw_m950_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
	if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_deagle", "fw_m950_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_deagle", "fw_m950_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_deagle", "m950_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, "weapon_deagle", "m950_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_deagle", "m950_Reload_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
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

	cvar_dmg_m950 = register_cvar("zp_m950_dmg", "3.10")
	cvar_recoil_m950 = register_cvar("zp_m950_recoil", "1.0")
	cvar_spd_m950 = register_cvar("zp_m950_spd", "0.7")
	cvar_dmg_m950_z = register_cvar("zp_m950_dmg_zoom", "5.19")
	cvar_recoil_m950_z = register_cvar("zp_m950_recoil_zoom", "0.5")
	cvar_spd_m950_z = register_cvar("zp_m950_spd_zoom", "1.0")
	cvar_clip_m950 = register_cvar("zp_m950_clip", "50")
	cvar_m950_ammo = register_cvar("zp_m950_ammo", "90")

	g_itemid_m950 = zp_register_extra_item("\r[П] \wM950 Water", 60, ZP_TEAM_HUMAN)
	g_MaxPlayers = get_maxplayers()
	cvar_botquota = get_cvar_pointer("bot_quota")
	gmsgWeaponList = get_user_msgid("WeaponList")
	register_clcmd(m950_name, "command_m950")
}

public plugin_precache()
{
	precache_model(m950_V_MODEL)
	precache_model(m950_P_MODEL)
	precache_model(m950_W_MODEL)

	for(new i = 0; i < sizeof Fire_Sounds; i++)
	precache_sound(Fire_Sounds[i])	

	precache_sound(Sound_Zoom)	

	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)

	new sFile[64]
	formatex(sFile, charsmax(sFile), "sprites/%s.txt", m950_name)
	precache_generic(sFile)
	
	for(new i = 0; i < sizeof(m950_spr); i++)
	{
		precache_generic(m950_spr[i])
	}
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_DEAGLE) return
	
	if(!g_has_m950[iAttacker]) return

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

public register_ham_czbots(Player)
{
	if (g_hamczbots || !is_user_connected(Player) || !get_pcvar_num(cvar_botquota)) return
	
	RegisterHamFromEntity(Ham_TakeDamage, Player, "fw_TakeDamage")
	
	g_hamczbots = true
}

public client_putinserver(Player)
{
	if(is_user_bot(Player) && !g_hamczbots && cvar_botquota) set_task(0.1, "register_ham_czbots", Player)
}

public command_m950(Player)
{
	engclient_cmd(Player, "weapon_deagle")
	return PLUGIN_HANDLED
}

public zp_user_humanized_post(id)
{
	g_has_m950[id] = false
}

public plugin_natives ()
{
	register_native("give_weapon_m950", "native_give_weapon_add", 1)
        register_native("get_weapon_m950", "native_get_weapon_add", 1)
}
public native_give_weapon_add(id)
{
	give_m950(id)
}
public native_get_weapon_add(id)
{
         return g_has_m950[id]
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/deagle.sc", name))
	{
		g_orig_event_m950 = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_m950[id] = false
}

public client_disconnect(id)
{
	g_has_m950[id] = false
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_m950[id] = false
	}
}

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
	
	if(equal(model, "models/w_deagle.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_deagle", entity)
	
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED
	
		if(g_has_m950[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, m950_WEAPONKEY)
			
			g_has_m950[iOwner] = false
			
			entity_set_model(entity, m950_W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_m950(id)
{
	drop_weapons(id, 2)
	new iWep2 = give_item(id,"weapon_deagle")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_m950))
		cs_set_user_bpammo (id, CSW_DEAGLE, get_pcvar_num(cvar_m950_ammo))	
		UTIL_PlayWeaponAnimation(id, m950_DRAW)
		set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)

		message_begin(MSG_ONE, gmsgWeaponList, _, id)
		write_string(m950_name)
		write_byte(8)
		write_byte(35)
		write_byte(-1)
		write_byte(-1)
		write_byte(1)
		write_byte(1)
		write_byte(CSW_DEAGLE)
		message_end()
	}
	g_has_m950[id] = true
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid != g_itemid_m950)
		return

	give_m950(id)
}

public fw_m950_AddToPlayer(m950, id)
{
	if(!is_valid_ent(m950) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(m950, EV_INT_WEAPONKEY) == m950_WEAPONKEY)
	{
		g_has_m950[id] = true
		
		entity_set_int(m950, EV_INT_WEAPONKEY, 0)
		
		message_begin(MSG_ONE, gmsgWeaponList, _, id)
		write_string(m950_name)
		write_byte(8)
		write_byte(35)
		write_byte(-1)
		write_byte(-1)
		write_byte(1)
		write_byte(1)
		write_byte(CSW_DEAGLE)
		message_end()

		return HAM_HANDLED
	}
	else
	{
		message_begin(MSG_ONE, gmsgWeaponList, _, id)
		write_string("weapon_deagle")
		write_byte(8)
		write_byte(35)
		write_byte(-1)
		write_byte(-1)
		write_byte(1)
		write_byte(1)
		write_byte(CSW_DEAGLE)
		message_end()
	}
	return HAM_IGNORED
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{
	if (use_type == USE_STOPPED && is_user_connected(caller))
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

     	if(read_data(2) != CSW_DEAGLE || !g_has_m950[id])
          	return
     
     	static Float:iSpeed
     	if(g_has_m950[id])
	{
		if(cs_get_user_zoom(id) == CS_SET_FIRST_ZOOM || cs_get_user_zoom(id) == CS_SET_SECOND_ZOOM)
			iSpeed = get_pcvar_float(cvar_spd_m950_z)
		else
			iSpeed = get_pcvar_float(cvar_spd_m950)
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
		case CSW_DEAGLE:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return
			
			if(g_has_m950[id])
			{
				set_pev(id, pev_viewmodel2, m950_V_MODEL)
				set_pev(id, pev_weaponmodel2, m950_P_MODEL)
				if(oldweap[id] != CSW_DEAGLE) 
				{
					UTIL_PlayWeaponAnimation(id, m950_DRAW)
					set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)

					message_begin(MSG_ONE, gmsgWeaponList, _, id)
					write_string(m950_name)
					write_byte(8)
					write_byte(35)
					write_byte(-1)
					write_byte(-1)
					write_byte(1)
					write_byte(1)
					write_byte(CSW_DEAGLE)
					message_end()
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_DEAGLE || !g_has_m950[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_m950_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_m950[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
	g_iClip = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_m950) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || (get_user_weapon(id) != CSW_DEAGLE || !g_has_m950[id]))
		return FMRES_IGNORED

	if(get_pdata_float(id, m_flNextAttack, OFFSET_LINUX) > 0.0)
		return FMRES_IGNORED
	
	if(get_user_weapon(id) == CSW_DEAGLE && g_has_m950[id])
	{
		if(get_uc(uc_handle, UC_Buttons) & IN_ATTACK2)
		{
            		new entity = get_pdata_cbase(id, OFFSET_ACTIVE_ITEM)

			if(get_pdata_float(entity, m_flNextSecondaryAttack, WEAP_LINUX_XTRA_OFF) <= 0.0)
			{
				if(!g_hasZoom[id] == true)
				{
					g_hasZoom[id] = true
					cs_set_user_zoom(id, CS_SET_FIRST_ZOOM, 1)
					emit_sound(id, CHAN_ITEM, Sound_Zoom, 0.20, 2.40, 0, 100)
					set_pdata_float(entity, m_flNextSecondaryAttack, 0.3, WEAP_LINUX_XTRA_OFF)
				}
				else if(g_hasZoom[id] && cs_get_user_zoom(id) == CS_SET_FIRST_ZOOM)
				{
					cs_set_user_zoom(id, CS_SET_SECOND_ZOOM, 1)
					emit_sound(id, CHAN_ITEM, Sound_Zoom, 0.20, 2.40, 0, 100)
					set_pdata_float(entity, m_flNextSecondaryAttack, 0.3, WEAP_LINUX_XTRA_OFF)
				}
				else if(g_hasZoom[id])
				{
					g_hasZoom[id] = false
					cs_set_user_zoom(id, CS_RESET_ZOOM, 0)	
					emit_sound(id, CHAN_ITEM, Sound_Zoom, 0.20, 2.40, 0, 100)
					set_pdata_float(entity, m_flNextSecondaryAttack, 0.3, WEAP_LINUX_XTRA_OFF)
				}
			}
		}
		if(g_hasZoom[id] && (pev(id, pev_button) & IN_RELOAD))
		{
			g_hasZoom[id] = false
			cs_set_user_zoom(id, CS_RESET_ZOOM, 0)
			emit_sound(id, CHAN_ITEM, Sound_Zoom, 0.20, 2.40, 0, 100)
		}
	}
	return FMRES_HANDLED
}

public fw_m950_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!is_user_alive(Player))
		return

	if (g_iClip <= cs_get_weapon_ammo(Weapon))
		return

	if(g_has_m950[Player])
	{
		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		if(cs_get_user_zoom(Player) == CS_SET_FIRST_ZOOM || cs_get_user_zoom(Player) == CS_SET_SECOND_ZOOM)
			xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_m950_z),push)
		else
			xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_m950),push)

		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		if(szClip > 1)  UTIL_PlayWeaponAnimation(Player, random_num(m950_SHOOT1,m950_SHOOT2))
		if(szClip == 1) UTIL_PlayWeaponAnimation(Player, m950_SHOOT_EMPTY)		
		
		set_pdata_int(Weapon, m_iShotsFired, -1, 4)

		static Float:vVel[3], Float:vAngle[3], Float:vOrigin[3], Float:vViewOfs[3], 
		i, Float:vShellOrigin[3], Float:vShellVelocity[3], Float:vRight[3], 
		Float:vUp[3], Float:vForward[3]
		pev(Player, pev_velocity, vVel)
		pev(Player, pev_view_ofs, vViewOfs)
		pev(Player, pev_angles, vAngle)
		pev(Player, pev_origin, vOrigin)
		global_get(glb_v_right, vRight)
		global_get(glb_v_up, vUp)
		global_get(glb_v_forward, vForward)
		for(i = 0; i<3; i++)
		{
			vShellOrigin[i] = vOrigin[i] + vViewOfs[i] + vUp[i] * UP_SCALE + vForward[i] * FORWARD_SCALE + vRight[i] * RIGHT_SCALE
			vShellVelocity[i] = vVel[i] + vRight[i] * random_float(-50.0, -70.0) + vUp[i] * random_float(100.0, 150.0) + vForward[i] * 25.0
		}
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_DEAGLE)
		{
			if(g_has_m950[attacker])
			{
				if(cs_get_user_zoom(attacker) == CS_SET_FIRST_ZOOM || cs_get_user_zoom(attacker) == CS_SET_SECOND_ZOOM)
					SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_m950_z))
				else
					SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_m950))
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
	
	if(equal(szTruncatedWeapon, "deagle") && get_user_weapon(iAttacker) == CSW_DEAGLE)
	{
		if(g_has_m950[iAttacker])
			set_msg_arg_string(4, "deagle")
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

public m950_ItemPostFrame(weapon_entity) 
{
     	new id = pev(weapon_entity, pev_owner)
     	if (!is_user_connected(id))
          	return HAM_IGNORED

     	if (!g_has_m950[id])
          	return HAM_IGNORED

     	static iClipExtra
     
     	iClipExtra = get_pcvar_num(cvar_clip_m950)
     	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

     	new iBpAmmo = cs_get_user_bpammo(id, CSW_DEAGLE)
     	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     	new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

     	if( fInReload && flNextAttack <= 0.0 )
     	{
	     	new j = min(iClipExtra - iClip, iBpAmmo)
	
	     	set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
	     	cs_set_user_bpammo(id, CSW_DEAGLE, iBpAmmo-j)
		
	     	set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
	     	fInReload = 0
     	}
     	return HAM_IGNORED
}

public m950_Reload(weapon_entity) 
{
     	new id = pev(weapon_entity, pev_owner)
     	if (!is_user_connected(id))
          	return HAM_IGNORED

     	if (!g_has_m950[id])
          	return HAM_IGNORED

     	static iClipExtra

     	if(g_has_m950[id])
          	iClipExtra = get_pcvar_num(cvar_clip_m950)

     	g_m950_TmpClip[id] = -1

     	new iBpAmmo = cs_get_user_bpammo(id, CSW_DEAGLE)
     	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     	if (iBpAmmo <= 0)
          	return HAM_SUPERCEDE

     	if (iClip >= iClipExtra)
          	return HAM_SUPERCEDE

     	g_m950_TmpClip[id] = iClip

     	return HAM_IGNORED
}

public m950_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_m950[id])
		return HAM_IGNORED

	if (g_m950_TmpClip[id] == -1)
		return HAM_IGNORED

	cs_set_user_zoom(id, CS_RESET_ZOOM, 1)

	set_pdata_int(weapon_entity, m_iClip, g_m950_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, m950_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, m950_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	UTIL_PlayWeaponAnimation(id, m950_RELOAD)

	return HAM_IGNORED
}

stock drop_weapons(id, dropwhat)
{
     static weapons[32], num, i, weaponid
     num = 0
     get_user_weapons(id, weapons, num)
     
     for (i = 0; i < num; i++)
     {
          weaponid = weapons[i]
          
          if (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM))
          {
               static wname[32]
               get_weaponname(weaponid, wname, sizeof wname - 1)
               engclient_cmd(id, "drop", wname)
          }
     }
}
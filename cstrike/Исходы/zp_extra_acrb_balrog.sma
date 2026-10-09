#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>

#define ENG_NULLENT		-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define acr_WEAPONKEY 32546
#define MAX_PLAYERS  			  32
const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4

new gmsgWeaponList

#define WEAP_LINUX_XTRA_OFF			4
#define m_fKnown				44
#define m_flNextPrimaryAttack 			46
#define m_flTimeWeaponIdle			48
#define m_iClip					51
#define m_fInReload				54
#define PLAYER_LINUX_XTRA_OFF			5
#define m_flNextAttack				83

#define acr_RELOAD_TIME 3.7

const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_MP5NAVY)|(1<<CSW_SG550)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_UMP45)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)

new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_mp5navy", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

new const Sound_Fire[][] = { "texas1k_extra/acrb_balrog-1.wav" }
new const Sound_Zoom[] = { "weapons/zoom.wav" }
new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }
new acr_V_MODEL[64]  = "models/texas1k_extra/v_acrb_balrog.mdl"
new acr_V_MODEL_Z[64]  = "models/texas1k_extra/v_acrb_balrog_zoom.mdl"
new acr_P_MODEL[64] = "models/texas1k_extra/p_acrb_balrog.mdl"
new acr_W_MODEL[64] = "models/texas1k_extra/w_acrb_balrog.mdl"
new cvar_dmg_acr, cvar_recoil_acr, g_itemid_acr, cvar_clip_acr, cvar_spd_acr, cvar_acr_ammo,cvar_spd_acr_z, cvar_dmg_acr_z, cvar_recoil_acr_zoom
new g_has_acr[33], g_MaxPlayers, Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2],
g_orig_event_acr, g_IsInPrimaryAttack, g_clip_ammo[33], g_acr_TmpClip[33], g_zoom[33],g_can[33]

public plugin_init()
{
	register_plugin("ACR", "1.0", "123321")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_mp5navy", "fw_acr_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_mp5navy", "fw_acr_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_mp5navy", "fw_acr_PrimaryAttack_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Item_PostFrame, "weapon_mp5navy", "acr__ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, "weapon_mp5navy", "acr__Reload");
	RegisterHam(Ham_Weapon_Reload, "weapon_mp5navy", "acr__Reload_Post", 1);
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_CmdStart, "fw_CmdStart")
	gmsgWeaponList = get_user_msgid("WeaponList")
	
	cvar_dmg_acr = register_cvar("zp_acr_dmg", "1.7")
	cvar_dmg_acr_z = register_cvar("zp_acr_dmg_zoom", "2.0")
	cvar_recoil_acr = register_cvar("zp_acr_recoil", "1.7") 
	cvar_recoil_acr_zoom = register_cvar("zp_acr_recoil_zoom", "0.3") 
	cvar_clip_acr = register_cvar("zp_acr_clip", "30")
	cvar_spd_acr = register_cvar("zp_acr_spd", "1.4")
	cvar_acr_ammo = register_cvar("zp_acr_ammo", "150")
	cvar_spd_acr_z = register_cvar("zp_acr_spd_zoom", "2.0")
	
	g_itemid_acr = zp_register_extra_item("\r[A] \wАcrb Balrog", 100, ZP_TEAM_HUMAN)
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	precache_model(acr_V_MODEL)
	precache_model(acr_V_MODEL_Z)
	precache_model(acr_P_MODEL)
	precache_model(acr_W_MODEL)
	for(new i = 0; i < sizeof Sound_Fire; i++)
	precache_sound(Sound_Fire[i])
	precache_sound("texas1k_extra/acrb_balrog_clipout.wav")
	precache_sound("texas1k_extra/acrb_balrog_clipin.wav")
	precache_sound("texas1k_extra/acrb_balrog_draw.wav")
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	precache_generic("sprites/weapon_acr.txt")
	precache_generic("sprites/640hud0.spr")
	precache_generic("sprites/640hud7.spr")
	register_clcmd("weapon_acr", "Hook_Select")

	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/mp5n.sc", name))
	{
		g_orig_event_acr = get_orig_retval()
		return FMRES_HANDLED
	}

	return FMRES_IGNORED
}

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED;
	
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
		
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED;
	
	static iOwner
	
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, "models/w_mp5.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_mp5navy", entity)
	
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED;
	
		if(g_has_acr[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, acr_WEAPONKEY)
			
			g_has_acr[iOwner] = false
			
			entity_set_model(entity, acr_W_MODEL)
			
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id)) 
		return PLUGIN_HANDLED
	
	if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
	{
		new szClip, szAmmo
		new szWeapID = get_user_weapon(id, szClip, szAmmo)
		
		if(szWeapID == CSW_MP5NAVY &&  g_has_acr[id] && !g_zoom[id] == true && g_can[id])
		{
			g_zoom[id] = true
			cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 1)
			emit_sound(id, CHAN_ITEM, Sound_Zoom, 0.20, 2.40, 0, 100)
			replace_weapon_models(id,CSW_MP5NAVY)
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("HideWeapon"), _, id)
			write_byte((1<<6))
			message_end()
		}
		
		else if(szWeapID == CSW_MP5NAVY && g_has_acr[id] && g_zoom[id])
		{
			g_zoom[id] = false
			cs_set_user_zoom(id, CS_RESET_ZOOM, 0)
			replace_weapon_models(id,CSW_MP5NAVY)
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("HideWeapon"), _, id)
			write_byte(0)
			message_end()
			
		}
		
	}
	return PLUGIN_HANDLED
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_itemid_acr)
	{
		drop_weapons(id, 1);
		new iWep2 = give_item(id,"weapon_mp5navy")
		if( iWep2 > 0 )
		{
			cs_set_weapon_ammo( iWep2, get_pcvar_num(cvar_clip_acr) )
			cs_set_user_bpammo (id, CSW_MP5NAVY, get_pcvar_num(cvar_acr_ammo))
			UTIL_PlayWeaponAnimation(id, 2)
		}
		g_has_acr[id] = true;
		g_can[id] = false
		g_zoom[id] = false
		set_pdata_float(id, m_flNextAttack, 1.28, PLAYER_LINUX_XTRA_OFF)
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("HideWeapon"), _, id)
		write_byte(0)
		message_end()
		if(g_has_acr[id] == 1)
		{
		Sprite(id)
		}
	}
}


public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
        if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_MP5NAVY) || !g_has_acr[Player])
        return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.00001)
	return FMRES_HANDLED
}

public fw_acr_AddToPlayer(ACR, id)
{
	if(!is_valid_ent(ACR) || !is_user_connected(id))
		return HAM_IGNORED;
	
	if(entity_get_int(ACR, EV_INT_WEAPONKEY) == acr_WEAPONKEY)
	{
		g_has_acr[id] = true
		
		Sprite(id)
		
		entity_set_int(ACR, EV_INT_WEAPONKEY, 0)
		
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
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

     if(read_data(2) != CSW_MP5NAVY || !g_has_acr[id])
          return
     
     static Float:iSpeed
     if(g_has_acr[id])
          iSpeed = get_pcvar_float(cvar_spd_acr)
     if(g_zoom[id]) iSpeed = get_pcvar_float(cvar_spd_acr_z)
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
	if(get_user_weapon(id) != CSW_MP5NAVY && !zp_get_user_zombie(id))
	{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("HideWeapon"), _, id)
	write_byte(0)
	message_end()
	}
	switch (weaponid)
	{
		case CSW_MP5NAVY:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return;
			
			if(g_has_acr[id])
			{
				if(g_has_acr[id]) set_pev(id, pev_viewmodel2, acr_V_MODEL)
				if(g_zoom[id]) set_pev(id, pev_viewmodel2, acr_V_MODEL_Z)
				set_pev(id, pev_weaponmodel2, acr_P_MODEL)
			}
			if(g_has_acr[id] && get_user_weapon(id) != CSW_MP5NAVY)
			{
			g_zoom[id] = false
			set_pdata_float(id, m_flNextAttack, 1.28, PLAYER_LINUX_XTRA_OFF)
			g_can[id] = false
			}
		}
	}
}

public Sprite(id)
{
 message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)

 write_string("weapon_acr")

 write_byte(10)
 write_byte(120) 
 write_byte(-1)
 write_byte(-1)
 write_byte(0)
 write_byte(7)
 write_byte(19)
 write_byte(0)
 message_end()

}

public Hook_Select(id)
{
 engclient_cmd(id, "weapon_mp5navy")
 return PLUGIN_HANDLED
}


public fw_acr_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_acr[Player])
		return;
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_acr) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_acr_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if(g_has_acr[Player])
	{
		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_acr),push)
		if(g_zoom[Player]) xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_acr_zoom),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		if (!g_clip_ammo[Player])
			return
		
		engfunc(EngFunc_EmitSound, Player, CHAN_WEAPON, Sound_Fire[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, random_num(3, 4))
	
		make_blood_and_bulletholes(Player)
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_MP5NAVY)
		{
			if(g_has_acr[attacker]) SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_acr))
			if(g_zoom[attacker]) SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_acr_z))
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
	
	if(equal(szTruncatedWeapon, "ump45") && get_user_weapon(iAttacker) == CSW_MP5NAVY)
	{
		if(g_has_acr[iAttacker])
			set_msg_arg_string(4, "acr")
	}
	
	return PLUGIN_CONTINUE
}

stock fm_cs_get_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX);
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

stock make_blood_and_bulletholes(id)
{
	new aimOrigin[3], target, body
	get_user_origin(id, aimOrigin, 3)
	get_user_aiming(id, target, body)
	
	if(target > 0 && target <= g_MaxPlayers && zp_get_user_zombie(target))
	{
		new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3]
		pev(id, pev_origin, fStart)
		
		velocity_by_aim(id, 64, fVel)
		
		fStart[0] = float(aimOrigin[0])
		fStart[1] = float(aimOrigin[1])
		fStart[2] = float(aimOrigin[2])
		fEnd[0] = fStart[0]+fVel[0]
		fEnd[1] = fStart[1]+fVel[1]
		fEnd[2] = fStart[2]+fVel[2]
		
		new res
		engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res)
		get_tr2(res, TR_vecEndPos, fRes)
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(TE_BLOODSPRITE)
		write_coord(floatround(fStart[0])) 
		write_coord(floatround(fStart[1])) 
		write_coord(floatround(fStart[2])) 
		write_short( m_iBlood [ 1 ])
		write_short( m_iBlood [ 0 ] )
		write_byte(70)
		write_byte(random_num(1,2))
		message_end()
		
		
	} 
	else if(!is_user_connected(target))
	{
		if(target)
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_DECAL)
			write_coord(aimOrigin[0])
			write_coord(aimOrigin[1])
			write_coord(aimOrigin[2])
			write_byte(GUNSHOT_DECALS[random_num ( 0, sizeof GUNSHOT_DECALS -1 ) ] )
			write_short(target)
			message_end()
		} 
		else 
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_WORLDDECAL)
			write_coord(aimOrigin[0])
			write_coord(aimOrigin[1])
			write_coord(aimOrigin[2])
			write_byte(GUNSHOT_DECALS[random_num ( 0, sizeof GUNSHOT_DECALS -1 ) ] )
			message_end()
		}
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		write_coord(aimOrigin[0])
		write_coord(aimOrigin[1])
		write_coord(aimOrigin[2])
		write_short(id)
		write_byte(GUNSHOT_DECALS[random_num ( 0, sizeof GUNSHOT_DECALS -1 ) ] )
		message_end()
	}
}

public acr__ItemPostFrame(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     static iAnim; iAnim = pev(id, pev_weaponanim)
     if (!is_user_connected(id))
          return HAM_IGNORED;

     if (!g_has_acr[id])
          return HAM_IGNORED;
     
     static iClipExtra

     if(g_has_acr[id])
          iClipExtra = get_pcvar_num(cvar_clip_acr)

     new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

     new iBpAmmo = cs_get_user_bpammo(id, CSW_MP5NAVY);
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 
     
     if(iAnim == 2)
     {
     g_can[id] = true
     }	
     
     if( fInReload && flNextAttack <= 0.0 )
     {
          new j = min(iClipExtra - iClip, iBpAmmo)
     
          set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
          cs_set_user_bpammo(id, CSW_MP5NAVY, iBpAmmo-j);
          
          set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
          g_can[id] = true
          fInReload = 0
     }

     return HAM_IGNORED;
}

public acr__Reload(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED;

     if (!g_has_acr[id])
          return HAM_IGNORED;

     static iClipExtra

     if(g_has_acr[id])
          iClipExtra = get_pcvar_num(cvar_clip_acr)

     g_acr_TmpClip[id] = -1;

     new iBpAmmo = cs_get_user_bpammo(id, CSW_MP5NAVY);
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     if (iBpAmmo <= 0)
          return HAM_SUPERCEDE;

     if (iClip >= iClipExtra)
          return HAM_SUPERCEDE;


     g_acr_TmpClip[id] = iClip;

     return HAM_IGNORED;
}

public acr__Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_acr[id])
		return HAM_IGNORED;

	if (g_acr_TmpClip[id] == -1)
		return HAM_IGNORED;

	static Float:iReloadTime
	if(g_has_acr[id])
		iReloadTime = acr_RELOAD_TIME

	set_pdata_int(weapon_entity, m_iClip, g_acr_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, iReloadTime, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, iReloadTime, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	UTIL_PlayWeaponAnimation(id, 1)
	g_zoom[id] = false
	g_can[id] = false
	cs_set_user_zoom( id, CS_RESET_ZOOM, 0 )
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("HideWeapon"), _, id)
	write_byte(0)
	message_end()

	return HAM_IGNORED;

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
//// Ыᤨ롧妫᩠misna 嬿 򡪲ힹ���ower-cs.ru 
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/

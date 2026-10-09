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
#define buffm4g_WEAPONKEY 		83413896228
#define MAX_PLAYERS  		32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)

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

#define buffm4g_RELOAD_TIME 	2.0
#define buffm4g_RELOAD			1
#define buffm4g_DRAW			2
#define buffm4g_SHOOT1			3
#define buffm4g_SHOOT2			4

new const Fire_Sounds[][] = { "vip_weapons/m4a1buff-2.wav" }

new buffm4g_V_MODEL[64] = "models/vip_weapons/v_buffm4_gold.mdl"
new buffm4g_P_MODEL[64] = "models/vip_weapons/p_buffm4_gold.mdl"
new buffm4g_W_MODEL[64] = "models/vip_weapons/w_buffm4_gold.mdl"

new cvar_dmg_buffm4g, cvar_recoil_buffm4g, g_itemid_buffm4g, cvar_clip_buffm4g, cvar_spd_buffm4g, cvar_buffm4g_ammo
new g_MaxPlayers, g_orig_event_buffm4g, g_IsInPrimaryAttack
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_has_buffm4g[33], g_clip_ammo[33], g_buffm4g_TmpClip[33], oldweap[33]
new sTrail, g_smokepuff_id

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
	register_plugin("[CSO] Weapon: Buff M4A1 Gold Knight", "1.0", "inf")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_sg552", "fw_buffm4g_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
	if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_sg552", "fw_buffm4g_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_sg552", "fw_buffm4g_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_sg552", "buffm4g_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, "weapon_sg552", "buffm4g_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_sg552", "buffm4g_Reload_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)

	cvar_dmg_buffm4g = register_cvar("zp_buffm4g_dmg", "5.0")
	cvar_recoil_buffm4g = register_cvar("zp_buffm4g_recoil", "0.41")
	cvar_clip_buffm4g = register_cvar("zp_buffm4g_clip", "50")
	cvar_spd_buffm4g = register_cvar("zp_buffm4g_spd", "2.61")
	cvar_buffm4g_ammo = register_cvar("zp_buffm4g_ammo", "90")
	
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	precache_model(buffm4g_V_MODEL)
	precache_model(buffm4g_P_MODEL)
	precache_model(buffm4g_W_MODEL)
	
	for(new i = 0; i < sizeof Fire_Sounds; i++)
	precache_sound(Fire_Sounds[i])	
	
	sTrail = precache_model("sprites/Reega_kz/zbeam2.spr")
	g_smokepuff_id = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")

	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

public fw_TraceAttack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker) || !is_user_connected(attacker))
		return HAM_IGNORED	
	if(get_user_weapon(attacker) != CSW_SG552 || !g_has_buffm4g[attacker])
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3]
	
	get_tr2(ptr, TR_vecEndPos, flEnd)
	get_tr2(ptr, TR_vecPlaneNormal, vecPlane)		

	if(!is_user_alive(ent))
	{
		make_bullet(attacker, flEnd)
		fake_smoke(attacker, ptr)
		shot_skill(attacker, ptr)
	}

	return HAM_HANDLED
}

public shot_skill(id, ptr)
{
	static Float:flEnd[3], Float:StartOrigin2[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	get_position(id, 40.0, 6.0, -7.0, StartOrigin2)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, StartOrigin2[0])
	engfunc(EngFunc_WriteCoord, StartOrigin2[1])
	engfunc(EngFunc_WriteCoord, StartOrigin2[2])
	engfunc(EngFunc_WriteCoord, flEnd[0])
	engfunc(EngFunc_WriteCoord, flEnd[1])
	engfunc(EngFunc_WriteCoord, flEnd[2])
	write_short(sTrail)
	write_byte(0) // start frame
	write_byte(0) // framerate
	write_byte(5) // life
	write_byte(12) // line width
	write_byte(0) // amplitude
	write_byte(200) // red
	write_byte(200) // green
	write_byte(200) // blue
	write_byte(30) // brightness
	write_byte(0) // speed
	message_end()
}

public zp_user_humanized_post(id)
{
	g_has_buffm4g[id] = false
}

public plugin_natives ()
{
	register_native("give_weapon_buffm4g", "native_give_weapon_add", 1)
}
public native_give_weapon_add(id)
{
	give_buffm4g(id)
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/sg552.sc", name))
	{
		g_orig_event_buffm4g = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_buffm4g[id] = false
}

public client_disconnect(id)
{
	g_has_buffm4g[id] = false
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_buffm4g[id] = false
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
	
	if(equal(model, "models/w_sg552.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_sg552", entity)
	
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED
	
		if(g_has_buffm4g[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, buffm4g_WEAPONKEY)
			
			g_has_buffm4g[iOwner] = false
			
			entity_set_model(entity, buffm4g_W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_buffm4g(id)
{
	drop_weapons(id, 1)
	new iWep2 = give_item(id,"weapon_sg552")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_buffm4g))
		cs_set_user_bpammo (id, CSW_SG552, get_pcvar_num(cvar_buffm4g_ammo))	
		UTIL_PlayWeaponAnimation(id, buffm4g_DRAW)
		set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
	}
	g_has_buffm4g[id] = true
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid != g_itemid_buffm4g)
		return

	give_buffm4g(id)
}

public fw_buffm4g_AddToPlayer(buffm4g, id)
{
	if(!is_valid_ent(buffm4g) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(buffm4g, EV_INT_WEAPONKEY) == buffm4g_WEAPONKEY)
	{
		g_has_buffm4g[id] = true
		
		entity_set_int(buffm4g, EV_INT_WEAPONKEY, 0)

		return HAM_HANDLED
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

     if(read_data(2) != CSW_SG552 || !g_has_buffm4g[id])
          return
     
     static Float:iSpeed
     if(g_has_buffm4g[id])
          iSpeed = get_pcvar_float(cvar_spd_buffm4g)
     
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
		case CSW_SG552:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return
			
			if(g_has_buffm4g[id])
			{
				set_pev(id, pev_viewmodel2, buffm4g_V_MODEL)
				set_pev(id, pev_weaponmodel2, buffm4g_P_MODEL)
				if(oldweap[id] != CSW_SG552) 
				{
					UTIL_PlayWeaponAnimation(id, buffm4g_DRAW)
					set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_SG552 || !g_has_buffm4g[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_buffm4g_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_buffm4g[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
	
	static Float:plrViewAngles[3], Float:VecEnd[3], Float:VecDir[3], Float:PlrOrigin[3]
	pev(Player, pev_v_angle, plrViewAngles)

	static Float:VecSrc[3], Float:VecDst[3]
	
	//VecSrc = pev->origin + pev->view_ofs
	pev(Player, pev_origin, PlrOrigin)
	pev(Player, pev_view_ofs, VecSrc)
	xs_vec_add(VecSrc, PlrOrigin, VecSrc)

	//VecDst = VecDir * 8192.0
	angle_vector(plrViewAngles, ANGLEVECTOR_FORWARD, VecDir)
	xs_vec_mul_scalar(VecDir, 8192.0, VecDst)
	xs_vec_add(VecDst, VecSrc, VecDst)
	
	new hTrace = create_tr2()
	engfunc(EngFunc_TraceLine, VecSrc, VecDst, 0, Player, hTrace)
	get_tr2(hTrace, TR_vecEndPos, VecEnd)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_buffm4g) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_buffm4g_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!is_user_alive(Player))
		return

	if(g_has_buffm4g[Player])
	{
		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_buffm4g),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, random_num(buffm4g_SHOOT1, buffm4g_SHOOT2))
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_SG552)
		{
			if(g_has_buffm4g[attacker])
				SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_buffm4g))
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
	
	if(equal(szTruncatedWeapon, "sg552") && get_user_weapon(iAttacker) == CSW_SG552)
	{
		if(g_has_buffm4g[iAttacker])
			set_msg_arg_string(4, "sg552")
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

stock make_bullet(id, Float:Origin[3])
{
	// Find target
	new decal = random_num(41, 45)
	const loop_time = 2
	
	static Body, Target
	get_user_aiming(id, Target, Body, 999999)
	
	if(is_user_connected(Target))
		return
	
	for(new i = 0; i < loop_time; i++)
	{
		// Put decal on "world" (a wall)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(decal)
		message_end()
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(id)
		write_byte(decal)
		message_end()
	}
}

public fake_smoke(id, trace_result)
{
	static Float:vecSrc[3], Float:vecEnd[3], TE_FLAG
	
	get_weapon_attachment(id, vecSrc)
	global_get(glb_v_forward, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)

	get_tr2(trace_result, TR_vecEndPos, vecSrc)
	get_tr2(trace_result, TR_vecPlaneNormal, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 2.5, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
    
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecEnd[0])
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] - 10.0)
	write_short(g_smokepuff_id)
	write_byte(2)
	write_byte(50)
	write_byte(TE_FLAG)
	message_end()
}

public buffm4g_ItemPostFrame(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_buffm4g[id])
          return HAM_IGNORED

     static iClipExtra
     
     iClipExtra = get_pcvar_num(cvar_clip_buffm4g)
     new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

     new iBpAmmo = cs_get_user_bpammo(id, CSW_SG552)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

     if( fInReload && flNextAttack <= 0.0 )
     {
	     new j = min(iClipExtra - iClip, iBpAmmo)
	
	     set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
	     cs_set_user_bpammo(id, CSW_SG552, iBpAmmo-j)
		
	     set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
	     fInReload = 0
     }
     return HAM_IGNORED
}

public buffm4g_Reload(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_buffm4g[id])
          return HAM_IGNORED

     static iClipExtra

     if(g_has_buffm4g[id])
          iClipExtra = get_pcvar_num(cvar_clip_buffm4g)

     g_buffm4g_TmpClip[id] = -1

     new iBpAmmo = cs_get_user_bpammo(id, CSW_SG552)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     if (iBpAmmo <= 0)
          return HAM_SUPERCEDE

     if (iClip >= iClipExtra)
          return HAM_SUPERCEDE

     g_buffm4g_TmpClip[id] = iClip

     return HAM_IGNORED
}

stock get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	new Float:vfEnd[3], viEnd[3] 
	get_user_origin(id, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	new Float:fOrigin[3], Float:fAngle[3]
	
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	new Float:fAttack[3]
	
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	new Float:fRate
	
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	
	xs_vec_add(fOrigin, fAttack, output)
}

public buffm4g_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_buffm4g[id])
		return HAM_IGNORED

	if (g_buffm4g_TmpClip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, m_iClip, g_buffm4g_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, buffm4g_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, buffm4g_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	UTIL_PlayWeaponAnimation(id, buffm4g_RELOAD)

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
          
          if (dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
          {
               static wname[32]
               get_weaponname(weaponid, wname, sizeof wname - 1)
               engclient_cmd(id, "drop", wname)
          }
     }
}

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp) //for player
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD, vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}
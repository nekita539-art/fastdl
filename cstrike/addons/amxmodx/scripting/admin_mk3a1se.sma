#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>

#define TASK_FBURN				100
#define ID_FBURN                ( taskid - TASK_FBURN )

#define MAX_CLIENTS				32

new bool:g_fRoundEnd

#define FIRE_DURATION			3
#define FIRE_DAMAGE				228

#define ENG_NULLENT		-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define jh_WEAPONKEY 709
#define MAX_PLAYERS  			  32
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

#define jh_RELOAD_TIME 2.5
#define jh_IDLE 			0
#define jh_SHOOT1		1
#define jh_SHOOT2		2
#define jh_RELOAD		3
#define jh_DRAW		4

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

new const Fire_Sounds[][] = { "admin_weapons/mk3a1se-1.wav" }

new jh_V_MODEL[64] = "models/admin_weapons/v_jh_flame.mdl"
new jh_P_MODEL[64] = "models/admin_weapons/p_jh_flame.mdl"
new jh_W_MODEL[64] = "models/admin_weapons/w_jh_flame.mdl"

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new cvar_dmg_jh, cvar_recoil_jh, cvar_clip_jh, cvar_spd_jh, cvar_jh_ammo
new g_MaxPlayers, g_orig_event_jh, g_IsInPrimaryAttack
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_has_jh[33], g_clip_ammo[33], g_jh_TmpClip[33], oldweap[33]
new g_flameSpr, g_smokeSpr, g_burning_duration[ MAX_CLIENTS + 1 ]

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
	register_plugin("[ZP] Extra: Jack Hammer Flame", "1.0", "inf")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_xm1014", "fw_jh_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
	if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_xm1014", "fw_jh_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_xm1014", "fw_jh_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_xm1014", "jh_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, "weapon_xm1014", "jh_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_xm1014", "jh_Reload_Post", 1)
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

	cvar_dmg_jh = register_cvar("zp_jh_dmg", "6.0")
	cvar_recoil_jh = register_cvar("zp_jh_recoil", "1.0")
	cvar_clip_jh = register_cvar("zp_jh_clip", "15")
	cvar_spd_jh = register_cvar("zp_jh_spd", "1.0")
	cvar_jh_ammo = register_cvar("zp_jh_ammo", "32")
	
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	precache_model(jh_V_MODEL)
	precache_model(jh_P_MODEL)
	precache_model(jh_W_MODEL)
	
	for(new i = 0; i < sizeof Fire_Sounds; i++)
	precache_sound(Fire_Sounds[i])	
	
	precache_sound("admin_weapons/mk3a1se_boltpull.wav")
	precache_sound("admin_weapons/mk3a1se_clipin.wav")
	precache_sound("admin_weapons/mk3a1se_draw.wav")
	
	g_flameSpr = precache_model( "sprites/flame.spr" );
	g_smokeSpr = precache_model( "sprites/black_smoke3.spr" );
	
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	
    register_clcmd("weapon_jh12", "weapon_hook")	

	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

public weapon_hook(id)
{
    engclient_cmd(id, "weapon_xm1014")
    return PLUGIN_HANDLED
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_XM1014) return
	
	if(!g_has_jh[iAttacker]) return

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

public zp_user_humanized_post(id)
{
	g_has_jh[id] = false
}

public plugin_natives()
{
	register_native("give_weapon_jh", "give_jh", 1)
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/xm1014.sc", name))
	{
		g_orig_event_jh = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_jh[id] = false
}

public client_disconnect(id)
{
	g_has_jh[id] = false
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_jh[id] = false
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
	
	if(equal(model, "models/w_xm1014.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_xm1014", entity)
	
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED
	
		if(g_has_jh[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, jh_WEAPONKEY)
			
			g_has_jh[iOwner] = false
			
			entity_set_model(entity, jh_W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_jh(id)
{
	drop_weapons(id, 1)
	new iWep2 = give_item(id,"weapon_xm1014")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_jh))
		cs_set_user_bpammo (id, CSW_XM1014, get_pcvar_num(cvar_jh_ammo))	
		UTIL_PlayWeaponAnimation(id, jh_DRAW)
		set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
	}
	g_has_jh[id] = true
}

public fw_jh_AddToPlayer(jh, id)
{
	if(!is_valid_ent(jh) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(jh, EV_INT_WEAPONKEY) == jh_WEAPONKEY)
	{
		g_has_jh[id] = true
		
		entity_set_int(jh, EV_INT_WEAPONKEY, 0) 
		
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

     if(read_data(2) != CSW_XM1014 || !g_has_jh[id])
          return
     
     static Float:iSpeed
     if(g_has_jh[id])
          iSpeed = get_pcvar_float(cvar_spd_jh)
     
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
		case CSW_XM1014:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return
			
			if(g_has_jh[id])
			{
				set_pev(id, pev_viewmodel2, jh_V_MODEL)
				set_pev(id, pev_weaponmodel2, jh_P_MODEL)
				if(oldweap[id] != CSW_XM1014) 
				{
					UTIL_PlayWeaponAnimation(id, jh_DRAW)
					set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_XM1014 || !g_has_jh[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_jh_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_jh[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_jh) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_jh_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!is_user_alive(Player))
		return

	if(g_has_jh[Player])
	{
		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_jh),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, random_num(jh_SHOOT1, jh_SHOOT2))
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_XM1014)
		{
			if(g_has_jh[attacker])
			SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_jh))
			
			if( !task_exists( victim + TASK_FBURN ) )
			{
				g_burning_duration[ victim ] += FIRE_DURATION * 5
				set_task( 0.1, "CTask__BurningFlame", victim + TASK_FBURN, _, _, "b" )
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
	
	if(equal(szTruncatedWeapon, "xm1014") && get_user_weapon(iAttacker) == CSW_XM1014)
	{
		if(g_has_jh[iAttacker])
			set_msg_arg_string(4, "xm1014")
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

public jh_ItemPostFrame(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_jh[id])
          return HAM_IGNORED

     static iAnim; iAnim = pev(id, pev_weaponanim)
     if(iAnim == jh_DRAW && g_has_jh[id])
     UTIL_PlayWeaponAnimation(id, jh_IDLE)

     static iClipExtra
     
     iClipExtra = get_pcvar_num(cvar_clip_jh)
     new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

     new iBpAmmo = cs_get_user_bpammo(id, CSW_XM1014)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

     if( fInReload && flNextAttack <= 0.0 )
     {
	     new j = min(iClipExtra - iClip, iBpAmmo)
	
	     set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
	     cs_set_user_bpammo(id, CSW_XM1014, iBpAmmo-j)
		
	     set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
	     fInReload = 0
     }
     return HAM_IGNORED
}

public jh_Reload(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_jh[id])
          return HAM_IGNORED

     static iClipExtra

     if(g_has_jh[id])
          iClipExtra = get_pcvar_num(cvar_clip_jh)

     g_jh_TmpClip[id] = -1

     new iBpAmmo = cs_get_user_bpammo(id, CSW_XM1014)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     if (iBpAmmo <= 0)
          return HAM_SUPERCEDE

     if (iClip >= iClipExtra)
          return HAM_SUPERCEDE

     g_jh_TmpClip[id] = iClip

     return HAM_IGNORED
}

public jh_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_jh[id])
		return HAM_IGNORED

	if (g_jh_TmpClip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, m_iClip, g_jh_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, jh_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, jh_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	UTIL_PlayWeaponAnimation(id, jh_RELOAD)

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

stock fm_set_user_health( index, health ) 
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index)

public CTask__BurningFlame( taskid )
{
	// Get player origin and flags
	static origin[3], flags
	get_user_origin(ID_FBURN, origin)
	flags = pev(ID_FBURN, pev_flags)
	
	// Madness mode - in water - burning stopped
	if ((flags & FL_INWATER) || g_burning_duration[ID_FBURN] < 1 || g_fRoundEnd || !is_user_alive(ID_FBURN))
	{
		// Smoke sprite
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_SMOKE) // TE id
		write_coord(origin[0]) // x
		write_coord(origin[1]) // y
		write_coord(origin[2]-50) // z
		write_short(g_smokeSpr) // sprite
		write_byte(random_num(15, 20)) // scale
		write_byte(random_num(10, 20)) // framerate
		message_end()
		
		// Task not needed anymore
		remove_task(taskid)
		return
	}
	
	// Get player's health
	static health
	health = pev(ID_FBURN, pev_health)
	
	// Take damage from the fire
	if (health - FIRE_DAMAGE > 0)
	fm_set_user_health(ID_FBURN, health - FIRE_DAMAGE)
	
	// Flame sprite
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_SPRITE) // TE id
	write_coord(origin[0]+random_num(-5, 5)) // x
	write_coord(origin[1]+random_num(-5, 5)) // y
	write_coord(origin[2]+random_num(-10, 10)) // z
	write_short(g_flameSpr) // sprite
	write_byte(random_num(5, 10)) // scale
	write_byte(200) // brightness
	message_end()

	g_burning_duration[ID_FBURN]--
}
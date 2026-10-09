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
#define arx160_WEAPONKEY 	19
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

#define arx160_RELOAD_TIME    2.4
#define arx160_SHOOT1			1
#define arx160_SHOOT2		  	2
#define arx160_SHOOT_EMPTY	3
#define arx160_RELOAD			4
#define arx160_DRAW			5

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

new const Fire_Sounds[][] = { "YouTuber/arx160_holy-1.wav" }
new const Sound_Zoom[] = { "weapons/zoom.wav" }

new arx160_V_MODEL[64] = "models/YouTuber/v_arx160_holy.mdl"
new arx160_P_MODEL[64] = "models/YouTuber/p_arx160_holy.mdl"
new arx160_W_MODEL[64] = "models/YouTuber/w_arx160_holy.mdl"

#define arx160_Body	0

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new const arx160_name[] = "weapon_arx160"

new const arx160_spr[][] = 
{ 
	"sprites/YouTuber/640hud97.spr", 
	"sprites/YouTuber/640hud7.spr"
}

new g_itemid_arx160
new cvar_dmg_arx160, cvar_recoil_arx160, cvar_clip_arx160, cvar_spd_arx160, cvar_arx160_ammo
new g_MaxPlayers, g_orig_event_arx160, g_IsInPrimaryAttack
new Float:cl_pushangle[MAX_PLAYERS + 1][3]
new g_has_arx160[33], g_clip_ammo[33], g_arx160_TmpClip[33], oldweap[33], g_hasZoom[33], Float:g_flNextUseTime[33], g_Reload[33]
new g_hamczbots, cvar_botquota
new gmsgWeaponList

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
	register_plugin("[ZP] Extra: Leader arx160", "1.0", "LARS-BLOODLIKER")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_galil", "fw_arx160_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
	if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil", "fw_arx160_PrimaryAttack")
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_galil", "fw_arx160_SecondaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil", "fw_arx160_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_galil", "arx160_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, "weapon_galil", "arx160_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_galil", "arx160_Reload_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Item_Holster, "weapon_galil", "fw_arx160_Holster_Post", 1)
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)

	cvar_dmg_arx160 = register_cvar("zp_arx160_dmg", "1.0")
	cvar_recoil_arx160 = register_cvar("zp_arx160_recoil", "0.9")
	cvar_clip_arx160 = register_cvar("zp_arx160_clip", "30")
	cvar_spd_arx160 = register_cvar("zp_arx160_spd", "1.2")
	cvar_arx160_ammo = register_cvar("zp_arx160_ammo", "180")
	
	g_itemid_arx160 = zp_register_extra_item("[A] \yArx160 Holy", 50, ZP_TEAM_HUMAN)
	g_MaxPlayers = get_maxplayers()
	cvar_botquota = get_cvar_pointer("bot_quota")
	gmsgWeaponList = get_user_msgid("WeaponList")
	register_clcmd(arx160_name, "command_arx160")
}

public plugin_precache()
{
	precache_model(arx160_V_MODEL)
	precache_model(arx160_P_MODEL)
	precache_model(arx160_W_MODEL)

	for(new i = 0; i < sizeof Fire_Sounds; i++)
	precache_sound(Fire_Sounds[i])
	precache_sound(Sound_Zoom)
	
	precache_sound("YouTuber/arx160_holy_draw.wav")
	precache_sound("YouTuber/arx160_holy_clipout.wav")
	precache_sound("YouTuber/arx160_holy_clipin.wav") 

	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)

	new sFile[64]
	formatex(sFile, charsmax(sFile), "sprites/%s.txt", arx160_name)
	precache_generic(sFile)
	
	for(new i = 0; i < sizeof(arx160_spr); i++)
	{
		precache_generic(arx160_spr[i])
	}
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_GALIL) return
	
	if(!g_has_arx160[iAttacker]) return

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

public command_arx160(Player)
{
	engclient_cmd(Player, "weapon_galil")
	return PLUGIN_HANDLED
}

public zp_user_humanized_post(id)
{
	g_has_arx160[id] = false
}

public plugin_natives ()
{
	register_native("give_weapon_arx160", "native_give_weapon_add", 1)
        register_native("get_weapon_arx160", "native_get_weapon_add", 1)
}
public native_give_weapon_add(id)
{
	give_arx160(id)
}
public native_get_weapon_add(id)
{
         return g_has_arx160[id]
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/galil.sc", name))
	{
		g_orig_event_arx160 = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_arx160[id] = false
}

public client_disconnect(id)
{
	g_has_arx160[id] = false
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_arx160[id] = false
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
	
	if(equal(model, "models/w_galil.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_galil", entity)
	
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED
	
		if(g_has_arx160[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, arx160_WEAPONKEY)
			
			g_has_arx160[iOwner] = false
			
			entity_set_model(entity, arx160_W_MODEL)

			set_pev(entity, pev_body, arx160_Body)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_arx160(id)
{
	drop_weapons(id, 1)
	new iWep2 = give_item(id,"weapon_galil")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_arx160))
		cs_set_user_bpammo (id, CSW_GALIL, get_pcvar_num(cvar_arx160_ammo))	
		UTIL_PlayWeaponAnimation(id, arx160_DRAW)
		set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)

		message_begin(MSG_ONE, gmsgWeaponList, _, id)
		write_string(arx160_name)
		write_byte(4)
		write_byte(90)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(17)
		write_byte(CSW_GALIL)
		message_end()
	}
	g_has_arx160[id] = true
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid != g_itemid_arx160)
		return

	give_arx160(id)
}

public fw_arx160_AddToPlayer(arx160, id)
{
	if(!is_valid_ent(arx160) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(arx160, EV_INT_WEAPONKEY) == arx160_WEAPONKEY)
	{
		g_has_arx160[id] = true
		
		entity_set_int(arx160, EV_INT_WEAPONKEY, 0)

		message_begin(MSG_ONE, gmsgWeaponList, _, id)
		write_string(arx160_name)
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
		message_begin(MSG_ONE, gmsgWeaponList, _, id)
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

     if(read_data(2) != CSW_GALIL || !g_has_arx160[id])
          return
     
     static Float:iSpeed
     if(g_has_arx160[id])
          iSpeed = get_pcvar_float(cvar_spd_arx160)
     
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
			
			if(g_has_arx160[id])
			{
				set_pev(id, pev_viewmodel2, arx160_V_MODEL)
				set_pev(id, pev_weaponmodel2, arx160_P_MODEL)
				if(oldweap[id] != CSW_GALIL) 
				{
					UTIL_PlayWeaponAnimation(id, arx160_DRAW)
					set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)

					message_begin(MSG_ONE, gmsgWeaponList, _, id)
					write_string(arx160_name)
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
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_GALIL || !g_has_arx160[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_arx160_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_arx160[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}
public fw_CmdStart(id, uc_handle, seed)
{
if(g_Reload[id])
  return PLUGIN_HANDLED
if(!is_user_alive(id))
  return PLUGIN_HANDLED

if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
{
  new szClip, szAmmo
  new szWeapID = get_user_weapon(id, szClip, szAmmo)
  if(szWeapID == CSW_GALIL && g_has_arx160[id] && !g_hasZoom[id] == true)
  {
   g_hasZoom[id] = true
   cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 0)
   emit_sound(id, CHAN_ITEM, Sound_Zoom, 0.20, 2.40, 0, 100)
  }
  else if(szWeapID == CSW_GALIL && g_has_arx160[id] && g_hasZoom[id])
  {
   g_hasZoom[id] = false
   cs_set_user_zoom(id, CS_RESET_ZOOM, 0)
  }
}
return PLUGIN_HANDLED
}
public fw_arx160_SecondaryAttack(Weapon)
{
   	new id = get_pdata_cbase(Weapon, 41, 4)

   	if(g_has_arx160[id])
      		return HAM_SUPERCEDE

   	return HAM_IGNORED
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_arx160) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_arx160_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!is_user_alive(Player))
		return

	if(g_has_arx160[Player])
	{
		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_arx160),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, random_num(arx160_SHOOT1, arx160_SHOOT2))

	}
}


public rem_ent( iEnt ) { remove_entity( iEnt ); }	

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_GALIL)
		{
			if(g_has_arx160[attacker])
				SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_arx160))
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
		if(g_has_arx160[iAttacker])
			set_msg_arg_string(4, "arx160")
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

public arx160_ItemPostFrame(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_arx160[id])
          return HAM_IGNORED

     static iClipExtra
     
     iClipExtra = get_pcvar_num(cvar_clip_arx160)
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

public arx160_Reload(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_arx160[id])
          return HAM_IGNORED

     static iClipExtra

     if(g_has_arx160[id])
          iClipExtra = get_pcvar_num(cvar_clip_arx160)

     g_arx160_TmpClip[id] = -1

     new iBpAmmo = cs_get_user_bpammo(id, CSW_GALIL)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     if (iBpAmmo <= 0)
          return HAM_SUPERCEDE

     if (iClip >= iClipExtra)
          return HAM_SUPERCEDE

     g_arx160_TmpClip[id] = iClip

     return HAM_IGNORED
}

public arx160_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_arx160[id])
		return HAM_IGNORED

	if (g_arx160_TmpClip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, m_iClip, g_arx160_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, arx160_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, arx160_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	UTIL_PlayWeaponAnimation(id, arx160_RELOAD)

	return HAM_IGNORED
}

public fw_arx160_Holster_Post(weapon_entity)
{
static Player
Player = get_pdata_cbase(weapon_entity, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)

g_flNextUseTime[Player] = 0.0
if(g_has_arx160[Player])
{
  cs_set_user_zoom(Player, CS_RESET_ZOOM, 1)
}
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
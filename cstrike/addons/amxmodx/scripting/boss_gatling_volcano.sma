#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>

#define AUTHOR          "Crock"
#define NAME            "Gatling Volcano"
#define VERSION         "1.0"

#define WEAPONSTR       "weapon_xm1014"
#define WEAPONSC        "events/xm1014.sc"
#define MODELV          "models/boss_weapons/v_gatling.mdl"
#define MODELP          "models/boss_weapons/p_gatling.mdl"
#define MODELW          "models/boss_weapons/w_gatling.mdl"
#define SOUNDFIRE       "boss_weapons/gatling_shoot.wav"
#define DMG             10.0
#define RECOIL          1.0
#define CLIP            40
#define AMMO            32

static g_orig_gat, g_IsInPrimaryAttack, Float:cl_pushangle[32 + 1][3] , g_has_gat[33], g_clip_ammo[33], g_gat_Tmpclip[33], oldweap[33];
new cvar_spd_gatling 

public plugin_init()
{
	register_plugin(NAME, VERSION, AUTHOR);
	
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg");
	register_event("CurWeapon","curw","be","1=1");
	
	RegisterHam(Ham_Weapon_PrimaryAttack, WEAPONSTR, "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, WEAPONSTR, "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Item_PostFrame, WEAPONSTR, "fwItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, WEAPONSTR, "fw_Reload");
	RegisterHam(Ham_Weapon_Reload, WEAPONSTR, "fw_Reload_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	RegisterHam(Ham_Item_AddToPlayer, WEAPONSTR, "fw_AddToPlayer");
	RegisterHam(Ham_Item_Deploy, WEAPONSTR, "fw_Item_Deploy_Post", 1);
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1);
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1);
	
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent");
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1);
	
	cvar_spd_gatling = register_cvar("zp_gat_spd", "1.0")
}

public plugin_precache()
{
	precache_model(MODELV)
	precache_model(MODELP)
	precache_model(MODELW)
	precache_sound(SOUNDFIRE)
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_XM1014) return
	
	if(!g_has_gat[iAttacker]) return

	static Float:End[3]
	get_tr2(ptr, TR_vecEndPos, End)
	
	if(iEnt)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DECAL)
		engfunc(EngFunc_WriteCoord, End[0]) 
		engfunc(EngFunc_WriteCoord, End[1])  
		engfunc(EngFunc_WriteCoord, End[2]) 
		write_byte(random_num(41,45))
		write_short(iEnt)
		message_end()
	}
	else
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, End[0]) 
		engfunc(EngFunc_WriteCoord, End[1])  
		engfunc(EngFunc_WriteCoord, End[2]) 
		write_byte(random_num(41,45))
		message_end()
	}
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_GUNSHOTDECAL)
	engfunc(EngFunc_WriteCoord, End[0])  
	engfunc(EngFunc_WriteCoord, End[1])  
	engfunc(EngFunc_WriteCoord, End[2]) 
	write_short(iAttacker)
	write_byte(random_num(41,45))
	message_end()
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
		
		iStoredAugID = find_ent_by_owner(-1, WEAPONSTR, entity)
	
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED
	
		if(g_has_gat[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_impulse, 8146)
			
			g_has_gat[iOwner] = false
			
			entity_set_model(entity, MODELW)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public plugin_natives() register_native("give_gatling", "get_gatling_volcano", 1)

public get_gatling_volcano(id)
{
	drop_weapons(id, 1);

	new iWep2 = give_item(id,WEAPONSTR)
	if( iWep2 > 0 )
	{
        cs_set_weapon_ammo(iWep2, CLIP)
        cs_set_user_bpammo (id, CSW_XM1014, AMMO)
        UTIL_PlayWeaponAnimation(id, 6)
        set_pdata_float(id, 83, 1.0, 5)
	}
	g_has_gat[id] = true
}

public fw_AddToPlayer(gat, id)
{
	if(!is_valid_ent(gat) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(gat, EV_INT_impulse) == 8146)
	{
		g_has_gat[id] = true
		
		entity_set_int(gat, EV_INT_impulse, 0)

		return HAM_HANDLED
	}
	return HAM_IGNORED
}

public fw_Item_Deploy_Post(weapon_ent)
{
	static owner
	owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	
	if (!pev_valid(owner))
    return;
	
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	
	replace_weapon_models(owner, weaponid)
}

public zp_user_humanized_post(id)
{
	g_has_gat[id] = false
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal(WEAPONSC, name))
	{
		g_orig_gat = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_gat[id] = false
}

public client_disconnect(id)
{
	g_has_gat[id] = false
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_gat[id] = false
	}
}


public curw(id)
{
     replace_weapon_models(id, read_data(2))

     if(read_data(2) != CSW_XM1014 || !g_has_gat[id])
          return
     
     static Float:iSpeed
     if(g_has_gat[id])
          iSpeed = get_pcvar_float(cvar_spd_gatling)
     
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
			
			if(g_has_gat[id])
			{
				set_pev(id, pev_viewmodel2, MODELV)
				set_pev(id, pev_weaponmodel2, MODELP)
				if(oldweap[id] != CSW_XM1014) 
				{
					UTIL_PlayWeaponAnimation(id, 6)
					set_pdata_float(id, 83, 1.0, 5)
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_XM1014 || !g_has_gat[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_PrimaryAttack(Weapon)
{
	if (!pev_valid(Weapon))
		return
		
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_gat[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_gat) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= 32))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!is_user_alive(Player))
		return

	if(g_has_gat[Player])
	{
		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push, RECOIL, push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		emit_sound(Player, CHAN_WEAPON, SOUNDFIRE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, random_num(1, 2))
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_XM1014)
		{
			if(g_has_gat[attacker])
				SetHamParamFloat(4, damage * DMG)
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
	
	if(equal(szTruncatedWeapon, "gatling") && get_user_weapon(iAttacker) == CSW_XM1014)
	{
		if(g_has_gat[iAttacker])
			set_msg_arg_string(4, "gatling")
	}
	return PLUGIN_CONTINUE
}

stock fm_cs_get_weapon_ent_owner(ent)
{
    if(pev_valid(ent) != 2)
    return -1;
	
    return get_pdata_cbase(ent, 41, 4)
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

public fwItemPostFrame(weapon_entity) 
{
     if (!pev_valid(weapon_entity))
     return HAM_IGNORED
	
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_gat[id])
          return HAM_IGNORED

     static iClipExtra
     
     iClipExtra = CLIP
     new Float:flNextAttack = get_pdata_float(id, 83, 5)

     new iBpAmmo = cs_get_user_bpammo(id, CSW_XM1014)
     new iClip = get_pdata_int(weapon_entity, 51, 4)

     new fInReload = get_pdata_int(weapon_entity, 54, 4) 

     if( fInReload && flNextAttack <= 0.0 )
     {
	     new j = min(iClipExtra - iClip, iBpAmmo)
	
	     set_pdata_int(weapon_entity, 51, iClip + j, 4)
	     cs_set_user_bpammo(id, CSW_XM1014, iBpAmmo-j)
		
	     set_pdata_int(weapon_entity, 54, 0, 4)
	     fInReload = 0
     }
     return HAM_IGNORED
}

public fw_Reload(weapon_entity) 
{
     if (pev_valid(weapon_entity) != 2)
     return HAM_IGNORED
		
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_gat[id])
          return HAM_IGNORED

     static iClipExtra

     if(g_has_gat[id])
          iClipExtra = CLIP

     g_gat_Tmpclip[id] = -1

     new iBpAmmo = cs_get_user_bpammo(id, CSW_XM1014)
     new iClip = get_pdata_int(weapon_entity, 51, 4)

     if (iBpAmmo <= 0)
          return HAM_SUPERCEDE

     if (iClip >= iClipExtra)
          return HAM_SUPERCEDE

     g_gat_Tmpclip[id] = iClip

     return HAM_IGNORED
}

public fw_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_gat[id])
		return HAM_IGNORED

	if (g_gat_Tmpclip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, 51, g_gat_Tmpclip[id], 4)

	set_pdata_float(weapon_entity, 48, 3.4, 4)

	set_pdata_float(id, 83, 3.4, 5)

	set_pdata_int(weapon_entity, 54, 1, 4)

	UTIL_PlayWeaponAnimation(id, 4)

	return HAM_IGNORED
}

stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid;
	num = 0;
	get_user_weapons(id, weapons, num);
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i];
		const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|
		(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)| (1<<CSW_M249)|(1<<CSW_M3)|
		(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90);
		if (dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		{
			static wname[32];
			get_weaponname(weaponid, wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname);
		}
	}
}
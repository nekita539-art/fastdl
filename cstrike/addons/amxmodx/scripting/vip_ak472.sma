#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <fun>
#include <xs>
#include <zombieplague>

const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4

#define WEAP_LINUX_XTRA_OFF		4
#define PLAYER_LINUX_XTRA_OFF	5
#define m_flNextAttack				83
#define m_iClip					51
#define m_fInReload				54
#define m_flTimeWeaponIdle			48
#define ENG_NULLENT				-1
#define EV_INT_WEAPONKEY		EV_INT_impulse
#define AK47GOLD_WEAPONKEY	        67854
#define MAX_PLAYERS  			  32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)


const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

new g_has_ak47_gold[33]
new g_ak47_gold_TmpClip[33]
new cvar_ak47_gold_dmg, cvar_ak47_gold_ammo, cvar_ak47_gold_clip, cvar_ak47_gold_spd

#define AK47GOLD_RELOAD_TIME 	2.5

new const AK47GOLD_V_MODEL[] = "models/vip_weapons/v_ak47gold.mdl"
new const AK47GOLD_P_MODEL[] = "models/vip_weapons/p_ak47gold.mdl"
new const AK47GOLD_W_MODEL[] = "models/vip_weapons/w_ak47gold.mdl"

public plugin_init()
{
	register_plugin("[ZP] Extra Item: AK47 Gold", "3.0", "4e/l")

	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_ak47", "fw_AK47GOLD_AddToPlayer")
	RegisterHam(Ham_Item_PostFrame, "weapon_ak47", "AK47GOLD__ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, "weapon_ak47", "AK47GOLD__Reload");
	RegisterHam(Ham_Weapon_Reload, "weapon_ak47", "AK47GOLD__Reload_Post", 1);
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)

	register_event("CurWeapon","CurrentWeapon","be","1=1")
	register_event("DeathMsg", "Death", "a")

        register_forward(FM_SetModel, "fw_SetModel")

	cvar_ak47_gold_clip = register_cvar("zp_ak47_gold_clip", "30")
        cvar_ak47_gold_ammo = register_cvar("zp_ak47_gold_ammo", "90")
	cvar_ak47_gold_dmg = register_cvar("zp_ak47_gold_dmg", "5.0")
	cvar_ak47_gold_spd = register_cvar("zp_ak47_gold_spd", "1.0")
}

public plugin_natives ()
{
	register_native("give_weapon_ak47gold", "gold", 1)
}

public gold(id)
{
	drop_weapons(id, 1);
	new iWep1 = give_item(id,"weapon_ak47")
	if( iWep1 > 0 )
	{
		cs_set_weapon_ammo(iWep1, get_pcvar_num(cvar_ak47_gold_clip))
		cs_set_user_bpammo (id, CSW_AK47, get_pcvar_num(cvar_ak47_gold_ammo))
	}
	g_has_ak47_gold[id] = true;
}	
public plugin_precache()
{
	precache_model(AK47GOLD_V_MODEL)
	precache_model(AK47GOLD_P_MODEL)
	precache_model(AK47GOLD_W_MODEL)
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
	static iWeapon; iWeapon = read_data(2)
	
	replace_weapon_models(id, read_data(2))
	
	static weapon[32], iEnt
	get_weaponname(iWeapon, weapon, 31)
	iEnt = find_ent_by_owner(-1, weapon, id)
	if(iEnt)
	{
		static Float:Delay, Float:M_Delay
		static Float:iSpeed
		iSpeed = 0.0
		if(iWeapon == CSW_AK47 && g_has_ak47_gold[id])
			iSpeed = get_pcvar_float(cvar_ak47_gold_spd)

		Delay = get_pdata_float(iEnt, 46, 4) * iSpeed
		M_Delay = get_pdata_float(iEnt, 47, 4) * iSpeed
		if (Delay > 0.0)
		{
			set_pdata_float(iEnt, 46, Delay, 4)
			set_pdata_float(iEnt, 47, M_Delay, 4)
		}
	}
}

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_AK47:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return;
			
			if(g_has_ak47_gold[id])
			{
				set_pev(id, pev_viewmodel2, AK47GOLD_V_MODEL)
				set_pev(id, pev_weaponmodel2, AK47GOLD_P_MODEL)
			}
		}
	}
}

public client_connect(id)
{
	g_has_ak47_gold[id] = false
}

public client_disconnect(id)
{
	g_has_ak47_gold[id] = false
}

public Death()
{
	g_has_ak47_gold[read_data(2)] = false
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
	g_has_ak47_gold[id] = false
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage) 
{ 
	if (victim != attacker && is_user_connected(attacker)) 
	{ 
		if(get_user_weapon(attacker) == CSW_AK47 && g_has_ak47_gold[attacker]) 
			SetHamParamFloat(4, damage * get_pcvar_float(cvar_ak47_gold_dmg)) 
	}
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
	
	if(equal(model, "models/w_ak47.mdl"))
	{
		static iStoredSVDID
		
		iStoredSVDID = find_ent_by_owner(ENG_NULLENT, "weapon_ak47", entity)
	
		if(!is_valid_ent(iStoredSVDID))
			return FMRES_IGNORED;
	
		if(g_has_ak47_gold[iOwner])
		{
			entity_set_int(iStoredSVDID, EV_INT_WEAPONKEY, AK47GOLD_WEAPONKEY)
			
			g_has_ak47_gold[iOwner] = false
			
			entity_set_model(entity, AK47GOLD_W_MODEL)
			set_pev(entity, pev_body, 2)
			
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public fw_AK47GOLD_AddToPlayer(AK47GOLD, id)
{
	if(!is_valid_ent(AK47GOLD) || !is_user_connected(id))
		return HAM_IGNORED;
	
	if(entity_get_int(AK47GOLD, EV_INT_WEAPONKEY) == AK47GOLD_WEAPONKEY)
	{
		g_has_ak47_gold[id] = true
		
		entity_set_int(AK47GOLD, EV_INT_WEAPONKEY, 0)
		
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
}

public message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
	
	if(equal(szTruncatedWeapon, "ak47") && get_user_weapon(iAttacker) == CSW_AK47)
	{
		if(g_has_ak47_gold[iAttacker])
			set_msg_arg_string(4, "ak47 gold")
	}

	return PLUGIN_CONTINUE
}

public AK47GOLD__ItemPostFrame(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_ak47_gold[id])
		return HAM_IGNORED;

	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	new iBpAmmo = cs_get_user_bpammo(id, CSW_AK47);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

	if( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(get_pcvar_num(cvar_ak47_gold_clip) - iClip, iBpAmmo)
	
		set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
		cs_set_user_bpammo(id, CSW_AK47, iBpAmmo-j);
		
		set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
		fInReload = 0
	}

	return HAM_IGNORED;
}

public AK47GOLD__Reload(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_ak47_gold[id])
		return HAM_IGNORED;

	g_ak47_gold_TmpClip[id] = -1;

	new iBpAmmo = cs_get_user_bpammo(id, CSW_AK47);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE;

	if (iClip >= get_pcvar_num(cvar_ak47_gold_clip))
		return HAM_SUPERCEDE;


	g_ak47_gold_TmpClip[id] = iClip;

	return HAM_IGNORED;
}

public AK47GOLD__Reload_Post(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_ak47_gold[id])
		return HAM_IGNORED;

	if (g_ak47_gold_TmpClip[id] == -1)
		return HAM_IGNORED;

	set_pdata_int(weapon_entity, m_iClip, g_ak47_gold_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, AK47GOLD_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, AK47GOLD_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	UTIL_PlayWeaponAnimation(id, 1)

	return HAM_IGNORED;
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
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

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}
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
#define m134_WEAPONKEY 		803
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

#define m134_RELOAD_TIME	5.0
#define m134_DRAW_TIME 		1.1
#define m134_SHOOT1			4
#define m134_RELOAD			2
#define m134_DRAW			1
#define m134_FIRE_READY		3
#define m134_FIRE_AFTER		5

#define UP_SCALE				-5.0    //ВВЕРХ
#define FORWARD_SCALE		7.5     //ВПЕРЕД
#define RIGHT_SCALE			5.5       //ВПРАВО
#define TE_BOUNCE_SHELL		1

new const BUYAMMO[] = 
{ 
	-1, 13,	//P228
	-1, 10, 	//SCOUT
	-1, 7,  	//XM1014
	-1, 30, 	//MAC10 
	30,    	//AUG
	-1, 30, 	//ELITE
	20, 		//FIVESEVEN
	25, 		//UMP45 
	30, 		//SG550
	35, 		//GALIL
	30, 		//FAMAS
	12, 		//USP
	20, 		//GLOCK18
	10, 		//AWP 
	30, 		//MP5NAVY
	200, 	//M249 		Должно быть равно = m134_CLIP
	8, 		//M3
	30, 		//M4A1
	30, 		//TMP
	20, 		//G3SG1
	-1, 7, 	//DEAGLE
	30, 		//SG552
	30, 		//AK47
	-1, 50 	//P90
}
new const MAXBPAMMO[] = 
{ 
	-1, 52, 	//P228
	-1, 90,  	//SCOUT
	1, 32,  	//XM1014
	1, 100, 	//MAC10 
	90, 		//AUG
	1, 120, 	//ELITE
	100, 	//FIVESEVEN
	100, 	//UMP45 
	90, 		//SG550
	90, 		//GALIL
	90, 		//FAMAS
	100, 	//USP
	120, 	//GLOSK18
	30, 		//AWP
	120, 	//MP5NAVY
	200, 	//M249 		Должно быть равно = m134_BPAMMO 
	32, 		//M3
	90, 		//M4A1
	120, 	//TMP
	90, 		//G3SG1
	2, 35, 	//DEAGLE
	90, 		//SG552
	90, 		//AK47
	-1, 100 	//P90
}

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

new const Fire_Sounds[][] = { "YouTuber/m134_legos-1.wav", "YouTuber/m134_legos-1.wav" }

new m134_s_V_MODEL[64] = "models/YouTuber/v_m134_legos.mdl"
new m134_V_MODEL[64] = "models/YouTuber/v_m134_legos.mdl"
new m134_P_MODEL[64] = "models/YouTuber/p_m134_legos.mdl"
new m134_W_MODEL[64] = "models/YouTuber/w_m134_legos.mdl"

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new const m134_name[] = "weapon_m134hero_zm7up.txt"

new const m134_spr[][] = 
{ 
	"sprites/YouTuber/640hud128.spr", 
	"sprites/YouTuber/640hud128.spr"
}

new cvar_dmg_m134, cvar_dmg_m134_survivor, cvar_recoil_m134, g_itemid_m134, cvar_clip_m134, cvar_spd_m134, cvar_m134_ammo, cvar_surv_m134, cvar_speedrun_m134, cvar_speedrunfire_m134 
new g_MaxPlayers, g_orig_event_m134, g_IsInPrimaryAttack
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_has_m134[33], g_clip_ammo[33], g_m134_TmpClip[33], oldweap[33], g_can[33], g_afterreload[33]
new g_hamczbots, cvar_botquota
new gmsgWeaponList
new gmsgAmmoPickup

new const AMMOID[] = 
{ 
	-1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10, 1, 10, 3, 5, 4, 10, 
	2, 11, 8, 4, 2, -1, 7 
}

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
	register_plugin("[ZP] Extra: M134", "1.0", "LARS-DAY[BR]EAKER")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m249", "fw_m134_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
	if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_m134_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_m134_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_m249", "m134_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, "weapon_m249", "m134_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_m249", "m134_Reload_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)

	cvar_dmg_m134 = register_cvar("zp_m134_dmg", "1.86")
	cvar_dmg_m134_survivor = register_cvar("zp_m134_dmg_survivor", "20.23")
	cvar_recoil_m134 = register_cvar("zp_m134_recoil", "0.1")
	cvar_clip_m134 = register_cvar("zp_m134_clip", "150")
	cvar_spd_m134 = register_cvar("zp_m134_spd", "0.75")
	cvar_m134_ammo = register_cvar("zp_m134_ammo", "200")
	cvar_surv_m134 = register_cvar("zp_m134_givesurvivor", "1")
	cvar_speedrunfire_m134 = register_cvar("zp_m134_speedrunfire", "240.0")
	cvar_speedrun_m134 = register_cvar("zp_m134_speedrun", "240.0")
	
	g_itemid_m134 = zp_register_extra_item("[П] \yM134 Lego", 200, ZP_TEAM_HUMAN)
	g_MaxPlayers = get_maxplayers()
	cvar_botquota = get_cvar_pointer("bot_quota")
	gmsgWeaponList = get_user_msgid("WeaponList")
	register_clcmd(m134_name, "command_m134")
	register_clcmd("buyammo1", "fw_BuyAmmo")
	register_clcmd("buyammo2", "fw_BuyAmmo")
	gmsgAmmoPickup = get_user_msgid("AmmoPickup")
}

public plugin_precache()
{
	precache_model(m134_s_V_MODEL)
	precache_model(m134_V_MODEL)
	precache_model(m134_P_MODEL)
	precache_model(m134_W_MODEL)
	for(new i = 0; i < sizeof Fire_Sounds; i++)
	precache_sound(Fire_Sounds[i])	
	precache_sound("YouTuber/m134_legos_clipoff.wav")
	precache_sound("YouTuber/m134_legos_clipon.wav")
	precache_sound("YouTuber/m134_legos_pinpull.wav")
  	precache_sound("YouTuber/m134_legos_spindown.wav")
  	precache_sound("YouTuber/m134_legos_spindown.wav")
	precache_sound("YouTuber/m134_legos_spinup.wav")
	precache_sound("YouTuber/m134_legos_spinup.wav")
	precache_sound("YouTuber/m134_legos_spinup.wav")
	precache_sound("YouTuber/m134_legos_spinup.wav")
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")

	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)

	new sFile[64]
	formatex(sFile, charsmax(sFile), "sprites/%s.txt", m134_name)
	precache_generic(sFile)
	
	for(new i = 0; i < sizeof(m134_spr); i++)
	{
		precache_generic(m134_spr[i])
	}
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_M249) return
	
	if(!g_has_m134[iAttacker]) return

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

public command_m134(Player)
{
	engclient_cmd(Player, "weapon_m249")
	return PLUGIN_HANDLED
}

public fw_BuyAmmo(Player)
{
	if(!is_user_alive(Player))
		return PLUGIN_CONTINUE
		
	if(!g_has_m134[Player])
		return PLUGIN_CONTINUE	
		
	static iAmmoPack; iAmmoPack = zp_get_user_ammo_packs(Player)
		
	static weapons[32], num, i, currentammo, weaponid, refilled
	num = 0
	refilled = false
	get_user_weapons(Player, weapons, num)
	
	for(i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		
		if(MAXBPAMMO[weaponid] > 2)
		{
			currentammo = cs_get_user_bpammo(Player, weaponid)
			
			if (currentammo < MAXBPAMMO[weaponid]-BUYAMMO[weaponid])
			{
				message_begin(MSG_ONE_UNRELIABLE, gmsgAmmoPickup, _, Player)
				write_byte(AMMOID[weaponid]) 
				write_byte(BUYAMMO[weaponid])
				message_end()
				
				cs_set_user_bpammo (Player, weaponid, currentammo + BUYAMMO[weaponid])
				
				refilled = true
			}
			else if (currentammo < MAXBPAMMO[weaponid])
			{
				message_begin(MSG_ONE_UNRELIABLE, gmsgAmmoPickup, _, Player)
				write_byte(AMMOID[weaponid])
				write_byte(MAXBPAMMO[weaponid]-currentammo)
				message_end()
				
				cs_set_user_bpammo (Player, weaponid, MAXBPAMMO[weaponid])
				
				refilled = true
			}
		}
	}
	if (!refilled) return PLUGIN_HANDLED
	
	zp_set_user_ammo_packs(Player, --iAmmoPack)
	engfunc(EngFunc_EmitSound, Player, CHAN_ITEM, "items/9mmclip1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	client_print(Player, print_chat, "[ZP] You purchased extra ammo for your guns.")
	
	return PLUGIN_HANDLED	
}

public zp_user_humanized_post(id, surv)
{
	g_has_m134[id] = false
	if(surv && get_pcvar_num(cvar_surv_m134)) give_m134(id)
}

public plugin_natives ()
{
	register_native("give_weapon_m134", "native_give_weapon_add", 1)
}
public native_give_weapon_add(id)
{
	give_m134(id)
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/m249.sc", name))
	{
		g_orig_event_m134 = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_m134[id] = false
}

public client_disconnect(id)
{
	g_has_m134[id] = false
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_m134[id] = false
	}
}

public user_can(id) 
{
	g_can[id] = 2
}

public user_can2(id) 
{
	g_can[id] = 0
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
	
	if(equal(model, "models/w_m249.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_m249", entity)
	
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED
	
		if(g_has_m134[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, m134_WEAPONKEY)
			
			g_has_m134[iOwner] = false
			
			entity_set_model(entity, m134_W_MODEL)

			set_pev(entity, pev_body, 29)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_m134(id)
{
	drop_weapons(id, 1)
	new iWep2 = give_item(id,"weapon_m249")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_m134))
		cs_set_user_bpammo (id, CSW_M249, get_pcvar_num(cvar_m134_ammo))	
		UTIL_PlayWeaponAnimation(id, m134_DRAW)
		set_pdata_float(id, m_flNextAttack, m134_DRAW_TIME, PLAYER_LINUX_XTRA_OFF)

		message_begin(MSG_ONE, gmsgWeaponList, _, id)
		write_string(m134_name)
		write_byte(3)
		write_byte(200)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(4)
		write_byte(CSW_M249)
		message_end()
	}
	g_has_m134[id] = true
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid != g_itemid_m134)
		return

	give_m134(id)
}

public fw_m134_AddToPlayer(m134, id)
{
	if(!is_valid_ent(m134) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(m134, EV_INT_WEAPONKEY) == m134_WEAPONKEY)
	{
		g_has_m134[id] = true
		
		entity_set_int(m134, EV_INT_WEAPONKEY, 0)

		message_begin(MSG_ONE, gmsgWeaponList, _, id)
		write_string(m134_name)
		write_byte(3)
		write_byte(200)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(4)
		write_byte(CSW_M249)
		message_end()
		
		return HAM_HANDLED
	}
	else
	{
		message_begin(MSG_ONE, gmsgWeaponList, _, id)
		write_string("weapon_m249")
		write_byte(3)
		write_byte(200)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(4)
		write_byte(CSW_M249)
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

     if(read_data(2) != CSW_M249 || !g_has_m134[id])
          return
     
     static Float:iSpeed
     if(g_has_m134[id])
          iSpeed = get_pcvar_float(cvar_spd_m134)
     
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
		case CSW_M249:
		{
			if (zp_get_user_zombie(id))
				return
			
			if(g_has_m134[id])
			{
				if(zp_get_user_survivor(id)) 
					set_pev(id, pev_viewmodel2, m134_s_V_MODEL)
				else
					set_pev(id, pev_viewmodel2, m134_V_MODEL)

				set_pev(id, pev_weaponmodel2, m134_P_MODEL)
	
				message_begin(MSG_ONE, get_user_msgid("CurWeapon"), {0,0,0}, id) 
				write_byte(1) 
				write_byte(CSW_KNIFE) 
				write_byte(0) 
				message_end()

				if(oldweap[id] != CSW_M249) 
				{
					UTIL_PlayWeaponAnimation(id, m134_DRAW)
					set_pdata_float(id, m_flNextAttack, m134_DRAW_TIME, PLAYER_LINUX_XTRA_OFF)

					message_begin(MSG_ONE, gmsgWeaponList, _, id)
					write_string(m134_name)
					write_byte(3)
					write_byte(200)
					write_byte(-1)
					write_byte(-1)
					write_byte(0)
					write_byte(4)
					write_byte(CSW_M249)
					message_end()
				}
			}
		}
	}
	if(weaponid != CSW_M249)
	{
		remove_task(id)
		g_can[id] = 0
		g_afterreload[id] = 0
		if(oldweap[id] == CSW_M249 && g_has_m134[id]) 
		{
			message_begin(MSG_ONE, get_user_msgid("CurWeapon"), {0,0,0}, id) 
			write_byte(1) 
			write_byte(CSW_KNIFE) 
			write_byte(0) 
			message_end()
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_M249 || !g_has_m134[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id) || get_user_weapon(id) != CSW_M249 || !g_has_m134[id]) 
		return PLUGIN_HANDLED

	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	if(flNextAttack > 0.0)
		return PLUGIN_HANDLED

	new szClip, szAmmo
	get_user_weapon(id, szClip, szAmmo)

	if(szClip <= 0)
		return PLUGIN_HANDLED

	if(!(pev(id, pev_oldbuttons) & IN_ATTACK))
	{
		remove_task(id)
		set_pdata_float(id, m_flNextAttack, 0.0, PLAYER_LINUX_XTRA_OFF)
		g_can[id] = 0
	}
	if((pev(id, pev_oldbuttons) & IN_ATTACK) && !(get_uc(uc_handle, UC_Buttons) & IN_ATTACK))
	{
		remove_task(id)
		set_task(1.0,"user_can2",id)
		g_can[id] = 3
		set_pdata_float(id, m_flNextAttack, m134_DRAW_TIME, PLAYER_LINUX_XTRA_OFF)
		UTIL_PlayWeaponAnimation(id,m134_FIRE_AFTER)
		g_can[id] = 0
	}
	return PLUGIN_HANDLED
}

public fw_m134_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_m134[Player])
		return HAM_IGNORED

	g_IsInPrimaryAttack = 1

	if(g_afterreload[Player])
	{
		g_afterreload[Player] = 0
		return HAM_SUPERCEDE
	}
	new Float:flNextAttack = get_pdata_float(Player, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	if(flNextAttack > 0.0)
		return HAM_IGNORED

	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)

	if(!g_can[Player] || g_can[Player] == 3)
	{
		if(szClip <= 0)
		{
			UTIL_PlayWeaponAnimation(Player,m134_FIRE_AFTER)
			set_pdata_float(Player, m_flNextAttack, m134_DRAW_TIME, PLAYER_LINUX_XTRA_OFF)
			return HAM_SUPERCEDE
		}
		set_task(1.0,"user_can",Player)
		g_can[Player] = 1
		set_pdata_float(Player, m_flNextAttack, 1.1, PLAYER_LINUX_XTRA_OFF)
		UTIL_PlayWeaponAnimation(Player,m134_FIRE_READY)
		return HAM_SUPERCEDE
	}
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)

	return HAM_IGNORED
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_m134) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_m134_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if(!is_user_alive(Player))
		return

	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)

	if(g_has_m134[Player])
	{
		if(g_can[Player] != 2)
			return

		if(szClip <= 0)
		{
			UTIL_PlayWeaponAnimation(Player,m134_FIRE_AFTER)
			set_pdata_float(Player, m_flNextAttack, m134_DRAW_TIME, PLAYER_LINUX_XTRA_OFF)
		}

		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_m134),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		random_num(emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM),emit_sound(Player, CHAN_WEAPON, Fire_Sounds[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM))
		UTIL_PlayWeaponAnimation(Player, m134_SHOOT1)

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
		if(get_user_weapon(attacker) == CSW_M249)
		{
			if(g_has_m134[attacker])
			{
				if(zp_get_user_survivor(attacker))
				{
					SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_m134_survivor))
				}else {
					SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_m134))
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
	
	if(equal(szTruncatedWeapon, "m249") && get_user_weapon(iAttacker) == CSW_M249)
	{
		if(g_has_m134[iAttacker])
			set_msg_arg_string(4, "m249")
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

public m134_ItemPostFrame(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_m134[id])
          return HAM_IGNORED

     new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

     new iBpAmmo = cs_get_user_bpammo(id, CSW_M249)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

     if( fInReload && flNextAttack <= 0.0 )
     {
	     new j = min(get_pcvar_num(cvar_clip_m134) - iClip, iBpAmmo)
	
	     set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
	     cs_set_user_bpammo(id, CSW_M249, iBpAmmo-j)
		
	     set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
	     fInReload = 0
	     g_can[id] = 0
     }
     return HAM_IGNORED
}

public m134_Reload(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_m134[id])
          return HAM_IGNORED

     g_m134_TmpClip[id] = -1

     new iBpAmmo = cs_get_user_bpammo(id, CSW_M249)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     if (iBpAmmo <= 0)
          return HAM_SUPERCEDE

     if (iClip >= get_pcvar_num(cvar_clip_m134))
          return HAM_SUPERCEDE

     g_m134_TmpClip[id] = iClip

     return HAM_IGNORED
}

public m134_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_m134[id])
		return HAM_IGNORED

	if(zp_get_user_survivor(id) && get_pcvar_num(cvar_surv_m134))
		return HAM_SUPERCEDE

	new szClip, szAmmo
	get_user_weapon(id, szClip, szAmmo)

	if (szClip == get_pcvar_num(cvar_clip_m134))
		return HAM_IGNORED

	if (szAmmo <= 0)
		return HAM_IGNORED

	if (g_m134_TmpClip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, m_iClip, g_m134_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, m134_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, m134_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	UTIL_PlayWeaponAnimation(id, m134_RELOAD)

	remove_task(id)
	g_can[id] = 0
	g_afterreload[id] = 1

	return HAM_IGNORED
}

public client_PreThink(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !g_has_m134[id] || get_user_weapon(id) != CSW_M249)
		return

	new szClip, szAmmo
	get_user_weapon(id, szClip, szAmmo)

	if(szClip <= 0 && szAmmo <= 0)
		g_can[id] = 0

	set_hudmessage(200, 80, 0, 1.0, 0.98, 0, 0.1, 0.1,0.0,0.0)
	show_hudmessage(id, "Ammo: %d / %d",szClip,szAmmo)
}

public fw_PlayerPreThink(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !g_has_m134[id] || get_user_weapon(id) != CSW_M249)
		return

	new szClip
	get_user_weapon(id, szClip)

	if(g_can[id]) set_pev(id, pev_maxspeed, get_pcvar_float(cvar_speedrunfire_m134))
	if(!g_can[id] || szClip <= 0) set_pev(id, pev_maxspeed, get_pcvar_float(cvar_speedrun_m134))
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/

#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>

#define WEAPON_NUMBER	6079

#define TIME_RELOAD		5.0
#define TIME_DRAW		1.0

#define ANIM_SHOOT		1
#define ANIM_SHOOT_END	6
#define ANIM_RELOAD		3
#define ANIM_DRAW		4

#define CLIP		100
#define AMMO		200

#define DAMAGE		250.0

#define SHOOT_SOUND		"admin_weapons/airburster_shoot.wav"
#define SHOOT_END_SOUND	"admin_weapons/airburster_shoot_end.wav"

#define VIEW_MODEL		"models/admin_weapons/v_airbuster.mdl"
#define PLAYER_MODEL	"models/admin_weapons/p_airbuster.mdl"
#define WORLD_MODEL		"models/admin_weapons/w_airbuster.mdl"

#define SPECIAL_MODEL	"sprites/Reega_kz/ef_aircyclone.spr"

new g_itemid, g_has_poisongun[33], g_clipammo[33], g_orig_event_m249, g_m249_variables[10]

const WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_MP5NAVY)|(1<<CSW_UMP45)|(1<<CSW_G3SG1)|(1<<CSW_AUG)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_M249)|(1<<CSW_P90)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_GALIL)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_FAMAS)

public plugin_init()
{
	register_plugin("[ZP] Extra Item: DOMESTOS", "1.0", "BlackCat")
	
	register_message(get_user_msgid("WeapPickup"), "message_weappickup")
	
	register_forward(FM_SetModel, "fm_setmodel")
	register_forward(FM_UpdateClientData, "fm_updateclientdata_post", 1)
	register_forward(FM_PlaybackEvent, "fm_playbackevent")
	register_forward(FM_CmdStart, "fm_cmdstart")
	
	register_touch("poisongun", "*", "touch_poisongun_grenade")
	register_think("poisongun", "fw_think")

	RegisterHam(Ham_Item_AddToPlayer, "weapon_m249", "ham_item_addtoplayer")
	RegisterHam(Ham_Item_Deploy, "weapon_m249", "ham_item_deploy_post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_m249", "ham_item_postframe")

	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "ham_weapon_primaryattack")
	RegisterHam(Ham_Weapon_Reload, "weapon_m249", "ham_weapon_reload_post", 1)
}

public plugin_precache()
{
	precache_model(VIEW_MODEL)
	precache_model(PLAYER_MODEL)
	precache_model(WORLD_MODEL)
	precache_model(SPECIAL_MODEL)

	precache_sound(SHOOT_SOUND)
	precache_sound(SHOOT_END_SOUND)	

	precache_generic("sprites/Reega_kz/640hud60.spr")
	precache_generic("sprites/Reega_kz/640hud7.spr")
	precache_generic("sprites/weapon_salam_m134.txt")

	register_clcmd("weapon_salam_m134", "clcmd_weapon_salam_m134")
	register_message(78, "message_weaponlist")
	register_forward(FM_PrecacheEvent, "fm_precacheevent_post", 1)
}

public client_connect(id) 
{
	g_has_poisongun[id] = false
}

public zp_user_infected_post(id) 
{
	g_has_poisongun[id] = false
}

public zp_extra_item_selected(id, itemid) 
{
	if(itemid != g_itemid) 
		return
		
	give_poisongun(id)
}

public plugin_natives ()
{
	register_native("give_weapon_domestos", "native_give_weapon_add", 1)
}
public native_give_weapon_add(id)
{
	give_poisongun(id)
}

public give_poisongun(id)
{
	drop_weapons(id, 1)
	
	g_has_poisongun[id] = true
	
	new weapon = give_item(id, "weapon_m249")
	
	if(weapon > 0)
	{
		cs_set_weapon_ammo(weapon, CLIP)
		cs_set_user_bpammo(id, CSW_M249, AMMO)
	}

	ExecuteHam(Ham_Item_Deploy, id)
}

public fm_precacheevent_post(type, const name[])
{
	if(!equal("events/m249.sc", name))
		return FMRES_IGNORED
		
	g_orig_event_m249 = get_orig_retval()	
	return FMRES_HANDLED
}

public fm_setmodel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED

	static id, Ent
	id = entity_get_edict(entity, EV_ENT_owner)
	Ent = find_ent_by_owner(-1, "weapon_m249", entity)

	if(!equal(model, "models/w_m249.mdl") || !is_valid_ent(Ent) || !g_has_poisongun[id])
		return FMRES_IGNORED

	entity_set_int(Ent, EV_INT_impulse, WEAPON_NUMBER)

	entity_set_model(entity, WORLD_MODEL)

	set_pev(entity, pev_body, 17)	

	g_has_poisongun[id] = false

	return FMRES_SUPERCEDE
}

public fm_updateclientdata_post(id, SendWeapons, CD_Handle)
{
	if(!is_user_alive(id) || get_user_weapon(id) != CSW_M249 || !g_has_poisongun[id])
		return FMRES_IGNORED

	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fm_playbackevent(flags, id, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (eventid != g_orig_event_m249 || !is_user_connected(id))
		return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, id, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fm_cmdstart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || get_user_weapon(id) != CSW_M249 || !g_has_poisongun[id])
		return FMRES_IGNORED

	if(get_pdata_float(id, 83, 5) > 0.0) 
		return FMRES_IGNORED

	if((pev(id, pev_oldbuttons) & IN_ATTACK) && !(get_uc(uc_handle, UC_Buttons) & IN_ATTACK))
	{
		play_weapon_animation(id, ANIM_SHOOT_END)
		
		emit_sound(id, CHAN_WEAPON, SHOOT_END_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		
		set_pdata_float(find_ent_by_owner(-1, "weapon_m249", id), 48, 3.0, 4)
	}

	return FMRES_IGNORED
}

public message_weappickup(msg_id, msg_dest, id)
{
	if(get_msg_arg_int(1) != CSW_M249 || !g_has_poisongun[id])
		return PLUGIN_CONTINUE

	set_weaplist(id, "weapon_salam_m134")
	return PLUGIN_CONTINUE
}

public message_weaponlist(msg_id, msg_dest, id)
{
	if(get_msg_arg_int(8) != CSW_M249)
		return PLUGIN_CONTINUE
	
	g_m249_variables[2] = get_msg_arg_int(2)
	g_m249_variables[3] = get_msg_arg_int(3)
	g_m249_variables[4] = get_msg_arg_int(4)
	g_m249_variables[5] = get_msg_arg_int(5)
	g_m249_variables[6] = get_msg_arg_int(6)
	g_m249_variables[7] = get_msg_arg_int(7)
	g_m249_variables[8] = get_msg_arg_int(8)
	g_m249_variables[9] = get_msg_arg_int(9)
	return PLUGIN_CONTINUE
}

public set_weaplist(index, const string_msg[])
{
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), {0,0,0}, index)
	write_string(string_msg) 
	write_byte(g_m249_variables[2])
	write_byte(g_m249_variables[3])
	write_byte(g_m249_variables[4])
	write_byte(g_m249_variables[5])
	write_byte(g_m249_variables[6])
	write_byte(g_m249_variables[7])
	write_byte(g_m249_variables[8])
	write_byte(g_m249_variables[9])
	message_end()
}

public clcmd_weapon_salam_m134(index)
{ 
	engclient_cmd(index, "weapon_m249")
	return PLUGIN_HANDLED
}

public ham_item_addtoplayer(entity, id)
{
	if(entity_get_int(entity, EV_INT_impulse) != WEAPON_NUMBER)
	{
		set_weaplist(id, "weapon_m249")
		return HAM_IGNORED
	}

	entity_set_int(entity, EV_INT_impulse, 0)

	g_has_poisongun[id] = true

	return HAM_HANDLED
}

public ham_item_deploy_post(weapon_ent)
{
	static id; id = get_pdata_cbase(weapon_ent, 41, 4)
	
	if(!is_user_connected(id) || !g_has_poisongun[id])
		return HAM_IGNORED

	set_pev(id, pev_viewmodel2, VIEW_MODEL)
	set_pev(id, pev_weaponmodel2, PLAYER_MODEL)

	play_weapon_animation(id, ANIM_DRAW)
	set_pdata_float(id, 83, TIME_DRAW, 5)

	return HAM_IGNORED
}

public ham_item_postframe(weapon_entity)
{
	new id; id = pev(weapon_entity, pev_owner)
	
	if (!is_user_connected(id) || !g_has_poisongun[id])
		return HAM_IGNORED

	new Float:flNextAttack = get_pdata_float(id, 83, 5)
	new iBpAmmo = cs_get_user_bpammo(id, CSW_M249)
	new iClip = get_pdata_int(weapon_entity, 51, 4)
	new g_reload = get_pdata_int(weapon_entity, 54, 4) 

	if(g_reload && flNextAttack <= 0.0)
	{
		new j = min(CLIP - iClip, iBpAmmo)

		set_pdata_int(weapon_entity, 51, iClip + j, 4)
		cs_set_user_bpammo(id, CSW_M249, iBpAmmo - j)
		
		set_pdata_int(weapon_entity, 54, 0, 4)
		g_reload = 0
	}
	
	return HAM_HANDLED
}

public ham_weapon_primaryattack(weapon_entity)
{
	new id = get_pdata_cbase(weapon_entity, 41, 4)
	new flags = pev(id, pev_flags)
	new waterlvl = pev(id, pev_waterlevel)
	
	if (!g_has_poisongun[id] || ((flags & FL_INWATER) && waterlvl > 1))
		return HAM_IGNORED
		
	if(!get_pdata_int(weapon_entity, 51, 4))
	{
		ExecuteHam(Ham_Weapon_Reload, weapon_entity)
		ham_weapon_reload_post(weapon_entity)
		return HAM_SUPERCEDE
	}

	g_clipammo[id] = cs_get_weapon_ammo(weapon_entity)

	emit_sound(id, CHAN_WEAPON, SHOOT_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	play_weapon_animation(id, ANIM_SHOOT) 

	make_grenade(id)

	set_pdata_float(weapon_entity, 46, 0.1, 4)

	set_pdata_int(weapon_entity, 51, get_pdata_int(weapon_entity, 51, 4) - 1, 4)

	set_pev(id, pev_punchangle, {0.0, 0.0, 0.0})

	static Float:flOrigin[3]
	pev(id, pev_origin, flOrigin)

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0)
 	write_byte(TE_DLIGHT)
 	engfunc(EngFunc_WriteCoord, flOrigin[0])
 	engfunc(EngFunc_WriteCoord, flOrigin[1])
 	engfunc(EngFunc_WriteCoord, flOrigin[2])
 	write_byte(15)
 	write_byte(0)
 	write_byte(0)
 	write_byte(255)
 	write_byte(150)
 	write_byte(30)
 	write_byte(20)
 	message_end()
	
	return HAM_SUPERCEDE
}

public ham_weapon_reload_post(weapon_entity)
{
	new id = pev(weapon_entity, pev_owner)
	
	if (!is_user_connected(id) || !g_has_poisongun[id])
		return HAM_IGNORED
		
	new iBpAmmo = cs_get_user_bpammo(id, CSW_M249)
	new iClip = get_pdata_int(weapon_entity, 51, 4)

	if (!iBpAmmo || iClip >= CLIP)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, 54, 1, 4)
	
	set_pdata_float(weapon_entity, 48, TIME_RELOAD, 4)
	set_pdata_float(id, 83, TIME_RELOAD, 5)

	play_weapon_animation(id, ANIM_RELOAD)

	return HAM_IGNORED
}

stock play_weapon_animation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)

	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

stock drop_weapons(id, dropwhat)
{
	static weapons[32], wname[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)

	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]

		if (dropwhat == 1 && ((1<<weaponid) & WEAPONS_BIT_SUM))
		{
			get_weaponname(weaponid, wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock return_has_weapon(id, const findstring[])
{
	static weapons[32], wname[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		get_weaponname(weaponid, wname, sizeof wname - 1)
		
		if(equal(wname, findstring)) 
			return 1;
	}
	return 0;
}

public make_grenade(id)
{
	new Float:fAngle[3], Float:fVelocity[3]
	pev(id, pev_v_angle, fAngle)
	
	new grenade = create_entity("info_target")
	
	if (!grenade) 
		return PLUGIN_HANDLED
	
	entity_set_string(grenade, EV_SZ_classname, "poisongun")
	
	entity_set_model(grenade, SPECIAL_MODEL)

	new  Float:upScale, Float:fwScale, Float:rgScale, Player
	upScale = -5.0,
	fwScale = 20.0
	rgScale = 4.0
	Player = id
	
	static Float:vPunchAngle[ 3 ], Float:vAngle[ 3 ], xol
	xol = 1 + 2
   
	if( xol & 1 )   
		pev( Player, pev_v_angle, vAngle )
	   
	if( xol & 2 )
		pev( Player, pev_punchangle, vPunchAngle )
   
	xs_vec_add(vAngle, vPunchAngle, vAngle)
	engfunc( EngFunc_MakeVectors, vAngle );
   
	static Float:vVel[ 3 ], Float:vOrigin[ 3 ], Float:vViewOfs[ 3 ],
	i, Float:vRight[ 3 ],
	Float:vUp[ 3 ], Float:vForward[ 3 ];
	pev( Player, pev_velocity, vVel );
	pev( Player, pev_view_ofs, vViewOfs );
	pev( Player, pev_angles, vAngle );
	pev( Player, pev_origin, vOrigin );
	global_get( glb_v_right, vRight );
	global_get( glb_v_up, vUp );
	global_get( glb_v_forward, vForward );
   
	for( i = 0; i < 3; i++ )
	{
		vOrigin[i] = vOrigin[ i ] + vViewOfs[ i ] + vUp[ i ] * upScale + vForward[i] * fwScale + vRight[ i ] * rgScale;
	}

	entity_set_origin(grenade, vOrigin)
	entity_set_vector(grenade, EV_VEC_angles, fAngle)
	entity_set_size(grenade, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0})
	fm_set_rendering(grenade, kRenderFxNoDissipation, 255, 255, 255, kRenderGlow, 255)
	set_pev(grenade, pev_scale, 0.2)
	entity_set_int(grenade, EV_INT_solid, SOLID_BBOX)
	entity_set_int(grenade, EV_INT_movetype, MOVETYPE_FLY)
	
	entity_set_edict(grenade, EV_ENT_owner, id)

	VelocityByAim(id, 850, fVelocity)
	
	entity_set_vector(grenade, EV_VEC_velocity, fVelocity)
	
	set_pev(grenade, pev_nextthink, get_gametime())
	
	return PLUGIN_HANDLED
}



public fw_think(iEnt)
{
	if (!pev_valid(iEnt)) 
		return

	set_pev(iEnt, pev_nextthink, get_gametime()+0.015)
	
	new Float:fFrame, Float:scale
	pev(iEnt, pev_frame, fFrame)
	pev(iEnt, pev_scale, scale)
	
	//Explode
	if (pev(iEnt, pev_movetype) == MOVETYPE_NONE)
	{
		fFrame += 0.65 
		
		if(scale <= 1.5)
			scale += 0.01
		
		if (fFrame > 21.0)
		{ 
			engfunc(EngFunc_RemoveEntity, iEnt)
			return
		}
	}
	// Flying
	else
	{
		fFrame += 0.8
		
		if( fFrame >= 21.0)
			set_pev(iEnt, pev_movetype, MOVETYPE_NONE)
		
		if(scale <= 1.5)
			scale += 0.05
	}
	
	set_pev(iEnt, pev_scale, scale)
	set_pev(iEnt, pev_frame, fFrame)
}

public touch_poisongun_grenade(ent, touched) 
{
	if (!pev_valid(ent))
		return PLUGIN_HANDLED
		
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_solid, SOLID_NOT)
	
	new owner=pev(ent, pev_owner)
	
	new Float:Origin[3], victim
	
	pev(ent, pev_origin, Origin)
	
	while((victim=fm_find_ent_in_sphere(victim, Origin, 20.0))!=0)
	{	
		if(pev(victim, pev_takedamage)!=DAMAGE_NO&&pev(victim, pev_solid)!=SOLID_NOT)
		{
			if(is_user_alive(victim))
			{
				if(zp_get_user_zombie(victim))
				{
					ExecuteHamB(Ham_TakeDamage, victim, ent, owner, DAMAGE, DMG_BURN)
					
					set_pdata_int(victim, 75, HIT_GENERIC)
				}
			}
			else
				ExecuteHamB( Ham_TakeDamage, victim, ent, owner, DAMAGE, DMG_BURN)
		}
	}
	return PLUGIN_HANDLED
}

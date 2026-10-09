#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>

#define PLUGIN "[ZP] Weapon: AK47 [Balrog Edition]"
#define VERSION "1.0"
#define AUTHOR "texas1k" 

#define V_MODEL "models/vip_weapons/v_ak47balrog.mdl"
#define P_MODEL "models/vip_weapons/p_ak47balrog.mdl"
#define W_MODEL "models/vip_weapons/w_ak47balrog.mdl"

#define DAMAGE 90
#define CLIP 40
#define BPAMMO 240
#define RECOIL 0.4
#define ACTIVE_CLIP 20

#define CSW_AK47B CSW_AK47
#define weapon_ak47b "weapon_ak47"

#define WEAPON_SECRETCODE 20151
#define WEAPON_EVENT "events/ak47.sc"
#define OLD_W_MODEL "models/w_ak47.mdl"

#define EXP_SPR "sprites/balrog5stack.spr"

new const AK47B_Sounds[4][] =
{
	"vip_weapons/balrogak47_1.wav",
	"vip_weapons/balrogak47_clipin.wav",
	"vip_weapons/balrogak47_clipout.wav",
	"vip_weapons/balrogak47_draw.wav"
}

enum
{
	ANIM_IDLE1 = 0,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT3,
	ANIM_SHOOTBCS1,
	ANIM_SHOOTBCS2
}

new g_Ak47b
new g_Had_Ak47b[33], g_Shoot_Special[33], g_Holding_Attack[33], g_Shoot_Count[33], g_Old_Weapon[33], g_Current_Weapon[33]
new g_Exp_SprId, g_Ak47b_Event, g_ShellId, g_SmokePuff_SprId

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_CmdStart, "fw_CmdStart")		
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_ak47b, "fw_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_ak47b, "fw_Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_AddToPlayer, weapon_ak47b, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_ak47b, "fw_Item_PostFrame")
	
	//register_clcmd("admin_get_ak47b", "Get_Ak47b", ADMIN_BAN)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	
	for(new i = 0; i < sizeof(AK47B_Sounds); i++)
		engfunc(EngFunc_PrecacheSound, AK47B_Sounds[i])
		
	g_Exp_SprId = engfunc(EngFunc_PrecacheModel, EXP_SPR)
	g_SmokePuff_SprId = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	g_ShellId = engfunc(EngFunc_PrecacheModel, "models/pshell.mdl")
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	//g_Ak47b = zp_register_extra_item("AK47 [Balrog Edition]", 35, ZP_TEAM_HUMAN)
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(WEAPON_EVENT, name))
		g_Ak47b_Event = get_orig_retval()		
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_Ak47b) Get_Ak47b(id)
}

public zp_user_infected_post(id) Remove_Ak47b(id)
public zp_user_humanized_post(id) Remove_Ak47b(id)

public plugin_natives ()
{
	register_native("give_vip_ak47balrog", "Get_Ak47b", 1)
}

public Get_Ak47b(id)
{
	if(!is_user_alive(id))
		return
		
	g_Had_Ak47b[id] = 1
	g_Shoot_Special[id] = 0
	g_Holding_Attack[id] = 0
	g_Shoot_Count[id] = 0
	
	fm_give_item(id, weapon_ak47b)
	
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_AK47B)
	if(!pev_valid(Ent)) return
	
	cs_set_weapon_ammo(Ent, CLIP)
	
	cs_set_user_bpammo(id, CSW_AK47B, BPAMMO)
}

public Remove_Ak47b(id)
{
	if(!is_user_connected(id))
		return
		
	g_Had_Ak47b[id] = 0
	g_Shoot_Special[id] = 0	
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
	
	if(get_user_weapon(id) != g_Current_Weapon[id]) g_Current_Weapon[id] = get_user_weapon(id)
	
	if(get_user_weapon(id) == CSW_AK47B && g_Had_Ak47b[id])
	{
		if(g_Old_Weapon[id] != CSW_AK47B)
		{
			set_pev(id, pev_viewmodel2, V_MODEL)
			set_pev(id, pev_weaponmodel2, P_MODEL)
		}
	}
	
	g_Old_Weapon[id] = get_user_weapon(id)
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_AK47B && g_Had_Ak47b[id])
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) != CSW_AK47B || !g_Had_Ak47b[invoker])
		return FMRES_IGNORED
	if(eventid != g_Ak47b_Event)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	if(!g_Shoot_Special[invoker] && cs_get_user_bpammo(invoker, CSW_AK47B) > 0)
	{
		g_Shoot_Count[invoker]++
		if(g_Shoot_Count[invoker] >= ACTIVE_CLIP)
		{
			g_Shoot_Special[invoker] = 1
			
			static Ent; Ent = fm_get_user_weapon_entity(invoker, CSW_AK47B)
			if(pev_valid(Ent)) g_Shoot_Count[invoker] = cs_get_weapon_ammo(Ent)
		}
	} else if(g_Shoot_Special[invoker]) {
		cs_set_user_bpammo(invoker, CSW_AK47B, cs_get_user_bpammo(invoker, CSW_AK47B) - 1)
		
		if(cs_get_user_bpammo(invoker, CSW_AK47B) <= 0)
		{
			g_Shoot_Special[invoker] = 0
			g_Shoot_Count[invoker] = 0
		}
	}
	
	set_weapon_anim(invoker, g_Shoot_Special[invoker] == 1 ? ANIM_SHOOTBCS2 : ANIM_SHOOTBCS1)
	emit_sound(invoker, CHAN_WEAPON, g_Shoot_Special[invoker] == 1 ? AK47B_Sounds[1] : AK47B_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	Eject_Shell(invoker, g_ShellId, 0.0)
		
	return FMRES_SUPERCEDE
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[32]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = pev(entity, pev_owner)
	
	if(equal(model, OLD_W_MODEL))
	{
		static weapon; weapon = fm_find_ent_by_owner(-1, weapon_ak47b, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(g_Had_Ak47b[iOwner])
		{
			Remove_Ak47b(iOwner)
			
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return
	if(g_Current_Weapon[id] != CSW_AK47B || !g_Had_Ak47b[id])
		return
		
	static NewButton; NewButton = get_uc(uc_handle, UC_Buttons)
	static OldButton; OldButton = pev(id, pev_oldbuttons)
	
	if(NewButton & IN_ATTACK)
	{
		if(!g_Holding_Attack[id]) g_Holding_Attack[id] = 1
	} else if((NewButton & IN_ATTACK2) && !(OldButton & IN_ATTACK2)) {
		if(cs_get_user_zoom(id) == 1) cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 1)
		else cs_set_user_zoom(id, CS_SET_NO_ZOOM, 1)
	} else {
		if(OldButton & IN_ATTACK)
		{
			if(g_Holding_Attack[id]) 
			{
				g_Holding_Attack[id] = 0
				g_Shoot_Count[id] = 0
				g_Shoot_Special[id] = 0
			}
		}
	}
}

public fw_TraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_alive(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_AK47B || !g_Had_Ak47b[Attacker])
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3]
	
	get_tr2(Ptr, TR_vecEndPos, flEnd)
	get_tr2(Ptr, TR_vecPlaneNormal, vecPlane)		
		
	if(!is_user_alive(Victim))
	{
		Make_BulletHole(Attacker, flEnd, Damage)
		Make_BulletSmoke(Attacker, Ptr)
	}
	
	if(g_Shoot_Special[Attacker])
	{
		Make_BalrogEffect(Attacker, Ptr)
		radius_damage(Attacker, flEnd, float(DAMAGE), 96.0)
	}
	
	SetHamParamFloat(3, float(DAMAGE))
	
	return HAM_IGNORED
}

public fw_Weapon_PrimaryAttack(Ent)
{
	if(!pev_valid(Ent))
		return
	static Id; Id = pev(Ent, pev_owner)
	if(!g_Had_Ak47b[Id])
		return
	
	if(g_Shoot_Special[Id]) set_pdata_float(Ent, 62, 0.4, 4)
	else set_pdata_float(Ent, 62, 0.2, 4)
}

public fw_Weapon_PrimaryAttack_Post(Ent)
{
	if(!pev_valid(Ent))
		return
	static Id; Id = pev(Ent, pev_owner)
	if(!g_Had_Ak47b[Id])
		return

	static Float:push[3]; pev(Id, pev_punchangle, push)
	
	xs_vec_mul_scalar(push, RECOIL, push)

	set_pev(Id, pev_punchangle, push)	
	
	if(g_Shoot_Special[Id] && cs_get_weapon_ammo(Ent) > 0) 
	{
		cs_set_weapon_ammo(Ent, g_Shoot_Count[Id])
		set_pdata_float(Ent, 46, get_pdata_float(Ent, 46, 4) * 0.75, 4)	
	}
}

public fw_Item_AddToPlayer_Post(ent, id)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	if(pev(ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		g_Had_Ak47b[id] = 1
		set_pev(ent, pev_impulse, 0)
	}		

	return HAM_HANDLED	
}

public fw_Item_PostFrame(Ent)
{
	if(!pev_valid(Ent))
		return
		
	static Id; Id = pev(Ent, pev_owner)
	if(!g_Had_Ak47b[Id])
		return
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(Id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(Id, CSW_AK47B)
	static iClip; iClip = get_pdata_int(Ent, 51, 4)

	if(get_pdata_int(Ent, 54, 4) && flNextAttack <= 0.0)
	{
		static temp1; temp1 = min(CLIP - iClip, bpammo)

		set_pdata_int(Ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(Id, CSW_AK47B, bpammo - temp1)		
		
		set_pdata_int(Ent, 54, 0, 4)
	}		
}

stock Make_BulletHole(id, Float:Origin[3], Float:Damage)
{
	// Find target
	static Decal; Decal = random_num(41, 45)
	static LoopTime; 
	
	if(Damage > 100.0) LoopTime = 2
	else LoopTime = 1
	
	for(new i = 0; i < LoopTime; i++)
	{
		// Put decal on "world" (a wall)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(Decal)
		message_end()
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(id)
		write_byte(Decal)
		message_end()
	}
}

public Make_BulletSmoke(id, TrResult)
{
	static Float:vecSrc[3], Float:vecEnd[3], TE_FLAG
	
	get_weapon_attachment(id, vecSrc)
	global_get(glb_v_forward, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)

	get_tr2(TrResult, TR_vecEndPos, vecSrc)
	get_tr2(TrResult, TR_vecPlaneNormal, vecEnd)
    
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
	write_short(g_SmokePuff_SprId)
	write_byte(2)
	write_byte(50)
	write_byte(TE_FLAG)
	message_end()
}

public Make_BalrogEffect(id, TrResult)
{
	static Float:vecSrc[3], Float:vecEnd[3], TE_FLAG
	
	get_weapon_attachment(id, vecSrc)
	global_get(glb_v_forward, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)

	get_tr2(TrResult, TR_vecEndPos, vecSrc)
	get_tr2(TrResult, TR_vecPlaneNormal, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 5.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
    
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecEnd[0])
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2])
	write_short(g_Exp_SprId)
	write_byte(5)
	write_byte(30)
	write_byte(TE_FLAG)
	message_end()
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

stock radius_damage(id, Float:Origin[3], Float:Damage, Float:Radius)
{
	static Victim; Victim = -1

	while((Victim = engfunc(EngFunc_FindEntityInSphere, Victim, Origin, Radius)) != 0)
	{
		if(!is_user_alive(Victim) || id == Victim) 
			continue
		if(!zp_get_user_zombie(Victim))
			continue

		ExecuteHamB(Ham_TakeDamage, Victim, fm_get_user_weapon_entity(id, get_user_weapon(id)), id, Damage, DMG_BULLET)
	}
}

stock Eject_Shell(id, Shell_ModelIndex, Float:Time) // By Dias
{
	static Ent; Ent = get_pdata_cbase(id, 373, 5)
	if(!pev_valid(Ent))
		return

        set_pdata_int(Ent, 57, Shell_ModelIndex, 4)
        set_pdata_float(id, 111, get_gametime() + Time)
}

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
	
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}
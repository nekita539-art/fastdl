#if defined _tslib_included
  #endinput
#endif
#define _tslib_included

#tryinclude <fakemeta>
#tryinclude <engine>

const LINUX_PLAYER = 5
const LINUX_ENTITY = 4

const CLIPAMMO_BITSUM = (1<<29) | (1<<34)
const RELOAD_BITSUM = (1<<24) | (1<<25) | (1<<29) | (1<<34) | (1<<35)
const EXTRARELOAD_BITSUM = (1<<4) | (1<<20) | (1<<26)


/* ----------------------pvPrivateData-------------------- */

// Float
const m_flNextPrimaryAttack = 35
const m_flNextSecondaryAttack = 36
const m_flTimeWeaponIdle = 38
const m_flNextAttack = 70

const m_flLastActivityTime = 25
const m_flPlayerGameTime = 85
const m_flLastBulletTime = 86 // unknown
const m_flBulletTime = 87

// Integer
const m_iClip = 41
const m_iId = 46
const m_iDeaths = 711

const ts_wpns_num = 38

new const WEAPONCLIPOFFSET[ts_wpns_num] = { -1, 80, 94, 108, 122, 136, 150, 164, 178, 192, 192, 220, 234, 248, 262, 276, 290, 304, 318, 332, 346, 360, 374, 388, 402, 416, 430, 444, 458, -1, 486, 500, 514, 528, -1, 556, 570, 590 }
new const WEAPONBPAMMOOFFSET[ts_wpns_num] = { -1, 50, 50, 50, 52, 53, 50, 50, 50, 51, 51, 52, 54, 53, 56, 53, 50, 50, 57, 56, 52, 51, 58, 51, 354, 366, 52, 53, 59, -1, 56, 61, 53, 52, -1, 556, 62, 61 }
new const WEAPONRELOADOFFSET[ts_wpns_num] = { -1, 82, 96, 110, 123, 138, 152, 166, 180, 194, 194, 222, 236, 250, 264, 278, 292, 306, 320, 334, 347, 362, 376, 390, -1, -1, 431, 446, 460, -1, 488, 502, 516, 530, -1, -1, 572, 586 }
new const WEAPONEXTRARELOADOFFSET[ts_wpns_num] = { -1, -1, -1, -1, 130, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 351, -1, -1, -1, -1, -1, 438, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 }

/* ------------------------------------------------------------- */

stock ts_is_valid_weaponid(weaponid)
{
	return 0 < weaponid < ts_wpns_num && !((1<<weaponid) & CLIPAMMO_BITSUM) ? true : false
}

stock ts_get_weapon_id(const entity) // Get TSW_* from entity index
{
	if(pev_valid(entity) != 2)
		return 0
	
	return get_pdata_int(entity, m_iId, 4)
}

stock ts_get_weapon_ent(const id)
{
	static ent
	ent = -1
	
	while((ent = find_ent_by_owner(ent, "weapon_tsgun", id)) != 0)
	{
		if(pev_valid(ent) != 2)
			continue
		
		return ent
	}
	return 0
}

stock ts_get_weapon_reload(const entity)
{
	if(pev_valid(entity) != 2)
		return 0
	
	static weaponid
	weaponid = ts_get_weapon_id(entity)
	
	if(!(0 < weaponid < ts_wpns_num) || (1<<weaponid) & RELOAD_BITSUM)
		return 0
	
	return get_pdata_int(entity, WEAPONRELOADOFFSET[weaponid], 4)
}

stock ts_get_user_reload(const id)
{
	static weaponid
	weaponid = get_user_weapon(id)
	
	if(!(0 < weaponid < ts_wpns_num) || (1<<weaponid) & RELOAD_BITSUM)
		return 0
	
	static ent
	ent = -1
	
	while((ent = find_ent_by_owner(ent, "weapon_tsgun", id)) != 0)
	{
		if(pev_valid(ent) != 2)
			continue
		
		return get_pdata_int(ent, WEAPONRELOADOFFSET[weaponid], 4)
	}
	return 0
}

stock ts_get_shotgun_extrareload(const entity)
{
	if(pev_valid(entity) != 2)
		return 0
	
	static weaponid
	weaponid = ts_get_weapon_id(entity)
	
	if(!(0 < weaponid < ts_wpns_num) || !((1<<weaponid) & EXTRARELOAD_BITSUM))
		return 0
	
	return get_pdata_int(entity, WEAPONEXTRARELOADOFFSET[weaponid], 4)
}

stock ts_get_user_extrareload(const id)
{	
	static weaponid
	weaponid = get_user_weapon(id)
	
	if(!(0 < weaponid < ts_wpns_num) || !((1<<weaponid) & EXTRARELOAD_BITSUM))
		return 0
	
	static ent
	ent = -1
	
	while((ent = find_ent_by_owner(ent, "weapon_tsgun", id)) != 0)
	{
		if(pev_valid(ent) != 2)
			continue
		
		return get_pdata_int(ent, WEAPONEXTRARELOADOFFSET[weaponid], 4)
	}
	
	return 0
}

stock ts_get_weapon_ammo(const entity)
{
	if(pev_valid(entity) != 2)
		return 0
	
	return get_pdata_int(entity, m_iClip, 4)
}

stock ts_get_user_ammo(const id)
{
	static weaponid
	weaponid = get_user_weapon(id)

	if(!ts_is_valid_weaponid(weaponid))
		return 0

	static ent
	ent = -1
	
	while((ent = find_ent_by_owner(ent, "weapon_tsgun", id)) != 0)
	{
		if(pev_valid(ent) != 2)
			continue
		
		return get_pdata_int(ent, WEAPONCLIPOFFSET[weaponid], 4)
	}
	return 0
}

stock ts_get_weapon_bpammo(const entity)
{
	if(pev_valid(entity) != 2)
		return 0
	
	static weaponid
	weaponid = get_pdata_int(entity, m_iId, 4)
	
	if(!ts_is_valid_weaponid(weaponid))
		return 0
	
	return get_pdata_int(entity, WEAPONBPAMMOOFFSET[weaponid], 4)
}

stock ts_get_user_bpammo(const id, const weaponid)
{
	if(!ts_is_valid_weaponid(weaponid))
		return 0
	
	static ent
	ent = -1
	
	while((ent = find_ent_by_owner(ent, "weapon_tsgun", id)) != 0)
	{
		if(pev_valid(ent) != 2 || ts_get_weapon_id(ent) != weaponid)
			continue
		
		return get_pdata_int(ent, WEAPONBPAMMOOFFSET[weaponid], 4)
	}
	return 0
}

stock ts_get_user_lastactivity(const id) // => cs_get_user_lastactivity(id)
{
	return get_pdata_int(id, m_flLastActivityTime, 5)
}

stock ts_set_weapon_ammo(const entity, const ammo)
{
	if(pev_valid(entity) != 2)
		return

	static weaponid
	weaponid = ts_get_weapon_id(entity)

	if(!ts_is_valid_weaponid(weaponid))
		return

	set_pdata_int(entity, WEAPONCLIPOFFSET[weaponid], ammo, 4)
}

stock ts_set_user_ammo(const id, const weaponid, const ammo)
{
	if(!ts_is_valid_weaponid(weaponid))
		return

	static ent
	ent = -1
	
	while((ent = find_ent_by_owner(ent, "weapon_tsgun", id)) != 0)
	{
		if(pev_valid(ent) != 2 || ts_get_weapon_id(ent) != weaponid)
			continue
		
		set_pdata_int(ent, WEAPONCLIPOFFSET[weaponid], ammo, 4)
	}
}

stock ts_set_weapon_bpammo(const entity, const ammo)
{
	static weaponid
	weaponid = get_pdata_int(entity, m_iId)

	if(pev_valid(entity) != 2 || !ts_is_valid_weaponid(weaponid))
		return
		
	set_pdata_int(entity, WEAPONBPAMMOOFFSET[weaponid], ammo, 4)
}

stock ts_set_user_bpammo(const id, const weaponid, const ammo)
{
	if(!ts_is_valid_weaponid(weaponid))
		return

	static ent
	ent = -1

	while((ent = find_ent_by_owner(ent, "weapon_tsgun", id)) != 0)
	{
		if(pev_valid(ent) != 2 || ts_get_weapon_id(ent) != weaponid)
			continue
		
		set_pdata_int(ent, WEAPONBPAMMOOFFSET[weaponid], ammo, 4)
	}
}

stock ts_set_player_gametime(const id, const Float:time = 1.0)
{
	set_pdata_float(id, m_flPlayerGameTime, time, 5)
}

stock ts_set_user_waiting(id)
{
	if(!is_user_alive(id))
		return
	
	new deaths = get_pdata_int(id, m_iDeaths, 5)
	set_pdata_int(id, m_iDeaths, deaths >= 0 ? (deaths-1) : (deaths+1), 5)
	entity_set_float(id, EV_FL_frags, float(get_user_frags(id)+1))
	set_msg_block(80, 1)
	ExecuteHamB(Ham_Killed, id, id, 0)
	set_msg_block(80, 0)
	entity_set_int(id, EV_INT_movetype, MOVETYPE_NOCLIP)
	entity_set_int(id, EV_INT_solid, SOLID_NOT)
	entity_set_int(id, EV_INT_effects, EF_NODRAW)
	entity_set_int(id, EV_INT_deadflag, DEAD_DEAD)
	entity_set_float(id, EV_FL_takedamage, 0.0)
	
	/* - Changing while dying buy not by setting deadflag to DEAD_DEAD
	set_pdata_int(id, 158, 7, 5) 
	set_pdata_int(id, 352, 0, 5)
	set_pdata_int(id, 354, 0, 5)
	*/
}
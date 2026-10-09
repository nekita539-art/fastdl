#include < amxmodx >
#include < fakemeta >
#include < hamsandwich >
#include < zombieplague >

#define PLUGIN		"[ZBG] Extra Item: Jump Bomb"
#define VERSION    	"1.0"
#define AUTHOR    	"SNAFFY"

native cs_get_user_bpammo(index, weapon)
native cs_set_user_bpammo(index, weapon, amount)

#define JUMPBOMB_ID		55559

/////////////////////////////////////Cvars/////////////////////////////////////

#define ITEM_NAME		"Голова Жабы" 	// Имя айтема
#define ITEM_COST		10		// Стоимость за 1 бомбу
#define MAX_GRENADE    		5 		// Лимит гранат
#define RADIUS			300.0 		// Радиус взрыва
#define JUMP_DAMAGE		20		// Урон
#define JUMP_EXP		500.0		// Сила отдачи от гранаты	

#define GRENADE_ICON				//Иконка с лева. Что бы отключить поставьте //

#define BUY_GRENADE_MSG		"[ZBG] Вы купили гранату джамп"
#define MAX_GRENADE_MSG		"[ZBG] Вы купили маскимум гранат"

#define TRAIL		//Трайл за гранатой. Что бы отключить закоментируем ( //#define TRAIL )

/////////////////////////////////////WeaponList/////////////////////////////////////

#define WEAPONLIST 	// WeaponList. Что бы отключить закоментируем ( //#define WEAPONLIST )

#define WEAPON_DEFAULT		"weapon_smokegrenade"	//Weapon под которую сделана граната
#define DEFAULT_CSW		CSW_SMOKEGRENADE	//CSW под которую сделана граната

#if defined WEAPONLIST
#define WEAPON_NEW		"zbg_extra_jumpbomb"	//Название WeaponList'a новой гранаты

new const WeaponList_Sprite[][] =
{
	"sprites/zbg_extra_jumpbomb.txt",
	"sprites/zbg/640hud61.spr",
	"sprites/640hud7.spr"
}

enum
{
	prim_ammoid 		= 13,
	prim_ammomaxamount 	= 1,
	sec_ammoid 		= -1,
	sec_ammomaxamount 	= -1,
	slotid 			= 3,
	number_in_slot 		= 3,
	weaponid 		= 9,
	flags 			= 24
}
#endif

////////////////////////////////////////////////////////////////////////////////////

// Модели гранаты
new const BOMB_MODEL[][] = 
{
	"models/zbg/v_zombi_bomb.mdl",
	"models/zbg/p_zombi_bomb.mdl",
	"models/zbg/w_zombi_bomb.mdl"
}

//Звуки покупки
#define	g_SoundGrenadeBuy	"items/gunpickup2.wav"
#define g_SoundAmmoPurchase	"items/9mmclip1.wav"
	
//Звук взрыва
#define g_SoundBombExplode	"zbg/jump_explode.wav"

//Не изменять! Звуки прописаны в модели.
new const frogbomb_sound[][] = 
{
	"nst_zombie/zombi_bomb_pull_1.wav", 
	"nst_zombie/zombi_bomb_deploy.wav",
	"nst_zombie/zombi_bomb_throw.wav"
}

new const frogbomb_sound_idle[][] = 
{ 
	"nst_zombie/zombi_bomb_idle_1.wav", 
	"nst_zombie/zombi_bomb_idle_2.wav", 
	"nst_zombie/zombi_bomb_idle_3.wav", 
	"nst_zombie/zombi_bomb_idle_4.wav"
}
new g_itemid

new g_JumpGrenadeCount[33], g_iExplo
#if defined TRAIL
new g_trailSpr
#endif
#if defined GRENADE_ICON
new grenade_icons[33][32]
#endif

public plugin_precache()
{
	static i

	for(i = 0; i < sizeof BOMB_MODEL; i++)
		precache_model(BOMB_MODEL[i])

	for(i = 0; i < sizeof frogbomb_sound; i++)
		precache_sound(frogbomb_sound[i])

	for(i = 0; i < sizeof frogbomb_sound_idle; i++)
		precache_sound(frogbomb_sound_idle[i])

	precache_sound(g_SoundGrenadeBuy)
	precache_sound(g_SoundAmmoPurchase)
	precache_sound(g_SoundBombExplode)

	#if defined WEAPONLIST
	register_clcmd(WEAPON_NEW, "hook")

	for(i = 0; i < sizeof WeaponList_Sprite; i++)
		precache_generic(WeaponList_Sprite[i])

	#endif

	g_iExplo = precache_model("sprites/zbg/zombiebomb.spr")

	#if defined TRAIL
	g_trailSpr = precache_model("sprites/laserbeam.spr")
	#endif
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	//Ham
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	RegisterHam(Ham_Item_Deploy, WEAPON_DEFAULT, "DeployPost", 1)

	//Forward
	register_forward(FM_SetModel, "fw_SetModel")

	//Event
	register_event("DeathMsg", "DeathMsg", "a")

	#if defined GRENADE_ICON
	register_event("CurWeapon", "grenade_icon", "be", "1=1")
	#endif

	//Extra Item
	g_itemid = zp_register_extra_item(ITEM_NAME, ITEM_COST, ZP_TEAM_ZOMBIE)
}

#if defined WEAPONLIST
public hook(id)
{ 
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE
		
	engclient_cmd(id, WEAPON_DEFAULT)
	
	return PLUGIN_HANDLED
}
#endif

public zp_extra_item_selected(id, Item)
{
	if(Item == g_itemid)
	{
		if(g_JumpGrenadeCount[id] >= MAX_GRENADE)
		{
			client_print(id, print_chat, "%s", MAX_GRENADE_MSG)
			return ZP_PLUGIN_HANDLED
		}

		new Ammo = cs_get_user_bpammo(id, DEFAULT_CSW)
		if(g_JumpGrenadeCount[id] >= 1)
		{
			cs_set_user_bpammo(id, DEFAULT_CSW, Ammo + 1)
			emit_sound(id, CHAN_ITEM, g_SoundAmmoPurchase, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			g_JumpGrenadeCount[id]++
		}
		else
		{
			fm_give_item(id, WEAPON_DEFAULT)
			client_print(id, print_chat, "%s", BUY_GRENADE_MSG)
			emit_sound(id, CHAN_ITEM, g_SoundGrenadeBuy, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			g_JumpGrenadeCount[id] = 1
		}

		AmmoPickup(id)
		#if defined WEAPONLIST
		WeaponList(id, 1)
		#endif
	}
	return PLUGIN_HANDLED
}

public zp_user_infected_post(id, infector, nemesis)
{
	if(zp_get_user_nemesis(id) || zp_is_survivor_round() || zp_is_nemesis_round())
		return

	g_JumpGrenadeCount[id] = 0

	fm_give_item(id, WEAPON_DEFAULT)    
	cs_set_user_bpammo(id, DEFAULT_CSW, 1)
	emit_sound(id, CHAN_ITEM, g_SoundGrenadeBuy, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)       

	AmmoPickup(id)

	g_JumpGrenadeCount[id] = 1
	#if defined WEAPONLIST
	WeaponList(id, 1)
	#endif
}

public zp_user_humanized_post(id, survivor)
{
	g_JumpGrenadeCount[id] = 0
	#if defined WEAPONLIST
	WeaponList(id, 0)
	#endif
}

public DeployPost(entity)
{
	static id
	id = get_pdata_cbase(entity, 41, 4)

	if(!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_nemesis(id) || zp_get_user_survivor(id))
		return PLUGIN_CONTINUE

	set_pev(id, pev_viewmodel2, BOMB_MODEL[0])
	set_pev(id, pev_weaponmodel2, BOMB_MODEL[1])

	return PLUGIN_CONTINUE
}

public fw_SetModel(Entity, const Model[])
{
	if (Entity < 0)
		return FMRES_IGNORED

	if (pev(Entity, pev_dmgtime) == 0.0)
		return FMRES_IGNORED

	new iOwner = pev(Entity, pev_owner)
 
	if(!zp_get_user_zombie(iOwner))
		return FMRES_IGNORED
	       
	if(g_JumpGrenadeCount[iOwner] >= 1 && equal(Model[7], "w_sm", 4))
	{
		g_JumpGrenadeCount[iOwner]--

		set_pev(Entity, pev_flTimeStepSound, JUMPBOMB_ID)
		set_pev(Entity, pev_body, 23)

		fm_set_rendering(Entity, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 16)

		#if defined TRAIL
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW)
		write_short(Entity) 		// entity
		write_short(g_trailSpr) 	// sprite
		write_byte(2) 			// life
		write_byte(5) 			// width
		write_byte(0) 			// r
		write_byte(200) 		// g
		write_byte(0) 			// b
		write_byte(200) 		// brightness
		message_end()
		#endif

		engfunc(EngFunc_SetModel, Entity, BOMB_MODEL[2])

		return FMRES_SUPERCEDE    
	}
	return FMRES_IGNORED
}

public fw_ThinkGrenade(Entity)
{
	if(!pev_valid(Entity))
		return HAM_IGNORED
       
	static Float:dmg_time
	pev(Entity, pev_dmgtime, dmg_time)
       
	if(dmg_time > get_gametime())
		return HAM_IGNORED
       
	if(pev(Entity, pev_flTimeStepSound) == JUMPBOMB_ID)
	{
		JumpBombExplode(Entity)
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}

public JumpBombExplode(Entity)
{
	if(Entity < 0)
		return
       
	static Float:Origin[3]
	pev(Entity, pev_origin, Origin)

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 45.0)
	write_short(g_iExplo)
	write_byte(35)
	write_byte(186)
	message_end()
     
      	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
      	write_byte(TE_PARTICLEBURST) // TE id
      	engfunc(EngFunc_WriteCoord, Origin[0]) // x
      	engfunc(EngFunc_WriteCoord, Origin[1]) // y
      	engfunc(EngFunc_WriteCoord, Origin[2] + 45.0) // z
      	write_short(70) // radius
      	write_byte(252) // color
      	write_byte(6) // duration (will be randomized a bit)
      	message_end()
	       
	emit_sound(Entity, CHAN_WEAPON, g_SoundBombExplode, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
      
	for(new victim = 1; victim <= get_maxplayers(); victim++)
	{
		if (!is_user_alive(victim))
			continue
                  
		new Float:VictimOrigin[3]
		pev(victim, pev_origin, VictimOrigin)
		           
		new Float:Distance = get_distance_f(Origin, VictimOrigin)   
		           
		if(Distance <= RADIUS)
		{
			static Float:NewSpeed

			NewSpeed = JUMP_EXP * (1.0 - (Distance / RADIUS))
			               
			static Float:Velocity[3]
			get_speed_vector(Origin, VictimOrigin, NewSpeed, Velocity)
			               
			set_pev(victim, pev_velocity, Velocity)
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), _, victim)
			write_short((1<<12) * 6)       
			write_short((1<<12) * 10)
			write_short((1<<12) * 10)
			message_end()

			message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, victim)
			write_short(2048)	// Duration
			write_short(2048)
			write_short(0x0000)
			write_byte(255)			// Red
			write_byte(140)			// Green
			write_byte(0)			// Blue
			write_byte(200)			// Alpha
			message_end()

		}
	}
	engfunc(EngFunc_RemoveEntity, Entity)
}       
#if defined GRENADE_ICON
public grenade_icon(id)
{
	remove_grenade_icon(id)
		
	if(is_user_bot(id))
		return

	static igrenade, grenade_sprite[16], grenade_color[3]
	igrenade = get_user_weapon(id)
	
	switch(igrenade) 
	{
		case DEFAULT_CSW:
		{
			if(!is_user_alive(id) || zp_get_user_zombie(id)) 
			{
				grenade_sprite = "dmg_gas"
				grenade_color = {255, 165, 0} 
			}
			else
			{
				grenade_sprite = ""
				grenade_color = {0, 0, 0} 
			}
		}
		default: return
	}
	grenade_icons[id] = grenade_sprite
	
	message_begin(MSG_ONE, get_user_msgid("StatusIcon"),{0, 0, 0}, id)
	write_byte(1)
	write_string(grenade_icons[id]) 
	write_byte(grenade_color[0])
	write_byte(grenade_color[1])
	write_byte(grenade_color[2]) 
	message_end()

	return
}
#endif
public zp_round_ended() 
{
	for(new id = 1; id <= get_maxplayers(); id++) 
	{
		if(!is_user_alive(id) || !zp_get_user_zombie(id)) 
			continue

		ham_strip_weapon(id, WEAPON_DEFAULT)
		g_JumpGrenadeCount[id] = 0
	}
}

public DeathMsg()
{
	new attacker = read_data(1)
	new victim = read_data(2)

	if(!is_user_connected(attacker))
		return HAM_IGNORED

	if(victim == attacker || !victim)
		return HAM_IGNORED

	if(!zp_get_user_zombie(victim))
		return HAM_IGNORED

	#if defined GRENADE_ICON
	remove_grenade_icon(victim)
	#endif

	#if defined WEAPONLIST
	WeaponList(victim, 0)
	#endif

	g_JumpGrenadeCount[victim] = 0

        return HAM_HANDLED
}

public client_connect(id) g_JumpGrenadeCount[id] = 0

#if defined WEAPONLIST
WeaponList(index, mode = 0)
{
	if (!is_user_connected(index))
		return
	
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), {0, 0, 0}, index)
	write_string(mode ? WEAPON_NEW : WEAPON_DEFAULT)
	write_byte(prim_ammoid)
	write_byte(prim_ammomaxamount)
	write_byte(sec_ammoid)
	write_byte(sec_ammomaxamount)
	write_byte(slotid)
	write_byte(number_in_slot)
	write_byte(weaponid)
	write_byte(flags)
	message_end()
}
#endif

#if defined GRENADE_ICON
static remove_grenade_icon(index) 
{
	message_begin(MSG_ONE, get_user_msgid("StatusIcon"), {0, 0, 0}, index)
	write_byte(0) 
	write_string(grenade_icons[index])
	message_end()
}
#endif

stock set_user_takedamage(index, damage)
{
	if(!is_user_alive(index))
		return

	new vec[3]
	FVecIVec(get_target_origin_f(index), vec)

	message_begin(MSG_ONE, get_user_msgid("Damage"), _, index)
	write_byte(0)
	write_byte(damage)
	write_long(DMG_CRUSH)
	write_coord(vec[0]) 
	write_coord(vec[1])
	write_coord(vec[2])
	message_end()

	if(pev(index, pev_health) - 20.0 <= 0)
		ExecuteHamB(Ham_Killed, index, index, 1)
	else ExecuteHamB(Ham_TakeDamage, index, 0, index, float(damage), DMG_BLAST)
}

stock AmmoPickup(index)
{
	message_begin(MSG_ONE, get_user_msgid("AmmoPickup"), _, index)
	write_byte(13)
	write_byte(1)
	message_end()
}

stock Float:get_target_origin_f(index)
{
	new Float:orig[3]
	pev(index, pev_origin, orig)

	if(index > get_maxplayers())
	{
		new Float:mins[3], Float:maxs[3]
		pev(index, pev_mins, mins)
		pev(index, pev_maxs, maxs)
		
		if(!mins[2]) orig[2] += maxs[2] / 2
	}
	return orig
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num

	return 1
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) 
{
	new Float:RenderColor[3]
	RenderColor[0] = float(r)
	RenderColor[1] = float(g)
	RenderColor[2] = float(b)

	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, RenderColor)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))

	return 1
}

stock fm_give_item(index, const item[])
{
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5))
		return 0

	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item))
	if (!pev_valid(ent))
		return 0

	new Float:origin[3]
	pev(index, pev_origin, origin)
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)

	new save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, index)
	if (pev(ent, pev_solid) != save)
		return ent

	engfunc(EngFunc_RemoveEntity, ent)

	return -1
}

stock ham_strip_weapon(index, weapon[])
{
	if(!equal(weapon, "weapon_", 7))
		return 0

    	new wId = get_weaponid(weapon)
    	if(!wId) return 0

    	new wEnt
    	while((wEnt = engfunc(EngFunc_FindEntityByString, wEnt, "classname", weapon)) && pev(wEnt,pev_owner) != index) {}

    	if(!wEnt) 
		return 0

    	if(get_user_weapon(index) == wId)
		ExecuteHamB(Ham_Weapon_RetireWeapon,wEnt)

    	if(!ExecuteHamB(Ham_RemovePlayerItem, index, wEnt))
		return 0

    	ExecuteHamB(Ham_Item_Kill, wEnt)

    	set_pev(index, pev_weapons, pev(index, pev_weapons) & ~(1<<wId))

    	return 1
}
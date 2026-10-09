#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <cstrike>
#include <fun>
#include <xs>

new const ball_name[] = "poison_ball"
new const ball_model[] = "models/zombie_plague/w_rhell_ball.mdl"
new const ball_poisonspritemdl[] = "sprites/texas1k/hell_exp_flame_1.spr"
new const ball_spriteexplodemdl[] = "sprites/texas1k/hell_exp_flame_1.spr"

new const zclass_name[] = { "• Ревенант HELL" }
new const zclass_info[] = { "\y[BOSS] •" }
new const zclass_model[] = { "revenant_hell" }
new const zclass_clawmodel[] = { "v_rhell.mdl" }
new const g_vgrenade[] = "models/zombie_plague/v_jbomb_rhell.mdl"
const zclass_health = 7000
const zclass_speed = 270
const Float:zclass_gravity = 0.70
const Float:zclass_knockback = 0.25

new index, defaultindex

new sprPoison, sprSmoke

new g_zclass_poison
new cvar_poisondmg, cvar_poisondelay, cvar_poisonvelocity, cvar_poisonballhealth, cvar_poisonballradius, cvar_poisonballpower, cvar_poisondmg2, cvar_poisontime, cvar_poison
new g_msgScreenShake, g_smoke, sTrail, ball_poisonsprite, ball_spriteexplode, g_explode[512], g_can[33], g_msgScoreInfo, bool:g_Alreadypoison[33], Time[33]
new g_roundend

public plugin_init()
{
	cvar_poisondelay = register_cvar("zp_classpoison_delay","15")
	cvar_poisondmg = register_cvar("zp_classpoisonball_dmg","90.0")
	cvar_poisonvelocity = register_cvar("zp_classpoisonball_velocity","1200")
	cvar_poisonballhealth = register_cvar("zp_classpoisonball_health","1.0")
	cvar_poisonballradius = register_cvar("zp_classpoisonball_radius","300.0")
	cvar_poisonballpower = register_cvar("zp_classpoisonball_power", "800")
	cvar_poison = register_cvar("zp_classpoisonball_enable", "1")
	cvar_poisontime = register_cvar("zp_classpoisonball_poisontime", "5")
	cvar_poisondmg2 = register_cvar("zp_classpoisonball_poisondmg", "2")

	register_touch(ball_name, "worldspawn", "touchWorld")
	register_touch(ball_name, "func_wall", "touchWorld")
	register_touch(ball_name, "func_door", "touchWorld")
	register_touch(ball_name, "func_door_rotating", "touchWorld")
	register_touch(ball_name, "func_wall_toggle", "touchWorld")
	register_touch(ball_name, "func_breakable", "touchWorld")
	register_think(ball_name,"ball_think")

	register_clcmd("drop","poison_cmd")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_logevent("logevent_round_end", 2, "1=Round_End")

	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_Player_Duck, "player", "Player_Duck", 1)

	g_msgScoreInfo = get_user_msgid("ScoreInfo")
	g_msgScreenShake = get_user_msgid("ScreenShake")

	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
}

public plugin_precache()
{
	precache_model(ball_model)
	g_smoke = precache_model("sprites/steam1.spr")
	sTrail = precache_model("sprites/laserbeam.spr")
	ball_poisonsprite = precache_model(ball_poisonspritemdl)
	ball_spriteexplode  = precache_model(ball_spriteexplodemdl)
	precache_model(g_vgrenade)
	sprPoison = precache_model("sprites/texas1k/hell_exp_flame_1.spr")
	sprSmoke = precache_model("sprites/black_smoke3.spr")

	g_zclass_poison = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)	

	index = precache_model("models/player/revenant_hell/revenant_hell.mdl")
    	defaultindex = precache_model("models/player.mdl")
}

public Event_CurWeapon(id)    
{
	new weaponID = read_data(2)
	
	if(!zp_get_user_zombie(id) || !is_user_alive(id) || zp_get_user_zombie_class(id) != g_zclass_poison)
		return PLUGIN_CONTINUE
	
	if(weaponID == CSW_HEGRENADE)
	{
		set_pev(id, pev_viewmodel, engfunc(EngFunc_AllocString, g_vgrenade))
	}
	if(weaponID == CSW_FLASHBANG)
	{
		set_pev(id, pev_viewmodel, engfunc(EngFunc_AllocString, g_vgrenade))
	}
	if(weaponID == CSW_SMOKEGRENADE)
	{
		set_pev(id, pev_viewmodel, engfunc(EngFunc_AllocString, g_vgrenade))
	}
	return PLUGIN_CONTINUE
}

public poison_cmd(id)
{
	if(!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_poison || zp_get_user_nemesis(id))
		return PLUGIN_CONTINUE

	if(g_can[id]) 
	{
		client_print(id,print_center,"Ждите %d сек",g_can[id])
		return PLUGIN_HANDLED
	}

	static Float:origin[3], Float:angles[3], Float:v_forward[3], Float:v_right[3], Float:v_up[3], Float:gun_position[3], Float:player_origin[3], Float:player_view_offset[3];
	static Float:OriginX[3]
	pev(id, pev_v_angle, angles)
	pev(id, pev_origin, OriginX)
	engfunc(EngFunc_MakeVectors, angles)

	global_get(glb_v_forward, v_forward)
	global_get(glb_v_right, v_right)
	global_get(glb_v_up, v_up)

	pev(id, pev_origin, player_origin)
	pev(id, pev_view_ofs, player_view_offset)
	xs_vec_add(player_origin, player_view_offset, gun_position)

	xs_vec_mul_scalar(v_forward, 13.0, v_forward)
	xs_vec_mul_scalar(v_right, 0.0, v_right)
	xs_vec_mul_scalar(v_up, 5.0, v_up)

	xs_vec_add(gun_position, v_forward, origin)
	xs_vec_add(origin, v_right, origin)
	xs_vec_add(origin, v_up, origin)

	new Float:StartOrigin[3]
			
	StartOrigin[0] = origin[0]
	StartOrigin[1] = origin[1]
	StartOrigin[2] = origin[2]

	new Float:fVelocity[3] , Float:flOrigin[3] , Float:flAngle[3]
	pev(id,pev_origin,flOrigin)
	pev(id,pev_angles,flAngle)

	new ball = create_entity("info_target")
	
	if(!ball) return PLUGIN_HANDLED

	g_explode[ball] = 0
	
	entity_set_string(ball, EV_SZ_classname, ball_name)
	
	entity_set_model(ball, ball_model)
	
	entity_set_origin(ball, StartOrigin)
	
	entity_set_vector(ball, EV_VEC_angles, flAngle)
	
	new Float:MinBox[3] = {-1.0, -1.0, -1.0}
	new Float:MaxBox[3] = {1.0, 1.0, 1.0}
	entity_set_vector(ball, EV_VEC_mins, MinBox)
	entity_set_vector(ball, EV_VEC_maxs, MaxBox)
	
	entity_set_int(ball, EV_INT_solid, SOLID_SLIDEBOX)
	
	entity_set_int(ball, EV_INT_movetype, MOVETYPE_TOSS)
	
	entity_set_edict(ball, EV_ENT_owner, id)
	
	entity_set_int(ball, EV_INT_effects, EF_BRIGHTLIGHT)
	
	VelocityByAim(id, get_pcvar_num(cvar_poisonvelocity), fVelocity)
	entity_set_vector(ball , EV_VEC_velocity, fVelocity)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(ball)
	write_short(sTrail)
	write_byte(10)
	write_byte(3)
	write_byte(255)
	write_byte(0)
	write_byte(255)
	write_byte(255)
	message_end() 

	UTIL_PlayPlayerAnimation(id,10)
	UTIL_PlayWeaponAnimation(id,8)

	g_can[id] = get_pcvar_num(cvar_poisondelay)
	set_task(1.0,"ability_zero",id)

	entity_set_float(ball, EV_FL_health , get_pcvar_float(cvar_poisonballhealth))

	entity_set_float(ball, EV_FL_nextthink, get_gametime() + 0.1) 
	
	return PLUGIN_HANDLED
}

public touchWorld(ball, world) 
{
	new Float:v[3]
	entity_get_vector(ball, EV_VEC_velocity, v)

	v[0] = (v[0] * 0.85)
	v[1] = (v[1] * 0.85)
	v[2] = (v[2] * 0.85)
	entity_set_vector(ball, EV_VEC_velocity, v)
	
	return PLUGIN_HANDLED
}

public event_round_start()
{
	new iEnt = FM_NULLENT
	while((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", ball_name)) > 0)
	{
		engfunc(EngFunc_RemoveEntity,iEnt)
	}	
	for(new i;i<=32;i++)
	{
		remove_task(i)
		g_can[i] = 0
		Time[i] = 0 
		g_Alreadypoison[i] = false
	}
	g_roundend = 0
}

public logevent_round_end ( )
{
	for ( new Player = 1; Player <= get_maxplayers ( ); Player ++ ) 
	{
		if ( !is_user_alive ( Player ) )
		{
			continue;
		}

		if ( !zp_get_user_zombie ( Player ) )
		{
			continue;
		}
	
		fm_set_user_model_index ( Player, defaultindex );
	}
}

public ball_think(ball)
{
	if(!is_valid_ent(ball))
		return

	new Float:oldangles[3],Float:angles[3]
	pev(ball,pev_angles,oldangles)
	angles[0] = oldangles[0] + random_float(20.0,100.0)
	angles[1] = oldangles[1] + random_float(10.0,80.0)
	angles[2] = oldangles[2] + random_float(10.0,80.0)
	set_pev(ball,pev_angles,angles)

	new Float:v[3]
	entity_get_vector(ball, EV_VEC_velocity, v)

	if(v[2] < 40.0 && v[1] < 40.0 && v[0] < 40.0) 
	{
		if(!g_explode[ball])
		{
			set_task(0.5,"poisonsprite_ball",ball)
			g_explode[ball] = 1
		}
		entity_set_float(ball, EV_FL_health, entity_get_float(ball,EV_FL_health) - 0.2) 

		if(entity_get_float(ball,EV_FL_health) <= 0.0) 
		{
			ball_explode(ball)
			remove_entity(ball)
			g_explode[ball] = 0
			return;
		}
	}
	entity_set_float(ball, EV_FL_nextthink, get_gametime() + 0.1) 
}

public poisonsprite_ball(ball)
{
	if(!is_valid_ent(ball))
		return

	new Float:flOrigin[3]
	pev(ball,pev_origin,flOrigin)

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, flOrigin [0])
	engfunc(EngFunc_WriteCoord, flOrigin [1])
	engfunc(EngFunc_WriteCoord, flOrigin [2] + 45.0)
	write_short (ball_poisonsprite)
	write_byte(5)
	write_byte(185)
	message_end ()

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SMOKE)
	engfunc(EngFunc_WriteCoord, flOrigin [0])
	engfunc(EngFunc_WriteCoord, flOrigin [1])
	engfunc(EngFunc_WriteCoord, flOrigin [2] + 45.0)
	write_short(g_smoke)
	write_byte(10)
	write_byte(10)
	message_end()

	if(entity_get_float(ball,EV_FL_health) >= 1.0) set_task(0.5,"poisonsprite_ball",ball)
}
public ball_explode(Entity)
{
	if(Entity < 0)
		return
       
	static Float:flOrigin[3]
	pev(Entity, pev_origin, flOrigin)
       
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, flOrigin[0])
	engfunc(EngFunc_WriteCoord, flOrigin[1])
	engfunc(EngFunc_WriteCoord, flOrigin[2] + 80.0)
	write_short(ball_spriteexplode)
	write_byte(8)
	write_byte(15)
	write_byte(0)
	message_end()
	
     	new iOwner = entity_get_edict(Entity, EV_ENT_owner)
       
      	for(new i = 1; i <= 32 ; i++)
	{
		if(!is_user_alive(i) || zp_get_user_zombie(i))
			continue
          
		new Float:flVictimOrigin[3]
		pev (i, pev_origin, flVictimOrigin)
           
		new Float:flDistance = get_distance_f(flOrigin, flVictimOrigin)   
           
		if(flDistance <= get_pcvar_float(cvar_poisonballradius))
		{
			static Float:flSpeed
			flSpeed = get_pcvar_float (cvar_poisonballpower)
               
			static Float:flNewSpeed
			flNewSpeed = flSpeed * (1.0 - (flDistance / get_pcvar_float(cvar_poisonballradius)))
               
			static Float:flVelocity[3]
			get_speed_vector(flOrigin, flVictimOrigin, flNewSpeed, flVelocity)
               
			set_pev(i, pev_velocity,flVelocity)

			message_begin(MSG_ONE, g_msgScreenShake, {0,0,0}, i)
			write_short(1<<14)
			write_short(1<<14)
			write_short(1<<14)
			message_end()

			radius_damage_ab(flVictimOrigin, flOrigin , i , iOwner)

			if(!g_Alreadypoison[i] && get_pcvar_num(cvar_poison) == 1) 
			{
				g_Alreadypoison[i] = true
		
				Time[i] = get_pcvar_num(cvar_poisontime)
		
				poison(i)
			}
		}
	}
}       

public radius_damage_ab(Float:originF[3] , Float:flOrigin[3] , iVictim , iAttacker)
{
	if(g_roundend || !is_user_connected(iAttacker) || !is_user_connected(iVictim))
		return

	new Float:dist = get_distance_f(originF, flOrigin)
	new Float:dmg = get_pcvar_float(cvar_poisondmg) - (get_pcvar_float(cvar_poisondmg) / get_pcvar_float(cvar_poisonballradius)) * dist

	if(pev(iVictim,pev_health) - dmg <= 0) 
	{
		new headshot
		if(dist < 20.0) headshot = 1
		if(dist >= 20.0) headshot = 0
		message_begin(MSG_ALL, get_user_msgid("DeathMsg"),{0,0,0},0)
		write_byte(iAttacker)
		write_byte(iVictim)
		write_byte(headshot)
		write_string("poison")
		message_end()

		user_silentkill(iVictim)

		set_pev(iAttacker, pev_frags, float(pev(iAttacker, pev_frags) + 1))
		zp_set_user_ammo_packs(iAttacker, zp_get_user_ammo_packs(iAttacker) + 1)
		fm_cs_set_user_deaths(iVictim, cs_get_user_deaths(iVictim) + 1)

		message_begin(MSG_BROADCAST, g_msgScoreInfo)
		write_byte(iAttacker)
		write_short(pev(iAttacker, pev_frags))
		write_short(cs_get_user_deaths(iAttacker))
		write_short(0)
		write_short(fm_cs_get_user_team(iAttacker))
		message_end()
		
		message_begin(MSG_BROADCAST, g_msgScoreInfo)
		write_byte(iVictim)
		write_short(pev(iVictim, pev_frags))
		write_short(cs_get_user_deaths(iVictim))
		write_short(0)
		write_short(fm_cs_get_user_team(iVictim))
		message_end()

	}else{
		if(dmg > 0) set_pev(iVictim , pev_health , pev(iVictim,pev_health) - dmg)
		if(dmg <= 0) set_pev(iVictim , pev_health , pev(iVictim,pev_health) + dmg)
	}
}

public remove_values(id)
{
	remove_task(id)
	g_can[id] = 0
}

public ability_zero(id) 
{
	g_can[id] -= 1
	if(g_can[id]) set_task(1.0,"ability_zero",id)
}

public poison(victim)
{
	static Origin[3] ; get_user_origin(victim, Origin)
	
	if(Time[victim] <= 0 || get_entity_flags(victim) & FL_INWATER)
	{	
		message_begin(MSG_PVS, SVC_TEMPENTITY, Origin)
		write_byte(TE_SMOKE)
		write_coord(Origin[0])
		write_coord(Origin[1])
		write_coord(Origin[2]-50)
		write_short(sprSmoke)
		write_byte(random_num(15, 20))
		write_byte(random_num(10, 20))
		message_end()
		
		set_task(float(get_pcvar_num(cvar_poisontime)), "Stop", victim)
		
		return
	}
	else
	{		
		message_begin(MSG_PVS, SVC_TEMPENTITY, Origin)
		write_byte(TE_SPRITE)
		write_coord(Origin[0]+random_num(-5, 5))
		write_coord(Origin[1]+random_num(-5, 5))
		write_coord(Origin[2]+random_num(-10, 10))
		write_short(sprPoison)
		write_byte(random_num(5, 10))
		write_byte(200)
		message_end()
			
		Time[ victim ]--
		
		if(get_user_health(victim) -  get_pcvar_num(cvar_poisondmg2) > 0) set_user_health(victim, get_user_health(victim) -  get_pcvar_num(cvar_poisondmg2))
		
		if(get_user_health(victim) <=  get_pcvar_num(cvar_poisondmg2))
		{
			g_Alreadypoison[ victim ] = false
			return
		}
		set_task(0.5, "poison", victim)
	}
}

public Stop(victim)
{
	g_Alreadypoison[victim] = false
}

/*
public fw_PlayerSpawn_Post(id) 
{ 
	if(is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_nemesis(id)) 
	{
		fm_set_user_model_index(id, defaultindex)
	}
} 
*/

public fw_PlayerKilled(id, attacker, shouldgib) 
{
	remove_values(id)
}

public client_connect(id)  remove_values(id)

public zp_round_ended() g_roundend = 1

public zp_user_infected_post(id)	
{
	if((zp_get_user_zombie_class(id) == g_zclass_poison) && (zp_get_user_zombie(id)))
	{
		fm_set_user_model_index(id, index)
	}
	Time[ id ] = 0 
	g_Alreadypoison[id] = false
	remove_task(id)
}

public zp_user_humanized_post(id) 
{
	fm_set_user_model_index(id, defaultindex)

	remove_values(id)
}

public zp_user_infected_pre(id) 
{ 
    	if(!(get_user_flags(id) & ADMIN_BAN)) 
	{ 
        	if(zp_get_user_next_class(id) == g_zclass_poison) 
		{ 
            		zp_set_user_zombie_class(id, 0) 
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

stock UTIL_PlayPlayerAnimation(const id, const Sequence , Float:frame = 1.0 , Float:framerate = 1.0)
{
	entity_set_int(id, EV_INT_sequence, Sequence)
	entity_set_int(id, EV_INT_gaitsequence, 1)
	entity_set_float(id, EV_FL_frame, frame)
	entity_set_float(id, EV_FL_framerate, framerate)
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

stock fm_cs_set_user_deaths(id, value)
{
	set_pdata_int(id, 444, value, 5)
}

stock fm_cs_get_user_team(id)
{
	return get_pdata_int(id, 114, 5)
}

public Player_Duck(id)
{
	if(zp_get_user_zombie_class(id) == g_zclass_poison && zp_get_user_zombie(id))
	{
   		static button, ducking
   		button = pev(id, pev_button)
		ducking = pev(id, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND)

   		if(button & IN_DUCK || ducking)
		{
			set_pev(id, pev_view_ofs, {0.0, 0.0, 20.0})   
   		}
	}
}

stock fm_set_user_model_index(id, value)
{
    set_pdata_int(id, 491, value, 5)
}  
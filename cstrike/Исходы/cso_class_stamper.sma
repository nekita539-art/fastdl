#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <xs>

#define TASK_STAMP 1948
#define TASK_FREEZE 2105
#define TASK_COOLDOWN 7503
#define TASK_BOT 8209
#define TASK_HEALTH 3507
#define TASK_TIMER 11223
#define ID_STAMP (taskid - TASK_STAMP)
#define ID_FREEZE (taskid - TASK_FREEZE)
#define ID_COOLDOWN (taskid - TASK_COOLDOWN)
#define ID_BOT (taskid - TASK_BOT)
#define ID_HEALTH (taskid - TASK_HEALTH)

new const zclass_name[] = "• Гробовщик"
new const zclass_info[] = "\r[Гроб G] •"
new const zclass_model[] = "cso_class_stamper"
new const zclass_clawmodel[] = "v_stamper.mdl"
const zclass_health = 4500
const zclass_speed = 270
const Float:zclass_gravity = 0.75
const Float:zclass_knockback = 0.75

new KNOCKBOMB_STAMPER[] = "models/zombie_plague/v_jbomb_stamper.mdl"

new const g_stamper_infect_sound[][] =     
{    
    "zombie_plague/stamper_inf1.wav" , 
    "zombie_plague/stamper_inf2.wav"  
}  
new const pain_stamper_sound[] = "zombie_plague/stamper_hurt.wav"
new const death_stamper_sound[] = "zombie_plague/stamper_death.wav"

new const STAMP_CLASSNAME[] = "ent_coffin"
new const STAMP_SOUND_DROP[] = "zombie_plague/stamper_stamping.wav"
new const STAMP_SOUND_HIT[] = "debris/wood1.wav"
new const STAMP_SOUND_EXPLODE[] = "zombie_plague/stamper_explosion.wav"
new const STAMP_MODEL[] = "models/zombie_plague/stamper_stamping.mdl"

new g_spr_beam, g_spr_explode, g_spr_blast, g_spr_trapped
new g_zclass_stamper
new g_maxplayers
new g_msgScreenShake
new g_roundend
new g_stamping[33]
new g_cooldown[33]
new g_frozen[33]
/* new Float:g_temp_speed[33] */
new i_cooldown_time[33]

const UNIT_SECOND = (1<<12)
const BREAK_WOOD = 0x08

#define EXPLOSION_RADIUS 200.0
#define EXPLOSION_KNOCKBACK 1500.0
#define EXPLOSION_DAMAGE 10.0
#define SKILL_COOLDOWN 25.0
#define TIME_FREEZE 5.0
#define KOFFIN_HEALTH 300.0
#define HUMAN_TRAPPED_SPEED 0.5

public plugin_precache()
{
	precache_sound(STAMP_SOUND_DROP)
	precache_sound(STAMP_SOUND_HIT)
	precache_sound(STAMP_SOUND_EXPLODE)
	
	precache_model(STAMP_MODEL)
	
	precache_sound(pain_stamper_sound[0])
	new i
	for(i = 0 ; i < sizeof g_stamper_infect_sound ; i++) precache_sound(g_stamper_infect_sound[i]) 
	precache_sound(death_stamper_sound[0])
	precache_model(KNOCKBOMB_STAMPER)
	
	precache_sound("zombie_plague/stamper_clap.wav")
	precache_sound("zombie_plague/stamper_glove.wav")
	
	g_spr_beam = precache_model("sprites/shockwave.spr")
	g_spr_explode = precache_model("models/woodgibs.mdl")
	g_spr_blast = precache_model("sprites/texas1k/jbomb_exp.spr")
	g_spr_trapped = precache_model("sprites/texas1k/slowed.spr")
	
	g_zclass_stamper = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
}

public plugin_init()
{
	register_event("HLTV", "EventHLTV", "a", "1=0", "2=0")
	register_event("DeathMsg", "EventDeath", "a")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	register_event("CurWeapon","handle_gun","be","1=1")
	RegisterHam(Ham_TakeDamage, "player", "CPlayer__TakeDamage");
	register_forward(FM_EmitSound, "fw_EmitSound")
	
	register_clcmd("drop", "CmdStampCoffin")
	
	RegisterHam(Ham_TraceAttack, "info_target", "CoffinTraceAttack")
	RegisterHam(Ham_Think, "info_target", "CoffinThink")
	
	g_maxplayers = get_maxplayers()
	g_msgScreenShake = get_user_msgid("ScreenShake")
}

public client_putinserver(id)
{
	ResetValue(id)
}

public client_disconnect(id)
{
	ResetValue(id)
}

public EventHLTV()
{
	g_roundend = 0
	
	for(new id = 1; id <= g_maxplayers; id++)
	{
		if(is_user_connected(id)) ResetValue(id);
	}
}

public logevent_round_end()
{
	g_roundend = 1
	
	RemoveAllCoffin()
}

public EventDeath()
{
	new id = read_data(2)
	if(is_user_connected(id)) ResetValue(id);
}

public zp_user_humanized_post(id)
{
	ResetValue(id)
}

public zp_user_infected_post(id, infector, nemesis)
{
	ResetValue(id)
	
	if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass_stamper && !zp_get_user_nemesis(id))
	{
		emit_sound(id, CHAN_VOICE, g_stamper_infect_sound[random(sizeof g_stamper_infect_sound)],  VOL_NORM, ATTN_NORM, 0, PITCH_NORM) 
	
		if(is_user_bot(id))
		{
			set_task(random_float(6.0,15.0), "BotAutoSkill", id+TASK_BOT)
			return
		}
	}
}

/*public EventCurWeapon(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;
	
	if(g_frozen[id]) set_pev(id, pev_maxspeed, HUMAN_TRAPPED_SPEED);
	
	return PLUGIN_CONTINUE;
}*/

public CPlayer__TakeDamage(id, iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamage)
{
	if (zp_get_user_zombie_class(id) == g_zclass_stamper && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && !zp_get_user_survivor(id))
	{
		new rand = random_num(1,2)
		switch(rand)
  		{
			case 1: emit_sound(id, CHAN_WEAPON, pain_stamper_sound[0], 1.0, ATTN_NORM, 0, PITCH_LOW)
		}
	}
} 

public handle_gun(id)
{
	new weap = get_user_weapon(id)

	if(weap == CSW_FLASHBANG && zp_get_user_zombie_class(id) == g_zclass_stamper && zp_get_user_zombie(id))
	{
		entity_set_string(id, EV_SZ_viewmodel, KNOCKBOMB_STAMPER)
	}
	else if(weap == CSW_SMOKEGRENADE && zp_get_user_zombie_class(id) == g_zclass_stamper && zp_get_user_zombie(id))
	{
		entity_set_string(id, EV_SZ_viewmodel, KNOCKBOMB_STAMPER)
	}
	return PLUGIN_HANDLED
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_user_connected(id))
		return FMRES_HANDLED;	

	if (sample[0] == 'h' && sample[1] == 'o' && sample[2] == 's' && sample[3] == 't' && sample[4] == 'a' && sample[5] == 'g' && sample[6] == 'e')
		return FMRES_SUPERCEDE;


	if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass_stamper && !zp_get_user_nemesis(id))
	{
		if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
		{
			emit_sound(id, CHAN_WEAPON, death_stamper_sound[0], 1.0, ATTN_NORM, 0, PITCH_LOW)
		}
	}
	return FMRES_IGNORED;
}

public fw_PlayerPreThink(id)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED

	if(g_frozen[id]) set_speed_to_velocity(id, HUMAN_TRAPPED_SPEED)
	
	return PLUGIN_CONTINUE
}

public timer(id)
{	
	id=id-TASK_TIMER
	if (!is_user_alive(id)) 
	{
		return;
	}	
	
	if(i_cooldown_time[id] <= 0)
	{
		remove_task(id+TASK_TIMER)
		return
	}
		
	i_cooldown_time[id]--
	client_print(id, print_center, "Ждите %d сек", i_cooldown_time[id])
}

public CmdStampCoffin(id)
{
	if(g_roundend) return PLUGIN_CONTINUE
	
	if(!is_user_alive(id)) return PLUGIN_CONTINUE

	if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass_stamper && get_user_weapon(id) == CSW_KNIFE && !zp_get_user_nemesis(id))
	{
		if(!g_stamping[id] && !g_cooldown[id])
		{
			g_stamping[id] = 1
			i_cooldown_time[id] = 20
			
			PlayWeaponAnimation(id, 2)
			set_task(1.0 , "timer", id+TASK_TIMER, _, _, "b")
			set_task(0.2, "TaskSequence", id)
			set_task(0.5, "TaskStampCoffin", id+TASK_STAMP)
			
			return PLUGIN_HANDLED
		}
	}
	
	return PLUGIN_CONTINUE
}

public TaskSequence(id)
{
	PlayPlayerAnimation(id, 111);
}	

public TaskStampCoffin(taskid)
{
	g_stamping[ID_STAMP] = 0
	g_cooldown[ID_STAMP] = 1
	
	CreateCoffinCancer(ID_STAMP)
	
	set_task(SKILL_COOLDOWN, "ResetCooldown", ID_STAMP+TASK_COOLDOWN)
}

public ResetCooldown(taskid)
{
	g_cooldown[ID_COOLDOWN] = 0
}

public ResetFreeze(taskid)
{
	UnFreezePlayer(ID_FREEZE)
}

public BotAutoSkill(taskid)
{
	if(!is_user_alive(ID_BOT)) return;
	
	CmdStampCoffin(ID_BOT)
	set_task(random_float(6.0,15.0), "BotAutoSkill", ID_BOT+TASK_BOT)
}

public CoffinTraceAttack(ent, attacker, Float: damage, Float: direction[3], trace, damageBits)
{
	if(ent == attacker || !is_user_connected(attacker) || !is_valid_ent(ent)) return HAM_IGNORED;
	
	if(!(damageBits & DMG_BULLET)) return HAM_IGNORED;
	
	new className[32];
	entity_get_string(ent, EV_SZ_classname, className, charsmax(className))
	
	if(!equali(className, STAMP_CLASSNAME)) return HAM_IGNORED;
	
	new Float: end[3]
	get_tr2(trace, TR_vecEndPos, end);
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_SPARKS)
	engfunc(EngFunc_WriteCoord, end[0])
	engfunc(EngFunc_WriteCoord, end[1])
	engfunc(EngFunc_WriteCoord, end[2])
	message_end()
	
	emit_sound(ent, CHAN_VOICE, STAMP_SOUND_HIT,  VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	return HAM_IGNORED;
}

public CoffinThink(ent)
{
	if(!is_valid_ent(ent)) return;
	
	static className[32];
	entity_get_string(ent, EV_SZ_classname, className, charsmax(className))
	
	if(!equali(className, STAMP_CLASSNAME)) return;
	
	CoffinExplodeKaboom(ent)
}

CreateCoffinCancer(id)
{	
	new Float: origin[3], Float: angle[3], Float:angle2[3], Float:vector[3]
	entity_get_vector(id, EV_VEC_origin, origin)
	get_origin_distance(id, vector, 40.0)
	vector[2] += 25.0
	entity_get_vector(id, EV_VEC_angles, angle)
	new ent = create_entity("info_target")
	entity_set_string(ent, EV_SZ_classname, STAMP_CLASSNAME)
	entity_get_vector(ent, EV_VEC_angles, angle2)
	angle[0] = angle2[0]
	entity_set_vector(ent, EV_VEC_angles, angle)
	entity_set_origin(ent, vector)
	entity_set_float(ent, EV_FL_takedamage, 1.0)
	entity_set_float(ent, EV_FL_health, 1000.0+KOFFIN_HEALTH)
	entity_set_model(ent, STAMP_MODEL)
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_PUSHSTEP)
	entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
	new Float:mins[3] = {-10.0, -6.0, -36.0}
	new Float:maxs[3] = {10.0, 6.0, 36.0}
	entity_set_size(ent, mins, maxs)
	entity_set_int(ent, EV_INT_iuser2, id)
	drop_to_floor(ent)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2]+200.0)
	write_short(g_spr_beam)
	write_byte(0)
	write_byte(0)
	write_byte(4)
	write_byte(10)
	write_byte(0)
	write_byte(0)
	write_byte(205)
	write_byte(255)
	write_byte(200)
	write_byte(0)
	message_end()

	emit_sound(ent, CHAN_VOICE, STAMP_SOUND_DROP,  VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	set_task(0.2, "TaskCoffinHealth", ent+TASK_HEALTH, _, _, "b")
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + SKILL_COOLDOWN)
	
	static victim; victim = -1
	while((victim = find_ent_in_sphere(victim, origin, EXPLOSION_RADIUS)) != 0)
	{
		if(!is_user_alive(victim) || zp_get_user_zombie(victim) || g_frozen[victim]) continue;
		
		SetFreezePlayer(victim)
		CreateScreenShake(victim)
		set_task(TIME_FREEZE, "ResetFreeze", victim+TASK_FREEZE)
	}
	
	set_task(0.2, "CheckStuck", ent)
}

public CheckStuck(ent)
{
	if(!is_valid_ent(ent)) return;
	
	if(is_player_stuck(ent)) CoffinExplodeKaboom(ent);
}

public TaskCoffinHealth(taskid)
{
	if(!is_valid_ent(ID_HEALTH)) return;
	
	if(pev(ID_HEALTH, pev_health) < 1000.0) CoffinExplodeKaboom(ID_HEALTH);
}

CoffinExplodeKaboom(ent)
{
	if(!is_valid_ent(ent)) return;

	remove_task(ent+TASK_HEALTH)
	
	static Float:flOrigin[3]
	entity_get_vector(ent, EV_VEC_origin, flOrigin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, flOrigin[0])
	engfunc(EngFunc_WriteCoord, flOrigin[1])
	engfunc(EngFunc_WriteCoord, flOrigin[2])
	write_short(g_spr_blast)
	write_byte(40)
	write_byte(30)
	write_byte(14)
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0)
	write_byte(TE_BREAKMODEL)
	engfunc(EngFunc_WriteCoord, flOrigin[0])
	engfunc(EngFunc_WriteCoord, flOrigin[1])
	engfunc(EngFunc_WriteCoord, flOrigin[2]+24)
	engfunc(EngFunc_WriteCoord, 16)
	engfunc(EngFunc_WriteCoord, 16)
	engfunc(EngFunc_WriteCoord, 16)
	engfunc(EngFunc_WriteCoord, random_num(-50, 50))
	engfunc(EngFunc_WriteCoord, random_num(-50, 50))
	engfunc(EngFunc_WriteCoord, 25)
	write_byte(10)
	write_short(g_spr_explode)
	write_byte(10)
	write_byte(25)
	write_byte(BREAK_WOOD)
	message_end()
	
	emit_sound(ent, CHAN_VOICE, STAMP_SOUND_EXPLODE,  VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	static attacker; attacker = entity_get_int(ent, EV_INT_iuser2)
	
	if (!is_user_connected(attacker))
	{
		remove_entity(ent)
		return;
	}
	
	static victim; victim = -1
	
	while((victim = find_ent_in_sphere(victim, flOrigin, EXPLOSION_RADIUS)) != 0)
	{
		if(!is_user_alive(victim) || !is_valid_ent(victim)) continue;
		
		static Float:flVictimOrigin[3], Float:flDistance, Float:flSpeed, Float:flNewSpeed, Float:flVelocity[3]
		entity_get_vector(victim, EV_VEC_origin, flVictimOrigin)
		flDistance = get_distance_f(flOrigin, flVictimOrigin)
		flSpeed = EXPLOSION_KNOCKBACK
		flNewSpeed = flSpeed * (1.0 - (flDistance / EXPLOSION_RADIUS))
		GetSpeedVector(flOrigin, flVictimOrigin, flNewSpeed, flVelocity)
		entity_set_vector(victim, EV_VEC_velocity, flVelocity)
		CreateScreenShake(victim)
		
		if(get_user_health(victim) > EXPLOSION_DAMAGE) ExecuteHam(Ham_TakeDamage, victim, attacker, attacker, EXPLOSION_DAMAGE, DMG_BLAST);
		else ExecuteHamB(Ham_Killed, victim, attacker, 0);
	}
	
	remove_entity(ent)
}

PlayWeaponAnimation(id, animation)
{
	set_pev(id, pev_weaponanim, animation)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(animation)
	write_byte(pev(id, pev_body))
	message_end()
}

PlayPlayerAnimation(id, sequence, Float: framerate = 1.0) 
{
	set_pev(id, pev_animtime, get_gametime())
	set_pev(id, pev_framerate, framerate)
	set_pev(id, pev_frame, 0.0)
	set_pev(id, pev_sequence, sequence)
}

GetSpeedVector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
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

SetFreezePlayer(id)
{
	g_frozen[id] = 1
	client_print(id, print_center, "Вас замедляет гроб")
	CreateSlowSprites(id)
}

UnFreezePlayer(id)
{
	g_frozen[id] = 0
	if(zp_get_user_zombie(id)) return;
	client_print(id, print_center, "Вас больше не замедляет гроб")
	RemoveSlowSprites(id)
}

RemoveAllCoffin()
{	
	new ent
	ent = find_ent_by_class(-1, STAMP_CLASSNAME)
	
	while(ent > 0)
	{
		remove_task(ent+TASK_HEALTH)
		remove_entity(ent)
		ent = find_ent_by_class(-1, STAMP_CLASSNAME)
	}
}

get_origin_distance(index, Float:origin[3], Float:dist)
{
	new Float:start[3]
	new Float:view_ofs[3]
	
	pev(index, pev_origin, start)
	pev(index, pev_view_ofs, view_ofs)
	xs_vec_add(start, view_ofs, start)
	
	new Float:dest[3]
	pev(index, pev_angles, dest)
	
	engfunc(EngFunc_MakeVectors, dest)
	global_get(glb_v_forward, dest)
	
	xs_vec_mul_scalar(dest, dist, dest)
	xs_vec_add(start, dest, dest)
	
	engfunc(EngFunc_TraceLine, start, dest, 0, index, 0)
	get_tr2(0, TR_vecEndPos, origin)
	
	return 1
}

is_player_stuck(id)
{
	static Float:originF[3]
	pev(id, pev_origin, originF)
	
	engfunc(EngFunc_TraceHull, originF, originF, 0, (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, id, 0)
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true
	
	return false
}

CreateScreenShake(id)
{
	new shake[3]
	shake[0] = random_num(2,20)
	shake[1] = random_num(2,5)
	shake[2] = random_num(2,20)
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
	write_short(UNIT_SECOND*shake[0])
	write_short(UNIT_SECOND*shake[1])
	write_short(UNIT_SECOND*shake[2])
	message_end()
}

CreateSlowSprites(id)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(TE_PLAYERATTACHMENT)
	write_byte(id)
	write_coord(35)
	write_short(g_spr_trapped)
	write_short(999)
	message_end()
}

RemoveSlowSprites(id)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(TE_KILLPLAYERATTACHMENTS)
	write_byte(id)
	message_end()
}

ResetValue(id)
{
	if(g_frozen[id]) RemoveSlowSprites(id);
	
	g_stamping[id] = 0
	g_cooldown[id] = 0
	g_frozen[id] = 0
	i_cooldown_time[id] = 0

	remove_task(id+TASK_STAMP)
	remove_task(id+TASK_FREEZE)
	remove_task(id+TASK_COOLDOWN)
	remove_task(id+TASK_BOT)
	remove_task(id+TASK_TIMER)
}

stock set_speed_to_velocity(id, Float:scalar = 1.0)
{
	new Float:velocity[3]
	pev(id, pev_velocity, velocity)
	xs_vec_mul_scalar(velocity, scalar, velocity)
	velocity[2] = velocity[2]/scalar
	set_pev(id, pev_velocity, velocity)
	
	return 1
}
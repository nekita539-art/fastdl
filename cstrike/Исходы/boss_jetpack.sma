#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
native zp_get_user_zombie(id)
native zp_register_extra_item(const name[], cost, teams)

new const ClassnameJetPack[] = "n4d_jetpack"
new const ClassnameRocket[] = "n4d_bazooka"
new const ModelVJetPack[] = "models/boss_weapons/v_jetpcak_tutanhamon.mdl"
new const ModelPJetPack[] = "models/boss_weapons/p_jetpcak_tutanhamon.mdl"
new const ModelWJetPack[] = "models/boss_weapons/w_jetpcak_tutanhamon.mdl"
new const ModelRocket[] = "models/boss_weapons/s_jp_lycantrop.mdl"
new const SoundPickup[] = "boss_weapons/gunpickup2.wav"
new const SoundShoot[] = "boss_weapons/jp_lycantrop_shoot2.wav"
new const SoundTravel[] = "boss_weapons/bfuu.wav"
new const SoundFly[] = "boss_weapons/fly.wav"
new const SoundBlow[] = "boss_weapons/spjet_fly_end.wav"

new bool:bHasJetPack[33]
new Float:fJetpackFuel[33]
new Float:fLastShoot[33]
new SprExp, SprTrail, iAllocInfoTarget, iMaxClients, MsgSayText
new CvarMaxFuel, CvarRadius, CvarDamage, CvarSpeed, CvarCooldown, CvarRegen, CvarRocketSpeed
new Float:CMaxFuel, Float:CRadius, Float:CDamage, CSpeed, Float:CCooldown, Float:CRegen, CRocketSpeed
#define IsPlayer(%0) (1<=%0<=iMaxClients)
#define ZP_TEAM_HUMAN (1<<1)
#define ZP_PLUGIN_HANDLED 97
#define PevEntType pev_flSwimTime
#define EntTypeJetPack 3904
#define EntTypeRocket 9340

// Uncomment this to draw ring effect
#define DrawRing

// Uncomment this to draw flame effect
// #define DrawFlame

#if defined DrawRing
new SprRing
#endif

#if defined DrawFlame
new SprFlame
#endif

public plugin_precache()
{
	precache_sound(SoundPickup)
	precache_sound(SoundShoot)
	precache_sound(SoundTravel)
	precache_sound(SoundFly)
	precache_sound(SoundBlow)

	SprExp = precache_model("sprites/zerogxplode.spr")
	SprTrail = precache_model("sprites/boss_weapons/black_smoke1.spr")

	#if defined DrawFlame
	SprFlame = precache_model("sprites/boss_weapons/xfireball3.spr")
	#endif

	#if defined DrawRing
	SprRing = precache_model("sprites/boss_weapons/shockwave.spr")
	#endif

	precache_model(ModelVJetPack)
	precache_model(ModelPJetPack)
	precache_model(ModelWJetPack)
	precache_model(ModelRocket)
}

public plugin_init()
{
	register_plugin("New Jetpack", "0.0.2", "Bad_Bud,ZmOutStanding,Connor,wbyokomo")

	register_event("HLTV", "OnNewRound", "a", "1=0", "2=0")
	register_logevent("OnRoundEnd", 2, "1=Round_End")

	RegisterHam(Ham_Killed, "player", "OnPlayerKilled")
	RegisterHam(Ham_Player_Jump, "player", "OnPlayerJump")
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "OnKnifeSecAtkPost", 1)
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "OnKnifeDeployPost", 1)

	register_forward(FM_PlayerPreThink, "OnPlayerPreThink")
	register_forward(FM_Touch, "OnTouch")

	CvarMaxFuel = register_cvar("jp_maxfuel", "250.0")
	CvarRadius = register_cvar("jp_radius", "250.0")
	CvarDamage = register_cvar("jp_damage", "600.0")
	CvarSpeed = register_cvar("jp_speed", "300")
	CvarCooldown = register_cvar("jp_cooldown", "10.0")
	CvarRegen = register_cvar("jp_regen", "0.5")
	CvarRocketSpeed = register_cvar("jp_rocket_speed", "1500")

	iMaxClients = get_maxplayers()
	MsgSayText = get_user_msgid("SayText")
	//ItemJetPack = zp_register_extra_item("Jetpack", 35, ZP_TEAM_HUMAN)

	register_clcmd("drop", "CmdDropJP")
}

public plugin_cfg()
{
	iAllocInfoTarget = engfunc(EngFunc_AllocString, "info_target")
}

public client_putinserver(id)
{
	ResetValues(id)
}

public client_disconnect(id)
{
	ResetValues(id)
}

public OnNewRound()
{
	RemoveAllJetPack()
	CMaxFuel = get_pcvar_float(CvarMaxFuel)
	CRadius = get_pcvar_float(CvarRadius)
	CDamage = get_pcvar_float(CvarDamage)
	CSpeed = get_pcvar_num(CvarSpeed)
	CCooldown = get_pcvar_float(CvarCooldown)
	CRegen = get_pcvar_float(CvarRegen)
	CRocketSpeed = get_pcvar_num(CvarRocketSpeed)
}

public OnRoundEnd()
{
	RemoveAllJetPack()
}

public OnPlayerKilled(id)
{
	if(bHasJetPack[id]) DropJetPack(id);

	ResetValues(id)
}

public OnPlayerJump(id)
{
	if(bHasJetPack[id] && fJetpackFuel[id] > 0.0 && get_user_weapon(id) == CSW_KNIFE && pev(id, pev_button) & IN_DUCK && ~pev(id, pev_flags) & FL_ONGROUND)
	{
		static Float:vVelocity[3], Float:upSpeed
		pev(id, pev_velocity, vVelocity)
		upSpeed = vVelocity[2] + 35.0
		velocity_by_aim(id, CSpeed, vVelocity)
		vVelocity[2] = upSpeed > 300.0 ? 300.0 : upSpeed
		set_pev(id, pev_velocity, vVelocity)

		#if defined DrawFlame
		pev(id, pev_origin, vVelocity)
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vVelocity, 0)
		write_byte(TE_SPRITE)
		engfunc(EngFunc_WriteCoord, vVelocity[0])
		engfunc(EngFunc_WriteCoord, vVelocity[1])
		engfunc(EngFunc_WriteCoord, vVelocity[2])
		write_short(SprFlame)
		write_byte(8)
		write_byte(128)
		message_end()
		#endif

		fJetpackFuel[id] > 80.0 ? emit_sound(id, CHAN_STREAM, SoundFly, VOL_NORM, ATTN_NORM, 0,  PITCH_NORM) : emit_sound(id, CHAN_STREAM, SoundBlow, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		fJetpackFuel[id] -= 1.0
	}
}

public plugin_natives ()
{
	register_native("give_boss_jetpack", "native_give_weapon_add", 1)
}

public native_give_weapon_add(id)
{
	give_jetpack(id)
}

public zp_user_infected_pre(id)
{
	if(bHasJetPack[id]) DropJetPack(id);

	ResetValues(id)
}

public give_jetpack(id)
{
	if(bHasJetPack[id])
	{
		zp_colored_print(id, "^x04[ZP]^x01 You already have this item!")
		return ZP_PLUGIN_HANDLED;
	}

	bHasJetPack[id] = true
	zp_colored_print(id, "^x04[ZP]^x01 Чтобы использовать Джет:^x04 Пробел+CTRL^x01 -- нажми. |^x04 Удачи!^x01 -- Танатос джет :D")
	engclient_cmd(id, "weapon_knife")
	ReplaceModel(id)

	return PLUGIN_CONTINUE;
}

public OnKnifeSecAtkPost(ent2)
{
	if(pev_valid(ent2) == 2)
	{
		static id, Float:ctime
		id = get_pdata_cbase(ent2, 41, 4)
		ctime = get_gametime()
		if(is_user_alive(id) && bHasJetPack[id] && fLastShoot[id] < ctime)
		{
			new ent = engfunc(EngFunc_CreateNamedEntity, iAllocInfoTarget)
			if(ent)
			{
				engfunc(EngFunc_SetModel, ent, ModelRocket)
				engfunc(EngFunc_SetSize, ent, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0})
				new Float:fOrigin[3]
				pev(id, pev_origin, fOrigin)
				fOrigin[2] += 16.0
				engfunc(EngFunc_SetOrigin, ent, fOrigin)
				set_pev(ent, pev_classname, ClassnameRocket)
				set_pev(ent, pev_dmg, 100.0)
				set_pev(ent, pev_owner, id)
				velocity_by_aim(id, CRocketSpeed, fOrigin)
				set_pev(ent, pev_velocity, fOrigin)
				new Float:vecAngles[3]
				engfunc(EngFunc_VecToAngles, fOrigin, vecAngles)
				set_pev(ent, pev_angles, vecAngles)
				set_pev(ent, PevEntType, EntTypeRocket)	
				set_pev(ent, pev_movetype, MOVETYPE_FLY)
				set_pev(ent, pev_effects, EF_LIGHT)
				set_pev(ent, pev_solid, SOLID_BBOX)

				emit_sound(id, CHAN_STATIC, SoundShoot, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				emit_sound(ent, CHAN_WEAPON, SoundTravel, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

				message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
				write_byte(TE_BEAMFOLLOW)
				write_short(ent)
				write_short(SprTrail)
				write_byte(15)
				write_byte(15)
				write_byte(0)
			    write_byte(191)
			    write_byte(255)
				write_byte(192)
				message_end()

				fLastShoot[id] = ctime+CCooldown
			}
			else
			{
				client_print(id, print_chat, "[JpDebug] Failed to create rocket!")
				fLastShoot[id] = ctime+1.5
			}
		}
	}
}

public OnKnifeDeployPost(ent)
{
	if(pev_valid(ent) == 2)
	{
		static id; id = get_pdata_cbase(ent, 41, 4)
		if(is_user_alive(id) && bHasJetPack[id]) ReplaceModel(id);
	}
}

public OnPlayerPreThink(id)
{
	if(bHasJetPack[id] && fJetpackFuel[id] < CMaxFuel)
	{
		static button; button = pev(id, pev_button)
		if(!(button & IN_DUCK) && !(button & IN_JUMP)) fJetpackFuel[id] += CRegen;
	}
}

public OnTouch(ent, id)
{
	if(pev_valid(ent))
	{
		if(pev(ent, PevEntType) == EntTypeJetPack)
		{
			if(IsPlayer(id) && is_user_alive(id) && !zp_get_user_zombie(id) && !bHasJetPack[id])
			{
				engfunc(EngFunc_RemoveEntity, ent)
				bHasJetPack[id] = true
				emit_sound(id, CHAN_STATIC, SoundPickup, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				engclient_cmd(id,"weapon_knife")
				ReplaceModel(id)
			}
		}
		else if(pev(ent, PevEntType) == EntTypeRocket)
		{
			static Float:fOrigin[3]
			pev(ent, pev_origin, fOrigin)

			engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
			write_byte(TE_EXPLOSION)
			engfunc(EngFunc_WriteCoord, fOrigin[0])
			engfunc(EngFunc_WriteCoord, fOrigin[1])
			engfunc(EngFunc_WriteCoord, fOrigin[2])
			write_short(SprExp)
			write_byte(10)
			write_byte(30)
			write_byte(10)
			message_end()

			#if defined DrawRing
			engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
			write_byte(TE_BEAMCYLINDER)
			engfunc(EngFunc_WriteCoord, fOrigin[0])
			engfunc(EngFunc_WriteCoord, fOrigin[1])
			engfunc(EngFunc_WriteCoord, fOrigin[2])
			engfunc(EngFunc_WriteCoord, fOrigin[0])
			engfunc(EngFunc_WriteCoord, fOrigin[1])
			engfunc(EngFunc_WriteCoord, fOrigin[2]+555.0)
			write_short(SprRing)
			write_byte(0)
			write_byte(1)
			write_byte(6)
			write_byte(8)
			write_byte(10)
			write_byte(0)
		     write_byte(191)
			 write_byte(255)
			write_byte(192)
			write_byte(5)
			message_end()
			#endif

			static attacker; attacker = pev(ent, pev_owner)
			if(!is_user_connected(attacker))
			{
				engfunc(EngFunc_RemoveEntity, ent)
				return FMRES_IGNORED;
			}

			if(pev_valid(id) && !is_user_connected(id))
			{
				static szClassname[32]
				pev(id, pev_classname, szClassname, 31)
				if(equal(szClassname, "func_breakable") && (pev(id, pev_solid) != SOLID_NOT))
				{
					dllfunc(DLLFunc_Use, id, ent)
				}
			}

			static victim; victim = -1
			while((victim = engfunc(EngFunc_FindEntityInSphere, victim, fOrigin, CRadius)) != 0)
			{
				if(is_user_alive(victim) && zp_get_user_zombie(victim))
				{
					static Float:originV[3], Float:dist, Float:damage
					pev(victim, pev_origin, originV)
					dist = get_distance_f(fOrigin, originV)
					damage = CDamage-(CDamage/CRadius)*dist
					if(damage > 0.0)
					{
						ExecuteHamB(Ham_TakeDamage, victim, ent, attacker, damage, DMG_BULLET)
						// client_print(attacker, print_chat, "[JpDebug] Rocket damage: %.1f", damage)
					}
				}
			}

			engfunc(EngFunc_RemoveEntity, ent)
		}
	}

	return FMRES_IGNORED;
}

public CmdDropJP(id)
{
	if(is_user_alive(id) && bHasJetPack[id] && get_user_weapon(id) == CSW_KNIFE)
	{
		DropJetPack(id)
		ResetValues(id)
		set_pev(id, pev_viewmodel2, "models/v_knife.mdl")
		set_pev(id, pev_weaponmodel2, "models/p_knife.mdl")
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

ReplaceModel(id)
{
	set_pev(id, pev_viewmodel2, ModelVJetPack)
	set_pev(id, pev_weaponmodel2, ModelPJetPack)
}

DropJetPack(id)
{
	new Float:fAim[3], Float:fOrigin[3]
	velocity_by_aim(id, 64, fAim)
	pev(id, pev_origin, fOrigin)
	fOrigin[0] += fAim[0]
	fOrigin[1] += fAim[1]

	new ent = engfunc(EngFunc_CreateNamedEntity, iAllocInfoTarget)
	if(ent)
	{
		engfunc(EngFunc_SetModel, ent, ModelWJetPack)
		engfunc(EngFunc_SetSize, ent, Float:{-4.0,-4.0,-4.0}, Float:{4.0,4.0,4.0})
		engfunc(EngFunc_SetOrigin, ent, fOrigin)
		set_pev(ent, pev_classname, ClassnameJetPack)
		set_pev(ent, pev_dmg, 100.0)
		set_pev(ent, PevEntType, EntTypeJetPack)
		set_pev(ent, pev_movetype, MOVETYPE_TOSS)
		set_pev(ent, pev_solid, SOLID_TRIGGER)
	}
}

RemoveAllJetPack()
{
	new ent = engfunc(EngFunc_FindEntityByString, -1, "classname", ClassnameJetPack)
	while(ent > 0)
	{
		engfunc(EngFunc_RemoveEntity, ent)
		ent = engfunc(EngFunc_FindEntityByString, -1, "classname", ClassnameJetPack)
	}
}

ResetValues(id)
{
	bHasJetPack[id] = false
	fJetpackFuel[id] = get_pcvar_float(CvarMaxFuel)
}

zp_colored_print(target, const message[], any:...)
{
	static buffer[512], i, argscount
	argscount = numargs()

	if (!target)
	{
		static iPlayers[32], iNum, j, player
		get_players(iPlayers, iNum, "ch")
		for (j = 0; j < iNum; j++)
		{
			player = iPlayers[j]
			static changed[5], changedcount
			changedcount = 0

			for (i = 2; i < argscount; i++)
			{
				if (getarg(i) == LANG_PLAYER)
				{
					setarg(i, 0, player)
					changed[changedcount] = i
					changedcount++
				}
			}

			vformat(buffer, charsmax(buffer), message, 3)
			message_begin(MSG_ONE_UNRELIABLE, MsgSayText, _, player)
			write_byte(player)
			write_string(buffer)
			message_end()

			for (i = 0; i < changedcount; i++) setarg(changed[i], 0, LANG_PLAYER);
		}
	}
	else
	{
		vformat(buffer, charsmax(buffer), message, 3)
		message_begin(MSG_ONE, MsgSayText, _, target)
		write_byte(target)
		write_string(buffer)
		message_end()
	}
}

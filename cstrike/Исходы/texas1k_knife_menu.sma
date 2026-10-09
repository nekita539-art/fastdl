#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <fakemeta>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>

native zp_get_user_level(id)

native native_knifes_menu(id)

#define TASK_FBURN				100
#define ID_FBURN                ( taskid - TASK_FBURN )

#define MAX_CLIENTS				32

new bool:g_fRoundEnd

#define FIRE_DURATION			1
#define FIRE_DAMAGE				255

const Float:TIME_FREEZE			=	0.0
const Float:TIME_WAIT_FREEZE		=	10.0

new g_flameSpr, g_flameSpr2, g_flameSpr3, g_smokeSpr, g_burning_duration[ MAX_CLIENTS + 1 ]
new g_freeze_wait[33]
new g_frozen[33], g_SpriteGlass

#define PLUGIN    "[ZP] Knifes: Bo3Me3DiE 3oM6u"
#define VERSION    "1.0"
#define AUTHOR    "Edition by texas1k"

#define VIP ADMIN_RESERVATION
#define ADMIN ADMIN_KICK
#define BOSS ADMIN_BAN
#define BUFF ADMIN_SLAY
#define LEVEL 15
#define LEVEL1 25

new KNIFE1_V_MODEL[] = "models/texas1k_knifes/v_knife.mdl"
new KNIFE1_P_MODEL[] = "models/texas1k_knifes/p_knife.mdl"

new KNIFE2_V_MODEL[] = "models/texas1k_knifes/v_fire_knife.mdl"
new KNIFE2_P_MODEL[] = "models/texas1k_knifes/p_fire_knife.mdl"

new KNIFE3_V_MODEL[] = "models/texas1k_knifes/v_katana_dragon.mdl"
new KNIFE3_P_MODEL[] = "models/texas1k_knifes/p_katana_dragon.mdl"

new KNIFE4_V_MODEL[] = "models/texas1k_knifes/v_demon_kopie.mdl"
new KNIFE4_P_MODEL[] = "models/texas1k_knifes/p_demon_kopie.mdl"

new KNIFE5_V_MODEL[] = "models/texas1k_knifes/v_red_topor.mdl"
new KNIFE5_P_MODEL[] = "models/texas1k_knifes/p_red_topor.mdl"

new KNIFE6_V_MODEL[] = "models/texas1k_knifes/v_knife1.mdl"
new KNIFE6_P_MODEL[] = "models/texas1k_knifes/p_knife1.mdl"

new KNIFE7_V_MODEL[] = "models/texas1k_knifes/v_storm_sword.mdl"
new KNIFE7_P_MODEL[] = "models/texas1k_knifes/p_storm_sword.mdl"

new KNIFE8_V_MODEL[] = "models/texas1k_knifes/v_hammer_firework.mdl"
new KNIFE8_P_MODEL[] = "models/texas1k_knifes/p_hammer_firework.mdl"

new KNIFE9_V_MODEL[] = "models/texas1k_knifes/v_knife5.mdl"
new KNIFE9_P_MODEL[] = "models/texas1k_knifes/p_knife5.mdl"

new KNIFESURV_V_MODEL[] = "models/texas1k_knifes/v_molot_tora.mdl"
new KNIFESURV_P_MODEL[] = "models/texas1k_knifes/p_molot_tora.mdl"

new const g_SpriteGlasses[] = "models/glassgibs.mdl"

new bool:g_KNIFE1[33]
new bool:g_KNIFE2[33]
new bool:g_KNIFE3[33]
new bool:g_KNIFE4[33]
new bool:g_KNIFE5[33]
new bool:g_KNIFE6[33]
new bool:g_KNIFE7[33]
new bool:g_KNIFE8[33]
new bool:g_KNIFE9[33]
new bool:g_has_survivor[33]
new bool:g_hasSpeed[33]

new g_knife_menu, cvar_knock, cvar_jump, cvar_dmgmult1, cvar_dmgmult2, cvar_dmgmult3, cvar_knife_spd
new cvar_jump_vip, cvar_dmgmult_vip, cvar_dmgmult_admin, cvar_dmgmult_boss, cvar_dmgmult_buff, cvar_dmgmult_surv, cvar_knife_spd_vip, cvar_knock_vip

new const g_sound_knife[] = { "items/gunpickup2.wav" }

new const a_sounds[][] =
{
	"texas1k_knifes/Skull/knife_draw_fix.wav",
	"texas1k_knifes/Skull/knife_hit_fix.wav",
	"texas1k_knifes/Skull/knife_hit_fix.wav",
	"texas1k_knifes/Skull/knife_wall_fix.wav",
	"texas1k_knifes/Skull/knife_slash_fix.wav",
	"texas1k_knifes/Skull/knife_hit_fix.wav"
}

new const b_sounds[][] =
{
	"texas1k_knifes/katana/katanadhw_draw.wav",
	"texas1k_knifes/katana/katanadhw_hit1.wav",
	"texas1k_knifes/katana/katanadhw_hit1.wav",
	"texas1k_knifes/katana/katanadhw_hitwall.wav",
	"texas1k_knifes/katana/katanadhw_slash1.wav",
	"texas1k_knifes/katana/katanadhw_stab.wav"
}

new const c_sounds[][] =
{
	"texas1k_knifes/Skull/knife_draw_fix.wav",
	"texas1k_knifes/Skull/knife_hit_fix.wav",
	"texas1k_knifes/Skull/knife_hit_fix.wav",
	"texas1k_knifes/Skull/knife_wall_fix.wav",
	"texas1k_knifes/Skull/knife_slash_fix.wav",
	"texas1k_knifes/Skull/knife_hit_fix.wav"
}

new const d_sounds[][] =
{
	"texas1k_knifes/Skull/knife_draw_fix.wav",
	"texas1k_knifes/Skull/knife_hit_fix.wav",
	"texas1k_knifes/Skull/knife_hit_fix.wav",
	"texas1k_knifes/Skull/knife_wall_fix.wav",
	"texas1k_knifes/Skull/knife_slash_fix.wav",
	"texas1k_knifes/Skull/knife_hit_fix.wav"
}

new const e_sounds[][] =
{
	"texas1k_knifes/Skull/knife_draw_fix.wav",
	"texas1k_knifes/Skull/knife_hit_fix.wav",
	"texas1k_knifes/Skull/knife_hit_fix.wav",
	"texas1k_knifes/Skull/knife_wall_fix.wav",
	"texas1k_knifes/Skull/knife_slash_fix.wav",
	"texas1k_knifes/Skull/knife_hit_fix.wav"
}

new const f_sounds[][] =
{
	"texas1k_knifes/Skull/knife_draw_fix.wav",
	"texas1k_knifes/Skull/knife_hit_fix.wav",
	"texas1k_knifes/Skull/knife_hit_fix.wav",
	"texas1k_knifes/Skull/knife_wall_fix.wav",
	"texas1k_knifes/Skull/knife_slash_fix.wav",
	"texas1k_knifes/Skull/knife_hit_fix.wav"
}

new const g_sounds[][] =
{
	"texas1k_knifes/warhammer/stormgiant_draw.wav",
	"texas1k_knifes/warhammer/buffkatana_hit1.wav",
	"texas1k_knifes/warhammer/buffkatana_hit1.wav",
	"texas1k_knifes/warhammer/buffkatana_hitwall1.wav",
	"texas1k_knifes/warhammer/buffkatana_slash1.wav",
	"texas1k_knifes/warhammer/buffkatana_stab.wav"
}

new const s_sounds[][] =
{
	"texas1k_knifes/warhammer/stormgiant_draw.wav",
	"texas1k_knifes/warhammer/buffkatana_hit1.wav",
	"texas1k_knifes/warhammer/buffkatana_hit1.wav",
	"texas1k_knifes/warhammer/buffkatana_hitwall1.wav",
	"texas1k_knifes/warhammer/buffkatana_slash1.wav",
	"texas1k_knifes/warhammer/buffkatana_stab.wav"
}

new const surv_sounds[][] =
{
	"texas1k_knifes/surv/chainsaw2_draw.wav",
	"texas1k_knifes/surv/chainsaw2_hit1.wav",
	"texas1k_knifes/surv/chainsaw2_hit1.wav",
	"texas1k_knifes/surv/chainsaw2_hitwall1.wav",
	"texas1k_knifes/surv/chainsaw2_slash1.wav",
	"texas1k_knifes/surv/chainsaw2_stab.wav"
}

new const pre_sounds[][] =
{
	"texas1k_knifes/surv/chainsaw_idle.wav",
	"texas1k_knifes/surv/chainsaw_steam.wav"
}

public plugin_init()
{
	register_plugin(PLUGIN , VERSION , AUTHOR);
	register_cvar("zp_addon_knife", VERSION, FCVAR_SERVER);
	
	register_forward(FM_AddToFullPack, "fw_PlayerAddToFullPack", 1 );
	
	RegisterHam(Ham_Spawn, "player", "fw_playerspawn_post", 1)

 	g_knife_menu = menu_create("Ножи","menu_handle")
 	register_clcmd("knife_zb", "knifemenu", ADMIN_ALL, "knife_menu")
	build_menu()

	register_event("CurWeapon","checkWeapon","be","1=1");
	register_forward(FM_EmitSound, "CEntity__EmitSound");
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)

	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg");

	cvar_knock		= register_cvar("zp_knife_power"		, "5");
	cvar_jump		= register_cvar("zp_knife_jump"			, "350.0");
	cvar_dmgmult1		= register_cvar("zp_knife_dmg_muiti1"		, "15");
	cvar_dmgmult2		= register_cvar("zp_knife_dmg_muiti2"		, "10");
	cvar_dmgmult3		= register_cvar("zp_knife_dmg_muiti3"		, "5");
	cvar_knife_spd		= register_cvar("zp_knife_spd"			, "280");
	cvar_jump_vip		= register_cvar("zp_knife_jump_vip"		, "400.0");
	cvar_dmgmult_vip	= register_cvar("zp_knife_dmg_vip"		, "20");
	cvar_dmgmult_admin	= register_cvar("zp_knife_dmg_admin"		, "25");
	cvar_dmgmult_boss	= register_cvar("zp_knife_dmg_boss"		, "30");
	cvar_dmgmult_buff	= register_cvar("zp_knife_dmg_buff"		, "35");
	cvar_dmgmult_surv	= register_cvar("zp_knife_dmg_surv"		, "40");
	cvar_knife_spd_vip	= register_cvar("zp_knife_spd_vip"		, "320");
	cvar_knock_vip		= register_cvar("zp_knife_power_vip"		, "10");
}

public fw_PlayerAddToFullPack( ES_Handle, E, pEnt, pHost, bsHostFlags, pPlayer, pSet )
{       
	if( pPlayer && get_user_weapon(pEnt) == CSW_KNIFE && g_has_survivor[pEnt] && !zp_get_user_zombie(pEnt))
	{
		static iAnim;

		iAnim = get_es( ES_Handle, ES_Sequence );

		switch( iAnim )
		{
			case 73, 74, 75, 76:
			{
				set_es( ES_Handle, ES_Sequence, iAnim += 22 );
			}
		}
	}
	
	if( pPlayer && get_user_weapon(pEnt) == CSW_KNIFE && g_KNIFE9[pEnt] && !zp_get_user_zombie(pEnt))
	{
		static iAnim;

		iAnim = get_es( ES_Handle, ES_Sequence );

		switch( iAnim )
		{
			case 73, 74, 75, 76:
			{
				set_es( ES_Handle, ES_Sequence, iAnim += 10 );
			}
		}
	}
	return FMRES_IGNORED;
}

public plugin_natives()
{
	register_native("native_knifes_menu", "native_knifes", 1)
}

public native_knifes(id)
{
	client_cmd(id, "native_menu_choose_knifes_by_inf_2017")
}

public client_connect(id)
{
	g_KNIFE1[id] = false
	g_KNIFE2[id] = false
	g_KNIFE3[id] = false
	g_KNIFE4[id] = false
	g_KNIFE5[id] = false
	g_KNIFE6[id] = false
	g_KNIFE7[id] = false
	g_KNIFE8[id] = false
	g_KNIFE9[id] = false
	g_has_survivor[id] = false
	g_hasSpeed[id] = false
}

public client_disconnect(id)
{
	g_KNIFE1[id] = false
	g_KNIFE2[id] = false
	g_KNIFE3[id] = false
	g_KNIFE4[id] = false
	g_KNIFE5[id] = false
	g_KNIFE6[id] = false
	g_KNIFE7[id] = false
	g_KNIFE8[id] = false
	g_KNIFE9[id] = false
	g_has_survivor[id] = false
	g_hasSpeed[id] = false
}

public zp_user_humanized_post(iPlayer) 
{
	if(zp_get_user_survivor(iPlayer)) 
	{
		buy_knife_surv(iPlayer)
	}
	else ChekKnife(iPlayer)
}

public plugin_precache()
{
	precache_model(KNIFE1_V_MODEL)
	precache_model(KNIFE1_P_MODEL)
	precache_model(KNIFE2_V_MODEL)
	precache_model(KNIFE2_P_MODEL)
	precache_model(KNIFE3_V_MODEL)
	precache_model(KNIFE3_P_MODEL)
	precache_model(KNIFE4_V_MODEL)
	precache_model(KNIFE4_P_MODEL)
	precache_model(KNIFE5_V_MODEL)
	precache_model(KNIFE5_P_MODEL)
	precache_model(KNIFE6_V_MODEL)
	precache_model(KNIFE6_P_MODEL)
	precache_model(KNIFE7_V_MODEL)
	precache_model(KNIFE7_P_MODEL)
	precache_model(KNIFE8_V_MODEL)
	precache_model(KNIFE8_P_MODEL)
	precache_model(KNIFE9_V_MODEL)
	precache_model(KNIFE9_P_MODEL)
	precache_model(KNIFESURV_V_MODEL)
	precache_model(KNIFESURV_P_MODEL)

	precache_sound(g_sound_knife)

	for(new i = 0; i < sizeof a_sounds; i++)
	precache_sound(a_sounds[i])

	for(new i = 0; i < sizeof b_sounds; i++)
	precache_sound(b_sounds[i])

	for(new i = 0; i < sizeof c_sounds; i++)
	precache_sound(c_sounds[i])

	for(new i = 0; i < sizeof d_sounds; i++)
	precache_sound(d_sounds[i])

	for(new i = 0; i < sizeof e_sounds; i++)
	precache_sound(e_sounds[i])

	for(new i = 0; i < sizeof f_sounds; i++)
	precache_sound(f_sounds[i])
	
	for(new i = 0; i < sizeof g_sounds; i++)
	precache_sound(g_sounds[i])
	
	for(new i = 0; i < sizeof s_sounds; i++)
	precache_sound(g_sounds[i])

	for(new i = 0; i < sizeof surv_sounds; i++)
	precache_sound(surv_sounds[i]) 
	
	for(new i = 0; i < sizeof pre_sounds; i++)
	precache_sound(pre_sounds[i]) 

	g_flameSpr = precache_model( "sprites/texas1k_knifes/stun_effect.spr" );
	g_flameSpr2 = precache_model( "sprites/texas1k_knifes/stun_effect.spr" );
	g_flameSpr3 = precache_model( "sprites/texas1k_knifes/hell_exp_flame_1.spr" );
	
	g_smokeSpr = precache_model( "sprites/black_smoke3.spr" );
	
	g_SpriteGlass = precache_model(g_SpriteGlasses);
}

build_menu()
{
	menu_additem(g_knife_menu, "\w• Томагавк \r[Урон] \w•", "1")
	menu_additem(g_knife_menu, "\w• Нож Силы \r[Отброс] \w•", "2")
	menu_additem(g_knife_menu, "\w• Меч \r[Прыжок] \w•^n", "3")
	menu_additem(g_knife_menu, "\y• Копье \r[Скорость] \y[15 LvL] \y•", "4")
	menu_additem(g_knife_menu, "\y• Топор \r[2 прыжка] \y[25 LvL] \y•^n", "5")
	menu_additem(g_knife_menu, "\y• Зеленые Катаны \r[VIP] \y•", "6")
	menu_additem(g_knife_menu, "\y• Штурмовой Меч \r[ADMIN] \y•", "7")
	menu_additem(g_knife_menu, "\y• Хаммер Firework \r[BOSS] \y•", "8")
	menu_additem(g_knife_menu, "\y• Вархаммер \r[DIAMOND] \y•", "9")
	menu_setprop(g_knife_menu, MPROP_PERPAGE, 0)
}

public knifemenu(id)
{
	if (zp_has_round_started())
	return PLUGIN_HANDLED

	if (!zp_has_round_started())
	{
 		menu_display(id, g_knife_menu, 0)
	}
 	return PLUGIN_HANDLED
}

public menu_handle(id, menu, item)
{
 	if(item < 0) return PLUGIN_CONTINUE
 	new cmd[2];
 	new access, callback;
 	menu_item_getinfo(menu, item, access, cmd,2,_,_, callback);
 	new choice = str_to_num(cmd)
 	switch (choice)
	{
		case 1: buy_knife1(id)
		case 2: buy_knife2(id)
		case 3: buy_knife3(id)
		case 4: buy_knife4(id)
		case 5: buy_knife5(id)
		case 6: buy_knife6(id)
		case 7: buy_knife7(id)
		case 8: buy_knife8(id)
		case 9: buy_knife9(id)
	}
 	return PLUGIN_HANDLED;
} 

public buy_knife1(id)
{
	g_KNIFE1[id] = true	
	g_KNIFE2[id] = false	
	g_KNIFE3[id] = false
	g_KNIFE4[id] = false
	g_KNIFE5[id] = false
	g_KNIFE6[id] = false
	g_KNIFE7[id] = false
	g_KNIFE8[id] = false
	g_KNIFE9[id] = false
	g_has_survivor[id] = false
	g_hasSpeed[id] = false
	
	checkWeapon(id)

	engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public buy_knife2(id)
{
	g_KNIFE1[id] = false	
	g_KNIFE2[id] = true	
	g_KNIFE3[id] = false
	g_KNIFE4[id] = false
	g_KNIFE5[id] = false
	g_KNIFE6[id] = false
	g_KNIFE7[id] = false
	g_KNIFE8[id] = false
	g_KNIFE9[id] = false
	g_has_survivor[id] = false
	g_hasSpeed[id] = false
	
	checkWeapon(id)

	engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
}	

public buy_knife3(id)
{
	g_KNIFE1[id] = false	
	g_KNIFE2[id] = false	
	g_KNIFE3[id] = true
	g_KNIFE4[id] = false
	g_KNIFE5[id] = false
	g_KNIFE6[id] = false
	g_KNIFE7[id] = false
	g_KNIFE8[id] = false
	g_KNIFE9[id] = false
	g_has_survivor[id] = false
	g_hasSpeed[id] = true
	
	checkWeapon(id)

	engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public buy_knife4(id)
{
    if(zp_get_user_level(id) >= LEVEL)
	{
		g_KNIFE1[id] = false	
		g_KNIFE2[id] = false	
		g_KNIFE3[id] = false
		g_KNIFE4[id] = true
		g_KNIFE5[id] = false
		g_KNIFE6[id] = false
		g_KNIFE7[id] = false
		g_KNIFE8[id] = false
		g_KNIFE9[id] = false
		g_has_survivor[id] = false
		g_hasSpeed[id] = true
		
		checkWeapon(id)

		engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}	
	else 
	{
		zp_get_user_level(id)
	}
}

public buy_knife5(id)
{
	if(zp_get_user_level(id) >= LEVEL1)
	{
		g_KNIFE1[id] = false	
		g_KNIFE2[id] = false	
		g_KNIFE3[id] = false
		g_KNIFE4[id] = false
		g_KNIFE5[id] = true
		g_KNIFE6[id] = false
		g_KNIFE7[id] = false
		g_KNIFE8[id] = false
		g_KNIFE9[id] = false
		g_has_survivor[id] = false
		g_hasSpeed[id] = true
		
		checkWeapon(id)

		engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	else 
	{
		zp_get_user_level(id)
	}

}

public buy_knife6(id)
{
	if (get_user_flags(id) & VIP)
	{
		g_KNIFE1[id] = false	
		g_KNIFE2[id] = false	
		g_KNIFE3[id] = false
		g_KNIFE4[id] = false
		g_KNIFE5[id] = false
		g_KNIFE6[id] = true
		g_KNIFE7[id] = false
		g_KNIFE8[id] = false
		g_KNIFE9[id] = false
		g_has_survivor[id] = false
		g_hasSpeed[id] = true
		
		checkWeapon(id)

		engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	else 
	{
		native_knifes_menu(id)
	}

}

public buy_knife7(id)
{
	if (get_user_flags(id) & ADMIN)
	{
		g_KNIFE1[id] = false	
		g_KNIFE2[id] = false	
		g_KNIFE3[id] = false
		g_KNIFE4[id] = false
		g_KNIFE5[id] = false
		g_KNIFE6[id] = false
		g_KNIFE7[id] = true
		g_KNIFE8[id] = false
		g_KNIFE9[id] = false
		g_has_survivor[id] = false
		g_hasSpeed[id] = true
		
		checkWeapon(id)

		engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	else 
	{
		native_knifes_menu(id)
	}

}

public buy_knife8(id)
{
	if (get_user_flags(id) & BOSS)
	{
		g_KNIFE1[id] = false	
		g_KNIFE2[id] = false	
		g_KNIFE3[id] = false
		g_KNIFE4[id] = false
		g_KNIFE5[id] = false
		g_KNIFE6[id] = false
		g_KNIFE7[id] = false
		g_KNIFE8[id] = true
		g_KNIFE9[id] = false
		g_has_survivor[id] = false
		g_hasSpeed[id] = true
		
		checkWeapon(id)

		engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	else 
	{
		native_knifes_menu(id)
	}

}

public buy_knife9(id)
{
	if (get_user_flags(id) & BUFF)
	{
		g_KNIFE1[id] = false	
		g_KNIFE2[id] = false	
		g_KNIFE3[id] = false
		g_KNIFE4[id] = false
		g_KNIFE5[id] = false
		g_KNIFE6[id] = false
		g_KNIFE7[id] = false
		g_KNIFE8[id] = false
		g_KNIFE9[id] = true
		g_has_survivor[id] = false
		g_hasSpeed[id] = true
		
		checkWeapon(id)

		engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	else 
	{
		native_knifes_menu(id)
	}

}

public buy_knife_surv(id)
{
	g_KNIFE1[id] = false	
	g_KNIFE2[id] = false	
	g_KNIFE3[id] = false
	g_KNIFE4[id] = false
	g_KNIFE5[id] = false
	g_KNIFE6[id] = false
	g_KNIFE7[id] = false
	g_KNIFE8[id] = false
	g_KNIFE9[id] = false
	g_has_survivor[id] = true
	g_hasSpeed[id] = true
	
	checkWeapon(id)

	engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public fw_playerspawn_post(id)
{
	if(!is_user_alive(id))
	return;
	
	ChekKnife(id)
	
	return;
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{	
	if (use_type == 0 && is_user_connected(caller))
	checkWeapon(caller)
}

public checkWeapon(id)
{
	new plrWeapId
    
	plrWeapId = get_user_weapon(id)
    
	if (plrWeapId == CSW_KNIFE && (g_KNIFE1[id] || g_KNIFE2[id] || g_KNIFE3[id] || g_KNIFE4[id] || g_KNIFE5[id] || g_KNIFE6[id] || g_KNIFE7[id] || g_KNIFE8[id] || g_KNIFE9[id] || g_has_survivor[id]))
	{
		checkModel(id)
	}
}

public checkModel(id)
{
	if (zp_get_user_zombie(id))
	return PLUGIN_HANDLED
    
	if (g_KNIFE1[id])
	{
		set_pev(id, pev_viewmodel2, KNIFE1_V_MODEL)
		set_pev(id, pev_weaponmodel2, KNIFE1_P_MODEL)
	}

	if (g_KNIFE2[id])
	{
		set_pev(id, pev_viewmodel2, KNIFE2_V_MODEL)
		set_pev(id, pev_weaponmodel2, KNIFE2_P_MODEL)
	}

	if (g_KNIFE3[id])
	{
		set_pev(id, pev_viewmodel2, KNIFE3_V_MODEL)
		set_pev(id, pev_weaponmodel2, KNIFE3_P_MODEL)
	}

	if (g_KNIFE4[id])
	{
		set_pev(id, pev_viewmodel2, KNIFE4_V_MODEL)
		set_pev(id, pev_weaponmodel2, KNIFE4_P_MODEL)
	}
	
	if (g_KNIFE5[id])
	{
		set_pev(id, pev_viewmodel2, KNIFE5_V_MODEL)
		set_pev(id, pev_weaponmodel2, KNIFE5_P_MODEL)
	}
	
	if (g_KNIFE6[id])
	{
		set_pev(id, pev_viewmodel2, KNIFE6_V_MODEL)
		set_pev(id, pev_weaponmodel2, KNIFE6_P_MODEL)
	}
	
	if (g_KNIFE7[id])
	{
		set_pev(id, pev_viewmodel2, KNIFE7_V_MODEL)
		set_pev(id, pev_weaponmodel2, KNIFE7_P_MODEL)
	}
	
	if (g_KNIFE8[id])
	{
		set_pev(id, pev_viewmodel2, KNIFE8_V_MODEL)
		set_pev(id, pev_weaponmodel2, KNIFE8_P_MODEL)
	}
	
	if (g_KNIFE9[id])
	{
		set_pev(id, pev_viewmodel2, KNIFE9_V_MODEL)
		set_pev(id, pev_weaponmodel2, KNIFE9_P_MODEL)
	}
	
	if (g_has_survivor[id])
	{
		set_pev(id, pev_viewmodel2, KNIFESURV_V_MODEL)
		set_pev(id, pev_weaponmodel2, KNIFESURV_P_MODEL)
	}
	return PLUGIN_HANDLED
}

public CEntity__EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (!is_user_connected(id)) 
		return HAM_IGNORED
	
	if (zp_get_user_zombie(id)) 
		return HAM_IGNORED
	
	if (sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
	{
		if (sample[14] == 'd') 
		{
			if(g_KNIFE1[id])
				emit_sound(id, channel, a_sounds[0], volume, attn, flags, pitch)
			if(g_KNIFE2[id])
				emit_sound(id, channel, b_sounds[0], volume, attn, flags, pitch)
			if(g_KNIFE3[id])
				emit_sound(id, channel, c_sounds[0], volume, attn, flags, pitch)
			if(g_KNIFE4[id])
				emit_sound(id, channel, d_sounds[0], volume, attn, flags, pitch)
			if(g_KNIFE5[id])
				emit_sound(id, channel, e_sounds[0], volume, attn, flags, pitch)
			if(g_KNIFE6[id])
				emit_sound(id, channel, f_sounds[0], volume, attn, flags, pitch)
			if(g_KNIFE7[id])
				emit_sound(id, channel, g_sounds[0], volume, attn, flags, pitch)
			if(g_KNIFE8[id])
				emit_sound(id, channel, s_sounds[0], volume, attn, flags, pitch)	
			if(g_KNIFE9[id])
				emit_sound(id, channel, s_sounds[0], volume, attn, flags, pitch)		
			if(g_has_survivor[id])
				emit_sound(id, channel, surv_sounds[0], volume, attn, flags, pitch)
		}
		else if (sample[14] == 'h')
		{
			if (sample[17] == 'w') 
			{
				if(g_KNIFE1[id])
					emit_sound(id, channel, a_sounds[3], volume, attn, flags, pitch)
				if(g_KNIFE2[id])
					emit_sound(id, channel, b_sounds[3], volume, attn, flags, pitch)
				if(g_KNIFE3[id])
					emit_sound(id, channel, c_sounds[3], volume, attn, flags, pitch)
				if(g_KNIFE4[id])
					emit_sound(id, channel, d_sounds[3], volume, attn, flags, pitch)
				if(g_KNIFE5[id])
					emit_sound(id, channel, e_sounds[3], volume, attn, flags, pitch)
				if(g_KNIFE6[id])
					emit_sound(id, channel, f_sounds[3], volume, attn, flags, pitch)
				if(g_KNIFE7[id])
					emit_sound(id, channel, g_sounds[3], volume, attn, flags, pitch)
				if(g_KNIFE8[id])
					emit_sound(id, channel, s_sounds[3], volume, attn, flags, pitch)
                if(g_KNIFE9[id])
					emit_sound(id, channel, s_sounds[3], volume, attn, flags, pitch)					
				if(g_has_survivor[id])
					emit_sound(id, channel, surv_sounds[3], volume, attn, flags, pitch)
			}
			else
			{
				if(g_KNIFE1[id])
					emit_sound(id, channel, a_sounds[random_num(1,2)], volume, attn, flags, pitch)
				if(g_KNIFE2[id])
					emit_sound(id, channel, b_sounds[random_num(1,2)], volume, attn, flags, pitch)
				if(g_KNIFE3[id])
					emit_sound(id, channel, c_sounds[random_num(1,2)], volume, attn, flags, pitch)
				if(g_KNIFE4[id])
					emit_sound(id, channel, d_sounds[random_num(1,2)], volume, attn, flags, pitch)
				if(g_KNIFE5[id])
					emit_sound(id, channel, e_sounds[random_num(1,2)], volume, attn, flags, pitch)
				if(g_KNIFE6[id])
					emit_sound(id, channel, f_sounds[random_num(1,2)], volume, attn, flags, pitch)
				if(g_KNIFE7[id])
					emit_sound(id, channel, g_sounds[random_num(1,2)], volume, attn, flags, pitch)
				if(g_KNIFE8[id])
					emit_sound(id, channel, s_sounds[random_num(1,2)], volume, attn, flags, pitch)	
				if(g_KNIFE9[id])
					emit_sound(id, channel, s_sounds[random_num(1,2)], volume, attn, flags, pitch)		
				if(g_has_survivor[id])
					emit_sound(id, channel, surv_sounds[random_num(1,2)], volume, attn, flags, pitch)
			}
		}
		else
		{
			if (sample[15] == 'l') 
			{
				if(g_KNIFE1[id])
					emit_sound(id, channel, a_sounds[4], volume, attn, flags, pitch)
				if(g_KNIFE2[id])
					emit_sound(id, channel, b_sounds[4], volume, attn, flags, pitch)
				if(g_KNIFE3[id])
					emit_sound(id, channel, c_sounds[4], volume, attn, flags, pitch)
				if(g_KNIFE4[id])
					emit_sound(id, channel, d_sounds[4], volume, attn, flags, pitch)
				if(g_KNIFE5[id])
					emit_sound(id, channel, e_sounds[4], volume, attn, flags, pitch)
				if(g_KNIFE6[id])
					emit_sound(id, channel, f_sounds[4], volume, attn, flags, pitch)
				if(g_KNIFE7[id])
					emit_sound(id, channel, g_sounds[4], volume, attn, flags, pitch)
				if(g_KNIFE8[id])
					emit_sound(id, channel, s_sounds[4], volume, attn, flags, pitch)	
				if(g_KNIFE9[id])
					emit_sound(id, channel, s_sounds[4], volume, attn, flags, pitch)		
				if(g_has_survivor[id])
					emit_sound(id, channel, surv_sounds[4], volume, attn, flags, pitch)
			}
			else 
			{
				if(g_KNIFE1[id])
					emit_sound(id, channel, a_sounds[5], volume, attn, flags, pitch)
				if(g_KNIFE2[id] )
					emit_sound(id, channel, b_sounds[5], volume, attn, flags, pitch)
				if(g_KNIFE3[id] )
					emit_sound(id, channel, c_sounds[5], volume, attn, flags, pitch)
				if(g_KNIFE4[id])
					emit_sound(id, channel, d_sounds[5], volume, attn, flags, pitch)
				if(g_KNIFE5[id])
					emit_sound(id, channel, e_sounds[5], volume, attn, flags, pitch)
				if(g_KNIFE6[id])
					emit_sound(id, channel, f_sounds[5], volume, attn, flags, pitch)
				if(g_KNIFE7[id])
					emit_sound(id, channel, g_sounds[5], volume, attn, flags, pitch)
				if(g_KNIFE8[id])
					emit_sound(id, channel, s_sounds[5], volume, attn, flags, pitch)	
				if(g_KNIFE9[id])
					emit_sound(id, channel, s_sounds[5], volume, attn, flags, pitch)		
				if(g_has_survivor[id])
					emit_sound(id, channel, surv_sounds[5], volume, attn, flags, pitch)
			}
		}
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}

public fw_PlayerPreThink(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id))
	return FMRES_IGNORED

	new temp[2], weapon = get_user_weapon(id, temp[0], temp[1])

	if (weapon == CSW_KNIFE && g_KNIFE1[id])
	{
		g_hasSpeed[id] = true
		set_pev(id, pev_maxspeed, get_pcvar_float(cvar_knife_spd))
	}

	if(weapon == CSW_KNIFE && g_KNIFE2[id]) 
	{
		g_hasSpeed[id] = true
		set_pev(id, pev_maxspeed, get_pcvar_float(cvar_knife_spd))

		if ((pev(id, pev_button) & IN_JUMP) && !(pev(id, pev_oldbuttons) & IN_JUMP))
		{
			new flags = pev(id, pev_flags)
			new waterlvl = pev(id, pev_waterlevel)

			if (!(flags & FL_ONGROUND))
			return FMRES_IGNORED

			if (flags & FL_WATERJUMP)
			return FMRES_IGNORED

			if (waterlvl > 1)
			return FMRES_IGNORED

			new Float:fVelocity[3]
			pev(id, pev_velocity, fVelocity)

			fVelocity[2] += get_pcvar_num(cvar_jump)

			set_pev(id, pev_velocity, fVelocity)
			set_pev(id, pev_gaitsequence, 6)
		}
	}
	if(weapon == CSW_KNIFE && g_KNIFE3[id]) 
	{
		g_hasSpeed[id] = true
		set_pev(id, pev_maxspeed, get_pcvar_float(cvar_knife_spd_vip))

		if ((pev(id, pev_button) & IN_JUMP) && !(pev(id, pev_oldbuttons) & IN_JUMP))
		{	
			new flags = pev(id, pev_flags)
			new waterlvl = pev(id, pev_waterlevel)

			if (!(flags & FL_ONGROUND))
			return FMRES_IGNORED

			if (flags & FL_WATERJUMP)
			return FMRES_IGNORED

			if (waterlvl > 1)
			return FMRES_IGNORED

			new Float:fVelocity[3]
			pev(id, pev_velocity, fVelocity)

			set_pev(id, pev_velocity, fVelocity)
			set_pev(id, pev_gaitsequence, 6)
		}
	}
	if (weapon == CSW_KNIFE && g_KNIFE4[id])
	{
		g_hasSpeed[id] = true
		set_pev(id, pev_maxspeed, get_pcvar_float(cvar_knife_spd_vip))

		if ((pev(id, pev_button) & IN_JUMP) && !(pev(id, pev_oldbuttons) & IN_JUMP))
		{
			new flags = pev(id, pev_flags)
			new waterlvl = pev(id, pev_waterlevel)

			if (!(flags & FL_ONGROUND))
			return FMRES_IGNORED

			if (flags & FL_WATERJUMP)
			return FMRES_IGNORED

			if (waterlvl > 1)
			return FMRES_IGNORED

			new Float:fVelocity[3]
			pev(id, pev_velocity, fVelocity)

			fVelocity[2] += get_pcvar_num(cvar_jump_vip)

			set_pev(id, pev_velocity, fVelocity)
			set_pev(id, pev_gaitsequence, 6)
		}
	}
	if (weapon == CSW_KNIFE && g_KNIFE5[id])
	{
		g_hasSpeed[id] = true
		set_pev(id, pev_maxspeed, get_pcvar_float(cvar_knife_spd_vip))

		if ((pev(id, pev_button) & IN_JUMP) && !(pev(id, pev_oldbuttons) & IN_JUMP))
		{
			new flags = pev(id, pev_flags)
			new waterlvl = pev(id, pev_waterlevel)

			if (!(flags & FL_ONGROUND))
			return FMRES_IGNORED

			if (flags & FL_WATERJUMP)
			return FMRES_IGNORED

			if (waterlvl > 1)
			return FMRES_IGNORED

			new Float:fVelocity[3]
			pev(id, pev_velocity, fVelocity)

			fVelocity[2] += get_pcvar_num(cvar_jump_vip)

			set_pev(id, pev_velocity, fVelocity)
			set_pev(id, pev_gaitsequence, 6)
		}
	}
	if (weapon == CSW_KNIFE && g_KNIFE6[id])
	{
		g_hasSpeed[id] = true
		set_pev(id, pev_maxspeed, get_pcvar_float(cvar_knife_spd_vip))

		if ((pev(id, pev_button) & IN_JUMP) && !(pev(id, pev_oldbuttons) & IN_JUMP))
		{
			new flags = pev(id, pev_flags)
			new waterlvl = pev(id, pev_waterlevel)

			if (!(flags & FL_ONGROUND))
			return FMRES_IGNORED

			if (flags & FL_WATERJUMP)
			return FMRES_IGNORED

			if (waterlvl > 1)
			return FMRES_IGNORED

			new Float:fVelocity[3]
			pev(id, pev_velocity, fVelocity)

			fVelocity[2] += get_pcvar_num(cvar_jump_vip)

			set_pev(id, pev_velocity, fVelocity)
			set_pev(id, pev_gaitsequence, 6)
		}
	}
	if (weapon == CSW_KNIFE && g_KNIFE7[id])
	{
		g_hasSpeed[id] = true
		set_pev(id, pev_maxspeed, get_pcvar_float(cvar_knife_spd_vip))

		if ((pev(id, pev_button) & IN_JUMP) && !(pev(id, pev_oldbuttons) & IN_JUMP))
		{
			new flags = pev(id, pev_flags)
			new waterlvl = pev(id, pev_waterlevel)

			if (!(flags & FL_ONGROUND))
			return FMRES_IGNORED

			if (flags & FL_WATERJUMP)
			return FMRES_IGNORED

			if (waterlvl > 1)
			return FMRES_IGNORED

			new Float:fVelocity[3]
			pev(id, pev_velocity, fVelocity)

			fVelocity[2] += get_pcvar_num(cvar_jump_vip)

			set_pev(id, pev_velocity, fVelocity)
			set_pev(id, pev_gaitsequence, 6)
		}
	}
	if (weapon == CSW_KNIFE && g_KNIFE8[id])
	{
		g_hasSpeed[id] = true
		set_pev(id, pev_maxspeed, get_pcvar_float(cvar_knife_spd_vip))

		if ((pev(id, pev_button) & IN_JUMP) && !(pev(id, pev_oldbuttons) & IN_JUMP))
		{
			new flags = pev(id, pev_flags)
			new waterlvl = pev(id, pev_waterlevel)

			if (!(flags & FL_ONGROUND))
			return FMRES_IGNORED

			if (flags & FL_WATERJUMP)
			return FMRES_IGNORED

			if (waterlvl > 1)
			return FMRES_IGNORED

			new Float:fVelocity[3]
			pev(id, pev_velocity, fVelocity)

			fVelocity[2] += get_pcvar_num(cvar_jump_vip)

			set_pev(id, pev_velocity, fVelocity)
			set_pev(id, pev_gaitsequence, 6)
		}
	}
	if (weapon == CSW_KNIFE && g_KNIFE9[id])
	{
		g_hasSpeed[id] = true
		set_pev(id, pev_maxspeed, get_pcvar_float(cvar_knife_spd_vip))

		if ((pev(id, pev_button) & IN_JUMP) && !(pev(id, pev_oldbuttons) & IN_JUMP))
		{
			new flags = pev(id, pev_flags)
			new waterlvl = pev(id, pev_waterlevel)

			if (!(flags & FL_ONGROUND))
			return FMRES_IGNORED

			if (flags & FL_WATERJUMP)
			return FMRES_IGNORED

			if (waterlvl > 1)
			return FMRES_IGNORED

			new Float:fVelocity[3]
			pev(id, pev_velocity, fVelocity)

			fVelocity[2] += get_pcvar_num(cvar_jump_vip)

			set_pev(id, pev_velocity, fVelocity)
			set_pev(id, pev_gaitsequence, 6)
		}
	}
	if (weapon == CSW_KNIFE && g_has_survivor[id])
	{
		g_hasSpeed[id] = true
		set_pev(id, pev_maxspeed, get_pcvar_float(cvar_knife_spd_vip))

		if ((pev(id, pev_button) & IN_JUMP) && !(pev(id, pev_oldbuttons) & IN_JUMP))
		{
			new flags = pev(id, pev_flags)
			new waterlvl = pev(id, pev_waterlevel)

			if (!(flags & FL_ONGROUND))
			return FMRES_IGNORED

			if (flags & FL_WATERJUMP)
			return FMRES_IGNORED

			if (waterlvl > 1)
			return FMRES_IGNORED

			new Float:fVelocity[3]
			pev(id, pev_velocity, fVelocity)

			fVelocity[2] += get_pcvar_num(cvar_jump_vip)

			set_pev(id, pev_velocity, fVelocity)
			set_pev(id, pev_gaitsequence, 6)
		}
	}
	return FMRES_IGNORED
}  

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED
	
	if(zp_get_user_zombie(attacker))
		return HAM_IGNORED

	new weapon = get_user_weapon(attacker)
	if (weapon == CSW_KNIFE && g_KNIFE1[attacker])
	{
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmgmult1))	
	}
	if (weapon == CSW_KNIFE && g_KNIFE2[attacker])
	{	
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmgmult2))
	}
	if (weapon == CSW_KNIFE && g_KNIFE3[attacker])
	{	
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmgmult3))
		
		new Float:vec[3];
		new Float:oldvelo[3];
		pev(victim, pev_velocity, oldvelo);
		create_velocity_vector(victim , attacker , vec);
		vec[0] += oldvelo[0];
		vec[1] += oldvelo[1];
		set_pev(victim, pev_velocity, vec);	
	}
	if (weapon == CSW_KNIFE && g_KNIFE4[attacker])
	{	
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmgmult_vip))	

		new Float:vec[3];
		new Float:oldvelo[3];
		pev(victim, pev_velocity, oldvelo);
		create_velocity_vector(victim , attacker , vec);
		vec[0] += oldvelo[0];
		vec[1] += oldvelo[1];
		set_pev(victim, pev_velocity, vec);

		if(!g_freeze_wait[attacker] && !zp_get_user_nemesis(victim))
		{
			set_pev(victim, pev_flags, pev(victim, pev_flags) | FL_FROZEN)
			set_user_rendering(victim, kRenderFxGlowShell, 0, 206, 209, kRenderNormal, 25)
			g_frozen[victim] = true
			set_task(TIME_FREEZE, "end", victim)
			g_freeze_wait[attacker] = true
			set_task(TIME_WAIT_FREEZE, "Freeze_Wait", attacker + 1233123)
		}	
	}
	if (weapon == CSW_KNIFE && g_KNIFE5[attacker])
	{	
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmgmult_admin))	

		new Float:vec[3];
		new Float:oldvelo[3];
		pev(victim, pev_velocity, oldvelo);
		create_velocity_vector(victim , attacker , vec);
		vec[0] += oldvelo[0];
		vec[1] += oldvelo[1];
		set_pev(victim, pev_velocity, vec);
		
		if( !task_exists( victim + TASK_FBURN ) )
		{
			g_burning_duration[ victim ] += FIRE_DURATION * 5
			set_task( 0.1, "CTask__BurningFlame", victim + TASK_FBURN, _, _, "b" )
		}
	}
	if (weapon == CSW_KNIFE && g_KNIFE6[attacker])
	{	
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmgmult_boss))	

		new Float:vec[3];
		new Float:oldvelo[3];
		pev(victim, pev_velocity, oldvelo);
		create_velocity_vector(victim , attacker , vec);
		vec[0] += oldvelo[0];
		vec[1] += oldvelo[1];
		set_pev(victim, pev_velocity, vec);

		if( !task_exists( victim + TASK_FBURN ) )
		{
			g_burning_duration[ victim ] += FIRE_DURATION * 5
			set_task( 0.1, "CTask__BurningFlame2", victim + TASK_FBURN, _, _, "b" )
		}
	}
	if (weapon == CSW_KNIFE && g_KNIFE7[attacker])
	{	
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmgmult_buff))	

		new Float:vec[3];
		new Float:oldvelo[3];
		pev(victim, pev_velocity, oldvelo);
		create_velocity_vector(victim , attacker , vec);
		vec[0] += oldvelo[0];
		vec[1] += oldvelo[1];
		set_pev(victim, pev_velocity, vec);

		if( !task_exists( victim + TASK_FBURN ) )
		{
			g_burning_duration[ victim ] += FIRE_DURATION * 5
			set_task( 0.1, "CTask__BurningFlame3", victim + TASK_FBURN, _, _, "b" )
		}
	}
	if (weapon == CSW_KNIFE && g_KNIFE8[attacker])
	{	
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmgmult_buff))	

		new Float:vec[3];
		new Float:oldvelo[3];
		pev(victim, pev_velocity, oldvelo);
		create_velocity_vector(victim , attacker , vec);
		vec[0] += oldvelo[0];
		vec[1] += oldvelo[1];
		set_pev(victim, pev_velocity, vec);

		if( !task_exists( victim + TASK_FBURN ) )
		{
			g_burning_duration[ victim ] += FIRE_DURATION * 5
			set_task( 0.1, "CTask__BurningFlame3", victim + TASK_FBURN, _, _, "b" )
		}
	}
	if (weapon == CSW_KNIFE && g_KNIFE9[attacker])
	{	
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmgmult_buff))	

		new Float:vec[3];
		new Float:oldvelo[3];
		pev(victim, pev_velocity, oldvelo);
		create_velocity_vector(victim , attacker , vec);
		vec[0] += oldvelo[0];
		vec[1] += oldvelo[1];
		set_pev(victim, pev_velocity, vec);

		if( !task_exists( victim + TASK_FBURN ) )
		{
			g_burning_duration[ victim ] += FIRE_DURATION * 5
			set_task( 0.1, "CTask__BurningFlame3", victim + TASK_FBURN, _, _, "b" )
		}
	}
	if (weapon == CSW_KNIFE && g_has_survivor[attacker])
	{	
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmgmult_surv))	

		new Float:vec[3];
		new Float:oldvelo[3];
		pev(victim, pev_velocity, oldvelo);
		create_velocity_vector(victim , attacker , vec);
		vec[0] += oldvelo[0];
		vec[1] += oldvelo[1];
		set_pev(victim, pev_velocity, vec);
	}

	return HAM_IGNORED
}

public Freeze_Wait(taskid)
{
	new attacker = taskid - 1233123

	if(is_user_alive(attacker))
	{
		remove_task(attacker + 1233123)
		g_freeze_wait[attacker] = false
		ChatColor(attacker, "!yВаша способность заморозить готова")
	}
	else remove_task(attacker + 1233123)
}

public end(victim)
{
	if(g_frozen[victim])
		g_frozen[victim] = false

	set_pev(victim, pev_flags, pev(victim, pev_flags) & ~FL_FROZEN)
	set_user_rendering(victim, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 25)
	CreateGlass(victim)

	remove_task(victim)
}

public message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iattacker, ivictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iattacker = get_msg_arg_int(1)
	ivictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iattacker) || iattacker == ivictim)
	return PLUGIN_CONTINUE

	if (!zp_get_user_zombie(iattacker))
	{
		if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
		{
			if(g_KNIFE1[iattacker])
			set_msg_arg_string(4, "knife1")
		}
	
		if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
		{
			if(g_KNIFE2[iattacker])
			set_msg_arg_string(4, "knife2")
		}
	
		if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
		{
			if(g_KNIFE3[iattacker])
			set_msg_arg_string(4, "knife3")
		}
	
		if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
		{
			if(g_KNIFE4[iattacker])
			set_msg_arg_string(4, "knife4")
		}
		
		if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
		{
			if(g_KNIFE5[iattacker])
			set_msg_arg_string(4, "knife5")
		}
		
		if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
		{
			if(g_KNIFE6[iattacker])
			set_msg_arg_string(4, "knife6")
		}
		
		if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
		{
			if(g_KNIFE7[iattacker])
			set_msg_arg_string(4, "knife7")
		}
		
		if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
		{
			if(g_KNIFE8[iattacker])
			set_msg_arg_string(4, "knife8")
		}
		
		if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
		{
			if(g_has_survivor[iattacker])
			set_msg_arg_string(4, "survivor")
		}
	
		if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
		{
			if(!g_KNIFE1[iattacker] && !g_KNIFE2[iattacker] && !g_KNIFE3[iattacker] && !zp_get_user_zombie(iattacker))
			set_msg_arg_string(4, "knife")
		}
	}
	if (zp_get_user_zombie(iattacker))
	{
		if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
		{
			if(g_KNIFE1[iattacker] || g_KNIFE2[iattacker] || g_KNIFE3[iattacker])
			set_msg_arg_string(4, "Claws")
		}
	}
	return PLUGIN_CONTINUE
}

stock create_velocity_vector(victim,attacker,Float:velocity[3])
{
	if(!zp_get_user_zombie(victim) || !is_user_alive(attacker))
		return 0;

	new Float:vicorigin[3];
	new Float:attorigin[3];
	pev(victim, pev_origin , vicorigin);
	pev(attacker, pev_origin , attorigin);

	new Float:origin2[3]
	origin2[0] = vicorigin[0] - attorigin[0];
	origin2[1] = vicorigin[1] - attorigin[1];

	new Float:largestnum = 0.0;

	if(floatabs(origin2[0])>largestnum) largestnum = floatabs(origin2[0]);
	if(floatabs(origin2[1])>largestnum) largestnum = floatabs(origin2[1]);

	origin2[0] /= largestnum;
	origin2[1] /= largestnum;

	if (g_KNIFE3[attacker])
	{
		velocity[0] = ( origin2[0] * (get_pcvar_float(cvar_knock) * 3000) ) / floatround(get_distance_f(vicorigin, attorigin));
		velocity[1] = ( origin2[1] * (get_pcvar_float(cvar_knock) * 3000) ) / floatround(get_distance_f(vicorigin, attorigin));
	}
	if (g_KNIFE4[attacker])
	{
		velocity[0] = ( origin2[0] * (get_pcvar_float(cvar_knock_vip) * 3000) ) / floatround(get_distance_f(vicorigin, attorigin));
		velocity[1] = ( origin2[1] * (get_pcvar_float(cvar_knock_vip) * 3000) ) / floatround(get_distance_f(vicorigin, attorigin));
	}
	if (g_KNIFE5[attacker])
	{
		velocity[0] = ( origin2[0] * (get_pcvar_float(cvar_knock_vip) * 3000) ) / floatround(get_distance_f(vicorigin, attorigin));
		velocity[1] = ( origin2[1] * (get_pcvar_float(cvar_knock_vip) * 3000) ) / floatround(get_distance_f(vicorigin, attorigin));
	}
	if (g_KNIFE6[attacker])
	{
		velocity[0] = ( origin2[0] * (get_pcvar_float(cvar_knock_vip) * 3000) ) / floatround(get_distance_f(vicorigin, attorigin));
		velocity[1] = ( origin2[1] * (get_pcvar_float(cvar_knock_vip) * 3000) ) / floatround(get_distance_f(vicorigin, attorigin));
	}
	if (g_KNIFE7[attacker])
	{
		velocity[0] = ( origin2[0] * (get_pcvar_float(cvar_knock_vip) * 3000) ) / floatround(get_distance_f(vicorigin, attorigin));
		velocity[1] = ( origin2[1] * (get_pcvar_float(cvar_knock_vip) * 3000) ) / floatround(get_distance_f(vicorigin, attorigin));
	}
	if (g_KNIFE8[attacker])
	{
		velocity[0] = ( origin2[0] * (get_pcvar_float(cvar_knock_vip) * 3000) ) / floatround(get_distance_f(vicorigin, attorigin));
		velocity[1] = ( origin2[1] * (get_pcvar_float(cvar_knock_vip) * 3000) ) / floatround(get_distance_f(vicorigin, attorigin));
	}
	
	if(velocity[0] <= 20.0 || velocity[1] <= 20.0)
	velocity[2] = random_float(200.0 , 275.0);

	return 1;
}

stock fm_set_user_maxspeed(index, Float:speed = -1.0) 
{
	engfunc(EngFunc_SetClientMaxspeed, index, speed);
	set_pev(index, pev_maxspeed, speed);

	return 1;
}

public CTask__BurningFlame( taskid )
{
	// Get player origin and flags
	static origin[3], flags
	get_user_origin(ID_FBURN, origin)
	flags = pev(ID_FBURN, pev_flags)
	
	// Madness mode - in water - burning stopped
	if ((flags & FL_INWATER) || g_burning_duration[ID_FBURN] < 1 || g_fRoundEnd || !is_user_alive(ID_FBURN))
	{
		// Smoke sprite
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_SMOKE) // TE id
		write_coord(origin[0]) // x
		write_coord(origin[1]) // y
		write_coord(origin[2]-50) // z
		write_short(g_smokeSpr) // sprite
		write_byte(random_num(15, 20)) // scale
		write_byte(random_num(10, 20)) // framerate
		message_end()
		
		// Task not needed anymore
		remove_task(taskid)
		return
	}
	
	// Get player's health
	static health
	health = pev(ID_FBURN, pev_health)
	
	// Take damage from the fire
	if (health - FIRE_DAMAGE > 0)
		fm_set_user_health(ID_FBURN, health - FIRE_DAMAGE)
	
	// Flame sprite
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_SPRITE) // TE id
	write_coord(origin[0]+random_num(-5, 5)) // x
	write_coord(origin[1]+random_num(-5, 5)) // y
	write_coord(origin[2]+random_num(-10, 10)) // z
	write_short(g_flameSpr) // sprite
	write_byte(random_num(5, 10)) // scale
	write_byte(200) // brightness
	message_end()

	g_burning_duration[ID_FBURN]--
}

public CTask__BurningFlame2( taskid )
{
	// Get player origin and flags
	static origin[3], flags
	get_user_origin(ID_FBURN, origin)
	flags = pev(ID_FBURN, pev_flags)
	
	// Madness mode - in water - burning stopped
	if ((flags & FL_INWATER) || g_burning_duration[ID_FBURN] < 1 || g_fRoundEnd || !is_user_alive(ID_FBURN))
	{
		// Smoke sprite
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_SMOKE) // TE id
		write_coord(origin[0]) // x
		write_coord(origin[1]) // y
		write_coord(origin[2]-50) // z
		write_short(g_smokeSpr) // sprite
		write_byte(random_num(15, 20)) // scale
		write_byte(random_num(10, 20)) // framerate
		message_end()
		
		// Task not needed anymore
		remove_task(taskid)
		return
	}
	
	// Get player's health
	static health
	health = pev(ID_FBURN, pev_health)
	
	// Take damage from the fire
	if (health - FIRE_DAMAGE > 0)
		fm_set_user_health(ID_FBURN, health - FIRE_DAMAGE)
	
	// Flame sprite
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_SPRITE) // TE id
	write_coord(origin[0]+random_num(-5, 5)) // x
	write_coord(origin[1]+random_num(-5, 5)) // y
	write_coord(origin[2]+random_num(-10, 10)) // z
	write_short(g_flameSpr2) // sprite
	write_byte(random_num(5, 10)) // scale
	write_byte(200) // brightness
	message_end()

	g_burning_duration[ID_FBURN]--
}

public CTask__BurningFlame3( taskid )
{
	// Get player origin and flags
	static origin[3], flags
	get_user_origin(ID_FBURN, origin)
	flags = pev(ID_FBURN, pev_flags)
	
	// Madness mode - in water - burning stopped
	if ((flags & FL_INWATER) || g_burning_duration[ID_FBURN] < 1 || g_fRoundEnd || !is_user_alive(ID_FBURN))
	{
		// Smoke sprite
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_SMOKE) // TE id
		write_coord(origin[0]) // x
		write_coord(origin[1]) // y
		write_coord(origin[2]-50) // z
		write_short(g_smokeSpr) // sprite
		write_byte(random_num(15, 20)) // scale
		write_byte(random_num(10, 20)) // framerate
		message_end()
		
		// Task not needed anymore
		remove_task(taskid)
		return
	}
	
	// Get player's health
	static health
	health = pev(ID_FBURN, pev_health)
	
	// Take damage from the fire
	if (health - FIRE_DAMAGE > 0)
		fm_set_user_health(ID_FBURN, health - FIRE_DAMAGE)
	
	// Flame sprite
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_SPRITE) // TE id
	write_coord(origin[0]+random_num(-5, 5)) // x
	write_coord(origin[1]+random_num(-5, 5)) // y
	write_coord(origin[2]+random_num(-10, 10)) // z
	write_short(g_flameSpr3) // sprite
	write_byte(random_num(5, 10)) // scale
	write_byte(200) // brightness
	message_end()

	g_burning_duration[ID_FBURN]--
}

stock fm_set_user_health( index, health ) 
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index)


stock CreateGlass(id)
{
	new szOrigin[3];
	get_user_origin(id, szOrigin);

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BREAKMODEL);
	write_coord( szOrigin[0] );
	write_coord( szOrigin[1] );
	write_coord( szOrigin[2] + 24 );
	write_coord(16);
	write_coord(16);
	write_coord(16);
	write_coord( random_num(-50, 50) );
	write_coord( random_num(-50, 50) );
	write_coord(25);
	write_byte(10);
	write_short(g_SpriteGlass);
	write_byte(10);
	write_byte(25);
	write_byte(0x01);
	message_end();
}

stock ChekKnife(id)
{
	g_has_survivor[id] = false
}

stock ChatColor(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)
    
	replace_all(msg, 190, "!g", "^4")
	replace_all(msg, 190, "!y", "^1")
	replace_all(msg, 190, "!team", "^3")
    
	if (id) players[0] = id; else get_players(players, count, "ch")
	{
		for (new i = 0; i < count; i++)
		{
			if (is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}
}
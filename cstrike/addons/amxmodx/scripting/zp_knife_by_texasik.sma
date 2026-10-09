#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <fakemeta>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>

native zp_get_user_level(id)

#define TASK_FBURN				100
#define ID_FBURN                ( taskid - TASK_FBURN )

#define MAX_CLIENTS				32

new bool:g_fRoundEnd

#define FIRE_DURATION			1
#define FIRE_DAMAGE				250

new g_flameSpr, g_smokeSpr, g_burning_duration[ MAX_CLIENTS + 1 ]

#define PLUGIN	"[ZP] Addon: Knifes"
#define VERSION	"1.0"
#define AUTHOR	"BlackCat"

#define VIP ADMIN_LEVEL_H
#define CVIP ADMIN_KICK
#define ADMIN ADMIN_BAN
#define CADMIN ADMIN_SLAY
#define BOSS ADMIN_MAP
#define HUNTER ADMIN_CVAR
#define LEVEL_KNIFE	5
#define LEVEL_KNIFE1	8
#pragma tabsize 0

new KNIFE1_V_MODEL[] = "models/knifes/v_skull_blood.mdl"
new KNIFE1_P_MODEL[] = "models/knifes/p_skull_blood.mdl"

new KNIFE2_V_MODEL[] = "models/knifes/v_warhammer_janus.mdl"
new KNIFE2_P_MODEL[] = "models/knifes/p_hammer.mdl"

new KNIFE3_V_MODEL[] = "models/knifes/v_rustik.mdl"
new KNIFE3_P_MODEL[] = "models/knifes/p_rustik.mdl"

new KNIFE4_V_MODEL[] = "models/knifes/v_knife_hammaxe.mdl"
new KNIFE4_P_MODEL[] = "models/knifes/p_knife_hammaxe.mdl"

new KNIFE5_V_MODEL[] = "models/knifes/v_kosavoron.mdl"
new KNIFE5_P_MODEL[] = "models/knifes/p_kosa_wolf.mdl"

new KNIFE6_V_MODEL[] = "models/knifes/v_kosa_new.mdl"
new KNIFE6_P_MODEL[] = "models/knifes/p_kosa_new.mdl"

new KNIFE7_V_MODEL[] = "models/knifes/v_waterpapers.mdl"
new KNIFE7_P_MODEL[] = "models/knifes/p_waterpapers.mdl"

new KNIFE8_V_MODEL[] = "models/knifes/v_surv_koroleva.mdl"
new KNIFE8_P_MODEL[] = "models/knifes/p_surv_koroleva.mdl"

new KNIFE9_V_MODEL[] = "models/knifes/v_war_bloody.mdl"
new KNIFE9_P_MODEL[] = "models/knifes/p_war_bloody.mdl"

new bool:g_has_axe[33]
new bool:g_has_strong[33]
new bool:g_has_combat[33]
new bool:g_has_hammer[33]
new bool:g_has_saxe[33]
new bool:g_has_fire[33]
new bool:g_has_ice[33]
new bool:g_has_gold[33]
new bool:g_has_lol[33]

new cvar_knock_axe, cvar_speed_axe, cvar_damage_axe
new cvar_knock_strong, cvar_speed_strong, cvar_damage_strong
new cvar_knock_combat, cvar_speed_combat, cvar_damage_combat
new cvar_knock_hammer, cvar_speed_hammer, cvar_damage_hammer
new cvar_knock_saxe, cvar_speed_saxe, cvar_damage_saxe
new cvar_knock_fire, cvar_speed_fire, cvar_damage_fire
new cvar_knock_ice, cvar_speed_ice, cvar_damage_ice
new cvar_knock_gold, cvar_speed_gold, cvar_damage_gold
new cvar_knock_lol, cvar_speed_lol, cvar_damage_lol

new const g_sound_knife[] = { "items/gunpickup2.wav" }

new const axe_sounds[][] =
{
        "knifes/skullaxe_deploy1.wav",
        "knifes/hammer_hit_01.wav",
        "knifes/hammer_hit_02.wav",
        "knifes/hammer_hitwall1.wav",
        "knifes/hammer_axe_slash1.wav",
        "knifes/hammer_stab.wav"
}

new const strong_sounds[][] =
{
        "knifes/hammer_draw.wav",
        "knifes/hammer_hit_01.wav",
        "knifes/hammer_hit_02.wav",
        "knifes/hammer_hitwall1.wav",
        "knifes/hammer_slash1.wav",
        "knifes/hammer_stab.wav"
}

new const combat_sounds[][] =
{
        "knifes/janus9_draw.wav",
        "knifes/janus9_hit1.wav",
        "knifes/janus9_hit2.wav",
        "knifes/janus9_metal1.wav",
        "knifes/janus9_slash1.wav",
        "knifes/janus9_metal1.wav"
}

new const hammer_sounds[][] =
{
        "knifes/per4atka_T_draw.wav",
        "knifes/snap_blade_hit1.wav",
        "knifes/snap_blade_hit2.wav",
        "knifes/snap_blade_hitwall.wav",
        "knifes/snap_blade_slash1.wav",
        "knifes/snap_blade_stab.wav"
}

new const saxe_sounds[][] =
{
        "knifes/buffhammer_draw.wav",
        "knifes/buffhammer_hit1.wav",
        "knifes/buffhammer_hit1.wav",
        "knifes/buffhammer_hitwall.wav",
        "knifes/buffhammer_slash1.wav",
        "knifes/buffhammer_stab.wav"
}

new const fire_sounds[][] =
{
        "knifes/buffhammer_draw.wav",
        "knifes/buffhammer_hit1.wav",
        "knifes/buffhammer_hit1.wav",
        "knifes/buffhammer_hitwall.wav",
        "knifes/buffhammer_slash1.wav",
        "knifes/buffhammer_stab.wav"
}

new const ice_sounds[][] =
{
        "knifes/buffhammer_draw.wav",
        "knifes/buffhammer_hit1.wav",
        "knifes/buffhammer_hit1.wav",
        "knifes/buffhammer_hitwall.wav",
        "knifes/buffhammer_slash1.wav",
        "knifes/buffhammer_stab.wav"
}

new const gold_sounds[][] =
{
        "knifes/buffhammer_draw.wav",
        "knifes/buffhammer_hit1.wav",
        "knifes/buffhammer_hit1.wav",
        "knifes/buffhammer_hitwall.wav",
        "knifes/buffhammer_slash1.wav",
        "knifes/buffhammer_stab.wav"
}

new const lol_sounds[][] =
{
        "knifes/buffhammer_draw.wav",
        "knifes/buffhammer_hit1.wav",
        "knifes/buffhammer_hit1.wav",
        "knifes/buffhammer_hitwall.wav",
        "knifes/buffhammer_slash1.wav",
        "knifes/buffhammer_stab.wav"
}

public plugin_init()
{
    register_plugin(PLUGIN , VERSION , AUTHOR);
    register_forward(FM_AddToFullPack, "fw_PlayerAddToFullPack", 1 );
    register_cvar("zp_addon_knife", VERSION, FCVAR_SERVER);

    register_clcmd("say /knife","knifemenu")
	register_clcmd("knife_zb","knifemenu")
	register_clcmd("zbg_knife","knifemenu")
	register_clcmd("/knife","knifemenu")
	
	register_event("CurWeapon","checkWeapon","be","1=1");

	register_forward(FM_EmitSound, "CEntity__EmitSound");
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	RegisterHam(Ham_Spawn, "player", "fw_playerspawn_post", 1)
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	
    register_message(get_user_msgid("DeathMsg"), "message_DeathMsg"); 
	
	cvar_speed_axe = register_cvar("zp_axe_speed", "270.0")
    cvar_damage_axe = register_cvar("zp_axe_damage", "10.3")
    cvar_knock_axe = register_cvar("zp_axe_knockback", "3.6")
	
    cvar_speed_strong = register_cvar("zp_strong_speed", "260.0")
    cvar_damage_strong = register_cvar("zp_strong_damage", "7.5")
    cvar_knock_strong = register_cvar("zp_strong_knockback", "5.6")
 
    cvar_speed_combat = register_cvar("zp_combat_speed", "300.0")
    cvar_damage_combat = register_cvar("zp_combat_damage", "6.3")
    cvar_knock_combat = register_cvar("zp_combat_knockback", "2.6")
	
    cvar_speed_hammer = register_cvar("zp_hammer_speed", "375.0")
    cvar_damage_hammer = register_cvar("zp_hammer_damage", "11.2")
    cvar_knock_hammer = register_cvar("zp_hammer_knockback", "6.0")
   
	cvar_speed_saxe = register_cvar("zp_saxe_speed", "350.0")
    cvar_damage_saxe = register_cvar("zp_saxe_damage", "12.2")
    cvar_knock_saxe = register_cvar("zp_saxe_knockback", "7.0")
	
	cvar_speed_fire = register_cvar("zp_fire_speed", "475.0")
    cvar_damage_fire = register_cvar("zp_fire_damage", "12.2")
    cvar_knock_fire = register_cvar("zp_fire_knockback", "7.0")
	
	cvar_speed_ice = register_cvar("zp_ice_speed", "475.0")
    cvar_damage_ice = register_cvar("zp_ice_damage", "12.2")
    cvar_knock_ice = register_cvar("zp_ice_knockback", "7.0")
	
	cvar_speed_gold = register_cvar("zp_ice_speed", "475.0")
    cvar_damage_gold = register_cvar("zp_ice_damage", "12.2")
    cvar_knock_gold = register_cvar("zp_ice_knockback", "7.0")
	
	cvar_speed_lol = register_cvar("zp_ice_speed", "475.0")
    cvar_damage_lol = register_cvar("zp_ice_damage", "12.2")
    cvar_knock_lol = register_cvar("zp_ice_knockback", "7.0")
}

public native_zp_knifes_get(id)
{
	if(g_has_axe[id])
	{
		return 1
	}else
	if(g_has_strong[id])
	{
		return 2
	}else
	if(g_has_combat[id])
	{
		return 3
	}else
	if(g_has_hammer[id])
	{
		return 4
	}else
	if(g_has_fire[id])
	{
	    return 5
	}else
	if(g_has_ice[id])
	{	
	    return 6
	}else
	if(g_has_gold[id])
	{	
	    return 7	
    }else
	if(g_has_lol[id])
	{	
	    return 8	
	}
	return 0
}

public native_zp_knifes_set(id, iKnife)
{
        switch( iKnife )
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
}

public fw_PlayerAddToFullPack( ES_Handle, E, pEnt, pHost, bsHostFlags, pPlayer, pSet )
{       
        if( pPlayer && get_user_weapon(pEnt) == CSW_KNIFE && g_has_hammer[pEnt] && !zp_get_user_zombie(pEnt))
        {
                static iAnim;

                iAnim = get_es( ES_Handle, ES_Sequence );

                switch( iAnim )
                {
                        case 73, 74, 75, 76:
                        {
                                set_es( ES_Handle, ES_Sequence, iAnim += 20 );
                        }
                }
        }
	
		if( pPlayer && get_user_weapon(pEnt) == CSW_KNIFE && g_has_saxe[pEnt] && !zp_get_user_zombie(pEnt))
        {
                static iAnim;

                iAnim = get_es( ES_Handle, ES_Sequence );

                switch( iAnim )
                {
                        case 73, 74, 75, 76:
                        {
                                set_es( ES_Handle, ES_Sequence, iAnim += 20 );
                        }
                }
        }
		
		if( pPlayer && get_user_weapon(pEnt) == CSW_KNIFE && g_has_axe[pEnt] && !zp_get_user_zombie(pEnt))
        {
                static iAnim;

                iAnim = get_es( ES_Handle, ES_Sequence );

                switch( iAnim )
                {
                        case 73, 74, 75, 76:
                        {
                                set_es( ES_Handle, ES_Sequence, iAnim += 20 );
                        }
                }
        }
		
        if( pPlayer && get_user_weapon(pEnt) == CSW_KNIFE && g_has_strong[pEnt] && !zp_get_user_zombie(pEnt))
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
	register_native( "knife_0", "knife_0", 1 )

	register_native("zp_get_user_knife", "native_zp_knifes_get", 1)
	register_native("zp_set_user_knife", "native_zp_knifes_set", 1)
}

public knife_0(id)
{
	g_has_axe[id] = false
	g_has_strong[id] = false
	g_has_combat[id] = false
	g_has_hammer[id] = false
}

public client_connect(id)
{
	g_has_axe[id] = true
	g_has_strong[id] = false
	g_has_combat[id] = false
	g_has_hammer[id] = false
}

public client_disconnect(id)
{
    g_has_axe[id] = false
    g_has_strong[id] = false
    g_has_combat[id] = false
    g_has_hammer[id] = false
}

public clcmd_knife(id)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED

	engclient_cmd(id, "weapon_knife")

	return PLUGIN_HANDLED
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
	
	precache_sound(g_sound_knife)
	
	for(new i = 0; i < sizeof axe_sounds; i++)
		precache_sound(axe_sounds[i])

	for(new i = 0; i < sizeof strong_sounds; i++)
		precache_sound(strong_sounds[i])

	for(new i = 0; i < sizeof combat_sounds; i++)
		precache_sound(combat_sounds[i])

	for(new i = 0; i < sizeof hammer_sounds; i++)
		precache_sound(hammer_sounds[i])
		
	for(new i = 0; i < sizeof saxe_sounds; i++)
		precache_sound(saxe_sounds[i])
		
	for(new i = 0; i < sizeof fire_sounds; i++)
		precache_sound(fire_sounds[i])	
		
	for(new i = 0; i < sizeof ice_sounds; i++)
		precache_sound(ice_sounds[i])	
		
	for(new i = 0; i < sizeof gold_sounds; i++)
		precache_sound(gold_sounds[i])

    for(new i = 0; i < sizeof lol_sounds; i++)
		precache_sound(lol_sounds[i])			
		
	g_flameSpr = precache_model( "sprites/Vaas/thanatos11_fire.spr" );
	g_smokeSpr = precache_model( "sprites/black_smoke3.spr" );
}

public knifemenu(id)
{
	new menu = menu_create("Меню ножей \yBy Texasik Show","menu_handle")

	menu_additem(menu, "Топор \y[5 Lvl]", "1")
	menu_additem(menu, "Повелитель Януса \y[8 Lvl]", "2")
	menu_additem(menu, "Дьявольская Палка \r[Скорость]^n", "3")
	 
	if(get_user_flags(id) & VIP)
		menu_additem(menu, "Хаммер Яд \r[Вип]", "4")
	else
		menu_additem(menu, "\dХаммер Яд [Вип]", "4")
		
	if(get_user_flags(id) & CVIP)
		menu_additem(menu, "Коса Ворона \r[С-вип]", "5")
	else
		menu_additem(menu, "\dКоса Ворона [С-вип]", "5")
		
	if(get_user_flags(id) & ADMIN)
		menu_additem(menu, "Коса Падших \r[Админ]", "6")
	else
		menu_additem(menu, "\dКоса Падших [Админ]", "6")	
		
	if(get_user_flags(id) & CADMIN)
		menu_additem(menu, "Водяные Перчатки \r[С-Админ]", "7")
	else
		menu_additem(menu, "\dВодяные Перчатки [С-Админ]", "7")		
		
	if(get_user_flags(id) & BOSS)
		menu_additem(menu, "Вархаммер Тьмы \r[Босс]", "8")
	else
		menu_additem(menu, "\dВархаммер Тьмы [Босс]", "8")	

    if(get_user_flags(id) & HUNTER)
		menu_additem(menu, "Адский Вархаммер \r[Охотник]", "9")
	else
		menu_additem(menu, "\dАдский Вархаммер [Охотник]", "9")			
		
	menu_setprop(menu, MPROP_PERPAGE, 0)

	menu_display(id, menu, 0)
}

public menu_handle(id, menu, item)
{
        if(item < 0) 
                return PLUGIN_CONTINUE
        
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
	if(zp_get_user_level(id) >= LEVEL_KNIFE)
	{
        g_has_axe[id] = true
        g_has_strong[id] = false
        g_has_combat[id] = false
        g_has_hammer[id] = false
		g_has_saxe[id] = false
		g_has_fire[id] = false
		g_has_ice[id] = false
	    g_has_gold[id] = false
		g_has_lol[id] = false


	message_begin(MSG_ONE, get_user_msgid("WeapPickup"), {0,0,0}, id) 
	write_byte(29)
	message_end()
                
	checkWeapon(id)
	//set_knife(id, 1)

	client_cmd(id, "setinfo Knifes 1")

	engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
        }

}

public buy_knife2(id)
{
	if(zp_get_user_level(id) >= LEVEL_KNIFE1)
	{
        g_has_axe[id] = false
        g_has_strong[id] = true
        g_has_combat[id] = false
        g_has_hammer[id] = false
		g_has_saxe[id] = false
		g_has_fire[id] = false
		g_has_ice[id] = false
	    g_has_gold[id] = false
		g_has_lol[id] = false


	message_begin(MSG_ONE, get_user_msgid("WeapPickup"), {0,0,0}, id) 
	write_byte(29)
	message_end()
                
	checkWeapon(id)
	//set_knife(id, 2)

	client_cmd(id, "setinfo Knifes 2")

	engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
        }

}

public buy_knife3(id)
{
        g_has_axe[id] = false
        g_has_strong[id] = false
        g_has_combat[id] = true
        g_has_hammer[id] = false
		g_has_saxe[id] = false
		g_has_fire[id] = false
		g_has_ice[id] = false
		g_has_gold[id] = false
		g_has_lol[id] = false	
        
	message_begin(MSG_ONE, get_user_msgid("WeapPickup"), {0,0,0}, id) 
	write_byte(29)
	message_end()
        
	checkWeapon(id)
	//set_knife(id, 3)

	client_cmd(id, "setinfo Knifes 3")

	engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public buy_knife4(id)
{
	if (get_user_flags(id) & VIP)
	{
        g_has_axe[id] = false
        g_has_strong[id] = false
        g_has_combat[id] = false
        g_has_hammer[id] = true
		g_has_saxe[id] = false
		g_has_fire[id] = false
		g_has_ice[id] = false
	    g_has_gold[id] = false
		g_has_lol[id] = false


	message_begin(MSG_ONE, get_user_msgid("WeapPickup"), {0,0,0}, id) 
	write_byte(29)
	message_end()
                
	checkWeapon(id)
	//set_knife(id, 4)

	client_cmd(id, "setinfo Knifes 4")

	engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
        }

}

public buy_knife5(id)
{
	if (get_user_flags(id) & CVIP)
	{
        g_has_axe[id] = false
        g_has_strong[id] = false
        g_has_combat[id] = false
        g_has_hammer[id] = false
		g_has_saxe[id] = true
		g_has_fire[id] = false
		g_has_ice[id] = false
		g_has_gold[id] = false
		g_has_lol[id] = false


	message_begin(MSG_ONE, get_user_msgid("WeapPickup"), {0,0,0}, id) 
	write_byte(29)
	message_end()
                
	checkWeapon(id)
	//set_knife(id, 4)

	client_cmd(id, "setinfo Knifes 5")

	engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
        }

}

public buy_knife6(id)
{
	if (get_user_flags(id) & ADMIN)
	{
        g_has_axe[id] = false
        g_has_strong[id] = false
        g_has_combat[id] = false
        g_has_hammer[id] = false
		g_has_saxe[id] = false
		g_has_fire[id] = true
		g_has_ice[id] = false
		g_has_gold[id] = false
		g_has_lol[id] = false


	message_begin(MSG_ONE, get_user_msgid("WeapPickup"), {0,0,0}, id) 
	write_byte(29)
	message_end()
                
	checkWeapon(id)
	//set_knife(id, 4)

	client_cmd(id, "setinfo Knifes 6")

	engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
        }

}

public buy_knife7(id)
{
	if (get_user_flags(id) & CADMIN)
	{
        g_has_axe[id] = false
        g_has_strong[id] = false
        g_has_combat[id] = false
        g_has_hammer[id] = false
		g_has_saxe[id] = false
		g_has_fire[id] = false
		g_has_ice[id] = true
		g_has_gold[id] = false
		g_has_lol[id] = false


	message_begin(MSG_ONE, get_user_msgid("WeapPickup"), {0,0,0}, id) 
	write_byte(29)
	message_end()
                
	checkWeapon(id)
	//set_knife(id, 4)

	client_cmd(id, "setinfo Knifes 7")

	engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
        }

}

public buy_knife8(id)
{
	if (get_user_flags(id) & BOSS)
	{
        g_has_axe[id] = false
        g_has_strong[id] = false
        g_has_combat[id] = false
        g_has_hammer[id] = false
		g_has_saxe[id] = false
		g_has_fire[id] = false
		g_has_ice[id] = false
		g_has_gold[id] = true
		g_has_lol[id] = false


	message_begin(MSG_ONE, get_user_msgid("WeapPickup"), {0,0,0}, id) 
	write_byte(29)
	message_end()
                
	checkWeapon(id)
	//set_knife(id, 4)

	client_cmd(id, "setinfo Knifes 8")

	engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
        }

}

public buy_knife9(id)
{
	if (get_user_flags(id) & HUNTER)
	{
        g_has_axe[id] = false
        g_has_strong[id] = false
        g_has_combat[id] = false
        g_has_hammer[id] = false
		g_has_saxe[id] = false
		g_has_fire[id] = false
		g_has_ice[id] = false
		g_has_gold[id] = false
		g_has_lol[id] = true


	message_begin(MSG_ONE, get_user_msgid("WeapPickup"), {0,0,0}, id) 
	write_byte(29)
	message_end()
                
	checkWeapon(id)
	//set_knife(id, 4)

	client_cmd(id, "setinfo Knifes 9")

	engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
        }

}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{	
	if (use_type == 0 && is_user_connected(caller))
		checkWeapon(caller)
}

public checkWeapon(id)
{
        if(!zp_get_user_zombie(id))
        {
	        if(get_user_weapon(id) == CSW_KNIFE)
		{
			if(g_has_axe[id])
			{
	                	set_pev(id, pev_viewmodel2, KNIFE1_V_MODEL)
	                	set_pev(id, pev_weaponmodel2, KNIFE1_P_MODEL)
				//set_pev(id, pev_gravity, 0.6)
			}
			else if(g_has_strong[id] )
			{
	                	set_pev(id, pev_viewmodel2, KNIFE2_V_MODEL)
				set_pev(id, pev_weaponmodel2, KNIFE2_P_MODEL)
				//set_pev(id, pev_gravity, 0.6)
			}
			else if(g_has_combat[id])
			{
	               	 	set_pev(id, pev_viewmodel2, KNIFE3_V_MODEL)
	             	   	set_pev(id, pev_weaponmodel2, KNIFE3_P_MODEL)
				//set_pev(id, pev_gravity, 0.6)
			}
			else if(g_has_hammer[id])
			{
	                	set_pev(id, pev_viewmodel2, KNIFE4_V_MODEL)
	                	set_pev(id, pev_weaponmodel2, KNIFE4_P_MODEL)
			}
			else if(g_has_saxe[id])
			{
	                	set_pev(id, pev_viewmodel2, KNIFE5_V_MODEL)
	                	set_pev(id, pev_weaponmodel2, KNIFE5_P_MODEL)
			}
			else if(g_has_fire[id])
			{
	                	set_pev(id, pev_viewmodel2, KNIFE6_V_MODEL)
	                	set_pev(id, pev_weaponmodel2, KNIFE6_P_MODEL)
			}
			else if(g_has_ice[id])
			{
	                	set_pev(id, pev_viewmodel2, KNIFE7_V_MODEL)
	                	set_pev(id, pev_weaponmodel2, KNIFE7_P_MODEL)
			}
			else if(g_has_gold[id])
			{
	                	set_pev(id, pev_viewmodel2, KNIFE8_V_MODEL)
	                	set_pev(id, pev_weaponmodel2, KNIFE8_P_MODEL)
			}
			else if(g_has_lol[id])
			{
	                	set_pev(id, pev_viewmodel2, KNIFE9_V_MODEL)
	                	set_pev(id, pev_weaponmodel2, KNIFE9_P_MODEL)
			}
		}
	}
}
	
public fw_playerspawn_post(id)
{
	if(!is_user_alive(id))
		return;
		
	ChekKnife(id)
	
	return;
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
			if(g_has_axe[id])
				emit_sound(id, channel, axe_sounds[0], volume, attn, flags, pitch)
			if(g_has_strong[id])
				emit_sound(id, channel, strong_sounds[0], volume, attn, flags, pitch)
			if(g_has_combat[id])
				emit_sound(id, channel, combat_sounds[0], volume, attn, flags, pitch)
			if(g_has_hammer[id])
				emit_sound(id, channel, hammer_sounds[0], volume, attn, flags, pitch)			
			if(g_has_saxe[id])
				emit_sound(id, channel, saxe_sounds[0], volume, attn, flags, pitch)
			if(g_has_fire[id])
				emit_sound(id, channel, fire_sounds[0], volume, attn, flags, pitch)	
			if(g_has_ice[id])
				emit_sound(id, channel, ice_sounds[0], volume, attn, flags, pitch)	
            if(g_has_gold[id])
				emit_sound(id, channel, gold_sounds[0], volume, attn, flags, pitch)
            if(g_has_lol[id])
				emit_sound(id, channel, lol_sounds[0], volume, attn, flags, pitch)				
		}
		else if (sample[14] == 'h')
		{
			if (sample[17] == 'w') 
			{
				if(g_has_axe[id])
					emit_sound(id, channel, axe_sounds[3], volume, attn, flags, pitch)
				if(g_has_strong[id])
					emit_sound(id, channel, strong_sounds[3], volume, attn, flags, pitch)
				if(g_has_combat[id])
					emit_sound(id, channel, combat_sounds[3], volume, attn, flags, pitch)
				if(g_has_hammer[id] )
					emit_sound(id, channel, hammer_sounds[3], volume, attn, flags, pitch)
				if(g_has_saxe[id])
					emit_sound(id, channel, saxe_sounds[3], volume, attn, flags, pitch)
				if(g_has_fire[id])
				    emit_sound(id, channel, fire_sounds[3], volume, attn, flags, pitch)	
                if(g_has_ice[id])
				    emit_sound(id, channel, ice_sounds[3], volume, attn, flags, pitch)
                if(g_has_gold[id])
				    emit_sound(id, channel, lol_sounds[3], volume, attn, flags, pitch)	
                if(g_has_lol[id])
				    emit_sound(id, channel, lol_sounds[3], volume, attn, flags, pitch)					
			}
			else
			{
				if(g_has_axe[id])
					emit_sound(id, channel, axe_sounds[random_num(1,2)], volume, attn, flags, pitch)
				if(g_has_strong[id])
					emit_sound(id, channel, strong_sounds[random_num(1,2)], volume, attn, flags, pitch)
				if(g_has_combat[id])
					emit_sound(id, channel, combat_sounds[random_num(1,2)], volume, attn, flags, pitch)
				if(g_has_hammer[id])
					emit_sound(id, channel, hammer_sounds[random_num(1,2)], volume, attn, flags, pitch)
				if(g_has_saxe[id])
					emit_sound(id, channel, saxe_sounds[random_num(1,2)], volume, attn, flags, pitch)
				if(g_has_fire[id])
					emit_sound(id, channel, fire_sounds[random_num(1,2)], volume, attn, flags, pitch)	
				if(g_has_ice[id])
					emit_sound(id, channel, ice_sounds[random_num(1,2)], volume, attn, flags, pitch)	
				if(g_has_gold[id])
					emit_sound(id, channel, gold_sounds[random_num(1,2)], volume, attn, flags, pitch)
                if(g_has_lol[id])
					emit_sound(id, channel, lol_sounds[random_num(1,2)], volume, attn, flags, pitch)					
			}
		}
		else
		{
			if (sample[15] == 'l') 
			{
				if(g_has_axe[id])
					emit_sound(id, channel, axe_sounds[4], volume, attn, flags, pitch)
				if(g_has_strong[id])
					emit_sound(id, channel, strong_sounds[4], volume, attn, flags, pitch)
				if(g_has_combat[id])
					emit_sound(id, channel, combat_sounds[4], volume, attn, flags, pitch)
				if(g_has_hammer[id])
					emit_sound(id, channel, hammer_sounds[4], volume, attn, flags, pitch)
				if(g_has_saxe[id])
					emit_sound(id, channel, saxe_sounds[4], volume, attn, flags, pitch)
				if(g_has_fire[id])
					emit_sound(id, channel, fire_sounds[4], volume, attn, flags, pitch)	
				if(g_has_ice[id])
					emit_sound(id, channel, ice_sounds[4], volume, attn, flags, pitch)		
				if(g_has_gold[id])
					emit_sound(id, channel, gold_sounds[4], volume, attn, flags, pitch)		
 				if(g_has_lol[id])
					emit_sound(id, channel, lol_sounds[4], volume, attn, flags, pitch)			
			}
			else 
			{
				if(g_has_axe[id])
					emit_sound(id, channel, axe_sounds[5], volume, attn, flags, pitch)
				if(g_has_strong[id] )
					emit_sound(id, channel, strong_sounds[5], volume, attn, flags, pitch)
				if(g_has_combat[id] )
					emit_sound(id, channel, combat_sounds[5], volume, attn, flags, pitch)
				if(g_has_hammer[id])
					emit_sound(id, channel, hammer_sounds[5], volume, attn, flags, pitch)
				if(g_has_saxe[id])
					emit_sound(id, channel, saxe_sounds[5], volume, attn, flags, pitch)
				if(g_has_fire[id])
					emit_sound(id, channel, fire_sounds[5], volume, attn, flags, pitch)	
				if(g_has_ice[id])
					emit_sound(id, channel, ice_sounds[5], volume, attn, flags, pitch)	
 				if(g_has_gold[id])
					emit_sound(id, channel, lol_sounds[5], volume, attn, flags, pitch)
				if(g_has_gold[id])
					emit_sound(id, channel, lol_sounds[5], volume, attn, flags, pitch)		
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

        if (weapon == CSW_KNIFE && g_has_axe[id])
        {
                set_user_maxspeed(id,get_pcvar_float(cvar_speed_axe))
                
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

                        new Float:fVelocity[ 3 ]
                        pev( id , pev_velocity , fVelocity )
		
			fVelocity[ 2 ] += 325

                        set_pev( id , pev_velocity , fVelocity )

                        set_pev(id, pev_gaitsequence, 6)
                }
        }
        
        if(weapon == CSW_KNIFE && g_has_strong[id])
        {
                set_user_maxspeed(id,get_pcvar_float(cvar_speed_strong)) 
                
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

                        new Float:fVelocity[ 3 ]
                        pev( id , pev_velocity , fVelocity )
		
			fVelocity[ 2 ] += 320

                        set_pev( id , pev_velocity , fVelocity )
                        
                        set_pev(id, pev_gaitsequence, 6)
                }       
        }

        if(weapon == CSW_KNIFE && g_has_combat[id])   
        {     
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

                        new Float:fVelocity[ 3 ]
                        pev( id , pev_velocity , fVelocity )
		
			fVelocity[ 2 ] += 320

                        set_pev( id , pev_velocity , fVelocity )
                        
                        set_pev(id, pev_gaitsequence, 6)
                }
                
                set_user_maxspeed(id,get_pcvar_float(cvar_speed_combat))  
        }
        if (weapon == CSW_KNIFE && g_has_hammer[id])
        {
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

                        new Float:fVelocity[ 3 ]
                        pev( id , pev_velocity , fVelocity )
		
			fVelocity[ 2 ] += 345

                        set_pev( id , pev_velocity , fVelocity )
                        
                        set_pev(id, pev_gaitsequence, 6)
                }
                
                set_user_maxspeed(id, get_pcvar_float(cvar_speed_hammer))
        }
		if (weapon == CSW_KNIFE && g_has_saxe[id])
        {
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

                        new Float:fVelocity[ 3 ]
                        pev( id , pev_velocity , fVelocity )
		
			fVelocity[ 2 ] += 345

                        set_pev( id , pev_velocity , fVelocity )
                        
                        set_pev(id, pev_gaitsequence, 6)
                }
                
                set_user_maxspeed(id, get_pcvar_float(cvar_speed_saxe))
        }
		if (weapon == CSW_KNIFE && g_has_fire[id])
        {
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

                        new Float:fVelocity[ 3 ]
                        pev( id , pev_velocity , fVelocity )
		
			fVelocity[ 2 ] += 345

                        set_pev( id , pev_velocity , fVelocity )
                        
                        set_pev(id, pev_gaitsequence, 6)
                }
                
                set_user_maxspeed(id, get_pcvar_float(cvar_speed_fire))
        }
		if (weapon == CSW_KNIFE && g_has_ice[id])
        {
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

                        new Float:fVelocity[ 3 ]
                        pev( id , pev_velocity , fVelocity )
		
			fVelocity[ 2 ] += 345

                        set_pev( id , pev_velocity , fVelocity )
                        
                        set_pev(id, pev_gaitsequence, 6)
                }
                
                set_user_maxspeed(id, get_pcvar_float(cvar_speed_ice))
        }
		if (weapon == CSW_KNIFE && g_has_gold[id])
        {
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

                        new Float:fVelocity[ 3 ]
                        pev( id , pev_velocity , fVelocity )
		
			fVelocity[ 2 ] += 345

                        set_pev( id , pev_velocity , fVelocity )
                        
                        set_pev(id, pev_gaitsequence, 6)
                }
                
                set_user_maxspeed(id, get_pcvar_float(cvar_speed_gold))
        }
		if (weapon == CSW_KNIFE && g_has_lol[id])
        {
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

                        new Float:fVelocity[ 3 ]
                        pev( id , pev_velocity , fVelocity )
		
			fVelocity[ 2 ] += 345

                        set_pev( id , pev_velocity , fVelocity )
                        
                        set_pev(id, pev_gaitsequence, 6)
                }
                
                set_user_maxspeed(id, get_pcvar_float(cvar_speed_lol))
        }
		
        return FMRES_IGNORED
}  

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, _type)
{
        if(!is_user_connected(attacker))
                return HAM_IGNORED
        
        if(zp_get_user_zombie(attacker))
                return HAM_IGNORED
        
        if(get_user_weapon(attacker) == CSW_KNIFE)
        {
                if (g_has_axe[attacker])
                {
                        SetHamParamFloat(4, damage * get_pcvar_float(cvar_damage_axe)) 
                        
                        new Float:vec[3];
                        new Float:oldvelo[3];
                        pev(victim, pev_velocity, oldvelo);
                        create_velocity_vector(victim , attacker , vec);
                        vec[0] += oldvelo[0] + get_pcvar_float(cvar_knock_axe);
                        vec[1] += oldvelo[1] + 0;
                        set_pev(victim, pev_velocity, vec);   
                }
                else if (g_has_strong[attacker])
                {       
                        SetHamParamFloat(4, damage * get_pcvar_float(cvar_damage_strong)) 
                        
                        new Float:vec[3];
                        new Float:oldvelo[3];
                        pev(victim, pev_velocity, oldvelo);
                        create_velocity_vector(victim , attacker , vec);
                        vec[0] += oldvelo[0] + get_pcvar_float(cvar_knock_strong);
                        vec[1] += oldvelo[1] + 0;
                        set_pev(victim, pev_velocity, vec);   
                }
                else if (g_has_combat[attacker])
                {       
                        SetHamParamFloat(4, damage * get_pcvar_float(cvar_damage_combat)) 
                        
                        new Float:vec[3];
                        new Float:oldvelo[3];
                        pev(victim, pev_velocity, oldvelo);
                        create_velocity_vector(victim , attacker , vec);
                        vec[0] += oldvelo[0] + get_pcvar_float(cvar_knock_combat);
                        vec[1] += oldvelo[1] + 0;
                        set_pev(victim, pev_velocity, vec);   
                }
                else if (g_has_hammer[attacker])
                {       
                        SetHamParamFloat(4, damage * get_pcvar_float(cvar_damage_hammer)) 
                        
                        new Float:vec[3];
                        new Float:oldvelo[3];
                        pev(victim, pev_velocity, oldvelo);
                        create_velocity_vector(victim , attacker , vec);
                        vec[0] += oldvelo[0] + get_pcvar_float(cvar_knock_hammer);
                        vec[1] += oldvelo[1] + 0;
                        set_pev(victim, pev_velocity, vec);
                }                
				else if (g_has_saxe[attacker])
                {       
                        SetHamParamFloat(4, damage * get_pcvar_float(cvar_damage_saxe)) 
                        
                        new Float:vec[3];
                        new Float:oldvelo[3];
                        pev(victim, pev_velocity, oldvelo);
                        create_velocity_vector(victim , attacker , vec);
                        vec[0] += oldvelo[0] + get_pcvar_float(cvar_knock_saxe);
                        vec[1] += oldvelo[1] + 0;
                        set_pev(victim, pev_velocity, vec);
						
						if( !task_exists( victim + TASK_FBURN ) )
						{
							g_burning_duration[ victim ] += FIRE_DURATION * 5
							set_task( 0.2, "CTask__BurningFlame", victim + TASK_FBURN, _, _, "b" )
						}	
                }
				else if (g_has_fire[attacker])
                {       
                        SetHamParamFloat(4, damage * get_pcvar_float(cvar_damage_fire)) 
                        
                        new Float:vec[3];
                        new Float:oldvelo[3];
                        pev(victim, pev_velocity, oldvelo);
                        create_velocity_vector(victim , attacker , vec);
                        vec[0] += oldvelo[0] + get_pcvar_float(cvar_knock_fire);
                        vec[1] += oldvelo[1] + 0;
                        set_pev(victim, pev_velocity, vec);
						
						if( !task_exists( victim + TASK_FBURN ) )
						{
							g_burning_duration[ victim ] += FIRE_DURATION * 5
							set_task( 0.2, "CTask__BurningFlame1", victim + TASK_FBURN, _, _, "b" )
						}	
                }
				else if (g_has_ice[attacker])
                {       
                        SetHamParamFloat(4, damage * get_pcvar_float(cvar_damage_ice)) 
                        
                        new Float:vec[3];
                        new Float:oldvelo[3];
                        pev(victim, pev_velocity, oldvelo);
                        create_velocity_vector(victim , attacker , vec);
                        vec[0] += oldvelo[0] + get_pcvar_float(cvar_knock_ice);
                        vec[1] += oldvelo[1] + 0;
                        set_pev(victim, pev_velocity, vec);
						
						if( !task_exists( victim + TASK_FBURN ) )
						{
							g_burning_duration[ victim ] += FIRE_DURATION * 5
							set_task( 0.2, "CTask__BurningFlame", victim + TASK_FBURN, _, _, "b" )
						}	
                }
				else if (g_has_gold[attacker])
                {       
                        SetHamParamFloat(4, damage * get_pcvar_float(cvar_damage_gold)) 
                        
                        new Float:vec[3];
                        new Float:oldvelo[3];
                        pev(victim, pev_velocity, oldvelo);
                        create_velocity_vector(victim , attacker , vec);
                        vec[0] += oldvelo[0] + get_pcvar_float(cvar_knock_gold);
                        vec[1] += oldvelo[1] + 0;
                        set_pev(victim, pev_velocity, vec);
						
						if( !task_exists( victim + TASK_FBURN ) )
						{
							g_burning_duration[ victim ] += FIRE_DURATION * 5
							set_task( 0.2, "CTask__BurningFlame", victim + TASK_FBURN, _, _, "b" )
						}	
                }
				else if (g_has_lol[attacker])
                {       
                        SetHamParamFloat(4, damage * get_pcvar_float(cvar_damage_lol)) 
                        
                        new Float:vec[3];
                        new Float:oldvelo[3];
                        pev(victim, pev_velocity, oldvelo);
                        create_velocity_vector(victim , attacker , vec);
                        vec[0] += oldvelo[0] + get_pcvar_float(cvar_knock_lol);
                        vec[1] += oldvelo[1] + 0;
                        set_pev(victim, pev_velocity, vec);
						
						if( !task_exists( victim + TASK_FBURN ) )
						{
							g_burning_duration[ victim ] += FIRE_DURATION * 5
							set_task( 0.2, "CTask__BurningFlame", victim + TASK_FBURN, _, _, "b" )
						}	
                }
                more_blood(victim)
        }

        return HAM_IGNORED
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
                        if(g_has_axe[iattacker])
                                set_msg_arg_string(4, "axe")
                }
        
                if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
                {
                        if(g_has_strong[iattacker])
                                set_msg_arg_string(4, "hatchet")
                }
        
                if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
                {
                        if(g_has_combat[iattacker])
                                set_msg_arg_string(4, "mastercombat")
                }
        
                if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
                {
                        if(g_has_hammer[iattacker])
                                set_msg_arg_string(4, "hammer")
                }
				if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
                {
                        if(g_has_saxe[iattacker])
                                set_msg_arg_string(4, "skullaxe")
                }
				if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
                {
                        if(g_has_saxe[iattacker])
                                set_msg_arg_string(4, "fire")
                }
				if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
                {
                        if(g_has_saxe[iattacker])
                                set_msg_arg_string(4, "ice")
                }
				if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
                {
                        if(g_has_saxe[iattacker])
                                set_msg_arg_string(4, "gold")
                }
				if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
                {
                        if(g_has_saxe[iattacker])
                                set_msg_arg_string(4, "lol")
                }
        
                if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
                {
                        if(!g_has_axe[iattacker] && !g_has_strong[iattacker] && !g_has_combat[iattacker] && !g_has_hammer[iattacker] && !g_has_saxe[iattacker] && !zp_get_user_zombie(iattacker))
                                set_msg_arg_string(4, "knife")
                }
        }
        if (zp_get_user_zombie(iattacker))
        {
                if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
                {
                        if(g_has_axe[iattacker] || g_has_strong[iattacker] || g_has_combat[iattacker] || g_has_hammer[iattacker])
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
        
        if (g_has_axe[attacker])
        {
                velocity[0] = ( origin2[0] * get_pcvar_float(cvar_knock_axe) * 10000 ) / floatround(get_distance_f(vicorigin, attorigin));
                velocity[1] = ( origin2[1] * get_pcvar_float(cvar_knock_axe) * 10000 ) / floatround(get_distance_f(vicorigin, attorigin));
        }
        else if (g_has_strong[attacker])
        {
                velocity[0] = ( origin2[0] * get_pcvar_float(cvar_knock_strong) * 10000 ) / floatround(get_distance_f(vicorigin, attorigin));
                velocity[1] = ( origin2[1] * get_pcvar_float(cvar_knock_strong) * 10000 ) / floatround(get_distance_f(vicorigin, attorigin));
        }
        else if (g_has_combat[attacker])
        {
                velocity[0] = ( origin2[0] * get_pcvar_float(cvar_knock_combat) * 10000 ) / floatround(get_distance_f(vicorigin, attorigin));
                velocity[1] = ( origin2[1] * get_pcvar_float(cvar_knock_combat) * 10000 ) / floatround(get_distance_f(vicorigin, attorigin));
        }
        else if (g_has_hammer[attacker])
        {
                velocity[0] = ( origin2[0] * get_pcvar_float(cvar_knock_hammer) * 10000 ) / floatround(get_distance_f(vicorigin, attorigin));
                velocity[1] = ( origin2[1] * get_pcvar_float(cvar_knock_hammer) * 10000 ) / floatround(get_distance_f(vicorigin, attorigin));
        }        
		else if (g_has_saxe[attacker])
        {
                velocity[0] = ( origin2[0] * get_pcvar_float(cvar_knock_saxe) * 10000 ) / floatround(get_distance_f(vicorigin, attorigin));
                velocity[1] = ( origin2[1] * get_pcvar_float(cvar_knock_saxe) * 10000 ) / floatround(get_distance_f(vicorigin, attorigin));
        }
		else if (g_has_fire[attacker])
        {
                velocity[0] = ( origin2[0] * get_pcvar_float(cvar_knock_fire) * 10000 ) / floatround(get_distance_f(vicorigin, attorigin));
                velocity[1] = ( origin2[1] * get_pcvar_float(cvar_knock_fire) * 10000 ) / floatround(get_distance_f(vicorigin, attorigin));
        }
		else if (g_has_ice[attacker])
        {
                velocity[0] = ( origin2[0] * get_pcvar_float(cvar_knock_ice) * 10000 ) / floatround(get_distance_f(vicorigin, attorigin));
                velocity[1] = ( origin2[1] * get_pcvar_float(cvar_knock_ice) * 10000 ) / floatround(get_distance_f(vicorigin, attorigin));
        }
		else if (g_has_gold[attacker])
        {
                velocity[0] = ( origin2[0] * get_pcvar_float(cvar_knock_gold) * 10000 ) / floatround(get_distance_f(vicorigin, attorigin));
                velocity[1] = ( origin2[1] * get_pcvar_float(cvar_knock_gold) * 10000 ) / floatround(get_distance_f(vicorigin, attorigin));
        }else if (g_has_lol[attacker])
        {
                velocity[0] = ( origin2[0] * get_pcvar_float(cvar_knock_lol) * 10000 ) / floatround(get_distance_f(vicorigin, attorigin));
                velocity[1] = ( origin2[1] * get_pcvar_float(cvar_knock_lol) * 10000 ) / floatround(get_distance_f(vicorigin, attorigin));
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

more_blood(id)
{
        static iOrigin[3]
        get_user_origin(id, iOrigin)
        
        message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin)
        write_byte(TE_BLOODSTREAM)
        write_coord(iOrigin[0])
        write_coord(iOrigin[1])
        write_coord(iOrigin[2]+10)
        write_coord(random_num(-360, 360))
        write_coord(random_num(-360, 360))
        write_coord(-10)
        write_byte(70)
        write_byte(random_num(50, 100))
        message_end()

        for (new j = 0; j < 4; j++) 
        {
                message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin)
                write_byte(TE_WORLDDECAL)
                write_coord(iOrigin[0]+random_num(-100, 100))
                write_coord(iOrigin[1]+random_num(-100, 100))
                write_coord(iOrigin[2]-36)
                write_byte(random_num(190, 197))
                message_end()
        }
}

public sprite(const player, const string_msg[], byte_1, byte_2, byte_3, byte_4, byte_5, byte_6, byte_7, byte_8)
{
	message_begin( MSG_ONE, get_user_msgid("WeaponList"), .player = player );
	{
		write_string(string_msg);
		write_byte(byte_1);
		write_byte(byte_2);
		write_byte(byte_3);
		write_byte(byte_4);
		write_byte(byte_5);
		write_byte(byte_6);
		write_byte(byte_7);
		write_byte(byte_8);
	}
	message_end();
}

stock ChekKnife(id)
{
	new str[3]
	get_user_info(id, "Knifes", str, charsmax(str))

	switch(str[0])
	{
		case '1':
		{
	        	g_has_axe[id] = true
	        	g_has_strong[id] = false
		        g_has_combat[id] = false
		        g_has_hammer[id] = false
				g_has_saxe[id] = false
				g_has_fire[id] = false
				g_has_ice[id] = false
				g_has_gold[id] = false
				g_has_lol[id] = false
		}
		case '2':
		{
	        	g_has_axe[id] = false
	        	g_has_strong[id] = true
		        g_has_combat[id] = false
		        g_has_hammer[id] = false
				g_has_saxe[id] = false
				g_has_fire[id] = false
				g_has_ice[id] = false
				g_has_gold[id] = false
				g_has_lol[id] = false
		}
		case '3':
		{
	        	g_has_axe[id] = false
	        	g_has_strong[id] = false
		        g_has_combat[id] = true
		        g_has_hammer[id] = false	
				g_has_saxe[id] = false
				g_has_fire[id] = false
				g_has_ice[id] = false
				g_has_gold[id] = false
				g_has_lol[id] = false
		}
		case '4':
		{
			if(get_user_flags(id) & VIP)
			{
	        		g_has_axe[id] = false
	        		g_has_strong[id] = false
				g_has_combat[id] = false
		        	g_has_hammer[id] = true	
					g_has_saxe[id] = false
					g_has_fire[id] = false
					g_has_ice[id] = false
					g_has_gold[id] = false
				g_has_lol[id] = false
			}
			else random_num(buy_knife1(id) , buy_knife2(id))
		}
		case '5':
		{
			if(get_user_flags(id) & CVIP)
			{
	        		g_has_axe[id] = false
	        		g_has_strong[id] = false
				g_has_combat[id] = false
		        	g_has_hammer[id] = false	
					g_has_saxe[id] = true	
					g_has_fire[id] = false
					g_has_ice[id] = false
					g_has_gold[id] = false
				g_has_lol[id] = false
			}
			else random_num(buy_knife1(id) , buy_knife2(id))
		}
		case '6':
		{
			if(get_user_flags(id) & ADMIN)
			{
	        		g_has_axe[id] = false
	        		g_has_strong[id] = false
				g_has_combat[id] = false
		        	g_has_hammer[id] = false	
					g_has_saxe[id] = false	
					g_has_fire[id] = true
					g_has_ice[id] = false
					g_has_gold[id] = false
				g_has_lol[id] = false
			}
			else random_num(buy_knife1(id) , buy_knife2(id))
		}
		case '7':
		{
			if(get_user_flags(id) & CADMIN)
			{
	        		g_has_axe[id] = false
	        		g_has_strong[id] = false
				g_has_combat[id] = false
		        	g_has_hammer[id] = false	
					g_has_saxe[id] = false	
					g_has_fire[id] = false
					g_has_ice[id] = true
					g_has_gold[id] = false
				g_has_lol[id] = false
			}
			else random_num(buy_knife1(id) , buy_knife2(id))
		}
		case '8':
		{
			if(get_user_flags(id) & BOSS)
			{
	        		g_has_axe[id] = false
	        		g_has_strong[id] = false
				g_has_combat[id] = false
		        	g_has_hammer[id] = false	
					g_has_saxe[id] = false	
					g_has_fire[id] = false
					g_has_ice[id] = false
					g_has_gold[id] = true
				g_has_lol[id] = false
			}
			else random_num(buy_knife1(id) , buy_knife2(id))
		}
		case '9':
		{
			if(get_user_flags(id) & HUNTER)
			{
	        		g_has_axe[id] = false
	        		g_has_strong[id] = false
				g_has_combat[id] = false
		        	g_has_hammer[id] = false	
					g_has_saxe[id] = false	
					g_has_fire[id] = false
					g_has_ice[id] = false
					g_has_gold[id] = false
				g_has_lol[id] = true
			}
			else random_num(buy_knife1(id) , buy_knife2(id))
		}
	}
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

stock fm_set_user_health( index, health ) 
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index)

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

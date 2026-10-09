#include < amxmodx >
#include < fakemeta >
#include < hamsandwich >
#include < zombieplague >
#include < engine >
#include < fun >

native zp_get_user_rub(id)
native zp_set_user_rub(id, amount)

new const PLUGIN_NAME[ ] 		= "[ZP] Bonus Zombies Kill";
new const PLUGIN_VERSION[ ] 		= "0.0.2";
new const PLUGIN_AUTHOR[ ] 		= "texas1k";

const MAX_CLIENTS  = 32;
const PDATA_SAFE = 2;
const OFFSET_CSMONEY = 115;
const OFFSET_LINUX = 5;
const OFFSET_AWM_AMMO  = 377 ;
const OFFSET_SCOUT_AMMO = 378;
const OFFSET_PARA_AMMO = 379;
const OFFSET_FAMAS_AMMO = 380;
const OFFSET_M3_AMMO = 381;
const OFFSET_USP_AMMO = 382;
const OFFSET_FIVESEVEN_AMMO = 383;
const OFFSET_DEAGLE_AMMO = 384;
const OFFSET_P228_AMMO = 385;
const OFFSET_GLOCK_AMMO = 386;
const OFFSET_FLASH_AMMO = 387;
const OFFSET_HE_AMMO = 388;
const OFFSET_SMOKE_AMMO = 389;
const OFFSET_C4_AMMO = 390;


new const g_szClassName[ ] 		= "ZombiesBBox";

const BONUS_MAX_HEALTH = 100;
const BONUS_LIMIT_HEALTH = 400;

const BONUS_MAX_MONEY = 250;
const BONUS_MAX_RUB = 5;

#define ZombiesBBox 				"models/texas1k/texas1k_present.mdl" 
new const ZombiesBBox_Sound[ ] 	= "texas1k/ammo_sound.wav";
new const g_sound_buyammo[ ] 		= "texas1k/clip.wav"
new const g_sound_heal[ ]	 		= "texas1k/medkit.wav"


enum _:AmmoIds 
{ 
    ammo_none, 
    ammo_338magnum = 1, 
    ammo_762nato, 
    ammo_556natobox, 
    ammo_556nato, 
    ammo_buckshot, 
    ammo_45acp, 
    ammo_57mm, 
    ammo_50ae, 
    ammo_357sig, 
    ammo_9mm 
};

new g_iAmmoMax[ AmmoIds ] = 
{ 
    -1, 
    30, // 338magnum 
    90, // 762nato 
    200, // 556natobox 
    90, // 556nato 
    32, // buckshot 
    100, // 45acp 
    100, // 57mm 
    35, // 50ae 
    52, // 357sig 
    120  // 9mm 
}; 

new const g_iAmmoWeaponSharedBitSum[ AmmoIds ] = 
{ 
    0, 
    (1<<CSW_AWP), 
    (1<<CSW_SCOUT)|(1<<CSW_G3SG1)|(1<<CSW_AK47), 
    (1<<CSW_M249), 
    (1<<CSW_AUG)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_M4A1)|(1<<CSW_SG552), 
    (1<<CSW_XM1014)|(1<<CSW_M3), 
    (1<<CSW_MAC10)|(1<<CSW_UMP45)|(1<<CSW_USP), 
    (1<<CSW_P90)|(1<<CSW_FIVESEVEN), 
    (1<<CSW_DEAGLE), 
    (1<<CSW_P228), 
    (1<<CSW_MP5NAVY)|(1<<CSW_TMP)|(1<<CSW_ELITE)|(1<<CSW_GLOCK18) 
};

new const AMMOOFFSET[] = { -1, OFFSET_P228_AMMO, -1, OFFSET_SCOUT_AMMO, OFFSET_HE_AMMO, OFFSET_M3_AMMO, OFFSET_C4_AMMO, OFFSET_USP_AMMO, OFFSET_FAMAS_AMMO, OFFSET_SMOKE_AMMO, OFFSET_GLOCK_AMMO, OFFSET_FIVESEVEN_AMMO, OFFSET_USP_AMMO, OFFSET_FAMAS_AMMO, OFFSET_FAMAS_AMMO, OFFSET_FAMAS_AMMO,
 OFFSET_USP_AMMO, OFFSET_GLOCK_AMMO, OFFSET_AWM_AMMO, OFFSET_GLOCK_AMMO, OFFSET_PARA_AMMO, OFFSET_M3_AMMO, OFFSET_FAMAS_AMMO, OFFSET_GLOCK_AMMO, OFFSET_SCOUT_AMMO, OFFSET_FLASH_AMMO, OFFSET_DEAGLE_AMMO, OFFSET_FAMAS_AMMO,  OFFSET_SCOUT_AMMO, -1, OFFSET_FIVESEVEN_AMMO }


//new g_pChance[ MAX_CLIENTS + 1 ];
new Float:g_vecOrigin[ MAX_CLIENTS + 1 ][ 3 ];

new g_pEntity;
new g_pMsgID_AmmoX;

new g_hamczbots, cvar_botquota;

public plugin_precache( )
{
	precache_model( ZombiesBBox);
	
	precache_sound(g_sound_buyammo);
	precache_sound(g_sound_heal)

	precache_sound( ZombiesBBox_Sound );
}


public plugin_init( )
{
	register_plugin( PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR );
	
	register_event("HLTV", "eventHLTV", "a", "1=0", "2=0");

	RegisterHam( Ham_Killed, "player", "CBasePlayer__Killed_Post", .Post = true );
	RegisterHam( Ham_Touch, "info_target", "CBaseEntity__Touch_Pre", .Post = false );

	g_pMsgID_AmmoX = get_user_msgid( "AmmoX" );
	cvar_botquota = get_cvar_pointer( "bot_quota" );
	
	register_dictionary("zp_zombie_kill_bonus.txt") ;
}

public eventHLTV( )	
{
	new entity = -1;
	
	while((entity = find_ent_by_class(entity, g_szClassName)))
	{
		remove_entity(entity);
	}
}

public CBasePlayer__Killed_Post( pevVictim )
{
	if( !zp_get_user_zombie( pevVictim ) )
	{
		return HAM_IGNORED;
	}

	//g_pChance[ pevVictim ] = random_num( 0 , 8 );

	//if( g_pChance[ pevVictim ] >= 4 )
	//{
	//	return HAM_IGNORED;
	//}

	pev( pevVictim, pev_origin, g_vecOrigin[ pevVictim ] );

	CreateBBox(  g_vecOrigin[ pevVictim ] );

	return HAM_IGNORED;
}


public CreateBBox( Float:vOrigin[ 3 ] )
{
	g_pEntity = engfunc( EngFunc_CreateNamedEntity , engfunc( EngFunc_AllocString,"info_target" ) );

	
	if( !pev_valid( g_pEntity ) )
	{
		return;
	}

	//vOrigin[ 0 ] += 25.0;

	set_pev( g_pEntity, pev_classname, g_szClassName );
	set_pev( g_pEntity, pev_model, ZombiesBBox );

	engfunc( EngFunc_SetModel, g_pEntity, ZombiesBBox );
	engfunc( EngFunc_SetSize, g_pEntity, Float:{ -1.0, -1.0, -1.0}, Float:{  2.5,  2.5,  2.5 });
	engfunc( EngFunc_SetOrigin, g_pEntity, vOrigin );	

	set_pev( g_pEntity , pev_body , random_num( 25 , 29 ) )
	
	set_pev( g_pEntity, pev_solid, SOLID_BBOX);
	set_pev( g_pEntity, pev_movetype, MOVETYPE_TOSS);

	UTIL_set_rendering( g_pEntity, kRenderFxGlowShell, random_num( 0 , 255 ), random_num( 0 , 255 ), random_num( 0 , 255 ) , kRenderNormal, 15)

	set_pev( g_pEntity, pev_nextthink, get_gametime() + 0.2);
}


public CBaseEntity__Touch_Pre( pEntity , pPlayer )
{
	if( !pev_valid( pEntity ) || !is_user_alive( pPlayer ) || !UTIL_get_user_human( pPlayer ) )
	{
		return HAM_IGNORED;
	}

	static zsClassname[ 32 ];

	pev( pEntity, pev_classname, zsClassname, charsmax( zsClassname ) );

	if( !equal( zsClassname, g_szClassName ) )
	{
		return HAM_IGNORED;
	}

	switch ( pev( pEntity, pev_body) )
	{
		case 25: 
		{
			  set_pev( pPlayer, pev_health, float(min(pev(pPlayer, pev_health) + BONUS_MAX_HEALTH, BONUS_LIMIT_HEALTH))) 
			  client_print(pPlayer, print_center, "%L", LANG_PLAYER, "KILLBONUS_HEATLH" )
			  engfunc( EngFunc_EmitSound, pPlayer, CHAN_ITEM, g_sound_heal, 1.0, ATTN_NORM, 0, PITCH_NORM);
		}	  
		case 26: 
		{
			 zp_set_user_ammo_packs( pPlayer , zp_get_user_ammo_packs( pPlayer ) + BONUS_MAX_MONEY);
			 client_print(pPlayer, print_center, "%L", LANG_PLAYER, "KILLBONUS_MONEY" )
			 engfunc( EngFunc_EmitSound, pPlayer, CHAN_ITEM, ZombiesBBox_Sound, 1.0, ATTN_NORM, 0, PITCH_NORM);
		}	 
		case 27: 
		{ 
			 set_user_armor(pPlayer , get_user_armor( pPlayer ) + 100 );
			 client_print(pPlayer, print_center, "%L", LANG_PLAYER, "KILLBONUS_ARMOR" )
		}	 
		case 28: 
		{
			 UTIL_SetFullBpAmmo( pPlayer ) 
			 client_print(pPlayer, print_center, "%L", LANG_PLAYER, "KILLBONUS_AMMO" )
			 engfunc( EngFunc_EmitSound, pPlayer, CHAN_ITEM, g_sound_buyammo, 1.0, ATTN_NORM, 0, PITCH_NORM);
		}  
		case 29: 
		{
			 zp_set_user_rub( pPlayer , zp_get_user_rub( pPlayer ) + BONUS_MAX_RUB);
			 client_print(pPlayer, print_center, "%L", LANG_PLAYER, "KILLBONUS_RUB" )
			 engfunc( EngFunc_EmitSound, pPlayer, CHAN_ITEM, ZombiesBBox_Sound, 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
	}

	engfunc( EngFunc_RemoveEntity , pEntity );

	return HAM_IGNORED;
}	

stock UTIL_set_user_bpammo( pPlayer, pWeapon , pAmount )
{
	if ( pev_valid( pPlayer ) != PDATA_SAFE )
	{
		return;
	}

	set_pdata_int( pPlayer , AMMOOFFSET[ pWeapon ] , pAmount, OFFSET_LINUX);
}

stock UTIL_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3];
	color[0] = float(r);
	color[1] = float(g);
	color[2] = float(b);
	
	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, color);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, float(amount));
}

stock UTIL_get_user_human( pPlayer )
{
	return ( !zp_get_user_zombie( pPlayer ) && !zp_get_user_nemesis( pPlayer ) && !zp_get_user_survivor( pPlayer ) )
}

stock UTIL_SetFullBpAmmo( pPlayer ) 
{ 
    	new iWeaponID , iFullbpammo, iAmmoId;
     
   	iWeaponID = get_user_weapon( pPlayer , _ , _ ); 
     
    	for( new i = 1; i < AmmoIds; i++ ) 
    	{ 
        	if( g_iAmmoWeaponSharedBitSum[i] & (1<<iWeaponID) ) 
        	{ 
            		iAmmoId = i; 
            		iFullbpammo = g_iAmmoMax[i]; 
            		break;
        	} 
    	} 
     
    	if( !iAmmoId ) 
	{
		return; 
     	}

    	UTIL_set_user_bpammo( pPlayer, iWeaponID, iFullbpammo ); 
     
    	message_begin( MSG_ONE_UNRELIABLE, g_pMsgID_AmmoX, _, pPlayer ); 
    	write_byte( iAmmoId ); 
    	write_byte( iFullbpammo ); 
    	message_end( ); 
} 

public register_ham_czbots( pPlayer )
{
	if( g_hamczbots || !is_user_connected( pPlayer ) || !get_pcvar_num( cvar_botquota ) ) 
	{
		return;
	}
	
	RegisterHamFromEntity( Ham_Killed, pPlayer, "CBasePlayer__Killed_Post", 1 );

	g_hamczbots = true;
}

public client_putinserver( pPlayer )
{
	if( is_user_bot( pPlayer ) && !g_hamczbots && cvar_botquota ) 
	{
		set_task( 0.1, "register_ham_czbots", pPlayer );
	}
}
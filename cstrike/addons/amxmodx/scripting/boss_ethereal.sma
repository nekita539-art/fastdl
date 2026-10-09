#include < amxmodx >
#include < cstrike >
#include < xs >
#include < fun >
#include < engine >
#include < fakemeta >
#include < fakemeta_util >
#include < hamsandwich >
#include < amxmisc >
#include < zombieplague >

new const PLUGIN_VERSION[ ]    =  "0.0.1";

//#define SET__MUZZLE 

const OFFSET_WEAPONOWNER    =      41
const OFFSET_LINUX    =    5
const OFFSET_LINUX_WEAPONS     =      4

const WEAP_KEY   =	545464464
const MAX_PLAYERS   =		32

const m_iClip			=		51
const m_fInReload		=		54
const m_flNextAttack		=		83
const m_flNextPrimaryAttack    =    46

enum ( <<=1 )
{
	DROP_PRIMARY = 1,
	DROP_SECONDARY
};

const IDLE = 0 
const RELOAD = 1
const DRAW = 2
const SHOOT_1 = 3 
const SHOOT_2 = 5 

new const g_iMuzzleFlash[ ]  = "sprites/arena/ex.spr" ; 
new const g_iTrace[ ]  = "sprites/laserbeam.spr"  

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)
#define HoldCBaseWeapon(%0)	( get_user_weapon( %0 ) == g_iWeaponID  && g_pWeaponA[ %0 ] )
#define IsValidPrivateData(%0)	( pev_valid( %0 ) == 2 )

new const WEAPON_SOUND_FIRE[ ] = "boss_weapons/ethereal-1.wav";

new const WEAPON_BASE_NAME[ ]   =  "weapon_ump45";

const Float:RELOAD_TIME  =   3.0

const AMMO_WEAPON        =  180 

new V_MODEL[ ] = "models/boss_weapons/v_ethereal.mdl";
new P_MODEL[ ] = "models/boss_weapons/p_ethereal.mdl";
new W_MODEL[ ] = "models/boss_weapons/w_ethereal.mdl";
 
new const TRACE_ATTACK[ ] [ ] = 
{
    "func_breakable" , 
	"func_wall" , 
	"func_door" ,
	"func_plat" , 
	"func_rotating" , 
	"worldspawn"
};

new g_iOriginEvent , g_iMaxPlayers , g_iForwardIndex;
	
new Float:cl_pushangle[ MAX_PLAYERS + 1 ][ 3 ], g_IndexBlood[ 2 ]

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 };

new g_pWeaponA[ MAX_PLAYERS + 1 ] , 
    bool:g_iPrimaryAttack;
	
new g_iClipAmmo[ MAX_PLAYERS + 1 ], 
	g_TmpClip[ MAX_PLAYERS + 1 ] , 
	g_iWeaponID = 0;
	
new g_Kah	

new cvar_speed , cvar_damage , cvar_recoil , cvar_ammo , cvar_clip , cvar_scale_muzzle 

new g_hamczbots, cvar_botquota;

const WEAPONS_PRIMARY_BITSUM 	= (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90);
const WEAPONS_SECONDARY_BITSUM 	= (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE);

public plugin_precache()
{
	precache_model(V_MODEL);
	precache_model(P_MODEL);
	precache_model(W_MODEL);
	
	precache_sound(WEAPON_SOUND_FIRE);
	
	precache_model( g_iMuzzleFlash ) 
	g_Kah = precache_model( g_iTrace ) 
	
	g_IndexBlood[0] = precache_model("sprites/blood.spr");
	g_IndexBlood[1] = precache_model("sprites/bloodspray.spr");
	
	g_iForwardIndex = register_forward( FM_PrecacheEvent, "Forward_PrecacheEventPost", true );
}

public plugin_init()
{
	register_plugin( "[CSO] Ethereal" , PLUGIN_VERSION , "Shurik07" );
	
	unregister_forward( FM_PrecacheEvent, g_iForwardIndex, true );
	register_forward(FM_SetModel, "Forward_SetModel" , false );
	register_forward(FM_PlaybackEvent, "Forward_PlayBackEvent" , false )
	register_forward(FM_UpdateClientData, "Forward_UpdateClientData" , true );
	
	register_message( get_user_msgid("DeathMsg") , "ClMsg_Death" )
	
	RegisterHam(Ham_Item_AddToPlayer, WEAPON_BASE_NAME, "CBaseWeapon__AddToPlayer__Pre" , .Post = false );
	RegisterHam(Ham_Item_Deploy, WEAPON_BASE_NAME , "CBaseWeapon__Deploy__Post", .Post = true );
	RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_BASE_NAME, "CBaseWeapon__PrimaryAttack__Pre" , .Post = false );
	RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_BASE_NAME, "CBaseWeapon_PrimaryAttack_Post", .Post = true );
	RegisterHam(Ham_Item_PostFrame, WEAPON_BASE_NAME, "CBaseWeapon__PostFrame__Pre" , .Post = false );
	RegisterHam(Ham_Weapon_Reload, WEAPON_BASE_NAME, "CBaseWeapon__Reload_Pre" , .Post = false );
	RegisterHam(Ham_Weapon_Reload, WEAPON_BASE_NAME, "CBaseWeapon__Reload_Post", .Post = true );
	
	RegisterHam(Ham_TakeDamage, "player", "CBasePlayer__TakeDamage__Pre" , .Post = false );
	
	for ( new i = 0 ; i < sizeof TRACE_ATTACK ; i++ )
	{
	         RegisterHam( Ham_TraceAttack, TRACE_ATTACK[ i ], "CbaseEntity__TraceAttack__Post",.Post = true );
	}	

	cvar_speed = register_cvar( "ethereal_speed" , "0.09" ) 
	cvar_damage = register_cvar( "ethereal_damage" , "4.0" ) 
	cvar_recoil  = register_cvar( "ethereal_recoil" , "0.1" ) 
	cvar_ammo = register_cvar( "ethereal_ammo" , "90" ) 
	cvar_clip = register_cvar( "ethereal_clip" , "30" ) 
	cvar_scale_muzzle = register_cvar( "ethereal_muzzle_scale" , "0.1" ) 
	
	g_iMaxPlayers = get_maxplayers();
	g_iWeaponID = get_weaponid( WEAPON_BASE_NAME );
	cvar_botquota = get_cvar_pointer( "bot_quota" );
}

public plugin_natives() register_native("give_ethereal", "get_ethereal", 1)

public get_ethereal(id)
{
	UTIL__DropWeapons( id, DROP_PRIMARY )

	g_pWeaponA[ id ]  = true;

	new pEntity;

	pEntity = give_item( id , WEAPON_BASE_NAME ); 

	if( pEntity > 0 )
	{
		cs_set_weapon_ammo( pEntity, get_pcvar_num( cvar_clip ) );	

		cs_set_user_bpammo( id , g_iWeaponID , get_pcvar_num( cvar_ammo ) );
	}	
}

public register_ham_czbots( pPlayer )
{
	if( g_hamczbots || !is_user_connected( pPlayer ) || !get_pcvar_num( cvar_botquota ) ) 
	{
		return;
	}
	
	RegisterHamFromEntity(Ham_TakeDamage, pPlayer, "CBasePlayer__TakeDamage__Pre" );

	g_hamczbots = true;
}

public client_putinserver( pPlayer )
{
	if( is_user_bot( pPlayer ) && !g_hamczbots && cvar_botquota ) 
	{
		set_task( 0.1, "register_ham_czbots", pPlayer );
	}
}

public zp_user_humanized_post( pPlayer )
{
	g_pWeaponA[ pPlayer ] = false;
}

public client_disconnect( pPlayer )
{
	g_pWeaponA[ pPlayer ]  = false;
}

public Forward_PrecacheEventPost(type, const pName[ ] )
{
	if ( equal ("events/ump45.sc", pName ) )
	{
		g_iOriginEvent = get_orig_retval( );
		return FMRES_HANDLED;
	}
	return FMRES_IGNORED;
}

public Forward_SetModel( pEntity, pModel[])
{
	if( !is_valid_ent( pEntity ) ) 
	{
		return FMRES_IGNORED;
	}	
	
	static szClassName [ 33 ]
	entity_get_string( pEntity, EV_SZ_classname, szClassName, charsmax ( szClassName ) )
		
	if( !equal ( szClassName, "weaponbox" ) )
	{
		return FMRES_IGNORED;
	}	
	
	static pOwner , pModel
	
	pModel = find_ent_by_owner ( -1, WEAPON_BASE_NAME, pEntity );
	
	pOwner = entity_get_edict(pEntity, EV_ENT_owner)
	
	if ( g_pWeaponA [ pOwner ]  && is_valid_ent ( pModel ) )
	{
		entity_set_int( pModel, EV_INT_impulse, WEAP_KEY);
		
		entity_set_model( pEntity, W_MODEL);

		g_pWeaponA [ pOwner ]  = false;
		
		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

public Forward_UpdateClientData( pPlayer , SendWeapons, CD_Handle )
{
	if ( !HoldCBaseWeapon( pPlayer ) )
	{
		return HAM_IGNORED;
	}

	static Float:fGametime;
	fGametime = get_gametime();
	
	set_cd ( CD_Handle, CD_flNextAttack, fGametime + 0.001 );

	return FMRES_HANDLED;
}

public ClMsg_Death( i_msgId, i_msgDest, pId )
{	
	static szTruncatedWeapon[33], pevAttacker, pevVictim;
	
	pevAttacker = get_msg_arg_int( 1 );
	pevVictim = get_msg_arg_int( 2 );
	
	if ( pevAttacker == pevVictim || !is_user_connected( pevAttacker) )
	{
		return PLUGIN_CONTINUE;
	}
	
	get_msg_arg_string( 4, szTruncatedWeapon, charsmax( szTruncatedWeapon ) )
	
	if (equal(szTruncatedWeapon, "ump45" ) )
	{
		if ( HoldCBaseWeapon( pevAttacker ) )
		{
			set_msg_arg_string(4, "hegrenade" );
		}
	}

	return PLUGIN_CONTINUE;
}

public Forward_PlayBackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ( ( eventid != g_iOriginEvent) || !g_iPrimaryAttack )
	{
		return FMRES_IGNORED;
	}	
		
	if (!( 1 <= invoker <= g_iMaxPlayers ) )
	{
        return FMRES_IGNORED;
	}	
	
	if( flags & FEV_GLOBAL )
	{	
		flags &= ~FEV_GLOBAL;
	}

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public CbaseEntity__TraceAttack__Post(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if ( !is_user_connected( iAttacker ) || !HoldCBaseWeapon( iAttacker )  )
	{
		return HAM_HANDLED;
	}
	 
	new Float:vecEnd[3];
	
	get_tr2(ptr, TR_vecEndPos, vecEnd);
	
	new iDecal = GUNSHOT_DECALS[ random_num( 0 , sizeof( GUNSHOT_DECALS ) - 1 ) ]
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_GUNSHOTDECAL);
	write_coord_f( vecEnd[0]);
	write_coord_f(vecEnd[1]);
	write_coord_f(vecEnd[2]);
	write_short(iEnt);
	write_byte(iDecal);
	message_end();
	
	return HAM_IGNORED;
}

public CBaseWeapon__AddToPlayer__Pre( pEnity , pPlayer )
{
	if( !pev_valid( pEnity ) && !is_user_connected( pPlayer ) ) 
	{
		 return HAM_IGNORED;
	}
	
	if( pev( pEnity, pev_impulse ) == WEAP_KEY || g_pWeaponA[ pPlayer ] )
	{
		g_pWeaponA[ pPlayer ] = true;

		return HAM_HANDLED;
	}

	return HAM_IGNORED;
}

public CBaseWeapon__Deploy__Post( pEntity )
{
	if( !IsValidPrivateData( pEntity ) )
	{
                return HAM_HANDLED;
	}
	
	new pId 
	pId = get_pdata_cbase( pEntity , OFFSET_WEAPONOWNER , OFFSET_LINUX_WEAPONS );
	
	if (!g_pWeaponA[pId] )
	{
		return HAM_IGNORED;
	}	
	
	set_pev(pId, pev_viewmodel2, V_MODEL);
	
	set_pdata_float( pId, m_flNextAttack, 1.0, OFFSET_LINUX);
	
	UTIL_SenwWeaponAnim( pId, DRAW );

	
	set_pev(pId, pev_weaponmodel2, P_MODEL);
	
	return HAM_IGNORED;
}

public CBaseWeapon__PrimaryAttack__Pre(pEntity)
{
	if( !IsValidPrivateData( pEntity ) )
	{
		return HAM_IGNORED;
	}

	new 	pId;

	pId = get_pdata_cbase( pEntity , OFFSET_WEAPONOWNER , OFFSET_LINUX_WEAPONS );

	if ( !HoldCBaseWeapon( pId ) )
	{
		return HAM_IGNORED;
	}

	g_iClipAmmo[pId] = cs_get_weapon_ammo(pEntity);

	pev( pId , pev_punchangle , cl_pushangle[ pId ] );

	g_iPrimaryAttack = true;
	
	return HAM_IGNORED;
}

public CBaseWeapon_PrimaryAttack_Post( pEntity )
{
	if( !IsValidPrivateData( pEntity ) )
	{
		return HAM_IGNORED;
	}
	
	g_iPrimaryAttack = false;
	
	new pId = get_pdata_cbase( pEntity, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS );
	
	if ( !HoldCBaseWeapon( pId ) )
	{
		return HAM_IGNORED;
	}

	if (!g_iClipAmmo[pId])
	{
			return HAM_IGNORED;
	}	
	
	
		
	emit_sound( pId, CHAN_WEAPON, WEAPON_SOUND_FIRE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
	UTIL_SenwWeaponAnim( pId, random_num( SHOOT_1 , SHOOT_2 ) );
	
	LaserBeam(pId , 7 , 100 , 50 , 253 )
	
	#if defined SET__MUZZLE
	UTIL_MakeMuzzle( pId ) 
	#endif
	
	new Float:Push[ 3 ];
	
	pev( pId, pev_punchangle, Push );
	xs_vec_sub( Push , cl_pushangle[ pId ] , Push );
		
	xs_vec_mul_scalar( Push, get_pcvar_float( cvar_recoil ) , Push );
	xs_vec_add( Push, cl_pushangle[ pId ] , Push );
	set_pev( pId, pev_punchangle, Push );
		
	set_pdata_float( pEntity, m_flNextPrimaryAttack , get_pcvar_float( cvar_speed ) , OFFSET_LINUX_WEAPONS );
	
	return HAM_IGNORED;
}


public CBasePlayer__TakeDamage__Pre( pevVictim, pevInflictor, pevAttacker, Float:damage)
{
	if ( pevVictim == pevAttacker || !pevAttacker )
	{
		return HAM_HANDLED;
	}

	if ( !is_user_connected( pevAttacker ) || !HoldCBaseWeapon( pevAttacker )  )
	{
		return HAM_HANDLED;
	}
	
	SetHamParamFloat(4, damage * get_pcvar_float( cvar_damage )  )
	
	return HAM_IGNORED;
}

public CBaseWeapon__PostFrame__Pre( pEntity ) 
{
	if( !IsValidPrivateData( pEntity ) )
	{
                return HAM_HANDLED;
	}

	new pId;

	pId = get_pdata_cbase( pEntity , OFFSET_WEAPONOWNER , OFFSET_LINUX_WEAPONS );

	if ( !is_user_connected( pId ) && !HoldCBaseWeapon( pId ) && !g_iMaxPlayers )
	{
		return HAM_HANDLED;
	}
	
	new fInReload = get_pdata_int( pEntity, 54, OFFSET_LINUX_WEAPONS );
	new Float:flNextAttack = get_pdata_float( pId, m_flNextAttack, OFFSET_LINUX_WEAPONS );
	new iClip  = get_pdata_int( pEntity, m_iClip, OFFSET_LINUX_WEAPONS );
	new iAmmoType = 376 + get_pdata_int( pEntity, 49, OFFSET_LINUX_WEAPONS );
	new iBpAmmo  = get_pdata_int( pId, iAmmoType, OFFSET_LINUX );
	
	if ( fInReload && flNextAttack <= 1.4 )
	{
		new j = min( get_pcvar_num( cvar_clip )  - iClip, iBpAmmo);
	
		set_pdata_int( pEntity, m_iClip, iClip + j, OFFSET_LINUX_WEAPONS );
		set_pdata_int( pId, iAmmoType, iBpAmmo-j, OFFSET_LINUX );
		set_pdata_int( pEntity, 54, 0, OFFSET_LINUX_WEAPONS );

		fInReload = 0;
	}	 
	
	return HAM_IGNORED;
}

public CBaseWeapon__Reload_Pre(pEntity) 
{
	if( !IsValidPrivateData( pEntity ) )
	{
		return HAM_HANDLED;
	}

	new pId;

	pId = get_pdata_cbase( pEntity , OFFSET_WEAPONOWNER , OFFSET_LINUX_WEAPONS );

	if ( !is_user_connected( pId ) || !HoldCBaseWeapon( pId ) )
	{
		return HAM_IGNORED;
	}
	
	static iClipExtra;
	iClipExtra = get_pcvar_num( cvar_clip );
	
	g_TmpClip[pId] = -1;
	
	new iAmmoType = 376 + get_pdata_int( pEntity, 49, OFFSET_LINUX_WEAPONS );
	new iBpAmmo = get_pdata_int( pId, iAmmoType, OFFSET_LINUX );
	new iClip = get_pdata_int( pEntity, m_iClip, OFFSET_LINUX );
	
	if ( iBpAmmo <= 0 || iClip >= iClipExtra )
	{
	   return HAM_SUPERCEDE;
	}  
	
	g_TmpClip[pId] = iClip;
	
	return HAM_HANDLED;
}

public CBaseWeapon__Reload_Post( pEntity ) 
{
	if( !IsValidPrivateData( pEntity ) )
	{
                return HAM_HANDLED;
	}

	new pId = get_pdata_cbase( pEntity , OFFSET_WEAPONOWNER , OFFSET_LINUX_WEAPONS );
	
	if ( !HoldCBaseWeapon( pId ) )
	{
		return HAM_IGNORED;
	}

	if (g_TmpClip[ pId ] == -1)
	{
		return HAM_IGNORED;
	}

	
	set_pdata_float( pId, m_flNextAttack, RELOAD_TIME , OFFSET_LINUX);
	
	UTIL_SenwWeaponAnim(pId, RELOAD);

	return HAM_HANDLED;
}

stock UTIL__DropWeapons( pPlayer, bitsDropType )
{
	for( new pWeapon = CSW_P228; pWeapon <= CSW_P90; pWeapon++ )
	{
		if( ( bitsDropType & DROP_PRIMARY ) && ( ( 1 << pWeapon ) & WEAPONS_PRIMARY_BITSUM )
		|| ( bitsDropType & DROP_SECONDARY ) && ( ( 1 << pWeapon ) & WEAPONS_SECONDARY_BITSUM ) )
		{
			new strWeaponName[ 32 ];
			get_weaponname( pWeapon, strWeaponName, charsmax( strWeaponName ) );
			
			engclient_cmd( pPlayer, "drop", strWeaponName );
		}
	}
}

stock UTIL_SenwWeaponAnim(const pPlayer, const Sequence)
{
	set_pev(pPlayer, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = pPlayer)
	write_byte(Sequence)
	write_byte(pev(pPlayer, pev_body))
	message_end()
}

stock UTIL_MakeMuzzle( pId   ) 
{
	new pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite")) 
	
	new Float:vecOrigin[ 3 ]
	pev( pId, pev_origin, vecOrigin )

	entity_set_origin( pEntity, vecOrigin )
	
	entity_set_model( pEntity, g_iMuzzleFlash )

	entity_set_int( pEntity, EV_INT_solid, SOLID_NOT )
	entity_set_int( pEntity, EV_INT_movetype, MOVETYPE_NOCLIP )
	
	entity_set_string( pEntity, EV_SZ_classname, "muzzle_et" )

	
	entity_set_float( pEntity, EV_FL_animtime, get_gametime() )
	entity_set_float( pEntity, EV_FL_framerate, 50.0 )       
	set_pev( pEntity, pev_scale, get_pcvar_float( cvar_scale_muzzle )  )

	set_pev( pEntity, pev_spawnflags, SF_SPRITE_ONCE)

	set_pev(pEntity, pev_rendermode,  kRenderTransAdd)
	
	set_pev(pEntity, pev_renderamt,   255.0)

	set_pev(pEntity, pev_skin, pId )
	set_pev(pEntity, pev_body, 1)
	set_pev(pEntity, pev_aiment, pId)

	entity_set_float(pEntity, EV_FL_nextthink, get_gametime() + 5.0 );
	
	DispatchSpawn( pEntity );
	
	set_task( 1.0 , "rem_ent" , pEntity ) 
}		

public rem_ent( iEnt ) 
{
	remove_entity( iEnt ) 
}	

stock LaserBeam(id , Size , Red , Grenn , Blue ) 
{
    static End[3]
    get_user_origin(id, End, 3)	
	
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte (TE_BEAMENTPOINT)
    write_short( id |0x1000 )
    write_coord(End[0])
    write_coord(End[1])
    write_coord(End[2])
    write_short(g_Kah)
    write_byte(0)
    write_byte(1)
    write_byte(1)
    write_byte(Size)
    write_byte(4)
    write_byte(Red)
    write_byte(Grenn)
    write_byte(Blue)
    write_byte(255)
    write_byte(0)
    message_end()
}	

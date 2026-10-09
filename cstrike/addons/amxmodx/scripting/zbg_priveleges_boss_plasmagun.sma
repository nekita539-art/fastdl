#include < amxmodx >
#include < fakemeta >
#include < cstrike >
#include < hamsandwich >
#include < zombieplague >

new const PLUGIN_VERSION[ ]    =  "1.0.0 FINAL";

const OFFSET_WEAPONOWNER    =      41
const OFFSET_LINUX    =    5
const OFFSET_LINUX_WEAPONS     =      4

const WEAP_KEY   =    545464464
const MAX_PLAYERS   =        32

const m_flNextPrimaryAttack = 46;
const m_iClip =    51;
const m_flNextAttack = 83;
const m_flTimeWeaponIdle    = 48; 
const m_szAnimExtention     = 492

enum ( <<=1 )
{
    DROP_PRIMARY = 1,
    DROP_SECONDARY
};    

const IDLE = 0 
const RELOAD = 1
const DRAW = 2
const SHOOT_1 = 3
const SHOOT_END = 4 

#define HoldCBaseWeapon(%0)    ( get_user_weapon( %0 ) == g_iWeaponID  && g_pWeaponA[ %0 ] )
#define IsValidPrivateData(%0)    ( pev_valid( %0 ) == 2 )

#define PRECACHE_MODEL(%0)        engfunc(EngFunc_PrecacheModel, %0)
#define PRECACHE_SOUND(%0)        engfunc(EngFunc_PrecacheSound, %0)
#define PRECACHE_GENERIC(%0)        engfunc(EngFunc_PrecacheGeneric, %0)

new const WEAPON_SOUND_FIRE[ ] = "zbg/plasmagun-1.wav";
new const WEAPON_SOUND_BOMB[ ] = "zbg/plasmagun_exp.wav";

new const WEAPON_LIST[ ]   =   "zbg_priveleges_adm_plasmagun";
new const WEAPON_BASE_NAME[ ]   =  "weapon_m249";

const Float: RELOAD_TIME  =   3.36 //Время перезарядки

const AMMO__WEAPON       =  200 //Кол-во обоймы
const CLIP__WEAPON      =  45 //Кол-во патрон 
const BALL__SPEED         =  2000 //Скорость  

const Float: BALL__DAMAGE       =   4.5 //Урон
const Float: BALL__RADIUS      =  195.0 //Радиус 
const Float: WEAPON__SPEED          = 0.15 //Скорость орудия 

//new const EXTRA_ITEM_NAME[ ]    =   "Plasmagun Thanatos"; //Название в Extra-Items 

new V_MODEL[ ] = "models/zbg/v_plasmathanatos.mdl";
new P_MODEL[ ] = "models/zbg/p_plasma_gun.mdl";
new W_MODEL[ ] = "models/zbg/w_plasma_gun.mdl";

new R_MODEL[ ] = "sprites/zbg/fire.spr";

new const HUD_SPRITES[ ] [ ] = 
{
    "sprites/640hud3.spr" , 
    "sprites/Vaas/thanatos11_fire.spr"
};

new g_iForwardIndex , g_iExpSprite  ; 
new g_pWeaponA[ MAX_PLAYERS + 1 ] ;
new g_iWeaponID = 0;

new const BALL__CLASSNAME[ ]  =   "zsClassBall";    

const WEAPONS_PRIMARY_BITSUM     = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90);
const WEAPONS_SECONDARY_BITSUM     = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE);

public plugin_precache( )
{
    PRECACHE_MODEL( V_MODEL );
    PRECACHE_MODEL( P_MODEL );
    PRECACHE_MODEL( W_MODEL );
    PRECACHE_MODEL( R_MODEL );
    PRECACHE_SOUNDS_FROM_MODEL( V_MODEL );
    
    PRECACHE_SOUND( WEAPON_SOUND_BOMB );
    PRECACHE_SOUND( WEAPON_SOUND_FIRE );
    
    static iFile
    for( iFile = 0 ; iFile < sizeof HUD_SPRITES; iFile++ ) 
    {
        PRECACHE_GENERIC( HUD_SPRITES[ iFile ] )
    }    
    
    static szFile [ 128 ];
    formatex ( szFile , charsmax( szFile ) , "sprites/%s.txt" , WEAPON_LIST );
    PRECACHE_GENERIC( szFile );
    
    g_iExpSprite = precache_model( "sprites/zbg/fire.spr" );
}

public plugin_init()
{
    register_plugin( "[CSO] Extra Item PlasmaGun" , PLUGIN_VERSION , "Shurik07|Kulogram" );
    register_clcmd( WEAPON_LIST, "weapon_hook_an" );
    
    register_forward( FM_SetModel, "Forward_SetModel" , false );
    register_forward( FM_UpdateClientData, "Forward_UpdateClientData" , true );
    
    RegisterHam( Ham_Item_AddToPlayer, WEAPON_BASE_NAME, "CBaseWeapon__AddToPlayer__Post" , .Post = true );
    RegisterHam( Ham_Item_Deploy, WEAPON_BASE_NAME , "CBaseWeapon__Deploy__Post", .Post = true );
    RegisterHam( Ham_Weapon_PrimaryAttack, WEAPON_BASE_NAME, "CBaseWeapon__PrimaryAttack__Pre" , .Post = false );
    RegisterHam( Ham_Item_PostFrame, WEAPON_BASE_NAME, "CBaseWeapon__PostFrame__Pre" , .Post = false );
    RegisterHam( Ham_Weapon_Reload, WEAPON_BASE_NAME, "CBaseWeapon__Reload_Pre" , .Post = false );
    RegisterHam( Ham_Weapon_WeaponIdle,    WEAPON_BASE_NAME,     "CBaseWeapon__Idle_Pre",    false );
    RegisterHam( Ham_TraceAttack,    "player",         "CBase__TraceAttack_Pre", false );
    
    register_forward( FM_Touch , "Forward_Touch" );

    g_iWeaponID = get_weaponid( WEAPON_BASE_NAME );
}
public plugin_natives () {
    register_native("priveleges_adm_plasmagun", "give_plasmagun", 1)
}

public give_plasmagun( pPlayer )
{
    UTIL__DropWeapons( pPlayer, DROP_PRIMARY )

    g_pWeaponA[ pPlayer ]  = true;

    static pEntity;
    pEntity = fm_give_item( pPlayer , WEAPON_BASE_NAME ); 

    if( pEntity > 0 ) cs_set_weapon_ammo( pEntity, CLIP__WEAPON );    

    cs_set_user_bpammo( pPlayer , g_iWeaponID , AMMO__WEAPON );

    UTIL__WeaponList( pPlayer,  WEAPON_LIST , 3 , AMMO__WEAPON , -1 , -1 , 0 , 4  , g_iWeaponID , 0 );    
}

public weapon_hook_an( pPlayer  ) 
{
    engclient_cmd( pPlayer, WEAPON_BASE_NAME);
    return PLUGIN_HANDLED;
}

public zp_user_humanized_post( pPlayer )
{
    g_pWeaponA[ pPlayer ] = false;
}

public client_disconnect( pPlayer )
{
    g_pWeaponA[ pPlayer ]  = false;
}

public Forward_SetModel( pEntity, const pModel[ ] )
{
    if( !pev_valid( pEntity ) ) 
    {
        return FMRES_IGNORED;
    }    
    
    static szClassName [ 33 ]
    pev( pEntity, pev_classname, szClassName, charsmax(szClassName) );
        
    if( !equal ( szClassName, "weaponbox" ) )
    {
        return FMRES_IGNORED;
    }    
    
    static pOwner , pModel
    pModel = fm_find_ent_by_owner ( -1, WEAPON_BASE_NAME, pEntity );
    pOwner = pev ( pEntity, pev_owner );
    
    if ( g_pWeaponA [ pOwner ]  && pev_valid ( pModel ) )
    {
        set_pev( pModel , pev_impulse , WEAP_KEY );
        engfunc( EngFunc_SetModel, pEntity, W_MODEL );
        
        g_pWeaponA [ pOwner ]   = false;
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
    fGametime = get_gametime( );
    
    set_cd ( CD_Handle, CD_flNextAttack, fGametime + 0.001 );

    return FMRES_HANDLED;
}

public Forward_PlayBackEvent(flags, invoker, eventindex, Float:delay, Float:origin[3], Float:fvangles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
    return FMRES_SUPERCEDE
} 

public CBaseWeapon__AddToPlayer__Post( pEntity , pPlayer )
{
    if( !pev_valid( pEntity ) && !is_user_connected( pPlayer ) ) 
    {
         return HAM_IGNORED;
    }
    
    if( pev( pEntity, pev_impulse) == WEAP_KEY )
    {
        g_pWeaponA[ pPlayer ]  = true;
        
        UTIL__WeaponList( pPlayer,  WEAPON_LIST , 3 , AMMO__WEAPON , -1 , -1 , 0 , 4  , g_iWeaponID , 0 );

        return HAM_IGNORED  ;
    }
    else
    {
        UTIL__WeaponList( pPlayer,  WEAPON_BASE_NAME , 3 , AMMO__WEAPON , -1 , -1 , 0 , 4  , g_iWeaponID , 0 )
    }    

    return HAM_IGNORED;
}

public CBaseWeapon__Deploy__Post( pEntity )
{
    if( !IsValidPrivateData( pEntity ) )
    {
                return HAM_IGNORED;
    }
    
    static pId 
    pId = get_pdata_cbase( pEntity , OFFSET_WEAPONOWNER , OFFSET_LINUX_WEAPONS );
    
    if ( !g_pWeaponA[ pId ] )
    {
        return HAM_IGNORED;
    }    
    
    set_pev( pId, pev_viewmodel2, V_MODEL);
    set_pev( pId, pev_weaponmodel2, P_MODEL);
    
    set_pdata_float( pId, m_flNextAttack, 1.0, OFFSET_LINUX );
    set_pdata_float( pEntity, m_flTimeWeaponIdle, 1.0 , OFFSET_LINUX_WEAPONS );
    set_pdata_string( pId, m_szAnimExtention * 4, "rifle" , -1, OFFSET_LINUX * 4);
    
    UTIL_SenwWeaponAnim( pId, DRAW );
    
    return HAM_IGNORED ;
}

public CBaseWeapon__PrimaryAttack__Pre(pEntity)
{
    if( !IsValidPrivateData( pEntity ) )
    {
        return HAM_IGNORED;
    }

    static     pId  ; pId = get_pdata_cbase( pEntity , OFFSET_WEAPONOWNER , OFFSET_LINUX_WEAPONS );
    static iClip ; iClip = get_pdata_int( pEntity, m_iClip, OFFSET_LINUX_WEAPONS );
    
    static Float: vecPuncheAngle[ 3 ];

    if ( !HoldCBaseWeapon( pId ) || iClip <= 0 )
    {
        return HAM_IGNORED;
    }
    
    g_iForwardIndex = register_forward( FM_PlaybackEvent, "Forward_PlayBackEvent" , false )
    
    pev(pId, pev_punchangle, vecPuncheAngle);
    ExecuteHam(Ham_Weapon_PrimaryAttack, pEntity);
    set_pev(pId, pev_punchangle, Float:{ -5.0, 0.0, 0.0 });
    
    Ball__Create( pId )
    
    emit_sound( pId, CHAN_WEAPON, WEAPON_SOUND_FIRE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
    UTIL_SenwWeaponAnim( pId, SHOOT_1 );
    
    set_pdata_float( pEntity, m_flNextPrimaryAttack , WEAPON__SPEED , OFFSET_LINUX_WEAPONS );
    set_pdata_float( pEntity, m_flTimeWeaponIdle, WEAPON__SPEED + 3.0  , OFFSET_LINUX_WEAPONS );
    
    unregister_forward(FM_PlaybackEvent, g_iForwardIndex , false);
    
    return HAM_SUPERCEDE;
}

Ball__Create (  const pId )
{
    static pEntity;

    if ( ( pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite") ) ) )
    {
        static Float:vf_vOrigin[ 3 ] , Float: vf_vAngle[ 3 ]; 
        engfunc( EngFunc_GetAttachment , pId , 1 , vf_vOrigin , vf_vAngle )
        
        set_pev ( pEntity, pev_classname , BALL__CLASSNAME );
        set_pev ( pEntity, pev_movetype, MOVETYPE_FLY );
        set_pev ( pEntity, pev_solid, SOLID_SLIDEBOX   );
        
        engfunc ( EngFunc_SetModel , pEntity, R_MODEL );
        engfunc ( EngFunc_SetOrigin, pEntity, vf_vOrigin );
        engfunc ( EngFunc_SetSize  , pEntity, Float:{ 0.0, 0.0, 0.0 }, Float:{ 0.0, 0.0, 0.0 } );
        
        set_pev ( pEntity, pev_renderfx, kRenderFxGlowShell );
        set_pev ( pEntity, pev_rendermode, kRenderTransAdd );
        set_pev ( pEntity, pev_renderamt,   255.0 )
        set_pev ( pEntity, pev_scale , random_float( random_float( 0.1 , 0.2 ) , random_float( 0.3 , 0.4 ) ) );
        set_pev ( pEntity, pev_iuser1 , pId );
        
        static Float:vf_vVelocity[ 3 ];
        velocity_by_aim( pId, BALL__SPEED, vf_vVelocity );
        set_pev( pEntity, pev_velocity, vf_vVelocity );

        static Float:vf_vAngles[ 3 ];
        engfunc( EngFunc_VecToAngles, vf_vVelocity, vf_vAngles );
        set_pev( pEntity, pev_angles, vf_vAngles );
    }
}

public CBaseWeapon__PostFrame__Pre( pEntity ) 
{
    if( !IsValidPrivateData( pEntity ) )
    {
                return HAM_IGNORED;
    }

    static pId;
    pId = get_pdata_cbase( pEntity , OFFSET_WEAPONOWNER , OFFSET_LINUX_WEAPONS );

    if ( !is_user_connected( pId ) && !HoldCBaseWeapon( pId ) )
    {
        return HAM_IGNORED;
    }
    
    static fInReload ; fInReload = get_pdata_int( pEntity, 54, OFFSET_LINUX_WEAPONS );
    static Float:flNextAttack ; flNextAttack = get_pdata_float( pId, m_flNextAttack, OFFSET_LINUX_WEAPONS );
    static iClip ; iClip = get_pdata_int( pEntity, m_iClip, OFFSET_LINUX_WEAPONS );
    static iAmmoType ; iAmmoType = 376 + get_pdata_int( pEntity, 49, OFFSET_LINUX_WEAPONS );
    static iBpAmmo ; iBpAmmo  = get_pdata_int( pId, iAmmoType, OFFSET_LINUX );
    
    if ( fInReload && flNextAttack <= RELOAD_TIME )
    {
        static  j ; j = min( CLIP__WEAPON  - iClip, iBpAmmo);
    
        set_pdata_int( pEntity, m_iClip, iClip + j, OFFSET_LINUX_WEAPONS );
        set_pdata_int( pId, iAmmoType, iBpAmmo-j, OFFSET_LINUX );
        set_pdata_int( pEntity, 54, 0, OFFSET_LINUX_WEAPONS );
    }     
    
    return HAM_IGNORED;
}

public CBaseWeapon__Reload_Pre(pEntity) 
{
    if( !IsValidPrivateData( pEntity ) )
    {
        return HAM_IGNORED;
    }

    static pId;
    pId = get_pdata_cbase( pEntity , OFFSET_WEAPONOWNER , OFFSET_LINUX_WEAPONS );
    
    static iAmmoType ; iAmmoType = 376 + get_pdata_int( pEntity, 49, OFFSET_LINUX_WEAPONS );
    static iBpAmmo ; iBpAmmo = get_pdata_int( pId, iAmmoType, OFFSET_LINUX );
    static iClip ; iClip = get_pdata_int( pEntity, m_iClip, OFFSET_LINUX );
    
    if ( iBpAmmo <= 0 || iClip >= CLIP__WEAPON )
    {
        return HAM_SUPERCEDE;
    } 
    
    set_pdata_int( pEntity, m_iClip, 0, OFFSET_LINUX_WEAPONS );
    ExecuteHam( Ham_Weapon_Reload, pEntity    );
    set_pdata_int( pEntity, m_iClip, iClip, OFFSET_LINUX_WEAPONS );

    if ( !is_user_connected( pId ) || !HoldCBaseWeapon( pId ) )
    {
        return HAM_IGNORED;
    }
    
    set_pdata_float( pId, m_flNextAttack, RELOAD_TIME , OFFSET_LINUX);
    set_pdata_float( pEntity, m_flTimeWeaponIdle, RELOAD_TIME , OFFSET_LINUX_WEAPONS );
    
    UTIL_SenwWeaponAnim(pId, RELOAD);
    
    return HAM_SUPERCEDE;
}

public CBaseWeapon__Idle_Pre( pEntity )
{
    if( !IsValidPrivateData( pEntity ) )
    {
                return HAM_IGNORED;
    }

    static pId;
    pId = get_pdata_cbase( pEntity , OFFSET_WEAPONOWNER , OFFSET_LINUX_WEAPONS );
    
    ExecuteHamB( Ham_Weapon_ResetEmptySound, pEntity );
    
    if (get_pdata_int(pEntity, m_flTimeWeaponIdle, OFFSET_LINUX_WEAPONS) > 0.0)
    {
        return HAM_IGNORED;
    }

    if ( !HoldCBaseWeapon( pId ) )
    {
        return HAM_IGNORED;
    }

    UTIL_SenwWeaponAnim ( pId, IDLE );
    set_pdata_float( pEntity, m_flTimeWeaponIdle, random_float( 5.0 , 15.0 ) , OFFSET_LINUX_WEAPONS );

    return HAM_SUPERCEDE;
}

public CBase__TraceAttack_Pre(const iEntity, const iAttacker, const Float: flDamage)
{
    if ( is_user_connected( iAttacker ) && HoldCBaseWeapon( iAttacker )  )
    {
        return HAM_SUPERCEDE;
    }
    
    return HAM_IGNORED;
}


public Forward_Touch( const pEntity , const i_Other )
{
    if( !pev_valid( pEntity ) ) 
    {
        return FMRES_IGNORED ;
    }
    
    static  g_classname[ 32 ]  ; 
    pev( pEntity, pev_classname, g_classname, 31 )
    
    if( equali( g_classname, BALL__CLASSNAME ) )
    {
        static Float:flOrigin[ 3 ];
        pev( pEntity, pev_origin, flOrigin );
        
        engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0 );
        write_byte( TE_EXPLOSION );
        engfunc( EngFunc_WriteCoord, flOrigin[ 0 ] );
        engfunc( EngFunc_WriteCoord, flOrigin[ 1 ] );
        engfunc( EngFunc_WriteCoord, flOrigin[ 2 ] );
        write_short( g_iExpSprite );
        write_byte( 4 );
        write_byte( 15 );
        write_byte( 10 );
        message_end( );
        
        emit_sound( pEntity, CHAN_WEAPON, WEAPON_SOUND_BOMB , VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

        static pOwner , pevVictim ;  
        pOwner = pev( pEntity, pev_iuser1 ); pevVictim  = -1;
        
        while( ( pevVictim = engfunc( EngFunc_FindEntityInSphere, pevVictim, flOrigin, BALL__RADIUS) ) != 0 )
        {
            if( !is_user_alive( pevVictim ) )
                    continue;
                    
            if( !zp_get_user_zombie( pevVictim ) )
                continue;
                
            ExecuteHamB( Ham_TakeDamage, pevVictim, pEntity, pOwner, BALL__DAMAGE, DMG_SONIC );
        }
        engfunc( EngFunc_RemoveEntity , pEntity );
    }
    return FMRES_IGNORED ;
}

stock UTIL__DropWeapons(id, bitsDropType)
{
    static weapons[32], num, i, weaponid
    num = 0 
    get_user_weapons(id, weapons, num)
    
    for (i = 0; i < num; i++)
    {
        weaponid = weapons[i]
        
        if ((bitsDropType == DROP_PRIMARY && ((1<<weaponid) & WEAPONS_PRIMARY_BITSUM)) || (bitsDropType == DROP_SECONDARY && ((1<<weaponid) & WEAPONS_SECONDARY_BITSUM)))
        {
            static wname[32]
            get_weaponname(weaponid, wname, charsmax(wname))
            
            engclient_cmd(id, "drop", wname)
        }
    }
}

stock fm_find_ent_by_owner(entity, const classname[], owner)
{
    while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner) { /* keep looping */ }
    return entity;
}

stock UTIL_SenwWeaponAnim(const pPlayer, const Sequence)
{
    set_pev(pPlayer, pev_weaponanim, Sequence)
    
    message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = pPlayer)
    write_byte(Sequence)
    write_byte(pev(pPlayer, pev_body))
    message_end()
}

UTIL__WeaponList( pPlayer, const szWeapon[ ], int, int2, int3, int4, int5, int6, int7, int8 )
{
    message_begin( MSG_ONE, get_user_msgid( "WeaponList" ) , _, pPlayer );
    write_string( szWeapon );
    write_byte( int );
    write_byte( int2);
    write_byte( int3 );
    write_byte( int4 );
    write_byte( int5 );
    write_byte( int6 );
    write_byte( int7 );
    write_byte( int8 );
    message_end( );
}

stock fm_give_item(id, const item[])
{
    static ent
    ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item))
    if (!pev_valid(ent)) return 0;
    
    static Float:originF[3]
    pev(id, pev_origin, originF)
    set_pev(ent, pev_origin, originF)
    set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
    dllfunc(DLLFunc_Spawn, ent)
    
    static save
    save = pev(ent, pev_solid)
    dllfunc(DLLFunc_Touch, ent, id)
    if (pev(ent, pev_solid) != save)
        return ent ;
    
    engfunc(EngFunc_RemoveEntity, ent)
    
    return -1;
}

PRECACHE_SOUNDS_FROM_MODEL(const szModelPath[])
{
    new iFile;
    
    if ((iFile = fopen(szModelPath, "rt")))
    {
        new szSoundPath[64];
        
        new iNumSeq, iSeqIndex;
        new iEvent, iNumEvents, iEventIndex;
        
        fseek(iFile, 164, SEEK_SET);
        fread(iFile, iNumSeq, BLOCK_INT);
        fread(iFile, iSeqIndex, BLOCK_INT);
        
        for (new k, i = 0; i < iNumSeq; i++)
        {
            fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
            fread(iFile, iNumEvents, BLOCK_INT);
            fread(iFile, iEventIndex, BLOCK_INT);
            fseek(iFile, iEventIndex + 176 * i, SEEK_SET);

            for (k = 0; k < iNumEvents; k++)
            {
                fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
                fread(iFile, iEvent, BLOCK_INT);
                fseek(iFile, 4, SEEK_CUR);
                
                if (iEvent != 5004)
                {
                    continue;
                }

                fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);
                
                if (strlen(szSoundPath))
                {
                    strtolower(szSoundPath);
                    PRECACHE_SOUND(szSoundPath);
                }
            }
        }
    }
    
    fclose(iFile);                               
}

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <engine>

#define pDataKey_CustomAmmo 3

//Linux extra offsets
#define pData_Player                5
#define pData_Item                4

// CWeaponBox
#define pDataKey_WeaponBoxItems            34

//CBasePlayerItem
#define pDataKey_iOwner                41
#define pDataKey_iNext                42
#define pDataKey_iId                43

//CBasePlayerWeapon
#define pDataKey_flNextPrimaryAttack        46
#define pDataKey_flNextSecondaryAttack        47
#define pDataKey_flNextTimeWeaponIdle        48
#define pDataKey_iPrimaryAmmoType        49
#define pDataKey_iClip                51
#define pDataKey_iInReload            54
#define pDataKey_iSpecialReload            55
#define pDataKey_iState                74

//CBaseMonster
#define pDataKey_iLastHitGroup            75
#define pDataKey_flNextAttack            83

//CBasePlayer
#define m_flPainShock                           108
#define pDataKey_iPlayerItems            367
#define pDataKey_iActiveItem            373    
#define pDataKey_ibpAmmo            376
#define pDataKey_iPlayerWeaponAnim        492

#define PLUGIN "AirBurster"
#define VERSION "1.0"
#define AUTHOR "Chrescoe1"

#define WEAPON_KEY                82813
#define Is_CustomItem(%0)            (pev(%0,pev_impulse)==WEAPON_KEY)

//Weapon Settings
#define weapon_name    "weapon_m249"
#define weapon_new    "weapon_airburster"

#define model_v        "models/zbg/priveleges/v_airburster.mdl"
#define model_p        "models/zbg/priveleges/p_airburster.mdl"
#define model_w        "models/zbg/priveleges/w_airburster.mdl"
#define body_w        0

#define weapon_punchangle    0.0
#define weapon_aspeed        0.097

#define weapon_ammo        50
#define weapon_bpammo        100

#define sound_shot "zbg/priveleges/airburster_shoot.wav"

new const sounds_dump[][]={
    "zbg/priveleges/airburster_shoot.wav"
};
/*new const precache_dump[][]={
    "sprites/dm_balrog7.txt",
    "sprites/dm/640hud2.spr",
    "sprites/dm/640hud76.spr"
};*/

new AllocString_V,AllocString_P;

//DM Register Item
new dm_item,g_steam;

#define DMG_ENTS    4
new const damage_entites[DMG_ENTS][]={"player","info_target","hostage_entity","func_breakable"}
new HamHook:tr_fwds[DMG_ENTS];
trace_register()for(new i=0;i<DMG_ENTS;i++)tr_fwds[i]=RegisterHam(Ham_TraceAttack,damage_entites[i],"HookHam_TakeTrace",0),DisableHamForward(tr_fwds[i])
stock trblock_enable(){for(new i=0;i<DMG_ENTS;i++)EnableHamForward(tr_fwds[i]);}
stock trblock_disable(){for(new i=0;i<DMG_ENTS;i++)DisableHamForward(tr_fwds[i]);}
public HookHam_TakeTrace(victim,inflictor,attacker, Float:damage){SetHamParamFloat(3,0.0);return HAM_SUPERCEDE;}

#define model_fire    "sprites/ef_aircyclone.spr"
#define classname_fire    "airthrower"

new frames;
//AMXX
public plugin_precache(){
    engfunc(EngFunc_PrecacheModel,model_v);
    engfunc(EngFunc_PrecacheModel,model_p);
    engfunc(EngFunc_PrecacheModel,model_w);
    new a=engfunc(EngFunc_PrecacheModel,model_fire);
    frames= engfunc(EngFunc_ModelFrames,a);
    g_steam=engfunc(EngFunc_PrecacheModel,"sprites/ef_aircyclone.spr");
    AllocString_V = engfunc(EngFunc_AllocString, model_v);
    AllocString_P = engfunc(EngFunc_AllocString, model_p);
    new i;
    for(i=0;i<sizeof(sounds_dump);i++)engfunc(EngFunc_PrecacheSound,sounds_dump[i]);
    //for(i=0;i<sizeof(precache_dump);i++)engfunc(EngFunc_PrecacheGeneric,precache_dump[i]);
}
public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
    
    RegisterHam(Ham_Item_Deploy,weapon_name,"HookHam_Weapon_Deploy",1);
    RegisterHam(Ham_Item_AddToPlayer,weapon_name,"HookHam_Weapon_Add",1);
    RegisterHam(Ham_Item_PostFrame,weapon_name,"HookHam_Weapon_Frame",0);
    
    RegisterHam(Ham_Weapon_Reload,weapon_name,"HookHam_Weapon_Reload",0);
    RegisterHam(Ham_Weapon_WeaponIdle,weapon_name,"HookHam_Weapon_Idle",0);
    RegisterHam(Ham_Weapon_PrimaryAttack,weapon_name,"HookHam_Weapon_PrimaryAttack",0);
    
    RegisterHam(Ham_Spawn,"weaponbox","HookHam_WeaponBox_Spawn",1);
    register_forward(FM_SetModel,"HookFm_SetModel",0);
    register_forward(FM_UpdateClientData,"HookFm_UpdateClientData",1);
    
    register_think(classname_fire, "Flame_Think");
    register_touch(classname_fire,"*","Flame_Touch");
    
    register_clcmd(weapon_new,"hook_item");
    trace_register();
    // Add your code here...
}
public plugin_natives ()
{
    register_native("priveleges_adm_buster", "native_give_weapon_add", 1)
}

public native_give_weapon_add(id)
    airbooster_items(id)

//Cl Cmds
public hook_item(id){
    engclient_cmd(id,weapon_name);
    return PLUGIN_HANDLED;
}
public airbooster_items(id)
{
        UTIL_DropWeapon(id,1);
        new weapon=make_weapon();if(weapon<=0) return;
        if(!ExecuteHamB(Ham_AddPlayerItem, id, weapon)) {engfunc(EngFunc_RemoveEntity, weapon);return;}
        ExecuteHam(Ham_Item_AttachToPlayer,weapon, id);
        new ammotype = pDataKey_ibpAmmo +pDataKey_CustomAmmo;
        new ammo=get_pdata_int(id, ammotype,pData_Player);
        if(ammo< weapon_bpammo)set_pdata_int(id, ammotype, weapon_bpammo,pData_Player);
        set_pdata_int(weapon,pDataKey_iClip,weapon_ammo,pData_Item);
        emit_sound(id, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
        engclient_cmd(id,weapon_name);
}

//Ham hooks
public HookHam_Weapon_Deploy(ent){
    if(!Is_CustomItem(ent))return HAM_IGNORED;
    new id=get_pdata_cbase(ent,pDataKey_iOwner,pData_Item);
    set_pev_string(id, pev_viewmodel2, AllocString_V);
    set_pev_string(id, pev_weaponmodel2, AllocString_P);
    set_pdata_float(ent,pDataKey_flNextPrimaryAttack,1.2,pData_Item);
    set_pdata_float(ent,pDataKey_flNextSecondaryAttack,1.2,pData_Item);
    set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,1.2,pData_Item);
    Play_WeaponAnim(id,4);
    return HAM_IGNORED;
}
public HookHam_Weapon_Add(ent,id){
    new imp=pev(ent, pev_impulse);
    if(imp==WEAPON_KEY)Weaponlist(id,true),set_pdata_int(id, pDataKey_ibpAmmo +pDataKey_CustomAmmo,pev(ent,pev_iuser1),pData_Player);
    else if(imp==0)Weaponlist(id,false);
    return HAM_IGNORED;
}
public HookHam_Weapon_Frame(ent){
    if(!Is_CustomItem(ent)) return HAM_IGNORED;
    if(get_pdata_int(ent, pDataKey_iInReload,pData_Item)){
        new id = get_pdata_cbase(ent, pDataKey_iOwner,pData_Item);
        new clip,ammotype,ammo,j;
        clip = get_pdata_int(ent, pDataKey_iClip,pData_Item);
        ammotype = pDataKey_ibpAmmo +pDataKey_CustomAmmo;
        ammo = get_pdata_int(id, ammotype,pData_Player);
        j = min(weapon_ammo - clip, ammo);
        set_pdata_int(ent, pDataKey_iClip, clip+j,pData_Item);
        set_pdata_int(id, ammotype, ammo-j,pData_Player);
        set_pdata_int(ent, pDataKey_iInReload,0,pData_Item);
    }/*else if(get_pdata_int(ent,pDataKey_iClip)<=0){
        new id = get_pdata_cbase(ent, pDataKey_iOwner,pData_Item);
        if(get_pdata_int(id,pDataKey_ibpAmmo+pDataKey_CustomAmmo)>0&&!(pev(id,pev_button)&IN_ATTACK))
            ExecuteHamB(Ham_Weapon_Reload,ent);
    }*/else if(get_pdata_int(ent,pDataKey_iState,pData_Item)>0){
        new id=get_pdata_cbase(ent, pDataKey_iOwner,pData_Item)
        if(!(pev( id,pev_button)&IN_ATTACK)|| get_pdata_int(ent, pDataKey_iClip,pData_Item)<=0){
            set_pdata_int(ent,pDataKey_iState,0,pData_Item);
            Play_WeaponAnim(id,2);
            set_pdata_float(ent,pDataKey_flNextPrimaryAttack,0.8,pData_Item);
            set_pdata_float(ent,pDataKey_flNextSecondaryAttack,0.8,pData_Item);
            set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,2.0,pData_Item);
        }
    }
    return HAM_IGNORED;
}
public HookHam_Weapon_Reload(ent){
    if(!Is_CustomItem(ent)) return HAM_IGNORED;
    new clip = get_pdata_int(ent, pDataKey_iClip, pData_Item);
    if(clip >= weapon_ammo) return HAM_SUPERCEDE;
    
    new id = get_pdata_cbase(ent, pDataKey_iOwner, pData_Item);
    if(get_pdata_int(id,pDataKey_ibpAmmo+pDataKey_CustomAmmo,pData_Player)<=0)return HAM_SUPERCEDE;
    
    set_pdata_int(ent, pDataKey_iClip, 0, pData_Item);
    ExecuteHam(Ham_Weapon_Reload, ent);
    set_pdata_int(ent, pDataKey_iClip, clip, pData_Item);
    set_pdata_int(ent, pDataKey_iInReload, 1, pData_Item);
    new Float:time_reload=4.65;
    set_pdata_float(ent,pDataKey_flNextPrimaryAttack,time_reload,pData_Item);
    set_pdata_float(ent,pDataKey_flNextSecondaryAttack,time_reload,pData_Item);
    set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,time_reload,pData_Item);
    set_pdata_float(id,pDataKey_flNextAttack,time_reload,pData_Player) ;
    Play_WeaponAnim(id,3);
    return HAM_SUPERCEDE;
}
public HookHam_Weapon_Idle(ent){
    if(!Is_CustomItem(ent))return HAM_IGNORED;
    if(get_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,pData_Item)>0.0)return HAM_IGNORED;
    set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,1.7,pData_Item);
    Play_WeaponAnim(get_pdata_cbase(ent,pDataKey_iOwner,pData_Item),0);
    return HAM_SUPERCEDE;
}
public HookHam_Weapon_PrimaryAttack(ent){
    if(!Is_CustomItem(ent))return HAM_IGNORED;
    new ammo=get_pdata_int(ent,pDataKey_iClip,pData_Item);
    if(ammo<=0){
        ExecuteHam(Ham_Weapon_PlayEmptySound, ent);
        set_pdata_float(ent,pDataKey_flNextPrimaryAttack,weapon_aspeed,pData_Item);
        return HAM_SUPERCEDE;
    }
    
    new id=get_pdata_cbase(ent,pDataKey_iOwner,pData_Item)
    new Float:user_punchangle[3];pev(id,pev_punchangle,user_punchangle)
    new Float:oldidle=get_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,pData_Item);
    new fm_playbackevent=register_forward(FM_PlaybackEvent,"HookFm_PlayBackEvent",false)
    trblock_enable()
    
    ExecuteHam(Ham_Weapon_PrimaryAttack,ent);
    
    trblock_disable()
    unregister_forward(FM_PlaybackEvent,fm_playbackevent,false)
    
    new Float:user_newpunch[3];pev(id,pev_punchangle,user_newpunch)
    user_newpunch[0]=user_punchangle[0]+(user_newpunch[0]-user_punchangle[0])*weapon_punchangle
    user_newpunch[1]=user_punchangle[1]+(user_newpunch[1]-user_punchangle[1])*weapon_punchangle
    user_newpunch[2]=user_punchangle[2]+(user_newpunch[2]-user_punchangle[2])*weapon_punchangle
    set_pev(id,pev_punchangle,user_newpunch)
    
    set_pdata_int(ent,pDataKey_iClip,ammo-1,pData_Item)
    
    if(pev(id,pev_weaponanim)!=1||get_pdata_int(ent,pDataKey_iState,pData_Item)!=1){
        set_pdata_int(ent,pDataKey_iState,1,pData_Item)
        Play_WeaponAnim(id,1);
        set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,2.1,pData_Item);
    }else if(oldidle<=0.0){
        set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,2.1,pData_Item);
        Play_WeaponAnim(id,1);
    }else set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,oldidle,pData_Item);
    
    emit_sound(id, CHAN_WEAPON,sound_shot,VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    
    set_pdata_float(ent,pDataKey_flNextPrimaryAttack,weapon_aspeed,pData_Item)
    
    
    //Create grnaede...
    new Float:Origin[3];pev(id,pev_origin,Origin);
    new Float:vOfs[3];pev(id,pev_view_ofs,vOfs);
    Origin[0]+=vOfs[0];
    Origin[1]+=vOfs[1];
    Origin[2]+=vOfs[2];
    
    new Float:vAngle[3];pev(id,pev_v_angle,vAngle);
    new Float:Vec[3];velocity_by_aim(id,1,Vec);
    vAngle[0]=-vAngle[0];
    
    new Float:FireOrigin[3]
    FireOrigin[0]=Vec[0]*25.0+Origin[0];
    FireOrigin[1]=Vec[1]*25.0+Origin[1];
    FireOrigin[2]=Vec[2]*25.0+Origin[2];
    Vec[0]*=500.0;
    Vec[1]*=500.0;
    Vec[2]*=500.0;
        
    new tr=create_tr2();
    engfunc(EngFunc_TraceLine,Origin,FireOrigin,IGNORE_MONSTERS,id,tr);
    get_tr2(tr, TR_vecEndPos, FireOrigin);
    free_tr2(tr);    
        
    static info_target;
    if(!info_target)info_target= engfunc(EngFunc_AllocString, "info_target")
    
    new fire=engfunc(EngFunc_CreateNamedEntity,info_target)
    set_pev(fire, pev_classname, classname_fire);
    engfunc(EngFunc_SetModel, fire, model_fire);
    engfunc(EngFunc_SetSize ,fire,Float:{ 0.0, 0.0, 0.0 },Float:{ 0.0, 0.0, 0.0 })
    engfunc(EngFunc_SetOrigin, fire, Origin);
    set_pev(fire, pev_solid, SOLID_TRIGGER);
    set_pev(fire, pev_movetype, MOVETYPE_FLY);
    set_pev(fire, pev_velocity, Vec);
    set_pev(fire, pev_owner, id);
    fm_set_rendering(fire,kRenderFxNone,255,255,255,kRenderTransAdd,255)
    set_pev(fire,pev_scale ,0.01)
    set_pev (fire,pev_nextthink,get_gametime()+0.06);
    return HAM_SUPERCEDE
}
public HookHam_WeaponBox_Spawn(ent)state SetModel: Enabled;
//Fakemeta
public HookFm_SetModel(const ent,const str[]) <SetModel: Enabled>{
    state SetModel: Disabled; 
    if(!ent||!pev_valid(ent))return FMRES_HANDLED;
    static i, classname[32], item; pev(ent, pev_classname, classname, 31);
    if(!equal(classname, "weaponbox")) return FMRES_IGNORED;
    for(i = 0; i < 6; i++) {
        item = get_pdata_cbase(ent, pDataKey_WeaponBoxItems + i, pData_Item);
        if(item > 0 && Is_CustomItem(item)) {
            engfunc(EngFunc_SetModel, ent, model_w);
            set_pev(ent,pev_body,body_w);
            static owner;owner=pev(ent,pev_owner);
            if(1<=owner<=32)
                set_pev(item,pev_iuser1,get_pdata_int(owner, pDataKey_ibpAmmo +pDataKey_CustomAmmo,pData_Player)),
                set_pdata_int(owner, pDataKey_ibpAmmo +pDataKey_CustomAmmo,0,pData_Player);
            return FMRES_SUPERCEDE;
        }
    }
    return FMRES_IGNORED;
}
public HookFm_SetModel() <SetModel: Disabled> { return FMRES_IGNORED;}
public HookFm_SetModel() <> { return FMRES_IGNORED;}
public HookFm_PlayBackEvent()return FMRES_SUPERCEDE;
public HookFm_UpdateClientData(const id,const SendWeapons,const CD_Handle){
    static item;item=get_pdata_cbase(id, pDataKey_iActiveItem,pData_Player);
    if(item<=0||!Is_CustomItem(item))return FMRES_IGNORED;
    set_cd(CD_Handle, CD_flNextAttack,99999.0);
    return FMRES_HANDLED;
}
//Stocks
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) {
    new Float:RenderColor[3];
    RenderColor[0] = float(r);
    RenderColor[1] = float(g);
    RenderColor[2] = float(b);

    set_pev(entity, pev_renderfx, fx);
    set_pev(entity, pev_rendercolor, RenderColor);
    set_pev(entity, pev_rendermode, render);
    set_pev(entity, pev_renderamt, float(amount));

    return 1;
}
stock make_weapon(){
    new ent; 
    static g_AllocString_E;
    if(g_AllocString_E||(g_AllocString_E=engfunc(EngFunc_AllocString,weapon_name)))
        ent = engfunc(EngFunc_CreateNamedEntity, g_AllocString_E);
    else return -1;
    if(ent <= 0) return -1;
    set_pev(ent, pev_spawnflags, SF_NORESPAWN);
    set_pev(ent, pev_impulse, WEAPON_KEY);
    ExecuteHam(Ham_Spawn, ent);
    set_pdata_int(ent,pDataKey_iPrimaryAmmoType,15,pData_Item);
    return ent;
}
stock Play_WeaponAnim(const id,const anim){
    set_pev(id, pev_weaponanim,anim);
    message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id);
    write_byte(anim);
    write_byte(0);
    message_end();
}
//3,    200,-1, -1, 0, 4, 20, 0,    // weapon_m249
stock Weaponlist(const id,const bool:set) {
    static Msg_WeaponList;
    if(!Msg_WeaponList&&!(Msg_WeaponList=get_user_msgid("WeaponList")))return;
    message_begin(MSG_ONE, Msg_WeaponList, {0,0,0}, id);
    if(set==true){
        write_string(weapon_new);
        write_byte(pDataKey_CustomAmmo);
        write_byte(weapon_bpammo);
    }else{
        write_string(weapon_name);
        write_byte(3);
        write_byte(200);
    }
    write_byte(-1);
    write_byte(-1);
    write_byte(0);
    write_byte(4);
    write_byte(20);
    message_end();
}

//Visit to AGHL.ru
stock UTIL_DropWeapon(const id,const slot){
    static iEntity; iEntity = get_pdata_cbase(id, (pDataKey_iPlayerItems + slot), pData_Player);
    if(iEntity > 0) {
        static iNext,szWeaponName[32];
        do{
            iNext = get_pdata_cbase(iEntity, pDataKey_iNext, 4);
            if(get_weaponname(get_pdata_int(iEntity, pDataKey_iId, 4), szWeaponName, 31))
                engclient_cmd(id, "drop", szWeaponName);
        } while(( iEntity = iNext) > 0);
    }
}
//Fire
public Flame_Think(ent){
    new owner=pev(ent,pev_owner);
    if(!is_user_connected(owner)){
        engfunc(EngFunc_RemoveEntity,ent);
        return;
    }
    new Float:fFrame;pev(ent,pev_frame,fFrame);
    new Float:fOrigin[3];pev(ent,pev_origin,fOrigin);
    if(pev(ent,pev_waterlevel)>0||fFrame>=(frames-1.0)){
        /*
        engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
        write_byte(TE_EXPLOSION);
        engfunc(EngFunc_WriteCoord, fOrigin[0])
        engfunc(EngFunc_WriteCoord, fOrigin[1])
        engfunc(EngFunc_WriteCoord, fOrigin[2])
        write_short(g_steam); // sprite
        write_byte(random_num(1,6)); // scale in 0.1
        write_byte(random_num(10,30)); // framerate
        write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES); // flags
        message_end() ;
        */
        engfunc(EngFunc_RemoveEntity, ent);
        return;
    }
    new Float:fScale;pev(ent,pev_scale,fScale);
    
    static mp;if(!mp)mp=get_maxplayers();
    new target;
    while((target = engfunc(EngFunc_FindEntityInSphere, target, fOrigin,35.0))> 0){
        if(target==owner||target==ent)continue
        if(pev(target,pev_takedamage)==DAMAGE_NO)continue
        new solid=pev(target,pev_solid);if(solid==SOLID_NOT||solid==SOLID_TRIGGER)continue
        new Float:Health;pev(target,pev_health,Health);if(Health<=0.0)continue
        if(target<=mp){
            if(!is_user_connected(target)||!zp_get_user_zombie(target))continue;
            
            //new Float:user_pain=get_pdata_float(target,m_flPainShock,5);
            
            //set_pdata_int(target,pDataKey_iLastHitGroup,HIT_GENERIC,pData_Player);
            
            new Float:user_velocity[3];
            pev(target,pev_velocity,user_velocity);
            
            ExecuteHamB(Ham_TakeDamage, target, ent, owner,5.0, DMG_BULLET);
            
            //set_pdata_float(target, m_flPainShock,user_pain,5);
            if(is_user_alive(target)){
                new Float:vlen=floatsqroot(user_velocity[0]*user_velocity[0]+user_velocity[1]*user_velocity[1]);
                user_velocity[0]=user_velocity[0]/vlen*floatmax(-60.0,vlen-16.0);
                user_velocity[1]=user_velocity[1]/vlen*floatmax(-60.0,vlen-16.0);
                set_pev(target,pev_velocity,user_velocity);
            }
        }else ExecuteHamB(Ham_TakeDamage, target, ent, owner,5.0, DMG_BULLET)
    }
    set_pev(ent,pev_scale,fScale+0.075)
    set_pev(ent,pev_frame,fFrame+1.0)
    set_pev (ent,pev_nextthink,get_gametime()+0.035)
}
public Flame_Touch(ent,touch){
    new owner=pev(ent,pev_owner);
    if(!is_user_connected(owner)){
        engfunc(EngFunc_RemoveEntity,ent);
        return;
    }
    if(touch>0&&pev_valid(touch)){
        static mp;if(!mp)mp=get_maxplayers();
        if(touch<=mp){
            if(!is_user_connected(touch)||!zp_get_user_zombie(touch))return;
            
            //set_pdata_int(touch,pDataKey_iLastHitGroup,HIT_GENERIC,pData_Player);
            //new Float:user_pain=get_pdata_float(touch,m_flPainShock,5);
            
            new Float:user_velocity[3];
            pev(touch,pev_velocity,user_velocity);
            
            ExecuteHamB(Ham_TakeDamage, touch, ent, owner,75.0, DMG_BULLET);
            
            //set_pdata_float(touch, m_flPainShock,user_pain,5);
            
            if(is_user_alive(touch)){
                new Float:vlen=floatsqroot(user_velocity[0]*user_velocity[0]+user_velocity[1]*user_velocity[1]);
                user_velocity[0]=user_velocity[0]/vlen*floatmax(-16.0,vlen-16.0);
                user_velocity[1]=user_velocity[1]/vlen*floatmax(-16.0,vlen-16.0);
                set_pev(touch,pev_velocity,user_velocity);
            }
        }else ExecuteHamB(Ham_TakeDamage, touch, ent,owner,75.0, DMG_BULLET);
    }

    new Float:fOrigin[3];pev(ent,pev_origin,fOrigin)
    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
    write_byte(TE_EXPLOSION);
    engfunc(EngFunc_WriteCoord, fOrigin[0])
    engfunc(EngFunc_WriteCoord, fOrigin[1])
    engfunc(EngFunc_WriteCoord, fOrigin[2])
    write_short(g_steam); // sprite
    write_byte(random_num(1,6)); // scale in 0.1
    write_byte(random_num(10,30)); // framerate
    write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES); // flags
    message_end() ;
            
    engfunc(EngFunc_RemoveEntity, ent) 
}
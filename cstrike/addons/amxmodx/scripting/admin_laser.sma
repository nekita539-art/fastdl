#include<amxmodx>
#include<fakemeta_util>
#include<hamsandwich>
#include<engine>

#define weapon_name		"weapon_m249"
#define weapon_new		"weapon_laser_chain"

#define ANIM_IDLE		0
#define ANIM_SHOOT_1		7
#define ANIM_SHOOT_2		8
#define ANIM_RELOAD		5
#define ANIM_DRAW		6

#define IDLE_TIME		1.7
#define DRAW_TIME		2.53
#define RELOAD_TIME		5.23

#define pData_Player				5
#define pData_Item				4

#define pDataKey_WeaponBoxItems			34

#define pDataKey_iOwner				41
#define pDataKey_iNext				42
#define pDataKey_iId				43

#define pDataKey_flNextPrimaryAttack		46
#define pDataKey_flNextSecondaryAttack		47
#define pDataKey_flNextTimeWeaponIdle		48
#define pDataKey_iPrimaryAmmoType		49
#define pDataKey_iClip				51
#define pDataKey_iInReload			54
#define pDataKey_iSpecialReload			55
#define pDataKey_iState				74

#define pDataKey_iLastHitGroup			75
#define pDataKey_flNextAttack			83

#define pDataKey_iPlayerItems			367
#define pDataKey_iActiveItem			373	
#define pDataKey_ibpAmmo			376

#define pDataKey_szAnimExtention                1968

#define WEAPON_KEY				4876676765564353
#define Is_CustomItem(%0)			(pev(%0,pev_impulse)==WEAPON_KEY)

#define model_v_low	"models/admin_weapons/v_laser_chain_low_inf.mdl"
#define model_v_high	"models/admin_weapons/v_laser_chain_high_inf.mdl"
#define model_v_extreme	"models/admin_weapons/v_laser_chain_extreme_inf.mdl"
#define model_v_charge	"models/admin_weapons/v_laser_chain_charge_inf.mdl"
#define model_p		"models/admin_weapons/p_laser_chain.mdl"
#define model_p_charge	"models/admin_weapons/p_laser_chain_charge.mdl"
#define model_w		"models/admin_weapons/w_laser_chain.mdl"

#define weapon_punchangle		0.5	
#define weapon_damage1			0.1		
#define weapon_damage2			0.1	
#define weapon_damage3			0.1				
#define weapon_aspeed			0.07			

#define damage_ball1                    1000.0
#define damage_ball2                    1500.0
#define damage_ball3                    2000.0
#define explode_radius                  100.0

#define sprite_ball1    "sprites/Reega_kz/laser_chain_ball1.spr"
#define sprite_ball2    "sprites/Reega_kz/laser_chain_ball2.spr"
#define sprite_ball3    "sprites/Reega_kz/laser_chain_ball3.spr"

#define weapon_ammo	100
#define weapon_bpammo	200
#define sound_shot	"admin_weapons/laser_chain_fire1.wav"
#define sound_shot2	"admin_weapons/laser_chain_fire2.wav"

#define classname_ball	"chain_ball"

#define Get_BitVar(%1,%2) (%1&(1<<(%2&31)))
#define Set_BitVar(%1,%2) %1|=(1<<(%2&31))
#define UnSet_BitVar(%1,%2) %1&=~(1<<(%2&31))

new Msg_WeaponList
new g_AllocString_V_low,g_AllocString_V_high,g_AllocString_V_extreme,g_AllocString_V_charge,g_AllocString_P,g_AllocString_P_charge

new g_ChargeState[512],g_ChargeShots[512]
new Float:g_VecEndTrace[3];
new g_ChargeBall,g_ChargeForEntity,Charge3rdState[33];
new gMaxPlayers

#define shots_for_high 20
#define shots_for_extreme shots_for_high+40

#define MUZZLEFLASH1 "sprites/Reega_kz/laser_chain_muzzle1.spr"
#define MUZZLEFLASH2 "sprites/Reega_kz/laser_chain_muzzle2.spr"
#define MUZZLEFLASH3 "sprites/Reega_kz/laser_chain_muzzle3.spr"

new g_Muzzleflash_Ent1,g_Muzzleflash1
new g_Muzzleflash_Ent2,g_Muzzleflash2
new g_Muzzleflash_Ent3,g_Muzzleflash3

new g_MuzzleflashBall_Ent1,g_MuzzleflashBall1
new g_MuzzleflashBall_Ent2,g_MuzzleflashBall2
new g_MuzzleflashBall_Ent3,g_MuzzleflashBall3

new g_ChargeBall1_Explosion,g_ChargeBall2_Explosion,g_ChargeBall3_Explosion

enum{
	STATE_LOW=0,
	STATE_HIGH,
	STATE_EXTREME,
	STATE_CHARGE
}
public plugin_precache(){
	engfunc(EngFunc_PrecacheModel,model_v_low)
	engfunc(EngFunc_PrecacheModel,model_v_high)
	engfunc(EngFunc_PrecacheModel,model_v_extreme)
	engfunc(EngFunc_PrecacheModel,model_v_charge)
	engfunc(EngFunc_PrecacheModel,model_p)
	engfunc(EngFunc_PrecacheModel,model_p_charge)
	engfunc(EngFunc_PrecacheModel,model_w)
	g_AllocString_V_low=engfunc(EngFunc_AllocString,model_v_low)
	g_AllocString_V_high=engfunc(EngFunc_AllocString,model_v_high)
	g_AllocString_V_extreme=engfunc(EngFunc_AllocString,model_v_extreme)
	g_AllocString_V_charge=engfunc(EngFunc_AllocString,model_v_charge)
	g_AllocString_P=engfunc(EngFunc_AllocString,model_p)
	g_AllocString_P_charge=engfunc(EngFunc_AllocString,model_p_charge)
	
	engfunc(EngFunc_PrecacheModel,sprite_ball1)
	engfunc(EngFunc_PrecacheModel,sprite_ball2)
	engfunc(EngFunc_PrecacheModel,sprite_ball3)
	
	g_ChargeBall1_Explosion=engfunc(EngFunc_PrecacheModel,"sprites/Reega_kz/laser_chain_explosion1.spr")
	g_ChargeBall2_Explosion=engfunc(EngFunc_PrecacheModel,"sprites/Reega_kz/laser_chain_explosion2.spr")
	g_ChargeBall3_Explosion=engfunc(EngFunc_PrecacheModel,"sprites/Reega_kz/laser_chain_explosion3.spr")
	
	engfunc(EngFunc_PrecacheSound,sound_shot)
	engfunc(EngFunc_PrecacheSound,sound_shot2)
	engfunc(EngFunc_PrecacheSound,"admin_weapons/laser_chain_charge_end1.wav")
	engfunc(EngFunc_PrecacheSound,"admin_weapons/laser_chain_charge_loop1.wav")
	engfunc(EngFunc_PrecacheSound,"admin_weapons/laser_chain_charge_spin1.wav")
	engfunc(EngFunc_PrecacheSound,"admin_weapons/laser_chain_charge_start1.wav")
	engfunc(EngFunc_PrecacheSound,"admin_weapons/laser_chain_clip_in1.wav")
	engfunc(EngFunc_PrecacheSound,"admin_weapons/laser_chain_clip_in2.wav")
	engfunc(EngFunc_PrecacheSound,"admin_weapons/laser_chain_clip_out1.wav")
	engfunc(EngFunc_PrecacheSound,"admin_weapons/laser_chain_clip_out2.wav")
	engfunc(EngFunc_PrecacheSound,"admin_weapons/laser_chain_draw1.wav")
	engfunc(EngFunc_PrecacheSound,"admin_weapons/laser_chain_explosion1.wav")
	engfunc(EngFunc_PrecacheSound,"admin_weapons/laser_chain_explosion2.wav")
	engfunc(EngFunc_PrecacheSound,"admin_weapons/laser_chain_explosion3.wav")
	engfunc(EngFunc_PrecacheSound,"admin_weapons/laser_chain_idle1.wav")
	
	g_Muzzleflash_Ent1=engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	precache_model(MUZZLEFLASH1)
	engfunc(EngFunc_SetModel,g_Muzzleflash_Ent1,MUZZLEFLASH1)
	set_pev(g_Muzzleflash_Ent1,pev_scale,0.1)
	set_pev(g_Muzzleflash_Ent1,pev_rendermode,kRenderTransTexture)
	set_pev(g_Muzzleflash_Ent1,pev_renderamt,0.0)
	
	g_Muzzleflash_Ent2=engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	precache_model(MUZZLEFLASH2)
	engfunc(EngFunc_SetModel,g_Muzzleflash_Ent2,MUZZLEFLASH2)
	set_pev(g_Muzzleflash_Ent2,pev_scale,0.1)
	set_pev(g_Muzzleflash_Ent2,pev_rendermode,kRenderTransTexture)
	set_pev(g_Muzzleflash_Ent2,pev_renderamt,0.0)
	
	g_Muzzleflash_Ent3=engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	precache_model(MUZZLEFLASH3)
	engfunc(EngFunc_SetModel,g_Muzzleflash_Ent3,MUZZLEFLASH3)
	set_pev(g_Muzzleflash_Ent3,pev_scale,0.1)
	set_pev(g_Muzzleflash_Ent3,pev_rendermode,kRenderTransTexture)
	set_pev(g_Muzzleflash_Ent3,pev_renderamt,0.0)
	
	g_MuzzleflashBall_Ent1=engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	engfunc(EngFunc_SetModel,g_MuzzleflashBall_Ent1,sprite_ball1)
	set_pev(g_MuzzleflashBall_Ent1,pev_scale,0.2)
	set_pev(g_MuzzleflashBall_Ent1,pev_rendermode,kRenderTransTexture)
	set_pev(g_MuzzleflashBall_Ent1,pev_renderamt,0.0)
	
	g_MuzzleflashBall_Ent2=engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	engfunc(EngFunc_SetModel,g_MuzzleflashBall_Ent2,sprite_ball2)
	set_pev(g_MuzzleflashBall_Ent2,pev_scale,0.2)
	set_pev(g_MuzzleflashBall_Ent2,pev_rendermode,kRenderTransTexture)
	set_pev(g_MuzzleflashBall_Ent2,pev_renderamt,0.0)
	
	g_MuzzleflashBall_Ent3=engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	engfunc(EngFunc_SetModel,g_MuzzleflashBall_Ent3,sprite_ball3)
	set_pev(g_MuzzleflashBall_Ent3,pev_scale,0.2)
	set_pev(g_MuzzleflashBall_Ent3,pev_rendermode,kRenderTransTexture)
	set_pev(g_MuzzleflashBall_Ent3,pev_renderamt,0.0)
	
	engfunc(EngFunc_PrecacheGeneric,"sprites/Reega_kz/laser_chain_ammo1.spr")
	engfunc(EngFunc_PrecacheGeneric,"sprites/Reega_kz/laser_chain_weapon1.spr")
	engfunc(EngFunc_PrecacheGeneric,"sprites/Reega_kz/laser_chain_muzzle1.spr")
	engfunc(EngFunc_PrecacheGeneric,"sprites/Reega_kz/laser_chain_muzzle2.spr")
	engfunc(EngFunc_PrecacheGeneric,"sprites/Reega_kz/laser_chain_muzzle3.spr")
	engfunc(EngFunc_PrecacheGeneric,"sprites/weapon_laser_chain.txt")
	
	register_forward(FM_Spawn,"HookFm_Spawn",0)
}
public plugin_init(){
	RegisterHam(Ham_Item_Deploy,weapon_name,"HookHam_Weapon_Deploy",1)
	RegisterHam(Ham_Item_AddToPlayer,weapon_name,"HookHam_Weapon_Add",1)
	RegisterHam(Ham_Item_PostFrame,weapon_name,"HookHam_Weapon_Frame",0)
	
	RegisterHam(Ham_Weapon_Reload,weapon_name,"HookHam_Weapon_Reload",0)
	RegisterHam(Ham_Weapon_WeaponIdle,weapon_name,"HookHam_Weapon_Idle",0)
	RegisterHam(Ham_Weapon_PrimaryAttack,weapon_name,"HookHam_Weapon_PrimaryAttack",0)
	RegisterHam(Ham_TakeDamage,"player","HookHam_TakeDamage")
	
	register_forward(FM_SetModel,"HookFm_SetModel")
	register_forward(FM_AddToFullPack,"fw_AddToFullPack_post",1)
	register_forward(FM_CheckVisibility,"fw_CheckVisibility")
	
	register_forward(FM_UpdateClientData,"HookFm_UpdateClientData",1)
	
	register_touch("*",classname_ball,"BallTouch");
	
	gMaxPlayers=get_maxplayers()
	
	Msg_WeaponList=get_user_msgid("WeaponList");
	register_clcmd(weapon_new,"hook_item")
}
public plugin_natives(){
	register_native("give_laser_chain","get_item",1);
}
public client_command(id) {
	new Command[32];read_argv(0,Command,charsmax(Command));  
	new ent=fm_find_ent_by_owner(-1,weapon_name,id)
	if(equali(Command,"weapon_",7)&&g_ChargeBall&&Is_CustomItem(ent)||equali(Command,"lastinv")&&g_ChargeBall&&Is_CustomItem(ent)) {  
		return PLUGIN_HANDLED;
	}
	else if(equali(Command,"drop")&&g_ChargeBall&&Is_CustomItem(ent)) {
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
public get_item(id){
	UTIL_DropWeapon(id,1);
	new weapon=make_weapon();if(weapon<=0)return
	if(!ExecuteHamB(Ham_AddPlayerItem,id,weapon)){engfunc(EngFunc_RemoveEntity,weapon);return;}
	ExecuteHam(Ham_Item_AttachToPlayer,weapon,id)
	new ammotype=pDataKey_ibpAmmo+get_pdata_int(weapon,pDataKey_iPrimaryAmmoType,pData_Item)
	new ammo=get_pdata_int(id,ammotype,pData_Player)
	if(ammo<weapon_bpammo)set_pdata_int(id,ammotype,weapon_bpammo,pData_Player)
	set_pdata_int(weapon,pDataKey_iClip,weapon_ammo,pData_Item)
	emit_sound(id,CHAN_ITEM,"items/gunpickup2.wav",VOL_NORM,ATTN_NORM,0,PITCH_NORM)
	g_ChargeState[weapon]=STATE_LOW
	g_ChargeShots[weapon]=0
	UnSet_BitVar(g_MuzzleflashBall1,id)
	UnSet_BitVar(g_MuzzleflashBall2,id)
	UnSet_BitVar(g_MuzzleflashBall3,id)
	g_ChargeBall=0
	Charge3rdState[id]=0
	g_ChargeForEntity=0
}
public hook_item(id){
	engclient_cmd(id,weapon_name)
	return PLUGIN_HANDLED
}
public fw_AddToFullPack_post(esState,iE,ent,iHost,iHostFlags,iPlayer,pSet){
	if(ent==g_Muzzleflash_Ent1){
		if(Get_BitVar(g_Muzzleflash1,iHost)){
			set_es(esState,ES_Frame,float(random_num(0,2)))
			set_es(esState,ES_RenderMode,kRenderTransAdd)
			set_es(esState,ES_RenderAmt,255.0)
			UnSet_BitVar(g_Muzzleflash1,iHost)
		}	
		set_es(esState,ES_Skin,iHost)
		set_es(esState,ES_Body,1)
		set_es(esState,ES_AimEnt,iHost)
		set_es(esState,ES_MoveType,MOVETYPE_FOLLOW)
	} 
	if(ent==g_Muzzleflash_Ent2){
		if(Get_BitVar(g_Muzzleflash2,iHost))
		{
			set_es(esState,ES_Frame,float(random_num(0,2)))
			set_es(esState,ES_RenderMode,kRenderTransAdd)
			set_es(esState,ES_RenderAmt,255.0)
			UnSet_BitVar(g_Muzzleflash2,iHost)
		}	
		set_es(esState,ES_Skin,iHost)
		set_es(esState,ES_Body,1)
		set_es(esState,ES_AimEnt,iHost)
		set_es(esState,ES_MoveType,MOVETYPE_FOLLOW)
	}
	if(ent==g_Muzzleflash_Ent3){
		if(Get_BitVar(g_Muzzleflash3,iHost)){
			set_es(esState,ES_Frame,float(random_num(0,2)))
			set_es(esState,ES_RenderMode,kRenderTransAdd)
			set_es(esState,ES_RenderAmt,255.0)
			UnSet_BitVar(g_Muzzleflash3,iHost)
		}	
		set_es(esState,ES_Skin,iHost)
		set_es(esState,ES_Body,1)
		set_es(esState,ES_AimEnt,iHost)
		set_es(esState,ES_MoveType,MOVETYPE_FOLLOW)
	}
	if(ent==g_MuzzleflashBall_Ent1){
		if(Get_BitVar(g_MuzzleflashBall1,iHost)){
			set_es(esState,ES_Frame,float(random_num(0,8)))
			set_es(esState,ES_RenderMode,kRenderTransAdd)
			set_es(esState,ES_RenderAmt,255.0)
		}	
		set_es(esState,ES_Skin,iHost)
		set_es(esState,ES_Body,1)
		set_es(esState,ES_AimEnt,iHost)
		set_es(esState,ES_MoveType,MOVETYPE_FOLLOW)
	}
	if(ent==g_MuzzleflashBall_Ent2){
		if(Get_BitVar(g_MuzzleflashBall2,iHost)){
			set_es(esState,ES_Frame,float(random_num(0,8)))
			set_es(esState,ES_RenderMode,kRenderTransAdd)
			set_es(esState,ES_RenderAmt,255.0)
		}	
		set_es(esState,ES_Skin,iHost)
		set_es(esState,ES_Body,1)
		set_es(esState,ES_AimEnt,iHost)
		set_es(esState,ES_MoveType,MOVETYPE_FOLLOW)
	}
	if(ent==g_MuzzleflashBall_Ent3){
		if(Get_BitVar(g_MuzzleflashBall3,iHost)){
			set_es(esState,ES_Frame,float(random_num(0,8)))
			set_es(esState,ES_RenderMode,kRenderTransAdd)
			set_es(esState,ES_RenderAmt,255.0)
		}	
		set_es(esState,ES_Skin,iHost)
		set_es(esState,ES_Body,1)
		set_es(esState,ES_AimEnt,iHost)
		set_es(esState,ES_MoveType,MOVETYPE_FOLLOW)
	}
}
public fw_CheckVisibility(entity,pSet){
	if(entity==g_Muzzleflash_Ent1){
		forward_return(FMV_CELL,1)
		return FMRES_SUPERCEDE
	} 
	else if(entity==g_Muzzleflash_Ent2){
		forward_return(FMV_CELL,1)
		return FMRES_SUPERCEDE
	} 
	else if(entity==g_Muzzleflash_Ent3){
		forward_return(FMV_CELL,1)
		return FMRES_SUPERCEDE
	}
	else if(entity==g_MuzzleflashBall_Ent1){
		forward_return(FMV_CELL,1)
		return FMRES_SUPERCEDE
	}
	else if(entity==g_MuzzleflashBall_Ent2){
		forward_return(FMV_CELL,1)
		return FMRES_SUPERCEDE
	}
	else if(entity==g_MuzzleflashBall_Ent3){
		forward_return(FMV_CELL,1)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}
public HookHam_Weapon_Deploy(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED
	static id;id=get_pdata_cbase(ent,pDataKey_iOwner,pData_Item)

	if(g_ChargeState[ent]==STATE_LOW)set_pev_string(id,pev_viewmodel2,g_AllocString_V_low)
	else if(g_ChargeState[ent]==STATE_HIGH)set_pev_string(id,pev_viewmodel2,g_AllocString_V_high)
	else if(g_ChargeState[ent]==STATE_EXTREME)set_pev_string(id,pev_viewmodel2,g_AllocString_V_extreme)
	else if(g_ChargeState[ent]==STATE_CHARGE)set_pev_string(id,pev_viewmodel2,g_AllocString_V_charge)
	set_pev_string(id,pev_weaponmodel2,g_AllocString_P)
	set_pdata_float(ent,pDataKey_flNextPrimaryAttack,DRAW_TIME,pData_Item)
	set_pdata_float(ent,pDataKey_flNextSecondaryAttack,DRAW_TIME,pData_Item)
	set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,DRAW_TIME,pData_Item)
	Play_WeaponAnim(id,ANIM_DRAW)
	set_pdata_string(id,pDataKey_szAnimExtention,"m249",-1,20);
	return HAM_IGNORED
}
public HookHam_Weapon_Add(ent,id){
	switch(pev(ent,pev_impulse)){
		case WEAPON_KEY:Weaponlist(id,true)
		case 0:Weaponlist(id,false)
	}
	return HAM_IGNORED
}
public MakeBall(id){
	new ent=create_entity("env_sprite"),Float: f_origin[3],Float: f_vec[3];
	set_pev(ent,pev_classname,classname_ball);
	pev(id,pev_origin,f_origin);
	velocity_by_aim(id,35,f_vec);
	for(new i=0;i<3;i++){ f_origin[i]+=f_vec[i];f_vec[i]*=40.0;}
	f_origin[2]+=(pev(id,pev_flags)&FL_DUCKING)?2.0:10.0;
	set_pev(ent,pev_origin,f_origin);
	set_pev(ent,pev_velocity,f_vec);
	set_pev(ent,pev_solid,SOLID_BBOX);
	set_pev(ent,pev_movetype,MOVETYPE_FLY);
	if(g_ChargeForEntity&1)entity_set_model(ent,sprite_ball1);
	else if(g_ChargeForEntity&2)entity_set_model(ent,sprite_ball2);
	if(Charge3rdState[id])entity_set_model(ent,sprite_ball3);
	set_pev(ent,pev_mins,Float:{-4.0,-4.0,-4.0});
	set_pev(ent,pev_maxs,Float:{4.0,4.0,4.0});
	set_pev(ent,pev_owner,id);
	set_pev(ent,pev_rendermode,kRenderTransAdd);
	set_pev(ent,pev_renderamt,255.0);
	set_pev(ent,pev_scale,0.3);
	pev(id,pev_v_angle,f_vec);
	set_pev(ent,pev_v_angle,f_vec);
}
public BallTouch(id,ent){
	new Float:origin[3],Float: f_vec[3];
	pev(ent,pev_origin,origin);
	velocity_by_aim(ent,-15,f_vec);
	for(new i=0;i<3;i++)origin[i]+=f_vec[i];
	if(g_ChargeForEntity&1){ 
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
		write_byte(TE_SPRITE);
		write_coord(floatround(origin[0]));
		write_coord(floatround(origin[1]));
		write_coord(floatround(origin[2]));
		write_short(g_ChargeBall1_Explosion);
		write_byte(7);
		write_byte(200);
		message_end();
		emit_sound(ent,CHAN_ITEM,"admin_weapons/laser_chain_explosion1.wav",1.0,ATTN_NORM,0,PITCH_NORM);
	}
	else if(g_ChargeForEntity&2){ 
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
		write_byte(TE_SPRITE);
		write_coord(floatround(origin[0]));
		write_coord(floatround(origin[1]));
		write_coord(floatround(origin[2]));
		write_short(g_ChargeBall2_Explosion);
		write_byte(7);
		write_byte(200);
		message_end();
		emit_sound(ent,CHAN_ITEM,"admin_weapons/laser_chain_explosion2.wav",1.0,ATTN_NORM,0,PITCH_NORM);
	}
	else if(!(g_ChargeForEntity&2)&&Charge3rdState[id]){
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
		write_byte(TE_SPRITE);
		write_coord(floatround(origin[0]));
		write_coord(floatround(origin[1]));
		write_coord(floatround(origin[2]));
		write_short(g_ChargeBall3_Explosion);
		write_byte(7);
		write_byte(200);
		message_end();
		emit_sound(ent,CHAN_ITEM,"admin_weapons/laser_chain_explosion3.wav",1.0,ATTN_NORM,0,PITCH_NORM);
		if(Charge3rdState[id])Charge3rdState[id]=0
	}
	BallDamage(ent)
	set_pev(ent,pev_flags,FL_KILLME);
}
public BallDamage(ent){
	static owner;owner=pev(ent, pev_owner);
	static attacker;
	if(!is_user_alive(owner)){
		attacker=0;
		return;
	} 
	else attacker=owner;
	for(new i=0; i<gMaxPlayers; i++) {
		if(i==attacker)continue;
		if(get_user_team(i)==get_user_team(attacker))continue;
		if(!is_user_alive(i))continue;
		if(entity_range(i, ent)>explode_radius)continue;
		if(g_ChargeForEntity&1)ExecuteHamB(Ham_TakeDamage,i,0,attacker,damage_ball1,DMG_BULLET)
		else if(g_ChargeForEntity&2)ExecuteHamB(Ham_TakeDamage,i,0,attacker,damage_ball2,DMG_BULLET)
		if(Charge3rdState[owner])ExecuteHamB(Ham_TakeDamage,i,0,attacker,damage_ball3,DMG_BULLET)
	}
}
public HookHam_Weapon_Frame(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED;
	static id;id=get_pdata_cbase(ent,pDataKey_iOwner,pData_Item);
	if(get_pdata_int(ent,pDataKey_iInReload,pData_Item)){
		static clip,ammotype,ammo,j
		clip=get_pdata_int(ent,pDataKey_iClip,pData_Item);
		ammotype=pDataKey_ibpAmmo+get_pdata_int(ent,pDataKey_iPrimaryAmmoType,pData_Item);
		ammo=get_pdata_int(id,ammotype,pData_Player);
		j=min(weapon_ammo-clip,ammo);
		set_pdata_int(ent,pDataKey_iClip,clip+j,pData_Item);
		set_pdata_int(id,ammotype,ammo-j,pData_Player);
		set_pdata_int(ent,pDataKey_iInReload,0,pData_Item);
	}
	if(g_ChargeShots[ent]<shots_for_high)g_ChargeState[ent]=STATE_LOW;
	else if(g_ChargeShots[ent]>=shots_for_high&&g_ChargeShots[ent]<shots_for_extreme)g_ChargeState[ent]=STATE_HIGH;
	else if(g_ChargeShots[ent]>=shots_for_extreme)g_ChargeState[ent]=STATE_EXTREME;
	if(g_ChargeBall)g_ChargeState[ent]=STATE_CHARGE
	if(g_ChargeState[ent]==STATE_LOW)set_pev_string(id,pev_viewmodel2,g_AllocString_V_low)
	else if(g_ChargeState[ent]==STATE_HIGH)set_pev_string(id,pev_viewmodel2,g_AllocString_V_high)
	else if(g_ChargeState[ent]==STATE_EXTREME)set_pev_string(id,pev_viewmodel2,g_AllocString_V_extreme)
	else if(g_ChargeState[ent]==STATE_CHARGE){   
		set_pev_string(id,pev_viewmodel2,g_AllocString_V_charge)
		set_pev_string(id,pev_weaponmodel2,g_AllocString_P_charge)
	}
	if(g_ChargeShots[ent]>0&&!(pev(id,pev_button)&IN_ATTACK)&&!g_ChargeBall)g_ChargeShots[ent]--
	
	static iButton;iButton=pev(id,pev_button);
	if(get_pdata_float(ent,pDataKey_flNextPrimaryAttack,pData_Item)>=0.0)return HAM_IGNORED;
	g_ChargeBall=pev(ent,pev_iuser1);
	new Float:fFinshTime;pev(ent,pev_fuser1,fFinshTime);
	if(iButton&IN_ATTACK2){
		g_ChargeState[ent]=STATE_CHARGE
		if(!g_ChargeBall){
			g_ChargeBall=1;
			fFinshTime=get_gametime()+3.0;
			Play_WeaponAnim(id,1);
			emit_sound(id,CHAN_WEAPON,"admin_weapons/laser_chain_charge_spin1.wav",1.0,ATTN_NORM,0,PITCH_NORM);
			set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,1.0,pData_Item);
			set_pdata_float(ent,pDataKey_flNextPrimaryAttack,1.0,pData_Item);
			set_pev(ent,pev_iuser1,g_ChargeBall)
			Set_BitVar(g_MuzzleflashBall1,id)
			UnSet_BitVar(g_MuzzleflashBall2,id)
			UnSet_BitVar(g_MuzzleflashBall3,id)
			if(Charge3rdState[id])Charge3rdState[id]=0
		}
		if(get_gametime()>fFinshTime&&g_ChargeBall!=2){
			g_ChargeBall=2;
			fFinshTime=get_gametime()+5.0;
			Play_WeaponAnim(id,2);	
			emit_sound(id,CHAN_WEAPON,"admin_weapons/laser_chain_charge_start1.wav",1.0,ATTN_NORM,0,PITCH_NORM);
			set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,3.0,pData_Item);
			set_pdata_float(ent,pDataKey_flNextPrimaryAttack,3.0,pData_Item);
			set_pev(ent,pev_iuser1,g_ChargeBall);
			UnSet_BitVar(g_MuzzleflashBall1,id)
			Set_BitVar(g_MuzzleflashBall2,id)
			UnSet_BitVar(g_MuzzleflashBall3,id)
			if(Charge3rdState[id])Charge3rdState[id]=0
		}
		if(get_gametime()>fFinshTime&&g_ChargeBall!=3){
			g_ChargeBall=3;
			Play_WeaponAnim(id,3);		
			set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,3.0,pData_Item);
			set_pdata_float(ent,pDataKey_flNextPrimaryAttack,3.0,pData_Item);
			set_pev(ent,pev_fuser1,fFinshTime);
			UnSet_BitVar(g_MuzzleflashBall1,id)
			UnSet_BitVar(g_MuzzleflashBall2,id)
			Set_BitVar(g_MuzzleflashBall3,id)
			if(!Charge3rdState[id])Charge3rdState[id]=1
		}
		iButton&=~IN_ATTACK2;
		set_pev(id,pev_button,iButton);
	}
	else{
		switch (g_ChargeBall){	
			case 1:{
				Play_WeaponAnim(id,4);
				emit_sound(id,CHAN_WEAPON,sound_shot2,1.0,ATTN_NORM,0,PITCH_NORM)
				set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,1.63,pData_Item);
				set_pdata_float(ent,pDataKey_flNextPrimaryAttack,1.0,pData_Item);
				UnSet_BitVar(g_MuzzleflashBall1,id)
				UnSet_BitVar(g_MuzzleflashBall2,id)
				UnSet_BitVar(g_MuzzleflashBall3,id)
				g_ChargeState[ent]=STATE_LOW
				g_ChargeShots[ent]=0
				g_ChargeForEntity=g_ChargeBall
				set_pev_string(id,pev_weaponmodel2,g_AllocString_P)
				MakeBall(id)
			}
			case 2:{
				Play_WeaponAnim(id,4);
				emit_sound(id,CHAN_WEAPON,sound_shot2,1.0,ATTN_NORM,0,PITCH_NORM)
				set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,1.63,pData_Item);
				set_pdata_float(ent,pDataKey_flNextPrimaryAttack,1.0,pData_Item);
				UnSet_BitVar(g_MuzzleflashBall1,id)
				UnSet_BitVar(g_MuzzleflashBall2,id)
				UnSet_BitVar(g_MuzzleflashBall3,id)
				g_ChargeState[ent]=STATE_LOW
				g_ChargeShots[ent]=0
				g_ChargeForEntity=g_ChargeBall
				set_pev_string(id,pev_weaponmodel2,g_AllocString_P)
				MakeBall(id)
			}
			case 3:{
				Play_WeaponAnim(id,4);
				emit_sound(id,CHAN_WEAPON,sound_shot2,1.0,ATTN_NORM,0,PITCH_NORM)
				set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,1.63,pData_Item);
				set_pdata_float(ent,pDataKey_flNextPrimaryAttack,1.0,pData_Item);
				UnSet_BitVar(g_MuzzleflashBall1,id)
				UnSet_BitVar(g_MuzzleflashBall2,id)
				UnSet_BitVar(g_MuzzleflashBall3,id)
				g_ChargeState[ent]=STATE_LOW
				g_ChargeShots[ent]=0
				g_ChargeForEntity=g_ChargeBall
				if(!Charge3rdState[id])Charge3rdState[id]=1
				set_pev_string(id,pev_weaponmodel2,g_AllocString_P)
				MakeBall(id)
			}
		}
		g_ChargeBall=0;
		set_pev_string(id,pev_weaponmodel2,g_AllocString_P)
		set_pev(ent,pev_iuser1,g_ChargeBall);
	}
	
	return HAM_IGNORED;
}
public HookHam_Weapon_Reload(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED;
	
	static clip;clip=get_pdata_int(ent,pDataKey_iClip,pData_Item);
	if(clip>=weapon_ammo)return HAM_SUPERCEDE;
	
	static id;id=get_pdata_cbase(ent,pDataKey_iOwner,pData_Item);
	if(get_pdata_int(id,pDataKey_ibpAmmo+get_pdata_int(ent,pDataKey_iPrimaryAmmoType,pData_Item),pData_Player)<=0)return HAM_SUPERCEDE
	
	set_pdata_int(ent,pDataKey_iClip,0,pData_Item);
	ExecuteHam(Ham_Weapon_Reload,ent);
	set_pdata_int(ent,pDataKey_iClip,clip,pData_Item);
	set_pdata_int(ent,pDataKey_iInReload,1,pData_Item);
	set_pdata_float(ent,pDataKey_flNextPrimaryAttack,RELOAD_TIME,pData_Item)
	set_pdata_float(ent,pDataKey_flNextSecondaryAttack,RELOAD_TIME,pData_Item)
	set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,RELOAD_TIME,pData_Item)
	set_pdata_float(id,pDataKey_flNextAttack,RELOAD_TIME,pData_Player)
	Play_WeaponAnim(id,ANIM_RELOAD)
	return HAM_SUPERCEDE;
}
public HookHam_Weapon_Idle(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED
	if(get_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,pData_Item)>0.0)return HAM_IGNORED
	set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,IDLE_TIME,pData_Item)
	Play_WeaponAnim(get_pdata_cbase(ent,pDataKey_iOwner,pData_Item),ANIM_IDLE)
	return HAM_SUPERCEDE
}
public HookHam_Weapon_PrimaryAttack(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED
	static ammo;ammo=get_pdata_int(ent,pDataKey_iClip,pData_Item);
	if(ammo<=0){
		ExecuteHam(Ham_Weapon_PlayEmptySound,ent);
		set_pdata_float(ent,pDataKey_flNextPrimaryAttack,weapon_aspeed,pData_Item)
		return HAM_SUPERCEDE
	}
		
	static id;id=get_pdata_cbase(ent,pDataKey_iOwner,pData_Item)
	static Float:user_punchangle[3];pev(id,pev_punchangle,user_punchangle)
	static fm_hooktrace;fm_hooktrace=register_forward(FM_TraceLine,"HookFm_TraceLine",true)
	static fm_playbackevent;fm_playbackevent=register_forward(FM_PlaybackEvent,"HookFm_PlayBackEvent",false)
	
	state FireBullets: Enabled;
	ExecuteHam(Ham_Weapon_PrimaryAttack,ent)
	state FireBullets: Disabled;
	
	unregister_forward(FM_TraceLine,fm_hooktrace,true)
	unregister_forward(FM_PlaybackEvent,fm_playbackevent,false)
	
	Play_WeaponAnim(id,random_num(ANIM_SHOOT_1,ANIM_SHOOT_2))
	set_pdata_int(ent,pDataKey_iClip,ammo-1,pData_Item)
	set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,2.0,pData_Item)
	static Float:user_newpunch[3];pev(id,pev_punchangle,user_newpunch)
	
	user_newpunch[0]=user_punchangle[0]+(user_newpunch[0]-user_punchangle[0])*weapon_punchangle
	user_newpunch[1]=user_punchangle[1]+(user_newpunch[1]-user_punchangle[1])*weapon_punchangle
	user_newpunch[2]=user_punchangle[2]+(user_newpunch[2]-user_punchangle[2])*weapon_punchangle
	set_pev(id,pev_punchangle,user_newpunch)

	emit_sound(id,CHAN_WEAPON,sound_shot,VOL_NORM,ATTN_NORM,0,PITCH_NORM)

	set_pdata_float(ent,pDataKey_flNextPrimaryAttack,weapon_aspeed,pData_Item)
	
	new Float:Origin[3]
	get_weapon_position(id,Origin,.add_forward=10.0,.add_right=7.0,.add_up=-10.5)
		
	new Float:Velo[3]
	Velo[0]=g_VecEndTrace[0]-Origin[0]
	Velo[1]=g_VecEndTrace[1]-Origin[1]
	Velo[2]=g_VecEndTrace[2]-Origin[2]
		
	vec_normalize(Velo,Velo)
	vec_mul_scalar(Velo,4096.0,Velo)
	
	if(g_ChargeState[ent]==STATE_LOW){
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_USERTRACER)
		engfunc(EngFunc_WriteCoord,Origin[0])
		engfunc(EngFunc_WriteCoord,Origin[1])
		engfunc(EngFunc_WriteCoord,Origin[2])
		engfunc(EngFunc_WriteCoord,Velo[0])
		engfunc(EngFunc_WriteCoord,Velo[1])
		engfunc(EngFunc_WriteCoord,Velo[2])
		write_byte(20)
		write_byte(4)
		write_byte(5)
		message_end()
		Set_BitVar(g_Muzzleflash1,id)
	}
	else if(g_ChargeState[ent]==STATE_HIGH){
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_USERTRACER)
		engfunc(EngFunc_WriteCoord,Origin[0])
		engfunc(EngFunc_WriteCoord,Origin[1])
		engfunc(EngFunc_WriteCoord,Origin[2])
		engfunc(EngFunc_WriteCoord,Velo[0])
		engfunc(EngFunc_WriteCoord,Velo[1])
		engfunc(EngFunc_WriteCoord,Velo[2])
		write_byte(20)
		write_byte(5)
		write_byte(5)
		message_end()
		Set_BitVar(g_Muzzleflash2,id)
	}
	else if(g_ChargeState[ent]==STATE_EXTREME){
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_USERTRACER)
		engfunc(EngFunc_WriteCoord,Origin[0])
		engfunc(EngFunc_WriteCoord,Origin[1])
		engfunc(EngFunc_WriteCoord,Origin[2])
		engfunc(EngFunc_WriteCoord,Velo[0])
		engfunc(EngFunc_WriteCoord,Velo[1])
		engfunc(EngFunc_WriteCoord,Velo[2])
		write_byte(20)
		write_byte(1)
		write_byte(5)
		message_end()
		Set_BitVar(g_Muzzleflash3,id)
	}
	
	g_ChargeShots[ent]++
	
	return HAM_SUPERCEDE
}
public HookHam_TakeDamage(victim,inflictor,attacker,Float:damage)<FireBullets: Enabled>{ 
	new ent=fm_find_ent_by_owner(-1,weapon_name,attacker)
	if(g_ChargeState[ent]==STATE_LOW)SetHamParamFloat(4,damage*weapon_damage1);
	else if(g_ChargeState[ent]==STATE_HIGH)SetHamParamFloat(4,damage*weapon_damage2);
	else if(g_ChargeState[ent]==STATE_EXTREME)SetHamParamFloat(4,damage*weapon_damage3);
	return HAM_OVERRIDE;
}
public HookHam_TakeDamage()<FireBullets: Disabled>{ 
	return HAM_IGNORED;
}
public HookHam_TakeDamage()<>{
	return HAM_IGNORED;
}
public HookFm_SetModel(ent){ 
	static i,classname[32],item;pev(ent,pev_classname,classname,31);
	if(!equal(classname,"weaponbox"))return FMRES_IGNORED;
	for(i=0;i<6;i++){
		item=get_pdata_cbase(ent,pDataKey_WeaponBoxItems+i,4);
		static id;id=pev(ent,pev_owner);
		if(item>0&&Is_CustomItem(item)){
			engfunc(EngFunc_SetModel,ent,model_w);
			g_ChargeState[ent]=STATE_LOW
			g_ChargeShots[ent]=0
			UnSet_BitVar(g_MuzzleflashBall1,id)
			UnSet_BitVar(g_MuzzleflashBall2,id)
			UnSet_BitVar(g_MuzzleflashBall3,id)
			g_ChargeBall=0
			Charge3rdState[id]=0
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}
public HookFm_PlayBackEvent(){ 
	return FMRES_SUPERCEDE
}
public HookFm_TraceLine(Float:tr_start[3],Float:tr_end[3],tr_flag,tr_ignore,tr){
	if(tr_flag&IGNORE_MONSTERS)return FMRES_IGNORED;
	static hit;hit=get_tr2(tr,TR_pHit)
	static Decal
	static glassdecal;if(!glassdecal)glassdecal=engfunc(EngFunc_DecalIndex,"{bproof1")
	hit=get_tr2(tr,TR_pHit)
	if(hit>0&&pev_valid(hit))
		if(pev(hit,pev_solid)!=SOLID_BSP)return FMRES_IGNORED
		else if(pev(hit,pev_rendermode)!=0)Decal=glassdecal
		else Decal=random_num(41,45)
	else Decal=random_num(41,45)

	static Float:vecEnd[3];get_tr2(tr,TR_vecEndPos,vecEnd)
	
	g_VecEndTrace=vecEnd
	
	engfunc(EngFunc_MessageBegin,MSG_PAS,SVC_TEMPENTITY,vecEnd,0)
	write_byte(TE_GUNSHOTDECAL)
	engfunc(EngFunc_WriteCoord,vecEnd[0])
	engfunc(EngFunc_WriteCoord,vecEnd[1])
	engfunc(EngFunc_WriteCoord,vecEnd[2])
	write_short(hit>0?hit:0)
	write_byte(Decal)
	message_end()
	
	static Float:WallVector[3];get_tr2(tr,TR_vecPlaneNormal,WallVector)
	
	engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,vecEnd,0);
	write_byte(TE_STREAK_SPLASH)
	engfunc(EngFunc_WriteCoord,vecEnd[0]);
	engfunc(EngFunc_WriteCoord,vecEnd[1]);
	engfunc(EngFunc_WriteCoord,vecEnd[2]);
	engfunc(EngFunc_WriteCoord,WallVector[0]*random_float(25.0,30.0));
	engfunc(EngFunc_WriteCoord,WallVector[1]*random_float(25.0,30.0));
	engfunc(EngFunc_WriteCoord,WallVector[2]*random_float(25.0,30.0));
	write_byte(111)
	write_short(12)
	write_short(3)
	write_short(75)	
	message_end()
	
	return FMRES_IGNORED
}
public HookFm_UpdateClientData(id,SendWeapons,CD_Handle){
	static item;item=get_pdata_cbase(id,pDataKey_iActiveItem,pData_Player)
	if(item<=0||!Is_CustomItem(item))return FMRES_IGNORED
	set_cd(CD_Handle,CD_flNextAttack,99999.0)
	return FMRES_HANDLED
}
public HookFm_Spawn(id){
	if(pev_valid(id)!=2)return FMRES_IGNORED
	static ClName[32];pev(id,pev_classname,ClName,31)
	if(strlen(ClName)<5)return FMRES_IGNORED
	static Trie:ClBuffer;if(!ClBuffer)ClBuffer=TrieCreate()
	if(!TrieKeyExists(ClBuffer,ClName)){
		TrieSetCell(ClBuffer,ClName,1)
		RegisterHamFromEntity(Ham_TakeDamage,id,"HookHam_TakeDamage",0)
	}
	return FMRES_IGNORED
}
stock make_weapon(){
	static ent;
	static g_AllocString_E;
	if(g_AllocString_E||(g_AllocString_E=engfunc(EngFunc_AllocString,weapon_name)))
		ent=engfunc(EngFunc_CreateNamedEntity,g_AllocString_E)
	else return 0
	if(ent<=0)return 0;
	set_pev(ent,pev_spawnflags,SF_NORESPAWN);
	set_pev(ent,pev_impulse,WEAPON_KEY);
	ExecuteHam(Ham_Spawn,ent)
	return ent
}
stock UTIL_DropWeapon(id,slot){
	static iEntity;iEntity=get_pdata_cbase(id,(pDataKey_iPlayerItems+slot),pData_Player);
	if(iEntity>0){
		static iNext,szWeaponName[32];
		do{
			iNext=get_pdata_cbase(iEntity,pDataKey_iNext,4);
			if(get_weaponname(get_pdata_int(iEntity,pDataKey_iId,4),szWeaponName,31))
				engclient_cmd(id,"drop",szWeaponName)
		} 
		while((iEntity=iNext)>0);
	}
}
stock Play_WeaponAnim(id,anim){
	set_pev(id,pev_weaponanim,anim)
	message_begin(MSG_ONE_UNRELIABLE,SVC_WEAPONANIM,_,id)
	write_byte(anim)
	write_byte(0)
	message_end()
}
stock Weaponlist(id,bool:set){
	if(!is_user_connected(id))return
	message_begin(MSG_ONE,Msg_WeaponList,_,id);
	write_string(set==false?weapon_name:weapon_new);
	write_byte(3);
	write_byte(weapon_bpammo);
	write_byte(-1);
	write_byte(-1);
	write_byte(0);
	write_byte(4);
	write_byte(20);
	write_byte(0);
	message_end();
}
stock get_weapon_position(id,Float:fOrigin[3],Float:add_forward=0.0,Float:add_right=0.0,Float:add_up=0.0){
	static Float:Angles[3],Float:ViewOfs[3],Float:vAngles[3]
	static Float:Forward[3],Float:Right[3],Float:Up[3]
	pev(id,pev_v_angle,vAngles)
	pev(id,pev_origin,fOrigin)
	pev(id,pev_view_ofs,ViewOfs)
	vec_add(fOrigin,ViewOfs,fOrigin)
	pev(id,pev_v_angle,Angles)
	engfunc(EngFunc_MakeVectors,Angles)
	global_get(glb_v_forward,Forward)
	global_get(glb_v_right,Right)
	global_get(glb_v_up,Up)
	vec_mul_scalar(Forward,add_forward,Forward)
	vec_mul_scalar(Right,add_right,Right)
	vec_mul_scalar(Up,add_up,Up)
	fOrigin[0]=fOrigin[0]+Forward[0]+Right[0]+Up[0]
	fOrigin[1]=fOrigin[1]+Forward[1]+Right[1]+Up[1]
	fOrigin[2]=fOrigin[2]+Forward[2]+Right[2]+Up[2]
}
vec_add(const Float:in1[],const Float:in2[],Float:out[]){
	out[0]=in1[0]+in2[0];
	out[1]=in1[1]+in2[1];
	out[2]=in1[2]+in2[2];
}
vec_mul_scalar(const Float:vec[],Float:scalar,Float:out[]){
	out[0]=vec[0]*scalar;
	out[1]=vec[1]*scalar;
	out[2]=vec[2]*scalar;
}
vec_normalize(const Float:vec[],Float:out[]){
	new Float:invlen=rsqrt(vec[0]*vec[0]+vec[1]*vec[1]+vec[2]*vec[2]);
	out[0]=vec[0]*invlen;
	out[1]=vec[1]*invlen;
	out[2]=vec[2]*invlen;
}
Float:rsqrt(Float:x){
	new Float:xhalf=x*0.5;
	
	new i=_:x;
	i=0x5f375a84 - (i>>1);
	x=Float:i;
			
	x=x*(1.5-xhalf*x*x);
	x=x*(1.5-xhalf*x*x);
	x=x*(1.5-xhalf*x*x);
		
	return x;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/

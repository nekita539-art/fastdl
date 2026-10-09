#include<amxmodx>
#include<fakemeta_util>
#include<hamsandwich>
#include<zombieplague>

#define weapon_name		"weapon_galil"

#define IDLE_TIME		2.00
#define DRAW_TIME		0.72
#define RELOAD_TIME		1.85
#define BUTTSTOCK_HIT_TIME      0.68
#define WALK_TIME               0.75

#define LunDiff_Player				5
#define LunDiff_Item				4

#define m_rgpPlayerItems_CWeaponBox		34

#define m_pPlayer				41
#define m_pNext				        42
#define m_iId				        43

#define m_flNextPrimaryAttack 		        46
#define m_flNextSecondaryAttack		        47
#define m_flTimeWeaponIdle		        48
#define m_iPrimaryAmmoType		        49
#define m_iClip				        51
#define m_fInReload			        54
#define m_fInSpecialReload			55
#define m_fWeaponState				74

#define m_LastHitGroup			        75
#define m_flNextAttack 			        83

#define m_rpgPlayerItems			367
#define m_pActiveItem			        373	
#define m_rgAmmo		 	        376
#define m_flEjectBrass                          111

#define m_szAnimExtention                       1968

#define WEAPON_KEY				42452724251
#define Is_CustomItem(%0)			(pev(%0,pev_impulse)==WEAPON_KEY)

#define model_v		"models/texas1k_extra/v_m4a1_born_beast.mdl"
#define model_p		"models/texas1k_extra/p_m4a1_born_beast.mdl"
#define model_w		"models/texas1k_extra/w_m4a1_born_beast.mdl"

#define weapon_punchangle		1.1		
#define weapon_damage			0.9				
#define weapon_aspeed			0.1		

#define weapon_ammo	38
#define weapon_bpammo	114
#define sound_shot	"texas1k_extra/m4a1_born_beast_fire1.wav"

new g_AllocString_V,g_AllocString_P;
new g_item;

enum{
	IDLE1=0,
	RELOAD1,
	DRAW1,
	FIRE1,
	BUTTSTOCK_HIT1,
	WALK1
}
public plugin_precache(){
	engfunc(EngFunc_PrecacheModel,model_v)
	engfunc(EngFunc_PrecacheModel,model_p)
	engfunc(EngFunc_PrecacheModel,model_w)
	g_AllocString_V=engfunc(EngFunc_AllocString,model_v)
	g_AllocString_P=engfunc(EngFunc_AllocString,model_p)
	
	register_clcmd("say /m4a1_born_beast","get_item");
	
	engfunc(EngFunc_PrecacheSound,sound_shot)
	
	engfunc(EngFunc_PrecacheSound,"crossfire/m4a1_born_beast_clip_in1.wav")
	engfunc(EngFunc_PrecacheSound,"crossfire/m4a1_born_beast_clip_out1.wav")
	engfunc(EngFunc_PrecacheSound,"crossfire/m4a1_born_beast_bolt_pull1.wav")
	
	register_forward(FM_Spawn,"HookFm_Spawn",0)
}
public plugin_init(){
	RegisterHam(Ham_Item_Deploy,weapon_name,"fw_Weapon_Deploy_Post",1)
	RegisterHam(Ham_Item_PostFrame,weapon_name,"fw_Weapon_PostFrame",0)
	
	RegisterHam(Ham_Weapon_Reload,weapon_name,"fw_Weapon_Reload",0)
	RegisterHam(Ham_Weapon_WeaponIdle,weapon_name,"fw_Weapon_WeaponIdle",0)
	RegisterHam(Ham_Weapon_PrimaryAttack,weapon_name,"fw_Weapon_PrimaryAttack",0)
	RegisterHam(Ham_TakeDamage,"player","fw_TakeDamage")
	
	g_item=zp_register_extra_item("\r[A] \wM4A1 Born Beast",110,ZP_TEAM_HUMAN);
	
	register_forward(FM_SetModel,"fw_SetModel")
	register_forward(FM_UpdateClientData,"fw_UpdateClientData_Post",1)
}
public get_item(id){
	UTIL_DropWeapon(id,1);
	new weapon=make_weapon();if(weapon<=0)return
	if(!ExecuteHamB(Ham_AddPlayerItem,id,weapon)){engfunc(EngFunc_RemoveEntity,weapon);return;}
	ExecuteHam(Ham_Item_AttachToPlayer,weapon,id)
	new ammotype=m_rgAmmo+get_pdata_int(weapon,m_iPrimaryAmmoType,LunDiff_Item)
	new ammo=get_pdata_int(id,ammotype,LunDiff_Player)
	if(ammo<weapon_bpammo)set_pdata_int(id,ammotype,weapon_bpammo,LunDiff_Player)
	set_pdata_int(weapon,m_iClip,weapon_ammo,LunDiff_Item)
	emit_sound(id,CHAN_ITEM,"items/gunpickup2.wav",VOL_NORM,ATTN_NORM,0,PITCH_NORM)
}
public zp_extra_item_selected(id,item){
	if(item==g_item)get_item(id);
}
public fw_Weapon_Deploy_Post(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED
	static id;id=get_pdata_cbase(ent,m_pPlayer,LunDiff_Item)

	set_pev_string(id,pev_viewmodel2,g_AllocString_V)
	set_pev_string(id,pev_weaponmodel2,g_AllocString_P)
	set_pdata_float(ent,m_flNextPrimaryAttack,DRAW_TIME,LunDiff_Item)
	set_pdata_float(ent,m_flNextSecondaryAttack,DRAW_TIME,LunDiff_Item)
	set_pdata_float(ent,m_flTimeWeaponIdle,DRAW_TIME,LunDiff_Item)
	Play_WeaponAnim(id,DRAW1)
	set_pdata_string(id,m_szAnimExtention,"rifle",-1,20);
	return HAM_IGNORED
}
public fw_Weapon_PostFrame(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED;
	static id;id=get_pdata_cbase(ent,m_pPlayer,LunDiff_Item);
	if(get_pdata_int(ent,m_fInReload,LunDiff_Item)==1){
		static clip,ammotype,ammo,j
		clip=get_pdata_int(ent,m_iClip,LunDiff_Item);
		ammotype=m_rgAmmo+ get_pdata_int(ent,m_iPrimaryAmmoType,LunDiff_Item);
		ammo=get_pdata_int(id,ammotype,LunDiff_Player);
		j=min(weapon_ammo-clip,ammo);
		set_pdata_int(ent,m_iClip,clip+j,LunDiff_Item);
		set_pdata_int(id,ammotype,ammo-j,LunDiff_Player);
		set_pdata_int(ent,m_fInReload,0,LunDiff_Item);
	}
	static curanim;curanim=pev(id,pev_weaponanim)
	static button;button=pev(id,pev_button)
	if(curanim==0&&button&IN_FORWARD||curanim==0&&button&IN_BACK||curanim==0&&button&IN_BACK||curanim==0&&button&IN_MOVELEFT||curanim==0&&button&IN_MOVERIGHT){ 
		Play_WeaponAnim(id,WALK1);
		set_pdata_float(ent,m_flTimeWeaponIdle,WALK_TIME,LunDiff_Item);
	}
	else ExecuteHamB(Ham_Weapon_WeaponIdle,ent)
	
	if(button&IN_ATTACK2&&get_pdata_float(ent,m_flNextPrimaryAttack,LunDiff_Item)<=0.0&&get_pdata_float(ent,m_flNextSecondaryAttack,LunDiff_Item)<=0.0&&get_pdata_float(id,m_flNextAttack,LunDiff_Player)<=0.0){
		static fakeent;fakeent=fm_find_ent_by_owner(-1,"weapon_knife",id);
		ExecuteHam(Ham_Weapon_SecondaryAttack,fakeent);
		Play_WeaponAnim(id,BUTTSTOCK_HIT1);
		set_pdata_float(ent,m_flTimeWeaponIdle,BUTTSTOCK_HIT_TIME,LunDiff_Item);
		set_pdata_float(ent,m_flNextPrimaryAttack,BUTTSTOCK_HIT_TIME,LunDiff_Item);
		set_pdata_float(ent,m_flNextSecondaryAttack,BUTTSTOCK_HIT_TIME,LunDiff_Item);
		set_pdata_float(id,m_flNextAttack,BUTTSTOCK_HIT_TIME,LunDiff_Player);
	}
	
	return HAM_IGNORED;
}
public fw_Weapon_Reload(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED;
	
	static clip;clip=get_pdata_int(ent,m_iClip,LunDiff_Item);
	if(clip>=weapon_ammo)return HAM_SUPERCEDE;
	
	static id;id=get_pdata_cbase(ent,m_pPlayer,LunDiff_Item);
	if(get_pdata_int(id,m_rgAmmo+get_pdata_int(ent,m_iPrimaryAmmoType,LunDiff_Item),LunDiff_Player)<=0)return HAM_SUPERCEDE
	
	set_pdata_int(ent,m_iClip,0,LunDiff_Item);
	ExecuteHam(Ham_Weapon_Reload,ent);
	set_pdata_int(ent,m_iClip,clip,LunDiff_Item);
	set_pdata_float(ent,m_flNextPrimaryAttack,RELOAD_TIME,LunDiff_Item)
	set_pdata_float(ent,m_flNextSecondaryAttack,RELOAD_TIME,LunDiff_Item)
	set_pdata_float(ent,m_flTimeWeaponIdle,RELOAD_TIME,LunDiff_Item)
	set_pdata_float(id,m_flNextAttack,RELOAD_TIME,LunDiff_Player) 
	
	Play_WeaponAnim(id,RELOAD1)
	return HAM_SUPERCEDE;
}
public fw_Weapon_WeaponIdle(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED
	if(get_pdata_float(ent,m_flTimeWeaponIdle,LunDiff_Item)>0.0)return HAM_IGNORED
	set_pdata_float(ent,m_flTimeWeaponIdle,IDLE_TIME,LunDiff_Item)
	Play_WeaponAnim(get_pdata_cbase(ent,m_pPlayer,LunDiff_Item),IDLE1)
	return HAM_SUPERCEDE
}
public fw_Weapon_PrimaryAttack(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED
	static ammo;ammo=get_pdata_int(ent,m_iClip,LunDiff_Item);
	if(ammo<=0){
		ExecuteHam(Ham_Weapon_PlayEmptySound,ent);
		set_pdata_float(ent,m_flNextPrimaryAttack,weapon_aspeed,LunDiff_Item)
		return HAM_SUPERCEDE
	}
		
	static id;id=get_pdata_cbase(ent,m_pPlayer,LunDiff_Item)
	static Float:user_punchangle[3];pev(id,pev_punchangle,user_punchangle)
	static fm_hooktrace;fm_hooktrace=register_forward(FM_TraceLine,"HookFm_TraceLine",true)
	static fm_playbackevent;fm_playbackevent=register_forward(FM_PlaybackEvent,"HookFm_PlayBackEvent",false)
	
	state FireBullets: Enabled;
	ExecuteHam(Ham_Weapon_PrimaryAttack,ent)
	state FireBullets: Disabled;
	
	unregister_forward(FM_TraceLine,fm_hooktrace,true)
	unregister_forward(FM_PlaybackEvent,fm_playbackevent,false)
	
	Play_WeaponAnim(id,FIRE1)
	emit_sound(id,CHAN_WEAPON,sound_shot,VOL_NORM,ATTN_NORM,0,PITCH_NORM)
	
	set_pdata_int(ent,m_iClip,ammo-1,LunDiff_Item)
	set_pdata_float(ent,m_flTimeWeaponIdle,2.0,LunDiff_Item)
	static Float:user_newpunch[3];pev(id,pev_punchangle,user_newpunch)
	
	user_newpunch[0]=user_punchangle[0]+(user_newpunch[0]-user_punchangle[0])*weapon_punchangle
	user_newpunch[1]=user_punchangle[1]+(user_newpunch[1]-user_punchangle[1])*weapon_punchangle
	user_newpunch[2]=user_punchangle[2]+(user_newpunch[2]-user_punchangle[2])*weapon_punchangle
	set_pev(id,pev_punchangle,user_newpunch)

	set_pdata_float(ent,m_flNextPrimaryAttack,weapon_aspeed,LunDiff_Item)
	
	return HAM_SUPERCEDE
}
public fw_TakeDamage(victim,inflictor,attacker,Float:damage)<FireBullets: Enabled>{ 
	SetHamParamFloat(4,damage*weapon_damage);
	return HAM_OVERRIDE;
}
public fw_TakeDamage()<FireBullets: Disabled>{ 
	return HAM_IGNORED;
}
public fw_TakeDamage()<>{
	return HAM_IGNORED;
}
public fw_SetModel(ent){ 
	static i,classname[32],item;pev(ent,pev_classname,classname,31);
	if(!equal(classname,"weaponbox"))return FMRES_IGNORED;
	for(i=0;i<6;i++){
		item=get_pdata_cbase(ent,m_rgpPlayerItems_CWeaponBox+i,LunDiff_Item);
		if(item>0&&Is_CustomItem(item)){
			engfunc(EngFunc_SetModel,ent,model_w);
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
public fw_UpdateClientData_Post(id,SendWeapons,CD_Handle){
	static item;item=get_pdata_cbase(id,m_pActiveItem,LunDiff_Player)
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
		RegisterHamFromEntity(Ham_TakeDamage,id,"fw_TakeDamage",0)
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
	static iEntity;iEntity=get_pdata_cbase(id,(m_rpgPlayerItems+slot),LunDiff_Player);
	if(iEntity>0){
		static iNext,szWeaponName[32];
		do{
			iNext=get_pdata_cbase(iEntity,m_pNext,LunDiff_Item);
			if(get_weaponname(get_pdata_int(iEntity,m_iId,LunDiff_Item),szWeaponName,31))
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/

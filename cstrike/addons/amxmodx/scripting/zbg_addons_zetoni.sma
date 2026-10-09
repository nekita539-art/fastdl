#include <amxmodx>
#include <amxmisc>
#include <nvault>
#include <hamsandwich>
#include <fakemeta_util>
#include <zombieplague>

#define PLUGIN 	"Money"
#define VERSION "1.0"
#define AUTHOR 	"HaSKe l Дмитрий Комаров"

#define MAXPLAYERS 32

new g_Money[ MAXPLAYERS + 1 ]

native zp_get_user_level(id)

new g_Nvault
new g_Health[ 33 ]
new g_Armor[ 33 ]
new g_Damage[ 33 ]

const START 	=	200
const HEALTH	=	20
const HP_COST	=	15

const ARMOR	=	5
const AP_COST	=	10

const DAMAGE	=	2
const DM_COST	=	20

new keys = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_0

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Killed, "player", "fw_Killed", 1)
	RegisterHam(Ham_Spawn, "player", "fw_Spawn", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage", 1)
	
	register_clcmd("shop_menu", "menu")
	
	register_menu("menu_key", keys, "menu_handler")
	
	register_dictionary("zbg_addons_zetoni.txt")
	
	g_Nvault = nvault_open("Gash")
}

public client_connect(id)
{
	g_Health[id] = 0
	g_Armor[id] = 0
	g_Damage[id] = 0
	g_Money[id] = 0
	
	LoadData(id)
}

public client_disconnect(id)
{
	SaveData(id)
	
	g_Health[id] = 0
	g_Armor[id] = 0
	g_Damage[id] = 0
	g_Money[id] = 0
}

public plugin_natives()
{
	register_native("zp_gash_show", "native_show", 1)
	register_native("zp_gash_set", "native_set", 1)
}

public native_show(id)
{
	return g_Money[id]
}

public native_set(id)
{
	g_Money[id] += 30
}

public fw_Killed(id, iKiller, iVictim)
{
	if(!is_user_connected(iVictim) || !is_user_connected(iKiller) && zp_get_user_zombie(iVictim))
                return HAM_IGNORED
		
	new name[32]
	get_user_name(iKiller, name, 31)
		
	g_Money[iKiller] += 1
	
	
	return HAM_IGNORED
}

public fw_Spawn(id)
{
	if(!is_user_connected(id))
		return
	
	if(!zp_get_user_zombie(id))
	{
		if(g_Health[id] >= 1)
		{
			fm_set_user_health(id, START + HEALTH*g_Health[id])
		}
		if(g_Armor[id] >= 1)
		{
			fm_set_user_armor(id, pev(id, pev_armorvalue) + ARMOR*g_Armor[id])
		}
	}
}

public fw_TakeDamage(id, victim, inflicator, attacker, damage)
{
	if(!is_user_connected(attacker))
		return
	
	if(victim == attacker || !victim)
		return
	
	if(g_Damage[id] >= 1)
	{
		SetHamParamFloat(4, damage *(3.0 * g_Damage[id]))
	}
}	

public menu(id)
{
	new text[512], iLen
	
	iLen = 0
	iLen = formatex(text[iLen], charsmax(text) - iLen, "%L^n^n", id, "MENU_NAME", g_Money[id])
	
	if(g_Money[id] >= HP_COST && g_Health[id] < 10){
		iLen += formatex(text[iLen], charsmax(text) - iLen, "%L^n", id, "MENU_KEY_1", g_Health[id], HP_COST)
		keys |= MENU_KEY_1
	} else {
		iLen += formatex(text[iLen], charsmax(text) - iLen, "%L^n", id, "MENU_KEY_1_D", g_Health[id], HP_COST)
		keys &= ~MENU_KEY_1
	}
	if(g_Money[id] >= AP_COST && g_Armor[id] < 15 && zp_get_user_level(id) > 5){
		iLen += formatex(text[iLen], charsmax(text) - iLen, "%L^n", id, "MENU_KEY_2", g_Armor[id], AP_COST)
		keys |= MENU_KEY_2
	} else {
		iLen += formatex(text[iLen], charsmax(text) - iLen, "%L^n", id, "MENU_KEY_2_D", g_Armor[id], AP_COST)
		keys &= ~MENU_KEY_2
	}
	if(g_Money[id] >= DM_COST && g_Damage[id] < 5 && zp_get_user_level(id) > 15){
		iLen += formatex(text[iLen], charsmax(text) - iLen, "%L^n^n", id, "MENU_KEY_3", g_Damage[id], DM_COST)
		keys |= MENU_KEY_3
	} else {
		iLen += formatex(text[iLen], charsmax(text) - iLen, "%L^n^n", id, "MENU_KEY_3_D", g_Damage[id], DM_COST)
		keys &= ~MENU_KEY_3
	}
	
	iLen += formatex(text[iLen], charsmax(text) - iLen, "%L^n^n", id, "MENU_KEY_4_D")
	keys |= MENU_KEY_3
	
	iLen += formatex(text[iLen], charsmax(text) - iLen, "^n\r[\y0\r]. \wВыход^n")
	keys |= MENU_KEY_0
		
	show_menu(id, keys, text, -1, "menu_key")
	return PLUGIN_HANDLED
}

public menu_handler(id, key)
{
	switch(key)
	{
		case 0: 
		{
			g_Money[id] -= HP_COST
			g_Health[id] ++
		}
		case 1: 
		{
			g_Money[id] -= AP_COST
			g_Armor[id] ++
		}
		case 2: 
		{
			g_Money[id] -= DM_COST
			g_Damage[id] ++
		}
		case 3: 
		{
			client_cmd(id, "open_yron")
		}
	}
	return PLUGIN_HANDLED
}

public SaveData(id)
{
	new AuthID[35]
	get_user_authid(id, AuthID, 34)
 
	new vaultkey[64], vaultdata[256]
	format(vaultkey, 63, "%s", AuthID)
	format(vaultdata, 255, "%i#%i#%i#%i#", g_Health[id], g_Armor[id], g_Damage[id], g_Money[id])
	nvault_set(g_Nvault, vaultkey, vaultdata)
	return PLUGIN_CONTINUE
}

public LoadData(id)
{
	new AuthID[35]
	get_user_authid(id, AuthID, 34)
 
	new vaultkey[64], vaultdata[256]
	format(vaultkey, 63, "%s", AuthID)
	format(vaultdata, 255, "%i#%i#%i#%i#", g_Health[id], g_Armor[id], g_Damage[id], g_Money[id])
	nvault_get(g_Nvault, vaultkey, vaultdata,255)
 
	replace_all(vaultdata, 255, "#", " ")
 
	new PlayerHP[32], PlayerAP[32], PlayerDM[32], PlayerMY[32]
 
	parse(vaultdata, PlayerHP, 31, PlayerAP, 31, PlayerDM, 31, PlayerMY, 31)
 
	g_Health[id] = str_to_num(PlayerHP)
	g_Armor[id] = str_to_num(PlayerAP)
	g_Damage[id] = str_to_num(PlayerDM)
	g_Money[id] = str_to_num(PlayerMY)
 
	return PLUGIN_CONTINUE
} 
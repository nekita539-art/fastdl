#include <amxmodx>
#include <nvault>

#define NAME			"texas1k_rub_system"
#define VERSION			"1.0"
#define AUTHOR			"Texas >3 | Александр Лейн"
#define FOR_ALL			"Система Рублей для Возмездие Зомби"

new g_rub[33]

new g_vault

public plugin_init()
{
	register_plugin(NAME, VERSION, AUTHOR)
	
	g_vault = nvault_open("Auto_Save_Rub")
}

public plugin_natives()
{
	register_native("zp_set_user_rub", "native_set_user_rub", 1)
	register_native("zp_get_user_rub", "native_get_user_rub", 1)
}

public native_set_user_rub(id, num)
{
	g_rub[id] = num
}

public native_get_user_rub(id)
{
	return g_rub[id]
}

public client_disconnect(id) 
{
	SaveData(id)
	
	g_rub[id] = 0
}

public client_connect(id)
{
	g_rub[id] = 0
	
	LoadData(id)
}

public plugin_end()
{
	nvault_close(g_vault)
}

public SaveData(id) 
{
	new AuthID[35]
	get_user_authid(id, AuthID, 34)
	
	new vaultkey[64], vaultdata[256]
	format(vaultkey, 63, "%s-cso", AuthID)
	format(vaultdata, 255, "%i#", g_rub[id])
	nvault_set(g_vault, vaultkey, vaultdata)
	
	return PLUGIN_CONTINUE
}

public LoadData(id) 
{
	new AuthID[35]
	get_user_authid(id, AuthID, 34)
	
	new vaultkey[64], vaultdata[256]
	format(vaultkey, 63, "%s-cso", AuthID)
	format(vaultdata, 255, "%i#", g_rub[id])
	nvault_get(g_vault, vaultkey, vaultdata, 255)
	
	replace_all(vaultdata, 255, "#", " ")
	
	new rub[32]
	
	parse(vaultdata, rub, 31)
	
	g_rub[id] = str_to_num(rub)
	
	return PLUGIN_CONTINUE
}
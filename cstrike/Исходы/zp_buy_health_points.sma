#include <amxmodx>
#include <fun>
#include <zombieplague>

new const item_name[] = "Жизни(\r+1000\w)"
new g_itemid_buyhp
new hpamount

public plugin_init() 
{
	register_plugin("[ZP] Buy Health Points", "1.0", "T[h]E Dis[as]teR")
	hpamount = register_cvar("zp_buyhp_amount", "1000")
	g_itemid_buyhp = zp_register_extra_item(item_name, 200, ZP_TEAM_ZOMBIE)
}
public zp_extra_item_selected(id,itemid)
{
	if(!is_user_alive(id))
	
	return PLUGIN_HANDLED;
	
	if(itemid==g_itemid_buyhp)
	{
		if(zp_get_user_ammo_packs(id) < 200)
		{
			client_print(id, print_chat,"[ZP] Не достаточно долларов!");
			return PLUGIN_HANDLED;
		}
		else
		{
			set_user_health(id,get_user_health(id)+get_pcvar_num(hpamount));
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) - 200);
			client_print(id, print_chat,"[ZP] Вы купили Жизни!");
		}
	}
	return PLUGIN_CONTINUE;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang3082\\ f0\\ fs16 \n\\ par }
*/

#include <amxmodx>
#include <fun>
#include <zombieplague>

new const item_name[] = "Жизни \y(+1500)"
new g_itemid_buyhp
new hpamount

public plugin_init() 
{
	register_plugin("[ZBG] Buy Health Points", "0.1", "SNAFFY")
	hpamount = register_cvar("zp_buyhp_amount", "1500")
	g_itemid_buyhp = zp_register_extra_item(item_name, 15, ZP_TEAM_ZOMBIE)
}
public zp_extra_item_selected(id,itemid)
{
	if(!is_user_alive(id))
	
	return PLUGIN_HANDLED;
	
	if(itemid==g_itemid_buyhp)
	{
		if(zp_get_user_ammo_packs(id) < 5)
		{
			client_print(id, print_chat,"[ZBG] Не хватает винтики!");
			return PLUGIN_HANDLED;
		}
		else
		{
			set_user_health(id,get_user_health(id)+get_pcvar_num(hpamount));
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) - 5);
			client_print(id, print_chat,"[ZBG] Вы купили здаровья!");
		}
	}
	return PLUGIN_CONTINUE;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang3082\\ f0\\ fs16 \n\\ par }
*/

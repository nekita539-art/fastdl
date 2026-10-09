#include <amxmisc>
#include <amxmodx>
#include <zombieplague>
#include <dhudmessage>

#define PLUGIN "[ZP] Addon: Extended Give Ammo 2.0"
#define VERSION "2.0"
#define AUTHOR "Yryry"

new g_msgSayText, admins[32],cur_add_amount1 = 10

public plugin_init()
{
	register_cvar("zp_ammo_ex", VERSION, FCVAR_SERVER|FCVAR_SPONLY);

	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_concmd("zp_ammo_menu", "menu_init",ADMIN_SLAY, "");
	register_concmd("zp_ammo_e_self", "give_ammo_e_self",ADMIN_SLAY, " - ammo_davalka_sebe <amount>");

	register_dictionary("zp_ammo_ex.txt");

	g_msgSayText = get_user_msgid("SayText");
}

public give_ammo_e (id, ammo)
{
	new user_ammo = zp_get_user_ammo_packs(id) + ammo

	zp_set_user_ammo_packs ( id, max ( 1, user_ammo) )

	return PLUGIN_HANDLED;
}

public give_ammo_e_self(id, level, cid)
{
	if ( !cmd_access ( id, level, cid, 2 ) )
	{
        	return PLUGIN_HANDLED;
    	}
	new amount[5];

	read_argv ( 1, amount, charsmax(amount));

	give_ammo_e( id, str_to_num(amount));

	new sebeammo = str_to_num(amount);

	get_user_name(id, admins, 31);

	client_printcolor(id, "/g[AP] /yВы взяли /t%i /tаммо паков!", sebeammo)

	return PLUGIN_HANDLED;
}

public menu_init(id){
	new MenuName[64]
	format(MenuName, 63, "\r%L", id, "AM")

	new menu = menu_create(MenuName, "menu_handler");

	new players[32], inum, tempid, ammo;

	get_players(players, inum);

	new nomer[10], name[32], pack[10], info[50]

	menu_additem(menu, "\wДать Евро", "45", 0);

	switch(cur_add_amount1){
		case 10:
		{
			menu_additem(menu, "\w10 Евро", "33", 0);
		}

		case 100:
		{
			menu_additem(menu, "\w100 Евро", "34", 0);
		}
	}

	for ( new i; i < inum; i++)
	{	
		tempid = players[i];
		ammo = zp_get_user_ammo_packs(tempid);
		get_user_name(tempid, name, 31);
		num_to_str(tempid, nomer, 9);
		num_to_str(ammo, pack, 9);
		
		if( get_user_flags(tempid) & ADMIN_SLAY )
		{
			format(info, 60, "%s  (\r%s \wammo)  \y[Админ]", name, pack);
		}else{
			format(info, 60, "%s  (\r%s \wammo) ", name, pack);
		}
		
		menu_additem(menu, info, nomer, ADMIN_SLAY);
	}

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);

	menu_display(id, menu, 0);
}

public menu_handler(id, menu, item){
	if ( item == MENU_EXIT )
	{
	menu_destroy(menu);
	return PLUGIN_HANDLED;
	}

	new data[6], iName[64];
	new access, callback;

	menu_item_getinfo(menu, item, access, data, 5, iName, 63, callback);

	new tempid = str_to_num(data);

	switch(tempid){
	case 33:
	{
	cur_add_amount1 = 100;
	menu_destroy(menu);
	menu_init(id);

	}
	case 35:
	{
	cur_add_amount1 = 10;
	menu_destroy(menu);
	menu_init(id);
	}

	case 39:
	{
	menu_destroy(menu);
	menu_init(id);

	}
	default:
	{
		if(is_user_connected(tempid)){
			give_ammo_e(tempid, cur_add_amount1);

			new Nick[32];
			get_user_name(tempid, Nick, 31);
			get_user_name(id, admins, 31);

			set_dhudmessage(0, 125, 200, -1.0, 0.4, 0, 0.0, 5.0, 1.0, 1.0 );
			show_dhudmessage(id, "Администратор %s дал вам %i аммо паков!", admins, cur_add_amount1);
		} else {
		menu_destroy(menu);
		menu_init(id);
		}
	}
	}


	return PLUGIN_HANDLED;
}

stock client_printcolor(id, const input[], any:...)
{
    static iPlayersNum[32], iCount; iCount = 1
    static szMsg[191]
    
    vformat(szMsg, charsmax(szMsg), input, 3)
    
    replace_all(szMsg, 190, "/g", "^4") // green txt
    replace_all(szMsg, 190, "/y", "^1") // orange txt
    replace_all(szMsg, 190, "/t", "^3") // team txt
    
    if(id) iPlayersNum[0] = id
    else get_players(iPlayersNum, iCount, "ch")
        
    for (new i = 0; i < iCount; i++)
    {
        if (is_user_connected(iPlayersNum[i]))
        {
            message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, iPlayersNum[i])
            write_byte(iPlayersNum[i])
            write_string(szMsg)
            message_end()
        }
    }
}

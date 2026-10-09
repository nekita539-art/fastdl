#include < amxmodx >

#define PLUGIN		"AmxModMenu"
#define VERSION		"1.0"
#define AUTHOR		"texas1k"

#define map_timer_change 		24

new g_Timer

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("adm_menu", "adm_menu")
	
	g_Timer = get_systime() + 60 * map_timer_change
}

public client_command(id) 
{
	new arg[13]
	read_argv(0, arg , 12)

	for (new a = 0; a < 34; a++) 
	{
		if(equal("amxmodmenu", arg)) 
		{
			client_cmd(id, "adm_menu")
			return PLUGIN_HANDLED
		} 
	}
	return PLUGIN_CONTINUE
}

public adm_menu(id) 
{
	new menu = menu_create("\r• \wAmxModMenu \r•", "menu_adm")
	new Buffer[512], Buffer2[512]
	
	if(get_user_flags(id) & ADMIN_RCON)
	menu_additem(menu, "Кикнуть","1")
	else
	menu_additem(menu, "\dКикнуть","1")
	
	if(get_user_flags(id) & ADMIN_RCON)
	menu_additem(menu, "Забанить","2")
	else
	menu_additem(menu, "\dЗабанить","2")
	
	if(get_user_flags(id) & ADMIN_RCON)
	menu_additem(menu, "Ударить/Убить","3")
	else
	menu_additem(menu, "\dУдарить/Убить","3")
	
	if(get_user_flags(id) & ADMIN_RCON)
	{
		if(g_Timer < get_systime())
		menu_additem(menu, "Сменить Карту","4")
		else
		{
		formatex(Buffer, charsmax(Buffer), "\dСменить Карту [\rПроиграно \y%d\r|\y%d \rмин\d]", map_timer_change - (g_Timer - get_systime()) / 60, map_timer_change)
		menu_additem(menu, Buffer,"4")
		}
	}
	else
	{
	menu_additem(menu, "\dСменить Карту","4")
	}
	
	if(get_user_flags(id) & ADMIN_RCON)
	{
		if(g_Timer < get_systime())
		menu_additem(menu, "Голосование за карту","5")
		else
		{
		formatex(Buffer2, charsmax(Buffer2), "\dГолосование за карту [\rПроиграно \y%d\r|\y%d \rмин\d]", map_timer_change - (g_Timer - get_systime()) / 60, map_timer_change)
		menu_additem(menu, Buffer2,"5")
		}
	}
	else
	{
	menu_additem(menu, "\dГолосование за карту","5")
	}
	
	menu_setprop(menu, MPROP_NEXTNAME, "Дальше")
	menu_setprop(menu, MPROP_BACKNAME, "Назад")
	menu_setprop(menu, MPROP_EXITNAME, "Выход")

	menu_display(id,menu,0)

	return PLUGIN_HANDLED
}
	 
public menu_adm(id, menu, item) 
{
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	     
	new data[6], iName[64], access, callback
	menu_item_getinfo(menu, item, access, data, 5, iName, 63, callback)
	     
	new key = str_to_num(data)

	switch(key)
	{
		case 1: if(get_user_flags(id) & ADMIN_RCON) client_cmd(id, "amx_kickmenu")// c
		case 2: if(get_user_flags(id) & ADMIN_RCON) client_cmd(id, "amx_banmenu")// d
		case 3: if(get_user_flags(id) & ADMIN_RCON) client_cmd(id, "amx_slapmenu")// e
		case 4:
		{
			if(get_user_flags(id) & ADMIN_RCON)
			{
				if (g_Timer < get_systime())
					client_cmd(id, "amx_mapmenu")
				else color_chat(id, "!yПроиграно %d/%d", map_timer_change - (g_Timer - get_systime()) / 60, map_timer_change)
			}
		}
		case 5:
		{
			if(get_user_flags(id) & ADMIN_RCON)
			{
				if (g_Timer < get_systime())
				client_cmd(id, "amx_votemapmenu")
				else color_chat(id, "!yПроиграно %d/%d", map_timer_change - (g_Timer - get_systime()) / 60, map_timer_change)
			}
		}
	}
	return PLUGIN_HANDLED
}

stock color_chat(const id, const input[], any:...)
{
	new count = 1, players[32];
	static msg[191];
	vformat(msg, 190, input, 3);
	
	replace_all(msg, 190, "!g", "^4");
	replace_all(msg, 190, "!y", "^1");
	replace_all(msg, 190, "!t", "^3");
	
	if (id) players[0] = id; else get_players(players, count, "ch");
	{
		for (new i = 0; i < count; i++)
		{
			if (is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}
}
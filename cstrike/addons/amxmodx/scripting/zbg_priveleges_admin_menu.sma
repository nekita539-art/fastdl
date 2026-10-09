#include < amxmodx >
#include < amxmisc >
#include < zombieplague >
#include < fakemeta_util >

#define FLAG ADMIN_LEVEL_B

native zp_exp_set(id, amount)
native give_weapon_jetpack(id)
native zp_gash_set(id, amount)

new g_Block[33][6]
new g_Data[32]

new keys = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_0

public plugin_init()
{
	register_plugin("[ZBG] Gold Menu", "1.0", "SNAFFY")
	
	register_clcmd("admin_weapons", "menu")
	register_menu("menu_key", keys, "menu_handler")
	
	register_logevent("RoundStart", 2, "1=Round_Start")
	
}
public client_authorized(id)
{
	if(is_user_admin(id))
	{
		new admin[32], pass[32], flags[32], x_access[32], x_days[32],bufferd[128],name[32], st[33]
		
		new iFiled = fopen("/addons/amxmodx/configs/users.ini","r");
		
		get_user_name(id, name, 31)
		get_user_authid(id, st, 32)
		
		while(!feof(iFiled))
		{
			fgets(iFiled,bufferd,255)
			trim(bufferd)
			
			if(bufferd[0]=='"')
			{		
				parse(bufferd, admin, 31, pass, 31, flags, 31, x_access, 31, x_days, 31)
	
				if(equal(admin, name) || equal(admin, st))
				{
					g_Data[id]=str_to_num(x_days)
					return PLUGIN_HANDLED
				}
			}
		}
		fclose(iFiled)	
	}
	return PLUGIN_HANDLED
}
public menu(id)
{
	if(is_user_alive(id))
	{
		if(!zp_get_user_zombie(id) & !zp_get_user_survivor(id))
		{
			menu_gold(id)
		}
	}
	return PLUGIN_HANDLED
}
public menu_gold(id)
{
	static text[512], iLen
	iLen = 0

	if(get_user_flags(id) & FLAG)
	{
		new name[32]
		get_user_name( id, name, 31)
	
		iLen = formatex(text[iLen], charsmax(text) - iLen, "\y[ZBG] \wПривет, \r%s^n\y[ZBG] \wАдмин Меню By Texasik Show^n\y[ZBG] \wОсталось: \y[\r%d\y] \wдней^n^n", name, g_Data[id])

		if(g_Block[id][0] == 0)
			iLen += formatex(text[iLen], charsmax(text) - iLen, "\r[\y1\r]. \d[\rВзять\d] \wЖизни + Броню \y[\r500\y]^n")
		else
			iLen += formatex(text[iLen], charsmax(text) - iLen, "\d[1]. [Взять] Жизни + Броню [500]^n")
		if(g_Block[id][1] < 2)
			iLen += formatex(text[iLen], charsmax(text) - iLen, "\r[\y2\r]. \d[\rВзять\d] \wДжетпак + Базуку^n")
		else
			iLen += formatex(text[iLen], charsmax(text) - iLen, "\d[2]. [Взять] Джетпак + Базуку^n")
		if(g_Block[id][2] == 0)
			iLen += formatex(text[iLen], charsmax(text) - iLen, "\r[\y3\r]. \d[\rВзять\d] \yГранаты \r(\y2\r)^n")
		else
			iLen += formatex(text[iLen], charsmax(text) - iLen, "\d[3]. [Взять] Гранаты (2)^n")
		if(g_Block[id][3] == 0)
			iLen += formatex(text[iLen], charsmax(text) - iLen, "\r[\y4\r]. \d[\rВзять\d] \wЖетоны \y[\r30\y]^n")
		else
			iLen += formatex(text[iLen], charsmax(text) - iLen, "\d[4]. [Взять] Жетоны [30]^n")
		if(g_Block[id][4] == 0)
			iLen += formatex(text[iLen], charsmax(text) - iLen, "\r[\y5\r]. \d[\rВзять\d] \wОпыт \y[\r20\y]^n")
		else
			iLen += formatex(text[iLen], charsmax(text) - iLen, "\d[5]. [Взять] Опыт [20]^n")
		if(g_Block[id][5] == 0)
			iLen += formatex(text[iLen], charsmax(text) - iLen, "\r[\y6\r]. \d[\rВзять\d] \wЕвро \y[\r3000\y]^n")
		else
			iLen += formatex(text[iLen], charsmax(text) - iLen, "\d[6]. [Взять] Евро [3000]^n")
		
		iLen += formatex(text[iLen], charsmax(text) - iLen, "^n^n\r[\y0\r]. \wВыход^n")
	}
	else
	{
		ChatColor(id, "!g[Меню Админа]!y У вас нет доступа, по поводу покупки!t Skype:!g texasik2002")
	}
	show_menu(id, keys, text, -1, "menu_key")
}
public menu_handler(id, key)
{
	switch(key)
	{
		case 0 :
		{
			if(g_Block[id][0] == 0)
			{
				g_Block[id][0]++
				fm_set_user_armor(id, pev(id, pev_armorvalue) + 500)
				fm_set_user_health(id, pev(id, pev_health) + 500)
				ChatColor(id, "!g[.:Админ-Меню:.] !yВы взяли !gЖизни + Броню")
			}
			else if(g_Block[id][0] > 0)
			{
				ChatColor(id, "!g[.:Админ-Меню:.] !yЖдите следующий раунд.")
			}
		}
		case 1 : 
		{
			new i_Player[32], i_Num
			get_players(i_Player, i_Num)
				
			for(new i = 0; i < i_Num; i++)
			{
				if(i_Player[i] >= 6)
				{
					if(g_Block[id][1] < 2)
					{
						g_Block[id][1]++
						give_weapon_jetpack(id)

						ChatColor(id, "!g[.:Админ-Меню:.] !yВы взяли !gДжетпак. !yОсталось взять еще !g[1] !yраз за карту.")
					}
					else if(g_Block[id][1] > 2)
					{	
						ChatColor(id, "!g[.:Админ-Меню:.] !yЖдите следующую карту.")
					}
				}
				else ChatColor(id, "!g[.:Админ-Меню:.] !yЗапрещено ! На сервере должно быть !g6 игроков!y, чтобы взять Джетпак.")
			}
		}
		case 2 :
		{
			if(g_Block[id][2] == 0)
			{
				g_Block[id][2]++
				fm_give_item(id, "weapon_flashbang")
				fm_give_item(id, "weapon_hegrenade")

				ChatColor(id, "!g[.:Админ-Меню:.] !yВы взяли !gГранаты")
			}
			else if(g_Block[id][0] > 0)
			{
				ChatColor(id, "!g[.:Админ-Меню:.] !yЖдите следующий раунд.")
			}
		}
		case 3 :
		{
			if(g_Block[id][3] == 0)
			{
				g_Block[id][3]++
				zp_gash_set(id, 30)

				ChatColor(id, "!g[.:Админ-Меню:.] !yВы взяли !g30 Жетонов")
			}
			else if(g_Block[id][3] > 0)
			{
				ChatColor(id, "!g[.:Админ-Меню:.] !yЖдите следующую карту.")
			}
		}
		case 4 :
		{
			if(g_Block[id][4] == 0)
			{
				g_Block[id][4]++
				zp_exp_set(id, 20)

				ChatColor(id, "!g[.:Админ-Меню:.] !yВы взяли !g20 Опыта")
			}
			else if(g_Block[id][4] > 0)
			{
				ChatColor(id, "!g[.:Админ-Меню:.] !yЖдите следующую карту.")
			}
		}
		case 5 :
		{
			if(g_Block[id][5] == 0)
			{
				g_Block[id][5]++
				zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + 3000)

				ChatColor(id, "!g[.:Админ-Меню:.] !yВы взяли !g3000 Евро")
			}
			else if(g_Block[id][5] > 0)
			{
				ChatColor(id, "!g[.:Админ-Меню:.] !yЖдите следующую карту.")
			}
		}
	}
	return PLUGIN_HANDLED
}
public RoundStart(id)
{
	for(new id = 0; id < 33; id++)
	{
		if(g_Block[id][0] > 0)
		{
			g_Block[id][0] -= 1
		}
		if(g_Block[id][2] > 0)
		{
			g_Block[id][2] -= 1
		}
	}
}
stock ChatColor(const id, const input[], any:...)
{
        new count = 1, players[32]
        static msg[191]
        vformat(msg, 190, input, 3)
       
        replace_all(msg, 190, "!g", "^4") // Green Color
        replace_all(msg, 190, "!y", "^1") // Default Color
        replace_all(msg, 190, "!t", "^3") // Team Color
       
        if (id) players[0] = id; else get_players(players, count, "ch")
        {
                for (new i = 0; i < count; i++)
                {
                        if (is_user_connected(players[i]))
                        {
                                message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
                                write_byte(players[i])
                                write_string(msg)
                                message_end()
                        }
                }
        }
}
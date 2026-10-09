#include < amxmodx >
#include < amxmisc >
#include < hamsandwich >
#include < zombieplague >

#define COST_EVRO_1		25000
#define COST_EVRO_2		50000
#define COST_EVRO_3		75000
#define COST_EVRO_4		100000

#define PLUGIN		"[ZP] Damage Menu"
#define VERSION 	"1.0"
#define AUTHOR 		"inf"

new g_Damage[33]

public plugin_init() 
{
        new mapname[32]
        get_mapname(mapname, charsmax(mapname))
        if(containi(mapname, "cs_assault_necro") != -1)
        {
        pause("ad")
        return
        }
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_TakeDamage, 	"player", 	"PlayerTakeDamage", 1)
	
	register_menu("DamageMenu", 1023, "menu_damage")
	
	
	register_clcmd("open_yron777", "OpenMenu")
}

public PlayerTakeDamage(victim, inflictor, attacker, Float:damage) 
{
	if(is_user_alive(attacker))
		g_Damage[attacker] += floatround(damage)
}

public OpenMenu(id) 
{
	if(!is_user_connected(id))
		return

	new name[32]
	static menu[512], iLen
	
	iLen = 0
	get_user_name(id, name, charsmax(name))
	
	iLen = formatex(menu[iLen], charsmax(menu) - iLen, "\y[ZM] \rОбменный \yцентр^n")
	iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\y[ZM] \wПривет, \y%s^n", name)
	iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\y[ZM] \wВаш урон: \r( \y%d \r)^n^n", g_Damage[id])
		
	if(g_Damage[id] >= COST_EVRO_1)
		iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\y1\r] \wКупить \r(\y100\r) \wЗолота: \r(\y%d\r) \wурона^n^n", COST_EVRO_1)
	else iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\y1\r] \dКупить \r(\y100\r) \dЗолота: \r(\y%d\r) \dурона^n^n", COST_EVRO_1)
	
	if(g_Damage[id] >= COST_EVRO_2)
		iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\y2\r] \wКупить \r(\y250\r) \wЗолота: \r(\y%d\r) \wурона^n^n", COST_EVRO_2)
	else iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\y2\r] \dКупить \r(\y250\r) \dЗолота: \r(\y%d\r) \dурона^n^n", COST_EVRO_2)
	
	if(g_Damage[id] >= COST_EVRO_3)
		iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\y3\r] \wКупить \r(\y500\r) \wЗолота: \r(\y%d\r) \wурона^n^n", COST_EVRO_3)
	else iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\y3\r] \dКупить \r(\y500\r) \dЗолота: \r(\y%d\r) \dурона^n^n", COST_EVRO_3)
	
	if(g_Damage[id] >= COST_EVRO_4)
		iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\y4\r] \wКупить \r(\y700\r) \wЗолота: \r(\y%d\r) \wурона^n^n", COST_EVRO_4)
	else iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\y4\r] \dКупить \r(\y700\r) \dЗолота: \r(\y%d\r) \dурона^n^n", COST_EVRO_4)
	
	iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\y0\r] \wВыход")

	show_menu(id, 1023, menu, -1, "DamageMenu")
}

public menu_damage(id, key) 
{
	switch(key) 
	{
		case 0:
		{
			if(g_Damage[id] < COST_EVRO_1)
			{
				ColorChat(id, "!y[.:!gЗатерянный-Мир!y:.] !gОшибка ! !tУ вас не хватает !g( !y%d !g) !y урона, чтобы купить !g( !y100 !g) !yЗолота.", (COST_EVRO_1-g_Damage[id]))
				OpenMenu(id) 
				return PLUGIN_HANDLED
			}
			g_Damage[id] -= COST_EVRO_1
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + 100)
			OpenMenu(id) 
		}
		case 1:
		{
			if(g_Damage[id] < COST_EVRO_2)
			{
				ColorChat(id, "!y[.:!gЗатерянный-Мир!y:.] !gОшибка ! !tУ вас не хватает !g( !y%d !g) !y урона, чтобы купить !g( !y250 !g) !yЗолота.", (COST_EVRO_2-g_Damage[id]))
				OpenMenu(id) 
				return PLUGIN_HANDLED
			}
			g_Damage[id] -= COST_EVRO_2
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + 250)
			OpenMenu(id) 
		}
		case 2:
		{
			if(g_Damage[id] < COST_EVRO_3)
			{
				ColorChat(id, "!y[.:!gЗатерянный-Мир!y:.] !gОшибка ! !tУ вас не хватает !g( !y%d !g) !y урона, чтобы купить !g( !y500 !g) !yЗолота.", (COST_EVRO_3-g_Damage[id]))
				OpenMenu(id) 
				return PLUGIN_HANDLED
			}
			g_Damage[id] -= COST_EVRO_3
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + 500)
			OpenMenu(id) 
		}
		case 3:
		{
			if(g_Damage[id] < COST_EVRO_4)
			{
				ColorChat(id, "!y[.:!gЗатерянный-Мир!y:.] !gОшибка ! !tУ вас не хватает !g( !y%d !g) !y урона, чтобы купить !g( !y700 !g) !yЗолота.", (COST_EVRO_4-g_Damage[id]))
				OpenMenu(id) 
				return PLUGIN_HANDLED
			}
			g_Damage[id] -= COST_EVRO_4
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + 700)
			OpenMenu(id) 
		}
	}
	return PLUGIN_HANDLED
}

stock ColorChat(const id, const input[], any:...)
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
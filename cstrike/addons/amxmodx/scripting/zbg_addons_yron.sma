#include < amxmodx >
#include < amxmisc >
#include < hamsandwich >
#include < zombieplague >

native zp_gash_set(id)
native zp_set_user_exp(id, num)
native zp_get_user_exp(id)

#define COST_GASH		250000
#define COST_EXP		100000
#define COST_EVRO		60000

#define PLUGIN		"[ZP] Damage Menu"
#define VERSION 	"1.0"
#define AUTHOR 		"Секрет)"

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
	
	
	register_clcmd("open_yron", "OpenMenu")
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
	
	iLen = formatex(menu[iLen], charsmax(menu) - iLen, "\y[ZBG] \rОбменный \yцентр^n")
	iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\y[ZBG] \wПривет, \y%s^n", name)
	iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\y[ZBG] \wВаш урон: \r( \y%d \r)^n^n", g_Damage[id])
	
	if(g_Damage[id] >= COST_GASH)
		iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\y1\r]. \wКупить \r(\y30\r) \wжетонов: \r(\y%d\r) \wурона^n", COST_GASH)
	else iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\y1\r]. \dКупить \r(\y30\r) \dжетонов: \r(\y%d\r) \dурона^n", COST_GASH)
	
	if(g_Damage[id] >= COST_EXP)
		iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\y2\r]. \wКупить \r(\y5\r) \wопыта: \r(\y%d\r) \wурона^n", COST_EXP)
	else iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\y2\r]. \dКупить \r(\y5\r) \dопыта: \r(\y%d\r) \dурона^n", COST_EXP)
	
	if(g_Damage[id] >= COST_EVRO)
		iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\y3\r]. \wКупить \r(\y500\r) \wопыта: \r(\y%d\r) \wурона^n^n", COST_EVRO)
	else iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\y3\r]. \dКупить \r(\y500\r) \dевро: \r(\y%d\r) \dурона^n^n", COST_EVRO)

        iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\y4\r]. \rПрокачка \yскиллов^n^n")
	
	iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\y0\r]. \wВыход")

	show_menu(id, 1023, menu, -1, "DamageMenu")
}

public menu_damage(id, key) 
{
	switch(key) 
	{
		case 0:
		{
			if(g_Damage[id] < COST_GASH)
			{
				ColorChat(id, "!y[.:!gZBG!y:.] !gОшибка ! !tУ вас не хватает !g( !y%d !g) !y урона, чтобы купить !g( !y30 !g) !yжетонов.", (COST_GASH-g_Damage[id]))
				OpenMenu(id) 
				return PLUGIN_HANDLED
			}
			g_Damage[id] -= COST_GASH
			zp_gash_set(id)
			OpenMenu(id) 
		}
		case 1:
		{
			if(g_Damage[id] < COST_EXP)
			{
				ColorChat(id, "!y[.:!gZBG!y:.] !gОшибка ! !tУ вас не хватает !g( !y%d !g) !y урона, чтобы купить !g( !y5 !g) !yопыта.", (COST_EXP-g_Damage[id]))
				OpenMenu(id) 
				return PLUGIN_HANDLED
			}
			g_Damage[id] -= COST_EXP
			zp_set_user_exp(id, zp_get_user_exp(id) + 5)
			OpenMenu(id) 
		}
		case 2:
		{
			if(g_Damage[id] < COST_EVRO)
			{
				ColorChat(id, "!y[.:!gZBG!y:.] !gОшибка ! !tУ вас не хватает !g( !y%d !g) !y урона, чтобы купить !g( !y500 !g) !yевро.", (COST_EVRO-g_Damage[id]))
				OpenMenu(id) 
				return PLUGIN_HANDLED
			}
			g_Damage[id] -= COST_EVRO
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + 500)
			OpenMenu(id) 
		}
		case 3:
		{
                client_cmd(id, "shop_menu")
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
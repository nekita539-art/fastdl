#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <zombieplague>
#include <dhudmessage>

new ammo[3][33],string[21],cvarShowType,ammopacks

public plugin_init() {
        new mapname[32]
        get_mapname(mapname, charsmax(mapname))
        if(containi(mapname, "cs_assault_necro") != -1)
        {
        pause("ad")
        return
        }
	register_plugin("[ZP] AmmoChange", "2.0", "ZETA [M|E|N]\Hunk(Editor)")
	register_logevent("round_start", 2, "1=Round_Start")
	cvarShowType = register_cvar("ac_show_type", "1")
	
	register_clcmd("say /change","func_change",ADMIN_ALL,"")
}

public round_start() {
	new players[32],num,i
	get_players(players,num)
	
	for(i=1;i<num;i++) {
		ammo[0][players[i]] = zp_get_user_ammo_packs(players[i])
	}
}

public client_putinserver(id) {
	set_task(3.0,"func_ammo",id)
}

public func_ammo(id) {
	ammopacks = zp_get_user_ammo_packs(id)
	
	ammo[0][id] = ammopacks
	ammo[1][id] = ammopacks
	ammo[2][id] = ammopacks
	
	set_task(1.0,"change_ammo",id,_,_,"b")
}

public change_ammo(id) {
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR)
		return PLUGIN_HANDLED
		
	ammo[1][id] = zp_get_user_ammo_packs(id)
		
	if(ammo[1][id] != ammo[2][id]) {
		if(ammo[1][id] > ammo[2][id]) {
			ammopacks = ammo[1][id] - ammo[2][id]
			format(string,charsmax(string),"[+%d Евро]", ammopacks)
		}
		else {
			ammopacks = ammo[2][id] - ammo[1][id]
			format(string,charsmax(string),"[-%d Евро]", ammopacks)
		}
		
		ammo[2][id] = ammo[1][id]
		
		if(get_pcvar_num(cvarShowType)) {
			set_dhudmessage(255, 255, 0, 0.42, 0.79, 0, 6.0, 1.0)
			show_dhudmessage(id, "%s", string)
		}
		else
			client_print(id, print_center, "%s", string)
	}
	
	return PLUGIN_HANDLED
}

public client_disconnect(id) {
	ammo[0][id] = 0
	ammo[1][id] = 0
	ammo[2][id] = 0
	
	remove_task(id)
}

public func_change(id) {
	if(ammo[0][id] != ammo[2][id]) {
		if(ammo[0][id] > ammo[2][id]) {
			ammopacks = ammo[0][id] - ammo[2][id]
			color_chat(id,"^1[^4.:Адские Зомби:.^1] ^1Ваше ^4[Евро] ^1уменьшилось на ^4%d.", ammopacks)
		}
		else {
			ammopacks = ammo[2][id] - ammo[0][id]
			color_chat(id,"^1[^4.:Адские Зомби:.^1] ^1Ваше ^4[Евро] ^1увеличилось на ^4%d.", ammopacks)
		}
	}
	else 
		color_chat(id,"^1[^4.:Адские Зомби:.^1] ^1Ваше ^4[Евро] ^1не изменилось.")
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/

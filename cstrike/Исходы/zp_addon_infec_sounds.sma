#include <amxmodx>
#include <zombieplague>

new g_infect[][] =
{
	"zombie_plague/re/infect_fear1.wav", "zombie_plague/re/infect_fear2.wav", "zombie_plague/re/infect_fear3.wav", "Reega_kz/allsounds/signal_inf1.wav", "Reega_kz/allsounds/signal_inf2.wav", "Reega_kz/allsounds/signal_inf3.wav"
}

public plugin_init()
{
	register_plugin("[ZN] Infect Human Sound", "1.0", "inf")
}

public plugin_precache()
{
	for(new i = 0; i < sizeof g_infect; i++) 
		precache_sound(g_infect[i])
}

public zp_user_infected_post(id, infector, nemesis)
{
	for(new i=1;i<=33;i++) {
		if(!is_user_connected(i)) continue
		if(!zp_get_user_zombie(i) && id != i) client_cmd(i,"speak ^"%s^"", g_infect[random_num(0, charsmax(g_infect))])
	}
}
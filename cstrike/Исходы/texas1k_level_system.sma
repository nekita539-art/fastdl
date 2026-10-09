#include < amxmodx >
#include < nvault >
#include < fakemeta >

#define 	PLUGIN_NAME			"Level__System"
#define 	PLUGIN_VERSION		"0.1"
#define 	PLUGIN_AUTHOR		"Bos93 & FirsT"

#define 	MAX_CLIENTS			32

#define ID_SHOWHUD (taskid - TASK_SHOWHUD)

enum (+= 100)
{
	TASK_SHOWHUD = 10
}

new const MAX_LEVELS[110] = 
{
	0,		//1
	25,		//2
	50,		//3
	77,		//4
	100,		//5
	140,		//6
	170,        //7
	200,        //8
	240,        //9
	280,        //10
	320,        //11
	360,        //12
	400,        //13
	450,        //14
	500,        //15
	550,        //16
	600,        //17
	650,        //18
	700,        //19
	750,        //20
	800,        //21
	850,        //22
	900,        //23
	950,        //24
	1000,        //25
	1100,        //26
	1200,        //27
	1300,        //28
	1400,        //29
	1500,        //30
	1600,        //31
	1700,        //32
	1800,        //33
	1900,        //34
	2000,        //35
	2100,        //36
	2200,        //37
	2300,        //38
	2400,        //39
	2500,        //40
	2600,        //41
	2700,        //42
	2800,        //43
	2900,        //44
	3000,        //45
	3100,        //46
	3200,        //47
	3300,        //48
	3400,        //49
	3500,        //50
	3600,        //51
	3700,        //52
	3800,        //53
	3900,        //55
	4000,        //56
	4100,        //57
	4200,        //58
	4300,        //59
	4400,        //60
	4500,        //61
	4600,        //62
	4700,        //63
	4800,        //64
	4900,        //65
	5000,        //66
	5100,        //67
	5200,        //68
	5300,        //69
	5400,        //70
	5500,        //71
	5600,        //72
	5700,        //73
	5800,        //74
	5900,        //75
	6000,        //76
	6100,        //77
	6200,        //78
	6300,        //79
	6400,        //80
	6500,        //81
	6600,        //82
	6700,        //83
	6800,        //84
	6900,        //85
	7000,        //86
	7100,        //87
	7200,        //88
	7300,        //89
	7400,        //90
	7500,        //91
	7600,        //92
	7700,        //93
	7800,        //94
	7900,        //95
	8000,        //96
	8100,        //97
	8200,        //98
	8300,        //99
	8400,        //100
	8500,        //101
	8600,        //102
	8700,        //103
	8800,        //104
	8900,        //105
	9000,        //106
	9100,        //107
	9200,        //108
	9300,        //109
	9400,        //110
}
const Float:HUD_STATS_X = 0.02;
const Float:HUD_STATS_Y = 0.9025;
const Float:HUD_SPECT_X = -1.0;
const Float:HUD_SPECT_Y = 0.8;

const PEV_SPEC_TARGET = pev_iuser2

new	g_iLevel[ MAX_CLIENTS + 1 ],
	g_iExp[ MAX_CLIENTS + 1 ],
	g_playername[ MAX_CLIENTS + 1 ][ MAX_CLIENTS ];

new g_vault

public plugin_init( )
{
	register_plugin ( PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR );

	register_event( "DeathMsg", "EV_DeathMsg", "a" );

	g_vault = nvault_open("Levels__System")
}

public plugin_natives() 
{

	register_native("zp_get_user_level", "native_get_user_level", 1)
	register_native("zp_set_user_level", "native_set_user_level", 1)

	register_native("zp_get_user_exp", "native_get_user_exp", 1)
	register_native("zp_set_user_exp", "native_set_user_exp", 1)
}

public client_disconnect(id) 
{
	SaveData(id);
}

public client_putinserver( iPlayer )
{
	get_user_name(iPlayer, g_playername[iPlayer], charsmax(g_playername[]))

	//set_task(1.0, "ShowHUD", iPlayer+TASK_SHOWHUD, _, _, "b")

	LoadData( iPlayer );
}

public plugin_end()
{
	nvault_close(g_vault)
}


public EV_DeathMsg( )
{
	static iVictim, iKiller;
	iVictim = read_data( 2 );
	iKiller = read_data( 1 );
	
	if( !is_user_connected( iVictim ) )
		return;
	
	if( iKiller == iVictim || !iKiller )
		return;

	g_iExp[ iKiller ] += 1;
	
	while( g_iExp[ iKiller ] >= MAX_LEVELS[ g_iLevel[ iKiller ] ] ) 
	{
		g_iLevel[ iKiller ] += 1;
	}


}

public ShowHUD(taskid) 
{

	static iPlayer
	iPlayer = ID_SHOWHUD;


	if (!is_user_alive( iPlayer )  )
	{
	
		iPlayer = pev(iPlayer, PEV_SPEC_TARGET)
		
		// Target not alive
		if (!is_user_alive(iPlayer) ) return;
	}
	
	if (iPlayer != ID_SHOWHUD)
	{
		set_hudmessage( 100, 100, 100, HUD_SPECT_X, HUD_SPECT_Y, 0, 5.0, 3.0, 1.0, 1.0, -1 );
		show_hudmessage( ID_SHOWHUD , "Наблюдение за: %s^n[Жизни: %d] [Уровень: %d] [Exp: %d / %d]", g_playername[ iPlayer ] , get_user_health(iPlayer), g_iLevel[ ID_SHOWHUD ] , g_iExp[ ID_SHOWHUD ] , (MAX_LEVELS[g_iLevel[ ID_SHOWHUD ]]) );
	}
	else
	{
		set_hudmessage( 0, 255, 0, HUD_STATS_X, HUD_STATS_Y, 0, 5.0, 3.0, 1.0, 1.0, -1 );
		show_hudmessage( ID_SHOWHUD , "[Жизни: %d] [Уровень: %d] [Exp: %d / %d]", get_user_health(iPlayer), g_iLevel[ ID_SHOWHUD ] , g_iExp[ ID_SHOWHUD ] , (MAX_LEVELS[g_iLevel[ ID_SHOWHUD ]]));
	}
}

public SaveData(id) {
	new AuthID[35]
	get_user_authid(id,AuthID,34)
	
	new vaultkey[64],vaultdata[256]
	format(vaultkey,63,"%s-cso",AuthID)
	format(vaultdata,255,"%i#%i#",g_iLevel[id],g_iExp[id])
	nvault_set(g_vault,vaultkey,vaultdata)
	
	return PLUGIN_CONTINUE
}

public LoadData(id) 
{
	new AuthID[35]
	get_user_authid(id,AuthID,34)
	
	new vaultkey[64],vaultdata[256]
	format(vaultkey,63,"%s-cso",AuthID)
	format(vaultdata,255,"%i#%i#",g_iLevel[id],g_iExp[id])
	nvault_get(g_vault,vaultkey,vaultdata,255)
	
	replace_all(vaultdata, 255, "#", " ")
	
	new experience[32], playerlevel[32]
	
	parse(vaultdata, experience, 31, playerlevel, 31)
	
	g_iLevel[id] = str_to_num(experience)
	g_iExp[id] = str_to_num(playerlevel)
	
	return PLUGIN_CONTINUE
}

public native_get_user_exp(id) 
{
	return g_iExp[id];
}

public native_set_user_exp(id, amount) 
{
	g_iExp[id] = amount;
}

public native_get_user_level(id) 
{
	return g_iLevel[id];
}

public native_set_user_level(id, amount) 
{
	g_iLevel[id] = amount;
}

stock color_print( const id , const input[], any:...) 
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)
	
	replace_all(msg, 190, "!g", "^4" ) // Green Color
	replace_all(msg, 190, "!y", "^1" ) // Default Color
	replace_all(msg, 190, "!team", "^3" ) // Team Color
	
	if (id) players[0] = id; else get_players(players, count, "ch")
	{
		for (new i = 0; i < count; i++) 
		{
			if (is_user_connected(players[i])) 
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText" ), _, players[i])
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}
}

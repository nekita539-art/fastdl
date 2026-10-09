#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <zombieplague>
#include <hamsandwich>

#define PLUGIN "Win HUD."
#define VERSION "0.1"
#define AUTHOR "SNAFFY"

new g_winh , g_winz , count , g_roundhud

stock __dhud_color;
stock __dhud_x;
stock __dhud_y;
stock __dhud_effect;
stock __dhud_fxtime;
stock __dhud_holdtime;
stock __dhud_fadeintime;
stock __dhud_fadeouttime;
stock __dhud_reliable;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")

	set_task (0.6,"showhud",_,_,_,"b");

	g_roundhud = 1
}

public plugin_precache()
{
	precache_sound("zbg/score/1.wav")
	precache_sound("zbg/score/2.wav")
	precache_sound("zbg/score/3.wav")
	precache_sound("zbg/score/4.wav")
	precache_sound("zbg/score/5.wav")
	precache_sound("zbg/score/6.wav")
	precache_sound("zbg/score/7.wav")
	precache_sound("zbg/score/8.wav")
	precache_sound("zbg/score/9.wav")
	precache_sound("zbg/score/10.wav")
	precache_sound("zbg/score/start1.mp3")
	precache_sound("zbg/score/start2.mp3")
        precache_sound("zbg/score/start3.mp3")
}

public event_roundstart()
{
	set_task(9.0,"start_countdown",1499)

	for (new i = 1; i <= get_maxplayers(); i++) 
	{
    		if (!is_user_connected(i))
		{
      			continue;
		}

		new snd = random_num(0, 2);
    		if (snd == 0)
		{
      			client_cmd(i,"mp3 play sound/zbg/score/start1.mp3")
		}
    		else if (snd == 1)
		{
      			client_cmd(i,"mp3 play sound/zbg/score/start2.mp3")
		}
		else if (snd == 2)
		{
			client_cmd(i,"mp3 play sound/zbg/score/start3.mp3")
		}
	}
	g_roundhud = g_winh + g_winz + 1
	count = 10
}

public start_countdown()
{
	remove_task(1499)
	remove_task(1500)
	set_task(1.0,"countdown",1500)
}

public countdown()
{
	if(count == 0) 
	{
		set_dhudmessage(0, 255, 252, -1.0, 0.22,  0, 1.0, 1.0,1.0,1.0)
		show_dhudmessage(0,"| ... Инфекция расходится ... |")
	}
	if(count > 0) 
	{
		set_dhudmessage(0, 255, 252, -1.0, 0.22,  0, 0.5, 0.5,0.5,0.5)
		if(count < 11) client_cmd(0,"spk  zbg/score/%d", count) 
		show_dhudmessage(0,"| ... Быстрее Прячемся ... |^n| ... До Первого Зараженного ... |^n | >>> %d <<< |",count)
	}
	count = count - 1
	if(count >= 0) set_task(1.0,"countdown",1500)
}

public showhud()
{
	new red , green , blue
	
	if(zp_is_nemesis_round())
	{
	red = 255
	green = 0
	blue = 0
	}else if(zp_is_survivor_round())
	{
	red = 0
	green = 0
	blue = 255
	}else if(!zp_has_round_started())
	{
	red = 150
	green = 154
	blue = 255
	}else{
	red = 150
	green = 154
	blue = 255
	}

	set_dhudmessage(red, green, blue, -1.0, 0.0, 0, 0.0, 0.01)
	show_dhudmessage(0, "Кол Зомби: %d | Кол.Людей: %d^n\-----[Кол.Побед: %d] | [Кол.Побед: %d]-----/^n|РАУНД: %d|" ,fn_get_zombies(),fn_get_humans(),g_winz,g_winh,g_roundhud)  
}

public zp_round_ended(winteam)
{
	if(winteam == WIN_ZOMBIES)
	{
		g_winz += 1 
	}else{
		g_winh += 1
	}	
}


fn_get_humans()
{
	static iAlive, id
	iAlive = 0
	
	for (id = 1; id <= 32; id++)
	{
		if (is_user_alive(id) && !zp_get_user_zombie(id))
			iAlive++
	}
	
	return iAlive;
}

fn_get_zombies()
{
	static iAlive, id
	iAlive = 0
	
	for (id = 1; id <= 32; id++)
	{
		if (is_user_alive(id) && zp_get_user_zombie(id))
			iAlive++
	}
	
	return iAlive;
}

stock set_dhudmessage( red = 0, green = 160, blue = 0, Float:x = -1.0, Float:y = 0.65, effects = 2, Float:fxtime = 0.6, Float:holdtime = 0.6, Float:fadeintime = 0.6, Float:fadeouttime = 0.6, bool:reliable = false )
{
    #define clamp_byte(%1)       ( clamp( %1, 0, 255 ) )
    #define pack_color(%1,%2,%3) ( %3 + ( %2 << 8 ) + ( %1 << 16 ) )

    __dhud_color       = pack_color( clamp_byte( red ), clamp_byte( green ), clamp_byte( blue ) );
    __dhud_x           = _:x;
    __dhud_y           = _:y;
    __dhud_effect      = effects;
    __dhud_fxtime      = _:fxtime;
    __dhud_holdtime    = _:holdtime;
    __dhud_fadeintime  = _:fadeintime;
    __dhud_fadeouttime = _:fadeouttime;
    __dhud_reliable    = _:reliable;

    return 1;
}

stock show_dhudmessage( index, const message[], any:... )
{
    new buffer[ 128 ];
    new numArguments = numargs();

    if( numArguments == 2 )
    {
        send_dhudMessage( index, message );
    }
    else if( index || numArguments == 3 )
    {
        vformat( buffer, charsmax( buffer ), message, 3 );
        send_dhudMessage( index, buffer );
    }
    else
    {
        new playersList[ 32 ], numPlayers;
        get_players( playersList, numPlayers, "ch" );

        if( !numPlayers )
        {
            return 0;
        }

        new Array:handleArrayML = ArrayCreate();

        for( new i = 2, j; i < numArguments; i++ )
        {
            if( getarg( i ) == LANG_PLAYER )
            {
                while( ( buffer[ j ] = getarg( i + 1, j++ ) ) ) {}
                j = 0;

                if( GetLangTransKey( buffer ) != TransKey_Bad )
                {
                    ArrayPushCell( handleArrayML, i++ );
                }
            }
        }

        new size = ArraySize( handleArrayML );

        if( !size )
        {
            vformat( buffer, charsmax( buffer ), message, 3 );
            send_dhudMessage( index, buffer );
        }
        else
        {
            for( new i = 0, j; i < numPlayers; i++ )
            {
                index = playersList[ i ];

                for( j = 0; j < size; j++ )
                {
                    setarg( ArrayGetCell( handleArrayML, j ), 0, index );
                }

                vformat( buffer, charsmax( buffer ), message, 3 );
                send_dhudMessage( index, buffer );
            }
        }

        ArrayDestroy( handleArrayML );
    }

    return 1;
}

stock send_dhudMessage( const index, const message[] )
{
    message_begin( __dhud_reliable ? ( index ? MSG_ONE : MSG_ALL ) : ( index ? MSG_ONE_UNRELIABLE : MSG_BROADCAST ), SVC_DIRECTOR, _, index );
    {
        write_byte( strlen( message ) + 31 );
        write_byte( DRC_CMD_MESSAGE );
        write_byte( __dhud_effect );
        write_long( __dhud_color );
        write_long( __dhud_x );
        write_long( __dhud_y );
        write_long( __dhud_fadeintime );
        write_long( __dhud_fadeouttime );
        write_long( __dhud_holdtime );
        write_long( __dhud_fxtime );
        write_string( message );
    }
    message_end();
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/

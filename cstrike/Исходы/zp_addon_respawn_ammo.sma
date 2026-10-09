#include <amxmodx>
#include <amxmisc> 
#include <fakemeta>
#include <zombieplague>

#define PLUGIN	"[ZP: Respawn Menu]"
#define VERSION	"0.2"
#define AUTHOR	"Phantom"

new cvar_respawn_humans_cost, cvar_respawn_zombies_cost 
new SayText

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_clcmd("res", "respawn", ADMIN_ALL, "respawn")
	register_clcmd("/res", "respawn", ADMIN_ALL, "respawn")
	register_clcmd("say /res", "respawn", ADMIN_ALL, "respawn")

	cvar_respawn_humans_cost = register_cvar("zp_respawn_humans_cost", "0")
	cvar_respawn_zombies_cost = register_cvar("zp_respawn_zombies_cost", "3")

        SayText = get_user_msgid("SayText")   

	register_dictionary("respawn_ammo.txt")
}

public respawn(id)
{
	new szMenuMulti[64]

	formatex(szMenuMulti, 63, "%L", id, "TITLE_MENU") 
	new menu = menu_create( szMenuMulti, "menu_handler")

	formatex(szMenuMulti, 63, "%L", id, "HUMAN_TEAM")
	menu_additem(menu, szMenuMulti, "1",0)

	formatex(szMenuMulti, 63, "%L", id, "ZOMBIE_TEAM")
	menu_additem(menu, szMenuMulti , "2",0)
 
	formatex(szMenuMulti,63, "%L", id, "EXIT")
        menu_setprop(menu, MPROP_EXIT, szMenuMulti)
    
	menu_display(id, menu, 0); 
		
	return PLUGIN_HANDLED
}

public menu_handler(id, menu, item)
{
    	if( item == MENU_EXIT )
   	{
        	menu_destroy(menu);
        	return PLUGIN_HANDLED;    
    	}
    
    	new data[6], iName[64];
    	new access, callback;
    
    	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
    
    	new key = str_to_num(data);
    
    	switch(key)
	{
        	case 1:
       		{	
			if(zp_get_user_ammo_packs(id)< get_pcvar_num(cvar_respawn_humans_cost))
			{
				print_color(id, "%L", id, "NO_MONEY")
				return PLUGIN_HANDLED			
			}

			if(zp_is_survivor_round() && !is_user_alive(id))
			{
				print_color(id, "%L", id, "ZOMBIES_ONLY")
				return PLUGIN_HANDLED
			}
			
			if(~get_user_flags(id) & ADMIN_LEVEL_F)
			{
				client_print(id,print_chat,"Только Арканы могут возрождаться за людей")
				return PLUGIN_HANDLED
			}
	
			if(!is_user_alive(id))
			{
				zp_respawn_user(id, ZP_TEAM_HUMAN)
				zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) - get_pcvar_num(cvar_respawn_humans_cost))
				set_task(1.0, "respawn1_message", id )
			}


           	 	menu_destroy(menu);
            		return PLUGIN_HANDLED
    		}

        	case 2:
        	{
			if(zp_get_user_ammo_packs(id)< get_pcvar_num(cvar_respawn_zombies_cost))
			{
				print_color(id, "%L", id, "NO_MONEY")
				return PLUGIN_HANDLED			
			}

			if(zp_is_nemesis_round() && !is_user_alive(id))
			{
				print_color(id, "%L", id, "HUMANS_ONLY")
				return PLUGIN_HANDLED
			}
	
			if(!is_user_alive(id))
			{
				zp_respawn_user(id, ZP_TEAM_ZOMBIE)
				zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) - get_pcvar_num(cvar_respawn_zombies_cost))
      			 	print_color(id, "%L", id, "PLAYER_RESPAWN")
       			 	set_task( 1.0 , "respawn2_message", id )
       				return PLUGIN_HANDLED
			}
				

			menu_destroy(menu);
			return PLUGIN_HANDLED
		}

	}
    	menu_destroy(menu);
    	return PLUGIN_HANDLED
}

public respawn1_message( id )
{
    new szName[ 32 ]
    get_user_name( id, szName, 31 )
    set_hudmessage( 255, 0, 0, 0.05, 0.45, 1, 0.0, 5.0, 1.0, 1.0, -1 )
    show_hudmessage( 0, "%s %L", szName, LANG_PLAYER, "RESPAWN" )
}

public respawn2_message( id )
{
    new szName[ 32 ]
    get_user_name( id, szName, 31 )
    set_hudmessage( 255, 0, 0, 0.05, 0.45, 1, 0.0, 5.0, 1.0, 1.0, -1 )
    show_hudmessage( 0, "%s %L", szName, LANG_PLAYER, "RESPAWN" )
}

stock print_color(const id, const input[], any:...)  
{  
	new count = 1, players[32];  
    	static msg[191];  
    	vformat(msg, 190, input, 3);  
    	replace_all(msg, 190, "!g", "^4"); // Green Color  
    	replace_all(msg, 190, "!y", "^1"); // Default Color 
    	replace_all(msg, 190, "!t", "^3"); // Team Color  
    	if (id) players[0] = id; else get_players(players, count, "ch");  
    	{  
        	for ( new i = 0; i < count; i++ )  
        	{  
            		if ( is_user_connected(players[i]) )  
            		{  
                		message_begin(MSG_ONE_UNRELIABLE, SayText, _, players[i]);  
                		write_byte(players[i]);  
                		write_string(msg);  
                		message_end();  
            		}  
        	}  
    	}  
}   
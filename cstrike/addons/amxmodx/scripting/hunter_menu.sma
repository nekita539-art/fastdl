#include < amxmodx >
#include < cstrike >
#include < zombieplague >
#include < fun >
#include < fakemeta >

native give_buffm4(id)
native give_buffak(id)
native give_buffsg(id)
native give_railgun(id)

native zp_force_open_admenu(id)

new const PLUGIN_INFO[ ] =
{
	"buff menu",
	"1.0",
	"inf"
}

enum _: pOptionVIP
{
	PAKI,
	ARMOR,
	HP
}

new g_menuVipBlock[ 33 ] [ pOptionVIP ]

new g_menuBlockWeapon[ 33 ]
new g_menuBlockWeapon2[ 33 ]
new g_menuBlockWeapon3[ 33 ]
new g_menuBlockWeapon4[ 33 ]

public plugin_init( ) 
{
	register_plugin( PLUGIN_INFO[ 0 ] , PLUGIN_INFO[ 1 ] , PLUGIN_INFO [ 2 ] )

	register_clcmd("/hunter_menu" , "ClCmd_VipMenu" )

	register_event( "HLTV" , "event_round_start" , "a" , "1=0" , "2=0" )
}

public event_round_start( pPlayer )
{
	for(new i = 0; i < 33; i++)
	{
		if(is_user_connected(i))
		{
			if(g_menuVipBlock[i][ARMOR] >= 1) g_menuVipBlock[i][ARMOR] = 0
			if(g_menuVipBlock[i][HP] >= 1) g_menuVipBlock[i][HP] = 0


			if(g_menuBlockWeapon[i] >= 1) g_menuBlockWeapon[i] = 0
			if(g_menuBlockWeapon2[i] >= 1) g_menuBlockWeapon2[i] = 0
			if(g_menuBlockWeapon3[i] >= 1) g_menuBlockWeapon3[i] = 0
			if(g_menuBlockWeapon4[i] >= 1) g_menuBlockWeapon4[i] = 0
		}
	}
}

public ClCmd_VipMenu( pPlayer ) 
{
	if(zp_get_user_survivor(pPlayer) || zp_get_user_nemesis(pPlayer))
	return;

	new g_AdminMenu = menu_create( "\y[ZM] \wМеню \d[\yОхотника\d]" , "ClCmd_VipMenu_Handler" )

	if( get_user_flags( pPlayer ) & ADMIN_CVAR  && !zp_get_user_zombie(pPlayer) && is_user_alive(pPlayer))
	menu_additem( g_AdminMenu , "\w[\yОткрыть\w] \wОружки" , "1" )
	else
	menu_additem( g_AdminMenu , "\d[Открыть] Оружки" , "1" )	
	
	if( get_user_flags( pPlayer ) & ADMIN_CVAR && g_menuVipBlock[ pPlayer ] [ PAKI ] < 1 )
	menu_additem( g_AdminMenu , "\w[\yВзять\w] \wЗолота \w[\y+1337\w]" , "2" , ADMIN_CVAR )
	else
	menu_additem( g_AdminMenu , "\d[Взять] Золота [+1337]" , "2" , ADMIN_CVAR )

	if( get_user_flags( pPlayer ) & ADMIN_CVAR && g_menuVipBlock[ pPlayer ] [ ARMOR ] < 1  && !zp_get_user_zombie(pPlayer) && is_user_alive(pPlayer))
	menu_additem( g_AdminMenu , "\w[\yВзять\w] \wБроню \w[\y+500\w]" , "3" , ADMIN_CVAR )
	else
	menu_additem( g_AdminMenu , "\d[Взять] Броню [+500]" , "3" , ADMIN_CVAR )
	
	if( get_user_flags( pPlayer ) & ADMIN_CVAR && g_menuVipBlock[ pPlayer ] [ HP ] < 1  && is_user_alive(pPlayer))
	menu_additem( g_AdminMenu , "\w[\yВзять\w] \wЖизни \w[\y+500\w]" , "4" , ADMIN_CVAR )
	else
	menu_additem( g_AdminMenu , "\d[Взять] Жизнь [+500]" , "4" , ADMIN_CVAR )
	
	if( get_user_flags( pPlayer ) & ADMIN_CVAR )
	menu_additem( g_AdminMenu , "Управление \w[\yМодом\w]" , "5" , ADMIN_CVAR )	
	else
	menu_additem( g_AdminMenu , "\dУправление [Модом]" , "5" , ADMIN_CVAR )	
	
	if( get_user_flags( pPlayer ) & ADMIN_CVAR )
	menu_additem( g_AdminMenu , "\wУправление \w[\yAmxModMenu\w]" , "6" , ADMIN_CVAR )	
	else
	menu_additem( g_AdminMenu , "\dУправление AmxModMenu]" , "6" , ADMIN_CVAR )	

	if( ! ( get_user_flags( pPlayer ) & ADMIN_CVAR ) )
	menu_setprop( g_AdminMenu , MPROP_EXITNAME , "Выход^n\rТы не Шредер!" )
	else
	menu_setprop( g_AdminMenu , MPROP_EXITNAME , "Выход" )	

	menu_setprop( g_AdminMenu , MPROP_EXIT , MEXIT_ALL )

	menu_display( pPlayer , g_AdminMenu , 0 )	
}

public ClCmd_VipMenu_Handler( pPlayer , pMenu, pItem )
{
	if ( pItem == MENU_EXIT || ~get_user_flags( pPlayer ) & ADMIN_CVAR)
	{
		menu_destroy( pMenu )
		return PLUGIN_HANDLED;
	}

	new pData[ 6 ], pName[ 64 ], pAccess, pCallback

	menu_item_getinfo( pMenu , pItem , pAccess , pData , charsmax( pData ) , pName , charsmax( pName ) , pCallback )

	new pKey = str_to_num( pData )

	switch( pKey )
	{
	case 1:
		{		
			if(zp_get_user_zombie(pPlayer) || !is_user_alive(pPlayer))
			{
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}
			weapon_menu_vip( pPlayer )
			menu_destroy( pMenu )
			return PLUGIN_HANDLED
		}
	case 2:
		{
			if(g_menuVipBlock[ pPlayer ] [ PAKI ] >= 1)
			{
				PrintChatColor( pPlayer ,  "!yНа этой карте ты уже не можешь брать !gПаки!y!" )
				ClCmd_VipMenu( pPlayer ) 
				return PLUGIN_HANDLED;
			}

			zp_set_user_ammo_packs( pPlayer , zp_get_user_ammo_packs( pPlayer ) + 1337 )
			PrintChatColor( pPlayer ,  "!yТы взял !g[Паки]!y!" )
			g_menuVipBlock[ pPlayer ] [ PAKI ]++
			ClCmd_VipMenu( pPlayer ) 
		}
	case 3:
		{
			if(zp_get_user_zombie(pPlayer) || !is_user_alive(pPlayer))
			{
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}

			if(get_user_armor(pPlayer) >= 500)
			{
				PrintChatColor( pPlayer ,  "!yУ вас максимально !gБрони" )
				set_user_armor(pPlayer, 500)
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}

			if(g_menuVipBlock[ pPlayer ] [ ARMOR ] >= 1)
			{
				PrintChatColor( pPlayer ,  "!yВ этом раунде ты уже не можешь брать !gБроню" )
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}

			set_pev(pPlayer, pev_armorvalue, float(min(pev(pPlayer, pev_armorvalue)+500, 500)))
			PrintChatColor( pPlayer ,  "!yТы взял !g[Броню]" )
			g_menuVipBlock[ pPlayer ] [ ARMOR ]++
			ClCmd_VipMenu( pPlayer )
		}
	case 4:
		{
			if(!is_user_alive(pPlayer))
			{
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}
			if(g_menuVipBlock[ pPlayer ] [ HP ] >=1)
			{
				PrintChatColor( pPlayer ,  "!yВ этом раунде ты уже не можешь брать !gЖизни" )
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}

			set_user_health( pPlayer , get_user_health( pPlayer ) + 500 )
			PrintChatColor( pPlayer ,  "!yТы взял !g[Жизни]" )
			g_menuVipBlock[ pPlayer ] [ HP ]++
			ClCmd_VipMenu( pPlayer )
        }
	case 5:
		{
			zp_force_open_admenu( pPlayer )
			menu_destroy( pMenu )
			return PLUGIN_HANDLED
		}
	case 6:
		{
			client_cmd( pPlayer , "amxmodmenu" )
			menu_destroy( pMenu )
			return PLUGIN_HANDLED		
		}		
	}

	menu_destroy( pMenu )
	return PLUGIN_HANDLED
}

public weapon_menu_vip( pPlayer ) 
{
	new g_AdminMenu = menu_create( "\y~|\rОружия\y|~" , "weapon_menu_vip_Handler" )
	
	if( get_user_flags( pPlayer ) & ADMIN_CVAR && g_menuBlockWeapon[ pPlayer ] < 1 )	
	menu_additem( g_AdminMenu , "\w[\yВзять\w] \wРыцарь" , "1" , ADMIN_CVAR )
	else
	menu_additem( g_AdminMenu , "\d[Тёмный Рыцарь]" , "1" , ADMIN_CVAR )

	if( get_user_flags( pPlayer ) & ADMIN_CVAR && g_menuBlockWeapon2[ pPlayer ] < 1 )	
	menu_additem( g_AdminMenu , "\w[\yВзять\w] \wПаладин" , "2" , ADMIN_CVAR )
	else
	menu_additem( g_AdminMenu , "\d[Паладин]" , "2" , ADMIN_CVAR )
	
	if( get_user_flags( pPlayer ) & ADMIN_CVAR && g_menuBlockWeapon3[ pPlayer ] < 1 )	
	menu_additem( g_AdminMenu , "\w[\yВзять\w] \wЛикантроп" , "3" , ADMIN_CVAR )
	else
	menu_additem( g_AdminMenu , "\d[Ликантроп]" , "3" , ADMIN_CVAR )
	
	if( get_user_flags( pPlayer ) & ADMIN_CVAR && g_menuBlockWeapon4[ pPlayer ] < 1 )	
	menu_additem( g_AdminMenu , "\w[\yВзять\w] \wРельсу" , "4" , ADMIN_CVAR )
	else
	menu_additem( g_AdminMenu , "\d[Рельсу]" , "4" , ADMIN_CVAR )
	
	menu_setprop( g_AdminMenu , MPROP_EXITNAME , "Выход" )

	menu_setprop( g_AdminMenu , MPROP_EXIT , MEXIT_ALL )

	menu_display( pPlayer , g_AdminMenu , 0 )	
}

public weapon_menu_vip_Handler( pPlayer , pMenu, pItem )
{
	if ( pItem == MENU_EXIT || ~get_user_flags( pPlayer ) & ADMIN_CVAR)
	{
		menu_destroy( pMenu )
		return PLUGIN_HANDLED;
	}

	new pData[ 6 ], pName[ 64 ], pAccess, pCallback

	menu_item_getinfo( pMenu , pItem , pAccess , pData , charsmax( pData ) , pName , charsmax( pName ) , pCallback )

	new pKey = str_to_num( pData )

	switch( pKey )
	{
	case 1:
		{
			if(!is_user_alive(pPlayer))
			return PLUGIN_HANDLED;

			if(g_menuBlockWeapon[ pPlayer ] >= 1)
			{
				PrintChatColor( pPlayer ,  "!yВы уже брали оружие в этом раунде!" )
				weapon_menu_vip( pPlayer ) 
				return PLUGIN_HANDLED
			}

			give_buffm4(pPlayer)
			PrintChatColor( pPlayer ,  "!yТы взял !g[Тёмный Рыцарь]!y!" )
			g_menuBlockWeapon[ pPlayer ]++
			weapon_menu_vip( pPlayer )
			return PLUGIN_HANDLED
		}
	case 2:
		{
			if(!is_user_alive(pPlayer))
			return PLUGIN_HANDLED;

			if(g_menuBlockWeapon2[ pPlayer ] >= 1)
			{
				PrintChatColor( pPlayer ,  "!yВы уже брали оружие в этом раунде!" )
				weapon_menu_vip( pPlayer ) 
				return PLUGIN_HANDLED
			}

			give_buffak(pPlayer)
			PrintChatColor( pPlayer ,  "!yТы взял !g[Паладин]!y!" )
			g_menuBlockWeapon2[ pPlayer ]++
			weapon_menu_vip( pPlayer )
			return PLUGIN_HANDLED
		}
		case 3:
		{
			if(!is_user_alive(pPlayer))
			return PLUGIN_HANDLED;

			if(g_menuBlockWeapon3[ pPlayer ] >= 1)
			{
				PrintChatColor( pPlayer ,  "!yВы уже брали оружие в этом раунде!" )
				weapon_menu_vip( pPlayer ) 
				return PLUGIN_HANDLED
			}

			give_buffsg(pPlayer)
			PrintChatColor( pPlayer ,  "!yТы взял !g[Ликантроп]!y!" )
			g_menuBlockWeapon3[ pPlayer ]++
			weapon_menu_vip( pPlayer )
			return PLUGIN_HANDLED
		}
		case 4:
		{
			if(!is_user_alive(pPlayer))
			return PLUGIN_HANDLED;

			if(g_menuBlockWeapon4[ pPlayer ] >= 1)
			{
				PrintChatColor( pPlayer ,  "!yВы уже брали оружие в этом раунде!" )
				weapon_menu_vip( pPlayer ) 
				return PLUGIN_HANDLED
			}

			give_railgun(pPlayer)
			PrintChatColor( pPlayer ,  "!yТы взял !g[Рельсу]!y!" )
			g_menuBlockWeapon4[ pPlayer ]++
			weapon_menu_vip( pPlayer )
			return PLUGIN_HANDLED
		}
	}

	menu_destroy( pMenu )
	return PLUGIN_HANDLED
}

stock PrintChatColor( const id , const input[], any:...) 
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
#include < amxmodx >
#include < cstrike >
#include < zombieplague >
#include < fun >
#include < fakemeta >

native give_crossbow(id)
native give_weapon_m4a1gold(id)
native give_weapon_ak47gold(id)
native give_weapon_sl8g(id)
native give_weapon_deagleg(id)
native give_weapon_dbarrel_cso(id)

native zp_gash_set(id, amount)

new const PLUGIN_INFO[ ] =
{
	"vip menu" ,
	"5.4" ,
	"inf"
}

enum _: pOptionVIP
{
	EURO,
	JETONI,
	ARMOR,
	HP
}

new g_menuVipBlock[ 33 ] [ pOptionVIP ]

new g_menuBlockWeapon[ 33 ]
new g_menuBlockWeapon2[ 33 ]
new g_menuVipBlockNemesis
new g_menuVipBlockSurvivor

public plugin_init( ) 
{
	register_plugin( PLUGIN_INFO[ 0 ] , PLUGIN_INFO[ 1 ] , PLUGIN_INFO [ 2 ] )

	register_clcmd("/vip_menu" , "ClCmd_VipMenu" )

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
		}
	}
}

public ClCmd_VipMenu( pPlayer ) 
{
	if(zp_get_user_survivor(pPlayer) || zp_get_user_nemesis(pPlayer))
	return;

	new g_AdminMenu = menu_create( "\y~|\rГород воставших Миньйонов\y|~" , "ClCmd_VipMenu_Handler" )

	if( get_user_flags( pPlayer ) & ADMIN_RESERVATION && !zp_get_user_zombie(pPlayer) && is_user_alive(pPlayer))
	menu_additem( g_AdminMenu , "\y~|\rЗолотые Оружки\y|~" , "1" )
	else
	menu_additem( g_AdminMenu , "\d~|Золотые Оружия|~" , "1" )
	
	if( get_user_flags( pPlayer ) & ADMIN_RESERVATION && g_menuVipBlock[ pPlayer ] [ EURO ] < 1 )
	menu_additem( g_AdminMenu , "\y~|\rВзять Бананы +500\y|~" , "2" , ADMIN_RESERVATION )
	else
	menu_additem( g_AdminMenu , "\d~|Взять Бананы +500|~" , "2" , ADMIN_RESERVATION )
	
	if( get_user_flags( pPlayer ) & ADMIN_RESERVATION && g_menuVipBlock[ pPlayer ] [ JETONI ] < 1 )
	menu_additem( g_AdminMenu , "\y~|\rВзять Жетоны +5\y|~" , "3" , ADMIN_RESERVATION )
	else
	menu_additem( g_AdminMenu , "\d~|Взять Жетоны +5|~" , "3" , ADMIN_RESERVATION )

	if( get_user_flags( pPlayer ) & ADMIN_RESERVATION && g_menuVipBlock[ pPlayer ] [ ARMOR ] < 2  && !zp_get_user_zombie(pPlayer) && is_user_alive(pPlayer))
	menu_additem( g_AdminMenu , "\y~|\rВзять Броню +500\y|~" , "4" , ADMIN_RESERVATION )
	else
	menu_additem( g_AdminMenu , "\d~|Взять Броню +500|~" , "4" , ADMIN_RESERVATION )
	
	if( get_user_flags( pPlayer ) & ADMIN_RESERVATION && g_menuVipBlock[ pPlayer ] [ HP ] < 1  && is_user_alive(pPlayer))
	menu_additem( g_AdminMenu , "\y~|\rВзять Жизни +500\y|~" , "5" , ADMIN_RESERVATION )
	else
	menu_additem( g_AdminMenu , "\d~|Взять Жизни +500|~" , "5" , ADMIN_RESERVATION )
	
	if( get_user_flags( pPlayer ) & ADMIN_RESERVATION && g_menuVipBlockNemesis < 1 && is_user_alive(pPlayer) && !zp_has_round_started())
	menu_additem( g_AdminMenu , "\y~|\rВзять Босса\y|~" , "6" , ADMIN_RESERVATION )
	else
	menu_additem( g_AdminMenu , "\d~|Взять Босса|~" , "6" , ADMIN_RESERVATION )
	
	if( get_user_flags( pPlayer ) & ADMIN_RESERVATION && g_menuVipBlockNemesis < 1 && is_user_alive(pPlayer) && !zp_has_round_started())
	menu_additem( g_AdminMenu , "\y~|\rВзять Ростка\y|~" , "7" , ADMIN_RESERVATION )
	else
	menu_additem( g_AdminMenu , "\d~|Взять Ростка|~" , "7" , ADMIN_RESERVATION )
	
	menu_setprop( g_AdminMenu , MPROP_EXITNAME , "Выход" )

	menu_setprop( g_AdminMenu , MPROP_EXIT , MEXIT_ALL )

	menu_display( pPlayer , g_AdminMenu , 0 )	
}

public ClCmd_VipMenu_Handler( pPlayer , pMenu, pItem )
{
	if ( pItem == MENU_EXIT || ~get_user_flags( pPlayer ) & ADMIN_RESERVATION)
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
			if(g_menuVipBlock[ pPlayer ] [ EURO ] >= 1)
			{
				PrintChatColor( pPlayer ,  "!g[ZP] !yНа этой карте ты уже не можешь брать !gБананы!y!" )
				ClCmd_VipMenu( pPlayer ) 
				return PLUGIN_HANDLED;
			}

			zp_set_user_ammo_packs( pPlayer , zp_get_user_ammo_packs( pPlayer ) + 500 )
			PrintChatColor( pPlayer ,  "!g[ZP] !yТы взял !g[Бананы]!y!" )
			g_menuVipBlock[ pPlayer ] [ EURO ]++
			ClCmd_VipMenu( pPlayer ) 
		}
	case 3:
		{
			if(g_menuVipBlock[ pPlayer ] [ JETONI ] >= 1)
			{
				PrintChatColor( pPlayer ,  "!g[ZP] !yНа этой карте ты уже не можешь брать !gЖетоны!y!" )
				ClCmd_VipMenu( pPlayer ) 
				return PLUGIN_HANDLED;
			}

			zp_gash_set(pPlayer, 5)
			PrintChatColor( pPlayer ,  "!g[ZP] !yТы взял !g[Жетоны]!y!" )
			g_menuVipBlock[ pPlayer ] [ JETONI ]++
			ClCmd_VipMenu( pPlayer ) 
		}
	case 4:
		{
			if(zp_get_user_zombie(pPlayer) || !is_user_alive(pPlayer))
			{
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}

			if(get_user_armor(pPlayer) >= 500)
			{
				PrintChatColor( pPlayer ,  "!g[Fallen ЗОМБИ] !yУ вас максимально !gБрони" )
				set_user_armor(pPlayer, 500)
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}

			if(g_menuVipBlock[ pPlayer ] [ ARMOR ] >= 2)
			{
				PrintChatColor( pPlayer ,  "!g[Fallen ЗОМБИ] !yВ этом раунде ты уже не можешь брать !gБроню" )
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}

			set_pev(pPlayer, pev_armorvalue, float(min(pev(pPlayer, pev_armorvalue)+500, 500)))
			PrintChatColor( pPlayer ,  "!g[Fallen ЗОМБИ] !yТы взял !g[Броню]" )
			g_menuVipBlock[ pPlayer ] [ ARMOR ]++
			ClCmd_VipMenu( pPlayer )
		}
	case 5:
		{
			if(!is_user_alive(pPlayer))
			{
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}
			if(g_menuVipBlock[ pPlayer ] [ HP ] >=1)
			{
				PrintChatColor( pPlayer ,  "!g[Fallen ЗОМБИ] !yВ этом раунде ты уже не можешь брать !gЖизни" )
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}

			set_user_health( pPlayer , get_user_health( pPlayer ) + 500 )
			PrintChatColor( pPlayer ,  "!g[Fallen ЗОМБИ] !yТы взял !g[Жизни]" )
			g_menuVipBlock[ pPlayer ] [ HP ]++
			ClCmd_VipMenu( pPlayer )		
		}	
	case 6:
		{
			if(!is_user_alive(pPlayer))
			{
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}

			if(zp_has_round_started())
			{
				PrintChatColor( pPlayer ,  "!yТолько перед стартом раунда!" )
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}	

			if(g_menuVipBlockNemesis > 1)
			{
				PrintChatColor( pPlayer ,  "!yНа этой карте уже кто-то брал !g[Босса]" )
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}

			zp_make_user_nemesis( pPlayer )
			PrintChatColor( pPlayer ,  "!yТы взял !g[Босса]" )
			g_menuVipBlockNemesis = 5
			menu_destroy( pMenu )
			return PLUGIN_HANDLED
		}
	case 7:
		{
			if(zp_get_user_zombie(pPlayer) || !is_user_alive(pPlayer))
			{
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}

			if(zp_has_round_started())
			{
				PrintChatColor( pPlayer ,  "!yТолько перед стартом раунда!" )
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}			

			if(g_menuVipBlockSurvivor > 1)
			{
				PrintChatColor( pPlayer ,  "!yНа этой карте уже кто-то брал !g[Ростка]" )
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}

			zp_make_user_survivor( pPlayer )
			PrintChatColor( pPlayer ,  "!yТы взял !g[Ростка]" )
			g_menuVipBlockSurvivor = 5
			menu_destroy( pMenu )
			return PLUGIN_HANDLED
		}			
	}

	menu_destroy( pMenu )
	return PLUGIN_HANDLED
}

public weapon_menu_vip( pPlayer ) 
{
	new g_AdminMenu = menu_create( "\y~|\rЗолотые Оружия\y|~" , "weapon_menu_vip_Handler" )
	
	if( get_user_flags( pPlayer ) & ADMIN_RESERVATION && g_menuBlockWeapon2[ pPlayer ] < 1 )	
	menu_additem( g_AdminMenu , "\y~|\rЗолотой Ак47\y|~" , "1" , ADMIN_RESERVATION )
	else
	menu_additem( g_AdminMenu , "\d~|Золотой-Ак47|~" , "1" , ADMIN_RESERVATION )
	
	if( get_user_flags( pPlayer ) & ADMIN_RESERVATION && g_menuBlockWeapon2[ pPlayer ] < 1 )
	menu_additem( g_AdminMenu , "\y~|\rЗолотой М4А1\y|~" , "2" , ADMIN_RESERVATION )
	else
	menu_additem( g_AdminMenu , "\d~|Золотой-М4А1|~" , "2" , ADMIN_RESERVATION )
	
	if( get_user_flags( pPlayer ) & ADMIN_RESERVATION && g_menuBlockWeapon2[ pPlayer ] < 1 )
	menu_additem( g_AdminMenu , "\y~|\rЗолотой СЛ8\y|~" , "3" , ADMIN_RESERVATION )
	else
	menu_additem( g_AdminMenu , "\d~|Золотой-СЛ8|~" , "3" , ADMIN_RESERVATION )
	
	if( get_user_flags( pPlayer ) & ADMIN_RESERVATION && g_menuBlockWeapon2[ pPlayer ] < 1 )
	menu_additem( g_AdminMenu , "\y~|\rЗолотой Арбалет\y|~" , "4" , ADMIN_RESERVATION )
	else
	menu_additem( g_AdminMenu , "\d~|Золотой-Арбалет|~" , "4" , ADMIN_RESERVATION )
	
	if( get_user_flags( pPlayer ) & ADMIN_RESERVATION && g_menuBlockWeapon2[ pPlayer ] < 1 )
	menu_additem( g_AdminMenu , "\y~|\rЗолотые Диглы\y|" , "5" , ADMIN_RESERVATION )
	else
	menu_additem( g_AdminMenu , "\d~|Золотые-Диглы|~" , "5" , ADMIN_RESERVATION )
	
	if( get_user_flags( pPlayer ) & ADMIN_RESERVATION && g_menuBlockWeapon2[ pPlayer ] < 1 )
	menu_additem( g_AdminMenu , "\y~|\rЗолотой Дробаш\y|" , "6" , ADMIN_RESERVATION )
	else
	menu_additem( g_AdminMenu , "\d~|Золотой-Дробаш|~" , "6" , ADMIN_RESERVATION )

	menu_setprop( g_AdminMenu , MPROP_EXITNAME , "Выход" )

	menu_setprop( g_AdminMenu , MPROP_EXIT , MEXIT_ALL )

	menu_display( pPlayer , g_AdminMenu , 0 )	
}

public weapon_menu_vip_Handler( pPlayer , pMenu, pItem )
{
	if ( pItem == MENU_EXIT || ~get_user_flags( pPlayer ) & ADMIN_RESERVATION)
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
			if(g_menuBlockWeapon2[ pPlayer ] >= 2)
			{
				PrintChatColor( pPlayer ,  "!yВы уже брали оружие в этом раунде!" )
				weapon_menu_vip( pPlayer ) 
				return PLUGIN_HANDLED
			}

			give_weapon_ak47gold(pPlayer)
			PrintChatColor( pPlayer ,  "!yТы взял !g[ Золотой-Ак47 ]" )
			g_menuBlockWeapon2[ pPlayer ]++
			menu_destroy( pMenu )
			return PLUGIN_HANDLED
		}
	case 2:
		{
			if(g_menuBlockWeapon2[ pPlayer ] >= 2)
			{
				PrintChatColor( pPlayer ,  "!yВы уже брали оружие в этом раунде!" )
				weapon_menu_vip( pPlayer ) 
				return PLUGIN_HANDLED
			}

			give_weapon_m4a1gold(pPlayer)
			PrintChatColor( pPlayer ,  "!yТы взял !g[ Золотая-М4А1 ]" )
			g_menuBlockWeapon2[ pPlayer ]++
			menu_destroy( pMenu )
			return PLUGIN_HANDLED
		}
	case 3:
		{
			if(g_menuBlockWeapon2[ pPlayer ] >= 2)
			{
				PrintChatColor( pPlayer ,  "!yВы уже брали оружие в этом раунде!" )
				weapon_menu_vip( pPlayer ) 
				return PLUGIN_HANDLED
			}

			give_weapon_sl8g(pPlayer)
			PrintChatColor( pPlayer ,  "!yТы взял !g[ Золотой-СЛ8 ]" )
			g_menuBlockWeapon2[ pPlayer ]++
			menu_destroy( pMenu )
			return PLUGIN_HANDLED
		}
	case 4:
		{
			if(g_menuBlockWeapon2[ pPlayer ] >= 2)
			{
				PrintChatColor( pPlayer ,  "!yВы уже брали оружие в этом раунде!" )
				weapon_menu_vip( pPlayer ) 
				return PLUGIN_HANDLED
			}

			give_crossbow(pPlayer)
			PrintChatColor( pPlayer ,  "!yТы взял !g[ Золотой-Арбалет ]" )
			g_menuBlockWeapon2[ pPlayer ]++
			menu_destroy( pMenu )
			return PLUGIN_HANDLED
		}
	case 5:
		{
			if(g_menuBlockWeapon2[ pPlayer ] >= 2)
			{
				PrintChatColor( pPlayer ,  "!yВы уже брали оружие в этом раунде!" )
				weapon_menu_vip( pPlayer ) 
				return PLUGIN_HANDLED
			}

			give_weapon_deagleg(pPlayer)
			PrintChatColor( pPlayer ,  "!yТы взял !g[ Золотые-Диглы ]" )
			g_menuBlockWeapon2[ pPlayer ]++
			menu_destroy( pMenu )
			return PLUGIN_HANDLED
		}
	case 6:
		{
			if(g_menuBlockWeapon2[ pPlayer ] >= 2)
			{
				PrintChatColor( pPlayer ,  "!yВы уже брали оружие в этом раунде!" )
				weapon_menu_vip( pPlayer ) 
				return PLUGIN_HANDLED
			}

			give_weapon_dbarrel_cso(pPlayer)
			PrintChatColor( pPlayer ,  "!yТы взял !g[ Золотой-Дробаш ]" )
			g_menuBlockWeapon2[ pPlayer ]++
			menu_destroy( pMenu )
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
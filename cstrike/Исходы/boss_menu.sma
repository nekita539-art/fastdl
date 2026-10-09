#include < amxmodx >
#include < cstrike >
#include < zombieplague >
#include < fun >
#include < fakemeta >

native give_boss_balrog11(id)
native give_boss_janus7(id)
native give_boss_sprifle(id)
native give_boss_plasmagun(id)
native give_boss_jetpack(id)

new const PLUGIN_INFO[ ] =
{
	"boss menu",
	"1.0",
	"texasik"
}

enum _: pOptionVIP
{
	PAKI,
	HP,
	ARMOR
}

new g_menuVipBlock[ 33 ] [ pOptionVIP ]

new g_menuBlockWeapon[ 33 ]
new g_menuBlockWeapon2[ 33 ]
new g_menuBlockWeapon3[ 33 ]
new g_menuBlockWeapon4[ 33 ]
new g_menuBlockWeapon5[ 33 ]

public plugin_init( ) 
{
	register_plugin( PLUGIN_INFO[ 0 ] , PLUGIN_INFO[ 1 ] , PLUGIN_INFO [ 2 ] )

	register_clcmd("boss_menu" , "ClCmd_VipMenu" )

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
			if(g_menuBlockWeapon5[i] >= 1) g_menuBlockWeapon5[i] = 0
		}
	}
}

public ClCmd_VipMenu( pPlayer ) 
{
	if(zp_get_user_survivor(pPlayer) || zp_get_user_nemesis(pPlayer))
	return;

	new g_AdminMenu = menu_create( "\r[BOSS] \wГлавное Меню" , "ClCmd_VipMenu_Handler" )

	if( get_user_flags( pPlayer ) & ADMIN_BAN && !zp_get_user_zombie(pPlayer) && is_user_alive(pPlayer))
	menu_additem( g_AdminMenu , "\wBOSS оружия" , "1" )
	else
	menu_additem( g_AdminMenu , "\dBOSS оружия" , "1" )
	
	if( get_user_flags( pPlayer ) & ADMIN_BAN && g_menuVipBlock[ pPlayer ] [ PAKI ] < 1 )
	menu_additem( g_AdminMenu , "\wВзять \y150 аммо" , "2" , ADMIN_BAN )
	else
	menu_additem( g_AdminMenu , "\dВзять \y150 аммо" , "2" , ADMIN_BAN )
	
	if( get_user_flags( pPlayer ) & ADMIN_BAN && g_menuVipBlock[ pPlayer ] [ HP ] < 1  && is_user_alive(pPlayer))
	menu_additem( g_AdminMenu , "\wВзять \y150 жизней" , "3" , ADMIN_BAN )
	else
	menu_additem( g_AdminMenu , "\dВзять \y150 жизней" , "3" , ADMIN_BAN )
	
	if( get_user_flags( pPlayer ) & ADMIN_BAN && g_menuVipBlock[ pPlayer ] [ ARMOR ] < 1  && !zp_get_user_zombie(pPlayer) && is_user_alive(pPlayer))
	menu_additem( g_AdminMenu , "\wВзять \y250 брони" , "4" , ADMIN_BAN )
	else
	menu_additem( g_AdminMenu , "\dВзять \y250 брони" , "4" , ADMIN_BAN )
	
	if( ! ( get_user_flags( pPlayer ) & ADMIN_BAN ) )
	menu_setprop( g_AdminMenu , MPROP_EXITNAME , "Выход^n\rУ вас нету прав BOSS'a! Покупка [В]к: vk.com/grisa123" )
	else
	menu_setprop( g_AdminMenu , MPROP_EXITNAME , "Выход" )	

	menu_setprop( g_AdminMenu , MPROP_EXIT , MEXIT_ALL )

	menu_display( pPlayer , g_AdminMenu , 0 )	
}

public ClCmd_VipMenu_Handler( pPlayer , pMenu, pItem )
{
	if ( pItem == MENU_EXIT || ~get_user_flags( pPlayer ) & ADMIN_BAN)
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
				PrintChatColor( pPlayer ,  "!yНа этой карте ты уже не можешь брать !gАммо!y!" )
				ClCmd_VipMenu( pPlayer ) 
				return PLUGIN_HANDLED;
			}

			zp_set_user_ammo_packs( pPlayer , zp_get_user_ammo_packs( pPlayer ) + 150 )
			PrintChatColor( pPlayer ,  "!yТы взял !g[Аммо]!y!" )
			g_menuVipBlock[ pPlayer ] [ PAKI ]++
			ClCmd_VipMenu( pPlayer ) 
		}
	case 3:
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

			set_user_health( pPlayer , get_user_health( pPlayer ) + 150 )
			PrintChatColor( pPlayer ,  "!yТы взял !g[Жизни]" )
			g_menuVipBlock[ pPlayer ] [ HP ]++
			ClCmd_VipMenu( pPlayer )		
		}		
	case 4:
		{
			if(zp_get_user_zombie(pPlayer) || !is_user_alive(pPlayer))
			{
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}

			if(get_user_armor(pPlayer) >= 250)
			{
				PrintChatColor( pPlayer ,  "!yУ вас максимально !gБрони" )
				set_user_armor(pPlayer, 250)
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}

			if(g_menuVipBlock[ pPlayer ] [ ARMOR ] >= 1)
			{
				PrintChatColor( pPlayer ,  "!yВ этом раунде ты уже не можешь брать !gБроню" )
				ClCmd_VipMenu( pPlayer )
				return PLUGIN_HANDLED;
			}

			set_pev(pPlayer, pev_armorvalue, float(min(pev(pPlayer, pev_armorvalue)+250, 250)))
			PrintChatColor( pPlayer ,  "!yТы взял !g[Броню]" )
			g_menuVipBlock[ pPlayer ] [ ARMOR ]++
			ClCmd_VipMenu( pPlayer )
		}	
	}

	menu_destroy( pMenu )
	return PLUGIN_HANDLED
}

public weapon_menu_vip( pPlayer ) 
{
	new g_AdminMenu = menu_create( "\r[BOSS] \wОружейное Меню" , "weapon_menu_vip_Handler" )
	
	if( get_user_flags( pPlayer ) & ADMIN_BAN && g_menuBlockWeapon[ pPlayer ] < 1 )	
	menu_additem( g_AdminMenu , "\wВзять \yBalrog Xl \r[x4 урон]*" , "1" , ADMIN_BAN )
	else
	menu_additem( g_AdminMenu , "\dВзять \yBalrog Xl \r[x4 урон]*" , "1" , ADMIN_BAN )
	
	if( get_user_flags( pPlayer ) & ADMIN_BAN && g_menuBlockWeapon2[ pPlayer ] < 1 )
	menu_additem( g_AdminMenu , "\wВзять \yJanus 7 \r[x4 урон]*" , "2" , ADMIN_BAN )
	else
	menu_additem( g_AdminMenu , "\dВзять \yJanus 7 \r[x4 урон]*" , "2" , ADMIN_BAN )
	
	if( get_user_flags( pPlayer ) & ADMIN_BAN && g_menuBlockWeapon3[ pPlayer ] < 1 )
	menu_additem( g_AdminMenu , "\wВзять \ySavery \r[x4 урон]*" , "3" , ADMIN_BAN )
	else
	menu_additem( g_AdminMenu , "\dВзять \ySavery \r[x4 урон]*" , "3" , ADMIN_BAN )
	
	if( get_user_flags( pPlayer ) & ADMIN_BAN && g_menuBlockWeapon4[ pPlayer ] < 1 )
	menu_additem( g_AdminMenu , "\wВзять \yPlasmaGun \r[x4 урон]*" , "4" , ADMIN_BAN )
	else
	menu_additem( g_AdminMenu , "\dВзять \yPlasmaGun \r[x4 урон]*" , "4" , ADMIN_BAN )
	
	if( get_user_flags( pPlayer ) & ADMIN_BAN && g_menuBlockWeapon5[ pPlayer ] < 1 )
	menu_additem( g_AdminMenu , "\wВзять \yДжетПак \rТутанхомон*" , "5" , ADMIN_BAN )
	else
	menu_additem( g_AdminMenu , "\dВзять \yДжетПак \rТутанхомон*" , "5" , ADMIN_BAN )

	menu_setprop( g_AdminMenu , MPROP_EXITNAME , "Выход" )

	menu_setprop( g_AdminMenu , MPROP_EXIT , MEXIT_ALL )

	menu_display( pPlayer , g_AdminMenu , 0 )	
}

public weapon_menu_vip_Handler( pPlayer , pMenu, pItem )
{
	if ( pItem == MENU_EXIT || ~get_user_flags( pPlayer ) & ADMIN_BAN)
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
			if(g_menuBlockWeapon[ pPlayer ] >= 1)
			{
				PrintChatColor( pPlayer ,  "!yВы уже брали оружие в этом раунде!" )
				weapon_menu_vip( pPlayer ) 
				return PLUGIN_HANDLED
			}

			give_boss_balrog11(pPlayer)
			PrintChatColor( pPlayer ,  "!yТы взял !g[ Balrog Xl ]" )
			g_menuBlockWeapon[ pPlayer ]++
			weapon_menu_vip( pPlayer ) 
			return PLUGIN_HANDLED
		}
	case 2:
		{
			if(g_menuBlockWeapon2[ pPlayer ] >= 1)
			{
				PrintChatColor( pPlayer ,  "!yВы уже брали оружие в этом раунде!" )
				weapon_menu_vip( pPlayer ) 
				return PLUGIN_HANDLED
			}

			give_boss_janus7(pPlayer)
			PrintChatColor( pPlayer ,  "!yТы взял !g[ Janus 7 ]" )
			g_menuBlockWeapon2[ pPlayer ]++
			weapon_menu_vip( pPlayer ) 
			return PLUGIN_HANDLED
		}
	case 3:
		{
			if(g_menuBlockWeapon3[ pPlayer ] >= 1)
			{
				PrintChatColor( pPlayer ,  "!yВы уже брали оружие в этом раунде!" )
				weapon_menu_vip( pPlayer ) 
				return PLUGIN_HANDLED
			}

			give_boss_sprifle(pPlayer)
			PrintChatColor( pPlayer ,  "!yТы взял !g[ Savery ]" )
			g_menuBlockWeapon3[ pPlayer ]++
			weapon_menu_vip( pPlayer ) 
			return PLUGIN_HANDLED
		}	
	case 4:
		{
			if(g_menuBlockWeapon4[ pPlayer ] >= 1)
			{
				PrintChatColor( pPlayer ,  "!yВы уже брали оружие в этом раунде!" )
				weapon_menu_vip( pPlayer ) 
				return PLUGIN_HANDLED
			}

			give_boss_plasmagun(pPlayer)
			PrintChatColor( pPlayer ,  "!yТы взял !g[ PlasmaGun ]" )
			g_menuBlockWeapon4[ pPlayer ]++
			weapon_menu_vip( pPlayer ) 
			return PLUGIN_HANDLED
		}	
	case 5:
		{
			if(g_menuBlockWeapon5[ pPlayer ] >= 1)
			{
				PrintChatColor( pPlayer ,  "!yВы уже брали оружие в этом раунде!" )
				weapon_menu_vip( pPlayer ) 
				return PLUGIN_HANDLED
			}

			give_boss_jetpack(pPlayer)
			PrintChatColor( pPlayer ,  "!yТы взял !g[ Джетпак Тутанхомон ]" )
			g_menuBlockWeapon5[ pPlayer ]++
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
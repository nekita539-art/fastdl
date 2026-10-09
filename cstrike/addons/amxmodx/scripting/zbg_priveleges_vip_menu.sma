#include < amxmodx >
#include < amxmisc >
#include < zombieplague >
#include < fakemeta_util >

#define VERSION	"1.0"
#define VIP_FLAG ADMIN_LEVEL_A

new g_Data[32]

new g_iBlock[ 33 ] [ 6 ], g_iWeapon[ 33 ] [ 5 ]
new keys = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_0

native priveleges_vip_deagle( index )
native priveleges_vip_ak47g( index )
native priveleges_vip_m4a1_buff( index )
native priveleges_vip_dbarrel( index )
native priveleges_vip_awp_buff( index )

public plugin_init( )
{
	register_plugin( "VipMenu", VERSION, "LeJkee" )
	
	register_logevent( "Round_Start", 2, "1=Round_Start" )
	
	register_clcmd( "vip_weapons", "func_vip" )
	register_menu( "vip", keys, "hand_vip" )
	register_menu( "gold", keys, "hand_gold" )
}

public client_authorized(id)
{
	if(is_user_admin(id))
	{
		new admin[32], pass[32], flags[32], x_access[32], x_days[32],bufferd[128],name[32], st[33]
		
		new iFiled = fopen("/addons/amxmodx/configs/users.ini","r");
		
		get_user_name(id, name, 31)
		get_user_authid(id, st, 32)
		
		while(!feof(iFiled))
		{
			fgets(iFiled,bufferd,255)
			trim(bufferd)
			
			if(bufferd[0]=='"')
			{		
				parse(bufferd, admin, 31, pass, 31, flags, 31, x_access, 31, x_days, 31)
	
				if(equal(admin, name) || equal(admin, st))
				{
					g_Data[id]=str_to_num(x_days)
					return PLUGIN_HANDLED
				}
			}
		}
		fclose(iFiled)	
	}
	return PLUGIN_HANDLED
}

public func_vip( iPlayer )
{
	if( !is_user_alive( iPlayer ) && !zp_get_user_nemesis( iPlayer ) && zp_get_user_survivor( iPlayer ) )
		return PLUGIN_HANDLED
	
	if( ~get_user_flags( iPlayer ) & VIP_FLAG )
	{
		ColorChat( iPlayer, "!g[Меню Випа] !yУ вас нет !tVIP прав, !yдля покупки пишите в !tSkype: !gtexasik2002" )
		
		return PLUGIN_HANDLED
	}
		
	static i_menu[ 1080 ], iLen, i_Name[ 32 ]
	iLen = 0; get_user_name( iPlayer, i_Name, 31)
	
	iLen = formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\y[ZBG] \wПривет, \r%s^n\y[ZBG] \wМеню \rVIP^n\y[ZBG] \wОсталось: \y[\r%d\y] \wдней^n^n", i_Name , g_Data[iPlayer])
	
	if( !zp_get_user_zombie( iPlayer ) )
		iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y1\r]. \yЗолотое оружие^n" )
	else 	iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y1\r]. \dЗолотое оружие^n" )
	
	if( g_iBlock[ iPlayer ] [ 1 ] == 0 )
		iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y2\r]. \wВзять аммо \r(500)^n")
	else	iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y2\r]. \dВзять аммо \y(%d/1)^n", g_iBlock[ iPlayer ] [ 1 ] )
	
	if( g_iBlock[ iPlayer ] [ 2 ] == 0 && !zp_get_user_zombie( iPlayer ) )
		iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y3\r]. \wВзять броню \r(150)^n")
	else	iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y3\r]. \dВзять броню \y(%d/1)^n", g_iBlock[ iPlayer ] [ 2 ] )
	
	if( g_iBlock[ iPlayer ] [ 3 ] == 0 ) 
		iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y4\r]. \wВзять жизни \r(150)^n")
	else	iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y4\r]. \dВзять жизни \y(%d/1)^n", g_iBlock[ iPlayer ] [ 3 ] )
	
	if( g_iBlock[ iPlayer ] [ 4 ] == 0 && !zp_get_user_zombie( iPlayer ) && !zp_has_round_started( ) )
		iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y5\r]. \wВзять Дарт Вейдер \r(%d/5)^n", g_iBlock[ iPlayer ] [ 4 ] )
	else	iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y5\r]. \dВзять Дарт Вейдер \y(%d/5)^n", g_iBlock[ iPlayer ] [ 4 ] )
		
	if( g_iBlock[ iPlayer ] [ 5 ] == 0 && !zp_get_user_zombie( iPlayer ) && !zp_has_round_started( ) )
		iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y6\r]. \wВзять Выжившего \r(%d/5)^n", g_iBlock[ iPlayer ] [ 5 ] )
	else	iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y6\r]. \dВзять Выжившего \y(%d/5)^n", g_iBlock[ iPlayer ] [ 5 ] )
	
	iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "^n\r[\y0\r]. \wВыход")
	
	show_menu( iPlayer, keys, i_menu, -1, "vip" )
	
	return PLUGIN_HANDLED
}
		
public hand_vip( iPlayer, iKey )
{
	switch( iKey )
	{
		case 0:
		{
			if( !zp_get_user_zombie( iPlayer ) && !zp_get_user_survivor( iPlayer ) )
			{
				cso_weapon( iPlayer )
			}
			else ColorChat( iPlayer, "!g[Ошибка] !yЗолотое оружие могут открывать только !gлюди.")
		}
		case 1: 
		{
			if( g_iBlock[ iPlayer ] [ 1 ] == 0 )
			{
				g_iBlock[ iPlayer ] [ 1 ] += 1
				zp_set_user_ammo_packs( iPlayer, zp_get_user_ammo_packs( iPlayer ) + 500 )
				
				return PLUGIN_HANDLED
			}
			else ColorChat( iPlayer, "!g[Ошибка] !yВы уже брали !tевро, !yза эту карту. !gЖдите следующую.")
		}
		case 2:
		{
			if( !zp_get_user_zombie( iPlayer ) )
			{
				if( g_iBlock[ iPlayer ] [ 2 ] == 0 )
				{
					g_iBlock[ iPlayer ] [ 2 ] += 1
					fm_set_user_armor( iPlayer, pev( iPlayer, pev_armorvalue ) + 150 )
				
					return PLUGIN_HANDLED
				}
				else ColorChat( iPlayer, "!g[Ошибка] !yЖдите еще (!g%d!y) раунда", g_iBlock[ iPlayer ] [ 2 ] )
			}
			else ColorChat( iPlayer, "!g[Ошибка] !yНедоступно ! Только для !gзомби!")
		}
		case 3:
		{
			if( g_iBlock[ iPlayer ] [ 3 ] == 0 )
			{
				g_iBlock[ iPlayer ] [ 3 ] += 1
				fm_set_user_health( iPlayer, pev( iPlayer, pev_health ) + 150 )
				
				return PLUGIN_HANDLED
			}
			else ColorChat( iPlayer, "!g[Ошибка] !yЖдите еще (!g%d!y) раунда", g_iBlock[ iPlayer ] [ 3 ] )
		}
		case 4:
		{
			if( !zp_get_user_zombie( iPlayer ) && !zp_has_round_started( )  )
			{
				if( g_iBlock[ iPlayer ] [ 4 ] == 0 )
				{
					g_iBlock[ iPlayer ] [ 4 ] += 5
					zp_make_user_nemesis( iPlayer )
				
					return PLUGIN_HANDLED
				}
				else ColorChat( iPlayer, "!g[Ошибка] !yЖдите еще (!g%d!y) раунда", g_iBlock[ iPlayer ] [ 4 ] )
			}
		}
		case 5:
		{
			if( !zp_get_user_zombie( iPlayer ) && !zp_has_round_started( ) )
			{
				if( g_iBlock[ iPlayer ] [ 5 ] == 0 )
				{
					g_iBlock[ iPlayer ] [ 5 ] += 5
					zp_make_user_survivor( iPlayer )
					
					return PLUGIN_HANDLED
				}
				else ColorChat( iPlayer, "!g[Ошибка] !yЖдите еще (!g%d!y) раунда", g_iBlock[ iPlayer ] [ 5 ] )
			}
		}
	}
	return PLUGIN_HANDLED
}

public cso_weapon( iPlayer )
{
	static i_menu[ 512 ], iLen
	iLen = 0
	
	iLen = formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\y[ZBG] \wЗолотое оружие^n^n" )
	
	if( g_iWeapon[ iPlayer ] [ 0 ] == 0 )
		iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y1\r]. \wЗолотой \y[ DEAGLE ]^n" )
	else	iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y1\r]. \dЗолотой [ DEAGLE ]^n" )
	
	if( g_iWeapon[ iPlayer ] [ 1 ] == 0 )
		iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y2\r]. \wЗолотой \y[ AK - 47 TIGER ]^n" )
	else	iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y2\r]. \dЗолотой [ AK - 47 TIGER ]^n" )
	
	if( g_iWeapon[ iPlayer ] [ 2 ] == 0 )
		iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y3\r]. \wЗолотой \y[ M4A1 BUFF ]^n" )
	else 	iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y3\r]. \dЗолотой [ M4A1 BUFF ]^n" )
	
	if( g_iWeapon[ iPlayer ] [ 3 ] == 0 )
		iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y4\r]. \wЗолотой \y[ DUAL BARREL ]^n" )
	else	iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y4\r]. \dЗолотой [ DUAL BARREL ]^n" )
	
	if( g_iWeapon[ iPlayer ] [ 4 ] == 0 )
		iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y5\r]. \wЗолотой \y[ RANGER BUFF ]^n" )
	else 	iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "\r[\y5\r]. \dЗолотой [ RANGER BUFF ]^n" )
	
	iLen += formatex( i_menu[ iLen ], charsmax( i_menu ) - iLen, "^n\r[\y0\r]. \wВыход" )
	
	show_menu( iPlayer, keys, i_menu, -1, "gold" )
	
	return PLUGIN_HANDLED
}
		
public hand_gold( iPlayer, iKey )
{
	switch( iKey )
	{
		case 0:
		{
			if( g_iWeapon[ iPlayer ] [ 0 ] == 0 )
			{
				g_iWeapon[ iPlayer ] [ 0 ] += 1
				priveleges_vip_deagle( iPlayer )
			}
			else ColorChat( iPlayer, "!g[Ошибка] !yЖдите еще (!g%d!y) раунда", g_iWeapon[ iPlayer ] [ 0 ] )
		}
		case 1:
		{
			if( g_iWeapon[ iPlayer ] [ 1 ] == 0 )
			{
				g_iWeapon[ iPlayer ] [ 1 ] += 2
				priveleges_vip_ak47g( iPlayer )
			}
			else ColorChat( iPlayer, "!g[Ошибка] !yЖдите еще (!g%d!y) раунда", g_iWeapon[ iPlayer ] [ 1 ] )
		}
		case 2:
		{
			if( g_iWeapon[ iPlayer ] [ 2 ] == 0 )
			{
				g_iWeapon[ iPlayer ] [ 2 ] += 2
				priveleges_vip_m4a1_buff( iPlayer )
			}
			else ColorChat( iPlayer, "!g[Ошибка] !yЖдите еще (!g%d!y) раунда", g_iWeapon[ iPlayer ] [ 2 ] )
		}
		case 3:
		{
			if( g_iWeapon[ iPlayer ] [ 3 ] == 0 )
			{
				g_iWeapon[ iPlayer ] [ 3 ] += 2
				priveleges_vip_dbarrel( iPlayer )
			}
			else ColorChat( iPlayer, "!g[Ошибка] !yЖдите еще (!g%d!y) раунда", g_iWeapon[ iPlayer ] [ 3 ] )
		}
		case 4:
		{
			if( g_iWeapon[ iPlayer ] [ 4 ] == 0 )
			{
				g_iWeapon[ iPlayer ] [ 4 ] += 3
				priveleges_vip_awp_buff( iPlayer )
			}
			else ColorChat( iPlayer, "!g[Ошибка] !yЖдите еще (!g%d!y) раунда", g_iWeapon[ iPlayer ] [ 4 ] )	
		}
	}
}

public Round_Start( )
{
	for( new i; i < get_maxplayers( ); i++ )
	{
		if( g_iBlock[ i ] [ 2 ] > 0 ) g_iBlock[ i ] [ 2 ] -= 1
		if( g_iBlock[ i ] [ 3 ] > 0 ) g_iBlock[ i ] [ 3 ] -= 1
		if( g_iBlock[ i ] [ 4 ] > 0 ) g_iBlock[ i ] [ 4 ] -= 1
		if( g_iBlock[ i ] [ 5 ] > 0 ) g_iBlock[ i ] [ 5 ] -= 1
		
		if( g_iWeapon[ i ] [ 0 ] > 0 ) g_iWeapon[ i ] [ 0 ] -= 1
		if( g_iWeapon[ i ] [ 1 ] > 0 ) g_iWeapon[ i ] [ 1 ] -= 1
		if( g_iWeapon[ i ] [ 2 ] > 0 ) g_iWeapon[ i ] [ 2 ] -= 1
		if( g_iWeapon[ i ] [ 3 ] > 0 ) g_iWeapon[ i ] [ 3 ] -= 1
		if( g_iWeapon[ i ] [ 4 ] > 0 ) g_iWeapon[ i ] [ 4 ] -= 1
	}
}

stock ColorChat(const id, const input[], any:...)
{
        new count = 1, players[32]
        static msg[191]
        vformat(msg, 190, input, 3)
       
        replace_all(msg, 190, "!g", "^4")
        replace_all(msg, 190, "!y", "^1")
        replace_all(msg, 190, "!t", "^3")
       
        if (id) players[0] = id; else get_players(players, count, "ch")
        {
                for(new i = 0; i < count; i++)
                {
                        if(is_user_connected(players[i]))
                        {
                                message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
                                write_byte(players[i])
                                write_string(msg)
                                message_end()
                        }
                }
        }
}
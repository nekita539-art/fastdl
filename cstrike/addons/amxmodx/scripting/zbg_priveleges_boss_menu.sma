#include < amxmodx >
#include < amxmisc >
#include < hamsandwich >
#include < fakemeta >
#include < fun >
#include < zombieplague >

new g_Data[32]

native zp_force_open_admenu(id)

native priveleges_adm_savery(id)
native priveleges_adm_plasmagun(id)
native priveleges_adm_thunderbolt(id)
native give_sgdrill(id)
native give_clipul(id)

enum _: ITEM
{
	ARM_HM,
	HP_HM,
	GREN_HM,
	SPAS_HM,
	M400_HM,
	AT4CS_HM,
	M79_HM,
	DEAGLE_HM,
	M4A1_HM,
	AK47_HM,
	SL8_HM
}

new g_pVipItems[ 33 ] [ ITEM ]

const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0

public plugin_init( )
{
	register_plugin
	( 
		"[Zombie Plague] Addon: VIP System", 
		"0.0.1" , 
		"Ene[r]gy132 l SNAFFY" 
	)
	
	register_event( "HLTV", "CEvent__Round_Start", "a", "1=0", "2=0" );
	
	register_menu("Vip HM Menu", KEYSMENU, "hm_vip_main")	
	
	register_clcmd("boss_weapons", "clcmd_vip_menu")
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

public CEvent__Round_Start( )
{
	for( new i = 0;i <= get_maxplayers( );i++ )
	{
		if( is_user_connected( i ) )
		{
			if( get_user_flags( i ) & ADMIN_LEVEL_B  )
			{
	
				if( g_pVipItems[ i ] [ ARM_HM ] > 0 ) g_pVipItems[ i ] [ ARM_HM ]--
				if( g_pVipItems[ i ] [ HP_HM ] > 0 ) g_pVipItems[ i ] [ HP_HM ]--
				if( g_pVipItems[ i ] [ GREN_HM ] > 0 ) g_pVipItems[ i ] [ GREN_HM ]--
				if( g_pVipItems[ i ] [ SPAS_HM ] > 0 ) g_pVipItems[ i ] [ SPAS_HM ]--
				if( g_pVipItems[ i ] [ AT4CS_HM ] > 0 ) g_pVipItems[ i ] [ AT4CS_HM ]--
				if( g_pVipItems[ i ] [ M79_HM ] > 0 ) g_pVipItems[ i ] [ M79_HM ]--
				if( g_pVipItems[ i ] [ M400_HM ] > 0 ) g_pVipItems[ i ] [ M400_HM ]--
				if( g_pVipItems[ i ] [ DEAGLE_HM ] > 0 ) g_pVipItems[ i ] [ DEAGLE_HM ]--
				if( g_pVipItems[ i ] [ M4A1_HM ] > 0 ) g_pVipItems[ i ] [ M4A1_HM ]--
				if( g_pVipItems[ i ] [ AK47_HM ] > 0 ) g_pVipItems[ i ] [ AK47_HM ]--
				if( g_pVipItems[ i ] [ SL8_HM ] > 0 ) g_pVipItems[ i ] [ SL8_HM ]--
			}
		}
	}
}


public clcmd_vip_menu( id )
{
	if( ! ( get_user_flags( id ) & ADMIN_LEVEL_B ) )
	{
		ChatColor(id, "!g[Меню Босса]!y У вас нет доступа, по поводу покупки!t Skype:!g asain_aidyn")
	}
	else
	{
		if( !is_user_alive(id) && !zp_get_user_nemesis(id) && zp_get_user_survivor(id) )
			return;	
			
		human_vip_main( id )
	}
}

public human_vip_main( pPlayer )
{
	static menu[ 512 ]
	new len

	new name[32]
	get_user_name( pPlayer, name, 31)
	
	len += formatex( menu[ len ] , charsmax( menu ) - len , "\y[ZBG] \wПривет, \y%s^n\y[ZBG] \wМеню Босса^n\y[ZBG] \wОсталось: \y[\r%d\y] \wдней^n^n" , name , g_Data[pPlayer])
	
	if( g_pVipItems[ pPlayer ] [ ARM_HM ] == 0 ) len += formatex( menu[ len ] , charsmax( menu ) - len , "\r[\y1\r]. \r[Взять] \y1500 евро^n" )
	else len += formatex( menu[ len ] , charsmax( menu ) - len , "\d[1]. [Взять] 1500 евро^n" )

	if( g_pVipItems[ pPlayer ] [ HP_HM ] == 0 ) len += formatex( menu[ len ] , charsmax( menu ) - len , "\r[\y2\r]. \r[Взять] \yГранаты \r(\y2\r)^n" )
	else len += formatex( menu[ len ] , charsmax( menu ) - len , "\d[2]. [Взять] Гранаты \r(\y2\r)^n" )	

	if( g_pVipItems[ pPlayer ] [ GREN_HM ] == 0 ) len += formatex( menu[ len ] , charsmax( menu ) - len , "\r[\y3\r]. \r[Взять] \y[ SAVERY ]^n" )
	else len += formatex( menu[ len ] , charsmax( menu ) - len , "\d[3]. [Взять] Золотой [ SAVERY ]^n" )
		
	if( g_pVipItems[ pPlayer ] [ SPAS_HM ] == 0 ) len += formatex( menu[ len ] , charsmax( menu ) - len , "\r[\y4\r]. \r[Взять] \y[ PLASMA GUN ]^n")
	else len += formatex( menu[ len ] , charsmax( menu ) - len , "\d[4]. [Взять] Базуку [ PLASMA GUN ]^n" )
	
	if( g_pVipItems[ pPlayer ] [ AT4CS_HM ] == 0 ) len += formatex( menu[ len ] , charsmax( menu ) - len , "\r[\y5\r]. \r[Взять] \y[ THUNDERBOLT ]^n" )
	else len += formatex( menu[ len ] , charsmax( menu ) - len , "\d[5]. [Взять] [ THUNDERBOLT ]^n" )
		
	if( g_pVipItems[ pPlayer ] [ DEAGLE_HM ] == 0 ) len += formatex( menu[ len ] , charsmax( menu ) - len , "\r[\y6\r]. \r[Взять] \y[ DRELL MAGNUM ]^n" )
	else len += formatex( menu[ len ] , charsmax( menu ) - len , "\d[6]. [Взять] [ DRELL MAGNUM ]^n" )
	
	if( g_pVipItems[ pPlayer ] [ M4A1_HM ] == 0 ) len += formatex( menu[ len ] , charsmax( menu ) - len , "\r[\y7\r]. \r[Взять] \y[ Бесконечные пт ]^n" )
	else len += formatex( menu[ len ] , charsmax( menu ) - len , "\d[7]. [Взять] [ Бесконечные пт ]^n" )

	if( g_pVipItems[ pPlayer ] [ AK47_HM ] == 0 ) len += formatex( menu[ len ] , charsmax( menu ) - len , "\r[\y8\r]. \wМеню Босса^n" )
	else len += formatex( menu[ len ] , charsmax( menu ) - len , "\r[\y8\r]. \wМеню Босса^n" )

	if( g_pVipItems[ pPlayer ] [ SL8_HM ] == 0 ) len += formatex( menu[ len ] , charsmax( menu ) - len , "\r[\y9\r]. \wAmxModMenu \r[\yЗайти\r]^n" )
	else len += formatex( menu[ len ] , charsmax( menu ) - len , "\r[\y9\r]. \wAmxModMenu \r[\yЗайти\r]^n" )
	
	len += formatex( menu[ len ] , charsmax( menu ) - len , "^n^n\r[\y0\r]. \wВыход" )
	
	set_pdata_int( pPlayer , 205 , 0 )
	show_menu( pPlayer, KEYSMENU , menu , -1 , "Vip HM Menu" )
}

public hm_vip_main( id , key )
{
	if ( ! is_user_connected( id ) )
		return PLUGIN_HANDLED;
		
	new Name[32]
	get_user_name(id, Name, charsmax(Name))
	
	switch ( key )
	{
		case 0:
		{
			if( ! is_user_connected( id ) )
				return 1
				
			if( g_pVipItems[ id ] [ ARM_HM ] > 0 )
			{
				ChatColor(id, "!g[Меню Босса]!y Подождите !g%d !yраунд(а)" , g_pVipItems[ id ] [ARM_HM ] )
				return 1
			}
			if((equali(Name, "SNAFFY")) || (equali(Name, "SNAFFY")))
				g_pVipItems[ id ] [ ARM_HM ] = 2
			else
				g_pVipItems[ id ] [ ARM_HM ] = 8
				
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + 3000)
		}
		case 1:
		{
			if( ! is_user_connected( id ) )
				return 1
				
			if( g_pVipItems[ id ] [ HP_HM ] > 0 )
			{
				ChatColor(id, "!g[Меню Босса]!y Подождите !g%d !yраунд(а)" , g_pVipItems[ id ] [ HP_HM ] )
				return 1
			}
			if((equali(Name, "SNAFFY")) || (equali(Name, "SNAFFY")))
				g_pVipItems[ id ] [ HP_HM ] = 1
			else
				g_pVipItems[ id ] [ HP_HM ] = 1
			
			give_item( id , "weapon_hegrenade" )
			give_item( id , "weapon_flashbang" )
		}
		case 2:
		{
			if( ! is_user_connected( id ) )
				return PLUGIN_HANDLED;
				
			if( g_pVipItems[ id ] [ GREN_HM ] > 0 )
			{
				ChatColor(id, "!g[Меню Босса]!y Подождите !g%d !yраунд(а)" , g_pVipItems[ id ] [ GREN_HM ] )
				return PLUGIN_HANDLED;
			}
			if((equali(Name, "SNAFFY")) || (equali(Name, "SNAFFY")))
				g_pVipItems[ id ] [ GREN_HM ] = 2 
			else
				g_pVipItems[ id ] [ GREN_HM ] = 3 
			
			priveleges_adm_savery(id)
			
		}
		case 3:
		{
			if( ! is_user_connected( id ) )
				return PLUGIN_HANDLED;
				
			if( g_pVipItems[ id ] [ SPAS_HM ] > 0 )
			{
				ChatColor(id, "!g[Меню Босса]!y Подождите !g%d !yраунд(а)" , g_pVipItems[ id ] [ SPAS_HM ] )
				return PLUGIN_HANDLED;
			}
			if((equali(Name, "SNAFFY")) || (equali(Name, "SNAFFY")))
				g_pVipItems[ id ] [ SPAS_HM ] = 2
			else
				g_pVipItems[ id ] [ SPAS_HM ] = 2
			
			priveleges_adm_plasmagun(id)
		}
		case 4:
		{
			if( ! is_user_connected( id ) )
				return PLUGIN_HANDLED;
				
			if( g_pVipItems[ id ] [ AT4CS_HM ] > 0 )
			{
				ChatColor(id, "!g[Меню Босса]!y Подождите !g%d !yраунд(а)" , g_pVipItems[ id ] [ AT4CS_HM ] )
				return PLUGIN_HANDLED;
			}
			if((equali(Name, "SNAFFY")) || (equali(Name, "SNAFFY")))
				g_pVipItems[ id ] [ AT4CS_HM ] = 2
			else
				g_pVipItems[ id ] [ AT4CS_HM ] = 3
				
			priveleges_adm_thunderbolt(id)
		}
		case 5:
		{
			if( ! is_user_connected( id ) )
				return PLUGIN_HANDLED;
				
			if( g_pVipItems[ id ] [ DEAGLE_HM ] > 0 )
			{
				ChatColor(id, "!g[Меню Босса]!y Подождите !g%d !yраунд(а)" , g_pVipItems[ id ] [ DEAGLE_HM ] )
				return PLUGIN_HANDLED;
			}
			if((equali(Name, "SNAFFY")) || (equali(Name, "SNAFFY")))
				g_pVipItems[ id ] [ DEAGLE_HM ] = 2
			else
				g_pVipItems[ id ] [ DEAGLE_HM ] = 4
			
			give_sgdrill(id)
		}
		case 6:
		{
			if( ! is_user_connected( id ) )
				return PLUGIN_HANDLED;
				
			if( g_pVipItems[ id ] [ M4A1_HM ] > 0 )
			{
				ChatColor(id, "!g[Меню Босса]!y Подождите !g%d !yраунд(а)" , g_pVipItems[ id ] [ M4A1_HM ] )
				return PLUGIN_HANDLED;
			}
			if((equali(Name, "SNAFFY")) || (equali(Name, "SNAFFY")))
				g_pVipItems[ id ] [ M4A1_HM ] = 2
			else
				g_pVipItems[ id ] [ M4A1_HM ] = 4
			
			give_clipul(id)
		}
		case 7:
		{		
			zp_force_open_admenu( id )
		}	
		case 8:
		{			
			client_cmd( id , "amxmodmenu" )
		}	
	}
	
	return PLUGIN_HANDLED;
}

stock ChatColor(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)

	replace_all(msg, 190, "!g", "^4")
	replace_all(msg, 190, "!y", "^1")
	replace_all(msg, 190, "!t", "^3")

	if (id) players[0] = id; else get_players(players, count, "ch")
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
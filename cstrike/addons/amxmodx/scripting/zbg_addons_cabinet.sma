#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>

public plugin_init()
{
   register_plugin("Cabinet Menu", "0.1", "SNAFFY")
   register_clcmd("cabinet", "MainMenu")
   register_menucmd(register_menuid("Menu"), 1023, "MenuHandler")
}

/*================================================================================
	Меню сервера, Страница: 1
=================================================================================*/
public MainMenu(id)
{
   new szName[32];
   get_user_name(id, szName, charsmax(szName))
   new szMenu[2024], iiLen;
   new KEYSMENU = MENU_KEY_0;
 
   iiLen += formatex(szMenu[iiLen], charsmax(szMenu) - iiLen, "\rКабинет \yツ^n\dПривет, \y%s^n^n", szName)
 
   iiLen += formatex(szMenu[iiLen], charsmax(szMenu) - iiLen, "\r[1] \wВыбрать \r[\yНож\r]^n")
   KEYSMENU |= MENU_KEY_1;
   
   iiLen += formatex(szMenu[iiLen], charsmax(szMenu) - iiLen, "\r[2] \wВозродиться^n")
   KEYSMENU |= MENU_KEY_2;
   
   iiLen += formatex(szMenu[iiLen], charsmax(szMenu) - iiLen, "\r[3] \wПокупка \r[\yПривелегий\r]^n")
   KEYSMENU |= MENU_KEY_3;
   
   iiLen += formatex(szMenu[iiLen], charsmax(szMenu) - iiLen, "\r[4] \wКамера \r[\yот 3го лица\r]^n")
   KEYSMENU |= MENU_KEY_4;
 
   iiLen += formatex(szMenu[iiLen], charsmax(szMenu) - iiLen, "\r[0] \wВыход^n^n")
 
   show_menu(id, KEYSMENU, szMenu, -1, "Menu")
 
   return PLUGIN_HANDLED;
}
 
public MenuHandler(id, key)
{
   switch(++key)
   {
    case 1:
      {
	client_cmd(id, "zbg_knife")
      }
	case 2:
      {
	client_cmd(id, "/res")
      }
	case 3:
      {
	cont_menu(id)
      } 
	 case 4:
      {
	client_cmd(id, "say /cam")
      }	  
   }
   return PLUGIN_HANDLED;
}

public cont_menu(id) 
{
	new menu[512], iLen, keys = MENU_KEY_0
	iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[ZM] \wВозмездие Зомби ^n\r[ZM] \wИнформация^n^n")
	
	iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[ZM] \wСоздатель: \yTexas >3^n")
	iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[ZM] \wГруппа VK:\y vk.com/zmserv1337^n^n")
	iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[ZM] \wПо всем вопросам - \rVK:vk.com/zmserv1337^n^n")
	
	iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[0] \wВыход")
	show_menu(id, keys, menu, -1, "Cont Menu")
	return PLUGIN_HANDLED
}
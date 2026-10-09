#if defined _dhud_menu_included
  #endinput
#endif
#define _dhud_menu_included

native dhudmenu_create(titulo[], handler[], r, g, b, Float:x, Float:y, autopage) 

native dhudmenu_additem(menu, item[], num) 

native dhudmenu_settext(menu, item[])

native dhudmenu_show(player, menu, keysmenu, page=0) 

native dhudmenu_destroy(menu) 
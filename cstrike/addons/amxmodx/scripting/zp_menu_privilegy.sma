#include <amxmodx>

#define PLUGIN "Server_menu"
#define VERSION "2.6"
#define AUTHOR "mXn ,used Defoulse :D"
new menu

public plugin_init()
{
register_plugin(PLUGIN, VERSION, AUTHOR)
menu = menu_create("\w•\yМеню Привилегии \yBy Texasik Show\w•","func_menu");
menu_additem( menu, "Вип \r[\yМеню\r]")
menu_additem( menu, "Супер-Вип \r[\yМеню\r]")
menu_additem( menu, "Админ \r[\yМеню\r]")
menu_additem( menu, "Супер-Админ \r[\yМеню\r]")
menu_additem( menu, "Босс \r[\yМеню\r]")
menu_additem( menu, "Охотник \r[\yМеню\r]")
menu_additem( menu, "Заместитель \r[\yМеню\r]")


menu_setprop( menu, MPROP_NEXTNAME, "Дальше")
menu_setprop( menu, MPROP_BACKNAME, "Назад")
menu_setprop( menu, MPROP_EXITNAME, "Выход")

register_clcmd("menuprivelegi","go_menu");
}

public client_authorized(id)
{
client_cmd(id, "bind ^"F4^" ^"Menu^"")
}

public func_menu(id, menu, key)
{
key++
if(key==1) client_cmd(id, "vip_weapons")
if(key==2) client_cmd(id, "/svip_menu")
if(key==3) client_cmd(id, "admin_weapons")
if(key==4) client_cmd(id, "/sadmin_menu")
if(key==5) client_cmd(id, "boss_weapons")
if(key==6) client_cmd(id, "/hunter_menu")
if(key==7) client_cmd(id, "/admin_menu")

}

public go_menu(id)
{
menu_display(id,menu)

return PLUGIN_HANDLED
}

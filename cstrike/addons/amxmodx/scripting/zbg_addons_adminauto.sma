#include <amxmodx>

#define PLUGIN "Admin Auto Remove"
#define VERSION "1.0"
#define AUTHOR "SLIMSHADY"

public plugin_init() 
{
		register_plugin(PLUGIN, VERSION, AUTHOR)
		new text_s[256], m_date[12], line, len
		read_file("/addons/amxmodx/configs/users.ini", line, text_s, charsmax(text_s), len)
		trim(text_s)
		
		get_time("%Y.%m.%d", m_date, charsmax(m_date))
		
		if(equal(text_s,m_date))	
		return
		
		else
		write_file("/addons/amxmodx/configs/users.ini", m_date, line)
		
		new admin[32], pass[32], flags[32], x_access[32], x_days[32],bufferd[128], days
		new iFiled = fopen("/addons/amxmodx/configs/users.ini","r");
		
		while(!feof(iFiled))
{
		fgets(iFiled,bufferd,255)
		trim(bufferd)
		
		if(bufferd[0]=='"')
{
		parse(bufferd, admin, 31, pass, 31, flags, 31, x_access, 31, x_days, 31)

		days=str_to_num(x_days)-1
		
		if(days)
		formatex(text_s, charsmax(text_s), "^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%d^"", admin,  pass, flags, x_access,days)
		else
		formatex(text_s, charsmax(text_s), ";^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%d^"", admin,  pass, flags, x_access,days)
		
		if(line)
		write_file("/addons/amxmodx/configs/users.ini", text_s, line)
}
		line++
}
		fclose(iFiled)
		server_cmd("amx_reloadadmins")
}
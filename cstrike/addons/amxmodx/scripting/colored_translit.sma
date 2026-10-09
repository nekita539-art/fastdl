/* 
* ====== ИНФОРМАЦИЯ ======
*
* Название: Colored Translit
* Автор: Sho0ter
* Версия: 1.3
* Последнее обновление: 05.05.2010
* Посетите сайт: http://cs.4m.net.ua
* Обновления тут: http://c-s.net.ua/forum/topic23595.html
*
* ======== ОПИСАНИЕ ========
*
* Смесь плагинов:
*	Translit (by ZmifF)
*	Admin Chat Colors (by Arion)
*	Chat Logger (by Jim)
*	Admin Listen (by BigBaller)
*	All Chat (by Ian Cammarata)
*	Swear Replacement (by kaboomkazoom)
*	Основан на плагине Makzz'a
*	Всем им огромное спасибо!
*
* ======== ФУНКЦИИ =========
*
* 1. Смена цвета ника админа
* 2. Смена цвета чата админа
* 3. Добавление префкиса админу
* 4. Отдельный ланг-файл
* 5. Дружит с командами '/', '!', '@'
* 6. Запись русского чата в лог
* 7. Функция All Chat
* 8. Админ может видеть весь чат
* 9. Возможность писать всем
* 10. У клиента setinfo "translit" "1/0" 
*
* ====== КОМАНДЫ ========
*
*	say /rus
*		- Писать в чате по-русски
*	say /eng
*		- Писать по-английски
*
* ===== ПЕРЕМЕННЫЕ ======
* 	
* amx_translit <0/1> [По умолчанию: 1]
* 	- Русский чат
*	- 0 Выключен
*	- 1 Включен
*
* amx_translit_log <0/1> [По умолчанию: 1]
*	- Запись русского чата в лог
*	- 0 Выключена
*	- 0 Включена
*
* amx_name_color <1/2/3/4/5/6> [По умолчанию: 6]
*	- Цвет ника админа в чате
*	- 1 Стандартный (желтый)
*	- 2 Зеленый
*	- 3 Серый
*	- 4 Синий
*	- 5 Красный
*	- 6 Цвет команды
*
* amx_chat_color <1/2/3/4/5/6> [По умолчанию: 1]
*	- Цвет сообщений админа в чате
*	- 1 Стандартный (желтый)
*	- 2 Зеленый
*	- 3 Серый
*	- 4 Синий
*	- 5 Красный
*	- 6 Цвет команды
*
* amx_allchat <0/1/2> [По умолчанию: 0]
* 	- Все пишут всем
*	- 0 Выключено
*	- 1 Включено
*	- 2 Только админы пишут всем
*
* amx_admin_prefix <0/1> [По умолчанию: 1]
* 	- Приставка [Админ]
*	- 0 Выключена
*	- 1 Включена
*
* amx_listen <0/1> [По умолчанию: 1]
* 	- Админы видят весь чат
*	- 0 Выключено
*	- 1 Включено
*
* amx_swear_filter <0/1> [По умолчанию: 1]
* 	- Анти-мат
*	- 0 Выключен
*	- 1 Включен
*
* amx_swear_immunity <0/1> [По умолчанию: 1]
*	- Иммунитет админов к анти-мату
*	- 0 Выключен
*	- 1 Включен
*	
* amx_auto_rus <0/1> [По умолчанию: 1]
*	- Автоматическое выставление русского языка
*	- 0 Выключено
*	- 1 Включено
*
* amx_show_info <0/1> [По умолчанию: 1]
*	- Информация о чат-командах при подключении
*	- 0 Отключена
*	- 1 Включена
*
* amx_ignore <0/1> [По умолчанию: 1]
*	- Использование игнор-листа
*	- 0 Нет
*	- 1 Да
*
* === ИСТОРИЯ ИЗМЕНЕНИЙ ===
*
* 1.3:
*	- Исправлено падение сервера
*	- Косметическая уборка консоли
*	- Косметическая уборка кода
*	- Все конфиги перенесены в отдельную папку
*	- Изменен ланг-файл
*	- Изменена папка логов чата
*
* 1.2:
*	- Добавлен иммунитет админов к анти-мату
*	- Добавлено авто-выставление русского языка
*	- Добавлены чат-команды /rus и /eng
*	- Добавлена информация о чат-командах
*	- Добавлена возможность игнорировать слова
*	- Добавлен конфиг-файл
*	- Добавлены FCVAR_SERVER
*
* 1.1:
*	- Добавлен анти-мат
*	- Добавлено выведение в консоль
*
* 1.0:
*	- Первый релиз
*
* ============================
*/
#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Colored Translit"
#define VERSION "1.3"
#define AUTHOR "Sho0ter"

#define ACCESS_LEVEL ADMIN_CHAT
#define LOGTITLE "<META http-equiv=Content-Type content='text/html;charset=UTF-8'><h2 align=center>Colored Translit Chat Logger v1.3 by Sho0ter</h2><hr>"
#define LOGFONT "<font face=^"Verdana^" size=2>"
#define MAX_SWEARS 200
#define MAX_REPLACES 200
#define MAX_IGNORES 200

new g_OriginalSimb[128][32]
new g_TranslitSimb[128][32]

new Swear[MAX_SWEARS][64]
new Replace[MAX_REPLACES][192]
new Ignore[MAX_IGNORES][64]

new p_LogMessage[1024]
new p_LogName[512]
new p_LogMsg[512]
new p_LogInfo[512]
new p_LogTitle[512]
new p_LogFile[128]
new p_LogAlive[128]
new p_LogTeam[64]
new p_LogFileTime[32]
new p_LogIp[32]
new p_LogSteamId[32]
new p_LogTime[32]
new p_LogDir[64]

new Message[192]
new p_Message[128]
new p_Name[64]
new s_Msg[128]
new s_Name[64]
new StrName[64]
new p_Team[32]
new Alive[32]

new p_FilePath[64]
new s_ConfigsDir[64]
new s_File[64]
new s_ConfigFile[64]
new s_SwearFile[64]
new s_IgnoreFile[64]
new s_ReplaceFile[64]


new Input[32]
new Info[128]
new TeamColor[10]
new TeamName[10]
new s_Info[2]

new g_Translit
new g_Log
new g_NameColor
new g_AllChat
new g_AdminPrefix
new g_Listen
new g_ChatColor
new g_SwearFilter
new g_AutoRus
new g_ShowInfo
new g_SwearImmunity
new g_Ignore

new isAlive
new StrTeam
new i_MaxSimbols
new SayText
new TeamInfo
new SwearNum
new ReplaceNum
new IgnoreNum
new Line
new Len

new bool:SwearList
new bool:ReplaceList
new bool:ConfigsList
new bool:TranslitList
new bool:IgnoreList

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_dictionary("colored_translit.txt")
	
	g_Translit = register_cvar("amx_translit", "1")
	g_Log = register_cvar("amx_translit_log", "1")
	g_NameColor = register_cvar("amx_name_color", "6")
	g_AllChat = register_cvar("amx_allchat", "0")
	g_AdminPrefix = register_cvar("amx_admin_prefix", "1")
	g_Listen = register_cvar("amx_listen", "1")
	g_ChatColor = register_cvar("amx_chat_color", "1")
	g_SwearFilter = register_cvar("amx_swear_filter", "1")
	g_AutoRus = register_cvar("amx_auto_rus", "1")
	g_ShowInfo = register_cvar("amx_show_info", "1")
	g_SwearImmunity = register_cvar("amx_swear_immunity", "1")
	g_Ignore = register_cvar("amx_ignore", "1")
	
	register_clcmd("say", "hook_say")
	register_clcmd("say_team", "hook_say_team")
	register_clcmd("say /rus", "cmd_rus")
	register_clcmd("say /eng", "cmd_eng")
	register_clcmd("say_team /rus", "cmd_rus")
	register_clcmd("say_team /eng", "cmd_eng")
	
	SayText = get_user_msgid("SayText")
	TeamInfo = get_user_msgid("TeamInfo")

	get_localinfo("amxx_logs", p_FilePath, 63)
}

public plugin_cfg()
{
	get_configsdir(s_ConfigsDir, 63)
	format(s_File, 63, "%s/translit/translit.ini", s_ConfigsDir)
	format(s_SwearFile, 63, "%s/translit/swears.ini", s_ConfigsDir)
	format(s_ReplaceFile, 63, "%s/translit/replaces.ini", s_ConfigsDir)
	format(s_IgnoreFile, 63, "%s/translit/ignores.ini", s_ConfigsDir)
	format(s_ConfigFile, 63, "%s/translit/config.cfg", s_ConfigsDir)
	if(file_exists(s_File))
	{
		while((Line = read_file(s_File, Line, Input, 31, Len)) != 0)
		{
			strtok(Input, g_OriginalSimb[i_MaxSimbols], 16, g_TranslitSimb[i_MaxSimbols], 16, ' ')
			i_MaxSimbols++
		}
		TranslitList = true
	}
	else
	{
		set_pcvar_num(g_Translit, 0)
		TranslitList = false
	}
	if(file_exists(s_SwearFile))
	{
		new i=0
		while(i < MAX_SWEARS && read_file(s_SwearFile, i , Swear[SwearNum], 63, Len))
		{
			i++
			if(Swear[SwearNum][0] == ';' || Len == 0)
			{
				continue
			}
			SwearNum++
		}
		SwearList = true
	}
	else
	{
		set_pcvar_num(g_SwearFilter, 0)
		SwearList = false
	}
	if(file_exists(s_ReplaceFile))
	{
		new i=0
		while(i < MAX_REPLACES && read_file(s_ReplaceFile, i , Replace[ReplaceNum], 191, Len))
		{
			i++
			if(Replace[ReplaceNum][0] == ';' || Len == 0)
			{
				continue
			}
			ReplaceNum++
		}
		ReplaceList = true
	}
	else
	{
		set_pcvar_num(g_SwearFilter, 0)
		ReplaceList = false
	}
	if(file_exists(s_IgnoreFile))
	{
		new i=0
		while(i < MAX_IGNORES && read_file(s_IgnoreFile, i , Ignore[IgnoreNum], 63, Len))
		{
			i++
			if(Ignore[IgnoreNum][0] == ';' || Len == 0)
			{
				continue
			}
			IgnoreNum++
		}
		IgnoreList = true
	}
	else
	{
		set_pcvar_num(g_Ignore, 0)
		IgnoreList = false
	}
	if(file_exists(s_ConfigFile))
	{
		server_cmd("exec %s", s_ConfigFile)
		ConfigsList = true
	}
	else
	{
		ConfigsList = false
	}
	server_print("========== [%s] START SET FCVAR ==========", PLUGIN)
	register_cvar("Colored Translit Version", "1.3", FCVAR_SERVER)
	if(TranslitList)
	{
		register_cvar("Colored Translit Status", "Loaded", FCVAR_SERVER)
	}
	else
	{
		register_cvar("Colored Translit Status", "Failed", FCVAR_SERVER)
	}
	if(SwearList)
	{
		register_cvar("Colored Translit Swear", "Loaded", FCVAR_SERVER)
	}
	else
	{
		register_cvar("Colored Translit Swear", "Failed", FCVAR_SERVER)
	}
	if(ReplaceList)
	{
		register_cvar("Colored Translit Replace", "Loaded", FCVAR_SERVER)
	}
	else
	{
		register_cvar("Colored Translit Replace", "Failed", FCVAR_SERVER)
	}
	if(IgnoreList)
	{
		register_cvar("Colored Translit Ignores", "Loaded", FCVAR_SERVER)
	}
	else
	{
		register_cvar("Colored Translit Ignores", "Failed", FCVAR_SERVER)
	}
	if(ConfigsList)
	{
		register_cvar("Colored Translit Config", "Loaded", FCVAR_SERVER)
	}
	else
	{
		register_cvar("Colored Translit Config", "Failed", FCVAR_SERVER)
	}
	server_print("=========== [%s] END SET FCVAR ===========", PLUGIN)
	server_print("=========== [%s] START DEBUG =============", PLUGIN)
	if(TranslitList)
	{
		server_print("[%s] Translit File Loaded. Simbols: %d", PLUGIN, i_MaxSimbols)
	}
	else
	{
		server_print("[%s] Translit File Non Found: %s", PLUGIN, s_File)
	}
	if(SwearList)
	{
		server_print("[%s] Swear File Loaded. Swears: %d", PLUGIN, SwearNum)	
	}
	else
	{
		server_print("[%s] Swear File Not Found: %s", PLUGIN, s_SwearFile)
	}
	if(ReplaceList)
	{
		server_print("[%s] Replace File Loaded. Replaces: %d", PLUGIN, ReplaceNum)	
	}
	else
	{
		server_print("[%s] Replace File Not Found: %s", PLUGIN, s_ReplaceFile)
	}
	if(IgnoreList)
	{
		server_print("[%s] Ignore File Loaded. Ignores: %d", PLUGIN, IgnoreNum)
	}
	else
	{
		server_print("[%s] File Not Found: %s", PLUGIN, s_IgnoreFile)
	}
	if(ConfigsList)
	{
		server_print("[%s] Config File Executed. Version: %s", PLUGIN, VERSION)
	}
	else
	{
		server_print("[%s] Config File Not Found: %s", PLUGIN, s_ConfigFile)
	}
	server_print("=========== [%s] END DEBUG ===============", PLUGIN)
	return PLUGIN_CONTINUE
}

public client_disconnect(id)
{
	remove_task(id)
	return PLUGIN_CONTINUE
}

public client_putinserver(id)
{
	set_task(10.0, "ShowInfo", id)
	return PLUGIN_CONTINUE
}

public cmd_eng(id)
{
	if(!is_user_connected(id))
	{
		return PLUGIN_CONTINUE
	}
	client_cmd(id, "setinfo translit 0")
	format(Info, 127, "^x04[%s] ^x01%L", PLUGIN, LANG_PLAYER, "CT_ENG")
	WriteMessage(id, Info)
	return PLUGIN_CONTINUE
}

public cmd_rus(id)
{
	if(!is_user_connected(id))
	{
		return PLUGIN_CONTINUE
	}
	client_cmd(id, "setinfo translit 1")
	format(Info, 127, "^x04[%s] ^x01%L", PLUGIN, LANG_PLAYER, "CT_RUS")
	WriteMessage(id, Info)
	return PLUGIN_CONTINUE
}

public ShowInfo(id)
{
	if(get_pcvar_num(g_AutoRus) == 1)
	{
		client_cmd(id, "setinfo translit 1")
	}
	if(get_pcvar_num(g_ShowInfo) == 1)
	{
		if(!is_user_connected(id))
		{
			return PLUGIN_CONTINUE
		}
		format(Info, 127, "^x04[%s] ^x01%L", PLUGIN, LANG_PLAYER, "CT_INFO_RUS")
		WriteMessage(id, Info)
		format(Info, 127, "^x04[%s] ^x01%L", PLUGIN, LANG_PLAYER, "CT_INFO_ENG")
		WriteMessage(id, Info)
	}
	return PLUGIN_CONTINUE
}

public hook_say(id)
{
	if(is_user_hltv(id) || is_user_bot(id))
	{
		return PLUGIN_CONTINUE
	}
	read_args(s_Msg, 127)
	remove_quotes(s_Msg)
	if(s_Msg[0] == '@' || s_Msg[0] == '/' || s_Msg[0] == '!' || equal(s_Msg, " "))
	{
		return PLUGIN_CONTINUE
	}
	if(get_pcvar_num(g_Ignore) == 1)
	{
		new i = 0
		while(i < IgnoreNum)
		{
			if(containi(s_Msg, Ignore[i++]) != -1)
			{
				i = IgnoreNum
				return PLUGIN_CONTINUE
			}
		}
	}
	get_time("20%y.%m.%d", p_LogFileTime, 31)
	get_time("%H:%M:%S", p_LogTime, 31)
	if(get_pcvar_num(g_Translit) == 1)
	{
		get_user_info(id, "translit", s_Info, 1)
		if(equal(s_Info, "1"))
		{
			for(new i; i < i_MaxSimbols; i++)
			{
				if(contain(s_Msg, g_OriginalSimb[i]) != -1)
				{
					replace_all(s_Msg, 191, g_OriginalSimb[i], g_TranslitSimb[i])
				}
			}
		}
	}
	get_user_name(id, s_Name, 63)
	if(get_user_flags(id) & ACCESS_LEVEL && get_pcvar_num(g_AdminPrefix) == 1)
	{
		format(StrName, 63, "[%L] %s", LANG_PLAYER, "CT_ADMIN", s_Name)
	}
	else
	{
		format(StrName, 63, "%s", s_Name)
	}
	if(is_user_alive(id))
	{
		isAlive = 1
		format(Alive, 31, "^x01")
		format(p_LogAlive, 31, "")
	}
	else
	{
		isAlive = 0
		format(Alive, 31, "^x01*%L* ", LANG_PLAYER, "CT_DEAD")
		format(p_LogAlive, 127, "<font color=^"#FFB41E^">*%L* </font>", LANG_PLAYER, "CT_DEAD")
	}
	static color[10]
	if(get_user_flags(id) & ACCESS_LEVEL)
	{
		switch(get_pcvar_num(g_NameColor))
		{
			case 1:
			{
				format(p_Name, 64, "%s%s", Alive, StrName)
				format(p_LogName, 511, "%s<font color=^"#FFB41E^">%s</font>", p_LogAlive, StrName)
			}
			case 2:
			{
				format(p_Name, 64, "%s^x04%s", Alive, StrName)
				format(p_LogName, 511, "%s<font color=^"green^">%s</font>", p_LogAlive, StrName)
			}
			case 3:
			{
				color = "SPECTATOR"
				format(p_Name, 64, "%s^x03%s", Alive, StrName)
				format(p_LogName, 511, "%s<font color=^"gray^">%s</font>", p_LogAlive, StrName)
			}
			case 4:
			{
				color = "CT"
				format(p_Name, 64, "%s^x03%s", Alive, StrName)
				format(p_LogName, 511, "%s<font color=^"blue^">%s</font>", p_LogAlive, StrName)
			}
			case 5:
			{
				color = "TERRORIST"
				format(p_Name, 64, "%s^x03%s", Alive, StrName)
				format(p_LogName, 511, "%s<font color=^"red^">%s</font>", p_LogAlive, StrName)
			}
			case 6:
			{
				get_user_team(id, color, 9)
				format(p_Name, 64, "%s^x03%s", Alive, StrName)
				if(equal(color, "CT"))
				{
					format(p_LogName, 511, "%s<font color=^"blue^">%s</font>", p_LogAlive, StrName)
				}
				if(equal(color, "TERRORIST"))
				{
					format(p_LogName, 511, "%s<font color=^"red^">%s</font>", p_LogAlive, StrName)
				}
				if(equal(color, "SPECTATOR"))
				{
					format(p_LogName, 511, "%s<font color=^"gray^">%s</font>", p_LogAlive, StrName)
				}
			}
		}
		switch(get_pcvar_num(g_ChatColor))
		{
			case 1:
			{
				format(p_Message, 127, "%s", s_Msg)
				format(p_LogMsg, 511, "<font color=^"#FFB41E^">%s</font>", s_Msg)
			}
			case 2:
			{
				format(p_Message, 127, "^x04%s", s_Msg)
				format(p_LogMsg, 511, "<font color=^"green^">%s</font>", s_Msg)
			}
			case 3:
			{
				copy(color, 9, "SPECTATOR")
				format(p_Message, 127, "^x03%s", s_Msg)
				format(p_LogMsg, 511, "<font color=^"gray^">%s</font>", s_Msg)
			}
			case 4:
			{
				copy(color, 9, "CT")
				format(p_Message, 127, "^x03%s", s_Msg)
				format(p_LogMsg, 511, "<font color=^"blue^">%s</font>", s_Msg)
			}
			case 5:
			{
				copy(color, 9, "TERRORIST")
				format(p_Message, 127, "^x03%s", s_Msg)
				format(p_LogMsg, 511, "<font color=^"red^">%s</font>", s_Msg)
			}
			case 6:
			{
				get_user_team(id, TeamColor, 9)
				copy(color, 9, TeamColor)
				format(p_Message, 127, "^x03%s", s_Msg)
				if(equal(TeamColor, "CT"))
				{
					format(p_LogMsg, 511, "<font color=^"blue^">%s</font>", s_Msg)
				}
				if(equal(TeamColor, "TERRORIST"))
				{
					format(p_LogMsg, 511, "<font color=^"red^">%s</font>", s_Msg)
				}
				if(equal(TeamColor, "SPECTATOR"))
				{
					format(p_LogMsg, 511, "<font color=^"gray^">%s</font>", s_Msg)
				}
			}
		}
	}
	else
	{
		get_user_team(id, color, 9)
		format(p_Name, 64, "%s^x03%s", Alive, StrName)
		format(p_Message, 127, "%s", s_Msg)
		if(equal(color, "CT"))
		{
			format(p_LogName, 511, "%s<font color=^"blue^">%s</font>", p_LogAlive, StrName)
		}
		if(equal(color, "TERRORIST"))
		{
			format(p_LogName, 511, "%s<font color=^"red^">%s</font>", p_LogAlive, StrName)
		}
		if(equal(color, "SPECTATOR"))
		{
			format(p_LogName, 511, "%s<font color=^"gray^">%s</font>", p_LogAlive, StrName)
		}
		format(p_LogMsg, 511, "<font color=^"#FFB41E^">%s</font>", s_Msg)
	}
	if(get_pcvar_num(g_SwearFilter) == 1)
	{
		new i = 0
		if(get_user_flags(id) & ACCESS_LEVEL && get_pcvar_num(g_SwearImmunity) == 1)
		{	
			i = SwearNum
		}
		while(i < SwearNum )
		{
	
			if(containi(s_Msg, Swear[i++]) != -1)
			{
				i = SwearNum
				new j, playercount, players[32], replace = random(ReplaceNum)
				get_players( players, playercount, "c" )
				for(j = 0 ; j < playercount ; j++)
				{
					if(get_user_flags(players[j]) & ACCESS_LEVEL)	
					{
						client_print( players[j], print_chat, "[%s] %s : %s", PLUGIN, s_Name, s_Msg)
					}
				}
				format(p_Message, 191, "%s", Replace[replace])
			}
		}
	}
	format(Message, 191, "%s ^x01: %s", p_Name, p_Message)
	switch(get_pcvar_num(g_AllChat))
	{
		case 0:
		{
			SendMessage(color, isAlive)
		}
		case 1:
		{
			SendMessageAll(color)
		}
		case 2:
		{
			if(get_user_flags(id) & ACCESS_LEVEL)
			{
				SendMessageAll(color)
			}
			else
			{
				SendMessage(color, isAlive)
			}
		}
	}
	if(get_pcvar_num(g_Log) == 1)
	{
		format(p_LogDir, 63, "%s/translit", p_FilePath)
		format(p_LogFile, 127, "%s/chat_%s.htm", p_LogDir, p_LogFileTime)
		if(!dir_exists(p_LogDir))
		{
			mkdir(p_LogDir)
		}
		if(!file_exists(p_LogFile))
		{
			format(p_LogTitle, 511, "<title>Colored Ctranslit Chat Log v1.3 by Sho0ter - %s</title>%s", p_LogFileTime, LOGTITLE)
			write_file(p_LogFile, p_LogTitle)
			write_file(p_LogFile, LOGFONT)
		}
		get_user_ip(id, p_LogIp, 31, 1)
		get_user_authid(id, p_LogSteamId, 31)
		format(p_LogInfo, 511, "<font color=^"black^">%s &lt;%s&gt;&lt;%s&gt;</font>", p_LogTime, p_LogSteamId, p_LogIp)
		format(p_LogMessage, 1023, "%s %s : %s<br>", p_LogInfo, p_LogName, p_LogMsg)
		write_file(p_LogFile, p_LogMessage)
	}
	return PLUGIN_HANDLED
}

public hook_say_team(id)
{
	if(is_user_hltv(id) || is_user_bot(id))
	{
		return PLUGIN_CONTINUE
	}
	read_args(s_Msg, 191)
	remove_quotes(s_Msg)
	if(s_Msg[0] == '@' || s_Msg[0] == '/' || s_Msg[0] == '!' || equal(s_Msg, " "))
	{
		return PLUGIN_CONTINUE
	}
	if(get_pcvar_num(g_Ignore) == 1)
	{
		new i = 0
		while(i < IgnoreNum)
		{
			if(containi(s_Msg, Ignore[i++]) != -1)
			{
				i = IgnoreNum
				return PLUGIN_CONTINUE
			}
		}
	}
	get_time("20%y.%m.%d", p_LogFileTime, 31)
	get_time("%H:%M:%S", p_LogTime, 31)
	StrTeam = get_user_team(id)
	switch(StrTeam)
	{
		case 1:
		{
			format(p_Team, 31, "(%L)", LANG_PLAYER, "CT_TERRORIST")
			format(p_LogTeam, 63, "<font color=^"#FFB41E^">(%L) <font>", LANG_PLAYER, "CT_TERRORIST")
		}
		case 2:
		{
			format(p_Team, 31, "(%L)", LANG_PLAYER, "CT_CT")
			format(p_LogTeam, 63, "<font color=^"#FFB41E^">(%L) </fomt>", LANG_PLAYER, "CT_CT")
		}
		case 3:
		{
			format(p_Team, 31, "(%L)", LANG_PLAYER, "CT_SPECTATOR")
			format(p_LogTeam, 63, "<font color=^"#FFB41E^">(%L) </fomt>", LANG_PLAYER, "CT_SPECTATOR")
		}
	}
	if(get_pcvar_num(g_Translit) == 1)
	{
		get_user_info(id, "translit", s_Info, 1)
		if(equal(s_Info, "1"))
		{
			for(new i; i < i_MaxSimbols; i++)
			{
				if(contain(s_Msg, g_OriginalSimb[i]) != -1)
				{
					replace_all(s_Msg, 191, g_OriginalSimb[i], g_TranslitSimb[i])
				}
			}
		}
	}
	get_user_name(id, s_Name, 31)
	if(get_user_flags(id) & ACCESS_LEVEL && get_pcvar_num(g_AdminPrefix) == 1)
	{
		format(StrName, 127, "[%L] %s", LANG_PLAYER, "CT_ADMIN", s_Name)
	}
	else
	{
		format(StrName, 127, "%s", s_Name)
	}
	if(is_user_alive(id))
	{
		isAlive = 1
		format(Alive, 31, "^x01")
		format(p_LogAlive, 31, "")
	}
	else
	{
		isAlive = 0
		format(Alive, 31, "^x01*%L* ", LANG_PLAYER, "CT_DEAD")
		format(p_LogAlive, 127, "<font color=^"#FFB41E^">*%L* </font>", LANG_PLAYER, "CT_DEAD")
	}
	static color[10]
	if(get_user_flags(id) & ACCESS_LEVEL)
	{
		switch(get_pcvar_num(g_NameColor))
		{
			case 1:
			{
				format(p_Name, 255, "%s%s %s", Alive, p_Team, StrName)
				format(p_LogName, 511, "%s%s<font color=^"#FFB41E^">%s</font>", p_LogAlive, p_LogTeam, StrName)
			}
			case 2:
			{
				format(p_Name, 255, "%s%s ^x04%s", Alive, p_Team, StrName)
				format(p_LogName, 511, "%s%s<font color=^"green^">%s</font>", p_LogAlive, p_LogTeam, StrName)
			}
			case 3:
			{
				color = "SPECTATOR"
				format(p_Name, 255, "%s%s ^x03%s", Alive, p_Team, StrName)
				format(p_LogName, 511, "%s%s<font color=^"gray^">%s</font>", p_LogAlive, p_LogTeam, StrName)
			}
			case 4:
			{
				color = "CT"
				format(p_Name, 255, "%s%s ^x03%s", Alive, p_Team, StrName)
				format(p_LogName, 511, "%s%s<font color=^"blue^">%s</font>", p_LogAlive, p_LogTeam, StrName)
			}
			case 5:
			{
				color = "TERRORIST"
				format(p_Name, 255, "%s%s ^x03%s", Alive, p_Team, StrName)
				format(p_LogName, 511, "%s%s<font color=^"red^">%s</font>", p_LogAlive, p_LogTeam, StrName)
			}
			case 6:
			{
				get_user_team(id, color, 9)
				format(p_Name, 255, "%s%s ^x03%s", Alive, p_Team, StrName)
				if(equal(color, "CT"))
				{
					format(p_LogName, 511, "%s%s<font color=^"blue^">%s</font>", p_LogAlive, p_LogTeam, StrName)
				}
				if(equal(color, "TERRORIST"))
				{
					format(p_LogName, 511, "%s%s<font color=^"red^">%s</font>", p_LogAlive, p_LogTeam, StrName)
				}
				if(equal(color, "SPECTATOR"))
				{
					format(p_LogName, 511, "%s%s<font color=^"gray^">%s</font>", p_LogAlive, p_LogTeam, StrName)
				}
			}
		}
		switch(get_pcvar_num(g_ChatColor))
		{
			case 1:
			{
				format(p_Message, 255, "%s", s_Msg)
				format(p_LogMsg, 511, "<font color=^"#FFB41E^">%s</font>", s_Msg)
			}
			case 2:
			{
				format(p_Message, 255, "^x04%s", s_Msg)
				format(p_LogMsg, 511, "<font color=^"green^">%s</font>", s_Msg)
			}
			case 3:
			{
				copy(color, 9, "SPECTATOR")
				format(p_Message, 191, "^x03%s", s_Msg)
				format(p_LogMsg, 511, "<font color=^"gray^">%s</font>", s_Msg)
			}
			case 4:
			{
				copy(color, 9, "CT")
				format(p_Message, 255, "^x03%s", s_Msg)
				format(p_LogMsg, 511, "<font color=^"blue^">%s</font>", s_Msg)
			}
			case 5:
			{
				copy(color, 9, "TERRORIST")
				format(p_Message, 255, "^x03%s", s_Msg)
				format(p_LogMsg, 511, "<font color=^"red^">%s</font>", s_Msg)
			}
			case 6:
			{
				get_user_team(id, TeamColor, 9)
				copy(color, 9, TeamColor)
				format(p_Message, 255, "^x03%s", s_Msg)
				if(equal(TeamColor, "CT"))
				{
					format(p_LogMsg, 511, "<font color=^"blue^">%s</font>", s_Msg)
				}
				if(equal(TeamColor, "TERRORIST"))
				{
					format(p_LogMsg, 511, "<font color=^"red^">%s</font>", s_Msg)
				}
				if(equal(TeamColor, "SPECTATOR"))
				{
					format(p_LogMsg, 511, "<font color=^"gray^">%s</font>", s_Msg)
				}
			}
		}
	}
	else
	{
		get_user_team(id, color, 9)
		format(p_Name, 255, "%s%s ^x03%s", Alive, p_Team, StrName)
		format(p_Message, 255, "%s", s_Msg)
		if(equal(color, "CT"))
		{
			format(p_LogName, 511, "%s%s<font color=^"blue^">%s</font>", p_LogAlive, p_LogTeam, StrName)
		}
		if(equal(color, "TERRORIST"))
		{
			format(p_LogName, 511, "%s%s<font color=^"red^">%s</font>", p_LogAlive, p_LogTeam, StrName)
		}
		if(equal(color, "SPECTATOR"))
		{
			format(p_LogName, 511, "%s%s<font color=^"gray^">%s</font>", p_LogAlive, p_LogTeam, StrName)
		}
		format(p_LogMsg, 511, "<font color=^"#FFB41E^">%s</font>", s_Msg)
	}
	if(get_pcvar_num(g_SwearFilter) == 1)
	{
		new i = 0
		if(get_user_flags(id) & ACCESS_LEVEL && get_pcvar_num(g_SwearImmunity) == 1)
		{	
			i = SwearNum
		}
		while(i < SwearNum )
		{
			if(containi(s_Msg, Swear[i++]) != -1)
			{
				i = SwearNum
				new j, playercount, players[32], replace = random(ReplaceNum)
				get_players( players, playercount, "c" )
				for(j = 0 ; j < playercount ; j++)
				{
					if(get_user_flags(players[j]) & ACCESS_LEVEL)	
					{
						client_print( players[j], print_chat, "[%s] %s : %s", PLUGIN, s_Name, s_Msg)
					}
				}
				format(p_Message, 255, "%s", Replace[replace])
			}
		}
	}
	format(Message, 511, "%s ^x01: %s", p_Name, p_Message)
	SendTeamMessage(color, isAlive, StrTeam)
	if(get_pcvar_num(g_Log) == 1)
	{
		format(p_LogDir, 63, "%s/translit", p_FilePath)
		format(p_LogFile, 127, "%s/chat_%s.htm", p_LogDir, p_LogFileTime)
		if(!dir_exists(p_LogDir))
		{
			mkdir(p_LogDir)
		}
		if(!file_exists(p_LogFile))
		{
			format(p_LogTitle, 127, "<title>Colored Ctranslit Chat Log v1.3 by Sho0ter - %s</title>%s", p_LogFileTime, LOGTITLE)
			write_file(p_LogFile, p_LogTitle)
			write_file(p_LogFile, LOGFONT)
		}
		get_user_ip(id, p_LogIp, 31, 1)
		get_user_authid(id, p_LogSteamId, 31)
		format(p_LogInfo, 511, "<font color=^"black^">%s &lt;%s&gt;&lt;%s&gt;</font>", p_LogTime, p_LogSteamId, p_LogIp)
		format(p_LogMessage, 1023, "%s %s : %s<br>", p_LogInfo, p_LogName, p_LogMsg)
		write_file(p_LogFile, p_LogMessage)
	}
	return PLUGIN_HANDLED
}

public SendMessage(color[], alive)
{
	for(new player = 0; player < get_maxplayers(); player++)
	{
		if(!is_user_connected(player))
		{
			continue
		}
		if (alive && is_user_alive(player) || !alive && !is_user_alive(player) || get_pcvar_num(g_Listen) && get_user_flags(player) & ACCESS_LEVEL)
		{
			console_print(player, "%s : %s", s_Name, s_Msg)
			get_user_team(player, TeamName, 9)
			ChangeTeamInfo(player, color)
			WriteMessage(player, Message)
			ChangeTeamInfo(player, TeamName)
		}
	}
}

public SendMessageAll(color[])
{
	for(new player = 0; player < get_maxplayers(); player++)
	{
		if(!is_user_connected(player))
		{
			continue
		}
		console_print(player, "%s : %s", s_Name, s_Msg)
		get_user_team(player, TeamName, 9)
		ChangeTeamInfo(player, color)
		WriteMessage(player, Message)
		ChangeTeamInfo(player, TeamName)
	}
}

public SendTeamMessage(color[], alive, playerTeam)
{
	for (new player = 0; player < get_maxplayers(); player++)
	{
		if (!is_user_connected(player))
		{
			continue
		}
		if(get_user_team(player) == playerTeam || get_pcvar_num(g_Listen) && get_user_flags(player) & ACCESS_LEVEL)
		{
			if (alive && is_user_alive(player) || !alive && !is_user_alive(player) || get_pcvar_num(g_Listen) && get_user_flags(player) & ACCESS_LEVEL)
			{
				console_print(player, "%s : %s", s_Name, s_Msg)
				get_user_team(player, TeamName, 9)
				ChangeTeamInfo(player, color)
				WriteMessage(player, Message)
				ChangeTeamInfo(player, TeamName)
			}
		}
	}
}


public ChangeTeamInfo (player, team[])
{
	message_begin (MSG_ONE, TeamInfo, _, player)
	write_byte(player)
	write_string(team)
	message_end()
}


public WriteMessage (player, message[])
{
	message_begin (MSG_ONE, SayText, {0, 0, 0}, player)
	write_byte (player)
	write_string (message)
	message_end()
}
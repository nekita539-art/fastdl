#define VERSION "1.0"
#include <amxmodx>

new name[32]

public plugin_init() {
	register_plugin("Chat Prefix", VERSION, "BaRSiK")
	register_message(get_user_msgid("SayText"), "prefix")
}

public prefix(msgId, msgDest, msgEnt){
	new id = get_msg_arg_int(1)
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE;
	
	get_user_name(id, name, 31)
	if(get_user_flags(id) & ADMIN_CHAT) {
		new szTmp[256],szTmp2[256]
		get_msg_arg_string(2,szTmp, charsmax(szTmp))
		new szPrefix[64] = "^x03[^x04Гл.Администратор^x03]"
		if(!equal(szTmp,"#Cstrike_Chat_All")) {
			add(szTmp2,charsmax(szTmp2),szPrefix)
			add(szTmp2,charsmax(szTmp2)," ")
			add(szTmp2,charsmax(szTmp2),szTmp)
		} else {
			add(szTmp2,charsmax(szTmp2),szPrefix)
			add(szTmp2,charsmax(szTmp2),"^x03 %s1^x01 : ^x04%s2")
		}
		set_msg_arg_string(2,szTmp2)
	} else if(get_user_flags(id) & ADMIN_CFG) {
		new szTmp[256],szTmp2[256]
		get_msg_arg_string(2,szTmp, charsmax(szTmp))
		new szPrefix[64] = "^x03[^x04Заместитель^x03]"
		if(!equal(szTmp,"#Cstrike_Chat_All")) {
			add(szTmp2,charsmax(szTmp2),szPrefix)
			add(szTmp2,charsmax(szTmp2)," ")
			add(szTmp2,charsmax(szTmp2),szTmp)
		} else {
			add(szTmp2,charsmax(szTmp2),szPrefix)
			add(szTmp2,charsmax(szTmp2),"^x03 %s1^x01 : ^x04%s2")
		}
		set_msg_arg_string(2,szTmp2)	
	} else if(get_user_flags(id) & ADMIN_CVAR) {
		new szTmp[256],szTmp2[256]
		get_msg_arg_string(2,szTmp, charsmax(szTmp))
		new szPrefix[64] = "^x03[^x04Шредер^x03]"
		if(!equal(szTmp,"#Cstrike_Chat_All")) {
			add(szTmp2,charsmax(szTmp2),szPrefix)
			add(szTmp2,charsmax(szTmp2)," ")
			add(szTmp2,charsmax(szTmp2),szTmp)
		} else {
			add(szTmp2,charsmax(szTmp2),szPrefix)
			add(szTmp2,charsmax(szTmp2),"^x03 %s1^x01 : ^x04%s2")
		}
		set_msg_arg_string(2,szTmp2)
	} else if(get_user_flags(id) & ADMIN_MAP) {
		new szTmp[256],szTmp2[256]
		get_msg_arg_string(2,szTmp, charsmax(szTmp))
		new szPrefix[64] = "^x03[^x04Бэтмен^x03]"
		if(!equal(szTmp,"#Cstrike_Chat_All")) {
			add(szTmp2,charsmax(szTmp2),szPrefix)
			add(szTmp2,charsmax(szTmp2)," ")
			add(szTmp2,charsmax(szTmp2),szTmp)
		} else {
			add(szTmp2,charsmax(szTmp2),szPrefix)
			add(szTmp2,charsmax(szTmp2),"^x03 %s1^x01 : ^x04%s2")
		}
		set_msg_arg_string(2,szTmp2)	
	} else if(get_user_flags(id) & ADMIN_SLAY) {
		new szTmp[256],szTmp2[256]
		get_msg_arg_string(2,szTmp, charsmax(szTmp))
		new szPrefix[64] = "^x03[^x04Супер-Админ^x03]"
		if(!equal(szTmp,"#Cstrike_Chat_All")) {
			add(szTmp2,charsmax(szTmp2),szPrefix)
			add(szTmp2,charsmax(szTmp2)," ")
			add(szTmp2,charsmax(szTmp2),szTmp)
		} else {
			add(szTmp2,charsmax(szTmp2),szPrefix)
			add(szTmp2,charsmax(szTmp2),"^x03 %s1^x01 : ^x04%s2")
		}
		set_msg_arg_string(2,szTmp2)	
	} else if(get_user_flags(id) & ADMIN_BAN) {
		new szTmp[256],szTmp2[256]
		get_msg_arg_string(2,szTmp, charsmax(szTmp))
		new szPrefix[64] = "^x03[^x04Админ^x03]"
		if(!equal(szTmp,"#Cstrike_Chat_All")) {
			add(szTmp2,charsmax(szTmp2),szPrefix)
			add(szTmp2,charsmax(szTmp2)," ")
			add(szTmp2,charsmax(szTmp2),szTmp)
		} else {
			add(szTmp2,charsmax(szTmp2),szPrefix)
			add(szTmp2,charsmax(szTmp2),"^x03 %s1^x01 : ^x04%s2")
		}
		set_msg_arg_string(2,szTmp2)	
	} else if(get_user_flags(id) & ADMIN_KICK) {
		new szTmp[256],szTmp2[256]
		get_msg_arg_string(2,szTmp, charsmax(szTmp))
		new szPrefix[64] = "^x03[^x04Супер-Вип^x03]"
		if(!equal(szTmp,"#Cstrike_Chat_All")) {
			add(szTmp2,charsmax(szTmp2),szPrefix)
			add(szTmp2,charsmax(szTmp2)," ")
			add(szTmp2,charsmax(szTmp2),szTmp)
		} else {
			add(szTmp2,charsmax(szTmp2),szPrefix)
			add(szTmp2,charsmax(szTmp2),"^x03 %s1^x01 : ^x04%s2")
		}
		set_msg_arg_string(2,szTmp2)
	} else if(get_user_flags(id) & ADMIN_LEVEL_H) {
		new szTmp[256],szTmp2[256]
		get_msg_arg_string(2,szTmp, charsmax(szTmp))
		new szPrefix[64] = "^x03[^x04Вип^x03]"
		if(!equal(szTmp,"#Cstrike_Chat_All")) {
			add(szTmp2,charsmax(szTmp2),szPrefix)
			add(szTmp2,charsmax(szTmp2)," ")
			add(szTmp2,charsmax(szTmp2),szTmp)
		} else {
			add(szTmp2,charsmax(szTmp2),szPrefix)
			add(szTmp2,charsmax(szTmp2),"^x03 %s1^x01 : ^x04%s2")
		}
		set_msg_arg_string(2,szTmp2)	
	} else if(get_user_flags(id) & ADMIN_ALL) {
		new szTmp[256],szTmp2[256]
		get_msg_arg_string(2,szTmp, charsmax(szTmp))
		new szPrefix[64] = "^x03[^x04Игрок^x03]"
		if(!equal(szTmp,"#Cstrike_Chat_All")) {
			add(szTmp2,charsmax(szTmp2),szPrefix)
			add(szTmp2,charsmax(szTmp2)," ")
			add(szTmp2,charsmax(szTmp2),szTmp)
		} else {
			add(szTmp2,charsmax(szTmp2),szPrefix)
			add(szTmp2,charsmax(szTmp2),"^x03 %s1^x01 : ^x04%s2")
		}
		set_msg_arg_string(2,szTmp2)	
	}
	return PLUGIN_CONTINUE;
}
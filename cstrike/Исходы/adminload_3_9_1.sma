/**
*
* Name: Admin Load
* Version: 3.9.1 (24.11.2016)
* Author: F@nt0M
* Description: The plugin is written to speed up load administrators from database/file, and make backups in case you will not be available database/file.
*
* Thanks: community GoldSrc, a2, h1k3 and others
* Supported: AmxBans 1.6 GM, AmxBans 6.13, FreshBans 1.0.5b or higher
* Requirements: AmxModX 1.8.2 or higher
* 
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
* 
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
* 
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>
*
*/

/////////////////////////////////////////////////// START OF CONFIG
#define DISCONECT_FWD 					// Use client_disconnect insted of client_disconnected on AMXX 1.8.3
// #define DEBUG 						// Enable debug mod
// #define FUNC_ADD_ADMIN				// Enable add admin functionality. Be careful. This is beta feature

#define FLAGS_SET_ID 1					// Flags SET ID for saving state of player. Valid values: from 1 up to 32. DO NOT COMMENT THIS LINE
#define BACKUP_FILENAME "users.bak"		// Name of backup file. DO NOT COMMENT THIS LINE
#define FRESH_BANS_TIMEOUT 1.0			// Fresh bans connection timeout. DO NOT COMMENT THIS LINE

new const g_StopPlugins[][] = {
	"admin.amxx",
	"admin_sql.amxx",
	"amxbans_core.amxx",
	"admin_loader.amxx"
};

/**
* Check priority
*
* s - STEAM_ID
* i - IP
* n - NAME
* c - CASESENSITIVE
* t - CLAN TAG
*/
new const g_DefaultPriority[] = "sinct";
/////////////////////////////////////////////////// END OF CONFIG

#include <amxmodx>
#include <sqlx>

#if !defined MAX_PLAYERS
#define MAX_PLAYERS 32
#endif
#if !defined MAX_NAME_LENGTH
#define MAX_NAME_LENGTH 32
#endif

#if AMXX_VERSION_NUM < 183
new MaxClients;
#endif

#if defined client_disconnected && !defined DISCONECT_FWD
#define fwd_client_disconnected client_disconnected
#else
#define fwd_client_disconnected client_disconnect
#endif

forward fbans_sql_connected(Handle:sqlTuple);

#define VERSION "3.9.1"
#define LOG_TAG "AdminLoad"

#define BACKUP_VERSION 4
#define FRESH_BANS_TASK_ID 3528

#define CHECK_PLAYER(%1) \
	if (%1 < 1 || %1 > MaxClients) { \
		log_error(AMX_ERR_NATIVE, "Player out of range (%d)", %1); \
		return 0; \
	} else if (!is_user_connected(%1) && !is_user_connecting(%1)) { \
		log_error(AMX_ERR_NATIVE, "Invalid player %d", %1); \
		return 0; \
	}

const FLAG_CHECK_NICK = (1<<11);  /* flag "l" */
const FLAG_RESERV_NICK = (1<<12);  /* flag "m" */

const BACKUP_LOAD_DB = (1<<1);
const BACKUP_LOAD_FILE = (1<<2);

enum (<<=1) {
	PDATA_DISCONNECTED = 1,
	PDATA_CONNECTING,
	PDATA_CONNECTED,
	PDATA_ADMIN,
	PDATA_CASESENSITIVE,
	PDATA_STATICBANTIME
}

#define add_user_state(%1,%2) 		set_user_flags(%1, %2, FLAGS_SET_ID)
#define get_user_state(%1,%2) 		(get_user_flags(%1, FLAGS_SET_ID) & %2)
#define remove_user_state(%1,%2) 	remove_user_flags(%1, %2, FLAGS_SET_ID)
#define clear_user_state(%1) 		remove_user_flags(%1, -1, FLAGS_SET_ID)

new pcvar_AmxMode;

new g_ServerAddress[22];
new g_DefaultAccess;
new g_HLTVAccess;
new g_BOTAccess;
new g_LoadType;
new g_LogType;
new g_BackupTime;
new g_HashDB;
new g_HashFile;

new g_LogFile[128];

new g_DbPrefix[32];
new g_PasswordField[32];

enum _:MFHANDLE_TYPES {
	Adminload_Sql_Initialized = 0,
	Adminload_Sql_Fail,
	Adminload_Loaded,
	Adminload_Connect,
	Adminload_Disconnect
};

new MFReturn;
new MFHandle[MFHANDLE_TYPES];

new g_BackupFile;
new bool:g_BackupMake = false;
new g_BackupLoadType;

new Handle:g_DBTuple;

new g_ServerId;

enum (+=1) {
	STATUS_NONE = 0,
	STATUS_CONFIG,
	STATUS_LOAD,
	STATUS_LOADED,
	STATUS_RELOADING
}

new g_Status = STATUS_NONE;
new bool:g_FreshBans = false;

new bool:g_CheckNick = false;

enum _:AdminData {
	AdminId,
	AdminPass[34],
	AdminAccess,
	AdminFlags,
	AdminNick[MAX_NAME_LENGTH],
	AdminExpired,
	bool:AdminStaticBandtime,
	bool:AdminPassHashed,
	bool:AdminLoadDB
};

new g_AdminData[AdminData];
new Trie:g_Admins;

enum _:ClanTags {
	ClanTag[MAX_NAME_LENGTH],
	ClanTagKey[40],
	bool:ClanTagCase
}
new g_ClanTag[ClanTags];
new Array:g_ClanTags;
new g_ClanTagsNum;

new Trie:g_ReservedNicks;

enum _:AdminCache {
	CacheId,
	CacheExpired,
	CacheNick[MAX_NAME_LENGTH],
}

new g_AdminCache[MAX_PLAYERS+1][AdminCache];

#if defined FUNC_ADD_ADMIN
enum (<<=1) {
	ADMINLOAD_ADD_FILE = 1,
	ADMINLOAD_ADD_DB,
	ADMINLOAD_ADD_REPLACE
}

enum _:AdminsList {
	AdminListAuth[44],
	AdminListFlags,
	AdminListId,
	bool:AdminListDB
}

new Array:g_AdminsList;
new g_AdminsListElement[AdminsList];
#endif

public plugin_init()
{
	register_plugin("Admin Load", VERSION, "F@nt0M");
	register_cvar("adminload_version", VERSION, FCVAR_SERVER | FCVAR_SPONLY);

	register_concmd("amx_reloadadmins", "cmdReload", ADMIN_CFG);
	register_concmd("amx_admins", "cmdAdmins", ADMIN_CFG);
	register_concmd("amx_reloadadminscfg", "cmdReloadCfg", ADMIN_CFG);

	#if defined FUNC_ADD_ADMIN
	register_concmd("amx_addadmin", "cmdAddAdmin", ADMIN_CFG);
	#endif

	#if AMXX_VERSION_NUM < 183
	MaxClients = get_maxplayers();
	#endif

	register_cvar("amx_sql_host", "127.0.0.1");
	register_cvar("amx_sql_user", "root");
	register_cvar("amx_sql_pass", "");
	register_cvar("amx_sql_db", "amx");
	register_cvar("amx_sql_type", "mysql");
	register_cvar("amx_sql_prefix", "amx");

	register_cvar("amx_password_field", "_pw");
	register_cvar("amx_default_access", "z");
	register_cvar("adminload_hltv_access", "a");
	register_cvar("adminload_bot_access", "a");
	register_cvar("adminload_server_address", "");
	register_cvar("adminload_load_type", "1");
	register_cvar("adminload_log_type", "1");
	register_cvar("adminload_backup_timecheck", "24");
	register_cvar("adminload_hash_db", "1");
	register_cvar("adminload_hash_file", "0");

	pcvar_AmxMode = register_cvar("amx_mode", "1");

	remove_user_flags(0, read_flags("z"));
	
	ExecuteCfg();

	g_Admins = TrieCreate();

	RegisterForwards();

	register_default_cvars();
}

#if defined OnConfigsExecuted
public OnConfigsExecuted()
#else
public plugin_cfg()
#endif
{
	#if defined g_StopPlugins
	for (new i = 0; i < sizeof g_StopPlugins; i++) {
		if (pause("acd", g_StopPlugins[i])) {
			LogError("Plugin %s is enabled. Please disable it", g_StopPlugins[i]);
		}	
	}
	#endif

	CacheCvars();

	if (!checkPluginRunning("FreshBan", "kanagava")) {
		g_Status = STATUS_LOAD;
		LoadAdmins(false);
	} else if (g_Status >= STATUS_LOAD) {
		LoadAdmins(false);
	} else {
		g_Status = STATUS_CONFIG;
		set_task(FRESH_BANS_TIMEOUT, "TaskFBansTimeout", FRESH_BANS_TASK_ID);
	}
}

public plugin_end() 
{
	if (g_DBTuple != Empty_Handle && !g_FreshBans) {
		SQL_FreeHandle(g_DBTuple);
	}

	TrieDestroy(g_Admins);

	if (g_ClanTags != Invalid_Array) {
		ArrayDestroy(g_ClanTags);
	}

	if (g_ReservedNicks != Invalid_Trie) {
		TrieDestroy(g_ReservedNicks);
	}

	#if defined FUNC_ADD_ADMIN
	if (g_AdminsList != Invalid_Array) {
		ArrayDestroy(g_AdminsList);
	}
	#endif

	UnregisterForwards();
}

public plugin_natives() 
{
	register_library("AMXBansCore");
	register_native("amxbans_get_db_prefix", "native_get_prefix", 0);
	register_native("amxbans_get_admin_nick", "native_get_nick", 0);
	register_native("amxbans_get_static_bantime", "native_static_bantime", 0);

	register_native("adminload_reloadadmins", "native_reloadadmins", 0);
	register_native("adminload_get_server_id", "native_get_server_id", 0);
	register_native("adminload_get_id", "native_get_id", 0);
	register_native("adminload_is_admin", "native_is_admin", 0);
	register_native("adminload_get_expired", "native_get_expired", 0);
	register_native("adminload_get_daysleft", "native_get_daysleft", 0);

	#if defined FUNC_ADD_ADMIN
	register_native("adminload_add_admin", "native_add_admin", 0);
	#endif
}

public client_authorized(id)
{
	clear_user_state(id);
	add_user_state(id, PDATA_CONNECTING);

	if (is_user_hltv(id)) {
		set_user_flags(id, g_HLTVAccess);
	} else if (is_user_bot(id)) {
		set_user_flags(id, g_BOTAccess);
	} else if (g_Status == STATUS_LOADED) {
		CheckPlayer(id);
	}
}

public client_putinserver(id)
{
	if (!get_user_state(id, PDATA_CONNECTING)) {
		if (is_user_hltv(id)) {
			set_user_flags(id, g_HLTVAccess);
		} else if (is_user_bot(id)) {
			set_user_flags(id, g_BOTAccess);
		} else if (g_Status == STATUS_LOADED) {
			CheckPlayer(id);
		}
	} else {
		remove_user_state(id, PDATA_CONNECTING);
	}

	add_user_state(id, PDATA_CONNECTED);

	if (g_Status == STATUS_LOADED && get_user_state(id, PDATA_ADMIN)) {
		LogLogin(id);
	}
}

public fwd_client_disconnected(id)
{
	if (get_user_state(id, PDATA_ADMIN)) {
		execFwd(Adminload_Disconnect, id);
		LogLogout(id);
	}

	ClearCache(id);

	clear_user_state(id);
	add_user_state(id, PDATA_DISCONNECTED);
	set_user_flags(id, g_DefaultAccess);
}

public client_infochanged(id)
{
	if (g_Status != STATUS_LOADED || !get_user_state(id, PDATA_CONNECTED) || !get_pcvar_num(pcvar_AmxMode) || is_user_hltv(id) || is_user_bot(id)) {
		return PLUGIN_CONTINUE;
	}

	new newname[MAX_NAME_LENGTH], oldname[MAX_NAME_LENGTH];
   
	get_user_name(id, oldname, 31);
	get_user_info(id, "name", newname, 31);

	new oldId = g_AdminCache[id][CacheId];
	new bool:oldAdmin = get_user_state(id, PDATA_ADMIN) ? true : false;
	new caseSensitive = (oldAdmin && get_user_state(id, PDATA_CASESENSITIVE)) ? 1 : 0;
	if (strcmp(newname, oldname, caseSensitive) != 0) {
		CheckAccess(id, newname);
		if (!oldAdmin && get_user_state(id, PDATA_ADMIN)) {
			execFwd(Adminload_Connect, id);
			LogLogin(id, newname);
		} else if (oldAdmin && !get_user_state(id, PDATA_ADMIN)) {
			execFwd(Adminload_Disconnect, id);
			LogLogout(id, oldname);
		} else if (oldAdmin && get_user_state(id, PDATA_ADMIN) && oldId != g_AdminCache[id][CacheId]) {
			execFwd(Adminload_Disconnect, id);
			LogLogout(id, oldname);
			execFwd(Adminload_Connect, id);
			LogLogin(id, newname);
		}
	}
	
	return PLUGIN_CONTINUE;
}

public cmdReload(id, level)
{
	if (~get_user_flags(id) & level) {
		console_print(id, "You have no access to that command");
		return PLUGIN_HANDLED;
	}

	ReloadAdmins();

	new name[MAX_NAME_LENGTH], authid[22], ip[16];
	get_user_name(id, name, charsmax(name));
	get_user_authid(id, authid, charsmax(authid));
	get_user_ip(id, ip, charsmax(ip), 1);

	LogAction("Admin <%s><%s><%s> run reload admins", name, authid, ip);

	console_print(id, "[%s] Admins reloaded successfully", LOG_TAG);

	return PLUGIN_HANDLED;
}

public cmdAdmins(id, level)
{
	if (~get_user_flags(id) & level) {
		console_print(id, "You have no access to that command");
		return PLUGIN_HANDLED;
	}

	new num = admins_num();

	if (num == 0) {
		console_print(id, "Currently loaded zero admins^nNothing to show");
		return PLUGIN_HANDLED;
	}

	new startPos = 0, endPos;
	if (read_argc() > 1) {
		new tmp[5];
		read_argv(1, tmp, charsmax(tmp));
		startPos = str_to_num(tmp) - 1;
	}

	endPos = min(startPos + 10, num);

	new authData[44];
	new Access, AcessStr[32];
	new Flags, FlagsStr[10];
	console_print(id, "Currently loaded admins^nShow from %d to %d of %d", startPos + 1, endPos, num);
	console_print(id, "#     %-44s %-32s %-10s", "authid", "access", "flags");
	for (new i = startPos; i < endPos; i++) {
		admins_lookup(i, AdminProp_Auth, authData, charsmax(authData));
		Access = admins_lookup(i, AdminProp_Access);
		Flags = admins_lookup(i, AdminProp_Flags);

		get_flags(Access, AcessStr, charsmax(AcessStr));
		get_flags(Flags, FlagsStr, charsmax(FlagsStr));

		console_print(id, "[%3d] %-44s %-32s %-10s", i + 1, authData, AcessStr, FlagsStr);
	}

	if (endPos < num) {
		console_print(id, "Execute amx_admins %d for view next page", endPos + 1);
	}

	return PLUGIN_HANDLED;
}

public cmdReloadCfg(id, level)
{
	if (~get_user_flags(id) & level) {
		console_print(id, "You have no access to that command");
		return PLUGIN_HANDLED;
	}

	new name[MAX_NAME_LENGTH], authid[22], ip[16];
	get_user_name(id, name, charsmax(name));
	get_user_authid(id, authid, charsmax(authid));
	get_user_ip(id, ip, charsmax(ip), 1);

	LogAction("Admin <%s><%s><%s> reload config", name, authid, ip);

	CacheCvars();

	console_print(id, "[%s] Config reloaded successfully", LOG_TAG);

	return PLUGIN_HANDLED;
}

public fbans_sql_connected(Handle:sqlTuple)
{
	if (g_Status < STATUS_LOAD) {
		g_FreshBans = true;
		remove_task(FRESH_BANS_TASK_ID);
		g_DBTuple = sqlTuple;

		if (g_Status > STATUS_NONE) {
			g_Status = STATUS_LOAD;
			LoadAdmins(false);
		} else {
			g_Status = STATUS_LOAD;
		}
	}
}

public TaskFBansTimeout()
{
	if (g_Status < STATUS_LOAD) {
		g_FreshBans = false;

		if (g_Status > STATUS_NONE) {
			g_Status = STATUS_LOAD;
			LoadAdmins(false);
		} else {
			g_Status = STATUS_LOAD;
		}
	}
}

CacheCvars()
{
	get_cvar_string("amx_password_field", g_PasswordField, charsmax(g_PasswordField));
	get_cvar_string("amx_sql_prefix", g_DbPrefix, charsmax(g_DbPrefix));

	new tmp[32];
	get_cvar_string("amx_default_access", tmp, charsmax(tmp));
	g_DefaultAccess = read_flags(tmp);

	get_cvar_string("adminload_hltv_access", tmp, charsmax(tmp));
	g_HLTVAccess = read_flags(tmp);

	get_cvar_string("adminload_bot_access", tmp, charsmax(tmp));
	g_BOTAccess = read_flags(tmp);

	g_LoadType = get_cvar_num("adminload_load_type");
	g_LogType = get_cvar_num("adminload_log_type");
	g_BackupTime = get_cvar_num("adminload_backup_timecheck");
	g_HashDB = get_cvar_num("adminload_hash_db");
	g_HashFile = get_cvar_num("adminload_hash_file");

	if (g_BackupTime > 0) {
		g_BackupTime *= 3600;
	}

	get_cvar_string("adminload_server_address", g_ServerAddress, charsmax(g_ServerAddress));
	if (!g_ServerAddress[0]){
		get_user_ip(0, g_ServerAddress, charsmax(g_ServerAddress), 0);
	}

	if (contain(g_ServerAddress, ":") == -1) {
		add(g_ServerAddress, charsmax(g_ServerAddress), ":27015");
	}
}

CheckPlayers()
{
	new mode = get_pcvar_num(pcvar_AmxMode);
	new players[MAX_PLAYERS], num, player;
	get_players(players, num, "chi");

	for (new i = 0; i < num; i++) {
		player = players[i];
		if (mode) {
			CheckAccess(player);
			if (get_user_state(player, PDATA_ADMIN)) {
				execFwd(Adminload_Connect, player);
				LogLogin(player);
			}
		} else {
			DefaultAccess(player);
		}
	}
}

CheckPlayer(id)
{
	ClearCache(id);

	if (g_Status == STATUS_LOADED && get_pcvar_num(pcvar_AmxMode)) {
		CheckAccess(id);
		if (get_user_state(id, PDATA_ADMIN)) {
			execFwd(Adminload_Connect, id);
		}
	} else {
		DefaultAccess(id);
	}
}

CheckAccess(id, const name[] = "")
{
	remove_user_flags(id);
	
	new userauthid[22], userip[16], username[MAX_NAME_LENGTH], usercasename[MAX_NAME_LENGTH];

	get_user_authid(id, userauthid, charsmax(userauthid));
	get_user_ip(id, userip, charsmax(userip), 1);

	if (name[0]) {
		copy(username, charsmax(username), name);
	} else {
		get_user_name(id, username, charsmax(username));
	}

	copy(usercasename, charsmax(usercasename), username);
	strtolower(usercasename);

	new bool:found = false;

	new key[50];
	new i = 0;
	do {
		switch (g_DefaultPriority[i]) {
			case 's': {
				formatex(key, charsmax(key), "s%s", userauthid);
			}

			case 'i': {
				formatex(key, charsmax(key), "i%s", userip);
			}

			case 'n': {
				formatex(key, charsmax(key), "n%s", username);
			}

			case 'c': {
				formatex(key, charsmax(key), "c%s", usercasename);
			}

			case 't': {
				if (g_ClanTags != Invalid_Array) {
					checkClanTag(username, key, charsmax(key));
				} else {
					key[0] = EOS;
				}
			}

			default: {
				key[0] = EOS;
			}
		}

		if (key[0] && TrieKeyExists(g_Admins, key)) {
			found = true;
		}
	} while (g_DefaultPriority[++i] != EOS && !found);

	if (found) {
		TrieGetArray(g_Admins, key, g_AdminData, sizeof g_AdminData);

		if (g_AdminData[AdminFlags] & FLAG_NOPASS) {
			if (g_CheckNick) {
				if (CheckNick(username)) {
					SetAccess(id);
				} else if(!CheckReservedNick(username, usercasename)) {
					KickPlayer(id, "Nickname Is Reserved!");
					LogAction("Client '%s' (steamid '%s')(ip '%s') kicked due to invalid nick (nick '%s')", \
						username, userauthid, userip, g_AdminData[AdminNick]);
				} else {
					DefaultAccess(id);
				}
			} else {
				SetAccess(id);
			}
		} else {
			new infopassword[40], password[34];
			get_user_info(id, g_PasswordField, infopassword, charsmax(infopassword));
			if (g_AdminData[AdminPassHashed]) {
				hashPassword(infopassword, password, charsmax(password));
			} else {
				copy(password, charsmax(password), infopassword);
			}

			if (strcmp(password, g_AdminData[AdminPass]) == 0) {
				if (g_CheckNick) {
					if (CheckNick(username)) {
						SetAccess(id);
					} else if(!CheckReservedNick(username, usercasename)) {
						KickPlayer(id, "Nickname Is Reserved!");
						LogAction("Client '%s' (steamid '%s')(ip '%s') kicked due to invalid nick (nick '%s')", \
							username, userauthid, userip, g_AdminData[AdminNick]);
					} else {
						DefaultAccess(id);
					}
				} else {
					SetAccess(id);
				}
			} else if (g_AdminData[AdminFlags] & FLAG_KICK){
				KickPlayer(id, "Invalid Password!");
				LogAction("Client '%s' (steamid '%s')(ip '%s') kicked due to invalid password (account '%s') (password '%s')", \
					username, userauthid, userip, key[1], infopassword);
			} else if(!CheckReservedNick(username, usercasename)) {
				KickPlayer(id, "Nickname Is Reserved!");
				LogAction("Client '%s' (steamid '%s')(ip '%s') kicked due to invalid nick (nick '%s')", \
					username, userauthid, userip, g_AdminData[AdminNick]);
			} else {
				DefaultAccess(id);
			}
		}
	} else if (get_pcvar_num(pcvar_AmxMode) == 2) {
		KickPlayer(id, "You have no entry to the server...");
	} else if(!CheckReservedNick(username, usercasename)) {
		KickPlayer(id, "Nickname Is Reserved!");
		LogAction("Client '%s' (steamid '%s')(ip '%s') kicked due to invalid nick (nick '%s')", \
			username, userauthid, userip, g_AdminData[AdminNick]);
	} else {
		DefaultAccess(id);
	}
}

bool:CheckNick(const username[])
{
	if (g_AdminData[AdminFlags] & FLAG_CHECK_NICK) {
		return strcmp(g_AdminData[AdminNick], username, (g_AdminData[AdminFlags] & FLAG_CASE_SENSITIVE ? 1 : 0)) == 0 ? true : false;
	}

	return true;
}

bool:checkClanTag(const username[], key[], len)
{
	for (new i = 0; i < g_ClanTagsNum; i++) {
		ArrayGetArray(g_ClanTags, i, g_ClanTag);
		
		if (g_ClanTag[ClanTagCase]) {
			if (containi(username, g_ClanTag[ClanTag]) != -1) {
				copy(key, len, g_ClanTag[ClanTagKey]);
				return true;
			}
		} else {
			if (contain(username, g_ClanTag[ClanTag]) != -1) {
				copy(key, len, g_ClanTag[ClanTagKey]);
				return true;
			}
		}
	}

	return false;
}

stock bool:CheckReservedNick(const username[], const usercasename[])
{
	if (g_Status != STATUS_LOADED || g_ReservedNicks == Invalid_Trie) {
		return true;
	}

	new key[50];
	if (TrieGetString(g_ReservedNicks, username, key, charsmax(key))) {
		TrieGetArray(g_Admins, key, g_AdminData, sizeof g_AdminData);
		return false;
	}

	if (TrieGetString(g_ReservedNicks, usercasename, key, charsmax(key))) {
		TrieGetArray(g_Admins, key, g_AdminData, sizeof g_AdminData);
		return false;
	}

	return true;
}

SetAccess(id)
{
	set_user_flags(id, g_AdminData[AdminAccess]);

	if (g_AdminData[AdminStaticBandtime]) {
		add_user_state(id, PDATA_STATICBANTIME);
	}

	if (g_AdminData[AdminFlags] & FLAG_CASE_SENSITIVE) {
		add_user_state(id, PDATA_CASESENSITIVE);
	}

	add_user_state(id, PDATA_ADMIN);

	g_AdminCache[id][CacheId] = g_AdminData[AdminId];
	g_AdminCache[id][CacheExpired] = g_AdminData[AdminExpired];
	copy(g_AdminCache[id][CacheNick], 31, g_AdminData[AdminNick]);

	PrintConsole(id, "* Privileges set");
}

DefaultAccess(id)
{
	remove_user_state(id, PDATA_ADMIN);

	set_user_flags(id, g_DefaultAccess);
	PrintConsole(id, "* Privileges set");

	ClearCache(id);
}

KickPlayer(id, const reason[] = "")
{
	if (reason[0]) {
		server_cmd("kick #%d ^"%s^"", get_user_userid(id), reason);
	} else {
		server_cmd("kick #%d", get_user_userid(id));
	}
}

LoadAdmins(bool:forceBackup = false)
{
	#if defined FUNC_ADD_ADMIN
	if (g_AdminsList == Invalid_Array) {
		g_AdminsList = ArrayCreate(AdminsList);
	} else {
		ArrayClear(g_AdminsList);
	}
	#endif

	g_BackupMake = BackupCheck(forceBackup);

	switch (g_LoadType) {
		case 1: {
			g_BackupLoadType = BACKUP_LOAD_DB;
			DBLoad();
		}

		case 2: {
			g_BackupLoadType = BACKUP_LOAD_DB | BACKUP_LOAD_FILE;
			DBLoad();
		}

		case 3: {
			g_BackupLoadType = BACKUP_LOAD_DB | BACKUP_LOAD_FILE;
			g_BackupMake = false;
			LoadAdminsPost();
		}

		default: {
			g_BackupLoadType = BACKUP_LOAD_FILE;
			FileLoad();
			LoadAdminsPost();
		}
	}
}

LoadAdminsPost()
{
	if (g_BackupMake) {

		if (g_BackupFile) {
			fclose(g_BackupFile);
		}

		new backupFilePath[128], backupFilePathNew[128];
		get_localinfo("amxx_datadir", backupFilePath, charsmax(backupFilePath));
		format(backupFilePath, charsmax(backupFilePath), "%s/%s", backupFilePath, BACKUP_FILENAME);
		formatex(backupFilePathNew, charsmax(backupFilePathNew), "%s.new", backupFilePath);

		if (g_BackupLoadType == 0) {
			unlink(backupFilePath);
			rename_file(backupFilePathNew, backupFilePath, 1);
			LogAction("Backup updated", LOG_TAG);
		} else {
			unlink(backupFilePathNew);
		}
	}

	if (g_BackupLoadType != 0) {
		BackupLoad();
	}

	if (g_ClanTags != Invalid_Array) {
		g_ClanTagsNum = ArraySize(g_ClanTags);
	}

	CheckPlayers();

	execFwd(Adminload_Loaded, g_Status == STATUS_RELOADING ? 1 : 0);

	if (g_Status != STATUS_LOADED) {
		g_Status = STATUS_LOADED;
	}
}

ReloadAdmins()
{
	remove_user_flags(0, read_flags("z"));

	admins_flush();
	TrieClear(g_Admins);
	
	if (g_ClanTags != Invalid_Array) {
		ArrayClear(g_ClanTags);
	}

	if (g_ReservedNicks != Invalid_Trie) {
		TrieClear(g_ReservedNicks);
	}

	g_CheckNick = false;

	LogoutAdmins();

	g_Status = STATUS_RELOADING;
	LoadAdmins(true);
}

LogoutAdmins()
{
	for (new player = 1; player < MaxClients; player++) {
		if ((is_user_connected(player) || is_user_connecting(player)) && !is_user_bot(player) && !is_user_hltv(player) && get_user_state(player, PDATA_ADMIN)) {
			ClearCache(player);
			execFwd(Adminload_Disconnect, player);
			LogLogout(player);
		}
	}
}

DBLoad()
{
	if (g_DBTuple == Empty_Handle) {
		DBMakeTuple();
	}

	new pquery[512];
	formatex(pquery, charsmax(pquery), "SELECT aa.id, CONVERT(aa.steamid, BINARY) steamid, aa.password, aa.access, ads.custom_flags, aa.flags, CONVERT(aa.nickname, BINARY) nickname, \
IF(ads.use_static_bantime = 'yes', 1, 0) use_static_bantime, aa.expired, si.id server_id FROM %s_amxadmins aa \
JOIN %s_admins_servers ads ON aa.id = ads.admin_id JOIN %s_serverinfo si ON ads.server_id = si.id WHERE si.address = '%s' && (aa.expired = 0 OR aa.expired > %d)",
	g_DbPrefix, g_DbPrefix, g_DbPrefix, g_ServerAddress, get_systime());

	#if defined DEBUG
	log_amx("Server address is %s", g_ServerAddress);
	log_amx("Query: ^"%s^"", pquery);
	#endif

	SQL_ThreadQuery(g_DBTuple, "DBLoadPost", pquery);
}

public DBLoadPost(failstate, Handle:query, const error[], errornum, const data[], size, Float:queuetime)
{
	new bool:loadServerId = false;

	if (failstate) {
		SQL_Error(query, error, errornum, failstate);
		execFwd(Adminload_Sql_Fail);
	} else if (SQL_NumResults(query) > 0) {
		new qcolId = SQL_FieldNameToNum(query, "id");
		new qcolAuth = SQL_FieldNameToNum(query, "steamid");
		new qcolPass = SQL_FieldNameToNum(query, "password");
		new qcolAccess = SQL_FieldNameToNum(query, "access");
		new qcolCustomAccess = SQL_FieldNameToNum(query, "custom_flags");
		new qcolFlags = SQL_FieldNameToNum(query, "flags");
		new qcolNick = SQL_FieldNameToNum(query, "nickname");
		new qcolStatic = SQL_FieldNameToNum(query, "use_static_bantime");
		new qcolExpired = SQL_FieldNameToNum(query, "expired");

		new authData[44];
		new access[32];
		new customAccess[32];
		new flags[32];

		new adminsNum = 0;

		while (SQL_MoreResults(query)) {
			setc(authData, sizeof authData, 0);
			setc(g_AdminData[AdminPass], sizeof g_AdminData[AdminPass], 0);
			setc(g_AdminData[AdminNick], sizeof g_AdminData[AdminNick], 0);

			g_AdminData[AdminId] = SQL_ReadResult(query, qcolId);
			SQL_ReadResult(query, qcolAuth, authData, charsmax(authData));
			SQL_ReadResult(query, qcolPass, g_AdminData[AdminPass], charsmax(g_AdminData[AdminPass]));
			SQL_ReadResult(query, qcolAccess, access, charsmax(access));
			SQL_ReadResult(query, qcolCustomAccess, customAccess, charsmax(customAccess));
			SQL_ReadResult(query, qcolNick, g_AdminData[AdminNick], charsmax(g_AdminData[AdminNick]));
			SQL_ReadResult(query, qcolFlags, flags, charsmax(flags));
			g_AdminData[AdminStaticBandtime] = SQL_ReadResult(query, qcolStatic) ? true : false;
			g_AdminData[AdminExpired] = SQL_ReadResult(query, qcolExpired);

			if (customAccess[0] != EOS) {
				copy(access, charsmax(access), customAccess);
			}

			g_AdminData[AdminAccess] = read_flags(access);
			g_AdminData[AdminFlags] = read_flags(flags);

			switch (g_HashDB) {
				case 1: {
					g_AdminData[AdminPassHashed] = true;
				}

				case 2: {
					g_AdminData[AdminPassHashed] = isMD5(g_AdminData[AdminPass]);
				}

				default: {
					g_AdminData[AdminPassHashed] = false;
				}
			}

			g_AdminData[AdminLoadDB] = true;

			PushAdmin(authData);
			BackupAdmin(authData, charsmax(authData));

			adminsNum++;

			SQL_NextRow(query);
		}

		LogAction("Loaded %d admins from database", adminsNum);
		g_BackupLoadType &= ~BACKUP_LOAD_DB;
		
		if (g_Status == STATUS_LOAD) {
			execFwd(Adminload_Sql_Initialized);
		}

		loadServerId = true;
	} else {
		LogAction("Loaded 0 admins from database", LOG_TAG);
		g_BackupLoadType &= ~BACKUP_LOAD_DB;
		
		if (g_Status == STATUS_LOAD) {
			execFwd(Adminload_Sql_Initialized);
		}
	}

	SQL_FreeHandle(query);

	if (g_LoadType == 2) {
		FileLoad();
	}
	
	LoadAdminsPost();

	if (loadServerId) {
		new pquery[512];
		formatex(pquery, charsmax(pquery), "SELECT id FROM %s_serverinfo WHERE address = '%s' LIMIT 1", g_DbPrefix, g_ServerAddress);

		SQL_ThreadQuery(g_DBTuple, "DBGetServerIdPost", pquery);
	}

	#if defined FUNC_ADD_ADMIN
	DBGetAdminList();
	#endif
}

public DBGetServerIdPost(failstate, Handle:query, const error[], errornum, const data[], size, Float:queuetime)
{
	if (failstate) {
		SQL_Error(query, error, errornum, failstate);
	} else if (SQL_NumResults(query) > 0) {
		g_ServerId = SQL_ReadResult(query, 0);
	}

	SQL_FreeHandle(query);
}

FileLoad()
{
	new fileName[128];
	get_localinfo("amxx_configsdir", fileName, charsmax(fileName));
	add(fileName, charsmax(fileName), "/users.ini");
	new file = fopen(fileName, "rt");
	if (file) {
		new authData[44];
		new access[32];
		new flags[32];
		new nick[MAX_NAME_LENGTH];
		new staticBanTime[2];
		new expired[15];

		new adminsNum = 0;
		new line[512];
		new sysTime = get_systime();

		new semicolonPos = EOS;
		while (!feof(file)) {
			fgets(file, line, charsmax(line));
			
			if ((semicolonPos = contain(line, ";")) > 0) {
				line[semicolonPos] = 0;
			}

			trim(line);
			
			if (!line[0] || line[0]==';') {
				continue;
			}
			
			access[0] = EOS;
			flags[0] = EOS;
			nick[0] = EOS;
			staticBanTime[0] = EOS;
			expired[0] = EOS;

			setc(authData, sizeof authData, 0);
			setc(g_AdminData[AdminPass], sizeof g_AdminData[AdminPass], 0);
			setc(g_AdminData[AdminNick], sizeof g_AdminData[AdminNick], 0);

			if (parse(line, authData, charsmax(authData), g_AdminData[AdminPass], charsmax(g_AdminData[AdminPass]), access, charsmax(access), flags, charsmax(flags), 
				staticBanTime, charsmax(staticBanTime), expired, charsmax(expired), nick, charsmax(nick)) < 4) {
				continue;
			}

			g_AdminData[AdminId] = 0;
			g_AdminData[AdminAccess] = read_flags(access);
			g_AdminData[AdminFlags] = read_flags(flags);

			if (nick[0]) {
				g_AdminData[AdminNick] = nick;
			} else  {
				copy(g_AdminData[AdminNick], charsmax(g_AdminData[AdminNick]), authData);
			}

			if (staticBanTime[0]) {
				g_AdminData[AdminStaticBandtime] = str_to_num(staticBanTime) ? true : false;
			} else {
				g_AdminData[AdminStaticBandtime] = true;
			}

			if (expired[0]) {
				g_AdminData[AdminExpired] = strcmp(expired, "0") != 0 ? parse_time(expired, "%d.%m.%Y") : 0;
			} else {
				g_AdminData[AdminExpired] = 0;
			}

			switch (g_HashFile) {
				case 1: {
					g_AdminData[AdminPassHashed] = true;
				}

				case 2: {
					g_AdminData[AdminPassHashed] = isMD5(g_AdminData[AdminPass]);
				}

				default: {
					g_AdminData[AdminPassHashed] = false;
				}
			}

			g_AdminData[AdminLoadDB] = false;

			if (g_AdminData[AdminExpired] == 0 || g_AdminData[AdminExpired] > sysTime) {
				PushAdmin(authData);
				BackupAdmin(authData, charsmax(authData));
				adminsNum++;
			} else {
				LogAction("Admin %s (access ^"%s^") (nick ^"%s^") (expired %s) not loaded because has been expired", authData, access, g_AdminData[AdminNick], expired);
			}
		}

		LogAction("Loaded %d admins from file", adminsNum);
		g_BackupLoadType &= ~BACKUP_LOAD_FILE;
	} else {
		LogError("Erorr open file '%s'", fileName);
	}

	fclose(file);
}

DBMakeTuple()
{
	new host[64], user[32], pass[32], db[128];
	new get_type[12], set_type[12];
	
	get_cvar_string("amx_sql_host", host, 63);
	get_cvar_string("amx_sql_user", user, 31);
	get_cvar_string("amx_sql_pass", pass, 31);
	get_cvar_string("amx_sql_type", set_type, 11);
	get_cvar_string("amx_sql_db", db, 127);
	
	SQL_GetAffinity(get_type, 12);
	
	if (!equali(get_type, set_type)) {
		if (!SQL_SetAffinity(set_type)) {
			LogError("Failed to set affinity from %s to %s.", get_type, set_type);
		}
	}
	
	g_DBTuple = SQL_MakeDbTuple(host, user, pass, db, 5);

	#if defined SQL_SetCharset
	SQL_SetCharset(g_DBTuple, "utf8");
	#endif
}

bool:BackupCheck(bool:forceBackup)
{
	new bool:makeBackup = false;

	new backupFilePath[128];
	get_localinfo("amxx_datadir", backupFilePath, charsmax(backupFilePath));
	format(backupFilePath, charsmax(backupFilePath), "%s/%s", backupFilePath, BACKUP_FILENAME);

	if (forceBackup || g_BackupTime == 0) {
		makeBackup = true;
	} else if (g_BackupTime == -1) {
		if (!file_exists(backupFilePath)) {
			makeBackup = true;
		}
	} else {
		#if defined GetFileTime
		new backupTime = GetFileTime(backupFilePath, FileTime_LastChange);
		makeBackup = ((get_systime() - backupTime) > g_BackupTime) ? true : false;
		#else
		new file = fopen(backupFilePath, "rb");
		if (!file) {
			makeBackup = true;
		} else {
			new backupTime, backupVersion;
			fread(file, backupVersion, BLOCK_SHORT);
			if (backupVersion != BACKUP_VERSION) {
				makeBackup = true;
			} else {
				fread(file, backupTime, BLOCK_INT);
				makeBackup = ((get_systime() - backupTime) > g_BackupTime) ? true : false;
				if (!makeBackup && backupVersion != BACKUP_VERSION) {
					makeBackup = true;
				}
			}
		}
		fclose(file);
		#endif
	}

	if (makeBackup) {
		add(backupFilePath, charsmax(backupFilePath), ".new");
		g_BackupFile = fopen(backupFilePath, "wb");
		fwrite(g_BackupFile, BACKUP_VERSION, BLOCK_SHORT);
		fwrite(g_BackupFile, get_systime(), BLOCK_INT);
	}

	return makeBackup;
}

BackupAdmin(const authData[], authDataLen)
{
	if (g_BackupMake && g_BackupFile) {
		fwrite(g_BackupFile, g_AdminData[AdminId], BLOCK_INT);
		fwrite_blocks(g_BackupFile, authData, authDataLen, BLOCK_CHAR);
		fwrite_blocks(g_BackupFile, g_AdminData[AdminPass], charsmax(g_AdminData[AdminPass]), BLOCK_CHAR);
		fwrite(g_BackupFile, g_AdminData[AdminAccess], BLOCK_INT);
		fwrite(g_BackupFile, g_AdminData[AdminFlags], BLOCK_INT);
		fwrite_blocks(g_BackupFile,g_AdminData[AdminNick], charsmax(g_AdminData[AdminNick]), BLOCK_CHAR);
		fwrite(g_BackupFile, (g_AdminData[AdminStaticBandtime] ? 1 : 0), BLOCK_BYTE);
		fwrite(g_BackupFile, g_AdminData[AdminExpired], BLOCK_INT);
		fwrite(g_BackupFile, (g_AdminData[AdminPassHashed] ? 1 : 0), BLOCK_BYTE);
		fwrite(g_BackupFile, (g_AdminData[AdminLoadDB] ? 1 : 0), BLOCK_BYTE);
	}
}

bool:BackupLoad()
{
	new backupFilePath[128];
	get_localinfo("amxx_datadir", backupFilePath, charsmax(backupFilePath));
	format(backupFilePath, charsmax(backupFilePath), "%s/%s", backupFilePath, BACKUP_FILENAME);
	new file = fopen(backupFilePath, "rb");
	if (file) {
		new authData[44];
		new staticBanTime, passHashed, loadDB;

		new adminsNum = 0;
		new backupVersion, backupTime;

		fread(file, backupVersion, BLOCK_SHORT);
		if (backupVersion != BACKUP_VERSION) {
			LogError("Version of backup is %d. Version %d needed", backupVersion, BACKUP_VERSION);
		} else {
			fread(file, backupTime, BLOCK_INT);
			new readBytes = 0;
			while (!feof(file)) {
				readBytes = 0;
				readBytes += fread(file, g_AdminData[AdminId], BLOCK_INT);
				readBytes += fread_blocks(file, authData, charsmax(authData), BLOCK_CHAR);
				readBytes += fread_blocks(file, g_AdminData[AdminPass], charsmax(g_AdminData[AdminPass]), BLOCK_CHAR);
				readBytes += fread(file, g_AdminData[AdminAccess], BLOCK_INT);
				readBytes += fread(file, g_AdminData[AdminFlags], BLOCK_INT);
				readBytes += fread_blocks(file, g_AdminData[AdminNick], charsmax(g_AdminData[AdminNick]), BLOCK_CHAR);
				readBytes += fread(file, staticBanTime, BLOCK_BYTE);
				readBytes += fread(file, g_AdminData[AdminExpired], BLOCK_INT);
				readBytes += fread(file, passHashed, BLOCK_BYTE);
				readBytes += fread(file, loadDB, BLOCK_BYTE);

				if (readBytes == 0) {
					break;
				}

				g_AdminData[AdminStaticBandtime] = staticBanTime == 1 ? true : false;
				g_AdminData[AdminPassHashed] = passHashed == 1 ? true : false;
				g_AdminData[AdminLoadDB] = loadDB == 1 ? true : false;

				if (g_AdminData[AdminLoadDB]) {
					if (g_BackupLoadType & BACKUP_LOAD_DB) {
						PushAdmin(authData);
						adminsNum++;
					}
				} else {
					if (g_BackupLoadType & BACKUP_LOAD_FILE) {
						PushAdmin(authData);
						adminsNum++;
					}
				}
			}
		}
		
		fclose(file);

		new time[20];
		format_time(time, charsmax(time), "%d.%m.%Y %H:%M", backupTime);
		LogAction("Loaded %d admind from backup (%s)", adminsNum, time);
	} else {
		LogError("Erorr open backup file '%s'", backupFilePath);
	}
}

PushAdmin(const authData[])
{
	new key[40];
	if (g_AdminData[AdminFlags] & FLAG_TAG) {
		if (g_ClanTags == Invalid_Array) {
			g_ClanTags = ArrayCreate(ClanTags);
		}

		formatex(key, charsmax(key), "t%s", authData);
		TrieSetArray(g_Admins, key, g_AdminData, sizeof g_AdminData);

		copy(g_ClanTag[ClanTag], charsmax(g_ClanTag[ClanTag]), authData);
		copy(g_ClanTag[ClanTagKey], charsmax(g_ClanTag[ClanTagKey]), key);
		g_ClanTag[ClanTagCase] = (g_AdminData[AdminFlags] & FLAG_CASE_SENSITIVE) ? true : false;
		ArrayPushArray(g_ClanTags, g_ClanTag);
	} else {
		if (g_AdminData[AdminFlags] & FLAG_AUTHID) {
			formatex(key, charsmax(key), "s%s", authData);
		} else if (g_AdminData[AdminFlags] & FLAG_IP) {
			formatex(key, charsmax(key), "i%s", authData);
		} else if (g_AdminData[AdminFlags] & FLAG_CASE_SENSITIVE) {
			formatex(key, charsmax(key), "c%s", authData);
			strtolower(key);
		} else {
			formatex(key, charsmax(key), "n%s", authData);
		}

		TrieSetArray(g_Admins, key, g_AdminData, sizeof g_AdminData);
	}

	if (g_AdminData[AdminFlags] & FLAG_CHECK_NICK) {
		g_CheckNick = true;
	}

	if (g_AdminData[AdminFlags] & FLAG_RESERV_NICK) {
		if (g_ReservedNicks == Invalid_Trie) {
			g_ReservedNicks = TrieCreate();
		}

		new nick[64];
		copy(nick, charsmax(nick), g_AdminData[AdminNick]);
		if (g_AdminData[AdminFlags] & FLAG_CASE_SENSITIVE) {
			strtolower(nick);
		}
		TrieSetString(g_ReservedNicks, nick, key);
	}

	admins_push(authData, g_AdminData[AdminPass], g_AdminData[AdminAccess], g_AdminData[AdminFlags]);

	#if defined DEBUG
	new expired[32], access[32], flags[10];
	if (g_AdminData[AdminExpired] > 0) {
		format_time(expired, charsmax(expired), "%d.%m.%Y - %H:%M:%S", g_AdminData[AdminExpired]);
	} else {
		expired = "never";
	}

	get_flags(g_AdminData[AdminAccess], access, charsmax(access));
	get_flags(g_AdminData[AdminFlags], flags, charsmax(flags));
	log_amx("Load admin '%s' <ID #%d><AuthData '%s'><Aceess %s><Flags %s><Static Bantime %s><Expired %s><Hash %s>", 
		g_AdminData[AdminNick], g_AdminData[AdminId], authData, access, flags,
		(g_AdminData[AdminStaticBandtime] ? "yes" : "no"), expired, (g_AdminData[AdminPassHashed] ? "yes" : "no"));
	#endif
}

SQL_Error(Handle:query, const error[], errornum, failstate)
{
	if (failstate == TQUERY_CONNECT_FAILED) {
		LogError("Connection failed!");
		LogError("Message: %s (%d)", error, errornum);
	} else if (failstate == TQUERY_QUERY_FAILED) {
		new qstring[1024];
		SQL_GetQueryString(query, qstring, 1023);
		LogError("Query failed!");
		LogError("Message: %s (%d)", error, errornum);
		LogError("Query statement: %s", qstring);
	}
}

RegisterForwards()
{
	MFHandle[Adminload_Sql_Initialized] = CreateForward("amxbans_sql_initialized", ET_IGNORE, FP_CELL, FP_STRING);
	MFHandle[Adminload_Connect] = CreateForward("amxbans_admin_connect", ET_IGNORE, FP_CELL);
	MFHandle[Adminload_Disconnect] = CreateForward("amxbans_admin_disconnect", ET_IGNORE, FP_CELL);

	MFHandle[Adminload_Sql_Fail] = CreateForward("adminload_sql_fail", ET_IGNORE);
	MFHandle[Adminload_Loaded] = CreateForward("adminload_loaded", ET_IGNORE, FP_CELL);
}

UnregisterForwards()
{
	if (MFHandle[Adminload_Sql_Initialized] != INVALID_HANDLE) {
		DestroyForward(MFHandle[Adminload_Sql_Initialized]);
	}

	if (MFHandle[Adminload_Connect] != INVALID_HANDLE) {
		DestroyForward(MFHandle[Adminload_Connect]);
	}

	if (MFHandle[Adminload_Disconnect] != INVALID_HANDLE) {
		DestroyForward(MFHandle[Adminload_Disconnect]);
	}

	if (MFHandle[Adminload_Sql_Fail] != INVALID_HANDLE) {
		DestroyForward(MFHandle[Adminload_Sql_Fail]);
	}

	if (MFHandle[Adminload_Loaded] != INVALID_HANDLE) {
		DestroyForward(MFHandle[Adminload_Loaded]);
	}
}

register_default_cvars()
{
	register_cvar("amx_vote_ratio", "0.02");
	register_cvar("amx_vote_time", "10");
	register_cvar("amx_vote_answers", "1");
	register_cvar("amx_vote_delay", "60");
	register_cvar("amx_last_voting", "0");
	register_cvar("amx_show_activity", "2");
	register_cvar("amx_votekick_ratio", "0.40");
	register_cvar("amx_voteban_ratio", "0.40");
	register_cvar("amx_votemap_ratio", "0.40");

	set_cvar_float("amx_last_voting", 0.0);
}

ClearCache(id)
{
	g_AdminCache[id][CacheId] = 0;
	g_AdminCache[id][CacheNick][0] = EOS;
	g_AdminCache[id][CacheExpired] = 1;
}

LogLogin(id, const name[] = "")
{
	new username[MAX_NAME_LENGTH], userauthid[32], userip[32], useraccess[32];
	get_flags(get_user_flags(id), useraccess, charsmax(useraccess));
	get_user_authid(id, userauthid, charsmax(userauthid));
	get_user_ip(id, userip, charsmax(username), 1);
	
	if (name[0]) {
		copy(username, charsmax(username), name);
	} else {
		get_user_name(id, username, charsmax(username));
	}

	new expired[32];
	if (g_AdminCache[id][CacheExpired] > 0) {
		format_time(expired, charsmax(expired), "%d.%m.%Y - %H:%M:%S", g_AdminData[AdminExpired]);
	} else {
		expired = "never";
	}

	LogAction("Client '%s' (steamid '%s')(ip '%s') became an admin (access ^"%s^") (nick ^"%s^") (id %d) (static %s) (expired %s)", \
		username, userauthid, userip, useraccess, g_AdminCache[id][CacheNick],  g_AdminCache[id][CacheId], (get_user_state(id, PDATA_STATICBANTIME) ? "yes" : "no"), expired);
}

LogLogout(id, const name[] = "")
{

	new username[MAX_NAME_LENGTH], userauthid[32], userip[32], useraccess[32];
	get_flags(get_user_flags(id), useraccess, charsmax(useraccess));
	get_user_authid(id, userauthid, charsmax(userauthid));
	get_user_ip(id, userip, charsmax(username), 1);
	
	if (name[0]) {
		copy(username, charsmax(username), name);
	} else {
		get_user_name(id, username, charsmax(username));
	}

	LogAction("Client '%s' (steamid '%s')(ip '%s') disconnected (access ^"%s^") (nick ^"%s^")", \
		username, userauthid, userip, useraccess, g_AdminCache[id][CacheNick]);
}

LogAction(const fmt[], any:...)
{
	new msg[256];
	vformat(msg, charsmax(msg), fmt, 2);

	if (g_LogType == 1) {
		if (!g_LogFile[0]) {
			LogActionInit();
		}

		log_to_file(g_LogFile, "[%s] %s", LOG_TAG, msg);
	} else {
		log_amx("[%s] %s", LOG_TAG, msg);
	}
}

LogError(const fmt[], any:...)
{
	static logFile[128];

	if (!logFile[0]) {
		new logTime[22];
		get_localinfo("amxx_logs", logFile, charsmax(logFile));

		get_time("/error_%Y%m%d.log", logTime, charsmax(logTime));
		add(logFile, charsmax(logFile), logTime);
	}

	new msg[256];
	vformat(msg, charsmax(msg), fmt, 2);

	log_to_file(logFile, "[%s] %s", LOG_TAG, msg);
}

LogActionInit()
{
	get_localinfo("amxx_logs", g_LogFile, charsmax(g_LogFile));

	add(g_LogFile, charsmax(g_LogFile), "/adminload");
	if (!dir_exists(g_LogFile)) {
		mkdir(g_LogFile);
	}

	new logTime[16];
	get_time("/L%Y%m%d.log", logTime, charsmax(logTime));
	add(g_LogFile, charsmax(g_LogFile), logTime);

	new logMap[32];
	get_mapname(logMap, charsmax(logMap));
	log_to_file(g_LogFile, "Start of log session (map %s)", logMap);
}

ExecuteCfg()
{
	new configsDir[128];
	get_localinfo("amxx_configsdir", configsDir, charsmax(configsDir));

	#if AMXX_VERSION_NUM < 183
	server_cmd("exec %s/amxx.cfg", configsDir);

	new mapname[32], path[64], prefix[32];
	get_mapname(mapname, charsmax(mapname));
	formatex(path, charsmax(path), "%s/maps/%s.cfg", configsDir, mapname);
	if(file_exists(path)) {
		server_cmd("exec %s", path);
	} else {
		strtok(mapname, prefix, charsmax(prefix), "", 0, '_');
		formatex(path, charsmax(path), "%s/maps/prefix_%s.cfg", configsDir, prefix);
		if(file_exists(path)) {
			server_cmd("exec %s", path);
		}
	}
	#endif

	server_cmd("exec %s/sql.cfg", configsDir);
	server_exec();
}

stock hashPassword(const password[], hash[], len)
{
	#if defined hash_string
	hash_string(password, Hash_Md5, hash, len);
	#else
	new buffer[34];
	md5(password, buffer);
	copy(hash, len, buffer);
	#endif
}

stock bool:isMD5(const value[])
{
	new len = strlen(value);
	if (len != 32) {
		return false;
	}

	for (new i = 0; i < len; i++) {
		if (!('0' <= value[i] <= '9') && !('a' <= value[i] <= 'f') && !('A' <= value[i] <= 'F')) {
			return false;
		}
	}

	return true;
}

stock execFwd(forwardType, id = 0)
{
	switch (forwardType) {
		case Adminload_Sql_Initialized: {
			if (MFHandle[Adminload_Sql_Initialized] != INVALID_HANDLE) {
				ExecuteForward(MFHandle[Adminload_Sql_Initialized], MFReturn, g_DBTuple, g_DbPrefix);
			}
		}

		case Adminload_Connect: {
			if (MFHandle[Adminload_Connect] != INVALID_HANDLE) {
				ExecuteForward(MFHandle[Adminload_Connect], MFReturn, id);
			}
		}

		case Adminload_Disconnect: {
			if (MFHandle[Adminload_Disconnect] != INVALID_HANDLE) {
				ExecuteForward(MFHandle[Adminload_Disconnect], MFReturn, id);
			}
		}

		case Adminload_Sql_Fail: {
			if (MFHandle[Adminload_Sql_Fail] != INVALID_HANDLE) {
				ExecuteForward(MFHandle[Adminload_Sql_Fail], MFReturn);
			}
		}

		case Adminload_Loaded: {
			if (MFHandle[Adminload_Loaded] != INVALID_HANDLE) {
				ExecuteForward(MFHandle[Adminload_Loaded], MFReturn, id);
			}
		}
	}
}

stock checkPluginRunning(const name[], const author[])
{
	new pluginName[32], pluginAuthor[32], pluginStatus[10];
	for (new i = 0, num = get_pluginsnum(); i < num; i++) {
		get_plugin(i, _, 0, pluginName, charsmax(pluginName), _, 0, pluginAuthor, charsmax(pluginAuthor), pluginStatus, charsmax(pluginStatus));

		if (containi(pluginName, name) != -1 && equal(author, pluginAuthor) && equal("running", pluginStatus)) {
			return true;
		}
	}

	return false;
}

stock PrintConsole(id, const msg[])
{
	message_begin(MSG_ONE, SVC_PRINT, .player = id);
	write_string(msg);
	message_end();
}

stock CreateForward(const forwardName[], const returnType, any:...)
{
	new ret = INVALID_HANDLE;
	for (new i = 0, num = get_pluginsnum(); i < num; i++) 
		if (get_func_id(forwardName, i) != -1) {
			switch (numargs()) {
				case 10: ret = CreateMultiForward(forwardName, returnType, getarg(2), getarg(3), getarg(4), getarg(5), getarg(6), getarg(7), getarg(8), getarg(9));
				case 9: ret = CreateMultiForward(forwardName, returnType, getarg(2), getarg(3), getarg(4), getarg(5), getarg(6), getarg(7), getarg(8));
				case 8: ret = CreateMultiForward(forwardName, returnType, getarg(2), getarg(3), getarg(4), getarg(5), getarg(6), getarg(7));
				case 7: ret = CreateMultiForward(forwardName, returnType, getarg(2), getarg(3), getarg(4), getarg(5), getarg(6));
				case 6: ret = CreateMultiForward(forwardName, returnType, getarg(2), getarg(3), getarg(4), getarg(5));
				case 5: ret = CreateMultiForward(forwardName, returnType, getarg(2), getarg(3), getarg(4));
				case 4: ret = CreateMultiForward(forwardName, returnType, getarg(2), getarg(3));
				case 3: ret = CreateMultiForward(forwardName, returnType, getarg(2));
				default: ret = CreateMultiForward(forwardName, returnType);
			}
			return ret;
		}

	return ret;
}

public native_reloadadmins(plugin_id, param_nums)
{
	ReloadAdmins();

	new filename[32], name[32], version[32], author[32], status[32];
	get_plugin(plugin_id, filename, charsmax(filename), name, charsmax(name), version, charsmax(version), author, charsmax(author), status, charsmax(status));
	LogAction("Plugin <%s><%s><%s><%s> run reload admins", filename, name, version, author);
}

public native_get_server_id(plugin_id, param_nums) 
{
	return g_ServerId;
}

public native_get_prefix(plugin_id, param_nums) 
{
	if (param_nums != 2) {
		return 0;
	}
	
	set_array(1, g_DbPrefix, get_param(2));
	return 1;
}

public native_get_nick(plugin_id, param_nums) 
{
	if (param_nums != 3) {
		return 0;
	}

	new id = get_param(1);
	CHECK_PLAYER(id)

	set_array(2, g_AdminCache[id][CacheNick], get_param(3));
	return 1;
}

public native_static_bantime(plugin_id, param_nums) 
{
	if (param_nums != 1) {
		return 0;
	}

	new id = get_param(1);
	CHECK_PLAYER(id)

	return get_user_state(id, PDATA_STATICBANTIME) ? 1 : 0;
}

public native_get_expired(plugin_id, param_nums) 
{
	if (param_nums != 1) {
		return 0;
	}

	new id = get_param(1);
	CHECK_PLAYER(id)

	return g_AdminCache[id][CacheExpired];
}

public native_get_daysleft(plugin_id, param_nums)
{
	if (param_nums != 1) {
		return 0;
	}

	new id = get_param(1);
	CHECK_PLAYER(id)

	return g_AdminCache[id][CacheExpired] > 0 ? max(1, (g_AdminCache[id][CacheExpired] - get_systime()) / 86400) : 0;
}

public native_get_id(plugin_id, param_nums) 
{
	if (param_nums != 1) {
		return 0;
	}

	new id = get_param(1);
	CHECK_PLAYER(id)

	return g_AdminCache[id][CacheId];
}

public native_is_admin(plugin_id, param_nums)
{
	if (param_nums != 1) {
		return 0;
	}

	new id = get_param(1);
	CHECK_PLAYER(id)

	return get_user_state(id, PDATA_ADMIN) ? 1 : 0;
}

#if defined FUNC_ADD_ADMIN
public native_add_admin(plugin_id, param_nums)
{
	if (param_nums != 5) {
		return 0;
	}

	new authData[44], password[32], access, flags, expired, nickname[MAX_NAME_LENGTH], bool:static_bantime;
	get_array(2, authData, charsmax(authData));
	get_array(3, password, charsmax(password));
	access = get_param(4);
	flags = get_param(5);

	if (param_nums >= 6) {
		expired = get_param(6);
	} else {
		expired = 0;
	}

	if (param_nums >= 7) {
		get_array(7, nickname, charsmax(nickname));
	} else {
		setc(nickname, sizeof nickname, 0);
	}

	if (param_nums >= 8) {
		static_bantime = get_param(8) ? true : false;
	} else {
		static_bantime = true;
	}

	AddAdmin(get_param(1), authData, password, access, flags, expired, nickname, static_bantime);

	new accessStr[32], flagsStr[32], expiredStr[32];
	get_flags(access, accessStr, charsmax(accessStr));
	get_flags(flags, flagsStr, charsmax(flagsStr));
	format_time(expiredStr, charsmax(expiredStr), "%d.%m.%Y", expired);

	new filename[32], plugin_name[32], version[32], author[32], status[32];
	get_plugin(plugin_id, filename, charsmax(filename), plugin_name, charsmax(plugin_name), version, charsmax(version), author, charsmax(author), status, charsmax(status));

	LogAction("Plugin <%s><%s><%s><%s> add new admin <%s><%s><%s><%s><%s><%s>", filename, plugin_name, version, author, authData, password, accessStr, flagsStr, expiredStr, nickname);

	return 1;
}

public cmdAddAdmin(id, level)
{
	if (~get_user_flags(id) & level) {
		console_print(id, "You have no access to that command");
		return PLUGIN_HANDLED;
	}

	if (read_argc() < 2) {
		console_print(id, "Usage: amx_addadmin <add flags> <playername|auth> <accessflags> [password] [flags] [expire] [static] [nickname]");
		return PLUGIN_HANDLED;
	}

	new args[2256], addFlagsStr[32], authData[44], accessStr[32], password[64], flagsStr[32], expiredStr[32], staticStr[2], nickname[MAX_NAME_LENGTH];
	read_args(args, charsmax(args));
	#if AMXX_VERSION_NUM < 183
	new pos = strbreak(args, addFlagsStr, charsmax(addFlagsStr), args, charsmax(args));
	if (pos != -1) {
		pos = strbreak(args, authData, charsmax(authData), args, charsmax(args));
	}
	if (pos != -1) {
		pos = strbreak(args, accessStr, charsmax(accessStr), args, charsmax(args));
	}
	if (pos != -1) {
		pos = strbreak(args, password, charsmax(password), args, charsmax(args));
	}
	if (pos != -1) {
		pos = strbreak(args, flagsStr, charsmax(flagsStr), args, charsmax(args));
	}
	if (pos != -1) {
		pos = strbreak(args, expiredStr, charsmax(expiredStr), args, charsmax(args));
	}
	if (pos != -1) {
		pos = strbreak(args, staticStr, charsmax(staticStr), args, charsmax(args));
	}
	if (pos != -1) {
		copy(nickname, charsmax(nickname), args);
	}
	#else
	new pos;
	pos = argparse(args, pos, addFlagsStr, charsmax(addFlagsStr));
	if (pos != -1) {
		pos = argparse(args, pos, authData, charsmax(authData));
	}
	if (pos != -1) {
		pos = argparse(args, pos, accessStr, charsmax(accessStr));
	}
	if (pos != -1) {
		pos = argparse(args, pos, password, charsmax(password));
	}
	if (pos != -1) {
		pos = argparse(args, pos, flagsStr, charsmax(flagsStr));
	}
	if (pos != -1) {
		pos = argparse(args, pos, expiredStr, charsmax(expiredStr));
	}
	if (pos != -1) {
		pos = argparse(args, pos, staticStr, charsmax(staticStr));
	}
	if (pos != -1) {
		copy(nickname, charsmax(nickname), args[pos]);
	}
	#endif

	trim(addFlagsStr);
	trim(authData);
	trim(accessStr);
	trim(password);
	trim(flagsStr);
	trim(expiredStr);
	trim(staticStr);
	trim(nickname);
	remove_quotes(addFlagsStr);
	remove_quotes(authData);
	remove_quotes(accessStr);
	remove_quotes(password);
	remove_quotes(flagsStr);
	remove_quotes(expiredStr);
	remove_quotes(staticStr);
	remove_quotes(nickname);

	new addFlags = read_flags(addFlagsStr);
	new access = read_flags(accessStr);
	new flags = read_flags(flagsStr);
	new expired = (expiredStr[0] && strcmp(expiredStr, "0") != 0) ? parse_time(expiredStr, "%d.%m.%Y") : 0;
	new bool:static_bantime = str_to_num(staticStr) ? true : false;

	AddAdmin(addFlags, authData, password, access, flags, expired, nickname, static_bantime);

	new name[MAX_NAME_LENGTH], authid[22], ip[16];
	get_user_name(id, name, charsmax(name));
	get_user_authid(id, authid, charsmax(authid));
	get_user_ip(id, ip, charsmax(ip), 1);

	LogAction("Admin <%s><%s><%s> add new admin <%s><%s><%s><%s><%s><%s>", name, authid, ip, authData, password, accessStr, flagsStr, expiredStr, nickname);

	console_print(id, "[%s] Admin added successfully", LOG_TAG);

	return PLUGIN_HANDLED;
}

DBGetAdminList()
{
	new pquery[512];
	formatex(pquery, charsmax(pquery), "SELECT id, steamid, flags FROM %s_amxadmins", g_DbPrefix);
	SQL_ThreadQuery(g_DBTuple, "DBGetAdminListPost", pquery);
}

public DBGetAdminListPost(failstate, Handle:query, const error[], errornum, const data[], size, Float:queuetime)
{
	if (failstate) {
		SQL_Error(query, error, errornum, failstate);
	} else if (SQL_NumResults(query) > 0) {
		new qcolId = SQL_FieldNameToNum(query, "id");
		new qcolAuth = SQL_FieldNameToNum(query, "steamid");
		new qcolFlags = SQL_FieldNameToNum(query, "flags");

		new flags[32];

		while (SQL_MoreResults(query)) {
			setc(g_AdminsListElement[AdminListAuth], sizeof g_AdminData[AdminListAuth], 0);

			g_AdminsListElement[AdminListId] = SQL_ReadResult(query, qcolId);
			SQL_ReadResult(query, qcolAuth, g_AdminsListElement[AdminListAuth], charsmax(g_AdminsListElement[AdminListAuth]));
			SQL_ReadResult(query, qcolFlags, flags, charsmax(flags));

			g_AdminsListElement[AdminListFlags] = read_flags(flags);

			g_AdminsListElement[AdminListDB] = true;

			ArrayPushArray(g_AdminsList, g_AdminsListElement);

			SQL_NextRow(query);
		}
	}

	SQL_FreeHandle(query);
}

bool:AddAdmin(const addFlags, const authData[], const password[], const access, const flags, const expired, const nickname[] = "", const bool:static_bantime = true)
{
	if (g_Status != STATUS_LOADED) {
		return false;
	}
	new tmp[10], tmp1[32], tmp2[32];
	get_flags(addFlags, tmp, charsmax(tmp));
	get_flags(access, tmp1, charsmax(tmp1));
	get_flags(flags, tmp2, charsmax(tmp2));
	server_print("^t ADD ADMIN %s %s %s %s %s %d %s %s", tmp, authData, password, tmp1, tmp2, expired, nickname, static_bantime ? "true" : "false");
	new bool:replace = (addFlags & ADMINLOAD_ADD_REPLACE) ? true : false;
	switch (g_LoadType) {
		case 1: {
			if (addFlags & ADMINLOAD_ADD_DB) {
				DBAddAdmin(authData, password, access, flags, expired, nickname, static_bantime, replace);
			}
		}

		case 2,3: {
			if (addFlags & ADMINLOAD_ADD_DB) {
				DBAddAdmin(authData, password, access, flags, expired, nickname, static_bantime, replace);
			}

			if (addFlags & ADMINLOAD_ADD_FILE) {
				FileAddAdmin(authData, password, access, flags, expired, nickname, static_bantime, replace);
			}
		}

		default: {
			if (addFlags & ADMINLOAD_ADD_FILE) {
				FileAddAdmin(authData, password, access, flags, expired, nickname, static_bantime, replace);
			}
		}
	}

	if (expired == 0 || expired > get_systime()) {
		g_AdminData[AdminId] = 0;
		g_AdminData[AdminAccess] = access;
		g_AdminData[AdminFlags] = flags;

		copy(g_AdminData[AdminPass], charsmax(g_AdminData[AdminPass]), password);

		if (nickname[0]) {
			copy(g_AdminData[AdminNick], charsmax(g_AdminData[AdminNick]), nickname);
		} else  {
			copy(g_AdminData[AdminNick], charsmax(g_AdminData[AdminNick]), authData);
		}

		g_AdminData[AdminStaticBandtime] = static_bantime;
		g_AdminData[AdminExpired] = expired;

		g_AdminData[AdminPassHashed] = false;
		g_AdminData[AdminLoadDB] = false;

		if (g_AdminData[AdminExpired] == 0 || g_AdminData[AdminExpired] > get_systime()) {
			PushAdmin(authData);
		}
	}

	return true;
}

DBAddAdmin(const authData[], const password[], const access, const flags, const expired, const nickname[] = "", const bool:static_bantime = true, bool:replace = true)
{
	new admin_id = GetAdminId(authData, flags & (FLAG_AUTHID | FLAG_IP | FLAG_TAG), true);

	if (admin_id != -1 && !replace) {
		return 0;
	}

	if (g_DBTuple == Empty_Handle) {
		DBMakeTuple();
	}

	new authdataStr[88];
	new passwordStr[64];
	new nicknameStr[64];
	new accessStr[32];
	new flagsStr[32];

	mysql_escape_string(authData, authdataStr, charsmax(authdataStr));
	mysql_escape_string(nickname, nicknameStr, charsmax(nicknameStr));
	get_flags(access, accessStr, charsmax(accessStr));
	get_flags(flags, flagsStr, charsmax(flagsStr));


	switch (g_HashDB) {
		case 0: {
			mysql_escape_string(password, passwordStr, charsmax(passwordStr));
		}

		default: {
			hashPassword(password, passwordStr, charsmax(passwordStr));
		}
	}

	new days = 0;
	if (expired != 0) {
		days = (expired - get_systime()) / 60;
	}

	new pquery[512];
	if (admin_id == -1) {
		formatex(pquery, charsmax(pquery), "INSERT INTO %s_amxadmins (steamid, `password`, access, flags, nickname, created, expired, days) \
		VALUES('%s', '%s', '%s', '%s', '%s', %d, %d, %d)", g_DbPrefix, authdataStr, passwordStr, accessStr, flagsStr, nicknameStr, get_systime(), expired, days);
	} else {
		formatex(pquery, charsmax(pquery), "UPDATE %s_amxadmins SET `password` = '%s', access = '%s', flags = '%s', nickname = '%s', expired = %d, days = %d WHERE id = %d LIMIT 1", 
			g_DbPrefix, passwordStr, accessStr, flagsStr, nicknameStr, expired, days, admin_id);
	}

	new data[48];
	data[0] = static_bantime ? 1 : 0;
	data[1] = admin_id;
	data[2] = flags;
	copy(data[3], charsmax(data) - 3, authData);

	SQL_ThreadQuery(g_DBTuple, "DBAddAdminPost", pquery, data, sizeof data);

	return 1;
}

public DBAddAdminPost(failstate, Handle:query, const error[], errornum, const data[], size, Float:queuetime)
{
	new admin_id = data[1];
	if (failstate) {
		SQL_Error(query, error, errornum, failstate);
	} else if (admin_id == -1) {
		admin_id = SQL_GetInsertId(query);
	}

	SQL_FreeHandle(query);

	if (!failstate) {
		setc(g_AdminsListElement[AdminListAuth], sizeof g_AdminData[AdminListAuth], 0);
		copy(g_AdminsListElement[AdminListAuth], charsmax(g_AdminsListElement[AdminListAuth]), data[3]);
		g_AdminsListElement[AdminListId] = admin_id;
		g_AdminsListElement[AdminListFlags] = data[2];
		g_AdminsListElement[AdminListDB] = true;
		ArrayPushArray(g_AdminsList, g_AdminsListElement);

		new pquery[512];
		formatex(pquery, charsmax(pquery), "REPLACE INTO %s_admins_servers (admin_id, server_id, custom_flags, use_static_bantime) VALUES (%d, %d, '', '%s')", 
			g_DbPrefix, admin_id, g_ServerId, data[0] ? "yes" : "no");

		SQL_ThreadQuery(g_DBTuple, "DBPushAdminPost", pquery, data, 1);
	}
}

public DBPushAdminPost(failstate, Handle:query, const error[], errornum, const data[], size, Float:queuetime)
{
	if (failstate) {
		SQL_Error(query, error, errornum, failstate);
	}

	SQL_FreeHandle(query);
}

FileAddAdmin(const authData[], const password[], const access, const flags, const expired, const nickname[] = "", const bool:static_bantime = true, bool:replace = true)
{
	new admin_id = GetAdminId(authData, flags & (FLAG_AUTHID | FLAG_IP | FLAG_TAG), false);

	if (admin_id != -1 && !replace) {
		return 0;
	}

	new fileName[128];
	get_localinfo("amxx_configsdir", fileName, charsmax(fileName));
	add(fileName, charsmax(fileName), "/users.ini");

	new passwordStr[64];
	new accessStr[32];
	new flagsStr[32];
	new expiredStr[32];

	switch (g_HashFile) {
		case 0: {
			copy(passwordStr, charsmax(passwordStr), password);
		}

		default: {
			hashPassword(password, passwordStr, charsmax(passwordStr));
		}
	}

	get_flags(access, accessStr, charsmax(accessStr));
	get_flags(flags, flagsStr, charsmax(flagsStr));

	format_time(expiredStr, charsmax(expiredStr), "%d.%m.%Y", expired);

	new text[512];
	formatex(text, charsmax(text), "^"%s^" ^"%s^" ^"%s^" ^"%s^" %d %s ^"%s^"", authData, passwordStr, accessStr, flagsStr, static_bantime ? 1 : 0, expiredStr, nickname);

	write_file(fileName, text, admin_id);

	setc(g_AdminsListElement[AdminListAuth], sizeof g_AdminData[AdminListAuth], 0);
	copy(g_AdminsListElement[AdminListAuth], charsmax(g_AdminsListElement[AdminListAuth]), authData);
	g_AdminsListElement[AdminListFlags] = flags;
	g_AdminsListElement[AdminListDB] = false;

	if (admin_id != -1) {
		g_AdminsListElement[AdminListId] = admin_id;
	} else {
		g_AdminsListElement[AdminListId] = file_size(fileName, 1);
	}

	if (g_AdminsList != Invalid_Array) {
		ArrayPushArray(g_AdminsList, g_AdminsListElement);
	}

	return 1;
}

GetAdminId(const authData[], const flags, bool:db)
{
	if (g_AdminsList == Invalid_Array) {
		return -1;
	}

	for (new i = 0, l = ArraySize(g_AdminsList), searchFlags; i < l; i++) {
		ArrayGetArray(g_AdminsList, i, g_AdminsListElement);

		searchFlags = flags == 0 ? 1 : (g_AdminsListElement[AdminListFlags] & flags);
		if (g_AdminsListElement[AdminListDB] == db && searchFlags && !strcmp(authData, g_AdminsListElement[AdminListAuth])) {
			return g_AdminsListElement[AdminListId];
		}
	}

	return -1;
}
#endif

stock mysql_escape_string(const str[], dest[], len)
{
	copy(dest, len, str);
	replace_all(dest, len, "\\", "\\\\");
	replace_all(dest, len, "\0", "\\0");
	replace_all(dest, len, "\n", "\\n");
	replace_all(dest, len, "\r", "\\r");
	replace_all(dest, len, "\x1a", "\Z");
	replace_all(dest, len, "'", "\'");
	replace_all(dest, len, "^"", "\^"");
}
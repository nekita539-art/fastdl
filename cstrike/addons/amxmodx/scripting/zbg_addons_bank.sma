#include <amxmodx>
#include <nvault>
#include <zombieplague>

#define CMDTARGET_OBEY_IMMUNITY (1<<0)
#define CMDTARGET_ALLOW_SELF	(1<<1)
#define CMDTARGET_ONLY_ALIVE	(1<<2)
#define CMDTARGET_NO_BOTS		(1<<3)

enum pcvar
{
	enable = 0,
	cap,
	start,
	advertise,
	deposit,
	withdraw,
	account,
	savetype,
	bot
}

new gvault, g_msgSayText, pcvars[pcvar], bankstorage[33]

public plugin_init()
{
	register_plugin("[ZP] Sub Plugin: Ultimate Bank", "1.1", "93()|29!/<, Random1");
	register_dictionary("zbg_addons_bank.txt")
	
	gvault = nvault_open("Zombie Bank Ultimate");
	g_msgSayText = get_user_msgid("SayText")
	
	pcvars[enable] =	register_cvar("zp_bank", "1");
	pcvars[cap] =		register_cvar("zp_bank_limit", "757");
	pcvars[start] =		register_cvar("zp_bank_blockstart", "0");
	pcvars[advertise] =	register_cvar("zp_bank_ad_delay", "275.7")
	pcvars[deposit] =	register_cvar("zp_bank_deposit", "1")
	pcvars[withdraw] =	register_cvar("zp_bank_withdraw", "1")
	pcvars[account] =	register_cvar("zp_bank_account", "1")
	pcvars[savetype] =	register_cvar("zp_bank_save_type", "1")
	pcvars[bot] =		register_cvar("zp_bank_bot_support", "1")
	
	if (get_pcvar_num(pcvars[cap]) > 2147483646)
	{
		set_pcvar_num(pcvars[cap], 2147483646);
		server_print("[%L] %L", LANG_PLAYER, "BANK_PREFIX", LANG_PLAYER, "BANK_LIMIT");
	}
	else if (get_pcvar_num(pcvars[cap]) < 1)
		set_pcvar_num(pcvars[cap], 1);
	
	register_clcmd("say", "handle_say");
	register_clcmd("say_team", "handle_say");
	
	if (get_pcvar_num(pcvars[advertise]))
		set_task(get_pcvar_float(pcvars[advertise]), "advertise_loop");
}

public plugin_cfg()
{
	// Plugin is disabled
	if (!get_pcvar_num(pcvars[enable]))
		return;
	
	// Get configs dir
	new cfgdir[32]
	get_configsdir(cfgdir, charsmax(cfgdir))
	
	// Execute config file (zp_rewards.cfg)
	server_cmd("exec %s/zbg_addons_bank.cfg", cfgdir)
}

public advertise_loop()
{
	if (!get_pcvar_num(pcvars[enable]) || !get_pcvar_float(pcvars[advertise]))
	{
		remove_task()
		
		return;
	}
	
	if (get_pcvar_num(pcvars[cap]))
		zp_colored_print(0, "^x04[%L]^x01 %L", LANG_PLAYER, "BANK_PREFIX", LANG_PLAYER, "BANK_INFO1", get_pcvar_num(pcvars[cap]));
	
	if (get_pcvar_num(pcvars[deposit]))
		zp_colored_print(0, "^x04[%L]^x01 %L", LANG_PLAYER, "BANK_PREFIX", LANG_PLAYER, "BANK_INFO_DPS");
	else
		zp_colored_print(0, "^x04[%L]^x01 %L", LANG_PLAYER, "BANK_PREFIX", LANG_PLAYER, "BANK_INFO_AS");
	
	if (get_pcvar_num(pcvars[withdraw]))
		zp_colored_print(0, "^x04[%L]^x01 %L", LANG_PLAYER, "BANK_PREFIX", LANG_PLAYER, "BANK_INFO_WD");
	
	set_task(get_pcvar_float(pcvars[advertise]), "advertise_loop");
}

public plugin_end()
	nvault_close(gvault);
	
public handle_say(id)
{
	if (!get_pcvar_num(pcvars[enable]))
		return PLUGIN_CONTINUE;
	
	new text[70], arg1[32], arg2[32], arg3[6];
	read_args(text, sizeof(text) - 1);
	remove_quotes(text);
	arg1[0] = '^0';
	arg2[0] = '^0';
	arg3[0] = '^0';
	parse(text, arg1, sizeof(arg1) - 1, arg2, sizeof(arg2) - 1, arg3, sizeof(arg3) - 1);

	//strip forward slash if present
	if (equali(arg1, "/", 1))
		format(arg1, 31, arg1[1]);
	
	// if the chat line has more than 2 words, we're not interested at all
	if (arg3[0])
		return PLUGIN_CONTINUE;
	
	if (equali(arg1, "deposit", 7) || equali(arg1, "save", 4) || equali(arg1, "store", 5))
	{
		if (!get_pcvar_num(pcvars[deposit]))
		{
			zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_DNA");
			
			return PLUGIN_CONTINUE;
		}
		
		if (isdigit(arg2[0]) || arg2[0] == '-' && isdigit(arg2[1]))
		{
			new amount = str_to_num(arg2);
			if (amount <= 0)
			{
				zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_VGZ");
				
				return PLUGIN_CONTINUE;
			}
			store_packs(id, amount);
			
			return PLUGIN_HANDLED;
		}
		else if (equali(arg2, "all"))
		{
			store_packs(id, 0);
			
			return PLUGIN_HANDLED;
		}
		else if (!arg2[0])
		{
			zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_HELP_DPS");
			
			return PLUGIN_CONTINUE;
		}
		
		return PLUGIN_CONTINUE;
	}
	else if (equali(arg1, "withdraw", 8) || equali(arg1, "take", 4) || equali(arg1, "retrieve", 8))
	{
		if (!get_pcvar_num(pcvars[withdraw]))
		{
			zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_WNA");
			
			return PLUGIN_CONTINUE;
		}
		
		if (isdigit(arg2[0]) || arg2[0] == '-' && isdigit(arg2[1]))
		{
			new amount = str_to_num(arg2);
			if (amount <= 0)
			{
				zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_VGZ");
				
				return PLUGIN_CONTINUE;
			}
			take_packs(id, amount);
			
			return PLUGIN_HANDLED;
		}
		else if (equali(arg2, "all", 3) || equali(arg2, "everything", 10))
		{
			take_packs(id, 0);
			
			return PLUGIN_HANDLED;
		}
		else if (!arg2[0])
		{
			zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_HELP_WD");
			
			return PLUGIN_CONTINUE;
		}
		
		return PLUGIN_CONTINUE;
	}
	else if (equali(arg1, "packs", 6) || equali(arg1, "account", 7) || equali(arg1, "bank", 4))
	{
		if (!arg2[0])
		{
			zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_INFO_CHK1", bankstorage[id]);
			
			return PLUGIN_HANDLED;
		}
		else
		{
			new id2 = cmd_target(id, arg2, 2);
			if (!id2)
				return PLUGIN_CONTINUE;
			
			static id2name[32];
			get_user_name(id2, id2name, 31);
			zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_INFO_CHK2", id2name, bankstorage[id2]);
			
			return PLUGIN_HANDLED;
		}
		
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_CONTINUE;
}

//public zp_user_disconnect_pre(id)
public client_disconnect(id)
{
	if (!get_pcvar_num(pcvars[enable]))
		return;
	
	if (is_user_bot(id) && !get_pcvar_num(pcvars[bot]) || !zp_get_user_ammo_packs(id))
		return;
	else
		store_packs(id, 0);
	
	if (bankstorage[id] > 0)
		save_data(id);
}

//public zp_user_connect_post(id)
public client_putinserver(id)
{
	if (!get_pcvar_num(pcvars[enable]))
		return;
	
	bankstorage[id] = 0; //clear residual before loading
	retrieve_data(id);
	if (!get_pcvar_num(pcvars[withdraw]))
	{
		if (!bankstorage[id] || is_user_bot(id) && !get_pcvar_num(pcvars[bot]))
			return;
		
		take_packs(id, 0)
	}
}

store_packs(id, amnt)
{
	if (!get_pcvar_num(pcvars[enable]))
		return;
	
	new temp = zp_get_user_ammo_packs(id);
	new limit = get_pcvar_num(pcvars[cap]);
	new fill = limit - bankstorage[id];
	
	if (!temp)
	{
		zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_NAPTD")
		
		return;
	}
	
	if (amnt == 0)
	{
		if (bankstorage[id] + temp <= limit)
		{
			bankstorage[id] += temp;
			zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_DPST", temp)
			zp_set_user_ammo_packs(id, 0);
		}
		else
		{
			zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_CPCT", limit);
			if (!fill)
			{
				zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_NDPST");
				
				return;
			}
			else
			{
				bankstorage[id] += fill
				zp_set_user_ammo_packs(id, temp - fill);
				zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_PADPST", fill);
			}
		}
		checkmax(id);
	}
	else if (amnt > 0)
	{		
		if (temp >= amnt)
		{			
			if (bankstorage[id] + amnt <= limit)
			{
				bankstorage[id] += amnt
				zp_set_user_ammo_packs(id, temp - amnt);
				zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_DPST", amnt)
			}
			else
			{
				zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_CPCT", limit);
				if (!fill)
				{
					zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_NDPST");
					
					return;
				}
				else
				{
					bankstorage[id] += fill
					zp_set_user_ammo_packs(id, temp - fill);
					zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_PDPST", fill, amnt);
				}
			}
		}
		else
		{
			zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_ASTDG", amnt, temp);
			
			return;
		}
	}
}

take_packs(id, amnt)
{
	if (!get_pcvar_num(pcvars[enable]))
		return;
	
	if (!bankstorage[id])
	{
		zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_NPIA")
		
		return;
	}
	
	if (amnt == 0)
	{
		zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + bankstorage[id])
		zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_WALL", bankstorage[id])
		bankstorage[id] = 0;
	}
	else if (amnt > 0)
	{
		if (bankstorage[id] >= amnt)
		{
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + amnt);
			bankstorage[id] -= amnt;
			zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_WAM", amnt)
		}
		else
		{
			zp_colored_print(id, "^x04[%L]^x01 %L", id, "BANK_PREFIX", id, "BANK_ASGB", amnt, bankstorage[id]);
			
			return;
		}
	}
}

save_data(id)
{
	new vaultkey[40], vaultdata[13];
	
	switch (get_pcvar_num(pcvars[savetype]))
	{
		case 1:
		{
			new AuthID[33];
			get_user_authid(id, AuthID, 32);
			
			formatex(vaultkey, 39, "__%s__", AuthID);
		}
		case 2:
		{
			new IP[33];
			get_user_ip(id, IP, 32);
			
			formatex(vaultkey, 39, "__%s__", IP);
		}
		case 3:
		{
			new Name[33];
			get_user_name(id, Name, 32);
			
			formatex(vaultkey, 39, "__%s__", Name);
		}
	}
	formatex(vaultdata, 12, "%i", bankstorage[id]);
	nvault_set(gvault, vaultkey, vaultdata);
}

retrieve_data(id)
{
	new vaultkey[40], vaultdata[13];
	
	switch (get_pcvar_num(pcvars[savetype]))
	{
		case 1:
		{
			new AuthID[33];
			get_user_authid(id, AuthID, 32);
			
			formatex(vaultkey, 39, "__%s__", AuthID);
		}
		case 2:
		{
			new IP[33];
			get_user_ip(id, IP, 32);
			
			formatex(vaultkey, 39, "__%s__", IP);
		}
		case 3:
		{
			new Name[33];
			get_user_name(id, Name, 32);
			
			formatex(vaultkey, 39, "__%s__", Name);
		}
	}
	nvault_get(gvault, vaultkey, vaultdata, 12); 
	
	bankstorage[id] = str_to_num(vaultdata);
	checkmax(id);	
	
	// If they have an account don't allow zombie mod to give them 5 ammo packs at beggining
	if (get_pcvar_num(pcvars[start]) && bankstorage[id] > 0)
		zp_set_user_ammo_packs(id, 0);
}

checkmax(id)
{
	if (bankstorage[id] > get_pcvar_num(pcvars[cap]))
		bankstorage[id] = get_pcvar_num(pcvars[cap]);
	else if (bankstorage[id] < 0)
		bankstorage[id] = 0;
}

// Colored chat print by MeRcyLeZZ
zp_colored_print(target, const message[], any:...)
{
	static buffer[512], i, argscount
	argscount = numargs()
	
	// Send to everyone
	if (!target)
	{
		static player
		for (player = 1; player <= get_maxplayers(); player++)
		{
			// Not connected
			if (!is_user_connected(player))
				continue;
			
			// Remember changed arguments
			static changed[5], changedcount // [5] = max LANG_PLAYER occurencies
			changedcount = 0
			
			// Replace LANG_PLAYER with player id
			for (i = 2; i < argscount; i++)
			{
				if (getarg(i) == LANG_PLAYER)
				{
					setarg(i, 0, player)
					changed[changedcount] = i
					changedcount++
				}
			}
			
			// Format message for player
			vformat(buffer, charsmax(buffer), message, 3)
			
			// Send it
			message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, player)
			write_byte(player)
			write_string(buffer)
			message_end()
			
			// Replace back player id's with LANG_PLAYER
			for (i = 0; i < changedcount; i++)
				setarg(changed[i], 0, LANG_PLAYER)
		}
	}
	// Send to specific target
	else
	{
		// Format message for player
		vformat(buffer, charsmax(buffer), message, 3)
		
		// Send it
		message_begin(MSG_ONE, g_msgSayText, _, target)
		write_byte(target)
		write_string(buffer)
		message_end()
	}
}

// Stock from AmxMisc
stock get_configsdir(name[], len)
	return get_localinfo("amxx_configsdir", name, len);

stock cmd_target(id,const arg[],flags = CMDTARGET_OBEY_IMMUNITY) 
{
	new player = find_player("bl",arg);
	if (player) 
	{
		if ( player != find_player("blj",arg) ) 
		{
#if defined AMXMOD_BCOMPAT
			console_print(id, SIMPLE_T("There are more clients matching to your argument"));
#else
			console_print(id,"%L",id,"MORE_CL_MATCHT");
#endif
			return 0;
		}
	}
	else if ( ( player = find_player("c",arg) )==0 && arg[0]=='#' && arg[1] )
	{
		player = find_player("k",str_to_num(arg[1]));
	}
	if (!player) 
	{
#if defined AMXMOD_BCOMPAT
		console_print(id, SIMPLE_T("Client with that name or userid not found"));
#else
		console_print(id,"%L",id,"CL_NOT_FOUND");
#endif
		return 0;
	}
	if (flags & CMDTARGET_OBEY_IMMUNITY) 
	{
		if ((get_user_flags(player) & ADMIN_IMMUNITY) && 
			((flags & CMDTARGET_ALLOW_SELF) ? (id != player) : true) ) 
		{
			new imname[32];
			get_user_name(player,imname,31);
#if defined AMXMOD_BCOMPAT
			console_print(id, SIMPLE_T("Client ^"%s^" has immunity"), imname);
#else
			console_print(id,"%L",id,"CLIENT_IMM",imname);
#endif
			return 0;
		}
	}
	if (flags & CMDTARGET_ONLY_ALIVE) 
	{
		if (!is_user_alive(player)) 
		{
			new imname[32];
			get_user_name(player,imname,31);
#if defined AMXMOD_BCOMPAT
			console_print(id, SIMPLE_T("That action can't be performed on dead client ^"%s^""), imname);
#else
			console_print(id,"%L",id,"CANT_PERF_DEAD",imname);
#endif
			return 0;
		}
	}
	if (flags & CMDTARGET_NO_BOTS) 
	{
		if (is_user_bot(player)) 
		{
			new imname[32];
			get_user_name(player,imname,31);
#if defined AMXMOD_BCOMPAT
			console_print(id, SIMPLE_T("That action can't be performed on bot ^"%s^""), imname);
#else
			console_print(id,"%L",id,"CANT_PERF_BOT",imname);
#endif
			return 0;
		}
	}
	return player;
}

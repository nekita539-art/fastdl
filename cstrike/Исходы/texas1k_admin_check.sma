#include <amxmodx> 
#include <amxmisc>  
#include <ColorChat> 

/***********************************************************\ 
*                          ACCESS                           * 
*                                                           * 
*        Owner Flags - (A) bcdefghijklmnopqrstu             *
*        Manager Flags - (T) cdefghijklmnopqrstu            *
*        Admins Flags - (M) cdefghijkmnopqrstu              *
*        VIP Flags - (C)  cjeip                             *
*                                                           *
\***********************************************************/ 

public plugin_init() { 
	register_plugin("Admin-Check", "5.5", "p1Mp & S1n[L]Ss") 
	
	register_clcmd("say /admin", "show_admins") 
	register_clcmd("say /admins", "show_admins") 
	register_clcmd("say /vip", "show_admins")
	register_clcmd("say /vips", "show_admins")
	register_clcmd("say_team /admin", "show_admins") 
	register_clcmd("say_team /admins", "show_admins") 
	register_clcmd("say_team /vip", "show_admins")
	register_clcmd("say_team /vips", "show_admins")
} 

public show_admins(id) {
	new Owner[5], oCounter = 0 
	new Manager[16], mCounter = 0 
	new Admins[16], aCounter = 0 
	new VIP[16], vCounter = 0 
	new MaxP[32], pCounter, player 
	
	get_players(MaxP, pCounter, "ch") 
	
	for (new i=0 ; i<pCounter ; i++) 
	{ 
		player = MaxP[i] 
		
		if (access(player, ADMIN_IMMUNITY)) {  
			Owner[oCounter] = player 
			oCounter++ 
			continue; 
		} 
		
		if (access(player, ADMIN_RCON)) { 
			Manager[mCounter] = player 
			mCounter++ 
			continue; 
		}    
		
		if (access(player, ADMIN_LEVEL_F)) { 
			Admins[aCounter] = player 
			aCounter++ 
			continue; 
		}             
		
		if (access(player, ADMIN_LEVEL_D)) { 
			VIP[vCounter] = player 
			vCounter++ 
			continue; 
		}             
	} 
	if (oCounter == 0)    // If no Head Admins are online  
	{  
		ColorChat(id,GREEN,"^3[^1 SERVER ^3] ^4Гл.Админы: ^3в сети нет.")  
	}      
	else  
	{  
		new ronline[200]  
		new rname[32], iOwnerID  
		
		for (new z=0 ; z<oCounter ; z++)  
		{  
			iOwnerID = Owner[z]  
			get_user_name(iOwnerID, rname, 31)  
			add(ronline, charsmax(ronline), rname)  
			
			if (z != oCounter-1)  
			{  
				add(ronline, charsmax(ronline), ", ")  
			}  
			
		}  
		ColorChat(id,GREEN,"^3[^1 SERVER ^3] ^4Гл.Админы: ^3%s.", ronline)  
	} 
	
	if (mCounter == 0)    // If no Manager are online  
	{  
		ColorChat(id,GREEN,"^3[^1 SERVER ^3] ^4Короли: ^3в сети нет.")  
	}  
	else  
	{  
		new monline[200]  
		new mname[32], iManagerID  
		
		for (new z=0 ; z<mCounter ; z++)  
		{  
			iManagerID = Manager[z]  
			get_user_name(iManagerID, mname, 31)  
			add(monline, charsmax(monline), mname)  
			
			if (z != mCounter-1)  
			{  
				add(monline, charsmax(monline), ", ")  
			}  
			
		} 
		ColorChat(id,GREEN,"^3[^1 SERVER ^3] ^4Короли: ^3%s.", monline)  
	} 
	
	if (aCounter == 0)    // If no Admins are online  
	{  
		ColorChat(id,GREEN,"^3[^1 SERVER ^3] ^4Арканы: ^3в сети нет.")  
	}  
	else  
	{  
		new aonline[200]  
		new aname[32], iAdminID  
		
		for (new z=0 ; z<aCounter ; z++)  
		{  
			iAdminID = Admins[z]  
			get_user_name(iAdminID, aname, 31)  
			add(aonline, charsmax(aonline), aname)  
			
			if (z != aCounter-1)  
			{  
				add(aonline, charsmax(aonline), ", ")  
			}  
			
			
		} 
		ColorChat(id,GREEN,"^3[^1 SERVER ^3] ^4Арканы: ^3%s.", aonline)  
	} 
	
	if (vCounter == 0)    // If no VIP are online  
	{  
		ColorChat(id,GREEN,"^3[^1 SERVER ^3] ^4Лордов: ^3в сети нет.")  
	}  
	else  
	{  
		new vonline[200]  
		new vname[32], iVIPID  
		
		for (new z=0 ; z<vCounter ; z++)  
		{  
			iVIPID = VIP[z]  
			get_user_name(iVIPID, vname, 31)  
			add(vonline, charsmax(vonline), vname)  
			
			if (z != vCounter-1)  
			{  
				add(vonline, charsmax(vonline), ", ")  
			}  
			
		} 
		ColorChat(id,GREEN,"^3[^1 SERVER ^3] ^4Лордов: ^3%s.", vonline)      
	}  
} 
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang1037\\ f0\\ fs16 \n\\ par }
*/

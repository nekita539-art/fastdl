#include <amxmodx>
#include <hamsandwich>
#include <zombieplague>

#define TASK_HEALTH 1234554321

new g_iHudSync

public plugin_init() 
{
	register_plugin("[ZP] Survivor and Namesis HP", "1.0", "O_o")

	g_iHudSync = CreateHudSyncObj()

	RegisterHam(Ham_Spawn, "player", "Fwd_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "Fwd_PlayerKilled_Pre", 0)
}

public Fwd_PlayerSpawn_Post(id)
{
	if(task_exists(id+TASK_HEALTH))
	remove_task(id+TASK_HEALTH)
}

public Fwd_PlayerKilled_Pre(victim, attacker, shouldgib)
{
	if(task_exists(victim+TASK_HEALTH))
	remove_task(victim+TASK_HEALTH)
}

public zp_round_started(mode, id)
{
	if(mode != MODE_SURVIVOR && mode != MODE_NEMESIS)
		return

	if(!zp_get_user_survivor(id) && !zp_get_user_nemesis(id))
		return

	set_task(1.0, "Task_ShowHealth", id+TASK_HEALTH, _, _, "b")
}

public Task_ShowHealth(id)
{
	id -= TASK_HEALTH

	if(!zp_get_user_survivor(id) && !zp_get_user_nemesis(id))
		remove_task(id+TASK_HEALTH)

	if(zp_get_user_survivor(id))
	{
		set_hudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), -1.0, 0.2, 0, 1.0, 1.0, 0.1, 0.2, -1)
		ShowSyncHudMsg(0, g_iHudSync, "Жизни Выжившего: %d", get_user_health(id))
	}
	if(zp_get_user_nemesis(id))
	{
		set_hudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), -1.0, 0.2, 0, 1.0, 1.0, 0.1, 0.2, -1)
		ShowSyncHudMsg(0, g_iHudSync, "Жизни Дракона: %d", get_user_health(id))
	}
}
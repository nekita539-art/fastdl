#include <amxmodx>
#include <hamsandwich>
#include <zombieplague>
#include <dhudmessage>

#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "Kulogram"

#define IsConnected(%1) (1 <= %1 <= g_iMaxPlayers && g_bIsConnected[%1])

new g_iMaxPlayers
new bool:g_bIsConnected[33]
new g_syncHudMessage// 2 Канал 

public plugin_init() 
{
    register_plugin("texas1k_kh_health", PLUGIN_VERSION, PLUGIN_AUTHOR)
    
    RegisterHam(Ham_TakeDamage, "player", "fw_Player_TakeDamage_Post", 1)
    
    g_iMaxPlayers = get_maxplayers()
    g_syncHudMessage = CreateHudSyncObj() 
}

public client_putinserver(iId) g_bIsConnected[iId] = true
public client_disconnect(iId) g_bIsConnected[iId] = false

public fw_Player_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:flDamage, iDamageType)
{                 
    if(!IsConnected(iAttacker) || iVictim == iAttacker)
        return HAM_IGNORED
    
    if(zp_get_user_zombie(iVictim))
    {
        static iVictimHealth
        iVictimHealth = get_user_health(iVictim)
        if(iVictimHealth)
        {
        set_hudmessage(237, 230, 33, -1.0, -0.71, 0, 1.1, 1.1, 0.1, 0.0, 2)// 2 Канал 
        ShowSyncHudMsg(iAttacker, g_syncHudMessage, "[Жизни: %d]^n[Урон: %.1f]", iVictimHealth, flDamage)
        }
    }
    return HAM_IGNORED
}

/*================================================================================  
      
    -------------------------------------------------  
    -*- [ZP] Extra Item: Anti-Infection Armor 1.0 -*-  
    -------------------------------------------------  
      
    ~~~~~~~~~~~~~~~  
    - Description -  
    ~~~~~~~~~~~~~~~  
      
    This item gives humans some armor that offers protection  
    against zombie injuries.  
      
================================================================================*/  

#include <amxmodx>  
#include <fakemeta>  
#include <zombieplague>  
#include <engine>  
#include <hamsandwich>  

/*================================================================================  
 [Plugin Customization]  
=================================================================================*/  


new const g_item_name[] = { "Шапка + \y(Броня)" }  
const g_item_cost = 10 

new const g_sound_buyarmor[] = { "items/tr_kevlar.wav" }  
new const g_Santa[] = { "models/zbg/costume_star_wars.mdl" }  
const g_armor_amount = 100 
const g_armor_limit = 250  

new Ent[33]  

/*============================================================================*/  

// Item IDs  
new g_itemid_humanarmor  

public plugin_precache()  
{  
    precache_sound(g_sound_buyarmor)  
    precache_model( g_Santa )  
}  

public plugin_init()  
{  
    register_plugin("[ZP] Extra: Anti-Infection Armor", "1.0", "MeRcyLeZZ")  
      
    RegisterHam(Ham_Spawn, "player", "Spawn_Post", 1)  
      
    g_itemid_humanarmor = zp_register_extra_item(g_item_name, g_item_cost, ZP_TEAM_HUMAN)  
}  

public Spawn_Post(id)  
{  
    remove_hat(id)  
      
}  
public client_connect(id)  
{  
    remove_hat(id)  
      
}  

public client_disconnect(id)  
{  
    remove_hat(id)  
      
}  

public remove_hat(id)  
{  
    if(Ent[id] > 0)  
    {  
        remove_entity(Ent[id])  
        Ent[id] = 0  
          
    }  
}  

// Human buys our upgrade, give him some armor  
public zp_extra_item_selected(player, itemid)  
{  
    if (itemid == g_itemid_humanarmor)  
    {  
        set_pev(player, pev_armorvalue, float(min(pev(player, pev_armorvalue)+g_armor_amount, g_armor_limit)))  
        engfunc(EngFunc_EmitSound, player, CHAN_BODY, g_sound_buyarmor, 1.0, ATTN_NORM, 0, PITCH_NORM)  
        //set_view(player, CAMERA_3RDPERSON)  
          
        if(Ent[player] < 1)  
        {  
            Ent[player] = create_entity("info_target")  
            if(is_valid_ent(Ent[player]))  
            {  
                entity_set_model(Ent[player], g_Santa)  
                entity_set_int(Ent[player], EV_INT_movetype, MOVETYPE_FOLLOW)  
                entity_set_edict(Ent[player], EV_ENT_aiment, player)  
            }  
        }  
    }  
}  

public zp_user_infected_post(id, inf, nem) 
{ 
    if(Ent[id] > 0) 
    remove_hat(id) 
     
} 
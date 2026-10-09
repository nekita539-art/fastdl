#include <amxmodx>
#include <zombieplague>

new const zclass_name[] = "• Паразит" // name
new const zclass_info[] = "\rАтака 2x •" // description
new const zclass_model[] = "strong_finger2_z7p" // model
new const zclass_clawmodel[] = "v_strong_finger3.mdl" // claw model
const zclass_health = 7500 // health
const zclass_speed = 240 // speed
const Float:zclass_gravity = 0.8 // gravity
const Float:zclass_knockback = 6.0 // knockback 

public plugin_precache()
{ 
	register_plugin("[ZP] Classic Zombie", "1.0", "dias")
	zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
}
#include <amxmodx>
#include <fakemeta>
#include <zombieplague>

new const zclass1_name[] = { "• Классик" }
new const zclass1_info[] = { "\rОбычный •" }
new const zclass1_model[] = { "cso_class_classic" }
new const zclass1_clawmodel[] = { "v_classic.mdl" }
const zclass1_health = 7000
const zclass1_speed = 250
const Float:zclass1_gravity = 0.81
const Float:zclass1_knockback = 6.0

public plugin_precache()
{
	register_plugin("[ZP] Class: Classic", "1.0", "lolkek")
	
	zp_register_zombie_class(zclass1_name, zclass1_info, zclass1_model, zclass1_clawmodel, zclass1_health, zclass1_speed, zclass1_gravity, zclass1_knockback)
}

/* Npc Register System functions
*
*  by Good_Hash
*
*  This file is provided as is (no warranties).
*/

#if defined _zp_main_included
	#endinput
#endif
#define _zp_main_included

#pragma reqlib "zp_specialists"


/* Returns zombie class id, -1 otherwise */
native zp_register_class(classname[], description[])

/* Sets zombie player model */
native zp_class_knife_model(classid, npc_model[])
native zp_class_body_model(classid, npc_model[])

/* Return/set value of zombie class data */
native Float:zp_get_class_data(classid, dataid)
native zp_set_class_data(classid, dataid, Float:value)
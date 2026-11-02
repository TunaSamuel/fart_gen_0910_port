// argument0: filename
// argument1: hole id
var ind, ret;

ind = ds_list_find_index(global.list_hh_fname, argument0);

if( ind == -1 ) return -1;

ret = ds_list_find_value(global.list_hh_extra[argument1], ind);
ret = downer16(ret);
//show_debug_message("extra x found!!" + string(ret));
return ret;


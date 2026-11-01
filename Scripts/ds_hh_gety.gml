// argument0: filename
var ind;

ind = ds_list_find_index(global.list_hh_fname, argument0);

if( ind == -1 ) return -1;

return ds_list_find_value(global.list_hh_y, ind);


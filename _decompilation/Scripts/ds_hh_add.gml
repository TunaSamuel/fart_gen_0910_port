// argument1: fname
// argument2: x
// argument3: y

var ind;

ind = ds_list_find_index(global.list_hh_fname, argument0);
show_debug_message("ds_hh_add called");
if( ind == -1 )
{
  ds_list_add(global.list_hh_fname, argument0);
  ds_list_add(global.list_hh_x, argument1);
  ds_list_add(global.list_hh_y, argument2);
}else{
  ds_list_replace(global.list_hh_x, ind, argument1);
  ds_list_replace(global.list_hh_y, ind, argument2);

}


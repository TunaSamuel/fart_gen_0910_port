// argument0: fname
// argument1: hole id
// argument2: x
// argument3: y

// check hole id
if( argument1 < 0 || argument1 > EXTRA_HIP_HOLE_MAX )
    return -1;

var ind;

ind = ds_list_find_index(global.list_hh_fname, argument0);

if( ind == -1 )
{
  ds_list_add(global.list_hh_fname, argument0);
  ds_list_add(global.list_hh_extra[argument1], (argument3 << 16) + argument2);
}else{
  ds_list_replace(global.list_hh_extra[argument1], ind, (argument3 << 16) + argument2);

}

show_debug_message( "add extra hole["+string(argument1)+"] pos ("
             + string(argument2) + ", " + string(argument3)+") ind"+string(ind) );


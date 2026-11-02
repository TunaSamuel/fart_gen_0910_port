/*
Arguments: 
 [0] : particle system
 [1] : size
 [2] : size_increment
 [3] : life
 [4] : speed
 [5] : friction
 [6] : direction
 [7] : range
*/
{
  var smog_size, smog_size_incr, smog_life, smog_speed, smog_fric, smog_dir, smog_range;
  pt_smog = part_type_create();
  pt_smog_shade = part_type_create();
  pt_smog_leave = part_type_create();

  ds_list_add(global.all_pt_list, pt_smog);
  ds_list_add(global.all_pt_list, pt_smog_shade);
  ds_list_add(global.all_pt_list, pt_smog_leave);
 
  smog_size = argument1;
  smog_size_incr = argument2;
  smog_life = argument3;
  smog_speed = argument4;
  smog_fric = argument5;
  smog_dir = argument6;
  smog_range = argument7;

  part_type_shape(pt_smog, pt_shape_smoke );
  part_type_size(pt_smog, smog_size, smog_size, smog_size_incr, 0);
  part_type_life(pt_smog, smog_life, smog_life*1.2);
  
  part_type_speed(pt_smog, smog_speed, smog_speed*1.5, smog_fric, 0);
  part_type_direction(pt_smog, -smog_range/2 + smog_dir, smog_range/2 + smog_dir, 0, 0);

  set_pt_color(pt_smog);
  part_type_alpha3(pt_smog, 0.05, 0.4, 0.1);
  
  return pt_smog;
}

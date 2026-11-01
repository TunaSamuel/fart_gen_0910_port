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
  var rolling_size, rolling_size_incr, rolling_life, rolling_speed, rolling_fric, rolling_dir, rolling_range;
  pt_rolling = part_type_create();
  pt_rolling_leave = part_type_create();

  ds_list_add(global.all_pt_list, pt_rolling);
  ds_list_add(global.all_pt_list, pt_rolling_shade);
  ds_list_add(global.all_pt_list, pt_rolling_leave);
  
  rolling_size = argument1;
  rolling_size_incr = argument2;
  rolling_life = argument3;
  rolling_speed = argument4;
  rolling_fric = argument5;
  rolling_dir = argument6;
  rolling_range = argument7;

  part_type_shape(pt_rolling, pt_shape_explosion );
  part_type_size(pt_rolling, rolling_size, rolling_size, rolling_size_incr, 0);
  part_type_life(pt_rolling, rolling_life, rolling_life*1.2);
  
  part_type_speed(pt_rolling, rolling_speed, rolling_speed*1.5, rolling_fric, 0);
  part_type_direction(pt_rolling, -rolling_range/2 + rolling_dir, rolling_range/2 + rolling_dir, 0, 0);

  set_pt_color(pt_rolling);
  part_type_alpha2(pt_rolling, 0.7, 0.5);
  
  part_type_death(pt_rolling, 1, pt_rolling_leave);

  part_type_orientation(pt_rolling, 0, 0, 16, 10, true);
//  part_type_orientation(pt_rolling_leave, 0, 0, 4, 5, true);
  
  // 残り香
  var shot2_size, shot2_size_incr, shot2_life;
  shot2_size = rolling_size + rolling_size_incr*rolling_life;
  shot2_size_incr = rolling_size_incr;
  shot2_life = rolling_life;
  
  part_type_shape(pt_rolling_leave, pt_shape_explosion);
  part_type_size(pt_rolling_leave, shot2_size, shot2_size*2, shot2_size_incr, 0);
  part_type_life(pt_rolling_leave, shot2_life/2, shot2_life/2);
  part_type_gravity(pt_rolling_leave, 0.1, 90);
  
  set_pt_color(pt_rolling_leave);
  part_type_alpha2(pt_rolling_leave, 0.5, 0.01);
  
  return pt_rolling;
}

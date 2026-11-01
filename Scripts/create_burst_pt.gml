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
 [8] : dir_increment
*/
{
  var burst_size, burst_size_incr, burst_life, burst_speed, burst_fric, burst_dir, burst_range, burst_dir_incr, ps;
  pt_burst = part_type_create();
  pt_burst_shade = part_type_create();
  pt_burst_leave = part_type_create();
  ds_list_add(global.all_pt_list, pt_burst);
  ds_list_add(global.all_pt_list, pt_burst_shade);
  ds_list_add(global.all_pt_list, pt_burst_leave);
  part_type_orientation(pt_burst,0,0,8,10,true);
 
  burst_size = argument1;
  burst_size_incr = argument2;
  burst_life = argument3;
  burst_speed = argument4;
  burst_fric = argument5;
  burst_dir = argument6;
  burst_range = argument7;
  burst_dir_incr = argument8;

  part_type_shape(pt_burst, pt_shape_flare);
  part_type_size(pt_burst, burst_size, burst_size, burst_size_incr, 0);
  part_type_life(pt_burst, burst_life, burst_life*1.2);
  
  part_type_speed(pt_burst, burst_speed*0.5, burst_speed*1.5, burst_fric, 0);
  part_type_direction(pt_burst, -burst_range/2 + burst_dir, burst_range/2 + burst_dir, burst_dir_incr, 0);

  set_pt_color(pt_burst);
  part_type_alpha2(pt_burst, 0.6, 0.3);
  
  part_type_step(pt_burst, 1, pt_burst_shade);
  part_type_death(pt_burst, 1, pt_burst_leave);
  
  // 残像というか尾
  var shot2_size, shot2_size_incr, shot2_life;
  shot2_size = 0.4;
  shot2_size_incr = -0.01;
  shot2_life = 5;
  
  part_type_shape(pt_burst_shade, pt_shape_sphere);
  part_type_size(pt_burst_shade, shot2_size, shot2_size*1.5, shot2_size_incr, 0);
  part_type_life(pt_burst_shade, shot2_life, shot2_life*1.5);
  
  set_pt_color(pt_burst_shade);
  part_type_alpha2(pt_burst_shade, 0.3, 0.1);
  
  // 残り香
  shot2_size = burst_size + burst_size_incr*burst_life;
  shot2_size_incr = 0.1;
  shot2_life = 5;
  
  part_type_shape(pt_burst_leave, pt_shape_cloud);
  part_type_size(pt_burst_leave, shot2_size, shot2_size*2, shot2_size_incr, 0);
  part_type_life(pt_burst_leave, shot2_life, shot2_life*2);
  part_type_gravity(pt_burst_leave, 0.2, 90);
  
  set_pt_color(pt_burst_leave);
  part_type_alpha2(pt_burst_leave, 0.7, 0.4);
  
  return pt_burst;
}

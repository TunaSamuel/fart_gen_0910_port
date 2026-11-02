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
  var mist_size, mist_size_incr, mist_life, mist_speed, mist_fric, mist_dir, mist_range, ps;
  pt_mist = part_type_create();
  pt_mist_shade = part_type_create();
  pt_mist_leave = part_type_create();

  ds_list_add(global.all_pt_list, pt_mist);
  ds_list_add(global.all_pt_list, pt_mist_shade);
  ds_list_add(global.all_pt_list, pt_mist_leave);

  ps = argument0;
  
  mist_size = argument1;
  mist_size_incr = argument2;
  mist_life = argument3;
  mist_speed = argument4;
  mist_fric = argument5;
  mist_dir = argument6;
  mist_range = argument7;

  part_type_shape(pt_mist, pt_shape_explosion );
  part_type_size(pt_mist, mist_size, mist_size, mist_size_incr, 0);
  part_type_life(pt_mist, mist_life, mist_life*1.2);
  
  part_type_speed(pt_mist, mist_speed, mist_speed*1.5, mist_fric, 0);
  part_type_direction(pt_mist, -mist_range/2 + mist_dir, mist_range/2 + mist_dir, 0, 0);

  set_pt_color(pt_mist);
  part_type_alpha3(pt_mist, 0.25, 0.05, 0.01);
  
  part_type_step(pt_mist, -5, pt_mist_shade);
  part_type_death(pt_mist, 1, pt_mist_leave);
  
  // 残像というか尾
  var shot2_size, shot2_size_incr, shot2_life;
  shot2_size = mist_size/2;
  shot2_size_incr = mist_size_incr;
  shot2_life = 10;
  
  part_type_shape(pt_mist_shade, pt_shape_flare);
  part_type_size(pt_mist_shade, shot2_size, shot2_size*1.3, shot2_size_incr, 0);
  part_type_life(pt_mist_shade, shot2_life, shot2_life*1.3);
  
  set_pt_color(pt_mist_shade);
  part_type_alpha2(pt_mist_shade, 0.1, 0.01);
  
  // 残り香
  shot2_size = mist_size + mist_size_incr*mist_life;
  shot2_size_incr = 0.1;
  shot2_life = 40;
  
  part_type_shape(pt_mist_leave, pt_shape_cloud);
  part_type_size(pt_mist_leave, shot2_size, shot2_size*1.5, shot2_size_incr, 0);
  part_type_life(pt_mist_leave, shot2_life, shot2_life*1.5);
  part_type_gravity(pt_mist_leave, 0.05, 90);
  
  set_pt_color(pt_mist_leave);
  part_type_alpha2(pt_mist_leave, 0.2, 0.02);
  
  return pt_mist;
}

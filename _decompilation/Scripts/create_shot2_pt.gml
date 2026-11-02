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
  var shot_size, shot_size_incr, shot_life, shot_speed, shot_fric, shot_dir, shot_range, ps;
  pt_shot = part_type_create();
  pt_shot_shade = part_type_create();
  pt_shot_leave = part_type_create();

  ds_list_add(global.all_pt_list, pt_shot);
  ds_list_add(global.all_pt_list, pt_shot_shade);
  ds_list_add(global.all_pt_list, pt_shot_leave);
  ps = argument0;
  
  shot_size = argument1;
  shot_size_incr = argument2;
  shot_life = argument3;
  shot_speed = argument4;
  shot_fric = argument5;
  shot_dir = argument6;
  shot_range = argument7;

  part_type_shape(pt_shot, pt_shape_smoke);
  part_type_size(pt_shot, shot_size, shot_size, shot_size_incr, 0);
  part_type_life(pt_shot, shot_life, shot_life*1.2);
  
  part_type_speed(pt_shot, shot_speed, shot_speed*1.5, shot_fric, 0);
  part_type_direction(pt_shot, -shot_range/2 + shot_dir, shot_range/2 + shot_dir, 0, 0);

  set_pt_color(pt_shot);
  part_type_alpha2(pt_shot, 0.3, 0.03);
  
  part_type_step(pt_shot, 1, pt_shot_shade);
  part_type_death(pt_shot, 1, pt_shot_leave);
  
  // ショット 残像というか尾
  var shot2_size, shot2_size_incr, shot2_life;
  shot2_size = 0.5;
  shot2_size_incr = -0.02;
  shot2_life = 6;
  
  part_type_shape(pt_shot_shade, pt_shape_smoke);
  part_type_size(pt_shot_shade, shot2_size, shot2_size*1.5, shot2_size_incr, 0);
  part_type_life(pt_shot_shade, shot2_life, shot2_life*1.5);
  
  set_pt_color(pt_shot_shade);
  part_type_alpha2(pt_shot_shade, 0.1, 0.01);
  
  // ショット 残り香
  shot2_size = shot_size + shot_size_incr*shot_life;
  shot2_size_incr = 0.1;
  shot2_life = 6;
  
  part_type_shape(pt_shot_leave, pt_shape_cloud);
  part_type_size(pt_shot_leave, shot2_size, shot2_size*2, shot2_size_incr, 0);
  part_type_life(pt_shot_leave, shot2_life, shot2_life*2);
  part_type_gravity(pt_shot_leave, 0.2, 90);
  
  set_pt_color(pt_shot_leave);
  part_type_alpha2(pt_shot_leave, 0.2, 0.01);
  
  return pt_shot;
}

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
  pt_simple = part_type_create();
  pt_simple_second = part_type_create();
  pt_simple_thrid = part_type_create();

  ds_list_add(global.all_pt_list, pt_simple);
  ds_list_add(global.all_pt_list, pt_simple_second);
  ds_list_add(global.all_pt_list, pt_simple_thrid);

  part_type_orientation(pt_simple,0,0,12,10,true);
  part_type_orientation(pt_simple_second,0,0,15,10,true);
  part_type_orientation(pt_simple_thrid,0,0,17,10,true);
  
  shot_size = argument1;
  shot_size_incr = argument2;
  shot_life = argument3;
  shot_speed = argument4;
  shot_fric = argument5;
  shot_dir = argument6;
  shot_range = argument7;

  part_type_shape(pt_simple, pt_shape_smoke);
  part_type_size(pt_simple, shot_size, shot_size, shot_size_incr, 0);
  part_type_life(pt_simple, shot_life, shot_life);
  
  part_type_speed(pt_simple, shot_speed, shot_speed*2, shot_fric, 0);
  part_type_direction(pt_simple, -shot_range/2 + shot_dir, shot_range/2 + shot_dir, 0, 0);

  set_pt_color(pt_simple);
  part_type_alpha2(pt_simple, 0.9, 0.3);
  
  part_type_step(pt_simple, -10, pt_simple_second);
  part_type_step(pt_simple_second, -10, pt_simple_thrid);
  
  // ショット 第二波
  var shot2_size, shot2_size_incr, shot2_life;
  shot2_size = shot_size;// + shot_size_incr*shot_life;
  shot2_size_incr = shot_size_incr*1.5;
  shot2_life = shot_life;
  
  part_type_shape(pt_simple_second, pt_shape_smoke);
  part_type_speed(pt_simple_second, shot_speed/2, shot_speed, shot_fric, 0);
  part_type_size(pt_simple_second, shot2_size, shot2_size*1.5, shot2_size_incr, 0);
  part_type_life(pt_simple_second, shot2_life, shot2_life*1.5);
  
  set_pt_color(pt_simple_second);
  part_type_alpha2(pt_simple_second, 0.9, 0.7);
  
  // ショット 第三波
  shot2_size = shot_size;// + shot_size_incr*shot_life;
  shot2_size_incr = shot_size_incr*3;
  shot2_life = shot_life;
  
  part_type_shape(pt_simple_thrid, pt_shape_smoke);
  part_type_speed(pt_simple_thrid, shot_speed/3, shot_speed/2, shot_fric, 0);
  part_type_size(pt_simple_thrid, shot2_size, shot2_size*2, shot2_size_incr, 0);
  part_type_life(pt_simple_thrid, shot2_life, shot2_life*2);
  part_type_gravity(pt_simple_thrid, 0.5, 90);
  
  set_pt_color(pt_simple_thrid);
  part_type_alpha2(pt_simple_thrid, 0.95, 0.8);
 
  return pt_simple;
}

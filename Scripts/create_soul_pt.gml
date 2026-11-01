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
 [8] ; color
*/
{
  var soul_size, soul_size_incr, soul_life, soul_speed, soul_fric, soul_dir, soul_range, ps;
  pt_soul = part_type_create();
  pt_soul_shade = part_type_create();

  ps = argument0;
  
  soul_size = argument1;
  soul_size_incr = argument2;
  soul_life = argument3;
  soul_speed = argument4;
  soul_fric = argument5;
  soul_dir = argument6;
  soul_range = argument7;
  soul_color = argument8;

//  part_type_sprite(pt_soul, spr_part_soul, true, true, false);
  part_type_shape(pt_soul, pt_shape_flare);
  part_type_size(pt_soul, soul_size, soul_size, soul_size_incr, 0);
  part_type_life(pt_soul, soul_life, soul_life*1.2);
  
  part_type_speed(pt_soul, soul_speed, soul_speed*1.5, soul_fric, 0);
  part_type_direction(pt_soul, -soul_range/2 + soul_dir, soul_range/2 + soul_dir, 0, 0);

  part_type_alpha2(pt_soul, 0.9, 0.3);
  part_type_step(pt_soul, 1, pt_soul_shade);   

  var soul2_size, soul2_size_incr, soul2_life;
  soul2_size = 0.5;
  soul2_size_incr = -0.05;
  soul2_life = 5;
  
  part_type_shape(pt_soul_shade, pt_shape_flare);
  part_type_size(pt_soul_shade, soul2_size, soul2_size, soul2_size_incr, 0);
  part_type_life(pt_soul_shade, soul2_life, soul2_life);
  
  part_type_alpha2(pt_soul_shade, 0.3, 0.1);

  part_type_color1(pt_soul_shade, soul_color);
  part_type_color1(pt_soul, soul_color);

  part_type_blend(pt_soul, true);
  part_type_blend(pt_soul_shade, true);
 
  return pt_soul;
}

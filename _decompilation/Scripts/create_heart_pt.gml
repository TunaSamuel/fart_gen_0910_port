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
  var heart_size, heart_size_incr, heart_life, heart_speed, heart_fric, heart_dir, heart_range, ps;
  pt_heart = part_type_create();
  pt_heart_shade = part_type_create();

  ps = argument0;
  
  heart_size = argument1;
  heart_size_incr = argument2;
  heart_life = argument3;
  heart_speed = argument4;
  heart_fric = argument5;
  heart_dir = argument6;
  heart_range = argument7;

  part_type_sprite(pt_heart, spr_part_heart, true, true, false);
  part_type_size(pt_heart, heart_size, heart_size, heart_size_incr, 0);
  part_type_life(pt_heart, heart_life, heart_life*1.2);
  
  part_type_speed(pt_heart, heart_speed, heart_speed*1.5, heart_fric, 0);
  part_type_direction(pt_heart, -heart_range/2 + heart_dir, heart_range/2 + heart_dir, 0, 0);

  part_type_alpha2(pt_heart, 0.9, 0.3);
//  part_type_gravity(pt_heart, 0.1, 270);
   
  return pt_heart;
}

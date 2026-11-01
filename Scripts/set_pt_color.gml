// argument0: particle_index

var rand;
rand = floor(random(5));
// pink  
//part_type_color3(argument0, make_color_rgb(220, 98, 234), make_color_rgb(255, 128, 234), make_color_rgb(255, 128, 255));
switch(rand){
case 0:
  part_type_color3(argument0, make_color_rgb(220, 188, 48), make_color_rgb(225, 208, 84), make_color_rgb(225, 228, 155));
  break;
case 1:
  set_pt_color2(argument0, make_color_rgb(202, 198, 85), make_color_rgb(178, 174, 70));
  break;
case 2:
  set_pt_color2(argument0, make_color_rgb(230, 223, 141), make_color_rgb(178, 174, 70));
  break;
case 3:
  part_type_color3(argument0, make_color_rgb(230, 223, 141), make_color_rgb(202, 198, 85), make_color_rgb(178, 174, 70));
  break;
default:
  part_type_color3(argument0, make_color_rgb(200, 168, 48), make_color_rgb(215, 178, 54), make_color_rgb(215, 188, 55));
  break;
}



var particle1;

 particle1 = part_type_create();
part_type_shape(particle1,pt_shape_line);
part_type_size(particle1,0.20,0.60,0.04,0);
part_type_scale(particle1,0.65,2.50);
part_type_color3(particle1,16749459,33023,255);
part_type_alpha3(particle1,0.04,0.06,0.07);
part_type_speed(particle1,4,7,-0.02,0);
part_type_direction(particle1,-20,10,0,9);
part_type_gravity(particle1,0.08,90);
part_type_orientation(particle1,0,0,10,20,true);
part_type_blend(particle1,true);
part_type_life(particle1,60,80);

return particle1;

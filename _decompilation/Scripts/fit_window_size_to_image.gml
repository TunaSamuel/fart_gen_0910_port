// argument0: background index
// argument1: scale

var imgwid, imghei, ind, wwid, whei, vx, vy, centerx, centery;

wwid = window_get_width();
whei = window_get_height();
//vx = global.hip_hole_x[global.cur_bkg_index]/argument1 - global.hip_hole_x[global.cur_bkg_index]
//vy = global.hip_hole_y[global.cur_bkg_index]/argument1 - global.hip_hole_y[global.cur_bkg_index]
vx = 0;
vy = 0;
ind = argument0;

imgwid = background_get_width(ind);
imghei = background_get_height(ind);
//imgwid = background_get_width(ind)/argument1;
//imghei = background_get_height(ind)/argument1;

if ( imgwid / imghei > view_wport[0] / view_hport[0]) { // 横幅いっぱいの時
   imghei = imgwid / view_wport[0] * view_hport[0];
   vy = -(imghei - background_get_height(ind)) / 2;
}else { // 縦幅いっぱいの時
   imgwid = imghei / view_hport[0] * view_wport[0];
   vx = -(imgwid - background_get_width(ind)) /2;
}

centerx = global.hip_hole_x[global.cur_bkg_index] + global.delta_x;
centery = global.hip_hole_y[global.cur_bkg_index] + global.delta_y;

vx = vx * ( 1/argument1) + (1.0 - 1/argument1) * centerx;
vy = vy * ( 1/argument1) + (1.0 - 1/argument1) * centery;
imgwid /= argument1;
imghei /= argument1;

view_enabled = true;

view_xview[0] = vx;
view_yview[0] = vy;
view_wview[0] = imgwid;
view_hview[0] = imghei;

view_visible[0] = true;



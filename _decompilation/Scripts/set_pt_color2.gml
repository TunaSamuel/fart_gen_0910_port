/*
 argument0 : pt index
 argument1 : color1
 arugment2 : color2

引数指定した2色をランダムで変動させて，パーティクルの色に割り当てる．
*/

{
  var col1, col2, pt, r, g, b;
  pt = argument0;
  col1 = argument1;
  col2 = argument2;

  r = color_get_red(col1) * (random(0.2)+0.9); // 90% ～ 110%
  g = color_get_green(col1) * (random(0.2)+0.9); // 90% ～ 110%
  b = color_get_blue(col1) * (random(0.2)+0.9); // 90% ～ 110%
  r = median(0, 255, r);
  g = median(0, 255, g);
  b = median(0, 255, b);
  col1 = make_color_rgb(r, g, b);
  
  r = color_get_red(col2) * (random(0.2)+0.9); // 90% ～ 110%
  g = color_get_green(col2) * (random(0.2)+0.9); // 90% ～ 110%
  b = color_get_blue(col2) * (random(0.2)+0.9); // 90% ～ 110%
  r = median(0, 255, r);
  g = median(0, 255, g);
  b = median(0, 255, b);
  col2 = make_color_rgb(r, g, b);
  
  part_type_color2( pt, col1, col2);

}


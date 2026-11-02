// argument0: image path
// argument1: touka
var ind;
ind = background_add(argument0, argument1, false);

// タイトルバーのテキストを書き換え
room_caption = "Fart Generator - " + filename_name(argument0)
     + " ["+string(background_get_width(ind))+"x"+string(background_get_height(ind))+"]";

if( obj_load_image.touka ){
  room_caption += " ([F8] Foreground Mode)";
}

return ind;

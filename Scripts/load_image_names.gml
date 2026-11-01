// argument
// [0]: filename_list

// return size of filename_list

load_image_names_to_list( argument0, global.image_dir );

i = ds_list_size(argument0);

show_debug_message("Read " + string(i) + " file(s)");

if( i == 0 )
  show_message("No Image!!");
else
  draw_text_on_board("Load "+string(i)+" Files!", true);


return i;

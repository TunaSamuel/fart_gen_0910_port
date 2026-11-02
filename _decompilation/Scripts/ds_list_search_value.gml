// リストに値があるかどうかを返す
// Argument
// [0]: list_index
// [1]: value

var i, found;
found = false;
for( i=0; i< ds_list_size(argument0); i+=1){
     if( ds_list_find_value(argument0, i) == argument1 ){
         found = true;
         break;
     }
}
return found;


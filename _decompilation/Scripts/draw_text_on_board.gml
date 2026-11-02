// [0]: text
// [1]: bool すでに書いてるテキストを消すかどうか
//          true(1) ... テキストを消す
//          false(0) ... テキストを消さず、同じ場所に描画

if( ! global.show_osd )
    return 0;

text_alignment = argument1;

if( argument1 == true ){
  with( obj_show_text ){ instance_destroy(); }
}

{
  var stxt;
  stxt = instance_create( 0, 0, obj_show_text );
  stxt.disp_text = argument0;
}


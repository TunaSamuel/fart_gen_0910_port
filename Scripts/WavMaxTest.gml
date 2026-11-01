//faster method using string
var wave,maxs,maxw;
maxs = 256;
maxw=256;
wave = argument0;
//show_debug_message("WavMaxTest: " + string(argument0));

l1 = ds_list_create();
l2 = ds_list_create();
FMODInstanceGetWaveSnapshot2(wave,0,maxw*2);
//FMODInstanceGetWaveSnapshot(wave, 0, maxw*2);
//FMODNormalizeWaveData(0, maxw)
FMODSnapShotToDsList(0,maxw,l1)
//wavel = global.FMODbuf
FMODInstanceGetWaveSnapshot2(wave,1,maxw*2);
//FMODNormalizeWaveData(0, maxw)
FMODSnapShotToDsList(0,maxw,l2)

var i,xx,yy,w,h;
i = 1;

var max1;
max1 = 0;
repeat(maxs-1)
{
    max1 = max( max1, ds_list_find_value(l1, i), ds_list_find_value(l2, i));
//    max1 = max( max1, abs(ord(string_char_at(global.FMODbuf, i))-127)/127.0 ) ;
    i+=1;
}
ds_list_destroy(l1);
ds_list_destroy(l2);

//show_debug_message("Wave Max .. " + string(max1));
return real(max1);


<?php

function get_string_between($string, $start, $end){
    $string = " ".$string;
    $ini = strpos($string,$start);
    if ($ini == 0) return "";
    $ini += strlen($start);
    $len = strpos($string,$end,$ini) - $ini;
    return substr($string,$ini,$len);
}

$traject=file_get_contents("traject.txt");
$traject=str_replace(' ','',$traject);
$traject=str_replace(Chr(13).Chr(10),'',$traject);
$traject=str_replace('}','',$traject);
$traject=str_replace('{','',$traject);
$traject=get_string_between($traject, "traject[]=", ";");
$traject=str_replace('0x','',$traject);
$tmp=explode(',',$traject);
$showme='';
    for($x=0;$x<240;$x++){
      for($y=0;$y<160;$y++){
	if($tmp[$y*240+$x]!='00')$showme=$showme.$x.','.$y.',';
      }
     }

$showme='const u8 line[]={'.$showme;
$showme="#include <gba.h> \n\r".$showme;
$showme=substr($showme,0,strlen($showme)-1);
$showme=$showme.'};';
$showme=$showme."\n\r";
$traject=file_put_contents("traject.h",$showme);
?>

<?php
define('HEX2BIN_WS', " \t\n\r");



if(count($argv)<=1)
{
    echo ("\n***************************\n");
    echo ("syntax : convert.php yourfile.xbm \n\n");
    echo ("will convert xbm picture\n");
    echo ("to 6 vcs2600 sprite width (48 pixels)\n");
    echo ("and height defined by user\n");
    echo ("*************************** \n\n");
    exit(1);
}

if (!function_exists('hex2bin')) {
    function hex2bin($data) {
        static $old;
        if ($old === null) {
            $old = version_compare(PHP_VERSION, '5.2', '<');
        }
        $isobj = false;
        if (is_scalar($data) || (($isobj = is_object($data)) && method_exists($data, '__toString'))) {
            if ($isobj && $old) {
                ob_start();
                echo $data;
                $data = ob_get_clean();
            }
            else {
                $data = (string) $data;
            }
        }
        else {
            trigger_error(__FUNCTION__.'() expects parameter 1 to be string, ' . gettype($data) . ' given', E_USER_WARNING);
            return;//null in this case
        }
        $len = strlen($data);
        if ($len % 2) {
            trigger_error(__FUNCTION__.'(): Hexadecimal input string must have an even length', E_USER_WARNING);
            return false;
        }
        if (strspn($data, '0123456789abcdefABCDEF') != $len) {
            trigger_error(__FUNCTION__.'(): Input string must be hexadecimal string', E_USER_WARNING);
            return false;
        }
        return pack('H*', $data);
    }
}

function toflip($str)
{
    $str=substr($str,1,2);
    $str=hex2ascii($str);
    $l = strlen($str);
    $result = '';
    while ($l--) {
        $result = str_pad(decbin(ord($str[$l])), 8, "0", STR_PAD_LEFT) . $result;
    }
    $flip="";
    for($i=7;$i>=0;$i--)
    {
        $flip=$flip.$result[$i];
    }
    $hex = dechex(bindec($flip));
    $hex= "$".str_pad($hex, 2, "0", STR_PAD_LEFT);
    return $hex;
}

function ascii2hex($ascii) {
    $hex = '';
    for ($i = 0; $i < strlen($ascii); $i++)
    {
        $byte = strtoupper(dechex(ord($ascii{$i})));
        $byte = str_repeat('0', 2 - strlen($byte)).$byte;
        $hex.=$byte." ";
    }
return $hex;
}

function hex2ascii($hex){
    $ascii='';
    $hex=str_replace(" ", "", $hex);
    for($i=0; $i<strlen($hex); $i=$i+2) {
        $ascii.=chr(hexdec(substr($hex, $i, 2)));
    }
    return($ascii);
}

function changebin($data)
{
    $data = hexdec ( $data);
    $data = ~$data & 0xff; // Reverse video
    $data = sprintf( "%08d", decbin( $data ));
    $i=0;
    $newdata="";
    for($i=0;$i<=strlen($data);$i++)
    {
        $newdata = $newdata . substr($data,strlen($data)-$i,1);
    }
    
    return($newdata);
}

function changebinspe($data)
{
    $data = hexdec ( $data);
    $data = sprintf( "%08d", decbin( $data ));
    $i=0;
    $newdata="";
    for($i=0;$i<=strlen($data);$i++)
    {
        //$newdata = $newdata . substr($data,strlen($data)-$i,1);
    }
    
    return($data);
}

echo $argv[1]."\n";
$fichier=$argv[1];

/*
if(stripos($fichier, ".")==true)
{
    $basef=explode(".",$fichier);
    $basef=$basef[0];
    echo("Fichier basename :".$basef);
}

*/
if(stripos($fichier, "/")==true)
{
    $basef=explode("/",$fichier);
    $basef=$basef[count($basef)-1];
    //echo $basef;
}else{
    $basef=$fichier;
}//

if(stripos($basef, ".")==true)
{
    $basef=explode(".",$basef);
    $basef=$basef[0];
    $savedfile=$basef.".asm";
}


$a=file_get_contents($fichier);
//
// nettoyage du fichier xbm
//
$splitted = explode("{",$a);
$maxsize = count($splitted);
$newtable = $splitted[1];
$newtable = str_replace(", };","",$newtable); // Some tools let a trailing ','
$newtable = str_replace(" };","",$newtable); // Some tools don't
$newtable = str_replace(" ","",$newtable);
$newtable = str_replace(";","",$newtable);
$newtable = str_replace("\n","",$newtable);
$newtable = str_replace("0x","$",$newtable);
//$newtable = "$00,$00,$00,$00,$00,$00,".$newtable; // ajout de la ligne morte pour le kernel
$tabletoreverse = explode(",",$newtable);
$tabletoreverse = str_replace("$","",$tabletoreverse);
$maxsize = count($tabletoreverse);
$newtable="";

$bc=0;
for($i=0;$i<$maxsize;$i=$i+5)
{
    $newnumber ="0000";
    $newnumber = $newnumber. changebin($tabletoreverse[$i]);
    $newnumber = $newnumber. changebin($tabletoreverse[$i+1]);
    $newnumber = $newnumber. substr(changebin($tabletoreverse[$i+2]),0,4);
    $newnumber = $newnumber. "0000";
    $newnumber = $newnumber. substr(changebin($tabletoreverse[$i+2]),4,4);
    $newnumber = $newnumber. changebin($tabletoreverse[$i+3]);
    $newnumber = $newnumber. changebin($tabletoreverse[$i+4]);
    echo $newnumber."\n";
    
    $arr2 = str_split($newnumber, 8);
    for($j=0;$j<=5;$j++)
    {
        if(strlen(dechex(bindec($arr2[$j])))==1)
        {
            $newtable[$bc+$j] = "$0".dechex(bindec($arr2[$j]));
        }else{
            $newtable[$bc+$j] = "$".dechex(bindec($arr2[$j]));
        }
        
    }
    $arr2="";
    $bc=$bc+6;
    //if($bc>=24)exit(1);
    //echo("\n");
}
//exit(1);
$tabletoreverse= $newtable;
$maxsize = count($tabletoreverse);


//
//flip horizontal
//

for($i=0;$i<$maxsize;$i=$i+6)
{
    $c=0;

        for($j=5;$j>=0;$j--)
        //for($j=0;$j<=5;$j++)
        {
            if($j==0 or $j==2 or $j==3 or $j==5)
            {
                $newtable[$i+$c]=toflip($tabletoreverse[$i+$j]);
            }else{
            
                $newtable[$i+$c]=$tabletoreverse[$i+$j];
            }
            $c++;
        }
    
}
$tabletoreverse=$newtable;

//
//flip vertical de l'image
//
$newtable=$tabletoreverse;
for($i=0;$i<$maxsize;$i++)
{
    $newtable[$i]=$tabletoreverse[($maxsize-1)-$i];
    //echo $newtable[$i]."\n";
}


$maxsize = count($newtable);

echo("Résolution : 48 x".((8*$maxsize)/48)." \n");
echo("Pixels : ".(8*$maxsize)."  \n");
echo("Nb bytes : ".$maxsize."  \n");
$c=1;
$s="";
for($j=0;$j<=5;$j++){
    $c=1;
    $s[$j]="\n        .byte ";
    echo("        ");
    for($i=$j;$i<$maxsize;$i=$i+6)
    {
        if($c>=((8*$maxsize)/48))
        {
            echo $newtable[$i]."\n";
            $s[$j]=$s[$j].$newtable[$i]."\n";
        }else{
            if($c%10==0)
            {
                 echo $newtable[$i]." \n        .byte ";
                $s[$j]=$s[$j].$newtable[$i]." \n        .byte ";           
            }else{
                    echo $newtable[$i].",";
                    $s[$j]=$s[$j].$newtable[$i].",";
            }
        }        
        $c++;
    }
}
$agreg="";
for($i=0;$i<=5;$i++)
{
    echo($s[$i]);
    $agreg=$agreg.$s[$i];
}
$header =".include \"banksetup.inc\"\n";
$header.=".export _$basef\n";
$header.=".segment RODATA_SEGMENT\n";
$header.="\n";
$header.="_$basef:\n";
$agreg=$header.$agreg;
file_put_contents($basef.".s",$agreg);
?>

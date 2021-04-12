#include <gba.h>
#include <gba_dma.h>
#include <maxmod.h>
// 
extern mm_modlayer mmLayerMain;
 
#include "gbalib.h"


//  #include "soundbank.h"
//  #include "soundbank_bin.h"
#include "splash.h"
#define RGB(r,g,b) ((r)+((g)<<5)+((b)<<10)) 
unsigned short int * MODE4_FB = (unsigned short int *) 0x6000000;


void Logo_Atari_Mode4_PutPixel(unsigned short x, unsigned short y, unsigned char Couleur){
  unsigned short temp;
  //récupère la valeur qui est déjà à cette place.
  temp=MODE4_FB[(y * 240 + x)>>1];
  if(x & 1){
    //Si coordonée x paire
    // Efface la partie haute de la variable
    temp = temp & 0x00FF ;
    temp = temp + (Couleur << 8);
  }else{
    //Si coordonée x impaire
    // Efface la partie basse de la variable
    temp = temp & 0xFF00 ;
    temp = temp + Couleur;
  }
  MODE4_FB[(y * 240 + x)>>1]=temp;
}

int main(void);

void rotpal_ori(void){
  int x,tmp;
  tmp=BG_PALETTE[1];
  for(x=1;x<=254;x++){
    BG_PALETTE[x]=BG_PALETTE[x]+1;
  }
  BG_PALETTE[255]=tmp;
}


void palori(void){
    int x;
    for(x=1;x<=128;x++){
    BG_PALETTE[x]=RGB(x+50,100,100);
  }
}


void pal_four(int i){
    int x;
    for(x=1;x<=255;x++){
    BG_PALETTE[x]=RGB(i,i,i);
  }
}

void init_pal_dark(void){
    int x;
    for(x=1;x<=255;x++){
    BG_PALETTE[x]=RGB(0,0,0);
  }
}

void showpicstyle_ori(void)
{
  int val,x,y;
   val=1;
  for(x=0;x<240;x++){
    for(y=0;y<160;y++){
      if(splash[y*240+x]!=0){
	Logo_Atari_Mode4_PutPixel(x,y,val);
	val++;
	if(val>=128){
	  val=1;
	}
      }else{
	Logo_Atari_Mode4_PutPixel(x,y,splash[y*240+x]);
      }
    }
  } 
  
}

void main_logo_atari(void) {
  // int i;

  REG_DISPCNT= (0x4 | 0x400);

  //init_pal_dark();
  showpicstyle_ori();
  palori();
 //u32 time = 400;
  
  while(mmLayerMain.position!=4)
   {
    mmFrame();
    VBlankIntrWait();
//     if(i>33)
//     {
       rotpal_ori(); 
//     }
//     if(i==33){
//      palori();
//       i++;
//     }
//     if(i<=32){
       //pal_four(i);
       //i++;
//     }
    //if(mmLayerMain.row % 12 == 0)BG_PALETTE[0]=RGB(31,31,31);
   // if(mmLayerMain.position== 1)BG_PALETTE[0]=RGB(31,31,31);
   }
}


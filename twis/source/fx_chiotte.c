#include "demo.h"
#include "3d.h"
#include "nmod.h"
#include "chiotte.h"
#include "flush_chiotte.h"

#define VideoBuffer ((u16*)0x6000000)
#define Palette ((u16*)0x5000000)
#define FrontBuffer ((u16*)0x6000000)
#define BackBuffer ((u16*)0x600A000)

#define MODE4_FB ((u16*)0x6000000)

#define maxit 300

typedef struct 
{
    int done;
    int busyme;
    int coul,maxelement;
    int maxind;
    int myx[1000];
    int myy[1000];
    int mycoul[1000];
} Monpack;

static void PutPixel(unsigned short x, unsigned short y, unsigned char Couleur, unsigned short int * TheBuffer){
    unsigned short temp;
    
    temp=TheBuffer[(y * 240 + x)>>1];
    if(x & 1){
        temp = temp & 0x00FF ;
        temp = temp + (Couleur << 8);
    }else{
        temp = temp & 0xFF00 ;
        temp = temp + Couleur;
    }
    TheBuffer[(y * 240 + x)>>1]=temp;
}
static unsigned short GetPixel(unsigned short x, unsigned short y, unsigned char * TheBuffer){
    u8 temp;
    temp=TheBuffer[(y * 240 + x)];
    return temp;
}
static unsigned short GetPixelVRam(unsigned short x, unsigned short y, u16* TheBuffer){
    u16 temp;
    if (y >= 160 || x >= 240) return 0;
    temp=TheBuffer[(y * 240 + x) >> 1];
    return (x&1) ? (temp >> 8) : (temp & 0xFF);
}

void fx_chiotte_init(void)
{
    LoadOverlay(OVERLAY_3D);
    clear_screen(BackBuffer);
    clear_screen(FrontBuffer);  
    Monpack* p;
    g_fx_data = p = iwalloc(sizeof(*p));
    p->done=0;
    
    dmaCopy((void*)imgflush, (void*)BackBuffer, 38400);
    dmaCopy((void*)imgchiotte, (void*)FrontBuffer , 38400);
    dmaCopy((void*)imgchiottePalette, (void*)Palette , 512);
    REG_DISPCNT = MODE_4 | OBJ_1D_MAP | BG2_ON | OBJ_ON;
    
    p->maxind=1000;
    memset32(p->myx, 0, sizeof(p->myx));
    memset32(p->myy, 0, sizeof(p->myy));
    memset32(p->mycoul, 0, sizeof(p->mycoul));
    
    p->maxelement=5;
  
    
    Palette[131]=RGB5(31,31,31);
    Palette[132]=RGB5(31,31,0);
    Palette[133]=RGB5(31,16,0);
    Palette[134]=RGB5(31,8,0);
    Palette[135]=RGB5(31,0,0);
    Palette[136]=RGB5(16,0,0);
    Palette[137]=RGB5(0,0,0);
    
    p->myx[1]=42;
    p->myy[1]=11;
    p->mycoul[1]=131;
    
    p->myx[2]=75;
    p->myy[2]=28;
    p->mycoul[2]=131;
    
    p->myx[3]=106;
    p->myy[3]=13;
    p->mycoul[3]=131;
    
    p->myx[4]=155;
    p->myy[4]=21;
    p->mycoul[4]=131;
    
    p->myx[5]=185;
    p->myy[5]=20;
    p->mycoul[5]=131;
    
    p->coul=131;
    
    int x, y;
    for(y=0;y<39;y++)
    {
        for(x=0;x<=239;x++)
        {
            if(GetPixelVRam(x,y,BackBuffer)!=0)
            {
                PutPixel(x,y+50,p->coul,FrontBuffer);
            }
        }
    }      
    p->busyme=0;
}

void fx_chiotte_deinit()
{
    iwfree(g_fx_data);
}

void fx_chiotte_exec(void)
{
    Monpack* p = g_fx_data;
    int ind;
    ++p->done;

    p->busyme++;
    
    if(p->busyme >= 2)
    {
        for(ind=0;ind<=p->maxelement/2;ind++)
        {
            if(p->mycoul[ind]<=136)
            {
                p->mycoul[ind]++;
                PutPixel(p->myx[ind],p->myy[ind]+50,p->mycoul[ind],FrontBuffer);
                if(p->maxelement<p->maxind)
                {
                    if(GetPixelVRam(p->myx[ind]-1,p->myy[ind],BackBuffer)!=0)
                    {
                        p->maxelement++;
                        p->myx[p->maxelement]=p->myx[ind]-1;
                        p->myy[p->maxelement]=p->myy[ind];
                        p->mycoul[p->maxelement]=131;
                        PutPixel(p->myx[ind]-1,p->myy[ind],0,BackBuffer);
                    }
                    if(GetPixelVRam(p->myx[ind]+1,p->myy[ind],BackBuffer)!=0)
                    {
                        p->maxelement++;
                        p->myx[p->maxelement]=p->myx[ind]+1;
                        p->myy[p->maxelement]=p->myy[ind];
                        p->mycoul[p->maxelement]=131;
                        PutPixel(p->myx[ind]+1,p->myy[ind],0,BackBuffer);
                    }
                    if(GetPixelVRam(p->myx[ind],p->myy[ind]-1,BackBuffer)!=0)
                    {
                        p->maxelement++;
                        p->myx[p->maxelement]=p->myx[ind];
                        p->myy[p->maxelement]=p->myy[ind]-1;
                        p->mycoul[p->maxelement]=131;
                        PutPixel(p->myx[ind],p->myy[ind]-1,0,BackBuffer);
                    }
                    if(GetPixelVRam(p->myx[ind],p->myy[ind]+1,BackBuffer)!=0)
                    {
                        p->maxelement++;
                        p->myx[p->maxelement]=p->myx[ind];
                        p->myy[p->maxelement]=p->myy[ind]+1;
                        p->mycoul[p->maxelement]=131;
                        PutPixel(p->myx[ind],p->myy[ind]+1,0,BackBuffer);
                    }
                    //
                    //
                    //
                    if(GetPixelVRam(p->myx[ind]-1,p->myy[ind]-1,BackBuffer)!=0)
                    {
                        p->maxelement++;
                        p->myx[p->maxelement]=p->myx[ind]-1;
                        p->myy[p->maxelement]=p->myy[ind]-1;
                        p->mycoul[p->maxelement]=131;
                        PutPixel(p->myx[ind]-1,p->myy[ind]-1,0,BackBuffer);
                    }
                    if(GetPixelVRam(p->myx[ind]+1,p->myy[ind]+1,BackBuffer)!=0)
                    {
                        p->maxelement++;
                        p->myx[p->maxelement]=p->myx[ind]+1;
                        p->myy[p->maxelement]=p->myy[ind]+1;
                        p->mycoul[p->maxelement]=131;
                        PutPixel(p->myx[ind]+1,p->myy[ind]+1,0,BackBuffer);
                    }
                    if(GetPixelVRam(p->myx[ind]+1,p->myy[ind]-1,BackBuffer)!=0)
                    {
                        p->maxelement++;
                        p->myx[p->maxelement]=p->myx[ind]+1;
                        p->myy[p->maxelement]=p->myy[ind]-1;
                        p->mycoul[p->maxelement]=131;
                        PutPixel(p->myx[ind]+1,p->myy[ind]-1,0,BackBuffer);
                    }
                    if(GetPixelVRam(p->myx[ind]-1,p->myy[ind]+1,BackBuffer)!=0)
                    {
                        p->maxelement++;
                        p->myx[p->maxelement]=p->myx[ind]-1;
                        p->myy[p->maxelement]=p->myy[ind]+1;
                        p->mycoul[p->maxelement]=131;
                        PutPixel(p->myx[ind]-1,p->myy[ind]+1,0,BackBuffer);
                    }
                }
            }
            if(p->mycoul[ind]>136)
            {
                PutPixel(p->myx[ind],p->myy[ind]+50,GetPixel(p->myx[ind],p->myy[ind]+50,imgchiotte),FrontBuffer);
                p->myx[ind]=0;
                p->myy[ind]=0;
                p->mycoul[ind]=0;
                if(ind!=p->maxelement)
                {
                    p->myx[ind]=p->myx[p->maxelement];
                    p->myy[ind]=p->myy[p->maxelement];
                    p->mycoul[ind]=p->mycoul[p->maxelement];
                    p->maxelement--;
                }else{
                    p->maxelement--;
                }
            }
        }
        p->busyme=0;
    }
    VBlankIntrWait();
}

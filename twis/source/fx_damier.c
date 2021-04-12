#include "demo.h"
#include "nmod.h"
#include "3d.h"
#include "damier_full.h"
#include "fixed.h"
#include "fonte.h"
#include "flush_neon.h"
#define Palette ((u16*)0x5000000)
#define FrontBuffer ((u16*)0x6000000)
#define BackBuffer ((u16*)0x600A000)
#define MODE4_FB ((u16*)0x6000000)
#define maxit 300

static const char * message = "twis demo has been possible thanks to : flure g012 maracuja p0ke zerkman for the code      awesome gfx and design by zerkman g012 p0ke      fantastic music by cyb0rg4 from rsi      greetz : sector one   traktor   xmen   razor 1911   lnx   blabla   abyss connection   poo brain   insane   tjoppen   jac   kk   svolli   jvb   sir garbage truck   tmp   ctrl alt test    evil bot      and all of those who sign my poster              made at revision 2016     revision ruleeeeez           *";
static int hauteurscroll=80;
typedef struct 
{
    int         busyme;
    u8          mycoul[64];
    u16*        VideoBuffer;
    u8          numsprite[20];
    u16          spriteposx[20];
    u8          lettre[20];
    u16         xlogo;
    u16         ylogo;
    u8          xsens;
    
    int         charpos;
    int         decalageLettre;
    
} Monpack;

static int irandom (int _iMin, int _iMax)
{
    return (_iMin + (rand () % (_iMax-_iMin+1)));
} 

static void PL_LoadSprites(const void* data, u32 datasz, const void* pal, u32 palsz,u32 ajout)
{
    memcpy(SPRITE_PALETTE, pal, palsz);
    memcpy(CHAR_BASE_BLOCK(5)+ajout, data, datasz);
}

static void PL_UpdateSprites(u32 x, u32 y, int zoom, int numspr, int numcostard)
{
    OAM[numspr].attr0 = ATTR0_COLOR_256|ATTR0_SQUARE|OBJ_Y(y-32);
    OAM[numspr].attr1 = ATTR1_SIZE_16|OBJ_SHAPE(0)|OBJ_X(x-32);
    OAM[numspr].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(512+(8*numcostard));
}



void fx_damier_init(void)
{
    int i;
    u8 coul;
    Monpack* p;
    g_fx_data = p = iwalloc(sizeof(*p));
    p->VideoBuffer=FrontBuffer;
    p->charpos=0;
    p->decalageLettre=33;
    p->xlogo=120;
    p->ylogo=32;
    p->xsens=1;
    LoadOverlay(OVERLAY_3D);
    clear_screen(BackBuffer);
    clear_screen(FrontBuffer);
    dmaCopy((void*)damier_fullBitmap, (void*)FrontBuffer, 38400);
    dmaCopy((void*)damier_fullBitmap, (void*)BackBuffer , 38400);
    dmaCopy((void*)damier_fullPal, (void*)Palette , 512);
    REG_DISPCNT = MODE_4 | OBJ_1D_MAP | BG2_ON | OBJ_ON;
    memset32(p->mycoul, 0, sizeof(p->mycoul));
    memset32(p->spriteposx, 0, sizeof(p->spriteposx));
    memset32(p->lettre, -1, sizeof(p->lettre));
    
    for(i=0;i<=19;i++)
    {
        p->numsprite[i]=i;
        p->lettre[i]=40;
    }
    for(i=1;i<32;i++)
    {
        p->mycoul[i]=21;
    }
    for(i=32;i<63;i++)
    {
        p->mycoul[i]=0;
    }
    for(i=1;i<=62;i++)
    {
        coul= p->mycoul[i];
        Palette[i]=RGB5(coul,coul,coul);
    }
    
    PL_LoadSprites(fonteTiles, sizeof(fonteTiles), fontePal, sizeof(fontePal),0);
    PL_LoadSprites(flush_neonTiles, sizeof(flush_neonTiles), flush_neonPal, sizeof(flush_neonPal),sizeof(fonteTiles));
    }

void fx_damier_deinit()
{
    iwfree(g_fx_data);
    oam_disable(OAM, 128);
}

void fx_damier_exec(void)
{
    Monpack* p = g_fx_data;
    int g,i,j;
    u8 coul;

    for(i=1;i<=62;i++)
    {
        coul= p->mycoul[i];
        Palette[i]=RGB5(coul,coul,coul);
    }
    for(g=0;g<=1;g++)
    {
        
        p->mycoul[63]=p->mycoul[62];
        for(i=62;i>1;i--)
        {
            p->mycoul[i]= p->mycoul[i-1];
        }
        p->mycoul[1]=p->mycoul[63];
    }
    
    if(p->decalageLettre>=12)
    {
        for(j=0;j<=19;j++)
        {
            if(p->lettre[j]==40)
            {
                p->spriteposx[j]=260;
                if(message[p->charpos]>='0' && message[p->charpos]<='9')
                {
                    p->lettre[j]=(message[p->charpos]-48)+27;   
                }else if(message[p->charpos]==':')
                {
                    p->lettre[j]=(message[p->charpos]-58)+38;   
                }else if(message[p->charpos]=='(')
                {
                    p->lettre[j]=(message[p->charpos]-40)+39;   
                }else if(message[p->charpos]==')')
                {
                    p->lettre[j]=(message[p->charpos]-41)+40; 
                }else if(message[p->charpos]==' ')
                {
                    p->lettre[j]=(message[p->charpos]-32)+26; 
                }
                else if(message[p->charpos]>='a' && message[p->charpos]<='z')
                {
                    p->lettre[j]=message[p->charpos]-97;   
                }
                p->decalageLettre=0;
                break;
            }
        }
        p->charpos++;
        if(message[p->charpos]=='*')
        {
            p->charpos=0;
        }
        p->decalageLettre=0;
    }else{
        p->decalageLettre++;    
        for(j=0;j<=19;j++)
        {
            if(p->lettre[j]<=40)
            {
                p->spriteposx[j]-=2;
                if(p->spriteposx[j]<=0)
                {
                    p->lettre[j]=40;
                }
                x32 sin=X32_SinIdx2(p->spriteposx[j]<<8);
                PL_UpdateSprites(p->spriteposx[j], (hauteurscroll+20*sin>>12)-150,128,p->numsprite[j],p->lettre[j]);
            }
        }
    }
    if(p->xsens==1)
    {
        //x32 sin=X32_SinIdx2(p->xlogo<<8);
        //p->xlogo =p->xlogo+20*sin>>12;
        p->xlogo++;
        if(p->xlogo>=200)
            p->xsens=0;
    }else{
        //x32 sin=X32_SinIdx2(p->xlogo<<8);
        //p->xlogo =p->xlogo+20*sin>>12;
        p->xlogo--;
        if(p->xlogo<=40)
            p->xsens=1;
    }
    PL_UpdateSprites(p->xlogo, p->ylogo,128,25,41);
    PL_UpdateSprites(p->xlogo+16, p->ylogo,128,26,42);
    PL_UpdateSprites(p->xlogo+32, p->ylogo,128,27,43);
    PL_UpdateSprites(p->xlogo+48, p->ylogo,128,28,44);
    PL_UpdateSprites(p->xlogo, p->ylogo+16,128,29,45);
    PL_UpdateSprites(p->xlogo+16, p->ylogo+16,128,30,46);
    PL_UpdateSprites(p->xlogo+32, p->ylogo+16,128,31,47);
    PL_UpdateSprites(p->xlogo+48, p->ylogo+16,128,32,48);

    VBlankIntrWait();
}

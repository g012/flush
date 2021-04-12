#include "demo.h"
#include "effect-manager.h"

//#include <maxmod9.h>
//#include "soundbank_bin.h"

// ---------------
// EDIT MUSIC HERE
// ---------------
#ifdef MUSIC_NMOD
#include "stardstm.mod.h"
#define MOD stardstm_mod
#elif defined(MUSIC_PCM)
#include "rsi_sensl.h"
#include "rsi_sensr.h"
#define PCM_LEFT rsi_sensl
#define PCM_RIGHT rsi_sensr
#define PCM_LEN rsi_sensl_size
#endif
// --------------
// END EDIT MUSIC
// --------------

/* Une part */ 
typedef struct
{
    fp_part_init init;
    fp_part_deinit deinit;
    fp_part_exec exec;
    u32 duration_ms;
} T_PartDef;
typedef struct {
    T_PartDef def;
	u32 start_ms;
} T_Part;

// --------------
// ADD PARTS HERE
// --------------
#define REF(x) \
    extern void x ## _init(void); \
    extern void x ## _deinit(void); \
    extern void x ## _exec(void)
REF(fx_damier);
REF(fx_chiotte);
REF(fx_cube);
REF(fx_twister);
REF(fx_fire);
REF(fx_flush);
REF(fx_evillogo);
REF(cemetery);

#define PART(x, duration_ms) { x ## _init, x ## _deinit, x ## _exec, duration_ms }
static const T_PartDef s_parts[] =
{
    PART(fx_chiotte, 5600),
    PART(fx_cube, 20000),
    PART(fx_twister, 20000),
    PART(fx_damier, 105000),
    PART(fx_evillogo, 150000),


    //PART(cemetery, 20000),
    //PART(fx_fire, 6000),
    //PART(fx_flush, 3000),
};
// -------------
// END ADD PARTS
// -------------
#define g_nb_parts (sizeof(s_parts) / sizeof(*s_parts))

static T_Part g_current_part; // data for current part being played, in IWRAM
static u32 g_current_part_index; // data is in IWRAM, keep this u32 (no clamping on store, same speed as u8)


// Not sure this is useful for anyone
#if 0
u32 g_timer_counter = 0;
void _inc_vbl() 
{
	g_timer_counter++;
}
#endif


/* Initialisation ************************************************************* 
 * --------------
 * Paramètres :
 * - parts : les parts qui devront être jouées
 * - nb_parts : le nombre de parts
 ******************************************************************************/
void demo_init(void)
{
	//g_timer_counter = 0;

	irqInit();

#ifdef MUSIC_NMOD
	irqSet(IRQ_TIMER1, NMOD_Timer1iRQ);
    //irqSet(IRQ_VBLANK, _inc_vbl);

	NMOD_SetMasterVol(64, 0);
	NMOD_SetMasterVol(64, 1);
	NMOD_SetMasterVol(64, 2);
	NMOD_SetMasterVol(64, 3);
#endif
}

/* Avance à la part suivante **************************************************
 * -------------------------
 ******************************************************************************/
void demo_advance_part(void)
{
	if(g_current_part_index < g_nb_parts) {
		if(g_current_part_index >= 0) {
			/* Deinit la part courante */		
			if(g_current_part.def.deinit != NULL) {
				g_current_part.def.deinit();
			}
		}
	
		g_current_part_index++; // Avance
		
		if(g_current_part_index < g_nb_parts) {		
            // move current part to IWRAM
            g_current_part.def = s_parts[g_current_part_index];

			/* Init la prochaine part */
			if(g_current_part.def.init != NULL) {
				g_current_part.def.init();
			}
			
			/* Initialise le temps de début de la part */
			g_current_part.start_ms = ZIC_MS;
		}
	}
}

/* Exécute la demo ************************************************************
 * ---------------
 ******************************************************************************/
IWRAM_CODE void demo_play(void)
{
    // move current part to IWRAM
    g_current_part.def = s_parts[g_current_part_index = 0];
	g_current_part.def.init();

#ifdef MUSIC_NMOD
	NMOD_Play((u32)MOD);
#elif defined(MUSIC_PCM)
    PcmPlay_Start(PCM_LEFT, PCM_RIGHT, PCM_LEN, PCMPLAY_FREQ_8192, PCMPLAY_RESAMPLE_8B_64KHZ);
#endif
	g_current_part.start_ms = ZIC_MS;

    irqEnable(IRQ_VBLANK | IRQ_TIMER1);

	for (;;) {
        Sync_Update();
        g_current_part.def.exec();
    
        if((ZIC_MS >= g_current_part.start_ms + g_current_part.def.duration_ms)) {
            g_current_part.def.deinit();
            g_current_part_index++;
            if(g_current_part_index == g_nb_parts) {
                break;
            }
            // move current part to IWRAM
            g_current_part.def = s_parts[g_current_part_index];
            g_current_part.def.init();
            g_current_part.start_ms = ZIC_MS;
        }
    }
}

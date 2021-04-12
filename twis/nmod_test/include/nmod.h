/*************************************************************
             NMOD v1 beta by NEiM0D/QTX!
     The smallest, baddest, fastest module player for GBA.
**************************************************************/
#ifndef NMOD_PLAYER
#define NMOD_PLAYER
/********************** DEFINES ******************/
#define MAX_CHANNELS	4
#define BUFFERS		2
#define BUFFER_SIZE	1344
/*************************************************/

/******************** VARIABLES ******************/
extern u32 NMOD_scanlines;
extern u8 NMOD_volume[MAX_CHANNELS];
extern u8 NMOD_instrument[MAX_CHANNELS];
extern u32 NMOD_period[MAX_CHANNELS];
extern u8 NMOD_pattern;
extern s8 NMOD_row;
extern u32 NMOD_modaddress;
extern u32 NMOD_effect[MAX_CHANNELS];
extern u8 NMOD_tick;
extern u8 NMOD_speed;
extern s8 NMOD_buffera[BUFFERS][BUFFER_SIZE];
extern s8 NMOD_bufferb[BUFFERS][BUFFER_SIZE];
/*************************************************/

/****************** FUNCTIONS ********************/
extern void NMOD_Play(u32 pt_modaddress);
 /*
 NMOD_Play(): Play the protracker module song.
     u32 pt_modaddress: Holds the address where
                        the module is stored.
 */

extern void NMOD_SetMasterVol(u8 mastervol,u8 soundchan);
 /*
 NMOD_SetMasterVol(): Sets the mastervolume for soundchan.
     mastervol: volume to be set (0-64)
     soundchan: sound channels to set volume (0-3)
 */

extern void NMOD_Stop(void);
 /*
 NMOD_Stop(): Stop playing.
 */

extern void NMOD_Timer1iRQ(void);
 /*
 Has no use for the user, just to let the compiler know to add
 this function to the project.
 */
/*************************************************/
#endif

#ifndef EFFECTS_MANAGER_H
#define EFFECTS_MANAGER_H

#define SEC2VBL(t) ((t) * ((1024 * 60) / 1024))
#define MS2VBL(t) ((t) * 60)
#define VBL2SEC(v) (v / 60)
#define VBL2MS(v) (v * 1024000) / (60 * 1024))

/******************************************************************************
 ******************************************************************************
                              PARTS
  Ensemble d'effets exécutés ensemble pendant une certaine durée.
  Peuvent être accompagnées de synchros déclenchées par les commandes de la
  musique.
 ******************************************************************************
 ******************************************************************************/
/* Type pour la fonction d'initialisation d'une part (appelée une fois à l'initialisation 
   de la part) */
typedef void (*fp_part_init) (void);

/* Type pour la fonction d'exécution d'une part */
// Synchros must be made with NMOD_pattern and NMOD_row 
typedef void (*fp_part_exec) (void);

/* Type pour la déinitialisation d'une part */
typedef void (*fp_part_deinit) (void);
 
/******************************************************************************
 ******************************************************************************
                              MOTEUR
 ******************************************************************************
 ******************************************************************************/
                             
/* Initialisation ************************************************************* 
 * --------------
 * Paramètres :
 * - parts : les parts qui devront être jouées
 * - nb_parts : le nombre de parts
 ******************************************************************************/
extern void demo_init(void);

/* Avance à la part suivante **************************************************
 * -------------------------
 ******************************************************************************/
extern void demo_advance_part(void);

/* Exécute la demo ************************************************************
 * ---------------
 ******************************************************************************/
extern void demo_play(void);

#endif // EFFECT_MANAGER_H


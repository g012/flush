Hello :)

Layers d�cor : 
--------------

Voici les layers pour le SOTB, en 512x160, 16 couleurs, comme demand�s.
J'imagine que �a va etre til�, donc d�coup� en blocs pointant chacun vers une palette de 16 couleurs, donc je me suis arrang� pour avoir une seule palette par layer, voire moins :

- Les 2 layers "mountain_back" partagent la m�me palette
- cloud_bottom, cloud_middle et cloud_top partagent �galement la m�me palette
- chaque palette de 16c est tri�e par luminosit�, du plus fonc� au plus clair (sauf la couleur z�ro). Ca ne sert � rien mais si chaque palette de 16c est un d�grad� de gris du noir au blanc, �a devrait rendre bizarre mais pas illisible.

organisation des palettes : 
palette 0 : background.png
palette 1 : mountain_back.png, mountain_front.png
palette 2 : cloud_bottom.png, cloud_middle.png, cloud_top.png
palette 3 : tree.png
palette 4 : fence.png
palette 5 : running_wurst.png

Running Wurst :
---------------

Cycle de course de la saucisse en 12 frames. Chaque frame fait une taille fixe de 32x48 pixels, la s�quence est sur 2 lignes.
la saucisse est un peu rigide, de lui donnerai de la souplesse demain :)

Voila, pour l'instant c'est tout.
Un niveau dessus se trouve un mockup de tout ces �l�ments assembl�s : screen_mockup.png

Bon courage :)
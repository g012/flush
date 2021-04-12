Hello :)

Layers décor : 
--------------

Voici les layers pour le SOTB, en 512x160, 16 couleurs, comme demandés.
J'imagine que ça va etre tilé, donc découpé en blocs pointant chacun vers une palette de 16 couleurs, donc je me suis arrangé pour avoir une seule palette par layer, voire moins :

- Les 2 layers "mountain_back" partagent la même palette
- cloud_bottom, cloud_middle et cloud_top partagent également la même palette
- chaque palette de 16c est triée par luminosité, du plus foncé au plus clair (sauf la couleur zéro). Ca ne sert à rien mais si chaque palette de 16c est un dégradé de gris du noir au blanc, ça devrait rendre bizarre mais pas illisible.

organisation des palettes : 
palette 0 : background.png
palette 1 : mountain_back.png, mountain_front.png
palette 2 : cloud_bottom.png, cloud_middle.png, cloud_top.png
palette 3 : tree.png
palette 4 : fence.png
palette 5 : running_wurst.png

Running Wurst :
---------------

Cycle de course de la saucisse en 12 frames. Chaque frame fait une taille fixe de 32x48 pixels, la séquence est sur 2 lignes.
la saucisse est un peu rigide, de lui donnerai de la souplesse demain :)

Voila, pour l'instant c'est tout.
Un niveau dessus se trouve un mockup de tout ces éléments assemblés : screen_mockup.png

Bon courage :)
# UI-Visibility-WoW-Forever
Controls when parts of the interface are visible in WoW Forever. It joins
four addons into one, each as a module that can be turned on or off:

  - Personal Resource Display: fully visible in combat, half visible while
    health or resources regenerate, hidden when everything is full. The
    bar text can show only in combat.
  - Experience bar: hidden, shown on mouse hover and for a few seconds
    after gaining experience.
  - Class bars: Stance, Pet, Possess and Totem bars can be Shown, Hidden
    or shown On hover. Hidden bars ignore the mouse, but keybinds still work.
  - Minimap elements: zone text, clock, calendar, tracking, mail, addon
    button, compass border, day/night icon and other addons' minimap
    buttons can be Shown, Hidden or shown On hover.

Everything is shown in Edit Mode, so you can move it.


INSTALLATION
------------
1. Put the UIVisibility folder inside:
     World of Warcraft\_forever_\Interface\AddOns\
   (the game folder name may vary; it must be the WoW: Forever installation)
2. The result must look like this:
     ...\Interface\AddOns\UIVisibility\UIVisibility.toc
     ...\Interface\AddOns\UIVisibility\Core.lua
     (and the other .lua files)
3. If you used the separate addons (PRDVisibility, XPBarVisibility,
   ClassBarsVisibility, MinimapElementsVisibility), disable or delete them.
   UI Visibility warns you in chat if one of them is still enabled.
4. For the Personal Resource Display: in Edit Mode set its Visibility to
   "Always" and its Opacity to 100%. Turn on "Show Bar Text" if you want
   the bar text in combat.


OPTIONS AND COMMANDS
--------------------
Options are in the game menu: Options > AddOns > UI Visibility, with one
page per module. There is also a window with one tab per module.

  /uiv              opens the options window
  /uiv prd          opens the Personal Resource Display tab
  /uiv xp           opens the experience bar tab
  /uiv bars         opens the class bars tab
  /uiv minimap      opens the minimap tab
  /uiv options      opens the pages in the game's Options menu
  /uiv help         opens the help window
  /uiv status       shows the state of every module
  /uiv debug        Personal Resource Display timing details
  /uiv list         lists the addon minimap buttons found
  /uiv add Name     adds an addon minimap button that wasn't found
  /uiv remove Name  removes a button you added

The old commands still work: /prdv, /xpbv, /cbv and /mev open their tab.
For example /mev list or /prdv status.


ADDON MINIMAP BUTTONS
---------------------
They are found automatically when they use the common LibDBIcon library or
have "MinimapButton" in their name. If one is missing from /uiv list:
  1. Type /fstack and hover the button.
  2. Look for its name at the top of the list (for example MyAddonButton).
  3. Type /uiv add MyAddonButton (names are case-sensitive).


IF THE ADDON STOPS LOADING
--------------------------
After a WoW: Forever update, the addon may stop loading. To fix it:

1. At character select, open the AddOns list and find UI Visibility.

2. If it says "Out of date":
   Check "Load out of date AddOns" at the top of the list. That's all.

3. If it says "Incompatible":
   a) Enter the game with any character and type this in chat:
        /dump select(4, GetBuildInfo())
      It prints a number, for example 16001.
   b) Open UIVisibility.toc with Notepad.
   c) Replace the number in the first line with the one from step a):
        ## Interface: 16001
   d) Save the file and restart the game.

Important: never put an invented number like 00000 in that line. The game
marks it as Incompatible and the addon will not load at all.




# UI Visibility (español)

Controla cuándo se ven las partes de la interfaz en WoW: Forever. Une
cuatro addons en uno, cada uno como un módulo que se puede activar o
desactivar:

  - Personal Resource Display: totalmente visible en combate, a medias
    mientras se regenera la vida o el recurso, oculto cuando todo está
    lleno. El texto de las barras puede verse solo en combate.
  - Barra de experiencia: oculta, visible al pasar el mouse y unos
    segundos después de ganar experiencia.
  - Barras de clase: las barras de posturas, mascota, posesión y tótems
    pueden estar Visibles, Ocultas o aparecer Con el mouse. Las barras
    ocultas no responden al mouse, pero sus atajos de teclado funcionan.
  - Elementos del minimapa: texto de zona, reloj, calendario, rastreo,
    correo, botón de addons, borde de brújula, ícono de día/noche y los
    botones de otros addons pueden estar Visibles, Ocultos o aparecer
    Con el mouse.

En el Modo Edición todo se muestra, para que puedas moverlo.

Para ver el addon en español, usa el botón "Language" en las opciones y
escribe /reload.


INSTALACIÓN
-----------
1. Pon la carpeta UIVisibility dentro de:
     World of Warcraft\_forever_\Interface\AddOns\
   (el nombre de la carpeta del juego puede variar; tiene que ser la
   instalación de WoW: Forever)
2. Tiene que quedar así:
     ...\Interface\AddOns\UIVisibility\UIVisibility.toc
     ...\Interface\AddOns\UIVisibility\Core.lua
     (y los demás archivos .lua)
3. Si usabas los addons separados (PRDVisibility, XPBarVisibility,
   ClassBarsVisibility, MinimapElementsVisibility), desactívalos o
   bórralos. UI Visibility te avisa en el chat si alguno sigue activado.
4. Para el Personal Resource Display: en el Modo Edición deja su
   Visibilidad en "Always" y su Opacidad en 100%. Activa "Show Bar Text"
   si quieres ver el texto de las barras en combate.


OPCIONES Y COMANDOS
-------------------
Las opciones están en el menú del juego: Opciones > AddOns > UI Visibility,
con una página por módulo. También hay una ventana con una pestaña por
módulo.

  /uiv               abre la ventana de opciones
  /uiv prd           abre la pestaña del Personal Resource Display
  /uiv xp            abre la pestaña de la barra de experiencia
  /uiv bars          abre la pestaña de las barras de clase
  /uiv minimap       abre la pestaña del minimapa
  /uiv opciones      abre las páginas en el menú de Opciones del juego
  /uiv ayuda         abre la ventana de ayuda
  /uiv estado        muestra el estado de cada módulo
  /uiv debug         detalles de tiempos del Personal Resource Display
  /uiv lista         muestra los botones de addons encontrados
  /uiv add Nombre    agrega un botón de addon que no se encontró
  /uiv remove Nombre quita un botón que agregaste

Los comandos antiguos siguen funcionando: /prdv, /xpbv, /cbv y /mev abren
su pestaña. Por ejemplo /mev lista o /prdv estado.


BOTONES DE ADDONS
-----------------
Se encuentran solos cuando usan la librería común LibDBIcon o tienen
"MinimapButton" en su nombre. Si falta alguno en /uiv lista:
  1. Escribe /fstack y pon el mouse sobre el botón.
  2. Busca su nombre arriba en la lista (por ejemplo MiAddonButton).
  3. Escribe /uiv add MiAddonButton (distingue mayúsculas y minúsculas).


SI EL ADDON DEJA DE CARGAR
--------------------------
Después de una actualización de WoW: Forever, el addon podría dejar de
cargar. Para arreglarlo:

1. En la selección de personaje, abre la lista de AddOns y busca
   UI Visibility.

2. Si dice "Out of date" (desactualizado):
   Marca "Load out of date AddOns" arriba de la lista. Con eso basta.

3. Si dice "Incompatible":
   a) Entra al juego con cualquier personaje y escribe en el chat:
        /dump select(4, GetBuildInfo())
      Te mostrará un número, por ejemplo 16001.
   b) Abre UIVisibility.toc con el Bloc de notas.
   c) Reemplaza el número de la primera línea por el del paso a):
        ## Interface: 16001
   d) Guarda el archivo y reinicia el juego.

Importante: nunca pongas un número inventado como 00000 en esa línea. El
juego lo marca como Incompatible y el addon no cargará.


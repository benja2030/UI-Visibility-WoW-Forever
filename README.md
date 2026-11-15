# UI Visibility
 
*(Instrucciones en español más abajo.)*
 
Controls when parts of the interface are visible in **WoW: Forever**, and helps you read the names of the characters you point at. Every part is a module that can be turned on or off.
 
## What it does
 
The options are grouped in tabs by where each part is on screen.
 
### Bars
 
- **Action bars**: Action Bars 1 to 8.
- **Class bars**: Stance, Pet, Possess and Totem bars.
- **Experience bar**: By default, hidden, shown on mouse hover and for a few seconds after gaining experience.
### Frames
 
- **Unit frames**: Player, pet, target, target of target, focus, party, raid manager and cast bar.
- **Personal Resource Display**: By default, fully visible in combat, half visible while health or resources regenerate, and hidden when everything is full. Every opacity can be changed, and the bar text can show only in combat.
### Interface
 
Chat (with its tabs and buttons), social button, quest tracker, Questie tracker, buffs, debuffs, bags and main menu.
 
### Minimap
 
Zone text, clock, calendar, tracking, mail, addon button, compass border, day/night icon and other addons' minimap buttons.
 
### Names
 
- **Name at the cursor**: While you hover a player or NPC, their name shows in big letters next to the cursor, in the game's name colors, at any distance. It can also show their level (colored by difficulty) and a quest mark when they're part of one of your active quests.
- You choose who it's for (allied players, enemy players, friendly NPCs, hostile NPCs) and when to hide it (in combat, in an instance, on dead characters, on characters close enough to have a nameplate, or over the interface).
- **Tooltip**: The tooltip can show next to the cursor instead of in the corner, bigger, and after a short delay.
### Shown, Hidden or On hover
 
In the Action bars, Class bars, Unit frames, Interface and Minimap modules, every element can be:
 
- **Shown**: the game's normal behavior. The addon doesn't touch the element.
- **Hidden**: invisible, and it ignores the mouse. Keybinds of hidden action bars still work.
- **On hover**: invisible until the mouse passes over it.
## Before you start: parts that are off in the game
 
UI Visibility only controls parts of the interface that the game is showing. Some of them are **off by default in the WoW client** and have to be turned on there first:
 
- **Personal Resource Display**: Turn it on in **Edit Mode** (check "Personal Resource Display"). Then select it and set its **Visibility** to **Always** and its **Opacity** to **100%**, so UI Visibility decides when it shows. Turn on **Show Bar Text** if you want the health and resource numbers in combat.
- **Action Bars 2 to 8**: Turn them on in **Edit Mode** or in **Options > Action Bars**.
- **Class bars**: The Stance, Pet, Possess and Totem bars can be turned off in **Edit Mode**. They also only appear for classes and situations that use them (for example the Pet Bar with a pet out).
- **Focus frame, party frames and raid manager**: They only appear when you have a focus or are in a group.
- **Questie tracker**: Needs the Questie addon.
- **Names, "Has a nameplate"**: Only matters if you have nameplates turned on (Shift+V for friendly nameplates, V for enemy nameplates).
## Other details
 
- Every element starts as **Shown**, so nothing changes until you choose what to hide.
- Everything is shown in **Edit Mode**, so you can move it.
- The chat is always shown while you type a message.
- **Fade smoothness** (0 to 10) sets how fast elements appear and disappear. 0 is instant.
- Action bars and unit frames can't be fully changed during combat: if you change their mode in a fight, they become invisible right away, but they keep reacting to the mouse until combat ends.
- The game doesn't let addons know where a character's head is on screen, so the bigger name follows the cursor instead of replacing the name above the head.
- Available in English and Spanish.
## Installation
 
1. Put the `UIVisibility` folder inside `World of Warcraft\_forever_\Interface\AddOns\`.
2. It must look like `...\Interface\AddOns\UIVisibility\UIVisibility.toc`, with no extra folder in between.
3. If you used the separate addons (PRDVisibility, XPBarVisibility, ClassBarsVisibility, MinimapElementsVisibility), disable or delete them. UI Visibility warns you in chat if one of them is still enabled.
4. Turn on the parts you want in the game, as explained in **Before you start**.
## Options and commands
 
Options are in **Options > AddOns > UI Visibility**, and in a window with the same tabs that opens with `/uiv` or by clicking UI Visibility in the minimap's addon button. The tabs are **General, Bars, Frames, Interface, Minimap and Names**. The General tab lists every module with an **Open** button that goes to its tab. Hover any option to see what it does.
 
- `/uiv`: Opens the options window
- `/uiv prd`, `xp`, `bars`, `actionbars`, `unitframes`, `interface`, `minimap`, `names`: Opens the tab with that module
- `/uiv options`: Opens the pages in the game's Options menu
- `/uiv help`: Opens the help window
- `/uiv status`: Shows the state of every module
- `/uiv debug`: Personal Resource Display timing details
- `/uiv list`: Lists the addon minimap buttons found
- `/uiv add Name`: Adds an addon minimap button that wasn't found
- `/uiv remove Name`: Removes a button you added
The old commands still work: `/prdv`, `/xpbv`, `/cbv` and `/mev` open their tab.
 
### Addon minimap buttons
 
They are found automatically when they use the common LibDBIcon library or have "MinimapButton" in their name. If one is missing from `/uiv list`:
 
1. Type `/fstack` and hover the button.
2. Look for its name at the top of the list (for example `MyAddonButton`).
3. Type `/uiv add MyAddonButton` (names are case-sensitive).
## If the addon stops loading
 
After a WoW: Forever update, the addon may stop loading.
 
1. At character select, open the AddOns list and find UI Visibility.
2. If it says **Out of date**, check **Load out of date AddOns** at the top of the list. That's all.
3. If it says **Incompatible**:
   1. Enter the game and type `/dump select(4, GetBuildInfo())` in chat. It prints a number, for example 16001.
   2. Open `UIVisibility.toc` with Notepad.
   3. Replace the number in the first line: `## Interface: 16001`
   4. Save the file and restart the game.
Never put an invented number like 00000 in that line: the game marks it as Incompatible and the addon will not load at all.
 
---
 
# UI Visibility (español)
 
Controla cuándo se ven las partes de la interfaz en **WoW: Forever**, y te ayuda a leer el nombre de los personajes que apuntas. Cada parte es un módulo que se puede activar o desactivar.
 
## Qué hace
 
Las opciones están agrupadas en pestañas según dónde está cada parte en la pantalla.
 
### Barras
 
- **Barras de acción**: Barras de acción 1 a 8.
- **Barras de clase**: Barras de posturas, mascota, posesión y tótems.
- **Barra de experiencia**: Por defecto, oculta, visible al pasar el mouse y unos segundos después de ganar experiencia.
### Marcos
 
- **Marcos de unidad**: Jugador, mascota, objetivo, objetivo del objetivo, foco, grupo, administrador de banda y barra de lanzamiento.
- **Personal Resource Display**: Por defecto, totalmente visible en combate, a medias mientras se regenera la vida o el recurso, y oculto cuando todo está lleno. Cada opacidad se puede cambiar, y el texto de las barras puede verse solo en combate.
### Interfaz
 
Chat (con sus pestañas y botones), botón social, misiones, rastreador de Questie, beneficios, perjuicios, bolsas y menú principal.
 
### Minimapa
 
Texto de zona, reloj, calendario, rastreo, correo, botón de addons, borde de brújula, ícono de día/noche y los botones de otros addons.
 
### Nombres
 
- **Nombre junto al cursor**: Mientras apuntas a un jugador o PNJ, su nombre aparece en grande junto al cursor, con los colores de nombre del juego, a cualquier distancia. También puede mostrar su nivel (coloreado por dificultad) y una marca de misión cuando es parte de una de tus misiones activas.
- Eliges para quién (jugadores aliados, jugadores enemigos, PNJ amistosos, PNJ hostiles) y cuándo ocultarlo (en combate, en instancias, en personajes muertos, en personajes con placa de nombre visible, o sobre la interfaz).
- **Tooltip**: El tooltip puede aparecer junto al cursor en vez de en la esquina, más grande y con un pequeño retraso.
### Visible, Oculto o Con el mouse
 
En los módulos de barras de acción, barras de clase, marcos de unidad, interfaz y minimapa, cada elemento puede estar:
 
- **Visible**: el comportamiento normal del juego. El addon no toca el elemento.
- **Oculto**: invisible, y no responde al mouse. Los atajos de teclado de las barras de acción ocultas siguen funcionando.
- **Con el mouse**: invisible hasta que el mouse pasa por encima.
## Antes de empezar: partes que están apagadas en el juego
 
UI Visibility solo controla partes de la interfaz que el juego está mostrando. Algunas vienen **desactivadas por defecto en el cliente de WoW** y hay que activarlas ahí primero:
 
- **Personal Resource Display**: Actívalo en el **Modo Edición** (marca "Personal Resource Display"). Luego selecciónalo y deja su **Visibilidad** en **Always** y su **Opacidad** en **100%**, para que UI Visibility decida cuándo se muestra. Activa **Show Bar Text** si quieres ver los números de vida y recurso en combate.
- **Barras de acción 2 a 8**: Actívalas en el **Modo Edición** o en **Opciones > Barras de acción**.
- **Barras de clase**: Las barras de posturas, mascota, posesión y tótems se pueden desactivar en el **Modo Edición**. Además, solo aparecen para las clases y situaciones que las usan (por ejemplo la barra de mascota con una mascota invocada).
- **Foco, grupo y administrador de banda**: Solo aparecen cuando tienes un foco o estás en grupo.
- **Rastreador de Questie**: Necesita el addon Questie.
- **Nombres, "Tiene placa"**: Solo importa si tienes las placas de nombre activadas (Shift+V para las aliadas, V para las enemigas).
## Otros detalles
 
- Cada elemento empieza como **Visible**, así que nada cambia hasta que elijas qué ocultar.
- En el **Modo Edición** todo se muestra, para que puedas moverlo.
- El chat siempre se muestra mientras escribes un mensaje.
- **Suavidad del fundido** (0 a 10) define qué tan rápido aparecen y desaparecen los elementos. 0 es instantáneo.
- Las barras de acción y los marcos de unidad no se pueden cambiar por completo en combate: si cambias su modo en una pelea, se vuelven invisibles de inmediato, pero siguen respondiendo al mouse hasta que termina el combate.
- El juego no deja a los addons saber dónde está la cabeza de un personaje en la pantalla, así que el nombre grande sigue al cursor en vez de reemplazar el nombre sobre la cabeza.
- Disponible en inglés y español. Para ver el addon en español, elige "Español" en el menú de idioma de la pestaña General.
## Instalación
 
1. Pon la carpeta `UIVisibility` dentro de `World of Warcraft\_forever_\Interface\AddOns\`.
2. Tiene que quedar `...\Interface\AddOns\UIVisibility\UIVisibility.toc`, sin una carpeta de más en medio.
3. Si usabas los addons separados (PRDVisibility, XPBarVisibility, ClassBarsVisibility, MinimapElementsVisibility), desactívalos o bórralos. UI Visibility te avisa en el chat si alguno sigue activado.
4. Activa en el juego las partes que quieras, como se explica en **Antes de empezar**.
## Opciones y comandos
 
Las opciones están en **Opciones > AddOns > UI Visibility**, y en una ventana con las mismas pestañas que se abre con `/uiv` o haciendo clic en UI Visibility dentro del botón de addons del minimapa. Las pestañas son **General, Barras, Marcos, Interfaz, Minimapa y Nombres**. La pestaña General muestra cada módulo con un botón **Abrir** que lleva a su pestaña. Pasa el mouse sobre cualquier opción para ver qué hace.
 
- `/uiv`: Abre la ventana de opciones
- `/uiv prd`, `xp`, `bars`, `actionbars`, `unitframes`, `interface`, `minimap`, `names`: Abre la pestaña con ese módulo
- `/uiv opciones`: Abre las páginas en el menú de Opciones del juego
- `/uiv ayuda`: Abre la ventana de ayuda
- `/uiv estado`: Muestra el estado de cada módulo
- `/uiv debug`: Detalles de tiempos del Personal Resource Display
- `/uiv lista`: Muestra los botones de addons encontrados
- `/uiv add Nombre`: Agrega un botón de addon que no se encontró
- `/uiv remove Nombre`: Quita un botón que agregaste
Los comandos antiguos siguen funcionando: `/prdv`, `/xpbv`, `/cbv` y `/mev` abren su pestaña.
 
### Botones de addons
 
Se encuentran solos cuando usan la librería común LibDBIcon o tienen "MinimapButton" en su nombre. Si falta alguno en `/uiv lista`:
 
1. Escribe `/fstack` y pon el mouse sobre el botón.
2. Busca su nombre arriba en la lista (por ejemplo `MiAddonButton`).
3. Escribe `/uiv add MiAddonButton` (distingue mayúsculas y minúsculas).
## Si el addon deja de cargar
 
Después de una actualización de WoW: Forever, el addon podría dejar de cargar.
 
1. En la selección de personaje, abre la lista de AddOns y busca UI Visibility.
2. Si dice **Out of date**, marca **Load out of date AddOns** arriba de la lista. Con eso basta.
3. Si dice **Incompatible**:
   1. Entra al juego y escribe `/dump select(4, GetBuildInfo())` en el chat. Te mostrará un número, por ejemplo 16001.
   2. Abre `UIVisibility.toc` con el Bloc de notas.
   3. Reemplaza el número de la primera línea: `## Interface: 16001`
   4. Guarda el archivo y reinicia el juego.
Nunca pongas un número inventado como 00000 en esa línea: el juego lo marca como Incompatible y el addon no cargará.
 
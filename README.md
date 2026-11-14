# UI Visibility
 
*(Instrucciones en español más abajo.)*
 
Controls when parts of the interface are visible in **WoW: Forever**. Every part is a module that can be turned on or off.
 
- **Personal Resource Display**: Fully visible in combat, half visible while health or resources regenerate, hidden when everything is full. The bar text can show only in combat.
- **Experience bar**: Hidden, shown on mouse hover and for a few seconds after gaining experience.
- **Class bars**: Stance, Pet, Possess and Totem bars.
- **Action bars**: Action Bars 1 to 8.
- **Unit frames**: Player, pet, target, target of target, focus, party, raid manager and cast bar.
- **Interface**: Chat (with its tabs and buttons), social button, quest tracker, Questie tracker, buffs, debuffs, bags and main menu.
- **Minimap**: Zone text, clock, calendar, tracking, mail, addon button, compass border, day/night icon and other addons' minimap buttons.
In the last five modules every element can be **Shown**, **Hidden** or shown **On hover**:
 
- **Shown** is the game's normal behavior. The addon doesn't touch the element.
- **Hidden** makes it invisible, and it ignores the mouse. Keybinds of hidden action bars still work.
- **On hover** keeps it invisible until the mouse passes over it.
Other details:
 
- Everything is shown in Edit Mode, so you can move it.
- The chat is always shown while you type a message.
- **Fade smoothness** (0 to 10) sets how fast elements appear and disappear. 0 is instant.
- Action bars and unit frames are protected by the game: if you change a mode in combat, the mouse part of the change is applied when combat ends.
## Installation
 
1. Put the `UIVisibility` folder inside `World of Warcraft\_forever_\Interface\AddOns\`.
2. It must look like `...\Interface\AddOns\UIVisibility\UIVisibility.toc`, with no extra folder in between.
3. If you used the separate addons (PRDVisibility, XPBarVisibility, ClassBarsVisibility, MinimapElementsVisibility), disable or delete them. UI Visibility warns you in chat if one of them is still enabled.
4. For the Personal Resource Display: in Edit Mode set its Visibility to "Always" and its Opacity to 100%. Turn on "Show Bar Text" if you want the bar text in combat.
## Options and commands
 
Options are in **Options > AddOns > UI Visibility**. The main page lists every module with an **Open** button that goes to its page. There is also a window with the same tabs, which opens with `/uiv` or by clicking UI Visibility in the minimap's addon button.
 
- `/uiv`: Opens the options window
- `/uiv prd`, `xp`, `bars`, `actionbars`, `unitframes`, `interface`, `minimap`: Opens that module's tab
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
 
Controla cuándo se ven las partes de la interfaz en **WoW: Forever**. Cada parte es un módulo que se puede activar o desactivar.
 
- **Personal Resource Display**: Totalmente visible en combate, a medias mientras se regenera la vida o el recurso, oculto cuando todo está lleno. El texto de las barras puede verse solo en combate.
- **Barra de experiencia**: Oculta, visible al pasar el mouse y unos segundos después de ganar experiencia.
- **Barras de clase**: Barras de posturas, mascota, posesión y tótems.
- **Barras de acción**: Barras de acción 1 a 8.
- **Marcos de unidad**: Jugador, mascota, objetivo, objetivo del objetivo, foco, grupo, administrador de banda y barra de lanzamiento.
- **Interfaz**: Chat (con sus pestañas y botones), botón social, misiones, rastreador de Questie, beneficios, perjuicios, bolsas y menú principal.
- **Minimapa**: Texto de zona, reloj, calendario, rastreo, correo, botón de addons, borde de brújula, ícono de día/noche y los botones de otros addons.
En los últimos cinco módulos cada elemento puede estar **Visible**, **Oculto** o aparecer **Con el mouse**:
 
- **Visible** es el comportamiento normal del juego. El addon no toca el elemento.
- **Oculto** lo vuelve invisible, y no responde al mouse. Los atajos de teclado de las barras de acción ocultas siguen funcionando.
- **Con el mouse** lo mantiene invisible hasta que el mouse pasa por encima.
Otros detalles:
 
- En el Modo Edición todo se muestra, para que puedas moverlo.
- El chat siempre se muestra mientras escribes un mensaje.
- **Suavidad del fundido** (0 a 10) define qué tan rápido aparecen y desaparecen los elementos. 0 es instantáneo.
- Las barras de acción y los marcos de unidad están protegidos por el juego: si cambias un modo en combate, la parte del mouse se aplica al salir de combate.
- Para ver el addon en español, elige "Español" en el menú de idioma de la pestaña General.
## Instalación
 
1. Pon la carpeta `UIVisibility` dentro de `World of Warcraft\_forever_\Interface\AddOns\`.
2. Tiene que quedar `...\Interface\AddOns\UIVisibility\UIVisibility.toc`, sin una carpeta de más en medio.
3. Si usabas los addons separados (PRDVisibility, XPBarVisibility, ClassBarsVisibility, MinimapElementsVisibility), desactívalos o bórralos. UI Visibility te avisa en el chat si alguno sigue activado.
4. Para el Personal Resource Display: en el Modo Edición deja su Visibilidad en "Always" y su Opacidad en 100%. Activa "Show Bar Text" si quieres ver el texto de las barras en combate.
## Opciones y comandos
 
Las opciones están en **Opciones > AddOns > UI Visibility**. La página principal muestra cada módulo con un botón **Abrir** que lleva a su página. También hay una ventana con las mismas pestañas, que se abre con `/uiv` o haciendo clic en UI Visibility dentro del botón de addons del minimapa.
 
- `/uiv`: Abre la ventana de opciones
- `/uiv prd`, `xp`, `bars`, `actionbars`, `unitframes`, `interface`, `minimap`: Abre la pestaña de ese módulo
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
 
# Bee a Hero — Guion del video (máx. 5 min)

**Duración objetivo:** ~4:00 (deja colchón antes de los 5 min).
**Público:** gente de la jam, 18–25 años. Tono cercano, entusiasta, sin tecnicismos de más.
**Voz:** está escrito en primera persona del singular ("lo hice"). Si lo presentan entre varios, cambien "hice" por "hicimos" y "lo desarrollé" por "lo desarrollamos".
**⚠️ Ajustar antes de grabar:** donde dice `[poné el tiempo real]`, reemplazá por cuánto te tomó de verdad.

---

## Tabla de tiempos

| # | Sección | Tiempo | Qué se muestra |
|---|---|---|---|
| 1 | Gancho | 0:00–0:15 | Oleada alta, mucha acción |
| 2 | Qué es | 0:15–0:45 | Panal, la abeja, la reina |
| 3 | Cómo se juega | 0:45–1:30 | Moverse, disparar, drag & drop, ciclo de oleadas |
| 4 | Qué construir | 1:30–2:15 | Las 10 construcciones, edificios y slots |
| 5 | Enemigos | 2:15–2:45 | Los 6 enemigos en acción |
| 6 | Cómo lo desarrollé | 2:45–3:45 | Código, grilla, doc, git |
| 7 | Cierre | 3:45–4:00 | Pantalla de derrota + link |

---

## Guion

### 1. Gancho (0:00–0:15)

**[PANTALLA]** Grabación de una oleada alta (4 en adelante): enemigos llegando de todos lados, torres disparando, una abeja suicida explotando, miel cayendo. Sin UI al principio para que se vea limpio, o con el HUD si ya está a tope.

**[VOZ]**
"Esto es Bee a Hero, un tower defense donde sos una abeja defendiendo a tu reina. Mirá cómo se pone... en un segundo te explico de qué va."

---

### 2. Qué es (0:00–0:15 → 0:45)

**[PANTALLA]** Vista panorámica del panal entero, la reina en el centro, la abeja protagonista moviéndose. Si hay, mostrar el título o la intro con Beerenice.

**[VOZ]**
"Bee a Hero es un tower defense y builder 2D hecho en Godot, para una game jam con el tema 'Construcción'. Sos la abeja obrera que protege a la reina — Beerenice — en el centro de un panal hexagonal. Cada hexágono es una celda donde podés construir. Y la clave es esa: acá la defensa no es solo poner torres y esperar, es construir una colmena entera."

---

### 3. Cómo se juega (0:45–1:30)

**[PANTALLA]** Control directo: mover la abeja, disparar, luego arrastrar una tarjeta y que se vea el fantasma + círculo de rango + celda verde/roja. Después el ciclo completo: oleada → miel → recolección → construcción.

**[VOZ]**
"Controlás una sola abeja. Te movés con WASD o las flechas y la cámara te sigue. Disparás con ESPACIO hacia el mouse. Para construir, arrastrás una tarjeta del menú hasta una celda: se ve un fantasma de lo que vas a poner, un círculo que muestra hasta dónde llegás, y la celda en verde si podés o en rojo si no. El ciclo es: llega una oleada, los enemigos sueltan miel al morir, la salís a recolectar y con eso construís antes de la próxima. Se termina cuando un enemigo llega al centro y mata a la reina."

---

### 4. Qué construir (1:30–2:15)

**[PANTALLA]** Mostrar el menú de tarjetas (10 construcciones). Construir una pared, una trampa, una torre doble; después un edificio (Base) y ver cómo sube el contador de "Abejas". Tocar una torre y mostrar Mejorar/Vender.

**[VOZ]**
"Tenés diez cosas para construir. Paredes baratas que bloquean, una reforzada que aguanta el triple, y trampas con pinchos que explotan cuando las pisan. Torres para el daño, y una torre doble que dispara a dos enemigos a la vez. Y lo que te hace crecer de verdad: los edificios. La Base, la Guardería y la Cultivadora ocupan siete hexágonos y te dan más slots de abejas. Sin slots no podés poner más torres ni aliados, así que construir es lo que te deja escalar. Y todo se puede mejorar o vender tocándolo."

---

### 5. Enemigos (2:15–2:45)

**[PANTALLA]** Uno por uno, cortes rápidos: la avispa en línea recta, la avispa grande que no retrocede, el avispón rompiendo una pared, la mosca en espiral, la tiradora disparando a la reina, la hormiga robando miel y escapando.

**[VOZ]**
"Y los enemigos no vienen de frente nomás. Está la avispa común, la avispa grande que casi no retrocede, y el avispón que te rompe las paredes. La mosca viene en espiral, la tiradora dispara aguijones a la reina, y la hormiga te roba la miel que dejaste tirada y se escapa. Cada uno te obliga a pensar una defensa distinta."

---

### 6. Cómo lo desarrollé (2:45–3:45)

**[PANTALLA]** Mostrar el editor de Godot: el árbol de escenas, un pedazo de `hex_grid.gd` (la parte de coordenadas axiales), y el doc `estructura.md`. No más de 20 segundos seguidos de código. Si se puede, una toma del `git log` o de commits.

**[VOZ]**
"Lo hice en Godot 4 con GDScript, de cero, en `[poné el tiempo real]`. Trabajé por etapas chicas: primero la grilla hexagonal, después la reina y un enemigo, después la abeja, las paredes, las torres... una cosa por vez. Lo más difícil fue la grilla: usa coordenadas axiales, y me apoyé en la guía de Red Blob Games. Usé inteligencia artificial como asistente, pero con una regla: una sola consulta por vez y un documento que mantenía actualizado como contexto fijo. Ahí apareció el bug más interesante: al arrastrar una tarjeta el juego se tildaba, porque las texturas se regeneraban cada vez en vez de cachearse. Y todo con git, commit a cada avance. Si algo funcionaba, commit. Si no, se podía volver."

---

### 7. Cierre (3:45–4:00)

**[PANTALLA]** Una pantalla de derrota ("Llegaste a la oleada N" / "Mejor oleada"), y después el título + link en pantalla.

**[VOZ]**
"Quedaron afuera algunas cosas: el arte final, el sistema de charlas con la reina y pulir el sonido. Pero lo importante está: es jugable, es intenso y se puede jugar en el navegador. El link está en la descripción. Protegé a la reina."

---

## Lista de tomas a grabar (por orden)

1. Oleada alta con acción (gancho).
2. Panal completo + reina + abeja (qué es).
3. Movimiento, disparo y drag & drop con preview (cómo se juega).
4. Recolección de miel + banner "Oleada N".
5. Construir pared / trampa / torre doble (qué construir).
6. Construir Base y ver subir los slots.
7. Mejorar / vender una torre.
8. Un corte por cada enemigo (6 cortes cortos).
9. Editor de Godot + árbol de escenas + `hex_grid.gd`.
10. `git log` o lista de commits.
11. Pantalla de derrota con récord.
12. Título + link (se puede poner como texto superpuesto en edición).

## Tips de grabación

- Grabá primero el gameplay en tomas cortas y después la voz por separado.
- Audio del juego bajo, la voz por encima.
- Hablá el guion, no lo leas: está escrito para sonar hablado.
- Mostrá código máximo 20 segundos seguidos; después volvé al gameplay.
- Grabá desde el build de PC (no web) para que se vea fluido.
- Revisá que la resolución sea 1080p y que el HUD no quede cortado.

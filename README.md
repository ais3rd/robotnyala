# Robot Nyala

A robot boxing prototype made with [Castle Game Engine](https://castle-engine.io/), drawn with Doom-style 8-direction sprites.
You are the operator at the ropes, behind your robot Glitchpop. Speak (or type) boxing commands; Glitchpop carries
them out against Boxer 07, which stands its ground. Press **Tab** to switch between the operator camera and a 3/4 view.

Voice works through any dictation tool that types into the focused window, such as Wispr Flow:
click the game window, dictate a command, press Enter.

## Commands

| Group | Say | |
|---|---|---|
| Punches | `jab` / `left jab`, `cross` / `right straight`, `left hook`, `right hook`, `left uppercut`, `right uppercut`, `left body` / `body shot`, `right body`, `haymaker` | land within 1.5 m, facing the enemy |
| Defense | `block` / `guard` (held until the next command), `duck`, `dodge left`, `dodge right` | |
| Movement | `forward`, `back`, `left` / `step left`, `right` / `step right`, `turn left`, `turn right` | 0.5 m steps, 15° turns |
| Combos | `one two` (jab, cross), `combo` (jab, cross, left hook) | |
| Control | `stop` | cancels the current move or combo |

One command per Enter. Capitals and punctuation are ignored (`Left hook.` works); other spellings are not.
Commands given while a move is still playing are ignored, except `stop`.

The enemy starts 2 m away, out of reach: say `forward` twice first.

## Code layout

- `code/gamecommands.pas`: the command list and text parsing
- `code/gamerobot.pas`: one move at a time, timings, combos, stop
- `code/gamecombat.pas`: reach, enemy HP and KO, movement limits
- `code/gameenemyanim.pas`: which enemy sprite-sheet frame to show (idle, KO, and a different reaction for each punch)
- `code/gameplayeranim.pas`: which Glitchpop sprite-sheet frame to show (idle, 4 frames per punch, defense)
- `code/gamecamera.pas`: operator / 3/4 cameras and which of the 8 sprite directions to show
- `code/gameimpact.pas`: hit feel: hit-stop freeze, white impact frame, screen shake, hit streak
- `code/gameviewmain.pas`: connects the rules to the screen and builds the ring
- `data/gameviewmain.castle-user-interface`: viewport, both robot sprites and labels (open it in the Castle Engine editor)
- `data/images/`: sprite sheets (rows = 8 view directions, columns = frames), rendered from the models in `art/`
- `art/`: three.js model pages; run `node art/server.js`, open `http://localhost:8765/enemy_boxer07.html?export`
  or `player_glitchpop.html?export` to re-render a sheet into `data/images/`

The rule units use no Castle Game Engine units, so they are tested on their own.

## Building

- **Delphi**: open `robotnyala_standalone.dproj` and press F9.
  (Delphi Community Edition can't compile from the command line, so the editor's "Compile" with the Delphi compiler won't work there; use the IDE.)
- **Castle Engine editor / build tool with Free Pascal**: `castle-engine compile --compiler=fpc` in this folder, or set the compiler to FPC in the editor's preferences.

## Tests

- **Delphi**: open `tests/robotnyala_tests.dpr` and press F9. The console prints PASS/FAIL per test.
- **Free Pascal** (bundled with Castle Engine), from the `tests` folder:

  ```
  "<castle engine>\tools\contrib\fpc\bin\fpc.exe" -Mdelphi -FEbin -FUbin robotnyala_tests.dpr
  bin\robotnyala_tests.exe
  ```

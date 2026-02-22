Place these audio files in this Resources/ directory before building:

  bgm.mp3          — Background music (looping). Copy from project root: cp ../../../../bgm.mp3 .
  sfx_select.wav   — Bubble pop sound (~150ms) — plays when a flower is selected
  sfx_move.wav     — Bubble whoosh (~200ms) — plays when a flower starts moving
  sfx_eliminate.wav — Bubble burst cascade (~400ms) — plays when flowers are eliminated
  sfx_gameover.wav — Descending multi-pop (~600ms) — plays on game over

Free CC0 sources: https://freesound.org (search "bubble pop")

Then add all .wav and .mp3 files to the Xcode project target (Build Phases → Copy Bundle Resources).

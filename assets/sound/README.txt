Fart Generator - sound folders
==============================

Same layout as the original game. Put .wav files into these folders:

  small/      short / light farts
  medium/     medium farts
  big/        big farts
  huge/       huge farts
  sneaky/     quiet, sneaky farts
  special/    the "experiment" mode sounds
  voice1..5/  optional voices (played when the Voice button is not Off)
  original1..5/  optional extra groups; they appear in the SE: cycle as Orig1..Orig5

The SE: button on the panel chooses which group the current fart pattern uses.
An empty group means "no sound" - just like the original, where the folders had
to be filled by the player. If *every* fart folder is empty, the port falls back
to a few synthesised fart noises so it is not silent out of the box. Fill the
folders to replace them.

sfx/ contains the two sound effects taken from the original decompile
(snd_hip_press.wav, snd_vacuum.wav).

After adding files, restart the game (or the soundtrack is loaded once at
startup).

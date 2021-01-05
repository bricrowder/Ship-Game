# Space-Game

Note: for [Love 0.10.2](https://github.com/love2d/love/releases/tag/0.10.2).  It uses 0-255 colour values.

Fly a ship around a planet protecting it from hazards.

apologize up-front that the menu is a terrible unfinished mess!

## What this has
- planet generation, including regions and slices, using law of cosine
- Play area rotates around the planet, with a day / night side, clouds and stars
- chromatic abbrassion shader for visual damage indicator
- keyboard/mouse controls (gamepad too I think)
- a few different enemy types: stationary, orbit, sinwave orbit, and homing.  They all use the same sprite though, sorry for that too! :)
- A few different bullet types including linear and homing
- Land at base, heal and upgrade weapons
- Basic level progression (by killing enemies), a boss and change to next level -> doesn't do much but increment some numbers at this point


## Keyboard & Mouse Controls:
- Movement - wsad keys
- Direction - mouse
- Shoot - left mouse
- Bomb - right mouse
- change weapons - mouse wheel
- land - space
- Pause menu / menu back - esc
- menu movement - wsad keys
- menu Ok - space

![screenshot](./screenshot1.png)
![screenshot](./screenshot2.png)
![screenshot](./screenshot3.png)

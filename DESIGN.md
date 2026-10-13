# DEAD FREQUENCY

A native Windows GameMaker action game. Six two-floor night-shift encounters: motel, club, broadcasting station, warehouse, laundromat and penthouse. Twelve floors and 164 enemies including six enforcers. Original setting, pixel assets, and synthesized 160 BPM soundtrack; no Hotline Miami assets.

## Direction
Deep ink shadows, faded turquoise, nicotine cream and emergency pink. Environment tiles and props have a consistent 1 px contour. Characters use 40 px, eight-frame overhead strips, with separate weapon sprites and faction silhouettes. Low-resolution world with nearest-neighbour scaling. No generated photographic textures.

## Combat
Immediate aim, sub-stepped movement and projectile collision, sound alerts, line-of-sight enemies, brief attack telegraphs, weapon pickups, a directional knife, a short invulnerable dash, finite magazines with unlimited reloads. One lethal hit in standard mode. Optional two-hit assist. Death resets immediately with R. Three distinct weapon rhythms.

Player speed 4.05 px/frame; dash speed 9.2, duration 9 frames, cooldown 36. Weapon delays 9/3.5/25 frames; reload 36/36/58. Shotgun: eight pellets, wider spread, limited range. Muzzle light, recoil, brass, short hitstop, dash ghosts, sliding corpses and persistent blood decals reinforce every action.

Navigation uses an 8 px grid with radius-9 body clearance and swept connections from actor positions. Cardinal edges cannot skip expanded wall rectangles. Sight uses segment/rectangle intersection; hidden targets cancel windups, and both the muzzle and locked aim segment are rechecked at shot time. Collision tolerances handle floating-point tangency at furniture edges.

## Campaign, physics and economy (v4)

Doors rotate about a hinge away from the opener. Collision and sight transform into the same oriented rectangle used for rendering. Rotation is substepped, blocks against the player and pushes guards. Kicked leaves stun each struck enemy once per opening. Occupied thresholds cannot close. Fully opened leaves are excluded from the navigation field; pursuers can open closed doors.

Idle guards follow reachable waypoints and pause with a stable heading. Glass blocks bodies but permits sight. Bullets, dash, melee or pursuing guards can break it to open a shortcut, leaving persistent shards.

Each first floor has a deep staircase guarded by an enforcer with 8-13 HP. Charges have a 30-frame locked-direction telegraph. A missed charge causes recovery. Stuns multiply incoming damage by 1.5; a four-frame damage gate prevents eight shotgun pellets from applying simultaneous damage. Grabs freeze other combat and require alternating A/D six times within 165 frames (assist: four within 200). Escape stuns the enemy and grants protection; failure applies a hit.

Contracts begin with a car-exit animation outside the entrance. Upstairs spawns are exactly on the staircase inside a protected landing. Ascending snapshots weapon, exact ammo, health/max health, score, elapsed time and prior kills. Death retries the current floor. Checkpoints last for the session; progression and purchases persist in the INI.

Payout is $300 + $75 per chapter index + up to $400 from score. Results lead to a walkable workshop: SMG $350, shotgun $550, one-contract armor $200. Weapon ownership is permanent and re-equipping is free. The car starts the next contract with selected equipment and full ammo. Armor adds one health and is consumed on deployment; retries retain the deployed checkpoint. Cash, owned weapons, selected weapon, pending armor and next contract are saved. Tests suppress profile writes.

Recorded CC0 gunshots, reloads, wood impacts, punches, glass and footsteps replace the corresponding synthesized effects. See licenses/Audio-CC0.txt. Music, UI stings, dash and death sounds remain original synthesis.

The Russian story is data-driven in story.json. Three original two-frame portraits accompany chapter introductions, stairwell exchanges and an ending. Text reveals progressively; Enter/Space/click reveals or advances, Escape skips the current conversation. Dialogue suspends combat and the clock, then returns to gameplay or chapter results. There is no voice-over.

## Production
Project is authored in GML for GameMaker LTS 2026. Windows VM target. Python tools generate the original pixel assets, WAV music and resource manifests reproducibly. Game runs independently of Python. No browser runtime or network dependency.

Additional modules: scr_action (patrols, glass, enforcer, grapple), scr_hub (economy, workshop, car), make_v4.py (authored layouts and art). See README.md for rebuilding graphics while preserving recorded audio.

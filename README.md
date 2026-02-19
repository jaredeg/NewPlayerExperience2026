# Between the Lanes — New Player Experience Community Support

**February 2026**

---

## How I Got Here (Thanks, Behavior Score)

I'd like to thank the Behavior Score and Communication systems for giving me the free time to work on this project. Silver lining: it gave me 40+ hours to stare at ERROR models in the tutorial. So let's talk about that.

---

So I decided to load up the New Player Experience — the tutorial scenarios that are supposed to help new players learn the game. You know, the ones you tell your friends to try before their first match. The ones that are supposed to make a good first impression.

They were, uh... not making a great first impression.

What followed was a solo community effort spanning **over 40 hours of vibe coding with Claude** and **hundreds of test iterations** to bring every single tutorial scenario back to a playable, polished state. Below is a summary of what I fixed and why.

---

## The ERROR Model Epidemic

If you've loaded into any tutorial scenario recently, you may have noticed something: your hero looks like a floating red ERROR sign from a 2007 Source Engine mod. Very retro. Not very educational.

The root cause: player-equipped cosmetics aren't precached in custom game contexts. The engine tries to load your Arcana, your Immortals, your limited-edition shoulder pads — and when it can't find the files, it replaces them with the ERROR placeholder. This affected nearly every scenario, from **Luna** in Basic Mechanics to **Vengeful Spirit** in Stacking, and everyone in between.

The fix varied by scenario. For bot-controlled heroes like **Shadow Fiend** in Mid-Game Progression, I discovered that spawning units with `bSpawnOnPrecacheComplete = true` and using a freeze-reveal pattern allowed the engine to properly load cosmetics within the precache context. For player-controlled heroes like **Night Stalker**, **Vengeful Spirit**, and others, I force the base model with `SetOriginalModel` and strip cosmetic wearables that fail to load.

**Affected scenarios:** Basic Mechanics (Luna), Getting Around (Mirana), Teleporting (WK & DK), Using Your Courier (Night Stalker), Regen & Consumables (Viper, Lina, Lion), Mid-Game Progression (Sven & SF), Map Vision & Warding, Stuns & Disables, Teamfight Initiation (Tidehunter), Status Effects (Ogre Magi), Roshan & The Aegis, Invisibility Detection (Lion), Stacking Neutral Camps (Vengeful Spirit), Pulling Creeps, Dodge & Disjoint (Windranger), Item Setups (Jakiro), and Glimmer Cape (CM, CK, and friends).

Yes, that's basically all of them.

---

## The Courier That Doesn't Exist

Here's a fun one: the default courier model has been removed from the game. The files `default_courier.vmdl`, `default_courier_flying.vmdl`, and `donkey_flying.vmdl` simply do not exist on disk anymore. Every courier in modern Dota is a cosmetic. So when the tutorial spawns a courier using `SpawnCourierAtPosition`, the engine searches for a base model that hasn't existed for years, fails, then tries to load the player's cosmetic courier which also isn't precached, and you get... nothing. Or ERROR. Or both.

The fix: spawn the courier as a regular unit with `CreateUnitByName("npc_dota_courier")` instead. No cosmetics applied, no missing models, and the courier actually works. I grant player control with `SetControllableByPlayer` so delivery and retrieval commands function normally.

This fix was applied to both the **Using Your Courier** and **Mid-Game Progression** scenarios.

---

## Scenarios That Forgot How to Restart

Several scenarios had issues where disconnecting and reconnecting — or clicking Retry after a failure — would leave you in a broken state. Heroes spawning at coordinates `(10000, 10000, 0)` off the edge of the map. Scheduled functions from previous attempts firing during the new attempt, causing stages to overlap. Checkpoint systems trying to skip you ahead while old task instances were still running in the background, detecting phantom creep deaths and cascading failures.

The **Stacking Neutral Camps** scenario was a particular adventure. The original code had no failure handling at all — if you killed a creep or failed to stack in time, the scenario just... stopped. No retry screen. No feedback. Nothing. Adding failure handling revealed a deeper bug: the stack detection task never set its completion flag when the target died, causing it to fire failure events every game tick in an infinite loop. This, combined with checkpoint restoration creating duplicate task instances and scheduled stage transitions from previous attempts still executing, required rethinking how the scenario handles failure from the ground up.

The final approach: intercept failures before they cascade, show the retry screen exactly once, and always restart from Stage 1 on retry for a clean slate.

---

## Death, Transitions, and the Camera

The **Mid-Game Progression** scenario teaches last-hitting and economy basics, but it also features a scripted Sven-vs-SF encounter. When SF dies, the scenario needs to restart. The original implementation had the player's camera locked onto a dead hero, staring at a death timer, with no way to proceed.

I added proper death-triggered restarts with a 3-second respawn, tightened the intro cinematic from ~20 seconds down to ~7 seconds so players aren't watching a cutscene longer than they're playing, and ensured the camera, fog of war, and scene timing all behave correctly across multiple death-restart cycles.

---

## The Little Things

Beyond the headline fixes, dozens of smaller issues were addressed across scenarios: ward placement not registering properly, bots failing to path after teleporting, rune pickups not triggering task completion, Bane and Pudge encounters breaking on restart, and various cases where the gentle `Purge` needed to preserve hidden cosmetic modifiers while still clearing debuffs.

**Black King Bar** (PA) and **Advanced Items** (Rubick) were already in working order — sometimes the best fix is confirming nothing is broken.

---

## Final Notes

The New Player Experience is how many people first interact with Dota 2. A tutorial that greets you with floating ERROR signs and softlocks doesn't exactly say "welcome to the best game you'll ever play." These fixes ensure that every scenario loads cleanly, handles failure gracefully, and actually teaches what it's supposed to teach.

And about that Behavior Score system that started this whole journey — in all seriousness, there are real bugs. Party reports against solo players carry way too much weight. A single bad game with a tilted stack and suddenly you're eating a communication ban with no recourse, no context reviewed, and no meaningful way to appeal. It's a system that punishes solo players disproportionately and rewards abuse by groups who use reports as a grief tool. That's not a hot take — it's a pattern that a lot of solo queue players have experienced and documented. Hopefully that gets some attention too.

Over 40 hours. Hundreds of builds. Countless ERROR models stared at and debugged. All so the next new player who clicks "Learn" gets the experience they deserve.

See you out there.

---

## Installation

1. Download this repository as a ZIP (green **Code** button → **Download ZIP**)
2. Extract the ZIP
3. Copy the `resource/` and `scripts/` folders to:
   ```
   C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota_addons\npx_2019\
   ```
4. Overwrite existing files when prompted
5. Launch Dota 2 and open the **Learn** tab to play any scenario

> **Tip:** Back up the original `npx_2019` folder before overwriting in case you want to revert.

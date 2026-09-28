# Eslabong reference study — complete video

## Current follow-up: Arena & Roster 3.4

The user's club-overview screenshot and three local recordings informed this update. Each local recording was sampled from start to finish, with key frames inspected at full size: the 19.60-second arena clip, 18.43-second multikill clip, and 29.13-second roster clip. Audio direction follows the user's explicit description; the recordings' audio was not transcribed or copied.

- The club overview now presents the next matchup, crests, team strips, season timeline, actionable agenda, news, objectives, and actual league impact leaders.
- Fresh campaigns receive 1,200 recruitment gold and no preset heroes. Five starters are chosen from an affordable balanced opening market. Existing campaigns retain their gold and heroes. Founding funds do not unlock equipment.
- The roster follows the reference's first-team/reserve layout and compact statistical register. Saved teams by format, quick swaps, inline growth focus, ability details, sortable combat data, role filters, and two-hero comparisons are functional. No new academy assignment or passive training system is implied.
- Combat follows the clips' spatial clarity: rectangular floor, smaller directional 3D heroes, attack wind-ups, stable targets, melee approach positions, ranged spacing, visible projectiles, compact team health bars, and a selected-hero inspector.
- Double-kill and longer-chain banners count final hero deaths within six seconds and persist in match highlights. Each ability has a distinct original procedural cue. Landing, club, preparation, fight, victory, and defeat have separate music scenes.
- Results return to the overview. Skill upgrades remain strictly tied to each hero's arena level-up, with a modest rarity benefit after wins. These current rules supersede the earlier historical descriptions of preset founders, guaranteed post-bout powers, and direct-to-next-match flow below.

The recordings also show features beyond this pass, including dedicated academy/training assignments and multi-round series. Manitoria still uses one bout per league fixture. The goal of this pass is a coherent club-to-roster-to-arena loop, not feature parity with every reference mode.

## Earlier video study

Source: [I Built a Team of Fantasy Gladiators | Eslabong — Madassassin](https://www.youtube.com/watch?v=SCjQAddJM8s), 1:09:41.

**Build 3.2 update:** the user's requested slower pacing supersedes the earlier preseason guarantees below. Fresh heroes start at level one with their signature ability. Only heroes who level up through arena combat receive their own upgrade choice; benched heroes receive none. Active abilities occupy specific level milestones, and victories modestly improve power rarity. The new main menu supports separate campaigns, immutable named checkpoints, save-and-quit, and fresh teams without replacing existing runs. Bulk upgrade and retraining controls are removed. Existing learned upgrades are preserved when loading older campaigns.

Reviewed the full available transcript, 0:00–1:09:39, and representative gameplay frames across the recording. This was a complete transcript study with visual sampling, not continuous viewing of every second.

| Video section | Observed loop | Manitoria implementation |
| --- | --- | --- |
| 0:00–6:30 | Starter composition, name/crest, captain duel, four preseason fights, gold and experience | Four preseason bouts (1v1, 3v3, 3v3, 5v5), preset founders, live identity designer. Each bout earns 50/60/75/90 gold regardless of outcome and at least one power choice. No preseason injuries or fatigue. |
| 6:30–13:41 | Spend earned money on roster gaps; inspect tactics and formation; league match rewards | Recruitment retained, direct formation dragging, role-aware founding lineups, scouting and tactics. Starting equipment removed; Armory unlocks after 300 cumulative arena gold. |
| 13:42–23:53 | Three-card upgrades and active abilities; adjust after defeats | Existing role-weighted three-card powers, learnable techniques, affordable technique reset, and post-bout development retained. New founders begin with assigned skills so the first action is playing, not processing a backlog. |
| 23:53–33:25 | Reserve development, recruiting a low-level tank, facilities financed by results | Academy, facilities, specializations and recruitment retained. These can be explored later; the short opening guide no longer tours them. |
| 33:26–38:25 | A 2v2 tournament requires a different pairing; elimination still yields rewards | Existing small-team cups, saved lineups by format, participation and champion payouts retained. |
| 38:26–47:43 | Repeated league, upgrades, respec cost frustration, friendly-fire frustration | Fight → earn → upgrade loop emphasized. Technique reset remains 50 gold; team-safe damage retained deliberately. |
| 47:44–51:25 | Iron Gate PvE: consecutive floors, persistent health, leave early with earned rewards | Not implemented in this pass. It needs its own encounter, reward, and persistence design. |
| 51:26–58:08 | Protect healers; counters and targeting can overcome raw stats | Bodyguard/focus partners, cautious posture, teamwork, interrupted channels, and range-aware decisions retained. |
| 58:09–1:08:58 | A midseason 3v3 cup, adaptation, post-round upgrades, championship payoff | Existing 3v3 knockout cup, per-format formations, upgrade delivery and trophy history retained. |
| 1:09:00–end | All-Star event and champion auction are mentioned | Not added. The existing draft cup and promotion/retirement loop remain Manitoria's end-of-season systems. |

## Changes in this pass

- Three short guide prompts, with one highlighted action at a time. Sound and motion settings remain available in Club office.
- A campaign hub prioritizing the next bout, pending powers, the roster, and the next unlock.
- New clubs earn their starting funds in four preseason bouts. Existing saves retain their season and roster.
- Equipment purchase and usage are gated in both interface and actions until 300 arena gold. Existing owned equipment is preserved and keeps its Armory access.
- Original articulated 3D meshes for all 32 species replace both previous flat portrait sets. Wings, tails, heads and limbs animate; a profile viewer supports rotation and pose previews. They are stylized procedural models, not externally sculpted production assets. The arena floor remains a 2D canvas composition containing live WebGL-rendered beasts.

## Arena Flow 3.1 follow-up

After implementing the new lineup and reward flow, revisited the recording's upgrade cards at 13:56, later league combat at 41:49, and late cup combat at 1:02:43, alongside the previously reviewed full transcript. The reference's decisions remain between automatic fights: inspect the result, develop a hero, rearrange the team, then compete again.

- Active techniques, passive powers, and awakenings now appear automatically as modal card choices over the round report. Choices persist through reloads, and returning from the report opens any pending rewards.
- One next-match action advances from completed rewards directly to the following preparation screen when a fixture is available.
- League preparation explicitly uses five heroes. Small-team cups keep their own capacities. Bench selection, direct dragging, replacement, and occupied-tile swaps share one lineup model. Invalid or overlapping saved positions are repaired.
- A browser check of the user's 319px preview exposed an oversized formation grid hiding the third column. Flexible columns and scaled models now keep the whole board visible.
- Beasts turn continuously toward movement and attack targets rather than choosing between two fixed angles. Original character designs and the existing combat systems are retained.

The reference uses multi-round league series. Manitoria still uses one bout per league fixture. Full parity with the reference's PvE, auctions, and All-Star modes is not claimed. Long-term balance and higher-detail sculpted assets remain future work.

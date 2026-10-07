# Manitoria 0.70 — measured balance pass and Atlas

The audit contains **8,192 actual engine-simulated matches**: 5,888 initial matches, 1,536 same-draft champion follow-ups, and 768 expanded item/control matches across both patches. Mirrored sides and paired controls are counted explicitly; these are not human player matches or 8,192 independent tournaments.

Atlas provides tier tables, individual pages for all 32 champions, measured skill contributions, item comparisons, build/evolution summaries and matchup samples. Patch selection keeps the complete 0.69 item screen separate from the current 0.70 champion cohort. Only Rosary and Sugar Rush received expanded 0.70 item experiments: 48 mirrored setups each. Other items retain their 0.69 evidence.

## Balance changes

| Champion / item | Change |
| --- | --- |
| Owlbear | Maul coefficient 1.70 → 1.55. Basic attacks and its control identity remain intact. |
| Naga | Tidal Ward reach 5.2 → 6.0, shield coefficient 1.8 → 2.0, base cooldown 10s → 9s. |
| Gargoyle | Stone Dive now splashes nearby enemies for 0.55 power, matching its description. Suggested gear favors armor/AP. |
| Storm Kirin | Chain Lightning coefficient 1.05 → 1.15 per bounce, preserving bounce falloff. |
| Basilisk | Petrifying Gaze coefficient 1.20 → 1.30; stun remains 1.6s. |
| Cave Troll | Species health/attack multiplier 1.064 → 1.095. |
| Saint's Rosary | Opening party heal 6% → 5% maximum health. |
| Sugar Rush | Health drain 1% → 0.6% per second; the 15% health floor and tempo bonuses remain. |

In the same drafts, Naga's observed team win rate moved from 42.8% to 46.6%, Troll from 44.5% to 47.1%, and Gargoyle from 42.7% to 44.0%. Owlbear remained high at 57.7%; Basilisk remained weak at 41.9%. These remain monitoring priorities rather than claims that every champion now wins exactly half its games. All changes were applied together, so individual rate changes are not isolated causal estimates.

Sugar Rush's expanded average marginal health outcome moved from −0.38 to +0.07 surviving-champion health equivalents. Both intervals include zero. Rosary's initial +1.85 screen result did not replicate at that magnitude: the expanded comparison measured approximately +0.33 before and +0.32 after. Atlas displays intervals and samples rather than presenting these small differences as conclusive.

## Economy and build choices

Star upgrades still require **three total copies for two stars and six total copies for three stars**. Their stat improvements and protected roll upgrades retain the existing shop display. The copies-first Tank carry audit policy underperformed because it spent early funds on one champion before equipping the team; this is not evidence that three-star upgrades inherently weaken champions.

Golden Idol costs 140 gold to forge and returns 60 gold per victory while equipped on an active champion. It recovers its acquisition cost after three future victories, before considering combat opportunity cost. The bearer takes 10% extra damage and gives up an equipment slot. The single-battle screen excludes future income, so its combat ranking is not an economic ranking. Its existing risk/reward remains unchanged in this pass; wild items are excluded from automatic recommendations.

## Verification and artifacts

Targeted Ward reach, Stone Dive splash, Sugar Rush drain/floor and suggestion checks pass. Skill scaling/kit auditing, item feedback/audio, stars, sustain, all difficulty economy rules, rival wallets and the complete five-cup save route pass. The packaged game also passes the targeted mechanics and all 473 skill-icon integration checks.

Atlas includes per-batch counts and SHA-256 hashes, downloadable display datasets, and a separate raw-audit archive. Full-resolution skill renders are retained locally; engine icons use optimized 512-pixel assets. Native save format and player saves are preserved.

`analytics/baseline-0.69/pre-to-post.patch` records the rule differences. Apply it in reverse to an isolated copy of the 0.70 project to reproduce the prior rules. The unchanged audit runner supports the original batches and larger selected-item cohorts through `AUDIT_ITEM_IDS` and `AUDIT_SCENARIOS`.

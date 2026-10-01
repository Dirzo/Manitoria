# 0.14 Fluid Combat

Heroes accelerate into movement and slow their approach near attack range. Melee fighters sharing a target approach an open shoulder. Steering considers nearby opponents as well as teammates, while target selection, player tactics and ability effects remain intact.

Attacks plant the feet through recovery. Creature models shift their weight backward during anticipation, lunge through melee release, and recover with directional recoil on significant hits. Heavy creatures use a slower, restrained weight rhythm; lighter creatures have quicker movement. Authored walk animation speed follows actual travel speed. These are animation layers on the existing models, not new character meshes or replacement skeletal clips.

Body motion, turning and layered animation freeze when paused. Grounding effects stop velocity immediately. Combat positions remain separate from visual lunges so damage range and targeting stay consistent.

Validation includes acceleration, rooted movement, planted recovery, visible weight transfer, pause, recoil, existing tactics and arena spacing, all 128 skill windups, and full seeded matches. An actual 12-second Godot exhibition recording is supplied in the preview folder.

Extract the Windows build into a fresh folder and keep Manitoria.exe and Manitoria.pck together. Title screen: Windows edition 0.14. Existing saves remain compatible.

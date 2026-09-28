import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.dirname(fileURLToPath(import.meta.url));
const files=['autobattle.js','autobattle.css','battle-audio.js','roster-desk.js','roster-desk.css','index.html','base.css','polish.css','onboarding.css','game.js','polish.js','portrait-frames.js','identity.js','formation-drag.js','cinema.js','score.js','tactics.js','club-flow.js','onboarding.js','boot.js','league-desk.js','league-desk.css','run-menu.js','run-menu.css','arena-growth.js','arena-flow.js','arena-flow.css','campaign.js','campaign.css','beast-materials.js','beast-sculpt.js','beasts-3d.js','beasts-3d.css','assets/vendor/three.min.js','assets/vendor/THREE-LICENSE.txt','assets/hero.png','assets/crest.svg'];
for(const file of files){const to=path.join(root,'dist',file);await fs.mkdir(path.dirname(to),{recursive:true});await fs.copyFile(path.join(root,file),to)}
for(const old of ['assets/beasts-a.png','assets/beasts-b.png'])await fs.rm(path.join(root,'dist',old),{force:true});
console.log(`Built ${files.length} static assets into dist/.`);

'use strict';
const RUN_LIBRARY_KEY='manitoria-campaign-library-v1';
let runSerial=0;
const copyRun=value=>JSON.parse(JSON.stringify(value));
const runId=()=>`run-${Date.now().toString(36)}-${(++runSerial).toString(36)}-${Math.random().toString(36).slice(2,8)}`;
function validRun(g){return !!(g&&g.v>=1&&g.v<=3&&g.clubs?.P&&Array.isArray(g.clubs.P.roster)&&g.clubs.P.roster.every(id=>g.beasts?.[id])&&Array.isArray(g.sched)&&g.league)}
function readRunLibrary(){const raw=localStorage.getItem(RUN_LIBRARY_KEY);if(!raw)return {version:1,activeId:null,slots:[]};const library=JSON.parse(raw);if(library.version!==1||!Array.isArray(library.slots))throw Error('Unreadable save library');return library}
function writeRunLibrary(library){try{localStorage.setItem(RUN_LIBRARY_KEY,JSON.stringify(library));return true}catch{toast('Could not save. Your campaign is still open. Export a backup from Club office.');return false}}
function runSlot(game,kind='autosave',label=game.runLabel||'Current progress',id=game.runId){return {id,kind,label,updatedAt:new Date().toISOString(),game:copyRun(game)}}
function captureRun(){
 if(['result','levelup'].includes(UI.mode)&&UI.result)G.resume={mode:'result',result:UI.result,lvq:UI.lvq||[],lvTotal:UI.lvTotal||0,rewardOpen:UI.mode==='levelup'};
 else if(UI.mode==='season'&&UI.seasonSum)G.resume={mode:'season',seasonSum:UI.seasonSum};
 else delete G.resume;
 G.flowCheckpoint={mode:UI.mode==='battle'?'prematch':UI.mode,ctx:UI.ctx,sel:UI.sel||[],tab:UI.tab||'club'};
 if(!G.runId)G.runId=runId();
 return copyRun(G);
}
save=function(){
 if(!G||['menu','intro'].includes(UI.mode))return true;
 try{const game=captureRun(),library=readRunLibrary(),slot=runSlot(game),index=library.slots.findIndex(s=>s.id===game.runId);if(index<0)library.slots.push(slot);else library.slots[index]=slot;library.activeId=game.runId;if(!writeRunLibrary(library))return false;
 // This compatibility copy also supports existing exported saves and recovery tools.
 try{localStorage.setItem(SAVE_KEY,JSON.stringify(game))}catch{}return true;
 }catch{toast('Could not read the save library. Export a backup before leaving this run.');return false}
};
function saveCheckpoint(label){if(!G||!save())return false;try{const library=readRunLibrary();library.slots.push(runSlot(G,'checkpoint',String(label||`Season ${G.season} · Day ${G.day+1}`).trim().slice(0,48)||'Saved checkpoint',runId()));return writeRunLibrary(library)}catch{return false}}
function resetRunUI(){stopBattle();clearFormationDrag();UI.ctx=null;UI.sel=[];UI.result=null;UI.lvq=[];UI.lvTotal=0;UI.modal=null;UI.tab='club';UI.seasonSum=null;UI.formBeast=null;UI.replaceWith=null;UI.quickTactics=[];keeperNeedsRoute=false;keeperScroll=false}
function restoreRun(game){
 resetRunUI();G=migrate(copyRun(game));migrateArenaProgress(G);UI.mode='hub';const c=G.flowCheckpoint,r=G.resume;
 if(r?.mode==='result'&&r.result?.ctx){UI.result=r.result;UI.ctx=r.result.ctx;UI.lvq=(r.lvq||[]).filter(id=>rewardKind(G.beasts[id]));UI.lvTotal=r.lvTotal||UI.lvq.length;UI.mode=r.rewardOpen&&UI.lvq.length?'levelup':'result';UI.modal=UI.mode==='levelup'?{k:'reward'}:null}
 else if(r?.mode==='season'&&r.seasonSum){UI.mode='season';UI.seasonSum=r.seasonSum}
 else if(c){UI.tab=['club','roster','academy','market','shop','league','leaders','bestiary','legacy'].includes(c.tab)?c.tab:'club';if(c.mode==='prematch'&&c.ctx){UI.ctx=c.ctx;UI.sel=c.sel||[];UI.mode='prematch';normalizeLineup()}else if(c.mode==='draft'&&G.draft)UI.mode='draft';else if(c.mode==='cupdone'&&G.cup)UI.mode='cupdone'}
 return G;
}
function loadRunSlot(id){try{const library=readRunLibrary(),slot=library.slots.find(s=>s.id===id);if(!slot||!validRun(slot.game)){toast('This saved campaign could not be opened.');return false}const game=copyRun(slot.game);if(slot.kind==='checkpoint'){game.runId=runId();game.runLabel=`From ${slot.label}`}restoreRun(game);const saved=save();render();music('prelude');window.scrollTo(0,0);return saved}catch{toast('This saved campaign could not be opened.');return false}}
function showRunMenu(){resetRunUI();G=null;UI.mode='menu';music(null);render();window.scrollTo(0,0)}
function bootRunMenu(){
 try{const library=readRunLibrary();if(!library.slots.length){const legacy=localStorage.getItem(SAVE_KEY);if(legacy){const game=JSON.parse(legacy);if(validRun(game)){game.runId=game.runId||runId();library.slots.push(runSlot(game,'autosave','Previous campaign'));library.activeId=game.runId;writeRunLibrary(library)}}}UI.menuError=null}catch{UI.menuError='Your save library could not be read. Its stored data has been kept.'}
 showRunMenu();
}
const menuLoad=load;load=function(){try{const library=readRunLibrary(),slot=library.slots.find(s=>s.id===library.activeId);if(slot&&validRun(slot.game))return restoreRun(slot.game)}catch{}const game=menuLoad();if(game)migrateArenaProgress(game);return game};
function saveStage(game){if(game.resume?.result)return 'Round complete · rewards saved';if(game.flowCheckpoint?.mode==='prematch')return 'Formation ready';if(game.campaign?.preseason<4)return `Preseason ${game.campaign.preseason} / 4`;return `Season ${game.season} · Day ${game.day+1}`}
function viewRunMenu(){
 let library;try{library=readRunLibrary()}catch{library={slots:[]}}
 const slots=library.slots.filter(s=>validRun(s.game)).sort((a,b)=>b.updatedAt.localeCompare(a.updatedAt)),active=slots.find(s=>s.id===library.activeId)||slots[0];
 return `<div class="run-home"><section class="run-hero"><div class="run-hero-copy"><span class="lbl gold">YOUR CLUB. YOUR NEXT CHAPTER.</span><h1>A legacy<br>worth returning to.</h1><p>Build a team. Earn every upgrade in the arena.<br>Come back to your story whenever you like.</p><div class="run-hero-actions">${active?`<button class="btn pri" data-act="runLoad" data-id="${active.id}">Continue ${esc(active.game.name)}</button>`:''}<button class="btn ${active?'':'pri'}" data-act="runNew">Start a fresh team</button></div><span class="run-version">CAMPAIGNS · 3.2</span></div></section><div class="section-heading"><div><span class="lbl gold">THE CLUB ARCHIVE</span><h2>Your saved campaigns</h2></div><span>Saved in this browser</span></div>${UI.menuError?`<p class="bad">${esc(UI.menuError)}</p>`:''}<div class="run-saves">${slots.map(s=>{const g=s.game;return `<article class="run-save"><div class="run-save-title">${crest(g.clubs.P,52)}<div><span class="lbl ${s.kind==='checkpoint'?'gold':''}">${s.kind==='checkpoint'?'NAMED CHECKPOINT':'AUTOSAVED CAMPAIGN'}</span><h3>${esc(g.name)}</h3></div></div>${s.kind==='checkpoint'||s.label!=='Current progress'?`<p class="checkpoint-name">${esc(s.label)}</p>`:''}<div class="saved-team">${g.clubs.P.roster.slice(0,5).map(id=>beastArt(g.beasts[id].sp)).join('')}</div><p>${esc(saveStage(g))}</p><div class="save-facts"><span>${fmt(g.gold)} gold</span><span>${g.clubs.P.roster.length} heroes</span><span>${g.trophies.length} trophies</span></div><div class="save-footer"><time datetime="${esc(s.updatedAt)}">${esc(new Date(s.updatedAt).toLocaleString(undefined,{month:'short',day:'numeric',hour:'numeric',minute:'2-digit'}))}</time><button class="btn sm" data-act="runLoad" data-id="${s.id}">${s.kind==='checkpoint'?'Start from checkpoint':'Load campaign'}</button></div></article>`}).join('')||'<div class="panel empty-run"><h3>Your first chapter awaits.</h3><p>Choose a fresh team to start your campaign.</p></div>'}</div><details class="panel menu-import"><summary>Import a campaign backup</summary><label for="menu-import">Save code</label><textarea id="menu-import" placeholder="Paste your campaign backup"></textarea><button class="btn sm" data-act="runImport">Import as a separate campaign</button></details><p class="note">A fresh team creates a separate campaign. Named checkpoints stay unchanged when you play from them.</p></div>`;
}
function modalRunMenu(){return `<div class="run-dialog"><span class="lbl gold">${esc(G.name)}</span><h2>Your campaign</h2><p class="note">${UI.mode==='battle'?'This bout is paused. Save and quit returns you to its preparation screen; the unfinished fight will restart.':'Progress saves automatically. Keep a named checkpoint to return to this moment.'}</p><button class="btn pri" data-act="runResume">Return to ${UI.mode==='battle'?'the arena':'campaign'}</button><section class="checkpoint-form"><label for="checkpoint-name">Name a checkpoint</label><input id="checkpoint-name" maxlength="48" placeholder="Before the cup final" value="${esc(`Season ${G.season} · Day ${G.day+1}`)}"><button class="btn" data-act="runCheckpoint">Save checkpoint</button><p class="note" id="checkpoint-status" role="status"></p></section><button class="btn" data-act="runSave">Save campaign now</button><button class="btn" data-act="runQuit">Save & quit to main menu</button></div>`}
function resumeFromRunMenu(){const paused=UI.modal?.wasPaused;UI.modal=null;if(BT&&paused===false)BT.paused=false;if(UI.mode==='battle')renderModal();else render()}
ACT.runMenu=()=>{if(!G)return;UI.modal={k:'runmenu',wasPaused:BT?.paused??true};if(BT)BT.paused=true;renderModal()};
ACT.runResume=resumeFromRunMenu;
ACT.runSave=()=>{if(save())toast('Campaign saved.')};
ACT.runCheckpoint=()=>{if(saveCheckpoint($('#checkpoint-name')?.value)){$('#checkpoint-status').textContent='Checkpoint saved. It is waiting in the main menu.';toast('Checkpoint saved.')}};
ACT.runQuit=()=>{if(save())showRunMenu()};
ACT.runLoad=d=>loadRunSlot(d.id);
ACT.runNew=()=>{if(G&&!save())return;resetRunUI();G=null;UI.mode='intro';render();window.scrollTo(0,0)};
ACT.runHome=()=>{if(G&&!save())return;showRunMenu()};
ACT.new=ACT.newok=ACT.runNew;
ACT.introContinue=ACT.runHome;
function importRunCode(code){try{const game=JSON.parse(decodeURIComponent(escape(atob(String(code).trim()))));if(!validRun(game))throw Error();game.runId=runId();const library=readRunLibrary(),slot=runSlot(game,'autosave','Imported campaign');library.slots.push(slot);library.activeId=slot.id;if(!writeRunLibrary(library))return false;showRunMenu();toast('Campaign imported as a separate save.');return true}catch{toast('That save code could not be read. Existing campaigns are unchanged.');return false}}
ACT.runImport=()=>importRunCode($('#menu-import').value);
ACT.import=()=>{if(save())importRunCode($('#imp').value)};
const runTop=renderTop;renderTop=function(){runTop();document.querySelector('.purse')?.insertAdjacentHTML('beforeend','<button class="btn sm" data-act="runMenu">Run menu</button>')};
const runClose=ACT.close;ACT.close=d=>UI.modal?.k==='runmenu'?resumeFromRunMenu():runClose(d);
const runScrim=ACT.scrim;ACT.scrim=(d,el,e)=>{if(UI.modal?.k==='runmenu'){if(e.target===el)resumeFromRunMenu()}else runScrim(d,el,e)};
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&UI.modal?.k==='runmenu'){e.preventDefault();e.stopImmediatePropagation();resumeFromRunMenu()}},true);
const runIntro=viewIntro;viewIntro=function(){return `<button class="linkbtn back-menu" data-act="runHome">← Main menu</button>`+runIntro().replace(' Founding a new club replaces your current club.',' Each new team gets its own campaign save.')};
const runOffice=modalSettings;modalSettings=function(m){return runOffice(m).replace(/<details class="office-details"[^>]*><summary>Found a new club<\/summary>[\s\S]*?<\/details>/,`<section class="office-details"><h3>Campaigns & saves</h3><p class="note">Keep this run, save a checkpoint, or start a separate team from the main menu.</p><button class="btn" data-act="runMenu">Open run menu</button></section>`).replace('Loading replaces the current club.','Imported backups become separate campaigns.')};

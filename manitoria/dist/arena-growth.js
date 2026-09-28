'use strict';
// Arena level-ups earn individual choices. No roster-wide or pre-fight spending.
const legacyTechniquePoints=techniquePoints;
function arenaHero(b){return !!(b?.arenaProgress&&b.clubId==='P')}
function techniqueRanks(b){return Object.values(b.techniques||{}).reduce((n,v)=>n+v,0)}
function initArenaHero(b,fresh=false){
 if(b.arenaProgress)return b.arenaProgress;
 const bank={powers:fresh?0:b.rolls||0,techniques:fresh?0:legacyTechniquePoints(b),awakening:fresh?[]:b.awaken||[]};
 if(fresh){b.lvl=1;b.xp=0;b.perks={};b.techniques={};b.techTiming={};b.picksTaken=0;b.mastery=null;b.skills={};b.skp=0}
 b.arenaProgress={version:1,bouts:0,wins:0,chosen:0,bank,pending:null,history:[]};b.rolls=0;b.offer=null;b.awaken=[];return b.arenaProgress;
}
function legalArenaPowers(b){return Object.keys(PERKS).filter(k=>(b.perks?.[k]||0)<PERKS[k].max&&!(k==='blades'&&SPECIES[b.sp].range>=60))}
function legalArenaTechniques(b){return techniquePool(b).filter(k=>(b.techniques?.[k]||0)<3&&(Object.keys(b.techniques||{}).length<2||b.techniques?.[k]))}
function arenaRarityWeights(b,won=false){const raw=tierW(b),sum=raw.reduce((a,v)=>a+v,0),weights=raw.map(n=>n/sum*100);if(won){weights[0]-=5;weights[1]+=3;weights[2]+=1.5;weights[3]+=.5}return weights}
const arenaRollOriginal=rollOffer;
rollOffer=function(b){
 if(!arenaHero(b))return arenaRollOriginal(b);
 if(b.arenaProgress.pending?.kind!=='power'){b.offer=null;return}
 const allowed=legalArenaPowers(b),out=[],weights=arenaRarityWeights(b,b.arenaProgress.pending.won);
 const draw=pool=>{if(!pool.length)return;const tiers=[1,2,3,4].filter(t=>pool.some(k=>PERKS[k].t===t)),tier=wpick(tiers,tiers.map(t=>weights[t-1]));out.push(pick(pool.filter(k=>PERKS[k].t===tier)))};
 draw(allowed.filter(k=>perkFit(b,k)));
 if((b.picksTaken||0)%6===5)draw(allowed.filter(k=>!out.includes(k)&&PERKS[k].t>=3));
 while(out.length<Math.min(3,allowed.length))draw(allowed.filter(k=>!out.includes(k)));
 b.offer=out.length?out:null;b.rerolls=0;
};
function grantArenaChoice(b,won,countBout=true){
 const p=initArenaHero(b);if(countBout){p.bouts++;if(won)p.wins++}if(p.pending)return false;
 const tech=legalArenaTechniques(b).length>0;
 let kind=p.bank.awakening.length?'trait':tech&&(p.bank.techniques>0||(b.lvl>=3&&(b.lvl-3)%4===0))?'technique':legalArenaPowers(b).length?'power':tech?'technique':null;
 if(!kind)return false;
 p.pending={kind,won:!!won,bout:p.bouts,level:b.lvl};
 if(kind==='trait'){b.awaken=p.bank.awakening.slice();p.bank.awakening=[]}
 if(kind==='technique'&&p.bank.techniques>0)p.bank.techniques--;
 if(kind==='power'){if(p.bank.powers>0)p.bank.powers--;b.rolls=1;rollOffer(b)}
 return true;
}
function migrateArenaProgress(g){
 if(!g?.clubs?.P)return g;const q=new Set(g.resume?.lvq||[]),rows=g.resume?.result?.rows||[];
 for(const id of g.clubs.P.roster){const b=g.beasts[id];if(!b||b.arenaProgress)continue;const offer=b.offer?.slice(),hadChoices=(b.rolls||0)>0||legacyTechniquePoints(b)>0||b.awaken?.length;initArenaHero(b);if(q.has(id)&&hadChoices&&rows.some(r=>r.bid===id&&r.team===0)){grantArenaChoice(b,g.resume.result.winner===0,false);if(b.arenaProgress.pending?.kind==='power'&&offer?.length)b.offer=offer}}
 g.arenaRules=1;return g;
}
const growthNewGame=newGame;newGame=function(...args){growthNewGame(...args);G.arenaRules=1;for(const b of clubBeasts())initArenaHero(b,true)};
const growthGen=genBeast;genBeast=function(...args){const b=growthGen(...args);if(G?.arenaRules&&b.clubId==='P')initArenaHero(b,true);return b};
techniquePoints=function(b){return arenaHero(b)?(b.arenaProgress.pending?.kind==='technique'?1:0):legacyTechniquePoints(b)};
const growthXP=gainXp;gainXp=function(b,amt){if(!arenaHero(b))return growthXP(b,amt);const rolls=b.rolls,offer=b.offer,awakening=b.awaken;const ups=growthXP(b,amt);if(b.awaken!==awakening&&b.awaken?.length)b.arenaProgress.bank.awakening=b.awaken.slice();b.rolls=rolls;b.offer=offer;b.awaken=awakening;return ups};
const growthRecord=recordMatch;recordMatch=function(S,meta){if(S.arenaGrowthRows)return S.arenaGrowthRows;const rows=growthRecord(S,meta);if(G.arenaRules)for(const r of rows){const b=G.beasts[r.bid];if(b?.clubId==='P'){const p=initArenaHero(b);p.bouts++;if(r.team===S.winner)p.wins++;if(r.ups>0)grantArenaChoice(b,r.team===S.winner,false);r.arenaChoice=b.arenaProgress.pending?.kind||null}}S.arenaGrowthRows=rows;return rows};
const growthAuto=autoPick;autoPick=function(b){if(!arenaHero(b))return growthAuto(b)};
const growthAutoTech=autoTechniques;autoTechniques=function(b){if(!arenaHero(b))return growthAutoTech(b)};
const growthKind=rewardKind;rewardKind=function(b){return arenaHero(b)?b.arenaProgress.pending?.kind||null:growthKind(b)};
function arenaChoiceAllowed(b,kind){return !!(arenaHero(b)&&b.arenaProgress.pending?.kind===kind&&UI.result?.rows.some(r=>r.bid===b.id&&r.team===0)&&UI.mode==='levelup'&&UI.lvq?.[0]===b.id)}
const growthTake=takePerk;takePerk=function(b,k){if(arenaHero(b)&&!arenaChoiceAllowed(b,'power'))return false;return growthTake(b,k)};
const growthLearn=learnTechnique;learnTechnique=function(b,k){if(arenaHero(b)&&!arenaChoiceAllowed(b,'technique'))return false;return growthLearn(b,k)};
function completeArenaChoice(b,name){const p=b.arenaProgress;p.history.push({bout:p.pending.bout,name,kind:p.pending.kind,won:p.pending.won});p.history=p.history.slice(-8);p.chosen++;b.notes.push({s:G.season,d:G.day+1,t:`learned ${name} after leveling up in the arena`});p.pending=null;b.rolls=0;b.offer=null;b.awaken=[];rewardRevision();playCue('upgrade');advanceLv();toast(`${b.name} learned ${name}.`)}
ACT.rewardPerk=d=>{const b=G.beasts[d.id];if(!rewardActionAllowed(d)||!arenaChoiceAllowed(b,'power')||!takePerk(b,d.k))return;completeArenaChoice(b,perkName(b,d.k))};
ACT.rewardTechnique=d=>{const b=G.beasts[d.id];if(!rewardActionAllowed(d)||!arenaChoiceAllowed(b,'technique')||!learnTechnique(b,d.k))return;completeArenaChoice(b,TECHNIQUES[d.k].n)};
ACT.rewardTrait=d=>{const b=G.beasts[d.id];if(!rewardActionAllowed(d)||!arenaChoiceAllowed(b,'trait')||!b.awaken.includes(d.k))return;b.traits.push(d.k);completeArenaChoice(b,d.k)};
const growthReroll=ACT.reroll;ACT.reroll=d=>{if(!arenaHero(G.beasts[d.id])||arenaChoiceAllowed(G.beasts[d.id],'power'))growthReroll(d)};
for(const key of ['keeperTrain','lvall','autoperk','autolearn','learn','technique','perk','awaken','resetTechniques','mastery'])ACT[key]=()=>toast('Heroes earn individual upgrades by leveling up in the arena.');
const growthUse=ACT.use;ACT.use=d=>{if(['manual','tome','dice'].includes(d.k)&&arenaHero(G.beasts[d.id]))return toast('Experience and skill choices are earned in the arena.');growthUse(d)};
const growthSupply=ACT.cbuy;ACT.cbuy=d=>{if(['manual','tome','dice'].includes(d.k)&&G.arenaRules)return;growthSupply(d)};
const growthBuy=ACT.buy;ACT.buy=d=>{growthBuy(d);const b=G.beasts[d.id];if(b?.clubId==='P'){initArenaHero(b);save();render()}};
const growthStart=startMatch;startMatch=function(watch){const pending=clubBeasts().filter(b=>rewardKind(b));if(pending.length){if(UI.result){UI.lvq=pending.map(b=>b.id);UI.lvTotal=UI.lvq.length;openRewardCards()}else toast('Finish the earned hero choices before another bout.');return}growthStart(watch)};
const growthModal=modalReward;modalReward=function(){const b=G.beasts[UI.lvq[0]],p=b.arenaProgress;let h=growthModal();if(!p)return h;h=h.replace('ROUND COMPLETE','ARENA LEVEL UP').replace('It carries into your next match.','This hero earned a level. Choose their next upgrade.');h=h.replace(/<span>[^<]* · Level [^<]*<\/span>/,`<span>${esc(SPECIES[b.sp].n)} · Level ${b.lvl} · One earned choice</span>`);if(p.pending?.kind==='power'&&p.pending.won)h=h.replace('</h2>','</h2><span class="victory-draft">VICTORY BONUS · Better odds of rare powers</span>');return h.replace('<button class="btn sm" data-act="rewardLater">Review match</button>','<button class="btn sm" data-act="rewardLater">Review match</button><button class="btn sm" data-act="runQuit">Save & quit</button>')};
const growthAcademy=viewAcademy;viewAcademy=function(){return growthAcademy().replace(/<section class="panel row between">[\s\S]*?<\/section>/,'').replace('Every investment follows your menagerie through the seasons.','Club facilities support your team. Each hero earns skills separately by fighting in the arena.').replace(/<div class="section-heading"><h2>Your future champions<\/h2>[\s\S]*$/,'</div>')};
upgradesHtml=function(b,edit){
 const p=b.arenaProgress,owned=Object.keys(b.perks||{}).filter(k=>b.perks[k]&&PERKS[k]),tech=Object.keys(b.techniques||{}).filter(k=>TECHNIQUES[k]);
 return `${p?`<section class="hero-progress"><span class="lbl gold">EARNED IN THE ARENA</span><h3>${p.bouts} bouts · ${p.chosen} choices made</h3><p>Only arena level-ups earn upgrades, one hero at a time. Active abilities unlock at levels 3, 7, 11, 15, 19, and 23. Wins slightly improve power rarity. Benched heroes earn no choices.</p>${p.pending?'<span class="gold">An earned choice is waiting in the match report.</span>':`<span class="note">${Math.max(0,xpNeed(b.lvl)-b.xp)} XP to this hero’s next level.</span>`}</section>`:''}<h3>Active abilities</h3><div class="path-grid">${tech.map(k=>`<article class="path-card active"><span class="lbl gold">${TECHNIQUES[k].icon} RANK ${b.techniques[k]}</span><h3>${TECHNIQUES[k].n}</h3><p>${TECHNIQUES[k].d}</p>${edit?`<label class="note">Cast timing <select data-chg="techTiming" data-id="${b.id}" data-k="${k}" aria-label="${TECHNIQUES[k].n} cast timing">${[['auto','Whenever useful'],['clutch','Only in danger'],['off','Hold this technique']].map(([v,n])=>`<option value="${v}" ${(b.techTiming?.[k]||'auto')===v?'selected':''}>${n}</option>`).join('')}</select></label>`:''}</article>`).join('')||'<p class="note">Your signature ability is ready from the start. Additional abilities are earned through arena appearances.</p>'}</div><h3>Learned powers</h3><div class="pcards">${owned.map(k=>upgradeCard(b,k)).join('')||'<p class="note">Level up in the arena to earn a three-card choice.</p>'}</div>`;
};
const growthClub=viewClub;viewClub=function(){return growthClub().replace(/<section class="earned-upgrades">[\s\S]*?<\/section>/,'')};
const growthProfile=modalProfile;modalProfile=function(m){const html=growthProfile(m);return arenaHero(G.beasts[m.id])?html.replace(/<div class="awaken">[\s\S]*?<\/div><\/div>/,'<p class="note">Choose this hero’s awakening in the post-arena reward cards.</p>'):html};
const growthResult=viewResult;viewResult=function(){let h=growthResult().replaceAll('>Pick skill</button>','>View hero</button>').replace('Choose powers ·','Choose upgrades ·');const heroes=UI.result.rows.filter(r=>r.team===0&&arenaHero(G.beasts[r.bid]));if(!heroes.length)return h;const progress=`<section class="panel"><span class="lbl gold">HERO DEVELOPMENT</span><h3>Every fight moves them forward.</h3><div class="round-growth">${heroes.map(r=>{const b=G.beasts[r.bid],capped=b.lvl>=lvlCap(b);return `<div class="round-growth-hero">${beastArt(b.sp)}<div><div class="row between"><strong>${esc(b.name)}</strong><span>Level ${b.lvl}</span></div><span class="bar xp"><i style="width:${capped?100:clamp(b.xp/xpNeed(b.lvl)*100,0,100)}%"></i></span><small>${r.ups?'Level up · '+(rewardKind(b)?'upgrade earned':'upgrade chosen'):capped?'Potential reached':`${Math.max(0,xpNeed(b.lvl)-b.xp)} XP to next level`}</small></div></div>`}).join('')}</div></section>`;return h.replace('</section>','</section>'+progress)};

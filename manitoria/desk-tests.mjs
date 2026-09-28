import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.dirname(fileURLToPath(import.meta.url));
let seed=305;
const math=Object.create(Math);math.random=()=>{seed=(seed*1664525+1013904223)>>>0;return seed/4294967296};
const store=new Map(),element={innerHTML:'',textContent:'',classList:{toggle(){},add(){},remove(){}},getContext:()=>({setTransform(){}}),dataset:{},style:{},insertAdjacentHTML(){}};
const sandbox={console,Math:math,document:{body:element,hidden:false,addEventListener(){},querySelector:()=>element,querySelectorAll:()=>[],getElementById:()=>element},window:{scrollTo(){}},localStorage:{getItem:k=>store.get(k)||null,setItem:(k,v)=>store.set(k,v)},matchMedia:()=>({matches:false}),setTimeout:()=>0,clearTimeout(){},setInterval:()=>0,clearInterval(){},requestAnimationFrame:()=>1,cancelAnimationFrame(){},devicePixelRatio:1,performance:{now:()=>0},Image:function(){},btoa:s=>Buffer.from(s,'binary').toString('base64'),atob:s=>Buffer.from(s,'base64').toString('binary')};
vm.createContext(sandbox);
for(const file of ['game.js','portrait-frames.js','polish.js','identity.js','cinema.js','score.js','tactics.js','formation-drag.js','club-flow.js','campaign.js','assets/vendor/three.min.js','beast-materials.js','beast-sculpt.js','beasts-3d.js','onboarding.js','arena-flow.js','arena-growth.js','run-menu.js','league-desk.js','autobattle.js','battle-audio.js','roster-desk.js'])vm.runInContext(fs.readFileSync(path.join(root,file),'utf8'),sandbox,{filename:file});
const run=code=>vm.runInContext(code,sandbox);
run(`render=()=>{};renderModal=()=>{};renderTop=()=>{};renderTabs=()=>{};toast=()=>{};music=()=>{};playCue=()=>{};
function fresh(name='Test Campaign'){resetRunUI();UI.mode='hub';newGame(name,CASTS[0].m,38);G.onboarding.active=false;return G}
function resultFor(winner=0){const S=createSim(UI.sel.map(id=>G.beasts[id]),pickLineup(UI.ctx.opp,UI.ctx.fmt),{headless:true});S.winner=winner;S.t=30;S.done=true;finishMatch(S);return S}
function chooseCurrent(){const b=G.beasts[UI.lvq[0]],kind=rewardKind(b),d={id:b.id,rev:UI.result.rewardRevision||0};if(kind==='power')ACT.rewardPerk({...d,k:b.offer[0]});else if(kind==='technique')ACT.rewardTechnique({...d,k:legalArenaTechniques(b)[0]});else ACT.rewardTrait({...d,k:b.awaken[0]})}
function clearChoices(){let guard=0;while(remainingRewards().length&&guard++<15)chooseCurrent();if(remainingRewards().length)throw Error('Undelivered choices')}
`);

let passed=0;const test=(name,code)=>{assert.equal(run(code),true,name);passed++;console.log('PASS '+name)};
test('new club has an empty roster, 1,200 gold, no gear unlock or preset lineup',
 "(()=>{fresh();return G.gold===1200&&clubBeasts().length===0&&Object.values(G.lineups).every(x=>x.length===0)&&G.campaign.earnedGold===0&&!armoryUnlocked()&&G.ledger[0].amt===1200&&!viewIntro().includes('Choose your founding cast')})()");
test('opening market has twelve distinct species, balanced roles, and level-one signature-only recruits',
 "(()=>{const bs=G.market.map(id=>G.beasts[id]);return bs.length===12&&new Set(bs.map(b=>b.sp)).size===12&&['front','flank','back'].every(l=>bs.filter(b=>ROLE_LINE[roleOf(b)]===l).length===4)&&bs.every(b=>b.lvl===1&&!b.rolls&&!b.offer&&!techniquePoints(b)&&!Object.keys(b.perks).length&&!Object.keys(b.techniques).length&&value(b)>=90&&value(b)<=220)})()");
test('empty club pages render useful recruitment states and no invalid stats',
 "(()=>{return [viewClub(),viewMarket(),viewRoster(),viewLeaders(),viewAcademy()].every(h=>h&&!/NaN|undefined/.test(h))&&viewClub().includes('0 / 5 STARTERS SIGNED')&&viewRoster().includes('Complete recruitment')})()");
test('arena and tutorial cannot bypass the five-hero requirement',
 "(()=>{openNext();if(UI.mode!=='hub'||UI.tab!=='market'||UI.ctx)return false;G.onboarding.active=true;ACT.keeperNext();return G.onboarding.step==='welcome'&&UI.tab==='market'})()");
test('scouts and facilities cannot consume founding funds or replace opening listings',
 "(()=>{const before=JSON.stringify(G);ACT.mrefresh();ACT.facility({k:'academy'});refreshMarket(false);return JSON.stringify(G)===before})()");
test('a paid recruit is signed exactly once and starts without upgrade choices',
 "(()=>{const id=G.market[0],b=G.beasts[id],price=value(b);ACT.buy({id});const after=JSON.stringify(G);ACT.buy({id});return G.gold===1200-price&&clubBeasts().length===1&&!G.market.includes(id)&&JSON.stringify(G)===after&&b.clubId==='P'&&!rewardKind(b)&&!b.rolls&&G.lineups[1][0]===id})()");
test('unknown and opposing heroes cannot be purchased',
 "(()=>{const before=JSON.stringify(G),id=G.clubs[G.div.find(id=>id!=='P')].roster[0];ACT.buy({id:'missing'});ACT.buy({id});return JSON.stringify(G)===before})()");
test('five most expensive recruits remain affordable across fifty starting markets',
 "(()=>{for(let n=0;n<50;n++){fresh();const ids=G.market.slice().sort((a,b)=>value(G.beasts[b])-value(G.beasts[a])).slice(0,5);for(const id of ids){if(recruitReason(G.beasts[id]))return false;ACT.buy({id})}if(foundingOpen()||clubBeasts().length!==5||G.gold<100)return false}return true})()");
test('recruitment expenses survive save-and-quit with no gold reset',
 "(()=>{fresh('Recruitment Save');ACT.buy({id:G.market[0]});ACT.buy({id:G.market[0]});const gold=G.gold,market=JSON.stringify(G.market),team=JSON.stringify(G.clubs.P.roster);save();const id=G.runId;ACT.runQuit();loadRunSlot(id);return G.gold===gold&&JSON.stringify(G.market)===market&&JSON.stringify(G.clubs.P.roster)===team&&saveStage(G)==='Recruiting · 2 / 5 starters'})()");
test('budget reserve rejects a signing that leaves too little to finish the team',
 "(()=>{G.gold=150;const b=G.beasts[G.market[0]],before=JSON.stringify(G);ACT.buy({id:b.id});return !!recruitReason(b)&&JSON.stringify(G)===before})()");
test('existing campaign loads without an empty roster or a founding grant',
 "(()=>{fresh('Existing');for(let i=0;i<5;i++)ACT.buy({id:G.market[0]});const old=copyRun(G);delete old.recruitment;old.gold=215;const ids=JSON.stringify(old.clubs.P.roster);restoreRun(old);return !G.recruitment&&G.gold===215&&JSON.stringify(G.clubs.P.roster)===ids&&!foundingOpen()})()");
test('impact rankings aggregate the current division and keep unplayed heroes unranked',
 "(()=>{fresh();const ai=G.beasts[G.clubs[G.div[1]].roster[0]],second=G.beasts[G.clubs[G.div[2]].roster[0]];ai.season.m=2;ai.season.imp=60;second.season.m=1;second.season.imp=45;const total=leagueImpactRows(),avg=leagueImpactRows('imp',true);return total[0].b.id===ai.id&&avg[0].b.id===second.id&&total.length===56&&total.every(x=>G.div.includes(x.b.clubId))&&viewLeaders().includes('Unplayed heroes are unranked')})()");
test('a completed league match records both player and rival impact from combat',
 "(()=>{fresh();for(let i=0;i<5;i++)ACT.buy({id:G.market[0]});G.campaign.preseason=4;openNext();startMatch(false);const rows=leagueImpactRows().filter(x=>x.b.season.m);return rows.some(x=>x.b.clubId==='P')&&new Set(rows.map(x=>x.b.clubId)).size===8&&rows.every(x=>Number.isFinite(x.score))&&rows.some(x=>x.score>0)})()");
test('match continuation returns to the overview without launching another bout',
 "(()=>{clearChoices();ACT.resnext();return UI.mode==='hub'&&UI.tab==='club'&&viewClub().includes('League impact')})()");
test('an authentic 1,200-gold campaign completes preseason with five chosen heroes',
 "(()=>{fresh('Founding Journey');for(let i=0;i<5;i++)ACT.buy({id:G.market[0]});let fights=0;while(inPreseason()&&fights<4){openNext();startMatch(false);clearChoices();ACT.resnext();fights++}return fights===4&&clubBeasts().length===5&&G.gold>=375&&G.campaign.earnedGold===275&&!armoryUnlocked()&&UI.mode==='hub'})()");
test('selling cannot leave a club without its five starters',
 "(()=>{const before=JSON.stringify(G);ACT.sellok({id:G.clubs.P.roster[0]});return before===JSON.stringify(G)})()");
console.log('\n'+passed+' club desk checks passed.');

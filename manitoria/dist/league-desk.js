'use strict';

// The club desk and recruitment-first campaigns. Existing saves keep their economy.
const FOUNDING_GOLD=1200;
const FOUNDING_SIZE=5;
const PRACTICE_CLUBS=['The Old Keepers','The Practice Pack','The Gate Wardens','The Trial Champions'];
function foundingOpen(){return !!G?.recruitment&&G.clubs.P.roster.length<FOUNDING_SIZE}
function openingMarket(){
 for(const id of G.market)delete G.beasts[id];
 G.market=[];
 for(const line of ['front','flank','back']){
  const pool=shuffle(lineSpecies(line).slice());
  const anchor=line==='front'?pool.find(sp=>SPECIES[sp].role==='Tank'):line==='back'?pool.find(sp=>SPECIES[sp].role==='Support'):pool[0];
  for(const sp of [anchor,...pool.filter(sp=>sp!==anchor)].slice(0,4)){
   const b=genBeast(TIERS[0].q+rnd(-2,3),{sp,clubId:'MKT',age:ri(1,4)});
   initArenaHero(b,true);b.recruitFee=clamp(value(b),90,220);G.market.push(b.id);
  }
 }
}
const deskNewGame=newGame;
newGame=function(name,members,hue){
 deskNewGame(name,[],hue);
 G.recruitment={version:1,budget:FOUNDING_GOLD,signed:0};G.gold=FOUNDING_GOLD;
 G.lineups={1:[],2:[],3:[],5:[]};G.ledger=[];
 ledger('Founding recruitment fund',FOUNDING_GOLD);
 G.news=G.news.filter(n=>!n.text.includes('Eight beasts')&&!n.text.includes('Four preseason'));
 news(`The gates are open. ${FOUNDING_GOLD.toLocaleString('en-US')} gold is ready to recruit your first five heroes.`,'season');
 openingMarket();
 G.onboarding={version:2,active:false,step:'welcome',visited:[],complete:false};
};
const deskValue=value;
value=function(b){return b.clubId==='MKT'&&Number.isFinite(b.recruitFee)?b.recruitFee:deskValue(b)};
const deskGen=genBeast;
genBeast=function(...args){const b=deskGen(...args);if(G?.recruitment&&b.clubId==='MKT')initArenaHero(b,true);return b};
function recruitReason(b){
 if(!canManageClub()||!b||b.clubId!=='MKT'||!G.market.includes(b.id))return 'This hero is no longer available.';
 if(G.clubs.P.roster.length>=12)return 'Your roster is full.';
 if(G.gold<value(b))return 'Not enough gold.';
 if(foundingOpen()){
  const needed=FOUNDING_SIZE-G.clubs.P.roster.length-1;
  const rest=G.market.filter(id=>id!==b.id).map(id=>G.beasts[id]).filter(Boolean).map(value).sort((a,z)=>a-z);
  if(rest.length<needed||G.gold-value(b)<rest.slice(0,needed).reduce((n,v)=>n+v,0))return 'Keep enough gold for five starters.';
 }
 return '';
}
ACT.buy=d=>{
 const b=G?.beasts[d.id],reason=recruitReason(b);if(reason){toast(reason);return}
 const cost=value(b),wasFounding=foundingOpen();G.gold-=cost;ledger(`Signed ${b.name}`,-cost);
 G.market=G.market.filter(id=>id!==b.id);b.clubId='P';delete b.recruitFee;initArenaHero(b);
 b.joined=`Recruited in Season ${G.season}`;b.energy=100;b.notes.push({s:G.season,d:G.day+1,t:`signed for ${cost} gold`});
 G.clubs.P.roster.push(b.id);if(G.recruitment)G.recruitment.signed++;
 for(const n of [1,2,3,5])if((G.lineups[n]||[]).length<n)(G.lineups[n]||(G.lineups[n]=[])).push(b.id);
 news(`${b.name} the ${SPECIES[b.sp].n} joins ${G.name} for ${cost} gold.`,'signing');
 UI.modal=null;save();render();playCue('upgrade');if(wasFounding&&!foundingOpen())window.scrollTo(0,0);
 toast(wasFounding&&!foundingOpen()?'Your five starters are signed. Prepare your first bout.':`${b.name} signed · ${fmt(G.gold)} gold remaining.`);
};
for(const key of ['mrefresh','facility']){
 const previous=ACT[key];ACT[key]=d=>{if(foundingOpen()){toast('Recruit five starters before spending on scouts or facilities.');return}previous(d)};
}
const deskSell=ACT.sellok;ACT.sellok=d=>{if(!canManageClub()||G.beasts[d.id]?.clubId!=='P'||G.clubs.P.roster.length<=5)return;deskSell(d)};
const deskOpenNext=openNext;openNext=function(){if(foundingOpen()){UI.mode='hub';UI.tab='market';UI.modal=null;render();toast('Recruit your five starters, then prepare the first bout.');return}deskOpenNext()};
const deskStartMatch=startMatch;startMatch=function(watch){if(foundingOpen())return openNext();deskStartMatch(watch)};
const deskRefresh=refreshMarket;refreshMarket=function(full){if(foundingOpen()&&G.market.length)return;deskRefresh(full)};

function deskTimeline(){return `<div class="desk-timeline" aria-label="Season schedule">${G.sched.map((e,i)=>`<span class="${e.t} ${i<G.day?'played':''} ${i===G.day&&!inPreseason()?'current':''}" title="Day ${i+1}: ${esc(eventLabel(e))}${i<G.day?' · completed':''}"></span>`).join('')}</div>`}
renderTop=function(){
 const preseason=inPreseason();
 $('#top').innerHTML=`<div class="desk-brand">${crest(G.clubs.P,54)}<div><span class="lbl">${TIERS[G.tier].n} · DIV ${['IV','III','II','I'][G.tier]}</span><h1>${esc(G.name)}</h1></div></div><div class="desk-season"><strong>Season ${G.season} <span>· ${preseason?'Preseason':`Day ${G.day+1} / ${G.sched.length}`}</span></strong>${deskTimeline()}<small>${preseason?foundingOpen()?'Recruitment window open':`${G.campaign.preseason} / 4 proving-ground bouts complete`:'League fixtures · Cup days · Draft tournament'}</small></div><div class="desk-wallet"><span><small>GOLD</small><b class="gold">${fmt(G.gold)}</b></span><span><small>RENOWN</small><b>${fmt(G.renown)}</b></span><button class="btn sm" data-act="runMenu">Menu</button></div>`;
};
renderTabs=function(){
 const locked=['battle','result','draft','season','cupdone','levelup'].includes(UI.mode);
 const tabs=[['club','Overview'],['league','Matches'],['roster','Roster'],['academy','Club'],['market','Market'],['leaders','Intel']];
 const active=['shop','legacy'].includes(UI.tab)?'academy':UI.tab==='bestiary'?'leaders':UI.tab;
 $('#tabs').innerHTML=locked?'':tabs.map(([k,label])=>`<button class="tab ${UI.mode==='hub'&&active===k?'on':''}" data-act="tab" data-k="${k}" ${UI.mode==='hub'&&active===k?'aria-current="page"':''}>${label}${k==='market'&&foundingOpen()?'<i class="nav-dot"></i>':''}</button>`).join('')+(UI.mode==='prematch'?'<button class="tab on" data-act="toPrematch">Formation</button>':'');
};
function deskSubnav(group){const tabs=group==='club'?[['academy','Facilities'],...(armoryUnlocked()?[['shop','Armory']]:[]),['legacy','Club history']]:[['leaders','League impact'],['bestiary','Species guide']];return `<div class="desk-subnav">${tabs.map(([k,label])=>`<button class="btn sm ${UI.tab===k?'pri':''}" data-act="tab" data-k="${k}">${label}</button>`).join('')}${group==='club'?'<button class="btn sm" data-act="settings">Sound & club settings</button>':''}</div>`}
const deskAcademy=viewAcademy;viewAcademy=function(){return deskSubnav('club')+(foundingOpen()?'<section class="panel"><h2>First, build your team.</h2><p>Facilities become available after you recruit five starters.</p><button class="btn pri" data-act="tab" data-k="market">Recruit heroes →</button></section>':deskAcademy())};
const deskShop=viewShop;viewShop=function(){return deskSubnav('club')+(clubBeasts().length?deskShop():'<p class="empty">Recruit a hero before opening the Armory.</p>')};
const deskLegacy=viewLegacy;viewLegacy=function(){return deskSubnav('club')+deskLegacy()};
const deskBestiary=viewBestiary;viewBestiary=function(){return deskSubnav('intel')+deskBestiary()};

function nextDeskMatch(){
 if(inPreseason()){
  const i=G.campaign.preseason,t=TRIALS[i];
  return {label:`PRESEASON · BOUT ${i+1} / 4`,title:t.name,fmt:t.fmt,opp:{name:PRACTICE_CLUBS[i],hue:172,emblem:'shield'},rivals:t.species.map(sp=>({sp,name:SPECIES[sp].n})),reward:`${t.reward} gold · win or lose`,practice:true};
 }
 const e=curEvent();if(!e)return {label:'SEASON COMPLETE',title:'A chapter in the club history',fmt:5,rivals:[]};
 if(e.t==='league'){const opp=G.clubs[leagueOpp(e.r)];return {label:'REGULAR SEASON',title:`League matchday ${e.r+1}`,fmt:5,opp,rivals:pickLineup(opp.id,5),reward:'Gold, experience & league points'}}
 const c=G.cup,pr=c&&!c.champ&&!c.out?c.rounds[c.ri].find(p=>p.includes('P')):null,opp=pr?G.clubs[pr.find(id=>id!=='P')]:null;
 return {label:e.t==='draft'?'DRAFT TOURNAMENT':'CUP DAY',title:eventLabel(e),fmt:e.fmt||5,opp,rivals:opp?teamFor(opp.id,c.fmt,c.draft):[],reward:e.t==='draft'?'Draft five loaned heroes · Compete for the cup':'A new draw. A chance at silverware.',draft:e.t==='draft'};
}
function deskLineup(n){
 const saved=(G.lineups[n]||[]).map(id=>G.beasts[id]).filter(b=>b&&b.clubId==='P'&&!b.inj);
 const all=pickLineup('P',n);return saved.concat(all.filter(b=>!saved.includes(b))).slice(0,n);
}
function deskTeamStrip(beasts,n,emptyLabel='Recruit hero'){
 return `<div class="desk-team-strip">${Array.from({length:n},(_,i)=>{const b=beasts[i];return b?`<${b.id?'button':'div'} class="desk-fighter" ${b.id?`data-act="profile" data-id="${b.id}"`:''}>${beastArt(b.sp)}<b>${esc(b.name)}</b><small>${b.id?'Lv '+b.lvl:SPECIES[b.sp].role}</small></${b.id?'button':'div'}>`:`<button class="desk-empty-slot" data-act="tab" data-k="market" aria-label="${emptyLabel} ${i+1}"><span>+</span><small>${emptyLabel}</small></button>`}).join('')}</div>`;
}
function deskClubMeta(c){const row=standings().find(r=>r.id===c?.id);return row?`DIV ${['IV','III','II','I'][G.tier]} · ${row.p?`RANK #${standings().findIndex(r=>r.id===c.id)+1} · ${row.w}W–${row.l}L`:'Awaiting league debut'}`:'THE PROVING GROUNDS'}
function deskTrophy(){return `<svg class="desk-trophy" viewBox="0 0 120 150" fill="none" aria-hidden="true"><path d="M33 28H13v20c0 21 14 32 32 32m42-52h20v20c0 21-14 32-32 32" stroke="currentColor" stroke-width="5"/><path d="M31 17h58v37c0 22-12 39-29 45-17-6-29-23-29-45Z" fill="#c1a46c19" stroke="currentColor" stroke-width="2"/><path d="M38 24h44M52 99v21H37l-7 17h60l-7-17H68V99M27 143h66" stroke="currentColor" stroke-width="3"/><path d="m60 37 5 12 13 1-10 9 3 13-11-7-11 7 3-13-10-9 13-1Z" fill="currentColor"/><circle cx="60" cy="58" r="29" stroke="currentColor" stroke-opacity=".3"/></svg>`}
function deskMatchHero(){
 const m=nextDeskMatch(),recruit=foundingOpen(),ours=deskLineup(recruit?5:m.fmt),ownScore=ours.reduce((n,b)=>n+ovr(b),0),rivalScore=m.rivals.reduce((n,b)=>n+(b.id?ovr(b):0),0);
 const danger=rivalScore&&ownScore?rivalScore>ownScore*1.12?'TOUGH OPPONENT':rivalScore<ownScore*.88?'YOUR EDGE':'CLOSE CONTEST':null;
 return `<section class="desk-match"><div class="desk-match-title"><span class="lbl gold">${recruit?'THE FOUNDING WINDOW':m.label}</span><h2>${recruit?'A club is built. One signing at a time.':m.title}</h2></div><div class="desk-match-grid"><div class="desk-side">${crest(G.clubs.P,78)}<h3>${esc(G.name)}</h3><p>${deskClubMeta(G.clubs.P)}</p><span class="desk-power">${recruit?`${ours.length} / 5 STARTERS SIGNED`:`COMBINED OVR <b>${ownScore}</b>`}</span>${deskTeamStrip(ours,recruit?5:m.fmt)}</div><div class="desk-prize">${deskTrophy()}<strong>${recruit?'THE FIRST CHAPTER':m.fmt+'v'+m.fmt+' · AUTOBATTLE'}</strong><span>${recruit?`${fmt(G.gold)} gold to build your team`:m.reward}</span>${danger&&!recruit?`<i class="match-danger">${danger}</i>`:''}</div><div class="desk-side desk-rival">${m.opp?crest(m.opp,78):'<div class="draw-emblem">?</div>'}<h3>${m.opp?esc(m.opp.name):'Draw to be revealed'}</h3><p>${m.opp?deskClubMeta(m.opp):'Your rivals await the cup draw'}</p><span class="desk-power">${rivalScore?`COMBINED OVR <b>${rivalScore}</b>`:m.practice?'PRACTICE RIVALS':'CUP DRAW PENDING'}</span>${m.rivals.length?deskTeamStrip(m.rivals,m.fmt):'<p class="draw-note">Open the next event to meet your challenger.</p>'}</div></div><div class="desk-match-caption">${recruit?'Choose five starters in the Market. Try a frontliner, damage dealers, and a support.':m.draft?'The draft cup supplies its own lineup. Your club roster rests.':`${ours.length} / ${m.fmt} selected · Prepare your formation before entering the arena.`}</div></section>`;
}
function leagueImpactRows(metric='imp',perBout=false){
 const seen=new Set();return G.div.flatMap(cid=>(G.clubs[cid]?.roster||[]).map(id=>G.beasts[id])).filter(b=>b&&!seen.has(b.id)&&seen.add(b.id)).map(b=>({b,score:perBout?(b.season.m?b.season[metric]/b.season.m:0):b.season[metric]||0})).sort((a,z)=>(z.b.season.m>0)-(a.b.season.m>0)||z.score-a.score||z.b.season.m-a.b.season.m||a.b.name.localeCompare(z.b.name));
}
function impactList(limit=5){const rows=leagueImpactRows().slice(0,limit);return `<div class="impact-list">${rows.map(({b,score},i)=>`<button class="impact-row ${b.clubId==='P'?'your-hero':''}" data-act="profile" data-id="${b.id}"><span class="impact-rank">${b.season.m?String(i+1).padStart(2,'0'):'—'}</span>${beastArt(b.sp)}<span class="impact-name"><b>${esc(b.name)}</b><small>${esc(clubName(b.clubId))}${b.clubId==='P'?' · YOUR CLUB':''}</small></span><span class="impact-score"><b>${b.season.m?score.toFixed(1):'—'}</b><small>${b.season.m?`${b.season.m} bouts`:'No bouts'}</small></span></button>`).join('')}</div>`}
function deskAgenda(){
 const heroes=clubBeasts(),injured=heroes.filter(b=>b.inj||b.energy<50),lines=new Set(heroes.map(b=>ROLE_LINE[roleOf(b)])),missing=['front','flank','back'].filter(l=>!lines.has(l));
 const rows=[];
 if(foundingOpen())rows.push(['01',`Recruit your starters · ${heroes.length} / 5`,`${fmt(G.gold)} gold available. Every signing is your choice.`,'Market','market']);
 else rows.push(['01','Your next match awaits',`${nextDeskMatch().fmt} heroes will enter. Check the formation and captain’s tactics.`,'Prepare','next']);
 if(injured.length)rows.push(['02',`${injured.length} heroes need recovery`,'Rotate tired or injured heroes before the next bout.','Roster','roster']);
 else if(missing.length)rows.push(['02','Build a balanced lineup',`Consider a ${missing.map(l=>({front:'frontliner',flank:'flanker',back:'back-line hero'}[l])).join(', ')}.`,'Scout','market']);
 else rows.push(['02','Your roles are covered','Frontline, flank, and backline options. Tune how they fight.','Roster','roster']);
 if(!armoryUnlocked())rows.push(['03','Earn access to the Armory',`${Math.min(300,campaignState().earnedGold)} / 300 arena gold. Recruitment funds do not count.`,'Guide','guide']);
 else rows.push(['03','The Armory is open','Your arena earnings unlocked equipment. Buy a piece and equip it.','Armory','shop']);
 return `<section class="desk-panel"><div class="desk-panel-heading"><h3>Club agenda</h3><span class="lbl">YOUR NEXT MOVES</span></div>${rows.map(([n,title,copy,label,act])=>`<div class="agenda-row"><span class="agenda-number">${n}</span><div><b>${title}</b><p>${copy}</p></div><button class="btn sm" data-act="${act==='next'?'next':act==='guide'?'keeperStart':'tab'}" ${['next','guide'].includes(act)?'':`data-k="${act}"`}>${label} →</button></div>`).join('')}</section>`;
}
function deskFeed(){return `<section class="desk-panel desk-feed"><div class="desk-panel-heading"><h3>Around the club</h3><span class="lbl">LATEST NEWS</span></div><div class="desk-feed-list">${G.news.slice(0,5).map(n=>`<div class="desk-news"><span class="news-sigil">${n.kind==='signing'?'+':n.kind==='win'?'↗':'◇'}</span><p>${esc(n.text)}</p><time>S${n.s} · D${n.d}</time></div>`).join('')}</div></section>`}
function deskObjectives(){const wins=standings().find(r=>r.id==='P')?.w||0,played=clubBeasts().some(b=>b.career.m),items=[['Build your starting five',Math.min(5,clubBeasts().length),5,'Recruit heroes from the Market.'],['Make your arena debut',played?1:0,1,'Fight your first proving-ground bout.'],['Win four league matches',Math.min(4,wins),4,'Build momentum in the regular season.']];return `<section class="desk-panel desk-objectives"><div class="desk-panel-heading"><h3>Season objectives</h3><span class="lbl">SEASON ${G.season}</span></div><div class="objective-grid">${items.map(([title,n,total,copy])=>`<div class="desk-objective"><span class="objective-status ${n===total?'done':''}">${n===total?'✓ COMPLETE':`${n} / ${total}`}</span><h4>${title}</h4><p>${copy}</p><div class="bar"><i style="width:${n/total*100}%"></i></div></div>`).join('')}</div></section>`}
function deskDock(){const need=foundingOpen();return `<div class="desk-dock"><button class="linkbtn" data-act="keeperStart">Quick start guide</button><div><small>${need?'THE FOUNDING WINDOW':nextDeskMatch().label}</small><button class="btn pri" data-act="${need?'tab':'next'}" ${need?'data-k="market"':''}>${need?'Recruit your starters':'Prepare next match'} <span>→</span></button></div><button class="linkbtn" data-act="runMenu">Save & menu</button></div>`}
viewClub=function(){return `<div class="league-desk">${deskMatchHero()}<div class="desk-columns">${deskAgenda()}<section class="desk-panel desk-impact"><div class="desk-panel-heading"><h3>League impact</h3><button class="linkbtn" data-act="tab" data-k="leaders">Full rankings ↗</button></div><p class="desk-impact-note">${leagueImpactRows().some(x=>x.b.season.m)?'Season contribution · all arena bouts':'A new season. Impact scores begin with the first arena appearances.'}</p>${impactList(4)}</section></div>${deskFeed()}${deskObjectives()}${deskDock()}</div>`};

viewLeaders=function(){
 const metric=LEADS.some(([k])=>k===UI.lead)?UI.lead:'imp',perBout=UI.impactMode==='average',rows=leagueImpactRows(metric,perBout),label=LEADS.find(([k])=>k===metric)[1];
 return `${deskSubnav('intel')}<div class="section-heading"><div><span class="lbl gold">SEASON ${G.season} · ${TIERS[G.tier].n}</span><h2>Every hero. Every contribution.</h2><p class="note">All clubs in your division · real results from this season’s arena bouts.</p></div></div><div class="intel-controls"><div class="seg">${LEADS.map(([k,n])=>`<button data-act="lead" data-k="${k}" class="${metric===k?'on':''}">${n}</button>`).join('')}</div><div class="seg" aria-label="Ranking basis"><button data-act="impactMode" data-k="total" class="${!perBout?'on':''}">Season total</button><button data-act="impactMode" data-k="average" class="${perBout?'on':''}">Per bout</button></div></div><section class="desk-panel intel-table"><div class="tw"><table><thead><tr><th>#</th><th>Hero / Club</th><th>Role</th><th class="n">Bouts</th><th class="n">${label}${perBout?' / bout':''}</th><th class="n">${perBout?'Total':'Per bout'}</th></tr></thead><tbody>${rows.map(({b,score},i)=>`<tr class="${b.clubId==='P'?'me':''}"><td>${b.season.m?i+1:'—'}</td><td><button class="intel-hero" data-act="profile" data-id="${b.id}">${beastArt(b.sp)}<span><b>${esc(b.name)}</b><small>${esc(clubName(b.clubId))}${b.clubId==='P'?' · YOUR CLUB':''}</small></span></button></td><td>${SPECIES[b.sp].role}</td><td class="n">${b.season.m}</td><td class="n"><b>${b.season.m?score.toFixed(1):'—'}</b></td><td class="n">${b.season.m?(perBout?b.season[metric]:b.season[metric]/b.season.m).toFixed(1):'—'}</td></tr>`).join('')}</tbody></table></div><p class="note">Unplayed heroes are unranked. Impact rewards damage, damage absorbed, healing, takedowns, assists and control; deaths reduce the score.</p><details class="impact-formula"><summary>How impact is scored</summary><p>Damage ÷ 60 + absorbed ÷ 150 + healing & shields ÷ 45 + takedowns × 4 + assists × 2 + control seconds × 2.5 − deaths × 1.5. The table includes preseason and cup appearances. Totals reset each season.</p></details></section>`;
};
ACT.impactMode=d=>{UI.impactMode=d.k==='average'?'average':'total';render()};
ACT.marketFilter=d=>{UI.marketLine=d.k;render()};
function recruitCard(b){const reason=recruitReason(b),role=SPECIES[b.sp].role;return `<article class="recruit-card"><button class="recruit-portrait" data-act="profile" data-id="${b.id}" aria-label="Scout ${esc(b.name)}"><span class="recruit-role">${role}</span>${beastArt(b.sp)}<span class="recruit-rating"><b>${ovr(b)}</b>OVR</span></button><div class="recruit-info"><h3>${esc(b.name)}</h3><p>${SPECIES[b.sp].n} · Level ${b.lvl} · ${potRange(b)} potential</p><span class="recruit-signature">${ABINFO[SPECIES[b.sp].ab][0]}</span><div class="recruit-stats"><span>${upkeep(b)} gold upkeep / day</span><span>${b.career.m?`${(b.career.imp/b.career.m).toFixed(1)} career impact / bout`:'Arena debut awaits'}</span></div><div class="recruit-actions"><button class="linkbtn" data-act="profile" data-id="${b.id}">Scout hero</button><button class="btn pri sm" data-act="buy" data-id="${b.id}" ${reason?'disabled':''}>Recruit · ${fmt(value(b))}g</button></div>${reason?`<small class="recruit-reason">${reason}</small>`:''}</div></article>`}
viewMarket=function(){
 const founding=foundingOpen(),filter=UI.marketLine||'all',heroes=clubBeasts(),market=G.market.map(id=>G.beasts[id]).filter(Boolean),listed=market.filter(b=>filter==='all'||ROLE_LINE[roleOf(b)]===filter);
 return `<div class="recruit-market"><section class="recruit-banner"><div><span class="lbl gold">${founding?'BUILD YOUR FOUNDING FIVE':'THE RECRUITMENT DESK'}</span><h2>${founding?'Your gold. Your team.':'Find your next difference maker.'}</h2><p>${founding?'Choose five starters. All opening recruits begin at level one with their signature ability.':'Scout roles, potential and abilities. New heroes earn upgrade choices by leveling up in the arena.'}</p></div><div class="recruit-budget"><small>AVAILABLE GOLD</small><b>${fmt(G.gold)}</b><span>${heroes.length} / ${founding?5:12} heroes signed</span></div></section><div class="recruit-progress" data-guide="recruitment"><div>${['front','flank','back'].map(line=>`<span class="${heroes.some(b=>ROLE_LINE[roleOf(b)]===line)?'filled':''}">${heroes.some(b=>ROLE_LINE[roleOf(b)]===line)?'✓':'○'} ${ {front:'Front line',flank:'Flank pressure',back:'Back line'}[line]}</span>`).join('')}</div><span>${founding?`${5-heroes.length} more to open the arena`:'Your roster is ready'}${!founding?'<button class="btn pri sm" data-act="next">Prepare next match →</button>':''}</span></div><div class="market-toolbar"><div class="seg" aria-label="Filter recruits">${[['all','All heroes'],['front','Front line'],['flank','Flank'],['back','Back line']].map(([k,n])=>`<button class="${filter===k?'on':''}" data-act="marketFilter" data-k="${k}">${n}</button>`).join('')}</div>${founding?'<span class="note">Opening listings stay until your team is signed.</span>':`<button class="btn sm" data-act="mrefresh" ${G.gold<25?'disabled':''}>New scouts · 25 gold</button>`}</div><div class="recruit-grid">${listed.map(recruitCard).join('')||'<p class="empty">No heroes in this role. Try another filter or send new scouts.</p>'}</div><p class="note">Click Scout hero to inspect the animated model, attributes and signature. Equipment unlocks through arena earnings.</p></div>`;
};
const deskRoster=viewRoster;viewRoster=function(){return clubBeasts().length?deskRoster():`<section class="panel empty-roster">${deskTrophy()}<span class="lbl gold">A NEW CLUB. AN OPEN ROSTER.</span><h2>Your first signing starts the story.</h2><p>${fmt(G.gold)} gold is ready. Recruit five heroes to build your starting lineup.</p><button class="btn pri" data-act="tab" data-k="market">Explore the recruitment market →</button></section>`};
const deskProfile=modalProfile;modalProfile=function(m){let h=deskProfile(m);const b=G.beasts[m.id];if(b?.clubId==='MKT'){const reason=recruitReason(b);if(reason)h=h.replace(/(<button[^>]*data-act="buy"[^>]*)(>)/,'$1 disabled$2');h=h.replace('Sign for ','Recruit for ')}return h};
viewIntro=function(){return `<button class="linkbtn back-menu" data-act="runHome">← Main menu</button><div class="intro stack recruitment-intro"><div class="founding-heading"><span class="lbl gold">THE FOUNDING CHARTER</span><h1>Give the league a new name.</h1><p>A crest. A recruitment fund. A team you choose yourself.</p></div>${identityDesigner(UI.intro)}<section class="founding-budget"><div><span class="lbl gold">YOUR STARTING FUND</span><strong>${fmt(FOUNDING_GOLD)} <small>gold</small></strong></div><p>Recruit five starters from the Market. Every hero begins with a signature ability; new upgrades are earned through arena level-ups.</p><button class="btn pri" data-act="introStart">Found club & recruit →</button></section><p class="note">This creates a separate campaign. Your existing saves stay available.</p></div>`};
const deskIntroStart=ACT.introStart;ACT.introStart=()=>{UI.marketLine='all';deskIntroStart()};
const deskMenu=viewRunMenu;viewRunMenu=function(){return deskMenu().replace('Build a team. Earn every upgrade in the arena.','Start with 1,200 gold. Recruit your own founding five.').replace('CAMPAIGNS · 3.2','THE BEASTS · 3.5')};
const deskSaveStage=saveStage;saveStage=function(game){return game.recruitment&&game.clubs.P.roster.length<5?`Recruiting · ${game.clubs.P.roster.length} / 5 starters`:deskSaveStage(game)};
// Keep the short guide useful for a recruitment-first opening.
KEEPER_STEPS[0]={id:'welcome',label:'Recruit your first five',target:'.recruit-progress',copy:'Open the Market and choose five heroes. A frontliner, damage dealers and support make a balanced start.'};
KEEPER_STEPS[1].copy='Drag your heroes onto formation tiles. Tough heroes in front; fragile allies behind.';
const deskKeeperNavigate=keeperNavigate;keeperNavigate=function(){if(keeperAvailable()&&keeperState()?.active&&keeperStep().id==='welcome'){UI.modal=null;UI.mode='hub';UI.tab='market';keeperScroll=true;render();return}deskKeeperNavigate()};
const deskKeeperNext=ACT.keeperNext;ACT.keeperNext=()=>{if(keeperStep().id==='welcome'&&foundingOpen()){keeperNavigate();toast('Recruit five heroes before the formation step.');return}deskKeeperNext()};
// The report returns to the overview, so recruitment, recovery and scouting stay in the loop.
ACT.resnext=()=>{if(openRewardCards())return;UI.modal=null;resultNext()};
const deskViewResult=viewResult;viewResult=function(){return deskViewResult().replace('Prepare next match →','Return to club overview →')};

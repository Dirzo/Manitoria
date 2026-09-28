'use strict';
// Committed attacks, stable targets, and enough room to read the fight.
const ARENA_BOUNDS={left:60,right:1220,top:92,bottom:682};
clampArena=function(u){u.x=clamp(u.x,ARENA_BOUNDS.left+u.r,ARENA_BOUNDS.right-u.r);u.y=clamp(u.y,ARENA_BOUNDS.top+u.r,ARENA_BOUNDS.bottom-u.r)};
const combatPickTarget=pickTarget;
pickTarget=function(S,u){
 let choice=combatPickTarget(S,u);if(!choice)return null;
 const current=u.target,valid=current?.alive&&current.team!==u.team&&current.s.stealth<=0;
 const forced=u.behavior?.commitment==='opportunist'&&choice.hp/choice.maxHp<.3||u.behavior?.teamwork==='close'&&choice.target?.line==='back';
 if(valid&&choice!==current&&!forced&&u.behavior?.commitment!=='flexible'&&u.tac.target==='nearest'){
  if(dist(u,current)<=u.range+u.r+current.r+26||dist(u,choice)>dist(u,current)-65)return current;
 }
 // Approach separate opponents when two equally accessible targets exist.
 if(!valid&&u.range<80&&u.tac.target==='nearest'&&!forced&&!choice.lure){
  const score=v=>dist(u,v)+S.units.filter(a=>a.alive&&a.team===u.team&&a!==u&&a.range<80&&a.target===v).length*24;
  choice=enemiesOf(S,u).filter(v=>dist(u,v)<dist(u,choice)+90).sort((a,b)=>score(a)-score(b))[0]||choice;
 }
 return choice;
};
function meleeApproach(S,u,target){
 const angle=Math.atan2(u.y-target.y,u.x-target.x),radius=u.r+target.r+Math.min(u.range,24)*.65;
 const options=[0,.55,-.55,1.05,-1.05].map(offset=>{
  const a=angle+offset,p={x:target.x+Math.cos(a)*radius,y:target.y+Math.sin(a)*radius,r:u.r};clampArena(p);
  const crowd=S.units.filter(v=>v!==u&&v!==target&&v.alive).reduce((n,v)=>n+Math.max(0,u.r+v.r+14-dist(p,v))*4,0);
  return {...p,cost:dist(u,p)+crowd};
 });return options.sort((a,b)=>a.cost-b.cost)[0];
}
function moveCombatant(S,u,mx,my,dt){
 if(u.s.root>0){u.vx=u.vy=0;return}
 const moving=Math.hypot(mx,my)>.03;
 if(moving){
  for(const v of S.units){if(v===u||!v.alive||v===u.target)continue;const d=dist(u,v),space=u.r+v.r+(u.team===v.team?18:8);if(d<space&&d>.01){const force=(space-d)/space;mx+=(u.x-v.x)/d*force;my+=(u.y-v.y)/d*force}}
  const margin=36;if(u.x<ARENA_BOUNDS.left+margin)mx+=.6;if(u.x>ARENA_BOUNDS.right-margin)mx-=.6;if(u.y<ARENA_BOUNDS.top+margin)my+=.6;if(u.y>ARENA_BOUNDS.bottom-margin)my-=.6;
 }
 const length=Math.hypot(mx,my);if(length>1){mx/=length;my/=length}
 const speed=u.mv*(u.s.slow>0?u.s.slowMul:1)*(u.s.hasteT>0?u.s.haste:1),smooth=1-Math.exp(-dt*(moving?12:22));
 u.vx=(u.vx||0)+(mx*speed-(u.vx||0))*smooth;u.vy=(u.vy||0)+(my*speed-(u.vy||0))*smooth;
 const velocity=Math.hypot(u.vx,u.vy);if(velocity>2){u.x+=u.vx*dt;u.y+=u.vy*dt;u.moved=.12;u.walk+=velocity*dt;clampArena(u)}else{u.vx=u.vy=0}
}
function beginAutoAttack(S,u,target){
 const period=1/(u.as*(u.s.hasteT>0?u.s.haste:1)),windup=clamp(period*.24,.12,.34);
 u.strike={target,remaining:windup,duration:windup,raw:u.atk};u.atkT=period;u.animAtk=.32;u.vx=u.vy=0;u.face=target.x>=u.x?1:-1;u.intent=u.range>60?'Aiming':'Winding up';
}
function releaseAutoAttack(S,u,strike){
 const target=strike.target;if(!target.alive||target.s.stealth>0)return false;
 if(u.range<=60&&dist(u,target)>u.range+u.r+target.r+14)return false;
 const hits=u.double&&Math.random()<u.double?2:1;
 for(let i=0;i<hits;i++){
  if(!target.alive)break;
  if(u.range>60)S.proj.push({x:u.x,y:u.y-i*5,t:target,src:u,raw:strike.raw,spd:u.role==='Artillery'?365:430,sp:u.sp,c:`hsl(${u.hue} 65% 73%)`});
  else{atkHit(S,u,target,strike.raw);if(u.cleave)enemiesOf(S,u).filter(v=>v!==target&&dist(target,v)<48).forEach(v=>hit(S,u,v,strike.raw*u.cleave));if(u.slowHit&&target.alive)slow(S,u,target,.7,1.2);fx(S,{k:'slash',x:target.x,y:target.y,r:target.r+8,a:Math.atan2(u.y-target.y,u.x-target.x)+i*.5,c:u.team===0?'#dbeac3':'#e7a39b',ttl:.22})}
 }
 u.animAtk=.17;u.recover=.08;u.intent=u.range>60?'Firing':'Striking';return true;
}
think=function(S,u,dt){
 const s=u.s;u.atkT=Math.max(0,u.atkT-dt);u.cdT=Math.max(0,u.cdT-dt);u.castLock=Math.max(0,(u.castLock||0)-dt);u.recover=Math.max(0,(u.recover||0)-dt);
 if(s.stun>0){u.strike=null;u.vx=u.vy=0;u.intent='Stunned';return}
 if(u.channel&&s.silence<=0){u.strike=null;u.vx=u.vy=0;u.intent='Channeling';return}
 if(u.strike){
  const strike=u.strike;u.vx=u.vy=0;
  if(!strike.target.alive||strike.target.s.stealth>0||(s.taunt>0&&s.tauntBy?.alive&&s.tauntBy!==strike.target)){u.strike=null;return}
  strike.remaining-=dt;if(strike.remaining<=0){u.strike=null;releaseAutoAttack(S,u,strike)}return;
 }
 if(u.dash){
  const d=u.dash,t=d.t;d.time-=dt;u.intent='Dashing';if(!t.alive||d.time<=0){u.dash=null;return}
  const distance=dist(u,t),reach=u.r+t.r+4;if(distance<=reach){d.cb();if(IMPACT[d.ab]&&!S.headless)IMPACT[d.ab](S,u,t);u.dash=null;u.atkT=.3;u.vx=u.vy=0;return}
  const amount=Math.min(distance-reach+.1,d.speed*dt);u.vx=(t.x-u.x)/distance*d.speed;u.vy=(t.y-u.y)/distance*d.speed;u.x+=(t.x-u.x)/distance*amount;u.y+=(t.y-u.y)/distance*amount;u.moved=.12;u.walk+=amount;u.face=t.x>=u.x?1:-1;clampArena(u);if(!S.headless)dashTrail(S,u,d.ab);return;
 }
 if(u.castLock>0||u.recover>0){u.vx=u.vy=0;u.intent=u.castLock>0?'Casting':'Recovering';return}
 if(S.t<(u.opening||0)&&s.taunt<=0&&s.confuse<=0){const enemy=nearestEnemy(S,u);if(!enemy||dist(u,enemy)>u.range+u.r+enemy.r){u.target=pickTarget(S,u);u.vx=u.vy=0;u.intent='Holding formation';return}}
 u.retT-=dt;
 if(s.confuse>0){const allies=S.units.filter(v=>v.alive&&v.team===u.team&&v!==u);u.target=allies.sort((a,b)=>dist(u,a)-dist(u,b))[0]||null}
 else if(s.taunt>0&&s.tauntBy?.alive)u.target=s.tauntBy;
 else if(!u.target?.alive||u.target.team===u.team||u.target.s.stealth>0||u.retT<=0){u.target=pickTarget(S,u);u.retT=u.behavior?.commitment==='flexible'?.35:1.15}
 if(!u.target){u.intent='Searching';moveCombatant(S,u,0,0,dt);return}
 const partner=u.partnerU,stance=u.tac.stance;
 if(s.confuse<=0&&s.taunt<=0&&partner?.alive){
  if(stance==='assist'&&partner.target?.alive&&partner.target.team!==u.team&&partner.target.s.stealth<=0)u.target=partner.target;
  if(stance==='guard'){const threat=enemiesOf(S,u).filter(v=>dist(v,partner)<170).sort((a,b)=>dist(a,partner)-dist(b,partner))[0];if(threat)u.target=threat}
 }
 if(u.ab&&u.tac.ability!=='disabled'&&u.cdT<=0&&s.silence<=0&&s.confuse<=0&&s.stealth<=0){
  if(gate(S,u)&&ABIL[u.ab](S,u,u.tac.ability==='group'&&AOE.has(u.ab)?2:1)){
   u.cdT=u.cd;u.animCast=.45;u.castLock=.28;u.vx=u.vy=0;u.intent='Casting';if(!S.headless&&CAST[u.ab])CAST[u.ab](S,u);
   if(u.echo&&Math.random()<u.echo){u.cdT=.6;fx(S,{k:'txt',x:u.x,y:u.y-40,s:'ECHO',c:'#cfa4ef',z:12,ttl:1})}
   if(!S.headless)fx(S,{k:'txt',x:u.x,y:u.y-34,s:ABINFO[u.ab][0],c:'#a5cddb',z:11,ttl:1});return;
  }u.cdT=.25;
 }
 const target=u.target;if(!target?.alive)return;
 const distance=dist(u,target)||1,reach=u.range+u.r+target.r,ranged=u.range>80,near=nearestEnemy(S,u);
 let mx=0,my=0,urgent=false;u.intent='Holding range';
 const retreat=(u.tac.retreatAt||0)>0&&u.hp/u.maxHp<u.tac.retreatAt/100&&!u.summon&&near&&dist(u,near)<190;
 const diver=ranged&&u.tac.kite&&s.taunt<=0&&s.confuse<=0?enemiesOf(S,u).filter(v=>v.range<80&&v.s.stun<=0&&dist(u,v)<u.range*.62+u.r+v.r).sort((a,b)=>dist(u,a)-dist(u,b))[0]:null;
 if(retreat||diver){const threat=retreat?near:diver,d=dist(u,threat)||1;[mx,my]=safeDir(S,u,threat,(u.x-threat.x)/d,(u.y-threat.y)/d);urgent=d<threat.r+u.r+threat.range+12;u.intent='Kiting'}
 else if(stance==='guard'&&partner?.alive&&s.confuse<=0&&s.taunt<=0&&dist(target,partner)>=170&&dist(u,partner)>62){const d=dist(u,partner);mx=(partner.x-u.x)/d;my=(partner.y-u.y)/d;u.intent='Protecting ally'}
 else if(stance==='hold'&&s.confuse<=0&&s.taunt<=0&&Math.hypot(target.x-u.ax,target.y-u.ay)>u.range+200){const d=Math.hypot(u.x-u.ax,u.y-u.ay);if(d>12){mx=(u.ax-u.x)/d;my=(u.ay-u.y)/d}u.intent='Holding ground'}
 else if(distance>reach-8){const destination=ranged?target:meleeApproach(S,u,target),d=dist(u,destination)||1;mx=(destination.x-u.x)/d;my=(destination.y-u.y)/d;u.intent='Engaging'}
 if(distance<=reach+2&&u.atkT<=0&&s.stealth<=0&&!urgent){beginAutoAttack(S,u,target);return}
 moveCombatant(S,u,mx,my,dt);u.face=target.x>=u.x?1:-1;
};
function separateCombatants(S){
 const live=S.units.filter(u=>u.alive);
 for(let pass=0;pass<2;pass++)for(let i=0;i<live.length;i++)for(let j=i+1;j<live.length;j++){
  const a=live[i],b=live[j];if(a.dash||b.dash)continue;
  let dx=b.x-a.x,dy=b.y-a.y,d=Math.hypot(dx,dy);const min=a.r+b.r+(a.summon||b.summon?3:10);
  if(d>=min)continue;if(d<.001){const angle=(a.id*2.399+b.id)*1.7;dx=Math.cos(angle);dy=Math.sin(angle);d=1}
  const push=(min-d)*.5;a.x-=dx/d*push;a.y-=dy/d*push;b.x+=dx/d*push;b.y+=dy/d*push;clampArena(a);clampArena(b);
 }
}
const readableStep=step;step=function(S,dt){readableStep(S,dt);separateCombatants(S)};
// Quick results use the same time step as watched bouts.
runHeadless=function(S){const before=S.headless;S.headless=true;let ticks=0;while(!S.done&&ticks++<12000)step(S,1/60);S.headless=before};

const MULTIKILL_WINDOW=6;
const MULTIKILL_NAMES={2:'DOUBLE KILL',3:'TRIPLE KILL',4:'QUADRA KILL',5:'TEAM SWEEP'};
const multikillDeath=die;die=function(S,v,killer){
 if(!v.alive)return;multikillDeath(S,v,killer);if(v.alive||v.summon)return;
 const k=cred(S,killer);if(!k||k.team===v.team)return;
 k.killChain=S.t-(k.lastKillAt??-Infinity)<=MULTIKILL_WINDOW?(k.killChain||0)+1:1;k.lastKillAt=S.t;
 k.bestChain=Math.max(k.bestChain||0,k.killChain);
 if(k.killChain<2)return;
 const label=MULTIKILL_NAMES[Math.min(5,k.killChain)],announcement={bid:k.bid,name:k.name,sp:k.sp,team:k.team,count:k.killChain,label,at:S.t};
 S.killAnnouncement=announcement;S.highlights=S.highlights||[];const last=S.highlights.find(h=>h.bid===k.bid);if(last){if(last.count<announcement.count)Object.assign(last,announcement)}else S.highlights.push({...announcement});
 S.feed.push({txt:`${k.name} · ${label}`,team:k.team});if(!S.headless&&BT?.S===S&&typeof playMultikill==='function')playMultikill(k.killChain,k.team);
};
const multikillFinish=finishMatch;finishMatch=function(S){const before=UI.result;multikillFinish(S);if(UI.result===before||!UI.result||!S.highlights?.length)return;UI.result.highlights=S.highlights.map(x=>({...x}));save();render()};
const highlightResult=viewResult;viewResult=function(){let html=highlightResult();const highlights=UI.result?.highlights;if(!highlights?.length)return html;return html.replace('</section>',`</section><section class="panel bout-highlights"><span class="lbl gold">MOMENTS OF THE MATCH</span>${highlights.map(h=>`<div>${beastArt(h.sp)}<strong>${h.label}<small>${esc(h.name)} · ${h.team?'Rival club':'Your club'}</small></strong><span>${h.count} hero kills in a chain</span></div>`).join('')}</section>`)};

function combatStatus(u){return !u.alive?'Fallen':u.s.stun>0?'Stunned':u.s.silence>0?'Silenced':u.s.root>0?'Rooted':u.s.shield>0?'Shielded':u.s.poison>0?'Poisoned':u.s.burn>0?'Burning':u.intent||'Ready'}
function combatHudUnit(u){return `<button class="combat-unit ${u.team?'enemy':''} ${u.alive?'':'fallen'} ${UI.battleInspect===u.id?'inspected':''}" data-act="battleInspect" data-id="${u.id}" aria-label="Inspect ${esc(u.name)}"><span class="combat-unit-name">${esc(u.name)}</span><span class="combat-hp"><i style="width:${clamp(u.hp/u.maxHp*100,0,100)}%"></i></span><span class="combat-charge"><i style="width:${(1-clamp(u.cdT/u.cd,0,1))*100}%"></i></span><small>${combatStatus(u)}</small></button>`}
function inspectedCombatant(S){const u=S.units.find(u=>u.id===UI.battleInspect)||S.units.find(u=>!u.summon&&u.team===0);if(!u)return '';return `<div><b>${esc(u.name)}</b><span>${SPECIES[u.sp]?.role||'Summon'} · ${combatStatus(u)}</span></div><div><small>HEALTH</small><b>${fmt(u.hp)} / ${fmt(u.maxHp)}</b></div><div><small>TARGET</small><b>${u.target?.alive?esc(u.target.name):'—'}</b></div><div><small>${esc(ABINFO[u.ab]?.[0]||'SIGNATURE')}</small><b>${u.tac.ability==='disabled'?'Held':u.cdT>0?u.cdT.toFixed(1)+'s':'Ready'}</b></div><div><small>IMPACT</small><b>${impactOf(u.st).toFixed(1)}</b></div><div><small>K / D / A</small><b>${u.st.k} / ${u.st.d} / ${u.st.a}</b></div>`}
viewBattle=function(c,S){
 UI.battleInspect=S.units.find(u=>u.team===0&&!u.summon)?.id;
 return `<div class="autobattle-shell"><div class="battle-scoreboard"><div>${crest(G.clubs.P,31)}<strong>${esc(G.name)}</strong><b id="scoreA">${c.fmt}</b></div><span>${esc(campaignLabel(c))}</span><div><b id="scoreB">${c.fmt}</b><strong>${esc(G.clubs[c.opp].name)}</strong>${crest(G.clubs[c.opp],31)}</div></div><div class="stage readable-arena"><canvas id="cv" width="1280" height="740" aria-label="Autobattle arena. Select a hero using the status buttons below."></canvas><div class="clock" id="clock">0s</div><div class="kill-callout" id="kill-callout" role="status" aria-live="polite"></div><div class="feed" id="feed"></div><div class="arena-key">GOLD · YOUR CLUB <span>CORAL · RIVALS</span></div></div><div class="battle-playback"><div class="seg" role="group" aria-label="Battle speed"><button data-act="pause" id="bp">Pause</button>${[.5,.75,1,2,4].map(s=>`<button data-act="speed" data-s="${s}" class="${s===1?'on':''}">${s}×</button>`).join('')}</div><span>AUTOBATTLE · Select a hero to follow their target</span><div><button class="btn sm" data-act="settings">Sound</button><button class="btn sm" data-act="runMenu">Menu</button><button class="btn sm" data-act="skip">Finish bout</button></div></div><div class="combat-rosters"><div id="sideA" aria-label="Your heroes"></div><div id="sideB" aria-label="Rival heroes"></div></div><section id="combat-inspector" class="combat-inspector" aria-label="Selected hero status"></section></div>`;
};
updateSides=function(S){
 const pause=document.getElementById('bp');if(pause)pause.textContent=BT?.paused?'Resume':'Pause';
 for(const [team,id] of [[0,'sideA'],[1,'sideB']]){const el=document.getElementById(id);if(el)el.innerHTML=S.units.filter(u=>u.team===team&&!u.summon).map(combatHudUnit).join('')}
 const clock=document.getElementById('clock');if(clock)clock.textContent=`${Math.floor(S.t/60).toString().padStart(2,'0')}:${Math.floor(S.t%60).toString().padStart(2,'0')}${BT?.paused?' · PAUSED':''}`;
 for(const [team,id] of [[0,'scoreA'],[1,'scoreB']]){const el=document.getElementById(id);if(el)el.textContent=S.units.filter(u=>u.alive&&!u.summon&&u.team===team).length}
 const feed=document.getElementById('feed');if(feed&&BT?.feedN!==S.feed.length){if(BT)BT.feedN=S.feed.length;feed.innerHTML=S.feed.slice(-4).map(f=>`<div class="${f.team?'b':'a'}">${esc(f.txt)}</div>`).join('')}
 const announcement=S.killAnnouncement,callout=document.getElementById('kill-callout');if(callout){const active=announcement&&S.t-announcement.at<3.5;if(active){const text=`${announcement.name} · ${announcement.label}`;if(callout.textContent!==text){callout.textContent=text;callout.className=`kill-callout active ${announcement.team?'rival':''}`}}else{callout.textContent='';callout.className='kill-callout'}}
 const inspector=document.getElementById('combat-inspector');if(inspector)inspector.innerHTML=inspectedCombatant(S);
};
ACT.battleInspect=d=>{const id=Number(d.id);if(!BT?.S.units.some(u=>u.id===id))return;UI.battleInspect=id;updateSides(BT.S)};
const inspectBattleStart=startBattle;startBattle=function(S){inspectBattleStart(S);const canvas=document.getElementById('cv');canvas?.addEventListener('click',e=>{if(!BT||BT.S!==S)return;const box=canvas.getBoundingClientRect(),scale=Math.min(box.width/W,box.height/H),x=(e.clientX-box.left-(box.width-W*scale)/2)/scale,y=(e.clientY-box.top-(box.height-H*scale)/2)/scale;const unit=S.units.filter(u=>!u.summon).sort((a,b)=>Math.hypot(a.x-x,a.y-30-y)-Math.hypot(b.x-x,b.y-30-y))[0];if(unit&&Math.hypot(unit.x-x,unit.y-30-y)<65){UI.battleInspect=unit.id;updateSides(S)}})};
const readablePause=ACT.pause;ACT.pause=()=>{readablePause();if(BT)updateSides(BT.S)};
const combatSettings=ACT.settings;ACT.settings=()=>{if(BT){UI.audioPaused=BT.paused;BT.paused=true}combatSettings()};
const combatClose=ACT.close;ACT.close=d=>{const resume=UI.modal?.k==='settings'&&BT&&UI.audioPaused===false;combatClose(d);if(resume&&BT)BT.paused=false};
const combatRender=render;render=function(){if(UI.audioPaused!==undefined&&UI.modal?.k!=='settings'){if(BT&&UI.modal?.k!=='runmenu')BT.paused=UI.audioPaused;delete UI.audioPaused}combatRender()};
const combatMenu=ACT.runMenu;ACT.runMenu=()=>{const paused=UI.audioPaused;combatMenu();if(paused!==undefined&&UI.modal?.k==='runmenu'){UI.modal.wasPaused=paused;delete UI.audioPaused}};

let tacticalArenaTexture=null;
arenaTexture=function(){
 if(tacticalArenaTexture)return tacticalArenaTexture;const canvas=document.createElement('canvas');canvas.width=W;canvas.height=H;const g=canvas.getContext('2d');
 g.fillStyle='#111c21';g.fillRect(0,0,W,H);const floor=g.createLinearGradient(0,70,0,H);floor.addColorStop(0,'#46483d');floor.addColorStop(.48,'#555344');floor.addColorStop(1,'#303c36');g.fillStyle=floor;g.fillRect(48,76,W-96,H-126);
 for(let row=0;row<12;row++)for(let col=0;col<24;col++){const x=50+col*52+(row%2)*26,y=78+row*51,hash=Math.abs(Math.sin(row*97+col*173));g.fillStyle=`rgba(218,206,161,${hash*.038})`;g.fillRect(x+1,y+1,50,49);g.strokeStyle='#151f2233';g.strokeRect(x,y,52,51)}
 g.strokeStyle='#a3976c60';g.lineWidth=3;g.strokeRect(58,87,W-116,H-143);g.strokeStyle='#d3b77718';g.lineWidth=1;g.strokeRect(75,104,W-150,H-178);
 g.setLineDash([4,12]);g.beginPath();g.moveTo(CX,114);g.lineTo(CX,H-94);g.stroke();g.setLineDash([]);ellipse(g,CX,CY,75,75,'#c5b48015',true,2);ellipse(g,CX,CY,65,65,'#c5b48010',true,1);
 for(let x=42;x<W-40;x+=55){g.fillStyle='#1b292c';g.fillRect(x,35,49,38);g.strokeStyle='#64726966';g.strokeRect(x,35,49,38);g.fillStyle='#c4a86d55';g.fillRect(x+12,41,25,2)}
 for(const [x,color] of [[37,'#cbb270'],[W-44,'#c77670']]){g.fillStyle=color;g.globalAlpha=.5;g.fillRect(x,CY-48,7,96);g.globalAlpha=1}
 tacticalArenaTexture=canvas;return canvas;
};
function prepareBeastFrames(S){const time=S.vt||0,stamp=Math.floor(time*60);if(S.beastFrameStamp===stamp)return;const units=S.units.filter(u=>u.alive||!u.summon),entries=units.map(u=>({sp:u.summon?(u.skin||u.sp||'direwolf'):u.sp,time:time+(u.id||0)*.13,opts:{motion:PREFS.motion,moving:u.moved>0,speed:Math.hypot(u.vx||0,u.vy||0)/Math.max(1,u.mv),attack:u.animAtk,windup:u.strike?u.strike.remaining/u.strike.duration:undefined,casting:u.animCast>0,state:u.visualState||(u.visualState={}),angle:updateBeastHeading(u,time,!u.alive),dead:!u.alive,arena:true}})),batch=Beast3D.renderBatch(entries);if(!batch)return;units.forEach((u,i)=>{u.modelFrame=batch.canvas;u.modelTile=batch.tiles[i];u.modelStamp=stamp+':'+!u.alive});S.beastFrameStamp=stamp}
drawArtRig=function(g,u,time,dead=false){
 const sp=u.summon?(u.skin||u.sp||'direwolf'):u.sp,size=((SPECIES[sp]?.size||15)*1.75+47)*(u.summon?.57:1),angle=updateBeastHeading(u,time,dead),stamp=Math.floor(time*60)+':'+dead;
 if(u.modelStamp!==stamp){if(u.modelTile)u.modelFrame=null;u.modelTile=null;const frame=Beast3D.render(sp,time+(u.id||0)*.13,{motion:PREFS.motion,moving:u.moved>0,speed:Math.hypot(u.vx||0,u.vy||0)/Math.max(1,u.mv),attack:u.animAtk,windup:u.strike?u.strike.remaining/u.strike.duration:undefined,casting:u.animCast>0,state:u.visualState||(u.visualState={}),angle,dead,arena:true});if(!frame)return;if(!u.modelFrame){u.modelFrame=document.createElement('canvas');u.modelFrame.width=u.modelFrame.height=256}const ctx=u.modelFrame.getContext('2d');ctx.clearRect(0,0,256,256);ctx.drawImage(frame,0,0,256,256);u.modelStamp=stamp}
 if(!u.modelFrame)return;g.save();if(dead)g.globalAlpha*=.24;if(u.s.stealth>0)g.globalAlpha*=.3;if(u.flash>0)g.filter='brightness(1.65)';const tile=u.modelTile;if(tile)g.drawImage(u.modelFrame,tile.x,tile.y,tile.size,tile.size,u.x-size*.5,u.y-size*.83,size,size);else g.drawImage(u.modelFrame,u.x-size*.5,u.y-size*.83,size,size);g.restore();u.visualHeight=size*.68;
};
const readableDraw=drawBattle;drawBattle=function(g,S,msg){
 prepareBeastFrames(S);readableDraw(g,S,msg);if(S.done||msg)return;const u=S.units.find(u=>u.id===UI.battleInspect);if(!u?.alive)return;
 g.save();ellipse(g,u.x,u.y,u.r+10,(u.r+10)*.64,'#f0e2af',true,2);if(u.target?.alive){g.setLineDash([3,7]);g.strokeStyle='#e9dc9d60';g.lineWidth=1;g.beginPath();g.moveTo(u.x,u.y);g.lineTo(u.target.x,u.target.y);g.stroke();g.setLineDash([]);ellipse(g,u.target.x,u.target.y,u.target.r+8,(u.target.r+8)*.64,'#d8b48470',true,1)}g.restore();
};
drawCombatBars=function(g,u){
 if(u.summon)return;const top=u.y-(u.visualHeight||55)-8,w=40;g.fillStyle='#0a131aea';g.fillRect(u.x-w/2-2,top-2,w+4,11);g.fillStyle=u.team?'#de8a7a':'#d1bf83';g.fillRect(u.x-w/2,top,w*clamp(u.hp/u.maxHp,0,1),4);g.fillStyle='#284854';g.fillRect(u.x-w/2,top+6,w,2);g.fillStyle='#8dced8';g.fillRect(u.x-w/2,top+6,w*(1-clamp(u.cdT/u.cd,0,1)),2);if(u.s.shield>0){g.fillStyle='#b8ebe8';g.fillRect(u.x-w/2,top,w*clamp(u.s.shield/u.maxHp,0,1),1)}
 if(UI.battleInspect===u.id){g.font='600 11px "DM Sans",sans-serif';g.textAlign='center';g.strokeStyle='#102026';g.lineWidth=3;g.strokeText(u.name,u.x,u.y+20);g.fillStyle='#f1e4c5';g.fillText(u.name,u.x,u.y+20)}
};

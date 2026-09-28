'use strict';
const KEEPER_STEPS=[
 {id:'welcome',label:'Meet the team',target:'.club-roster-strip',copy:'Your founders have signature abilities. Each hero earns upgrade cards when they level up in the arena.'},
 {id:'formation',label:'Drag your formation',target:'.formation-panel',prep:true,copy:'Drag tough beasts to the front and fragile allies behind them. Occupied tiles swap. The starting lineup is already selected.'},
 {id:'ready',label:'Enter the arena',target:'[data-guide="readiness"]',prep:true,copy:'Fights are automatic. Earn gold and experience; level-ups unlock hero upgrades. Wins give slightly better rarity odds.'}
];
let keeperNeedsRoute=false,keeperScroll=false;
function keeperState(){return G?.onboarding}
function keeperStep(){return KEEPER_STEPS.find(s=>s.id===keeperState()?.step)||KEEPER_STEPS[0]}
function keeperAvailable(){return !!G&&['hub','prematch'].includes(UI.mode)}
function keeperVisit(id){if(!keeperState()||!KEEPER_STEPS.some(s=>s.id===id))return false;G.onboarding.step=id;G.onboarding.visited=Array.from(new Set([...(G.onboarding.visited||[]),id]));save();return true}
function keeperNavigate(){if(!keeperAvailable()||!keeperState()?.active)return;UI.modal=null;if(keeperStep().prep){if(UI.mode!=='prematch')openNext()}else{UI.mode='hub';UI.tab='club'}keeperScroll=true;render()}
function keeperStart(restart=false){if(!keeperAvailable())return;if(!keeperState()||restart)G.onboarding={version:2,active:true,step:'welcome',visited:[],complete:false};G.onboarding.active=true;keeperVisit(keeperStep().id);keeperNavigate()}
function keeperFinish(){if(!keeperState())return;G.onboarding.active=false;G.onboarding.complete=true;save()}
ACT.keeperStart=()=>keeperStart(!!keeperState()?.complete);
ACT.keeperPause=()=>{if(keeperState()){G.onboarding.active=false;save();render()}};
ACT.keeperNext=()=>{const i=KEEPER_STEPS.indexOf(keeperStep());if(i===2){keeperFinish();render()}else{keeperVisit(KEEPER_STEPS[i+1].id);keeperNavigate()}};
ACT.keeperBack=()=>{const i=KEEPER_STEPS.indexOf(keeperStep());if(i>0){keeperVisit(KEEPER_STEPS[i-1].id);keeperNavigate()}};
ACT.keeperLocate=keeperNavigate;
function paintKeeper(){document.querySelectorAll('.keeper-highlight').forEach(el=>el.classList.remove('keeper-highlight'));let host=document.getElementById('keeper-guide');if(!keeperState()?.active||!keeperAvailable()||UI.modal){host?.remove();return}if(!host){host=document.createElement('aside');host.id='keeper-guide';host.className='keeper-guide';host.setAttribute('aria-label','Quick start guide');document.getElementById('view').before(host)}const s=keeperStep(),i=KEEPER_STEPS.indexOf(s);host.innerHTML=`<div class="keeper-count">${i+1}<small>/ 3</small></div><div class="keeper-copy"><span class="lbl gold">QUICK START</span><h3>${s.label}</h3><p>${s.copy}</p></div><div class="keeper-actions">${i?'<button class="btn sm" data-act="keeperBack">Back</button>':''}<button class="btn pri sm" data-act="keeperNext">${i===2?'Got it':'Next →'}</button><button class="keeper-icon" data-act="keeperPause" aria-label="Close quick start">×</button></div>`;const target=document.querySelector(s.target);target?.classList.add('keeper-highlight');if(target&&keeperScroll)target.scrollIntoView({behavior:'instant',block:'center'});keeperScroll=false}
const keeperRenderModal=renderModal;renderModal=function(){keeperRenderModal();paintKeeper()};
const keeperRender=render;render=function(){keeperRender();paintKeeper();if(keeperNeedsRoute&&keeperAvailable()){keeperNeedsRoute=false;keeperNavigate()}};
const keeperTop=renderTop;renderTop=function(){keeperTop();if(keeperAvailable())document.querySelector('.purse')?.insertAdjacentHTML('beforeend','<button class="btn sm keeper-launch" data-act="keeperStart">Quick start</button>')};
const keeperNewGame=newGame;newGame=function(...args){keeperNewGame(...args);G.onboarding={version:2,active:true,step:'welcome',visited:['welcome'],complete:false}};
const keeperLoad=load;load=function(){const g=keeperLoad();if(g?.onboarding){if(g.onboarding.version!==2){g.onboarding={version:2,active:false,step:'welcome',visited:[],complete:false}}else if(g.onboarding.active){keeperNeedsRoute=true;if(!KEEPER_STEPS.some(s=>s.id===g.onboarding.step))g.onboarding.step='welcome'}}return g};
const keeperGo=ACT.go;ACT.go=d=>{if(UI.mode!=='prematch'||!matchReadiness().full)return;keeperFinish();keeperGo(d);paintKeeper()};

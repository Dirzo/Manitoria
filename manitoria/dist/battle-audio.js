'use strict';
// Original, local synthesis: every signature and learned technique has its own cue.
const ABILITY_SOUND={
 gore:['charge',82,.42,2],bulwark:['stone',66,.56,3],smash:['stone',49,.36,1],hunger:['roar',118,.55,2],howl:['roar',220,.9,2],venom:['venom',410,.44,3],skystrike:['wind',630,.38,2],foxfire:['arcane',520,.7,4],acid:['venom',260,.65,5],shriek:['roar',730,.48,3],flamewave:['fire',110,.85,4],chain:['spark',740,.42,4],gaze:['crystal',390,.7,2],rootbloom:['life',293,.65,3],tidal:['water',330,.8,4],radiance:['life',523,.8,5],triplebite:['claw',125,.34,3],prideroar:['roar',145,.68,3],frostroar:['crystal',680,.65,4],shellup:['stone',94,.44,2],maul:['claw',84,.4,2],regrowth:['life',196,.7,4],threefold:['fire',220,.54,3],stonedive:['stone',41,.64,4],vanish:['arcane',277,.48,2],antlerrush:['charge',106,.6,4],boulder:['stone',58,.7,2],stormcall:['spark',520,.7,3],riddle:['arcane',466,.82,3],tailwind:['wind',840,.75,4],brood:['venom',165,.46,6],magma:['fire',73,.95,3],
 seismic:['stone',36,.8,3],aegis:['crystal',440,.85,3],challenge:['charge',164,.5,2],frost:['crystal',880,.95,5],bloom:['life',349,.9,4],rupture:['arcane',185,.6,3],pounce:['wind',470,.35,2],cyclone:['wind',290,1.3,5],siphon:['venom',130,.6,2]
};
PREFS.sfxVolume=Number.isFinite(PREFS.sfxVolume)?clamp(PREFS.sfxVolume,0,1):.7;
function soundReady(){if(!PREFS.sfx||PREFS.sfxVolume<=0||document.hidden)return null;const c=actx();if(!c||c.state!=='running')return null;SCORE.fx.gain.setTargetAtTime(.24*PREFS.sfxVolume,c.currentTime,.015);return c}
function effectTone(c,out,t,f,end,dur,gain,type='sine'){const env=stageVoice(c,out,t,dur*.65,gain,0,.008,dur*.35),osc=aosc(c,type,f,t,t+dur+.05);osc.frequency.exponentialRampToValueAtTime(Math.max(24,end),t+dur);osc.connect(env)}
function effectNoise(c,out,t,dur,f,q,gain){const env=stageVoice(c,out,t,dur*.55,gain,0,.012,dur*.45),filter=c.createBiquadFilter();filter.type='bandpass';filter.frequency.setValueAtTime(f,t);filter.frequency.exponentialRampToValueAtTime(Math.max(60,f*.28),t+dur);filter.Q.value=q;filter.connect(env);anoise(c,t,dur+.05).connect(filter)}
function playAbilityCue(key,u=null,preview=false){
 const spec=ABILITY_SOUND[key],c=soundReady();if(!spec||!c)return false;const now=c.currentTime;
 // The same caster cannot stack duplicate cast cues; simultaneous heroes remain audible.
 const identity=`${u?.id??'preview'}:${key}`;SCORE.abilityTimes=SCORE.abilityTimes||{};if(!preview&&now-(SCORE.abilityTimes[identity]??-Infinity)<.18)return false;SCORE.abilityTimes[identity]=now;
 const [kind,f,dur,count]=spec,t=now+.006,out=c.createGain(),pan=c.createStereoPanner();out.gain.value=.75;pan.pan.value=u?clamp((u.x/W-.5)*1.1,-.7,.7):0;out.connect(pan);pan.connect(SCORE.fx);setTimeout(()=>{out.disconnect();pan.disconnect()},Math.ceil((dur+1)*1000));
 if(kind==='stone'||kind==='charge'){effectTone(c,out,t,f*1.6,f*.5,dur,.55,'triangle');effectNoise(c,out,t,dur*.6,kind==='stone'?560:1300,.6,.65);for(let i=1;i<count;i++)effectTone(c,out,t+i*.07,f*2,f*.8,.14,.13,'triangle')}
 if(kind==='fire'){effectNoise(c,out,t,dur,1000,.45,1);effectTone(c,out,t,f*1.6,40,dur,.35,'triangle');for(let i=0;i<count;i++)effectNoise(c,out,t+i*.09,.12,2200+i*140,1,.23)}
 if(kind==='claw'){for(let i=0;i<count;i++){effectNoise(c,out,t+i*.09,.15,1900-i*200,.8,.6);effectTone(c,out,t+i*.09,f*2,f,.14,.22,'triangle')}}
 if(kind==='roar'){effectTone(c,out,t,f,f*.72,dur,.3,'sawtooth');effectTone(c,out,t,f*.51,f*.4,dur,.3);effectNoise(c,out,t,dur,430+f,.9,.6)}
 if(kind==='spark'){for(let i=0;i<count;i++){effectNoise(c,out,t+i*.07,.1,2700+i*500,1.4,.52);effectTone(c,out,t+i*.07,f*(1+i*.3),f*.4,.14,.16,'square')}}
 if(kind==='wind'||kind==='water'){effectNoise(c,out,t,dur,kind==='wind'?2400:700,.6,.7);for(let i=0;i<count;i++)effectTone(c,out,t+i*.09,f*(1+i*.2),f*(.4+i*.12),dur*.5,.1,'sine')}
 if(kind==='venom'){for(let i=0;i<count;i++){effectTone(c,out,t+i*.06,f*(1+i*.16),f*.4,.22,.19,'triangle');effectNoise(c,out,t+i*.04,.13,1500,.9,.2)}}
 if(kind==='crystal'||kind==='life'||kind==='arcane'){const ratios=kind==='life'?[1,1.25,1.5,2,2.5]:kind==='arcane'?[1,1.189,1.498,2.119,2.378]:[1,2.01,2.76,4.02,5.4];for(let i=0;i<count;i++){const n=f*ratios[i%ratios.length];effectTone(c,out,t+i*.055,n,kind==='arcane'?n*.72:n,dur,.18/(1+i*.2),'sine');effectTone(c,out,t+i*.055,n*2.003,n*2,.22,.04,'sine')}if(kind==='arcane')effectNoise(c,out,t,dur,1800,3,.22)}
 return true;
}
// Emit only on a successful cast, including abilities with no separate visual hook.
for(const key of Object.keys(ABIL)){const cast=ABIL[key];ABIL[key]=function(S,u,...args){const result=cast(S,u,...args);if(result&&!S.headless&&BT?.S===S)playAbilityCue(key,u);return result}}
for(const [key,tech] of Object.entries(TECHNIQUES)){const cast=tech.cast;tech.cast=function(S,u,...args){const result=cast(S,u,...args);if(result&&!S.headless&&BT?.S===S)playAbilityCue(key,u);return result}}
Object.assign(CAST,soundCast);
const genericCue=playCue;playCue=function(kind){if(kind==='cast'||!soundReady())return;genericCue(kind)};
// Repeated poison/burn ticks are deliberately quiet; landed blows retain a light impact.
hit=function(S,src,target,raw,opts={}){const before=target.hp+target.s.shield,result=soundHit(S,src,target,raw,opts);if(!opts.dot&&target.hp+target.s.shield<before&&!S.headless&&BT?.S===S)playCue('hit');return result};
function playMultikill(count,team){const c=soundReady();if(!c)return;const t=c.currentTime+.01,base=team?55:62;[0,7,12,Math.min(19,12+count)].forEach((n,i)=>iBrass(c,SCORE.fx,t+i*.11,base+n,.32,.6,.6));taiko(c,SCORE.fx,t,.7,70)}
TRACKS.landing={bpm:56,bar(c,o,t,b,i){const chords=[[57,64,69,72],[53,60,65,69],[55,62,67,71],[52,59,64,67]],ch=chords[Math.floor(i/2)%4];iStrings(c,o,t,ch.slice(0,3),b*3.9,.5);if(i%2===0)iChoir(c,o,t,ch.slice(1),b*7.8,.26);[0,.75,1.5,2.5,3.25].forEach((p,j)=>iPluck(c,o,t+p*b,ch[[0,2,1,3,2][j]]+12,.38));if(i%4===2)iBrass(c,o,t,ch[2],b*3.5,.18,.2)}};
function desiredMusic(){return ['menu','intro'].includes(UI.mode)||!G?'landing':UI.mode==='battle'?'battle':['prematch','draft'].includes(UI.mode)?'prelude':['result','levelup'].includes(UI.mode)?UI.result?.winner===0?'victory':'honor':UI.mode==='cupdone'?G.cup?.champ==='P'?'victory':'honor':UI.mode==='season'?UI.seasonSum?.pos<=2||UI.seasonSum?.move===1?'victory':'honor':'club'}
const adaptiveMusic=music;music=function(){adaptiveMusic(desiredMusic())};
const musicRender=render;render=function(){musicRender();if(SCORE.started&&MUS.name!==desiredMusic())music(desiredMusic())};
const audioSettings=modalSettings;modalSettings=function(m){return audioSettings(m)+`<section class="sound-controls"><h3>The sound of your club</h3><p>Landing: quiet harp & choir. Club: reflective strings. Preparation: gathering drums. Arena: percussion & brass. Music changes with the screen.</p><label for="sfx-volume">Ability & interface volume · <span id="sfx-level">${Math.round(PREFS.sfxVolume*100)}%</span></label><input id="sfx-volume" type="range" min="0" max="1" step=".05" value="${PREFS.sfxVolume}"><div class="sound-preview"><button class="btn sm" data-act="soundPreview" data-k="flamewave">Flame Wave</button><button class="btn sm" data-act="soundPreview" data-k="chain">Chain Lightning</button><button class="btn sm" data-act="soundPreview" data-k="radiance">Radiant Horn</button><button class="btn sm" data-act="soundPreview" data-k="multikill">Double kill</button></div><p>Every signature and learned ability has its own sound. Sounds follow heroes across the arena; music and effects have separate controls.</p></section>`};
ACT.soundPreview=d=>{if(d.k==='multikill')playMultikill(2,0);else playAbilityCue(d.k,null,true)};
const settingsMusicToggle=ACT.music;ACT.music=()=>{settingsMusicToggle();if(UI.modal?.k==='settings')renderModal()};
document.addEventListener('input',e=>{if(e.target.id!=='sfx-volume')return;PREFS.sfxVolume=clamp(Number(e.target.value),0,1);const label=document.getElementById('sfx-level');if(label)label.textContent=Math.round(PREFS.sfxVolume*100)+'%';if(SCORE.fx&&MUS.ctx)SCORE.fx.gain.setTargetAtTime(.24*PREFS.sfxVolume,MUS.ctx.currentTime,.02);try{localStorage.setItem('manitoria-presentation',JSON.stringify(PREFS))}catch{}});

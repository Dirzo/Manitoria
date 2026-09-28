'use strict';

function clubInitials(name){
 const words=String(name||'').normalize('NFKC').match(/[\p{L}\p{N}]+/gu)||[];
 if(words.length>1&&/^(the|a|an)$/i.test(words[0]))words.shift();
 return words.slice(0,3).map(word=>Array.from(word)[0]).join('').toLocaleUpperCase()||'C';
}
const EMBLEMS={cup:'Champion’s cup',shield:'Keeper’s shield',laurel:'Laurel seal'};
crest=function(c,size=48){
 const letters=clubInitials(c.name),emblem=c.emblem||(c.id==='P'?'cup':'shield');
 const hue=Number.isFinite(Number(c.hue))?Number(c.hue):38;
 const dark=`hsl(${hue} 31% 20%)`,light=`hsl(${hue} 48% 67%)`,ink='#f5e4b7';
 let art,y=58;
 if(emblem==='cup'){
  art=`<path d="M28 25H12v12c0 15 10 23 24 24M68 25h16v12c0 15-10 23-24 24" fill="none" stroke="${light}" stroke-width="5"/><path d="M27 15h42v27c0 17-8 28-21 34-13-6-21-17-21-34Z" fill="${dark}" stroke="${light}" stroke-width="2.5"/><path d="M33 22h30M43 75v12H32l-7 10h46l-7-10H53V75M29 103h38" fill="none" stroke="${light}" stroke-width="3" stroke-linecap="round"/><path d="m48 2 2 5 5 2-5 2-2 5-2-5-5-2 5-2Z" fill="${ink}"/>`;y=53;
 }else if(emblem==='laurel'){
  art=`<circle cx="48" cy="52" r="31" fill="${dark}" stroke="${light}" stroke-width="2"/><circle cx="48" cy="52" r="26" fill="none" stroke="${light}" stroke-opacity=".35"/><path d="M43 98C11 86 2 56 15 26M53 98c32-12 41-42 28-72" fill="none" stroke="${light}" stroke-width="2"/>${[0,1,2,3].map(i=>`<path d="M${17+i*3} ${44+i*12}q-16-7-13-18 15 5 13 18M${79-i*3} ${44+i*12}q16-7 13-18-15 5-13 18" fill="${light}"/>`).join('')}<path d="m48 4 3 7 8 1-6 5 1 8-6-4-6 4 1-8-6-5 8-1Z" fill="${light}"/>`;
 }else{
  art=`<path d="M13 12h70v40c0 25-18 40-35 49-17-9-35-24-35-49Z" fill="${dark}" stroke="${light}" stroke-width="2.5"/><path d="M20 20h56v31c0 20-13 32-28 41-15-9-28-21-28-41Z" fill="none" stroke="${light}" stroke-opacity=".35"/><path d="m35 24 5 5 8-9 8 9 5-5-3 12H38Z" fill="${light}"/>`;y=66;
 }
 return `<svg class="crest crest-${emblem}" width="${size}" height="${Math.round(size*112/96)}" viewBox="0 0 96 112" role="img" aria-label="${esc(c.name||'Club')} crest · ${esc(letters)}">${art}<text x="48" y="${y}" text-anchor="middle" font-family="Cinzel,Georgia,serif" font-weight="700" font-size="${letters.length>2?20:letters.length===2?27:33}" fill="${ink}">${esc(letters)}</text></svg>`;
};
function identityDesigner(I){
 const emblem=I.emblem||'cup';
 return `<div class="panel identity-designer"><div class="identity-preview"><div id="identity-crest">${crest({name:I.name,hue:I.hue,emblem},128)}</div><span class="lbl">EST. SEASON I</span><strong id="identity-name">${esc(I.name||'Your club name')}</strong><span class="identity-rule"></span><small>YOUR CLUB. YOUR LEGACY.</small></div><div class="identity-controls"><label class="lbl" for="iname">Club name</label><input type="text" id="iname" value="${esc(I.name)}" maxlength="32" autocomplete="off" spellcheck="false" aria-label="Club name"><p class="note">Your name becomes your monogram. The emblem updates as you type.</p><span class="lbl">Choose your emblem</span><div class="emblem-options" role="group" aria-label="Club emblem">${Object.entries(EMBLEMS).map(([key,name])=>`<button class="emblem-choice ${emblem===key?'on':''}" data-act="introEmblem" data-k="${key}" aria-pressed="${emblem===key}">${crest({name:I.name,hue:I.hue,emblem:key},32)}<span>${name}</span></button>`).join('')}</div><div class="row identity-colors"><span class="lbl">Club colors</span><div class="row" role="group" aria-label="Crest color">${CREST_HUES.map(h=>`<button class="sw ${I.hue===h?'on':''}" style="--sh:${h}" data-act="introHue" data-k="${h}" aria-label="Crest color ${h}" aria-pressed="${I.hue===h}"></button>`).join('')}</div></div></div></div>`;
}
function updateIdentityPreview(){
 const I=UI.intro,el=document.getElementById('identity-crest');
 if(!el)return;
 el.innerHTML=crest({name:I.name,hue:I.hue,emblem:I.emblem||'cup'},128);
 document.getElementById('identity-name').textContent=I.name.trim()||'Your club name';
 document.querySelectorAll('.emblem-choice').forEach(button=>{button.querySelector('.crest').outerHTML=crest({name:I.name,hue:I.hue,emblem:button.dataset.k},32)});
}
ACT.introEmblem=d=>{if(EMBLEMS[d.k]){UI.intro.emblem=d.k;render()}};
const identityNewGame=newGame;newGame=function(...args){identityNewGame(...args);G.clubs.P.emblem=UI.intro.emblem||'cup'};

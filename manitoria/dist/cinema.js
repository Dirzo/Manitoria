'use strict';
// High-resolution canvas presentation, with fixed-time simulation independent of display refresh.
let cinematicArena=null;
function ellipse(g,x,y,rx,ry,color,stroke=false,width=1){g.beginPath();g.ellipse(x,y,Math.max(.1,rx),Math.max(.1,ry),0,0,Math.PI*2);if(stroke){g.strokeStyle=color;g.lineWidth=width;g.stroke()}else{g.fillStyle=color;g.fill()}}
function glow(g,x,y,r,color,alpha=1){if(!PREFS.effects)return;g.save();g.globalAlpha*=alpha;const a=g.createRadialGradient(x,y,0,x,y,r);a.addColorStop(0,color);a.addColorStop(1,'transparent');g.fillStyle=a;g.fillRect(x-r,y-r,r*2,r*2);g.restore()}
function arenaTexture(){if(cinematicArena)return cinematicArena;const cv=document.createElement('canvas');cv.width=W;cv.height=H;const g=cv.getContext('2d');g.fillStyle='#07111b';g.fillRect(0,0,W,H);
 for(let k=9;k>=0;k--){ellipse(g,CX,CY+3,RX+12+k*7,RY+10+k*7,k%2?'#19262d':'#101e26');ellipse(g,CX,CY,RX+10+k*7,RY+8+k*7,'#32404a88',true,1)}
 const floor=g.createRadialGradient(CX,CY,30,CX,CY,650);floor.addColorStop(0,'#35434a');floor.addColorStop(.65,'#23333b');floor.addColorStop(1,'#111e27');ellipse(g,CX,CY,RX,RY,floor);
 g.save();g.beginPath();g.ellipse(CX,CY,RX-3,RY-3,0,0,Math.PI*2);g.clip();
 for(let row=-1;row<18;row++){for(let col=-1;col<26;col++){const x=col*58+(row%2)*29,y=row*48;const hash=(Math.sin(row*173+col*61)*43758)%1;g.fillStyle=`rgba(175,199,196,${.012+Math.abs(hash)*.025})`;g.fillRect(x+1,y+1,56,46);g.strokeStyle='#07182044';g.lineWidth=1;g.strokeRect(x,y,58,48);g.strokeStyle='#68808914';g.beginPath();g.moveTo(x+2,y+2);g.lineTo(x+55,y+2);g.stroke()}}
 for(let k=1;k<5;k++)ellipse(g,CX,CY,RX*k/5,RY*k/5,'#a8a18418',true,1);
 for(let i=0;i<12;i++){const a=i*Math.PI/6;g.strokeStyle='#b19d6820';g.beginPath();g.moveTo(CX+Math.cos(a)*72,CY+Math.sin(a)*45);g.lineTo(CX+Math.cos(a)*(RX-24),CY+Math.sin(a)*(RY-20));g.stroke()}
 ellipse(g,CX,CY,85,51,'#101c2466');ellipse(g,CX,CY,79,47,'#a2915c88',true,2);ellipse(g,CX,CY,68,40,'#a2915c44',true,1);
 g.save();g.translate(CX,CY);g.scale(1,.62);g.strokeStyle='#c3b27b66';g.lineWidth=2;for(let i=0;i<8;i++){g.rotate(Math.PI/4);g.beginPath();g.moveTo(0,-58);g.lineTo(12,-25);g.lineTo(0,-34);g.lineTo(-12,-25);g.closePath();g.stroke()}g.restore();
 g.restore();ellipse(g,CX,CY,RX,RY,'#7c807366',true,5);ellipse(g,CX,CY,RX-8,RY-6,'#bfac7244',true,1);
 for(let i=0;i<68;i++){const a=i/68*Math.PI*2,x=CX+Math.cos(a)*(RX+10),y=CY+Math.sin(a)*(RY+9);g.save();g.translate(x,y);g.rotate(a);g.fillStyle='#34464b';g.fillRect(-4,-7,8,14);g.fillStyle='#76807788';g.fillRect(-4,-7,2,14);g.restore()}
 [0,1].forEach(team=>{const x=team?CX+RX-15:CX-RX+15;g.fillStyle='#060d13';g.fillRect(x-13,CY-35,26,70);for(let i=-2;i<=2;i++){g.fillStyle='#637273';g.fillRect(x+i*5-1,CY-33,2,66)}g.fillStyle=team?'#783836':'#8d7842';g.fillRect(x-17,CY-68,34,26);g.fillStyle='#d9c48e';g.font='16px Georgia';g.textAlign='center';g.fillText(team?'Ⅱ':'Ⅰ',x,CY-49)});
 cinematicArena=cv;return cv;
}
function drawArtRig(g,u,T,dead=false){const sp=u.summon?(u.skin||u.sp||'direwolf'):u.sp,art=ART.frames[sp];const x=u.x,y=u.y;const scale=u.summon?.52:1;const size=(SPECIES[sp]?.size||15)*2.5+43;const maxW=size*1.13*scale,maxH=size*scale;let w=maxW,h=art?maxW*art.height/art.width:maxH;if(h>maxH){w*=maxH/h;h=maxH}const phase=T*2.4+u.id*1.618,move=PREFS.motion&&u.moved>0,wing=FLY.has(sp);const cast=u.animCast>0,attack=u.animAtk>0;const atk=attack?(u.animAtk>.18?-4:Math.sin(u.animAtk/.18*Math.PI)*12):0;const hover=wing&&!dead?10+(PREFS.motion?Math.sin(phase*1.7)*4:0):0;const bounce=move?Math.abs(Math.sin(u.walk*.22))*4:0;
 g.save();g.translate(x+(u.face||1)*atk,y-hover-bounce);g.scale(u.face||1,1);if(dead){const age=Math.max(0,T-(u.visualDeath||T));g.rotate(Math.min(1,age*3)*.8);g.globalAlpha*=Math.max(.2,1-age*.4)}else if(PREFS.motion){g.rotate(move?Math.sin(u.walk*.22)*.025:Math.sin(phase)*.009);g.scale(1+(cast?.045:0),1+Math.sin(phase)*.012+(cast?.045:0))}
 if(u.s.stealth>0)g.globalAlpha*=.3;if(u.summon&&u.lure)g.globalAlpha*=.65;
 if(art){if(u.flash>0)g.filter='brightness(1.65) saturate(.65)';else if(u.s.tintT>0)g.filter=u.s.tint==='ice'?'sepia(.4) saturate(.4) hue-rotate(150deg)':'grayscale(1)';else if(dead)g.filter='grayscale(.7) brightness(.65)';
  if(!PREFS.motion||dead||(!move&&!wing)){g.drawImage(art,-w/2,-h,w,h)}else{
   // A continuous strip deformation animates the body and appendages without allocating frames.
   const strips=16;for(let i=0;i<strips;i++){const v=i/strips,sh=art.height/strips,sy=i*sh;const limb=v>.65&&move?Math.sin(u.walk*.26+v*7)*(v-.65)*7:0;const flap=wing?Math.sin(phase*2.6+v*2)*(1-v)*3:0;g.drawImage(art,0,sy,art.width,Math.min(sh+1,art.height-sy),-w/2+limb,-h+i*h/strips+flap,w,h/strips+1.1)}
  }g.filter='none';
 }else{const o=getSpr(sp,SC0),f=frameOf(u,T);g.imageSmoothingEnabled=false;g.drawImage(o.f[f],-OX*2,-OY*2,SW*2,SH*2);g.imageSmoothingEnabled=true}
 g.restore();u.visualHeight=h+hover;
}
function battlefieldEffects(g,S,T){for(const z of S.zones){const a=Math.min(1,z.t/.5);glow(g,z.x,z.y,z.r,`hsla(${z.hue},80%,48%,.2)`,a);ellipse(g,z.x,z.y,z.r,z.r*.64,`hsla(${z.hue},65%,30%,${.26*a})`);ellipse(g,z.x,z.y,z.r,z.r*.64,`hsla(${z.hue},80%,70%,${.45*a})`,true,1.3);for(let i=0;i<7&&PREFS.effects;i++){const t=T*1.6+i*2;glow(g,z.x+Math.cos(t)*z.r*.6,z.y+Math.sin(t)*z.r*.38,4,`hsla(${z.hue},100%,78%,.8)`)}}
 for(const f of S.fx){if(f.k==='txt'||f.ground)continue;const k=f.t/f.ttl,a=Math.max(0,1-k);g.save();g.globalAlpha=a;g.strokeStyle=f.c||'#a3ddf0';g.fillStyle=f.c||'#a3ddf0';g.lineWidth=2;if(PREFS.effects){g.shadowColor=f.c||'#a3ddf0';g.shadowBlur=10}
  if(f.k==='ring'||f.k==='wave'){const r=f.r0+(f.r1-f.r0)*k;g.beginPath();g.ellipse(f.x,f.y,Math.max(1,r),Math.max(1,r*.65),0,f.k==='wave'?f.a-f.w:0,f.k==='wave'?f.a+f.w:Math.PI*2);g.stroke();if(f.fill){g.globalAlpha=a*.12;g.fill()}}
  else if(f.k==='slash'||f.k==='crescent'){g.lineWidth=3*(1-k)+1;for(let i=0;i<(f.k==='crescent'?3:1);i++){g.beginPath();g.arc(f.x+i*5,f.y-28+i*4,f.r,f.a-.95,f.a+.95);g.stroke()}}
  else if(f.k==='bolt'){g.lineWidth=2;g.beginPath();f.pts.forEach((p,i)=>{if(!i)g.moveTo(p[0],p[1]-35);else{const p0=f.pts[i-1];for(let j=1;j<=7;j++){const t=j/7;g.lineTo(p0[0]+(p[0]-p0[0])*t+(j<7?Math.sin(j*11+T*42)*8:0),p0[1]+(p[1]-p0[1])*t-35+(j<7?Math.cos(j*9+T*50)*8:0))}}});g.stroke();g.strokeStyle='#eafaff';g.lineWidth=.8;g.stroke()}
  else if(f.k==='beam'){g.lineWidth=3;g.beginPath();g.moveTo(f.x1,f.y1-35);g.lineTo(f.x2,f.y2-35);g.stroke()}
  else if(f.k==='pillar'){const gradient=g.createLinearGradient(f.x,f.y-360,f.x,f.y);gradient.addColorStop(0,'transparent');gradient.addColorStop(1,f.c);g.fillStyle=gradient;g.globalAlpha=a*.4;g.fillRect(f.x-(f.w||14),f.y-400,(f.w||14)*2,400);g.globalAlpha=a;g.beginPath();g.moveTo(f.x,f.y-350);for(let yy=f.y-310;yy<f.y;yy+=25)g.lineTo(f.x+(f.jag?Math.sin(yy+T*50)*9:0),yy);g.lineTo(f.x,f.y);g.stroke();glow(g,f.x,f.y,55,f.c,.35)}
  else if(f.k==='dome'&&f.u?.alive){const u=f.u;ellipse(g,u.x,u.y-40,u.r*2,u.r*2.8,f.c,true,2);glow(g,u.x,u.y-35,u.r*3,f.c,.14)}
  else if(f.k==='glyph'&&f.u?.alive){const u=f.u;ellipse(g,u.x,u.y-80,16,7,f.c,true);g.font='18px Georgia';g.textAlign='center';g.fillText('?',u.x,u.y-90)}
  else if(f.k==='dot')ellipse(g,f.x,f.y,3,3,f.c);g.restore();
 }
}
function drawCombatBars(g,u){if(u.summon)return;const top=u.y-(u.visualHeight||80)-8,w=44;g.fillStyle='#040a10d9';g.fillRect(u.x-w/2-2,top-2,w+4,9);const col=u.team===0?'#d9c07f':'#dc756f';g.fillStyle=col;g.fillRect(u.x-w/2,top,w*clamp(u.hp/u.maxHp,0,1),3);g.fillStyle='#344858';g.fillRect(u.x-w/2,top+5,w,1.5);g.fillStyle='#8ad3ea';g.fillRect(u.x-w/2,top+5,w*(1-clamp(u.cdT/u.cd,0,1)),1.5);if(u.s.shield>0){g.fillStyle='#b2eeed';g.fillRect(u.x-w/2,top,w*clamp(u.s.shield/u.maxHp,0,1),1)}g.font='500 10px "DM Sans",sans-serif';g.textAlign='center';g.fillStyle=u.team===0?'#eee3c6':'#e6bbb6';g.shadowColor='#000';g.shadowBlur=5;g.fillText(u.name,u.x,u.y+16);g.shadowBlur=0}
drawBattle=function(g,S,msg){const T=S.vt||0;g.clearRect(0,0,W,H);g.save();if(PREFS.motion&&S.shake>0&&!BT?.paused){g.translate(Math.sin(T*83)*2.4,Math.cos(T*91)*1.5);S.shake=Math.max(0,S.shake-(S.renderDt||0))}g.drawImage(arenaTexture(),0,0);
 // Small, deterministic spectator lights avoid render-time randomness changing the simulation.
 for(let i=0;i<210;i++){const a=i*2.39996,r=RX+21+(i%3)*10,ry=RY+16+(i%3)*8,x=CX+Math.cos(a)*r,y=CY+Math.sin(a)*ry;const pulse=.25+.15*Math.sin(T*1.5+i);g.fillStyle=`rgba(185,163,129,${pulse})`;g.fillRect(x,y,2,3)}
 TORCH.forEach((p,i)=>{const flicker=1+(PREFS.motion?Math.sin(T*9+i)*.08:0);glow(g,p.x,p.y-7,65*flicker,'#ffa44933');g.fillStyle='#655b45';g.fillRect(p.x-3,p.y-5,6,16);ellipse(g,p.x,p.y-11,4,8*flicker,'#ef8b37');ellipse(g,p.x,p.y-12,2,5*flicker,'#ffe4a0')});
 for(const f of S.fx)if(f.ground)ellipse(g,f.x,f.y,f.rx||10,(f.rx||10)*.5,'#060c1366');
 for(const u of S.units)if(!u.alive&&!u.summon){if(u.visualDeath==null)u.visualDeath=T;drawArtRig(g,u,T,true)}
 for(const z of S.zones){ellipse(g,z.x,z.y,z.r,z.r*.65,`hsla(${z.hue},60%,24%,.24)`)}
 const live=S.units.filter(u=>u.alive).sort((a,b)=>a.y-b.y);
 for(const u of live){ellipse(g,u.x,u.y+1,u.r*1.1,u.r*.43,'#0007');ellipse(g,u.x,u.y,u.r*1.35,u.r*.56,u.team===0?'#c5b57999':'#d5716999',true,1.4);if(u.animCast>0){const r=u.r*2+(Math.sin(T*6)+1)*5;ellipse(g,u.x,u.y,r,r*.5,`hsla(${u.hue},90%,75%,.6)`,true,1);glow(g,u.x,u.y-24,65,`hsla(${u.hue},80%,65%,.24)`)}if(u.dash&&PREFS.effects){g.save();g.globalAlpha=.16;g.translate(-u.face*18,0);drawArtRig(g,u,T);g.restore()}}
 for(const u of live){drawArtRig(g,u,T);const h=u.visualHeight||75;if(u.s.shield>0){ellipse(g,u.x,u.y-h*.46,u.r*1.55,h*.59,'#a2e4ec55',true,1.6)}if(u.s.stun>0){g.fillStyle='#e4c876';g.textAlign='center';g.font='13px sans-serif';g.fillText('✦  ✦  ✦',u.x,u.y-h-18)}if(u.s.root>0){g.strokeStyle='#73a480';g.lineWidth=2;for(let i=-2;i<=2;i++){g.beginPath();g.moveTo(u.x+i*5,u.y);g.quadraticCurveTo(u.x+i*8,u.y-8,u.x+i*5,u.y-15);g.stroke()}}if(u.s.silence>0){g.fillStyle='#c4a5dc';g.font='10px sans-serif';g.fillText('SILENCED',u.x,u.y-h-17)}}
 for(const p of S.proj){const y=p.y-28-(p.lob?Math.sin(clamp(1-Math.hypot(p.t.x-p.x,p.t.y-p.y)/p.d0,0,1)*Math.PI)*65:0);g.strokeStyle=p.c;g.lineWidth=p.lob?4:2;g.beginPath();g.moveTo(p.px??p.x-8,p.py!=null?p.py-28:y);g.lineTo(p.x,y);g.stroke();glow(g,p.x,y,p.lob?13:9,p.c,.7);ellipse(g,p.x,y,p.lob?5:2.5,p.lob?5:2.5,p.c||'#d6c9a0')}
 battlefieldEffects(g,S,T);
 const dt=S.renderDt||0;S.parts=S.parts.filter(p=>(p.t+=dt)<p.ttl);if(PREFS.effects)for(const p of S.parts){if(p.to){const dx=p.to.x-p.x,dy=p.to.y-p.y,d=Math.hypot(dx,dy)||1;p.x+=dx/d*140*dt;p.y+=dy/d*140*dt;if(d<8||!p.to.alive)p.t=p.ttl}else{p.x+=p.vx*dt;p.y+=p.vy*dt;p.z+=p.vz*dt;p.vz-=p.g*dt;if(p.z<0){p.z=0;p.vz*=-.3}}g.globalAlpha=Math.max(0,Math.min(1,(1-p.t/p.ttl)*3));ellipse(g,p.x,p.y-p.z,Math.max(.8,p.s),Math.max(.8,p.s),p.c)}g.globalAlpha=1;
 for(const u of live)drawCombatBars(g,u);
 for(const f of S.fx)if(f.k==='txt'){const k=f.t/f.ttl;g.globalAlpha=Math.max(0,1-k*k);g.font=`600 ${Math.max(11,Math.min(19,f.z||12))}px "DM Sans",sans-serif`;g.textAlign='center';g.strokeStyle='#071119';g.lineWidth=3;g.strokeText(f.s,f.x,f.y-28-k*30);g.fillStyle=f.c;g.fillText(f.s,f.x,f.y-28-k*30)}g.globalAlpha=1;
 if(PREFS.effects){const v=g.createRadialGradient(CX,CY,230,CX,CY,730);v.addColorStop(0,'transparent');v.addColorStop(1,'#020711a0');g.fillStyle=v;g.fillRect(0,0,W,H)}g.restore();
 const big=S.done?(S.winner===0?'VICTORY':'VALOR IN DEFEAT'):msg;if(big){g.fillStyle='#08141ee0';g.fillRect(0,CY-54,W,112);g.strokeStyle='#bba46a66';g.lineWidth=1;g.beginPath();g.moveTo(240,CY-54);g.lineTo(1040,CY-54);g.moveTo(240,CY+58);g.lineTo(1040,CY+58);g.stroke();g.font='500 43px "Cinzel",Georgia';g.textAlign='center';g.fillStyle=S.done?(S.winner===0?'#ecd59c':'#dcb8b0'):'#f0e5cf';g.fillText(big,CX,CY+9);g.font='10px "DM Sans",sans-serif';g.fillStyle='#96b1bb';g.fillText(S.done?'THE ARENA WILL REMEMBER':msg==='READY'?'YOUR CHAMPIONS TAKE THEIR PLACES':'LET THEIR LEGEND BEGIN',CX,CY+35)}
};
startBattle=function(S){stopBattle();document.body.dataset.mode='battle';const cv=$('#cv'),dpr=Math.min(1.5,devicePixelRatio||1),g=cv.getContext('2d');cv.width=W*dpr;cv.height=H*dpr;g.setTransform(dpr,0,0,dpr,0,0);BT={S,speed:1,paused:false,raf:0,frame:0,endAt:0,feedN:-1,t0:0,last:0,acc:0,elapsed:0};S.vt=0;
 const loop=now=>{if(!BT||BT.S!==S)return;const dt=BT.last?Math.min(.1,(now-BT.last)/1000):0;BT.last=now;const active=!BT.paused&&!document.hidden;if(active)BT.elapsed+=dt;const intro=BT.elapsed<1.5;S.renderDt=active?dt*BT.speed:0;if(active)S.vt+=dt*BT.speed;
  if(active&&!intro&&!S.done){BT.acc+=dt*BT.speed;let guard=0;while(BT.acc>=1/60&&guard++<30){step(S,1/60);BT.acc-=1/60;if(S.done){BT.acc=0;break}}}else BT.acc=0;
  drawBattle(g,S,intro?(BT.elapsed<.85?'READY':'FIGHT'):null);if(BT.frame++%6===0)updateSides(S);
  if(S.done){BT.endAt+=active?dt:0;if(BT.endAt>2.2){finishMatch(S);return}}BT.raf=requestAnimationFrame(loop)};
 BT.raf=requestAnimationFrame(loop);updateSides(S);
};
document.addEventListener('visibilitychange',()=>{if(BT)BT.last=0});

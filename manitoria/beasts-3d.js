'use strict';
// Original articulated meshes. One WebGL context renders every portrait and arena beast.
// The small 2D canvases only composite the live 3D renders into the existing interface.
const Beast3D=(()=>{
 const T=THREE, models=new Map(), materials=new Map(), portraits=new Set(), cache=new Map();
 let activeSpecies="direwolf";
 const geo={orb:new T.SphereGeometry(1,24,16),facet:new T.IcosahedronGeometry(1,1),cone:new T.ConeGeometry(1,1,10),box:new T.BoxGeometry(1,1,1)};
 const colors={minotaur:['#643f37','#d0a366'],golem:['#526477','#60dfdd'],troll:['#648077','#e6b46e'],wendigo:['#485357','#c3dfcf'],direwolf:['#50667a','#9ce6eb'],manticore:['#ad6753','#edb76a'],griffin:['#c1aa7d','#f6dba0'],kitsune:['#e7cfb4','#eb7868'],wyvern:['#466d71','#9fdbc3'],harpy:['#916c9d','#d9b5d9'],phoenix:['#df673b','#ffcf6e'],kirin:['#61a7a9','#b8f2de'],basilisk:['#71916b','#f0d68d'],treant:['#725b40','#a3c783'],naga:['#527e72','#d6c16a'],unicorn:['#d7dfda','#c2b5ee'],cerberus:['#413e48','#ef916b'],nemean:['#b79352','#f5d69b'],yeti:['#c1cdd3','#7ebbd6'],zaratan:['#627c70','#c8b789'],owlbear:['#887160','#efce95'],hydra:['#588678','#dbb868'],chimera:['#9b7969','#dad09a'],gargoyle:['#6c7080','#b8bcce'],nekomata:['#595369','#dfafd4'],jackalope:['#9c8880','#f1d4a9'],cyclops:['#887168','#dac393'],thunderbird:['#405f84','#a7def0'],sphinx:['#ba9c65','#95c6d2'],pegasus:['#c9d9df','#e4cbb7'],arachne:['#64526b','#d7a0c7'],salamander:['#8c493d','#ffac59']};
 function mat(c,metal=false,glow=false,hint){return BeastMaterials.material(activeSpecies,c,metal,glow,hint||(['#e9dfc5','#d6d1b8','#ded2b4'].includes(c)?'bone':['#27303a','#1a242e','#20232a'].includes(c)?'chitin':undefined))}
 function part(p,g,c,pos,scale,metal=false,glow=false){const geometry=activeSpecies==='golem'&&g==='orb'&&!glow&&c===colors.golem[0]?geo.facet:geo[g]||g,m=new T.Mesh(geometry,mat(c,metal,glow));m.position.set(...pos);m.scale.set(...scale);m.castShadow=m.receiveShadow=true;p.add(m);return m}

 function group(p,pos=[0,0,0]){const g=new T.Group();g.position.set(...pos);p.add(g);return g}
 function rod(p,a,b,r,c,r2){const A=new T.Vector3(...a),B=new T.Vector3(...b),len=A.distanceTo(B),g=new T.CylinderGeometry(r2??r*.7,r,len,9);const m=part(p,g,c,A.clone().add(B).multiplyScalar(.5).toArray(),[1,1,1]);m.quaternion.setFromUnitVectors(new T.Vector3(0,1,0),B.sub(A).normalize());return m}
 function curve(p,points,r,c){const path=new T.CatmullRomCurve3(points.map(a=>new T.Vector3(...a)));return part(p,new T.TubeGeometry(path,16,r,7,false),c,[0,0,0],[1,1,1])}
 function horn(p,x,y,z,s,c){const pts=[[x,y,z],[x+s*.22,y+.22,z-.04],[x+s*.32,y+.56,z+.08],[x+s*.20,y+.8,z+.25]];curve(p,pts,.085,c);const tip=part(p,'cone',c,pts[3],[.085,.24,.085]);tip.rotation.z=-s*.3}
 function head(p,pos,scale,body,accent,kind='beast',eyes=2){const h=group(p,pos);h.scale.setScalar(scale);part(h,kind==='stone'?'facet':'orb',body,[0,0,0],[.43,.40,.43]);
  if(kind==='beak'){const b=part(h,'cone',accent,[0,-.10,.47],[.23,.48,.21]);b.rotation.x=Math.PI/2}
  else if(['stone','face','bark'].includes(kind)){part(h,kind==='stone'?'box':'facet',body,[0,-.14,.32],[.36,.28,.18]);part(h,'facet',kind==='stone'?accent:body,[0,-.03,.42],[.095,.13,.10],false,kind==='stone');part(h,'box','#27303a',[0,-.25,.40],[.28,.025,.025]);if(kind==='bark')for(const s of [-1,1])rod(h,[s*.1,-.3,.3],[s*.18,-.65,.2],.075,body,.01)}
  else {part(h,'orb',kind==='skull'?'#d6d1b8':body,[0,-.14,.36],[.31,.24,kind==='horse'?.47:.29]);part(h,'orb','#27303a',[0,-.08,kind==='horse'?.78:.60],[.19,.09,.10]);part(h,'box','#20232a',[0,-.24,.52],[.33,.024,.035])}
  for(const s of (eyes===1?[0]:[-1,1])){part(h,'orb','#1a242e',[s*.25,.055,.35],[eyes===1?.19:.115,.085,.065]);part(h,'orb',accent,[s*.25,.065,.406],[eyes===1?.11:.047,.044,.024],false,true);part(h,'orb','#e7f0df',[s*.25-.016,.083,.431],[.012,.012,.009]);if(s){const brow=part(h,'facet',body,[s*.26,.17,.36],[.20,.075,.115]);brow.rotation.z=s*.22}}
  if(!['beak','skull','stone','face','bark'].includes(kind))for(const s of [-1,1]){const ear=part(h,'cone',body,[s*.34,.40,-.07],[.16,kind==='rabbit'?.70:.35,.15]);ear.rotation.z=-s*.3;part(h,'cone',accent,[s*.34,.41,.01],[.075,kind==='rabbit'?.48:.16,.025])}
  if(['skull','bull'].includes(kind))for(const s of [-1,1])horn(h,s*.37,.20,-.04,s,accent);
  if(['wolf','cat','beast','skull','bull'].includes(kind))for(const s of [-1,1]){const tooth=part(h,'cone','#e9dfc5',[s*.20,-.27,.5],[.045,.17,.045]);tooth.rotation.z=Math.PI}
  return h;
 }
 function make(sp){if(models.has(sp))return models.get(sp);return BeastMaterials.build(()=>makeMesh(sp))}
 function makeMesh(sp){if(models.has(sp))return models.get(sp);activeSpecies=sp;const [body,accent]=colors[sp]||colors.direwolf,root=new T.Group(),rig=group(root),limbs=[],wings=[],tails=[],heads=[];
  const biped=['minotaur','golem','troll','wendigo','treant','yeti','cyclops','gargoyle','harpy','naga'].includes(sp),bird=['phoenix','thunderbird'].includes(sp),snake=['hydra','basilisk','salamander'].includes(sp),horse=['kirin','unicorn','pegasus'].includes(sp),spider=sp==='arachne',turtle=sp==='zaratan';
  function leg(x,y,z,thick,length,arm=false){
   const pivot=group(rig,[x,y,z]),knee=group(pivot,[0,-length*.49,0]),ankle=group(knee,[0,-length*.47,.04]),side=x>0?1:-1;
   const limb={pivot,knee,ankle,side,phase:(side>0?Math.PI:0)+(z<0?Math.PI:0),arm,thick,length,quadruped:!biped&&!bird&&!spider,front:z>0,baseZ:0};limbs.push(limb);
   part(pivot,'orb',body,[0,-length*.24,0],[thick*1.12,length*.29,thick]);part(knee,'orb',body,[0,-length*.1,0],[thick*.8,.15,thick*.85]);part(knee,'orb',body,[0,-length*.29,.03],[thick*.63,length*.24,thick*.72]);
   part(ankle,horse?'box':'orb',horse?'#434950':body,[0,0,.10],[thick*1.10,.12,thick*1.45]);
   if(!horse)for(let c=-1;c<=1;c++){part(ankle,'orb',body,[c*thick*.63,-.015,thick*1.34],[thick*.30,.08,.12]);part(ankle,'cone','#ded2b4',[c*thick*.63,-.025,thick*1.83],[.035,.15,.04]).rotation.x=Math.PI*.57}
   return pivot;
  }
  function tail(x,z,n=0){const p=group(rig,[x,biped?.8:.85,z]);tails.push(p);p.userData.baseYaw=n;p.userData.chain=[];p.rotation.y=n;
   let parent=p;const thick=sp==='kitsune'?.18:sp==='nekomata'?.09:.085;
   for(let j=0;j<4;j++){const joint=group(parent,j?[0,.13,-.28]:[0,0,0]);curve(joint,[[0,0,0],[0,.065,-.14],[0,.13,-.28]],thick*(1-j*.16),body);p.userData.chain.push(joint);parent=joint}
   part(parent,'orb',accent,[0,.13,-.30],[.10,.14,.17]);return p;
  }
  function wing(side,feather=true){const p=group(rig,[side*.43,biped?1.8:1.2,-.28]),outer=group(p,[side*.72,.48,-.10]),w={pivot:p,outer,side,feathers:[]};wings.push(w);
   rod(p,[0,0,0],[side*.72,.48,-.10],.105,body);rod(outer,[0,0,0],[side*1.05,-.03,-.12],.065,accent);
   if(feather){const shape=new T.Shape();shape.moveTo(0,.13);shape.bezierCurveTo(-.18,-.18,-.14,-.60,0,-1);shape.bezierCurveTo(.14,-.60,.18,-.18,0,.13);const fg=new T.ExtrudeGeometry(shape,{depth:.038,bevelEnabled:true,bevelSegments:1,steps:1,bevelSize:.025,bevelThickness:.025,curveSegments:5});
    for(let row=0;row<2;row++)for(let i=0;i<8;i++){const f=group(outer,[side*(i*.145-.16),-.02-row*.10,-row*.065]),color=i%3?body:accent,m=part(f,fg,color,[0,0,0],[1-row*.22,.7+i*.025-row*.20,1]);m.material=BeastMaterials.material(sp,color,false,false,'feather');f.rotation.z=side*(-.55+i*.025);w.feathers.push({pivot:f,rest:f.rotation.z,phase:i*.23+row})}
   }else{const shape=new T.Shape();shape.moveTo(-side*.7,-.4);shape.lineTo(0,0);shape.lineTo(side*1.15,-.03);shape.lineTo(side*.91,-.94);shape.quadraticCurveTo(side*.5,-.55,side*.37,-1.02);shape.quadraticCurveTo(side*.05,-.59,-side*.7,-.55);const material=BeastMaterials.material(sp,body,false,false,'hide').clone();material.side=T.DoubleSide;material.roughness=.82;const membrane=new T.Mesh(new T.ShapeGeometry(shape),material);membrane.position.z=-.09;outer.add(membrane);for(let i=0;i<3;i++)rod(outer,[0,0,-.05],[side*(.35+i*.29),-.96+i*.025,-.05],.022,accent)}
  }
  if(biped){part(rig,'orb',body,[0,1.5,0],[sp==='wendigo'?.40:.64,.74,.37]);part(rig,'orb',body,[0,.92,0],[.43,.38,.30]);
   if(sp==='naga'){curve(rig,[[0,.9,0],[.4,.45,0],[.6,.2,-.5],[0,.16,-.9],[-.6,.17,-.3],[-.6,.2,.5]],.28,body);tail(-.6,.5)}
   else {leg(-.28,.88,0,.23,.69);leg(.28,.88,0,.23,.69)}
   const a=leg(-.72,1.9,0,.24,.83,true),b=leg(.72,1.9,0,.24,.83,true);a.rotation.z=-.15;b.rotation.z=.15;
   const kind=sp==='minotaur'?'bull':sp==='wendigo'?'skull':sp==='harpy'?'beak':['golem','gargoyle'].includes(sp)?'stone':sp==='treant'?'bark':'face';heads.push(head(rig,[0,2.30,.08],sp==='cyclops'?1.15:1,body,accent,kind,sp==='cyclops'?1:2));
   for(const s of [-1,1]){part(rig,'facet',sp==='golem'?body:accent,[s*.66,1.98,-.02],[.37,.22,.37],sp!=='treant');part(rig,'facet',accent,[s*.25,.95,.28],[.23,.30,.08],true)}
   part(rig,'facet',accent,[0,1.55,.38],[.20,.27,.065],true);part(rig,'facet',sp==='golem'?'#c0fff2':accent,[0,1.56,.45],[.095,.14,.035],false,sp==='golem');
   if(sp==='treant'){for(const s of [-1,1]){curve(rig,[[s*.4,2,-.15],[s*.65,2.55,-.2],[s*.9,2.95,-.2]],.07,body);part(rig,'facet',accent,[s*.72,2.7,-.12],[.44,.36,.35])}}
   if(sp==='wendigo')for(const s of [-1,1]){curve(rig,[[s*.25,2.6,0],[s*.6,2.95,-.1],[s*.7,3.35,-.16]],.05,accent);for(let i=0;i<3;i++)rod(rig,[s*(.48+i*.08),2.8+i*.18,-.1],[s*(.76+i*.14),2.91+i*.18,-.1],.035,accent,.005)}
   if(['yeti','troll'].includes(sp))for(let i=0;i<9;i++)part(rig,'cone',body,[Math.sin(i)*.5,1.8+Math.cos(i)*.35,-.15],[.18,.55,.15]).rotation.z=i;
  }else if(bird){part(rig,'orb',body,[0,1.20,0],[.45,.6,.42]);heads.push(head(rig,[0,1.92,.14],.84,body,accent,'beak'));leg(-.2,.76,.05,.085,.51);leg(.2,.76,.05,.085,.51);for(let i=-2;i<=2;i++){const f=part(rig,'orb',i%2?accent:body,[i*.14,.60,-.7],[.10,.7,.06]);f.rotation.x=-.85;f.rotation.z=i*.16}wing(-1);wing(1);
  }else if(spider){part(rig,'orb',body,[0,.78,-.3],[.70,.50,.83]);part(rig,'orb',accent,[0,.95,-.58],[.40,.37,.43]);heads.push(head(rig,[0,.70,.57],.85,body,accent,'beast'));for(const s of [-1,1])for(let i=0;i<4;i++){const p=group(rig,[s*.45,.72,.45-i*.33]);limbs.push({pivot:p,side:s,phase:i,arm:false});rod(p,[0,0,0],[s*.55,.30,0],.085,body);rod(p,[s*.55,.30,0],[s*.95,-.60,.3-i*.15],.065,body,.015)}}
  else {const long=snake?1.20:horse?.94:turtle?1.08:.86;part(rig,'orb',body,[0,.98,-.16],[turtle?.92:horse?.43:.58,turtle?.43:.51,long]);
   for(const x of [-1,1])for(const z of [-.7,.48])leg(x*(turtle?.73:.39),.82,z,turtle?.23:horse?.13:.20,horse?.73:.62);
   if(turtle){part(rig,'orb','#354f4b',[0,1.23,-.23],[1.04,.64,1.17]);for(let i=0;i<7;i++){const ang=i*Math.PI/3;part(rig,'facet',accent,[Math.sin(ang)*.61,1.65-(i===6?-.10:.14),-.20+Math.cos(ang)*.71],[.38,.17,.37])}}
   const count=sp==='hydra'?5:sp==='cerberus'||sp==='chimera'?3:1;
   for(let i=0;i<count;i++){const x=(i-(count-1)/2)*.60,hy=sp==='hydra'?1.65+Math.cos(i)*.30:horse?1.96:1.45,z=sp==='hydra'?.77:.85;
    if(horse||sp==='hydra')curve(rig,[[x*.3,1,0],[x,1.35,.5],[x,hy,z]],horse?.23:.18,body);
    const kind=horse?'horse':['griffin','owlbear'].includes(sp)?'beak':sp==='jackalope'?'rabbit':sp==='chimera'&&i===2?'bull':sp==='direwolf'?'wolf':['nemean','nekomata','sphinx','kitsune'].includes(sp)?'cat':'beast';
    const h=head(rig,[x,hy,z],count===1?(horse?.82:1):.68,body,accent,kind);heads.push(h);
    if(['unicorn','kirin','basilisk','wyvern'].includes(sp)){const a=part(h,'cone',accent,[0,.5,.22],[.10,.78,.10],true);a.rotation.x=.25}
    if(['nemean','manticore','sphinx','chimera'].includes(sp))for(let j=0;j<12;j++){const ang=j*Math.PI/6;const mane=part(h,'cone',accent,[Math.sin(ang)*.43,Math.cos(ang)*.43,-.15],[.16,.37,.15]);mane.rotation.z=-ang}
    if(sp==='jackalope')for(const s of [-1,1])horn(h,s*.34,.50,-.15,s,accent);
   }
   const nt=sp==='kitsune'?7:sp==='nekomata'?2:1;for(let i=0;i<nt;i++)tail((i-(nt-1)/2)*.16,-.87,(i-(nt-1)/2)*.25);
   if(snake||sp==='wyvern')for(let i=0;i<7;i++)part(rig,'cone',accent,[0,1.39,-.9+i*.24],[.10,.3,.15]);
  }
  if(['griffin','harpy','pegasus','sphinx','wyvern','gargoyle','manticore'].includes(sp)){wing(-1,!['wyvern','gargoyle','manticore'].includes(sp));wing(1,!['wyvern','gargoyle','manticore'].includes(sp))}
  if(sp==='salamander')for(let i=0;i<5;i++)part(rig,'facet',accent,[0,1.42,-.9+i*.35],[.16,.22,.20],false,true);
  const detail=BeastSculpt.enrich({sp,rig,root,heads,limbs,wings,tails,body,accent,part,curve,rod});
  BeastSculpt.compile(rig);for(const l of limbs)l.baseZ=l.pivot.rotation.z;
  root.updateMatrixWorld(true);const box=new T.Box3().setFromObject(root),center=box.getCenter(new T.Vector3()),size=box.getSize(new T.Vector3());rig.position.sub(center);
  const model={root,rig,limbs,wings,tails,heads,base:rig.position.clone(),extent:Math.max(size.x,size.y,size.z)*(sp==='naga'?1.34:1.24),ground:-size.y/2,sp,family:detail.family};models.set(sp,model);return model;
 }

 let renderer,scene,camera,shadow,failed=false,renderSize=0;
 const animationStates=new Map();
 function environment(){const room=new T.Scene(),shell=new T.Mesh(new T.BoxGeometry(16,14,16),new T.MeshBasicMaterial({color:0x263039,side:T.BackSide}));room.add(shell);
  for(const [x,y,z,sx,sy,color] of [[-4,3,4,4,6,[5,4.2,3.2]],[4,2,0,2,5,[1.5,2.9,4]],[0,5,-4,5,3,[3,3.5,3.8]]]){const panel=new T.Mesh(new T.PlaneGeometry(sx,sy),new T.MeshBasicMaterial({color:new T.Color(...color),side:T.DoubleSide}));panel.position.set(x,y,z);panel.lookAt(0,0,0);room.add(panel)}
  const pmrem=new T.PMREMGenerator(renderer),target=pmrem.fromScene(room,.025,.1,30);scene.environment=target.texture;pmrem.dispose();room.traverse(o=>{o.geometry?.dispose();o.material?.dispose()});
 }
 function init(){return BeastMaterials.build(initRenderer)}
 function initRenderer(){if(renderer||failed)return !failed;try{renderer=new T.WebGLRenderer({alpha:true,antialias:true,preserveDrawingBuffer:true,powerPreference:'high-performance'});renderer.setPixelRatio(1);renderer.setSize(256,256,false);renderSize=256;renderer.outputColorSpace=T.SRGBColorSpace;renderer.toneMapping=T.ACESFilmicToneMapping;renderer.toneMappingExposure=1.04;scene=new T.Scene();scene.add(new T.HemisphereLight(0xb5d3de,0x32251b,1.15));const key=new T.DirectionalLight(0xffdeb1,3.1);key.position.set(-3,5,4);scene.add(key);const rim=new T.DirectionalLight(0x82cee4,2.7);rim.position.set(3,2,-4);scene.add(rim);const fill=new T.DirectionalLight(0xc9dcdf,.45);fill.position.set(0,0,5);scene.add(fill);camera=new T.PerspectiveCamera(31,1,.1,100);environment();
   const N=64,pixels=new Uint8Array(N*N*4);for(let y=0;y<N;y++)for(let x=0;x<N;x++){const i=(y*N+x)*4,r=Math.hypot((x-31.5)/31.5,(y-31.5)/31.5);pixels[i+3]=Math.round(Math.pow(Math.max(0,1-r),2)*160)}const texture=new T.DataTexture(pixels,N,N,T.RGBAFormat);texture.needsUpdate=true;shadow=new T.Mesh(new T.PlaneGeometry(1,1),new T.MeshBasicMaterial({map:texture,transparent:true,depthWrite:false,toneMapped:false}));shadow.rotation.x=-Math.PI/2;scene.add(shadow);
   renderer.domElement.addEventListener('webglcontextlost',e=>{e.preventDefault();failed=true});return true}catch(e){failed=true;console.warn('3D rendering unavailable',e);return false}}
 function pose(sp,time,opts={}){
  const m=make(sp),motion=opts.motion!==false,key=sp+(opts.preview?':preview':':portrait');if(!animationStates.has(key))animationStates.set(key,{});const state=opts.state||animationStates.get(key),dt=Math.max(0,Math.min(.1,time-(state.last??time))),blend=1-Math.exp(-dt*9);state.last=time;
  const move=motion&&!!opts.moving,cast=motion&&!!opts.casting;state.walk=(state.walk||0)+((move?1:0)-(state.walk||0))*blend;state.cast=(state.cast||0)+((cast?1:0)-(state.cast||0))*blend;state.death=(state.death||0)+((opts.dead?1:0)-(state.death||0))*(1-Math.exp(-dt*12));if(!motion){state.walk=state.cast=0;state.death=opts.dead?1:0}
  state.phase=(state.phase||0)+dt*(m.family==='stone'?6.5:9)*(move?Math.max(.45,Math.min(1.7,opts.speed||1)):1);const gait=state.phase,weight=state.walk*(1-state.death),idle=motion?time*1.65:0,casting=state.cast*(1-state.death),p=motion?(opts.strikePhase??(opts.windup!=null?.65*(1-opts.windup):opts.attack>0?.65+.35*(1-Math.min(1,opts.attack/.17)):0)):0,attack=Math.sin(Math.max(0,Math.min(1,p))*Math.PI),snap=p>.5?Math.sin((p-.5)*Math.PI*2):0;
  m.root.rotation.set(0,opts.angle??-.42,state.death*1.4);m.rig.position.copy(m.base);m.rig.position.y+=Math.abs(Math.sin(gait))*.042*weight+Math.sin(idle)*.012-state.death*.18;m.rig.position.z+=snap*.12;m.rig.rotation.set(-attack*.13+casting*.06,Math.sin(gait)*.025*weight,Math.sin(gait)*.025*weight);m.rig.scale.set(1+Math.sin(idle)*.004,1+Math.sin(idle)*.006,1+Math.sin(idle)*.005);
  for(const l of m.limbs){const stride=Math.sin(gait+l.phase),lift=Math.max(0,Math.cos(gait+l.phase));l.pivot.rotation.set(l.arm?stride*.27*weight-attack*1.12-casting*.95:stride*.43*weight+(l.quadruped?attack*(l.front?-.55:.15):0),l.arm?-l.side*attack*.16:0,l.baseZ+(l.arm?l.side*(casting*.38+Math.sin(idle+l.side)*.025):0));if(l.knee){l.knee.rotation.x=l.arm?-.12-attack*.65-casting*.35:lift*.65*weight+(l.quadruped&&l.front?attack*.4:0);l.ankle.rotation.x=l.arm?Math.PI/2+attack*.35:-stride*.18*weight-lift*.25*weight}}
  for(const w of m.wings){const flap=Math.sin(idle*1.8+(move?gait*.2:0));w.pivot.rotation.z=w.side*(.15+flap*(.1+weight*.16)+casting*.30+attack*.18);w.pivot.rotation.y=w.side*(.08+Math.cos(idle*1.8)*.045);w.outer.rotation.z=w.side*(Math.sin(idle*1.8-.45)*(.08+weight*.12));for(const f of w.feathers)f.pivot.rotation.z=f.rest+w.side*Math.sin(idle*1.8-f.phase)*.035*(1+weight)}
  for(const [i,t] of m.tails.entries()){t.rotation.y=t.userData.baseYaw+Math.sin(idle*.7+i*.45)*.12+Math.sin(gait-.6)*.09*weight;t.rotation.x=-attack*.18;for(const [j,joint] of (t.userData.chain||[]).entries()){joint.rotation.y=Math.sin(idle*1.25-j*.55+i*.4)*.14+Math.sin(gait-j*.4)*weight*.10;joint.rotation.x=Math.cos(idle-j*.4)*.055}}
  const blink=motion?Math.pow(Math.max(0,Math.cos(time*1.37+sp.length)),48):0;
  for(const [i,h] of m.heads.entries()){h.rotation.y=Math.sin(idle*.32+i*.9)*.045*(1-attack);h.rotation.x=Math.sin(idle*.6+i)*.016-Math.sin(gait+.4)*.04*weight+attack*.16-casting*.12;if(h.userData.jaw)h.userData.jaw.rotation.x=attack*.34+casting*(.08+Math.sin(idle*3)*.035);for(const lid of h.userData.lids||[])lid.scale.y=.004+blink*.083}
  m.rig.traverse(o=>{if(o.userData.aura){o.visible=motion&&(casting>.05||['phoenix','salamander'].includes(sp));o.rotation.y=motion?time*.45:0;o.position.y=motion?Math.sin(time*2)*.03:0}});return m;
 }
 function compose(m,opts={}){const zoom=opts.preview?Math.max(.85,Math.min(1.15,opts.zoom||1)):1;
  camera.position.set(m.extent*.72/zoom,m.extent*(opts.arena?.8:.29)/zoom,m.extent*1.75/zoom);camera.lookAt(0,0,0);shadow.visible=!opts.arena;shadow.position.set(0,m.ground-.03,0);shadow.scale.set(m.extent*.65,m.extent*.65,1);scene.add(m.root);renderer.clear();renderer.render(scene,camera);scene.remove(m.root);
 }
 function render(sp,time,opts={}){if(!init())return null;const m=pose(sp,time,opts),res=opts.preview?640:opts.arena?160:256;if(renderSize!==res){renderer.setSize(res,res,false);renderSize=res}compose(m,opts);return renderer.domElement}
 let batchCanvas;
 function renderBatch(entries){if(!entries.length||!init())return null;const tile=160,cols=Math.ceil(Math.sqrt(entries.length)),rows=Math.ceil(entries.length/cols),width=cols*tile,height=rows*tile,key=width+':'+height;if(renderSize!==key){renderer.setSize(width,height,false);renderSize=key}const tiles=[];renderer.setScissorTest(true);
  try{entries.forEach((entry,i)=>{const x=(i%cols)*tile,y=Math.floor(i/cols)*tile;renderer.setViewport(x,height-y-tile,tile,tile);renderer.setScissor(x,height-y-tile,tile,tile);compose(pose(entry.sp,entry.time,entry.opts),entry.opts);tiles.push({x,y,size:tile})})}finally{renderer.setScissorTest(false);renderer.setViewport(0,0,width,height)}
  if(!batchCanvas)batchCanvas=document.createElement('canvas');if(batchCanvas.width!==width||batchCanvas.height!==height){batchCanvas.width=width;batchCanvas.height=height}const g=batchCanvas.getContext('2d');g.clearRect(0,0,width,height);g.drawImage(renderer.domElement,0,0);return {canvas:batchCanvas,tiles};
 }

 function portraitFrame(sp,t,motion){let c=cache.get(sp);if(!c){c=document.createElement('canvas');c.width=c.height=256;cache.set(sp,c)}const cv=render(sp,t,{motion});if(cv){const g=c.getContext('2d');g.clearRect(0,0,256,256);g.drawImage(cv,0,0)}return c}
 function scan(){for(const el of document.querySelectorAll('.spr:not([data-model])')){const sp=[...el.classList].find(c=>c.startsWith('spr-'))?.slice(4);if(!colors[sp])continue;el.dataset.model=sp;el.style.backgroundImage='none';el.style.animation='none';const cv=document.createElement('canvas');cv.width=cv.height=256;cv.setAttribute('aria-hidden','true');el.append(cv);portraits.add(el)}for(const el of portraits)if(!el.isConnected)portraits.delete(el)}
 let last=0,needsScan=true;
 function tick(now){requestAnimationFrame(tick);if(document.hidden||now-last<(document.querySelector('.model-stage')?16:33))return;last=now;if(needsScan){scan();needsScan=false}const visible=[...portraits].filter(el=>{const r=el.getBoundingClientRect();return r.width&&r.height&&r.bottom>0&&r.top<innerHeight&&r.right>0&&r.left<innerWidth&&(!UI.modal||el.closest('.sheet'))});const frames=new Map();for(const el of visible){const sp=el.dataset.model,cv=el.querySelector('canvas'),g=cv?.getContext('2d');if(g){g.clearRect(0,0,cv.width,cv.height);if(el.closest('.model-stage')){if(cv.width!==640){cv.width=cv.height=640}const cycle=(now/1000)%1.7,frame=render(sp,now/1000,{motion:PREFS.motion,preview:true,angle:UI.modelAngle??-.42,moving:UI.modelPose==='walk',strikePhase:UI.modelPose==='strike'&&cycle<.85?cycle/.85:0,casting:UI.modelPose==='cast',zoom:UI.modelZoom||1});if(frame)g.drawImage(frame,0,0,640,640)}else{if(!frames.has(sp))frames.set(sp,portraitFrame(sp,now/1000,PREFS.motion));g.drawImage(frames.get(sp),0,0)}}if(failed){el.classList.add('model-unavailable');el.setAttribute('title','3D needs WebGL. Enable hardware acceleration in your browser.')}}}
 function start(){init();new MutationObserver(()=>{needsScan=true}).observe(document.body,{childList:true,subtree:true});requestAnimationFrame(tick);document.body.classList.add('beasts-3d')}
 return {make,pose,render,renderBatch,start,get available(){return !!renderer&&!failed},get species(){return Object.keys(colors)}};
})();

// No illustrated atlas or pixel-art fallback: every interface uses the mesh renderer.
spriteCss=function(){Beast3D.start();ART.ready=true;ART.promise=Promise.resolve()};
function desiredBeastHeading(u){let dx=0,dy=0;const target=u.dash?.t||u.target;if(target?.alive&&(u.dash||u.animAtk>0||u.animCast>0||Math.hypot(u.vx||0,u.vy||0)<12)){dx=target.x-u.x;dy=target.y-u.y}else if(Math.hypot(u.vx||0,u.vy||0)>4){dx=u.vx;dy=u.vy}else if(target?.alive){dx=target.x-u.x;dy=target.y-u.y}else dx=u.face||(!u.team?1:-1);return Math.atan2(.72,1.75)+Math.atan2(dx,dy/.62)}
function updateBeastHeading(u,time,dead=false){const goal=desiredBeastHeading(u);if(!Number.isFinite(u.modelHeading))u.modelHeading=goal;const dt=Math.max(0,Math.min(.1,time-(u.headingAt??time)));if(!dead){const turn=Math.atan2(Math.sin(goal-u.modelHeading),Math.cos(goal-u.modelHeading));u.modelHeading+=turn*(1-Math.exp(-14*dt))}u.headingAt=time;return u.modelHeading}
drawArtRig=function(g,u,time,dead=false){const sp=u.summon?(u.skin||u.sp||'direwolf'):u.sp,size=((SPECIES[sp]?.size||15)*2.5+65)*(u.summon?.58:1),angle=updateBeastHeading(u,time,dead),stamp=Math.floor(time*18)+':'+dead;
 if(u.modelStamp!==stamp){const frame=Beast3D.render(sp,time+(u.id||0)*.13,{motion:PREFS.motion&&!dead,moving:u.moved>0,attack:u.animAtk,casting:u.animCast>0,angle,dead,arena:true});if(!frame)return;if(!u.modelFrame){u.modelFrame=document.createElement('canvas');u.modelFrame.width=u.modelFrame.height=256}const ctx=u.modelFrame.getContext('2d');ctx.clearRect(0,0,256,256);ctx.drawImage(frame,0,0,256,256);u.modelStamp=stamp}
 g.save();if(dead)g.globalAlpha*=.3;if(u.s?.stealth>0)g.globalAlpha*=.3;if(u.flash>0)g.filter='brightness(1.6)';g.drawImage(u.modelFrame,u.x-size*.5,u.y-size*.87,size,size);g.restore();u.visualHeight=size*.76};
const modelProfile=modalProfile;modalProfile=function(m){const b=G.beasts[m.id];if(!b)return modelProfile(m);const family=BeastMaterials.families[b.sp],stage=`<section class="model-inspector"><div class="model-stage" role="img" aria-label="Animated 3D ${esc(SPECIES[b.sp].n)}. Drag to rotate.">${beastArt(b.sp)}<span class="model-surface">${family==='silk'?'SILKEN COAT':family.toUpperCase()}</span></div><div class="model-controls"><span class="lbl gold">DRAG TO ROTATE</span><div class="row"><button class="btn sm" data-act="modelTurn" data-dir="-1" aria-label="Rotate beast left">↶</button><button class="btn sm" data-act="modelTurn" data-dir="1" aria-label="Rotate beast right">↷</button>${['idle','walk','strike','cast'].map(p=>`<button class="btn sm ${(UI.modelPose||'idle')===p?'pri':''}" data-act="modelPose" data-k="${p}" aria-pressed="${(UI.modelPose||'idle')===p}">${p[0].toUpperCase()+p.slice(1)}</button>`).join('')}<button class="btn sm" data-act="modelZoom" aria-label="Toggle model close-up">${UI.modelZoom>1?'Full view':'Closer'}</button></div></div></section>`;return modelProfile(m).replace('<div class="seg" role="tablist"',`${stage}<div class="seg" role="tablist"`)};
ACT.modelTurn=d=>{UI.modelAngle=(UI.modelAngle??-.42)+Number(d.dir)*.5};ACT.modelPose=d=>{if(!['idle','walk','strike','cast'].includes(d.k))return;UI.modelPose=d.k;for(const el of document.querySelectorAll('[data-act="modelPose"]')){el.classList.toggle('pri',el.dataset.k===d.k);el.setAttribute('aria-pressed',String(el.dataset.k===d.k))}};
ACT.modelZoom=()=>{UI.modelZoom=UI.modelZoom>1?1:1.15;const el=document.querySelector('[data-act="modelZoom"]');if(el)el.textContent=UI.modelZoom>1?'Full view':'Closer'};

let modelDrag=null;
document.addEventListener('pointerdown',e=>{const stage=e.target.closest('.model-stage');if(!stage||e.button!==0)return;modelDrag={x:e.clientX,angle:UI.modelAngle??-.42,id:e.pointerId};stage.setPointerCapture(e.pointerId);e.preventDefault()});
document.addEventListener('pointermove',e=>{if(modelDrag&&e.pointerId===modelDrag.id)UI.modelAngle=modelDrag.angle+(e.clientX-modelDrag.x)*.012});
for(const ev of ['pointerup','pointercancel','lostpointercapture'])document.addEventListener(ev,()=>{modelDrag=null});




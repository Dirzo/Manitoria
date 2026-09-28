'use strict';
// Silhouette detail is instanced, keeping fur, feathers and scales inexpensive to draw.
const BeastSculpt=(()=>{
 const T=THREE,tuftGeo=new T.ConeGeometry(1,1,5),scaleGeo=new T.SphereGeometry(1,8,6),gemGeo=new T.OctahedronGeometry(1,0),dummy=new T.Object3D();
 const hash=n=>{const x=Math.sin(n*127.1+31.7)*43758.5453;return x-Math.floor(x)};
 function batch(parent,geometry,material,items){if(!items.length)return null;const mesh=new T.InstancedMesh(geometry,material,items.length);items.forEach((p,i)=>{dummy.position.set(...p.p);dummy.rotation.set(...(p.r||[0,0,0]));dummy.scale.set(...p.s);dummy.updateMatrix();mesh.setMatrixAt(i,dummy.matrix)});mesh.instanceMatrix.needsUpdate=true;mesh.computeBoundingBox();mesh.computeBoundingSphere();mesh.userData.detailInstances=items.length;parent.add(mesh);return mesh}
 // Bake rigid pieces together within each joint. Animated pivots stay independent.
 function compile(parent){for(const child of [...parent.children])if(child.isGroup)compile(child);const groups=new Map();for(const mesh of parent.children){if(!mesh.isMesh||mesh.isInstancedMesh||mesh.userData.animated||!mesh.geometry.attributes.uv)continue;const key=mesh.material.uuid;if(!groups.has(key))groups.set(key,[]);groups.get(key).push(mesh)}
  for(const meshes of groups.values()){if(meshes.length<2)continue;const pieces=meshes.map(mesh=>{mesh.updateMatrix();const g=mesh.geometry.clone();return g.applyMatrix4(mesh.matrix)}),merged=new T.BufferGeometry();for(const key of ['position','normal','uv']){const arrays=pieces.map(g=>g.attributes[key]),length=arrays.reduce((n,a)=>n+a.array.length,0),data=new Float32Array(length);let offset=0;for(const a of arrays){data.set(a.array,offset);offset+=a.array.length}merged.setAttribute(key,new T.BufferAttribute(data,arrays[0].itemSize))}const indices=[];let vertexOffset=0;for(const g of pieces){const count=g.attributes.position.count;if(g.index)for(const n of g.index.array)indices.push(n+vertexOffset);else for(let n=0;n<count;n++)indices.push(n+vertexOffset);vertexOffset+=count}merged.setIndex(indices);merged.computeBoundingBox();merged.computeBoundingSphere();const mesh=new T.Mesh(merged,meshes[0].material);mesh.castShadow=mesh.receiveShadow=true;mesh.userData.bakedParts=meshes.length;for(const old of meshes)parent.remove(old);parent.add(mesh);for(const g of pieces)g.dispose()}
 }
 function enrich({sp,rig,heads,limbs,wings,tails,body,accent,part,curve,rod}){
  const family=BeastMaterials.families[sp],skin=BeastMaterials.material(sp,body),fur=BeastMaterials.material(sp,body,false,false,'fur'),bone=BeastMaterials.material(sp,'#b5a78a',false,false,'bone');
  const isFur=['fur','silk'].includes(family),items=[];
  // Chest and shoulder shapes replace the impression of a single round toy body.
  if(['minotaur','troll','wendigo','yeti','cyclops','golem','treant','gargoyle'].includes(sp)){
   for(const s of [-1,1]){part(rig,sp==='golem'?'facet':'orb',body,[s*.29,1.72,.28],[sp==='wendigo'?.2:.34,.27,.18]);part(rig,'orb',body,[s*.47,1.4,-.14],[.24,.43,.27])}
   for(let i=0;i<3;i++)for(const s of [-1,1])part(rig,'facet',body,[s*.14,1.4-i*.15,.335],[.16,.11,.1]);
  }
  if(isFur){
   const white=sp==='yeti',rough=sp!=='unicorn'&&sp!=='pegasus';
   for(let i=0;i<(rough?80:24);i++){const a=hash(i+9)*Math.PI*2,z=(hash(i+51)-.5)*1.55;items.push({p:[Math.sin(a)*.53,.97+Math.cos(a)*.43,z-.1],s:[.09,.18+hash(i+81)*.16,.065],r:[.4+hash(i)*.35,0,Math.PI+Math.sin(a)*.8]})}
   if(!['minotaur','yeti','wendigo'].includes(sp))batch(rig,tuftGeo,fur,items);
   for(const h of heads){const tufts=[];for(let i=0;i<(white?38:26);i++){const a=i/(white?38:26)*Math.PI*2,extra=['nemean','manticore','sphinx','chimera'].includes(sp)?.16:0;tufts.push({p:[Math.sin(a)*(.39+extra),Math.cos(a)*(.38+extra),-.13],s:[.12,.24+extra+hash(i)*.18,.11],r:[-.18,0,-a]})}batch(h,tuftGeo,fur,tufts)}
   for(const l of limbs){const cuffs=[];for(let i=0;i<8;i++){const a=i*Math.PI/4;cuffs.push({p:[Math.sin(a)*l.thick*.85,-l.length*.35,Math.cos(a)*l.thick*.9],s:[.08,.22,.07],r:[0,a,Math.PI]})}batch(l.pivot,tuftGeo,fur,cuffs)}
  }
  if(['scale','chitin'].includes(family)){
   const plates=[];for(let row=0;row<8;row++)for(let col=0;col<5;col++){const a=(col-2)*.37,z=-.95+row*.25;plates.push({p:[Math.sin(a)*.53,.98+Math.cos(a)*.45,z],s:[.15,.035,.18],r:[0,0,-a]})}batch(rig,scaleGeo,skin,plates);
   for(const h of heads){const ridges=[];for(const side of [-1,1])for(let i=0;i<4;i++)ridges.push({p:[side*(.27+i*.035),.24-i*.12,.10],s:[.08,.17,.06],r:[-.3,0,-side*.75]});batch(h,tuftGeo,bone,ridges)}
  }
  if(family==='stone'){
   const mineral=BeastMaterials.material(sp,sp==='golem'?'#435866':'#60646b',false,false,'stone'),glow=BeastMaterials.material(sp,accent,false,true);
   for(const l of limbs)part(l.pivot,'facet',sp==='golem'?'#435866':body,[0,-l.length*.35,.13],[l.thick*1.22,l.length*.29,.17]);
   for(let i=0;i<5;i++){const y=1.24+i*.13;curve(rig,[[-.17,y,.39],[0,y-.06,.455],[.17,y,.39]],.012,accent)}
   const crystals=[];for(const side of [-1,1])for(let i=0;i<3;i++)crystals.push({p:[side*(.65+i*.09),1.94+i*.07,-.13-i*.05],s:[.09,.24+i*.025,.09],r:[0,0,-side*(.35+i*.17)]});if(sp!=='zaratan')batch(rig,gemGeo,glow,crystals);
   if(sp==='zaratan'){const scutes=[];for(let i=0;i<12;i++){const a=i*Math.PI/6;scutes.push({p:[Math.sin(a)*.78,1.41,-.23+Math.cos(a)*.94],s:[.25,.14,.26],r:[0,a,0]})}batch(rig,gemGeo,mineral,scutes)}
  }
  if(sp==='treant')for(const side of [-1,1]){for(let i=0;i<4;i++){const x=side*(.18+i*.08);curve(rig,[[x,.86,.25],[x*.6,1.37,.43],[x*1.5,1.92,.33]],.022,'#a08652')}const leaves=[];for(let i=0;i<28;i++)leaves.push({p:[side*(.5+hash(i)*.6),2.4+hash(i+20)*.6,-.12+(hash(i+80)-.5)*.6],s:[.15,.045,.23],r:[hash(i)*2,hash(i+10)*6,hash(i+30)*3]});batch(rig,scaleGeo,BeastMaterials.material(sp,'#66864c',false,false,'feather'),leaves)}
  if(['unicorn','pegasus','kirin','nemean','sphinx'].includes(sp)){
   const gold=BeastMaterials.material(sp,'#ae8749',true),inlays=[];for(let i=0;i<7;i++)inlays.push({p:[Math.sin(i*Math.PI/6)*.43,1.28+Math.cos(i*Math.PI/6)*.23,.55],s:[.06,.08,.035],r:[0,0,i*.1]});batch(rig,gemGeo,gold,inlays);
   if(['unicorn','pegasus'].includes(sp))for(const h of heads){const mane=[];for(let i=0;i<12;i++)mane.push({p:[0,.3-i*.065,-.31],s:[.11,.27,.12],r:[.3+i*.04,0,Math.PI]});batch(h,tuftGeo,BeastMaterials.material(sp,accent,false,false,'silk'),mane)}
  }
  if(sp==='arachne'){const marks=[];for(let i=0;i<7;i++)marks.push({p:[0,1.24,-.8+i*.15],s:[.19,.025,.065],r:[0,0,0]});batch(rig,gemGeo,BeastMaterials.material(sp,accent,false,false,'chitin'),marks)}
  if(['phoenix','salamander','kirin','thunderbird'].includes(sp)){const sparks=[];for(let i=0;i<14;i++)sparks.push({p:[(hash(i)-.5)*1.6,.7+hash(i+20)*1.4,(hash(i+40)-.5)*1.5],s:[.018+hash(i)*.014,.065,.018],r:[0,i,0]});const embers=batch(rig,gemGeo,BeastMaterials.material(sp,accent,false,true),sparks);embers.userData.aura=true}
  // More mature facial proportions, recessed eyelids and a separate lower jaw.
  for(const h of heads){h.scale.multiplyScalar(['cyclops','hydra'].includes(sp)?1:.94);const jaw=new T.Group();jaw.position.set(0,-.20,.21);h.add(jaw);part(jaw,'orb',body,[0,-.095,.16],[.255,.115,.23]);h.userData.jaw=jaw;h.userData.lids=[];
   const count=sp==='cyclops'?[0]:[-1,1];for(const side of count){const lid=part(h,'orb',body,[side*.25,.067,.413],[side?.123:.20,.005,.035]);lid.userData.animated=true;h.userData.lids.push(lid)}
   if(!['unicorn','pegasus','kirin','treant','golem','gargoyle'].includes(sp))for(const side of [-1,1])part(jaw,'cone','#ded2b4',[side*.16,-.025,.30],[.035,.12,.035]);
  }
  return {family};
 }
 return {enrich,batch,compile};
})();

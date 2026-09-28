'use strict';
// Deterministic, seamless PBR surfaces. Generated locally; no remote texture requests.
const BeastMaterials=(()=>{
 const T=THREE,textures=new Map(),materials=new Map(),N=256;
 // Three.js allocates random UUIDs. Keep those allocations off the combat RNG.
 let visualSeed=0x59f12cab;
 function build(fn){const original=Math.random;Math.random=()=>{visualSeed^=visualSeed<<13;visualSeed^=visualSeed>>>17;visualSeed^=visualSeed<<5;return (visualSeed>>>0)/4294967296};try{return fn()}finally{Math.random=original}}
 const families={minotaur:'hide',golem:'stone',troll:'hide',wendigo:'fur',direwolf:'fur',manticore:'fur',griffin:'feather',kitsune:'fur',wyvern:'scale',harpy:'feather',phoenix:'feather',kirin:'scale',basilisk:'scale',treant:'bark',naga:'scale',unicorn:'silk',cerberus:'fur',nemean:'fur',yeti:'fur',zaratan:'stone',owlbear:'fur',hydra:'scale',chimera:'fur',gargoyle:'stone',nekomata:'fur',jackalope:'fur',cyclops:'hide',thunderbird:'feather',sphinx:'fur',pegasus:'silk',arachne:'chitin',salamander:'scale'};
 const clamp01=x=>Math.max(0,Math.min(1,x)),fract=x=>x-Math.floor(x),hash=(x,y)=>fract(Math.sin(x*127.1+y*311.7)*43758.5453),smooth=x=>x*x*(3-2*x);
 function noise(x,y,period){let ix=Math.floor(x),iy=Math.floor(y),fx=smooth(fract(x)),fy=smooth(fract(y));const h=(a,b)=>hash((a%period+period)%period,(b%period+period)%period);return (h(ix,iy)*(1-fx)+h(ix+1,iy)*fx)*(1-fy)+(h(ix,iy+1)*(1-fx)+h(ix+1,iy+1)*fx)*fy}
 function sample(kind,u,v){const grain=noise(u*64,v*64,64),broad=noise(u*8,v*8,8),fine=hash((Math.floor(u*N)%N+N)%N,(Math.floor(v*N)%N+N)%N);let height=.5,tone=.84,rough=.78;
  if(kind==='fur'||kind==='silk'){const density=kind==='silk'?100:64,flow=u*density+Math.sin(v*Math.PI*8)*.6,streak=Math.pow(.5+.5*Math.sin(flow*Math.PI*2),7);height=.3+streak*.2+grain*.12;tone=.62+broad*.20+grain*.12+streak*.1;rough=kind==='silk'?.48:.86}
  else if(kind==='scale'||kind==='chitin'){const rows=kind==='chitin'?12:20,col=kind==='chitin'?8:14,y=v*rows,row=Math.floor(y),x=fract(u*col+(row%2)*.5)-.5,z=fract(y),edge=Math.sqrt(x*x*3.4+(z-.30)*(z-.30)*1.5),plate=clamp01((.76-edge)*8);height=plate*(.45+Math.max(0,.5-z)*.55)+grain*.05;tone=.40+plate*.42+broad*.12+Math.max(0,.1-Math.abs(z-.12))*.8;rough=kind==='chitin'?.28:.5}
  else if(kind==='stone'){const x=u*8,y=v*8,ix=Math.floor(x),iy=Math.floor(y);let first=9,second=9;for(let a=-1;a<=1;a++)for(let b=-1;b<=1;b++){const hx=(ix+a+8)%8,hy=(iy+b+8)%8,dx=ix+a+hash(hx,hy)*.8-x,dy=iy+b+hash(hy,hx+31)*.8-y,d=dx*dx+dy*dy;if(d<first){second=first;first=d}else second=Math.min(second,d)}const fissure=clamp01((Math.sqrt(second)-Math.sqrt(first))*12);height=.2+fissure*.35+broad*.18+grain*.1;tone=.38+fissure*.35+broad*.17+grain*.07;rough=.82+grain*.15}
  else if(kind==='bark'){const x=u*18+Math.sin(v*Math.PI*4)*.3+broad*.5,groove=Math.pow(Math.abs(Math.sin(x*Math.PI)),.45);height=groove*.6+grain*.1;tone=.29+groove*.38+broad*.2+grain*.08;rough=.92}
  else if(kind==='feather'){const x=fract(u*10)-.5,y=fract(v*5),barbs=.5+.5*Math.sin((y*30+Math.abs(x)*11)*Math.PI*2),spine=Math.exp(-x*x*1300);height=.35+barbs*.11+spine*.2;tone=.52+broad*.14+barbs*.14+spine*.16;rough=.56+barbs*.2}
  else if(kind==='metal'){height=grain*.08;tone=.66+broad*.14+grain*.08+fine*.07;rough=.28+grain*.18}
  else if(kind==='bone'){height=.5+Math.sin(u*Math.PI*48)*.03+grain*.08;tone=.70+broad*.18+grain*.1;rough=.4+grain*.18}
  else{height=grain*.14+fine*.05;tone=.69+broad*.16+grain*.09;rough=.66+grain*.16}
  return [height,clamp01(tone),clamp01(rough)];
 }
 function dataTexture(bytes,srgb=false){const t=new T.DataTexture(bytes,N,N,T.RGBAFormat);t.wrapS=t.wrapT=T.RepeatWrapping;t.magFilter=T.LinearFilter;t.minFilter=T.LinearMipmapLinearFilter;t.generateMipmaps=true;t.colorSpace=srgb?T.SRGBColorSpace:T.NoColorSpace;t.needsUpdate=true;return t}
 function maps(kind){if(textures.has(kind))return textures.get(kind);const heights=new Float32Array(N*N),albedo=new Uint8Array(N*N*4),rough=new Uint8Array(N*N*4),normal=new Uint8Array(N*N*4);
  for(let y=0;y<N;y++)for(let x=0;x<N;x++){const i=y*N+x,[h,c,r]=sample(kind,x/N,y/N);heights[i]=h;for(let a=0;a<3;a++){albedo[i*4+a]=Math.round(c*255);rough[i*4+a]=Math.round(r*255)}albedo[i*4+3]=rough[i*4+3]=255}
  for(let y=0;y<N;y++)for(let x=0;x<N;x++){const i=(y*N+x)*4,dx=(heights[y*N+(x+1)%N]-heights[y*N+(x+N-1)%N])*3,dy=(heights[((y+1)%N)*N+x]-heights[((y+N-1)%N)*N+x])*3,length=Math.hypot(dx,dy,1);normal[i]=Math.round((-.5*dx/length+.5)*255);normal[i+1]=Math.round((-.5*dy/length+.5)*255);normal[i+2]=Math.round((.5/length+.5)*255);normal[i+3]=255}
  const result={map:dataTexture(albedo,true),normalMap:dataTexture(normal),roughnessMap:dataTexture(rough)};textures.set(kind,result);return result;
 }
 function material(sp,color,metal=false,glow=false,hint){const family=hint||(metal?'metal':glow?'gem':families[sp]||'hide'),key=[family,color,glow].join(':');if(materials.has(key))return materials.get(key);const rough={fur:.92,silk:.68,stone:1,bark:1,feather:.84,scale:.72,chitin:.58,hide:.92,bone:.78,metal:.8,gem:.32}[family]||.8;
  const m=new T.MeshPhysicalMaterial({name:family+' · '+color,color,roughness:rough,metalness:family==='metal'?.72:family==='gem'?.25:0,emissive:glow?color:'#000000',emissiveIntensity:glow?.8:0,clearcoat:['scale','chitin','gem'].includes(family)?.28:0,clearcoatRoughness:.38,sheen:['fur','feather','silk'].includes(family)?.35:0,sheenColor:new T.Color(color),sheenRoughness:.7,envMapIntensity:family==='metal'?1.1:.55});
  if(!glow){Object.assign(m,maps(family));m.normalScale.setScalar(['stone','bark'].includes(family)?.95:family==='fur'?.48:.65)}m.userData.surface=family;materials.set(key,m);return m;
 }
 return {material,maps,families,sample,build,get textureCount(){return textures.size},get materialCount(){return materials.size}};
})();

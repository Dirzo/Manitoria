'use strict';

// The illustrated sheets are not exact grids. Follow each beast's alpha island
// so antlers, feet and tails crossing a nominal cell edge stay in its portrait.
function portraitRegions(pixels,width,height){
 const labels=new Int32Array(width*height),queue=new Int32Array(width*height),regions=[];let label=0;
 for(let start=0;start<labels.length;start++){
  if(labels[start]||pixels[start*4+3]<=30)continue;
  label++;let head=0,tail=1,left=width,top=height,right=0,bottom=0;queue[0]=start;labels[start]=label;
  while(head<tail){
   const p=queue[head++],x=p%width,y=Math.floor(p/width);left=Math.min(left,x);right=Math.max(right,x);top=Math.min(top,y);bottom=Math.max(bottom,y);
   const visit=n=>{if(n>=0&&n<labels.length&&!labels[n]&&pixels[n*4+3]>30){labels[n]=label;queue[tail++]=n}};
   if(x>0)visit(p-1);if(x<width-1)visit(p+1);if(y>0)visit(p-width);if(y<height-1)visit(p+width);
  }
  if(tail>100)regions.push({label,left,top,right,bottom,area:tail});
 }
 return {labels,regions:regions.sort((a,b)=>b.area-a.area).slice(0,16)};
}
function extractPortraitFrames(img,list){
 const canvas=document.createElement('canvas');canvas.width=img.width;canvas.height=img.height;
 const ctx=canvas.getContext('2d',{willReadFrequently:true});ctx.drawImage(img,0,0);
 const {data:pixels}=ctx.getImageData(0,0,img.width,img.height),{labels,regions}=portraitRegions(pixels,img.width,img.height),frames={};
 for(const r of regions){
  const column=Math.min(3,Math.floor((r.left+r.right)/2/img.width*4)),row=Math.min(3,Math.floor((r.top+r.bottom)/2/img.height*4)),sp=list[row*4+column];
  if(!sp||frames[sp])continue;
  const left=Math.max(0,r.left-4),top=Math.max(0,r.top-4),right=Math.min(img.width,r.right+5),bottom=Math.min(img.height,r.bottom+5);
  const frame=document.createElement('canvas');frame.width=right-left;frame.height=bottom-top;
  const fc=frame.getContext('2d'),out=fc.createImageData(frame.width,frame.height);
  for(let y=top;y<bottom;y++)for(let x=left;x<right;x++){
   const p=y*img.width+x;if(!pixels[p*4+3])continue;
   let belongs=labels[p]===r.label;
   // Preserve the soft edge without admitting a neighboring creature's pixels.
   if(!belongs&&!labels[p])for(let oy=-2;oy<=2&&!belongs;oy++)for(let ox=-2;ox<=2&&!belongs;ox++){const nx=x+ox,ny=y+oy;if(nx>=0&&nx<img.width&&ny>=0&&ny<img.height&&labels[ny*img.width+nx]===r.label)belongs=true}
   if(belongs){const at=((y-top)*frame.width+x-left)*4;out.data.set(pixels.subarray(p*4,p*4+4),at)}
  }
  fc.putImageData(out,0,0);frames[sp]=frame;
 }
 if(Object.keys(frames).length!==list.length)throw Error('The creature sheet did not contain all expected portraits.');
 return frames;
}

'use strict';

// Pointer events cover mouse, touch and pen; click placement remains available.
let formationDrag=null,suppressFormationClickUntil=0;
function formationDropTarget(x,y){const el=document.elementFromPoint(x,y)?.closest('.formation-cell');return el?.closest('.formation-board')?el:null}
function highlightFormationDrop(x,y){
 const next=formationDropTarget(x,y),d=formationDrag;if(!d||d.target===next)return;
 d.target?.classList.remove('drop-target','drop-swap');d.target=next;
 if(next){next.classList.add('drop-target');next.classList.toggle('drop-swap',!!next.dataset.occupant&&next.dataset.occupant!==d.id)}
}
function clearFormationDrag(){
 const d=formationDrag;if(!d)return;formationDrag=null;
 d.ghost?.remove();d.source.classList.remove('drag-origin');d.target?.classList.remove('drop-target','drop-swap');document.body.classList.remove('formation-dragging');
 try{if(d.source.hasPointerCapture(d.pointerId))d.source.releasePointerCapture(d.pointerId)}catch{}
}
document.addEventListener('pointerdown',e=>{
 const source=e.target.closest('[data-drag-unit]');
 if(!source||e.target.closest('.lineup-card-actions')||UI.mode!=='prematch'||e.button!==0||e.isPrimary===false||!selectableBeast(source.dataset.dragUnit))return;
 clearFormationDrag();formationDrag={id:source.dataset.dragUnit,source,pointerId:e.pointerId,x:e.clientX,y:e.clientY,started:false,target:null};
});
document.addEventListener('pointermove',e=>{
 const d=formationDrag;if(!d||d.pointerId!==e.pointerId)return;
 if(!d.started&&Math.hypot(e.clientX-d.x,e.clientY-d.y)<6)return;
 if(!d.started){
  d.started=true;d.source.setPointerCapture?.(e.pointerId);const b=G.beasts[d.id];d.ghost=document.createElement('div');d.ghost.className='formation-drag-ghost';d.ghost.setAttribute('aria-hidden','true');d.ghost.innerHTML=beastArt(b.sp)+`<strong>${esc(b.name)}</strong>`;document.body.append(d.ghost);d.source.classList.add('drag-origin');document.body.classList.add('formation-dragging');
 }
 e.preventDefault();d.ghost.style.transform=`translate3d(${e.clientX-54}px,${e.clientY-74}px,0)`;highlightFormationDrop(e.clientX,e.clientY);
 if(e.clientY<45)window.scrollBy(0,-12);else if(e.clientY>window.innerHeight-45)window.scrollBy(0,12);
},{passive:false});
document.addEventListener('pointerup',e=>{
 const d=formationDrag;if(!d||d.pointerId!==e.pointerId)return;
 const started=d.started,target=started?formationDropTarget(e.clientX,e.clientY):null,id=d.id;
 if(started){e.preventDefault();suppressFormationClickUntil=performance.now()+500}
 clearFormationDrag();
 if(target&&placeLineupBeast(id,Number(target.dataset.col),Number(target.dataset.row))){UI.formBeast=id;persistLineup();render();toast(`${G.beasts[id].name} moved to ${['back','middle','front'][target.dataset.col]} row ${Number(target.dataset.row)+1}.`)}
});
document.addEventListener('pointercancel',clearFormationDrag);
document.addEventListener('lostpointercapture',()=>{if(formationDrag)clearFormationDrag()});
document.addEventListener('keydown',e=>{if(e.key==='Escape')clearFormationDrag()});
document.addEventListener('click',e=>{if(e.detail!==0&&performance.now()<suppressFormationClickUntil){suppressFormationClickUntil=0;e.preventDefault();e.stopImmediatePropagation()}},true);

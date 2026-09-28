
spriteCss();
bootRunMenu();
document.addEventListener('input',e=>{if(e.target.id==='iname'){UI.intro.name=e.target.value;updateIdentityPreview()}if(e.target.id==='vol'){MUS.vol=+e.target.value;musSave();if(MUS.master&&MUS.on)MUS.master.gain.setTargetAtTime(MUS.vol,MUS.ctx.currentTime,.05)}});

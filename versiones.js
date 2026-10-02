/* Identificación conjunta: cada repositorio mantiene su propia numeración.
 * Nunca inferir que una web está publicada usando solo GitHub main. */
(function(){
  'use strict';
  const local=['localhost','127.0.0.1'].includes(location.hostname);
  const ownBadge=document.getElementById('build-code');
  const parts=[
    {name:'Capitán',key:'capitan',short:'C',label:document.getElementById('capitan-meta'),
      remote:'https://duiliomf.github.io/capitan-rodolfo/VERSION',
      main:'https://raw.githubusercontent.com/DuilioMF/capitan-rodolfo/main/VERSION',
      local:'./capitan-rodolfo/VERSION'},
    {name:'Rubén',key:'ruben',short:'R',label:document.getElementById('ruben-meta'),
      remote:'https://duiliomf.github.io/ruben/VERSION',
      main:'https://raw.githubusercontent.com/DuilioMF/ruben/main/VERSION',
      local:'./ruben/VERSION'},
    {name:'Lola',key:'lola',short:'L',label:document.getElementById('lola-meta'),
      remote:'https://duiliomf.github.io/lola-redes/VERSION',
      main:'https://raw.githubusercontent.com/DuilioMF/lola-redes/main/VERSION',
      local:'./lola-redes/VERSION'}
  ];
  async function getNumber(url){
    const controller=new AbortController();
    const timer=setTimeout(()=>controller.abort(),3500);
    try{
      const r=await fetch(url+(url.includes('?')?'&':'?')+'ts='+Date.now(),
        {cache:'no-store',signal:controller.signal});
      if(!r.ok)throw Error('HTTP '+r.status);
      const result=(await r.text()).trim();
      if(!/^\d+$/.test(result))throw Error('Versión inválida');
      return String(Number(result));
    }finally{clearTimeout(timer)}
  }
  async function getChild(part){
    try{return {version:await getNumber(local?part.local:part.remote),source:local?'instalación local':'web publicada'}}
    catch(_){
      if(local)return null; // Jamás sustituir versión local desconocida con GitHub main.
      try{return {version:await getNumber(part.main),source:'GitHub main; publicación sin comprobar'}}
      catch(__){return null}
    }
  }
  async function getSqlStatus(){
    if(!local)return '';
    try{
      const r=await fetch('/_doinglio_diagnostic',{cache:'no-store'});
      if(!r.ok)throw Error('Diagnóstico sin respuesta');
      const d=await r.json();
      const observed=d.healthVersion||d.serviceVersion;
      if(observed&&d.expectedVersion&&String(observed)!==String(d.expectedVersion))
        return ' · CONECTOR v'+observed+' / esperado v'+d.expectedVersion+' · ACTUALIZAR';
      if(!d.healthVersion)return ' · CONECTOR SIN CONFIRMAR';
      const sr=await fetch('/_doinglio_sql/api/state',{cache:'no-store'});
      const s=sr.ok?await sr.json():null;
      return ' · conector v'+d.healthVersion+(s&&s.connected?' · SQL CONECTADO'+(s.database?' · '+s.database:''):' · SQL SIN CONFIRMAR');
    }catch(_){return ' · CONECTOR NO VERIFICADO'}
  }
  async function main(){
    if(local){
      const cap=document.getElementById('open-capitan');
      const rub=document.getElementById('open-ruben');
      const lol=document.getElementById('open-lola');
      if(cap)cap.href='./capitan-rodolfo/index.html';
      if(rub)rub.href='./ruben/index.html';
      if(lol)lol.href='./lola-redes/index.html';
      const install=document.getElementById('local-install');
      if(install)install.style.display='none';
    }
    for(const p of parts){if(p.label)p.label.textContent=p.name+' · verificando versión…'}
    let d;
    try{d=await getNumber('./BUILD');if(ownBadge)ownBadge.textContent='D·'+d}
    catch(_){
      if(ownBadge)ownBadge.textContent='D·?';
      for(const p of parts){if(p.label)p.label.textContent=p.name+' · DoingLio sin versión verificable'}
      return;
    }
    const children=await Promise.all(parts.map(getChild));
    const sql=await getSqlStatus();
    parts.forEach((p,i)=>{
      if(!p.label)return;
      const child=children[i];
      if(!child){p.label.textContent='D'+d+'.'+p.short+'? · versión no comprobada';return}
      const composite='D'+d+'.'+p.short+child.version;
      p.label.textContent=composite+' · '+child.source+(p.key==='capitan'?sql:'');
      p.label.title='DoingLio D'+d+' + '+p.name+' '+p.short+child.version+
        ' · fuente: '+child.source+(p.key==='capitan'?' · conector independiente':'');
    });
  }
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',main,{once:true});
  else main();
})();

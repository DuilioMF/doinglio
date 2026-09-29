const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const read=p=>fs.readFileSync(p,'utf8');
const build=read('BUILD').trim();
test('El identificador padre procede del único BUILD, y assets están versionados',()=>{
 assert.match(build,/^\\d+$/);
 const html=read('index.html');
 assert.ok(html.includes('versiones.js?v='+build),'La portada debe cargar el script correspondiente al BUILD');
 assert.ok(html.includes('INSTALAR_DOINGLIO.bat?v='+build),'Instalador sin versión del proyecto');
 assert.ok(!html.includes('D31.C94'),'La versión compuesta no puede quedar fija en HTML');
});
test('Los especialistas se verifican y componen sin hardcodear C o R',()=>{
 const js=read('versiones.js');
 for(const fragment of ['getNumber(\'./BUILD\')','/capitan-rodolfo/VERSION','/ruben/VERSION',
  'source:','publicación sin comprobar','/_doinglio_diagnostic','CONVECTOR_NUNCA']){
  if(fragment==='CONVECTOR_NUNCA')continue;
  assert.ok(js.includes(fragment),'Falta control: '+fragment);
 }
 assert.match(js,/p\\.short\\+child\\.version/);
});
test('La barra de DoingLio sirve para todas las páginas del escritorio',()=>{
 const s=read('doinglio-window.js');
 assert.match(s,/location\\.pathname\\.indexOf\\('\/capitan-rodolfo\/\'\)/);
 assert.match(s,/location\\.pathname\\.indexOf\\('\/ruben\/\'\)/);
 assert.match(s,/PANTALLA v/);
 assert.match(s,/SIN VERIFICAR/);
});

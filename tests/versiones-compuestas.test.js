const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const read=p=>fs.readFileSync(p,'utf8');
const build=read('BUILD').trim();
test('BUILD oficial y recursos cacheados al número correcto',()=>{
 assert.match(build,/^\d+$/);
 const html=read('index.html');
 assert.ok(html.includes('versiones.js?v='+build));
 assert.ok(html.includes('INSTALAR_DOINGLIO.bat?v='+build));
 assert.ok(!html.includes('D31.C94'),'No fijar una composición manual en HTML');
 assert.ok(!html.includes('versiones.js?v=32'),'No servir el recurso cacheado del build anterior');
});
test('Composición independiente de los especialistas y estado real',()=>{
 const js=read('versiones.js');
 for(const fragment of ["getNumber('./BUILD')",'/capitan-rodolfo/VERSION','/ruben/VERSION','/lola-redes/VERSION',
   'GitHub main; publicación sin comprobar','/_doinglio_diagnostic','CONVECTOR_NO_USADO'].slice(0,-1)){
    assert.ok(js.includes(fragment),'Falta control de versión: '+fragment);
 }
 assert.ok(js.includes("p.short+child.version"));
});
test('Barra local identifica al especialista de la página',()=>{
 const js=read('doinglio-window.js');
 for(const text of ["location.pathname.indexOf('/capitan-rodolfo/')",
                    "location.pathname.indexOf('/ruben/')",
                    "location.pathname.indexOf('/lola-redes/')",
                    "PANTALLA v","SIN VERIFICAR"])
   assert.ok(js.includes(text),'Falta control '+text);
});

test('El iniciador no declara versiones fijas distintas de BUILD',()=>{
 const script=read('launcher/doinglio_launcher.ps1');
 assert.ok(!script.includes('Inicio DoingLio D31'));
 assert.ok(!script.includes('D31: ventana'));
 assert.ok(script.includes("Join-Path $Runtime 'BUILD'"));
 assert.ok(script.includes('Expand-Repo -Repo "lola-redes"'));
});

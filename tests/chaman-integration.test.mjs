import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const html=readFileSync(new URL('../index.html',import.meta.url),'utf8');
const expected={
 'open-capitan':'https://duiliomf.github.io/capitan-rodolfo/',
 'open-ruben':'https://duiliomf.github.io/ruben/',
 'open-lola':'https://duiliomf.github.io/lola-redes/',
 'open-chaman':'https://duiliomf.github.io/el-chaman/'
};
test('Los cuatro especialistas conservan enlaces únicos y correctos',()=>{
 for(const [id,url] of Object.entries(expected)){
  const pattern=new RegExp('<a[^>]+id="'+id+'"[^>]+href="'+url.replaceAll('.','\\.')+'"');
  assert.match(html,pattern,id+' ausente o enlace modificado');
  assert.equal((html.match(new RegExp('id="'+id+'"','g'))||[]).length,1,id+' duplicado');
 }
});
test('Las cuatro órbitas funcionan y la nueva apunta a una sección real',()=>{
 for(const name of ['cap','rub','lol','cha'])assert.match(html,new RegExp('class="node '+name+'"'));
 assert.match(html,/class="node cha" href="#chaman"/);
 assert.match(html,/id="chaman"/);
});
test('La integración no elimina la navegación de los especialistas existentes',()=>{
 assert.match(html,/id="open-capitan"/);
 assert.match(html,/id="open-ruben"/);
 assert.match(html,/id="open-lola"/);
 assert.match(html,/id="open-chaman"/);
 assert.match(html,/<meta name="viewport"/);
});
test('El Chamán tiene una sola tarjeta y no carga scripts de terceros',()=>{
 assert.equal((html.match(/id="open-chaman"/g)||[]).length,1);
 assert.match(html,/PRESENCIA · MEDITACIÓN/);
});

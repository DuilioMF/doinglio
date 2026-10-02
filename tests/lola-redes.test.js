const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');

const home=fs.readFileSync('index.html','utf8');
const versions=fs.readFileSync('versiones.js','utf8');
const launcher=fs.readFileSync('launcher/doinglio_launcher.ps1','utf8');

test('Lola es un especialista externo de DoingLio',()=>{
  assert.match(home,/id="open-lola"/);
  assert.match(home,/https:\/\/duiliomf\.github\.io\/lola-redes\//);
  assert.match(home,/id="lola-meta"/);
  assert.match(versions,/DuilioMF\/lola-redes\/main\/VERSION/);
  assert.match(launcher,/Expand-Repo -Repo "lola-redes"/);
});

test('DoingLio ya no contiene el login de Lola',()=>{
  assert.ok(!fs.existsSync('lola-redes.html'));
  assert.ok(!home.includes('doinglio-login-return'));
});

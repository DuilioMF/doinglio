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

test('DoingLio conserva solo un puente legacy hacia Lola independiente',()=>{
  assert.ok(fs.existsSync('lola-redes.html'));
  const legacy=fs.readFileSync('lola-redes.html','utf8');
  assert.match(legacy,/https:\/\/duiliomf\.github\.io\/lola-redes\//);
  assert.match(legacy,/location\.replace/);
  assert.ok(!legacy.includes('signInWithOtp'));
  assert.ok(!legacy.includes('auth-form'));
  assert.ok(!home.includes('doinglio-login-return'));
});

const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');

const home=fs.readFileSync('index.html','utf8');
const lola=fs.readFileSync('lola-redes.html','utf8');

test('Lola Redes aparece en DoingLio',()=>{
  assert.match(home,/id="open-lola"/);
  assert.match(home,/href="\.\/lola-redes\.html"/);
  assert.match(lola,/Hola, soy <em>Lola\.<\/em>/);
});

test('Lola muestra los cinco canales definidos',()=>{
  for(const channel of ['Facebook','Instagram','WhatsApp','LinkedIn','TikTok']){
    assert.ok(lola.includes(channel),'Falta '+channel);
  }
});

test('Lola tiene saludo por voz y no pide contraseñas',()=>{
  assert.match(lola,/SpeechSynthesisUtterance/);
  assert.match(lola,/Hola, soy Lola\. ¿En qué puedo ayudarte\?/);
  assert.ok(!/type=["']password["']/i.test(lola));
});

test('Lola reutiliza sesión antes de enviar otro mail',()=>{
  assert.match(lola,/Comprobando si ya estás conectado/);
  assert.match(lola,/const session=await currentSession\(\)/);
  assert.match(lola,/if\(session\?\.user\)/);
  assert.match(lola,/OTP_RESEND_WAIT_MS=10\*60\*1000/);
  assert.match(lola,/No sigas apretando Entrar/);
});

test('Lola permite reenviar si el usuario borró el correo',()=>{
  assert.match(lola,/id="auth-resend"/);
  assert.match(lola,/clearPendingOtp\(\);/);
  assert.match(lola,/form\.requestSubmit\(\)/);
  assert.match(lola,/Si lo borraste/);
});

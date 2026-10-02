(function () {
'use strict';
// En escritorio local, una barra compacta agrupa cerrar, maximizar y versión.
var local = location.hostname === '127.0.0.1' || location.hostname === 'localhost';
if (!local) return;
var desktop = new URLSearchParams(location.search).has('desktop');
try {
  if (desktop) sessionStorage.setItem('doinglio.desktop', '1');
  desktop = desktop || sessionStorage.getItem('doinglio.desktop') === '1';
} catch (_) {}
if (!desktop) return;
function mount() {
  if (!document.body || document.getElementById('doinglio-window-toolbar')) return;
  document.body.classList.add('doinglio-desktop-mode');
  var style = document.createElement('style');
  style.textContent =
    '#doinglio-window-toolbar{position:fixed!important;top:12px!important;left:14px!important;' +
    'display:flex!important;align-items:center!important;gap:10px!important;z-index:2147483646!important;' +
    'height:46px!important;max-width:calc(100vw - 28px)!important;box-sizing:border-box!important}' +
    '#doinglio-window-toolbar button{position:static!important;display:grid!important;place-items:center!important;' +
    'flex:0 0 46px!important;width:46px!important;height:46px!important;margin:0!important;padding:0!important;' +
    'border-radius:12px!important;border:1px solid #c58b4b!important;background:#20160fe8!important;' +
    'color:#ffdbac!important;font:400 26px/1 Segoe UI,Arial,sans-serif!important;cursor:pointer!important;' +
    'box-shadow:0 4px 20px #0008!important;opacity:1!important}' +
    '#doinglio-window-toolbar button:hover{background:#934a26!important;color:#fff!important}' +
    '#doinglio-window-toolbar button:focus-visible{outline:3px solid #ffbe72;outline-offset:3px}' +
    '#doinglio-window-toolbar #build-code{display:inline-flex!important;position:static!important;align-items:center!important;' +
    'margin:0!important;min-width:92px!important;height:46px!important;box-sizing:border-box!important;' +
    'padding:6px 13px!important;white-space:nowrap!important;letter-spacing:.12em!important}' +
    '#doinglio-window-toolbar #build-code:before{display:none!important}' +
    'body.doinglio-desktop-mode>header.top{padding-top:76px!important;min-height:136px!important}' +
    'body.doinglio-desktop-mode .wrap>header:first-child{padding-top:76px!important}' +
    'html[data-theme="light"] #doinglio-window-toolbar button{background:#fff7e9!important;color:#563a19!important}' +
    '@media(max-width:540px){body.doinglio-desktop-mode>header.top{padding-top:75px!important}}';
  document.head.appendChild(style);

  var bar = document.createElement('div');
  bar.id = 'doinglio-window-toolbar';
  bar.setAttribute('role', 'group');
  bar.setAttribute('aria-label', 'Controles de la ventana');

  var close = document.createElement('button');
  close.id = 'doinglio-window-close';
  close.type = 'button';
  close.textContent = '\u00d7';
  close.title = 'Cerrar DoingLio';
  close.setAttribute('aria-label', 'Cerrar DoingLio');

  var maximize = document.createElement('button');
  maximize.id = 'doinglio-window-maximize';
  maximize.type = 'button';
  maximize.textContent = '\u25a1';
  maximize.title = 'Maximizar';
  maximize.setAttribute('aria-label', 'Maximizar');

  function updateMaximize() {
    var full = !!document.fullscreenElement;
    maximize.textContent = full ? '\u2750' : '\u25a1';
    maximize.title = full ? 'Restaurar tamaño' : 'Maximizar';
    maximize.setAttribute('aria-label', maximize.title);
    maximize.setAttribute('aria-pressed', String(full));
  }
  maximize.addEventListener('click', function () {
    try {
      if (document.fullscreenElement) {
        if (document.exitFullscreen) {
          var exit = document.exitFullscreen();
          if (exit && exit.catch) exit.catch(function () { alert('Presioná Esc para restaurar.'); });
        }
      } else if (document.documentElement.requestFullscreen) {
        var enter = document.documentElement.requestFullscreen();
        if (enter && enter.catch) enter.catch(function () { alert('Maximizá la ventana desde Windows.'); });
      } else {
        alert('Maximizá la ventana desde Windows.');
      }
    } catch (_) { alert('Maximizá la ventana desde Windows.'); }
  });
  document.addEventListener('fullscreenchange', updateMaximize);

  close.addEventListener('click', function () {
    if (close.disabled) return;
    close.disabled = true;
    function fallback() {
      try { window.close(); } catch (_) {}
      window.setTimeout(function () {
        close.disabled = false;
        alert('Si la ventana no se cerró, usá Alt+F4.');
      }, 700);
    }
    if (!window.__doinglioExitToken) { fallback(); return; }
    fetch('/_doinglio_exit', {
      method: 'POST', cache: 'no-store',
      headers: {'X-DoingLio-Exit': window.__doinglioExitToken}
    }).then(function (r) {
      if (!r.ok) throw new Error('Cierre local no disponible');
      window.setTimeout(function () { try { window.close(); } catch (_) {} }, 1100);
    }).catch(fallback);
  });

  bar.appendChild(close);
  bar.appendChild(maximize);
  // Mantener el identificador original: el código que obtiene BUILD sigue actualizándolo.
  var version = document.getElementById('build-code');
  if (version) {
    bar.appendChild(version);
  } else {
    // El escritorio muestra la composición real del especialista que está abierto.
    var part = location.pathname.indexOf('/capitan-rodolfo/')===0 ? {code:'C',folder:'capitan-rodolfo'} :
      location.pathname.indexOf('/ruben/')===0 ? {code:'R',folder:'ruben'} :
      location.pathname.indexOf('/lola-redes/')===0 ? {code:'L',folder:'lola-redes'} : null;
    if (part) {
      version = document.createElement('span');
      version.id = 'build-code';
      version.textContent = 'D?.'+part.code+'? · verificando';
      bar.appendChild(version);
      function num(path) {
        return fetch(path+'?ts='+Date.now(),{cache:'no-store'}).then(function(response){
          if(!response.ok)throw new Error('Versión sin respuesta');
          return response.text();
        }).then(function(s){
          s=s.trim();
          if(!/^\d+$/.test(s))throw new Error('Versión inválida');
          return Number(s);
        });
      }
      Promise.all([num('/BUILD'),num('/'+part.folder+'/VERSION')]).then(function(values){
        var label='D'+values[0]+'.'+part.code+values[1];
        if(part.code==='C') {
          var actual=document.body.dataset.capitanBuild;
          if(actual && Number(actual)!==values[1]) {
            label+=' · PANTALLA v'+actual+' DESFASADA';
          }
        }
        version.textContent=label;
      }).catch(function(){ version.textContent='D?.'+part.code+'? · SIN VERIFICAR'; });
    }
  }
  document.body.appendChild(bar);
  updateMaximize();
}
if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', mount, {once:true});
else mount();
})();

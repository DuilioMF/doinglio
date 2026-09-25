(function () {
'use strict';
// Regla común: toda ventana del escritorio local tiene X de cierre.
var local = location.hostname === '127.0.0.1' || location.hostname === 'localhost';
if (!local) return;
var desktop = new URLSearchParams(location.search).has('desktop');
try {
  if (desktop) sessionStorage.setItem('doinglio.desktop', '1');
  desktop = desktop || sessionStorage.getItem('doinglio.desktop') === '1';
} catch (_) {}
if (!desktop) return;
function mount() {
  if (!document.body || document.getElementById('doinglio-window-close')) return;
  document.body.classList.add('doinglio-desktop-mode');
  var style = document.createElement('style');
  style.textContent =
    '#doinglio-window-close{position:fixed!important;left:12px!important;top:12px!important;' +
    'z-index:2147483646!important;width:44px!important;height:44px!important;' +
    'display:grid!important;place-items:center!important;border-radius:12px!important;' +
    'border:1px solid #c58b4b!important;background:#20160fe8!important;color:#ffdbac!important;' +
    'font:400 28px/1 Segoe UI,Arial,sans-serif!important;cursor:pointer!important;' +
    'box-shadow:0 4px 20px #0008!important;opacity:1!important}' +
    '#doinglio-window-close:hover{background:#934a26!important;color:#fff!important}' +
    '#doinglio-window-close:focus-visible{outline:3px solid #ffbe72;outline-offset:3px}' +
    'body.doinglio-desktop-mode>header.top{padding-left:max(76px,6vw)!important}' +
    'body.doinglio-desktop-mode .wrap>header:first-child{padding-left:64px!important}' +
    'html[data-theme="light"] #doinglio-window-close{background:#fff7e9!important;color:#563a19!important}';
  document.head.appendChild(style);
  var btn = document.createElement('button');
  btn.id = 'doinglio-window-close';
  btn.type = 'button';
  btn.textContent = '\u00d7';
  btn.title = 'Cerrar DoingLio';
  btn.setAttribute('aria-label', 'Cerrar DoingLio');
  btn.addEventListener('click', function () {
    if (btn.disabled) return;
    btn.disabled = true;
    function fallback() {
      try { window.close(); } catch (_) {}
      window.setTimeout(function () {
        btn.disabled = false;
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
  document.body.appendChild(btn);
}
if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', mount, {once:true});
else mount();
})();

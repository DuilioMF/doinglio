const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
function read(file) { return fs.readFileSync(path.join(root, file), 'utf8'); }
const script = read('doinglio-window.js');
new vm.Script(script, {filename:'doinglio-window.js'});
const splash = read('launcher/reloj_inicio.hta');
const inline = splash.match(/<script type="text\/javascript">([\s\S]*?)<\/script>/i);
assert(inline, 'Splash has JS code');
new vm.Script(inline[1], {filename:'reloj_inicio.hta inline JS'});
assert(splash.includes('id="startup-build"'), 'Startup version is present');
assert(splash.includes('left:78px;top:19px'), 'Startup build badge is next to X and not hidden at screen edge');
const home = read('index.html');
assert(home.includes('<div class="code" id="build-code"'), 'Visible main build is under brand, not behind right controls');
assert(home.indexOf('id="build-code"') < home.indexOf('</header>'), 'Build badge is inside header');
assert(splash.includes('onclick="cancelStartup()"'), 'Startup X cancels launch');
assert(read('BUILD').trim() === '30', 'Expected DoingLio build D30');
const server = read('launcher/doinglio_web_server.ps1');
assert(server.includes('doinglio-window.js'), 'Server injects shared X into all local HTML');
assert(server.charCodeAt(0) === 65279, 'PowerShell 5.1 receives UTF-8 BOM for Spanish diagnostics');
assert(server.includes('57877') && server.includes('servicePort'), 'Proxy checks real port and known alternatives');
assert(server.includes('healthVersion') && server.includes('healthPort'), 'Proxy distinguishes stale connector version');
assert(server.includes('SQL Server puede estar activo'), 'Bridge absence does not imply SQL Server is down');
assert(server.includes("'/ _doinglio_exit'".replace(' ', '')), 'Local exit endpoint exists');
assert(server.includes('browser-profile-'), 'Only isolated browser profiles may be killed');
const launcher = read('launcher/doinglio_launcher.ps1');
assert(launcher.includes('last_build.txt'), 'Launcher keeps installed build for splash');
assert((launcher.match(/if\(Test-Path \$CancelFlag\)/g) || []).length === 2,
       'Cancellation is respected before SQL and before opening browser');
assert(read('launcher/DoingLioInicio.vbs').includes('fs.DeleteFile cancelPath'),
       'Clear obsolete cancel flag on each launch');
function fakeWindow(url, session, token) {
  const elements = [];
  const css = [];
  const body = {classList:{add(){}}, appendChild(node){elements.push(node);}};
  const doc = {
    readyState:'complete', body, head:{appendChild(node){css.push(node);}},
    getElementById(id){return elements.find(n=>n.id === id);},
    createElement(tag){return {tag, setAttribute(k,v){this[k]=v;},
                           addEventListener(k,fn){this[k]=fn;}};}
  };
  const context = {
    location: new URL(url), URLSearchParams,
    document:doc, sessionStorage: {
      getItem(k){return session.get(k) || null;},
      setItem(k,v){session.set(k,v);}
    },
    window:{__doinglioExitToken:token, close(){}, setTimeout(){}},
    fetch(){return Promise.resolve({ok:true});}, alert(){},
  };
  vm.runInNewContext(script,context,{filename:'doinglio-window.js'});
  return {elements, css, context};
}
const session = new Map();
const main = fakeWindow('http://127.0.0.1:8790/?desktop=1',session,'test-secret');
assert.equal(main.elements.length,1,'Cuaderno Maestro has one X');
assert.equal(main.elements[0].textContent,'×','X appears');
assert.equal(session.get('doinglio.desktop'),'1');
const child = fakeWindow('http://127.0.0.1:8790/capitan-rodolfo/index.html',session,'test-secret');
assert.equal(child.elements.length,1,'Capitán inherits X');
const ruben = fakeWindow('http://127.0.0.1:8790/ruben/index.html',session,'test-secret');
assert.equal(ruben.elements.length,1,'Ruben inherits X');
const publicSite = fakeWindow('https://duiliomf.github.io/doinglio/',new Map(),undefined);
assert.equal(publicSite.elements.length,0,'Public browser tab has no nonfunctional close control');
console.log('OK: Desktop D28 startup build, cancel button, script syntax, shared X, specialist inheritance and isolated exit.');

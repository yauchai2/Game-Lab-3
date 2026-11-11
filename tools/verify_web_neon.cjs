// Actual browser QA for the current Lab Web export. Fresh ephemeral browser storage.
const {chromium}=require('playwright');
const fs=require('fs'),crypto=require('crypto');
const out=process.argv[2],url=process.argv[3],smoke=process.argv.includes('--smoke');
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
(async()=>{
 fs.mkdirSync(out,{recursive:true});
 const proxy=process.env.HTTPS_PROXY||process.env.HTTP_PROXY;
 const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'],...(proxy?{proxy:{server:proxy,bypass:'127.0.0.1,localhost'}}:{})});
 const page=await browser.newPage({viewport:{width:1366,height:900}}),errors=[],messages=[],checks=[];
 let navigations=0;
 const memory=[];const memoryTimer=setInterval(()=>{try{memory.push({time:Date.now(),cgroupBytes:Number(fs.readFileSync('/sys/fs/cgroup/memory.current','utf8'))})}catch{}},1000);
 const check=(name,passed,detail)=>{checks.push({name,passed,detail});console.log(name,passed);if(!passed)throw Error(name)};
 page.on('pageerror',e=>errors.push(e.message));
 page.on('console',m=>{const t=m.text();if(m.type()==='error'||/SCRIPT ERROR|^ERROR:/.test(t))errors.push(t);else if(m.type()==='warning')messages.push(t.slice(0,1400))});
 page.on('framenavigated',f=>{if(f===page.mainFrame())navigations++});
 await page.addInitScript(()=>{window.__audioContexts=[];const C=window.AudioContext;if(C)window.AudioContext=class extends C{constructor(...args){super(...args);window.__audioContexts.push(this)}}});
 const boot=async()=>{await page.locator('#start').click();await page.waitForFunction(()=>document.querySelector('#gate').hidden,{},{timeout:150000});await page.locator('#canvas').focus();await page.waitForTimeout(1500)};
 const click=async(x,y)=>{const b=await page.locator('#canvas').boundingBox();await page.mouse.click(b.x+b.width*x/1280,b.y+b.height*y/720);await page.waitForTimeout(900)};
 const shot=async name=>hash(await page.screenshot({path:out+'/'+name+'.png'}));
 const prefs=async()=>page.evaluate(async()=>{
  const found=[];
  for(const info of await indexedDB.databases()){
   const db=await new Promise((resolve,reject)=>{const r=indexedDB.open(info.name);r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error)});
   for(const name of db.objectStoreNames){const rows=await new Promise((resolve,reject)=>{const a=[],tx=db.transaction(name,'readonly'),r=tx.objectStore(name).openCursor();r.onsuccess=()=>{const c=r.result;if(c){if(/neon_lab\/(options|progression)\.cfg$/.test(String(c.key)))a.push({key:String(c.key),text:new TextDecoder().decode(c.value.contents)});c.continue()}else resolve(a)};r.onerror=()=>reject(r.error)});found.push(...rows)}db.close();
  }return found;
 });
 let saved=[],audio=[];
 try{
  await page.goto(url,{waitUntil:'domcontentloaded',timeout:60000});await boot();
  const gl=await page.evaluate(()=>{const g=document.querySelector('#canvas').getContext('webgl2');return g?{version:g.getParameter(g.VERSION),maxTexture:g.getParameter(g.MAX_TEXTURE_SIZE)}:null});
  check('Actual Web engine boots with WebGL2',!!gl,gl);
  const a=await shot('01-title');await page.waitForTimeout(1400);const b=await shot('02-title-motion');check('Native title has changing rendered frames',a!==b);
  await click(260,390);const heroes=[];
  for(const [i,x,y] of [[0,260,230],[1,480,230],[2,260,480],[3,480,480]]){await click(x,y);heroes.push(await shot('03-roster-'+i))}
  check('Four pointer selections produce distinct character views',new Set(heroes).size===4);
  await click(1160,330);const skills=await shot('04-skills');check('Skills pointer navigation changes the rendered page',!heroes.includes(skills));
  await page.keyboard.press('Escape');await page.waitForTimeout(800);
  await click(1160,422);await page.waitForTimeout(1800);await shot('05-street-run');
  // Normal inputs and normal opponent. No low-HP or resource/XP fixture.
  await page.keyboard.down('KeyD');await page.waitForTimeout(900);await page.keyboard.up('KeyD');
  await page.keyboard.down('KeyJ');await page.waitForTimeout(1800);await page.keyboard.up('KeyJ');
  await page.keyboard.press('KeyK');await page.keyboard.press('KeyE');await page.keyboard.press('KeyL');await page.waitForTimeout(1200);await shot('06-combat');
  if(!smoke){
   const deadline=Date.now()+90000;
   // Remain in place and allow an ordinary AI result to exercise a real reward save.
   do{saved=await prefs();if(saved.some(p=>/progression\.cfg$/.test(p.key)))break;await page.waitForTimeout(2000)}while(Date.now()<deadline);
   check('Street Run creates actual browser progression save after a normal result',saved.some(p=>/progression\.cfg$/.test(p.key)&&/xp=/.test(p.text)));
   await shot('07-run-result');
  }
  await page.keyboard.press('Escape');await page.waitForTimeout(800);await shot('08-pause-or-result');
  audio=await page.evaluate(()=>window.__audioContexts.map(a=>({state:a.state,time:a.currentTime,sampleRate:a.sampleRate})));
  check('Browser audio context runs after user gesture',audio.some(a=>a.state==='running'));
  const audioTime=audio[0]?.time||0;await page.waitForTimeout(500);
  check('Audio context advances through menu/result',await page.evaluate(t=>window.__audioContexts.some(a=>a.state==='running'&&a.currentTime>t+.2),audioTime));
  await page.locator('#canvas').focus();await page.keyboard.press('KeyM',{delay:120});await page.keyboard.press('F2',{delay:120});
  for(let i=0;i<12;i++){await page.waitForTimeout(1000);saved=await prefs();if(saved.some(p=>p.key.endsWith('options.cfg')&&p.text.includes('muted=true')&&p.text.includes('reduced_effects=true')))break}
  check('Lab preferences persist to real browser IndexedDB',saved.some(p=>p.key.endsWith('options.cfg')&&p.text.includes('muted=true')&&p.text.includes('reduced_effects=true')));
  await page.locator('#fullscreen').click();await page.waitForTimeout(500);const bounds=await page.locator('#canvas').boundingBox();check('Fullscreen keeps 16:9 input rectangle',Math.abs(bounds.width/bounds.height-16/9)<.01);await shot('09-fullscreen');await page.evaluate(()=>document.exitFullscreen());
  await page.setViewportSize({width:960,height:640});await page.waitForTimeout(500);await shot('10-small');
  check('Gameplay and function controls did not navigate the browser',navigations===1);
  await page.reload({waitUntil:'domcontentloaded'});await boot();await shot('11-reloaded');
  const reloaded=await prefs();check('Browser reload retains saved Lab options',reloaded.some(p=>p.key.endsWith('options.cfg')&&p.text.includes('reduced_effects=true')&&p.text.includes('muted=true')));
  check('No browser or Godot script errors',errors.length===0,errors);
  fs.writeFileSync(out+'/browser.json',JSON.stringify({url,mode:smoke?'live-smoke':'full',checks,passed:checks.length,total:checks.length,errors,messages,audio,preferences:saved,memory,scope:'Real Chromium/ANGLE SwiftShader WebGL2, pointer/keyboard, AudioContext and IndexedDB. Screenshots separately reviewed. Normal AI result for progression in full mode. Not human feel, speaker listening or target hardware FPS.'},null,2));
 }catch(e){await page.screenshot({path:out+'/failure.png'}).catch(()=>{});fs.writeFileSync(out+'/failure.json',JSON.stringify({error:e.message,checks,errors,messages,memory},null,2));throw e}
 finally{clearInterval(memoryTimer);await browser.close()}
})().catch(e=>{console.error(e.message);process.exit(1)});

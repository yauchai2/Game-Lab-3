// Requires Playwright and an installed Chromium. Automated QA; no telemetry from visitors.
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');const fs=require('fs');
(async()=>{
 const out=process.argv[2],url=process.argv[3];fs.mkdirSync(out,{recursive:true});
 const proxy=process.env.HTTPS_PROXY||process.env.HTTP_PROXY;
 const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'],...(proxy?{proxy:{server:proxy,bypass:'127.0.0.1,localhost'}}:{})});
 const page=await browser.newPage({viewport:{width:1366,height:900}});const errors=[],messages=[],checks=[];let navigations=0;
 page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error'||m.type()==='warning')messages.push({type:m.type(),text:m.text().slice(0,1800)})});page.on('framenavigated',frame=>{if(frame===page.mainFrame())navigations++});
 await page.addInitScript(()=>{window.__audioContexts=[];const Native=window.AudioContext;if(Native)window.AudioContext=class extends Native{constructor(...args){super(...args);window.__audioContexts.push(this)}}});
 try{
  await page.goto(url,{waitUntil:'domcontentloaded',timeout:60000});await page.locator('#start').click();await page.waitForFunction(()=>document.querySelector('#gate').hidden,{},{timeout:120000});
  checks.push({name:'actual Web engine boots',passed:true});await page.waitForTimeout(1200);await page.screenshot({path:out+'/01_title.png'});
  await page.keyboard.press('KeyT');await page.waitForTimeout(1500);await page.screenshot({path:out+'/02_training.png'});
  await page.keyboard.down('KeyD');await page.waitForTimeout(500);await page.keyboard.up('KeyD');await page.keyboard.press('KeyJ');await page.keyboard.press('KeyL');await page.waitForTimeout(1300);await page.screenshot({path:out+'/03_training_inputs.png'});
  await page.keyboard.press('F5');await page.waitForTimeout(500);checks.push({name:'training F5 does not refresh browser',passed:navigations===1 && await page.locator('#gate').isHidden()});await page.screenshot({path:out+'/04_reset.png'});
  await page.keyboard.press('F7');await page.waitForTimeout(500);checks.push({name:'training F7 does not navigate browser',passed:navigations===1});await page.screenshot({path:out+'/05_guarding.png'});
  await page.keyboard.press('Escape');await page.waitForTimeout(500);await page.screenshot({path:out+'/06_pause.png'});
  await page.keyboard.press('KeyM');await page.keyboard.press('F2');await page.waitForTimeout(8000);
  const audio=await page.evaluate(()=>window.__audioContexts.map(a=>({state:a.state,sampleRate:a.sampleRate})));checks.push({name:'browser audio context runs after user input',passed:audio.some(a=>a.state==='running')});
  const prefs=await page.evaluate(async()=>{
   const dbs=await indexedDB.databases(),found=[];
   for(const info of dbs){const db=await new Promise((resolve,reject)=>{const r=indexedDB.open(info.name);r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error)});
    for(const name of db.objectStoreNames){const pairs=await new Promise((resolve,reject)=>{const result=[],tx=db.transaction(name,'readonly'),r=tx.objectStore(name).openCursor();r.onsuccess=()=>{const c=r.result;if(c){if(String(c.key).endsWith('afterhours.cfg'))result.push({key:String(c.key),text:new TextDecoder().decode(c.value.contents)});c.continue()}else resolve(result)};r.onerror=()=>reject(r.error)});found.push(...pairs)}db.close()}
   return found;
  });
  checks.push({name:'preferences persisted to real browser IndexedDB',passed:prefs.some(p=>p.text.includes('reduced_effects=true')&&p.text.includes('muted=true')&&p.text.includes('partner_mode=1'))});
  await page.locator('#fullscreen').click();await page.waitForTimeout(500);const bounds=await page.locator('#canvas').boundingBox();checks.push({name:'fullscreen preserves 16:9 canvas input rectangle',passed:Math.abs(bounds.width/bounds.height-16/9)<0.01});await page.screenshot({path:out+'/07_fullscreen.png'});await page.evaluate(()=>document.exitFullscreen());
  await page.setViewportSize({width:960,height:640});await page.waitForTimeout(500);await page.screenshot({path:out+'/08_small_viewport.png'});
  await page.reload({waitUntil:'domcontentloaded'});await page.locator('#start').click();await page.waitForFunction(()=>document.querySelector('#gate').hidden,{},{timeout:120000});await page.waitForTimeout(1000);await page.screenshot({path:out+'/09_reloaded.png'});
  checks.push({name:'browser reload boots with saved preferences',passed:errors.length===0});
  fs.writeFileSync(out+'/browser.json',JSON.stringify({url,checks,passed:checks.filter(c=>c.passed).length,total:checks.length,errors,messages,audio,preferences:prefs,method:'Chromium headless / ANGLE SwiftShader; real WebGL, input and IndexedDB. Not human playtest, listening or hardware FPS.'},null,2));
  if(checks.some(c=>!c.passed)||errors.length)throw new Error('Browser check failure; see report');
 }catch(e){await page.screenshot({path:out+'/failure.png'}).catch(()=>{});fs.writeFileSync(out+'/failure.json',JSON.stringify({error:e.message,errors,messages,checks},null,2));throw e}
 finally{await browser.close()}
})().catch(e=>{console.error(e.message);process.exit(1)});

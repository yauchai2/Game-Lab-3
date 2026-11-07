// Validate the actual export with native WebAssembly / Web Streams APIs.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import zlib from 'node:zlib';
import crypto from 'node:crypto';
const directory = path.resolve(process.argv[2] || 'build/web');
const manifest = JSON.parse(fs.readFileSync(path.join(directory, 'release-manifest.json')));
for (const file of manifest.files) {
 const bytes = fs.readFileSync(path.join(directory, file.file));
 if(crypto.createHash('sha256').update(bytes).digest('hex') !== file.sha256) throw new Error('Hash mismatch: '+file.file);
}
const html = fs.readFileSync(path.join(directory,'index.html'),'utf8');
for(const match of html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g)) if(match[1].trim()) new vm.Script(match[1]);
if(html.includes('$GODOT_') || html.includes('__BUILD_ID__')) throw new Error('Unexpanded HTML placeholder');
const gzip = fs.readFileSync(path.join(directory,'game.wasm.gz'));
const original = zlib.gunzipSync(gzip);
const streamed = await new Response(new Blob([gzip]).stream().pipeThrough(new DecompressionStream('gzip'))).arrayBuffer();
if(Buffer.compare(original,Buffer.from(streamed))) throw new Error('Web Streams decompression mismatch');
if(crypto.createHash('sha256').update(original).digest('hex') !== manifest.wasm_uncompressed_sha256) throw new Error('Wasm hash mismatch');
const compiled = await WebAssembly.compile(streamed);
console.log(JSON.stringify({files_verified:manifest.files.length,inline_scripts_parse:true,lossless_web_decompression:true,wasm_compiles:true,wasm_bytes:original.length,wasm_import_count:WebAssembly.Module.imports(compiled).length,threads:manifest.threads,method:'Node WebAssembly and Web Streams plus artifact hashes; not a browser rendering test'},null,2));

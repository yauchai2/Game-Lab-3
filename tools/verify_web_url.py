#!/usr/bin/env python3
"""Fetch the public release without cookies/auth and verify every published asset."""
import concurrent.futures
import hashlib
import json
from pathlib import Path
import sys
import urllib.parse
import urllib.request
import urllib.error
base = sys.argv[1].rstrip('/') + '/'
manifest = json.loads(Path(sys.argv[2]).read_text())
def verify(item):
    url = urllib.parse.urljoin(base, item['file'])
    try:
        with urllib.request.urlopen(url, timeout=60) as response:
            data = response.read()
            result = {'file': item['file'], 'http': response.status, 'bytes': len(data), 'content_type': response.headers.get('Content-Type'), 'final_url': response.url, 'hash_matches': hashlib.sha256(data).hexdigest() == item['sha256']}
    except urllib.error.HTTPError as error:
        result = {'file': item['file'], 'http': error.code, 'hash_matches': False, 'error_body': error.read(500).decode(errors='replace')}
    return result
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    results = list(pool.map(verify, manifest['files']))
report = {'base_url': base, 'anonymous_http': True, 'passed': sum(x['http']==200 and x['hash_matches'] for x in results), 'total': len(results), 'files': results, 'scope': 'Anonymous HTTP downloads and hashes, not browser rendering or input'}
print(json.dumps(report, indent=2))
if report['passed'] != report['total']: sys.exit(1)

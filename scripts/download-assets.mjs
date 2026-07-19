import { writeFile, mkdir } from 'node:fs/promises';

const BASE = 'https://wirebot.trade';
const assets = [
  { url: `${BASE}/logo.png`, dest: 'public/images/logo.png' },
  { url: `${BASE}/favicon-32.png`, dest: 'public/seo/favicon-32.png' },
  { url: `${BASE}/favicon-16.png`, dest: 'public/seo/favicon-16.png' },
  { url: `${BASE}/favicon.png`, dest: 'public/seo/favicon.png' },
  { url: `${BASE}/banner.png`, dest: 'public/seo/banner.png' },
  { url: `${BASE}/_next/static/css/6f725393a78f7f1d.css`, dest: 'docs/research/wirebot.trade/site.css' },
];

for (const { url, dest } of assets) {
  try {
    const res = await fetch(url);
    if (!res.ok) { console.error(`SKIP ${url} -> ${res.status}`); continue; }
    await writeFile(dest, Buffer.from(await res.arrayBuffer()));
    console.log(`OK ${url} -> ${dest}`);
  } catch (e) {
    console.error(`FAIL ${url}: ${e.message}`);
  }
}

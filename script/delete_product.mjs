#!/usr/bin/env node
/*
Usage:
  WEB_URL="https://mcm.backoffice.test17.shub.us" \
  ANDROID_ACTIVATE_EMAIL="<email>" ANDROID_ACTIVATE_PASSWORD="<password>" \
  node scripts/delete_product.mjs [--dry-run] "<Product Name>"
*/
import { wrapper } from 'axios-cookiejar-support';
import axios from 'axios';
import { CookieJar } from 'tough-cookie';

async function main() {
  const args = process.argv.slice(2);
  const dryRun = args[0] === '--dry-run';
  const productName = dryRun ? args[1] : args[0];
  if (!productName) {
    console.error('Product name is required.');
    process.exit(2);
  }

  const baseRaw = process.env.WEB_URL || '';
  const base = baseRaw.replace(/\/$/, '');
  const username = process.env.ANDROID_ACTIVATE_EMAIL;
  const password = process.env.ANDROID_ACTIVATE_PASSWORD;
  if (!base || !username || !password) {
    console.error('Missing env: WEB_URL and/or ANDROID_ACTIVATE_EMAIL and/or ANDROID_ACTIVATE_PASSWORD');
    process.exit(2);
  }

  const jar = new CookieJar();
  const client = wrapper(axios.create({ jar, withCredentials: true, timeout: 30000 }));

  // 1) Login
  const loginUrl = base + '/login';
  const loginBody = { username, password };
  const loginRes = await client.post(loginUrl, loginBody, { headers: { 'Content-Type': 'application/json' }, validateStatus: () => true });
  if (loginRes.status !== 200) {
    console.error('Login failed', loginRes.status, loginRes.data);
    process.exit(1);
  }

  // 2) Search product by name
  const searchUrl = base + '/products/ajaxInventoryWithCount';
  const searchBody = `sSearch=${encodeURIComponent(productName)}`;
  const searchRes = await client.post(searchUrl, searchBody, { headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, validateStatus: () => true });
  if (searchRes.status !== 200) {
    console.error('Search failed', searchRes.status, searchRes.data);
    process.exit(1);
  }
  const rows = (searchRes.data && searchRes.data.aaData) || [];
  const target = rows.find(r => (r['1'] || '').trim().toLowerCase() === productName.trim().toLowerCase());
  if (!target) {
    console.error('Product not found by exact name. Candidates:', rows.map(r => r['1']).slice(0, 5));
    process.exit(3);
  }
  const productId = target.DT_RowId;
  console.log('Found product ID:', productId, 'for name:', target['1']);

  if (dryRun) {
    console.log('Dry-run mode: not deleting.');
    return;
  }

  // 3) Delete product by ID
  const delUrl = base + '/products/ajaxDeleteProducts';
  const delBody = `products%5B%5D=${encodeURIComponent(productId)}`; // products[]=<id>
  const delRes = await client.post(delUrl, delBody, { headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, validateStatus: () => true });
  if (delRes.status !== 200) {
    console.error('Delete failed', delRes.status, delRes.data);
    process.exit(1);
  }
  console.log('Delete succeeded. HTTP', delRes.status);
}

main().catch(err => {
  if (err.response) {
    console.error('HTTP error', err.response.status, err.response.data);
  } else {
    console.error(err.message || err);
  }
  process.exit(1);
});


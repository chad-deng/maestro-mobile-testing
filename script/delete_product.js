/*
Maestro script to delete a product via the backoffice API
Usage: Called from Maestro YAML flow with environment variables:
  - myAccount: business name
  - myEmail: login email
  - myPassword: login password
  - myProductName: product name to delete
*/

// Get environment variables (passed from Maestro YAML env section)
// In Maestro GraalJS, env variables are available as global variables
const envName = (typeof ENV !== 'undefined' ? ENV : 'fat');
const businessName = (typeof myAccount !== 'undefined' ? myAccount : '');
const productName = (typeof myProductName !== 'undefined' ? myProductName : '');
const username = (typeof myEmail !== 'undefined' ? myEmail : '');
const password = (typeof myPassword !== 'undefined' ? myPassword : '');

// Validate required environment variables
if (!productName) {
  console.error('Product name is required. Set myProductName env var.');
  throw new Error('Missing required environment variable: myProductName');
}

if (!businessName) {
  console.error('Business name is required. Set myAccount env var.');
  throw new Error('Missing required environment variable: myAccount');
}

if (!username || !password) {
  console.error('Login credentials are required. Set myEmail and myPassword env vars.');
  throw new Error('Missing required environment variables: myEmail and myPassword');
}

// Build base URL based on environment
let base;
if (envName.toLowerCase() === 'fat') {
  base = `https://${businessName}.backoffice.test17.shub.us`;
} else if (envName.toLowerCase() === 'staging') {
  base = `https://${businessName}.backoffice.staging.mymyhub.com`;
} else if (envName.toLowerCase() === 'production' || envName.toLowerCase() === 'prod') {
  base = `https://${businessName}.storehubhq.com`;
} else {
  console.warn(`Unknown ENV '${envName}', defaulting to FAT backoffice domain`);
  base = `https://${businessName}.backoffice.test17.shub.us`;
}

console.log(`Using base URL: ${base}`);
console.log(`Attempting to delete product: ${productName}`);

try {
  // 1) Login to get session cookies
  const loginUrl = base + '/login';
  console.log(`Logging in to: ${loginUrl}`);

  // Use JSON login to match working deactivate.js authentication
  const loginRes = http.post(loginUrl, {
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Connection': 'keep-alive'
    },
    body: JSON.stringify({ username: username, password: password })
  });

  console.log('Login response status:', loginRes.status);
  console.log('Login response headers:', Object.keys(loginRes.headers));

  // Check if we got redirected (common for successful logins)
  if (loginRes.status === 302 || loginRes.status === 301) {
    console.log('Login resulted in redirect - this may indicate successful authentication');
    console.log('Redirect location:', loginRes.headers['location'] || 'not specified');
  } else if (loginRes.status !== 200) {
    console.error('Login failed', loginRes.status);
    console.error('Response body preview:', loginRes.body ? loginRes.body.substring(0, 300) : 'empty');
    throw new Error(`Login failed with status ${loginRes.status}`);
  } else {
    console.log('Login successful, status:', loginRes.status);
  }

  // Extract cookies from login response (matching deactivate.js approach)
  const cookies = loginRes.headers['set-cookie'];
  let cookieString = '';

  if (cookies) {
    // Format cookies for subsequent requests (same as deactivate.js)
    cookieString = cookies.split(',').map(cookie => cookie.split(';')[0]).join('; ');
    console.log('Session cookies obtained:', cookieString);
  } else {
    console.log('No cookies in login response');
    console.log('Available headers:', Object.keys(loginRes.headers));
    throw new Error('No cookies received from login response');
  }

  // 2) Search for product by name
  const searchUrl = base + '/products/ajaxInventoryWithCount';
  const searchBody = `sSearch=${encodeURIComponent(productName)}`;

  console.log(`Searching for product: ${productName}`);

  // Prepare headers for search request
  const searchHeaders = {
    'Content-Type': 'application/x-www-form-urlencoded'
  };

  // Only add Cookie header if we have cookies
  if (cookieString) {
    searchHeaders['Cookie'] = cookieString;
    console.log('Using session cookies for search request');
  } else {
    console.log('Making search request without cookies');
  }

  const searchRes = http.post(searchUrl, {
    headers: searchHeaders,
    body: searchBody
  });

  if (searchRes.status !== 200) {
    console.error('Search failed', searchRes.status, searchRes.body);
    throw new Error(`Search failed with status ${searchRes.status}`);
  }

  // Check if response is JSON by looking at content type or trying to parse
  let searchData;
  try {
    if (typeof searchRes.body === 'string') {
      // Check if response looks like HTML (common when authentication fails)
      if (searchRes.body.trim().startsWith('<')) {
        console.error('Received HTML response instead of JSON - likely authentication failed');
        console.error('Response body preview:', searchRes.body.substring(0, 200));
        throw new Error('Authentication failed - received HTML instead of JSON response');
      }
      searchData = JSON.parse(searchRes.body);
    } else {
      searchData = searchRes.body;
    }
  } catch (parseError) {
    console.error('Failed to parse search response as JSON:', parseError.message);
    console.error('Response body preview:', searchRes.body ? searchRes.body.substring(0, 200) : 'empty or null');
    throw new Error('Invalid JSON response from search API');
  }

  const rows = (searchData && searchData.aaData) || [];

  // Find exact match for product name (case-insensitive)
  const target = rows.find(r => (r['1'] || '').trim().toLowerCase() === productName.trim().toLowerCase());

  if (!target) {
    const candidates = rows.map(r => r['1']).slice(0, 5);
    console.error('Product not found by exact name. Candidates:', candidates);
    throw new Error(`Product '${productName}' not found. Available: ${candidates.join(', ')}`);
  }

  const productId = target.DT_RowId;
  console.log('Found product ID:', productId, 'for name:', target['1']);

  // 3) Delete product by ID
  const delUrl = base + '/products/ajaxDeleteProducts';
  const delBody = `products%5B%5D=${encodeURIComponent(productId)}`; // products[]=<id>

  console.log(`Deleting product ID: ${productId}`);

  // Prepare headers for delete request
  const deleteHeaders = {
    'Content-Type': 'application/x-www-form-urlencoded'
  };

  // Only add Cookie header if we have cookies
  if (cookieString) {
    deleteHeaders['Cookie'] = cookieString;
    console.log('Using session cookies for delete request');
  } else {
    console.log('Making delete request without cookies');
  }

  const delRes = http.post(delUrl, {
    headers: deleteHeaders,
    body: delBody
  });

  if (delRes.status !== 200) {
    console.error('Delete failed', delRes.status, delRes.body);
    throw new Error(`Delete failed with status ${delRes.status}`);
  }

  console.log('Product deleted successfully. HTTP', delRes.status);
  output.result = {
    success: true,
    productId: productId,
    productName: target['1'],
    message: 'Product deleted successfully'
  };

} catch (error) {
  console.error('Error during product deletion:', error.message || error);
  output.result = {
    success: false,
    error: error.message || 'Unknown error occurred',
    productName: productName
  };
  throw error; // Re-throw to fail the Maestro flow
}


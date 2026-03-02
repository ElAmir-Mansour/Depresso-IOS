const jwt = require('jsonwebtoken');
const axios = require('axios');

let applePublicKeys = null;
let keysLastFetched = 0;
const KEY_CACHE_DURATION = 24 * 60 * 60 * 1000; // 24 hours

/**
 * Fetch Apple's public keys for token verification
 */
async function getApplePublicKeys() {
    const now = Date.now();
    
    // Use cached keys if still valid
    if (applePublicKeys && (now - keysLastFetched) < KEY_CACHE_DURATION) {
        return applePublicKeys;
    }
    
    try {
        const response = await axios.get('https://appleid.apple.com/auth/keys');
        applePublicKeys = response.data.keys;
        keysLastFetched = now;
        return applePublicKeys;
    } catch (error) {
        throw new Error(`Failed to fetch Apple public keys: ${error.message}`);
    }
}

/**
 * Convert JWK to PEM format for verification
 */
function jwkToPem(jwk) {
    const NodeRSA = require('node-rsa');
    const key = new NodeRSA();
    key.importKey({ n: Buffer.from(jwk.n, 'base64'), e: Buffer.from(jwk.e, 'base64') }, 'components-public');
    return key.exportKey('public');
}

/**
 * Verify Apple identity token
 * Returns the verified Apple user ID (sub claim)
 */
async function verifyAppleToken(identityToken, bundleId) {
    try {
        // Decode header to get kid
        const decoded = jwt.decode(identityToken, { complete: true });
        if (!decoded) {
            throw new Error('Invalid token format');
        }
        
        const kid = decoded.header.kid;
        
        // Get Apple's public keys
        const keys = await getApplePublicKeys();
        const matchingKey = keys.find(key => key.kid === kid);
        
        if (!matchingKey) {
            throw new Error('No matching key found');
        }
        
        // Convert JWK to PEM
        const pem = jwkToPem(matchingKey);
        
        // Verify token
        const verified = jwt.verify(identityToken, pem, {
            algorithms: ['RS256'],
            audience: bundleId || process.env.APPLE_BUNDLE_ID,
            issuer: 'https://appleid.apple.com'
        });
        
        return verified.sub; // Apple user ID
    } catch (error) {
        throw new Error(`Apple token verification failed: ${error.message}`);
    }
}

module.exports = {
    verifyAppleToken
};

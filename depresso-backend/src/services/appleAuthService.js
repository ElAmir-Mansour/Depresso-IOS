const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

const client = jwksClient({
    jwksUri: 'https://appleid.apple.com/auth/keys',
    cache: true,
    cacheMaxAge: 86400000 // 24 hours
});

function getKey(header, callback) {
    client.getSigningKey(header.kid, function(err, key) {
        if (err) {
            callback(err);
            return;
        }
        const signingKey = key.getPublicKey();
        callback(null, signingKey);
    });
}

/**
 * Verify Apple identity token
 * Returns the verified Apple user ID (sub claim)
 */
async function verifyAppleToken(identityToken, bundleId) {
    return new Promise((resolve, reject) => {
        jwt.verify(
            identityToken,
            getKey,
            {
                algorithms: ['RS256'],
                audience: bundleId || process.env.APPLE_BUNDLE_ID,
                issuer: 'https://appleid.apple.com'
            },
            (err, decoded) => {
                if (err) {
                    reject(new Error(`Apple token verification failed: ${err.message}`));
                } else {
                    resolve(decoded.sub); // Apple user ID
                }
            }
        );
    });
}

module.exports = {
    verifyAppleToken
};

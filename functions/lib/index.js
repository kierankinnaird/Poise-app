"use strict";
// Cloud Function: verify an Apple identity token server-side and mint a
// Firebase custom auth token. This bypasses the Firebase Apple provider
// entirely, which has been returning invalid-credential errors for native
// iOS tokens (aud = bundle ID, not Services ID).
//
// Using v1 callable -- v1 functions are publicly invokable by default,
// which avoids needing to configure Cloud Run IAM for unauthenticated callers.
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyAppleToken = void 0;
const admin = require("firebase-admin");
const functions = require("firebase-functions/v1");
const jose_1 = require("jose");
const fs = require("fs");
const path = require("path");
// Use a service account key file if present -- avoids needing the
// iam.serviceAccounts.signBlob IAM permission for createCustomToken.
const keyPath = path.join(__dirname, "../service-account.json");
if (fs.existsSync(keyPath)) {
    const serviceAccount = JSON.parse(fs.readFileSync(keyPath, "utf8"));
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
    });
}
else {
    admin.initializeApp();
}
const APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys";
const APPLE_ISSUER = "https://appleid.apple.com";
// Native iOS Apple Sign In tokens have aud = bundle ID, not Services ID.
const BUNDLE_ID = "com.kierankinnaird.poise";
const appleJwks = (0, jose_1.createRemoteJWKSet)(new URL(APPLE_JWKS_URL));
exports.verifyAppleToken = functions.https.onCall(async (data) => {
    const { identityToken } = data;
    if (!identityToken || typeof identityToken !== "string") {
        throw new functions.https.HttpsError("invalid-argument", "identityToken is required");
    }
    let payload;
    try {
        const result = await (0, jose_1.jwtVerify)(identityToken, appleJwks, {
            issuer: APPLE_ISSUER,
            audience: BUNDLE_ID,
        });
        payload = result.payload;
    }
    catch (err) {
        console.error("Apple JWT verification failed:", err);
        throw new functions.https.HttpsError("unauthenticated", "Invalid Apple identity token");
    }
    const appleUid = payload.sub;
    if (!appleUid) {
        throw new functions.https.HttpsError("unauthenticated", "Missing sub claim in Apple token");
    }
    // Prefix the UID so Apple users are namespaced in Firebase Auth.
    const firebaseUid = `apple:${appleUid}`;
    // Carry email through as a custom claim so the app can read it if needed.
    const additionalClaims = {};
    if (payload.email) {
        additionalClaims.email = payload.email;
    }
    const customToken = await admin
        .auth()
        .createCustomToken(firebaseUid, additionalClaims);
    return { customToken, isNewUser: await _isNewUser(firebaseUid) };
});
// Check if a Firebase UID already has a user record -- used by the client
// to decide whether to show onboarding.
async function _isNewUser(uid) {
    try {
        await admin.auth().getUser(uid);
        return false;
    }
    catch {
        return true;
    }
}
//# sourceMappingURL=index.js.map
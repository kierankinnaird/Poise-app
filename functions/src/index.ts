// Cloud Function: verify an Apple identity token server-side and mint a
// Firebase custom auth token. This bypasses the Firebase Apple provider
// entirely, which has been returning invalid-credential errors for native
// iOS tokens (aud = bundle ID, not Services ID).
//
// Using v1 callable -- v1 functions are publicly invokable by default,
// which avoids needing to configure Cloud Run IAM for unauthenticated callers.

import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import {createRemoteJWKSet, jwtVerify} from "jose";
import * as fs from "fs";
import * as path from "path";

// Use a service account key file if present -- avoids needing the
// iam.serviceAccounts.signBlob IAM permission for createCustomToken.
const keyPath = path.join(__dirname, "../service-account.json");
if (fs.existsSync(keyPath)) {
  const serviceAccount = JSON.parse(fs.readFileSync(keyPath, "utf8"));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
} else {
  admin.initializeApp();
}

const APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys";
const APPLE_ISSUER = "https://appleid.apple.com";
// Native iOS Apple Sign In tokens have aud = bundle ID, not Services ID.
const BUNDLE_ID = "com.kierankinnaird.poise";

const appleJwks = createRemoteJWKSet(new URL(APPLE_JWKS_URL));

export const verifyAppleToken = functions.https.onCall(async (data: {identityToken: string}) => {
  const {identityToken} = data;

  if (!identityToken || typeof identityToken !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "identityToken is required");
  }

  let payload: Record<string, unknown>;
  try {
    const result = await jwtVerify(identityToken, appleJwks, {
      issuer: APPLE_ISSUER,
      audience: BUNDLE_ID,
    });
    payload = result.payload as Record<string, unknown>;
  } catch (err) {
    console.error("Apple JWT verification failed:", err);
    throw new functions.https.HttpsError("unauthenticated", "Invalid Apple identity token");
  }

  const appleUid = payload.sub as string;
  if (!appleUid) {
    throw new functions.https.HttpsError("unauthenticated", "Missing sub claim in Apple token");
  }

  // Prefix the UID so Apple users are namespaced in Firebase Auth.
  const firebaseUid = `apple:${appleUid}`;

  // Carry email through as a custom claim so the app can read it if needed.
  const additionalClaims: Record<string, unknown> = {};
  if (payload.email) {
    additionalClaims.email = payload.email;
  }

  const customToken = await admin
    .auth()
    .createCustomToken(firebaseUid, additionalClaims);

  return {customToken, isNewUser: await _isNewUser(firebaseUid)};
});

// Check if a Firebase UID already has a user record -- used by the client
// to decide whether to show onboarding.
async function _isNewUser(uid: string): Promise<boolean> {
  try {
    await admin.auth().getUser(uid);
    return false;
  } catch {
    return true;
  }
}

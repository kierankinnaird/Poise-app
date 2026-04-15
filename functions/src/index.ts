// Cloud Functions for Poise.
//
// verifyAppleToken      -- verifies Apple JWT and mints a Firebase custom auth token.
// createCheckoutSession -- creates a Stripe Checkout session for a given practitioner tier.
// stripeWebhook         -- handles Stripe webhook events; creates the org doc on checkout.session.completed.
// createPortalSession   -- creates a Stripe Customer Portal session for subscription management.
//
// Environment variables required (set in functions/.env for local, Secret Manager for prod):
//   STRIPE_SECRET_KEY      -- Stripe secret key (sk_test_... or sk_live_...)
//   STRIPE_WEBHOOK_SECRET  -- Stripe webhook signing secret (whsec_...) -- set after deploying

import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import {createRemoteJWKSet, jwtVerify} from "jose";
import StripeLib = require("stripe");
type StripeInstance = StripeLib.Stripe;
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

// Test mode price IDs -- swap for live IDs before going to production.
const PRICE_IDS: Record<string, string> = {
  starter: "price_1TLuV7LJixDIqTxGe31PjVis",
  pro:     "price_1TLuV8LJixDIqTxGvr4MElbn",
  team:    "price_1TLuV9LJixDIqTxGj1zZ8ejx",
  club:    "price_1TLuVALJixDIqTxG7UdtJFot",
};

const SUCCESS_URL = "https://getpoise.app/pro/dashboard.html?checkout=success";
const CANCEL_URL  = "https://getpoise.app/pro/";

// Lazy Stripe instance -- initialised on first call so env vars are available at runtime.
let _stripe: StripeInstance | null = null;
function getStripe(): StripeInstance {
  if (!_stripe) {
    const key = process.env.STRIPE_SECRET_KEY;
    if (!key) throw new Error("STRIPE_SECRET_KEY environment variable is not set");
    _stripe = new StripeLib(key);
  }
  return _stripe;
}

// --- Apple Sign In ---

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

async function _isNewUser(uid: string): Promise<boolean> {
  try {
    await admin.auth().getUser(uid);
    return false;
  } catch {
    return true;
  }
}

// --- Stripe ---

// Creates a Stripe Checkout session and returns the hosted URL to redirect to.
// The client passes { tier, orgName } -- tier maps to a price ID, orgName is stored
// in metadata so the webhook can name the org doc on completion.
export const createCheckoutSession = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be signed in");
  }

  const tier = data.tier as string;
  const priceId = PRICE_IDS[tier];
  if (!priceId) {
    throw new functions.https.HttpsError("invalid-argument", `Unknown tier: ${tier}`);
  }

  const session = await getStripe().checkout.sessions.create({
    mode: "subscription",
    payment_method_types: ["card"],
    line_items: [{price: priceId, quantity: 1}],
    subscription_data: {trial_period_days: 14},
    client_reference_id: context.auth.uid,
    customer_email: context.auth.token.email as string | undefined,
    success_url: SUCCESS_URL,
    cancel_url: CANCEL_URL,
    metadata: {
      tier,
      uid: context.auth.uid,
      orgName: (data.orgName as string | undefined) ?? "",
    },
  });

  return {url: session.url};
});

// Stripe webhook -- receives POST events from Stripe and creates the org doc
// in Firestore after a successful checkout. Must be an HTTP function (not callable)
// so Stripe can POST to it directly.
export const stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers["stripe-signature"];
  if (!sig || typeof sig !== "string") {
    res.status(400).send("Missing stripe-signature header");
    return;
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let event: any;
  try {
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
    if (!webhookSecret) {
      console.error("STRIPE_WEBHOOK_SECRET is not set");
      res.status(500).send("Webhook secret not configured");
      return;
    }
    event = getStripe().webhooks.constructEvent(req.rawBody, sig, webhookSecret);
  } catch (err) {
    console.error("Webhook signature verification failed:", err);
    res.status(400).send("Webhook error");
    return;
  }

  if (event.type === "checkout.session.completed") {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const session = event.data.object as any;
    const uid = session.client_reference_id;
    const tier = session.metadata?.tier ?? "starter";
    const orgName = session.metadata?.orgName || "My Organisation";
    const stripeCustomerId = session.customer as string;
    const stripeSubscriptionId = session.subscription as string;

    if (!uid) {
      console.error("checkout.session.completed missing client_reference_id");
      res.json({received: true});
      return;
    }

    // Short unique referral code for athletes to enter in the app.
    const code = "POISE-" + Math.random().toString(36).substring(2, 8).toUpperCase();

    const orgRef = admin.firestore().collection("organisations").doc();
    await orgRef.set({
      id: orgRef.id,
      name: orgName,
      ownerUid: uid,
      code,
      tier,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      stripeCustomerId,
      stripeSubscriptionId,
    });

    // Mark the user as a practitioner so the app can gate accordingly.
    await admin.firestore().collection("users").doc(uid).set(
      {isPro: true, orgId: orgRef.id},
      {merge: true}
    );
  }

  res.json({received: true});
});

// Creates a Stripe Customer Portal session so practitioners can manage or cancel
// their subscription. Returns the portal URL to redirect to.
export const createPortalSession = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be signed in");
  }

  const orgSnap = await admin.firestore()
    .collection("organisations")
    .where("ownerUid", "==", context.auth.uid)
    .limit(1)
    .get();

  if (orgSnap.empty) {
    throw new functions.https.HttpsError("not-found", "No organisation found");
  }

  const org = orgSnap.docs[0].data();
  if (!org.stripeCustomerId) {
    throw new functions.https.HttpsError("failed-precondition", "No billing account linked");
  }

  const portalSession = await getStripe().billingPortal.sessions.create({
    customer: org.stripeCustomerId,
    return_url: "https://getpoise.app/pro/dashboard.html",
  });

  return {url: portalSession.url};
});

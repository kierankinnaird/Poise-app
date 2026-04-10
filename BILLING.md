# Billing

## Model

14-day free trial, then £7.99/month or £59.99/year (~£5/month).

## Reasoning

Based on 8 feedback form responses (April 2026).

**Pricing:**
- 3 of 7 said "more than £10/month if it genuinely works" -- the qualifier matters. They need to be convinced first, so launching above £10 is risky without a track record.
- 2 said up to £5/month. £7.99 sits above that low anchor but well below the psychological £10 barrier.
- Annual at £59.99 rewards commitment and reduces churn.

**Trial length:**
- One person said "I just like to know what I am committing to before spending anything."
- The core value of Poise is tracking change over time -- users need to complete at least one rescreen to feel it. 14 days is enough time for a second session and builds more trust before the paywall hits. 7 days is not.

## Implementation (not yet built)

- RevenueCat handles App Store subscriptions, trial periods, and entitlement checks.
- One entitlement (`pro`) gates the app after the trial expires.
- Trial period is configured in App Store Connect (subscription group), not in code.
- Firestore field `isPro: true` on a user document overrides the paywall for manually granted accounts. Checked before any RevenueCat call.

## Free Access for Specific Users

Set `isPro: true` on the user's Firestore document (`users/{uid}`) directly in the Firebase console. The app checks this before hitting RevenueCat, so those users never see a paywall. No promo codes, no App Store involvement needed.

Once RevenueCat is live, it also has a "Grant Entitlement" button per user in its dashboard -- but the Firestore flag works without it and can be set today.

## Promo Codes (not yet built)

Two phases:

1. **Pre-RevenueCat:** simple Firestore promo code table (`promoCodes/{code}` with `trialDays` + `maxRedemptions`). User enters a code in the app, extends their `trialExpiresAt`. Created manually in the Firebase console. Good for pitch handouts -- e.g. 1 month free instead of 14 days.

2. **Post-RevenueCat:** migrate to Apple Offer Codes -- either unique per-person codes or a single vanity code (e.g. `POISE-LAUNCH`) with a redemption cap. Redeemed natively in the App Store.

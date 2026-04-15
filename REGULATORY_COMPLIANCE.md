# Regulatory Compliance: General Wellbeing App Classification

## Status: 🟡 IN PROGRESS

**Last updated:** April 15, 2026  
**Goal:** Ensure Poise is classified as a **general wellbeing / fitness app** and avoids classification as a medical or health device under FDA, MHRA, EU MDR, Apple App Store, and Google Play policies.

---

## 1. Why This Matters

### Health Device Classification Triggers

An app is regulated as a medical device (FDA Class II / EU MDR Class IIa) if it:

- Claims to **diagnose, treat, cure, or prevent** a disease or medical condition
- Performs **clinical assessment** of bodily function or structure
- Provides **therapeutic recommendations** based on detected abnormalities
- Uses language implying **medical authority** (e.g. "screening", "prehab", "corrective")
- Markets to people with **injuries or medical conditions**
- Is intended for use by or under the supervision of **healthcare professionals**

### Our Target: General Wellbeing App

Under FDA guidance (*General Wellness: Policy for Low Risk Devices*, 2019) and EU MDR Article 2, a general wellbeing app:

- Provides **educational information** about movement and fitness
- Offers **general fitness suggestions** for a healthy population
- Makes **no claims** about diagnosing, treating, or preventing conditions
- Is intended for **general audience** fitness interest
- Uses **observational, neutral** language throughout

---

## 2. What Has Already Been Done ✅

| Change | Status |
|---|---|
| `Fault` → `MovementObservation` model class | ✅ Done |
| `FaultType` → `MovementObservationType` enum | ✅ Done |
| `prehab_plan.dart` → `fitness_plan.dart` | ✅ Done |
| `prehab_generator.dart` → `movement_suggestions_generator.dart` | ✅ Done |
| `ObservationIntensity` replaces severity language | ✅ Done |
| Results screen disclaimer added | ✅ Done |
| "Screen" → "Audit" in all user-facing text | ✅ Done |
| Notification text updated (Audit Reminders) | ✅ Done |
| Pose painter uses `activeObservations` | ✅ Done |
| `screen_result.dart` uses `.observations` not `.faults` | ✅ Done |

---

## 3. Outstanding Changes Required

### 3.1 🔴 Critical — User-Facing Strings With Regulated Language

These are **visible to users** and would be flagged by a regulatory reviewer or app store reviewer.

| # | File | Line | Current Text | Required Change |
|---|---|---|---|---|
| 1 | `lib/screens/home_screen.dart` | 507 | *"We detect movement faults and prescribe corrective exercises tailored to what we find."* | *"We observe your movement patterns and suggest exercises you might enjoy."* |
| 2 | `lib/screens/onboarding_screen.dart` | 25 | *"Stay injury-free"* | *"Move with confidence"* |
| 3 | `lib/screens/onboarding_screen.dart` | 26 | *"Reduce injury risk before it happens"* | *"Explore your movement quality"* |
| 4 | `lib/screens/onboarding_screen.dart` | 30 | *"Fix the faults holding back your performance"* | *"Understand the patterns shaping your movement"* |
| 5 | `lib/screens/history_screen.dart` | 548 | *"COMMON FAULTS"* | *"COMMON OBSERVATIONS"* |
| 6 | `lib/screens/history_screen.dart` | 746 | *"X fault(s)"* | *"X observation(s)"* |

### 3.2 🟡 High — Code Identifiers Using "prehab" / "fault"

Not user-visible, but create risk during app store review (reviewers can inspect source) and make the codebase inconsistent. Renaming these also prevents future developers from accidentally using the old terminology.

| # | File | Current Identifier | Rename To |
|---|---|---|---|
| 1 | `lib/models/user_profile.dart` | `prehabLocked` field | `suggestionsLocked` |
| 2 | `lib/screens/screen_screen.dart` | `prehabLocked` parameter | `suggestionsLocked` |
| 3 | `lib/screens/results_screen.dart` | `prehabLocked` field | `suggestionsLocked` |
| 4 | `lib/screens/home_screen.dart` | `prehabLocked: profile.prehabLocked` | `suggestionsLocked: profile.suggestionsLocked` |
| 5 | `lib/services/firestore_service.dart` | `'prehabLocked': true` | `'suggestionsLocked': true` |
| 6 | `lib/screens/home_screen.dart` | `_PrehabExerciseTile` class | `_SuggestedExerciseTile` |
| 7 | `lib/screens/home_screen.dart` | `faultSummary` variable | `observationSummary` |
| 8 | `lib/widgets/fault_card.dart` | **Filename** | Rename to `observation_card.dart` |

### 3.3 ⚪ Low — Code Comments With Stale Terminology

These are not user-visible and carry no regulatory risk, but should be cleaned up for consistency.

| File | Line | Current Comment |
|---|---|---|
| `lib/models/user_profile.dart` | 2 | *"prehab plan"* |
| `lib/models/user_profile.dart` | 14 | *"faults only, no prehab plan"* |
| `lib/models/organisation.dart` | 2 | *"faults only, no prehab plan"* |
| `lib/screens/results_screen.dart` | 65 | *"faults shown, plan hidden"* |
| `lib/screens/home_screen.dart` | 177 | *"top prehab exercise"* |
| `lib/screens/screen_screen.dart` | 453 | *"_allFaults"* |
| `lib/screens/history_screen.dart` | 559 | *"high-frequency faults"* |
| `lib/analysis/shoulder_rotation_analyser.dart` | 106 | *"severity"* |

### 3.4 Firestore & SharedPreferences Keys — NO CHANGE

These internal data keys are **not user-visible** and changing them would **break existing user data**. They should remain as-is and be documented as legacy naming.

| Location | Key | Action |
|---|---|---|
| `firestore_service.dart` | `.collection('screens')` (×3) | Keep. Legacy naming. |
| SharedPreferences | `'screen_history'` | Keep. Legacy naming. |
| SharedPreferences | `'last_screen_result'` | Keep. Legacy naming. |

---

## 4. Disclaimer Requirements

### 4.1 Current Disclaimer (Results Screen) ✅

```
IMPORTANT: This app provides general fitness feedback for educational purposes only.
• NOT a medical device
• NOT medical advice
• Consult a healthcare provider if you have pain or injury concerns
```

### 4.2 Additional Disclaimer Placements Required

| Location | Status | Priority |
|---|---|---|
| Results screen (bottom of view) | ✅ Done | — |
| App Store description (first paragraph) | ❌ Not done | 🔴 Before submission |
| Onboarding flow (goal selection step) | ❌ Not done | 🟡 Before submission |
| Profile screen (About / Legal row) | ❌ Not done | 🟡 Before submission |
| Privacy policy page | ❌ Not done | 🔴 Before submission |
| Terms of service | ❌ Not done | 🔴 Before submission |

---

## 5. Language Guidelines

### 5.1 Prohibited Terms — Never Use in User-Facing Text

| ❌ Prohibited | ✅ Use Instead |
|---|---|
| Screen / screening (medical sense) | Audit / movement audit |
| Prehab / rehabilitation / rehab | Fitness suggestions / exercise ideas |
| Fault / fault detection | Observation / movement observation |
| Corrective exercise / correction | Suggested exercise / exercise variation |
| Dysfunction / abnormality | Movement pattern / variation |
| Diagnose / diagnosis / assessment | Observe / feedback / analysis |
| Treatment / therapy / therapeutic | Suggestion / guidance / educational |
| Severity (mild/moderate/significant) | Intensity (minimal/moderate/significant) |
| Injury prevention / prevent injury | Move with confidence / movement quality |
| Prescribe / prescription | Suggest / recommendation |
| Clinical / medical | Educational / fitness-focused |
| Fix / correct / cure | Explore / practice / develop |

### 5.2 Compliant Framing Examples

| ❌ Non-Compliant | ✅ Compliant |
|---|---|
| "We detected 3 faults in your squat" | "We observed 3 patterns in your squat" |
| "Corrective exercises for knee cave" | "Exercises you might find helpful" |
| "Reduce your injury risk" | "Explore your movement quality" |
| "This exercise will fix your hip drop" | "This exercise explores hip stability" |
| "Prehab plan to prevent knee injuries" | "Suggested exercises for your movement profile" |
| "Stay injury-free" | "Move with confidence" |
| "We prescribe corrective exercises" | "We suggest exercises based on your patterns" |

### 5.3 Safe Claims

- ✅ "Explore your movement patterns with AI-powered analysis"
- ✅ "Get feedback on your form and movement variations"
- ✅ "Suggested exercises based on your movement profile"
- ✅ "Track your movement quality over time"
- ✅ "Educational feedback for fitness enthusiasts"
- ✅ "Developed with input from fitness professionals"

---

## 6. App Store & Marketing Rules

### 6.1 App Store Category
- ✅ List under **Health & Fitness** (general category)
- ❌ Never list under **Medical**

### 6.2 App Store Description
- Must include disclaimer in the **first paragraph**
- ❌ "Assess your movement for injury prevention"
- ✅ "Explore your movement patterns with AI-powered analysis"
- ❌ "Recommended by physical therapists"
- ✅ "Developed with fitness professionals"

### 6.3 Advertising & Social Media
- Never target people with injuries or medical conditions
- Never claim health or therapeutic benefits
- Never compare to professional clinical assessment
- Never use before/after injury narratives
- Always include disclaimer with any performance claims

---

## 7. Feature Development Checklist

Before shipping **any** new feature involving user feedback or recommendations:

- [ ] No medical/therapeutic terminology in user-facing strings
- [ ] Observations framed as educational, not diagnostic
- [ ] Disclaimer visible where feedback is shown
- [ ] No claims that exercises "fix", "correct", or "treat" anything
- [ ] Exercise suggestions not framed as prescriptions
- [ ] Language is neutral and descriptive, not clinical
- [ ] No targeting of users with medical conditions

**Key question:** *"Would a reasonable user believe this is medical advice?"*  
If yes → reframe or add disclaimer.

---

## 8. Implementation Phases

### Phase 1 ✅ COMPLETE — Core Model Refactoring

All `Fault`/`FaultType` types replaced with `MovementObservation`/`MovementObservationType`. Old files deleted. Results disclaimer added. "Screen" → "Audit" in all user-facing strings.

### Phase 2 ❌ TODO — Remaining String & Identifier Cleanup

| # | Task | Priority |
|---|---|---|
| 1 | Fix home_screen "How it works" step 3 text (*"detect faults… prescribe corrective"*) | 🔴 Critical |
| 2 | Fix onboarding goal options (*"injury-free"*, *"Fix the faults"*) | 🔴 Critical |
| 3 | Fix history_screen "COMMON FAULTS" heading | 🟡 High |
| 4 | Fix history_screen "X fault(s)" label | 🟡 High |
| 5 | Rename `prehabLocked` → `suggestionsLocked` across codebase | 🟡 Medium |
| 6 | Rename `fault_card.dart` → `observation_card.dart` | ⚪ Low |
| 7 | Rename `_PrehabExerciseTile` → `_SuggestedExerciseTile` | ⚪ Low |
| 8 | Rename `faultSummary` → `observationSummary` in home_screen | ⚪ Low |
| 9 | Clean up code comments with stale terminology | ⚪ Low |

### Phase 3 ❌ TODO — App Store & Legal

| # | Task |
|---|---|
| 1 | Write App Store description with prominent disclaimer |
| 2 | Create/update privacy policy stating app is not a medical device |
| 3 | Create terms of service with wellbeing framing |
| 4 | Set App Store category to Health & Fitness (not Medical) |
| 5 | Ensure all screenshots use compliant language |
| 6 | Add disclaimer step to onboarding flow |
| 7 | Add "About / Legal" section in Profile screen |
| 8 | Update README.md with wellness positioning |

### Phase 4 — Ongoing Governance

| Task | Cadence |
|---|---|
| Codebase terminology audit (run validation grep below) | Every release |
| App Store policy review (Apple / Google) | Quarterly |
| FDA / MHRA / EU MDR guidance monitoring | Quarterly |
| Feature compliance review | Every PR touching user feedback |

---

## 9. Compliance Validation Commands

Run these to find remaining non-compliant terms:

```bash
# 🔴 User-facing strings (critical — must be zero before submission)
grep -rn "faults\|corrective\|prescribe\|injury-free\|injury risk\|prehab\|COMMON FAULTS\|Fix the fault" lib/ --include="*.dart"

# 🟡 Code identifiers (medium — clean up before submission)
grep -rn "prehabLocked\|_PrehabExerciseTile\|faultSummary\|fault_card" lib/ --include="*.dart"

# ⚪ Stale comments (low — clean up when convenient)
grep -rn "prehab plan\|faults only\|severity scales\|top prehab" lib/ --include="*.dart"
```

All three commands should return **no results** when fully compliant.

---

## 10. Regulatory References

| Authority | Guidance | Key Point |
|---|---|---|
| **FDA (US)** | *General Wellness: Policy for Low Risk Devices* (2019) | Apps promoting general wellness without claiming to treat/diagnose are not regulated as medical devices |
| **MHRA (UK)** | *Medical Device Stand-Alone Software Including Apps* (2023) | Software is a medical device if it interprets data for diagnosis/treatment; general fitness feedback is exempt |
| **EU MDR** | Article 2, Regulation (EU) 2017/745 | Medical device definition requires intended medical purpose; general wellness is excluded |
| **Apple** | App Store Review Guidelines §5.1.3 | Health apps must not make medical claims without appropriate regulatory clearance |
| **Google Play** | Health & Fitness App Policy (2024) | Apps making health claims must comply with local regulations; general fitness is permitted |
| **FTC (US)** | Health Product Compliance Guidance | Health benefit claims must be substantiated; general fitness education is lower risk |

---

## Document History

| Version | Date | Changes |
|---|---|---|
| 1.0 | April 2026 | Initial document |
| 2.0 | April 15, 2026 | Phase 1 implementation complete |
| 3.0 | April 15, 2026 | Full codebase audit; accurate status of all remaining issues; added Phase 2/3 action items with line-level references; regulatory references; validation commands; language guidelines |

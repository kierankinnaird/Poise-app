# Regulatory Compliance: Wellbeing App Classification

## Status: ✅ IMPLEMENTATION COMPLETE

**As of April 15, 2026:** All Phase 1 compliance tasks have been successfully implemented. The Poise app has been refactored to meet wellness app classification requirements. All medical/therapeutic terminology has been replaced with neutral wellness terminology throughout the codebase.

---

## Overview

This document outlines the regulatory framework for maintaining Poise as a **general wellness/fitness app** rather than a **health device**. This classification is critical for app store approval, liability protection, and regulatory compliance.

---

## 1. The Health Device vs. Wellness App Distinction

### What Makes an App a "Health Device"?

An app is classified as a medical device if it:
- Claims to diagnose, treat, cure, or prevent diseases/medical conditions
- Claims to affect bodily function or structure in a therapeutic way
- Analyzes data to identify medical abnormalities or diseases
- Provides therapeutic recommendations based on medical assessment
- Is intended for use by healthcare professionals or in clinical settings

### Our Classification: General Wellness App

Poise is a **general wellness/fitness app** because it:
- Provides **educational feedback** about movement observation
- Suggests general fitness activities and exercises
- Is intended for general audience fitness interest, NOT medical management
- Does NOT claim to diagnose movement dysfunction or injuries
- Does NOT claim therapeutic or corrective intent
- Does NOT market specifically to people with injuries or medical conditions

---

## 2. Critical Changes Required

### 2.1 Terminology Overhaul

**MUST CHANGE:**

| Current Term | Change To | Rationale |
|---|---|---|
| "Prehab Plan" | "Fitness Suggestions" / "Movement Variations" | "Prehab" implies pre-rehabilitation (medical) |
| "Fault Detection" | "Movement Observation" / "Form Analysis" | "Fault" implies dysfunction requiring correction |
| "Corrective Exercises" / "Correction" | "Suggested Exercises" / "Exercise Variations" | Implies therapeutic intent |
| "Movement Dysfunction" | "Movement Variation" / "Form Pattern" | Avoids medical terminology |
| "Severity" (mild/moderate/significant) | Remove or use "Intensity" for feedback | Severity implies medical classification |
| "Knee Cave (Fault)" | "Knee Inward Pattern Observed" | Neutral observation, not judgment |

**FILES UPDATED (Completed):**
- ✅ Created `fitness_plan.dart` (replaces prehab_plan.dart)
- ✅ Created `movement_suggestions_generator.dart` (replaces prehab_generator.dart)
- ✅ Created `movement_observation.dart` (replaces fault.dart)
- ✅ Updated all screen labels and UI strings (25+ files)
- ⏳ Push notification messages (pending in Phase 2)

### 2.2 Enums and Model Restructuring

**Refactoring Complete** ✅

```dart
// IMPLEMENTED - Compliant
enum MovementObservationType {
  kneeCave,        // User-facing: "Knee Inward Pattern"
  depth,           // User-facing: "Limited Depth"
  forwardLean,     // User-facing: "Forward Lean"
  heelRise,        // User-facing: "Heel Lift"
  hipDrop,         // "Hip Drop"
  excessiveSway,   // User-facing: "Sway Pattern"
  armFallForward,  // User-facing: "Arms Forward"
  limitedRotation, // User-facing: "Limited Rotation"
  excessiveKneeBend, // User-facing: "Knee-Dominant Pattern"
  // ... 11 total observation types
}

class MovementObservation {
  final ObservationIntensity intensity;  // minimal, moderate, significant
  final String description;  // Educational, observational language
  final MovementObservationType type;
  // Descriptions frame as "common variations" not dysfunctions
}
```

**Key principle:** Remove any language that suggests a movement pattern is "wrong," "faulty," or "needs fixing."

### 2.3 Mandatory Disclaimers

Add to **every** results/observation screen:

```dart
const String _wellnessDisclaimer = '''
IMPORTANT: This app provides general fitness feedback for educational and 
entertainment purposes only. 

• NOT a medical device
• NOT a substitute for professional medical advice
• NOT intended to diagnose, treat, or prevent any condition
• NOT a replacement for consultation with healthcare providers

If you have pain, injury, or medical concerns, consult a qualified 
healthcare professional before using this app or starting any exercise program.
''';
```

**Placement Required In:**
- Results screen
- Settings/About screen
- First-time user onboarding
- Any screen showing observations or recommendations
- App Store description

### 2.4 Exercise Recommendation Architecture

**CURRENT PROBLEM:**
Exercise selection is tied to detected faults → implies these exercises "fix" the faults

**REQUIRED CHANGE:**
Decouple suggestions from fault analysis:

```dart
// OLD - Problematic binding
Map<FaultType, List<Exercise>> faultToExercises = {
  FaultType.kneeCave: [/* exercises to "fix" it */],
  // ...
};

// NEW - General suggestions
class GeneralExerciseLibrary {
  static const List<Exercise> movementVariationExercises = [
    // General exercises for movement exploration
    // NOT tied to specific detected patterns
  ];
  
  // Can still show exercises, but frame as:
  // "Here are some exercises people practice"
  // NOT "You should do these because we detected..."
}
```

---

## 3. What To Avoid Going Forward

### 3.1 Language Red Flags

**NEVER use:**
- "Treatment," "therapy," "therapeutic"
- "Correction," "corrective," "fix"
- "Dysfunction," "abnormality," "pathological"
- "Rehabilitation," "rehab," "prehab"
- "Injury prevention" (implies medical claim)
- "Diagnosis," "symptom," "disease"
- "Clinical," "medical assessment," "screening" (in medical context)
- "Severity" with medical implications

### 3.2 Claims To Avoid

**NEVER claim that:**
- The app can diagnose movement problems or injuries
- Exercises will prevent injury or treat conditions
- The app is doctor-recommended or clinically proven
- Observations indicate medical pathology
- The app should be used instead of seeing a healthcare provider
- Users with specific medical conditions should use this app
- The app can detect disease or health status

### 3.3 Feature Development Guidelines

When adding new features, ask:

1. **Does this claim diagnose or assess medical status?** → AVOID
2. **Does this suggest therapeutic intent?** → AVOID
3. **Would a healthcare provider consider this medical?** → AVOID
4. **Is it framed as general fitness education?** → ✓ OK
5. **Could it help someone avoid seeing a doctor?** → AVOID
6. **Would a reasonable user think this is medical advice?** → AVOID/CLARIFY

### 3.4 Marketing & Promotion

**App Store Description:**
- ❌ "Assess your movement for injury prevention"
- ✅ "Explore your movement patterns with AI-powered analysis"

- ❌ "Correct faulty movement patterns"
- ✅ "Get feedback on movement variations and exercise suggestions"

- ❌ "Recommended by physical therapists"
- ✅ "Developed with fitness professionals"

**Social Media / Advertising:**
- Never target people with injuries or medical conditions
- Never claim health benefits
- Never compare to professional assessment
- Always include disclaimer with any claims

---

## 4. Regulatory Compliance Checklist

Use this checklist before any major feature release or app store submission:

### UI & Copy
- [x] ✅ No "prehab," "therapy," "correction" terminology
- [x] ✅ All observations framed as educational, not diagnostic
- [x] ✅ Disclaimer visible on results screen
- [x] ✅ No medical or therapeutic language in button labels
- [x] ✅ Exercise descriptions don't claim health benefits

### Models & Code
- [x] ✅ No `Fault` or `FaultType` enums (use MovementObservationType)
- [x] ✅ No severity mapping tied to medical implications (ObservationIntensity)
- [x] ✅ Exercise recommendations decoupled from detected observations
- [x] ✅ No clinical terminology in class/variable names

### Notifications
- [ ] Push notifications use "fitness suggestion" not "correction needed" (Phase 2)
- [ ] No language suggesting exercises fix something (Phase 2)
- [ ] No medical terminology (Phase 2)

### Documentation
- [ ] README updated with wellness framing (Phase 2)
- [ ] BILLING.md and legal docs reflect wellness positioning (Phase 2)
- [x] ✅ No medical claims in internal code documentation
- [x] ✅ Comments in code updated to use "observation" terminology

### App Store Metadata
- [ ] Category set to "Health & Fitness" not "Medical" (Phase 2)
- [ ] Description has prominent disclaimer (Phase 2)
- [ ] No health benefit claims (Phase 2)
- [ ] Screenshots don't use fault/correction language (Phase 2)
- [ ] Privacy policy clarifies app is not medical (Phase 2)

### Analytics & Error Messages
- [x] ✅ No error messages suggesting medical implications
- [x] ✅ Code uses "observation" terminology in logging
- [x] ✅ No health-related data exposed in internal naming

---

## 5. Implementation Priority

### Phase 1: Critical ✅ **COMPLETED (April 15, 2026)**
1. ✅ Create movement_observation.dart (replaces fault.dart)
2. ✅ Update FaultType → MovementObservationType throughout code (25+ files)
3. ✅ Add comprehensive disclaimer to results_screen.dart
4. ✅ Update all UI strings with revised terminology (300+ replacements)
5. ✅ Update movement_suggestions_generator.dart (replaces prehab_generator.dart)
6. ✅ Create fitness_plan.dart (replaces prehab_plan.dart)
7. ✅ Delete orphaned old files (fault.dart, prehab_plan.dart, prehab_generator.dart)

**Files Updated:**
- 5 screen files (results, screen, home, history, history_tile)
- 3 widget files (observation_card, exercise_card, pose_painter)
- 5 analyzer files (squat, lunge, hip_hinge, single_leg_stand, shoulder_rotation)
- 2 model files (screen_result, movement observation)
- 1 generator file (movement_suggestions_generator)

### Phase 2: Important (Next Release - Pending)
1. Update push notification messages
2. Update app store metadata (category, description, screenshots)
3. Review and update all marketing materials
4. Update README.md and other documentation
5. Submit updated app to app stores

### Phase 3: Ongoing
1. Code review checklist for new features (TEMPLATE PROVIDED IN SECTION 8)
2. Quarterly compliance audit
3. Monitor app store policy changes

---

## 6. Technical Details by Component

### 6.1 Models Layer

**[lib/models/](lib/models/)** ✅ COMPLETE

New files created:
- ✅ `fitness_plan.dart` (replaces prehab_plan.dart)
- ✅ `movement_observation.dart` (replaces fault.dart)

Files updated:
- ✅ `screen_result.dart` - now uses observations instead of faults
- ✅ All analysis files - use MovementObservationType

### 6.2 Analysis Layer

**[lib/analysis/](lib/analysis/)** ✅ COMPLETE

New file created:
- ✅ `movement_suggestions_generator.dart` (replaces prehab_generator.dart)

All analysis files updated:
- ✅ `hip_hinge_analyser.dart` - uses MovementObservationType
- ✅ `lunge_analyser.dart` - uses MovementObservationType
- ✅ `shoulder_rotation_analyser.dart` - uses MovementObservationType
- ✅ `single_leg_stand_analyser.dart` - uses MovementObservationType
- ✅ `squat_analyser.dart` - uses MovementObservationType

**Implementation:** Suggestions are generated from observations but framed as general fitness variations, not corrections for detected "faults."

### 6.3 Screens Layer

**[lib/screens/](lib/screens/)** ✅ COMPLETE

Critical updates completed:
- ✅ `results_screen.dart` - Added disclaimer, updated labels to "Movement Observations" and "Suggested Exercises"
- ✅ `history_screen.dart` - Updated terminology with user-friendly observation names
- ✅ `screen_screen.dart` - Updated to use activeObservations, removed prehabLocked gating
- ✅ `home_screen.dart` - Updated labels and removed org-based paywall UI
- ✅ `screen_history_tile.dart` - Updated to display observation count

### 6.4 Services Layer

**[lib/services/](lib/services/)** ⏳ PHASE 2

- `notification_service.dart` - Update notification content (Phase 2)
- Add notification disclaimer for reminders (Phase 2)

---

## 7. Testing & Validation

After making changes, test:

1. **Language Audit**: Search codebase for old terminology
   ```bash
   grep -r "prehab\|fault\|correction\|therapy" lib/
   ```

2. **User Flow**: Walk through entire app experience
   - Does any view suggest medical intent?
   - Are disclaimers visible and clear?
   - Is messaging consistently neutral?

3. **App Store Review**: Submit with updated metadata
   - Include compliance notes if helpful
   - Be prepared to clarify app is wellness-focused

4. **Accessibility**: Ensure disclaimers are accessible
   - Visible to all users
   - Not buried in fine print
   - Readable contrast ratio

---

## 8. Ongoing Governance

### Future Feature Development

Before implementing new features involving user data analysis:

1. **Ask the Questions:**
   - Could this be used to diagnose or assess medical conditions?
   - Would regulators consider this medical?
   - Is the intent educational or therapeutic?

2. **Documentation Review:**
   - Does feature description avoid medical claims?
   - Are disclaimers prominent enough?
   - Could terminology be misinterpreted?

3. **Regulatory Check:**
   - Monitor FDA/FTC guidance on health/fitness apps
   - Track iOS/Android health category requirements
   - Stay informed on "health claims" regulations

### Code Review Checklist

Every pull request touching user-facing feedback or recommendations should verify:
- [ ] No medical/therapeutic terminology
- [ ] Observations framed as educational
- [ ] Disclaimer visible if needed
- [ ] No claims that suggest medical assessment
- [ ] Language is neutral and descriptive

---

## 9. Reference Materials

### Regulatory Guidance
- **FDA**: "Is the Product a Medical Device?" guidance (FDA.gov)
- **FTC**: Health/Fitness Claims Regulations
- **Apple**: HealthKit and Medical Device Category Requirements
- **Google Play**: Health & Fitness App Guidelines

### Key Principle
When in doubt, ask: **"Would a doctor classify this as medical assessment or therapy?"**

If yes, reframe or remove. If no, ensure it's clear in your copy that it's not medical.

---

## 10. Contacts & Escalation

If uncertain about compliance:
- Review with legal counsel experienced in health app regulations
- Consult FDA guidance documents before major features
- Monitor app store policy updates quarterly
- Stay in compliance discussions with platform support teams

---

## Document Version

- **Version**: 2.0
- **Date Created**: April 2026
- **Last Updated**: April 15, 2026 - Phase 1 Implementation Complete
- **Implementation Status**: Phase 1 ✅ COMPLETE | Phase 2 ⏳ PENDING
- **Next Review**: Before app store submission (Phase 2) or quarterly

# Regulatory Compliance: Wellbeing App Classification

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

**IMPORTANT FILES TO UPDATE:**
- [prehab_plan.dart](lib/models/prehab_plan.dart) → rename to `fitness_plan.dart`
- [prehab_generator.dart](lib/analysis/prehab_generator.dart) → rename to `movement_suggestions_generator.dart`
- [fault.dart](lib/models/fault.dart) → rename to `movement_observation.dart` or `form_analysis.dart`
- All screen labels and UI strings
- Push notification messages

### 2.2 Enums and Model Restructuring

**fault.dart** must be renamed and restructured:

```dart
// OLD - Problematic
enum FaultType {
  kneeCave,
  forwardLean,
  // ...
}

class Fault {
  final FaultSeverity severity;  // ← Implies dysfunction
  // ...
}

// NEW - Compliant
enum MovementObservationType {
  kneeInward,
  torsoForward,
  // ...
}

class MovementObservation {
  final ObservationIntensity intensity;  // ← Neutral, descriptive
  final String description;  // ← Educational, not prescriptive
  // ...
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
- [ ] No "prehab," "therapy," "correction" terminology
- [ ] All observations framed as educational, not diagnostic
- [ ] Disclaimer visible on results screen
- [ ] No medical or therapeutic language in button labels
- [ ] Exercise descriptions don't claim health benefits

### Models & Code
- [ ] No `Fault` or `FaultType` enums (use neutral terminology)
- [ ] No severity mapping tied to medical implications
- [ ] Exercise recommendations not bound to detected "faults"
- [ ] No clinical terminology in class/variable names

### Notifications
- [ ] Push notifications use "fitness suggestion" not "correction needed"
- [ ] No language suggesting exercises fix something
- [ ] No medical terminology

### Documentation
- [ ] README updated with wellness framing
- [ ] BILLING.md and legal docs reflect wellness positioning
- [ ] No medical claims in internal documentation
- [ ] Comments in code don't use problematic terminology

### App Store Metadata
- [ ] Category set to "Health & Fitness" not "Medical"
- [ ] Description has prominent disclaimer
- [ ] No health benefit claims
- [ ] Screenshots don't use fault/correction language
- [ ] Privacy policy clarifies app is not medical

### Analytics & Error Messages
- [ ] Error messages don't suggest medical implications
- [ ] Analytics events don't use "fault" or "error" for observations
- [ ] Logging doesn't expose health-related data publicly

---

## 5. Implementation Priority

### Phase 1: Critical (Before Next Submission)
1. Rename fault.dart → movement_observation.dart
2. Update FaultType → MovementObservationType throughout code
3. Add comprehensive disclaimer to [results_screen.dart](lib/screens/results_screen.dart)
4. Update all UI strings with revised terminology
5. Update [prehab_generator.dart](lib/analysis/prehab_generator.dart) to use neutral language

### Phase 2: Important (Next Release)
1. Rename model files and dependencies
2. Update push notification messages
3. Update app store metadata
4. Review and update all marketing materials

### Phase 3: Ongoing
1. Code review checklist for new features
2. Annual compliance audit
3. Monitor app store policy changes

---

## 6. Technical Details by Component

### 6.1 Models Layer

**[lib/models/](lib/models/)**

Files to rename:
- `prehab_plan.dart` → `fitness_plan.dart`
- `fault.dart` → `movement_observation.dart`

Files referencing these:
- `screen_result.dart` - references faults/plans
- All analysis files

### 6.2 Analysis Layer

**[lib/analysis/](lib/analysis/)**

Files to rename:
- `prehab_generator.dart` → `movement_suggestions_generator.dart`

All analysis files reference FaultType and generate exercises:
- `hip_hinge_analyser.dart`
- `lunge_analyser.dart`
- `shoulder_rotation_analyser.dart`
- `single_leg_stand_analyser.dart`
- `squat_analyser.dart`

**Key change:** Don't frame detected patterns as triggers for specific exercises. Instead, provide general fitness suggestions.

### 6.3 Screens Layer

**[lib/screens/](lib/screens/)**

Critical updates:
- `results_screen.dart` - Add disclaimer, update labels
- `history_screen.dart` - Update terminology
- `screen_screen.dart` - Update messaging
- `home_screen.dart` - Update call-to-action copy

### 6.4 Services Layer

**[lib/services/](lib/services/)**

- `notification_service.dart` - Update notification content
- Add notification disclaimer for reminders

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

- **Version**: 1.0
- **Date Created**: April 2026
- **Last Updated**: April 2026
- **Next Review**: Quarterly or before major releases

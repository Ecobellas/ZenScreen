# ZenScreen

## What This Is

ZenScreen is a mindful screen time control app for adults (25-45 age range) who struggle with compulsive phone usage and doomscrolling. Instead of hard blocking, it uses "mindful friction" — breathing exercises, intention prompts, and progressive wait timers — to help users pause and make conscious decisions about their phone usage. Built with Flutter for iOS and Android, targeting App Store and Google Play.

## Core Value

When a user reaches for a distracting app, ZenScreen creates a meaningful pause that breaks the autopilot habit — this friction moment is the product.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Onboarding flow (7 steps: welcome, shock stat, goal selection, app selection, friction preference, permission priming, ready)
- [ ] Smart Friction Engine with 3 types: wait timer (escalating 5-30s), breathing exercise (15s animated), intention prompt (4 choices)
- [ ] App blocking: time-based schedules (e.g., 22:00-07:00), daily time limits per app/group, app groups with preset categories
- [ ] Intention Journal: log why user opens each app (work, social, boredom, just checking), weekly breakdown with pie chart
- [ ] Digital Health Score: daily 0-100 score based on screen time, open count, night usage, friction dismiss rate
- [ ] Strict Mode: irreversible blocking for scheduled periods, emergency bypass with 60s wait
- [ ] Weekly Report: push notification on Monday with screen time comparison, top 5 apps, health score trend, intention breakdown
- [ ] Dashboard: daily score display, today's summary cards, quick action buttons
- [ ] Statistics: daily/weekly/monthly charts, per-app usage breakdown, intention journal detail view
- [ ] Settings: friction type selection, blocking rules management, time profiles (Work/Night/Weekend), Strict Mode scheduling
- [ ] Blocking overlay: full-screen "app is blocked" screen with motivational message
- [ ] Friction overlays: wait timer countdown, breathing animation, intention question — shown when user opens restricted app
- [ ] Native platform integration: iOS Screen Time API / Family Controls, Android UsageStats + Accessibility Service
- [ ] Paywall: premium subscription ($44.99/year) with feature-gated triggers (6th app, breath/intention friction, Strict Mode)
- [ ] In-app purchase integration (RevenueCat or native StoreKit 2 / Google Play Billing)
- [ ] Dark theme ("Mindful Dark") with purple-blue primary (#6C63FF) and neon green accent (#00D9A3)
- [ ] Local data storage: SharedPreferences for settings, SQLite for usage stats and intention logs
- [ ] Background service: foreground service (Android) / background app refresh (iOS) for continuous monitoring
- [ ] Push notifications: weekly report, approaching daily limit (5min warning), Strict Mode reminders

### Out of Scope

- Backend/cloud sync — V1 is fully offline/local, no user accounts
- Multi-language support — English only for V1
- Apple Watch / wearable widgets — defer to V2
- Chrome extension / web blocking — defer to V2
- Location-based profiles (GPS geofencing) — defer to V2
- Accountability partner / social features — defer to V2
- Adaptive friction (AI-based auto difficulty) — defer to V2
- GitHub-style heatmap visualization — defer to V2
- Shareable social cards — defer to V2

## Context

### Competitive Landscape
Based on analysis of 6 competitors (ScreenZen, Opal, OffScreen, BePresent, Refocus, ClearSpace):
- ScreenZen: Free, donation-supported, mindful friction pioneer. Our closest philosophical match but lacks analytics depth.
- Opal: Premium ($99.99/yr), most feature-rich, 3D gem gamification. We're half the price with unique intention journaling.
- ClearSpace: Breathing exercise + physical challenges. Y Combinator backed. We share the breathing concept but add intention tracking.
- BePresent: Social gamification leader ($250K/mo revenue). We focus on individual mindfulness instead.

### Key Differentiators
1. **Intention Journal** — No competitor asks "why are you opening this?" and tracks patterns over time.
2. **Smart Friction Engine** — 3 friction types (wait/breath/intention) vs competitors who offer 1-2.
3. **Digital Health Score** — Composite metric combining multiple signals, not just screen time.
4. **Price** — $44.99/yr vs Opal ($99.99) and BePresent (~$60), with generous free tier (5 apps).

### Technical Context
- Flutter 3.x with Riverpod 3.x state management, GoRouter navigation
- iOS: Family Controls framework (iOS 15+) for app blocking, Screen Time API for usage data
- Android: UsageStatsManager for usage data, AccessibilityService for app detection/blocking
- Method Channels for native platform communication
- SQLite (sqflite) for structured data, SharedPreferences for settings
- RevenueCat SDK for cross-platform in-app purchases

## Constraints

- **Platform**: Flutter — cross-platform iOS + Android from single codebase
- **iOS minimum**: iOS 15+ (Family Controls framework requirement)
- **Android minimum**: Android 10+ (UsageStats API improvements)
- **Storage**: Local only — no backend, no cloud sync, no user accounts
- **Language**: English only
- **Architecture**: Feature-first folder structure with Riverpod 3.x providers
- **Monetization**: Freemium with feature-gated paywall (not time-gated)
- **Store compliance**: Must comply with Apple/Google accessibility service policies for app blocking

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flutter over native | Single codebase for iOS + Android, faster development, prior team experience | — Pending |
| Riverpod 3.x over Bloc | Simpler API, better code generation, team familiarity from CrossMath/Reflex Pro | — Pending |
| Local-only over cloud | Simpler MVP, no backend costs, privacy-friendly positioning, faster to market | — Pending |
| RevenueCat for IAP | Cross-platform purchase management, analytics, simpler than raw StoreKit/Billing | — Pending |
| Feature-gated paywall | Higher trust than onboarding paywall, proven conversion pattern (ClearSpace model) | — Pending |
| Dark theme default | Competitors with dark themes (Opal, BePresent) have highest premium perception | — Pending |
| 3 friction types | Broader appeal than single-method competitors, user choice increases retention | — Pending |

---
*Last updated: 2026-02-25 after initialization*

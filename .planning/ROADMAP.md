# Roadmap: ZenScreen

## Overview

ZenScreen delivers a mindful screen time control app through 7 phases. We start with project scaffolding and theme, then build the first-launch onboarding experience. Phase 3 establishes the native platform bridge (the hardest technical layer -- background services, permissions, app usage detection) which unblocks Phases 4 and 5. Phase 4 delivers the friction engine (the core product), Phase 5 adds blocking and Strict Mode. Phase 6 builds the analytics layer (intention journal, health score, dashboard, statistics). Phase 7 wraps up with weekly reports, full settings screens, and the monetization paywall.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Project Foundation** - Flutter scaffold with theme, navigation shell, and data layer
- [ ] **Phase 2: Onboarding** - 7-step first-launch flow capturing user goals, app selections, and preferences
- [ ] **Phase 3: Platform Bridge** - Native iOS/Android services for app monitoring, permissions, and usage data
- [ ] **Phase 4: Friction Engine** - Wait timer, breathing exercise, and intention prompt overlays on restricted app opens
- [ ] **Phase 5: Blocking and Strict Mode** - Time-based schedules, daily limits, app groups, and irreversible Strict Mode
- [ ] **Phase 6: Analytics and Dashboard** - Intention journal, health score, dashboard, and statistics screens
- [ ] **Phase 7: Reports, Settings, and Monetization** - Weekly reports, full settings, and feature-gated paywall

## Phase Details

### Phase 1: Project Foundation
**Goal**: A running Flutter app with the ZenScreen theme, bottom navigation shell, routing, and local storage ready for feature development
**Depends on**: Nothing (first phase)
**Requirements**: SETUP-01, SETUP-02, SETUP-03, SETUP-04
**Success Criteria** (what must be TRUE):
  1. App launches on both iOS simulator and Android emulator showing the Mindful Dark theme with purple-blue primary and neon green accent
  2. Bottom navigation switches between three tab placeholders (Dashboard, Statistics, Settings) without errors
  3. GoRouter navigates to all defined routes (including onboarding, overlays, and detail screens) with correct transitions
  4. SQLite database and SharedPreferences are initialized and can persist a test value across app restarts
**Plans**: TBD

Plans:
- [ ] 01-01: TBD
- [ ] 01-02: TBD

### Phase 2: Onboarding
**Goal**: First-time users complete a guided 7-step onboarding that captures their goals, apps to restrict, and friction preferences -- and never see it again
**Depends on**: Phase 1
**Requirements**: ONBD-01, ONBD-02, ONBD-03, ONBD-04, ONBD-05, ONBD-06
**Success Criteria** (what must be TRUE):
  1. First-time user sees the 7-step onboarding flow in sequence (welcome, shock stat, goal selection, app selection, friction preference, permission priming, ready)
  2. User can select a goal, pick apps from categorized lists, and choose a friction type -- and these selections persist in local storage
  3. After completing onboarding, the app navigates to the Dashboard and never shows onboarding again on subsequent launches
  4. Permission priming screen clearly explains what permissions are needed and why, before any OS-level prompt fires
**Plans**: TBD

Plans:
- [ ] 02-01: TBD
- [ ] 02-02: TBD

### Phase 3: Platform Bridge
**Goal**: Native iOS and Android services are running in the background, detecting app usage, and communicating with Flutter through method channels
**Depends on**: Phase 1
**Requirements**: PLAT-01, PLAT-02, PLAT-03, PLAT-04
**Success Criteria** (what must be TRUE):
  1. Background service runs continuously on both platforms (foreground service on Android, background app refresh on iOS) and survives app being backgrounded
  2. Method channel bridge passes data bidirectionally between Flutter and native code without errors
  3. App requests and handles all required permissions (Usage Access on Android, Screen Time on iOS, Notifications) with proper grant/deny flows
  4. App usage data (which apps opened, how long, timestamps) is collected from native APIs and accessible in Flutter
**Plans**: TBD

Plans:
- [ ] 03-01: TBD
- [ ] 03-02: TBD

### Phase 4: Friction Engine
**Goal**: When a user opens a restricted app, they are intercepted with a friction overlay (wait timer, breathing exercise, or intention prompt) that creates a mindful pause before they can proceed
**Depends on**: Phase 3
**Requirements**: FRIC-01, FRIC-02, FRIC-03, FRIC-04, FRIC-05, FRIC-06, FRIC-07
**Success Criteria** (what must be TRUE):
  1. Opening a restricted app triggers the assigned friction overlay (wait timer starts at 5s and escalates by +5s per consecutive open up to 30s; breathing exercise shows 15s animated inhale/exhale; intention prompt shows 4 choices)
  2. Every friction overlay shows both "Give Up" (closes the app) and "Open Anyway" (lets user through) buttons that work correctly
  3. First 3 opens per day pass through without friction; friction activates from the 4th open onward (grace period)
  4. User can assign different friction types to different app groups and configure escalation and grace period settings
**Plans**: TBD

Plans:
- [ ] 04-01: TBD
- [ ] 04-02: TBD

### Phase 5: Blocking and Strict Mode
**Goal**: Users can create blocking schedules and daily time limits that prevent access to apps, and activate an irreversible Strict Mode for focused periods
**Depends on**: Phase 3, Phase 4
**Requirements**: BLCK-01, BLCK-02, BLCK-03, BLCK-04, BLCK-05, BLCK-06, BLCK-07, BLCK-08, STRK-01, STRK-02, STRK-03, STRK-04
**Success Criteria** (what must be TRUE):
  1. User can create time-based blocking schedules (start/end time, days of week) and daily time limits per app or app group, enforced via native iOS Family Controls and Android AccessibilityService
  2. When a limit is reached or schedule is active, a full-screen blocking overlay appears with a motivational message and no bypass option
  3. User can create and manage app groups (Social Media, Video, Games, News, custom) and assign them to time profiles (Work, Night, Weekend)
  4. User can start Strict Mode with an irreversible warning; during Strict Mode all blocked apps are completely inaccessible except via 60-second emergency bypass with explicit confirmation
  5. User receives a push notification when 5 minutes remain on a daily limit
**Plans**: TBD

Plans:
- [ ] 05-01: TBD
- [ ] 05-02: TBD
- [ ] 05-03: TBD

### Phase 6: Analytics and Dashboard
**Goal**: Users can see their digital health score, today's usage summary, intention patterns, and detailed statistics across daily/weekly/monthly views
**Depends on**: Phase 4, Phase 5
**Requirements**: INTJ-01, INTJ-02, INTJ-03, INTJ-04, HLTH-01, HLTH-02, HLTH-03, HLTH-04, DASH-01, DASH-02, DASH-03, DASH-04, STAT-01, STAT-02, STAT-03, STAT-04
**Success Criteria** (what must be TRUE):
  1. Dashboard shows today's Digital Health Score (0-100) as a large circular progress indicator with emoji feedback, plus today's screen time, app opens, friction dismissals, and top 3 most-used apps
  2. Every intention selection from friction prompts is logged and viewable as a daily pie chart breakdown (Work vs Social vs Boredom vs Just Checking) with weekly trends
  3. Intention journal shows insight text like "This week you opened Instagram mostly out of Boredom (65%)" based on actual logged data
  4. Statistics screen shows daily/weekly/monthly screen time charts, per-app usage breakdown with time bars, filterable intention journal detail, and week-over-week comparison with percentage change
  5. Health score resets daily at midnight and 7-day/30-day trend charts are available
**Plans**: TBD

Plans:
- [ ] 06-01: TBD
- [ ] 06-02: TBD
- [ ] 06-03: TBD

### Phase 7: Reports, Settings, and Monetization
**Goal**: Users receive automated weekly reports, can fully configure all app settings, and encounter a feature-gated paywall when reaching premium boundaries
**Depends on**: Phase 6
**Requirements**: REPT-01, REPT-02, REPT-03, REPT-04, STNG-01, STNG-02, STNG-03, STNG-04, STNG-05, MNTZ-01, MNTZ-02, MNTZ-03, MNTZ-04, MNTZ-05, MNTZ-06
**Success Criteria** (what must be TRUE):
  1. Automated weekly report generates every Monday with screen time comparison, top 5 apps, health score trend, intention breakdown, and a motivational tip -- delivered via push notification
  2. Settings screen provides full control: theme toggle, notification preferences, friction type per group, grace period, escalation, blocking schedules, app group management, time profiles, Strict Mode scheduling, data export (CSV), and reset
  3. Free tier users can monitor 5 apps with wait timer friction only, 7-day journal history, and basic health score; premium features are clearly gated
  4. Paywall appears at natural trigger points (adding 6th app, selecting breath/intention friction, starting Strict Mode, adding 2nd profile) with feature comparison and 7-day free trial
  5. RevenueCat SDK handles cross-platform subscription management for the $44.99/year premium tier
**Plans**: TBD

Plans:
- [ ] 07-01: TBD
- [ ] 07-02: TBD
- [ ] 07-03: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Project Foundation | 0/0 | Not started | - |
| 2. Onboarding | 0/0 | Not started | - |
| 3. Platform Bridge | 0/0 | Not started | - |
| 4. Friction Engine | 0/0 | Not started | - |
| 5. Blocking and Strict Mode | 0/0 | Not started | - |
| 6. Analytics and Dashboard | 0/0 | Not started | - |
| 7. Reports, Settings, and Monetization | 0/0 | Not started | - |

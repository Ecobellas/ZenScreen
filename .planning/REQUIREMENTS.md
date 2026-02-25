# Requirements: ZenScreen

**Defined:** 2026-02-25
**Core Value:** When a user reaches for a distracting app, ZenScreen creates a meaningful pause that breaks the autopilot habit — this friction moment is the product.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Project Setup

- [ ] **SETUP-01**: Flutter project initialized with feature-first folder structure, Riverpod 3.x, GoRouter, sqflite, SharedPreferences
- [ ] **SETUP-02**: Dark theme system ("Mindful Dark") with purple-blue primary (#6C63FF), neon green accent (#00D9A3), dark backgrounds
- [ ] **SETUP-03**: Bottom navigation with 3 tabs: Dashboard, Statistics, Settings
- [ ] **SETUP-04**: GoRouter navigation structure with all app routes defined

### Onboarding

- [ ] **ONBD-01**: User sees 7-step onboarding flow on first launch (welcome, shock stat, goal, app selection, friction preference, permission priming, ready)
- [ ] **ONBD-02**: User can select their goal: Reduce screen time / Mindful usage / Better sleep
- [ ] **ONBD-03**: User can select apps to restrict from categorized list (Social, Video, Games, News)
- [ ] **ONBD-04**: User can choose preferred friction type (wait timer, breathing, intention prompt)
- [ ] **ONBD-05**: User sees permission priming screen explaining why permissions are needed before OS prompt
- [ ] **ONBD-06**: Onboarding state persists — user never sees it again after completion

### Friction Engine

- [ ] **FRIC-01**: Wait timer overlay appears when user opens restricted app, starting at 5s and escalating by +5s per consecutive open (max 30s)
- [ ] **FRIC-02**: Breathing exercise overlay with 15-second animated inhale/exhale circle and calming quote
- [ ] **FRIC-03**: Intention prompt overlay asks "Why are you opening this?" with 4 choices: Work/Communication, Socializing, Boredom, Just Checking
- [ ] **FRIC-04**: Each friction overlay shows "Give Up" (close app) and "Open Anyway" buttons
- [ ] **FRIC-05**: User can assign different friction types per app group
- [ ] **FRIC-06**: Grace period: first 3 opens per day skip friction, friction activates from 4th open onward
- [ ] **FRIC-07**: Friction settings are configurable: type selection, escalation on/off, grace period count

### App Blocking

- [ ] **BLCK-01**: User can create time-based blocking schedules (start/end time, days of week)
- [ ] **BLCK-02**: User can set daily time limits per app or app group (e.g., Instagram 30min/day)
- [ ] **BLCK-03**: User receives notification when 5 minutes remain on a daily limit
- [ ] **BLCK-04**: Full-screen blocking overlay appears when limit is reached or schedule is active, with motivational message
- [ ] **BLCK-05**: User can create and manage app groups (preset categories: Social Media, Video, Games, News + custom groups)
- [ ] **BLCK-06**: Time profiles: Work, Night, Weekend presets with custom schedule and blocked groups per profile
- [ ] **BLCK-07**: Native iOS blocking via Family Controls / Screen Time API
- [ ] **BLCK-08**: Native Android blocking via UsageStatsManager + AccessibilityService

### Strict Mode

- [ ] **STRK-01**: User can start Strict Mode for a scheduled period with clear "irreversible" warning
- [ ] **STRK-02**: During Strict Mode, blocked apps are completely inaccessible — no bypass possible
- [ ] **STRK-03**: Emergency bypass requires 60-second wait + explicit "Is this truly urgent?" confirmation
- [ ] **STRK-04**: User can schedule recurring Strict Mode periods (e.g., every weeknight 22:00-07:00)

### Intention Journal

- [ ] **INTJ-01**: Every intention selection during friction is logged with timestamp, app name, choice, and whether user proceeded
- [ ] **INTJ-02**: User can view daily intention breakdown as pie chart (Work vs Social vs Boredom vs Just Checking)
- [ ] **INTJ-03**: User can view weekly intention trends showing change over time
- [ ] **INTJ-04**: Journal shows insight text: "This week you opened Instagram mostly out of Boredom (65%)"

### Digital Health Score

- [ ] **HLTH-01**: Daily score calculated (0-100) based on: screen time vs goal, app open count, night usage, friction dismiss rate, bypass count
- [ ] **HLTH-02**: Score displayed as large circular progress indicator with emoji feedback (80+ happy, 50-79 neutral, <50 sad)
- [ ] **HLTH-03**: User can view 7-day and 30-day score trend chart
- [ ] **HLTH-04**: Score resets daily at midnight

### Dashboard

- [ ] **DASH-01**: Dashboard shows today's Digital Health Score prominently
- [ ] **DASH-02**: Dashboard shows today's summary: total screen time, app opens, friction dismissals
- [ ] **DASH-03**: Dashboard shows quick action buttons: Start Strict Mode, View Report
- [ ] **DASH-04**: Dashboard shows top 3 most-used apps today with time spent

### Statistics

- [ ] **STAT-01**: User can view screen time charts for daily, weekly, and monthly periods
- [ ] **STAT-02**: User can view per-app usage breakdown with time bars
- [ ] **STAT-03**: User can view intention journal detail with filters (by app, by intention type, by date range)
- [ ] **STAT-04**: Weekly comparison: this week vs last week with percentage change indicators

### Weekly Report

- [ ] **REPT-01**: Automated weekly report generated every Monday
- [ ] **REPT-02**: Report includes: total screen time comparison, top 5 apps, health score average + trend, intention breakdown summary
- [ ] **REPT-03**: Push notification sent Monday morning linking to report screen
- [ ] **REPT-04**: Motivational message and tip for the coming week based on previous week's data

### Settings

- [ ] **STNG-01**: General settings: theme toggle (dark/light, default dark), notification preferences
- [ ] **STNG-02**: Friction settings: type selection per group, grace period count, escalation toggle
- [ ] **STNG-03**: Blocking settings: app/group management, schedule editing, profile management
- [ ] **STNG-04**: Strict Mode settings: scheduling, emergency bypass toggle
- [ ] **STNG-05**: Data settings: export data as CSV, reset all data, about/privacy/support info

### Platform Integration

- [ ] **PLAT-01**: Background service running continuously to monitor app usage (foreground service on Android, background app refresh on iOS)
- [ ] **PLAT-02**: Method Channel bridge for native platform communication (Flutter <-> iOS/Android)
- [ ] **PLAT-03**: Permission handling: request and manage Usage Access (Android), Screen Time (iOS), Notification permissions
- [ ] **PLAT-04**: App usage data collection from native APIs (UsageStatsManager / Screen Time API)

### Monetization

- [ ] **MNTZ-01**: Free tier: 5 app limit, wait timer friction only, 7-day intention journal, basic health score
- [ ] **MNTZ-02**: Premium tier ($44.99/yr): unlimited apps, all friction types, Strict Mode, full journal history, detailed reports, CSV export, 3+ profiles
- [ ] **MNTZ-03**: Paywall screen with feature comparison, testimonials area, and purchase buttons
- [ ] **MNTZ-04**: Feature-gated triggers: paywall shown when user tries to add 6th app, select breath/intention friction, start Strict Mode, or add 2nd profile
- [ ] **MNTZ-05**: 7-day free trial for premium
- [ ] **MNTZ-06**: RevenueCat SDK integration for cross-platform subscription management

## v2 Requirements

### Advanced Features

- **ADV-01**: Adaptive friction — AI-based auto difficulty adjustment based on user success rate
- **ADV-02**: GitHub-style heatmap for long-term progress visualization
- **ADV-03**: Accountability partner — invite friend, send notifications on limit breach
- **ADV-04**: Apple Watch widget showing daily score
- **ADV-05**: Chrome extension for web blocking
- **ADV-06**: Location-based profiles via GPS geofencing (auto-switch at school/work/home)
- **ADV-07**: Shareable social cards for Instagram/TikTok ("I saved 12 hours this week")
- **ADV-08**: Settings lock with PIN protection
- **ADV-09**: Before/After comparison graphics
- **ADV-10**: Multi-language support (Turkish, German, Spanish, etc.)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Backend / cloud sync | V1 is fully offline/local — simpler, faster, privacy-friendly |
| User accounts / login | No backend means no accounts needed |
| Social features / leaderboards | Individual mindfulness focus, not social competition |
| Physical exercise challenges (ML) | High technical complexity for MVP, defer to V2+ |
| Parental controls / child mode | ZenScreen targets adults; FocusNest concept covers family use case |
| Real-time group sessions | High backend complexity, not aligned with solo mindfulness approach |
| Monetary stake / betting system | Ethical concerns, not aligned with mindful approach |
| NFC tag blocking | Hardware dependency, niche feature |
| AI Coach / LLM integration | High cost and complexity for MVP |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SETUP-01 | Phase 1 | Pending |
| SETUP-02 | Phase 1 | Pending |
| SETUP-03 | Phase 1 | Pending |
| SETUP-04 | Phase 1 | Pending |
| ONBD-01 | Phase 2 | Pending |
| ONBD-02 | Phase 2 | Pending |
| ONBD-03 | Phase 2 | Pending |
| ONBD-04 | Phase 2 | Pending |
| ONBD-05 | Phase 2 | Pending |
| ONBD-06 | Phase 2 | Pending |
| PLAT-01 | Phase 3 | Pending |
| PLAT-02 | Phase 3 | Pending |
| PLAT-03 | Phase 3 | Pending |
| PLAT-04 | Phase 3 | Pending |
| FRIC-01 | Phase 4 | Pending |
| FRIC-02 | Phase 4 | Pending |
| FRIC-03 | Phase 4 | Pending |
| FRIC-04 | Phase 4 | Pending |
| FRIC-05 | Phase 4 | Pending |
| FRIC-06 | Phase 4 | Pending |
| FRIC-07 | Phase 4 | Pending |
| BLCK-01 | Phase 5 | Pending |
| BLCK-02 | Phase 5 | Pending |
| BLCK-03 | Phase 5 | Pending |
| BLCK-04 | Phase 5 | Pending |
| BLCK-05 | Phase 5 | Pending |
| BLCK-06 | Phase 5 | Pending |
| BLCK-07 | Phase 5 | Pending |
| BLCK-08 | Phase 5 | Pending |
| STRK-01 | Phase 5 | Pending |
| STRK-02 | Phase 5 | Pending |
| STRK-03 | Phase 5 | Pending |
| STRK-04 | Phase 5 | Pending |
| INTJ-01 | Phase 6 | Pending |
| INTJ-02 | Phase 6 | Pending |
| INTJ-03 | Phase 6 | Pending |
| INTJ-04 | Phase 6 | Pending |
| HLTH-01 | Phase 6 | Pending |
| HLTH-02 | Phase 6 | Pending |
| HLTH-03 | Phase 6 | Pending |
| HLTH-04 | Phase 6 | Pending |
| DASH-01 | Phase 6 | Pending |
| DASH-02 | Phase 6 | Pending |
| DASH-03 | Phase 6 | Pending |
| DASH-04 | Phase 6 | Pending |
| STAT-01 | Phase 6 | Pending |
| STAT-02 | Phase 6 | Pending |
| STAT-03 | Phase 6 | Pending |
| STAT-04 | Phase 6 | Pending |
| REPT-01 | Phase 7 | Pending |
| REPT-02 | Phase 7 | Pending |
| REPT-03 | Phase 7 | Pending |
| REPT-04 | Phase 7 | Pending |
| STNG-01 | Phase 7 | Pending |
| STNG-02 | Phase 7 | Pending |
| STNG-03 | Phase 7 | Pending |
| STNG-04 | Phase 7 | Pending |
| STNG-05 | Phase 7 | Pending |
| MNTZ-01 | Phase 7 | Pending |
| MNTZ-02 | Phase 7 | Pending |
| MNTZ-03 | Phase 7 | Pending |
| MNTZ-04 | Phase 7 | Pending |
| MNTZ-05 | Phase 7 | Pending |
| MNTZ-06 | Phase 7 | Pending |

**Coverage:**
- v1 requirements: 64 total
- Mapped to phases: 64
- Unmapped: 0

---
*Requirements defined: 2026-02-25*
*Last updated: 2026-02-25 after roadmap creation*

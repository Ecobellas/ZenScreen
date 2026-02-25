# Phase 1: Project Foundation - Context

**Gathered:** 2026-02-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Flutter project scaffold with the ZenScreen "Mindful Dark" theme, 3-tab bottom navigation shell, GoRouter navigation for all app routes, and local data layer (SQLite + SharedPreferences). No feature logic — just the skeleton that all subsequent phases build on.

</domain>

<decisions>
## Implementation Decisions

### Theme & Visual Style
- Dark theme ("Mindful Dark") as default and only theme for now (light theme in settings is v1 but can be a simple inversion)
- Background: #0D0D0F, Surface: #1A1A1F, Card: #242429
- Primary: #6C63FF (purple-blue), Secondary/Accent: #00D9A3 (neon green), Error: #FF6B6B
- Text primary: #FFFFFF, Text secondary: #9898A0, Text hint: #5A5A65
- Border radius: 16px for cards, 24px for bottom sheets/modals, 12px for buttons
- Subtle glassmorphism for overlay screens (friction/blocking overlays in later phases)
- Fonts: Inter for all text, JetBrains Mono for numbers/metrics/scores
- Font sizes: 12/14/16/20/24/32/40 scale
- Smooth animations: 300ms default, 500ms for page transitions

### Navigation Structure
- Bottom navigation with 3 tabs: Dashboard (home icon), Statistics (chart icon), Settings (gear icon)
- Tab labels visible below icons
- Active tab uses primary color (#6C63FF), inactive uses text secondary (#9898A0)
- Each tab maintains its own navigation stack (ShellRoute with GoRouter)
- Page transitions: slide from right for push, fade for tab switches

### Folder Architecture
- Feature-first structure: lib/features/{feature_name}/
- Each feature has: screens/, widgets/, providers/, models/, repositories/
- Shared code: lib/core/ (theme, router, database, constants, extensions)
- lib/core/theme/ — AppTheme, AppColors, AppTextStyles, AppSpacing
- lib/core/router/ — GoRouter configuration with all routes
- lib/core/database/ — SQLite helper, SharedPreferences wrapper
- lib/core/models/ — shared data models (AppGroup, DailyStats, IntentionLog, UserProfile, TimeProfile)
- lib/core/providers/ — shared providers (database, preferences, theme)
- lib/core/widgets/ — reusable widgets (cards, buttons, progress indicators)

### Data Layer
- SQLite database with tables: daily_stats, intention_logs, app_groups, time_profiles, blocked_apps
- SharedPreferences for: onboarding_complete, preferred_friction_type, daily_screen_time_goal, is_premium, premium_expiry, selected_goal, theme_mode
- Database version 1 with migration support built in from start
- Repository pattern: each feature has a repository that abstracts data access

### Route Structure
- /onboarding — 7-step PageView (Phase 2 implements)
- /dashboard — main dashboard tab
- /statistics — statistics tab
- /statistics/journal — intention journal detail
- /statistics/app/:id — per-app detail
- /settings — settings tab
- /settings/blocking — blocking management
- /settings/blocking/group/:id — group edit
- /settings/profiles — time profiles
- /settings/strict-mode — strict mode config
- /settings/paywall — premium purchase
- /report — weekly report detail
- /overlay/friction — friction overlay (handled separately as system overlay)
- /overlay/blocking — blocking overlay

### Claude's Discretion
- Exact icon choices for bottom navigation (from Material Icons or Lucide)
- Splash screen design and duration
- Exact animation curves (Curves.easeInOut vs custom)
- SQLite table column details and indexes
- SharedPreferences key naming convention
- Whether to use code generation (freezed/json_serializable) for models
- Widget test setup structure

</decisions>

<specifics>
## Specific Ideas

- Theme should feel premium like Opal — dark, calm, confident. Not "dark for dark's sake" but purposeful darkness that reduces eye strain during night usage
- Numbers and metrics should pop with JetBrains Mono — health score, screen time, percentages
- Neon green (#00D9A3) reserved for positive/success states — score improvements, goals met, friction dismissed
- Purple-blue (#6C63FF) is the brand color — buttons, active states, progress indicators
- Cards should have subtle elevation/shadow, not flat — separated from surface background

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-project-foundation*
*Context gathered: 2026-02-25*

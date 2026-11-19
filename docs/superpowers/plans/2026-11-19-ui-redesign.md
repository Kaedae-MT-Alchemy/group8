# Alchemy Lavender UI Redesign Implementation Plan

> For agentic workers: work task by task, tick the boxes, run the named check after each task.

**Goal:** Make the public site and course pages minimal, easy to follow and animated (hero banner, rotating programme cards, scroll reveals), with real, working course resources, without breaking any existing function.

**Architecture:** Re-skin globally through tokens (`lib/theme.dart`) and the shared building blocks (`widgets.dart`, `shared/ui_kit.dart`), so every page, dashboards included, picks up Alchemy Lavender. Add one motion library (`lib/shared/motion.dart`) and rebuild only the pages that need new structure (Home, Programmes, course pages).

**Tech stack:** Flutter 3.47.1 web, Material 3, no new packages (fonts bundled as assets).

**Spec:** `DESIGN.md`

## Global constraints

- All 42 existing tests stay green. A test that asserts old copy may be updated only when the copy deliberately changes in Phase 9, and the test still checks the same behaviour.
- Every looping animation must stop when `Motion.enabled(context)` is false (reduced motion, and widget tests, so `pumpAndSettle` still settles).
- No raw hex in widgets you touch: `Tok.*`.

## File map

| File | Responsibility |
|---|---|
| `lib/theme.dart` | tokens (`Tok`), ThemeData, page transition (done in Phase 3) |
| `lib/shared/motion.dart` (new) | `Motion.enabled`, `Reveal`, `CountUp`, `TiltHover`, `Marquee`, `AmbientShapes`, `RotatingWords` |
| `lib/shared/programme_carousel.dart` (new) | 3D rotating programme card wheel with arrows, dots, pause on hover |
| `lib/widgets.dart` | header (fewer nav items), SectionTitle, Eyebrow, InfoCard, ResponsiveGrid, footer |
| `lib/shared/ui_kit.dart` | ImageBanner, PhotoFeatureCard, PathChoiceCard, StatTile restyle |
| `lib/pages.dart` | HomePage rebuilt; ProgrammesPage/ServicesPage use the carousel and reveals |
| `lib/widgets/lms/course_card.dart` | course card restyle with tilt |
| `lib/data/mock_data.dart` | verified video + article resources |
| `assets/fonts/*` | Lexend, Source Sans 3 (subset, OFL) |

## Tasks

### Task 1: Motion library
- [ ] Create `lib/shared/motion.dart` with the six widgets; each looping one checks `Motion.enabled`.
- [ ] `Motion.enabled` = not `MediaQuery.disableAnimations` and not running under `flutter test`.
- [ ] Check: `flutter analyze lib/shared/motion.dart`.

### Task 2: Shared components re-skin
- [ ] SectionTitle (eyebrow with gold bar, h1, 680px subtitle), Eyebrow, InfoCard (flat, 1px border), PhotoFeatureCard (tilt + lift, tag style icon), ImageBanner (royal blue scrim, Lexend title), PathChoiceCard, StatTile, footer (deep navy, 3 columns, links).
- [ ] Header: logo + About, Programmes (menu), Courses, Store, Contact; Insights/Impact/Sitemap move to the footer and drawer. Keep every route reachable.
- [ ] Check: `flutter test` (all 42).

### Task 3: Home page
- [ ] Hero: ambient drifting shapes, headline words rise in, rotating phrase, two path cards, photo with floating badges.
- [ ] Stats band with CountUp.
- [ ] Programme carousel (6 services) → `/services`.
- [ ] "Two ways to grow" (individuals vs organisations).
- [ ] Courses (3 cards, tilt), impact photo marquee, testimonials, final CTA.
- [ ] Remove the store and split-feature sections from Home (store stays in nav).
- [ ] Check: widget_test + chat_assistant_test; screenshot 1440 and 390.

### Task 4: Programmes, Services, course hub and detail
- [ ] Services and Programmes pages: Reveal on sections, carousel at the top of Services.
- [ ] Learning hub and course cards: tag, duration, level, tilt; course detail resources list shows type icon (video/article) and opens the link.
- [ ] Check: integration_regression_test, training_upgrade_test.

### Task 5: Real resources
- [ ] For each of the 8 courses, one primary YouTube video (embeddable, from a credible channel) and 2–3 articles from WHO, APA, HBR, Greater Good, NHS, Mind Tools or Google re:Work.
- [ ] Verify every link loads (browser on the user's device, since YouTube is blocked from the build workspace).
- [ ] Check: `flutter test`.

### Task 6: Motion review, audit, stress test, copy (Phases 6–9)
- [ ] review-animations pass; design-audit list; fix; break-ui worst-case data; avoid-ai-writing copy pass.
- [ ] Final: `flutter analyze`, `flutter test`, `flutter build web`, screenshots before → after.

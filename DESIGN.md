# MT Alchemy design system: Alchemy Lavender

One page of rules so every screen looks like it came from the same team.
Tokens live in `lib/theme.dart` (class `Tok`). Motion helpers live in
`lib/shared/motion.dart`. If a value is not in this file, don't invent one:
add it here first.

## 1. Intent

MT Alchemy sells calm, human growth: emotional intelligence, leadership and
well-being. The site should feel the same way. That means:

- **Clean style.** Generous white space on pale lavender, royal blue as the one brand colour, Alchemy gold as the one accent.
- **Simple to scan.** Every section has one job and one action.
- **Alive, not busy.** Motion explains (what's next, what's clickable, what
  changed). It never loops in the reader's face while they read.

Anti-goals: purple gradients, glassmorphism, Inter or Roboto everywhere,
shadows used as decoration, more than two accent colours on one screen.

## 2. Colour

Palette set by the course lecturer (royal blue, Alchemy gold, pure white,
pale lavender, soft lavender, caption purple). Three layers: primitive →
semantic → component. Code uses the semantic names in `Tok`.

| Primitive | Hex | Semantic role |
|---|---|---|
| royal blue | `#2412B8` | `brand`: main colour, buttons, links, headings, hero background |
| royal blue dark | `#1C0E94` | `brandHover`: pressed and hover state |
| deep navy | `#16105B` | `brandDeep`: footer, focus ring, darkest headings |
| soft lavender | `#E8DFFE` | `brandTint` and `border`: dividers, fine circles, selected rows |
| Alchemy gold | `#FCC931` | `accent`: accent strokes, ornaments, active nav dot, icon chips |
| gold tint | `#FFF4CC` | `accentTint`: category tags |
| gold text | `#6B4E00` | `onAccentTint`: text on gold tint (7.0:1) |
| lavender mid | `#7B6FD0` | `calm`: progress bars and graphics |
| caption purple | `#47416F` | `textMuted` / `calmText`: body copy and eyebrows (8.6:1 on pale lavender) |
| lavender tag | `#EFEAFE` | `calmTint`: secondary tags |
| pale lavender | `#F7F5FF` | `page` background |
| pure white | `#FFFFFF` | `surface`: cards, inputs; text on royal blue (11.3:1) |
| ink | `#1B1838` | `text`: long body text (15.8:1) |
| line strong | `#D3C8F5` | `borderStrong`: inputs, outlined controls |
| green-800 | `#2E7D32` | `success` |
| amber-700 | `#B7791F` | `warning` |
| red-700 | `#B3261E` | `danger` |

Checked contrast: royal blue on pale lavender 10.5:1, royal blue on gold
7.3:1, deep navy on gold 10.8:1, caption purple on soft lavender 7.3:1.

Rules:
- Gold is never text on white or lavender (fails contrast). Use it for
  fills, strokes, ornaments and icon chips, or as text on royal blue/navy.
- White text only on royal blue, deep navy, or photos with a 60%+ scrim.
- No gradients between blue and purple. One flat royal blue field per
  screen at most (the hero).
- Legacy names in code (`deepBlue`, `royalBlue`, `softYellow`, `purple`,
  `ink`, `canvas`) are aliases of these tokens and stay for compatibility.
  New code uses `Tok.*`.

## 3. Typography

Three families, bundled in `assets/fonts/` (no network needed):

- **Fraunces** (500, 600, italic): big headings only, 28px and up (hero,
  page banners, section titles). One or two words may be set in gold
  italic as an accent on royal blue. `Tok.heading()` picks it automatically.
- **Lexend** (500, 600, 700): card titles, numbers, buttons, nav. Open,
  friendly, designed for reading ease.
- **Source Sans 3** (400, 600, 700, italic 400): body text and UI labels.

Scale (ratio about 1.25, base 16):

| Token | Size / line height | Weight | Use |
|---|---|---|---|
| display | 56 / 1.05 (36 on phones) | Lexend 600 | hero headline only |
| h1 | 40 / 1.12 (30 on phones) | Lexend 600 | section titles |
| h2 | 30 / 1.2 | Lexend 600 | page sub-sections |
| h3 | 22 / 1.3 | Lexend 600 | card titles |
| title | 18 / 1.35 | Lexend 500 | list titles, nav |
| bodyL | 18 / 1.6 | Source Sans 400 | intros, subtitles |
| body | 16 / 1.55 | Source Sans 400 | default text |
| small | 14 / 1.45 | Source Sans 400 | meta, helper text |
| eyebrow | 13, +1.6 tracking, caps | Source Sans 700 | section labels |

Rules (ui-typography, practical-typography):
- Body lines 45 to 90 characters: text blocks max 680px wide.
- Headings: tracking −0.5 at 40px+, never all caps.
- Curly quotes and apostrophes (’ “ ”), en dash for ranges (9–5), em dash
  rarely. Numbers in stats use Lexend tabular figures.
- One display headline per page.

## 4. Spacing, radius, elevation

- Spacing scale (4-pt): 4, 8, 12, 16, 24, 32, 48, 64, 96.
  Section gap 96 desktop / 64 phone. Card padding 24. Grid gutter 24.
- Page width: max 1200, side padding 40 desktop / 20 phone.
- Radius: sm 8 (chips, inputs inner), md 12 (buttons, inputs), lg 20
  (cards, images), pill 999 (tags).
- Elevation: cards are flat with a 1px `border`. On hover they lift
  4px and get `shadowHover` (0 16 40, navy at 10%). No resting shadows.

## 5. Components

- **Button, primary:** royal blue fill, white Lexend 600 16, height 52, radius 12.
  Hover royal blue dark, press scale 0.97, focus ring 3px deep navy.
- **Button, secondary:** 1.5px royal blue outline, royal blue text, same size.
- **Card:** white, 1px border, radius 20, padding 24. Photo cards put a
  16:10 image on top, then tag, h3, one line of body, link with arrow.
- **Tag:** pill, 13px semibold, accentTint or calmTint fill.
- **Eyebrow:** caption purple, caps, 13px, caption purple, preceded by a 24×2 gold bar.
- **Section title:** eyebrow, h1, bodyL subtitle (max 680).
- **Page banner:** photo with royal blue scrim (left to right, 85% → 35%),
  eyebrow + h1 in white, radius 0, height 260 desktop / 200 phone.
- **Nav:** max 6 top-level items. Active item gets a gold dot under it.

- **Bento grid:** one large photo tile beside two stacked tiles, each with a
  frosted white caption panel (86% white, 14px blur). Stacks on phones.
- **Text size button:** header control that cycles text at 100%, 115%, 130%.
- **Glass bubble:** decorative glossy bubble with a gold rim reflection in
  the home hero.

## 6. Motion

Purposeful motion only. Every animation answers one of: *what's new*,
*what can I touch*, *what changed*.

| Token | Value | Use |
|---|---|---|
| fast | 150 ms | hover colour, press |
| base | 240 ms | card lift, tab change |
| slow | 420 ms | carousel slide |
| reveal | 520 ms | section fade-up on scroll (marketing pages only) |
| ambient | 18–24 s | hero background drift (very slow) |
| easeOut | `Curves.easeOutCubic` | anything entering |
| easeInOut | `Curves.easeInOutCubic` | anything moving across |

Signature moments:
1. **Hero:** slow drifting soft shapes behind the headline, words of the
   headline rise in one after another, rotating "for leaders / for teams /
   for you" phrase.
2. **Programme carousel:** six programme cards rotate on a 3D wheel every
   4.5 s; pauses on hover or focus; arrows and dots for control.
3. **Stats:** numbers count up once when scrolled into view.
4. **Cards:** tilt toward the cursor and lift on hover.
5. **Impact strip:** photos glide slowly sideways (marquee), pause on hover.
6. **Scroll reveal:** sections fade up 24px once.
7. **Cursor ring:** a gold ring trails the mouse and grows over anything
   clickable (mouse only, `CursorHalo`).
8. **Button pop:** main buttons lift and grow 4% on hover and squash to 96%
   on press (`Pop`); filled buttons get a soft royal blue shadow on hover.
9. **Card spotlight:** tilt cards get a soft gold light that follows the cursor.
10. **Flip cards:** programme formats turn over on hover, focus or tap (`FlipCard`).
11. **Pop-ups:** the Ask Alchemy button pulses gold and pops a one-time greeting.
12. **Scroll progress:** a 3px gold bar under the header fills as you scroll.
13. **Menu underline:** a gold line slides in under the hovered or current menu item.
14. **Brand ornament:** a slowly turning gold ring, lavender disc, dot grid and
    sparkles on page banners and dashboard headers (`BrandOrnament`).

Reduced motion: when the OS asks for less motion
(`MediaQuery.disableAnimations`), all loops stop, reveals keep a short
fade but no movement, the carousel stays flat and only moves when the user
presses an arrow, and cards don't tilt.

## 7. Accessibility gates

- Text contrast ≥ 4.5:1 (large text ≥ 3:1). Checked values are listed in §2.
- Touch targets ≥ 44×44.
- Visible focus on every interactive element (deep navy ring).
- Images have semantic labels; decorative shapes are excluded from
  semantics.
- Auto-moving content pauses on hover/focus and has manual controls.

## 8. QA checklist (code review)

- [ ] No raw hex in widgets: use `Tok.*`.
- [ ] No new font families beyond Fraunces, Lexend and Source Sans 3.
- [ ] Every looping animation checks `Motion.enabled(context)`.
- [ ] Long titles wrap without overflow at 360px wide.
- [ ] Empty lists show a friendly empty state.
- [ ] `flutter analyze` clean and `flutter test` green.

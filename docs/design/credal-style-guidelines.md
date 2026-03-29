Credal.ai — Comprehensive Design Style Guide

1. PLATFORM & FRAMEWORK
The site is built on Webflow (evidenced by w-button, w-inline-block, w-dropdown class patterns and hosted CSS on cdn.prod.website-files.com). The layout system relies heavily on Webflow's native flex utilities with custom class naming conventions like standard_verticalflex, standard_horizontalflex, and standard_outersection.

2. COLOR PALETTE
Primary Brand Colors
RoleValueRGBBlack (Primary Dark)#25262Brgb(37, 38, 43)Pure Black#000000rgb(0, 0, 0)White#FFFFFFrgb(255, 255, 255)Credal Purple (Primary CTA)#6D46DErgb(109, 70, 222)Credal Green (Accent)#00C14Ergb(0, 193, 78)
Secondary / Supporting Colors
RoleValueRGBDark Gray (Body Text)#333333rgb(51, 51, 51)Medium Gray (Nav Links)#555555rgb(85, 85, 85)Light Gray (Muted Text)#777777rgb(119, 119, 119)Warm Light Background#FAF5F3rgb(250, 245, 243)Red (Accent)#B3014Drgb(179, 1, 77)Orange (Code Syntax)#FE8500rgb(254, 133, 0)Blue (Code Syntax / Badge)#0074D2rgb(0, 116, 210)Deep Purple (Banner)#381C88rgb(56, 28, 136)
Functional / UI Colors
RoleValueSurface background#FFFFFF (white)Dark section background#25262B (charcoal-black)Code block background#000000 (pure black)Light section tintrgba(0, 0, 0, 0.03)Semi-transparent overlayrgba(255, 255, 255, 0.5)Warm tinted overlayrgba(244, 235, 232, 0.28)Border light1px solid #E0E0E0

3. TYPOGRAPHY
Primary Typeface: DM Sans (Google Font, sans-serif fallback)
This is the sole typeface used across the entire site — for headings, body text, navigation, and UI elements. It's a clean, geometric sans-serif that reinforces the modern, enterprise-tech aesthetic.
Heading Hierarchy
ElementSizeWeightLine HeightLetter SpacingColorH1 (Hero)55px400 (Regular)63.25px (1.15×)0.55px#000000H2 (Section Titles)24px500 (Medium)32px (1.33×)normal#333333 (light) / #FFFFFF (dark)H3 (Sub-features)24px500 (Medium)32pxnormal#333333H4 (Card Titles)20px500 (Medium)32pxnormal#1A1A1A
Body Text
VariantSizeWeightLine HeightColorBody (base)18px300 (Light)21.6px (1.2×)#333333Body (on dark bg)18px30021.6px#FFFFFFSmall / Labels16px30021.6px#555555Muted / Sub-text16px30021.6px#777777Badge text10px300—#FFFFFF
A notable design choice is the extensive use of font-weight 300 (Light) for body and UI text, giving the site a refined, airy feel. Headings use weight 400–500 for subtle emphasis without feeling heavy.

4. BUTTONS & CTAs
Primary CTA Button (Hero)
PropertyValueBackground#6D46DE (Credal Purple)Text Color#FFFFFFBorder Radius64px (full pill shape)Padding8px 12pxFont Size18pxFont Weight300Bordernone
Header / Nav Button
PropertyValueBackground#25262B (Dark Charcoal)Text Color#FFFFFFBorder Radius64px (pill)Padding8px 12pxFont Size16pxFont Weight300
Secondary CTA (Footer area)
Same purple pill style as primary CTA. The variant_large and variant_bleach class modifiers apply the purple background to standard buttons.
Key takeaway: All buttons use a pill/capsule shape (64px border-radius) and maintain the light font weight of 300, consistent with the overall design's elegant, lightweight tone.

5. LINKS & INTERACTIVE TEXT
ContextColorDecorationWeightNavigation dropdown links#555555none300In-page accent links (e.g., "documentation")#00C14E (green)none300Case study links ("Read the full case study →")#00C14E (green)none300Banner links#00C14E (green)none300Footer links#FFFFFFnone300
Green (#00C14E) is the universal accent link color used throughout the site for inline hyperlinks.

6. LAYOUT & SPACING SYSTEM
Container / Content Width: The site uses a max-width constraint with padding for centered content, operating within Webflow's responsive framework.
Spacing Scale (observed gap/padding values):

8px — tight (button padding, small gaps)
12px — compact (button horizontal padding)
16px — standard (vertical flex gaps, card gaps)
20px — medium
32px — large (footer column gaps, section margins)
48px — section spacing
64px — major section gaps (horizontal flex)

Flex Layout Patterns:

standard_verticalflex — column direction, 16px gap, flex-start alignment
standard_horizontalflex — row direction, 64px gap, center aligned, space-between
standard_verticalflex variant_gap64 — column direction, 48px gap
footer_rightcolumns — row, 32px gap, flex-end alignment


7. BORDER RADIUS SCALE
ValueUsage4pxDefault small rounding (inputs, minor elements)5pxButtons, subtle cards8pxMethod badges in code blocks16pxCard containers, code widget containers20pxFeature cards50pxPill badges, logos64pxButtons (full pill shape)125pxCase study pill badges50%Circular elements (avatars, icons)

8. SHADOWS & ELEVATION
The site uses a very minimal shadow approach, keeping the design flat and clean. The few shadows observed include:

Card/container: 0px 4px 14px rgba(0, 0, 0, 0.04) — extremely subtle
Tooltip/popover: 0 2px 10px rgb(0 0 0 / 20%) (CSS variable --rm-box-shadow)
Testimonial cards: light border-based definition (1px solid #E0E0E0) rather than shadow

This is consistent with a modern, enterprise-grade aesthetic that avoids decorative depth effects.

9. SECTION COLOR SCHEMES
The site alternates between three primary section themes:
Light Theme (default): White (#FFFFFF) background, dark text (#333333, #000000), green accent links.
Dark Theme (variant_dark): Charcoal (#25262B) background, white text (#FFFFFF), green accent checkmarks and links. Used for the security/compliance section.
Code/API Theme: Pure black (#000000) background for code blocks with syntax-highlighted text (orange for keywords, blue for URLs, green for strings).
Warm Tinted: A light warm background (#FAF5F3) is defined as --light but used sparingly.

10. ICONOGRAPHY & VISUAL SYSTEM
Icon Style: The site uses a distinctive line-art/dashed-border icon system with corner bracket motifs (resembling scan/focus frames). These icons use thin strokes and are rendered as images (not SVG icon fonts), featuring colorful accents (pink, purple, cyan, orange) against monochrome outlines.
Logo: The Credal logo is a circular radial pattern (resembling a starburst/mandala) paired with "CREDAL" in uppercase, medium-weight sans-serif tracking. The logo appears in black on light backgrounds and white on the dark footer.
Checkmarks: Used in feature lists, rendered as 17×17px images with a circular green/dark design.
Partner Logos: Displayed in grayscale monochrome with "Case Study" pill badges overlaid. The pill badges use blue (#0074D2) backgrounds with white text, fully rounded (125px radius).

11. CODE BLOCK / API TERMINAL STYLING
PropertyValueContainer background#FFFFFF (outer) with #000000 (code area)Container border radius16pxSidebar background#FFFFFFSidebar text (method names)Monospace-styled, #333333Code textLight weight on blackSyntax: commands (curl)#FE8500 (orange)Syntax: URLs/values#0074D2 (blue)Syntax: strings#00C14E (green)Method badge ("Post")Green text on #25262B bg, 8px radiusEndpoint URL barGreen (#00C14E) background strip

12. TESTIMONIAL / CASE STUDY CARDS
PropertyValueBackground#FFFFFFBorder1px solid #E0E0E0Border Radius16px (or soft rounding)Quote text24px, weight 400, #333333Attribution nameBold, darkerAttribution titleRegular weight, grayCTA link#00C14E (green), no underline, with → arrow

13. NAVIGATION (HEADER)
The header is a sticky white bar with the Credal logo on the left, a hamburger menu icon (circle-outlined), and a dark pill-shaped "Get a demo" button on the right. Navigation links are hidden behind the hamburger menu on this viewport, but dropdown items use #555555 text at 16px/300 weight. The header uses a clean white background with no visible border-bottom or shadow, giving it a seamless, floating appearance.

14. FOOTER
PropertyValueBackground#25262B (dark charcoal)Text color#FFFFFFFont size14–16pxFont weight300LayoutLogo top-left, 3-column link grid (Use Cases, Company, Resources) + LinkedIn iconLink styleWhite, no underlineSection headingsWhite, slightly bolderFooter links (legal)Centered, standard weight

15. ANIMATIONS & TRANSITIONS
The site uses subtle, performance-friendly transitions. Many interactive elements (links, buttons, cards) have CSS transitions defined, though the overall design ethos is restrained motion — the focus is on content clarity rather than animation flourish. The icon ring on the hero (app integration icons in a circular pattern) has a gentle rotational or floating animation.

16. DESIGN PHILOSOPHY SUMMARY
Credal's visual identity communicates enterprise trust, technical sophistication, and simplicity. The key principles are:
Minimalism with warmth — A near-monochrome palette (black/white/gray) is softened by a single vibrant purple for CTAs and green for accent interactions, avoiding the cold sterility of pure grayscale enterprise design.
Lightweight typography — The consistent use of DM Sans at weight 300 throughout gives the entire site an elegant, spacious, breathable quality that signals refinement without sacrificing readability.
Flat, borderless design — Minimal shadows, thin borders, and generous whitespace create a clean, confident visual hierarchy. Depth is communicated through color contrast (light vs. dark sections) rather than elevation.
Pill-shaped interactive elements — Buttons and badges all use high border-radius values, creating a friendly, approachable feel that contrasts with the serious enterprise messaging.
Duality of light and dark — The strategic alternation between white and charcoal-black sections creates visual rhythm, with the dark sections reserved for security/compliance messaging to reinforce trust and authority.
# Design System Specification: Clinical Precision & Digital Trust

## 1. Overview & Creative North Star: "The Clinical Sanctuary"
This design system moves beyond the generic "medical app" aesthetic to establish a **Clinical Sanctuary**. The objective is to balance the rigorous, high-security requirements of a digital health platform with a user experience that feels breathable, empathetic, and sophisticated. 

The "North Star" is **Architectural Clarity**. We reject the "flat" web look in favor of an editorial layout that uses intentional asymmetry and tonal layering. By treating the UI as a series of stacked, high-precision surfaces rather than a grid of boxes, we communicate "High Security" through structural integrity and "Trust" through visual calm.

---

## 2. Color Theory & Tonal Depth
We utilize a sophisticated Material 3 palette where color is used for state and hierarchy, never for decoration.

### The "No-Line" Rule
**Strict Mandate:** Designers are prohibited from using 1px solid borders to section content. Boundaries must be defined solely through background color shifts. 
*   *Implementation:* Place a `surface-container-low` card on a `surface` background. The difference in luminance is the divider.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—like stacked sheets of frosted glass.
*   **Level 0 (Base):** `surface` (#f7f9fe) - The canvas.
*   **Level 1 (Sectioning):** `surface-container-low` (#f1f4f9) - Defines broad content areas.
*   **Level 2 (Interaction):** `surface-container-lowest` (#ffffff) - Reserved for high-priority interactive cards or data entry fields to make them "pop" against the lower levels.

### The "Glass & Signature" Rule
To evoke a modern, premium feel, use **Glassmorphism** for floating elements (like the Bottom Navigation or Modal overlays).
*   **Floating Elements:** Use `primary-container` at 80% opacity with a `20px` backdrop-blur. 
*   **Signature Textures:** For Hero sections or high-level E2E Security status, use a subtle linear gradient: `primary` (#004e99) to `primary-container` (#0a66c2) at a 135° angle.

---

## 3. Typography: The Editorial Scale
We pair **Inter** (Headings) for its technical, Swiss-style precision with **Roboto** (Body) for its high legibility in dense medical data.

*   **Display (Inter):** Use `display-lg` (3.5rem) with tight letter-spacing (-0.02em) for dashboard welcomes. This creates an authoritative, editorial impact.
*   **Headlines (Inter):** `headline-sm` (1.5rem) should be used for section titles to maintain a "Journal of Medicine" hierarchy.
*   **Body (Roboto):** All clinical data, patient notes, and logs must use `body-md` (0.875rem). The slightly smaller scale conveys a professional, data-rich environment.
*   **Labels (Inter):** Use `label-md` (0.75rem) in All-Caps with +0.05em tracking for secondary metadata or "E2E Encrypted" status tags.

---

## 4. Elevation & Depth: Tonal Layering
Traditional shadows are often "muddy." This system uses **Ambient Light** principles.

*   **The Layering Principle:** Depth is achieved by "stacking" surface tokens. An "Elevated Card" is not a shadow; it is a `surface-container-lowest` block on a `surface-container-high` background.
*   **Ambient Shadows:** For floating action buttons or critical alerts, use a "Tinted Glow." 
    *   *Shadow:* `0px 12px 24px -4px`, Color: `on-surface` at 6% opacity.
*   **The "Ghost Border" Fallback:** If a container sits on an identical color (e.g., in Dark Mode), use a **Ghost Border**: `outline-variant` at 15% opacity. Never use a 100% opaque border.

---

## 5. Components & Signature Patterns

### Buttons (Elevated & Refined)
*   **Primary:** `primary` (#004e99) background with `on-primary` (#ffffff) text. Use `xl` (1.5rem) rounding for a "pill" shape that feels approachable.
*   **Secondary:** `secondary-container` (#bfd5ff) background. No border.

### The "Medical Card"
*   **Radius:** Always use `lg` (1rem/16dp).
*   **Styling:** Forbid dividers. Use **Spacing 6 (1.5rem)** to separate patient name from vitals.
*   **E2E Status:** The green padlock icon must be paired with a `tertiary-container` (#00772e) "Glass" badge to denote security without visually overwhelming the medical data.

### Navigation & Filters
*   **Bottom Navigation:** 5-icon layout. The active state should use a `primary-fixed` pill behind the icon, rather than just a color change.
*   **Filter Chips:** Use `surface-container-high` for unselected chips. When selected, transition to `primary` with a subtle white glow.

### Input Fields
*   **State:** Use `surface-container-low` as the field background. 
*   **Validation:** Success states must use `tertiary` (#005c22) for the label and a `tertiary-fixed` glow on the field itself.

---

## 6. Do’s and Don’ts

### Do
*   **Do** use white space as a structural element. If a layout feels cramped, increase spacing to `10` (2.5rem).
*   **Do** use "Surface Dim" for Dark Mode backgrounds to reduce eye strain for clinicians working night shifts.
*   **Do** align all icons to a 24px bounding box to maintain clinical rigor.

### Don’t
*   **Don’t** use pure black (#000000) in Dark Mode. Use the `inverse-surface` (#2d3135) or deep navy tones defined in the palette.
*   **Don’t** use 1px dividers between list items. Use a `surface-variant` background shift or a `1.5` (0.375rem) vertical gap.
*   **Don’t** use high-saturation reds for errors. Use the specified `error` (#ba1a1a) token, which is calibrated for professional environments.

---

## 7. The Dark Mode Transition
Dark mode is not a color inversion; it is a shift in **Luminance Density**.
*   **Background:** Use `on-primary-fixed` (#001b3d) for the base.
*   **Accent:** Use `primary-fixed-dim` (#a8c8ff) for text on dark backgrounds to ensure WCAG AAA compliance.
*   **Depth:** In dark mode, higher-elevation items must be *lighter* (more towards `surface-variant`), mimicking how light hits objects in a dark room.
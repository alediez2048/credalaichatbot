# P0-005 — Frontend toolchain: esbuild + Tailwind CSS + React

**Priority:** P0
**Estimate:** 1.5 hours
**Phase:** 0 — Foundation & Setup
**PRD reference:** `PRD - AI-Powered Onboarding Assistant.md` §5.1 (System Architecture), §6 (Form Factor)

---

## Goal

Replace the current Importmap + vanilla CSS setup with **esbuild** (for JSX/TSX support), **Tailwind CSS** (for utility-first styling), and **React** (for the chat component). After this ticket, every subsequent view can use Tailwind classes, and the chat component has a React mount point ready for P1-001.

---

## Why this is needed

The current setup uses Importmap (no JSX support) and hand-written CSS. This blocks:
- **P1-001** — React chat component with streaming, typing indicators, dynamic messages
- **P1-000** — Landing page needs polished styling (Tailwind)
- **All future UI work** — Devise forms, admin dashboard, OCR preview cards

Importmap cannot compile JSX. Switching to esbuild is a prerequisite for React.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P0-005 |
|--------|----------------------|
| **P0-001** | Rails app must exist with working Gemfile, asset pipeline, and views |

This ticket is **independent** of P0-002/P0-003/P0-004 (AI service layer). It can run in parallel.

---

## Deliverables Checklist

- [ ] Replace `importmap-rails` with `jsbundling-rails` (esbuild)
- [ ] Install and configure Tailwind CSS
- [ ] Install React and ReactDOM via npm/yarn
- [ ] Update `Procfile.dev` to run esbuild + Tailwind watchers
- [ ] Update `application.html.erb` layout to load built JS and CSS
- [ ] Restyle landing page (`home/index.html.erb`) with Tailwind
- [ ] Restyle app layout/nav with Tailwind
- [ ] Style Devise views (sign in, sign up) with Tailwind
- [ ] Create a test React component that renders in `/onboarding`
- [ ] Verify mobile-responsive at 375px

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | esbuild compiles JS/JSX | `bin/dev` → no build errors, JS loads in browser |
| 2 | Tailwind processes utility classes | Add `class="text-blue-500"` to a view → text is blue |
| 3 | React component renders | Visit `/onboarding` → see React-rendered placeholder text |
| 4 | Landing page uses Tailwind | Visit `/` → clean, styled hero with Tailwind classes |
| 5 | Devise forms styled | Visit `/users/sign_in` → form has Tailwind styling |
| 6 | Mobile-responsive | DevTools 375px → layout doesn't break |
| 7 | `bin/dev` starts all processes | Web, esbuild, Tailwind, Redis, Sidekiq all start |

---

## Step-by-Step Implementation

### Step 1 — Switch from Importmap to esbuild

```bash
cd backend

# Remove importmap
bundle remove importmap-rails
rm config/importmap.rb
rm bin/importmap

# Add jsbundling-rails
bundle add jsbundling-rails
bin/rails javascript:install:esbuild
```

This creates:
- `package.json` with esbuild
- `app/javascript/application.js` entry point
- `app/assets/builds/` output directory
- Build script in `package.json`

### Step 2 — Install Tailwind CSS

```bash
# Option A: via npm (recommended with esbuild)
npm install -D tailwindcss @tailwindcss/forms
npx tailwindcss init

# Option B: via gem
bundle add tailwindcss-rails
bin/rails tailwindcss:install
```

Configure `tailwind.config.js`:
```js
module.exports = {
  content: [
    './app/views/**/*.{html,erb}',
    './app/javascript/**/*.{js,jsx,tsx}',
    './app/helpers/**/*.rb',
  ],
  plugins: [require('@tailwindcss/forms')],
}
```

Create `app/assets/stylesheets/application.tailwind.css`:
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

### Step 3 — Install React

```bash
npm install react react-dom
npm install -D @types/react @types/react-dom  # if using TypeScript
```

### Step 4 — Update Procfile.dev

```
web: bin/rails server -p 3000
js: npm run build -- --watch
css: npx tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./app/assets/builds/application.css --watch
redis: redis-server --port 6379
worker: bundle exec sidekiq
```

### Step 5 — Update layout

Update `application.html.erb` to reference the built assets:
```erb
<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
<%= javascript_include_tag "application", "data-turbo-track": "reload", defer: true %>
```

### Step 6 — Restyle with Tailwind

Replace all vanilla CSS classes in:
- `app/views/layouts/application.html.erb` (nav, flash messages)
- `app/views/home/index.html.erb` (landing page hero, CTA, features)
- Devise views (generate with `rails generate devise:views`, then style)

### Step 7 — Create React mount point

Create `app/javascript/components/ChatApp.jsx`:
```jsx
import React from 'react'
import { createRoot } from 'react-dom/client'

function ChatApp() {
  return (
    <div className="flex items-center justify-center h-full text-gray-500">
      Chat loading...
    </div>
  )
}

const container = document.getElementById('chat-root')
if (container) {
  createRoot(container).render(<ChatApp />)
}
```

Import in `app/javascript/application.js`:
```js
import './components/ChatApp'
```

In the `/onboarding` view:
```erb
<div id="chat-root" class="h-screen"></div>
```

---

## Files You Will Modify / Create

| Area | Path | Action |
|------|------|--------|
| Gemfile | `Gemfile` | Remove importmap-rails, add jsbundling-rails (+ optionally tailwindcss-rails) |
| Package | `package.json` | New — esbuild, React, Tailwind, @tailwindcss/forms |
| Tailwind config | `tailwind.config.js` | New — content paths, plugins |
| Tailwind entry | `app/assets/stylesheets/application.tailwind.css` | New — @tailwind directives |
| Old CSS | `app/assets/stylesheets/application.css` | Remove or gut (replaced by Tailwind) |
| Layout | `app/views/layouts/application.html.erb` | Restyle with Tailwind, update asset tags |
| Landing | `app/views/home/index.html.erb` | Restyle with Tailwind |
| React entry | `app/javascript/components/ChatApp.jsx` | New — React mount point |
| JS entry | `app/javascript/application.js` | Import React component |
| Procfile | `Procfile.dev` | Add esbuild + Tailwind watch processes |
| Devise views | `app/views/devise/` | Generate and style with Tailwind |
| Routes | `config/routes.rb` | Add `/onboarding` route (if not done by P1-000 yet) |

---

## Design Direction

Keep it clean and modern. Not flashy — professional.

- **Color palette:** Neutral grays + one accent color (blue-600 or indigo-600)
- **Typography:** System font stack (already set), generous spacing
- **Landing page:** Centered hero, large heading, clear CTA button, feature bullets
- **Chat interface:** Full-height, light background, rounded message bubbles, bottom-anchored input
- **Devise forms:** Centered card layout, clean inputs with labels, consistent button styling
- **Dark mode:** Not for MVP. Tailwind makes it easy to add later.

---

## Files You Should NOT Modify

- Models, migrations, or database config (P0-001 scope)
- AI service layer (P0-002 scope)
- Prompt configs (P0-003 scope)
- Chat functionality or Action Cable channels (P1-001 scope)

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified manually
- [ ] `bin/dev` starts cleanly with all 5 processes
- [ ] No vanilla CSS remains in `application.css` (fully replaced by Tailwind)
- [ ] `DEVLOG.md` updated with P0-005 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P0-005-frontend-toolchain
```

---

## Out of Scope for P0-005

- Chat functionality (P1-001)
- Action Cable streaming (P1-001)
- Onboarding flow logic (P1-002)
- LLM integration (P0-002)
- Complex animations or transitions

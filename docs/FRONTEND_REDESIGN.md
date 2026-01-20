# Refonte Front — Loc Vallis (Rails ERB + Bootstrap 5 + SCSS + Stimulus)

Objectif : moderniser l’UI (mobile-first), rendre l’expérience chaleureuse (gîtes / chambres d’hôtes), et augmenter la conversion (réservation / paiement) **sans toucher au backend** (routes/contrôleurs/modèles/champs inchangés).

## 1) Direction artistique

### Mood
- Maison de campagne contemporaine : bois clair, lin, pierre, verdure.
- Sensations : confiance, calme, simplicité premium, proximité humaine.
- Signature visuelle : grandes photos, beaucoup d’air, accents “terre cuite”, détails “artisanaux” (bordures douces, ombres discrètes, icônes fines).

### Principes UI/UX
- **Mobile-first** : CTA visibles, formulaires en 1 colonne, offcanvas pour filtres.
- **Clarté tarifaire** : prix/nuit + total + conditions visibles, avant le paiement.
- **Réassurance** : avis, “Paiement sécurisé”, politique d’annulation, hôte vérifié.
- **Hiérarchie** : un seul CTA primaire par écran, le reste en secondaire.
- **Lisibilité** : contrastes AA, tailles de typo généreuses, focus states visibles.

### Ton rédactionnel (micro-copy)
- Chaleureux et direct : “Réserver”, “Vérifier la disponibilité”, “Contacter l’hôte”.
- Éviter le jargon : “Arrivée / Départ”, “Nuits”, “Services optionnels”.

## 2) Design system (Bootstrap-friendly)

### Tokens (SCSS)
À placer dans les fichiers SCSS existants (variables Bootstrap + design tokens).

**Palette proposée**
- `lv-cream` (fond) : #FBF7F0
- `lv-sand` (surface) : #F3ECE1
- `lv-ink` (texte) : #1F2937
- `lv-sage` (primary) : #2F6B55
- `lv-terracotta` (accent) : #C86B4A
- `lv-sky` (info) : #3B82F6
- `lv-amber` (warning) : #F59E0B
- `lv-rose` (danger) : #E11D48
- Neutres : gris doux pour bordures (#E5E7EB) et diviseurs (#F3F4F6)

**Typographies**
- Titres : `Fraunces` (serif chaleureuse) ou `Playfair Display`.
- Texte : `Inter` ou `Source Sans 3`.
- Tailles : base 16px, titres plus “calmes” (moins d’ultra-bold).

**Rythme / spacing**
- Unité : 8px (Bootstrap). Sections : `py-5` par défaut.
- Cartes : padding 20–24px; rayons 16px; ombre subtile.

### Composants Bootstrap à themifier

**Boutons**
- Primary (`btn-primary`) = Sage (action principale : réserver/payer).
- Accent (`btn-accent` custom) = Terracotta (action “conversion” sur pages de listing/room show).
- Secondary = `btn-outline-primary`.
- États : hover doux + focus ring visible (couleur sage).

**Cards**
- `card` = border légère + rayon + ombre faible.
- Variantes : `lv-card--soft` (fond sand), `lv-card--ghost` (sans bord).

**Forms**
- Inputs : hauteur confortable (44–48px), bordures douces.
- `form-text` pour aide; `invalid-feedback` clair.
- Labels : plus petits mais plus contrastés.

**Badges**
- Statuts de réservation : pastilles `rounded-pill`, fond doux + texte contrasté.

**Alerts / Toasts**
- Alertes moins “flashy” : fond pâle, icône, bordure gauche.

**Navbar**
- Sticky, translucide légère (blur), CTA “Réserver” visible (selon contexte).
- Mobile : offcanvas menu.

**Footer**
- 3 colonnes : contact, infos, réseaux; micro-réassurance.

**Modals**
- Modals confortables, headers minimalistes, CTA alignés.

## 3) Bibliothèque de partials réutilisables (API)

> Convention : partials dans `app/views/shared/ui/` ; classes CSS prefixées `lv-`.

### Layout
- `shared/ui/_page_header.html.erb`
  - locals: `title:`, `subtitle: nil`, `actions: nil` (bloc), `breadcrumbs: nil`
- `shared/ui/_section.html.erb`
  - locals: `title: nil`, `subtitle: nil`, `body_class: nil` (wrap section), bloc contenu

### CTA & boutons
- `shared/ui/_button.html.erb`
  - locals: `label:`, `href: nil`, `method: nil`, `variant: :primary`, `size: :md`, `icon: nil`, `data: {}`
  - support `button_to` vs `link_to` selon présence de `href`

### Cards métier
- `shared/ui/_room_card.html.erb`
  - locals: `room:`, `href:`, `variant: :default`, `show_price: true`, `show_rating: true`
- `shared/ui/_booking_summary_card.html.erb`
  - locals: `booking:`, `show_actions: false`, `actions: nil`
- `shared/ui/_message_thread.html.erb`
  - locals: `booking:`, `messages:`, `current_actor:`, `composer: true`

### Statuts & prix
- `shared/ui/_status_badge.html.erb`
  - locals: `status:`, `label: nil`, `size: :md`
- `shared/ui/_price.html.erb`
  - locals: `amount_cents:`, `currency: "EUR"`, `style: :inline` (inline / pill)

### States
- `shared/ui/_empty_state.html.erb`
  - locals: `title:`, `body: nil`, `icon: nil`, `cta: nil`

## 4) Stimulus (progressive enhancement)

Contrôleurs proposés (optionnels, sans dépendre du backend)
- `sticky_header_controller` : shadow à scroll, comportement mobile.
- `form_submit_controller` : désactiver bouton + spinner lors submit.
- `auto_dismiss_controller` : fermer alerts après X secondes.
- `clipboard_controller` : copier adresse/infos.

## 5) Checklist d’implémentation (ordre recommandé)

1. **Tokens + variables Bootstrap** : palette, typographies, rayons, ombres.
2. Navbar + footer : structure responsive + cohérence globale.
3. Composants UI : boutons, cards, badges, forms.
4. Pages clés conversion : listing rooms, room show, booking flow (checkout), inbox.
5. Admin : vues booking/admin plus lisibles (cards + actions alignées).
6. Responsive QA : iPhone SE → desktop, focus states, contrastes.

## 6) Arborescence proposée

### Views
- `app/views/shared/ui/`
  - `_page_header.html.erb`
  - `_section.html.erb`
  - `_button.html.erb`
  - `_status_badge.html.erb`
  - `_price.html.erb`
  - `_empty_state.html.erb`
  - `_room_card.html.erb`
  - `_booking_summary_card.html.erb`
  - `_message_thread.html.erb`

### SCSS
- `app/assets/stylesheets/config/`
  - `_colors.scss` (tokens + maps)
  - `_fonts.scss` (imports + stacks)
  - `_bootstrap_variables.scss` (override Bootstrap)
- `app/assets/stylesheets/components/`
  - `_buttons.scss`
  - `_cards.scss`
  - `_forms.scss`
  - `_badges.scss`
  - `_navbar.scss` (refonte)
  - `_footer.scss`
  - `_alerts.scss`

### Stimulus
- `app/javascript/controllers/`
  - `auto_dismiss_controller.js`
  - `form_submit_controller.js`
  - `sticky_header_controller.js`

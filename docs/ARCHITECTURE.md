# Architecture — Loc Vallis

## Vue d’ensemble
Loc Vallis est une application Rails (7.1) avec deux types d’acteurs :

- **User** : navigue les rooms, demande une réservation, paie, échange des messages.
- **Owner** : gère ses rooms (admin), approuve/refuse des demandes, peut annuler/refunder.

L’app s’appuie sur :

- **Devise** pour l’authentification (Users & Owners)
- **Pundit** pour l’autorisation
- **Stripe** pour le paiement et les remboursements
- **Active Storage + Cloudinary** pour les photos des rooms
- **Solid Queue** + jobs ActiveJob pour les tâches récurrentes (expiration)

## Domain model (métier)

### Room
- Héberge les informations d’un logement et ses photos.
- A des **OpeningPeriods** (périodes d’ouverture tarifées) et des **Bookings**.

### OpeningPeriod
- Définit un intervalle [start_date, end_date] et un prix **nightly_price_cents** + **currency**.
- Contrainte importante : les périodes ne doivent pas se chevaucher pour une même room.

### Booking
- Représente une demande de séjour d’un User sur une Room.
- Le prix est **calculé** via `BookingQuote` lors de la création puis **persisté** dans `total_price_cents` + `currency`.
- Les statuts encodent la machine d’état (voir ci-dessous).

### Message
- Message rattaché à une Booking.
- `sender` est polymorphique (User ou Owner).

## Machine d’état des bookings
Les statuts actuels sont stockés en string et validés par inclusion.

Flux principal :
- `requested` → `approved_pending_payment` → `confirmed_paid`

Autres sorties :
- `requested` → `declined`
- Annulation : `requested|approved_pending_payment|confirmed_paid` → `canceled`
- Expiration : `approved_pending_payment` → `expired` (si la fenêtre de paiement est dépassée)
- Remboursement : `confirmed_paid` → `refunded`

## Paiement Stripe

### Création checkout
- Le owner approuve une booking : l’app ouvre une fenêtre de paiement (48h).
- Le user déclenche `/bookings/:id/checkout`.
- `StripeCheckoutSessionCreator` crée une Checkout Session et persist :
  - `stripe_checkout_session_id`
  - `stripe_payment_intent_id`

### Webhooks
- `StripeWebhooksController` vérifie la signature via `STRIPE_WEBHOOK_SECRET`.
- `checkout.session.completed` : confirme la booking en `confirmed_paid` (idempotent).
- `refund.updated` : maintient l’état `refunded` (idempotent).

### Expiration
- L’expiration des bookings “en attente de paiement” est gérée par :
  - un garde-fou `Booking.expire_overdue!` appelé dans certains controllers
  - `ExpireOverdueBookingsJob` (exécutable via scheduler/recurring)

## Autorisation (Pundit)
- `BookingPolicy` sert de point central :
  - un Owner ne voit/agit que sur les bookings de ses rooms
  - un User ne voit/agit que sur ses propres bookings

## Où regarder pour modifier un flux
- Cycle de vie booking : modèle `Booking`, policy `BookingPolicy`, controllers `BookingsController` et `Admin::BookingsController`
- Disponibilités et calcul de prix : service `BookingQuote`, modèle `OpeningPeriod`
- Paiement/Stripe : services `StripeCheckoutSessionCreator`, `StripeRefundCreator`, controller `StripeWebhooksController`

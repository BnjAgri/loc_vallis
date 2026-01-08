# Maintenance

## Démarrer en local
- Installer les dépendances : `bundle install`
- Préparer la DB : `bin/rails db:setup` (ou `db:create db:migrate db:seed`)
- Lancer : `bin/rails s`

## Variables d’environnement
### Stripe
- `STRIPE_SECRET_KEY` (si utilisé dans l’app)
- `STRIPE_WEBHOOK_SECRET` (obligatoire pour valider les webhooks)
- `APP_BASE_URL` (utilisé pour construire les URLs de retour Checkout)

### Cloudinary (Active Storage)
- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`

## Dépannage rapide
- Paiements “confirmés” qui ne passent pas : vérifier que le webhook Stripe arrive bien et que `STRIPE_WEBHOOK_SECRET` correspond.
- Bookings qui “expirent” trop tôt/tard : vérifier la timezone, et le déclenchement de `Booking.expire_overdue!`/job.
- Conflits de dates : regarder `BookingQuote` (règles de recouvrement + opening period).

## Ajouter / modifier un statut de Booking
1. Mettre à jour `Booking::STATUSES` et les garde-fous métier (méthodes `approve!`, `cancel!`, etc.).
2. Mettre à jour `BookingPolicy` (qui a le droit de quoi).
3. Mettre à jour les controllers et les vues associées.
4. Mettre à jour les mails si nécessaire.

## Ajouter un événement Stripe
1. Ajouter un `when` dans `StripeWebhooksController#handle_event`.
2. Garder le handler **idempotent** (Stripe peut renvoyer le même event).
3. En cas de changement d’état, vérifier les transitions autorisées côté `Booking`.

## Endroits “source de vérité”
- Prix total : `Booking#total_price_cents` (persisté) ; calcul initial via `BookingQuote`.
- Disponibilité : `BookingQuote` (chevauchement + périodes).
- Confirmation paiement : webhook `checkout.session.completed`.

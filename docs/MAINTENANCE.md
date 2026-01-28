# Maintenance

## Démarrer en local
- Installer les dépendances : `bundle install`
- Préparer la DB : `bin/rails db:setup` (ou `db:create db:migrate db:seed`)
- Lancer : `bin/rails s`

## Variables d’environnement
### Rails (sessions)
- `SECRET_KEY_BASE` : obligatoire en production pour signer/chiffrer les cookies de session.
  Sur Heroku, s'il manque, tu peux observer des déconnexions “aléatoires” et des éléments UI (owner-only) qui disparaissent.

### Accès restreint (optionnel)
- `BASIC_AUTH_USER` + `BASIC_AUTH_PASSWORD` : active un HTTP Basic Auth sur toute l’app.
	Exceptions : `/stripe/webhook` (Stripe) et `/up` (health check) restent accessibles.

### Stripe
- `STRIPE_SECRET_KEY` (**obligatoire** pour le flow “Payer maintenant” et pour les remboursements)
- `STRIPE_WEBHOOK_SECRET` (obligatoire pour valider les webhooks)
- `APP_BASE_URL` (utilisé pour construire les URLs de retour Checkout)

En local, `dotenv-rails` charge automatiquement `.env` : tu peux donc ajouter par ex.
- `STRIPE_SECRET_KEY=sk_test_...`
- `STRIPE_WEBHOOK_SECRET=whsec_...`

Rappel (préfixes Stripe) :
- `pk_...` = **publishable key** (côté navigateur / Stripe.js)
- `sk_...` = **secret key** (côté serveur, utilisée par `Stripe.api_key`)
- `whsec_...` = **webhook signing secret** (pour `Stripe::Webhook.construct_event`)

Pour obtenir un `whsec_...` en local :
- Installer Stripe CLI (voir la doc Stripe “Stripe CLI install”), puis :
	- `bin/stripe login`
	- `bin/stripe listen --forward-to localhost:3000/stripe/webhook`
	- la commande affiche “Your webhook signing secret is whsec_...” (à copier dans `.env`).

### Heroku / URLs
- `APP_HOST` : ex. `loc-vallis-demo.herokuapp.com` (pour ActionMailer)
- `APP_PROTOCOL` : `https` (par défaut)

### Seeds (Heroku / démo)
- Par défaut, `db:seed` n'insère rien en production.
- Pour charger des données de démo sur Heroku : exécuter `db:seed` avec `SEED_DEMO=1`.
- Identifiants (optionnels) : `SEED_OWNER_EMAIL`, `SEED_OWNER_PASSWORD`, `SEED_USER_EMAIL`, `SEED_USER_PASSWORD`.

Notes :
- Devise impose une longueur minimale de mot de passe (souvent 6). Si tu passes un mot de passe trop court (ex. `toto`), le seed échoue.
- Exemple :
	- `heroku run env SEED_DEMO=1 SEED_OWNER_EMAIL=owner@locvallis.demo SEED_OWNER_PASSWORD=toto123 SEED_USER_EMAIL=user@locvallis.demo SEED_USER_PASSWORD=toto123 rails db:seed -a loc-vallis-demo`

### Cloudinary (Active Storage)
- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`

### TODO (à faire demain) — Mailer Gmail (tests)
- Objectif : configurer l’envoi de mails réels via une adresse Gmail perso (dev + Heroku).
- Pré-requis Gmail : activer la validation en 2 étapes + générer un **mot de passe d’application**.
- Dev (local) : définir `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_STARTTLS`, `MAIL_FROM`.
	- Le mode SMTP en dev est activé dès que `SMTP_ADDRESS` est présent ; sinon, on reste en `delivery_method = :test`.
- Prod (Heroku) : ajouter les mêmes variables en config vars, et vérifier la config ActionMailer production.
- Script de test : `bin/rails runner script/send_user_mail_flow.rb <email>` (déclenche welcome + booking mails + message + demande d’avis).
- Option : activer le welcome automatique à la création avec `SEND_WELCOME_EMAILS=true` (et lancer `bin/jobs start` si besoin).

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

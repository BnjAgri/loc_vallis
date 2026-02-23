# Provisioning — Nouveau client (domaine + Stripe + email)

Objectif : déployer la même codebase Loc Vallis pour un nouveau client, avec :
- son domaine
- son compte Stripe (clés + webhook)
- ses paramètres d’email (MAIL_FROM + SMTP)
- son stockage médias (Cloudinary / Active Storage)
- ses secrets Rails (sessions)

Ce document ne couvre volontairement pas le branding UI/PWA.

## Pré-requis

- Accès DNS au domaine du client.
- Heroku CLI (`heroku`) connecté au bon compte/équipe.
- Accès au Dashboard Stripe du client pour créer le webhook.

## Données à collecter auprès du client

- Domaine: `booking.client.com`
- Email:
  - `MAIL_FROM` (ex: `no-reply@client.com`)
  - Identifiants SMTP: `SMTP_ADDRESS`, `SMTP_USERNAME`, `SMTP_PASSWORD` (+ port si besoin)
- Stripe:
  - `STRIPE_SECRET_KEY` (ex: `sk_live_...`)
  - La capacité à créer un webhook endpoint sur ce compte
- Accès Owner (admin):
  - `PRIMARY_OWNER_EMAIL` (email autorisé pour se connecter en tant qu’Owner)
- Contenu (optionnel):
  - `HOST_DEFAULT_IMAGE_URL` (image par défaut de la page `/host`)
- Cloudinary (Active Storage):
  - `CLOUDINARY_CLOUD_NAME`
  - `CLOUDINARY_API_KEY`
  - `CLOUDINARY_API_SECRET`

## Secret Rails (sessions)

En production, Rails a besoin de `SECRET_KEY_BASE` pour signer/chiffrer les cookies.

- Si tu ne le définis pas sur Heroku, tu peux observer des comportements bizarres (déconnexions, UI qui “perd” l’état de session).


## Route webhook Stripe

L’app attend les webhooks sur :
- `POST /stripe/webhook`

En production, l’URL complète est :
- `https://<domaine>/stripe/webhook`

Événements utilisés aujourd’hui :
- `checkout.session.completed`
- `checkout.session.async_payment_failed`
- `checkout.session.expired`
- `refund.updated`

## Provision via script

Le script: [script/provision_client.sh](../script/provision_client.sh)

### (Optionnel) UI interne “Provisioning (dev)”

Pour éviter de composer la commande à la main, une page admin cachée peut générer:
- la commande `./script/provision_client.sh ...`
- l’URL du webhook Stripe + les événements

Activation (local/staging uniquement): définir `PROVISIONING_UI_ENABLED=true`.

Accès:
- `/admin/provisioning` (ou `/<locale>/admin/provisioning`)

Notes:
- La page ne lance aucun provisioning automatiquement: elle génère uniquement du texte à copier-coller.
- Aucun secret n’est persisté en base.

### Notes pratiques (Heroku app name / DNS)

- **Nom d’app Heroku** : le “Heroku app name” ne peut pas contenir d’espaces ni d’accents.
  Exemple OK : `lv-gite-angles`.

- **Domaine racine vs `www`** : sur beaucoup de providers DNS (dont OVH), le domaine racine (`gite-angles.fr`) ne peut pas être un `CNAME`.
  Heroku recommande un `CNAME` vers la “DNS Target” Heroku, donc la solution la plus simple est souvent :
  - utiliser `www.gite-angles.fr` sur Heroku (CNAME)
  - rediriger `gite-angles.fr` → `https://www.gite-angles.fr` côté provider DNS
  Si tu veux servir **directement** `gite-angles.fr` sur Heroku, il faut un provider qui supporte `ALIAS/ANAME` ou du “CNAME flattening” (ex: Cloudflare).

### 1) Créer l’app + config vars

```bash
HEROKU_APP=lv-client1 \
CLIENT_DOMAIN=booking.client.com \
PRIMARY_OWNER_EMAIL=owner@client.com \
HOST_DEFAULT_IMAGE_URL=https://example.com/host.jpg \
STRIPE_SECRET_KEY=sk_live_xxx \
MAIL_FROM=no-reply@client.com \
SMTP_ADDRESS=smtp.mailgun.org \
SMTP_USERNAME=xxx \
SMTP_PASSWORD=yyy \
./script/provision_client.sh --create-app --scale
```

Créer un `SECRET_KEY_BASE` (une fois), puis le définir sur Heroku :

```bash
# Génère un secret localement (ok), puis le push en config var
heroku config:set -a lv-client1 SECRET_KEY_BASE=$(bin/rails secret)
```

Configurer Cloudinary (Active Storage) :

```bash
heroku config:set -a lv-client1 \
  CLOUDINARY_CLOUD_NAME=xxx \
  CLOUDINARY_API_KEY=yyy \
  CLOUDINARY_API_SECRET=zzz
```

### 2) Ajouter le domaine + SSL (ACM)

```bash
HEROKU_APP=lv-client1 \
CLIENT_DOMAIN=booking.client.com \
STRIPE_SECRET_KEY=sk_live_xxx \
MAIL_FROM=no-reply@client.com \
./script/provision_client.sh --add-domain

# Puis récupérer la cible DNS Heroku:
heroku domains -a lv-client1
```

### 3) Base de données

Créer l’addon Postgres si l’app est neuve (si tu as déjà une DB attachée, tu peux sauter cette étape) :

```bash
heroku addons:create heroku-postgresql:essential-0 -a lv-client1
```

Si l’app vient d’être créée, exécuter les migrations:

```bash
HEROKU_APP=lv-client1 \
CLIENT_DOMAIN=booking.client.com \
STRIPE_SECRET_KEY=sk_live_xxx \
MAIL_FROM=no-reply@client.com \
./script/provision_client.sh --db-prepare
```

### 4) Webhook Stripe

Créer un webhook endpoint sur le compte Stripe du client vers `https://<domaine>/stripe/webhook`, puis:
- Copier le signing secret (`whsec_...`) et définir:

```bash
heroku config:set -a lv-client1 STRIPE_WEBHOOK_SECRET=whsec_...
```

## Vérifications minimales

- `heroku config -a <app>` contient:
  - `APP_HOST`, `APP_PROTOCOL`, `APP_BASE_URL`
  - `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`
  - `MAIL_FROM` (+ SMTP si utilisé)
- La page `/up` répond 200.
- Un paiement de test (en mode test Stripe) déclenche bien `checkout.session.completed` côté webhook.

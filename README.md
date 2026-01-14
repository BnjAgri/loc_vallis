Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.

## Documentation

- `docs/ARCHITECTURE.md` : vue d'ensemble du domaine, flux Booking/Stripe, points d'entrée.
- `docs/MAINTENANCE.md` : variables d'env, opérations courantes, guide de maintenance.

## Memo: Admin / Owner calendrier (WIP)

Objectif: afficher dans le dashboard Owner (`/admin/rooms`) un calendrier des dates ouvertes/reservees par chambre + une vue combinee.

Fonctionnalites ajoutees:

- Calendrier par chambre (inline Flatpickr):
	- Vert = periodes d'ouverture (`OpeningPeriod`)
	- Jaune = demandes (`Booking.status == "requested"`)
	- Rouge = reserve (bloquant) (`Booking::RESERVED_STATUSES` = `approved_pending_payment`, `confirmed_paid`)
- Vue combinee (toutes les chambres):
	- Vert = ouvert dans toutes les chambres et non reserve
	- Rouge = au moins une chambre reservee
- Toggle pour afficher/masquer vue combinee et calendriers par chambre (persisted via `localStorage`).

Fichiers principaux:

- `app/views/admin/rooms/index.html.erb`
- `app/views/admin/rooms/show.html.erb`
- `app/controllers/admin/rooms_controller.rb`
- `app/javascript/controllers/admin_room_calendar_controller.js`
- `app/javascript/controllers/admin_rooms_calendar_toggle_controller.js`
- `app/services/date_range_set.rb` (+ tests `test/services/date_range_set_test.rb`)
- `app/assets/stylesheets/pages/_admin_rooms.scss`

Etat actuel (bug): le calendrier s'affiche mais les couleurs (classes CSS) ne s'appliquent pas.

Checklist debug (a faire):

1. Console navigateur: verifier qu'il n'y a aucune erreur JS (Stimulus/flatpickr/importmap).
2. Verifier que Stimulus tourne: `window.Stimulus` existe et pas d'erreur d'enregistrement de controller.
3. Ajouter temporairement un `console.log` dans `connect()` de `admin_room_calendar_controller.js`.
4. Sur un input `.lv-calendar-input`, verifier que `element._flatpickr` existe.
5. Inspecter les attributs `data-admin-room-calendar-*-ranges-value` (JSON avec dates `YYYY-MM-DD`).
6. Verifier que le CSS est charge: chercher `.flatpickr-calendar .flatpickr-day.lv-open-day` dans les styles.

Commandes utiles:

- `bin/rails test`
- relance serveur: stopper puis `bin/rails s`

## Cloudinary (Active Storage)

Pour stocker les photos des rooms sur Cloudinary via Active Storage, définir les variables d'environnement :

- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`

En développement, l'app utilise `:local` tant que ces variables ne sont pas définies. En production, le service est `:cloudinary`.

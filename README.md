Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.

## Documentation

- `docs/ARCHITECTURE.md` : vue d'ensemble du domaine, flux Booking/Stripe, points d'entrée.
- `docs/MAINTENANCE.md` : variables d'env, opérations courantes, guide de maintenance.

## Memo: Admin / Owner calendrier

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

## Cloudinary (Active Storage)

Pour stocker les photos des rooms sur Cloudinary via Active Storage, définir les variables d'environnement :

- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`

En développement, l'app utilise `:local` tant que ces variables ne sont pas définies. En production, le service est `:cloudinary`.

Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.

## Documentation

- `docs/ARCHITECTURE.md` : vue d'ensemble du domaine, flux Booking/Stripe, points d'entrée.
- `docs/MAINTENANCE.md` : variables d'env, opérations courantes, guide de maintenance.

## Cloudinary (Active Storage)

Pour stocker les photos des rooms sur Cloudinary via Active Storage, définir les variables d'environnement :

- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`

En développement, l'app utilise `:local` tant que ces variables ne sont pas définies. En production, le service est `:cloudinary`.

# Copilot instructions — Loc Vallis

## Big picture
- Rails 7.1 app (Ruby 3.3.5) for guesthouse bookings with **two Devise roles**: `User` (guest) and `Owner` (host/admin).
- Central domain objects: `Room`, `OpeningPeriod`, `Booking`, `Message` (messages are attached to a booking; `sender` is polymorphic).
- Payments/refunds use **Stripe**; booking lifecycle is a string-based state machine stored on `Booking`.

## Where the business logic lives
- Booking lifecycle + validations: `app/models/booking.rb` (see `STATUSES`, `approve!`, `expire_overdue!`, `payment_window_open?`).
- Pricing/availability rules: `app/services/booking_quote.rb` (`BookingQuote.call(...)` returns a Result struct; overlap logic uses `RESERVED_STATUSES`).
- Stripe integration:
  - Checkout session: `app/services/stripe_checkout_session_creator.rb` (precondition: `booking.payment_window_open?`).
  - Refund: `app/services/stripe_refund_creator.rb`.
  - Webhooks: `app/controllers/stripe_webhooks_controller.rb` (signature via `STRIPE_WEBHOOK_SECRET`, handlers must be **idempotent**).

## Controllers & authorization conventions
- User-facing booking actions: `app/controllers/bookings_controller.rb`.
- Owner/admin booking actions: `app/controllers/admin/bookings_controller.rb`.
- Authorization is Pundit; `BookingPolicy` is the source of truth for who can `pay?`, `approve?`, `refund?`, etc. (`app/policies/booking_policy.rb`).
- Some controllers run an explicit guard `Booking.expire_overdue!` before actions; keep this in mind when adding flows around payment windows.

## Background jobs / scheduling (Solid Queue)
- Uses **Solid Queue** (run workers with `bin/jobs start`).
- Separate queue database is configured in `config/database.yml` (`development.queue`, `test.queue`, `production.queue`).
- Recurring jobs are configured in `config/recurring.yml` (e.g. `ExpireOverdueBookingsJob` every 5 minutes).
- Mailers are often `deliver_later`, so local dev typically needs the jobs process running.

## Local dev workflow (common commands)
- Install + DB: `bundle install` then `bin/rails db:prepare`.
- Run web: `bin/rails s`.
- Run jobs: `bin/jobs start`.

## Environment variables you’ll likely need
- Stripe: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `APP_BASE_URL` (used for checkout success/cancel URLs).
- Cloudinary/Active Storage: `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`.

## Project-specific patterns to follow
- Services use the `Service.call(...)` convention and raise on violated preconditions (controllers typically rescue and show `alert`).
- Booking price is **persisted** (`total_price_cents` + `currency`) at creation; don’t recompute totals later without a migration/explicit design change.
- Stripe state changes happen via webhooks; keep handlers idempotent (Stripe can retry events).

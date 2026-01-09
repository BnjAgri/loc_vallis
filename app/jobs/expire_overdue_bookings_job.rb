## ExpireOverdueBookingsJob
# Job de maintenance : expire les bookings dont la fenêtre de paiement est dépassée.
#
# Cette logique vit dans `Booking.expire_overdue!` afin de rester réutilisable (controllers, jobs).
class ExpireOverdueBookingsJob < ApplicationJob
  queue_as :default

  def perform
    Booking.expire_overdue!
  end
end

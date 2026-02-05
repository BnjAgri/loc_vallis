## CancelOverdueRequestedBookingsJob
# Job de maintenance : annule les bookings "requested" dont la date de début est dépassée.
#
# Cette logique vit dans `Booking.cancel_overdue_requested!` afin de rester réutilisable.
class CancelOverdueRequestedBookingsJob < ApplicationJob
  queue_as :default

  def perform
    Booking.cancel_overdue_requested!
  end
end

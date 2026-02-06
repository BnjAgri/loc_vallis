## SendPostStayReviewRequestsJob
# Job quotidien : envoie un email de demande d'avis le lendemain du départ.
#
# La sélection et l'idempotence (via `review_request_sent_at`) vivent dans `Booking`.
class SendPostStayReviewRequestsJob < ApplicationJob
  queue_as :default

  def perform
    Booking.send_review_requests_after_stay!
  end
end

class ExpireOverdueBookingsJob < ApplicationJob
  queue_as :default

  def perform
    Booking.expire_overdue!
  end
end

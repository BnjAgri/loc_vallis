require "test_helper"

class BookingReviewRequestTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @owner = Owner.create!(email: "owner_review_request@test.local", password: "password")
    @user = User.create!(email: "guest_review_request@test.local", password: "password")
    @room = Room.create!(owner: @owner, name: "Room")

    OpeningPeriod.create!(
      room: @room,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 25),
      nightly_price_cents: 10_000,
      currency: "EUR"
    )
  end

  test "sends review request email the day after checkout (idempotent)" do
    travel_to Time.zone.local(2026, 1, 15, 10, 0, 0) do
      booking = Booking.create!(
        room: @room,
        user: @user,
        start_date: Date.new(2026, 1, 12),
        end_date: Date.new(2026, 1, 14),
        status: "confirmed_paid"
      )

      assert_enqueued_email_with BookingMailer, :review_request, params: { booking: booking } do
        Booking.send_review_requests_after_stay!
      end

      booking.reload
      assert booking.review_request_sent_at.present?

      assert_enqueued_emails 0 do
        Booking.send_review_requests_after_stay!
      end
    end
  end
end

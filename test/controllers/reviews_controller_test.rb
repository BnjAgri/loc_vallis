require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  test "user can create one review after stay" do
    travel_to Time.zone.local(2026, 1, 13, 12, 0, 0) do
      owner = Owner.create!(email: "owner_review_ctrl@test.local", password: "password")
      user = User.create!(email: "guest_review_ctrl@test.local", password: "password")
      room = Room.create!(owner:, name: "Room")

      OpeningPeriod.create!(
        room:,
        start_date: Date.new(2026, 1, 1),
        end_date: Date.new(2026, 1, 31),
        nightly_price_cents: 10_000,
        currency: "EUR"
      )

      booking = Booking.create!(
        room:,
        user:,
        start_date: Date.new(2026, 1, 10),
        end_date: Date.new(2026, 1, 12),
        status: "confirmed_paid"
      )

      sign_in user

      assert_difference "Review.count", 1 do
        post booking_reviews_path(booking), params: { review: { rating: 5, comment: "Super séjour" } }
      end

      assert_response :redirect

      assert_no_difference "Review.count" do
        post booking_reviews_path(booking), params: { review: { rating: 4, comment: "Deuxième avis" } }
      end
    end
  end
end

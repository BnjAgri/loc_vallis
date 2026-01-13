require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.local(2026, 1, 13, 12, 0, 0) do
      @owner = Owner.create!(email: "owner_review_model@test.local", password: "password")
      @user = User.create!(email: "guest_review_model@test.local", password: "password")
      @room = Room.create!(owner: @owner, name: "Room")

      OpeningPeriod.create!(
        room: @room,
        start_date: Date.new(2026, 1, 1),
        end_date: Date.new(2026, 1, 31),
        nightly_price_cents: 10_000,
        currency: "EUR"
      )

      @booking = Booking.create!(
        room: @room,
        user: @user,
        start_date: Date.new(2026, 1, 10),
        end_date: Date.new(2026, 1, 12),
        status: "confirmed_paid"
      )
    end
  end

  test "rating must be between 1 and 5" do
    travel_to Time.zone.local(2026, 1, 13, 12, 0, 0) do
      bad = Review.new(booking: @booking, user: @user, rating: 6, comment: "Too high")
      assert_not bad.valid?

      good = Review.new(booking: @booking, user: @user, rating: 5, comment: "Great")
      assert good.valid?
    end
  end

  test "only one review per booking" do
    travel_to Time.zone.local(2026, 1, 13, 12, 0, 0) do
      Review.create!(booking: @booking, user: @user, rating: 5, comment: "Great")
      second = Review.new(booking: @booking, user: @user, rating: 4, comment: "Again")
      assert_not second.valid?
    end
  end

  test "review user must match booking user" do
    travel_to Time.zone.local(2026, 1, 13, 12, 0, 0) do
      other_user = User.create!(email: "other_guest_review_model@test.local", password: "password")
      review = Review.new(booking: @booking, user: other_user, rating: 5, comment: "Nope")
      assert_not review.valid?
    end
  end
end

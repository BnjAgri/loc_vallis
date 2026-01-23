require "test_helper"

class OptionalLocaleSegmentTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  test "positional route args are ambiguous with optional locale" do
    booking = Booking.new(id: 123)

    assert_raises(ActionController::UrlGenerationError) do
      booking_path(booking)
    end
  end

  test "keyword route args work with optional locale" do
    booking = Booking.new(id: 123)

    assert_equal "/bookings/123", booking_path(id: booking)
    assert_equal "/bookings/123/messages", booking_messages_path(booking_id: booking)
    assert_equal "/bookings/123/reviews", booking_reviews_path(booking_id: booking)
  end
end

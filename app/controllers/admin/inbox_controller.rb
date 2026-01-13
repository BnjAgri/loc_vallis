module Admin
  class InboxController < ApplicationController
    before_action :authenticate_owner!

    def index
      bookings_scope = policy_scope(Booking)

      @bookings = bookings_scope.includes(:room, :user).to_a

      last_messages = Message
        .joins(:booking)
        .merge(bookings_scope)
        .select("DISTINCT ON (messages.booking_id) messages.*")
        .order("messages.booking_id, messages.created_at DESC")
        .includes(:sender)

      @last_message_by_booking_id = last_messages.index_by(&:booking_id)

      @unread_count_by_booking_id = Message
        .joins(:booking)
        .merge(bookings_scope)
        .where(sender_type: "User")
        .where("messages.created_at > COALESCE(bookings.owner_last_read_at, ?)", Time.at(0))
        .group("messages.booking_id")
        .count

      @bookings.sort_by! do |booking|
        last_message = @last_message_by_booking_id[booking.id]
        -(last_message&.created_at || booking.created_at).to_i
      end
    end
  end
end

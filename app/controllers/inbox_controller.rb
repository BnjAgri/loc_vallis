class InboxController < ApplicationController
  before_action :authenticate_user!

  def index
    base_scope = policy_scope(Booking)

    @filter = params[:filter].to_s
    unread_only = @filter == "unread"

    filtered_scope = base_scope
    if unread_only
      filtered_scope = filtered_scope
        .joins(:messages)
        .where(messages: { sender_type: "Owner" })
        .where("messages.created_at > COALESCE(bookings.user_last_read_at, ?)", Time.at(0))
        .distinct
    end

    @bookings = filtered_scope.includes(room: :owner).to_a

    booking_ids = @bookings.map(&:id)

    last_messages = if booking_ids.empty?
                      Message.none
                    else
                      Message
                        .joins(:booking)
                        .where(bookings: { id: booking_ids })
                        .select("DISTINCT ON (messages.booking_id) messages.*")
                        .order("messages.booking_id, messages.created_at DESC")
                        .includes(:sender)
                    end

    @last_message_by_booking_id = last_messages.index_by(&:booking_id)

    @unread_count_by_booking_id = Message
      .joins(:booking)
      .merge(base_scope)
      .where(sender_type: "Owner")
      .where("messages.created_at > COALESCE(bookings.user_last_read_at, ?)", Time.at(0))
      .group("messages.booking_id")
      .count

    @unread_conversations_count = @unread_count_by_booking_id.count
    @unread_messages_count = @unread_count_by_booking_id.values.sum

    @bookings.sort_by! do |booking|
      last_message = @last_message_by_booking_id[booking.id]
      -(last_message&.created_at || booking.created_at).to_i
    end
  end
end

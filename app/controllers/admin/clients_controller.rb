module Admin
  class ClientsController < ApplicationController
    before_action :authenticate_owner!
    before_action :expire_overdue_bookings

    NEXT_BOOKING_STATUSES = (Booking::RESERVED_STATUSES + ["requested"]).freeze

    def index
      authorize User, :index?

      bookings_scope = policy_scope(Booking)

      next_booking_sql = ApplicationRecord.sanitize_sql_array(
        [
          "MIN(CASE WHEN bookings.start_date >= ? AND bookings.status IN (?) THEN bookings.start_date END)",
          Date.current,
          NEXT_BOOKING_STATUSES
        ]
      )

      last_booking_sql = "MAX(bookings.start_date)"
      bookings_count_sql = "COUNT(bookings.id)"
      cancellations_count_sql = "SUM(CASE WHEN bookings.status IN ('canceled', 'expired') THEN 1 ELSE 0 END)"

      @clients =
        policy_scope(User)
          .joins(:bookings)
          .where(bookings: { id: bookings_scope.select(:id) })
          .select(
            "users.*",
            "#{next_booking_sql} AS next_booking_start_date",
            "#{last_booking_sql} AS last_booking_start_date",
            "#{bookings_count_sql} AS bookings_count",
            "#{cancellations_count_sql} AS cancellations_count"
          )
          .group("users.id")
          .order(Arel.sql("next_booking_start_date ASC NULLS LAST, last_booking_start_date DESC, users.id DESC"))
    end

    def show
      @client = policy_scope(User).find(params[:id])
      authorize @client

      bookings_scope = policy_scope(Booking)

      @next_booking = bookings_scope
        .where(user_id: @client.id, status: NEXT_BOOKING_STATUSES)
        .where("start_date >= ?", Date.current)
        .includes(:room)
        .order(:start_date)
        .first

      @bookings = bookings_scope
        .where(user_id: @client.id)
        .includes(:room)
        .order(start_date: :desc)

      @reviews = Review
        .joins(:booking)
        .where(bookings: { id: bookings_scope.where(user_id: @client.id).select(:id) })
        .includes(booking: :room)
        .order(created_at: :desc)

      @messages = Message
        .joins(:booking)
        .where(bookings: { id: bookings_scope.where(user_id: @client.id).select(:id) })
        .includes(:sender, booking: :room)
        .order(created_at: :desc)
    end

    private

    def expire_overdue_bookings
      Booking.expire_overdue!
    end
  end
end

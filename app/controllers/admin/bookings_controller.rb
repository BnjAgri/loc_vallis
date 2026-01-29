module Admin
  class BookingsController < ApplicationController
    before_action :authenticate_owner!
    before_action :expire_overdue_bookings

    def index
      bookings_scope = policy_scope(Booking)

      @bookings = bookings_scope
      if params[:date].present?
        begin
          date = Date.iso8601(params[:date].to_s)

          statuses =
            case params[:kind].to_s
            when "pending"
              ["requested"]
            when "booked"
              Booking::RESERVED_STATUSES
            else
              Booking::RESERVED_STATUSES + ["requested"]
            end

          @bookings = @bookings
            .where(status: statuses)
            .where("start_date <= ? AND end_date > ?", date, date)
        rescue ArgumentError
          # ignore invalid date
        end
      end

      @bookings = @bookings.includes(:room, :user).order(created_at: :desc)

      if params[:date].present? && @bookings.size == 1
        redirect_to admin_booking_path(id: @bookings.first)
        return
      end
      @rooms = policy_scope(Room).includes(:opening_periods).order(created_at: :desc)

      unread_bookings_scope = bookings_scope
        .joins(:messages)
        .where(messages: { sender_type: "User" })
        .where("messages.created_at > COALESCE(bookings.owner_last_read_at, ?)", Time.at(0))
        .distinct

      @unread_conversations_count = unread_bookings_scope.count

      @recent_messages = Message
        .joins(:booking)
        .merge(bookings_scope)
        .includes(:sender, booking: %i[room user])
        .order(created_at: :desc)
        .limit(10)
    end

    def show
      @booking = Booking.find(params[:id])
      authorize @booking

      @booking.mark_owner_read!

      @messages = @booking.messages.includes(:sender).order(:created_at)
      @message = Message.new
    end

    def approve
      @booking = Booking.find(params[:id])
      authorize @booking, :approve?

      @booking.approve!(by: current_owner)
      BookingMailer.with(booking: @booking).approved.deliver_later
      redirect_to admin_booking_path(id: @booking), notice: t("admin.bookings.flash.approved")
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_booking_path(id: @booking), alert: e.record.errors.full_messages.to_sentence
    end

    def decline
      @booking = Booking.find(params[:id])
      authorize @booking, :decline?

      @booking.decline!(by: current_owner)
      BookingMailer.with(booking: @booking).declined.deliver_later
      redirect_to admin_booking_path(id: @booking), notice: t("admin.bookings.flash.declined")
    end

    def cancel
      @booking = Booking.find(params[:id])
      authorize @booking, :cancel?

      @booking.cancel!(by: current_owner)
      BookingMailer.with(booking: @booking, canceled_by: "owner").canceled.deliver_later
      redirect_to admin_booking_path(id: @booking), notice: t("admin.bookings.flash.canceled")
    end

    def refund
      @booking = Booking.find(params[:id])
      authorize @booking, :refund?

      StripeRefundCreator.call(booking: @booking)
      BookingMailer.with(booking: @booking).refunded.deliver_later
      redirect_to admin_booking_path(id: @booking), notice: t("admin.bookings.flash.refund_initiated")
    rescue StandardError => e
      redirect_to admin_booking_path(id: @booking), alert: e.message
    end

    private

    def expire_overdue_bookings
      Booking.expire_overdue!
    end
  end
end

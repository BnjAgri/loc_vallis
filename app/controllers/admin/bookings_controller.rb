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

      per_page = 10

      filtered_bookings = @bookings

      total_bookings = filtered_bookings.count

      if params[:date].present? && total_bookings == 1
        redirect_to admin_booking_path(id: filtered_bookings.first)
        return
      end

      @bookings_page = params[:bookings_page].to_i
      @bookings_page = 1 if @bookings_page < 1
      @total_bookings = total_bookings
      @bookings_total_pages = (@total_bookings.to_f / per_page).ceil
      @bookings_total_pages = 1 if @bookings_total_pages < 1
      @bookings_page = @bookings_total_pages if @bookings_page > @bookings_total_pages

      bookings_offset = (@bookings_page - 1) * per_page
      @bookings = filtered_bookings
        .includes(:room, :user)
        .order(created_at: :desc)
        .limit(per_page)
        .offset(bookings_offset)

      @rooms = policy_scope(Room).includes(:opening_periods).order(created_at: :desc)

      unread_bookings_scope = bookings_scope
        .joins(:messages)
        .where(messages: { sender_type: "User" })
        .where("messages.created_at > COALESCE(bookings.owner_last_read_at, ?)", Time.at(0))
        .distinct

      @unread_conversations_count = unread_bookings_scope.count

      recent_messages_scope = Message
        .joins(:booking)
        .merge(bookings_scope)

      @messages_page = params[:messages_page].to_i
      @messages_page = 1 if @messages_page < 1
      @total_messages = recent_messages_scope.count
      @messages_total_pages = (@total_messages.to_f / per_page).ceil
      @messages_total_pages = 1 if @messages_total_pages < 1
      @messages_page = @messages_total_pages if @messages_page > @messages_total_pages

      messages_offset = (@messages_page - 1) * per_page
      @recent_messages = recent_messages_scope
        .includes(:sender, booking: %i[room user])
        .order(created_at: :desc)
        .limit(per_page)
        .offset(messages_offset)
    end

    def show
      @booking = Booking.find(params[:id])
      authorize @booking

      @booking.mark_owner_read!

      @messages = @booking.messages.includes(:sender).order(created_at: :desc)
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

      amount_cents = params[:amount_cents].presence
      amount_cents = amount_cents.to_i if amount_cents

      StripeRefundCreator.call(booking: @booking, amount_cents: amount_cents)
      BookingMailer.with(booking: @booking).refunded.deliver_later
      redirect_to admin_booking_path(id: @booking), notice: t("admin.bookings.flash.refund_initiated")
    rescue Pundit::NotAuthorizedError
      raise
    rescue StandardError => e
      redirect_to admin_booking_path(id: @booking), alert: e.message
    end

    private

    def expire_overdue_bookings
      Booking.expire_overdue!
    end
  end
end

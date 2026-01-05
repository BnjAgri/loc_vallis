module Admin
  class BookingsController < ApplicationController
    before_action :authenticate_owner!
    before_action :expire_overdue_bookings

    def index
      @bookings = policy_scope(Booking).order(created_at: :desc)
    end

    def show
      @booking = Booking.find(params[:id])
      authorize @booking
    end

    def approve
      @booking = Booking.find(params[:id])
      authorize @booking, :approve?

      @booking.approve!(by: current_owner)
      redirect_to admin_booking_path(@booking), notice: "Booking approved."
    end

    def decline
      @booking = Booking.find(params[:id])
      authorize @booking, :decline?

      @booking.decline!(by: current_owner)
      redirect_to admin_booking_path(@booking), notice: "Booking declined."
    end

    def cancel
      @booking = Booking.find(params[:id])
      authorize @booking, :cancel?

      @booking.cancel!(by: current_owner)
      redirect_to admin_booking_path(@booking), notice: "Booking canceled."
    end

    def refund
      @booking = Booking.find(params[:id])
      authorize @booking, :refund?

      StripeRefundCreator.call(booking: @booking)
      redirect_to admin_booking_path(@booking), notice: "Refund initiated."
    rescue StandardError => e
      redirect_to admin_booking_path(@booking), alert: e.message
    end

    private

    def expire_overdue_bookings
      Booking.expire_overdue!
    end
  end
end

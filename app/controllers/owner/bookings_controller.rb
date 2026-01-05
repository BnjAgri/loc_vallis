module Owner
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
      redirect_to owner_booking_path(@booking), notice: "Booking approved."
    end

    def decline
      @booking = Booking.find(params[:id])
      authorize @booking, :decline?

      @booking.decline!(by: current_owner)
      redirect_to owner_booking_path(@booking), notice: "Booking declined."
    end

    def cancel
      @booking = Booking.find(params[:id])
      authorize @booking, :cancel?

      @booking.cancel!(by: current_owner)
      redirect_to owner_booking_path(@booking), notice: "Booking canceled."
    end

    private

    def expire_overdue_bookings
      Booking.expire_overdue!
    end
  end
end

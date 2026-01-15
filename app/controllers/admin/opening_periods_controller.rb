module Admin
  class OpeningPeriodsController < ApplicationController
    before_action :authenticate_owner!

    def create
      room = policy_scope(Room).find(params[:room_id])
      authorize room, :update?

      opening_period = OpeningPeriod.new(opening_period_params)
      opening_period.room = room
      authorize opening_period

      if opening_period.save
        redirect_to admin_room_path(room), notice: "Opening period added."
      else
        redirect_to admin_room_path(room), alert: opening_period.errors.full_messages.to_sentence
      end
    end

    def destroy
      room = policy_scope(Room).find(params[:room_id])
      authorize room, :update?

      opening_period = room.opening_periods.find(params[:id])
      authorize opening_period

      blocking_statuses = Booking::RESERVED_STATUSES + ["requested"]
      has_upcoming_blocking_bookings = room.bookings
        .where(status: blocking_statuses)
        .where("end_date > ?", Date.current)
        .where("start_date < ? AND end_date > ?", opening_period.end_date, opening_period.start_date)
        .exists?

      if has_upcoming_blocking_bookings
        redirect_to admin_room_path(room), alert: "Réservations à venir, suppression impossible"
        return
      end

      opening_period.destroy
      redirect_to admin_room_path(room), notice: "Opening period removed."
    end

    private

    def opening_period_params
      params.require(:opening_period).permit(:start_date, :end_date, :nightly_price_euros, :currency)
    end
  end
end

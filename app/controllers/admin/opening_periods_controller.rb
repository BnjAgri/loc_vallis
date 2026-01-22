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
        redirect_to admin_room_path(room), notice: t("admin.opening_periods.flash.added")
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
        redirect_to admin_room_path(room), alert: t("admin.shared.flash.deletion_blocked_upcoming_bookings")
        return
      end

      opening_period.destroy
      redirect_to admin_room_path(room), notice: t("admin.opening_periods.flash.removed")
    end

    def edit
      @room = policy_scope(Room).includes(:opening_periods).find(params[:room_id])
      authorize @room, :update?

      @opening_period = @room.opening_periods.find(params[:id])
      authorize @opening_period

      euros = @opening_period.nightly_price_cents.to_f / 100.0
      @opening_period.nightly_price_euros = format("%.2f", euros)

      @other_open_ranges = @room.opening_periods
        .where.not(id: @opening_period.id)
        .order(:start_date)
        .map { |p| { from: p.start_date, to: (p.end_date - 1.day) } }
    end

    def update
      room = policy_scope(Room).find(params[:room_id])
      authorize room, :update?

      opening_period = room.opening_periods.find(params[:id])
      authorize opening_period

      if opening_period.update(opening_period_params)
        redirect_to admin_room_path(room), notice: t("admin.opening_periods.flash.updated")
      else
        redirect_to edit_admin_room_opening_period_path(room, opening_period), alert: opening_period.errors.full_messages.to_sentence
      end
    end

    private

    def opening_period_params
      params.require(:opening_period).permit(:start_date, :end_date, :nightly_price_euros, :currency)
    end
  end
end

class RoomsController < ApplicationController
  def index
    @rooms = Room
      .with_attached_photos
      .includes(:opening_periods)
      .order(:created_at)
  end

  def show
    @room = Room.find(params[:id])

    @enabled_ranges = @room.opening_periods
      .pluck(:start_date, :end_date)
      .map do |start_date, end_date|
        {
          from: start_date.to_s,
          to: (end_date - 1.day).to_s
        }
      end

    reserved_statuses = %w[approved_pending_payment confirmed_paid]
    @disabled_ranges = @room.bookings
      .where(status: reserved_statuses)
      .pluck(:start_date, :end_date)
      .map do |start_date, end_date|
        {
          from: start_date.to_s,
          to: (end_date - 1.day).to_s
        }
      end
  end
end

class RoomsController < ApplicationController
  def index
    @rooms = Room
      .with_attached_photos
      .includes(:opening_periods)
      .left_joins(:reviews)
      .select(
        "rooms.*",
        "AVG(reviews.rating) AS average_rating",
        "COUNT(reviews.id) AS reviews_count"
      )
      .group("rooms.id")
      .order(:created_at)

    @owner = Owner.order(:created_at).first

    @hero_owner_name = @owner&.first_name.presence || ENV.fetch("GUESTHOUSE_OWNER_NAME", "Claude")
    @hero_location = ENV.fetch("GUESTHOUSE_LOCATION", ENV.fetch("MAP_LOCATION", "Anglès"))

    @guesthouse_name = @owner&.guesthouse_name.presence || ENV.fetch("GUESTHOUSE_NAME", "Chez Claude")
    @owner_postal_address = @owner&.postal_address.presence || ENV["OWNER_POSTAL_ADDRESS"].presence || ENV.fetch("MAP_ADDRESS", "")
    @owner_phone = @owner&.phone.presence || ENV["OWNER_PHONE"].presence
  end

  def show
    @room = Room.find(params[:id])

    today = Date.current
    @enabled_ranges = @room.opening_periods
      .pluck(:start_date, :end_date)
      .map do |start_date, end_date|
        start_date = [start_date, today].max
        next if end_date <= start_date

        {
          from: start_date.to_s,
          to: (end_date - 1.day).to_s
        }
      end
      .compact

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

    reviews = @room.reviews.includes(:user).order(created_at: :desc)
    @average_rating = reviews.average(:rating)&.to_f
    @reviews_count = reviews.count
    @latest_reviews = reviews.limit(2)
  end
end

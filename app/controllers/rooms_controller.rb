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

    open_pairs = @room.opening_periods.pluck(:start_date, :end_date).filter_map do |start_date, end_date|
      start_date = [start_date, today].max
      # Opening periods are end-exclusive in DB; Flatpickr uses inclusive ranges.
      to = end_date - 1.day
      next if to < start_date

      [start_date, to]
    end

    open_set = DateRangeSet.from_pairs(open_pairs)
    booked_set = DateRangeSet.from_records(
      @room.bookings.where(status: Booking::RESERVED_STATUSES),
      start_attr: :start_date,
      end_attr: :end_date,
      end_exclusive: true
    )

    available_set = open_set.subtract(booked_set)

    # We store opening periods as end-exclusive ranges in DB ([start_date, end_date)).
    # Our DateRangeSet uses inclusive Date..Date pairs representing *nights* (start dates).
    # Flatpickr (range mode) needs the checkout day to be selectable as the end date,
    # so we extend each availability range by one day on its end.
    @enabled_ranges = available_set.to_range_hashes.map do |r|
      { from: r[:from].to_s, to: (r[:to] + 1.day).to_s }
    end
    # Keep disabled empty to avoid any precedence quirks between Flatpickr enable/disable.
    @disabled_ranges = []

    reviews = @room.reviews.includes(:user).order(created_at: :desc)
    @average_rating = reviews.average(:rating)&.to_f
    @reviews_count = reviews.count
    @latest_reviews = reviews.limit(2)
  end
end

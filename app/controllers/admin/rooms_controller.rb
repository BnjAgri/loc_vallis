module Admin
  class RoomsController < ApplicationController
    before_action :authenticate_owner!

    def index
      @rooms = policy_scope(Room).includes(:opening_periods, :bookings).order(:created_at)

      open_sets = @rooms.map do |room|
        DateRangeSet.from_records(room.opening_periods, start_attr: :start_date, end_attr: :end_date, end_exclusive: true)
      end

      booked_set = DateRangeSet.from_records(
        @rooms.flat_map { |room| room.bookings.select { |b| Booking::RESERVED_STATUSES.include?(b.status) } },
        start_attr: :start_date,
        end_attr: :end_date,
        end_exclusive: true
      )

      pending_set = DateRangeSet.from_records(
        @rooms.flat_map { |room| room.bookings.select { |b| b.status == "requested" } },
        start_attr: :start_date,
        end_attr: :end_date,
        end_exclusive: true
      )

      @combined_open_ranges =
        if open_sets.empty?
          []
        else
          combined_open = open_sets.reduce { |acc, set| acc.intersect(set) }
          combined_open.subtract(booked_set).to_range_hashes
        end

      @combined_booked_ranges = booked_set.to_range_hashes

      @combined_pending_ranges = pending_set.to_range_hashes
    end

    def show
      @room = policy_scope(Room).includes(:opening_periods, :bookings).find(params[:id])
      authorize @room

      @opening_period = OpeningPeriod.new(room: @room, currency: "EUR")
      @opening_periods = @room.opening_periods.order(:start_date)
    end

    def new
      @room = Room.new
      authorize @room
    end

    def create
      @room = Room.new(room_params)
      @room.owner = current_owner
      authorize @room

      if @room.save
        redirect_to admin_room_path(id: @room), notice: t("admin.rooms.flash.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @room = policy_scope(Room).find(params[:id])
      authorize @room
    end

    def update
      @room = policy_scope(Room).find(params[:id])
      authorize @room

      if @room.update(room_params)
        redirect_to admin_room_path(id: @room), notice: t("admin.rooms.flash.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @room = policy_scope(Room).find(params[:id])
      authorize @room

      blocking_statuses = Booking::RESERVED_STATUSES + ["requested"]
      has_upcoming_blocking_bookings = @room.bookings
        .where(status: blocking_statuses)
        .where("end_date > ?", Date.current)
        .exists?

      if has_upcoming_blocking_bookings
        redirect_to admin_room_path(id: @room), alert: t("admin.shared.flash.deletion_blocked_upcoming_bookings")
        return
      end

      @room.destroy!
      redirect_to admin_rooms_path, notice: t("admin.rooms.flash.deleted")
    end

    private

    def room_params
      params.require(:room).permit(
        :name,
        :description,
        :capacity,
        :room_url,
        photos: [],
        optional_services: %i[name price_eur]
      )
    end
  end
end

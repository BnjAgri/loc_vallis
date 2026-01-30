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

    def destroy_photo
      @room = policy_scope(Room).find(params[:id])
      authorize @room, :update?

      attachment = @room.photos.attachments.find_by(id: params[:photo_id])
      unless attachment
        respond_to do |format|
          format.html { redirect_to edit_admin_room_path(id: @room), alert: t("admin.rooms.photos.flash.not_found") }
          format.turbo_stream { render turbo_stream: turbo_stream.replace("existing-photos", partial: "existing_photos", locals: { room: @room }) }
        end
        return
      end

      attachment.purge

      respond_to do |format|
        format.html { redirect_to edit_admin_room_path(id: @room), notice: t("admin.rooms.photos.flash.deleted") }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("existing-photos", partial: "existing_photos", locals: { room: @room }) }
      end
    end

    def destroy_url
      @room = policy_scope(Room).find(params[:id])
      authorize @room, :update?

      urls = @room.image_urls
      index = params[:url_index].to_i

      if index < 0 || index >= urls.size
        respond_to do |format|
          format.html { redirect_to edit_admin_room_path(id: @room), alert: t("admin.rooms.urls.flash.not_found") }
          format.turbo_stream { render turbo_stream: turbo_stream.replace("existing-url-photos", partial: "existing_url_photos", locals: { room: @room }) }
        end
        return
      end

      urls.delete_at(index)
      @room.room_url = urls.join("\n")
      @room.save

      respond_to do |format|
        format.html { redirect_to edit_admin_room_path(id: @room), notice: t("admin.rooms.urls.flash.deleted") }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("existing-url-photos", partial: "existing_url_photos", locals: { room: @room }) }
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
      permitted = params.require(:room).permit(
        :name,
        :description,
        :capacity,
        :room_url,
        photos: [],
        optional_services: %i[name price_eur]
      )

      # IMPORTANT: A multi-file input can submit an empty array / empty string when no file is selected.
      # If we pass that through to `@room.update`, Active Storage treats it as a replacement and removes
      # existing attachments. We only keep `photos` when at least one real upload is present.
      photos = Array(permitted[:photos]).reject(&:blank?)
      if photos.any?
        permitted[:photos] = photos
      else
        permitted.delete(:photos)
      end

      # Same idea for URLs: keep existing value unless a non-blank value is submitted.
      if permitted.key?(:room_url) && permitted[:room_url].to_s.strip.blank?
        permitted.delete(:room_url)
      end

      permitted
    end
  end
end

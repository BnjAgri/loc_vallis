module Admin
  class ClientsController < ApplicationController
    before_action :authenticate_owner!
    before_action :expire_overdue_bookings

    NEXT_BOOKING_STATUSES = (Booking::RESERVED_STATUSES + ["requested"]).freeze
    LAST_BOOKING_STATUSES = %w[confirmed_paid refunded canceled expired].freeze

    def index
      authorize User, :index?

      bookings_scope = policy_scope(Booking)

      bookings_scope_ids_sql = bookings_scope.select(:id).to_sql

      sort = params[:sort].to_s
      direction = params[:direction].to_s
      sort = "next_booking" unless %w[next_booking alpha].include?(sort)
      direction = "asc" unless %w[asc desc].include?(direction)

      next_booking_sql = ApplicationRecord.sanitize_sql_array(
        [
          "MIN(CASE WHEN bookings.start_date >= ? AND bookings.status IN (?) THEN bookings.start_date END)",
          Date.current,
          NEXT_BOOKING_STATUSES
        ]
      )

      last_booking_sql = "MAX(bookings.start_date)"
      bookings_count_sql = "COUNT(bookings.id)"
      cancellations_count_sql = "SUM(CASE WHEN bookings.status IN ('canceled', 'expired') THEN 1 ELSE 0 END)"

      current_booking_status_sql = ApplicationRecord.sanitize_sql_array(
        [
          "(SELECT b.status FROM bookings b WHERE b.user_id = users.id AND b.id IN (#{bookings_scope_ids_sql}) AND b.start_date <= ? AND b.end_date > ? AND b.status IN (?) ORDER BY b.start_date ASC LIMIT 1)",
          Date.current,
          Date.current,
          NEXT_BOOKING_STATUSES
        ]
      )

      current_booking_start_date_sql = ApplicationRecord.sanitize_sql_array(
        [
          "(SELECT b.start_date FROM bookings b WHERE b.user_id = users.id AND b.id IN (#{bookings_scope_ids_sql}) AND b.start_date <= ? AND b.end_date > ? AND b.status IN (?) ORDER BY b.start_date ASC LIMIT 1)",
          Date.current,
          Date.current,
          NEXT_BOOKING_STATUSES
        ]
      )

      last_relevant_booking_status_sql = ApplicationRecord.sanitize_sql_array(
        [
          "(SELECT b.status FROM bookings b WHERE b.user_id = users.id AND b.id IN (#{bookings_scope_ids_sql}) AND b.status IN (?) ORDER BY b.start_date DESC LIMIT 1)",
          LAST_BOOKING_STATUSES
        ]
      )

      last_relevant_booking_start_date_sql = ApplicationRecord.sanitize_sql_array(
        [
          "(SELECT b.start_date FROM bookings b WHERE b.user_id = users.id AND b.id IN (#{bookings_scope_ids_sql}) AND b.status IN (?) ORDER BY b.start_date DESC LIMIT 1)",
          LAST_BOOKING_STATUSES
        ]
      )

      @clients =
        policy_scope(User)
          .joins(:bookings)
          .where(bookings: { id: bookings_scope.select(:id) })
          .select(
            "users.*",
            "#{next_booking_sql} AS next_booking_start_date",
            "#{last_booking_sql} AS last_booking_start_date",
            "#{bookings_count_sql} AS bookings_count",
            "#{cancellations_count_sql} AS cancellations_count",
            "#{current_booking_status_sql} AS current_booking_status",
            "#{current_booking_start_date_sql} AS current_booking_start_date",
            "#{last_relevant_booking_status_sql} AS last_relevant_booking_status",
            "#{last_relevant_booking_start_date_sql} AS last_relevant_booking_start_date"
          )
          .group("users.id")

      @clients =
        case sort
        when "alpha"
          name_order = "LOWER(COALESCE(users.last_name, '')) #{direction}, LOWER(COALESCE(users.first_name, '')) #{direction}, LOWER(users.email) #{direction}"
          @clients.order(Arel.sql(name_order))
        else
          nulls = direction == "asc" ? "NULLS LAST" : "NULLS FIRST"
          @clients.order(Arel.sql("next_booking_start_date #{direction.upcase} #{nulls}, last_booking_start_date DESC, users.id DESC"))
        end

      per_page = 20
      @page = params[:page].to_i
      @page = 1 if @page < 1

      total_clients_relation =
        policy_scope(User)
          .joins(:bookings)
          .where(bookings: { id: bookings_scope.select(:id) })
          .distinct

      @total_clients = total_clients_relation.count(:id)
      @total_pages = (@total_clients.to_f / per_page).ceil
      @total_pages = 1 if @total_pages < 1
      @page = @total_pages if @page > @total_pages

      offset = (@page - 1) * per_page
      @clients = @clients.limit(per_page).offset(offset)
    end

    def show
      @client = policy_scope(User).find(params[:id])
      authorize @client

      bookings_scope = policy_scope(Booking)

      @next_booking = bookings_scope
        .where(user_id: @client.id, status: NEXT_BOOKING_STATUSES)
        .where("start_date >= ?", Date.current)
        .includes(:room)
        .order(:start_date)
        .first

      @bookings = bookings_scope
        .where(user_id: @client.id)
        .includes(:room)
        .order(start_date: :desc)

      @reviews = Review
        .joins(:booking)
        .where(bookings: { id: bookings_scope.where(user_id: @client.id).select(:id) })
        .includes(booking: :room)
        .order(created_at: :desc)

      @messages = Message
        .joins(:booking)
        .where(bookings: { id: bookings_scope.where(user_id: @client.id).select(:id) })
        .includes(:sender, booking: :room)
        .order(created_at: :desc)
    end

    def destroy
      @client = policy_scope(User).find(params[:id])
      authorize @client

      bookings_scope = policy_scope(Booking)

      active_bookings_exist = bookings_scope
        .where(user_id: @client.id, status: NEXT_BOOKING_STATUSES)
        .where("end_date > ?", Date.current)
        .exists?

      if active_bookings_exist
        redirect_to admin_client_path(id: @client), alert: t("admin.clients.flash.active_bookings")
        return
      end

      @client.destroy!
      redirect_to admin_clients_path, notice: t("admin.clients.flash.deleted")
    rescue ActiveRecord::RecordNotDestroyed => e
      redirect_to admin_client_path(id: @client), alert: e.message
    end

    private

    def expire_overdue_bookings
      Booking.expire_overdue!
    end
  end
end

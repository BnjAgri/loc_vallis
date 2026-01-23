## BookingsController
# Parcours et actions côté `User` autour des bookings.
#
# Points clés :
# - Les actions sont protégées par Devise (`authenticate_user!`) + Pundit.
# - `checkout` délègue la création de session Stripe à `StripeCheckoutSessionCreator`.
# - Un garde-fou expire les bookings “en attente de paiement” via `Booking.expire_overdue!`.
class BookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :expire_overdue_bookings

  def index
    @bookings = policy_scope(Booking).order(created_at: :desc)
  end

  def show
    @booking = policy_scope(Booking).find(params[:id])
    authorize @booking

    @booking.mark_user_read!

    @messages = @booking.messages.includes(:sender).order(:created_at)
    @message = Message.new

    @review = @booking.review || @booking.build_review(user: current_user)
  end

  def checkout
    @booking = policy_scope(Booking).find(params[:id])
    authorize @booking, :pay?

    session = StripeCheckoutSessionCreator.call(booking: @booking)
    redirect_to session.url, allow_other_host: true
  rescue StandardError => e
    redirect_to @booking, alert: e.message
  end

  def new
    @room = Room.find(params[:room_id])
    authorize @room, :show?

    @booking = Booking.new(room: @room)
    @booking.start_date = parse_date_param(params[:start_date]) if params[:start_date].present?
    @booking.end_date = parse_date_param(params[:end_date]) if params[:end_date].present?
  end

  def create
    @room = Room.find(params[:room_id])
    authorize @room, :show?

    @booking = Booking.new(booking_params)
    @booking.room = @room
    @booking.user = current_user
    @booking.selected_optional_services = selected_optional_services_from_params(@room)

    authorize @booking

    if @booking.save
      BookingMailer.with(booking: @booking).requested.deliver_later
      redirect_to @booking, notice: t("bookings.flash.request_sent")
    else
      render :new, status: :unprocessable_content
    end
  end

  def cancel
    @booking = policy_scope(Booking).find(params[:id])
    authorize @booking, :cancel?

    if @booking.cancel!(by: current_user)
      BookingMailer.with(booking: @booking, canceled_by: "user").canceled.deliver_later
      redirect_to @booking, notice: t("bookings.flash.canceled")
    else
      redirect_to @booking, alert: t("bookings.flash.unable_to_cancel")
    end
  end

  private

  def booking_params
    params.require(:booking).permit(:start_date, :end_date)
  end

  def selected_optional_services_from_params(room)
    names = Array(params.dig(:booking, :optional_service_names)).map { |n| n.to_s.strip }.reject(&:blank?)
    return [] if names.empty?

    allowed = Array(room.optional_services)
    allowed_by_name = allowed.each_with_object({}) do |entry, acc|
      next unless entry.is_a?(Hash)

      name = (entry["name"] || entry[:name]).to_s.strip
      next if name.blank?

      acc[name] = entry
    end

    unique_names = names.uniq.first(5)
    unique_names.filter_map do |name|
      allowed_entry = allowed_by_name[name]
      next if allowed_entry.nil?

      {
        "name" => name,
        "price_cents" => (allowed_entry["price_cents"] || allowed_entry[:price_cents]).to_i,
        "currency" => (allowed_entry["currency"] || allowed_entry[:currency]).to_s.presence || "EUR"
      }
    end
  end

  def expire_overdue_bookings
    Booking.expire_overdue!
  end

  def parse_date_param(value)
    Date.parse(value.to_s)
  rescue Date::Error
    nil
  end
end

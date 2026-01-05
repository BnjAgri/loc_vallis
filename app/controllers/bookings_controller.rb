class BookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :expire_overdue_bookings

  def index
    @bookings = policy_scope(Booking).order(created_at: :desc)
  end

  def show
    @booking = Booking.find(params[:id])
    authorize @booking
  end

  def new
    @room = Room.find(params[:room_id])
    authorize @room, :show?

    @booking = Booking.new(room: @room)
  end

  def create
    @room = Room.find(params[:room_id])
    authorize @room, :show?

    @booking = Booking.new(booking_params)
    @booking.room = @room
    @booking.user = current_user

    authorize @booking

    if @booking.save
      redirect_to @booking, notice: "Booking request sent."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def cancel
    @booking = Booking.find(params[:id])
    authorize @booking, :cancel?

    if @booking.cancel!(by: current_user)
      redirect_to @booking, notice: "Booking canceled."
    else
      redirect_to @booking, alert: "Unable to cancel booking."
    end
  end

  private

  def booking_params
    params.require(:booking).permit(:start_date, :end_date)
  end

  def expire_overdue_bookings
    Booking.expire_overdue!
  end
end

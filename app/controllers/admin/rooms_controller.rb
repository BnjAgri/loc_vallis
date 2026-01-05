module Admin
  class RoomsController < ApplicationController
    before_action :authenticate_owner!

    def index
      @rooms = policy_scope(Room).order(:created_at)
    end

    def show
      @room = policy_scope(Room).find(params[:id])
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
        redirect_to admin_room_path(@room), notice: "Room created."
      else
        render :new, status: :unprocessable_entity
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
        redirect_to admin_room_path(@room), notice: "Room updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def room_params
      params.require(:room).permit(:name, :capacity)
    end
  end
end

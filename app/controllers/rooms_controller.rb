class RoomsController < ApplicationController
  def index
    @rooms = Room.order(:created_at)
  end

  def show
    @room = Room.find(params[:id])
  end
end

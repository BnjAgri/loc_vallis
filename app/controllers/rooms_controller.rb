class RoomsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]

  def index
    @rooms = Room.order(:created_at)
  end

  def show
    @room = Room.find(params[:id])
  end
end

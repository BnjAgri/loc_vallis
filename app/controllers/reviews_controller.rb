class ReviewsController < ApplicationController
  before_action :authenticate_user!

  def create
    @booking = policy_scope(Booking).find(params[:booking_id])
    authorize @booking, :show?

    if @booking.review&.persisted?
      redirect_to @booking, alert: t("reviews.flash.already_left")
      return
    end

    @review = @booking.build_review(review_params.merge(user: current_user))
    authorize @review

    if @review.save
      redirect_to @booking, notice: t("reviews.flash.thanks")
    else
      @messages = @booking.messages.includes(:sender).order(:created_at)
      @message = Message.new
      flash.now[:alert] = @review.errors.full_messages.to_sentence
      render "bookings/show", status: :unprocessable_content
    end
  end

  private

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end

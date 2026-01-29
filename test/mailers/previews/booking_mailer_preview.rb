require_relative "preview_data"

class BookingMailerPreview < ActionMailer::Preview
  def requested
    BookingMailer.with(booking: PreviewData.booking(status: "requested")).requested
  end

  def approved
    BookingMailer.with(booking: PreviewData.booking(status: "approved_pending_payment")).approved
  end

  def declined
    BookingMailer.with(booking: PreviewData.booking(status: "declined")).declined
  end

  def confirmed
    BookingMailer.with(booking: PreviewData.booking(status: "confirmed_paid")).confirmed
  end

  def canceled
    BookingMailer.with(
      booking: PreviewData.booking(status: "canceled"),
      canceled_by: "user"
    ).canceled
  end

  def expired
    BookingMailer.with(booking: PreviewData.booking(status: "expired")).expired
  end

  def refunded
    BookingMailer.with(booking: PreviewData.booking(status: "refunded")).refunded
  end

  def review_request
    BookingMailer.with(booking: PreviewData.booking(status: "confirmed_paid")).review_request
  end
end

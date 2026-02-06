class AddReviewRequestSentAtToBookings < ActiveRecord::Migration[7.1]
  def change
    add_column :bookings, :review_request_sent_at, :datetime
    add_index :bookings, :review_request_sent_at
  end
end

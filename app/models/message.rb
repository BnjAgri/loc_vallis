## Message
# Message conversationnel rattaché à une `Booking`.
#
# `sender` est polymorphique afin de supporter `User` et `Owner`.
class Message < ApplicationRecord
  belongs_to :booking
  belongs_to :sender, polymorphic: true

  validates :body, presence: true
end

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :bookings, dependent: :destroy
  has_many :messages, as: :sender, dependent: :nullify

  has_many :reviews, dependent: :destroy

  def display_name
    email.to_s.split("@").first.presence || "Guest"
  end
end

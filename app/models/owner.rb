class Owner < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :rooms, dependent: :destroy

  has_many :articles, dependent: :destroy

  def display_name
    full_name = [first_name, last_name].map { |s| s.to_s.strip.presence }.compact.join(" ").presence
    full_name || guesthouse_name.to_s.strip.presence || email.to_s.split("@").first.presence || "Host"
  end
end

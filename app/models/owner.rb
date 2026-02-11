class Owner < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  has_many :rooms, dependent: :destroy

  has_many :articles, dependent: :destroy

  validate :singleton_owner, on: :create, unless: -> { Rails.env.test? }
  validate :email_matches_primary_owner, unless: -> { Rails.env.test? }

  def self.primary_email
    Rails.configuration.x.primary_owner_email.to_s
  end

  def display_name
    full_name = [first_name, last_name].map { |s| s.to_s.strip.presence }.compact.join(" ").presence
    full_name || guesthouse_name.to_s.strip.presence || email.to_s.split("@").first.presence || "Host"
  end

  private

  def singleton_owner
    return unless self.class.where.not(id: id).exists?

    errors.add(:base, "Only one owner is allowed")
  end

  def email_matches_primary_owner
    primary = self.class.primary_email
    return if primary.blank?
    return if email.to_s.casecmp(primary).zero?

    errors.add(:email, "must be #{primary}")
  end
end

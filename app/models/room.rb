## Room
# Représente un logement publié par un `Owner`.
#
# Points d'attention :
# - Les photos utilisent Active Storage (`has_many_attached :photos`).
# - Les disponibilités et le pricing sont portés par `OpeningPeriod`.
# - Règle MVP : limitation volontaire à 2 rooms max (validation on create).
class Room < ApplicationRecord
  belongs_to :owner

  has_many_attached :photos

  has_many :opening_periods, dependent: :destroy
  has_many :bookings, dependent: :destroy

  has_many :reviews, through: :bookings

  validates :name, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :mvp_room_limit, on: :create
  validate :validate_photos

  validate :disallow_angle_brackets_in_text_fields

  before_validation :normalize_optional_services
  validate :validate_optional_services

  def image_urls
    return [] if room_url.blank?

    room_url
      .to_s
      .split(/\r?\n|,/)
      .map(&:strip)
      .reject(&:blank?)
      .select { |value| valid_http_url?(value) }
  end

  private

  FORBIDDEN_TEXT_CHARS_REGEX = /[<>]/.freeze

  def valid_http_url?(value)
    uri = URI.parse(value.to_s)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end

  def disallow_angle_brackets_in_text_fields
    {
      name: name,
      description: description,
      room_url: room_url
    }.each do |attr, value|
      next if value.blank?
      next unless value.to_s.match?(FORBIDDEN_TEXT_CHARS_REGEX)

      errors.add(attr, "ne doit pas contenir < ou >")
    end
  end

  def normalize_optional_services
    raw = optional_services
    raw = raw.values if raw.is_a?(Hash)
    raw = [] if raw.nil?

    normalized = []

    Array(raw).each do |entry|
      next unless entry.is_a?(Hash)

      name = (entry["name"] || entry[:name]).to_s.strip
      price_cents = entry["price_cents"] || entry[:price_cents]
      price_eur = entry["price_eur"] || entry[:price_eur]

      if price_cents.blank? && price_eur.present?
        begin
          price_decimal = BigDecimal(price_eur.to_s.tr(",", "."))
          price_cents = (price_decimal * 100).round(0).to_i
        rescue ArgumentError
          price_cents = "__invalid__"
        end
      end

      next if name.blank? && (price_cents.blank? || price_cents == "__invalid__")

      normalized << {
        "name" => name.presence,
        "price_cents" => price_cents,
        "currency" => "EUR"
      }
    end

    self.optional_services = normalized
  end

  def validate_optional_services
    services = Array(optional_services)

    if services.size > 5
      errors.add(:optional_services, "maximum 5")
      return
    end

    services.each do |entry|
      next unless entry.is_a?(Hash)

      name = entry["name"].to_s.strip
      price_cents = entry["price_cents"]

      if name.blank?
        errors.add(:optional_services, "nom manquant")
        next
      end

      if name.match?(FORBIDDEN_TEXT_CHARS_REGEX)
        errors.add(:optional_services, "ne doit pas contenir < ou >")
        next
      end

      if price_cents == "__invalid__"
        errors.add(:optional_services, "prix invalide")
        next
      end

      if price_cents.blank?
        errors.add(:optional_services, "prix manquant")
        next
      end

      unless price_cents.is_a?(Integer)
        errors.add(:optional_services, "prix invalide")
        next
      end

      if price_cents.negative?
        errors.add(:optional_services, "prix invalide")
      end
    end
  end

  def mvp_room_limit
    return unless Room.count >= 2

    errors.add(:base, "MVP limit reached: maximum 2 rooms")
  end

  def validate_photos
    return unless photos.attached?

    allowed_types = %w[image/jpeg image/png image/gif]

    photos.each do |photo|
      content_type = photo.blob.content_type.to_s

      unless allowed_types.include?(content_type)
        errors.add(:photos, :invalid_content_type)
      end

      if photo.blob.byte_size > 3.megabytes
        errors.add(:photos, :too_large)
      end
    end
  end
end

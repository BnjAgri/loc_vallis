module ApplicationHelper
	def stars_for_rating(rating, out_of: 5)
		rounded = rating.to_f.round

		safe_join(
			(1..out_of).map do |i|
				klass = i <= rounded ? "fa-solid fa-star" : "fa-regular fa-star"
				content_tag(:i, "", class: klass, aria: { hidden: true })
			end,
			""
		)
	end

	def format_price_euros(cents)
		return "—" if cents.nil?

		number_to_currency(cents.to_i / 100.0, unit: "€", format: "%n %u", precision: 2)
	end

	def format_price(cents, currency: "EUR")
		return "—" if cents.nil?

		code = currency.to_s.upcase
		if code == "EUR"
			number_to_currency(cents.to_i / 100.0, unit: "€", format: "%n %u", precision: 2)
		else
			number_to_currency(cents.to_i / 100.0, unit: "#{code} ", format: "%u%n", precision: 2)
		end
	end

	def booking_status_badge_class(status)
		case status.to_s
		when "requested"
			"text-bg-secondary"
		when "approved_pending_payment"
			"text-bg-warning"
		when "confirmed_paid"
			"text-bg-success"
		when "declined", "canceled", "expired"
			"text-bg-danger"
		when "refunded"
			"text-bg-info"
		else
			"text-bg-light"
		end
	end

	def booking_status_label(status)
		key = "bookings.statuses.#{status}"
		I18n.t(key, default: status.to_s.tr("_", " "))
	end
end

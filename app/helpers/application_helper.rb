module ApplicationHelper
	# Switch locale while preserving the current path (and query string).
	# We rewrite the URL instead of using `url_for(locale: ...)` because some
	# routes (notably Devise) are ambiguous between :user and :owner and Rails may
	# pick the first matching route.
	def switch_locale_path(target_locale)
		fullpath = request.fullpath.to_s
		path, query = fullpath.split("?", 2)

		segments = path.split("/")
		available = I18n.available_locales.map(&:to_s)

		# Remove any existing locale prefix.
		segments.delete_at(1) if segments[1].present? && available.include?(segments[1])

		# Add locale prefix unless it's the default locale (which we keep unprefixed).
		target = target_locale&.to_sym
		if target.present? && target != I18n.default_locale
			segments.insert(1, target.to_s)
		end

		new_path = segments.join("/")
		new_path = "/" if new_path.blank?

		query.present? ? "#{new_path}?#{query}" : new_path
	end

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
		when "completed"
			"text-bg-light text-muted border"
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

	def booking_effective_status(booking)
		return booking.status.to_s if booking.nil?

		status = booking.status.to_s
		return status unless status == "confirmed_paid"
		return status if booking.end_date.blank?

		Date.current >= booking.end_date ? "completed" : status
	end

	def sortable_table_header(label, sort:, current_sort:, current_direction:, reset_page_param: nil)
		next_direction = (current_sort.to_s == sort.to_s && current_direction.to_s == "asc") ? "desc" : "asc"

		overrides = { sort: sort, direction: next_direction }
		overrides[reset_page_param] = 1 if reset_page_param.present?

		link_to label, url_for(overrides), class: "text-decoration-none"
	end
end

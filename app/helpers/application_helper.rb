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
end

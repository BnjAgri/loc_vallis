module SeoHelper
  DEFAULT_OG_IMAGE_PATH = "/icons/icon-512.png".freeze

  def seo_title
    return content_for(:title) if content_for?(:title)

    t("app.title")
  end

  def seo_description
    return strip_tags(content_for(:meta_description).to_s).squish if content_for?(:meta_description)

    I18n.t("app.meta_description", default: "")
  end

  def seo_canonical_url
    return content_for(:canonical_url) if content_for?(:canonical_url)

    url = request.base_url + request.path
    url.end_with?("/") && url != request.base_url + "/" ? url.chomp("/") : url
  end

  def seo_og_type
    return content_for(:og_type) if content_for?(:og_type)

    "website"
  end

  def seo_og_image_url
    override = content_for?(:og_image_url) ? content_for(:og_image_url).to_s.strip : ""
    return override if override.present?

    request.base_url + DEFAULT_OG_IMAGE_PATH
  end

  def seo_robots
    return content_for(:robots) if content_for?(:robots)

    return "noindex,nofollow" if controller_path.start_with?("admin/")
    return "noindex,nofollow" if %w[unified_sessions profiles].include?(controller_name)

    "index,follow"
  end

  def seo_hreflang_links
    return "" unless %w[fr en].include?(I18n.locale.to_s)
    return "" if controller_path.start_with?("admin/")

    fr = url_for(request.path_parameters.merge(locale: "fr"))
    en = url_for(request.path_parameters.merge(locale: "en"))

    safe_join(
      [
        tag.link(rel: "alternate", hreflang: "fr", href: fr),
        tag.link(rel: "alternate", hreflang: "en", href: en)
      ],
      "\n"
    )
  rescue ActionController::UrlGenerationError
    ""
  end
end

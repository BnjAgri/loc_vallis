# frozen_string_literal: true

class SitemapsController < ApplicationController
  def show
    url_options = url_options_from_base

    entries = []

    %w[fr en].each do |locale|
      entries << { loc: root_url(locale:, **url_options), changefreq: "weekly", priority: "1.0" }
      entries << { loc: rooms_url(locale:, **url_options), changefreq: "weekly", priority: "0.9" }
      entries << { loc: articles_url(locale:, **url_options), changefreq: "weekly", priority: "0.7" }
      entries << { loc: legal_url(locale:, **url_options), changefreq: "yearly", priority: "0.2" }
      entries << { loc: cgv_url(locale:, **url_options), changefreq: "yearly", priority: "0.2" }

      Room.find_each do |room|
        entries << {
          loc: room_url(room, locale:, **url_options),
          lastmod: room.updated_at&.to_date,
          changefreq: "weekly",
          priority: "0.8"
        }
      end

      Article.find_each do |article|
        entries << {
          loc: article_url(article, locale:, **url_options),
          lastmod: article.updated_at&.to_date,
          changefreq: "monthly",
          priority: "0.6"
        }
      end
    end

    @entries = entries
    render layout: false
  end

  private

  def url_options_from_base
    base = ENV.fetch("APP_BASE_URL", request.base_url)
    uri = URI.parse(base)

    options = { host: uri.host, protocol: uri.scheme }
    options[:port] = uri.port if uri.port && ![80, 443].include?(uri.port)
    options
  rescue URI::InvalidURIError
    { host: request.host, protocol: request.protocol }
  end
end

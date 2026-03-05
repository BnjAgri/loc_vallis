require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module LocVallis
  class Application < Rails::Application
    config.action_controller.raise_on_missing_callback_actions = false if Rails.version >= "7.1.0"
    config.generators do |generate|
      generate.assets false
      generate.helper false
      generate.test_framework :test_unit, fixture: false
    end
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Internationalization configuration
    config.i18n.default_locale = :fr
    config.i18n.available_locales = [:fr, :en, :es]
    config.i18n.fallbacks = true

    # Single-owner setup.
    # If PRIMARY_OWNER_EMAIL is set, the app enforces that the (single) Owner email matches it.
    #
    # Template default:
    # - development/test: owner@locvallis.demo
    # - production: no default (set PRIMARY_OWNER_EMAIL per client deployment)
    config.x.primary_owner_email =
      if ENV["PRIMARY_OWNER_EMAIL"].to_s.strip.present?
        ENV.fetch("PRIMARY_OWNER_EMAIL")
      elsif Rails.env.production?
        nil
      else
        "owner@locvallis.demo"
      end
  end
end

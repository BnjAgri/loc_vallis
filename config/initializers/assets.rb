# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Font Awesome (font-awesome-sass) ships fonts under assets/fonts.
if (spec = Gem.loaded_specs["font-awesome-sass"])
	Rails.application.config.assets.paths << spec.full_gem_path + "/assets/fonts"
	Rails.application.config.assets.precompile += %w[
		font-awesome/fa-solid-900.woff2
		font-awesome/fa-solid-900.ttf
		font-awesome/fa-regular-400.woff2
		font-awesome/fa-regular-400.ttf
		font-awesome/fa-brands-400.woff2
		font-awesome/fa-brands-400.ttf
	]
end

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )
Rails.application.config.assets.precompile += %w(bootstrap.min.js popper.js)

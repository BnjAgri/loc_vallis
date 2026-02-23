# frozen_string_literal: true

class UpdateDefaultHostPageImageUrl < ActiveRecord::Migration[7.1]
  OLD_URL = "https://static.mediapart.fr/etmagine/article_google_discover/files/2024/10/14/portrait-de-ric-zemmour-avril-2022.jpg"
  NEW_URL = "https://res.cloudinary.com/du8dsc7cg/image/upload/v1771866361/IMG_0938_xe3zs6.jpg"

  def up
    execute <<~SQL.squish
      UPDATE host_pages
      SET image_url = #{connection.quote(NEW_URL)}
      WHERE image_url = #{connection.quote(OLD_URL)}
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE host_pages
      SET image_url = #{connection.quote(OLD_URL)}
      WHERE image_url = #{connection.quote(NEW_URL)}
    SQL
  end
end

class CreateHostPages < ActiveRecord::Migration[7.1]
  def change
    create_table :host_pages do |t|
      t.string :title
      t.text :content
      t.string :image_url

      t.timestamps
    end
  end
end

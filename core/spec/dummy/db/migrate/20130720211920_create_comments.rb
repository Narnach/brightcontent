class CreateComments < ActiveRecord::Migration[4.2]
  def change
    create_table :comments do |t|
      t.text :text
      t.integer :blog_id

      t.timestamps
    end
    add_index :comments, :blog_id
  end
end

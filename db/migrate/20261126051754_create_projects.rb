class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false, limit: 80
      t.text :description

      t.timestamps
    end

    add_index :projects, "user_id, lower(name)", unique: true, name: "index_projects_on_user_and_lower_name"
  end
end

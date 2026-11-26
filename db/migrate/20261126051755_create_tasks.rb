class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :project, null: false, foreign_key: true
      t.string :title, null: false, limit: 140
      t.text :notes
      t.date :due_on
      t.integer :priority, null: false, default: 1
      t.datetime :completed_at

      t.timestamps
    end

    add_index :tasks, %i[project_id completed_at]
    add_check_constraint :tasks, "priority IN (0, 1, 2)", name: "tasks_priority_range"
  end
end

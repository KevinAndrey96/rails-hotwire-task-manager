class Project < ApplicationRecord
  belongs_to :user
  has_many :tasks, dependent: :destroy

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, length: { maximum: 80 },
    uniqueness: { scope: :user_id, case_sensitive: false }
  validates :description, length: { maximum: 500 }

  broadcasts_refreshes

  # COUNT(column) skips NULLs, so tasks_done counts only completed tasks in the same pass.
  scope :with_task_counts, -> {
    left_joins(:tasks)
      .group(:id)
      .select("projects.*, COUNT(tasks.id) AS tasks_total, COUNT(tasks.completed_at) AS tasks_done")
  }

  def task_counts
    { total: tasks.count, done: tasks.completed.count, overdue: tasks.overdue.count }
  end

  def progress
    counts = task_counts
    return 0 if counts[:total].zero?

    (counts[:done] * 100.0 / counts[:total]).round
  end
end

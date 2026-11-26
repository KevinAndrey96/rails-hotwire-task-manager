class Task < ApplicationRecord
  FILTERS = %w[all pending completed overdue].freeze

  belongs_to :project

  enum :priority, { low: 0, normal: 1, high: 2 }, default: :normal, validate: true

  normalizes :title, with: ->(title) { title.squish }

  validates :title, presence: true, length: { maximum: 140 }
  validates :notes, length: { maximum: 2_000 }

  broadcasts_refreshes_to :project

  scope :pending, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :overdue, ->(today = Date.current) { pending.where(due_on: ...today) }

  # Pending first, then the most urgent: higher priority, earliest due date, undated last.
  scope :in_display_order, -> {
    order(Arel.sql("CASE WHEN tasks.completed_at IS NULL THEN 0 ELSE 1 END"))
      .order(priority: :desc)
      .order(Arel.sql("CASE WHEN tasks.due_on IS NULL THEN 1 ELSE 0 END"), :due_on, :created_at)
  }

  def self.filtered(filter)
    case filter
    when "pending" then pending
    when "completed" then completed
    when "overdue" then overdue
    else all
    end
  end

  def completed?
    completed_at.present?
  end

  def overdue?(today = Date.current)
    !completed? && due_on.present? && due_on < today
  end

  def toggle_completion!
    update!(completed_at: completed? ? nil : Time.current)
  end
end

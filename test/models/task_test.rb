require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "requires a title and squishes whitespace" do
    task = projects(:launch).tasks.build(title: "   ")
    assert_not task.valid?
    assert task.errors.added?(:title, :blank)

    task.title = "  Revisar   contrato  "
    assert task.valid?
    assert_equal "Revisar contrato", task.title
  end

  test "limits title and notes length" do
    task = projects(:launch).tasks.build(title: "x" * 141, notes: "y" * 2_001)
    assert_not task.valid?
    assert task.errors.added?(:title, :too_long, count: 140)
    assert task.errors.added?(:notes, :too_long, count: 2_000)
  end

  test "defaults to normal priority and rejects unknown priorities" do
    assert_predicate projects(:launch).tasks.build(title: "Nueva"), :normal?

    task = projects(:launch).tasks.build(title: "Nueva", priority: "urgent")
    assert_not task.valid?
    assert task.errors.key?(:priority)
  end

  test "pending, completed and overdue scopes" do
    launch = projects(:launch).tasks

    assert_equal ids(:copy, :overdue_dns, :someday).sort, launch.pending.ids.sort
    assert_equal ids(:published_logo), launch.completed.ids
    assert_equal ids(:overdue_dns), launch.overdue.ids
    assert_empty launch.overdue(Date.current - 10)
  end

  test "display order puts pending first, then priority, then earliest due date" do
    assert_equal ids(:overdue_dns, :someday, :copy, :published_logo), projects(:launch).tasks.in_display_order.ids
  end

  test "filtered falls back to every task for unknown filters" do
    launch = projects(:launch).tasks

    assert_equal 4, launch.filtered("anything").count
    assert_equal 1, launch.filtered("completed").count
    assert_equal 1, launch.filtered("overdue").count
    assert_equal 3, launch.filtered("pending").count
  end

  test "overdue only applies to pending tasks with a past due date" do
    assert tasks(:overdue_dns).overdue?
    assert_not tasks(:copy).overdue?
    assert_not tasks(:someday).overdue?
    assert_not tasks(:copy).overdue?(Date.current + 2)
    assert tasks(:copy).overdue?(Date.current + 4)
  end

  test "toggle completion marks and reopens a task" do
    task = tasks(:copy)

    task.toggle_completion!
    assert_predicate task.reload, :completed?

    task.toggle_completion!
    assert_not_predicate task.reload, :completed?
  end

  test "changes broadcast a page refresh to the project stream" do
    assert_turbo_stream_broadcasts projects(:launch) do
      perform_enqueued_jobs { tasks(:copy).toggle_completion! }
    end
  end

  private
    def ids(*names)
      names.map { |name| tasks(name).id }
    end
end

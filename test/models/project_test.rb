require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "requires a name and squishes whitespace" do
    project = users(:one).projects.build(name: "  ")
    assert_not project.valid?

    project.name = "  Mudanza   de oficina "
    assert project.valid?
    assert_equal "Mudanza de oficina", project.name
  end

  test "names are unique per user regardless of case" do
    duplicate = users(:one).projects.build(name: "LANZAMIENTO WEB")
    assert_not duplicate.valid?
    assert duplicate.errors.added?(:name, :taken, value: "LANZAMIENTO WEB")

    assert users(:two).projects.build(name: "Lanzamiento web").valid?
  end

  test "the database also enforces case-insensitive uniqueness" do
    assert_raises ActiveRecord::RecordNotUnique do
      Project.insert_all!([ { user_id: users(:one).id, name: "lanzamiento WEB", created_at: Time.current, updated_at: Time.current } ])
    end
  end

  test "with_task_counts aggregates totals and completed tasks in one query" do
    counts = users(:one).projects.with_task_counts.index_by(&:name)

    assert_equal [ 4, 1 ], [ counts["Lanzamiento web"].tasks_total, counts["Lanzamiento web"].tasks_done ]
    assert_equal [ 0, 0 ], [ counts["Pendientes de la casa"].tasks_total, counts["Pendientes de la casa"].tasks_done ]
  end

  test "task_counts reports totals, completed and overdue tasks" do
    assert_equal({ total: 4, done: 1, overdue: 1 }, projects(:launch).task_counts)
  end

  test "progress is the rounded share of completed tasks" do
    assert_equal 25, projects(:launch).progress
    assert_equal 0, projects(:errands).progress
  end

  test "destroying a project removes its tasks" do
    assert_difference "Task.count", -4 do
      projects(:launch).destroy
    end
  end
end

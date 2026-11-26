require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:launch)
    @task = tasks(:copy)
    sign_in_as users(:one)
  end

  test "requires authentication" do
    sign_out

    post project_tasks_path(@project), params: { task: { title: "Nada" } }

    assert_redirected_to new_session_path
  end

  test "create responds with turbo streams for the board, form and flash" do
    assert_difference "@project.tasks.count", 1 do
      post project_tasks_path(@project), params: { filter: "pending", task: { title: "Comprar dominio", priority: "high", due_on: Date.current + 1 } },
        as: :turbo_stream
    end

    assert_response :success
    assert_turbo_stream action: :replace, target: dom_id(@project, :board) do
      assert_select ".filter.is-active", "Pendientes"
      assert_select ".task-title", "Comprar dominio"
    end
    assert_turbo_stream action: :replace, target: "new_task"
    assert_turbo_stream action: :update, target: "flash"
    assert_predicate Task.order(:id).last, :high?
  end

  test "create with invalid data re-renders the form" do
    assert_no_difference "Task.count" do
      post project_tasks_path(@project), params: { task: { title: "" } }, as: :turbo_stream
    end

    assert_turbo_stream status: :unprocessable_content, action: :replace, target: "new_task" do
      assert_select ".form-errors"
    end
  end

  test "create falls back to a redirect without turbo" do
    post project_tasks_path(@project), params: { filter: "overdue", task: { title: "Sin Turbo" } }

    assert_redirected_to project_path(@project, filter: "overdue")
  end

  test "create broadcasts a refresh to other viewers" do
    assert_turbo_stream_broadcasts @project do
      perform_enqueued_jobs do
        post project_tasks_path(@project), params: { task: { title: "Tiempo real" } }, as: :turbo_stream
      end
    end
  end

  test "edit renders the inline form inside the task frame" do
    get edit_project_task_path(@project, @task), headers: { "Turbo-Frame" => dom_id(@task) }

    assert_response :success
    assert_select "turbo-frame##{dom_id(@task)} form textarea[name='task[notes]']"
  end

  test "update" do
    patch project_task_path(@project, @task), params: { task: { title: "Textos finales", notes: "Revisar con marketing" } }, as: :turbo_stream

    assert_response :success
    assert_turbo_stream action: :replace, target: dom_id(@project, :board)
    assert_equal "Textos finales", @task.reload.title
  end

  test "update with invalid data re-renders the edit form" do
    patch project_task_path(@project, @task), params: { task: { title: "", priority: "urgent" } }

    assert_response :unprocessable_content
    assert_select ".form-errors li", 2
  end

  test "toggle completes and reopens a task" do
    patch toggle_project_task_path(@project, @task), as: :turbo_stream
    assert_predicate @task.reload, :completed?

    patch toggle_project_task_path(@project, @task), as: :turbo_stream
    assert_not_predicate @task.reload, :completed?
  end

  test "destroy" do
    assert_difference "Task.count", -1 do
      delete project_task_path(@project, @task), as: :turbo_stream
    end

    assert_turbo_stream action: :replace, target: dom_id(@project, :board)
  end

  test "tasks from other users' projects are not found" do
    foreign = tasks(:foreign)

    patch toggle_project_task_path(foreign.project, foreign), as: :turbo_stream
    assert_response :not_found

    patch toggle_project_task_path(@project, foreign), as: :turbo_stream
    assert_response :not_found
    assert_not_predicate foreign.reload, :completed?
  end
end

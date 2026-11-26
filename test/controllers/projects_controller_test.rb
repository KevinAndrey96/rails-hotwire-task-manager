require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:launch)
    sign_in_as users(:one)
  end

  test "requires authentication" do
    sign_out

    get projects_path

    assert_redirected_to new_session_path
  end

  test "index lists only the current user's projects with progress" do
    get root_path

    assert_response :success
    assert_select ".project-card", 2
    assert_select ".project-card h2", text: "Proyecto ajeno", count: 0
    assert_select ".project-card .meta", text: "1 de 4 tareas completadas"
  end

  test "show renders the board and subscribes to project refreshes" do
    get project_path(@project)

    assert_response :success
    assert_select "turbo-cable-stream-source", 1
    assert_select "##{dom_id(@project, :board)} .task", 4
  end

  test "show applies a filter and ignores unknown ones" do
    get project_path(@project, filter: "overdue")
    assert_select ".task", 1
    assert_select ".filter.is-active", "Vencidas"

    get project_path(@project, filter: "drop table")
    assert_select ".task", 4
    assert_select ".filter.is-active", "Todas"
  end

  test "other users' projects are not found" do
    get project_path(projects(:strangers))

    assert_response :not_found
  end

  test "create" do
    assert_difference "users(:one).projects.count", 1 do
      post projects_path, params: { project: { name: "  Mudanza  ", description: "Oficina nueva" } }
    end

    project = Project.order(:id).last
    assert_redirected_to project_path(project)
    assert_equal "Mudanza", project.name
  end

  test "create renders errors for invalid data" do
    assert_no_difference "Project.count" do
      post projects_path, params: { project: { name: "lanzamiento web" } }
    end

    assert_response :unprocessable_content
    assert_select ".form-errors li", /ya está en uso/
  end

  test "update" do
    patch project_path(@project), params: { project: { name: "Lanzamiento v2" } }

    assert_redirected_to project_path(@project)
    assert_equal "Lanzamiento v2", @project.reload.name
  end

  test "cannot update another user's project" do
    patch project_path(projects(:strangers)), params: { project: { name: "Robado" } }

    assert_response :not_found
    assert_equal "Proyecto ajeno", projects(:strangers).reload.name
  end

  test "destroy removes the project and its tasks" do
    assert_difference "Project.count" => -1, "Task.count" => -4 do
      delete project_path(@project)
    end

    assert_redirected_to projects_path
  end
end

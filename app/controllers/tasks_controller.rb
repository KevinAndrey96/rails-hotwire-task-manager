class TasksController < ApplicationController
  before_action :set_project
  before_action :set_task, only: %i[edit update destroy toggle]
  before_action :set_filter

  def create
    @task = @project.tasks.build(task_params)

    if @task.save
      respond_with_board(notice: t(".created"))
    else
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_content }
        format.html { redirect_to project_path(@project, filter: @filter), alert: @task.errors.full_messages.to_sentence }
      end
    end
  end

  def edit
  end

  def update
    if @task.update(task_params)
      respond_with_board(notice: t(".updated"))
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @task.destroy!
    respond_with_board(notice: t(".destroyed"))
  end

  def toggle
    @task.toggle_completion!
    respond_with_board
  end

  private
    def set_project
      @project = Current.user.projects.find(params.expect(:project_id))
    end

    def set_task
      @task = @project.tasks.find(params.expect(:id))
    end

    def set_filter
      @filter = Task::FILTERS.include?(params[:filter]) ? params[:filter] : "all"
    end

    def task_params
      params.expect(task: %i[title notes due_on priority])
    end

    def respond_with_board(notice: nil)
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = notice
          render :board
        end
        format.html { redirect_to project_path(@project, filter: @filter), notice: notice, status: :see_other }
      end
    end
end

class ProjectsController < ApplicationController
  before_action :set_project, only: %i[show edit update destroy]

  def index
    @projects = Current.user.projects.with_task_counts.order(:name)
  end

  def show
    @filter = Task::FILTERS.include?(params[:filter]) ? params[:filter] : "all"
    @task = Task.new
  end

  def new
    @project = Current.user.projects.build
  end

  def create
    @project = Current.user.projects.build(project_params)

    if @project.save
      redirect_to @project, notice: t(".created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: t(".updated"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @project.destroy!
    redirect_to projects_path, notice: t(".destroyed"), status: :see_other
  end

  private
    def set_project
      @project = Current.user.projects.find(params.expect(:id))
    end

    def project_params
      params.expect(project: %i[name description])
    end
end

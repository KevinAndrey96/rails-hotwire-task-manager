module TasksHelper
  def priority_label(task)
    t("tasks.priorities.#{task.priority}")
  end

  def priority_options
    Task.priorities.keys.map { |priority| [ t("tasks.priorities.#{priority}"), priority ] }
  end
end

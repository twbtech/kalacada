class DashboardData
  attr_accessor :current_page

  def initialize(filter)
    @params = filter.to_sanitized_hash

    # sanitize current page number
    self.current_page = (params[:page].to_i < 1) ? 1 : [params[:page].to_i, count_pages].min
  end

  def word_stats
    @word_stats ||= load_word_stats
  end

  def projects_stats
    @projects_stats ||= load_projects_stats
  end

  def tasks_stats
    @tasks_stats ||= load_tasks_stats
  end

  def capacity_stats
    @capacity_stats ||= load_capacity_stats
  end

  def projects
    @projects ||= load_projects
  end

  def count_pages
    @count_pages ||= projects_pages
  end

  def load_projects
    Solas::Project.projects(params.slice(:source_lang, :target_lang, :partner, :project_manager, :from_date, :to_date), current_page).to_a
  end

  private

  attr_reader :params

  def load_capacity_stats
    [
      { label: 'active translators',   value: Solas::Translator.active_count(params[:source_lang], params[:target_lang]) },
      { label: 'inactive translators', value: Solas::Translator.inactive_count(params[:source_lang], params[:target_lang]) },
      { label: 'total',                value: Solas::Translator.count(params[:source_lang], params[:target_lang]) }
    ]
  end

  def load_word_stats
    [
      { label: 'words completed',   value: Solas::Word.completed_count(params.slice(:source_lang, :target_lang, :partner, :project_manager, :from_date, :to_date)) },
      { label: 'words in progress', value: Solas::Word.in_progress_count(params.slice(:source_lang, :target_lang, :partner, :project_manager, :from_date, :to_date)) },
      { label: 'words unclaimed',   value: Solas::Word.not_claimed_yet_count(params.slice(:source_lang, :target_lang, :partner, :project_manager, :from_date, :to_date)) },
      { label: 'words overdue',     value: Solas::Word.overdue_count(params.slice(:source_lang, :target_lang, :partner, :project_manager, :from_date, :to_date)) }
    ]
  end

  def load_projects_stats
    [
      { label: 'completed',   value: Solas::Project.completed_count(params.slice(:source_lang, :target_lang, :partner, :project_manager, :from_date, :to_date)) },
      { label: 'in progress', value: Solas::Project.in_progress_count(params.slice(:source_lang, :target_lang, :partner, :project_manager, :from_date, :to_date)) },
      { label: 'unclaimed',   value: Solas::Project.not_claimed_yet_count(params.slice(:source_lang, :target_lang, :partner, :project_manager, :from_date, :to_date)) },
      { label: 'overdue',     value: Solas::Project.overdue_count(params.slice(:source_lang, :target_lang, :partner, :project_manager, :from_date, :to_date)) }
    ]
  end

  def load_tasks_stats
    [
      { label: 'completed',   value: Solas::Task.completed_count(params.slice(:source_lang, :target_lang, :partner, :project_manager, :from_date, :to_date)) },
      { label: 'in progress', value: Solas::Task.in_progress_count(params.slice(:source_lang, :target_lang, :partner, :project_manager, :from_date, :to_date)) },
      { label: 'unclaimed',   value: Solas::Task.not_claimed_yet_count(params.slice(:source_lang, :target_lang, :partner, :project_manager, :from_date, :to_date)) },
      { label: 'overdue',     value: Solas::Task.overdue_count(params.slice(:source_lang, :target_lang, :partner, :project_manager, :from_date, :to_date)) }
    ]
  end

  def projects_pages
    projects_count = Solas::Project.count_with_language_pairs(params.slice(:source_lang, :target_lang, :partner, :project_manager, :from_date, :to_date))

    if projects_count % 20 == 0
      projects_count / 20
    else
      projects_count / 20 + 1
    end
  end
end

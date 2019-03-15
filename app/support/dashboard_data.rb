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

  def package_status
    @package_status ||= load_package_status
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

  def load_package_status
    if params[:partner]
      package = Solas::Package.find_package(params[:partner])

      if package.present?
        package[:name] = Solas::Package.find_partners_name(params[:partner])

        package[:words_remaining] = Solas::Package.count_remaining_words params[:partner],
                                                                         package[:word_count_limit],
                                                                         package[:member_start_date],
                                                                         package[:member_expire_date]
        package[:show_warning] = if package[:words_remaining] <= 0
                                   [:no_remaining_words]

                                 elsif package[:member_expire_date] < Time.zone.today
                                   [:package_expired]

                                 elsif package[:words_remaining] <= package[:word_count_limit] * 0.1 && (package[:member_expire_date] + 1.day) - 1.month < Time.zone.now
                                   [:few_remaining_words, :month_to_expire]

                                 elsif package[:words_remaining] <= package[:word_count_limit] * 0.1
                                   [:few_remaining_words]

                                 elsif (package[:member_expire_date] + 1.day) - 1.month < Time.zone.now
                                   [:month_to_expire]
                                 end
      end

      package
    end
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

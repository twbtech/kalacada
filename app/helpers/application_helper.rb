module ApplicationHelper
  def source_language_options_for_select(selected_id = nil)
    languages = [['Any source language', nil]] + Solas::Language.source_languages(logged_in_user).map { |p| [p.name, p.id] }
    options_for_select(languages, selected_id)
  end

  def target_language_options_for_select(selected_id = nil)
    languages = [['Any target language', nil]] + Solas::Language.target_languages(logged_in_user).map { |p| [p.name, p.id] }
    options_for_select(languages, selected_id)
  end

  def most_translated_language_pair_options_for_select(selected_ids = nil)
    language_pairs = Solas::Language.most_translated_pairs(Forecasting::Generator::MOST_TRANSLATED_LANGUAGE_PAIRS_COUNT).map do |p|
      ["#{p[:source_lang_name]} - #{p[:target_lang_name]}", "#{p[:source_lang_id]}_#{p[:target_lang_id]}"]
    end

    options = [['Any languages', nil]] + language_pairs
    options_for_select(options, selected_ids)
  end

  def partner_options_for_select
    partners = [['Any partner', nil]] + Solas::Partner.all.map { |p| [p.name, p.id] }
    options_for_select(partners)
  end

  def project_manager_options_for_select
    managers = [['Any project manager', nil]] + Solas::ProjectManager.all.map { |p| [p.name, p.id] }
    options_for_select(managers)
  end

  def paging(page_actual, maxp)
    x = 3

    pg = (((page_actual - x)..(page_actual + x)).to_a & (1..maxp).to_a).to_a

    if pg.present?
      pg = [nil] + pg if pg.min > 2
      pg = [1] + pg   if pg.compact.min > 1
      pg += [nil]     if pg.compact.max < maxp - 1
      pg += [maxp]    if pg.compact.max < maxp

      pg.map do |p|
        klass = (p == page_actual) ? 'btn-default' : 'btn-primary'

        if p
          link_to p.to_s, projects_dashboards_path(@filter.to_sanitized_hash.merge(page: p)), remote: true, class: "btn #{klass} margin-pagging"
        else
          ' . . . '
        end
      end.join.html_safe
    end
  end

  def lt(datetime, options = {})
    l(datetime, options) if datetime
  end

  def format_number(value)
    number_with_delimiter(value, delimiter: ',')
  end

  def spinner
    '<div class="spinning"><div class="loader"><svg class="circular" viewBox="25 25 50 50"><circle class="path" cx="50" cy="50" r="20" fill="none" stroke-width="4" stroke-miterlimit="10"/></svg></div></div>'.html_safe
  end
end

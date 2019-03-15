require 'spec_helper'

describe DashboardData do
  let(:logged_in_user) do
    allow_any_instance_of(Solas::User).to receive(:load_role).and_return(:admin)
    Solas::User.new id: 3
  end

  let(:filter) do
    DashboardFilter.new(
      {
        source_lang:     '1; SQL INJECTION STATEMENT',
        target_lang:     '2; SQL INJECTION STATEMENT',
        partner:         '3; SQL INJECTION STATEMENT',
        project_manager: '4; SQL INJECTION STATEMENT',
        from_date:       '01.10.2018',
        to_date:         '08.10.2018',
        page:            '7; SQL INJECTION STATEMENT'
      },
      logged_in_user
    )
  end

  let(:data) { DashboardData.new(filter) }

  before do
    allow(Solas::Translator).to receive(:active_count).and_return(1)
    allow(Solas::Translator).to receive(:inactive_count).and_return(2)
    allow(Solas::Translator).to receive(:count).and_return(3)

    allow(Solas::Word).to receive(:completed_count).and_return(4)
    allow(Solas::Word).to receive(:in_progress_count).and_return(5)
    allow(Solas::Word).to receive(:not_claimed_yet_count).and_return(6)
    allow(Solas::Word).to receive(:overdue_count).and_return(7)

    allow(Solas::Project).to receive(:completed_count).and_return(8)
    allow(Solas::Project).to receive(:in_progress_count).and_return(9)
    allow(Solas::Project).to receive(:not_claimed_yet_count).and_return(10)
    allow(Solas::Project).to receive(:overdue_count).and_return(11)
    allow(Solas::Project).to receive(:count_with_language_pairs).and_return(38)
    allow(Solas::Project).to receive(:projects).and_return([]) # for the ease we don't return 38 projects in this test

    allow(Solas::Task).to receive(:completed_count).and_return(12)
    allow(Solas::Task).to receive(:in_progress_count).and_return(13)
    allow(Solas::Task).to receive(:not_claimed_yet_count).and_return(14)
    allow(Solas::Task).to receive(:overdue_count).and_return(15)
  end

  it 'should have capacity_stats' do
    expect(data.capacity_stats).to eq(
      [
        { label: 'active translators',   value: 1 },
        { label: 'inactive translators', value: 2 },
        { label: 'total',                value: 3 }
      ]
    )
  end

  it 'should have word_stats' do
    expect(data.word_stats).to eq(
      [
        { label: 'words completed',   value: 4 },
        { label: 'words in progress', value: 5 },
        { label: 'words unclaimed',   value: 6 },
        { label: 'words overdue',     value: 7 }
      ]
    )
  end

  it 'should have projects_stats' do
    expect(data.projects_stats).to eq(
      [
        { label: 'completed',   value: 8 },
        { label: 'in progress', value: 9 },
        { label: 'unclaimed',   value: 10 },
        { label: 'overdue',     value: 11 }
      ]
    )
  end

  it 'should have tasks_stats' do
    expect(data.tasks_stats).to eq(
      [
        { label: 'completed',   value: 12 },
        { label: 'in progress', value: 13 },
        { label: 'unclaimed',   value: 14 },
        { label: 'overdue',     value: 15 }
      ]
    )
  end

  it 'should have projects' do
    expect(data.projects).to eq([])
  end

  it 'should have count_pages' do
    expect(data.count_pages).to eq(2)
  end

  it 'should have current_page' do
    expect(data.current_page).to eq(2)
  end

  describe 'package-related information' do
    start_time = 5.months.ago
    context 'remaining word count is less than 10%' do
      before do
        allow(Solas::Package).to receive(:find_package).and_return(word_count_limit: 6_000, member_name: 'package name', member_expire_date: Date.tomorrow + 2.months, member_start_date: start_time)
        allow(Solas::Package).to receive(:find_partners_name).and_return('partner name')
        allow(Solas::Package).to receive(:count_remaining_words).and_return(500)
      end

      it 'should have package_statuswith show_warning=true' do
        expect(data.package_status).to eq(member_expire_date: Date.tomorrow + 2.months, member_name: 'package name', member_start_date: start_time, name: 'partner name', show_warning: [:few_remaining_words], word_count_limit: 6_000, words_remaining: 500)
      end
    end

    context 'expired time is less then month' do
      before do
        allow(Solas::Package).to receive(:find_package).and_return(word_count_limit: 6_000, member_name: 'package name', member_expire_date: Date.tomorrow + 1.month - 5.days, member_start_date: start_time)
        allow(Solas::Package).to receive(:find_partners_name).and_return('partner name')
        allow(Solas::Package).to receive(:count_remaining_words).and_return(5_000)
      end

      it 'should have package_statuswith show_warning=true' do
        expect(data.package_status).to eq(member_expire_date: Date.tomorrow + 1.month - 5.days, member_name: 'package name', member_start_date: start_time, name: 'partner name', show_warning: [:month_to_expire], word_count_limit: 6_000, words_remaining: 5_000)
      end
    end

    context 'expired time is less then month and remaining word count is less than 10%' do
      before do
        allow(Solas::Package).to receive(:find_package).and_return(word_count_limit: 6_000, member_name: 'package name', member_expire_date: Date.tomorrow + 1.month - 5.days, member_start_date: start_time)
        allow(Solas::Package).to receive(:find_partners_name).and_return('partner name')
        allow(Solas::Package).to receive(:count_remaining_words).and_return(500)
      end

      it 'should have package_statuswith show_warning=true' do
        expect(data.package_status).to eq(member_expire_date: Date.tomorrow + 1.month - 5.days, member_name: 'package name', member_start_date: start_time, name: 'partner name', show_warning: [:few_remaining_words, :month_to_expire], word_count_limit: 6_000, words_remaining: 500)
      end
    end

    context 'remaining word count is 0' do
      before do
        allow(Solas::Package).to receive(:find_package).and_return(word_count_limit: 6_000, member_name: 'package name', member_expire_date: Date.tomorrow + 2.months, member_start_date: start_time)
        allow(Solas::Package).to receive(:find_partners_name).and_return('partner name')
        allow(Solas::Package).to receive(:count_remaining_words).and_return(0)
      end

      it 'should have package_statuswith show_warning=true' do
        expect(data.package_status).to eq(member_expire_date: Date.tomorrow + 2.months, member_name: 'package name', member_start_date: start_time, name: 'partner name', show_warning: [:no_remaining_words], word_count_limit: 6_000, words_remaining: 0)
      end
    end

    context 'time is expired' do
      before do
        allow(Solas::Package).to receive(:find_package).and_return(word_count_limit: 6_000, member_name: 'package name', member_expire_date: Date.yesterday, member_start_date: start_time)
        allow(Solas::Package).to receive(:find_partners_name).and_return('partner name')
        allow(Solas::Package).to receive(:count_remaining_words).and_return(5_000)
      end

      it 'should have package_statuswith show_warning=true' do
        expect(data.package_status).to eq(member_expire_date: Date.yesterday, member_name: 'package name', member_start_date: start_time, name: 'partner name', show_warning: [:package_expired], word_count_limit: 6_000, words_remaining: 5_000)
      end
    end

    context 'expired time and remaining word count is 0' do
      before do
        allow(Solas::Package).to receive(:find_package).and_return(word_count_limit: 6_000, member_name: 'package name', member_expire_date: Date.yesterday, member_start_date: start_time)
        allow(Solas::Package).to receive(:find_partners_name).and_return('partner name')
        allow(Solas::Package).to receive(:count_remaining_words).and_return(0)
      end

      it 'should have package_statuswith show_warning=true' do
        expect(data.package_status).to eq(member_expire_date: Date.yesterday, member_name: 'package name', member_start_date: start_time, name: 'partner name', show_warning: [:no_remaining_words], word_count_limit: 6_000, words_remaining: 0)
      end
    end

    context 'remaining word count is bigger than 10000 and package is valid' do
      before do
        allow(Solas::Package).to receive(:find_package).and_return(word_count_limit: 100_000, member_name: 'package name', member_expire_date: Date.tomorrow + 5.months, member_start_date: start_time)
        allow(Solas::Package).to receive(:find_partners_name).and_return('partner name')
        allow(Solas::Package).to receive(:count_remaining_words).and_return(90_000)
      end

      it 'should have package_status show_warning=false' do
        expect(data.package_status).to eq(member_expire_date: Date.tomorrow + 5.months, member_name: 'package name', member_start_date: start_time, name: 'partner name', show_warning: nil, word_count_limit: 100_000, words_remaining: 90_000)
      end
    end
  end
end

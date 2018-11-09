require 'spec_helper'

describe DashboardData do
  let(:filter) do
    DashboardFilter.new source_lang:     '1; SQL INJECTION STATEMENT',
                        target_lang:     '2; SQL INJECTION STATEMENT',
                        partner:         '3; SQL INJECTION STATEMENT',
                        project_manager: '4; SQL INJECTION STATEMENT',
                        from_date:       '01.10.2018',
                        to_date:         '08.10.2018',
                        page:            '7; SQL INJECTION STATEMENT'
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
    allow(Solas::Project).to receive(:count).and_return(38)
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
end

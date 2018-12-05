require 'spec_helper'

describe Solas::Project do
  shared_examples_for :project_count do |conditions, extra_options = {}|
    before do
      conditions = [conditions, options[:conditions]].map(&:presence).compact.join(' AND ')
      conditions = "WHERE #{conditions}" if conditions.present?

      expect_any_instance_of(Solas::Connection).to receive(:query).with(
        <<-QUERY
            SELECT COUNT(DISTINCT project_id) AS count
            FROM (
              SELECT DISTINCT Tasks.id, Tasks.project_id AS project_id
              FROM Tasks
                JOIN Projects ON Tasks.project_id = Projects.id
                JOIN Organisations ON Projects.organisation_id = Organisations.id
                LEFT JOIN Admins ON Admins.organisation_id = Organisations.id
                LEFT JOIN Users ON Admins.user_id = Users.id
                #{extra_options[:joins]}
              #{conditions}
            ) AS wuc
        QUERY
      ).and_return(
        [
          { 'count' => 123 }
        ]
      )
    end
  end

  shared_examples_for :all_project_counts do
    describe 'self.completed_count' do
      it_should_behave_like :project_count, 'Tasks.`task-status_id` = 4' do
        it 'should execute correct SQL statement and return correct count' do
          expect(Solas::Project.completed_count(params)).to eq 123
        end
      end
    end

    describe 'self.in_progress_count' do
      it_should_behave_like :project_count, 'Tasks.`task-status_id` = 3' do
        it 'should execute correct SQL statement and return correct count' do
          expect(Solas::Project.in_progress_count(params)).to eq 123
        end
      end
    end

    describe 'self.not_claimed_yet_count' do
      it_should_behave_like :project_count, 'Tasks.`task-status_id` < 3' do
        it 'should execute correct SQL statement and return correct count' do
          expect(Solas::Project.not_claimed_yet_count(params)).to eq 123
        end
      end
    end

    describe 'self.overdue_count' do
      it_should_behave_like :project_count, 'Tasks.`task-status_id` <> 4 AND Tasks.deadline < now()' do
        it 'should execute correct SQL statement and return correct count' do
          expect(Solas::Project.overdue_count(params)).to eq 123
        end
      end
    end
  end

  context 'no filters' do
    let(:params)  { {} }
    let(:options) { {} }

    it_should_behave_like :all_project_counts
  end

  context 'only source language filter' do
    let(:params)  { { source_lang: 3 } }
    let(:options) { { conditions: 'Tasks.`language_id-source` = 3' } }

    it_should_behave_like :all_project_counts
  end

  context 'only target language filter' do
    let(:params)  { { target_lang: 4 } }
    let(:options) { { conditions: 'Tasks.`language_id-target` = 4' } }

    it_should_behave_like :all_project_counts
  end

  context 'only partner filter' do
    let(:params)  { { partner: 11 } }
    let(:options) { { conditions: 'Organisations.id = 11' } }

    it_should_behave_like :all_project_counts
  end

  context 'only project manager filter' do
    let(:params)  { { project_manager: 37 } }
    let(:options) { { conditions: 'Users.id = 37' } }

    it_should_behave_like :all_project_counts
  end

  context 'only project from date' do
    let(:params)  { { from_date: Date.new(2018, 10, 1) } }
    let(:options) { { conditions: "Tasks.`created-time` >= '2018-10-01'" } }

    it_should_behave_like :all_project_counts
  end

  context 'only project to date' do
    let(:params)  { { to_date: Date.new(2018, 10, 8) } }
    let(:options) { { conditions: "Tasks.`created-time` <= '2018-10-08'" } }

    it_should_behave_like :all_project_counts
  end

  context 'source and target language, partner and project manager filters' do
    let(:params)  { { source_lang: 3, target_lang: 4, partner: 11, project_manager: 37, from_date: Date.new(2018, 10, 1), to_date: Date.new(2018, 10, 8) } }
    let(:options) { { conditions: "Tasks.`language_id-source` = 3 AND Tasks.`language_id-target` = 4 AND Organisations.id = 11 AND Users.id = 37 AND Tasks.`created-time` >= '2018-10-01' AND Tasks.`created-time` <= '2018-10-08'" } }

    it_should_behave_like :all_project_counts
  end
end

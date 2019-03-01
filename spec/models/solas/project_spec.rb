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
              SELECT DISTINCT tasks_kp.id, tasks_kp.project_id AS project_id
              FROM tasks_kp
                JOIN projects_kp ON tasks_kp.project_id = projects_kp.pid
                JOIN partners_kp ON projects_kp.orgid = partners_kp.kpid
                LEFT JOIN SolasMatch.Admins ON SolasMatch.Admins.organisation_id = partners_kp.kpid
                LEFT JOIN users_kp ON SolasMatch.Admins.user_id = users_kp.kpid
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
      it_should_behave_like :project_count, 'tasks_kp.taskstatusid = 4' do
        it 'should execute correct SQL statement and return correct count' do
          expect(Solas::Project.completed_count(params)).to eq 123
        end
      end
    end

    describe 'self.in_progress_count' do
      it_should_behave_like :project_count, 'tasks_kp.taskstatusid = 3' do
        it 'should execute correct SQL statement and return correct count' do
          expect(Solas::Project.in_progress_count(params)).to eq 123
        end
      end
    end

    describe 'self.not_claimed_yet_count' do
      it_should_behave_like :project_count, 'tasks_kp.taskstatusid < 3' do
        it 'should execute correct SQL statement and return correct count' do
          expect(Solas::Project.not_claimed_yet_count(params)).to eq 123
        end
      end
    end

    describe 'self.overdue_count' do
      it_should_behave_like :project_count, 'tasks_kp.taskstatusid <> 4 AND tasks_kp.deadline < now()' do
        it 'should execute correct SQL statement and return correct count' do
          expect(Solas::Project.overdue_count(params)).to eq 123
        end
      end
    end

    describe 'self.count_with_language_pairs' do
      before do
        cond = ("WHERE #{options[:conditions]}" if options[:conditions].present?)

        expect_any_instance_of(Solas::Connection).to receive(:query).with(
          <<-QUERY
          SELECT COUNT(*) AS count
          FROM (
                    SELECT
          DISTINCT projects_kp.*,
          tasks_kp.langsourceid,
          tasks_kp.langtargetid,
          MIN(tasks_kp.taskstatusid) AS min_status,
          MAX(tasks_kp.taskstatusid) AS max_status,
          MIN(tasks_kp.deadline) AS task_deadline
        FROM tasks_kp
          JOIN projects_kp ON tasks_kp.project_id = projects_kp.pid
          JOIN partners_kp ON projects_kp.orgid = partners_kp.kpid
          LEFT JOIN SolasMatch.Admins ON partners_kp.kpid = SolasMatch.Admins.organisation_id
          LEFT JOIN users_kp ON SolasMatch.Admins.user_id = users_kp.kpid
        #{cond}
        GROUP BY projects_kp.pid, tasks_kp.langsourceid, tasks_kp.langtargetid

          ) AS project_list
        QUERY
        ).and_return(
          [
            { 'count' => 123 }
          ]
        )
      end

      it 'should execute correct SQL statement and return list of projects' do
        expect(Solas::Project.count_with_language_pairs(params)).to be 123
      end
    end

    describe 'self.projects' do
      before do
        cond = ("WHERE #{options[:conditions]}" if options[:conditions].present?)

        expect_any_instance_of(Solas::Connection).to receive(:query).with(
          <<-QUERY
                  SELECT
          DISTINCT projects_kp.*,
          tasks_kp.langsourceid,
          tasks_kp.langtargetid,
          MIN(tasks_kp.taskstatusid) AS min_status,
          MAX(tasks_kp.taskstatusid) AS max_status,
          MIN(tasks_kp.deadline) AS task_deadline
        FROM tasks_kp
          JOIN projects_kp ON tasks_kp.project_id = projects_kp.pid
          JOIN partners_kp ON projects_kp.orgid = partners_kp.kpid
          LEFT JOIN SolasMatch.Admins ON partners_kp.kpid = SolasMatch.Admins.organisation_id
          LEFT JOIN users_kp ON SolasMatch.Admins.user_id = users_kp.kpid
        #{cond}
        GROUP BY projects_kp.pid, tasks_kp.langsourceid, tasks_kp.langtargetid

          LIMIT 20 OFFSET 0
        QUERY
        ).and_return([{}])
      end

      it 'should execute correct SQL statement and return list of projects' do
        result = Solas::Project.projects(params, 1)
        expect(result.length).to be 1
        expect(result.first.class).to be Solas::Project
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
    let(:options) { { conditions: 'tasks_kp.langsourceid = 3' } }

    it_should_behave_like :all_project_counts
  end

  context 'only target language filter' do
    let(:params)  { { target_lang: 4 } }
    let(:options) { { conditions: 'tasks_kp.langtargetid = 4' } }

    it_should_behave_like :all_project_counts
  end

  context 'only partner filter' do
    let(:params)  { { partner: 11 } }
    let(:options) { { conditions: 'partners_kp.kpid = 11' } }

    it_should_behave_like :all_project_counts
  end

  context 'only project manager filter' do
    let(:params)  { { project_manager: 37 } }
    let(:options) { { conditions: 'users_kp.kpid = 37' } }

    it_should_behave_like :all_project_counts
  end

  context 'only project from date' do
    let(:params)  { { from_date: Date.new(2018, 10, 1) } }
    let(:options) { { conditions: "tasks_kp.createdtime >= '2018-10-01'" } }

    it_should_behave_like :all_project_counts
  end

  context 'only project to date' do
    let(:params)  { { to_date: Date.new(2018, 10, 8) } }
    let(:options) { { conditions: "tasks_kp.createdtime <= '2018-10-08'" } }

    it_should_behave_like :all_project_counts
  end

  context 'source and target language, partner and project manager filters' do
    let(:params)  { { source_lang: 3, target_lang: 4, partner: 11, project_manager: 37, from_date: Date.new(2018, 10, 1), to_date: Date.new(2018, 10, 8) } }
    let(:options) { { conditions: "tasks_kp.langsourceid = 3 AND tasks_kp.langtargetid = 4 AND partners_kp.kpid = 11 AND users_kp.kpid = 37 AND tasks_kp.createdtime >= '2018-10-01' AND tasks_kp.createdtime <= '2018-10-08'" } }

    it_should_behave_like :all_project_counts
  end
end

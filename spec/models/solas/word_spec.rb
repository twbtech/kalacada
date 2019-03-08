require 'spec_helper'

describe Solas::Word do
  shared_examples_for :word_count do |conditions, extra_options = {}|
    before do
      conditions = [conditions, options[:conditions]].map(&:presence).compact.join(' AND ')
      conditions = "WHERE #{conditions}" if conditions.present?

      expect_any_instance_of(Solas::Connection).to receive(:query).with(
        <<-QUERY
            SELECT SUM(word_count) AS count
            FROM (
              SELECT DISTINCT tasks_kp.id, tasks_kp.wordcount AS word_count
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

  shared_examples_for :all_word_counts do
    describe 'self.completed_count' do
      before do
        conditions = [options[:conditions]].map(&:presence).compact.join(' AND ')
        conditions = "WHERE #{conditions}" if conditions.present?

        expect_any_instance_of(Solas::Connection).to receive(:query).with(
          <<-QUERY
            SELECT SUM(wuc.wordcount) as count FROM (
              SELECT
                DISTINCT projects_kp.pid,
                MAX(projects_kp.wordcount) AS wordcount,
                tasks_kp.langsourceid,
                tasks_kp.langtargetid,
                MIN(tasks_kp.taskstatusid) AS min_status
              FROM tasks_kp
                JOIN projects_kp ON tasks_kp.project_id = projects_kp.pid
                JOIN partners_kp ON projects_kp.orgid = partners_kp.kpid
                LEFT JOIN SolasMatch.Admins ON partners_kp.kpid = SolasMatch.Admins.organisation_id
                LEFT JOIN users_kp ON SolasMatch.Admins.user_id = users_kp.kpid
              #{conditions}
              GROUP BY projects_kp.pid, tasks_kp.langsourceid, tasks_kp.langtargetid
            ) AS wuc WHERE min_status = 4
          QUERY
        ).and_return(
          [
            { 'count' => 123 }
          ]
        )
      end

      it 'should execute correct SQL statement and return correct count' do
        expect(Solas::Word.completed_count(params)).to eq 123
      end
    end

    describe 'self.uncompleted_count' do
      it_should_behave_like :word_count, 'tasks_kp.taskstatusid <> 4' do
        it 'should execute correct SQL statement and return correct count' do
          expect(Solas::Word.uncompleted_count(params)).to eq 123
        end
      end
    end

    describe 'self.in_progress_count' do
      it_should_behave_like :word_count, 'tasks_kp.taskstatusid = 3' do
        it 'should execute correct SQL statement and return correct count' do
          expect(Solas::Word.in_progress_count(params)).to eq 123
        end
      end
    end

    describe 'self.not_claimed_yet_count' do
      it_should_behave_like :word_count, 'tasks_kp.taskstatusid < 3' do
        it 'should execute correct SQL statement and return correct count' do
          expect(Solas::Word.not_claimed_yet_count(params)).to eq 123
        end
      end
    end

    describe 'self.overdue_count' do
      it_should_behave_like :word_count, 'tasks_kp.taskstatusid <> 4 AND tasks_kp.deadline < now()' do
        it 'should execute correct SQL statement and return correct count' do
          expect(Solas::Word.overdue_count(params)).to eq 123
        end
      end
    end
  end

  context 'no filters' do
    let(:params)  { {} }
    let(:options) { {} }

    it_should_behave_like :all_word_counts
  end

  context 'only source language filter' do
    let(:params)  { { source_lang: 3 } }
    let(:options) { { conditions: 'tasks_kp.langsourceid = 3' } }

    it_should_behave_like :all_word_counts
  end

  context 'only target language filter' do
    let(:params)  { { target_lang: 4 } }
    let(:options) { { conditions: 'tasks_kp.langtargetid = 4' } }

    it_should_behave_like :all_word_counts
  end

  context 'only partner filter' do
    let(:params)  { { partner: 11 } }
    let(:options) { { conditions: 'partners_kp.kpid = 11' } }

    it_should_behave_like :all_word_counts
  end

  context 'only project manager filter' do
    let(:params)  { { project_manager: 37 } }
    let(:options) { { conditions: 'users_kp.kpid = 37' } }

    it_should_behave_like :all_word_counts
  end

  context 'source and target language, partner and project manager filters' do
    let(:params)  { { source_lang: 3, target_lang: 4, partner: 11, project_manager: 37 } }
    let(:options) { { conditions: 'tasks_kp.langsourceid = 3 AND tasks_kp.langtargetid = 4 AND partners_kp.kpid = 11 AND users_kp.kpid = 37' } }

    it_should_behave_like :all_word_counts
  end
end

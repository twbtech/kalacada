require 'spec_helper'

describe Solas::Translator do
  shared_examples_for :active_translators_count do
    before do
      conditions = [
        'tasks_kp.claimdate IS NOT NULL',
        ("tasks_kp.langsourceid = #{source_language}" if source_language.present?),
        ("tasks_kp.langtargetid = #{target_language}" if target_language.present?)
      ].compact.join(' AND ')
      conditions = "WHERE #{conditions}" if conditions.present?

      expect_any_instance_of(Solas::Connection).to receive(:query).with(
        <<-QUERY
            SELECT
              COUNT(DISTINCT users_kp.kpid) AS count
            FROM tasks_kp
              JOIN users_kp ON tasks_kp.claimuserid = users_kp.kpid
            #{conditions}
      QUERY
      ).and_return(
        [
          { 'count' => 123 }
        ]
      )
    end
  end

  shared_examples_for :inactive_translators_count do
    before do
      conditions_1 = [
        ("language_id = #{source_language}" if source_language.present? && target_language.blank?),
        ("language_id = #{target_language}" if target_language.present? && source_language.blank?)
      ].compact.join(' AND ')

      expect_any_instance_of(Solas::Connection).to receive(:query).with(
        if conditions_1.present?
          users_kp_conditions = conditions_1.gsub('language_id', 'primarylangid')
          <<-QUERY
                SELECT COUNT(DISTINCT ul1.user_id) AS count FROM
                  (
                    (SELECT id AS user_id, primarylangid AS language_id FROM users_kp WHERE #{users_kp_conditions}) UNION
                    (SELECT user_id, language_id FROM SolasMatch.UserSecondaryLanguages WHERE #{conditions_1})
                  ) AS ul1
                LEFT JOIN tasks_kp ON tasks_kp.claimuserid = ul1.user_id
                WHERE tasks_kp.claimdate IS NULL
          QUERY
        elsif source_language.present? && target_language.present?
          <<-QUERY
                SELECT COUNT(DISTINCT ul1.user_id) AS count FROM
                  (
                    (SELECT id AS user_id, primarylangid AS language_id FROM users_kp WHERE primarylangid = #{source_language}) UNION
                    (SELECT user_id, language_id FROM SolasMatch.UserSecondaryLanguages WHERE language_id = #{source_language})
                  ) AS ul1
                  JOIN
                  (
                    (SELECT id AS user_id, primarylangid AS language_id FROM users_kp WHERE primarylangid = #{target_language}) UNION
                    (SELECT user_id, language_id FROM SolasMatch.UserSecondaryLanguages WHERE language_id = #{target_language})
                  ) AS ul2
                  ON ul1.user_id = ul2.user_id
                LEFT JOIN tasks_kp ON tasks_kp.claimuserid = ul1.user_id
                WHERE tasks_kp.claimdate IS NULL
          QUERY
        else
          <<-QUERY
                SELECT COUNT(DISTINCT users_kp.kpid) AS count
                FROM users_kp LEFT JOIN tasks_kp ON tasks_kp.claimuserid = users_kp.kpid
                WHERE tasks_kp.claimdate IS NULL
          QUERY
        end
      ).and_return(
        [
          { 'count' => 123 }
        ]
      )
    end
  end

  shared_examples_for :all_active_translators_count do
    describe 'self.completed_count' do
      it_should_behave_like :active_translators_count do
        it 'should execute correct SQL statement and return correct count' do
          expect(Solas::Translator.active_count(source_language, target_language)).to eq 123
        end
      end
    end
  end

  shared_examples_for :all_inactive_translators_count do
    describe 'self.completed_count' do
      it_should_behave_like :inactive_translators_count do
        it 'should execute correct SQL statement and return correct count' do
          expect(Solas::Translator.inactive_count(source_language, target_language)).to eq 123
        end
      end
    end
  end

  context 'no filters' do
    let(:source_language) { nil }
    let(:target_language) { nil }

    it_should_behave_like :all_active_translators_count
    it_should_behave_like :all_inactive_translators_count
  end

  context 'source language only' do
    let(:source_language) { 1786 }
    let(:target_language) { nil }

    it_should_behave_like :all_active_translators_count
    it_should_behave_like :all_inactive_translators_count
  end

  context 'target language only' do
    let(:source_language) { nil }
    let(:target_language) { 1786 }

    it_should_behave_like :all_active_translators_count
    it_should_behave_like :all_inactive_translators_count
  end

  context 'target language and source language' do
    let(:source_language) { 1507 }
    let(:target_language) { 1786 }

    it_should_behave_like :all_active_translators_count
    it_should_behave_like :all_inactive_translators_count
  end
end

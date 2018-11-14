require 'spec_helper'

describe Solas::Translator do
  shared_examples_for :active_translators_count do
    before do
      conditions = [
        ("Tasks.`language_id-source` = #{source_language}" if source_language.present?),
        ("Tasks.`language_id-target` = #{target_language}" if target_language.present?)
      ].compact.join(' AND ')
      conditions = "WHERE #{conditions}" if conditions.present?

      expect_any_instance_of(Solas::Connection).to receive(:query).with(
        <<-QUERY
            SELECT
              COUNT(DISTINCT Users.id) AS count
            FROM Tasks
              JOIN TaskClaims ON Tasks.id = TaskClaims.task_id
              JOIN Users      ON TaskClaims.user_id = Users.id
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
          <<-QUERY
                SELECT COUNT(DISTINCT ul1.user_id) AS count FROM
                  (
                    (SELECT id AS user_id, language_id FROM Users WHERE #{conditions_1}) UNION
                    (SELECT user_id, language_id FROM UserSecondaryLanguages WHERE #{conditions_1})
                  ) AS ul1
                LEFT JOIN TaskClaims ON TaskClaims.user_id = ul1.user_id
                WHERE TaskClaims.id IS NULL
          QUERY
        elsif source_language.present? && target_language.present?
          <<-QUERY
                SELECT COUNT(DISTINCT ul1.user_id) AS count FROM
                  (
                    (SELECT id AS user_id, language_id FROM Users WHERE language_id = #{source_language}) UNION
                    (SELECT user_id, language_id FROM UserSecondaryLanguages WHERE language_id = #{source_language})
                  ) AS ul1
                  JOIN
                  (
                    (SELECT id AS user_id, language_id FROM Users WHERE language_id = #{target_language}) UNION
                    (SELECT user_id, language_id FROM UserSecondaryLanguages WHERE language_id = #{target_language})
                  ) AS ul2
                  ON ul1.user_id = ul2.user_id
                LEFT JOIN TaskClaims ON TaskClaims.user_id = ul1.user_id
                WHERE TaskClaims.id IS NULL
          QUERY
        else
          <<-QUERY
                SELECT COUNT(DISTINCT Users.id) AS count
                FROM Users LEFT JOIN TaskClaims ON TaskClaims.user_id = Users.id
                WHERE TaskClaims.id IS NULL
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

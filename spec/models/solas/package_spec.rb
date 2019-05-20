require 'spec_helper'

describe Solas::Package do
  describe 'self.find_packages' do
    it 'should execute correct SQL statement and return correct partner objects' do
      expect_any_instance_of(Solas::Connection).to receive(:query).with('SELECT * FROM partners_neon JOIN partners_kp ON partners_neon.neonid = partners_kp.neonid WHERE kpid = 49').and_return([{ 'wordcountlimit' => 10_000, 'membrname' => 'mem name', 'membrexpiredate' => '2017-01-01', 'membrstartdate' => '2017-12-31' }])

      packages = Solas::Package.find_packages(49)
      expect(packages.count).to be 1

      package = packages.first
      expect(package[:partner_division_name]).to eq 'something'
      expect(package[:word_count_limit]).to eq      10_000
      expect(package[:membership_name]).to eq       'mem name'
      expect(package[:member_expire_date]).to eq    '2017-01-01'
      expect(package[:member_start_date]).to eq     '2017-12-31'
      expect(package[:words_remaining]).to eq       123
    end
  end

  describe 'self.count_remaining_words' do
    it 'should return count of remaining words' do
      expect_any_instance_of(Solas::Connection).to receive(:query).with(
        <<-QUERY
            SELECT SUM(tasks_kp.wordcount) AS wordcount
            FROM tasks_kp
            JOIN projects_kp ON tasks_kp.project_id = projects_kp.pid
            JOIN partners_kp ON projects_kp.orgid = partners_kp.kpid
            WHERE tasks_kp.tasktype = 'Translation' AND partners_kp.kpid = 49 AND
              tasks_kp.claimdate >= '2017-01-01 00:00:00' AND tasks_kp.claimdate <= '2017-12-31 23:59:59'
        QUERY
      ).and_return([{ 'wordcount' => 1_000 }])

      word_count = Solas::Package.count_remaining_words(49, 500, Date.parse('2017-01-01 00:00:00 +0100'), Date.parse('2017-12-31 00:00:00 +0100'))
      expect(word_count).to eq 0
    end
  end
end

require 'spec_helper'

examples_dir = File.expand_path('../examples', __dir__)
expected_outputs = {
  'add.kalc' => '42',
  'arrays.kalc' => 'Ada, Grace, Katherine closed 845.50 in sales. Top score: 100',
  'crew_lookup.kalc' => 'Crew record: role=Scientist, score=100, specialty=Math',
  'gradebook.kalc' => 'Ada Lovelace finished with 92.50% and earned a A',
  'invoice.kalc' => 'Ada Lovelace owes 102.98 (subtotal 98.00, discount 9.80, shipping 7.50, tax 7.28)',
  'leaderboard.kalc' => 'Winner: Grace with 100 / podium: Grace, Katherine, Ada',
  'movie_marathon.kalc' => 'Headliner: Arrival / sci-fi films: 3 / sci-fi runtime: 370 min',
  'newton.kalc' => '32.000007',
  'northwind_report.kalc' => 'North closed 3 deals for 4600 revenue and 44 tickets.',
  'quest_briefing.kalc' => 'Juniper the Wizard enters Glass Glacier facing a dangerous threat.',
  'restock_queue.kalc' => 'Restock route: saffron from Vault, then cardamom, then coffee',
  'sequence_board.kalc' => '[7.0, 35.0, 63.0, 91.0; 14.0, 42.0, 70.0, 98.0; 21.0, 49.0, 77.0, 105.0; 28.0, 56.0, 84.0, 112.0]',
  'spaceport_dashboard.kalc' => 'Active docks: 3 / throughput: 545 / top dock: Cinder / upgrade path: Orbital',
  'string_cleanup.kalc' => 'Kalc Build 2026 03 23 / characters=21',
  'subscription_tiers.kalc' => 'For 7200 events/month, choose the Scale plan with same-day support.',
  'subtract.kalc' => '90',
  'transpose_schedule.kalc' => '["Mon", "Parse"; "Tue", "Spec"; "Wed", "Ship"; "Thu", "Rest"]',
  'unique_topics.kalc' => 'All topics: arrays, excel, grammar, parser, repl, ruby / mentioned once: grammar, parser, repl',
  'wizard_tower.kalc' => 'Crystal tower beds: 5, 8, 13, 21 / total seeds: 47'
}.freeze

RSpec.describe 'Examples' do
  it 'tracks every example file in the expectations table' do
    example_files = Dir.children(examples_dir).grep(/\.kalc\z/).sort

    expect(expected_outputs.keys.sort).to eq(example_files)
  end

  expected_outputs.each do |file_name, expected_output|
    it "keeps #{file_name} working" do
      result = Kalc::Runner.new.run(File.read(File.join(examples_dir, file_name)))

      expect(render_output(result)).to eq(expected_output)
    end
  end

  def render_output(result)
    result.to_s
  end
end

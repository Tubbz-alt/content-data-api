RSpec.describe Queries::FindAggregations do
  it 'has aggregations for all metric names' do
    result = Queries::FindAggregations.new.run
    expect(result.keys).to eq(Metric.find_all_names)
  end

  it 'return aggregated values for daily metrics' do
    edition = create :edition, base_path: '/path/1', date: '2018-01-01'
    create :metric, edition: edition, date: '2018-01-01', pviews: 2
    create :metric, edition: edition, date: '2018-01-02', pviews: 3

    result = Queries::FindAggregations.new.run
    expect(result.fetch('pviews')).to eq(5)
    expect(result.fetch(:pviews)).to eq(5)
  end

  it 'filters by base_path' do
    edition = create :edition, base_path: '/path/1', date: '2018-01-01'
    create :metric, edition: edition, date: '2018-01-01', pviews: 2
    create :metric, edition: edition, date: '2018-01-02', pviews: 3

    edition2 = create :edition, base_path: '/path/2', date: '2018-01-01'
    create :metric, edition: edition2, date: '2018-01-02', pviews: 3

    result = Queries::FindAggregations.new.by_base_path('/path/1').run
    expect(result.fetch(:pviews)).to eq(5)
  end

  it 'filters by from and to' do
    edition = create :edition, base_path: '/path/1', date: '2018-01-01'
    create :metric, edition: edition, date: '2018-01-01', pviews: 2
    create :metric, edition: edition, date: '2018-01-02', pviews: 3
    create :metric, edition: edition, date: '2018-01-03', pviews: 4
    create :metric, edition: edition, date: '2018-01-04', pviews: 5

    result = Queries::FindAggregations.new.between(
      from: '2018-01-02',
      to: '2018-01-03'
    ).run

    expect(result.fetch(:pviews)).to eq(7)
  end

  it 'aggregates edition metrics' do
    edition1 = create :edition, facts: { words: 10 }, date: '2018-01-01'
    edition2 = create :edition, replaces: edition1, facts: { words: 12 }, date: '2018-01-02'

    create :metric, edition: edition1, date: '2018-01-01', pviews: 2
    create :metric, edition: edition2, date: '2018-01-02', pviews: 2
    result = Queries::FindAggregations.new.run

    expect(result.fetch(:words)).to eq(22)
  end

  describe 'Satisfaction score' do
    it 'recalculate the `satisfaction-score` aggregation' do
      edition = create :edition, base_path: '/path/1', date: '2018-01-02'
      create :metric, edition: edition, date: '2018-01-02', useful_yes: 2, useful_no: 0
      create :metric, edition: edition, date: '2018-01-03', useful_yes: 1, useful_no: 2

      result = Queries::FindAggregations.new.run

      expect(result.fetch(:satisfaction)).to eq(0.6)
    end

    it 'return 0 if no responses' do
      edition = create :edition, base_path: '/path/1', date: '2018-01-01'
      create :metric, edition: edition, date: '2018-01-01', useful_yes: 0, useful_no: 0
      create :metric, edition: edition, date: '2018-01-02', useful_yes: 0, useful_no: 0

      result = Queries::FindAggregations.new.run

      expect(result.fetch(:satisfaction)).to be_zero
    end
  end

  it 'returns nil values when no results' do
    result = Queries::FindAggregations.new.run

    expect(result).to match(hash_including('pviews' => nil, 'upviews' => nil))
  end
end

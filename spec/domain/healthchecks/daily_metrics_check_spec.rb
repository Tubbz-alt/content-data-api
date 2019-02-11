RSpec.describe Healthchecks::DailyMetricsCheck do
  include_examples 'Healthcheck enabled/disabled within time range'

  describe '#status' do
    context 'When there are metrics' do
      before { create :metric, dimensions_date: Dimensions::Date.build(Date.yesterday) }

      it 'returns status :ok' do
        expect(subject.status).to eq(:ok)
      end

      it 'returns a detailed message' do
        expect(subject.message).to eq('ETL :: no daily metrics for yesterday')
      end
    end

    context 'When there are no metrics' do
      it 'returns status :ok' do
        expect(subject.status).to eq(:critical)
      end
    end
  end
end

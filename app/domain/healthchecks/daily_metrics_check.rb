module Healthchecks
  class DailyMetricsCheck
    include Concerns::Deactivable

    def name
      :daily_metrics
    end

    def status
      metrics.any? ? :ok : :critical
    end

    def message
      "ETL :: no daily metrics for yesterday"
    end

  private

    def metrics
      @metrics ||= Facts::Metric.where(dimensions_date_id: Date.yesterday)
    end
  end
end

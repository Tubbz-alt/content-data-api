class Queries::Series
  attr_reader :metric_name

  def initialize(metric_name, all_metrics)
    @metric_name = metric_name
    @all_metrics = all_metrics
  end

  def total
    time_series.reduce(0) { |total, time_point| total + time_point[:value] }
  end

  def time_series
    @all_metrics.map do |metric|
      date = metric.dimensions_date_id.to_s
      value = metric.send(metric_name)
      { date: date, value: value }
    end
  end
end

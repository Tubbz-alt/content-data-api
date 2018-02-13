class ETL::Master
  def self.process(*args)
    new(*args).process
  end

  def process
    initialize_facts_table
    update_with_google_analytics_metrics
  end

private

  def initialize_facts_table
    Dimensions::Item.where(latest: true).find_in_batches(batch_size: 50000) do |batch|
      values = batch.pluck(:id).map do |value|
        {
          dimensions_date_id: date.date,
          dimensions_item_id: value,
        }
      end
      Facts::Metric.import(values, validate: false)
    end
  end

  def update_with_google_analytics_metrics
    ETL::GA.process(date: date)
  end

  def date
    @date ||= Dimensions::Date.for(Date.yesterday)
  end
end

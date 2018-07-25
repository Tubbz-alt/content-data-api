class Etl::Jobs::QualityMetricsJob < ActiveJob::Base
  retry_on Net::OpenTimeout, wait: 5.seconds, attempts: 10
  queue_as :quality_metrics

  def perform(item_id, _ = {})
    item = Dimensions::Item.find(item_id)
    item.facts_edition.update!(quality_metrics(item.document_text))
  end

private

  def quality_metrics(content)
    Etl::Item::Quality::Service.new.run(content)
  end
end
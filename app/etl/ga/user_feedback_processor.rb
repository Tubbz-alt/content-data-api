class GA::UserFeedbackProcessor
  include Concerns::Traceable
  include GA::Concerns::TransformPath

  def self.process(*args)
    new(*args).process
  end

  def initialize(date:)
    @date = date
  end

  def process
    time(process: :ga) do
      extract_events
      transform_events
      load_metrics
    end
  end

private

  def extract_events
    batch = 1
    GA::UserFeedbackService.find_in_batches(date: date) do |events|
      log process: :ga, message: "Processing #{events.length} events in batch #{batch}"
      Events::GA.import(events, batch_size: 10_000)
      batch += 1
    end
  end

  def transform_events
    remove_invalid_prefix
  end

  def load_metrics
    conn = ActiveRecord::Base.connection
    date_to_s = date.strftime("%F")
    conn.execute(load_metrics_query(date_to_s))
    conn.execute(clean_up_query)
  end

  def load_metrics_query(date_to_s)
    <<~SQL
      UPDATE facts_metrics
      SET is_this_useful_no = s.is_this_useful_no,
          is_this_useful_yes = s.is_this_useful_yes
      FROM (
        SELECT is_this_useful_no,
               is_this_useful_yes,
               dimensions_items.id
        FROM events_gas, dimensions_items
        WHERE page_path = base_path
              AND events_gas.date = '#{date_to_s}'
      ) AS s
      WHERE dimensions_item_id = s.id AND dimensions_date_id = '#{date_to_s}'
    SQL
  end

  def clean_up_query
    date_to_s = date.strftime("%F")
    <<~SQL
      DELETE FROM events_gas
      WHERE date = '#{date_to_s}' AND
            process_name = #{Events::GA.process_names['user_feedback']} AND
        page_path in (
           SELECT base_path
           FROM dimensions_items, facts_metrics
           WHERE dimensions_items.id = facts_metrics.dimensions_item_id
           AND facts_metrics.dimensions_date_id = '#{date_to_s}'
        )
    SQL
  end

  attr_reader :date
end
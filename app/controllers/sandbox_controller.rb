class SandboxController < ApplicationController
  include Concerns::ExportableToCSV

  def index
    respond_to do |format|
      format.html do
        @metrics = Facts::Metric
          .by_locale('en')
          .between(from, to)
          .by_base_path(base_path)
          .by_organisation_id(organisation)
                     .by_document_type(document_type)

        @metrics =
          if is_content_metric?
            @metrics.with_edition_metrics
          else
            @metrics.joins(:dimensions_item)
          end

        @query_params = query_params
      end

      format.csv do
        @metrics = Facts::Metric.joins(dimensions_item: :facts_edition)
                     .by_locale('en')
                     .between(from, to)
                     .by_base_path(base_path)
                     .by_organisation_id(organisation)
        export_to_csv enum: CSVExport.run(@metrics, Facts::Metric.csv_fields)
      end
    end
  end

private

  def metric
    params[:metric]
  end

  def from
    params[:from] ||= 5.days.ago.to_date
  end

  def to
    params[:to] ||= Date.yesterday
  end

  def base_path
    params[:base_path]
  end

  def organisation
    params[:organisation]
  end

  def document_type
    params[:document_type]
  end

  def query_params
    params.permit(:from, :to, :base_path, :utf8,
      :total_items, :pageviews, :unique_pageviews, :feedex_comments,
      :number_of_pdfs, :number_of_word_files, :filter, :organisation,
      :is_this_useful_yes, :is_this_useful_no, :number_of_internal_searches,
      :contractions_count, :equality_count, :indefinite_article_count, :number_of_pdfs,
      :number_of_word_files, :passive_count, :profanities_count, :readability_score,
      :redundant_acronyms_count, :repeated_words_count, :sentence_count, :simplify_count,
      :spell_count, :string_length, :word_count, :entrances, :exits, :bounce_rate,
      :avg_time_on_page, :document_type, :metric)
  end

  def is_content_metric?
    content_metrics = %w(
      number_of_pdfs
      number_of_word_files
      readability_score
      contractions_count
      equality_count
      indefinite_article_count
      passive_count
      profanities_count
      redundant_acronyms_count
      repeated_words_count
      simplify_count
      spell_count
      string_length
      sentence_count
      word_count
    )

    content_metrics.any? { |metric| params[metric] == 'on' }
  end
end

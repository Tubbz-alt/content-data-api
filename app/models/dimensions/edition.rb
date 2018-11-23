require 'json'

class Dimensions::Edition < ApplicationRecord
  has_one :facts_edition, class_name: "Facts::Edition", foreign_key: :dimensions_edition_id
  validates :content_id, presence: true
  validates :base_path, presence: true
  validates :schema_name, presence: true
  validates :publishing_api_payload_version, presence: true
  validates :warehouse_item_id, presence: true

  scope :by_base_path, ->(base_path) { where('base_path like (?)', base_path) }
  scope :by_content_id, ->(content_id) { where(content_id: content_id) }
  scope :by_organisation_id, ->(organisation_id) { where(organisation_id: organisation_id) }
  scope :by_document_type, ->(document_type) { where('document_type like (?)', document_type) }
  scope :by_locale, ->(locale) { where(locale: locale) }
  scope :latest, -> { where(latest: true) }
  scope :latest_by_content_id, ->(content_id, locale) { where(content_id: content_id, locale: locale, latest: true) }
  scope :latest_by_base_path, ->(base_paths) { where(base_path: base_paths, latest: true) }
  scope :existing_latest_editions, ->(content_id, locale, base_paths) { latest_by_content_id(content_id, locale).or(latest_by_base_path(base_paths)) }
  scope :outdated_subpages, ->(content_id, locale, exclude_paths) do
    latest_by_content_id(content_id, locale)
      .where.not(base_path: exclude_paths)
  end
  scope :relevant_content, -> { where.not(document_type: %w[redirect gone]) }

  def self.search(query)
    sql = <<~SQL
      to_tsvector('english',title) @@ plainto_tsquery('english', :search_term) or
      to_tsvector('english'::regconfig, replace((base_path)::text, '/'::text, ' '::text)) @@ plainto_tsquery('english', :search_term_without_slash)
    SQL

    where(sql, search_term: query, search_term_without_slash: query.tr('/', ' '))
  end

  def promote!(old_edition)
    if old_edition
      old_edition.deprecate!
      assign_attributes warehouse_item_id: old_edition.warehouse_item_id
    end
    update!(latest: true)
  end

  def deprecate!
    update!(latest: false)
  end

  def change_from?(attributes)
    assign_attributes(attributes.reject { |k, _| k == :raw_json })
    dirty = changed?
    reload
    dirty
  end

  def metadata
    {
      title: title,
      base_path: base_path,
      content_id: content_id,
      first_published_at: first_published_at,
      public_updated_at: public_updated_at,
      publishing_app: publishing_app,
      document_type: document_type,
      primary_organisation_title: primary_organisation_title,
      withdrawn: withdrawn,
      historical: historical
    }
  end
end

module Audits
  class FilteredContentQuery
    attr_reader :scope
    alias_method :content_items, :scope

    def self.filter_scope(content_scope)
      FilteredContentQuery.new(content_scope)
    end

    def self.filter_query(query)
      filter_scope(query.scope)
    end

    def initialize(content_scope = ContentItem.all)
      @scope = content_scope
    end

    def audit_status(audit_status)
      return self unless audit_status.present?

      case audit_status.to_sym
      when :audited
        audited
      when :non_audited
        non_audited
      else
        self
      end
    end

    def audited
      @scope = @scope.joins(:audit)
      self
    end

    def non_audited
      @scope = @scope.where.not(content_id: Audit.all.select(:content_id))
      self
    end

    def passing
      @scope = @scope.where(content_id: Audit.passing.select(:content_id))
      self
    end

    def failing
      @scope = @scope.where(content_id: Audit.passing.select(:content_id))
      self
    end
  end
end

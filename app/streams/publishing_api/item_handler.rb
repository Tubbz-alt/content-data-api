class PublishingAPI::ItemHandler
  def initialize(old_item:, new_item:)
    @old_item = old_item
    @new_item = new_item
  end

  def process!
    if new_item
      grow_dimension! if new_version?
    else
      old_item.deprecate!
    end
  end

  def process_links!
    if new_item
      grow_dimension! if new_version? && links_have_changed?
    else
      old_item.deprecate!
    end
  end

private

  attr_reader :old_item
  attr_reader :new_item

  def new_version?
    new_item && new_item.newer_than?(old_item)
  end

  def links_have_changed?
    return true if old_item.nil?

    HashDiff::Comparison.new(
      old_item.expanded_links.deep_sort,
      new_item.expanded_links.deep_sort
    ).diff.present?
  end

  def grow_dimension!
    new_item.promote!(old_item)
    Item::Processor.run(new_item, Date.today)
  end
end

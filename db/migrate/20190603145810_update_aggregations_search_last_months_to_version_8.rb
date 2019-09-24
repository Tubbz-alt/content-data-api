class UpdateAggregationsSearchLastMonthsToVersion8 < ActiveRecord::Migration[5.2]
  def change
    update_view(
      :aggregations_search_last_months,
      version: 8,
      revert_to_version: 7,
      materialized: true,
    )
  end
end

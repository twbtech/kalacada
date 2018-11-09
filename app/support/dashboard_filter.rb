class DashboardFilter
  include ActiveModel::Model

  INT_ATTRS = [:source_lang, :target_lang, :partner, :project_manager, :page].freeze
  DATE_ATTRS = [:from_date, :to_date].freeze
  ATTRS = (INT_ATTRS + DATE_ATTRS).freeze

  ATTRS.each { |attr| attr_reader attr }

  def initialize(params)
    INT_ATTRS.each do |attr|
      instance_variable_set "@#{attr}", (params[attr].to_i if params[attr].present?)
    end

    DATE_ATTRS.each do |attr|
      instance_variable_set "@#{attr}", (Date.parse(params[attr]) if params[attr].present?)
    end
  end

  def to_sanitized_hash
    Hash[*ATTRS.map { |attr| [attr, send(attr)] }.flatten]
  end
end

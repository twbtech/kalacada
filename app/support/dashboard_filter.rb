class DashboardFilter
  include ActiveModel::Model

  INT_ATTRS = [:source_lang, :target_lang, :partner, :project_manager, :page].freeze
  DATE_ATTRS = [:from_date, :to_date].freeze
  ATTRS = (INT_ATTRS + DATE_ATTRS).freeze

  ATTRS.each { |attr| attr_reader attr }

  attr_reader :logged_in_user

  def initialize(params, logged_in_user)
    @logged_in_user = logged_in_user

    INT_ATTRS.each do |attr|
      instance_variable_set "@#{attr}", (params[attr].to_i if params[attr].present?)
    end

    DATE_ATTRS.each do |attr|
      instance_variable_set "@#{attr}", (Date.parse(params[attr]) if params[attr].present?)
    end

    @source_lang, @target_lang = params[:language_pair].to_s.split('_').map(&:to_i) if params[:language_pair].present?

    if logged_in_user.partner?
      @partner         = logged_in_user.partner_organization.id
      @project_manager = nil
    end
  end

  def to_sanitized_hash
    Hash[*ATTRS.map { |attr| [attr, send(attr)] }.flatten]
  end

  def language_pair
    [@source_lang, @target_lang].join('_') if @source_lang && @target_lang
  end
end

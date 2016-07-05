class SecuritiesReleaseRequest
  include ActiveModel::Model

  TRANSACTION_CODES = {
    standard: 'standard',
    repo: 'repo'
  }.freeze

  SETTLEMENT_TYPES = {
    free: 'free',
    payment: 'payment'
  }.freeze

  DELIVERY_TYPES = {
    dtc: 'dtc',
    fed: 'fed',
    mutual_fund: 'mutual_fund',
    physical_securities: 'physical_securities'
  }.freeze

  BROKER_INSTRUCTION_KEYS = [:transaction_code, :settlement_type, :trade_date, :settlement_date].freeze

  DELIVERY_INSTRUCTION_KEYS = {
    fed: [:clearing_agent_fed_wire_address, :aba_number, :fed_credit_account_number],
    dtc: [:clearing_agent_participant_number, :dtc_credit_account_number],
    mutual_fund: [:mutual_fund_company, :mutual_fund_account_number],
    physical_securities: [:delivery_bank_agent, :receiving_bank_agent_name, :receiving_bank_agent_address, :physical_securities_credit_account_number]
  }.freeze

  ACCOUNT_NUMBER_TYPES = [:fed_credit_account_number, :dtc_credit_account_number, :mutual_fund_account_number, :physical_securities_credit_account_number]

  OTHER_PARAMETERS = [:delivery_type, :member_id, :clearing_agent_fed_wire_address_1, :clearing_agent_fed_wire_address_2].freeze

  ACCESSIBLE_ATTRS = BROKER_INSTRUCTION_KEYS + OTHER_PARAMETERS + DELIVERY_INSTRUCTION_KEYS.values.flatten - [:clearing_agent_fed_wire_address]

  attr_accessor *ACCESSIBLE_ATTRS
  attr_writer :clearing_agent_fed_wire_address
  attr_reader :securities

  validates *(BROKER_INSTRUCTION_KEYS + [:delivery_type, :securities]), presence: true
  validates *DELIVERY_INSTRUCTION_KEYS[:fed], presence: true, if: Proc.new { |request| request.delivery_type && request.delivery_type.to_sym == :fed }
  validates *DELIVERY_INSTRUCTION_KEYS[:dtc], presence: true, if: Proc.new { |request| request.delivery_type && request.delivery_type.to_sym == :dtc }
  validates *DELIVERY_INSTRUCTION_KEYS[:mutual_fund], presence: true, if: Proc.new { |request| request.delivery_type && request.delivery_type.to_sym == :mutual_fund }
  validates *DELIVERY_INSTRUCTION_KEYS[:physical_securities], presence: true, if: Proc.new { |request| request.delivery_type && request.delivery_type.to_sym == :physical_securities }
  validate :trade_date_must_come_before_settlement_date
  validate :securities_must_have_payment_amount, if: Proc.new { |request| request.settlement_type && request.settlement_type.to_sym == :payment }

  def self.from_hash(hash)
    obj = new
    obj.attributes = hash
    obj
  end

  def clearing_agent_fed_wire_address
    if clearing_agent_fed_wire_address_1 && clearing_agent_fed_wire_address_2
      clearing_agent_fed_wire_address_1.to_s + ' ' + clearing_agent_fed_wire_address_2.to_s
    elsif clearing_agent_fed_wire_address_1
      clearing_agent_fed_wire_address_1
    elsif clearing_agent_fed_wire_address_2
      clearing_agent_fed_wire_address_2
    end
  end

  def attributes=(hash)
    hash.each do |key, value|
      key = key.to_sym
      value = case key
      when :trade_date, :settlement_date
        Time.zone.parse(value)
      when :delivery_type, :transaction_code, :settlement_type
        value.to_sym
      when :securities, *ACCESSIBLE_ATTRS
        value
      else
        raise ArgumentError, "unknown attribute: '#{key}'"
      end
      send("#{key.to_sym}=", value)
    end
  end

  def securities=(securities)
    securities = if securities.is_a?(String)
      JSON.parse(securities)
    else
      securities || []
    end
    securities.collect! do |security|
      if security.is_a?(Security)
        security
      elsif security.is_a?(String)
        Security.from_json(security)
      elsif security.is_a?(Hash)
        Security.from_hash(security)
      else
        raise ArgumentError, "unable to process security with class: '#{security.class}'"
      end
    end
    @securities = securities
  end

  def broker_instructions
    {
      transaction_code: transaction_code,
      settlement_type: settlement_type,
      trade_date: trade_date,
      settlement_date: settlement_date
    }
  end

  def delivery_instructions
    delivery_instructions_hash = {
      delivery_type: delivery_type
    }
    DELIVERY_INSTRUCTION_KEYS[delivery_type.to_sym].each do |attr|
      if ACCOUNT_NUMBER_TYPES.include?(attr)
        delivery_instructions_hash[:account_number] = self.send(attr)
      else
        delivery_instructions_hash[attr] = self.send(attr)
      end
    end
    delivery_instructions_hash
  end

  private

  def trade_date_must_come_before_settlement_date
    trade_date <= settlement_date if trade_date && settlement_date
  end

  def securities_must_have_payment_amount
    securities_clone = securities || []
    has_payment_amount = !securities_clone.blank?
    securities_clone.each do |security|
      if security.payment_amount.blank?
        has_payment_amount = false
        break
      end
    end
    has_payment_amount
  end
end

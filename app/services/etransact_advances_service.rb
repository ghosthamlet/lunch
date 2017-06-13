class EtransactAdvancesService < MAPIService

  def status
    get_hash(:status, 'etransact_advances/status')
  end
  
  def blackout_dates
    get_json(:blackout_dates, 'etransact_advances/blackout_dates')
  end
  
  def etransact_active?(status_object=nil)
    status_object = self.status unless status_object
    return false unless status_object
    status_object[:etransact_advances_status] 
  end

  def has_terms?(status_object=nil)
    status_object = self.status unless status_object
    return false unless status_object
    status_object[:all_loan_status].select do |term, loans|
      loans.select do |loan,  details|
        details[:display_status] && details[:trade_status]
      end.present?
    end.present?
  end

  def signer_full_name(signer)
    signer = get(:signer_full_name, "etransact_advances/signer_full_name/#{(signer)}").try(:body)
    String.new(signer) if signer
  end

  def quick_advance_validate(member_id, amount, advance_type, advance_term, rate, check_capstock, signer, maturity_date, allow_grace_period=false, funding_date=nil)
    error_handler = calypso_error_handler(member_id)
    get_hash(:quick_advance_validate, "etransact_advances/validate_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{check_capstock}/#{URI.escape(signer)}/#{maturity_date.to_date.iso8601}", allow_grace_period: allow_grace_period, funding_date: funding_date.try(:to_date).try(:iso8601), &error_handler)
  end

  def quick_advance_execute(member_id, amount, advance_type, advance_term, rate, signer, maturity_date, allow_grace_period=false, funding_date=nil)
    error_handler = calypso_error_handler(member_id)
    body = {
      amount: amount,
      advance_type: advance_type,
      advance_term: advance_term,
      rate: rate,
      signer: signer,
      maturity_date: maturity_date.to_date.iso8601,
      funding_date: funding_date.try(:to_date).try(:iso8601),
      allow_grace_period: allow_grace_period
    }
    data = post_hash(:quick_advance_execute, "etransact_advances/execute_advance/#{member_id}", body, &error_handler)
    data[:initiated_at] = Time.zone.now.to_datetime if data
    data
  end

  def todays_advances_amount(member_id, low_days, high_days)
    if data = get_json(:todays_advances_amount, "member/#{member_id}/todays_advances")
      amount = 0
      data.each do |row|
        days_to_maturity = get_days_to_maturity_date(row['maturity_date'])
        if days_to_maturity >= low_days.to_i && days_to_maturity <= high_days.to_i
          amount = amount + row['current_par'].to_i
        end
      end
      amount
    end
  end

  def todays_cumulative_advances_amount(member_id)
    if data = get_json(:todays_advances_amount, "member/#{member_id}/todays_advances")
      amount = 0
      data.each do |row|
        amount = amount + row['current_par'].to_i
      end
      amount
    end
  end

  def check_limits(member_id, amount, advance_term, custom_maturity_date=nil)
    return nil if amount.nil? || advance_term.nil?
    if limits = get_json(:check_limits, 'etransact_advances/limits')
      days_to_maturity = get_days_to_maturity(advance_term, custom_maturity_date)
      min_amount = 0
      max_amount = 0
      low_days = 0
      high_days = 1105
      limits.each do |row|
        if days_to_maturity >= row['LOW_DAYS_TO_MATURITY'].to_i && days_to_maturity <= row['HIGH_DAYS_TO_MATURITY'].to_i
          min_amount = row['MIN_ONLINE_ADVANCE'].to_i
          max_amount = row['TERM_DAILY_LIMIT'].to_i
          low_days = row['LOW_DAYS_TO_MATURITY'].to_i
          high_days = row['HIGH_DAYS_TO_MATURITY'].to_i
          break
        end
      end
      check_limit = 'pass'
      if todays_amount = todays_advances_amount(member_id, low_days, high_days)
        if amount.to_i < min_amount.to_i
          check_limit = 'low'
        elsif amount.to_i + todays_amount.to_i > max_amount.to_i
          check_limit = 'high'
        else
          if todays_cumulative_amount = todays_cumulative_advances_amount(member_id)
            settings = self.settings
            if amount.to_i + todays_cumulative_amount.to_i > settings['shareholder_total_daily_limit'].to_i
              check_limit = 'high'
            end
          else
            return nil
          end
        end
        {
          status: check_limit,
          low: min_amount,
          high: max_amount
        }
      else
        nil
      end
    end
  end

  def limits
    get_json(:check_limits, 'etransact_advances/limits').collect do |bucket|
      Hash[bucket.map{ |k,v| [k.downcase,v] }].with_indifferent_access
    end
  end

  def settings
    @settings ||= get_hash(:settings, 'etransact_advances/settings')
  end

  def update_settings(settings)
    put_hash(:update_settings, 'etransact_advances/settings', settings)
  end

  def update_term_limits(limits)
    put_hash(:update_term_limits, 'etransact_advances/limits', limits)
  end

  MEMBER_SERVICES_DESK_HOURS = 8..13

  def etransact_status(member_id, status_object=nil)
    enabled_for_member = MembersService.new(request).quick_advance_enabled_for_member?(member_id)
    status_object = self.status unless status_object
    etransact_active = self.etransact_active?(status_object)
    etransact_has_terms = self.has_terms?(status_object)
    # Priority Order: Closed/Unavailable, No Terms, Disabled, Open
    if etransact_active
      if etransact_has_terms
        if enabled_for_member
          :open
        else
          :disabled_for_member
        end
      else
        :no_terms
      end
    else
      MEMBER_SERVICES_DESK_HOURS.cover?(Time.zone.now.hour) ? :unavailable : :closed
    end
  end

  def shutoff_times_by_type
    if shutoff_times = get_hash(:shutoff_times_by_type, 'etransact_advances/shutoff_times_by_type')
      shutoff_times.each {|product_type, end_time| shutoff_times[product_type] = parse_24_hour_time(end_time) }
    end
  end

  def early_shutoffs
    if early_shutoffs = get_hashes(:early_shutoffs, 'etransact_advances/early_shutoffs')
      early_shutoffs.each do |early_shutoff|
        fix_date(early_shutoff, :early_shutoff_date)
        early_shutoff[:frc_shutoff_time] = parse_24_hour_time(early_shutoff[:frc_shutoff_time])
        early_shutoff[:vrc_shutoff_time] = parse_24_hour_time(early_shutoff[:vrc_shutoff_time])
      end
    end
  end

  def schedule_early_shutoff(early_shutoff)
    shutoff_hash = {
      early_shutoff_date: early_shutoff.early_shutoff_date,
      vrc_shutoff_time: early_shutoff.vrc_shutoff_time,
      frc_shutoff_time: early_shutoff.frc_shutoff_time,
      day_of_message: early_shutoff.day_of_message_simple_format,
      day_before_message: early_shutoff.day_before_message_simple_format
    }
    post_hash(:schedule_early_shutoff, 'etransact_advances/early_shutoff', shutoff_hash)
  end

  def enable_etransact_service
    put_hash(:enable_etransact_service, 'etransact_advances/settings/enable_service', {})
  end

  def disable_etransact_service
    put_hash(:disable_etransact_service, 'etransact_advances/settings/disable_service', {})
  end

  protected

  def days_until(date)
    (date - Time.zone.today).to_i
  end

  def get_days_to_maturity (term, custom_maturity_date=nil)
    today = Time.zone.today
    case term
    when /\Aovernight|open\z/i
        1
    when /\A(\d+)w/i
        7*$1.to_i
    when /\A(\d+)m/i
        days_until(today + $1.to_i.month)
    when /\A(\d+)y/i
        days_until(today + $1.to_i.year)
    when /\A(\d+)day\z/i
        (custom_maturity_date.to_date - today.to_date).to_i
    end
  end

  def get_days_to_maturity_date (trade_maturity_date)
    case trade_maturity_date
    when /\Aovernight|open\z/i
      1
    else
      days_until(Date.parse(trade_maturity_date))
    end
  end

  def calypso_error_handler(member_id)
    -> (name, msg, err) do
      InternalMailer.calypso_error(err, connection_request_uuid, connection_user, member_id_to_name(member_id)).deliver_now
    end
  end

  def member_id_to_name(member_id)
    (member_id == request.member_id ? request.member_name : nil) || member_id
  end

end
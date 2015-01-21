class MemberBalanceService

  def initialize(member_id)
    @connection = ::RestClient::Resource.new Rails.configuration.mapi.endpoint, headers: {:'Authorization' => "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""}
    @member_id = member_id
    raise ArgumentError, 'member_id must not be blank' if member_id.blank?
  end

  def pledged_collateral
    begin
      response = @connection["member/#{@member_id}/balance/pledged_collateral"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("MemberBalanceService.pledged_collateral encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("MemberBalanceService.pledged_collateral encountered a connection error: #{e.class.name}")
      return nil
    end
    data = JSON.parse(response.body).with_indifferent_access

    mortgage_mv = data[:mortgages].to_f
    agency_mv = data[:agency].to_f
    aaa_mv = data[:aaa].to_f
    aa_mv = data[:aa].to_f

    total_collateral = mortgage_mv + agency_mv + aaa_mv + aa_mv
    {
      mortgages: {absolute: mortgage_mv, percentage: mortgage_mv.fdiv(total_collateral)*100},
      agency: {absolute: agency_mv, percentage: agency_mv.fdiv(total_collateral)*100},
      aaa: {absolute: aaa_mv, percentage: aaa_mv.fdiv(total_collateral)*100},
      aa: {absolute: aa_mv, percentage: aa_mv.fdiv(total_collateral)*100}
    }.with_indifferent_access
  end

  def total_securities
    begin
      response = @connection["member/#{@member_id}/balance/total_securities"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("MemberBalanceService.total_securities encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("MemberBalanceService.total_securities encountered a connection error: #{e.class.name}")
      return nil
    end
    data = JSON.parse(response.body).with_indifferent_access
    pledged_securities = data[:pledged_securities].to_i
    safekept_securities = data[:safekept_securities].to_i
    total_securities = pledged_securities + safekept_securities
    {
      pledged_securities: {absolute: pledged_securities, percentage: pledged_securities.fdiv(total_securities)*100},
      safekept_securities: {absolute: safekept_securities, percentage: safekept_securities.fdiv(total_securities)*100}
    }.with_indifferent_access
  end

  def effective_borrowing_capacity
    begin
      response = @connection["member/#{@member_id}/balance/effective_borrowing_capacity"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("MemberBalanceService.total_securities encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("MemberBalanceService.total_securities encountered a connection error: #{e.class.name}")
      return nil
    end
    data = JSON.parse(response.body)

    total_capacity = data['total_capacity']
    unused_capacity= data['unused_capacity']
    used_capacity = total_capacity - unused_capacity
    
    {
        used_capacity: {absolute: used_capacity, percentage: used_capacity.fdiv(total_capacity)*100},
        unused_capacity: {absolute: unused_capacity, percentage: unused_capacity.fdiv(total_capacity)*100}
    }.with_indifferent_access
  end

  def capital_stock_activity(start_date, end_date)
    # get open balance from start date
    begin
      opening_balance_response = @connection["member/#{@member_id}/capital_stock_balance/#{start_date}"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("MemberBalanceService.capital_stock_activity encountered a RestClient error while hitting the /member/#{@member_id}/capital_stock_balance/#{start_date} MAPI endpoint: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("MemberBalanceService.capital_stock_balance encountered a connection error while hitting the /member/#{@member_id}/capital_stock_balance/#{start_date} MAPI endpoint: #{e.class.name}")
      return nil
    end

    # closing balance from end date
    begin
      closing_balance_response = @connection["member/#{@member_id}/capital_stock_balance/#{end_date}"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("MemberBalanceService.capital_stock_activity encountered a RestClient error while hitting the /member/#{@member_id}/capital_stock_balance/#{start_date} MAPI endpoint: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("MemberBalanceService.capital_stock_balance encountered a connection error while hitting the /member/#{@member_id}/capital_stock_balance/#{start_date} MAPI endpoint: #{e.class.name}")
      return nil
    end

    # get activities from date range
    begin
      activities_response = @connection["member/#{@member_id}/capital_stock_activities/#{start_date}/#{end_date}"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("MemberBalanceService.capital_stock_activity encountered a RestClient error while hitting the /member/{id}/capital_stock_activities/{from_date}/{to_date} MAPI endpoint: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("MemberBalanceService.capital_stock_balance encountered a connection error while hitting the /member/{id}/capital_stock_activities/{from_date}/{to_date} MAPI endpoint: #{e.class.name}")
      return nil
    end

    # catch JSON parsing errors
    begin
      opening_balance = JSON.parse(opening_balance_response.body).with_indifferent_access
    rescue JSON::ParserError => e
      Rails.logger.warn("MemberBalanceService.capital_stock_balance encountered a JSON parsing error when parsing opening balance from /member/#{@member_id}/capital_stock_balance/#{start_date} MAPI endpoint: #{e}")
      return nil
    end
    begin
      closing_balance = JSON.parse(closing_balance_response.body).with_indifferent_access
    rescue JSON::ParserError => e
      Rails.logger.warn("MemberBalanceService.capital_stock_balance encountered a JSON parsing error when parsing closing balance from /member/#{@member_id}/capital_stock_balance/#{end_date} MAPI endpoint: #{e}")
      return nil
    end
    begin
      activities = JSON.parse(activities_response.body).with_indifferent_access
    rescue JSON::ParserError => e
      Rails.logger.warn("MemberBalanceService.capital_stock_balance encountered a JSON parsing error when parsing activities from /member/{id}/capital_stock_activities/{from_date}/{to_date} MAPI endpoint: #{e}")
      return nil
    end

    # begin building response data
    data = {}
    data[:start_date] = opening_balance[:balance_date].to_date
    data[:start_balance] = opening_balance[:open_balance].to_i
    data[:end_date] = closing_balance[:balance_date].to_date
    data[:end_balance] = closing_balance[:close_balance].to_i
    data[:activities] = activities[:activities]

    # Tally credits and debits, as the distinction is not made by MAPI. Also format date.
    data[:total_credits] = 0
    data[:total_debits] = 0
    data[:activities].each_with_index do |row, i|
      data[:activities][i][:credit_shares] = 0
      data[:activities][i][:debit_shares] = 0
      data[:activities][i][:trans_date]= data[:activities][i][:trans_date].to_date
      shares = data[:activities][i][:share_number].to_i
      begin
        if row[:dr_cr] == 'C'
          data[:activities][i][:credit_shares] = shares
          data[:total_credits] += shares
        elsif row[:dr_cr] == 'D'
          data[:activities][i][:debit_shares] = shares
          data[:total_debits] += shares
        else
          raise StandardError, "MemberBalanceService.capital_stock_activity returned '#{row[:dr_cr]}' for share type on row number #{i}. Share type should be either 'C' for Credit or 'D' for Debit."
        end
      rescue StandardError => e
        Rails.logger.warn(e)
        return nil
      end
    end
    data
  end

  def borrowing_capacity_summary(date)

    # TODO: hit MAPI endpoint or enpoints to retrieve/construct an object similar to the fake one below. Pass date along, though it won't be used as of yet.
    begin
      data = JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', 'borrowing_capacity_summary.json'))).with_indifferent_access
    rescue JSON::ParserError => e
      Rails.logger.warn("MemberBalanceService.borrowing_capacity_summary encountered a JSON parsing error: #{e}")
      return nil
    end

    if data[:standard].length > 0 && data[:sbc].length > 0
      # first table - Standard Collateral
      begin
        standard_collateral_fields = [:count, :original_amount, :unpaid_principal, :market_value, :borrowing_capacity]
        data[:standard_credit_totals] = {}
        # build data[:standard_credit_totals] object here to account for the case where data[:standard][:collateral] comes back empty
        standard_collateral_fields.each do |field_name|
          data[:standard_credit_totals][field_name] = 0
        end
        data[:standard][:collateral].each_with_index do |row, i|
          standard_collateral_fields.each do |key|
            data[:standard_credit_totals][key] += row[key].to_i
          end
          if row[:borrowing_capacity].to_i > 0 && row[:unpaid_principal].to_i > 0
            data[:standard][:collateral][i][:bc_upb] = ((row[:borrowing_capacity].to_f / row[:unpaid_principal].to_f) * 100).round
          else
            data[:standard][:collateral][i][:bc_upb] = 0
          end
        end
        data[:net_loan_collateral] = data[:standard_credit_totals][:borrowing_capacity].to_i - data[:standard][:excluded].values.sum
        data[:standard_excess_capacity] = data[:net_loan_collateral].to_i - data[:standard][:utilized].values.reduce(:+)
      rescue => e
        Rails.logger.warn("The data[:standard] hash in MemberBalanceService.borrowing_capacity_summary is malformed in some way. It returned #{data[:standard]} and threw the following error: #{e}")
        return nil
      end

      # second table - Securities Backed Collateral
      begin
        data[:sbc_totals] = {}
        securities_backed_collateral_fields = [:total_market_value, :total_borrowing_capacity, :advances, :standard_credit, :remaining_market_value, :remaining_borrowing_capacity]
        securities_backed_collateral_fields.each do |key|
          data[:sbc_totals][key] ||= 0
          data[:sbc][:collateral].each do |row|
            data[:sbc_totals][key] += row[key].to_i
          end
        end
        data[:sbc_excess_capacity] = data[:sbc_totals][:remaining_borrowing_capacity].to_i - data[:sbc][:utilized].values.sum
        data[:total_borrowing_capacity] = data[:standard_credit_totals][:borrowing_capacity].to_i + data[:sbc_totals][:remaining_borrowing_capacity].to_i
        data[:remaining_borrowing_capacity] = data[:standard_excess_capacity].to_i + data[:sbc_excess_capacity].to_i
      rescue => e
        Rails.logger.warn("The data[:sbc] hash in MemberBalanceService.borrowing_capacity_summary is malformed in some way. It returned #{data[:sbc]} and threw the following error: #{e}")
        return nil
      end
    else
      data[:total_borrowing_capacity] = 0
      data[:remaining_borrowing_capacity] = 0
    end

    data
  end

  def settlement_transaction_account(start_date, end_date)
    daily_balance_key = ReportsController::DAILY_BALANCE_KEY # the key returned by us from MAPI to let us know a row represents balance at close of business
    start_date = start_date.to_date
    end_date = end_date.to_date

    # TODO: hit MAPI endpoint or enpoints to retrieve/construct an object similar to the fake one below. Pass date along, though it won't be used as of yet.
    begin
      data = JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', 'settlement_transaction_account.json'))).with_indifferent_access
    rescue JSON::ParserError => e
      Rails.logger.warn("MemberBalanceService.settlement_transaction_account encountered a JSON parsing error: #{e}")
      return nil
    end

    data[:activities].each_with_index do |activity, i|
      data[:activities][i][:trans_date] = activity[:trans_date].to_date
    end

    # sort the activities array by description and then by date to wind up with the proper order
    data[:activities] = data[:activities].sort do |a, b|
      if a[:trans_date] == b[:trans_date]
        if a[:descr] == daily_balance_key && b[:descr] != daily_balance_key
          -1
        elsif a[:descr] == daily_balance_key && b[:descr] == daily_balance_key
          Rails.logger.warn("MemberBalanceService.settlement_transaction_account returned an activities array that contains duplicate `end of day balance` entries for the date: #{a[:trans_date]}")
          0
        else
          1
        end
      else
        b[:trans_date] <=> a[:trans_date]
      end
    end

    # TODO: remove these lines once MAPI is rigged up - they are just used to mimic the date range functionality that will eventually be handled by MAPI
    # **************** BEGIN CODE THAT WILL BE REMOVED ****************
    # This is separated out from the above code as this whole block is going to disappear once MAPI is rigged up
    # The following all depends on the sorting above (i.e. most recent activities to oldest)
    data[:start_date] = start_date
    data[:end_date] = end_date

    # find the closest start date to in your set, with priority given to dates older than the start_date arg
    closest_start_date = nil
    start_date_in_future = false
    data[:activities].each do |activity|
      activity_date = activity[:trans_date]
      if activity_date > start_date
        closest_start_date = activity_date
      elsif activity_date == start_date
        closest_start_date = activity_date
        break
      else
        # find the next closest one, then break
        closest_start_date = activity_date
        start_date_in_future = true
        break
      end
    end

    starting_balance = 0
    data[:activities].each do |activity|
      if activity[:trans_date] == closest_start_date
        if activity[:descr] == daily_balance_key
          starting_balance = activity[:balance]
        elsif activity[:credit]
          starting_balance -= activity[:credit] unless start_date_in_future
        elsif activity[:debit]
          starting_balance += activity[:debit] unless start_date_in_future
        end
      end
    end
    data[:start_balance] = starting_balance

    # Need to calculate ending balance - just choose the ending balance that is closest in date to the end_date arg
    data[:activities].each do |activity|
      activity_date = activity[:trans_date]
      if activity_date > end_date
        # just continue
      elsif activity_date == end_date && activity[:descr] == daily_balance_key
        data[:end_balance] = activity[:balance]
        break
      elsif activity[:descr] == daily_balance_key
        # find the next closest one, then break
        data[:end_balance] = activity[:balance]
        break
      end
    end
    # Need to get rid of rows that don't fall in the date range
    data[:activities].delete_if do |activity|
      activity[:trans_date] < start_date.to_date || activity[:trans_date] > end_date.to_date
    end
    # **************** END CODE THAT WILL BE REMOVED ****************

    data
  end

end

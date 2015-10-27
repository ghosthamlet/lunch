module MAPI
  module Services
    module Member
      module SettlementTransactionAccount
        def self.sta_activities(app, member_id, from_date, to_date)
          member_id = member_id.to_i
          sta_count = 0

          sta_check_data_exist_connection_string = <<-SQL
          SELECT COUNT(*) As BALANCE_ROW_COUNT
          FROM PORTFOLIOS.STA_WEB_DETAIL
          WHERE fhlb_id = #{ActiveRecord::Base.connection.quote(member_id)}
          AND TRANS_DATE BETWEEN to_date(#{ActiveRecord::Base.connection.quote(from_date)}, 'yyyy-mm-dd')
          AND to_date(#{ActiveRecord::Base.connection.quote(to_date)}, 'yyyy-mm-dd')
          AND DESCR = 'Interest Rate / Daily Balance'
          SQL

          sta_open_balance_connection_string = <<-SQL
          SELECT ACCOUNT_NUMBER, (SUM(BALANCE) - SUM(CREDIT) + SUM(DEBIT)) OPEN_BALANCE, TRANS_DATE
          FROM PORTFOLIOS.STA_WEB_DETAIL
          WHERE fhlb_id = #{ActiveRecord::Base.connection.quote(member_id)}
          AND TRANS_DATE =
            ( select min(trans_date) from portfolios.sta_web_detail
              WHERE fhlb_id = #{ActiveRecord::Base.connection.quote(member_id)}
              AND DESCR = 'Interest Rate / Daily Balance'
              AND trans_date >= to_date(#{ActiveRecord::Base.connection.quote(from_date)}, 'yyyy-mm-dd')
              AND trans_date <= to_date(#{ActiveRecord::Base.connection.quote(to_date)}, 'yyyy-mm-dd')
            )
          GROUP BY ACCOUNT_NUMBER, TRANS_DATE
          SQL

          sta_open_adjustment_connection_string = <<-SQL
          SELECT ACCOUNT_NUMBER, count(*) ADJUST_TRANS_COUNT, MIN(TRANS_DATE) MIN_DATE,
          (SUM(CREDIT) - SUM(DEBIT)) AMOUNT_TO_ADJUST
          FROM PORTFOLIOS.STA_WEB_DETAIL
          WHERE FHLB_ID = #{ActiveRecord::Base.connection.quote(member_id)}
          AND TRANS_DATE >= to_date(#{ActiveRecord::Base.connection.quote(from_date)}, 'yyyy-mm-dd')
          AND TRANS_DATE <
            ( select min(trans_date) from portfolios.sta_web_detail
              WHERE fhlb_id = #{ActiveRecord::Base.connection.quote(member_id)}
              AND DESCR = 'Interest Rate / Daily Balance'
              AND trans_date >= to_date(#{ActiveRecord::Base.connection.quote(from_date)}, 'yyyy-mm-dd')
              AND trans_date <= to_date(#{ActiveRecord::Base.connection.quote(to_date)}, 'yyyy-mm-dd')
              GROUP BY ACCOUNT_NUMBER
            )
          AND DESCR != 'Interest Rate / Daily Balance'
          GROUP BY ACCOUNT_NUMBER
          SQL

          sta_close_balance_connection_string = <<-SQL
          SELECT ACCOUNT_NUMBER, BALANCE, TRANS_DATE
          FROM PORTFOLIOS.STA_WEB_DETAIL
          WHERE fhlb_id = #{ActiveRecord::Base.connection.quote(member_id)}
          AND DESCR = 'Interest Rate / Daily Balance'
          AND TRANS_DATE =
            ( select max(trans_date) from portfolios.sta_web_detail
              WHERE fhlb_id = #{ActiveRecord::Base.connection.quote(member_id)}
              AND DESCR = 'Interest Rate / Daily Balance'
              AND trans_date <= to_date(#{ActiveRecord::Base.connection.quote(to_date)}, 'yyyy-mm-dd')
              AND trans_date >= to_date(#{ActiveRecord::Base.connection.quote(from_date)}, 'yyyy-mm-dd')
            )
          SQL

          sta_activities_connection_string = <<-SQL
          SELECT TRANS_DATE, REFNUMBER, DESCR, DEBIT, CREDIT, RATE, BALANCE
          FROM PORTFOLIOS.STA_WEB_DETAIL
          WHERE fhlb_id = #{ActiveRecord::Base.connection.quote(member_id)}
          AND trans_date >= to_date(#{ActiveRecord::Base.connection.quote(from_date)}, 'yyyy-mm-dd')
          AND trans_date <= to_date(#{ActiveRecord::Base.connection.quote(to_date)}, 'yyyy-mm-dd')
          SQL

          from_date = from_date.to_date
          to_date = to_date.to_date
          open_balance_hash = {}
          open_balance_adjust_hash  = {}
          close_balance_hash  = {}
          activities_array = []
          sta_count = 0

          if app.settings.environment == :production
            # get the count to make sure there is record, at the same time, get the max and min date with balances to pass into subsequence balance
            sta_count_cursor = ActiveRecord::Base.connection.execute(sta_check_data_exist_connection_string)
            while row = sta_count_cursor.fetch_hash()
              sta_count = row['BALANCE_ROW_COUNT']
              break
            end
            if sta_count == 0
              # halt 404, "No Data Found"
              {}
            else
              sta_open_cursor = ActiveRecord::Base.connection.execute(sta_open_balance_connection_string)
              while row = sta_open_cursor.fetch_hash()
                open_balance_hash  = row
                break
              end

              sta_open_adjust_cursor = ActiveRecord::Base.connection.execute(sta_open_adjustment_connection_string)
              while row = sta_open_adjust_cursor.fetch_hash()
                open_balance_adjust_hash  = row
                break
              end
              sta_close_cursor = ActiveRecord::Base.connection.execute(sta_close_balance_connection_string)
              while row = sta_close_cursor.fetch_hash()
                close_balance_hash  = row
                break
              end
              sta_activities_cursor = ActiveRecord::Base.connection.execute(sta_activities_connection_string)
              while row = sta_activities_cursor.fetch_hash()
                activities_array.push(row)
              end
            end

          else
            sta_count_hash = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_sta_count.json')))
            sta_count = sta_count_hash['BALANCE_ROW_COUNT'].to_i
            if sta_count == 0
              # return {} to the caller to indicate no data found
              {}
            else
              open_balance_adjust_hash = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_sta_activities_open_balance_adjust_value.json')))
              open_balance_hash = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_sta_activities_open_balance_earliest.json')))
              if to_date - from_date > 4
                activities_array = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_sta_activities.json')))
                close_balance_hash = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_sta_activities_close_balance.json')))
              else
                activities_array = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_sta_activities_small_set.json')))
                close_balance_hash = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_sta_activities_close_balance_small_set.json')))
              end
              open_balance_hash['TRANS_DATE'] = from_date
              close_balance_hash['TRANS_DATE'] = to_date
              open_balance_adjust_hash['MIN_DATE'] = from_date
              count = 0
              last_date = activities_array.first['TRANS_DATE']
              activities_array.collect!.with_index do |activity, i|
                count += 1 if i == 0 || last_date != activity['TRANS_DATE']
                new_date = from_date.to_date + count.days
                if new_date > to_date
                  new_date = to_date
                end
                last_date = activity['TRANS_DATE']
                activity['TRANS_DATE'] = new_date
                activity
              end
              # add fake "daily balance" rows to the end of the activities_array so we have data for the whole date range
              ((activities_array.last['TRANS_DATE'] + 1.day)..to_date).each do |date|
                day_of_week = date.wday
                if day_of_week != 0 && day_of_week != 6
                  activities_array.push({
                                            "TRANS_DATE" =>date,
                                            "DESCR" =>"Interest Rate / Daily Balance",
                                            "REFNUMBER" =>nil,
                                            "DEBIT" =>0,
                                            "CREDIT" =>0,
                                            "RATE" =>activities_array.last['RATE'],
                                            "BALANCE" =>activities_array.last['BALANCE']
                                        })
                end
              end
            end
          end

          if sta_count ==  0
            {}
          else
            open_balance = open_balance_hash['OPEN_BALANCE'].to_f || 0
            open_balance_date = (open_balance_hash['TRANS_DATE'] || from_date).to_date # adjust to earliest date with transaction records or balances
            close_balance = close_balance_hash['BALANCE'].to_f || 0
            close_balance_date = (close_balance_hash['TRANS_DATE'] || to_date).to_date  # adjust to the latest date with transaction records or balances

            # adjusting open balance final where the between from date and 1st balance date has transaction
            if open_balance_adjust_hash.count() > 0
              open_balance_adjust = open_balance_adjust_hash['AMOUNT_TO_ADJUST']|| 0
              open_balance_date_adjust = (open_balance_adjust_hash['MIN_DATE'] || from_date).to_date
              open_balance = open_balance - open_balance_adjust
              open_balance_date = open_balance_date_adjust
            end

            activities_formatted = []
            # caller expect end point to return null instead of 0 value for credit, debit and balances
            activities_array.each do |row|
              credit = row['CREDIT'].to_f
              if credit == 0
                credit = nil
              end
              debit = row['DEBIT'].to_f
              if debit == 0
                debit = nil
              end
              balance_temp = row['BALANCE'].to_f
              description = row['DESCR']
              if (balance_temp == 0 && description != 'Interest Rate / Daily Balance')
                balance_temp = nil
              end
              hash = {'trans_date' => row['TRANS_DATE'].to_date,
                      'refnumber' => row['REFNUMBER'],
                      'descr' => description,
                      'debit' => debit,
                      'credit' => credit,
                      'rate' => row['RATE'].to_f,
                      'balance' => balance_temp
              }
              activities_formatted.push(hash)
            end
            {
                start_balance: open_balance.to_f.round(4),
                start_date: open_balance_date,
                end_balance: close_balance.to_f.round(4),
                end_date: close_balance_date,
                activities: activities_formatted
            }.to_json
          end
        end

        def self.current_sta_rate(app, member_id)
          member_id = member_id.to_i
          current_sta_data = {account_number: nil, rate: nil, date: nil}
          if app.settings.environment == :production
            current_sta_rate_query = <<-SQL
            SELECT RATE, TRANS_DATE
            FROM PORTFOLIOS.STA_WEB_DETAIL
              WHERE FHLB_ID = #{ActiveRecord::Base.connection.quote(member_id)}
              AND  DESCR = 'Interest Rate / Daily Balance'
              AND TRANS_DATE =
                (SELECT max(TRANS_DATE) FROM PORTFOLIOS.STA_WEB_DETAIL WHERE FHLB_ID = #{ActiveRecord::Base.connection.quote(member_id)}
                AND TRANS_DATE <= to_date(sysdate))
            SQL
            current_sta_rate_cursor = ActiveRecord::Base.connection.execute(current_sta_rate_query)
            row = current_sta_rate_cursor.fetch_hash() || {}
            current_sta_data[:rate] = row['RATE']
            current_sta_data[:date] = row['TRANS_DATE']
          else
            current_sta_data = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'current_sta_rate.json'))).with_indifferent_access
            current_sta_data[:date] = MAPI::Services::Member::CashProjections::Private.fake_as_of_date
          end
          current_sta_data[:rate] = current_sta_data[:rate].to_f if current_sta_data[:rate]
          current_sta_data[:date] = current_sta_data[:date].to_date if current_sta_data[:date]
          current_sta_data
        end
      end
    end
  end
end
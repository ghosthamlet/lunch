module MAPI
  module Services
    module Member
      module SecuritiesServicesStatements
        include MAPI::Shared::Utils
        include MAPI::Shared::Constants

        MAPPING={
            MAINT_FEE_CHARGE:             'account_maintenance/total',

            REG_OF_CERT_CHARGEPERTRANS:   'certifications/cost',
            REG_OF_CERT_TRANS:            'certifications/count',
            REG_OF_CERT_CHARGE:           'certifications/total',

            CP_CITY:                      'contact/city',
            CP_NAME:                      'contact/name',
            CP_STATE:                     'contact/state',
            CP_ZIP_CODE:                  'contact/zip',

            STA_CHARGE_DATE:              'debit_date',

            SPECIAL_HAND_CHARGEPERHOURS:  'handling/cost',
            SPECIAL_HANDLING_HOURS:       'handling/count',
            SPECIAL_HANDLING_CHARGE:      'handling/total',

            PI_CHARGEPERTRANS:            'income_disbursement/cost',
            PI_TRANS:                     'income_disbursement/count',
            PI_CHARGE:                    'income_disbursement/total',

            FHLB_ID:                      'member_id',
            SSX_BTC_DATE:                 'month_ending',

            PLEDGE_CHANGE_CHARGEPERTRANS: 'pledge_status_change/cost',
            PLEDGE_CHANGE_TRANS:          'pledge_status_change/count',
            PLEDGE_CHANGE_CHARGE:         'pledge_status_change/total',

            RESEARCH_PROJECTS_CHARGE:     'research/total',
            RESEARCH_PROJECTS_HOURS:      'research/count',
            RESEARCH_PROJ_CHARGEPERHOURS: 'research/cost',

            DEP_SEC_LOTS:                 'securities_fees/dtc/count',
            DEP_SEC_CHARGEPERLOTS:        'securities_fees/dtc/cost',
            DEP_SEC_LOT_CHARGE:           'securities_fees/dtc/total',
            EURO_CD_CHARGEPERPAR1000:     'securities_fees/euroclear/cost',
            EURO_CD_PAR:                  'securities_fees/euroclear/count',
            EURO_CD_PAR_CHARGE:           'securities_fees/euroclear/total',
            FRB_SEC_CHARGEPERLOTS:        'securities_fees/fed/cost',
            FRB_SEC_LOTS:                 'securities_fees/fed/count',
            FRB_SEC_LOT_CHARGE:           'securities_fees/fed/total',
            PHYSICAL_SEC_CHARGEPERLOTS:   'securities_fees/funds/cost',
            PHYSICAL_SEC_LOTS:            'securities_fees/funds/count',
            PHYSICAL_SEC_LOT_CHARGE:      'securities_fees/funds/total',

            STA_ACCOUNT_NUM:              'sta_account_number',
            TOTAL_STATEMENT_CHARGE:       'total',

            DEP_SEC_CHARGEPERTRANS:       'transaction_fees/dtc/cost',
            DEP_SEC_TRANS:                'transaction_fees/dtc/count',
            DEP_SEC_TRANS_CHARGE:         'transaction_fees/dtc/total',
            EURO_CD_CHARGEPERTRANS:       'transaction_fees/euroclear/cost',
            EURO_CD_TRANS:                'transaction_fees/euroclear/count',
            EURO_CD_TRANS_CHARGE:         'transaction_fees/euroclear/total',
            FRB_SEC_CHARGEPERTRANS:       'transaction_fees/fed/cost',
            FRB_SEC_TRANS:                'transaction_fees/fed/count',
            FRB_SEC_TRANS_CHARGE:         'transaction_fees/fed/total',
            PHYSICAL_SEC_CHARGEPERTRANS:  'transaction_fees/funds/cost',
            PHYSICAL_SEC_TRANS:           'transaction_fees/funds/count',
            PHYSICAL_SEC_TRANS_CHARGE:    'transaction_fees/funds/total'
        }.with_indifferent_access

        def self.statement_sql(fhlb_id, report_date)
          <<-SQL
          SELECT #{MAPPING.keys.join(',')}
          FROM SAFEKEEPING.SECURITIES_FEES_STMT_WEB
          WHERE FHLB_ID = #{fhlb_id} AND (SSX_BTC_DATE = #{quote(report_date)})
          SQL
        end

        def self.available_statements_sql(fhlb_id)
          <<-SQL
          SELECT DISTINCT SSX_BTC_DATE as report_end_date, to_char(ssx_btc_date, 'Month') || ' ' || to_char(ssx_btc_date, 'YYYY') as month_year
          FROM SAFEKEEPING.SECURITIES_FEES_STMT_WEB WHERE FHLB_ID = #{fhlb_id}
          ORDER BY SSX_BTC_DATE DESC
          SQL
        end

        def self.available_statements(logger, env, fhlb_id)
          if env == :production
            fetch_hashes(logger, available_statements_sql(fhlb_id))
          else
            fake('securities_services_statements_available')
          end
        end

        def self.multi_level_merge(rhs, keys, value)
          key = keys.shift
          rhs[key] = keys.empty? ? value : multi_level_merge(rhs[key] || {}, keys, value)
          rhs
        end

        def self.multi_level_transform(original, mapping)
          original.each_with_object({}) do |(key, value), result|
            multi_level_merge(result, mapping[key].split('/'), value)
          end
        end

        def self.statement(logger, env, fhlb_id, report_date)
          from_db = env == :production ? fetch_hashes(logger,statement_sql(fhlb_id, report_date)) : fake('securities_services_statements')
          from_db.map{ |record| multi_level_transform(record.with_indifferent_access, MAPPING) }
        end
      end
    end
  end
end

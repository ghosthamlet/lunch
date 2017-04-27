require 'rails_helper'

RSpec.describe Admin::RulesController, :type => :controller do
  login_user(admin: true)
  it_behaves_like 'an admin controller'

  RSpec.shared_examples 'a RulesController action with before_action methods' do
    it 'sets the active nav to :rules' do
      expect(controller).to receive(:set_active_nav).with(:rules)
      call_action
    end
    context 'when the current user can edit trade rules' do
      allow_policy :web_admin, :edit_trade_rules?
      it 'sets `@can_edit_trade_rules` to true' do
        call_action
        expect(assigns[:can_edit_trade_rules]).to be true
      end
    end
    context 'when the current user cannot edit trade rules' do
      deny_policy :web_admin, :edit_trade_rules?
      it 'sets `@can_edit_trade_rules` to false' do
        begin
          call_action
        rescue Pundit::NotAuthorizedError
        end
        expect(assigns[:can_edit_trade_rules]).to be false
      end
    end
  end

  RSpec.shared_examples 'it checks the edit_trade_rules? web_admin policy' do
    before { allow(subject).to receive(:authorize).and_call_original }
    it 'checks if the current user is allowed to edit trade rules' do
      expect(subject).to receive(:authorize).with(:web_admin, :edit_trade_rules?)
      call_action
    end
    it 'raises any errors raised by checking to see if the user is authorized to modify the advance' do
      error = Pundit::NotAuthorizedError
      allow(subject).to receive(:authorize).and_raise(error)
      expect{call_action}.to raise_error(error)
    end
  end
  
  RSpec.shared_examples 'a RulesController table column that is a text field' do |name, &context_block|
    it 'has a `type` of :text_field' do
      expect(column[:type]).to eq(:text_field)
    end
    it "has a `name` of `#{name}`" do
      expect(column[:name]).to eq(name)
    end
    it 'has a `value_type` of :number' do
      expect(column[:value_type]).to eq(:number)
    end
    it 'has `options` of `{html: false}`' do
      expect(column[:options][:html]).to be false
    end
    context 'when the user can edit trade rules' do
      allow_policy :web_admin, :edit_trade_rules?
      it 'sets `disabled` to false' do
        expect(column[:disabled]).to be false
      end
    end
    context 'when the user cannot edit trade rules' do
      deny_policy :web_admin, :edit_trade_rules?
      it 'sets `disabled` to false' do
        expect(column[:disabled]).to be true
      end
    end
  end

  describe 'GET limits' do
    let(:global_limit_data) {{
      shareholder_total_daily_limit: double('total daily limit'),
      shareholder_web_daily_limit: double('web daily limit')
    }}
    let(:term_limit_data) {{
      term: described_class::VALID_TERMS.sample,
      min_online_advance: double('min online advance', to_i: nil),
      term_daily_limit: double('term daily limit', to_i: nil)
    }}
    let(:etransact_service) { instance_double(EtransactAdvancesService, limits: [term_limit_data], settings: global_limit_data)}
    let(:sentinel) { SecureRandom.hex }
    let(:call_action) { get :limits }
    before do
      allow(EtransactAdvancesService).to receive(:new).and_return(etransact_service)
      allow(controller).to receive(:fhlb_add_unit_to_table_header)
    end
    it_behaves_like 'a RulesController action with before_action methods'

    [:settings, :limits].each do |method|
      it "raises an error if EtransactAdvancesService#{method} returns nil" do
        allow(etransact_service).to receive(method).and_return(nil)
        expect{call_action}.to raise_error('There has been an error and Admin::RulesController#limits has encountered nil. Check error logs.')
      end
    end
    describe '`@global_limits`' do
      let(:global_limits) { call_action; assigns[:global_limits] }
      it 'contains two rows' do
        expect(global_limits[:rows].length).to eq(2)
      end
      describe 'the `per_member` row' do
        let(:per_member_row) { global_limits[:rows][0] }
        describe 'the first column data' do
          it 'calls `fhlb_add_unit_to_table_header` with the proper translation and unit' do
            expect(controller).to receive(:fhlb_add_unit_to_table_header).with(I18n.t('admin.term_rules.daily_limit.per_member'), '$')
            per_member_row
          end
          it 'has a `value` equal to that returned by `fhlb_add_unit_to_table_header`' do
            allow(controller).to receive(:fhlb_add_unit_to_table_header).with(I18n.t('admin.term_rules.daily_limit.per_member'), '$').and_return(sentinel)
            expect(per_member_row[:columns][0][:value]).to eq(sentinel)
          end
        end
        describe 'the second column data' do
          it_behaves_like 'a RulesController table column that is a text field', 'global_limits[shareholder_total_daily_limit]' do
            let(:column) { per_member_row[:columns][1] }
          end
          it 'has a `value` of the global_limit_data[:shareholder_total_daily_limit]' do
            expect(per_member_row[:columns][1][:value]).to eq(global_limit_data[:shareholder_total_daily_limit])
          end
        end
      end
      describe 'the `all_member` row' do
        let(:all_member_row) { global_limits[:rows][1] }
        describe 'the first column data' do
          it 'calls `fhlb_add_unit_to_table_header` with the proper translation and unit' do
            expect(controller).to receive(:fhlb_add_unit_to_table_header).with(I18n.t('admin.term_rules.daily_limit.all_member'), '$')
            all_member_row
          end
          it 'has a `value` equal to that returned by `fhlb_add_unit_to_table_header`' do
            allow(controller).to receive(:fhlb_add_unit_to_table_header).with(I18n.t('admin.term_rules.daily_limit.all_member'), '$').and_return(sentinel)
            expect(all_member_row[:columns][0][:value]).to eq(sentinel)
          end
        end
        describe 'the second column data' do
          it_behaves_like 'a RulesController table column that is a text field', 'global_limits[shareholder_web_daily_limit]' do
            let(:column) { all_member_row[:columns][1] }
          end
          it 'has a `value` of the global_limit_data[:shareholder_web_daily_limit]' do
            expect(all_member_row[:columns][1][:value]).to eq(global_limit_data[:shareholder_web_daily_limit])
          end
        end
      end
    end
    describe '`@term_limits`' do
      let(:term_limits) { call_action; assigns[:term_limits] }
      describe 'column_headings' do
        it 'calls `fhlb_add_unit_to_table_header` with the minimum online translation and unit' do
          expect(controller).to receive(:fhlb_add_unit_to_table_header).with(I18n.t('admin.term_rules.daily_limit.minimum_online'), '$')
          term_limits
        end
        it 'calls `fhlb_add_unit_to_table_header` with the daily limit translation and unit' do
          expect(controller).to receive(:fhlb_add_unit_to_table_header).with(I18n.t('admin.term_rules.daily_limit.daily'), '$')
          term_limits
        end
        it 'contains the proper column_headings' do
          minimum_online_heading = double('minimum online heading')
          daily_limit_heading = double('daily limit heading')
          allow(controller).to receive(:fhlb_add_unit_to_table_header).with(I18n.t('admin.term_rules.daily_limit.minimum_online'), '$').and_return(minimum_online_heading)
          allow(controller).to receive(:fhlb_add_unit_to_table_header).with(I18n.t('admin.term_rules.daily_limit.daily'), '$').and_return(daily_limit_heading)
          expect(term_limits[:column_headings]).to eq(['', minimum_online_heading, daily_limit_heading])
        end
      end
      it 'raises an error if it encounters an unrecognized `:term` in one the etransact_service.limits buckets' do
        term_limit_data[:term] = sentinel
        expect{term_limits}.to raise_error("There has been an error and Admin::RulesController#limits has encountered an etransact_service.limits bucket with an invalid term: #{sentinel}")
      end
      describe 'rows' do
        let(:term_limit_data_buckets) do
          data = []
          described_class::VALID_TERMS.each do |term|
            data << {
              term: term,
              min_online_advance: instance_double(Integer, to_i: nil),
              term_daily_limit: instance_double(Integer, to_i: nil)
            }
          end
          data
        end
        before { allow(etransact_service).to receive(:limits).and_return(term_limit_data_buckets) }
        it 'contains as many rows as etransact_service.limits buckets' do
          expect(term_limits[:rows].length).to eq(term_limit_data_buckets.length)
        end
        described_class::VALID_TERMS.each_with_index do |term, i|
          describe "the `#{term}` term row" do
            let(:term_row) { term_limits[:rows][i] }

            it "has a first column value with the correct translation for the `#{term}` term" do
              expect(term_row[:columns][0][:value]).to eq(I18n.t("admin.term_rules.daily_limit.dates.#{term}"))
            end
            describe 'the second column' do
              it_behaves_like 'a RulesController table column that is a text field', "term_limits[#{term}][min_online_advance]" do
                let(:column) { term_row[:columns][1] }
              end
              it 'has a `value` that is the result of calling `to_i` on the bucket\'s `min_online_advance`' do
                allow(term_limit_data_buckets[i][:min_online_advance]).to receive(:to_i).and_return(sentinel)
                expect(term_row[:columns][1][:value]).to eq(sentinel)
              end
            end
            describe 'the third column' do
              it_behaves_like 'a RulesController table column that is a text field', "term_limits[#{term}][term_daily_limit]" do
                let(:column) { term_row[:columns][2] }
              end
              it 'has a `value` that is the result of calling `to_i` on the bucket\'s `term_daily_limit`' do
                allow(term_limit_data_buckets[i][:term_daily_limit]).to receive(:to_i).and_return(sentinel)
                expect(term_row[:columns][2][:value]).to eq(sentinel)
              end
            end
          end
        end
      end
    end
  end

  describe 'PUT `update_limits`' do
    allow_policy :web_admin, :edit_trade_rules?

    let(:global_limits_param) { {SecureRandom.hex => 'some value'} }
    let(:term_limits_param) { {SecureRandom.hex => 'some value'} }
    let(:etransact_service) { instance_double(EtransactAdvancesService, update_term_limits: {}, update_settings: {})}
    let(:call_action) { put(:update_limits, {global_limits: global_limits_param, term_limits: term_limits_param}) }

    before do
      allow(EtransactAdvancesService).to receive(:new).and_return(etransact_service)
      allow(controller).to receive(:set_flash_message)
    end

    it_behaves_like 'a RulesController action with before_action methods'
    it_behaves_like 'it checks the edit_trade_rules? web_admin policy'
    it 'creates a new instance of EtransactAdvancesService with the request' do
      expect(EtransactAdvancesService).to receive(:new).with(request).and_return(etransact_service)
      call_action
    end
    describe 'updating etransact settings' do
      it 'calls `update_settings` on the EtransactAdvancesService with the `global_limits` param' do
        expect(etransact_service).to receive(:update_settings).with(global_limits_param).and_return({})
        call_action
      end
      it 'raises an error if the `update_settings` method returns nil' do
        allow(etransact_service).to receive(:update_settings).with(global_limits_param).and_return(nil)
        expect{call_action}.to raise_error("There has been an error and Admin::RulesController#update_limits has encountered nil")
      end
    end
    describe 'updating etransact limits' do
      it 'calls `update_term_limits` on the EtransactAdvancesService with the `term_limits` param' do
        expect(etransact_service).to receive(:update_term_limits).with(term_limits_param).and_return({})
        call_action
      end
      it 'raises an error if the `update_term_limits` method returns nil' do
        allow(etransact_service).to receive(:update_term_limits).with(term_limits_param).and_return(nil)
        expect{call_action}.to raise_error("There has been an error and Admin::RulesController#update_limits has encountered nil")
      end
    end
    it 'calls the `set_flash_message` method with the results from `update_term_limits` and `update_settings`' do
      term_limits_results = instance_double(Hash)
      settings_results = instance_double(Hash)
      allow(etransact_service).to receive(:update_term_limits).and_return(term_limits_results)
      allow(etransact_service).to receive(:update_settings).and_return(settings_results)
      expect(controller).to receive(:set_flash_message).with([settings_results, term_limits_results])
      call_action
    end
    it 'redirects to the `rules_term_limits_url`' do
      call_action
      expect(response).to redirect_to(rules_term_limits_url)
    end
  end

  describe 'GET advance_availability_status' do
    let(:call_action) { get :advance_availability_status }
    it_behaves_like 'a RulesController action with before_action methods'
  end

  describe 'GET advance_availability_by_term' do
    let(:call_action) { get :advance_availability_by_term }
    it_behaves_like 'a RulesController action with before_action methods'
  end

  describe 'GET advance_availability_by_member' do
    let(:call_action) { get :advance_availability_by_member }
    it_behaves_like 'a RulesController action with before_action methods'
  end

  describe 'GET rate_bands' do
    let(:sentinel) { SecureRandom.hex }
    let(:term) { described_class::VALID_TERMS.sample }
    let(:rate_bands) {{
      term => {'LOW_BAND_OFF_BP' => double('LOW_BAND_OFF_BP', to_i: nil),
      'LOW_BAND_WARN_BP' => double('LOW_BAND_WARN_BP', to_i: nil),
      'HIGH_BAND_WARN_BP' => double('HIGH_BAND_WARN_BP', to_i: nil),
      'HIGH_BAND_OFF_BP' => double('HIGH_BAND_OFF_BP', to_i: nil)}
    }}
    let(:rates_service) { instance_double(RatesService, rate_bands: rate_bands)}
    let(:call_action) { get :rate_bands }

    before do
      allow(RatesService).to receive(:new).with(request).and_return(rates_service)
    end

    it_behaves_like 'a RulesController action with before_action methods'
    it 'creates a new instance of the RatesService with the request' do
      expect(RatesService).to receive(:new).with(request).and_return(rates_service)
      call_action
    end
    it 'calls `rate_bands` on the instance of RatesService' do
      expect(rates_service).to receive(:rate_bands).and_return(rate_bands)
      call_action
    end
    it 'raises an error if `rate_bands` returns nil' do
      allow(rates_service).to receive(:rate_bands).and_return(nil)
      expect{call_action}.to raise_error('There has been an error and Admin::RulesController#rate_bands has encountered nil')
    end
    describe '`@rate_bands`' do
      let(:rate_band_var) { call_action; assigns[:rate_bands] }
      describe 'column_headings' do
        let(:translated_string) { double('translation') }
        before { allow(controller).to receive(:t).and_call_original }
        it 'contains the proper translations for the column headings' do
          expect(rate_band_var[:column_headings]).to eq(
            ['', I18n.t('admin.term_rules.rate_bands.low_shutdown_html'), I18n.t('admin.term_rules.rate_bands.low_warning_html'),
             I18n.t('admin.term_rules.rate_bands.high_warning_html'), I18n.t('admin.term_rules.rate_bands.high_shutdown_html')]
          )
        end
        ['low_shutdown_html', 'low_warning_html', 'high_warning_html', 'high_shutdown_html'].each do |translation|
          it "ensures the translation for `#{translation}` is html safe" do
            allow(controller).to receive(:t).with("admin.term_rules.rate_bands.#{translation}").and_return(translated_string)
            expect(translated_string).to receive(:html_safe)
            call_action
          end
        end
      end
      it 'raises an error if it encounters an unrecognized `:term` in one of the rates_service.rate_bands keys' do
        rate_bands[sentinel] = {}
        expect{rate_band_var}.to raise_error("There has been an error and Admin::RulesController#rate_bands has encountered a RatesService.rate_bands bucket with an invalid term: #{sentinel}")
      end
      it 'ignores rate_band info for the `overnight` term' do
        rate_bands['overnight'] = {}
        expect(rate_band_var[:rows].length).to eq(1)
      end
      describe 'rows' do
        let(:rate_bands) do
          data = {}
          described_class::VALID_TERMS.each do |term|
            data[term] = {'LOW_BAND_OFF_BP' => double('LOW_BAND_OFF_BP', to_i: nil),
                          'LOW_BAND_WARN_BP' => double('LOW_BAND_WARN_BP', to_i: nil),
                          'HIGH_BAND_WARN_BP' => double('HIGH_BAND_WARN_BP', to_i: nil),
                          'HIGH_BAND_OFF_BP' => double('HIGH_BAND_OFF_BP', to_i: nil)}
          end
          data
        end
        before { allow(rates_service).to receive(:rate_bands).and_return(rate_bands) }
        it 'contains as many rows as rates_service.rate_bands keys' do
          expect(rate_band_var[:rows].length).to eq(rate_bands.keys.length)
        end
        described_class::VALID_TERMS.each_with_index do |term, i|
          describe "the `#{term}` term row" do
            let(:term_row) { rate_band_var[:rows][i] }

            it "has a first column value with the correct translation for the `#{term}` term" do
              translation = term == 'open' ? 'admin.term_rules.daily_limit.dates.open' : "dashboard.quick_advance.table.axes_labels.#{term}"
              expect(term_row[:columns][0][:value]).to eq(I18n.t(translation))
            end
            describe 'the second column' do
              it_behaves_like 'a RulesController action with before_action methods',  "rate_bands[#{term}][LOW_BAND_OFF_BP]" do
                let(:column) { term_row[:columns][1] }
              end
              it 'has a `value` that is the result of calling `to_i` on the bucket\'s `LOW_BAND_OFF_BP`' do
                allow(rate_bands[term]['LOW_BAND_OFF_BP']).to receive(:to_i).and_return(sentinel)
                expect(term_row[:columns][1][:value]).to eq(sentinel)
              end
            end
            describe 'the third column' do
              it_behaves_like 'a RulesController action with before_action methods',  "rate_bands[#{term}][LOW_BAND_WARN_BP]" do
                let(:column) { term_row[:columns][2] }
              end
              it 'has a `value` that is the result of calling `to_i` on the bucket\'s `LOW_BAND_WARN_BP`' do
                allow(rate_bands[term]['LOW_BAND_WARN_BP']).to receive(:to_i).and_return(sentinel)
                expect(term_row[:columns][2][:value]).to eq(sentinel)
              end
            end
            describe 'the fourth column' do
              it_behaves_like 'a RulesController action with before_action methods',  "rate_bands[#{term}][HIGH_BAND_WARN_BP]" do
                let(:column) { term_row[:columns][3] }
              end
              it 'has a `value` that is the result of calling `to_i` on the bucket\'s `HIGH_BAND_WARN_BP`' do
                allow(rate_bands[term]['HIGH_BAND_WARN_BP']).to receive(:to_i).and_return(sentinel)
                expect(term_row[:columns][3][:value]).to eq(sentinel)
              end
            end
            describe 'the fifth column' do
              it_behaves_like 'a RulesController action with before_action methods',  "rate_bands[#{term}][HIGH_BAND_OFF_BP]" do
                let(:column) { term_row[:columns][4] }
              end
              it 'has a `value` that is the result of calling `to_i` on the bucket\'s `HIGH_BAND_OFF_BP`' do
                allow(rate_bands[term]['HIGH_BAND_OFF_BP']).to receive(:to_i).and_return(sentinel)
                expect(term_row[:columns][4][:value]).to eq(sentinel)
              end
            end
          end
        end
      end
    end
  end

  describe 'PUT update_rate_bands' do
    allow_policy :web_admin, :edit_trade_rules?

    let(:rate_bands_param) { {SecureRandom.hex => 'some value'} }
    let(:rates_service) { instance_double(RatesService, update_rate_bands: {}) }
    let(:call_action) { put(:update_rate_bands, {rate_bands: rate_bands_param}) }

    before do
      allow(RatesService).to receive(:new).and_return(rates_service)
      allow(controller).to receive(:set_flash_message)
    end

    it_behaves_like 'a RulesController action with before_action methods'
    it_behaves_like 'it checks the edit_trade_rules? web_admin policy'
    it 'creates a new instance of RatesService with the request' do
      expect(RatesService).to receive(:new).with(request).and_return(rates_service)
      call_action
    end
    describe 'updating the rate bands' do
      it 'calls `update_rate_bands` on the RatesService with the `rate_bands` param' do
        expect(rates_service).to receive(:update_rate_bands).with(rate_bands_param).and_return({})
        call_action
      end
      it 'raises an error if the `update_term_limits` method returns nil' do
        allow(rates_service).to receive(:update_rate_bands).with(rate_bands_param).and_return(nil)
        expect{call_action}.to raise_error("There has been an error and Admin::RulesController#update_rate_bands has encountered nil")
      end
    end
    it 'calls the `set_flash_message` method with the results from `update_rate_bands`' do
      rate_bands_results = instance_double(Hash)
      allow(rates_service).to receive(:update_rate_bands).and_return(rate_bands_results)
      expect(controller).to receive(:set_flash_message).with(rate_bands_results)
      call_action
    end
    it 'redirects to the `rules_rate_bands_url`' do
      call_action
      expect(response).to redirect_to(rules_rate_bands_url)
    end
  end

  describe 'private methods' do
    describe '`set_flash_message`' do
      let(:result) { {} }
      let(:result_with_errors) {{error: double('some error')}}
      context 'when a single result set is passed' do
        it 'sets the `flash[:error]` message if the result set contains an error message' do
          subject.send(:set_flash_message, result_with_errors)
          expect(flash[:error]).to eq(I18n.t('admin.term_rules.messages.error'))
        end
        it 'sets the `flash[:notice] message` if the result set does not contain an error message' do
          subject.send(:set_flash_message, result)
          expect(flash[:notice]).to eq(I18n.t('admin.term_rules.messages.success'))
        end
      end
      context 'when multiple result sets are passed' do
        it 'sets the `flash[:error]` message if any of the passed result sets contains an error message' do
          subject.send(:set_flash_message, [result, result_with_errors, result])
          expect(flash[:error]).to eq(I18n.t('admin.term_rules.messages.error'))
        end
        it 'sets the `flash[:notice] message` if none of the result sets contain an error message' do
          subject.send(:set_flash_message, [result, result, result])
          expect(flash[:notice]).to eq(I18n.t('admin.term_rules.messages.success'))
        end
      end
    end
  end
end
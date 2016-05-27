require 'rails_helper'
include CustomFormattingHelper

RSpec.describe SecuritiesController, type: :controller do
  login_user

  describe 'requests hitting MemberBalanceService' do
    let(:member_balance_service_instance) { double('MemberBalanceServiceInstance') }

    before do
      allow(MemberBalanceService).to receive(:new).and_return(member_balance_service_instance)
    end

    describe 'GET manage' do
      let(:security) do
        security = {}
        [:cusip, :description, :custody_account_type, :eligibility, :maturity_date, :authorized_by, :current_par, :borrowing_capacity].each do |attr|
          security[attr] = double(attr.to_s)
        end
        security
      end
      let(:call_action) { get :manage }
      let(:securities) { [security] }
      let(:status) { double('status') }
      before { allow(member_balance_service_instance).to receive(:managed_securities).and_return(securities) }
      it_behaves_like 'a user required action', :get, :manage
      it_behaves_like 'a controller action with an active nav setting', :manage, :securities
      it 'renders the manage view' do
        call_action
        expect(response.body).to render_template('manage')
      end
      it 'raises an error if the managed_securities endpoint returns nil' do
        allow(member_balance_service_instance).to receive(:managed_securities).and_return(nil)
        expect{call_action}.to raise_error(StandardError)
      end
      it 'assigns @securities_table_data the correct column_headings' do
        call_action
        expect(assigns[:securities_table_data][:column_headings]).to eq([{value: 'check_all', type: :checkbox, name: 'check_all'}, I18n.t('common_table_headings.cusip'), I18n.t('common_table_headings.description'), I18n.t('common_table_headings.status'), I18n.t('securities.manage.eligibility'), I18n.t('common_table_headings.maturity_date'), I18n.t('common_table_headings.authorized_by'), fhlb_add_unit_to_table_header(I18n.t('common_table_headings.current_par'), '$'), fhlb_add_unit_to_table_header(I18n.t('global.borrowing_capacity'), '$')])
      end
      describe 'the `columns` array in each row of @securities_table_data[:rows]' do
        describe 'the checkbox object at the first index' do
          it 'has a `type` of `checkbox`' do
            call_action
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][0][:type]).to eq(:checkbox)
            end
          end
          it 'has a `name` that includes its cusip value' do
            security[:cusip] = SecureRandom.hex
            name = "cusip_#{security[:cusip]}"
            allow(member_balance_service_instance).to receive(:managed_securities).and_return([security])
            call_action
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][0][:name]).to eq(name)
            end
          end
          it 'has a `value` that is its cusip value' do
            call_action
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][0][:value]).to eq(security[:cusip])
            end
          end
          it 'has `disabled` set to `false` if there is a cusip value' do
            call_action
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][0][:disabled]).to eq(false)
            end
          end
          it 'has `disabled` set to `true` if there is no cusip value' do
            security[:cusip] = nil
            allow(member_balance_service_instance).to receive(:managed_securities).and_return([security])
            call_action
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][0][:disabled]).to eq(true)
            end
          end
          it 'has a `data` field that includes its status' do
            allow(controller).to receive(:custody_account_type_to_status).with(security[:custody_account_type]).and_return(status)
            call_action
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][0][:data]).to eq({status: status})
            end
          end
        end
        [[:cusip, 1], [:description, 2], [:eligibility, 4], [:authorized_by, 6]].each do |attr_with_index|
          it "contains an object at the #{attr_with_index.last} index with the correct value for #{attr_with_index.first}" do
            call_action
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][attr_with_index.last][:value]).to eq(security[attr_with_index.first])
            end
          end
          it "contains an object at the #{attr_with_index.last} index with a value of '#{I18n.t('global.missing_value')}' when the given security has no value for #{attr_with_index.first}" do
            security[attr_with_index.first] = nil
            allow(member_balance_service_instance).to receive(:managed_securities).and_return([security])
            call_action
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][attr_with_index.last][:value]).to eq(I18n.t('global.missing_value'))
            end
          end
        end
        it 'contains an object at the 3 index with a value of the response from the `custody_account_type_to_status` private method' do
          allow(controller).to receive(:custody_account_type_to_status).with(security[:custody_account_type]).and_return(status)
          call_action
          assigns[:securities_table_data][:rows].each do |row|
            expect(row[:columns][3][:value]).to eq(status)
          end
        end
        it 'contains an object at the 5 index with the correct value for :maturity_date and a type of `:date`' do
          call_action
          assigns[:securities_table_data][:rows].each do |row|
            expect(row[:columns][5][:value]).to eq(security[:maturity_date])
            expect(row[:columns][5][:type]).to eq(:date)
          end
        end
        [[:current_par, 7], [:borrowing_capacity, 8]].each do |attr_with_index|
          it "contains an object at the #{attr_with_index.last} index with the correct value for #{attr_with_index.first} and a type of `:number`" do
            call_action
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][attr_with_index.last][:value]).to eq(security[attr_with_index.first])
              expect(row[:columns][attr_with_index.last][:type]).to eq(:number)
            end
          end
        end
      end
      it 'sets @securities_table_data[:filter]' do
        filter = {
          name: 'securities-status-filter',
          data: [
            {
              text: I18n.t('securities.manage.safekept'),
              value: 'Safekept'
            },
            {
              text: I18n.t('securities.manage.pledged'),
              value: 'Pledged'
            },
            {
              text: I18n.t('securities.manage.all'),
              value: 'all',
              class: 'active'
            }
          ]
        }
        call_action
        expect(assigns[:securities_table_data][:filter]).to eq(filter)
      end
    end
  end

  describe 'GET `requests`' do
    let(:authorized_requests) { [] }
    let(:awaiting_authorization_requests) { [] }
    let(:securities_requests_service) { double(SecuritiesRequestService, authorized: authorized_requests, awaiting_authorization: awaiting_authorization_requests) }
    let(:call_action) { get :requests }
    before do
      allow(SecuritiesRequestService).to receive(:new).and_return(securities_requests_service)
    end

    it_behaves_like 'a user required action', :get, :requests
    it_behaves_like 'a controller action with an active nav setting', :requests, :securities

    it 'raises an error if the `authorized` securities request endpoint returns nil' do
      allow(securities_requests_service).to receive(:authorized).and_return(nil)
      expect{call_action}.to raise_error(/SecuritiesController#requests has encountered nil/i)
    end
    it 'raises an error if the `awaiting_authorization` securities request endpoint returns nil' do
      allow(securities_requests_service).to receive(:awaiting_authorization).and_return(nil)
      expect{call_action}.to raise_error(/SecuritiesController#requests has encountered nil/i)
    end
    it 'fetches the list of authorized securities requests from the service' do
      expect(securities_requests_service).to receive(:authorized)
      call_action
    end
    it 'fetches the list of securities requests awaiting authorization from the service' do
      expect(securities_requests_service).to receive(:awaiting_authorization)
      call_action
    end
    describe '`@authorized_requests_table`' do
      it 'builds the column headers' do
        call_action
        expect(assigns[:authorized_requests_table][:column_headings]).to eq([
          I18n.t('securities.requests.columns.request_id'),
          I18n.t('common_table_headings.description'),
          I18n.t('common_table_headings.authorized_by'),
          I18n.t('securities.requests.columns.authorization_date'),
          I18n.t('common_table_headings.settlement_date'),
          I18n.t('global.actions')
        ])
      end
      it 'builds a row for each entry in the `authorized` requests' do
        3.times do
          authorized_requests << {
            request_id: double('Request ID'),
            authorized_by: double('Authorized By'),
            authorized_date: double('Authorized Date'),
            settle_date: double('Settlement Date'),
            form_type: double('Form Type')
          }
        end
        rows = authorized_requests.collect do |request|
          description = double('A Description')
          allow(subject).to receive(:form_type_to_description).with(request[:form_type]).and_return(description)
          {
            columns: [
              {value: request[:request_id]},
              {value: description},
              {value: request[:authorized_by]},
              {value: request[:authorized_date], type: :date},
              {value: request[:settle_date], type: :date},
              {value: [[I18n.t('global.view'), '#']], type: :actions}
            ]
          }
        end
        call_action
        expect(assigns[:authorized_requests_table][:rows]).to eq(rows)
      end
    end
    describe '`@awaiting_authorization_requests_table`' do
      it 'builds the column headers' do
        call_action
        expect(assigns[:awaiting_authorization_requests_table][:column_headings]).to eq([
          I18n.t('securities.requests.columns.request_id'),
          I18n.t('common_table_headings.description'),
          I18n.t('securities.requests.columns.submitted_by'),
          I18n.t('securities.requests.columns.submitted_date'),
          I18n.t('common_table_headings.settlement_date'),
          I18n.t('global.actions')
        ])
      end
      it 'builds a row for each entry in the `awaiting_authorization` requests' do
        3.times do
          awaiting_authorization_requests << {
            request_id: double('Request ID'),
            submitted_by: double('Submitted By'),
            submitted_date: double('Submitted Date'),
            settle_date: double('Settlement Date'),
            form_type: double('Form Type')
          }
        end
        rows = awaiting_authorization_requests.collect do |request|
          description = double('A Description')
          allow(subject).to receive(:form_type_to_description).with(request[:form_type]).and_return(description)
          {
            columns: [
              {value: request[:request_id]},
              {value: description},
              {value: request[:submitted_by]},
              {value: request[:submitted_date], type: :date},
              {value: request[:settle_date], type: :date},
              {value: [[I18n.t('securities.requests.actions.authorize'), '#']], type: :actions}
            ]
          }
        end
        call_action
        expect(assigns[:awaiting_authorization_requests_table][:rows]).to eq(rows)
      end
    end
  end

  describe 'private methods' do
    describe '`custody_account_type_to_status`' do
      ['P', 'p', :P, :p].each do |custody_account_type|
        it "returns '#{I18n.t('securities.manage.pledged')}' if it is passed '#{custody_account_type}'" do
          expect(controller.send(:custody_account_type_to_status, custody_account_type)).to eq(I18n.t('securities.manage.pledged'))
        end
      end
      ['U', 'u', :U, :u].each do |custody_account_type|
        it "returns '#{I18n.t('securities.manage.safekept')}' if it is passed '#{custody_account_type}'" do
          expect(controller.send(:custody_account_type_to_status, custody_account_type)).to eq(I18n.t('securities.manage.safekept'))
        end
      end
      it "returns '#{I18n.t('global.missing_value')}' if passed anything other than 'P', :P, 'p', :p, 'U', :U, 'u' or :u" do
        ['foo', 2323, :bar, nil].each do |val|
          expect(controller.send(:custody_account_type_to_status, val)).to eq(I18n.t('global.missing_value'))
        end
      end
    end

    describe '`form_type_to_description`' do
      {
        'pledge_release' => 'securities.requests.form_descriptions.release',
        'safekept_release' => 'securities.requests.form_descriptions.release',
        'pledge_intake' => 'securities.requests.form_descriptions.pledge',
        'safekept_intake' => 'securities.requests.form_descriptions.safekept'
      }.each do |form_type, description_key|
        it "returns the localization value for `#{description_key}` when passed `#{form_type}`" do
          expect(controller.send(:form_type_to_description, form_type)).to eq(I18n.t(description_key))
        end
      end
      it 'returns the localization value for `global.missing_value` when passed an unknown form type' do
        expect(controller.send(:form_type_to_description, double(String))).to eq(I18n.t('global.missing_value'))
      end
    end
  end
end
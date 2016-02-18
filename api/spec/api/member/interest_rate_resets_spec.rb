require 'spec_helper'

describe MAPI::ServiceApp do
  describe 'member interest_rate_resets' do
    describe 'the `interest_rate_resets` method' do
      let(:interest_rate_reset_data) { JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'interest_rate_resets.json')))
      }
      let(:interest_rate_resets) { MAPI::Services::Member::InterestRateResets.interest_rate_resets(subject, member_id) }
      let(:max_advances_update_date) { [Date.new(2015,1,31)] }
      let(:max_advances_business_date) { [Date.new(2015,1,30)] }
      let(:advances_prior_business_date) { [Date.new(2015,1,29)] }

      it 'calls the `interest_rate_resets` method when the endpoint is hit' do
        allow(MAPI::Services::Member::InterestRateResets).to receive(:interest_rate_resets).and_return('a response')
        get "/member/#{member_id}/interest_rate_resets"
        expect(last_response.status).to eq(200)
      end

      it 'returns a 503 if the `interest_rate_resets` method returns nil' do
        allow(MAPI::Services::Member::InterestRateResets).to receive(:interest_rate_resets).and_return(nil)
        get "/member/#{member_id}/interest_rate_resets"
        expect(last_response.status).to eq(503)
      end

      [:test, :production].each do |env|
        describe "in the #{env} environment" do
          if env == :production
            let(:interest_rate_reset_result_set) {double('Oracle Result Set', fetch_hash: nil, fetch: nil)}
            let(:interest_rate_reset_result) {[interest_rate_reset_data[0],interest_rate_reset_data[1], nil]}

            before do
              allow(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
              allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(interest_rate_reset_result_set)
              allow(interest_rate_reset_result_set).to receive(:fetch).and_return(max_advances_update_date, max_advances_business_date, advances_prior_business_date)
              allow(interest_rate_reset_result_set).to receive(:fetch_hash).and_return(*interest_rate_reset_result)
            end
            it 'returns nil if `max_advances_update_date` is nil' do
              allow(interest_rate_reset_result_set).to receive(:fetch).and_return(nil)
              expect(interest_rate_resets).to be_nil
            end
            it 'returns nil if `max_advances_business_date` is nil' do
              allow(interest_rate_reset_result_set).to receive(:fetch).and_return(max_advances_update_date, nil)
              expect(interest_rate_resets).to be_nil
            end
            it 'returns nil if `advances_prior_business_date` is nil' do
              allow(interest_rate_reset_result_set).to receive(:fetch).and_return(max_advances_update_date, max_advances_business_date, nil)
              expect(interest_rate_resets).to be_nil
            end
          else
            before do
              allow(MAPI::Services::Member::CashProjections::Private).to receive(:fake_as_of_date).and_return(max_advances_business_date.first)
            end
          end
          it 'returns an object with a `date_processed` attribute of `max_advances_business_date`' do
            expect(interest_rate_resets[:date_processed]).to eq(max_advances_business_date.first)
          end
          it "returns an object with an `interest_rate_resets` attribute" do
            expect(interest_rate_resets[:interest_rate_resets]).to be_kind_of(Array)
          end
          describe 'the `interest_rate_resets` array' do
            it 'contains objects with an `effective_date`' do
              interest_rate_resets[:interest_rate_resets].each do |reset|
                expect(reset[:effective_date]).to be_kind_of(Date)
              end
            end
            it 'contains objects with an `advance_number`' do
              interest_rate_resets[:interest_rate_resets].each do |reset|
                expect(reset[:advance_number]).to be_kind_of(String)
              end
            end
            it 'contains objects with a `prior_rate`' do
              interest_rate_resets[:interest_rate_resets].each do |reset|
                expect(reset[:prior_rate]).to be_kind_of(Float)
              end
            end
            it 'contains objects with a `new_rate`' do
              interest_rate_resets[:interest_rate_resets].each do |reset|
                expect(reset[:new_rate]).to be_kind_of(Float)
              end
            end
            it 'contains objects with a `next_reset`' do
              interest_rate_resets[:interest_rate_resets].each do |reset|
                expect(reset[:next_reset]).to be_kind_of(Date) if reset[:next_reset]
              end
            end
            describe 'converting values into a percentage' do
              let(:interest_rate_reset_object) { double('interest rate reset object', :[] => nil) }
              let(:interest_rate_attribute) { double('an attribute of the reset object', to_date: nil, to_s: nil) }
              let(:interest_rate_reset_result) {[interest_rate_reset_object, nil]}
              before do
                allow(interest_rate_reset_object).to receive(:[]).with(:NEXT_RESET_DATE).and_return(interest_rate_attribute)
                allow(interest_rate_reset_object).to receive(:with_indifferent_access).and_return(interest_rate_reset_object)
                allow(MAPI::Services::Member::InterestRateResets::Private).to receive(:decimal_to_percentage_rate)
              end
              if env != :production
                before { allow(JSON).to receive(:parse).and_return([interest_rate_reset_object]) }
              end

              [['prior_rate', :PRIOR_RATE],['new_rate', :INTEREST_RATE]].each do |attribute|
                it "uses the `decimal_to_percentage_rate` util method to convert the `#{attribute.first}` to a percentage format" do
                  allow(interest_rate_reset_object).to receive(:[]).with(attribute.last).and_return(interest_rate_attribute)
                  expect(MAPI::Services::Member::InterestRateResets::Private).to receive(:decimal_to_percentage_rate).with(interest_rate_attribute)
                  interest_rate_resets
                end
              end
            end
          end

        end
      end

    end
  end
end

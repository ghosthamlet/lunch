require 'rails_helper'

RSpec.describe DashboardController, :type => :controller do
  describe "GET index" do
    it "should render the index view" do
      get :index
      expect(response.body).to render_template("index")
    end
    it "should assign @market_overview" do
      get :index
      expect(assigns[:market_overview]).to be_present
      expect(assigns[:market_overview][0]).to be_present
      expect(assigns[:market_overview][0][:name]).to be_present
      expect(assigns[:market_overview][0][:data]).to be_present
    end
    it "should assign @pledged_collateral" do
      get :index
      expect(assigns[:pledged_collateral]).to be_present
      expect(assigns[:pledged_collateral][:mortgages]).to be_present
      expect(assigns[:pledged_collateral][:mortgages][:absolute]).to be_present
      expect(assigns[:pledged_collateral][:mortgages][:percentage]).to be_present
      expect(assigns[:pledged_collateral][:agency]).to be_present
      expect(assigns[:pledged_collateral][:agency][:absolute]).to be_present
      expect(assigns[:pledged_collateral][:agency][:percentage]).to be_present
      expect(assigns[:pledged_collateral][:aaa]).to be_present
      expect(assigns[:pledged_collateral][:aaa][:absolute]).to be_present
      expect(assigns[:pledged_collateral][:aaa][:percentage]).to be_present
      expect(assigns[:pledged_collateral][:aa]).to be_present
      expect(assigns[:pledged_collateral][:aa][:absolute]).to be_present
      expect(assigns[:pledged_collateral][:aa][:percentage]).to be_present
    end
    it "should assign @total_securities" do
      get :index
      expect(assigns[:total_securities]).to be_present
      expect(assigns[:total_securities][:pledged_securities]).to be_present
      expect(assigns[:total_securities][:pledged_securities][:absolute]).to be_present
      expect(assigns[:total_securities][:pledged_securities][:percentage]).to be_present
      expect(assigns[:total_securities][:safekept_securities]).to be_present
      expect(assigns[:total_securities][:safekept_securities][:absolute]).to be_present
      expect(assigns[:total_securities][:safekept_securities][:percentage]).to be_present
    end
    it "should assign @effective_borrowing_capacity" do
      get :index
      expect(assigns[:effective_borrowing_capacity]).to be_present
      expect(assigns[:effective_borrowing_capacity][:used_capacity]).to be_present
      expect(assigns[:effective_borrowing_capacity][:used_capacity][:absolute]).to be_present
      expect(assigns[:effective_borrowing_capacity][:used_capacity][:percentage]).to be_present
      expect(assigns[:effective_borrowing_capacity][:unused_capacity]).to be_present
      expect(assigns[:effective_borrowing_capacity][:unused_capacity][:absolute]).to be_present
      expect(assigns[:effective_borrowing_capacity][:unused_capacity][:percentage]).to be_present
      expect(assigns[:effective_borrowing_capacity][:threshold_capacity]).to be_present
    end
  end

  describe "GET quick_advance_rates" do
    let(:json_response) { {some: "json"}.to_json }
    let(:RatesService) {class_double(RatesService)}
    let(:rate_service_instance) {double("rate service instance", quick_advance_rates: nil)}
    it "should call the RatesService object with quick_advance_rates and return the quick_advance_table_rows partial" do
      expect(RatesService).to receive(:new).and_return(rate_service_instance)
      expect(rate_service_instance).to receive(:quick_advance_rates).and_return(json_response)
      get :quick_advance_rates
      expect(response.body).to render_template(partial: 'dashboard/_quick_advance_table_rows')
    end
  end

  describe "GET quick_advance_preview" do
    let(:RatesService) {class_double(RatesService)}
    let(:rate_service_instance) {double("rate service instance", quick_advance_preview: nil)}
    let(:member_id) {double(MEMBER_ID)}
    let(:advance_term) {'some term'}
    let(:advance_type) {'some type'}
    let(:advance_rate) {'0.17'}
    it "should render the quick_advance_preview partial" do
      post :quick_advance_preview, rate_data: {advance_term: advance_term, advance_type: advance_type, advance_rate: advance_rate}.to_json
      expect(response.body).to render_template(partial: 'dashboard/_quick_advance_preview')
    end
    it "should call the RatesService object's `quick_advance_preview` method with the POSTed advance_type, advance_term and rate" do
      stub_const("MEMBER_ID", 750)
      expect(RatesService).to receive(:new).and_return(rate_service_instance)
      expect(rate_service_instance).to receive(:quick_advance_preview).with(MEMBER_ID, advance_type, advance_term, advance_rate.to_f)
      post :quick_advance_preview, rate_data: {advance_term: advance_term, advance_type: advance_type, advance_rate: advance_rate}.to_json
    end
  end

end
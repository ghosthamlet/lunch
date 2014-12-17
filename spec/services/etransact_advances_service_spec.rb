require 'spec_helper'

describe EtransactAdvancesService do
  subject { EtransactAdvancesService.new }
  it { expect(subject).to respond_to(:etransact_active?) }
  describe '`etransact_active? method`', :vcr do
    let(:status) {subject.etransact_active?}
    let(:json_response) { {etransact_advances_status: 'my_status'}.to_json }
    let (:mapi_response) {double('MAPI_response', body: json_response)}
    it 'returns the value of `etransact_advances_status` from a hash built from the JSON response' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_return(mapi_response)
      expect(mapi_response).to receive(:body).and_return(json_response)
      expect(status).to eq('my_status')
    end
    it "should return false if there was an error" do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(status).to be false
    end
  end
end
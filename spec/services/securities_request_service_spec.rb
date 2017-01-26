require 'rails_helper'

describe SecuritiesRequestService do
  let(:member_id) { rand(1..1000) }
  let(:request) { ActionDispatch::TestRequest.new }
  let(:requests) { double(Array) }
  let(:processed_requests) { double(Array) }
  subject { described_class.new(member_id, request) }

  before do
    allow(subject).to receive(:get_json).and_return(requests)
  end

  describe '`initialize`' do
    it 'stores the supplied `member_id`' do
      expect(subject.member_id).to be(member_id)
    end
    it 'stores the supplied `request`' do
      expect(subject.request).to be(request)
    end
    it 'raises an error if `member_id` is nil' do
      expect{ described_class.new(nil, request) }.to raise_error(ArgumentError)
    end
  end

  describe '`authorized`' do
    let(:call_method) { subject.authorized }
    it_should_behave_like 'a MAPI backed service object method', :authorized

    it 'calls `get_json` with the securities requests end point' do
      expect(subject).to receive(:get_json).with(:authorized, "/member/#{member_id}/securities/requests", anything)
      call_method
    end
    it 'calls `get_json` with a parameter `status` set to `authorized`' do
      expect(subject).to receive(:get_json).with(anything, anything, include(status: :authorized))
      call_method
    end
    it 'calls `get_json` with a parameter `settle_start_date` set to 7 days ago' do
      today = Time.zone.today
      allow(Time.zone).to receive(:today).and_return(today)
      expect(subject).to receive(:get_json).with(anything, anything, include(settle_start_date: today - 7.days))
      call_method
    end
    it 'calls `process_securities_requests` with the reponse from `get_json`' do
      expect(subject).to receive(:process_securities_requests).with(requests)
      call_method
    end
    it 'returns the result of calling `process_securities_requests`' do
      allow(subject).to receive(:process_securities_requests).and_return(processed_requests)
      expect(call_method).to be(processed_requests)
    end
  end

  describe '`awaiting_authorization`' do
    let(:call_method) { subject.awaiting_authorization }

    it_behaves_like 'a MAPI backed service object method', :awaiting_authorization

    it 'calls `get_json` with the securities requests end point' do
      expect(subject).to receive(:get_json).with(:awaiting_authorization, "/member/#{member_id}/securities/requests", anything)
      call_method
    end
    it 'calls `get_json` with a parameter `status` set to `awaiting_authorization`' do
      expect(subject).to receive(:get_json).with(anything, anything, include(status: :awaiting_authorization))
      call_method
    end
    it 'calls `process_securities_requests` with the reponse from `get_json`' do
      expect(subject).to receive(:process_securities_requests).with(requests)
      call_method
    end
    it 'returns the result of calling `process_securities_requests`' do
      allow(subject).to receive(:process_securities_requests).and_return(processed_requests)
      expect(call_method).to be(processed_requests)
    end
    it 'calls `get_json` with a parameter `settle_start_date` set to today' do
      today = Time.zone.today
      allow(Time.zone).to receive(:today).and_return(today)
      expect(subject).to receive(:get_json).with(anything, anything, include(settle_start_date: today))
      call_method
    end
  end

  describe '`submit_request_for_authorization`' do
    let(:broker_instructions) { SecureRandom.hex }
    let(:delivery_instructions) { SecureRandom.hex }
    let(:securities) { SecureRandom.hex }
    let(:session_id) { SecureRandom.hex }
    let(:request_id) { SecureRandom.hex }
    let(:kind) { SecureRandom.hex }
    let(:session) { instance_double(ActionDispatch::Request::Session, id: session_id) }
    let(:user) { instance_double(User, username: SecureRandom.hex, display_name: SecureRandom.hex) }
    let(:securities_request) { instance_double(SecuritiesRequest, broker_instructions: broker_instructions, delivery_instructions: delivery_instructions, securities: securities, request_id: nil, 'request_id=': nil, kind: kind) }

    before do
      allow(request).to receive(:session).and_return(session)
    end

    [:pledge, :release, :safekeep, :transfer].each do |type|
      describe "when `type` is #{type}" do
        let(:call_method) { subject.submit_request_for_authorization(securities_request, user, type) }
        it_behaves_like 'a MAPI backed service object method', :submit_request_for_authorization, nil, :get, false do
          let(:call_method) { subject.submit_request_for_authorization(securities_request, user, type) }
        end

        shared_examples 'release endpoint call' do |method|
          it "calls `#{method}` with `:submit_request_for_authorization` for the name arg" do
            expect(subject).to receive(method).with(:submit_request_for_authorization, any_args)
            call_method
          end
          case type
          when :release
            it "calls `#{method}` with `{member_id}/securities/release` for the endpoint arg" do
              expect(subject).to receive(method).with(anything, "/member/#{member_id}/securities/release", any_args)
              call_method
            end
          when :transfer
            it "calls `#{method}` with `{member_id}/securities/transfer` for the endpoint arg" do
              expect(subject).to receive(method).with(anything, "/member/#{member_id}/securities/transfer", any_args)
              call_method
            end
          else
            it "calls `#{method}` with `{member_id}/securities/intake` for the endpoint arg" do
              expect(subject).to receive(method).with(anything, "/member/#{member_id}/securities/intake", any_args)
              call_method
            end
          end
          it "calls `#{method}` with `application/json` for the content type" do
            expect(subject).to receive(method).with(anything, anything, anything, 'application/json', any_args)
            call_method
          end
          it "calls `#{method}` with a JSON body argument including the broker instructions from the security_request" do
            expect(subject).to receive(method).with(anything, anything, satisfy { |arg| JSON.parse(arg)['broker_instructions'] == broker_instructions }, any_args)
            call_method
          end
          it "calls `#{method}` with a body argument including the delivery instructions from the security_request" do
            expect(subject).to receive(method).with(anything, anything, satisfy { |arg| JSON.parse(arg)['delivery_instructions'] == delivery_instructions }, any_args)
            call_method
          end
          it "calls `#{method}` with a body argument including the securities from the security_request" do
            expect(subject).to receive(method).with(anything, anything, satisfy { |arg| JSON.parse(arg)['securities'] == securities }, any_args)
            call_method
          end
          it "calls `#{method}` with a body argument including the `username` of the passed user" do
            expect(subject).to receive(method).with(anything, anything, satisfy { |arg| JSON.parse(arg)['user']['username'] == user.username }, any_args)
            call_method
          end
          it "calls `#{method}` with a body argument including the `full_name` of the passed user" do
            expect(subject).to receive(method).with(anything, anything, satisfy { |arg| JSON.parse(arg)['user']['full_name'] == user.display_name }, any_args)
            call_method
          end
          it "calls `#{method}` with a body argument including the `session_id` of the passed user's session" do
            expect(subject).to receive(method).with(anything, anything, satisfy { |arg| JSON.parse(arg)['user']['session_id'] == session_id }, any_args)
            call_method
          end
          it "calls `#{method}` with a body argument including the `kind` of the security_request" do
            expect(subject).to receive(method).with(anything, anything, satisfy { |arg| JSON.parse(arg)['kind'] == kind }, any_args)
            call_method
          end
          describe "when the #{method} to MAPI succeeds" do
            before do
              allow_any_instance_of(RestClient::Resource).to receive(method).and_return(instance_double(RestClient::Response, code: 200, body: {request_id: request_id}.to_json))
            end
            it 'returns true' do
              expect(call_method).to be(true)
            end
          end
          describe 'when there is a RestClient error in the 400 range' do
            let(:status) { rand(400...500) }
            let(:error) { RestClient::Exception.new(nil, status) }
            before { allow_any_instance_of(RestClient::Resource).to receive(method).and_raise(error) }
            it 'calls the error handler with the error if an error handler was supplied' do
              expect{|error_handler| subject.submit_request_for_authorization(securities_request, user, type, &error_handler)}.to yield_with_args(error)
            end
            it 'returns false' do
              expect(call_method).to be(false)
            end
          end
        end

        describe 'when passed an already submitted request' do
          before do
            allow(securities_request).to receive(:request_id).and_return(request_id)
          end
          include_examples 'release endpoint call', :put
          it 'calls `put` with a body argument including the `request_id` of the passed SecuritiesRequest' do
            expect(subject).to receive(:put).with(anything, anything, satisfy { |arg| JSON.parse(arg)['request_id'] == request_id }, any_args)
            call_method
          end
        end

        describe 'when passed a new request' do
          include_examples 'release endpoint call', :post
        end
      end
    end
  end

  describe '`submitted_request`' do
    let(:request_id) { SecureRandom.hex }
    let(:response_hash) { instance_double(Hash) }
    let(:mapped_hash) { instance_double(Hash) }
    let(:securities_request) { instance_double(SecuritiesRequest) }
    let(:call_method) { subject.submitted_request(request_id) }

    it_behaves_like 'a MAPI backed service object method', :submitted_request, SecureRandom.hex

    describe 'with MAPI call stubbed' do
      before do
        allow(subject).to receive(:get_hash).and_return(response_hash)
        allow(subject).to receive(:map_response_to_securities_release_hash).and_return(mapped_hash)
        allow(SecuritiesRequest).to receive(:from_hash).and_return(securities_request)
      end

      it 'calls `get_hash` with `:submitted_request` as an argument' do
        expect(subject).to receive(:get_hash).with(:submitted_request, any_args).and_return(response_hash)
        call_method
      end
      it 'calls `get_hash` with "/member/#{member_id}/securities/request/#{request_id}" as the endpoint argument' do
        endpoint = "/member/#{member_id}/securities/request/#{request_id}"
        expect(subject).to receive(:get_hash).with(anything, endpoint).and_return(response_hash)
        call_method
      end
      it 'calls `map_response_to_securities_release_hash` with the returned securities request' do
        expect(subject).to receive(:map_response_to_securities_release_hash).with(response_hash).and_return(securities_request)
        call_method
      end
      it 'returns the mapped securities request' do
        expect(call_method).to eq(securities_request)
      end
    end
  end

  describe '`delete_request`' do
    let(:request_id) { SecureRandom.hex }
    let(:response) { instance_double(RestClient::Response) }
    let(:call_method) { subject.delete_request(request_id) }

    before { allow_any_instance_of(RestClient::Resource).to receive(:delete).and_return(response) }

    it_behaves_like 'a MAPI backed service object method', :delete_request, SecureRandom.hex, :delete, nil, false

    it 'calls `delete` with `:delete_request` for the name arg' do
      expect(subject).to receive(:delete).with(:delete_request, any_args)
      call_method
    end
    it 'calls `delete` with `{member_id}/securities/request/{request_id}` for the endpoint arg' do
      expect(subject).to receive(:delete).with(anything, "/member/#{member_id}/securities/request/#{request_id}")
      call_method
    end
    it 'returns the value of the `delete` call' do
      expect(call_method).to eq(response)
    end
  end

  describe '`authorize_request`' do
    let(:user) { instance_double(User) }
    let(:user_details) { SecureRandom.hex }
    let(:request_id) { SecureRandom.hex }
    let(:call_method) { subject.send(:authorize_request, request_id, user) }
    let(:response) { instance_double(RestClient::Response) }

    before do
      allow(subject).to receive(:user_details).and_return(nil)
      allow(subject).to receive(:user_details).with(user).and_return(user_details)
      allow_any_instance_of(RestClient::Resource).to receive(:put).and_return(response)
    end

    it_behaves_like 'a MAPI backed service object method', :authorize_request, nil, :put, nil, false do
      let(:call_method) { subject.authorize_request(request_id, user) }
    end

    it 'calls `put` with `:authorize_securities_request` for the name arg' do
      expect(subject).to receive(:put).with(:authorize_securities_request, any_args)
      call_method
    end
    it 'calls `put` with `{member_id}/securities/authorize` for the endpoint arg' do
      expect(subject).to receive(:put).with(anything, "/member/#{member_id}/securities/authorize", any_args)
      call_method
    end
    it 'calls `put` with `application/json` for the content type' do
      expect(subject).to receive(:put).with(anything, anything, anything, 'application/json', any_args)
      call_method
    end
    it 'calls `put` with a JSON blob containing the `request_id`' do
      expect(subject).to receive(:put).with(anything, anything, satisfy { |arg| JSON.parse(arg)['request_id'] == request_id }, any_args)
      call_method
    end
    it 'calls `put` with a JSON blob containing the user details' do
      expect(subject).to receive(:put).with(anything, anything, satisfy { |arg| JSON.parse(arg)['user'] == user_details }, any_args)
      call_method
    end
    it 'returns the value of the `put` call' do
      expect(call_method).to eq(response)
    end
  end

  describe 'private methods' do
    describe '`map_response_to_securities_release_hash`' do
      let(:raw_hash) {{
        broker_instructions: {
          transaction_code: instance_double(String),
          settlement_type: instance_double(String),
          trade_date: instance_double(String),
          settlement_date: instance_double(String)
        },
        delivery_instructions: {},
        request_id: instance_double(String),
        form_type: instance_double(String),
        securities: instance_double(Array),
        pledged_account: instance_double(String),
        safekept_account: instance_double(String),
        member_id: instance_double(String)
      }}
      let(:call_method) { subject.send(:map_response_to_securities_release_hash, raw_hash) }

      SecuritiesRequest::BROKER_INSTRUCTION_KEYS.each do |broker_instruction|
        it "returns a hash with a `#{broker_instruction}` value" do
          expect(call_method[broker_instruction]).to eq(raw_hash[:broker_instructions][broker_instruction])
        end
      end
      (SecuritiesRequest::DELIVERY_TYPES.keys - [:transfer]).each do |delivery_type|
        describe "when the `delivery_type` is `#{delivery_type}`" do
          before do
            raw_hash[:delivery_instructions] = {
              delivery_type: delivery_type,
              account_number: instance_double(String)
            }
          end
          SecuritiesRequest::DELIVERY_INSTRUCTION_KEYS[delivery_type].each do |delivery_key|
            if SecuritiesRequest::ACCOUNT_NUMBER_TYPE_MAPPING.values.include?(delivery_key)
              account_number_key = SecuritiesRequest::ACCOUNT_NUMBER_TYPE_MAPPING[delivery_type]
              it "sets the `account_number` value of the passed hash to the `#{account_number_key}` in the returned hash" do
                expect(call_method[account_number_key]).to eq(raw_hash[:delivery_instructions][:account_number])
              end
            else
              it "returns a hash with a `#{delivery_key}` value" do
                expect(call_method[delivery_key]).to eq(raw_hash[:delivery_instructions][delivery_key])
              end
            end
          end
        end
      end
      describe 'when the delivery type is `:transfer`' do
        before do
          raw_hash[:delivery_instructions] = {
            delivery_type: :transfer,
            account_number: nil
          }
        end
        it 'does not set an account number' do
          response = call_method
          (SecuritiesRequest::ACCOUNT_NUMBER_TYPE_MAPPING.values + [:account_number]).each do |account_number_key|
            expect(response[account_number_key]).to be_nil
          end
        end
      end
      [:request_id, :securities, :form_type, :pledged_account, :safekept_account, :member_id].each do |attr|
        it "returns a hash with a `#{attr}` value" do
          raw_hash[attr] = double('A Value')
          expect(call_method[attr]).to eq(raw_hash[attr])
        end
      end
    end

    describe '`process_securities_requests`' do
      let(:requests) { [ double(Hash), double(Hash) ] }
      let(:indifferent_requests) do
        requests.collect do |request|
          indifferent = double('An Indifferent Securities Request')
          allow(request).to receive(:with_indifferent_access).and_return(indifferent)
          indifferent
        end
      end
      let!(:fixed_requests) do
        indifferent_requests.collect do |request|
          fixed = double('A Fixed Securities Request')
          allow(subject).to receive(:fix_date).with(request, anything).and_return(fixed)
          fixed
        end
      end
      let(:call_method) { subject.send(:process_securities_requests, requests) }

      it 'returns `nil` if passed `nil`' do
        expect(subject.send(:process_securities_requests, nil)).to be_nil
      end
      it 'converts each request to a hash with indifferent access' do
        requests.each do |request|
          expect(request).to receive(:with_indifferent_access)
        end
        call_method
      end
      it 'calls `fix_date` on each request' do
        indifferent_requests.each do |request|
          expect(subject).to receive(:fix_date).with(request, match([:authorized_date, :settle_date, :submitted_date]))
        end
        call_method
      end
      it 'returns the processed requests' do
        expect(call_method).to eq(fixed_requests)
      end
    end

    describe '`user_details`' do
      let(:username) { double('A Username') }
      let(:full_name) { double('A Full Name') }
      let(:session_id) { double('A Session ID') }
      let(:session) { instance_double(ActionDispatch::Request::Session, id: session_id) }
      let(:user) { instance_double(User, username: username, display_name: full_name) }
      let(:call_method) { subject.send(:user_details, user) }

      before do
        request.session = session
      end

      it 'returns a hash containing the `username` of the user' do
        expect(call_method).to include(username: username)
      end
      it 'returns a hash containing the `full_name` of the user' do
        expect(call_method).to include(full_name: full_name)
      end
      it 'returns a hash containing the bound requests `session_id` if no request is passed' do
        expect(call_method).to include(session_id: session_id)
      end
      it 'returns a hash containing the passed requests `session_id`' do
        session_id = double('A Session ID')
        request = ActionDispatch::TestRequest.new
        request.session = instance_double(ActionDispatch::Request::Session, id: session_id)
        expect(subject.send(:user_details, user, request)).to include(session_id: session_id)
      end
    end
  end
end
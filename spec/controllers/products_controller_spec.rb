require 'rails_helper'

RSpec.describe ProductsController, :type => :controller do
  login_user

  describe 'GET index' do
    it_behaves_like 'a user required action', :get, :index
    it 'should render the index view' do
      get :index
      expect(response.body).to render_template('index')
    end
  end

  [:arc, :auction_indexed, :frc_embedded, :frc, :amortizing, :choice_libor, :knockout, :ocn, :putable, :callable, :vrc].each do |action|
    describe "GET #{action}" do
      it_behaves_like 'a product page', action
    end
  end

end

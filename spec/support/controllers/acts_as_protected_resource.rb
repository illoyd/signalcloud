shared_examples 'a protected resource' do

  context 'as nobody' do

    describe 'GET index' do
      before { get :index }

      it 'redirects to home' do
        expect( response ).to redirect_to( '/user/sign_in' )
      end
    end

  end
  
end
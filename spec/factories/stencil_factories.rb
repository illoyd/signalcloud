FactoryGirl.define do

  factory :stencil do
    account
    #association :phone_directory, account: { account }
    phone_directory { create :phone_directory, account: account }
    label                     'Babys First Stencil'
    description               'A simple toaster'
    seconds_to_live           180
    question                  'Hello, I am a question.'
    expected_confirmed_answer 'yes'
    expected_denied_answer    'no'
    confirmed_reply           'Right answer!'
    denied_reply              'The other right answer!'
    failed_reply              'Wrong answer!'
    expired_reply             'Took too long!'
    
    #before(:create) { |stencil| generate_hashed_password(user) }
  end

end
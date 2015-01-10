require 'rails_helper'

describe UserPolicy do
  subject { UserPolicy.new(user, other_user) }

  let(:other_user) { create(:user) }
  
  context 'as a user' do
    context 'with another user' do
      let(:user) { create(:user) }
      let(:team) { create(:team, owner: user) }
  
      context 'in a shared team' do
        before do
          Membership.create!(user: user, team: team)
          Membership.create!(user: other_user, team: team)
        end

        it { should permit(:show)    }
  
        it { should_not permit(:create)  }
        it { should_not permit(:new)     }
        it { should_not permit(:update)  }
        it { should_not permit(:edit)    }
        it { should_not permit(:destroy) }
      end
      
      context 'not in a shared team' do
        it { should_not permit(:show)    }
  
        it { should_not permit(:create)  }
        it { should_not permit(:new)     }
        it { should_not permit(:update)  }
        it { should_not permit(:edit)    }
        it { should_not permit(:destroy) }
      end
    end
  
    context 'with self' do
      let(:user) { User.find(other_user.id) }
  
      it { should permit(:show)    }
      it { should permit(:update)  }
      it { should permit(:edit)    }

      it { should_not permit(:create)  }
      it { should_not permit(:new)     }
      it { should_not permit(:destroy) }
    end
  end

end

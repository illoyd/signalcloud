require 'rails_helper'

describe TeamPolicy do
  subject { TeamPolicy.new(user, team) }

  context 'with team owner' do
    let(:user) { create(:user) }
    let(:team) { create(:team, owner: user) }
    
    it { should permit(:show)    }
    it { should permit(:create)  }
    it { should permit(:new)     }
    it { should permit(:update)  }
    it { should permit(:edit)    }

    it { should_not permit(:destroy) }   
  end

  context 'with team member' do
    let(:user) { create(:user) }
    let(:team) { create(:team) }
    before { Membership.create!(user: user, team: team) }

    it { should permit(:show)    }
    it { should permit(:create)  }
    it { should permit(:new)     }

    it { should_not permit(:update)  }
    it { should_not permit(:edit)    }
    it { should_not permit(:destroy) }   
  end

  context 'with unrelated team' do
    let(:user) { create(:user) }
    let(:team) { create(:team) }

    it { should permit(:create)  }
    it { should permit(:new)     }

    it { should_not permit(:show)    }
    it { should_not permit(:update)  }
    it { should_not permit(:edit)    }
    it { should_not permit(:destroy) }   
  end

end

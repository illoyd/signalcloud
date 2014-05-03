module Workflow
  class Specification
    def valid_state_names
      state_names + state_names.map{|state| state.to_s}
    end
  end
end

module Workflow
  module Adapter
    module ActiveRecord
      module InstanceMethods
      
        # alias :original_persist_workflow_state :persist_workflow_state

        # On transition the new workflow state is immediately saved in the
        # database.
        def persist_workflow_state(new_value)
          unless self.new_record?
            if self.respond_to? :update_column
              # Rails 3.1 or newer
              update_column self.class.workflow_column, new_value
            else
              # older Rails; beware of side effect: other (pending) attribute changes will be persisted too
              update_attribute self.class.workflow_column, new_value
            end
          end
        end

      end
    end
  end
end
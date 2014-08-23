class UpdateMessageWorkflowStates < ActiveRecord::Migration
  def up
    Message.where( workflow_state: 'pending' ).update_all( workflow_state: 'draft' )
  end
  
  def down
    Message.where( workflow_state: 'draft' ).update_all( workflow_state: 'pending' )
  end
end

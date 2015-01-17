class Stencil < ActiveRecord::Base
  belongs_to :team,       inverse_of: :stencils
  belongs_to :phone_book, inverse_of: :stencils
  has_many :if_clauses,   inverse_of: :parent, as: :parent

  normalize_attributes :name, :description
  
  validates_presence_of :name

  include Workflow
  workflow do
    state :active do
      event :deactivate, transitions_to: :inactive
    end
    state :inactive do
      event :activate, transitions_to: :active
    end
  end

end

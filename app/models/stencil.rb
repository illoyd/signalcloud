class Stencil < ActiveRecord::Base
  belongs_to :team,       inverse_of: :stencils
  belongs_to :phone_book, inverse_of: :stencils
  has_many :if_clauses,   inverse_of: :parent, as: :parent, autosave: true, dependent: :destroy

  normalize_attributes :name, :description
  
  validates_presence_of :name

  accepts_nested_attributes_for :if_clauses

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

class IfClause < ActiveRecord::Base
  belongs_to :parent, polymorphic: true
  has_many :then_clauses, inverse_of: :if_clause, dependent: :destroy, autosave: true
  
  accepts_nested_attributes_for :then_clauses
  
  validates :type, presence: true, exclusion: ['IfClause']
end

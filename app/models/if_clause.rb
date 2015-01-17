class IfClause < ActiveRecord::Base
  belongs_to :parent, polymorphic: true
  has_many :then_clauses, inverse_of: :if_clause
end

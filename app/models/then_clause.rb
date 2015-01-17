class ThenClause < ActiveRecord::Base
  belongs_to :if_clause, inverse_of: :then_clauses

  validates :type, presence: true, exclusion: ['ThenClause']
end

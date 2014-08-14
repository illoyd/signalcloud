##
# Icons for icon helper, for global management and access. May move into more efficient library later.
ICONS = {
  # Objects
  stencils: 'edit',
  phone_books: 'book',
  phone_numbers: 'phone',
  conversations: 'comments',
  organizations: 'th-large',
  users: 'group',
  ledger_entries: 'list-alt',
  boxes: 'archive',
  
  # Common actions
  show: 'search',
  edit: 'pencil',
  delete: 'trash-o',
  
  # Conversation statuses
  confirmed: 'check-circle',
  denied: 'minus-circle',
  failed: 'times-circle',
  expired: 'clock-o',
  pending: 'plus-circle',
  asking: 'question-circle',
  asked: 'question-circle',
  received: 'exclamation-circle',
  challenge_sent: 'plus-circle',
  draft: 'file-text',

  error: 'warning-sign',
  
  disable: 'ban',
  enable:  'check-circle-o'
  
}.with_indifferent_access.freeze

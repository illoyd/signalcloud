##
# Icons for icon helper, for global management and access. May move into more efficient library later.
ICONS = {
  # Objects
  stencils: 'edit',
  phone_books: 'book',
  phone_numbers: 'phone',
  conversations: 'comments',
  organizations: 'briefcase',
  users: 'group',
  ledger_entries: 'list-alt',
  boxes: 'archive',
  
  # Common actions
  show: 'search',
  edit: 'pencil',
  delete: 'trash-o',
  
  # Conversation statuses
  confirmed: 'ok-sign',
  denied: 'minus-sign',
  failed: 'remove-sign',
  expired: 'time',
  pending: 'plus-sign',
  asking: 'question-sign',
  asked: 'question-sign',
  received: 'exclamation-sign',
  challenge_sent: 'plus-sign',
  draft: 'file-text',

  error: 'warning-sign'
  
}.with_indifferent_access.freeze

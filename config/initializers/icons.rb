##
# Icons for icon helper, for global management and access. May move into more efficient library later.
ICONS = {
  # Objects
  stencil:        'edit',
  stencils:       'edit',

  phone_book:     'book',
  phone_books:    'book',

  phone_number:   'phone',
  phone_numbers:  'phone',

  conversation:   'comments',
  conversations:  'comments',

  organization:   'th-large',
  organizations:  'th-large',

  user:           'user',
  users:          'group',

  ledger_entry:   'list-alt',
  ledger_entries: 'list-alt',

  invoice:        'file-text-o',
  invoices:       'file-text-o',

  box:            'archive',
  boxes:          'archive',
  
  # Common actions
  show:           'search',
  edit:           'pencil',
  delete:         'trash-o',
  disable:        'ban',
  enable:         'check-circle-o',
  
  # Conversation statuses
  draft:          'file-file-o',
  pending:        'plus-circle',
  asking:         'question-circle',
  asked:          'question-circle',
  received:       'exclamation-circle',
  confirmed:      'check-circle',
  denied:         'minus-circle',
  failed:         'times-circle',
  expired:        'clock-o',
  challenge_sent: 'plus-circle',

  # Misc
  error:          'warning-sign'
    
}.with_indifferent_access.freeze

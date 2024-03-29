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
  invite:         'envelope-o',
  roles:          'check-circle-o',
  change_password: 'key',
  
  # Phone Number statuses/actions
  purchase:       'chain',
  release:        'chain-broken',
  
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
  error:          'warning-sign',
  active:         'check',
  inactive:       'times',
    
}.with_indifferent_access.freeze

ORGANIZATION_ICONS = %w( glass music search envelope-o heart star star-o user film th-large th th-list check remove close times search-plus search-minus power-off signal gear cog trash-o home file-o clock-o road download arrow-circle-o-down arrow-circle-o-up inbox play-circle-o rotate-right repeat refresh list-alt lock flag headphones volume-off volume-down volume-up qrcode barcode tag tags book bookmark print camera font bold italic text-height text-width align-left align-center align-right align-justify list dedent outdent indent video-camera photo image picture-o pencil map-marker adjust tint edit pencil-square-o share-square-o check-square-o arrows step-backward fast-backward backward play pause stop forward fast-forward step-forward eject chevron-left chevron-right plus-circle minus-circle times-circle check-circle question-circle info-circle crosshairs times-circle-o check-circle-o ban arrow-left arrow-right arrow-up arrow-down mail-forward share expand compress plus minus asterisk exclamation-circle gift leaf fire eye eye-slash warning exclamation-triangle plane calendar random comment magnet chevron-up chevron-down retweet shopping-cart folder folder-open arrows-v arrows-h bar-chart-o bar-chart twitter-square facebook-square camera-retro key gears cogs comments thumbs-o-up thumbs-o-down star-half heart-o sign-out linkedin-square thumb-tack external-link sign-in trophy github-square upload lemon-o phone square-o bookmark-o phone-square twitter facebook github unlock credit-card rss hdd-o bullhorn bell certificate hand-o-right hand-o-left hand-o-up hand-o-down arrow-circle-left arrow-circle-right arrow-circle-up arrow-circle-down globe wrench tasks filter briefcase arrows-alt group users chain link cloud flask cut scissors copy files-o paperclip save floppy-o square navicon reorder bars list-ul list-ol strikethrough underline table magic truck pinterest pinterest-square google-plus-square google-plus money caret-down caret-up caret-left caret-right columns unsorted sort sort-down sort-desc sort-up sort-asc envelope linkedin rotate-left undo legal gavel dashboard tachometer comment-o comments-o flash bolt sitemap umbrella paste clipboard lightbulb-o exchange cloud-download cloud-upload user-md stethoscope suitcase bell-o coffee cutlery file-text-o building-o hospital-o ambulance medkit fighter-jet beer h-square plus-square angle-double-left angle-double-right angle-double-up angle-double-down angle-left angle-right angle-up angle-down desktop laptop tablet mobile-phone mobile circle-o quote-left quote-right spinner circle mail-reply reply github-alt folder-o folder-open-o smile-o frown-o meh-o gamepad keyboard-o flag-o flag-checkered terminal code mail-reply-all reply-all star-half-empty star-half-full star-half-o location-arrow crop code-fork unlink chain-broken question info exclamation superscript subscript eraser puzzle-piece microphone microphone-slash shield calendar-o fire-extinguisher rocket maxcdn chevron-circle-left chevron-circle-right chevron-circle-up chevron-circle-down html5 css3 anchor unlock-alt bullseye ellipsis-h ellipsis-v rss-square play-circle ticket minus-square minus-square-o level-up level-down check-square pencil-square external-link-square share-square compass toggle-down caret-square-o-down toggle-up caret-square-o-up toggle-right caret-square-o-right euro eur gbp dollar usd rupee inr cny rmb yen jpy ruble rouble rub won krw bitcoin btc file file-text sort-alpha-asc sort-alpha-desc sort-amount-asc sort-amount-desc sort-numeric-asc sort-numeric-desc thumbs-up thumbs-down youtube-square youtube xing xing-square youtube-play dropbox stack-overflow instagram flickr adn bitbucket bitbucket-square tumblr tumblr-square long-arrow-down long-arrow-up long-arrow-left long-arrow-right apple windows android linux dribbble skype foursquare trello female male gittip sun-o moon-o archive bug vk weibo renren pagelines stack-exchange arrow-circle-o-right arrow-circle-o-left toggle-left caret-square-o-left dot-circle-o wheelchair vimeo-square turkish-lira try plus-square-o space-shuttle slack envelope-square wordpress openid institution bank university mortar-board graduation-cap yahoo google reddit reddit-square stumbleupon-circle stumbleupon delicious digg pied-piper pied-piper-alt drupal joomla language fax building child paw spoon cube cubes behance behance-square steam steam-square recycle automobile car cab taxi tree spotify deviantart soundcloud database file-pdf-o file-word-o file-excel-o file-powerpoint-o file-photo-o file-picture-o file-image-o file-zip-o file-archive-o file-sound-o file-audio-o file-movie-o file-video-o file-code-o vine codepen jsfiddle life-bouy life-buoy life-saver support life-ring circle-o-notch ra rebel ge empire git-square git hacker-news tencent-weibo qq wechat weixin send paper-plane send-o paper-plane-o history circle-thin header paragraph sliders share-alt share-alt-square bomb soccer-ball-o futbol-o tty binoculars plug slideshare twitch yelp newspaper-o wifi calculator paypal google-wallet cc-visa cc-mastercard cc-discover cc-amex cc-paypal cc-stripe bell-slash bell-slash-o trash copyright at eyedropper paint-brush birthday-cake area-chart pie-chart line-chart lastfm lastfm-square toggle-off toggle-on bicycle bus ioxhost angellist cc shekel sheqel ils meanpath ).sort.uniq

# encoding: UTF-8

def rand_datetime(from, to=Time.now)
  Time.at(rand_in_range(from.to_f, to.to_f))
end

def rand_datetime_lastmonth(from=nil, to=nil)
  from ||= 1.month.ago.beginning_of_month
  to ||= from.end_of_month
  Time.at rand_in_range(from.to_f, to.to_f)
end

def rand_in_range(from, to)
  rand * (to - from) + from
end

def rand_f( min, max )
  rand * (max-min) + min
end

def rand_i( min, max )
  min = min.to_i
  max = max.to_i
  rand(max-min) + min
end

def random_us_number()
  '1%03d%03d%04d' % [ rand_i(201, 799), rand_i(100, 999), rand_i(0001, 9999) ]
end

def random_ca_number()
  '1%03d%03d%04d' % [ rand_i(201, 799), rand_i(100, 999), rand_i(0001, 9999) ]
end

def random_uk_number()
  '44%04d%03d%03d' % [ rand_i(2000, 9999), rand_i(000, 999), rand_i(000, 999) ]
end

def random_cost( min=0.01, max=99.99, round=2 )
  rand_f(min, max).round(round)
end

alias random_price random_cost

RANDOM_UTF8_SAMPLE = '♈ ♉ ♊ ♋ ♌ ♍ ♎ ♏ ♐ ♑ ♒ ♓

A chessboard:

^   ^ A ^ B ^ C ^ D ^ E ^ F ^ G ^ H ^
^ 8 | ♜ | ♞ | ♝ | ♛ | ♚ | ♝ | ♞ | ♜ |
^ 7 | ♟ | ♟ | ♟ | ♟ | ♟ | ♟ | ♟ | ♟ | 
^ 6 |   |    |   |   |    |   |    |   | 
^ 5 |   |    |   |   |    |   |    |   | 
^ 4 |   |    |   |   |    |   |    |   | 
^ 3 |   |    |   |   |    |   |    |   | 
^ 2 | ♙ | ♙ | ♙ | ♙ | ♙ | ♙ | ♙ | ♙ |
^ 1 | ♖ | ♘ | ♗ | ♕ | ♔ | ♗ | ♘ | ♖ |

Russian (по-русски):

  По оживлённым берегам
  Громады стройные теснятся
  Дворцов и башен; корабли
  Толпой со всех концов земли
  К богатым пристаням стремятся;

Ancient Greek:

Αρχαίο Πνεύμα Αθάνατον!  
Ἰοὺ ἰού· τὰ πάντʼ ἂν ἐξήκοι σαφῆ.
  Ὦ φῶς, τελευταῖόν σε προσϐλέψαιμι νῦν,
  ὅστις πέφασμαι φύς τʼ ἀφʼ ὧν οὐ χρῆν, ξὺν οἷς τʼ
  οὐ χρῆν ὁμιλῶν, οὕς τέ μʼ οὐκ ἔδει κτανών.

Modern Greek:
  Η σύγχρονη Ελλάδα, έχει να παρουσιάσει δυναμικό
  έργο στον τομέα του πολιτισμού, των τεχνών και
  των γραμμάτων. Αντίστοιχα δυναμική είναι η παρουσία
  των Ελλήνων επιχειρηματιών στην διεθνή οικονομική
  και βιομηχανική σκηνή.

Sanskrit:

  पशुपतिरपि तान्यहानि कृच्छ्राद्
  अगमयदद्रिसुतासमागमोत्कः । 
  कमपरमवशं न विप्रकुर्युर्
  विभुमपि तं यदमी स्पृशन्ति भावाः ॥

Hindi:

गूगल समाचार हिन्दी में 

Korean:
  한글은 아름다운 우리글입니다.
  곱고 아름답게 사용하는 것이 우리의 의무입니다.

Chinese:

  子曰：「學而時習之，不亦說乎？有朋自遠方來，不亦樂乎？
  人不知而不慍，不亦君子乎？」
  
  有子曰：「其為人也孝弟，而好犯上者，鮮矣；
  不好犯上，而好作亂者，未之有也。君子務本，本立而道生。
  孝弟也者，其為仁之本與！」

Japanese:

  「秋の田の かりほの庵の 苫をあらみ わが衣手は 露にぬれつつ」　天智天皇
  「春すぎて 夏来にけらし 白妙の 衣ほすてふ 天の香具山」　持統天皇
  「あしびきの 山鳥の尾の しだり尾の ながながし夜を ひとりかも寝む」　柿本人麻呂 

Latvian:
  
  Iedomu jaukie ideāli,
  Vecākie principi, tikla, mīla - 
  Dienas allažības priekšā
  Šķīst kā graudi akmeņstarpā.

  Glāžšķūņa rūķīši jautri dziedādami čiepj koncertflīģeļa vāku. 

Simplified Chinese:

  这是简体字汉语。 zhè shì jiǎn t zì hàn yǔ 

Armenian:

  Հարգանքներիս հավաստիքը Հայ Ժողովրդին:
  Ամենալավ օրենքները չեն օգնի, եթե մարդիկ բանի պետք չեն:

Hebrew:

  המשפט עם הזכוכית שאפשר לאכול בלי שזה מפריע, לא זוכר איך הוא הולך
'.gsub(/[| \r\n]+/, '').split(//)

# Helper: Build a random string for unicode SMS
def random_unicode_string(length=1)
  str = (1..length).map{ RANDOM_UTF8_SAMPLE.sample }.join('')
  str.ascii_only? ? random_unicode_string(length) : str
end

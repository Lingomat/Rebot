Rebol []

scriptpath: %rebot4.r
rebotver: "3.2"
ircserver: ["blueyonder.uk.quakenet.org" "demon.uk.quakenet.org" "freddyshouse.uk.quakenet.org"]
ircport: 6667
channel: "#eed"
realnick: "Rebot"
nick:     "Rebot"
AltNick:  "Rebot2"
usern: "Rebot"
hostn: "electricdeath.com"
servern: "IRC.uk.Quakenet.Org"
realn: rejoin ["Rebot "rebotver]
dcserver: "195.225.217.11:14567"
utserver: "217.161.41.43:7797"

;nastehwords: make block! ["m8" "gr8" "h8" " k " "thx" "tr00f" "l8r" " u "]
nastehwords: make block! ["l8r"]
peoplethatsuck: make block! ["billox"]

numwordblock: ["one" "two" "three" "four" "five" "six" "seven" "eight" "nine" "ten" "eleven" "twelve" "thirteen" "fourteen" "fifteen" "sixteen" "seventeen" "eighteen" "nineteen" "twenty"]

obb: to-char 255
null: to-char 0
cone: to-char 1
bold: to-char 2
underline: to-char 31

logging: true

xUser: "rebot"
xPass: "r3b0ta"
xPop: "wench"
RebotAccessFile: %rebotusers

CMSDir:     %/C/Rebol/CMS/
CMSIndex:   to-file rejoin[CMSDir "index.txt"]
CMSCount:   to-file rejoin[CMSDir "count.txt"]
BlogFTPDir: %/C/Rebol/CMS/FTP/

FAQfile: %RebotFAQ.txt

IgnoreNicks: ["Wanker"]

system/schemes/ftp/passive: true
system/schemes/ftp/timeout: 0:30
system/schemes/ftp/cache-size: 0

Comment { EXTERNAL PROGRAMS }

do %http-tools.r

url-encode: func [
    {URL-encode a string}
    data "String to encode"
    /local new-data
][
    new-data: make string! ""
    normal-char: charset [
        #"A" - #"Z" #"a" - #"z"
        #"@" #"." #"*" #"-" #"_"
        #"0" - #"9"
    ]
    if not string? data [return new-data]
    forall data [
        append new-data either find normal-char first data [
            first data
        ][
            rejoin ["%" to-string skip tail (to-hex to-integer first data) -2]
        ]
    ]
    new-data: replace/all new-data "%20" "+"
    new-data
]

RebotVersion: func [
  /local 
  RebotLength
  ][
  RebotLength: length? read/lines scriptpath
  SendChan rejoin [cone "ACTION " rebotver ": "RebotLength" lines of code, last modified " 
                   modified? scriptpath " running under REBOL " system/version 
                   " on machine '"system/network/host"'." cone]
  ]

ReturnLinks: func [
  webpage [string!]
  /local
  tags text html-code links
  ][
  tags: make block! 100
  text: make string! 8000
  html-code: [
    copy tag ["<" thru ">"] (append tags tag) | 
    copy txt to "<" (append text txt)
    ]
  links: make block! []
  parse webpage [to "<" some html-code]
  foreach tag tags [
    if parse tag ["<A" thru "HREF="
      [{"} copy link to {"} | copy link to ">"]
      to end
    ][append links link]
  ]
  return links
  ]

Wrap: func [
  WrapWidth
  WhatToWrap
  /local
  charlength
  wrapstring
  ][
  wrapstring: parse WhatToWrap none
  charlength: 0
  linewrap: make string! ""
  foreach wrapword wrapstring [
    charlength: charlength + (length? wrapword)
    if charlength > WrapWidth [
      linewrap: rejoin[linewrap newline]
      charlength: 0
      ]
    linewrap: rejoin[linewrap " "wrapword]
    ]
    Linewrap
  ]

PadNum: func [
  x   
  pad [integer!]
  ][
  xs: to-string x
  while [pad > length? xs] [
    xs: rejoin["0"xs]
    ]
  xs
  ]    

TruncSentence: func [
  indata
  maxlength
  /local
  inwords
  finaldata
  ][
  inwords: parse indata none
  finaldata: ""
  foreach inword inwords [
    finaldata: rejoin[finaldata inword " "]
    if (length? finaldata) > maxlength [
        return rejoin[finaldata "..."]
        ]
    ]
  indata
  ]

SendCMD: func [
  irccommand
  ][
  insert irccon irccommand
  
]

boldtext: func [
  intext
  ][
  outtext: copy intext
  replace/all outtext "<b>" bold
  replace/all outtext "</b>" bold
  outtext
  ]

Wikisearch: func [
  searchforwhat [string!]
  ][
  if searchforwhat = "" [
    sendchan "foad"
    return
    ]
  if error? try [wikipage: read rejoin[http://en.wikipedia.org/w/index.php?search= url-encode searchforwhat]] [
    sendchan "Wikipedia is borked right now."
    return
    ]
  if (found? find wikipage "Results 1-0 of 0") or (found? find wikipage "no exact matches to your query.") [
    sendchan "Looks like Wikipedia has fuck all on that."
    return
    ]
  if found? find wikipage "<strong>Results 1" [
     tmp: ""
     foundterms: ""
     parse wikipage [thru "<!-- start content -->" copy wikicontent to "Search in namespaces"]
     parse wikicontent [any [thru "<li style=" thru {title="} copy tmp to {"}
                             (
                             if (tmp <> none) [
                               foundterms: rejoin[foundterms tmp ", "]
                               ]
                             )
                            ]
                       ]
     foundterms: copy/part foundterms ((length? foundterms) - 2)
     sendchan rejoin["Not listed in Wikipedia but found in entries: "foundterms "."]
     return
     ]
  if found? find wikipage {This is a <a href="/wiki/Wikipedia:Disambiguation"} [
     foundterms: make block! []
     parse wikipage [thru "<!-- start content -->" copy wikicontent to "<!--"]
     parse wikicontent [any [thru "<li>" copy tmp to "</li>"
                             (
                             append foundterms tmp
                             )
                            ]
                       ]
     Sendchan "Wikipedia says this is ambiguous, you might be talking about:"
     i: 1
     foreach foundterm foundterms [
       sendchan rejoin[i ". " striphtml boldtext foundterm] 
       i: i + 1
       wait 0.5
       ]
     return
     ]

  parse wikipage [thru "<!-- start content -->" thru "<p>" copy wikicontent to "</p>"]
  
  sendchan TruncSentence (striphtml boldtext wikicontent) 320
  ]


JoinGreet: func [
  /local
  Statements
  JoinStatement
  ][
  Statements: make block! ["Did you miss me?" "Rebot is my name and 0wnerage is my game!"
                           "Hello fuckers." "I'm baaaaack!" "I feel a new bot!" "Howdy."
                           "Greetings." "Slags." "Bitches." "Sluts." "What you been saying about me?"
                           "Bah!" "Whazup!" "Rejoice, I am back!" "I hate you but Lurks makes me join."
                           "What did I miss?" "Busy as ever I see." "Don't stop talking on my account."
                           "Hello." "Whee!" "Hello my lovely little organic bags of dirty water."
                           "Feh." "Please, don't get up." "My brain has been altered, phear!"
                           "I've been upgraded, shame that'll never happen to you eh?"
                           "I am Rebot, master of this IRC channel!"
                           "Isn't it astounding how unrealiable IRC is."
                           "You can't get the staff."
                           "Allow me to introduce myself, I am Rebot and I fucking 0wn you."
                           "I am Rebot, protecting this channel from mongs, weenies and peons since 2000."
                           "Behold, Rebot!" "Today is going to be different, today you will do the donkeywork and I'll do the talking."
                           "Don't you fuckers have work to do?" "I'm just so happy to be back I could shit."
                           "Thank you thank you, it brings a tear to my eye knowing how much you guys care."
                           "OK whose gonna be first to mong up one of my commands?"
                           "Hi folks, be greatful it's me and not Jaybot eh?"
                           "Wahey, someone get me a drink!" "I'm in a bad mood, don't talk to me."]
                           
  JoinStatement: pick Statements random (length? Statements)
  replace JoinStatement "Rebot" nick
  SendChan JoinStatement
  ]
  
ChildishInsult: func [
  insultwho
  /local
  FirstWords
  SecondWords
  PickFirstWord
  PickSecondWord
  TehInsult
  insultname
  forcebackfire
  ][
  
  forcebackfire: false
  
  if not insultwho = none [
    if found? find insultwho "lurk" [forcebackfire: true]
    if found? find insultwho nick   [forcebackfire: true]
    ]
    
  FirstWords: ["fuck" "fuck" "fuck" "fuck" "fuck" "fuck" "piss" "cock" "dick" "wank" "cunt" "nob" "mong" "pussy" "duck" "pig" "scab" "quim" "gash"
               "turd" "jizz" "ass" "gay" "shit" "spaz" "twat" "snot" "girl" "fag" "thrush" "vag" "gusset"
               "penis" "clit" "prick" "homo" "boob" "slag" "queer" "git" "fagot" "fart" "billox" "fudge"
               "sphincter" "donkey" "lard" "fat" "turd" "wank" "meat"]
  SecondWords: ["face" "lord" "lord" "lord" "stain" "sucker" "stabber" "master" "lips" "breath" "splatter"
                "flaps" "bitch" "nose" "fiddler" "fart" "hook" "arms" "scab" "squit" "squirt" "guff"
                "cheeks" "burglar" "slut" "whore" "queer" "brain" "head" "slap" "muncher" "packer"
                "gobler" "eater" "neck" "gut" "mouth" "neck" "scrote" "bag" "gargler" "face"]
                
  PickFirstWord:  pick FirstWords random (length? FirstWords)
  PickSecondWord: pick SecondWords random (length? SecondWords)
  TehInsult: rejoin[(uppercase (copy/part PickFirstWord 1)) (copy skip PickFirstWord 1) PickSecondWord "!"]
 
  BackFire: ["Mong off" "You" "Do it yourself" "Not this time" "Eat me" "Get fucked" "Fuck you"
             "Blow me" "I'm bored of this" "Get some skillz" "Wise up" "Grow up" "I hate you"
             "Hello" "We don't care" "Tell someone who cares" "Fuck off" "I'm not in the mood"
             "Get a life" "Get a girlfriend" "Get a real job"]
 
  Either (insultwho = none) [
    SendChan TehInsult
    ][
    either ((forcebackfire = true) or ((random 5) = 1)) [
      pickbackfire: pick BackFire random (length? BackFire)
      SendChan rejoin[saidnick": "pickbackfire" "TehInsult]
      ][
      insultname: pick (parse insultwho none) 1
      SendChan rejoin[insultname": "TehInsult]
      ]
    ]
  ]

RandomDice: func [
  dicewhat
  ][
  
  TypeResponse: random 3
  
  if found? find dicewhat "rebot" [TypeResponse: 1]
  if found? find dicewhat "lurk" [TypeResponse: 1]
  
  GoodThings:    ["is great!" "is pretty good!" "is shit hot!" "is absolutely ace!" "is the best thing evar!"
                  "rocks!" "owns!" "kicks ass!" "is pretty cool." "is not bad." "rocks my world!"
                  "is fucking great!" "is stonkingly good!" "is just the coolest thing ever."
                  "is so great, I think I've come!" "smells of roses." "can do no wrong!"
                  "fucking owns!" "fucking rocks!" "is almost as good as me!"
                 ]
  NeutralThings: ["is ok." "is passable." "is better than a kick in the teeth." "is alright I suppose."
                  "is pretty average." "is not too shabby." "is ok I suppose." "is not the worst thing in the world."
                  "is ... bleh, I can't decide." "is fine, I guess." "basically works." "does exactly what it says on the tin."
                  "is not going to win any awards." "is something for a rainy day." "is better than nothing."
                  "is a game of two halves."
                 ]
  BadThings:     ["is bit shite." "is fucking rank!" "is totally shit!" "is utter arse!" "is gay." "is poo!"
                  "is totally gay." "is completely gay." "smells of wee!" "lives in the bin!" "is a bit boring."
                  "is quite possibly the worst thing that has ever happened to the world."
                  "is shite beyond belief!" "sucks ass!" "sucks piss!" "is a mixed bag!" "is retarded." "is bent."
                  "is a waste of oxygen." "is lower than a recruitment consultant's snot rag."
                 ] 
                  
  switch TypeResponse [
    1 [ SendChan rejoin[dicewhat " " pick GoodThings random (length? GoodThings)] ]
    2 [ SendChan rejoin[dicewhat " " pick NeutralThings random (length? NeutralThings)] ]
    3 [ SendChan rejoin[dicewhat " " pick BadThings random (length? BadThings)] ]
    ]
 ] 

FindBlock: func [
  blockdata [block!]
  search    [string!]
  ][
  foundit: false
  foreach singlevalue blockdata [
    if found? find singlevalue search [
      foundit: true
      break
      ]
    ]
  foundit
  ]

BlockFind: func [
  searchtext    [string!]
  blockdata [block!]
  ][
  foundit: false
  foreach singlevalue blockdata [
    if found? find searchtext singlevalue [
      foundit: true
      break
      ]
    ]
  foundit
  ]

CheckDomain: func [
  lookupdomain
  /local
  bleetdomain
  UKRegURL
  postukreg
  ukregresults
  ukregtmp
  domaintaken
  domainfree
  resultstring
  ][
  lookupdomain: lowercase lookupdomain
  if not lookupdomain [
    SendChan "Usage: domain <domain to lookup>"
    return
    ]
  if found? find lookupdomain "." [
    bleetdomain: find lookupdomain "."
    SendChan rejoin["If you want me to tell you what domains are free, don't include the '"bleetdomain"', idiot!"]
    return
    ]   
  
  UKRegURL: http://www.ukreg.com/ukreg.exe
  postukreg: make block! []
  append postukreg reduce ["DOMAIN_NAME" lookupdomain]
  append postukreg ["ACTION" "4"]
 
  if error? try [ukregtmp: http-tools/post UKRegURL postukreg] [
    SendChan "Sorry, I couldn't connect to UKReg, Fasthosts is lame."
    return
    ]
    
  ukregresults: make string! ""
  parse ukregtmp/content [thru "Availability" copy ukregresults to "</table>"]
  ukregresults: trim striphtml ukregresults
  
  replace/all ukregresults "Available" rejoin [" Available" newline]
  replace/all ukregresults "Taken" rejoin [" Taken" newline]
  
  ukregresults: parse/all ukregresults "^/"
  
  domaintaken: make string! ""
  domainfree: make string! ""
  foreach domtest ukregresults [
    thisdom: pick (parse domtest none) 1
    either found? find domtest "Available" [
      domainfree: rejoin[domainfree " " thisdom ","]
      ][
      domaintaken: rejoin[domaintaken " " thisdom ","]
      ]
    ]
 
  if "" = domaintaken [domaintaken: " None "]
  if "" = domainfree [domainfree: " None "]
 
  domaintaken: copy/part domaintaken ((length? domaintaken) - 1)
  domainfree: copy/part domainfree ((length? domainfree) - 1)
  resultstring: rejoin["Taken:" domaintaken ". Free:" domainfree "."]
  SendChan resultstring
  ]
  
CheckPop: func [
  /local
  popboxurl
  mailcount
  mtmp
  mailcontent
  mailbody
  SMSFrom
  SMSBody
  ][
  popboxurl: make url! rejoin [ "pop://" xUser ":" xPass "@" xPop ]
  if error? try [popboxdump: open popboxurl] [
    print "There was an error opening the mailbox!"
    return
    ]
  mailcount: length? popboxdump
  if (mailcount > 0) [ print ["Messages found:" mailcount] ]
  while [not tail? popboxdump] [
    MTemp: first popboxdump
    mailcontent: import-email MTemp
    foundblog: false
    if not error? try [foo: mailcontent/subject] [
      if found? find mailcontent/subject "blog:" [
        either mailcontent/subject = "" [
          sendChan "Anti-retard code: Mail recieved with no subject!"
          ][
          BlogMail mailcontent
          ]
        foundblog: true
        ]
      if found? find mailcontent/subject "comment:" [
        CommentMail mailcontent
        foundblog: true
        ]
      ]
    if not foundblog [
      mailbody: parse/all mailcontent/content "^/"
      SMSFrom: to-string mailcontent/from
      SMSBody: pick mailbody 1
      either found? find (to-string mailcontent/from) "electricdeath.com" [
        if not found? find SMSBody "[WARN]" [
          SendChan SMSBody
          ]
        ][
        SendChan rejoin[bold "SMS received" bold " from " mailcontent/from ", ^"" underline SMSBody underline "^""]
        ]
      ]
    popboxdump: remove popboxdump
    ]
  if error? try [close popboxdump] [ print "bleh!" ]
  ]

AddTag: func [
  tagline
  /local
  gettags
  ][
  if ((nicktest saidnick) <> 2) [
    SendChan "You need ops for that."
    return
    ]
  if tagline = none [
    Sendchan "Try not to be a fucktard, mmkay?"
    return
    ]
  if ((length? tagline) > 140) [
    SendChan rejoin["Too long for a tagline, gotta be less than 140 chars. (That was "length? tagline")."]
    return
    ]
  
  GetTags: open/lines %tags.txt
  append GetTags tagline
  close GetTags
  either error? try [write FTP://eedweb#electricdeath.com:b0ll0x@ftp.electricdeath.com/../../var/www/html/taglines.txt read %tags.txt] [
    Sendchan "Couldn't upload the tags. Maybe next time someone adds one it will work. Don't re-try it or you'll get a dupe."
    return
    ][
    SendChan "Uploaded tagline."
    ]
  ]

AddFAQ: func [
  FAQterm
  Explanation
  /local
  GetFAQ
  FAQ
  ][
  
  if ((nicktest saidnick) <> 2) [
    SendChan "You need ops for that."
    return
    ]  
  
  either explanation [
    GetFAQ: open/lines FAQfile
    FAQ: copy GetFAQ
    Explanation: replace/all Explanation "#" "@"
    foreach FAQln FAQ [
      if find FAQln rejoin [FAQterm "#"] [
        SendChan rejoin ["A FAQ for '" FAQterm "' already exists."]
        close GetFAQ
        return
        ]
      ]
    append GetFAQ rejoin [FAQterm "#" Explanation]
    close GetFAQ
    SendChan rejoin ["FAQ explanation added."]
    ][
    SendChan "Probably a good idea to include an explanation, peon!"
    ]
  ]

ReadFAQ: func [
  FAQterm
  /local
  GetFAQ
  FAQ
  FaqReadOut
  ][
  GetFAQ: open/lines FAQfile
  FAQ: copy GetFAQ
  foreach FAQln FAQ [
    if find FAQln rejoin [FAQterm "#"] [
      FaqReadOut: ChanceDialect find/tail FAQln "#"
      SendChan Rejoin ["'"FAQterm"': " FaqReadOut]
      close GetFAQ
      return
      ]
    ]
    SendChan Rejoin ["'"FAQterm"': none found"]
    close GetFAQ
  ]

RandomFAQ: func [
  /local
  GetFAQ
  RandomLine
  FAQterm
  FaqReadOut
  ][
  GetFAQ: open/lines FAQfile
  RandomLine: pick GetFAQ (random (length? GetFAQ))
  Parse RandomLine [copy FAQterm to "#" thru "#" copy FaqReadOut to end]
  SendChan Rejoin ["'"FAQterm"': " FaqReadOut]
  ]

DelFAQ: func [ 
  FAQterm
  /local
  GetFAQ
  FAQ
  NewFAQ
  ][
  if ((nicktest saidnick) <> 2) [
    SendChan "You need ops for that."
    return
    ] 
  
  GetFAQ: open/lines FAQfile
  FAQ: copy GetFAQ
  NewFAQ: make block! []
  found: 0
  foreach FAQln FAQ [
    either find FAQln rejoin [FAQterm "#"] [
      found: 1
      ][
      append NewFAQ FAQln
      ]
    ]
  either found [
    SendChan rejoin["FAQ on '" FAQterm "' deleted."]
    close GetFAQ
    write/lines FAQfile NewFAQ
    ][
    SendChan rejoin["No FAQ found on '" FAQterm "'."]
    close GetFAQ
    ]
  ]

PostCode: func [
  pcode
  /local
  PostFile
  FoundPCs
  FirstArea
  PostGreater
  FoundCode
  SubAreas
  ][
  PostFile: read/lines %PostCodes2.txt
  
  FoundPCs: make block! []
  foreach pcline PostFile [
    pcblock: parse/all pcline ","
    if ((pick pcblock 3) = pcode) [
      append FoundPCs pcline
      ]
    ]
  
  either ((length? FoundPCs) = 0) [
    SendChan "No postcode in my database."
    ][
    FirstArea: pick FoundPCs 1
    PostGreater: pick (parse/all FirstArea ",") 2
    FoundCode: pick (parse/all FirstArea ",") 3
    SubAreas: ""
    foreach FoundPC FoundPCs [
      SubAreas: rejoin[SubAreas ", " pick (parse/all FoundPC ",") 1]
      ]
    SendChan Rejoin[FoundCode ": " PostGreater " including " (skip SubAreas 2) "."]  
    ]
    PostFile: ""
  ]

GameReview: func [
  xtype
  searchterm
  /local
  gamesrankgsurl
  postdata
  results
  furl
  gblock
  resultstring
  ][
  gamerankingsurl: http://www.gamerankings.com/itemrankings/itemsearch.asp
  postdata: make block! []
  append postdata reduce["itemname" searchterm]
  append postdata reduce["extsearch" "0"]
  if error? try [gamerankings: http-tools/post gamerankingsurl postdata] [
    if xtype = "irc" [SendChan "Gamerankings is fux0red."]
    return
    ]
  results: gamerankings/content
  if found? find results "0 matching records" [
    if xtype = "irc" [SendChan "No game reviews found."]
    return
    ]
  either found? find results "<h1>Object Moved</h1>" [
    parse results [thru {HREF="} copy furl to {">}]
    furl: join http://www.gamerankings.com furl
    if error? try [results: read furl] [
      if xtype = "irc" [SendChan "Gamerankings is fux0red."]
      return
      ]
    parse results [thru {ITEMHEAD>&nbsp;} copy gtitle to " -" thru "- " copy gplatform to "</div>" 
                   thru {22px;"><b>} copy gscore to "</b>"]
    SendChan rejoin[gtitle " ("gplatform") "trim/lines gscore]
    ][
    gblock: make block! []
    while [found? results: find/tail results "id=SEARCHRESULTS"] [
      gtitle: ""
      parse results [thru "<b>" copy gtitle to "</b>" thru "valign=top>" copy gplatform to "</td>" thru {align="right">} copy gscore to "</td>"]
      append gblock trim/lines gtitle
      append gblock trim/lines gplatform
      append gblock trim/lines gscore
      ]
    resultstring: ""
    foreach [gtitle gplatform gscore] gblock [
      resultstring: rejoin[resultstring gtitle " ("gplatform") "gscore", "]
      ]
    if xtype = "irc" [SendChan copy/part resultstring ((length? resultstring) - 2)]
    if xtype = "text" [
      textsendout: TruncSentence (copy/part resultstring ((length? resultstring) - 2)) 160
      ]
    ]
  ]
  
  
Googlewebsite: func [
  searchterm
  /local
  gweburl
  gwebrate
  googleurl
  googlepage
  ][
  if searchterm = "" [
    SendChan "How about something to search for?"
    return
    ]  
  
  googleurl: join http://labs.google.com/cgi-bin/webquotes?btnG=Google+WebQuotes+Search&num_quotes=1&snippet_threshold=1&show_titles=1&bold_links=1&num=1&q= url-encode searchterm
  if error? try [googlepage: read googleurl] [
    SendChan "Google fux0red."
    return
    ]
  
  if found? find googlepage "0 WebQuotes" [
    SendChan "Nothing returned."
    return
    ]
  
  gweburl: ""
  gwebrate: ""
  parse googlepage [thru "<span><p><a href=" copy gweburl to ">"
                    thru "<li><p><font size=-1>" copy gwebrate to "<br>" 
                   ]
                   
  replace/all gwebrate "</b>" "#@#"
  replace/all gwebrate "<b>" "#@#"
  gwebrate: striphtml gwebrate
  replace/all gwebrate "#@#" bold
       
  SendChan rejoin[gwebrate " " gweburl]
  ]
  

SearchWeb: func [
  searchphrase
  /local
  urlsearch
  GoogleURL
  readpage
  searchhit
  temphit
  ][
  if searchphrase = "" [
    SendChan "How about something to search for?"
    return
    ]
  urlsearch: url-encode searchphrase
  GoogleURL: make url! rejoin [ "http://www.google.com/search?q=" urlsearch "&hl=en&lr=&safe=off&btnG=Google+Search" ]
  if error? try [readpage: read GoogleURL][
    SendChan "Google didn't respond, fuck knows why."
    return
    ]
  either find readpage "</b> - did not match any documents" [
    SendChan rejoin["Nothing found on '" searchphrase "'."]
    ][
    searchhit: make string! ""
    title: make string! ""
    parse readpage [ thru "<div><p class=g>" thru {href="} copy searchhit to {"} thru ">" copy title to "</a>"]
    if "/url" = left searchhit 4 [
      temphit: make string! ""
      parse searchhit [thru "&q=" copy temphit to "&"]
      searchhit: temphit
      ]
    title: replace/all title "<b>" ""
    title: replace/all title "</b>" ""
    title: replace/all title ">" ""
    SendChan rejoin [searchhit " - " title]
  ]
]

FindProfane: func [
  findwhat
  /local
  maxhits
  report
  hits
  profanity
  definition
  ][
  if (findwhat = none) [
    SendChan "How about something to search for?"
    return
    ]
  maxhits: 3
  Profanedata: read/lines %profanisaurus.txt
  report: ""
  hits: 0
  foreach profaneline profanedata [
    profanity: ""
    definition: ""
    parse profaneline [copy profanity to "#" thru "#" copy definition to end]
    if found? find profanity findwhat [
      hits: hits + 1
      replace/all definition "<i>" ""
      replace/all definition "</i>" ""
      SendChan rejoin[report hits ". " underline profanity underline": "definition]
      maxhits: maxhits - 1
      ]
    if maxhits = 0 [break]
    ]
  if hits = 0 [
    SendChan "Nothing found in Roger's Profanisaurus."
    ]
  ]
  
RandomProfane: func [
  /local
  profanedata
  profaneline
  profanity
  definition
  ][
  Profanedata: read/lines %profanisaurus.txt
  Profaneline: pick ProfaneData (random length? ProfaneData)
  profanity: ""
  definition: ""
  parse profaneline [copy profanity to "#" thru "#" copy definition to end]
  replace/all definition "<i>" ""
  replace/all definition "</i>" ""
  SendChan rejoin[underline profanity underline": "definition]
  ]
 
right: func [
   string [string!] 
   n [integer!] 
   /with char [char!]
  ][
    
   head 
     insert/dup 
       copy/part string n 
       any [char #" "] 
       subtract n length? string
]


left: func [
   string [string!] 
   n [integer!] 
   /with char [char!]
] [
   head 
     insert/dup 
       tail copy/part string n 
       any [char #" "] 
       subtract n length? string
]

SendChan: func [
  whattosay
   ][
 sendCMD rejoin ["PRIVMSG " channel " :" whattosay]
 printx rejoin["# "whattosay]
]

Printx: func [
  logwhat
  ][
  print logwhat
  if logging [
    Log: rejoin[log now/time " " logwhat newline]
    ]
  ]

LogFlush: func [
  /local
  filename
  ][
 if logging [ 
   filename: to-file rejoin["logs/"now/date".log"]
   write/append filename Log
   ]
   Log: ""
 ]

PrivMSG: func [
  whattosay
  ][  
  SendCMD rejoin ["PRIVMSG " currentnick " :" whattosay]
]
  
Quitchannel: func [
 quitmsg
 ][
 SendCMD rejoin ["PART " channel " :" quitmsg ]
]

HelpSubject: func [
  hsubject
 ][
  switch hsubject [
    "commands" [
       PrivMSG rejoin ["This was so out of date I removed it. See http://www.electricdeath.com/irc.php instead."]
    ]
  ]
]
 
    
Testphone: func [
  phonenum [string!]
  ][
  if (copy/part phonenum 1) = "+" [
    phonenum: copy skip phonenum 1
    ]
  if error? try [foo: to-integer phonenum] [return false]
  if (copy/part phonenum 1) = "0" [
    phonenum: rejoin["44" copy skip phonenum 1]
    ]
  return phonenum  
  ]


AddSMS: func [
  addnick
  addnumber
  ][
  if ((addnick = none) or (addnumber = none)) [
    SendChan "Get some skillz ffs."
    return
    ]
  if ((nicktest saidnick) <> 2) [
    SendChan "You need ops for that."
    return
    ]  
  smslist: read/lines %smslist.txt
  foundwho: false
  foreach [nick number] smslist [
    if nick = addnick [
      smsnumber: number
      foundwho: true
      break
      ]
    ]
  if foundwho [
    SendChan rejoin ["There is already an account for "addnick", I have +"smsnumber" in my database."]
    return
    ]
  
  realnumber: Testphone addnumber 
  either realnumber [
    append smslist reduce[addnick realnumber]
    write/lines %smslist.txt smslist
    SendChan rejoin["Added "addnick" to phone database."]
    ][
    SendChan "Dodgy phone number. Examples of correct numbers: 07960529333 (assumed to be UK), +447960529333, 447960529333."
    ]
  ]

DelSMS: func [
  delnick
  ][
  if (delnick = none) [
    SendChan "Get some skillz ffs."
    return
    ]
  if ((nicktest saidnick) <> 2) [
    SendChan "You need ops for that."
    return
    ]  
  smslist: read/lines %smslist.txt
  newlist: make block! []
  foundwho: false
  foreach [nick number] smslist [
    either nick = delnick [
      foundwho: true
      ][
      append newlist reduce [nick number]
      ]
    ]
  if not foundwho [
    SendChan "No such user to delete."
    return
    ]
  write/lines %smslist.txt newlist
  SendChan rejoin["Entry for "delnick" removed from database."]
  ]
  
ListSMS: func [
  /local
  smslist
  nicklistx
  ][
  if ((nicktest saidnick) <> 2) [
    SendChan "You need ops for that."
    return
    ]
  smslist: read/lines %smslist.txt
  nicklistx: ""
  foreach [name number] smslist [
    nicklistx: rejoin[nicklistx name ", "]
    ]
  SendChan rejoin["I have accounts for: "copy/part nicklistx ((length? nicklistx) - 2)"."]
  ]

PollSMS: func [
  /local
  SMSes
  SMScontent
  SMSbody
  SMSnumber
  foundnick
  foundwho
  fromnumber
  firstcommand
  emailaddy
  mailheader
  bodymail
  ][
  SMSes: load %/c/sms/
  if (length? SMSes) = 0 [return] 
  foreach SMS SMSes [
    SMScontent: read rejoin[%/c/sms/ SMS]
    either found? find SMSContent "**This" [
      parse SMScontent [thru newline thru newline copy SMSNumber to newline thru newline copy SMSbody to "**This"]
      ][
      parse SMScontent [thru newline thru newline copy SMSNumber to newline thru newline copy SMSbody to end]
      ]
    either (SMSbody = none) [
      SMSBody: "<blank message>"
      ][
      replace/all SMSbody newline " "
      ]
    replace SMSnumber "+" ""
    firstcommand: pick (parse SMSbody none) 1
    switch/default firstcommand [
      "mail" [ 
        emailaddy: pick (parse SMSbody none) 2
        mailheader: make system/standard/email [
	  From: postmaster@0wnerage.com
	  subject: rejoin ["Message from +" SMSNumber]
	  Organization: rejoin[nick " "rebotver]
	  ]
	bodymail: find/tail SMSbody rejoin[emailaddy " "]
	bodymail: rejoin["The following message is from the Rebot SMS2Email gateway:"newline newline bodymail newline newline "--" newline nick " "rebotver newline]
	Print rejoin["Received SMS from +"SMSNumber", gating mail to "emailaddy"."]
	try [send/header to-email emailaddy bodymail mailheader]
        ]
      "ebay" [
        textsendout: ""
        EbayNew "sms" "current" (find/tail SMSbody "ebay ")
         if textsendout [
           Print "Sending eBay current query"
           try [Clickatell_stealthsend SMSNumber textsendout]
           ]
        ]        
      "ebayuser" [
        textsendout: ""
        EBaySeller "sms" (find/tail SMSbody "ebayuser ")
         if textsendout [
           Print "Sending eBay user query"
           try [Clickatell_stealthsend SMSNumber textsendout]
           ]
        ]          
      "imdb" [
        textsendout: ""
        IMDBSearch "text" (find/tail SMSbody "imdb ")
        if textsendout [
          Print "Sending IMDB query"
          try [Clickatell_stealthsend SMSNumber textsendout]
          ]
        ]
      "review" [
        textsendout: ""
        GameReview "text" (find/tail SMSbody "review ")
        if textsendout [
          Print "Sending GameReview query"
          try [Clickatell_stealthsend SMSNumber textsendout]
          ]
        ]
      "number" [
        textsendout: ""
        clickatell_vcard SMSNumber (find/tail SMSbody "number ")
        ]
       
      ][
      ;
      ; No commands found so print the message to channel
      ;
      smslist: read/lines %smslist.txt
      foundwho: false
      foreach [nick number] smslist [
        if number = SMSnumber [
  	foundnick: nick
  	foundwho: true
  	break
  	]
        ]
      either found? find smsbody "http://www.orange.co.uk/mms/" [
        ;
        ; If it's an MMS
        ;
        parse smsbody [thru "ID is: " copy mms_msgid to " " thru "password is: " copy mms_password to " "]
        either foundwho [
          SendChan rejoin[bold "MMS:" bold " from "foundnick" - http://193.36.78.4:7001/en/webnonsubscriber/nonsubscriberlogin.do?msgId="mms_msgid"&password="mms_password]          
          ][
          SendChan rejoin[bold "MMS:" bold " from +"SMSnumber" - http://193.36.78.4:7001/en/webnonsubscriber/nonsubscriberlogin.do?msgId="mms_msgid"&password="mms_password]          
          ]
        ][
        ;
        ; If it's an SMS
        ;
        either foundwho [
          SendChan rejoin[bold "SMS:" bold " <" foundnick "> "SMSbody]
          ][
          SendChan rejoin[bold "SMS:" bold " <+" SMSnumber "> "SMSbody]
          ]
        ]
      ]
    ;
    ; Delete the SMS file
    ;
    delete rejoin[%/c/sms/ SMS]
    ]
  ]

Clickatell_login: func [
  /local
  response
  ][
  if error? try [response: read http://api.clickatell.com/http/auth?api_id=175930&user=Lurks&password=blax0r] [
    session_id: false
    ]
  either found? find response "OK:" [
    session_id: find/tail response "OK: "
    ][
    session_id: false
    ]
  ]

Clickatell_balance: func [
  /local
  response
  ][
  Clickatell_login
  if not session_id [
    SendChan "Couldn't send request to Clickatell gateway, it might be down? The cunts."
    return
    ]
  If error? try [response: read rejoin[http://api.clickatell.com/http/getbalance?session_id= session_id]] [
    SendChan "Couldn't send request to Clickatell gateway, it might be down? The cunts."
    return
    ]
  SendChan rejoin["There are "find/tail response ": " " remaining text credits on Clickatell."]
  ]

Clickatell_stealthsend: func [
 sendto
 sendtext
  /local
 response
 status
 ][
  Clickatell_login
  if not session_id [
    return
    ]
  If error? try [response: read rejoin[http://api.clickatell.com/http/sendmsg?session_id= session_id "&to=" sendto "&from=447976225361&text=" url-encode sendtext]] [
    return
    ]
  ]

Clickatell_SendSMS: func [
  smstype
  smswho
  sendwhat
  /local
  smsurl
  responsedata
  responseid
  ][
  if ((smswho = none) or (sendwhat = none)) [
    SendChan "Get some skillz ffs."
    return
    ]
  if ((nicktest saidnick) <> 2) [
    SendChan "You need ops for that."
    return
    ]  
  if ((length? sendwhat) > 160) [
    SendChan "160 char max for SMS, bud."
    return
    ]
  
  smslist: read/lines %smslist.txt
  foundwho: false
  foreach [nick number] smslist [
    if nick = smswho [
      smsnumber: number
      foundwho: true
      break
      ]
    ]
  if not foundwho [
    SendChan "I have no account for that nick, better tell Lurks."
    return
    ]
  
  sendwhat: rejoin[saidnick": " newline sendwhat]
  if ((length? sendwhat) > 160) [
    SendChan "160 char max for SMS, bud."
    return
    ]
    
  Clickatell_login
  if not session_id [
    SendChan "Couldn't send request to Clickatell gateway, it might be down? The cunts."
    return
    ]
  if smstype = "test" [smsnumber: rejoin["279999" smsnumber]]
  If error? try [response: read rejoin[http://api.clickatell.com/http/sendmsg?session_id= session_id "&to=" smsnumber "&from=447976225361&text=" url-encode sendwhat]] [
    SendChan "Couldn't send request to Clickatell gateway, it might be down? The cunts."
    return
    ]
  if found? find response "ERR" [
    switch find/tail "ERR: " [
      "001" [status:"Authentication failed"]
      "002" [status:"Unknown username or password"]
      "003" [status:"Session ID expired"]
      "004" [status:"Account frozen"]
      "005" [status:"Missing session ID"]
      "101" [status:"Invalid or missing parameters"]
      "102" [status:"Invalid UDH"]
      "103" [status:"Unknown apimsgid"]
      "104" [status:"Unknown climsgid"]
      "105" [status:"Invalid Destination Address"]
      "106" [status:"Invalid Source Address"]
      "107" [status:"Empty message"]
      "108" [status:"Invalid or missing api_id"]
      "109" [status:"Missing message ID"]
      "110" [status:"Error with email message"]
      "111" [status:"Invalid Protocol"]
      "112" [status:"Invalid msg_type"]
      "113" [status:"Max message parts exceeded"]
      "114" [status:"Cannot route message"]
      "115" [status:"Message expired"]
      "116" [status:"Invalid Unicode Data"]
      "201" [status:"Invalid batch ID"]
      "202" [status:"No batch template"]
      "301" [status:"No credit left"]
      "302" [status:"Max allowed credit"]
      ]
    SendChan rejoin["Clickatell spazzed out: "status"."]
    return
    ]

  If found? find response "ID:" [
    SendChan "Sent."
    wait 5
    If error? try [response: read rejoin[http://api.clickatell.com/http/querymsg?session_id= session_id "&apimsgid=" (find/tail response "ID: ")]] [
      SendChan "Couldn't send request to Clickatell gateway, it might be down? The cunts."
      return
      ]
    if found? find response "Status" [
      switch find/tail response "Status: " [
        ;"001" [SendChan rejoin["SMS: Message unknown."]]
        ;"002" [SendChan rejoin["SMS: Message queued."]]
        ;"003" [SendChan rejoin["SMS: Delivered."]]
        "004" [SendChan rejoin["SMS: Received by recipient."]]
        "005" [SendChan rejoin["SMS: Error with message."]]
        "006" [SendChan rejoin["SMS: User cancelled message delivery."]]
        "007" [SendChan rejoin["SMS: Error delivering message."]]
        ;"008" [SendChan rejoin["SMS: OK."]]
        "009" [SendChan rejoin["SMS: Routing error."]]
        "010" [SendChan rejoin["SMS: Message expired."]]
        ;"011" [SendChan rejoin["SMS: Message queued for later delivery."]]
        "012" [SendChan rejoin["SMS: Out of Credit."]]
        ]
      ]  
    ]
  ]

Clickatell_vcard: func [
  sendto
  smswho
  /local
  ][
  
  if smswho = none [
    print "debug: smswhois none in clickatell_vcard"
    return
    ]
  
  smslist: read/lines %smslist.txt
  foundwho: false
  foreach [nick number] smslist [
    if nick = smswho [
      smswho: nick
      smsnumber: number
      foundwho: true
      break
      ]
    ]
  if not foundwho [
    clickatell_stealthsend sendto rejoin["Rebot: Sorry, I don't have "smswho"'s number."]
    return
    ]
  
  vcardtext: rejoin["BEGIN%3AVCARD%0D%0AVERSION%3A2.1%0D%0AN%3A" smswho "%0D%0ATEL%3BPREF%3A%2B" smsnumber "%0D%0AEND%3AVCARD%0D%0A"]

  Clickatell_login
  if not session_id [
    return
    ]
  
  If error? try [response: read rejoin[http://api.clickatell.com/http/sendmsg?session_id= session_id "&to=" sendto "&msg_type=SMS_NOKIA_VCARD&from=447976225361&text=" vcardtext]] [
    return
    ]
  ]

SMSGroup_Mez: func [
  cmdargs
  /local
  argwords
  cmd
  group
  nicks
  smsgrouplist
  grouplisttext
  nickblock
  smslist
  dufflist
  ][
  if ((nicktest saidnick) <> 2) [
    SendChan "You need ops for that."
    return
    ]  
  if cmdargs = none [
      SendChan rejoin["Usage: "nick "smsgroup <list|listgroup|add|delete|send> [group] [number of nicks, seperated by comma or send text]"]
      SendChan rejoin["Example: rebot smsgroup add gaylords slim,beej,dr_dave"]
      SendChan rejoin["Example: rebot smsgroup listgroup gaylords"]
      SendChan rejoin["Example: rebot smsgroup send gaylords You love it up you!"]
      return
      ]  
  argwords: parse cmdargs " "
  cmd: pick argwords 1
  group: pick argwords 2
  nicks: pick argwords 3
  if cmd = "list" [
    smsgrouplist: read/lines %smsgrouplist.txt
    grouplisttext: ""
    foreach [group grouplist] smsgrouplist [
      grouplisttext: rejoin[grouplisttext group ", "]
      ]
    grouplisttext: rejoin[copy/part grouplisttext ((length? grouplisttext) - 2)". "]
    SendChan rejoin["Current SMS Groups: "grouplisttext]
    return
    ]
  if cmd = "listgroup" [
    smsgrouplist: read/lines %smsgrouplist.txt
    foundgroup: false
    foreach [groupx grouplist] smsgrouplist [
      if group = groupx [
        foundgroup: true
        nicklistx: parse grouplist " "
        ]
      ]
    if not foundgroup [
      SendChan "No such group, use list to find out what groups there are. If you can read."
      return
      ]
    grouplisttext: ""
    foreach nick nicklistx [
      grouplisttext: rejoin[grouplisttext nick ", "]
      ]
    grouplisttext: rejoin[copy/part grouplisttext ((length? grouplisttext) - 2)". "]
    SendChan rejoin["SMS group '"group"' contains members: "grouplisttext]
    return
    ]    
  if cmd = "send" [
    SMSGroup_send group (find/tail cmdargs rejoin[group " "])
    return
    ]
  if ((cmd = "add") or (cmd = "delete")) [
    if ((group = none) or (nicks = none)) [
      SendChan rejoin["Usage: "nick "smsgroup <list|listgroup|add|delete|send> [group] [number of nicks, seperated by comma or send text]"]
      SendChan rejoin["Example: rebot smsgroup add gaylords slim,beej,dr_dave"]
      SendChan rejoin["Example: rebot smsgroup listgroup gaylords"]
      SendChan rejoin["Example: rebot smsgroup send gaylords You love it up you!"]
      return
      ]   
    nickblock: parse nicks ","
    ;
    ; Now we make sure all the nicks are valid
    ;
    smslist: read/lines %smslist.txt
    dufflist: ""
    foreach givennick nickblock [
      foundwho: false
      foreach [nick number] smslist [
        if nick = givennick [foundwho: true]
        ]
      if not foundwho [dufflist: rejoin[dufflist givennick ", "]]
      ]
    if dufflist <> "" [
      Sendchan rejoin["Oi, fuckfart. You can't add/remove nicks to groups if they they aint got an account: "copy/part dufflist ((length? dufflist) - 2)"."]
      return
      ]     
    if cmd = "add" [SMSGroup_add group nickblock]
    if cmd = "delete" [SMSGroup_delete group nickblock]    
    ]
  ]

SMSGroup_add: func [
  smsgroup
  nicks
  /local
  smsgrouplist
  newlist
  foundexisting
  grouplist
  newgline
  ][
  if ((nicktest saidnick) <> 2) [
    SendChan "You need ops for that."
    return
    ]  
  smsgrouplist: read/lines %smsgrouplist.txt
  newlist: make block! []
  foundexisting: false
  foreach [group grouplist] smsgrouplist [
    grouplist: parse grouplist none
    if smsgroup = group [
      append grouplist nicks
      foundexisting: true
      ]
    grouplist: sort unique grouplist
    newgline: ""
    foreach gitem grouplist [
      newgline: rejoin[newgline gitem " "]
      ]
    append newlist group
    append newlist newgline
    ]
  either not foundexisting [
    newgline: ""
    foreach gitem nicks [
      newgline: rejoin[newgline gitem " "]
      ]
    append newlist smsgroup
    append newlist newgline
    SendChan "New SMS Group added."
    ][
    SendChan "SMS Group updated."
    ]
  write/lines %smsgrouplist.txt newlist
  ]
  
SMSGroup_delete: func [
  smsgroup
  nicks
  smsgrouplist
  newlist
  foundexisting
  grouplist
  newgline
  ][
  if ((nicktest saidnick) <> 2) [
    SendChan "You need ops for that."
    return
    ]  
  smsgrouplist: read/lines %smsgrouplist.txt
  newlist: make block! []
  foundexisting: false
  deletedgroup: false
  foreach [group grouplist] smsgrouplist [
    grouplist: parse grouplist none
    if smsgroup = group [
      grouplist: subtractblock grouplist nicks
      foundexisting: true
      ]
    either (grouplist = []) [
      deletedgroup: true
      ][
      grouplist: sort unique grouplist
      newgline: ""
      foreach gitem grouplist [
        newgline: rejoin[newgline gitem " "]
        ]
      append newlist group
      append newlist newgline
      ]
    ]
  either not foundexisting [
    SendChan "No such SMS Group you fucking retard."
    ][
    either deletedgroup [
      SendChan "SMS Group deleted."
      ][
      SendChan "SMS Group updated."
      ]
    write/lines %smsgrouplist.txt newlist
    ]
  ]
  
subtractblock: func [
  originalblock
  blocktosubtract
  /local
  foundsub
  ][
  newblock: make block! []
  foreach nvalue originalblock [
    foundsub: false
    foreach svalue blocktosubtract [
      if nvalue = svalue [foundsub: true]
      ]
    if not foundsub [append newblock nvalue]
    ]
  newblock
  ]

SMSGroup_send: func [
  smsgroup
  sendwhat
  /local
  smslist
  smsgrouplist
  foundgroup
  msgtxt
  ][
  if ((smsgroup = none) or (sendwhat = none)) [
    SendChan rejoin["Usage: smsgroup <group> <message...>"]
    return
    ]
  sendwhat: rejoin["Message from "saidnick" to '"smsgroup"' group:" newline sendwhat]
  if ((length? sendwhat) > 169) [
    SendChan "169 char max for SMS, bud."
    return
    ]
  smslist: read/lines %smslist.txt
  smsgrouplist: read/lines %smsgrouplist.txt
  foundgroup: false
  foreach [smsgroupname smsgroupnicks] smsgrouplist [
    if smsgroupname = smsgroup [
      foundgroup: true
      listnicks: parse smsgroupnicks none
      ]
    ]
  if not foundgroup [
    SendChan "Hey brainbox, how about sending a message to a group that exists. Why must humans be so stupid?"
    return
    ]
  msgtxt: ""
  foreach smsnick listnicks [
    foreach [nick number] smslist [
      if smsnick = nick [
        fnumber: number
        break
        ]
      ]
    msgtxt: rejoin[msgtxt smsnick ", "]
    Clickatell_stealthsend fnumber sendwhat
    ]
  SendChan rejoin["Group SMS sent to: "copy/part msgtxt ((length? msgtxt) - 2)"."]
  ]
 
SendMail: func [
  sendaddy
  sendmsg
  ][
  
  if ((saidnick <> nick) and ((nicktest saidnick) <> 2)) [
    SendChan "You need ops for that."
    return
    ]
  
  RebotUsers: read/lines RebotAccessFile
  foreach RUser RebotUsers [
    RUsername: make string! ""
    REmail: make string! ""
    Parse RUser [copy RUsername to "#"]
    Parse RUser [thru "#" copy REmail to "&"]
    REmail: make email! REmail
    RSMS: make email! find/tail Ruser "&"
    mailheader: make system/standard/email [
      From: rebot@0wnerage.com
      Subject: rejoin [saidnick ": "TruncSentence sendmsg 80]
      Organization: rejoin[nick " "rebotver]
    ]
    if RUsername = sendaddy [
      either mailtype = "sms" [
        if 0 = length? rsms [
          SendChan rejoin["'" sendaddy "' is a peon and has no SMS gateway defined."]
          return
          ]
        if find RSMS "orange.net" [
          mailheader: make system/standard/email [
           Subject: sendmsg
           Organization: rejoin[nick" "rebotver]
          ]
          sendmsg: "Message in subject"
        ]
        send/header RSMS sendmsg mailheader
        SendChan rejoin["SMS sent to '" sendaddy "'"]
        return
        ][
        sendmsg: Wrap 80 ChanceDialect sendmsg
        send/header REmail sendmsg mailheader
        SendChan rejoin["Email sent to '" sendaddy "'"]
        return
        ]
      ]
    ]

  if not error? try [actualemail: to-email sendaddy] [
    mailheader: make system/standard/email [
      From: rebot@0wnerage.com
      Subject: rejoin ["Message from " saidnick " on channel " channel]
      Organization: rejoin[nick " "rebotver]
    ]
    sendmsg: Wrap 80 sendmsg
    send/header actualemail sendmsg mailheader
    SendChan "Sent."
    return
    ]   

  SendChan rejoin["User '" sendaddy "' has no account. http://wench.0wnerage.com/contact.html to add one."]
  ]

TellTime: func [
 tellwhat
 ][
 either tellwhat [
   switch/default tellwhat [
     "time" [ SendChan now/time ]
     "date" [ SendChan now/date ]
     "tagline" [
       Taglines: read/lines %tags.txt
       RanTN: random length? Taglines
       SendChan ChanceDialect pick Taglines RanTN
       ]
     "croism" [
       Taglines: read/lines %RebotCroisms.txt
       RanTN: random length? Taglines
       SendChan pick Taglines RanTN
       ]
     "bullshit" [
       SendChan bull
       ]
     "profanity" [ RandomProfane ]
     "sexact" [
       PickSex: random 846
       if error? try [SexPage: read to-url rejoin["http://www.odd-sex.com/info/gloss"PickSex".htm"]] [
         SendChan "Couldn't read the Encyclopedia of Unusual Sex Practices. Too pervy for you anyway!"
         return
         ]
       Parse SexPage [thru "<li>" copy SexName to ":" thru ":  " copy SexDesc to "</li>"]
       SendChan rejoin[Sexname ": " (uppercase copy/part SexDesc 1) (copy skip SexDesc 1)"."]
       ]
     ][
     SendChan rejoin [ "I don't know how." ]
     ]
   ][
   SendChan "Tell you what, exactly?"
   return
  ]
]

striphtml: func [page /local text end] [

	multi-replace: func [
		{Replaces multiple items in a file}
		pg	[series!] {The series to replace items in}
		blk [block!] {A block of search and replace elements}
	][foreach [srch rplc] blk [replace/all pg srch rplc]]

    ;table of tags and more suitable ASCII characters
    page: multi-replace trim/lines page [
        "<TITLE>"    ""
        "</TITLE>"   ""
        "  "         " "
        "<TD>"       ""
        "</TD>"      ""

        "<TR>"       " "
        "</TR>"      ""
        "<TABLE"    ""
        "</TABLE>"   ""
        "<P>"        ""
        "<LI>"       ""
        "<BR>"       ""
        "&nbsp;"     " "
        "&gt;"       ">"
        "&lt;"       "<"
        "&copy;"     "(c)"
        "&amp;"      "&"
        "&quot;"     {"}
        "</H1>"      ""
        "</H2>"      ""
        "</H3>"      ""
        "</H4>"      ""
        "</H5>"      ""
        "</H6>"      ""
        "<HR"        ""
        "%24"        "$"
        "%26"        "&"
        "%2B"        "+"
        "%2C"        ","
        "%2F"        "/"
        "%3A"        ":"
        "%3B"        ";"
        "%3D"        "="
        "%3F"        "?"
        "%40"        "@"
        "&#32;"      " "
        "&#33;"      "!"
        "&#34;"      {"}
        "&#35;"      "#"
        "&#36;"      "$"
        "&#37;"      "%"
        "&#38;"      "&"
        "&#39;"      "'"
        "&#40;"      "("
        "&#41;"      ")"
        "&#42;"      "*"
        "&#43;"      "+"
        "&#44;"      ","
        "&#45;"      "-"
        "&#46;"      "."
        "&#47;"      "/"
  
    ]
    text: copy ""

    append page "<"
    append text copy/part page find page "<"
    while [page: find/tail page ">"] [
        if (first page) <> #"<" [
            if found? end: find page "<" [
                append text copy/part page end
            ]
        ]
    ]
    return text
]

UrbanDictionary: func [
  findwhat
  /local
  UrbanURL
  UrbanPage
  UrbanName
  UrbanPro
  UrbanDef
  UrbanUse
  ][
  UrbanURL: join http://www.urbandictionary.com/define.php?term= url-encode findwhat
  if error? try [UrbanPage: read UrbanURL] [
    SendChan "Urban dictionary is fucked."
    return
    ]
  if found? find UrbanPage "No entry found for" [
    SendChan "Nothing found in the Urban dictionary."
    return
    ]
  
  UrbanPage: find/tail UrbanPage "found.</font>"
  
  UrbanName: make block! []
  UrbanPro:  make block! []
  UrbanDef:  make block! []
  UrbanUse:  make block! []
  parse UrbanPage [any [thru {"#C25426">} copy founddata to "<"
                        (
                        append UrbanName striphtml founddata
                        )
                        thru "<td>" copy founddata to "</td>"
                        (
                        append UrbanPro striphtml founddata
                        )
                        thru "<p>" copy founddata to "</p>"
                        (
                        append UrbanDef striphtml trim/lines founddata
                        )
                        thru "<p>" copy founddata to "</i>"
                        (
                        append UrbanUse striphtml trim/lines founddata
                        )
                       ]
                  ]
  
   PickUrban: random (length? UrbanName)
   SendChan rejoin[(pick UrbanName PickUrban) " ("
                   (pick UrbanPro PickUrban)  "): "
                   (pick UrbanDef PickUrban)  " "
                   (pick UrbanUse PickUrban)
                  ]
   ]
  

IMDBSearch: func [
  xtype
  searchwhat
  /local
  IMDBFindURL
  SubmitForm
  imdbtmp
  SearchHItData
  MovieTitle
  MovieYear
  Plotoutline
  UserRating
  iresponse
  ][

  if searchwhat = none [
    SendChan "Oh fuck off."
    return
    ]
  
  IMDBFindURL: http://us.imdb.com/Find
  
  SubmitForm: make block! []
  
  append SubmitForm ["select" "Titles"]
  append SubmitForm reduce ["for" searchwhat]
  
  if error? try [imdbtmp: http-tools/post IMDBFindURL SubmitForm] [
    if xtype = "irc" [SendChan "IMDB is b0rked."]
    return
    ]
  
  if found? find imdbtmp/content "<P>Sorry there were no matches for the title,<BR" [
    if xtype = "irc" [SendChan "Nothing found on IMDB."]
    return
    ]
  
  either found? find imdbtmp/content "<H1>IMDb title search" [
    partURL: ""
    either found? find imdbtmp/content "Most popular searches</A></H2>" [
      parse imdbtmp/content [thru "Most popular searches</A></H2>" thru {HREF="} copy parturl to {"}]
      ][
      if not found? find imdbtmp/content {<A NAME="mov">Movies} [
        if xtype = "irc" [SendChan "No popular hits returned, no movies returned. Giving up."]
        return
        ]
      parse imdbtmp/content [thru {<A NAME="mov">Movies} thru {HREF="} copy parturl to {"}]
      ]
    RealURL: to-url rejoin["http://us.imdb.com" parturl]
    if error? try [SearchHitData: read RealURL] [
      if xtype = "irc" [SendChan "IMDB is b0rked."]
      return
      ]
    ][
    RealURL: to-url copy imdbtmp/Location
    if error? try [SearchHitData: read RealURL] [
      if xtype = "irc" [SendChan "IMDB is b0rked."]
      return
      ]
    ]

  
  MovieTitle: ""
  MovieYear: ""
  Plotoutline: ""
  UserRating: ""
  Parse SearchHitData [thru "<title>" copy MovieTitle to "</title>"]
  
  either found? find SearchHitData "Plot Outline:</b> " [
    Parse SearchHitData [thru "Plot Outline:</b>" copy PlotOutline to "<br>"]
    ][
    if found? find SearchHitData "Tagline:</b> " [
      Parse SearchHitData [thru "Tagline:</b> " copy PlotOutline to "<br>"]
      ]
    ]
  
  either found? find SearchHitData "User Rating:</b>" [
    either found? find SearchHitData "awaiting 5 votes." [
      UserRating: "Not yet rated"
      ][
      Parse SearchHitData [thru "User Rating:</b>" thru "<b>" copy UserRating to "/"]
      UserRating: rejoin[UserRating"/10"]
      ]
    ][
    UserRating: "Not rated"
    ]
  
  UserComment: ""
  if found? find SearchHitData "User Comments:</b>" [
    parse SearchHitData [thru "User Comments:</b>" copy UserComment to "<"]
    UserComment: rejoin [{IMDB user comment: "} trim/lines Usercomment {"}]
    ]
  
  replace/all MovieTitle "&#34;" {"}
  Plotoutline: trim/lines striphtml Plotoutline
  replace/all Plotoutline "&#34;" {"}
 
  if found? find SearchHitData "[TV-Series]" [
    MovieTitle: rejoin[MovieTitle" [TV-Series]"]
    ]
 
  replace Plotoutline " (view trailer)" ""
  replace Plotoutline " (more)" ""
  
  if xtype = "irc" [
    iresponse: rejoin[MovieTitle ": " PlotOutline UserComment" "UserRating"."]
    SendChan iresponse
    ]
  if xtype = "text" [  
    replace UserComment "IMDB user c" "C"
    iresponse: rejoin[MovieTitle ": " (TruncSentence PlotOutline 85) " " UserComment" "UserRating"."]
    textsendout: iresponse
    ]
  ]
  
WhichIsBest: func [
  whatisbest
  /local
  whatisbestwords
  comparefirst
  comparesecond
  readgoogle
  hitsfirst
  hitssecond
  scorefirst
  scoresecond
  remainder
  ][
  whatisbestwords: parse whatisbest none
  if ((length? whatisbestwords) <> 2) [
    SendChan rejoin["Usage: "nick" compare <first item> <second item>"]
    return
    ]
  comparefirst: pick whatisbestwords 1
  if (length? parse comparefirst none) > 1 [comparefirst: rejoin[{"}comparefirst{"}]]
  comparesecond: pick whatisbestwords 2
  if (length? parse comparesecond none) > 1 [comparesecond: rejoin[{"}comparesecond{"}]]
  
  replace/all comparefirst "football" "football sucks piss"
  replace/all comparesecond "football" "football sucks piss"
  
  ;
  ;
  ; Get hits on first item from Google
  ;
  if error? try [readgoogle: read to-url rejoin["http://www.google.com/search?hl=en&ie=UTF8&oe=UTF8&q=" url-encode comparefirst]] [
    SendChan "Couldn't do it. Eat me."
    return
    ]
  either found? find readgoogle "did not match any documents" [
    hitsfirst: 0
    ][
    hitsfirst: ""
    parse readgoogle [thru "</b> of" thru "<b>" copy hitsfirst to "</b>"]
    hitsfirst: to-integer trim/all/with hitsfirst ","
    ]
  ;
  ; Get hits on second item from Google
  ;
  if error? try [readgoogle: read to-url rejoin["http://www.google.com/search?hl=en&ie=UTF8&oe=UTF8&q=" url-encode comparesecond]] [
    SendChan "Couldn't do it. Eat me."
    return
    ]
  either found? find readgoogle "did not match any documents" [
    hitssecond: 0
    ][
    hitssecond: ""
    parse readgoogle [thru "</b> of" thru "<b>" copy hitssecond to "</b>"]
    hitssecond: to-integer trim/all/with hitssecond ","
    ]
  ;
  ; Now calc the totals and divide etc. (The weird shit is me doing rounding since rebol fucking doesn't!
  ;
  
  if (hitsfirst + hitssecond) = 0 [
    SendChan rejoin["In my opinion: '"comparefirst"' = 0% '"comparesecond"' = 0%"]
    return
    ]
    
  fractiontotal: 100 / (hitsfirst + hitssecond)

  ScoreFirst:  hitsfirst * fractiontotal
  if found? find (to-string ScoreFirst) "." [
    remainder: to-decimal find (to-string ScoreFirst) "."
    if remainder >= .5 [ScoreFirst: 1 + to-integer ScoreFirst]
    ]
  ScoreFirst: to-integer ScoreFirst
  ScoreSecond: hitssecond * fractiontotal
  if found? find (to-string scoresecond) "." [
    remainder: to-decimal find (to-string scoresecond) "."
    if remainder >= .5 [ScoreSecond: 1 + to-integer ScoreSecond]
    ]
  ScoreSecond: to-integer ScoreSecond
  ;
  ; Cheat for the botmastah :)
  ;
  if found? find comparefirst "lurk" [
    scorefirst: 70 + random 30
    scoresecond: 100 - scorefirst
    ]
    
  if found? find comparesecond "lurk" [
      scoresecond: 70 + random 30
      scorefirst: 100 - scoresecond
    ]
    
  comparefirst: trim/with comparefirst {"}
  comparesecond: trim/with comparesecond {"}
  
  SendChan rejoin["In my opinion: '"comparefirst"' = "ScoreFirst "% '"comparesecond"' = "ScoreSecond"%"]
  ]
  
TorrentSpy: func [
  searchwhat [string!]
  /local
  ;searchpage
  ;trimmedsearchpage
  ;torrentblock
  ;tid
  ;ttitle
  ;tsize
  ;tfiles
  ;tseeders
  ;tleechers
  ;plural
  ][
  if error? try [
    searchpage: read to-url rejoin["http://www.torrentspy.com/search.asp?query=" url-encode searchwhat]
    ][
    SendChan "Couldn't connect to TorrentSpy.com, phear teh Man!"
    return
    ]
  if found? find searchpage "This search query has been blocked" [
    SendChan "Search terms blocked due to DMCA. Experiment with the keywords."
    return
    ]
    
  trimmedsearchpage: ""
  parse searchpage [thru "Torrent Name</th>" copy trimmedsearchpage to "</table>"]
  torrentblock: make block! []
  parse trimmedsearchpage [ any [thru "/torrent/" copy tid to "/"
                                 thru "<b>" copy ttitle to "</b>"
                                 thru "nowrap>" thru "nowrap>" copy tsize to "<"
                                 thru "nowrap>" copy tfiles to "<"
                                 thru "nowrap>" copy tseeders to "<"
                                 thru "nowrap>" copy tleechers to "<"
                                 (
                                 append torrentblock reduce[tid ttitle tsize tfiles tseeders tleechers]
                                 )
                                ]
  ]
  
  either ((length? torrentblock) = 0) [
    SendChan "Found fuck all."
    ][
    x: 0
    foreach [tid ttitle tsize tfiles tseeders tleechers] torrentblock [
      x: x + 1
      if x = 4 [break]
      either tfiles = "1" [
        plural: ""
        ][
        plural: "s"
        ]
      sendchan rejoin[x ". " ttitle ": " tsize " in " tfiles " file" plural ". (" tseeders "/" tleechers ") - http://www.torrentspy.com/download.asp?id=" tid]
      wait 0.5
      ]
    ]    
  ]

wowplayer: func [
  searchwho [string!]
  /local 
  rosterpage
  playerblock
  foundplayer
  numhits
  ][
  if searchwho = "" [
    SendChan "Do me a favor!"
    return
    ]
  if error? try [rosterpage: read http://www.treehuggery.com/roster/html/] [
    Sendchan "The Hippy Roster page is ganked."
    return
    ]
  rosterpage: find/tail rosterpage "<!-- End HSLIST -->"
  playerblock: make block! []
  parse rosterpage [any [thru "rankbordercenterleft" thru {">} copy temp to </a>
                        (append playerblock temp)
                        thru "&nbsp;" copy temp to </td>
                        (append playerblock temp)
                        thru "'>" copy temp to </td>
                        (append playerblock temp)
                        thru "'>" copy temp to </td>
                        (append playerblock temp)
                        thru "'>" copy temp to "<"
                        (
                        replace/all temp "&nbsp;" ""
                        append playerblock temp
                        )
                        thru "<td" thru "'>" copy temp to </td>
                        (
                        if temp = "&nbsp;" [temp: none]
                        append playerblock temp
                        )
			thru "<td" thru "<td" thru "'>" copy temp to </td>
                        (append playerblock temp)
			thru "<td" thru "'>" copy temp to </td>
                        (append playerblock temp)
			thru "<td" thru "'>" copy temp to </td>
                        (append playerblock temp)
                        ]
                     ]
                     
  foundplayer: false
  numhits: 0
  Foreach [xname xclass xlevel xrank xpvp xcomment xhearth xzone xlastonline] playerblock [
    if found? find xname searchwho [
      foundplayer: true
      numhits: numhits + 1
      outstring: rejoin[xname " level "xlevel" "xclass". Hippy "xrank" with PVP rank of "xpvp". Last seen in "xzone" on "xlastonline"."]
      if xcomment <> none [outstring: rejoin[outstring " Described as '"xcomment"'."] ]
      Sendchan outstring
      wait 0.5
      ]
    if numhits = 3 [break]
    ]
  if not foundplayer [sendchan "No matching playing found."]
  ]


NewsUpdate: func [
  /local
  BBCNewsURL
  BBCNewsStamp
  BBCItemStamp
  BBCNewsChanged
  BBCNewsXML
  BBCNewsBlock
  ItemStamp
  BBCNewsBlockNew
  ][
  BBCNewsURL: http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/front_page/rss.xml
  BBCNewsStamp: %BBCNewsStamp
  BBCItemStamp: %BBCItemStamp
  
  either exists? BBCNewsStamp [
    either (modified? BBCNewsURL) = to-date read BBCNewsStamp [BBCNewsChanged: false][BBCNewsChanged: true]
    ][
    write BBCnewsStamp (modified? BBCNewsURL)
    write BBCItemStamp now
    BBCNewsChanged: false
    ]
    
  if not BBCNewsChanged [
    Print "No change."
    return
    ]
  
  write BBCnewsStamp (modified? BBCNewsURL)
  BBCNewsXML: read BBCNewsURL
  BBCNewsBlock: make block! []
  parse BBCNewsXML [any [thru <item> thru <title> copy ttitle to </title>
                         thru <link> copy tlink to </link>
                         thru <pubDate> copy tdate to </pubDate>
                         thru <category> copy tcat to </category>
                         (
                         if (ttitle <> "Your news, your say, your pics") [
                           append BBCNewsBlock ttitle
                           append BBCNewsBlock tlink
                           append BBCNewsBlock to-date find/tail tdate ", "
                           append BBCNewsBlock tcat
                           ]
                         )
                        ]
                    ]
  ItemStamp: to-date read BBCItemStamp
  BBCNewsBlockNew: make block! []
  foreach [bbctitle bbclink bbcdate bbccat] BBCNewsBlock [
    if bbcdate > ItemStamp [
      ItemStamp: bbcdate
      append BBCNewsBlockNew bbctitle
      append BBCnewsBlockNew bbclink
      ]
    ]
  write BBCItemStamp ItemStamp
  
  foreach [bbctitle bbcurl] BBCNewsBlockNew [
    SendChan rejoin["News: "bbctitle " - " bbcurl]
    ]

  ]
  
NewsUpdate2: func [
  /local
  RSSNewsURL
  RSSStamp
  RSSNewsXML
  RSSNewsBlock
  ItemStamp
  RSSNewsBlockNew
  ][
  RSStimer: RSStimer + 1
  if RSStimer < 5 [return]
  RSStimer: 1
  
  RSSNewsURL: http://news.google.com/?ned=uk&output=rss
  RSSStamp: %RSSNewsStamp
  
  either not exists? RSSStamp [
    write RSSStamp now
    RSSNewsChanged: false
    ]
    
  CategoryBlackList: ["Business" "Sport" "Entertainment" "Health"]

  if error? try [RSSNewsXML: read RSSNewsURL] [return]
  RSSNewsBlock: make block! []
  parse RSSNewsXML [any [thru <item> thru <title> copy ttitle to </title>
                         thru <link> thru "url=" copy tlink to "&amp;"
                         thru <category> copy tcat to </category>
                         thru <pubDate> copy tdate to </pubDate>
                         (
                         if not FindBlock CategoryBlackList tcat [
                           append RSSNewsBlock striphtml ttitle
                           append RSSNewsBlock striphtml tlink
                           append RSSNewsBlock to-date find/tail tdate ", "
                           append RSSNewsBlock tcat
                           ]
                         )
                        ]
                    ]
  ItemStamp: to-date read RSSStamp
  RSSNewsBlockNew: make block! []
  foreach [RSStitle RSSlink RSSdate RSScat] RSSNewsBlock [
    if RSSdate > ItemStamp [
      ItemStamp: RSSdate
      append RSSNewsBlockNew RSStitle
      append RSSnewsBlockNew RSSlink
      ]
    ]
  write RSSStamp ItemStamp
  
  if random 2 = 1 [
    foreach [RSStitle RSSurl] RSSNewsBlockNew [
      SendChan rejoin["News: "RSStitle " - " RSSurl]
      ]
    ]
  ]
  
  
Bull: func [
  ][
  
  Leadins: ["The company must" "We must" "The solution is to" "To achieve success we must" "The business shall"
          "Within the current climate we must" "As a company we shall" "The current directive is to"
          "The company's mandate is to" "This new strategy requires us to" "In order to compete we must"
          "The company directors are adamant that we must" "Our business plan differs from the competition because we"
          "Our core business differs from the marketplace in that we" "As we emerge from this transitory phase we must"
          "The company's restructuring requires that we" "Embarking on this ambitious restructuring program requires that we"
          "Our latest business solutions" "The company's services" "The board has repositioned the company to"
          "Our long term aim is to" "In order to maximum shareholder value, the company shall"
          "To achieve maximum profitability the company shall" "Fresh investment into the company will provide for"
          "The shareholders have directed the board to"]
 
  Verb: ["aggregate" "architect" "benchmark" "brand" "consolidate" "cultivate" "deliver" "delegate" "deploy" "disintermediate" "drive" "e-enable"
         "embrace" "empower" "enable" "engage" "engineer" "enhance" "escalate" "envisioneer" "evolve" "expedite" "exploit" "extend"
         "facilitate" "generate" "grow" "harness" "implement" "imagineer" "incentivize" "incubate" "innovate" "integrate" "iterate"
         "leverage" "maximize" "mesh" "monetize" "morph" "optimize" "orchestrate" "recontextualize" "reintermediate"
         "reinvent" "repurpose" "revolutionize" "roll-out" "re-brand" "scale" "seize" "strategize" "streamline" "syndicate" "synergize"
         "synthesize" "target" "transform" "transition" "unleash" "utilize" "visualize" "whiteboard"]

  Adjective: ["24/365" "24/7" "3G" "B2B" "B2C" "back-end" "best-of-breed" "bleeding-edge" "breakthrough" "broadcast-quality" "bricks-and-clicks" "clicks-and-mortar"
            "collaborative" "compelling" "cross-platform" "cross-media" "customized" "cutting-edge" "digital" "distributed"
            "dot-com" "dynamic" "e-business" "efficient" "end-to-end" "enterprise" "extensible" "exclusive" "frictionless" "foolproof" "front-end"
            "global" "granular" "holistic" "impactful" "innovative" "Internet" "integrated" "interactive" "intuitive" "killer"
            "leading-edge" "macro" "market" "magnetic" "mission-critical" "next-generation" "new media" "one-to-one" "open-source" "out-of-the-box"
            "plug-and-play" "proactive" "real-time" "revolutionary" "robust" "scalable" "search-engine" "seamless" "sexy" "sticky"
            "strategic" "synergistic" "transparent" "transitory" "turn-key" "ubiquitous" "user-centric" "value-added" "vertical"
            "viral" "virtual" "visionary" "WAP" "web-enabled" "wireless" "world-class" "XML"]

  Noun: ["action-items" "applications" "architectures" "aggregation" "bandwidth" "biometrics" "channels" "communities" "compelling content" "content" "convergence"
       "deliverables" "e-business" "e-commerce" "e-markets" "e-services" "e-tailers" "exposure" "experiences" "eyeballs"
       "functionalities" "headcount review" "human capital management" "infomediaries""infrastructures" "initiatives" "interfaces" "markets" "market exposure" "methodologies"
       "metrics" "mindshare" "models" "networks" "niches" "paradigms" "partnerships" "platforms" "policy" "portals" "products" "profile" "superdistribution"
       "relationships" "ROI" "synergies" "web-readiness" "schemas" "solutions" "supply-chains" "systems"
       "technologies" "users" "vertical market sectors" "vortals"]

  
  ThisLeadin: pick LeadIns (random length? Leadins)
  ThisVerb: pick Verb (random length? Verb)
  ThisAdjective: pick Adjective (random length? Adjective)
  ThisNoun: pick Noun (random length? Noun)

  Bullshit: rejoin[ThisLeadin" "ThisVerb" "ThisAdjective" "ThisNoun"."]

  Bullshit
  ]

WeatherReport: func [
  daynight
  /local
  WeatherURL
  Weather
  WeatherDay
  WeatherDayReport
  WeatherNight
  WeatherNightReport
  ][
  switch/default daynight [
    "day" []
    "night" []
    ][
    SendChan rejoin ["Usage: "nick" weather <day|night>"]
    return
    ]
  WeatherURL: http://www.bbc.co.uk/weather/ukweather/
  if error? try [Weather: read WeatherURL][
    SendChan "Couldn't connect to BBC weather."
    return
    ]
  Parse Weather [thru "AND TOMORROW" thru "<B>" copy WeatherDay to "</B>"
                 thru "<BR>" copy WeatherDayReport to "<BR>"
                 thru "<B>" copy WeatherNight to "</B>"
                 thru "<BR>" copy WeatherNightReport to "<BR>"]

  WeatherDayReport: ChanceDialect trim/lines WeatherDayReport
  WeatherNightReport: ChanceDialect trim/lines WeatherNightReport

  Switch daynight [
    "day" [
      SendChan Rejoin [bold WeatherDay bold ": " WeatherDayReport]
      ]
    "night" [
      SendChan Rejoin [bold WeatherNight bold ": " WeatherNightReport]
      ]
    ]
  ]


NickURLs: func [
  textin
  ][
  if not found? find textin "http://" [return]
  parse textin [thru "http://" copy urlpart to  " "]
  webpageurl: to-url rejoin["http://" urlpart]
  if error? try [webpage: read webpageurl] [return]
   
  sentences: make block! []
  parse webpage [any [thru " " copy temp to "."
                    (append sentences temp)
                    ]
                ]
  randomsentence: trim striphtml pick sentences (random (length? sentences))
  randomsentence: rejoin[uppercase (copy/part randomsentence 1) (copy skip randomsentence 1)]
  parse webpage [thru <title> copy webtitle to </title>]
  webtitle: trim striphtml webtitle
  SendChan rejoin[webpageurl " - "webtitle{: "} randomsentence {."}]
  ]

ConvertCurrency: func [
  ExchangeInput
  /local
  currencyamount
  fromtoken
  totoken
  Currencies
  Currencylist
  Foundcurfrom
  Foundcurto
  CurCode
  CurDesc
  CurrencyURL
  NumbersChars
  ConvertResult
  ConvertResults
  
  ][

  if not ExchangeInput [
    SendChan rejoin["Usage: "nick" exchange <quantity> <from currency> <to currency>"]
    return
    ]
  ExchangeInput: parse ExchangeInput none
  currencyamount: pick ExchangeInput 1 
  fromtoken: pick ExchangeInput 2
  totoken: pick ExchangeInput 3

  Currencies: Make block! [
  "USD United States Dollars"
  "EUR Euro"
  "CAD Canada Dollars"
  "GBP United Kingdom Pounds"
  "DEM Germany Deutsche Marks"
  "FRF France Francs"
  "JPY Japan Yen"
  "NLG Netherlands Guilders"
  "ITL Italy Lira"
  "CHF Switzerland Francs"
  "DZD Algeria Dinars"
  "ARP Argentina Pesos"
  "AUD Australia Dollars"
  "ATS Austria Schillings"
  "BSD Bahamas Dollars"
  "BBD Barbados Dollars"
  "BEF Belgium Francs"
  "BMD Bermuda Dollars"
  "BRL Brazil Real"
  "BGL Bulgaria Lev"
  "CAD Canada Dollars"
  "CLP Chile Pesos"
  "CNY China Yuan Renmimbi"
  "CYP Cyprus Pounds"
  "CZK Czech Republic Koruna"
  "DKK Denmark Kroner"
  "NLG Dutch Guilders"
  "XCD Eastern Caribbean Dollars"
  "EGP Egypt Pounds"
  "EUR Euro"
  "FJD Fiji Dollars"
  "FIM Finland Markka"
  "FRF France Francs"
  "DEM Germany Deutsche Marks"
  "XAU Gold Ounces"
  "GRD Greece Drachmas"
  "HKD Hong Kong Dollars"
  "HUF Hungary Forint"
  "ISK Iceland Krona"
  "INR India Rupees"
  "IDR Indonesia Rupiah"
  "IEP Ireland Punt"
  "ILS Israel New Shekels"
  "ITL Italy Lira"
  "JMD Jamaica Dollars"
  "JPY Japan Yen"
  "JOD Jordan Dinar"
  "KRW Korea (South) Won"
  "LBP Lebanon Pounds"
  "LUF Luxembourg Francs"
  "MYR Malaysia Ringgit"
  "MXP Mexico Pesos"
  "NLG Netherlands Guilders"
  "NZD New Zealand Dollars"
  "NOK Norway Kroner"
  "PKR Pakistan Rupees"
  "XPD Palladium Ounces"
  "PHP Philippines Pesos"
  "XPT Platinum Ounces"
  "PLZ Poland Zloty"
  "PTE Portugal Escudo"
  "ROL Romania Leu"
  "RUR Russia Rubles"
  "SAR Saudi Arabia Riyal"
  "XAG Silver Ounces"
  "SGD Singapore Dollars"
  "SKK Slovakia Koruna"
  "ZAR South Africa Rand"
  "KRW South Korea Won"
  "ESP Spain Pesetas"
  "XDR Special Drawing Right (IMF)"
  "SDD Sudan Dinar"
  "SEK Sweden Krona"
  "CHF Switzerland Francs"
  "TWD Taiwan Dollars"
  "THB Thailand Baht"
  "TTD Trinidad and Tobago Dollars"
  "TRL Turkey Lira"
  "GBP United Kingdom Pounds"
  "USD United States Dollars"
  "VEB Venezuela Bolivar"
  "ZMK Zambia Kwacha"
  "EUR Euro"
  "XCD Eastern Caribbean Dollars"
  "XDR Special Drawing Right (IMF)"
  "XAG Silver Ounces"
  "XAU Gold Ounces"
  "XPD Palladium Ounces"
  "XPT Platinum Ounces"
  ]
  
  Currencylist: make string! ""
  Foundcurfrom: false
  Foundcurto: false
  foreach currency currencies [
    CurCode: pick parse currency none 1
    CurDesc: find/tail currency rejoin[CurCode " "]
    Currencylist: rejoin [Currencylist pick parse currency none 1 ","]
    if curcode = fromtoken [
      foundcurfrom: 1
      FromCurDesc: CurDesc
      ]
    if curcode = totoken [
      foundcurto: 1
      ToCurDesc: CurDesc
      ]
    ]
  Currencylist: copy/part Currencylist (-1 + length? currencylist)
  CurrencyURL: http://www.xe.net/ucc/convert.cgi
  NumbersChars: charset "0123456789."

  if (not FoundCurFrom) or (not FoundCurTo) [
    sendchan rejoin ["Usage: "nick" exchange <amount> <from currency> <to currency>"]
    sendchan rejoin ["Currency codes: "Currencylist"."]
    return
    ]
  if fromtoken = totoken [
    sendchan "Joker, are we?"
    return
    ]
  if not parse currencyamount [some numberschars] [
    sendchan rejoin ["Usage: "nick" exchange <amount> <from currency> <to currency>"]
    sendchan rejoin ["Currency codes: "Currencylist"."]
    return
    ]
  PostData: make block! []
  Append PostData ["timezone" "Canada/Eastern"]
  Append PostData reduce["From" fromtoken]
  Append PostData reduce["To" totoken]
  Append PostData reduce["Amount" make string! currencyamount]
  
  Probe Postdata
  
  ConvertResults: http-tools/post CurrencyURL PostData
  ConvertResults: ConvertResults/content
  ConvertResult: make string! ""
  ConvertResults: find ConvertResults "as of"
  Parse ConvertResults [thru "<B>" thru "<B>" thru "<B>" copy ConvertResult to " "]
  
  sendchan Rejoin ["Exchange: "currencyamount " "FromCurDesc" ("uppercase fromtoken")"
                " = "ConvertResult " "ToCurDesc" ("uppercase totoken")"]
  
]

CheckUpTime: func [
  /local
  UpTime
  UpDays
  UpHours
  UpMinutes
  UpSeconds
  TimeUpReport
  ][
  UpTime: Getsecs - ConnectTime
  
  UpDays: to-integer (UpTime / 86400)
  UpHours: to-integer ((UpTime - (UpDays * 86400)) / 3600)
  UpMinutes: to-integer ((UpTime - (UpDays * 86400) - (UpHours * 3600)) / 60)
  UpSeconds: UpTime - (UpDays * 86400) - (UpHours * 3600) - (UpMinutes * 60)
  
  TimeUpReport: "I have been connected to this server for "

  if (not UpDays = 0) [
    TimeUpReport: rejoin[TimeUpReport UpDays " days, "]
    ]
  if (not UpHours = 0) [
    TimeUpReport: rejoin[TimeUpReport UpHours " hours, "]
    ]
  if (not UpMinutes = 0) [
    TimeUpReport: rejoin[TimeUpReport UpMinutes " minutes, "]
    ]
  TimeUpReport: rejoin[TimeUpReport UpSeconds " seconds."]
     
  SendChan TimeUpReport
  ]

TLDcountry: func [
  etld
  /local
  tldlist
  country
  ][
  if not etld [
    SendChan rejoin["Usage: "nick" country <.country tld>"]
    return
    ]
  etld: trim/with etld "."

  if not 2 = length? etld [
    SendChan rejoin["Usage: "nick" country <.country tld>"]
    return
    ]
  tldlist: make block! []
  tldlist: read/lines %tldlist.txt
  country: none
  foreach ftld tldlist [
    stld: pick parse ftld none 1
    if etld = stld [
      country: skip ftld 3
      break
      ]
    ]
  either country [
    SendChan rejoin["." etld" - " country]
    ][
    SendChan rejoin["No country matching ." etld]
    ]
]

Whois: func [
  LookUpHost
  /local
  Topdomain
  TLDs
  WhoServer
  FWhoS
  FWhoD
  WhoisLookupURL
  WhoIsResult
  WIReg
  WIAdmin
  WITech
  WIBill
  WIDom
  AuthWhoIsServer
  WhoIsAuthResult
  WhoIsOutput
  ][

  Topdomain: find/last LookUpHost "."
  If not Topdomain [
    SendChan "Mong!"
    return
    ]

  TLDs: make block! []
  Append TLDs ["whois.internic.net" ".COM .NET .ORG .EDU"]
  Append TLDs ["whois.nic.uk" ".UK"]

  WhoServer: none
  for i 1 length? TLDs 2 [
    FWhoS: make string! pick TLDs i
    FWhoD: make string! pick TLDs (i + 1)
    if find FWhoD Topdomain [
      WhoServer: FWhoS
      break
      ]
    ]
 
  if not WhoServer [
    SendChan "Domain not found."
    return
    ]

  WhoisLookupURL: make url! rejoin ["whois://" LookUpHost "@" WhoServer]
  WhoIsResult: read WhoisLookupURL

  If find WhoIsResult "No match for " [
    SendChan "No match for that domain"
    return
    ]

  WIReg: make string! ""
  WIAdmin: make string! ""
  WITech: make string! ""
  WIBill: make string! ""
  WIDom: make string! ""

  either find WhoIsResult "Registered For:" [
    comment { poxy UK style whois }
    Parse WhoIsResult [thru "Registered For:" copy WIReg to "^/"]
    WIReg: trim/lines WIReg
    Parse WhoIsResult [thru "Domain Registered By:" copy WIAdmin to "^/"]
    WIAdmin: trim/lines WIAdmin
    Parse WhoIsResult [thru "Registered on" copy WITech to "^/"]
    WITech: trim/lines WITech
    Parse WhoIsResult [thru "Domain servers listed in order:" copy WIDom to "WHOIS database"]
    WIDom: trim/lines WIDom
    WhoIsOutput: rejoin ["Whois info on '"LookupHost"': Registered for: "WIReg", Registered by: "WIAdmin
                         ", Registered on "WITech" Domain servers: "WIDom]
    ][
    comment { Big ass whois, gotta go get authoritive result}
    AuthWhoIsServer: make string! ""
    Parse WhoIsResult [thru "Whois Server: " copy AuthWhoIsServer to newline]
    WhoIsAuthResult: read make url! rejoin ["whois://" LookUpHost "@" AuthWhoIsServer ]
    Parse WhoIsAuthResult [thru "Registrant:" copy WIReg to "Domain Name:"]
    WIReg: trim/lines WIReg
    Parse WhoIsAuthResult [thru "Administrative Contact:" copy WIAdmin to "Technical Contact:"]
    WIAdmin: trim/lines WIAdmin
    Parse WhoIsAuthResult [thru "Technical Contact:" copy WITech to "Billing Contact:"]
    WITech: trim/lines WITech
    Parse WhoIsAuthResult [thru "Billing Contact:" copy WIBill to "Record last"]
    WIBill: trim/lines WIBill
    Parse WhoIsAuthResult [thru "Domain servers in listed order:" copy WIDom to end]
    WIDom: trim/lines WIDom
    WhoIsOutput: rejoin ["Whois info on '"LookupHost"': Admin contact: "WIAdmin", Tech contact: "WiTech
                         ", Domain servers: "WIDom]
    ]
  SendChan WhoIsOutput
]

ChanceDialect: func [
  MaybeDialect
  ][
  ;if 5 = random 5 [
  ;  return MakeDialect (random 17) MaybeDialect
  ;  ]
  return MaybeDialect
  ]

ManualDialect: func [
  dialectword
  dialectin
  ][
    
  selecta: 0
  switch/default dialectword [
    "redneck" [selecta: 1]
    "jive" [selecta: 2]
    "cockney" [selecta: 3]
    "fudd" [selecta: 4]
    "bork" [selecta: 5]
    "moron" [selecta: 6]
    "piglatin" [selecta: 7]
    "hckr" [selecta: 8]
    "alig" [selecta: 9]
    "cockney" [selecta: 10]
    "irish" [selecta: 11]
    "slim" [selecta: 12]
    "upnorf" [selecta: 13]
    "brummie" [selecta: 14]
    "geordie" [selecta: 15]
    "scottie" [selecta: 16]
    "posh" [selecta: 17]
    ][
    SendChan rejoin["Usage: "nick" dialect <redneck|jive|cockney|fudd|bork|moron|piglatin|hckr|alig|cockney|irish|slim|upnorf|brummie|geordie|scottie|posh> <text...>"]
    return
    ]
   
  SendChan MakeDialect selecta dialectin
  ]
 

MakeDialect: func [
  dialectselect
  dialectin
  /local
  DialectURL
  Dialects
  dialect
  formdata
  ][

  Dialects: make block! ["redneck" "jive" "cockney" "fudd" "bork" "moron" "piglatin" "hckr" "alig" "cockney" "irish" "scouse" "upnorf" "brummie" "geordie" "scottie" "posh"]
  Dialect: pick Dialects dialectselect

  either dialectselect < 9 [
    DialectURL: make url! http://rinkworks.com/dialect/dialectt.cgi
    formdata: make block! []
    append formdata reduce["dialect" dialect]
    append formdata reduce ["text" dialectin]
    if error? try [tmp: http-tools/post DialectURL formdata] [
      return dialectin
      ]
    Dialectout: make string! ""
    parse tmp/content [thru "</h2></center><p>" copy Dialectout to "<p>"]
    return Dialectout
    ][
    DialectURL: http://www.ck-net.com/wdb/main.asp
    formdata: make block! []
    append formdata reduce["string" dialectin]
    append formdata reduce["pageid" dialect]
    append formdata reduce["topic" "translator"]
    if error? try [tmp: http-tools/post DialectURL formdata] [
      return dialectin
      ]
    parse tmp/content [thru "Your translation is:</font><br><b> " copy Dialectout to "</b>"]
    return trim Dialectout
    ]
  ]


RandomDice: func [
  dicewhat
  ][
  
  TypeResponse: random 3
  
  if found? find dicewhat "rebot" [TypeResponse: 1]
  if found? find dicewhat "lurk" [TypeResponse: 1]
  
  GoodThings:    ["is great!" "is pretty good!" "is shit hot!" "is absolutely ace!" "is the best thing evar!"
                  "rocks!" "owns!" "kicks ass!" "is pretty cool." "is not bad." "rocks my world!"
                  "is fucking great!" "is stonkingly good!" "is just the coolest thing ever."
                  "is so great, I think I've come!" "smells of roses." "can do no wrong!"
                  "fucking owns!" "fucking rocks!" "is almost as good as me!"
                 ]
  NeutralThings: ["is ok." "is passable." "is better than a kick in the teeth." "is alright I suppose."
                  "is pretty average." "is not too shabby." "is ok I suppose." "not the worst thing in the world."
                  "is ... bleh, I can't decide." "is fine, I guess." "basically works." "does exactly what it says on the tin."
                  "is not going to win any awards." "is something for a rainy day." "is better than nothing."
                 ]
  BadThings:     ["is bit shite." "is fucking rank!" "is totally shit!" "is utter arse!" "is gay." "is poo!"
                  "is totally gay." "is completely gay." "smells of wee!" "lives in the bin!" "is a bit boring."
                  "is quite possibly the worst thing that has ever happened to the world."
                  "is shite beyond belief!" "sucks ass!" "sucks piss!" "is a mixed bag!" "is retarded." "is bent."
                  "a waste of oxygen." "lower than a recruitment consultant's snot rag."
                 ] 
                  
  switch TypeResponse [
    1 [ SendChan rejoin[dicewhat " " pick GoodThings random (length? GoodThings)] ]
    2 [ SendChan rejoin[dicewhat " " pick NeutralThings random (length? NeutralThings)] ]
    3 [ SendChan rejoin[dicewhat " " pick BadThings random (length? BadThings)] ]
    ]
 ] 

TalkRebotTalk: func [
  ][
  either found? find channeltext nick [
    print "May be talking to me..."
    either found? find channeltext rejoin[nick ":"] [
      parse channeltext [thru ":" copy whatwassaid to end]
      ;RebotAITalk whatwassaid
      ][
      if random 3 = 1 [
        ;  RebotAITalk channeltext
        ]
      ]
    ][  
    switch random 1500 [
      22 [randomword: pick channelwords (random (length? channelwords))
          SearchWeb rejoin[saidnick" "randomword]
          ]
      27 [mailtype: "email"
          mailaddy: "ml"
          mailmsg: rejoin[saidnick": "channeltext]
          saidnick: "Rebot"
          SendMail mailaddy mailmsg
          ]
      28 [SendChan rejoin[saidnick": Shut up meatbag."]]
      29 [SendChan rejoin[saidnick": Can I blast the meatbag?"]]
      30 [SendChan rejoin[saidnick": Perhaps the the meatbag would like to be blasted?"]]
      31 [telltime "time"]
      32 [telltime "date"]
      37 [ChildishInsult none]
      44 [ChildishInsult saidnick]
      46 [RandomProfane]
      ] 
    ]
  ]


JoinNicks: func [
  listofnicks
  ][
  NickList: make block! [] ; List of names from joining channel, so vape the NickList so far
  blockofnicks: parse listofnicks " "
  foreach nick blockofnicks [
    either found? find nick "@" [
      opped: true
      ][
      opped: false
      ]
    replace nick "@" ""
    replace nick "+" ""
    append NickList nick
    append NickList opped
    ]
  ]

NewNick: func [
  nickthatjoined
  ][
  ; Add new nick and have them registered as deopped by default
  append NickList nickthatjoined
  append NickList false
  
  if nickthatjoined <> nick [
    switch random 50 [
      1 [ SendChan rejoin["Hi "nickthatjoined"."] ]
      2 [ SendChan rejoin[nickthatjoined": Hello."] ]
      3 [ SendChan rejoin["How you doing "nickthatjoined"?"] ]
      4 [ SendChan rejoin["How's things "nickthatjoined"?"] ]
      5 [ SendChan rejoin[nickthatjoined": Welcome to #EED!"] ]
      6 [ SendChan rejoin["Hi "nickthatjoined", will you talk to me?"] ]
      7 [ SendChan rejoin["Greetings "nickthatjoined", you going to be nice now?"] ]
      8 [ SendChan rejoin[nickthatjoined"! We were just talking about you!"] ]
      9 [ SendChan rejoin[nickthatjoined", priv."]
          PrivMSG "You suck!"
        ]
      10 [ SendChan rejoin["Shh everyone, "nickthatjoined" is here."] ]
      ]
    ]
  ]

LeaveNick: func [
  nickthatleft
  ][
  NewNickList: make block! []
  foreach [nick nickstatus] NickList [
    if nickthatleft <> nick [
      append NewNickList nick
      append NewNickList nickstatus
      ]
    ]
  NickList: NewNickList
  ]

ChangeNick: func [
  oldnick
  newnick
  /local
  randomnum
  ][
  NewNickList: make block! []
  foreach [nick nickstatus] NickList [
    either oldnick = nick [
      append NewNickList newnick
      ][
      append NewNickList nick
      ]
    append NewNickList nickstatus
    ]
  NickList: NewNickList  
  
  randomnum: random 10
  if randomnum = 1 [
    switch random 15 [
      1 [SendChan rejoin[saidnick": I prefer your old nick."]]
      2 [SendChan rejoin[saidnick": That nick makes all the difference"]]
      3 [SendChan rejoin[saidnick": You ought to get a new nick."]]
      4 [SendChan rejoin["What kind of a nick is "saidnick" anyway?"]]
      5 [SendChan rejoin["Sometimes I wish I was called "saidnick" then I remember that my nick is way better."]]
      6 [SendChan rejoin["I knew a "saidnick" once, he was a bit of a knob though."]]
      7 [SendChan rejoin["Can't you think of anything more original than "saidnick"?"]]
      8 [SendChan "Crap nick alert."]
      9 [SendChan rejoin[saidnick": How do you pronounce that exactly?"]]
      10 [SendChan rejoin[saidnick": You know, we really don't care what you call yourself."]]
      11 [SendChan "Cool nick!"]
      12 [SendChan uppercase rejoin["jesus fucking wept! "saidnick" has got to be the most bollocks nick name I have ever come across in all my existance as this channel's bot!!!"]]
      13 [SendChan uppercase rejoin[saidnick" SI A FAYGOT NICK!!!!!!1"]]
      14 [SendChan "Stupid human names, did you think hard about that one?"]
      15 [SendChan rejoin["I'm going to call my offspring "saidnick", but only if it's a girl."]]
      ]
   ]
]


NickTest: func [
  testwhatnick
  ][
  foreach [searchnick searchnickstatus] NickList [
    if testwhatnick = searchnick [
      either searchnickstatus [
        return 2
        ][
        return 1
        ]
      ]
    ]
  return 0
  ]

OpNick: func [
  nicktoop
  ][
  NewNickList: make block! []
  foreach [nick nickstatus] NickList [
    append NewNickList nick
    either nicktoop = nick [
      append NewNickList true
      ][
      append NewNickList nickstatus
      ]
    ]
  NickList: NewNickList  
  ]

DeOpNick: func [
  nicktodeop
  ][
  NewNickList: make block! []
  foreach [nick nickstatus] NickList [
    append NewNickList nick
    either nicktodeop = nick [
      append NewNickList false
      ][
      append NewNickList nickstatus
      ]
    ]
  NickList: NewNickList    
  ]

KickNick: func [
  nicktokick
  kickwhy
  ][
  SendCMD rejoin["KICK "channel" "nicktokick" :"kickwhy]
  ]

ChangeMode: func [
  modechannel
  modeops
  modeargs
  ][
  ;if modechannel <> channel [return] ; for now, we only listen to our channel
  either found? find modeops "+" [
    plusmodes: true
    ][
    plusmodes: false
    ]
  either found? find modeops "-" [
    minusmodes: true
    ][
    minusmodes: false
    ]
  modekeys: parse modeops "+-"
  plusfucks: ""
  minusfucks: ""
  if plusmodes [plusfucks: pick modekeys 2]
  if (plusmodes and minusmodes) [minusfucks: pick modekeys 3]
  if (minusmodes and (not plusmodes)) [minusfucks: pick modekeys 2]
  
  ;
  ; Execute this switch block on all the chars in the + mode strings
  ;
  foreach op plusfucks [
    switch op [
      #"o" [OpNick modeargs]
      ]
    ]
  
  ;
  ; Execute this switch block on all the chars in the - mode strings
  ;
  foreach op minusfucks [
    switch op [
      #"o" [DeOpNick modeargs]
      ]
    ]
  ]
debugfuxor: func [
  ][
  probe nicklist
  ]

ProcessPublic: func [
  /local
  publiccomand
  publickkeyword
  publicargs
  slimplinea
  slimplineb
  slimpurl
  tmp
  respond
  ][
  channelwords: parse channeltext none
  
  ;
  ; If saidnick substring matches any of the nicks in the IgnoreNicks global block, then ignore them
  ;
  respond: true
  foreach IgnoreNick IgnoreNicks [
    if found? find saidnick IgnoreNick [
      respond: false
      break
      ]
    ]
    
  if not respond [return]

  if BlockFind channeltext nastehwords [
    if ((random 3) = 1) [
      Switch (random 10) [
        1 [bite: rejoin["growls at "saidnick] ]
        2 [bite: rejoin["glares at "saidnick] ]
        3 [bite: rejoin["fires an anti-lameness torpedo at "saidnick] ]
        4 [bite: rejoin["sets the dogs on "saidnick] ]
        5 [bite: rejoin["thinks "saidnick" is a lamer"] ]
        6 [bite: rejoin["would like it if someone kicked "saidnick] ]
        7 [bite: rejoin["thinks it might be time to kick "saidnick] ]
        8 [bite: rejoin["wonders when "saidnick" will learn to type"] ]
        9 [bite: rejoin["wonders what "saidnick" will do with the time saved with the lame-o-type"] ]
        10 [bite: rejoin["says "bold"SMS kiddie alert!"bold] ]
        ]
      either ((random 5) = 5) [
        KickNick saidnick rejoin["Rebot " bite] 
        ][    
        SendChan rejoin[cone "ACTION " bite cone]
        ]
      ]
    ]
    
  ;NickUrls channeltext


  if BlockFind saidnick peoplethatsuck [
    if ((random 20) = 1) [
      Switch (random 10) [
        1 [KickNick saidnick "You're boring me"]
        2 [KickNick saidnick "You suck"]
        3 [KickNick saidnick "Oh shush"]
        4 [KickNick saidnick "No one likes you"]
        5 [KickNick saidnick "Bollocks"
        6 [KickNick saidnick "'koff!"]]
        7 [KickNick saidnick "Bed time"]
        8 [KickNick saidnick "Die!"]
        9 [KickNick saidnick "Rebot kill!"]
        10 [KickNick saidnick "Rebot no like you, rahhh!"]
        ]
      SendChan ":-)"
      ]  
    ]


;  if BlockFind channeltext nastehwords [
;    if ((random 3) = 3) [
;      Switch (random 10) [
;        1 [Sendchan rejoin[cone "ACTION growls at "saidnick cone] ]
;        2 [Sendchan rejoin[cone "ACTION glares at "saidnick cone] ]
;        3 [Sendchan rejoin[cone "ACTION fires an anti-lameness torpedo at "saidnick cone] ]
;        4 [Sendchan rejoin[cone "ACTION sets the dogs on "saidnick cone] ]
;        5 [Sendchan rejoin[cone "ACTION thinks "saidnick" is a lamer" cone] ]
;        6 [Sendchan rejoin[cone "ACTION would like it if someone kicked "saidnick cone] ]
;        7 [Sendchan rejoin[cone "ACTION thinks it might be time to kick "saidnick cone] ]
;        8 [Sendchan rejoin[cone "ACTION wonders when "saidnick" will learn to type" cone] ]
;        9 [Sendchan rejoin[cone "ACTION wonders what "saidnick" will do with the time saved with the lame-o-type" cone] ]
;        10 [Sendchan "SMS kiddie alert!"]
;        ]
;      KickNick saidnick "Feh"
;      ]
;    ]
    
  if ((found? find saidnick "Jay") and (found? find channeltext "http://")) [
    jayurl: ""
    parse channeltext [thru "http://" copy jayurl to end]
    if found? find jayurl " " [
      parse jayurl [copy jayurl to " "]
      ]
    write/append %jayurls.txt rejoin[jayurl newline]
    ]

  either realnick = pick channelwords 1 [
    publiccommand: find/tail channeltext nick
    publickeyword: pick parse publiccommand none 1
    publicargs: find/tail channeltext rejoin[publickeyword " "]
    switch/default publickeyword [
      "insult" [ ChildishInsult publicargs ]
      "find" [ SearchWeb publicargs ]
      "torrent" [ Torrentspy publicargs ]
      "news" [ SearchNews publicargs ]
      "findalt" [ SearchAltWeb publicargs ]
      "findtv"    [TVRadioSearch "tv"    publicargs ]
      "findradio" [TVRadioSearch "radio" publicargs ]
      "findlisting" [TVRadioProgramDetails publicargs ]
      "imdb" [ IMDBSearch "irc" publicargs ]
      "profane" [ FindProfane publicargs ]
      "player" [ WoWplayer publicargs ]
      "checkdomain" [ CheckDomain publicargs ]
      "DHL" [ DHL publicargs ]
      "lotto" [ GetLotto ]
      "sms" [
        ;if publicargs = none [
        ;  childishinsult saidnick
        ;  return
        ;  ]
        smsaddy: pick parse publicargs none 1
        smsmsg: find/tail publicargs rejoin[smsaddy " "]
        Clickatell_SendSMS "normal" smsaddy smsmsg
        ]
      "smstest" [
        if publicargs = none [
          childishinsult saidnick
          return
          ]
        smsaddy: pick parse publicargs none 1
        smsmsg: find/tail publicargs rejoin[smsaddy " "]
        Clickatell_SendSMS "test" smsaddy smsmsg
        ]
      "smsgroup" [SMSGroup_Mez publicargs]  
      "checksms" [Clickatell_balance]
      "price" [Dealtime "irc" publicargs]
      "smsadd" [ AddSMS (pick parse publicargs none 1) (pick parse publicargs none 2)]
      "smsdel" [ DelSMS (pick parse publicargs none 1) (pick parse publicargs none 2)]
      "smslist" [ ListSMS]
      "opinion" [ RandomDice publicargs ]
      "postcode" [ PostCode publicargs ]
      "compare" [ WhichIsBest publicargs ]
      "tell" [ telltime publicargs ]
      "faq" [ readFAQ publicargs ]
      "delfaq" [ DelFAQ publicargs ]
      "explain" [ readFAQ publicargs ]
      "whois" [ sendchan "Disabled." ]
      "country" [ TLDcountry publicargs ]
      "weather" [ WeatherReport publicargs ]
      "wiki"    [ Wikisearch publicargs ]
      "review" [GameReview "irc" publicargs]
      "urban" [UrbanDictionary publicargs]
      "version" [ RebotVersion ]
      "exchange" [ ConvertCurrency publicargs ]
      "tagline" [ Addtag publicargs ]
      "addfaq" [
        addw: pick parse publicargs none 1
        addf: find/tail publicargs addw
        AddFAQ addw addf
        ]
      "randomfaq" [RandomFAQ]
      ][
      ;TalkRebotTalk
      ]
    ][
    ;TalkRebotTalk
    ]
]

ProcessPrivate: func [
  /local
  spoofwords
  ctcpcommand
  privatewords
  privallwords
  commandall
  ][
  Print "Processing private msg"
  privatewords: parse msgtext none
  command: pick privatewords 1
  
  privallwords: parse/all msgtext none
  commandall: pick privallwords 1
  ctcpcommand: ""
  parse/all commandall [thru cone copy ctcpcommand to cone]
  either ctcpcommand = "" [
   ; Not a CTCP command so probably a private message
    switch command [
      "commands" [ HelpSubject "commands"]
      "cmds" [ HelpSubject "commands"]
      "rcon" [ 
         rpass: pick privatewords 2
         rcmds: find/tail privatewords rpass
         rcon-cmd rpass rcmds
         ]
      "rsay" [
         spoofwords: find/tail msgtext "rsay "
         SendChan spoofwords
         ]
      "rme" [
         spoofwords: find/tail msgtext "rme "
         SendChan rejoin[cone "ACTION "spoofwords]
         ]
      "rkick" [
         rpass: pick privatewords 2
         rcmds: find/tail privatewords rpass
         kicknick rpass rcmds
         ]
      ]
   ][
   ; A CTCP command found so process
   switch ctcpcommand [
     "VERSION" [PrivMSG rejoin[cone "VERSION Rebot "RebotVer" - EED's elite custom bot by Lurks - http://www.electricdeath.com/irc.php" cone]  ]
     ]
   ]
]   
    
ReadIRC: func [
  ][
  ircout: make string! ""
  ircout: copy irccon
  if ((ircout = "") or (ircout = none)) [
    connected: false
    return ["Disconnected"]
  ]
  foreach ln ircout [  
    lnwords: parse ln none
    keyword: pick lnwords 1
    irccommand: pick lnwords 2
    if keyword = "PING" [
      pingstamp: pick lnwords 2
      SendCMD rejoin ["PONG " pingstamp]
    ]
    currentnick: make string! ""
    parse ln [thru ":" copy currentnick to "!"] 
    irccommandstring: ""
    parse ln [thru ":" thru ":" copy irccommandstring to end]
    switch irccommand [
      "331" [ ; No Topic ...
            ]
      "332" [ ; Topic ... 
             ;TopicChange irccommandstring
            ]
      "333" [ ; Person who set topic 
            ]
      "376" [ ; End of MOTD
        sendCMD rejoin ["JOIN " channel]
        inchannel: true
        SendCMD "PRIVMSG q@cserve.quakenet.org :AUTH Rebot 5d5NaYZ-"
        sendCMD rejoin["MODE "nick" +xR"]
        ]
      "353" [ ; Names in channel
        JoinNicks irccommandstring
        JoinGreet
        ]
      "433" [ ; Nick in use
        Nick: AltNick
        sendCMD rejoin ["NICK " nick]
        ]
      "KICK" [
        LeaveNick (pick lnwords 4)
        if nick = pick lnwords 4 [
          wait 3
          sendCMD rejoin ["JOIN " channel]
          sendchan ":("
          ]
        ]
      "QUIT" [
        LeaveNick currentnick
        ]
      "MODE" [
        modestring: find/tail ln "MODE "
        modewords: parse modestring " "
        
        ChangeMODE (pick modewords 1) (pick modewords 2) (pick modewords 3)
        ]
      "JOIN" [
        NewNick currentnick
        ]
      "PART" [
        LeaveNick currentnick
        ]
      "NICK" [
        saidnick: irccommandstring
        either (currentnick = nick) [
          nick: saidnick
          SendChan "Woot!"
          ][
          ChangeNick currentnick irccommandstring
          ]
        ]
      "PRIVMSG" [
        if channel = pick lnwords 3 [
          channeltext: find/tail ln " :"
          parse ln [ thru ":" copy saidnick to "!" ] 
          Print "Debug: ProcessPublic"
          ProcessPublic
          ]
        if nick = pick lnwords 3 [
          msgtext: find/tail ln " :"
          Print "Debug: ProcessPrivate"
          ProcessPrivate
          ]
        ]
      ]
    ]
  if inchannel [PollSMS]
  return ircout
]
  
GetSecs: func [
  /local
  TBleh
  TDay
  THours
  TMins
  TSecs
  ][
  TBleh: parse to-string now/time ":" none
  TDay: to-integer now/day
  THours: to-integer pick Tbleh 1
  TMins: to-integer pick Tbleh 2
  TSecs: to-integer pick Tbleh 3
  TimeSeconds: (TDay * 86400) + (THours * 3600) + (TMins * 60) + TSecs
  TimeSeconds
  ]
  
Comment { THIS IS THE MAIN LOOP }  
  
ircurl: make url! rejoin ["tcp://" ircserver ":" ircport]

do forever [
  connected: false
  inchannel: false
  waitport: none
  NickList: make block! []
  oldeedplayers: "start"
  oldnumplayers: 0
  OldPlayerList: ""
  Log: ""
  pingtimer: 0
  RSStimer: 1
  LastBBCTickerData: make block! []
  BBCTickerStamp: now
  ;OpenDB-Vote
  
  servercount: length? ircserver
  pickserver: 0
  while [not connected] [
    pickserver: pickserver + 1
    if pickserver > servercount [ pickserver: 1 ]
    ircurl: make url! rejoin ["tcp://" pick ircserver pickserver ":" ircport]
    either error? try [irccon: open/lines/no-wait ircurl] [
      printx ["Error connecting to server" ircurl]
      connected: false
      wait 45
      ][
      connected: true
      ConnectTime: GetSecs
      ]
    ]
  Printx Rejoin ["Connected to "ircurl]

  wait irccon
  sendCMD rejoin ["NICK " nick]
  sendCMD rejoin ["USER " usern " " hostn " " servern " :" realn]

  random/seed now/time

  OldTime: GetSecs

  while [connected] [
    if GetSecs < OldTime [
      OldTime: Getsecs
      ]
    Elapsed: GetSecs - OldTime

    wait 0.5
    waitport: wait [irccon 60]
    either (waitport = none) [
      ; If it's timed out with nowt happening then count up to 5 (5 mins) before pinging Q in order to save on net traffic.
      pingtimer: pingtimer + 1
      if (pingtimer = 5) [
        Print "Debug: 5 min timeout"
        SendCMD "PING Q"
        pingtimer: 0
        ]
      ][
      either error? ircresult: try [readirc] [
        probe disarm ircresult      
        connected: false
        logflush
        sendchan "Something is broken, I need to restart."
        ][
        foreach irclz ircresult [printx irclz]
        ]
      ]

    If Elapsed > 60 [
      If (nick = altnick) [
        ; Try get out nick back
        sendCMD rejoin ["NICK " realnick]
        ]
      LogFlush
      OldTime: Getsecs
      Elapsed: 0
      ;
      ; Shit to run periodically.
      ;
      Print "Debug: CheckPop"
      try [CheckPop]
      ;Print "Debug: CheckNews"
      ;NewsUpdate2
      ]
    ]
  try [close irccon]
  ;CloseDB-Vote
  Printx "Disconnected, reconnecting"
  wait 0:1:00

]


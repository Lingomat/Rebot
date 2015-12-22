REBOL [
	Title: "Http tools"
	File: %http-tools.r
	Author: "Graham Chiu"
	Email: gchiu@compkarori.co.nz
	Date: 14-Dec-2000
	Version: .3
	Category: [web net 4]
	Purpose: {
		To grab cookies from the server and post form data.
	}
	Notes: {
		url-encode posted to the Rebol mailing list by KGD03011@nifty.ne.jp
		Modification of Andrew Grossman's cookies-client script by Graham Chiu. 
		Modification of Martin Johannesson's POST script by Andrew Grossman.
		Orig. cookies-client.r available at www.rebol.com in users' library.
	}
	Usage: {
		variables are stored in the http-tools-data object. To read a page which requires
		basic http-authentication, set them first as follows:

		http-tools-data/username: "myusername"
		http-tools-data/password: "mypassword"

		You may clear them by using the function 'clear-http-tools

		To fetch a page which sends you a cookie, pass the function an empty block

		tmp: HTTP-TOOLS http://www.rebol.com []

		The url encoded cookie will be returned as http-tools-data/cookie-data

		To post to a page which may or may not require a cookie, pass the name value pairs in the block,
		and call 'http-tools with the /post refinement.

		tmp: HTTP-TOOLS/POST http://www.rebol.com/cgi-bin/register.r [ "name1" "value1" "name2" value2" ... ]

		http-tools will use the cookie(s) stored in http-tools-data/cookie-data
		The name value pairs will be url-encoded by http-tools.

		The page in all cases will be returned by the function.  You can view the content
		as tmp/content, and look at the header data by

		probe tmp

		If the page fetched by http-tools contains a location directive, that will be
		also stored in http-tools-data/location

	}
	Category: [web util 4]
]


url-encode: func [
	{URL-encode a string}
	data "String to encode"
	/local new-data normal-char c
] compose [
	new-data: make string! ""
	normal-char: (charset [
			#"A" - #"Z" #"a" - #"z"
			#"@" #"." #"*" #"-" #"_"
			#"0" - #"9"
		])
	if not string? data [return new-data]
	parse data [some [
			copy c normal-char
			(append new-data c) |
			copy c skip
			(append new-data reduce ["%" skip tail (to-hex 0 + first c) -2])
		]]
	new-data
]

http-tools-data: make object! [
	location: copy ""
	username: copy ""
	password: copy ""
	cookie-data: copy ""
]

http-tools: func [
	{ read pages off web server, or post values to http forms and automatically handle cookies, authentication }
	url "The URL"
	data [block!] "A block of name/value pairs to represent the form data"
	/local
	encoded-data
	port-spec
	HTTP-Post-Header
	http-request
	buffer
	tmp-buffer
	tmp-header
	/post "Post form data"
] [

	port-spec: make port! [
		scheme: 'tcp
		port-id: 80
		timeout: 0:30
	]

	; check that being passed a valid url
	net-utils/url-parser/parse-url port-spec url

	; encode the value pairs 
	encoded-data: make string! ""
	foreach [name value] data [
		append encoded-data rejoin [
			url-encode name "=" url-encode value "&"
		]
	]

	remove back tail encoded-data

	either post
	[; post data to a form  at url

		HTTP-Post-Header: make object! [
			Accept: "text/html"
			User-Agent: reform ["REBOL" system/version]
			Host: port-spec/host
			Content-Type: "application/x-www-form-urlencoded"
			Content-Length: length? encoded-data
			Cookie: http-tools-data/cookie-data
			Authorization: join {Basic } enbase rejoin [http-tools-data/username ":" http-tools-data/password]
		]

		http-request: rejoin [
			"POST /"
			either found? port-spec/path [port-spec/path] [""]
			either found? port-spec/target [port-spec/target] [""]
			" HTTP/1.0"
		]
	]

	[; just read the url
		HTTP-Post-Header: make object! [
			Accept: "*/*"
			User-Agent: reform ["REBOL" system/version]
			Host: port-spec/host
			Cookie: http-tools-data/cookie-data
			Authorization: join {Basic } enbase rejoin [http-tools-data/username ":" http-tools-data/password]
		]

		http-request: rejoin [
			"GET /"
			either found? port-spec/path [port-spec/path] [""]
			either found? port-spec/target [port-spec/target] [""]
			" HTTP/1.0"
		]
	]

	http-port-private: open/lines [
		scheme: 'tcp
		port-id: port-spec/port-id
		timeout: port-spec/timeout
		host: port-spec/host
		user: port-spec/user
		pass: port-spec/pass
	]

	insert http-port-private http-request
	insert http-port-private net-utils/export HTTP-Post-Header "^/"
	if not empty? encoded-data [
		insert http-port-private encoded-data
	]

	buffer: make string! 10000
	tmp-buffer: reform ["HTTP-Response:" pick http-port-private 1]
	while [not none? tmp-buffer] [
		append buffer rejoin [tmp-buffer "^/"]
		tmp-buffer: pick http-port-private 1
	]

	close http-port-private

	http-tools-data/cookie-data: copy ""
	parse buffer [ any [thru "Set-cookie:" copy txt to " " (append http-tools-data/cookie-data txt) ] | skip ]

	HTTP-Header: make object! [
		HTTP-Response: Date: Server: Last-Modified: none
		Accept-Ranges: Content-Encoding: Content-Type: none
		Content-Length: Location: Expires: Referer: Connection: none
		Set-Cookie: none
	]

	tmp-header: parse-header HTTP-Header buffer

	either none? tmp-header/Location 
	[	http-tools-data/location: copy "" ]
	[	http-tools-data/location: tmp-header/Location	]
	tmp-header
]

clear-http-tools: func [] [
	http-tools-data/cookie-data: copy ""
	http-tools-data/location: copy ""
	http-tools-data/username: copy ""
	http-tools-data/password: copy ""
]


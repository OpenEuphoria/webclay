--****
-- CGI handling
--
-- Based on: 
--     LibCGI v1.5
--     Common Gateway Interface routines for Euphoria
--     Buddy Hyllberg <budmeister1@juno.com>

include std/get.e         -- converting %3D to =
include std/sequence.e
include std/text.e
include std/map.e as m

include cgi/fileio.e      -- for reading/writing files
include cgi/multip.e      -- for multipart/form-data forms

export constant SERVER_VARS = {
	"SERVER_SOFTWARE",   -- the name of the web server.
	"SERVER_VERSION",    -- the version of the web server.
	"SERVER_NAME",       -- the current host name.
	"SERVER_URL",        -- holds the full URL to the server.
	"SERVER_PORT",       -- the port on which the web server is running.
	"SERVER_PROTOCOL",   -- the HTTP version in use (e.g. "HTTP/1.0").
	"GATEWAY_INTERFACE", -- the CGI version in use (e.g. "CGI/1.1").
	"REQUEST_METHOD",    -- the HTTP method used, "GET" or "POST".
	"CONTENT_TYPE",      -- the Content-Type: HTTP field.
	"CONTENT_LENGTH",    -- the Content-Length: HTTP field.
	"REMOTE_USER",       -- the authorized username, if any, else "-";
	-- this will only be set if the user has accessed a protected URL.
	"REMOTE_HOST",       -- the same as REMOTE_ADDR.
	"REMOTE_ADDR",       -- the IP address of the remote host, "x.x.x.x".
	"SCRIPT_PATH",       -- the path of the script being executed.
	"SCRIPT_NAME",       -- the URI of the script being executed.
	"QUERY_STRING",      -- the query string following the URL.
	"PATH_INFO",         -- any path data following the CGI URL.
	"PATH_TRANSLATED",   -- the full translated path with URL arguments.
	"HTTP_ACCEPT",       -- the MIME types the client will accept.
	"HTTP_USER_AGENT"    -- the client's browser signature.
}

export map get = m:new(), post = m:new()

--**
public function server_var( sequence name )
	return getenv(name)
end function

--**
export procedure out( sequence text )
	puts(1, text)
end procedure

--**
export function in()
	return gets(0)
end function

--**
export procedure type_html()
	puts(1, "Content-type: text/html\n\n")
end procedure

--**
export procedure type_text()
	puts(1, "Content-type: text/plain\n\n")
end procedure

--**
export procedure cgi_die( sequence error, sequence message)
	type_html()
	puts(1, "<h1>" & error & "</h1>\n")
	puts(1, "<p>" & message & "</p>\n")
end procedure

--**
export function method()
	return getenv("REQUEST_METHOD")
end function

--**
export function get_data()
	return getenv("QUERY_STRING")
end function

--**
export function post_data()
	object in
	sequence buf = {}
	sequence len = value(getenv("CONTENT_LENGTH"))

	for i = 1 to len[2] do
		in = getc(0)
		if equal(in, -1) then
			return buf
		else
			buf &= in
		end if
	end for
	return buf
end function

--**
export function form_data( sequence method )
  if equal(upper(method), "GET") then
    return get_data()
  elsif equal(upper(method), "POST") then
    return post_data()
  else
    return -1
  end if
end function

constant PAIR_SEP = {'&', ';'}, HEX_SIG = '%', WHITESPACE = '+', VALUE_SEP = '='

--**
export function process_data(object data)
	atom i, char
	object tmp
	sequence charbuf, fieldbuf, fname=""
	m:map the_map = m:new()

	if atom(data) then
		return the_map
	end if

	charbuf = {}  fieldbuf = {}  i = 1
	while i <= length(data) do
		char = data[i]  -- character we're working on
		if equal(char, HEX_SIG) then
			tmp = value("#" & data[i+1] & data[i+2])
			charbuf &= tmp[2]
			i += 3
		elsif equal(char, WHITESPACE) then
			charbuf &= " "
			i += 1
		elsif equal(char, VALUE_SEP) then
			fname = charbuf
			charbuf = {}
			i += 1
		elsif find(char, PAIR_SEP) then
			m:put(the_map, fname, charbuf)
			fname = {}
			charbuf = {}
			i += 1
		else
			charbuf &= char
			i += 1
		end if
	end while

	if length(fname) then
		m:put(the_map, fname, charbuf)
	end if

	return the_map
end function


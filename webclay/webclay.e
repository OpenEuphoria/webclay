--****
-- == Web Clay
--
-- Web framework for Euphoria

include std/sequence.e
include std/text.e
include std/map.e
include std/datetime.e
include std/pretty.e
include std/get.e

include logging.e as log
include errdisp.e

public include cgi.e as cgi
public include escape.e as esc

public map:map cookies = map:new()

--**
-- Return Types

public enum OK, TEXT, REDIRECT, REDIRECT_303, INVALID, VALID
public enum NONE=-1, ATOM, INTEGER, SEQUENCE, OBJECT

enum CONVERT_TYPE, CONVERT_NAME, CONVERT_DEFAULT
enum ACTION_RID, VALIDATION_RID, MODULE, ACTION, CONVERSION
enum VALID_MODULE, VALID_ACTION, VALID_ERRORS

sequence handlers = {}, headers = {}
integer set_content_type = 0, default_handler = -1

function handler_idx(sequence module, sequence action)
	for i = 1 to length(handlers) do
		if equal(handlers[i][MODULE], module) then
			if equal(handlers[i][ACTION], action) then
				return i
			end if
		end if
	end for

	return 0
end function

function handler_idx_by_rid(integer rid)
	for i = 1 to length(handlers) do
		if handlers[i][ACTION_RID] = rid then
			return i
		end if
	end for

	return 0
end function

--**
-- Create a new error sequence

public function new_errors(sequence module, sequence action)
	return { module, action, {}}
end function

--**
-- Add a validation error

public function add_error(sequence errors, sequence field, sequence message, object data={})
	errors[VALID_ERRORS] &= { { field, sprintf(message, data) } }
	return errors
end function

--**
-- Do we have errors?
-- 

public function has_errors(sequence errors)
	if length(errors[VALID_ERRORS]) then
		return 1
	end if
	
	return 0
end function

--**
-- Set the default handler

public procedure set_default_handler(integer rid)
	default_handler = rid
end procedure

--**
-- Add a request handler
--
-- TODO:
--   * handle an invalid rid (typo on passing, i.e. routine_id("say_hllo")

public procedure add_handler(integer action_rid, integer validation_rid, sequence module,
		sequence action="index", sequence conversion={})
	sequence handler = {action_rid, validation_rid, module, action, conversion}
	handlers &= {handler}
end procedure

--**
-- Add a header for output

public procedure add_header(sequence name, sequence value)
	if equal(name, "Content-Type") then
		set_content_type = 1
	end if
	headers &= {name & ": " & value}
end procedure

--**
-- Add a session cookie

public procedure add_cookie(sequence name, sequence value, object path=0, object expires=0, 
		object domain=0)
	sequence cookie = name & "=" & value
	if sequence(domain) then
		cookie &= "; domain=" & domain
	end if
	if sequence(path) then
		cookie &= "; path=" & path
	end if
	if datetime:datetime(expires) then
		cookie &= "; expires=" & datetime:format(expires, "%a, %d-%b-%y %H:%map:%S GMT")
	elsif sequence(expires) then
		cookie &= "; expires=" & expires
	end if

	add_header("Set-cookie", cookie)
end procedure

--**
-- Put a value into the GET request map

public procedure get_put(sequence key, object v)
	map:put(cgi:get, key, v)
end procedure

--**
-- Determine if the GET request map has key

public function get_has(sequence key)
	return map:has(cgi:get, key)
end function

--**
-- Get a value from the GET request map

public function get(sequence key)
	return map:get(cgi:get, key, "")
end function

--**
-- Put a value into the POST request map

public procedure post_put(sequence key, object v)
	map:put(cgi:post, key, v)
end procedure

--**
-- Determine if the POST request map has key

public function post_has(sequence key)
	return map:has(cgi:post, key)
end function

--**
-- Get a value from the POST request map

public function post(sequence key)
	return map:get(cgi:post, key, "")
end function

--**
-- Determine if the request has a cookie named ##key##.

public function cookie_has(sequence key)
	return map:has(cookies, key)
end function

--**
-- Get the cookie value of ##key##.

public function cookie(sequence key)
	return map:get(cookies, key, "")
end function

public procedure display_error(sequence message, object data={})
	sequence s = sprintf(message, data)
	puts(1, "Content-Type: text/html\n\n")
	puts(1, "<html><body>" & htmlspecialchars(s) & "</body></html>")
	abort(0)
end procedure

procedure do_conversion(sequence handler, map cgi_vars)
	if not equal(handler[CONVERSION], {}) then
		-- Handle Conversion
		for a = 1 to length(handler[CONVERSION]) do
			object convert = handler[CONVERSION][a]
			switch convert[CONVERT_TYPE] do
				case ATOM, INTEGER then
					object o_v
					if get_has(convert[CONVERT_NAME]) then
						o_v = value(map:get(cgi:get, convert[CONVERT_NAME], 0))
						if o_v[1] = GET_SUCCESS then
							o_v = o_v[2]
						elsif length(convert) >= CONVERT_DEFAULT then
							o_v = convert[CONVERT_DEFAULT]
						else
							o_v = 0
						end if
						map:put(cgi_vars, convert[CONVERT_NAME], o_v)

					elsif post_has(convert[CONVERT_NAME]) then
						o_v = value(map:get(cgi:post, convert[CONVERT_NAME], 0))
						if o_v[1] = GET_SUCCESS then
							o_v = o_v[2]
						elsif length(convert) >= CONVERT_DEFAULT then
							o_v = convert[CONVERT_DEFAULT]
						else
							o_v = 0
						end if
						map:put(cgi_vars, convert[CONVERT_NAME], o_v)

					else
						if length(convert) >= CONVERT_DEFAULT then
							o_v = convert[CONVERT_DEFAULT]
						else
							o_v = 0
						end if
						map:put(cgi_vars, convert[CONVERT_NAME], o_v)
					end if

				case else
					if get_has(convert[CONVERT_NAME]) then
						map:put(cgi_vars, convert[CONVERT_NAME],
							map:get(cgi:get, convert[CONVERT_NAME], ""))
					elsif post_has(convert[CONVERT_NAME]) then
						map:put(cgi_vars, convert[CONVERT_NAME],
							map:get(cgi:post, convert[CONVERT_NAME], ""))
					elsif length(convert) >= CONVERT_DEFAULT then
						map:put(cgi_vars, convert[CONVERT_NAME], convert[CONVERT_DEFAULT])
					else
						map:put(cgi_vars, convert[CONVERT_NAME], "")
					end if
			end switch
		end for
	end if
end procedure

--**
-- Turn control over to eWeb and handle the request

public procedure handle_request(integer app_rid=-1)
	object handler, data
	object status, template
	object cookie_var = getenv("HTTP_COOKIE")
	
	-- Generic cookie handling
	if sequence(cookie_var) and length(cookie_var) then
		sequence kv = keyvalues(cookie_var, ";", "=", "\"'`", "")
		for a = 1 to length(kv) do
			map:put(cookies, kv[a][1], kv[a][2])
		end for
	end if

	cgi:get = cgi:process_data(cgi:get_data())

	if equal(getenv("REQUEST_METHOD"), "POST") then
		cgi:post = cgi:process_data(cgi:post_data())
	end if
	
	map:map template_data = map:new()

	if not get_has("module") or not get_has("action") then
		if default_handler = -1 then
			display_error("Invalid request and no default handler")
		end if

		handler = handler_idx_by_rid(default_handler)
		handler = handlers[handler]
	else
		handler = handler_idx(get("module"), get("action"))
		if handler = 0 then
			display_error("Invalid module/action pair '%s/%s'",
				{get("module"), get("action")})
		end if

		handler = handlers[handler]
	end if

	map:map cgi_vars = map:copy(cgi:get)
	map:copy(cgi:post, cgi_vars)

	sequence params = { template_data, cgi_vars }

	do_conversion(handler, cgi_vars)

	if app_rid > -1 then
		call_proc(app_rid, params)
	end if

	map:put(template_data, "has_errors", 0)
	if handler[VALIDATION_RID] > -1 then
		status = call_func(handler[VALIDATION_RID], params)
		if length(status[VALID_ERRORS]) then
			map:put(template_data, "has_errors", 1)
			
			for a = 1 to length(status[VALID_ERRORS]) do
				sequence error = status[VALID_ERRORS][a]
				map:put(template_data, "errors", error, map:APPEND)
				map:put(template_data, sprintf("%s_error", { error[1] }), 1)
				map:put(template_data, sprintf("%s_emsg", { error[1] }), error[2])
			end for

			handler = handler_idx(status[VALID_MODULE], status[VALID_ACTION])
			if handler = 0 then
				display_error("Invalid module/action pair for validation")
			end if

			handler = handlers[handler]
			
			-- do the conversion specified by the new handler
			do_conversion(handler, cgi_vars)
		end if
	end if

	status = call_func(handler[ACTION_RID], params)

	switch status[1] do
		case OK then
			
		case TEXT then
			if set_content_type = 0 then
				add_header("Content-Type", "text/html")
			end if
			
			puts(1, join(headers, "\n") & "\n\n")
			puts(1, status[2])

		case REDIRECT then
			printf(1, "Content-Type: text/html\n\n<html><body>\n", {})
			printf(1, status[2], status[3])
			printf(1, "</body></html>\n", {})
		
		case REDIRECT_303 then
			printf(1, "Status: 303 See Other\n", {})
			printf(1, "Location: %s\n\n", { status[2] })
	end switch
end procedure

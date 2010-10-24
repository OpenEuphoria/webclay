include std/map.e
include std/io.e
include std/error.e
include errconv.e

include errtmpl.etml as errtmpl

function display_error(integer dummy)
	sequence error, msg
	map:map data = map:new()
	
	map:put(data, "title", "Internal Error")
	error = err_conv("")
	if length(error) > 0 then
		error = read_lines("ex.err")
	else
		error = read_lines("ex_conv.err")
	end if

	msg = ""
	for x = 1 to length(error) do
		msg &= error[x] & "\n"
	end for

	map:put(data, "error", msg)

	puts(1, "Content-Type: text/html\n\n")
	puts(1, errtmpl:template(data))
	flush(1)

	return 1
end function
crash_routine(routine_id("display_error"))

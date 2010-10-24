include std/cmdline.e
include std/filesys.e
include std/io.e
include std/map.e as m
include std/regex.e as re
include std/sequence.e as seq
include std/text.e

constant at_value   = re:new(`@([A-Za-z0-9_]+)`)
constant hash_value = re:new(`#([A-Za-z0-9_]+)`)

function expand_value(sequence str)
	str = re:find_replace(at_value, str,`map:get(data, "\1", "")`)
	return re:find_replace(hash_value, str,`map:get(params, "\1", "")`)
end function

function parse_template_string(sequence in, sequence funcName = "template",
		sequence params = {})
	integer next_tag, pos = 1
	sequence out = sprintf("""

	public function %s(map:map data, map:map params=map:new())
			sequence result = ""

		""", { funcName })
	
	while next_tag > 0 with entry do
		if next_tag > pos then
			if eu:find('`', in[pos..next_tag-1]) = 0 then
				out &= "\tresult &= `" & in[pos..next_tag-1] & "`\n"
			else
				out &= "\tresult &= \"\"\"" & in[pos..next_tag-1] & "\"\"\"\n"
			end if
		end if

		pos = match_from("%>", in, next_tag) + 2

		sequence tag = trim(in[next_tag+2..pos-3])

		switch tag[1] do
			case '=' then
				sequence item_name = trim(tag[2..$])
				out &= "\tresult &= " & expand_value(item_name) & "\n"

			case '-' then
				sequence tag_name = trim(tag[2..$])
				sequence tag_params = ""
				integer param_pos = eu:find(' ', tag_name)
				if param_pos then
					tag_params = tag_name[param_pos + 1..$]
					tag_name = tag_name[1..param_pos-1]
				end if

				if length(tag_params) then
					m:map tp = m:new_from_string(tag_params)
					out &= "\tif 1 then\n"
					out &= "\t\tmap:map _p = map:new()\n"
					sequence param_keys = m:keys(tp)
					for key_idx = 1 to length(param_keys) do
						sequence v = m:get(tp, param_keys[key_idx])

						out &= "\t\tmap:put(_p, \"" & param_keys[key_idx] & "\", "
						if eu:find('#', v) or eu:find('@', v) then
 							out &= expand_value(v) & ")\n"
						elsif eu:find('!', v) = 1 then
							out &= v[2..$] & ")\n"
						else
							out &= "\"" & v & "\")\n"
						end if
					end for
					out &= "\t\tresult &= " & tag_name & "(data, _p)\n"
					out &= "\tend if\n"
				else
					out &= "\tresult &= " & tag_name & "(data)\n"
				end if
									

			case '@' then
				out = trim(tag[2..$]) & "\n" & out

			case else
				out &= expand_value(trim(tag)) & "\n"
		end switch

	entry
		next_tag = match_from("<%", in, pos)
	end while

	out &= "\tresult &= \"\"\"" & in[pos..$] & "\"\"\"\n"

	out &= """
		return result
	end function
	"""

	return out
end function

function taglib(sequence in_fname, sequence out_fname)
	sequence out = "include std/map.e\n"
	sequence in = read_file(in_fname)
	integer spos, epos, npos

	spos = match("{{{", in)
	
	while spos < length(in) do
		epos = match_from("}}}", in, spos)
		npos = match_from("{{{", in, epos) - 1

		if npos = -1 then
			npos = length(in)
		end if

		sequence tag_data = seq:split(trim(in[spos+3..epos-1]))
		sequence t = in[epos+4..npos]
		sequence tag_name = tag_data[1]

		if length(tag_data) > 1 then
			tag_data = tag_data[2..$]
		else
			tag_data = {}
		end if

		out &= parse_template_string(t, tag_name, tag_data)

		spos = npos + 1
	end while

	write_file(out_fname, out)

	return 0
end function

function template(sequence in_fname, sequence out_fname)
	sequence in = read_file(in_fname)
	sequence out = "include std/map.e\n"

	out &= parse_template_string(in)

	write_file(out_fname, out)

	return 0
end function

public function preprocess(sequence inFileName, sequence outFileName, sequence options={})
	if equal(fileext(inFileName), "etml") then
		return template(inFileName, outFileName)
	else
		return taglib(inFileName, outFileName)
	end if
end function

ifdef not EUC_DLL then
	constant cmd_params = {
		{ "i", 0, "Input filename", { NO_CASE, MANDATORY, HAS_PARAMETER, "filename" } },
		{ "o", 0, "Output filename", { NO_CASE, MANDATORY, HAS_PARAMETER, "filename" } }
	}

	map:map params = cmd_parse(cmd_params)

	sequence inFileName  = map:get(params, "i")
	sequence outFileName = map:get(params, "o")

	abort(preprocess(inFileName, outFileName))
end ifdef

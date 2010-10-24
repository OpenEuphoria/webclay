--
-- WebClay PreProcessor
--

include std/filesys.e
include std/io.e
include std/cmdline.e
include std/text.e
include std/pretty.e
include std/map.e
include std/sequence.e

constant cmd_params = {
	{ "i", 0, "Input filename", { NO_CASE, HAS_PARAMETER } },
	{ "o", 0, "Output filename", { NO_CASE, HAS_PARAMETER } }
}

function parse_tag(sequence content)
	sequence action_name, params
	integer b_paren = find('(', content)
	
	if b_paren then
		integer e_paren = find(')', content)
		action_name = content[2..b_paren-1]
		params = split_any(content[b_paren+1..e_paren-1], ", ", 0, 1)
	else
		action_name = content[2..$]
		params = {}
	end if
	
	return { action_name, params }
end function

procedure main()
	map:map params = cmd_parse(cmd_params)
	
	object input_filename=map:get(params, "i"), 
		output_filename=map:get(params, "o")

	if atom(input_filename) or atom(output_filename) then
		puts(1, "Usage: wcpp.ex -i input_file -o output_file\n")
		abort(1)
	end if

	sequence action_name = ""
	sequence validator_name = ""
	sequence invar_name = ""
	sequence module_name = filebase(input_filename)
	sequence content = read_lines(input_filename)
	integer i = 1
	
	while i <= length(content) do	
		if match("@action", content[i]) = 1 then
			sequence tag_data = parse_tag(content[i])
			if length(tag_data[2]) > 0 then
				invar_name = tag_data[2][1]
			end if
			if length(tag_data[2]) > 1 then
				validator_name = tag_data[2][2]
			end if
	
			content = remove(content, i)
			continue
			
		elsif match("@validator", content[i]) = 1 then
			sequence tag_data = parse_tag(content[i])
			validator_name = tag_data[2][1]

			content = remove(content, i)
			continue

		elsif match("function", content[i]) = 1 then
			integer b_paren = find('(', content[i])
			action_name = content[i][10..b_paren-1]
			
		elsif match("end function", content[i]) = 1 then
			if length(action_name) then
				sequence reg_action = sprintf(`wc:add_handler(routine_id("%s"), `, { action_name })
				
				if length(validator_name) then
					reg_action &= sprintf(`routine_id("%s"), `, { validator_name })
				else
					reg_action &= "-1, "
				end if
				
				reg_action &= sprintf(`"%s", "%s"`, { module_name, action_name })
				
				if length(invar_name) then
					reg_action &= ", " & invar_name
				end if
				
				reg_action &= ")"
				
				content &= { reg_action }
			end if
			
			action_name = ""
			validator_name = ""
			invar_name = ""
			
		end if
		
		i += 1
	end while
	
	write_lines(output_filename, content)
end procedure

main()


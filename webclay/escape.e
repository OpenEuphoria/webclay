include std/text.e

public function shellarg(sequence arg)
	sequence ret
	ret = ""
	for i = 1 to length(arg) do
		if arg[i] = '\'' then
			ret &= "\'\"\\'\"\'"
		else
			ret &= arg[i]
		end if
	end for
	return '\'' & ret & '\''
end function

public function htmlspecialchars(sequence arg)
	sequence ret
	ret = ""
	for i = 1 to length(arg) do
		if arg[i] = '&' then
			ret &= "&amp;"
		elsif arg[i] = '"' then
			ret &= "&quot;"
		elsif arg[i] = '\'' then
			ret &= "&#039;"
		elsif arg[i] = '<' then
			ret &= "&lt;"
		elsif arg[i] = '>' then
			ret &= "&gt;"
		else
			ret &= arg[i]
		end if
	end for
	return ret
end function

global function _h(object arg)
	if atom(arg) then
		return sprint(arg)
	end if

	return htmlspecialchars(arg)
end function

public function xmlspecialchars(sequence arg)
	sequence ret
	ret = ""
	for i = 1 to length(arg) do
		if arg[i] = '&' then
			ret &= "&amp;"
		elsif arg[i] = '<' then
			ret &= "&lt;"
		elsif arg[i] = '>' then
			ret &= "&gt;"
		else
			ret &= arg[i]
		end if
	end for
	return ret
end function

global function _x(object arg)
	if atom(arg) then
		return sprint(arg)
	end if

	return xmlspecialchars(arg)
end function

public function shellcmd(sequence arg)
	sequence ret
	ret = ""
	for i = 1 to length(arg) do
		if find(arg[i], "\"\'#&;`|*?~<>^()[]{}$\\, \n"&255) then
			ret &= '\\'
		end if
		ret &= arg[i]
	end for
	return ret
end function

public function batchcmd(sequence arg)
	sequence ret
	ret = ""
	for i = 1 to length(arg) do
		if find(arg[i], "\"\'%#&;`|*?~<>^()[]{}$\\, \n"&255) then
			ret &= ' '
		else
			ret &= arg[i]
		end if
	end for
	return ret
end function

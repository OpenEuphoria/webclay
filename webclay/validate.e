include std/regex.e

--
-- Validators for Intrigue
--

public function not_empty(sequence content)
	return length(content) > 0
end function

public function size_within(sequence content, integer low, integer high)
	return length(content) >= low and length(content) <= high
end function

public function size_equal(sequence content, integer len)
	return length(content) = len
end function

public function in_range(atom value, atom low, atom high)
	return value >= low and value <= high
end function

constant re_valid_email = regex:new("^[a-zA-Z][\\w\\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\\w\\.-]*[a-zA-Z0-9]\\.[a-zA-Z][a-zA-Z\\.]*[a-zA-Z]$")

public function valid_email(sequence email)
        return regex:is_match(re_valid_email, email)
end function

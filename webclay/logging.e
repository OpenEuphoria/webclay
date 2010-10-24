include std/io.e
include std/datetime.e as dt

atom log_fh=-1

public procedure open(sequence name)
	log_fh = eu:open(name, "a")
end procedure

public procedure close()
	if log_fh > 0 then
		eu:close(log_fh)
	end if

	log_fh = -1
end procedure

public procedure log(sequence f, object data={})
	if log_fh > 0 then
		printf(log_fh, dt:format(dt:now(), "%Y-%m-%d %H:%M:%S") & ": " & f & "\n", data)
	end if
end procedure

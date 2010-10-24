-- File I/O routines for LibCGI
--

include std/io.e -- seek()

-- sequence file: filename
-- atom chunksize: number of bytes to read; 0 reads the whole file
-- atom offset: starting position in file; 0 starts at the beginning
--
public function read_binary( sequence file, atom chunksize, atom offset )
  atom A, char, j
  sequence buf  buf = {}  j = 1
  A = open(file, "rb")
  if A = -1 then  return -1  end if
  if offset != 0 then  char = seek(A, offset)  end if
  if chunksize != 0 then
    while j <= chunksize do
      char = getc(A)
      if char = -1 then
        if length(buf) then  close(A)  return buf
        else  return -1
        end if
      else  buf &= char
      end if
    end while
  else
    while 1 do
      char = getc(A)
      if char = -1 then
        if length(buf) then  close(A)  return buf
        else  return -1
        end if
      else  buf &= char
      end if
    end while
  end if
end function


-- sequence file: filename
-- sequence data: data to write; expects a straight sequence (no sequence-in-sequence)
public function write_binary( sequence file, sequence data )
  atom B
  B = open(file, "wb")
  if B = -1 then  return -1  end if
  puts(1, data)
  close(B)
  return 1
end function


-- sequence file: filename
-- atom lines: number of lines to read; 0 reads the whole file.
--
public function read_text( sequence file, atom lines )
  atom A
  object in
  sequence buf  buf = {}
  A = open(file, "r")
  if A = -1 then  return -1  end if
  if lines > 0 then
    in = gets(A)
    if equal(in, -1) then  close(A)  return -1
    else  close(A)  return in
    end if
  else
    while 1 do
      in = gets(A)
      if equal(in, -1) then  close(A)  return buf
      else  buf &= in
      end if
    end while
  end if
end function


-- sequence file: filename
-- sequence data: data to write to the file
--
public function write_text( sequence file, sequence data )
  atom B
  B = open(file, "w")
  if B = -1 then  return -1  end if
  puts(1, data)
  close(B)
  return 1
end function

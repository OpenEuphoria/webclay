-- Multipart form handling routines for LibCGI
--

include std/wildcard.e

function post_data_multipart()
  object in
  sequence buf  buf = {}
  while 1 do
    in = gets(0)
    if equal(in, -1) then
      return buf
    else
      buf = append(buf, in)
    end if
  end while
end function


public function form_data_multipart()
  return post_data_multipart()
end function


public function parse_multipart_content( sequence content )
  atom q, z, char, pair_sep, string_sep
  sequence whitespace, value_sep, fieldbuf, charbuf
  fieldbuf = {}  charbuf = {}
  pair_sep = ';'  whitespace = {' ','\n'}  string_sep = '"'  value_sep = {'=',':'}
  q = 1
  while q <= length(content) do
    char = content[q]
    if equal(char, pair_sep) then
      fieldbuf = append(fieldbuf, charbuf)
      charbuf = {}
      q += 1
    elsif equal(char, string_sep) then
      z = match("\"", content[q+1..length(content)])
      z = q + z
      fieldbuf = append(fieldbuf, content[q+1..z-1])
      q = z+1
    elsif find(char, whitespace) then
      q += 1
    elsif find(char, value_sep) then
      fieldbuf = append(fieldbuf, charbuf)
      charbuf = {}
      q += 1
    else
      charbuf &= char
      q += 1
    end if
  end while
  fieldbuf = append(fieldbuf, charbuf)
  return fieldbuf
end function


public function process_form_multipart( sequence data )
  atom q
  object bounds, line, linebuf, fieldbuf, databuf
  line = {}  linebuf = {}  fieldbuf = {}  databuf = {}

  -- FOR TESTING
  --trace(1)
  --bounds = "multipart/form-data; boundary=---------------------------32171498913840"
  --

  bounds = getenv("CONTENT_TYPE")
  if equal(bounds, -1) then  return -1  end if  -- a little error check
  bounds = parse_multipart_content(bounds)
  bounds = bounds[find("boundary", bounds)+1]  -- get the MIME boundary

  q = 1
  while q <= length(data) do
    line = data[q]

    if match(bounds & "--", line) then  -- catch the end of the input before anything else
      if length(linebuf) then
        fieldbuf = append(fieldbuf, linebuf & {databuf})
      end if
      return fieldbuf

    elsif match(bounds, line) then  -- reached a MIME boundary; the data for this element is done
      if length(linebuf) then
        fieldbuf = append(fieldbuf, linebuf & {databuf})
      end if
      linebuf = {}  databuf = {}
      q += 1

    elsif is_match("Content?*", line) then
      line = parse_multipart_content(line)
      linebuf = line
      if is_match("Content?*", data[q+1]) then  -- add any Content-types to linebuf
        q += 1
        line = data[q]
        line = parse_multipart_content(line)
        linebuf &= line
        q += 2
      else
        q += 2
      end if

    else
      databuf &= line
      q += 1

    end if
  end while

  return -1   -- it only gets here if no ending boundary is found

end function

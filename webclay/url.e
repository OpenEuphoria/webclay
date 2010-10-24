include std/get.e

public function decode(sequence s)
  integer k
  k = 1
  while k <= length(s) do
    if s[k] = '+' then
      s[k] = ' ' --space is a special case, converts into +
    elsif s[k] = '%' then
      s[k] = value("#"&s[k+1..k+2])
      s[k] = s[k][2]
      s = s[1..k] & s[k+3..length(s)]
    else
        -- do nothing if it is a regular char ('0' or 'A' or etc)
    end if
    k += 1
  end while
  return s
end function

public function encode(sequence what)
  -- Function added by Kathy Smith (Kat)(KAT12@coosahs.net), version 1.3.0
  sequence encoded, alphanum, hexnums
  object junk, junk1, junk2

  encoded = ""
  junk = ""
  alphanum = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz01234567890/" -- encode all else
  hexnums = "0123456789ABCDEF"

  for idx = 1 to length(what) do
    if find(what[idx],alphanum) then
      encoded &= what[idx]
    else
      junk = what[idx]
      junk1 = floor(junk / 16)
      junk2 = floor(junk - (junk1 * 16))
      encoded &= "%" & hexnums[junk1+1] & hexnums[junk2+1]
    end if
  end for
  return encoded
end function

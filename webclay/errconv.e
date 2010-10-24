-- ErrConv 1.40
-- Convert Euphoria's "ex.err" file to 1 or 2 other files, that contain
-- the contents of sequences _either_ as  numbers _or_ as strings, so
-- that they are better readable.
--
-- Public Domain -- 2007, Dec 18
-- by Juergen Luethje <support {AT} luethje {DOT} eu>
-- Standard disclaimer: Use at your own risk!

-- Successfully tested with the Euphoria 3.1.1 DOS, Windows and Linux
-- interpreters.

include std/get.e                              -- for value()
include std/types.e                            -- for FALSE

-------------------------------[ types ]--------------------------------

public type sequence_of_byte (object x)
   object t

   if atom(x) then
      return 0
   end if
   for i = 1 to length(x) do
      t = x[i]
      if (not integer(t)) or (t < 0)  or (t > #FF) then
         return 0
      end if
   end for
   return 1
end type

type boolean (object x)
   if integer(x) then
      return x = 0 or x = 1
   end if
   return 0
end type

--------------------------[ utility routines ]--------------------------

function slash_char()
   if platform() = 3 then        -- = LINUX
      return '/'
   else
      return '\\'
   end if
end function

public constant
   SLASH = slash_char()
   -- FALSE = 0, TRUE = 1  -- Defined in std/types.e

function path_end (sequence name, integer slash)
   for i = length(name) to 1 by -1 do
      if name[i] = slash then
         return i
      end if
   end for
   return find(':', name)
end function

public function file_path (sequence name, integer slash)
   -- in : filename, e.g. "c:\\programs\\nicetool.exe"
   -- out: path, always with trailing slash or colon
   integer p

   p = path_end(name, slash)
   if p = length(name) or name[p+1] != '.' then
      return name[1..p]
   else
      return name & slash
   end if
end function

public function file_name (sequence name, integer slash)
   -- in : filename, e.g. "c:\\programs\\nicetool.exe"
   -- out: name without path, e.g. "nicetool.exe"
   integer p

   p = path_end(name, slash) + 1
   if p <= length(name) and name[p] != '.' then
      return name[p..$]
   else
      return ""
   end if
end function

--------------------------------[ main ]--------------------------------

public constant
   FILE_ERR_MAIN    = "ex_conv.err",              -- names in lowercase!
   FILE_ERR_NUMBERS = "ex_n.err"

constant
   SPECIAL_ASCII = {"9","10","13"},
   SPECIAL_CHARS = {"\\t","\\n","\\r"},
   TO_BE_ESCAPED = {'"','\\'}

sequence_of_byte Number, NumList, String
boolean GotChar, IsString

procedure add_number()
   -- Add number to list of numbers, and maybe appropriate character to string.
   sequence v
   atom n
   integer p

   NumList &= Number

   if GotChar = FALSE then
      if find('\n', Number) = 1 then
         Number = Number[2..$]
      end if
      p = find(Number, SPECIAL_ASCII)
      if p then
         String &= SPECIAL_CHARS[p]
      else 
         v = value(Number)
         if v[1] = GET_SUCCESS then
            n = v[2]
         else
            n = -1
         end if
         if integer(n) and (32 <= n) and (n <= 255) then
            String &= {n}
         else
            IsString = FALSE
         end if
      end if
   end if

   GotChar = FALSE
   Number = ""
end procedure

function convert (sequence_of_byte ex_err,
                  sequence_of_byte ex_conv_err, sequence_of_byte ex_n_err)
   -- Convert file <ex_err> to 1 or 2 other files.
   sequence errNumbers
   integer ifn, ofn, byte
   boolean isSeq, stringThere

   -- initialize
   ifn = open(ex_err, "r")
   if ifn = -1 then
      return ex_err                                     -- error
   end if
   ofn = open(ex_conv_err, "w")
   if ofn = -1 then
      return ex_conv_err                                -- error
   end if

   errNumbers = {}
   isSeq = FALSE
   stringThere = FALSE
   GotChar = FALSE
   Number = ""
   NumList = ""
   String = ""

   -- main loop
   byte = getc(ifn)
   while byte != -1 do
      if byte = '{' then                                -- begin of sequence
         errNumbers &= NumList & Number
         puts(ofn, NumList & Number)
         Number = ""
         NumList = "{"
         String = "\""
         isSeq = TRUE
         IsString = TRUE

      elsif isSeq then
         if byte = '\'' then                            -- opening |'|
            byte = getc(ifn)                            -- get the following character
            if find(byte, TO_BE_ESCAPED) then
               String &= '\\'
            end if
            String &= byte
            byte = getc(ifn)                            -- closing |'| ignored
            GotChar = TRUE

         elsif byte = ',' then                          -- end of element
            add_number()
            NumList &= ','

         elsif byte = '}' then                          -- normal end of sequence
            add_number()
            errNumbers &= NumList & '}'
            if IsString then
               puts(ofn, String & '"')
               stringThere = TRUE
            else
               puts(ofn, NumList & '}')
            end if
            NumList = ""
            String = ""
            isSeq = FALSE
            IsString = FALSE

         elsif byte = '.' and length(Number) = 0 then   -- end of long sequence |,...|
            errNumbers &= NumList & '.'
            puts(ofn, String & '.')
            if IsString then
               stringThere = TRUE
            end if
            NumList = ""
            String = ""
            isSeq = FALSE
            IsString = FALSE

         elsif byte != '\r' then                        -- add (e.g.) digit to Number
            Number &= byte
         end if

      else                                              -- no sequence
         errNumbers &= byte
         puts(ofn, byte)
         if byte = '\'' then
            for i = 1 to 2 do                           -- read/write character and closing |'|
               byte = getc(ifn)
               errNumbers &= byte
               puts(ofn, byte)
            end for
         end if
      end if

      byte = getc(ifn)
   end while
   close(ifn)
   close(ofn)

   -- write file ex_n_err, if necessary
   if stringThere then
      ofn = open(ex_n_err, "w")
      if ofn = -1 then
         return ex_n_err                                -- error
      end if
      puts(ofn, errNumbers)
      close(ofn)
   end if

   return ""                                            -- success
end function

public function err_conv (sequence_of_byte ex_err)
   --> Read 1 input file and generate 1 or 2 output files.
   --> Return "" on success, otherwise name of file that couldn't be opened.
   sequence_of_byte path

   if length(ex_err) = 0 then
      ex_err = "ex.err"
      path = ""
   else
      path = file_path(ex_err, SLASH)
   end if

   return convert(ex_err, path & FILE_ERR_MAIN, path & FILE_ERR_NUMBERS)
end function

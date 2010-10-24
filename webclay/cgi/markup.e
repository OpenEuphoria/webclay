-- HTML tag and comboform routines for LibCGI
--

------- structural markup

public function htmls_html( sequence text )
  return sprintf("<html>%s</html>\n", {text})
end function

public function htmls_head( sequence text )
  return sprintf("<head>%s</head>\n", {text})
end function

public function htmls_title( sequence text )
  return sprintf("<title>%s</title>\n", {text})
end function

public function htmls_body( sequence text, object bgcolor, object textcolor, object linkcolor, object background )
  sequence x  x = {}
  x &= "<body "
  if not equal(bgcolor, 0) then  x &= sprintf("bgcolor='%s' ", {bgcolor})  end if
  if not equal(textcolor, 0) then  x &= sprintf("textcolor='%s' ", {textcolor})  end if
  if not equal(linkcolor, 0) then  x &= sprintf("linkcolor='%s' ", {linkcolor})  end if
  if not equal(background, 0) then  x &= sprintf("background='%s' ", {background})  end if
  x &= sprintf(">%s</body>", {text})
  return x
end function



-------- basic formatting markup

public function html_head( sequence text, atom level )
  return sprintf("<h%d>%s</h%d>\n", {level, text, level})
end function

public function html_p( sequence text )
  return sprintf("<p>%s</p>\n", {text})
end function

public function html_pre( sequence text )
  return sprintf("<pre>%s</pre>\n", {text})
end function

public function html_center( sequence text )
  return sprintf("<center>%s</center>\n", {text})
end function

public function html_b( sequence text )
  return sprintf("<b>%s</b>", {text})
end function

public function html_i( sequence text )
  return sprintf("<i>%s</i>", {text})
end function

public function html_u( sequence text )
  return sprintf("<u>%s</u>", {text})
end function



------------ some more advanced markup

public function html_font( sequence text, object face, atom size, object color )
  sequence x  x = {}
  x &= "<font "
  if not equal(face, 0) then  x &= sprintf("face='%s' ", {face})  end if
  if not equal(size, 0) then  x &= sprintf("size='%s' ", {size})  end if
  if not equal(color, 0) then  x &= sprintf("color='%s' ", {color})  end if
  x &= sprintf(">%s</font>", {text})
  return x
end function

public function html_anchor( sequence text, object name, object href )
  sequence x  x = {}
  x &= "<a "
  if not equal(name, 0) then  x &= sprintf("name='%s' ", {name})  end if
  if not equal(href, 0) then  x &= sprintf("href='%s' ", {href})  end if
  x &= sprintf(">%s</a>", {text})
  return x
end function



----------- form elements

public function html_form( sequence text, object name, object enctype, object action, object method )
  sequence x  x = {}
  x &= "<form "
  if not equal(name, 0) then  x &= sprintf("name='%s' ", {name})  end if
  if not equal(enctype, 0) then  x &= sprintf("enctype='%s' ", {enctype})  end if
  if not equal(action, 0) then  x &= sprintf("action='%s' ", {action})  end if
  if not equal(method, 0) then  x &= sprintf("method='%s' ", {method})  end if
  x &= sprintf(">%s</form>", {text})
  return x
end function

public function html_input( object name, object iptype, object value, object size )
  sequence x  x = {}
  x &= "<input "
  if not equal(name, 0) then  x &= sprintf("name='%s' ", {name})  end if
  if not equal(iptype, 0) then  x &= sprintf("type='%s' ", {iptype})  end if
  if not equal(value, 0) then  x &= sprintf("value='%s' ", {value})  end if
  if not equal(size, 0) then  x &= sprintf("size='%s' ", {size})  end if
  x &= ">\n"
  return x
end function

public function html_textarea( sequence text, object name, object rows, object cols )
  sequence x  x = {}
  x &= "<textarea "
  if not equal(name, 0) then  x &= sprintf("name='%s' ", {name})  end if
  if not equal(rows, 0) then  x &= sprintf("rows='%s' ", {rows})  end if
  if not equal(cols, 0) then  x &= sprintf("cols='%s' ", {cols})  end if
  x &= sprintf(">%s</textarea>", {text})
  return x
end function


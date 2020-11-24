# WebClay

WebClay is a web application framework written in Euphoria. http://OpenEuphoria.org is written in Euphoria using WebClay.

## A simple WebClay program

### Overview

This program is a Hello World for the web. It presents a form to the user to enter the Greeting and Name. It then accepts the input, validates it and greets the user.

### ETML template

    <!-- greet.etml -->
    <html>
      <head><title>Greeter</title></head>
      <body>
        <% if @has_errors then %>
            <h1><%= sprintf("%d", length(@errors)) %> Validation Errors</h1>
            <div class="error_box">
                <ul>
                    <%
                        sequence errors = @errors
                        for i = 1 to length(errors) do
                            sequence error = errors[i]
                        %>
                            <li><b><%= error[1] %></b>: <%= error[2] %></li>
                        <% end for %>
                </ul>
            </div>
        <% end if %>

        <% if @greet_person %>
          <h1>Greeting</h1>
          <% for a = 1 to @times do %>
            <p><%= @greeting %>, <%= @name %>!</p>
          <% end for %>
        <% end if %>

        <h1>Greeter Form</h1>
        <form method="post" action="greet.ex?module=greet&action=greet">
          Name: <input type="text" name="name" /><br />
          Greeting: <input type="text" name="greeting" value="<%= @greeting %>" /><br />
          Times: <input type="text" name="times" value="<%= sprint(@times) %>" /><br />
          <input type="submit" />
        </form>
      </body>
    </html>

### WebClay Program

    -- greet.ex
    include webclay/webclay.e as wc
    include greet.etml as t_greet

    -- Allows web clay to provide default values and type conversion.
    -- This is not required, but many times makes things easier.

    sequence greeter_invars = {
        { wc:SEQUENCE, "name", "World" },
        { wc:SEQUENCE, "greeting", "Hello" },
        { wc:INTEGER, "times", 1 }
    }

    -- A handler gets any data that WebClay may have put into the template
    -- map (data) as well as all request data (post/get submissions)

    function greet_form(map data, map request)
        -- We are simply going to return the template w/o any data
        return { TEXT, t_greet:parse(data) }
    end function

    -- Registers a module/action handler. The first parameter is which function to
    -- call. The second is a validation function, in this case we are not using one.
    -- The third is a module identifier, which will be dispatched by WebClay. The
    -- fourth parameter is the action. The last parameter is the translation map
    -- that WebClay will use. So, a request for myprox.ex?module=greet&action=form
    -- will call the greet_form routine with no validation on the input data taking
    -- place.

    wc:add_handler(routine_id("greet_form"), -1, "greet", "form", greeter_invars)

    -- On the actual greeting, we are going to do some validation

    function validate_greeting(map request)
        -- Create a new errors sequence. The first and second parameters
        -- are the module/action to call if a validation error takes place.
        sequence errors = wc:new_errors("greet", "form")

        if length(map:get(request, "name")) = 0 then
            -- Add an error for the "name" field
            errors = wc:add_error(errors, "name", "Name cannot be empty")
        end if

        if length(map:get(request, "greeting")) = 0 then
            -- Add an error for the "greeting" field
            errors = wc:add_error(errors, "greeting", "Greeting cannot be empty")
        end if

        if equal(map:get(request, "greeting"), "Goodbye") then
            errors = wc:add_error(errors, "greeting", "Don't go! We are having too much fun!")
        end if

        return errors
    end function

    function do_greet(map data, map request)
        -- If we are this far, then we know our validation worked, so just fill
        -- in some values for the greeting.

        -- Copy the "name" and "greeting" from the request right over to the template
        map:copy(request, data)

        -- Tell the template to greet this person
        map:put(data, "greet_person", 1)

        return { TEXT, t_greet:generate(data) }
    end function
    wc:add_handler(routine_id("do_greet"), routine_id("validate_greeting"), "greet", "do_greet")

### Summary

So, the first time `greet.ex` is accessed via the web browser, they will be presented with a greeter form. Upon entering information into the form and pressing the submit button, WebClay will validate the data via the routine `validate_greeting`. If it fails, it will send the data and validation errors to the routine `greet_form`. If, however, the validation tests pass, then WebClay will call `do_greet` and the user get's greeted.

Now, this only touches on what can be done with WebClay and ETML. There are many helpers to make this whole process easier. This was just a basic example to give you a rough idea on how WebClay works.

## Getting WebClay

WebClay was originally hosted on BitBucket: http://bitbucket.org/jcowgar/webclay

You can read more about WebClay at http://jeremy.cowgar.com/webclay/
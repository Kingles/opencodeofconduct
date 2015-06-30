---
# Hey Jekyll, please transform this file.
---

class @Configure
  constructor: (@template, @element) ->
    @form = @element.querySelector("form")
    @snippet = @element.querySelector("#snippet")

    # Listen to form events to update the snippet
    @form.addEventListener "submit", @submit
    for input in @form.querySelectorAll("input")
      input.addEventListener "keypress", @keypress

    # If the URL has config variables, update the tempalate
    if data = @decode(window.location.hash.substr(1))
      @template.configure(data)

      # Fill out configuration form with values so it can be edited
      @form.elements.namedItem(key)?.value = value for key,value of data
      document.body.classList.add("configured")

  # Handle the keypress event with a throttle
  keypress: =>
    clearTimeout(@throttle) if @throttle
    @throttle = setTimeout(@submit, 250)

  # Handle the form submission event
  submit: (event) =>
    event?.preventDefault()

    # Bail if the form is not valid
    return unless @form.checkValidity()

    @update @data()
    document.body.classList.add("configuring")

  # Return the form data as an object
  data: ->
    data = {}
    for element in @form.elements
      data[element.name] = element.value if element.value.length
    data

  # Update the snippet and template
  update: (data) ->
    @template.configure(data)
    window.location.hash = @encode(data)

    snippet = @element.querySelector("#markdown-template").innerText.trim()
    snippet = snippet.replace("[URL]", window.location)
    @snippet.value = snippet
    @snippet.setAttribute("disabled", false)

  # Encode the configuration data
  encode: (data) ->
    # Base64 encode the data, escaping non-ascii characters.
    # https://developer.mozilla.org/en-US/docs/Web/API/WindowBase64/Base64_encoding_and_decoding#The_.22Unicode_Problem.22
    str = encodeURIComponent(JSON.stringify(data))
    escaped = str.replace /%([0-9A-F]{2})/g, (match, p1) -> String.fromCharCode('0x' + p1)
    btoa(escaped)

  # Decode the configuration data
  decode: (string) ->
    try
      JSON.parse(atob(string))

class Template
  constructor: (@element) ->

  configure: (data) ->
    # Make a backup copy so this can be run multiple times
    @original ?= @element.cloneNode(true)

    node = @original.cloneNode(true)

    placeholders = {}
    placeholders["[#{key.toUpperCase()}]"] = value for key, value of data

    for element in node.querySelectorAll("strong")
      for key, value of placeholders
        element.textContent = value if element.textContent == key

    @element.parentNode.replaceChild(node, @element)
    @element = node

template = new Template(element) if element = document.querySelector("#code-of-conduct")
new Configure(template, element) if element = document.getElementById("configure")

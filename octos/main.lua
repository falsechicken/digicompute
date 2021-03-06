local input = get_attr("input"):split(" ")
local bin   = get_userdata("bin")

if input[1] ~= "" then
  print(get_attr("input"), false)

  local binentry = bin[input[1]]

  if binentry then
    -- Remove first param
    table.remove(input, 1)

    local ok, res = fs.run(binentry.exec, input)

    if not ok then
      print("Error: "..res)
    end
  else
    print(input[1]..": command not found")
  end

  print(get_os("prefix"))

  -- Clear input
  set_input("")

  -- Refresh view
  refresh()
end

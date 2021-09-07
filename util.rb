def height_to_unix(height)
  height * 30 + 1598331600
end

def unix_to_height(unix)
  (unix - 1598331600) / 30
end

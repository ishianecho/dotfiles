local function jj_en(key, env)
  if key:release() then
    return 2
  end
  if key:repr() ~= "j" then
    return 2
  end
  local context = env.engine.context
  if context:is_composing() and context.input == "j" then
    context:clear()
    os.execute("fcitx5-remote -c >/dev/null 2>&1 &")
    return 1
  end
  return 2
end

return jj_en

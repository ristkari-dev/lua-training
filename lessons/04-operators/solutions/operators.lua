local M = {}

function M.page_label(items, per_page)
  local pages = items // per_page + (items % per_page == 0 and 0 or 1)
  return pages .. " page" .. (pages == 1 and "" or "s")
end

return M

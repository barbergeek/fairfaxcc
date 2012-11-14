Function slugToGraphicName(slug as string) as string
	if slug = "" then
		return "fairfax"
	elseif slug = "red" then
		return "revealedinred"
	else
  	reg = CreateObject("roRegex", "-", "i")
		return reg.ReplaceAll(slug, "")
	end if
End Function

Function getShowCategorySlug(show as object) as string
	slug = "fairfax"
	for each category in show.categories
		if category.parent = 8 slug = category.slug
	next
	return slug
End Function

Function getShowCategoryTitle(show as object) as string
	title = ""
	for each category in show.categories
		if category.parent = 8 title = category.title
	next
	return title
End Function
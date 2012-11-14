'**********************************************************
'**  Video Player Example Application - Show Feed 
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************

'******************************************************
'** Set up the show feed connection object
'** This feed provides the detailed list of shows for
'** each subcategory (categoryLeaf) in the category
'** category feed. Given a category leaf node for the
'** desired show list, we'll hit the url and get the
'** results.     
'******************************************************

Function InitShowFeedConnection(category As String) As Object

    if validateParam(category, "roString", "initShowFeedConnection") = false return invalid 

    conn = CreateObject("roAssociativeArray")

    conn.UrlPrefix   = "http://www.fairfaxvideos.com/api"
    conn.UrlShowFeed = conn.UrlPrefix + "/get_category_posts/?custom_fields=mp4,mp3&slug="+category

    conn.Timer = CreateObject("roTimespan")

    conn.LoadShowFeed    = load_show_feed
    conn.ParseShowFeed   = parse_show_feed
    conn.InitFeedItem    = init_show_feed_item

    print "created feed connection for " + conn.UrlShowFeed
    return conn

End Function


'******************************************************
'Initialize a new feed object
'******************************************************
Function newShowFeed() As Object

    o = CreateObject("roArray", 100, true)
    return o

End Function


'***********************************************************
' Initialize a ShowFeedItem. This sets the default values
' for everything.  The data in the actual feed is sometimes
' sparse, so these will be the default values unless they
' are overridden while parsing the actual game data
'***********************************************************
Function init_show_feed_item() As Object
    o = CreateObject("roAssociativeArray")

    o.ContentId        = ""
    o.Title            = ""
    o.ContentType      = ""
    o.ContentQuality   = ""
    o.Synopsis         = ""
    o.Genre            = ""
    o.Runtime          = ""
    o.StreamQualities  = CreateObject("roArray", 5, true) 
    o.StreamBitrates   = CreateObject("roArray", 5, true)
    o.StreamUrls       = CreateObject("roArray", 5, true)

    return o
End Function


'*************************************************************
'** Grab and load a show detail feed. The url we are fetching 
'** is specified as part of the category provided during 
'** initialization. This feed provides a list of all shows
'** with details for the given category feed.
'*********************************************************
Function load_show_feed(conn As Object) As Dynamic

    if validateParam(conn, "roAssociativeArray", "load_show_feed") = false return invalid 

    print "url: " + conn.UrlShowFeed 
    http = NewHttp(conn.UrlShowFeed)

    m.Timer.Mark()
    rsp = http.GetToStringWithRetry()
    print "Request Time: " + itostr(m.Timer.TotalMilliseconds())

		response = ParseJson(rsp)
		
    feed = newShowFeed()
    m.Timer.Mark()
    m.ParseShowFeed(response.posts, feed)
    print "Show Feed Parse Took : " + itostr(m.Timer.TotalMilliseconds())

    return feed

End Function


'**************************************************************************
'**************************************************************************
Function parse_show_feed(posts As Object, feed As Object) As Void

    showCount = 0

    for each curShow in posts

        item = init_show_feed_item()

				' Find the category slug for this show and transform into the graphic file name
				showCategorySlug = getShowCategorySlug(curShow)
				graphic = slugToGraphicName(showCategorySlug)
				
        'fetch all values from the xml for the current show
        item.hdImg            = "http://www.fairfaxvideos.com/wp-content/videos/"+graphic+"-tn.jpg" 'curShow@hdImg 
        item.sdImg            = "http://www.fairfaxvideos.com/wp-content/videos/"+graphic+"-tn.jpg" ' curShow@sdImg 
        item.ContentId        = curShow.slug 
        item.Title            = curShow.title 
				'item.TitleSeason			= getShowCategoryTitle(curShow)
        item.Description      = curShow.content 
        item.ContentType      = "episode"
        item.ContentQuality   = "" 'curShow.contentQuality.GetText())
        item.Synopsis         = curShow.content ' curShow.synopsis.GetText())
        item.Genre            = curShow.author.name ' curShow.genres.GetText())
        item.Runtime          = "" ' curShow.runtime.GetText())
        item.HDBifUrl         = "" ' curShow.hdBifUrl.GetText())
        item.SDBifUrl         = "" ' curShow.sdBifUrl.GetText())
        
				item.ReleaseDate = left(curShow.date,10)
				
        'map xml attributes into screen specific variables
        item.ShortDescriptionLine1 = item.Title 
        item.ShortDescriptionLine2 = left(curShow.date,10) ' use the sermon date
        item.HDPosterUrl           = item.hdImg
        item.SDPosterUrl           = item.sdImg

        'Set Default screen values for items not in feed
        item.HDBranded = false
        item.IsHD = false
        item.StarRating = "90"

        'media may be at multiple bitrates, so parse an build arrays
        'for idx = 0 to 4
        '    e = curShow.media[idx]
        '    if e  <> invalid then
        '        item.StreamBitrates.Push(strtoi(validstr(e.streamBitrate.GetText())))
        '        item.StreamQualities.Push(validstr(e.streamQuality.GetText()))
        '        item.StreamUrls.Push(validstr(e.streamUrl.GetText()))
        '    endif
        'next idx
				if curShow.custom_fields.mp4 = invalid then
						item.StreamUrls.Push("http://www.fairfaxvideos.com/wp-content/videos/"+curShow.custom_fields.mp3[0])
						item.StreamFormat = "mp3"
						item.Categories = "Audio"
        	else
						item.StreamUrls.Push("http://www.fairfaxvideos.com/wp-content/videos/"+curShow.custom_fields.mp4[0])
		        item.StreamFormat =  "mp4"
						item.Categories = "Video"
				endif
				item.StreamQualities.Push(false)
				item.StreamBitrates.Push(0)

        item.Length = 45*60 'strtoi(item.Runtime)
        'item.Categories = CreateObject("roArray", 5, true)
        'item.Categories.Push("[Category]")
        'item.Actors = CreateObject("roArray", 5, true)
        'item.Actors.Push(curShow.author.name)

				item.Actors = curShow.author.name
        item.Description = item.Synopsis

        showCount = showCount + 1
        feed.Push(item)

        skipitem:

    next

End Function

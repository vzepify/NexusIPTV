sub init()
    m.loginGroup = m.top.findNode("loginGroup")
    m.homeGroup = m.top.findNode("homeGroup")
    m.playerGroup = m.top.findNode("playerGroup")

    m.serverBox = m.top.findNode("serverBox")
    m.userBox = m.top.findNode("userBox")
    m.passBox = m.top.findNode("passBox")
    m.loginButton = m.top.findNode("loginButton")
    m.remoteButton = m.top.findNode("remoteButton")
    m.syncButton = m.top.findNode("syncButton")
    m.remoteBox = m.top.findNode("remoteBox")
    m.portalApiBox = m.top.findNode("portalApiBox")
    m.deviceCodeValue = m.top.findNode("deviceCodeValue")
    m.loginStatus = m.top.findNode("loginStatus")

    m.navList = m.top.findNode("navList")
    m.contentList = m.top.findNode("contentList")
    m.panelTitle = m.top.findNode("panelTitle")
    m.emptyLabel = m.top.findNode("emptyLabel")
    m.accountLabel = m.top.findNode("accountLabel")
    m.video = m.top.findNode("video")
    m.playerTitle = m.top.findNode("playerTitle")
    m.playerError = m.top.findNode("playerError")

    m.apiTask = m.top.createChild("ApiTask")
    m.apiTask.observeField("result", "onApiResult")
    m.apiTask.observeField("error", "onApiError")

    m.navList.observeField("itemSelected", "onNavSelected")
    m.contentList.observeField("itemSelected", "onContentSelected")
    m.loginButton.observeField("buttonSelected", "onLogin")
    m.remoteButton.observeField("buttonSelected", "onRemotePlaylist")
    m.syncButton.observeField("buttonSelected", "onPortalSync")
    m.video.observeField("state", "onVideoState")

    LoadSavedCredentials()
    EnsureDeviceCode()
    SetupLoginFocus()
end sub

sub SetupLoginFocus()
    if m.serverBox.text = "" then
        m.serverBox.setFocus(true)
    else
        m.loginButton.setFocus(true)
    end if
end sub

sub LoadSavedCredentials()
    sec = CreateObject("roRegistrySection", "NexusIPTV")
    if sec.Exists("server") then m.serverBox.text = sec.Read("server")
    if sec.Exists("username") then m.userBox.text = sec.Read("username")
    if sec.Exists("password") then m.passBox.text = sec.Read("password")
    if sec.Exists("remoteUrl") then m.remoteBox.text = sec.Read("remoteUrl")
    if sec.Exists("portalApi") then m.portalApiBox.text = sec.Read("portalApi")
    EnsureDeviceCode()
end sub

sub EnsureDeviceCode()
    sec = CreateObject("roRegistrySection", "NexusIPTV")
    code = ""
    if sec.Exists("deviceCode") then code = Trim(sec.Read("deviceCode"))
    if code = "" then
        di = CreateObject("roDeviceInfo")
        raw = ""
        id = di.GetChannelClientId()
        if id <> invalid then raw = Replace(id, "-", "")
        if Len(raw) >= 8 then
            code = UCase(Right(raw, 8))
        else
            dt = CreateObject("roDateTime")
            code = Right("00000000" + dt.AsSeconds().ToStr(), 8)
        end if
        sec.Write("deviceCode", code)
        sec.Flush()
    end if
    m.deviceCodeValue.text = code
end sub

sub SaveCredentials()
    sec = CreateObject("roRegistrySection", "NexusIPTV")
    sec.Write("server", Trim(m.serverBox.text))
    sec.Write("username", Trim(m.userBox.text))
    sec.Write("password", m.passBox.text)
    if m.portalApiBox.text <> invalid then sec.Write("portalApi", Trim(m.portalApiBox.text))
    sec.Flush()
end sub

sub onPortalSync()
    api = Trim(m.portalApiBox.text)
    if api = "" then
        m.loginStatus.text = "Enter your Portal API URL first."
        return
    end if
    if Left(LCase(api), 8) <> "https://" and Left(LCase(api), 7) <> "http://" then
        api = "https://" + api
        m.portalApiBox.text = api
    end if
    sec = CreateObject("roRegistrySection", "NexusIPTV")
    sec.Write("portalApi", api)
    sec.Flush()
    m.loginStatus.text = "Checking portal for playlists..."
    StartPortalSync(api)
end sub

sub StartPortalSync(api as string)
    m.apiTask.control = "stop"
    m.apiTask.mode = "portal"
    m.apiTask.remoteUrl = StripSlash(api) + "/api/device/" + UrlPart(m.deviceCodeValue.text) + "/playlists"
    m.apiTask.baseUrl = ""
    m.apiTask.username = ""
    m.apiTask.password = ""
    m.apiTask.action = ""
    m.apiTask.extraQuery = ""
    m.apiTask.requestId = "portal_sync"
    m.apiTask.control = "run"
end sub

sub onRemotePlaylist()
    url = Trim(m.remoteBox.text)
    if url = "" then
        m.loginStatus.text = "Enter a playlist JSON URL."
        return
    end if
    if Left(LCase(url), 8) <> "https://" then
        m.loginStatus.text = "Use an HTTPS playlist URL."
        return
    end if

    sec = CreateObject("roRegistrySection", "NexusIPTV")
    sec.Write("remoteUrl", url)
    sec.Flush()

    m.loginStatus.text = "Loading playlist..."
    StartRemoteApi(url)
end sub

sub StartRemoteApi(url as string)
    m.apiTask.control = "stop"
    m.apiTask.mode = "remote"
    m.apiTask.remoteUrl = url
    m.apiTask.baseUrl = ""
    m.apiTask.username = ""
    m.apiTask.password = ""
    m.apiTask.action = ""
    m.apiTask.extraQuery = ""
    m.apiTask.requestId = "remote_playlist"
    m.apiTask.control = "run"
end sub

sub ConnectPlaylist(info as dynamic)
    if type(info) <> "roAssociativeArray" then
        m.loginStatus.text = "Playlist entry is not valid JSON."
        return
    end if

    server = ToText(info.server)
    if server = "" then server = ToText(info.url)
    user = ToText(info.username)
    pass = ToText(info.password)

    if server = "" or user = "" or pass = "" then
        m.loginStatus.text = "Playlist must contain server, username, and password."
        return
    end if

    m.serverBox.text = server
    m.userBox.text = user
    m.passBox.text = pass
    SaveCredentials()
    m.loginStatus.text = "Connecting to " + ToText(info.name)
    StartApi("", "", "login")
end sub

sub onLogin()
    server = Trim(m.serverBox.text)
    if Left(LCase(server), 7) <> "http://" and Left(LCase(server), 8) <> "https://" then
        server = "http://" + server
        m.serverBox.text = server
    end if
    user = Trim(m.userBox.text)
    pass = m.passBox.text

    if server = "" or user = "" or pass = "" then
        m.loginStatus.text = "Enter server URL, username, and password."
        return
    end if

    m.loginStatus.text = "Connecting..."
    SaveCredentials()
    StartApi("", "", "login")
end sub

sub StartApi(action as string, extraQuery as string, requestId as string)
    m.apiTask.control = "stop"
    m.apiTask.mode = "xtream"
    m.apiTask.remoteUrl = ""
    m.apiTask.baseUrl = Trim(m.serverBox.text)
    m.apiTask.username = Trim(m.userBox.text)
    m.apiTask.password = m.passBox.text
    m.apiTask.action = action
    m.apiTask.extraQuery = extraQuery
    m.apiTask.requestId = requestId
    m.apiTask.control = "run"
end sub

sub onApiError()
    err = m.apiTask.error
    if err <> invalid and err <> "" then
        if m.loginGroup.visible then
            m.loginStatus.text = err
        else
            m.emptyLabel.text = err
        end if
    end if
end sub

sub onApiResult()
    r = m.apiTask.result
    if r = invalid then return

    data = r.data
    req = m.apiTask.requestId

    if req = "portal_sync" then
        playlists = data
        if type(playlists) <> "roArray" or playlists.Count() = 0 then
            m.loginStatus.text = "No playlist has been added for device " + m.deviceCodeValue.text + "."
            return
        end if
        ConnectPlaylist(playlists[0])
        return
    end if

    if req = "remote_playlist" then
        playlist = invalid
        if type(data) = "roAssociativeArray" and data.playlists <> invalid then
            if type(data.playlists) = "roArray" and data.playlists.Count() > 0 then
                playlist = data.playlists[0]
            else
                m.loginStatus.text = "The playlist contains no entries."
                return
            end if
        else if type(data) = "roAssociativeArray" then
            playlist = data
        else if type(data) = "roArray" then
            if data.Count() > 0 then playlist = data[0]
        end if

        if playlist = invalid then
            m.loginStatus.text = "Unsupported playlist JSON format."
            return
        end if
        ConnectPlaylist(playlist)
        return
    end if

    if req = "login" then
        if type(data) <> "roAssociativeArray" or data.user_info = invalid then
            m.loginStatus.text = "Invalid response from server."
            return
        end if
        if data.user_info.auth <> 1 then
            m.loginStatus.text = "Login failed. Check your credentials."
            return
        end if

        m.loginStatus.text = ""
        m.loginGroup.visible = false
        m.homeGroup.visible = true
        m.accountLabel.text = "Logged in as " + Trim(m.userBox.text)
        BuildNavigation()
        m.navList.setFocus(true)
        return
    end if

    HandleData(req, data)
end sub

sub BuildNavigation()
    root = CreateObject("roSGNode", "ContentNode")
    for each name in ["Live TV", "Movies", "Series", "Favorites", "Settings"]
        item = root.CreateChild("ContentNode")
        item.title = name
    end for
    m.navList.content = root
    m.navList.jumpToItem = 0
    ShowWelcome()
end sub

sub onNavSelected()
    idx = m.navList.itemSelected
    if idx = invalid then return

    m.emptyLabel.text = "Loading..."
    m.contentList.content = invalid

    if idx = 0 then
        m.panelTitle.text = "Live TV"
        StartApi("get_live_categories", "", "live_categories")
    else if idx = 1 then
        m.panelTitle.text = "Movies"
        StartApi("get_vod_categories", "", "vod_categories")
    else if idx = 2 then
        m.panelTitle.text = "Series"
        StartApi("get_series_categories", "", "series_categories")
    else if idx = 3 then
        LoadFavorites()
    else
        ShowSettings()
    end if
end sub

sub HandleData(req as string, data as dynamic)
    m.emptyLabel.text = ""

    if req = "live_categories" then
        PopulateCategories(data, "live_streams")
    else if req = "vod_categories" then
        PopulateCategories(data, "vod_streams")
    else if req = "series_categories" then
        PopulateCategories(data, "series")
    else if req = "live_streams" then
        PopulatePlayable(data, "live")
    else if req = "vod_streams" then
        PopulatePlayable(data, "vod")
    else if req = "series" then
        PopulatePlayable(data, "series")
    else if req = "series_info" then
        PopulateSeriesEpisodes(data)
    end if
end sub

sub PopulateSeriesEpisodes(data as dynamic)
    root = CreateObject("roSGNode", "ContentNode")
    if type(data) <> "roAssociativeArray" then
        m.emptyLabel.text = "No episode data returned."
        return
    end if

    episodes = invalid
    if data.episodes <> invalid then episodes = data.episodes
    if data.episodes = invalid and data.series_info <> invalid and data.series_info.episodes <> invalid then episodes = data.series_info.episodes

    if episodes = invalid then
        m.emptyLabel.text = "No episodes returned."
        return
    end if

    for each seasonKey in episodes
        seasonEpisodes = episodes[seasonKey]
        if type(seasonEpisodes) = "roArray" then
            for each ep in seasonEpisodes
                item = root.CreateChild("ContentNode")
                title = "S" + ToText(ep.season) + " E" + ToText(ep.episode_num) + " - " + ToText(ep.title)
                item.title = title
                item.addFields({mediaType: "episode", episodeId: ToText(ep.id), titleText: title, containerExtension: ToText(ep.container_extension)})
            end for
        end if
    end for

    if root.GetChildCount() = 0 then
        m.emptyLabel.text = "No episodes returned."
        return
    end if

    m.contentList.content = root
    m.currentBrowseType = "episodes"
    m.contentList.setFocus(true)
end sub

sub PopulateCategories(data as dynamic, nextType as string)
    root = CreateObject("roSGNode", "ContentNode")
    if type(data) <> "roArray" then
        m.emptyLabel.text = "No categories returned."
        return
    end if

    for each cat in data
        if cat <> invalid
            item = root.CreateChild("ContentNode")
            item.title = ToText(cat.category_name)
            item.description = ToText(cat.category_id)
        end if
    end for

    m.contentList.content = root
    m.currentBrowseType = nextType
    m.contentList.setFocus(true)
end sub

sub onContentSelected()
    idx = m.contentList.itemSelected
    if idx = invalid then return
    item = m.contentList.content.GetChild(idx)
    if item = invalid then return

    if m.currentBrowseType = "live_streams" then
        catId = item.description
        StartApi("get_live_streams", "category_id=" + EncodeQuery(catId), "live_streams")
    else if m.currentBrowseType = "vod_streams" then
        catId = item.description
        StartApi("get_vod_streams", "category_id=" + EncodeQuery(catId), "vod_streams")
    else if m.currentBrowseType = "series" then
        catId = item.description
        StartApi("get_series", "category_id=" + EncodeQuery(catId), "series")
    else
        PlaySelection(item)
    end if
end sub

sub PopulatePlayable(data as dynamic, mediaType as string)
    root = CreateObject("roSGNode", "ContentNode")
    if type(data) <> "roArray" then
        m.emptyLabel.text = "No streams returned."
        return
    end if

    for each entry in data
        item = root.CreateChild("ContentNode")
        if mediaType = "live" then
            item.title = ToText(entry.name)
            item.description = ToText(entry.stream_id)
            item.HDPosterUrl = ToText(entry.stream_icon)
            item.addFields({mediaType: "live", streamId: ToText(entry.stream_id), name: ToText(entry.name)})
        else if mediaType = "vod" then
            item.title = ToText(entry.name)
            item.description = ToText(entry.stream_id)
            item.HDPosterUrl = ToText(entry.stream_icon)
            item.addFields({mediaType: "vod", streamId: ToText(entry.stream_id), containerExtension: ToText(entry.container_extension), name: ToText(entry.name)})
        else
            item.title = ToText(entry.name)
            item.description = ToText(entry.series_id)
            item.HDPosterUrl = ToText(entry.cover)
            item.addFields({mediaType: "series", seriesId: ToText(entry.series_id), name: ToText(entry.name)})
        end if
    end for

    m.contentList.content = root
    m.contentList.setFocus(true)
end sub

sub PlaySelection(item as object)
    if item = invalid then return
    mediaType = item.mediaType
    if mediaType = invalid or mediaType = "" then return

    if mediaType = "live" then
        url = BuildLiveUrl(item.streamId)
        StartPlayback(url, item.name)
    else if mediaType = "vod" then
        ext = item.containerExtension
        if ext = invalid or ext = "" then ext = "mp4"
        url = BuildVodUrl(item.streamId, ext)
        StartPlayback(url, item.name)
    else if mediaType = "series" then
        StartApi("get_series_info", "series_id=" + EncodeQuery(item.seriesId), "series_info")
    else if mediaType = "episode" then
        ext = item.containerExtension
        if ext = invalid or ext = "" then ext = "mp4"
        url = StripSlash(Trim(m.serverBox.text)) + "/series/" + UrlPart(m.userBox.text) + "/" + UrlPart(m.passBox.text) + "/" + item.episodeId + "." + ext
        StartPlayback(url, item.titleText)
    end if
end sub

sub StartPlayback(url as string, title as string)
    m.homeGroup.visible = false
    m.playerGroup.visible = true
    m.playerTitle.text = title
    m.playerError.text = ""

    content = CreateObject("roSGNode", "ContentNode")
    content.url = url
    content.title = title
    content.streamformat = "hls"
    m.video.content = content
    m.video.setFocus(true)
    m.video.control = "play"
end sub

sub onVideoState()
    state = m.video.state
    if state = "error" then
        m.playerError.text = "Playback failed. The provider may require a different stream format."
    end if
end sub

function BuildLiveUrl(streamId as string) as string
    return StripSlash(Trim(m.serverBox.text)) + "/live/" + UrlPart(m.userBox.text) + "/" + UrlPart(m.passBox.text) + "/" + streamId + ".m3u8"
end function

function BuildVodUrl(streamId as string, ext as string) as string
    return StripSlash(Trim(m.serverBox.text)) + "/movie/" + UrlPart(m.userBox.text) + "/" + UrlPart(m.passBox.text) + "/" + streamId + "." + ext
end function

sub ShowWelcome()
    m.panelTitle.text = "Welcome"
    m.emptyLabel.text = "Choose Live TV, Movies, or Series. Your Xtream account is ready."
end sub

sub ShowSettings()
    m.panelTitle.text = "Settings"
    m.emptyLabel.text = "Back: returns to the previous screen\nOK: choose a section\nSaved credentials can be changed by logging in again."
end sub

sub LoadFavorites()
    m.panelTitle.text = "Favorites"
    m.emptyLabel.text = "Favorites are ready for the next playback pass."
end sub

sub onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if m.playerGroup.visible then
        if key = "back" then
            m.video.control = "stop"
            m.playerGroup.visible = false
            m.homeGroup.visible = true
            m.contentList.setFocus(true)
            return true
        end if
    else if m.homeGroup.visible then
        if key = "back" then
            m.navList.setFocus(true)
            return true
        end if
    end if
    return false
end sub

function StripSlash(value as string) as string
    out = value
    while Len(out) > 0 and Right(out, 1) = "/"
        out = Left(out, Len(out) - 1)
    end while
    return out
end function

function UrlPart(value as string) as string
    xfer = CreateObject("roUrlTransfer")
    return xfer.Escape(value)
end function

function EncodeQuery(value as string) as string
    return UrlPart(value)
end function

function ToText(v as dynamic) as string
    if v = invalid then return ""
    return v.toStr()
end function

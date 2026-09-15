sub init()
    m.top.functionName = "run"
end sub

sub run()
    m.top.error = ""
    m.top.result = invalid

    xfer = CreateObject("roUrlTransfer")
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.InitClientCertificates()
    xfer.SetRequest("User-Agent", "NexusIPTV-Roku/1.1")

    if LCase(Trim(m.top.mode)) = "portal" then
        url = Trim(m.top.remoteUrl)
        if url = "" then
            m.top.error = "Portal URL is required."
            return
        end if
        xfer.SetUrl(url)
        raw = xfer.GetToString()
        if raw = invalid or raw = "" then
            m.top.error = "Portal returned no data."
            return
        end if
        parsed = ParseJson(raw)
        if parsed = invalid then
            m.top.error = "Portal returned invalid JSON."
            return
        end if
        m.top.result = { data: parsed }
        return
    end if

    if LCase(Trim(m.top.mode)) = "remote" then
        url = Trim(m.top.remoteUrl)
        if url = "" then
            m.top.error = "Playlist URL is required."
            return
        end if
        xfer.SetUrl(url)
        raw = xfer.GetToString()
        if raw = invalid or raw = "" then
            m.top.error = "The playlist URL returned no data."
            return
        end if
        parsed = ParseJson(raw)
        if parsed = invalid then
            m.top.error = "Playlist URL must return valid JSON."
            return
        end if
        m.top.result = { data: parsed }
        return
    end if

    base = Trim(m.top.baseUrl)
    base = StripTrailingSlash(base)
    if base = "" then
        m.top.error = "Server URL is required."
        return
    end if

    url = base + "/player_api.php?username=" + UrlEncode(m.top.username) + "&password=" + UrlEncode(m.top.password)
    if Trim(m.top.action) <> "" then
        url = url + "&action=" + UrlEncode(m.top.action)
    end if
    if Trim(m.top.extraQuery) <> "" then
        url = url + "&" + m.top.extraQuery
    end if

    xfer.SetUrl(url)

    raw = xfer.GetToString()
    if raw = invalid or raw = "" then
        m.top.error = "The IPTV server returned no data."
        return
    end if

    parsed = ParseJson(raw)
    if parsed = invalid then
        m.top.error = "The IPTV server returned invalid JSON."
        return
    end if

    result = { data: parsed }
    m.top.result = result
end sub

function StripTrailingSlash(value as string) as string
    out = value
    while Len(out) > 0 and Right(out, 1) = "/"
        out = Left(out, Len(out) - 1)
    end while
    return out
end function

function UrlEncode(value as string) as string
    xfer = CreateObject("roUrlTransfer")
    return xfer.Escape(value)
end function

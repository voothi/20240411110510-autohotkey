; Own one asynchronous, read-only preference request until startup resolves.
class DeskStartup {
    __New(host, port, token, timeoutMs, pollMs, onReady := 0) {
        if (timeoutMs < 100 || pollMs < 10 || pollMs > timeoutMs)
            throw ValueError("Invalid controller readiness timing")
        this.url := "http://" host ":" port "/api/v1/config"
        this.token := token
        this.timeoutMs := timeoutMs
        this.pollMs := pollMs
        this.phase := "stopped"
        this.request := 0
        this.timer := 0
        this.readyTimer := 0
        this.onReady := onReady
    }

    Start() {
        this.Stop()
        this.timer := ObjBindMethod(this, "Poll")
        this.phase := "waiting"
        this.deadline := DllCall("GetTickCount64", "UInt64") + this.timeoutMs
        this.Project("Waiting for committed preferences")
        SetTimer(this.timer, this.pollMs)
        this.Poll()
    }

    Stop() {
        this.phase := "stopped"
        if IsObject(this.timer)
            SetTimer(this.timer, 0)
        if IsObject(this.readyTimer)
            SetTimer(this.readyTimer, 0)
        this.timer := 0
        this.readyTimer := 0
        this.AbortRequest()
    }

    AbortRequest() {
        request := this.request
        this.request := 0
        if !IsObject(request)
            return
        try request.Abort()
        catch as err
            OutputDebug("Desk startup request cancellation: " err.Message)
    }

    Poll() {
        ; No blocking Send/Wait: protect the state/projection from timer interruption.
        prior := A_IsCritical
        Critical
        try this.PollCurrent()
        finally Critical(prior ? prior : "Off")
    }

    PollCurrent() {
        if this.phase != "waiting"
            return
        if DllCall("GetTickCount64", "UInt64") >= this.deadline {
            this.Fail("Preferences unavailable (startup deadline)")
            return
        }
        if !IsObject(this.request) {
            try {
                this.BeginRequest()
            } catch as err {
                this.AbortRequest()
            }
            return
        }
        try complete := this.request.WaitForResponse(0)
        catch as err {
            ; Connection refusal during controller boot is transient until deadline.
            this.AbortRequest()
            return
        }
        if complete
            this.Receive()
    }

    BeginRequest() {
        request := ComObject("WinHttp.WinHttpRequest.5.1")
        this.request := request
        request.Open("GET", this.url, true)
        request.SetTimeouts(500, 500, 1000, 1000)
        if this.token != ""
            request.SetRequestHeader("X-API-Token", this.token)
        request.Send()
    }

    Receive() {
        request := this.request
        this.request := 0
        if request.Status == 503
            return
        if request.Status != 200 {
            this.Fail("Preferences unavailable (HTTP " request.Status ")")
            return
        }
        if !LoadCommittedPreferences(request.ResponseText) {
            this.Fail("Preferences unavailable (invalid snapshot)")
            return
        }
        SetTimer(this.timer, 0)
        this.timer := 0
        try {
            this.Project("Running")
            this.phase := "ready"
            if IsObject(this.onReady) {
                this.readyTimer := ObjBindMethod(this, "NotifyReady")
                SetTimer(this.readyTimer, -1)
            }
        } catch as err {
            this.Fail("Tray projection failed")
        }
    }

    Fail(message) {
        this.Stop()
        this.phase := "failed"
        this.Project(message)
    }

    NotifyReady() {
        this.readyTimer := 0
        if this.phase == "ready"
            this.onReady.Call()
    }

    Project(message) {
        global G_ServerStatus
        G_ServerStatus := message
        UpdateTrayMenu()
        UpdateTrayIcon()
    }
}

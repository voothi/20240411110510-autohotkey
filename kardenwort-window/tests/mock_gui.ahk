#Requires AutoHotkey v2.0

class MockControl {
    Enabled := false
    Visible := false
    Text := ""
    Move(x?, y?, w?, h?) => 0
    Redraw() => 0
}

class MockGui {
    FsmState := ""
    FsmMemory := Map()
    ZID := "20260701120000"
    Lang := "en"
    TsvPath := "dummy.tsv"
    SourceText := "mock source text"
    TextMode := "single"
    StatusLog := []
    selectableTextMode := false

    SaveBtn := MockControl()
    UpdateBtn := MockControl()
    SendBtn := MockControl()
    DeleteBtn := MockControl()
    ReprocBtn := MockControl()
    RetextBtn := MockControl()
    PointerBtn := MockControl()
    StatusTxt := MockControl()

    GetClientPos(x?, y?, &w := 800, &h := 600) => 0
    Destroy() => 0
}

MakeMockGui() {
    g := MockGui()
    FsmInit(g)
    return g
}

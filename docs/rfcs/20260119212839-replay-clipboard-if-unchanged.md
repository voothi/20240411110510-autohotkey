20260119212839

# Replay Clipboard if Unchanged

## Request
Make it so in anki-tts-cli that if the clipboard is not changed, it will be played again without having to re-select the last substring to replay it after it stopped being highlighted just after the first play.

## Implementation Details
Modified `tts/tts.ahk` to handle `ClipWait` timeout differently.
Previously, if `ClipWait` timed out (indicating no new text selection copy), the function would simply restore the old clipboard and return.
Now, if `ClipWait` times out (timeout reduced to 0.5s for responsiveness), the script will restore the old clipboard AND execute the TTS script with that restored content, effectively replaying the last copied text.

#Requires AutoHotkey v2.0

/**
 * Encodes a string into Base64 (UTF-8 binary representation).
 * @param {String} text - The cleartext string.
 * @returns {String} The Base64 encoded string.
 */
B64Encode(text) {
    if (text == "")
        return ""
    
    len := StrPut(text, "UTF-8") - 1
    if (len <= 0)
        return ""
    
    buf := Buffer(len)
    StrPut(text, buf, "UTF-8")
    
    ; CRYPT_STRING_BASE64 = 0x01
    ; CRYPT_STRING_NOCRLF = 0x40000000
    flags := 0x40000001
    size := 0
    DllCall("Crypt32\CryptBinaryToStringW", "Ptr", buf, "UInt", len, "UInt", flags, "Ptr", 0, "UInt*", &size)
    
    outBuf := Buffer(size * 2)
    DllCall("Crypt32\CryptBinaryToStringW", "Ptr", buf, "UInt", len, "UInt", flags, "Ptr", outBuf, "UInt*", &size)
    
    return StrGet(outBuf, "UTF-16")
}

/**
 * Decodes a Base64 string back to a UTF-8 string.
 * @param {String} str - The Base64 encoded string.
 * @returns {String} The decoded cleartext string.
 */
B64Decode(str) {
    if (str == "")
        return ""
    
    ; CRYPT_STRING_BASE64 = 0x01
    flags := 0x01
    size := 0
    DllCall("Crypt32\CryptStringToBinaryW", "Str", str, "UInt", 0, "UInt", flags, "Ptr", 0, "UInt*", &size, "Ptr", 0, "Ptr", 0)
    
    buf := Buffer(size)
    DllCall("Crypt32\CryptStringToBinaryW", "Str", str, "UInt", 0, "UInt", flags, "Ptr", buf, "UInt*", &size, "Ptr", 0, "Ptr", 0)
    
    return StrGet(buf, size, "UTF-8")
}

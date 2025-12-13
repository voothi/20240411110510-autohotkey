#Requires AutoHotkey v2.0

class Security {
    /**
     * Obfuscates text using XOR encryption with a salt, then Base64 encodes it.
     * @param {String} text - The cleartext string to obfuscate.
     * @param {String} salt - The salt string to use for XOR key.
     * @returns {String} The obfuscated string.
     */
    static Obfuscate(text, salt) {
        if (text == "")
            return ""
        if (salt == "")
            salt := "default_salt" ; Fallback if no salt provided, though discouraged

        ; Convert text to UTF-8 buffer
        len := StrPut(text, "UTF-8") - 1
        if (len <= 0)
            return ""

        buf := Buffer(len)
        StrPut(text, buf, "UTF-8")

        ; Prepare Salt buffer
        saltLen := StrPut(salt, "UTF-8") - 1
        saltBuf := Buffer(saltLen)
        StrPut(salt, saltBuf, "UTF-8")

        ; XOR
        loop len {
            byte := NumGet(buf, A_Index - 1, "UChar")
            saltByte := NumGet(saltBuf, Mod(A_Index - 1, saltLen), "UChar")
            NumPut("UChar", byte ^ saltByte, buf, A_Index - 1)
        }

        ; Base64 Encode
        return this.Base64Encode(buf, len)
    }

    /**
     * Deobfuscates text by Base64 decoding and then XOR decryption with a salt.
     * @param {String} text - The obfuscated string.
     * @param {String} salt - The salt string used for obfuscation.
     * @returns {String} The original cleartext string.
     */
    static Deobfuscate(text, salt) {
        if (text == "")
            return ""
        if (salt == "")
            salt := "default_salt"

        ; Base64 Decode
        len := 0
        buf := this.Base64Decode(text, &len)
        if (len == 0)
            return ""

        ; Prepare Salt buffer
        saltLen := StrPut(salt, "UTF-8") - 1
        saltBuf := Buffer(saltLen)
        StrPut(salt, saltBuf, "UTF-8")

        ; XOR
        loop len {
            byte := NumGet(buf, A_Index - 1, "UChar")
            saltByte := NumGet(saltBuf, Mod(A_Index - 1, saltLen), "UChar")
            NumPut("UChar", byte ^ saltByte, buf, A_Index - 1)
        }

        return StrGet(buf, "UTF-8")
    }

    static Base64Encode(buf, len) {
        ; CRYPT_STRING_BASE64 = 0x01
        ; CRYPT_STRING_NOCRLF = 0x40000000
        flags := 0x40000001
        size := 0
        DllCall("Crypt32\CryptBinaryToStringW", "Ptr", buf, "UInt", len, "UInt", flags, "Ptr", 0, "UInt*", &size)

        outBuf := Buffer(size * 2)
        DllCall("Crypt32\CryptBinaryToStringW", "Ptr", buf, "UInt", len, "UInt", flags, "Ptr", outBuf, "UInt*", &size)

        return StrGet(outBuf, "UTF-16")
    }

    static Base64Decode(str, &len) {
        ; CRYPT_STRING_BASE64 = 0x01
        flags := 0x01
        size := 0
        DllCall("Crypt32\CryptStringToBinaryW", "Str", str, "UInt", 0, "UInt", flags, "Ptr", 0, "UInt*", &size, "Ptr",
            0, "Ptr", 0)

        buf := Buffer(size)
        DllCall("Crypt32\CryptStringToBinaryW", "Str", str, "UInt", 0, "UInt", flags, "Ptr", buf, "UInt*", &size, "Ptr",
            0, "Ptr", 0)

        len := size
        return buf
    }
}

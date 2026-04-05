---
name: reference_telnyx_voice
description: Telnyx voice infrastructure — API key in Keychain, Claudia's phone number, connection details
type: reference
---

Claudia's phone number: **+1 305 501 6501** (Telnyx, Miami area code)

- Telnyx API key stored in macOS Keychain: `security find-generic-password -s "telnyx-api-key" -w`
- TeXML Application ID (Connection ID): `2931136483001632254`
- TeXML webhook: `https://voice.xurman.com/webhook/telnyx`
- Pipecat voice service runs on VPS at port 7860, behind nginx
- Cartesia API key stored in macOS Keychain: `security find-generic-password -s "cartesia-api-key" -w`
- Cartesia voice ID (default): `a167e0f3-df7e-4d52-a9c3-f949145571c4`
- Replaces previous Twilio setup (+18596952433)

# v4.0.1 — Features OFF by default

Source changes (built into the `RuntimeBroker.exe` attached to release v4.0.1):

- `Core/Esp/Config.cs`
  - Sab feature toggles default `false` (Aimbot, ForceAim, SilentAim, SilentBrutal, FastReload, Speed, Drag, SpinBot, AI Aimbot, Aimbot External, Aimbot Body, NoRecoil).
  - Naya master switch `Config.ESP = false` — ESP koi bhi element tabhi draw karta hai jab F2 se ON ho.
  - Saare hotkeys ek jagah define (VK codes), easy to edit.
- `ImGui/Gui.cs`
  - Purana hardcoded `_espEnabled = true` hata diya.
  - F2 ab `Config.ESP` toggle karta hai.
  - F10/F11/F12/0 hotkeys add kiye (Silent Brutal, Drag, SpinBot, AI Aimbot).

Behavior: app start par koi feature active nahi. Har key press feature ko ON/OFF toggle karti hai.

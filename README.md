# RetroLink V0.2

RetroLink is an easy-to-use, easy-to-adapt, and easy-to-adjust way of connecting your Commander X16 to the Internet—both in hardware and in the emulator.

---

## 📦 Hardware

RetroLink hardware is as simple as an ESP32 and a level shifter (to convert 5 V to 3.3 V).

<img src="/Images/hardware.jpg" width="300px" alt="RetroLink Hardware" />

---

## 🖥️ Emulator

In the `/emulator` folder you'll find a custom build of the X16 Emulator with RetroLink support baked in. This lets you write programs for the emulator that connect to the Internet. It’s the normal X16 Emulator—you can still run your existing programs—only now there’s an emulated I²C-connected RetroLink device.

1. **Download** the provided emulator binary into the same directory as your regular emulator executable.  
2. **Backup** your old emulator in case you need to revert.

---

## 🚀 Demo

In **`demo.s`** you’ll find a sample program that:

- Checks if a RetroLink device is present  
- Prints the RetroLink firmware version  
- Connects to Wi-Fi (configure your SSID & password in `demo.s`)  
- Performs an HTTP GET request  
- Prints the response, stripping out HTML tags  

---

## 🎯 Design Goals

- **Cost-effective**: Uses only two inexpensive, readily available parts (ESP32 + level shifter).  
- **DIY-friendly**: Minimal wiring and components—perfect for home build.  
- **Fully emulated**: Works identically in hardware and in the emulator.  
- **Extensible server support**: A companion server will be provided soon for easy multiplayer game and program development.

Stay tuned for server details and more examples!

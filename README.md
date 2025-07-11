# RetroLink V0.2

RetroLink is an easy-to-use, easy-to-adapt, and easy-to-adjust way of connecting your Commander X16 to the Internet—both in hardware and in the emulator.

---

## 📦 Hardware

RetroLink hardware is as simple as an ESP32 and a level shifter (to convert 5 V to 3.3 V).

### Level shifter

The level shifter converts the 5 V I²C bus of the Commander X16 to 3.3 V as that is what the ESP32 can use. I use this component:

* Europe: [2-Channel I²C Level Converter](https://funduinoshop.com/en/electronic-modules/interfaces-converters/signal-converter/2-channel-i2c-level-converter-3-5v?gQT=2)
* USA: [Bi-Directional Level Converter Module](https://www.amazon.com/Channel-Converter-Bi-Directional-Module-Arduino/dp/B09SQ1NJC9)
* Ali: [AliExpress 2-Channel I²C Level Converter](https://nl.aliexpress.com/item/1005008505093208.html?gatewayAdapt=glo2nld) (not exactly the same, but it should work also).

You can use others as well. The advantage of these is that they include the required pull-up resistors on both lines. If you have or buy one without pull-up resistors, you should add a 4.7 kΩ resistors on the 3.3 V side between each line and 5 V. Do you'll need two resistors.

### ESP32

In this picture you'll see an ESP32-S2 board with the SDA line connected to pin 16 and the CLK line connected to pin 17. The current RetroLink firmware expects this setup. I am planning to change this setup to an ESP32-C3, which is smaller, cheaper, and consumes less power.

* [ESP32-S2 Development Board on AliExpress](https://nl.aliexpress.com/item/1005004499308167.html)

<img src="/Images/hardware.jpg" width="300px" alt="RetroLink Hardware" />

---

## 🖥️ Emulator

In the `/emulator` folder you'll find a custom build of the X16 Emulator with RetroLink support baked in. This lets you write programs for the emulator that connect to the Internet. It’s the normal X16 Emulator—you can still run your existing programs—only now there’s an emulated I²C-connected RetroLink device. Currently I only have a Windows and Linux build. If anyone would like to help me with a Mac-build, please contact me :-)

1. **Download** the provided emulator binary into the same directory as your regular emulator executable.
2. **Backup** your old emulator in case you need to revert.

As the RetroLink actualy does not connect to any wifi network when on the Emulator (it just uses the hosts internet connection), on the emulator you can just run `demo.prg`.

---

## 🚀 Demo

In **`Assembly/demo.s`** you’ll find a sample program that:

* Checks if RetroLink is present
* Prints the RetroLink firmware version
* Connects to Wi‑Fi (configure your SSID & password in `demo.s`)
* Performs an HTTP GET request
* Prints the response, stripping out HTML tags

---

## 🎯 Design Goals

* **Cost-effective**: Uses only two inexpensive, readily available parts (ESP32 + level shifter).
* **DIY-friendly**: Minimal wiring and components—perfect for home build.
* **Fully emulated**: Works identically in hardware and in the emulator.
* **Extensible server support**: A companion server will be provided soon for easy multiplayer game and program development.

Stay tuned for server details and more examples!

## ⚠️ Disclaimer

The current version is just a proof-of-concept. Although it works, it might not be very usable depending on your use case. Starting from version 1.0, a lot more features and improvements will be available.

# Waveshare 3.5" Capacitive Touch LCD for Raspberry Pi 5 (SKU 29318/30896)

![Working Display](https://imgur.com/your-image.png)

Finally! A working solution for the Waveshare 3.5" capacitive touch LCD on **Raspberry Pi 5** with **Raspberry Pi OS 64-bit (Bookworm/Trixie)**.

Display works. Touch works. No broken scripts. No deprecated fbtft drivers.

## 📦 What's in this repo

| File | Description |
|------|-------------|
| `spi0-waveshare-SK30896-pi5.dtbo` | Pre-compiled Device Tree Overlay |
| `wavesku30896.bin` | Display firmware |
| `install-simple.sh` | One-command install (uses pre-compiled files) |
| `install-full.sh` | Full install (compiles from source) |

## 🚀 Quick Install (2 commands)

```bash
git clone https://github.com/mumbojum2/Waveshare-SK30896-Display.git
cd Waveshare-SK30896-Display && chmod +x install-simple.sh && ./install-simple.sh

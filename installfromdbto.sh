#!/bin/bash

# ============================================
# Waveshare 3.5" Capacitive Touch LCD (SKU 29318/30896)
# SIMPLE INSTALL - uses pre-compiled overlay
# Raspberry Pi 5 + Raspberry Pi OS 64-bit
# Source: https://github.com/mumbojum2/Waveshare-SK30896-Display
# ============================================

set -e

echo "Waveshare 3.5 install"

# 1. Install required tools
sudo apt update
sudo apt install -y git evtest

# 2. Clone your repository
cd ~
if [ -d "Waveshare-SK30896-Display" ]; then
    cd Waveshare-SK30896-Display && git pull
else
    git clone https://github.com/mumbojum2/Waveshare-SK30896-Display.git
    cd Waveshare-SK30896-Display
fi

# 3. Copy firmware and overlay
sudo cp wavesku30896.bin /lib/firmware/
sudo cp spi0-waveshare-SK30896-pi5.dtbo /boot/firmware/overlays/

# 4. Enable SPI and I2C
sudo raspi-config nonint do_spi 0
sudo raspi-config nonint do_i2c 0

# 5. Add configuration to config.txt (if not already there)
if ! grep -q "waveshare 3.5in" /boot/firmware/config.txt; then
    sudo tee -a /boot/firmware/config.txt << 'EOF'


# waveshare 3.5in 320x480pixels - SKU 30896                                                    
# connected via pogo-pins                                                                       
dtoverlay=mipi-dbi-spi,speed=64000000                                                           
dtparam=compatible=wavesku30896\0panel-mipi-dbi-spi                                            
dtparam=width=320,height=480,width-mm=49,height-mm=79                                           
dtparam=reset-gpio=27,dc-gpio=22,backlight-gpio=18                                              
dtoverlay=goodix,addr=0x5d,i2c1=on                                                              
dtparam=backlight=on                                                                              

EOF
    echo "Config added to /boot/firmware/config.txt"
else
    echo "Config already present, skipping..."
fi

echo "=== Installation complete! Rebooting in 5 seconds... ==="
sleep 5
sudo reboot

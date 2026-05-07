#!/bin/bash

# ============================================
# Waveshare 3.5" Capacitive Touch LCD (SKU 29318/30896)
# FULL INSTALL - compiles overlay from source
# Raspberry Pi 5 + Raspberry Pi OS 64-bit
# Source: https://github.com/mumbojum2/Waveshare-SK30896-Display
# ============================================

set -e

echo "=== Waveshare 3.5" LCD Install (Full - Compile from Source) ==="

# 1. Install required tools
sudo apt update
sudo apt install -y device-tree-compiler git evtest

# 2. Download firmware from your GitHub
cd ~
if [ -d "Waveshare-SK30896-Display" ]; then
    cd Waveshare-SK30896-Display && git pull
else
    git clone https://github.com/mumbojum2/Waveshare-SK30896-Display.git
    cd Waveshare-SK30896-Display
fi
cp wavesku30896.bin ~/
cd ~

# 3. Clone kernel headers for includes (sparse checkout)
cd /tmp
rm -rf rpi-linux
git clone --depth=1 --filter=blob:none --sparse https://github.com/raspberrypi/linux.git rpi-linux
cd rpi-linux
git sparse-checkout set arch/arm/boot/dts/overlays include/dt-bindings include/linux include/uapi/linux
cd ~

# 4. Create overlay source file
cat > waveshare-sk30896.dts << 'EOF'
/dts-v1/;
/plugin/;

#include "i2c-buses.dtsi"
#include <dt-bindings/interrupt-controller/irq.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/gpio/gpio.h>

/ {
	compatible = "brcm,bcm2712";

	fragment@0 {
		target = <&spi0_cs_pins>;
		frag0: __overlay__ {
			brcm,pins = <8>;
		};
	};

	fragment@1 {
		target = <&spi0>;
		frag1: __overlay__ {
			cs-gpios = <&gpio 8 1>;
			status = "okay";
		};
	};

	fragment@2 {
		target = <&spidev0>;
		__overlay__ {
			status = "disabled";
		};
	};

	fragment@3 {
		target = <&spidev1>;
		__overlay__ {
			status = "disabled";
		};
	};

	fragment@4 {
		target = <&gpio>;
		__overlay__ {
			control_lcd0: control_lcd0 {
				brcm,pins = <27 22>;
				brcm,function = <1 1>;
				brcm,pull = <0 0>;
			};
		};
	};

	fragment@5 {
		target = <&spi0>;
		__overlay__ {
			#address-cells = <1>;
			#size-cells = <0>;
			status = "okay";
			panel_lcd0: panel@0 {
				compatible = "wavesku30896", "panel-mipi-dbi-spi";
				reg = <0>;
				pinctrl-names = "default";
				pinctrl-0 = <&control_lcd0>;
				spi-max-frequency = <48000000>;
				write-only;
				spi-cpha;
				spi-cpol;
				reset-gpios = <&gpio 27 GPIO_ACTIVE_HIGH>;
				dc-gpios = <&gpio 22 GPIO_ACTIVE_HIGH>;
				width-mm = <49>;
				height-mm = <74>;
				timing0: panel-timing {
					hactive = <320>;
					vactive = <480>;
					hback-porch = <0>;
					vback-porch = <0>;
					clock-frequency = <0>;
					hfront-porch = <0>;
					hsync-len = <0>;
					vfront-porch = <0>;
					vsync-len = <0>;
				};
			};
		};
	};

	fragment@6 {
		target = <&panel_lcd0>;
		__overlay__ {
			backlight = <&backlight_pwm>;
		};
	};

	fragment@7 {
		target-path = "/";
		__overlay__  {
			backlight_pwm: backlight_pwm {
				compatible = "pwm-backlight";
				brightness-levels = <0 6 8 12 16 24 32 40 48 64 96 128 160 192 224 255>;
				default-brightness-level = <15>;
				pwms = <&rp1_pwm0 2 1000000 0>;
			};
		};
	};

	fragment@8 {
		target = <&rp1_gpio>;
		__overlay__ {
			pwm_pins: pwm_pins {
				pins = "gpio18";
				function = "pwm0";
			};
		};
	};

	fragment@9 {
		target = <&rp1_pwm0>;
		__overlay__ {
			pinctrl-names = "default";
			pinctrl-0 = <&pwm_pins>;
			assigned-clock-rates = <50000000>;
			status = "okay";
		};
	};

	fragment@10 {
		target = <&gpio>;
		__overlay__ {
			goodix_pins: goodix_pins {
				brcm,pins = <4 17>;
				brcm,function = <0 1>;
				brcm,pull = <2 0>;
			};
		};
	};

	fragment@11 {
		target = <&i2c1>;
		__overlay__ {
			#address-cells = <1>;
			#size-cells = <0>;
			status = "okay";
			gt911: gt911@5d {
				compatible = "goodix,gt911";
				reg = <0x5d>;
				pinctrl-names = "default";
				pinctrl-0 = <&goodix_pins>;
				interrupt-parent = <&gpio>;
				interrupts = <4 2>;
				irq-gpios = <&gpio 4 0>;
				reset-gpios = <&gpio 17 0>;
				touchscreen-size-x = <320>;
				touchscreen-size-y = <480>;
				touchscreen-x-mm = <49>;
				touchscreen-y-mm = <74>;
			};
		};
	};
};
EOF

# 5. Preprocess with cpp
cpp -x assembler-with-cpp \
    -I /tmp/rpi-linux/arch/arm/boot/dts/overlays \
    -I /tmp/rpi-linux/include \
    -I /tmp/rpi-linux/include/dt-bindings/input \
    -I /tmp/rpi-linux/include/dt-bindings/gpio \
    -I /tmp/rpi-linux/include/dt-bindings/interrupt-controller \
    -D__DTS__ \
    waveshare-sk30896.dts -o waveshare-sk30896.tmp.dts

# 6. Compile overlay
dtc -@ -I dts -O dtb -o spi0-waveshare-SK30896-pi5.dtbo waveshare-sk30896.tmp.dts

# 7. Install compiled overlay and firmware
sudo cp wavesku30896.bin /lib/firmware/
sudo cp spi0-waveshare-SK30896-pi5.dtbo /boot/firmware/overlays/

# 8. Save a copy to your GitHub repo folder for future use
cp spi0-waveshare-SK30896-pi5.dtbo ~/Waveshare-SK30896-Display/

# 9. Enable SPI and I2C
sudo raspi-config nonint do_spi 0
sudo raspi-config nonint do_i2c 0

# 10. Add configuration to config.txt
if ! grep -q "waveshare 3.5in" /boot/firmware/config.txt; then
    sudo tee -a /boot/firmware/config.txt << 'EOF'

# ===== Waveshare 3.5" Display - SKU 30896/29318 =====
# Basic SPI panel driver
dtoverlay=mipi-dbi-spi,speed=64000000
dtparam=compatible=wavesku30896\0panel-mipi-dbi-spi
dtparam=width=320,height=480,width-mm=49,height-mm=79
dtparam=reset-gpio=27,dc-gpio=22,backlight-gpio=18

# Custom overlay for touch + PWM backlight
dtoverlay=spi0-waveshare-SK30896-pi5,i2c1
EOF
    echo "Config added"
fi

# 11. Cleanup
rm -f waveshare-sk30896.tmp.dts waveshare-sk30896.dts
rm -rf /tmp/rpi-linux

echo "=== Compilation complete! Overlay saved to ~/Waveshare-SK30896-Display/ ==="
echo "=== Rebooting in 5 seconds... ==="
sleep 5
sudo reboot

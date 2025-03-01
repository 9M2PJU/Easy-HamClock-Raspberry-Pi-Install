<div align="center">

# 🕒 HamClock Installer for Raspberry Pi

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi-C51A4A?style=flat&logo=Raspberry-Pi&logoColor=white)](https://www.raspberrypi.org/)
[![Bash Script](https://img.shields.io/badge/Bash-4EAA25?style=flat&logo=GNU%20Bash&logoColor=white)](https://www.gnu.org/software/bash/)

<img src="https://raw.githubusercontent.com/yourusername/hamclock-installer/main/assets/hamclock-logo.png" alt="HamClock Logo" width="200"/>

*A streamlined installation script for [HamClock](https://clearskyinstitute.com/ham/HamClock/) on Raspberry Pi OS*

</div>

---

## 📋 Overview

This script simplifies the process of installing HamClock, a feature-rich amateur radio clock application, on Raspberry Pi systems. The installer automates dependency installation, source code compilation, and configuration with a focus on hardware display support.

<div align="center">
<img src="https://raw.githubusercontent.com/yourusername/hamclock-installer/main/assets/hamclock-screenshot.png" alt="HamClock Screenshot" width="600"/>
</div>

## ✨ Features

- 🔧 **One-Command Installation**: Full installation process from dependencies to final configuration
- 📊 **Smart Display Sizing**: Automatically detects your screen resolution and offers appropriate size options
- 🖥️ **Hardware Display Support**: Optimized for direct use with Raspberry Pi displays
- ⚙️ **Customizable Options**:
  - Desktop icon creation
  - Man page installation
  - Autostart on boot configuration

## 🔍 Requirements

- Raspberry Pi running Raspberry Pi OS Bullseye or Bookworm
- Internet connection
- Display with minimum resolution of 800x480

## 📥 Installation

```bash
# Download the installer script
wget https://raw.githubusercontent.com/yourusername/hamclock-installer/main/install-hamclock.sh

# Make the script executable
chmod +x install-hamclock.sh

# Run the installer
./install-hamclock.sh
```

## 🚀 Usage

After installation, launch HamClock by typing:
```bash
hamclock
```

If you enabled autostart during installation, HamClock will launch automatically on system boot.

## 🔄 Modifications from Original

This installer has been streamlined from the original version:

- ✅ **Hardware Display Focus**: Removed web-only access option
- ✅ **Simplified Documentation**: Removed user guide installation option
- ✅ **Optimized Process**: Streamlined installation flow

## 🛠️ Troubleshooting

The installer creates a detailed log file (`install-hamclock.sh.log`) in the same directory as the script. If you encounter issues, check this log for error messages and diagnostic information.

Common issues:
- **Build Errors**: Ensure all dependencies were installed correctly
- **Display Issues**: Verify your display meets the minimum resolution requirements
- **Permission Errors**: Make sure you're not running the script with sudo

## 📊 HamClock Display Sizes

| Size Option | Resolution | Recommended For |
|-------------|------------|-----------------|
| Small       | 800x480    | 7" displays     |
| Medium      | 1600x960   | 10-12" displays |
| Large       | 2400x1440  | 15-17" displays |
| Extra Large | 3200x1920  | 19"+ displays   |

## 📄 License

This installer script is provided under the same license as the original HamClock software.

## 👏 Acknowledgments

- Original HamClock software by [Elwood Downey](https://clearskyinstitute.com)
- Built for the amateur radio community 📻

---

<div align="center">

### 🌟 Enjoy using HamClock on your Raspberry Pi! 🌟

[![GitHub Stars](https://img.shields.io/github/stars/yourusername/hamclock-installer?style=social)](https://github.com/yourusername/hamclock-installer)
[![GitHub Forks](https://img.shields.io/github/forks/yourusername/hamclock-installer?style=social)](https://github.com/yourusername/hamclock-installer/fork)

</div>

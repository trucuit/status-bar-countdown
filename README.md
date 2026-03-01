# Status Bar Countdown

Ứng dụng macOS hiển thị đồng hồ đếm ngược trên thanh status bar, xây dựng bằng Swift + AppKit.

## 📋 Tính năng

- Đồng hồ đếm ngược trên macOS status bar
- Cài đặt thời gian tùy chỉnh
- Thông báo khi hết giờ
- Giao diện native macOS
- Nhẹ, chiếm ít tài nguyên

## 🛠️ Công nghệ

- **Language:** Swift
- **Framework:** AppKit
- **Build:** Swift Package Manager

## ⚙️ Cài đặt

### Yêu cầu

- macOS 13.0+
- Xcode 14+ hoặc Swift CLI

### 1. Clone & build

```bash
git clone https://github.com/trucuit/status-bar-countdown.git
cd status-bar-countdown
swift build
```

### 2. Chạy ứng dụng

```bash
swift run
```

### 3. Cài đặt vào hệ thống

Xem hướng dẫn chi tiết tại [INSTALL_CHECKLIST_MAC.md](INSTALL_CHECKLIST_MAC.md).

## 📁 Cấu trúc

```
status-bar-countdown/
├── Sources/       # Swift source code
├── Assets/        # App icons & resources
├── scripts/       # Build & install scripts
├── dist/          # Distribution builds
└── Package.swift  # SPM manifest
```

## 🔒 Bảo mật

Ứng dụng không yêu cầu API key hay credentials. Chạy hoàn toàn local.

## 📄 License

All rights reserved.

## 👤 Author

**trung truc** — [GitHub](https://github.com/trucuit)

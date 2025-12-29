# 🍽️ Ứng Dụng Quản Lý Quán Ăn – TKA

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Realtime%20Database-orange?style=for-the-badge&logo=firebase&logoColor=white)
![Android](https://img.shields.io/badge/Platform-Android-green?style=for-the-badge&logo=android&logoColor=white)
![Figma](https://img.shields.io/badge/UI-Figma-purple?style=for-the-badge&logo=figma&logoColor=white)

## 📌 Giới thiệu

**TKA – Ứng Dụng Quản Lý Quán Ăn** được xây dựng bằng **Flutter**, giúp quản lý hoạt động bán hàng một cách đơn giản, trực quan và hiệu quả.

Ứng dụng được thiết kế phù hợp cho các quán ăn quy mô vừa và nhỏ, phục vụ mục đích học tập nghiên cứu công nghệ và triển khai thực tế.

## 🎯 Mục tiêu dự án

- Áp dụng kiến thức lập trình **Flutter** vào thực tế.
- Rèn luyện tư duy tổ chức và quản lý Source Code.
- Xây dựng giao diện (UI/UX) thân thiện, tối giản, dễ sử dụng.
- Kiến trúc hệ thống có khả năng mở rộng trong tương lai.

## 🧠 Công nghệ sử dụng

| Thành phần | Công nghệ |
| :--- | :--- |
| **Ngôn ngữ** | Dart (Flutter Framework) |
| **Nền tảng** | Android |
| **Cơ sở dữ liệu** | Firebase Realtime Database |
| **Lưu trữ ảnh** | Không sử dụng (Hiện tại) |
| **Xác thực** | Không sử dụng (Hiện tại) |
| **Thiết kế UI** | Figma |

## 📱 Chức năng chính

### 🍔 Quản lý sản phẩm
- [x] Thêm / Sửa / Xóa món ăn.
- [x] Hiển thị danh sách thực đơn trực quan.
- [x] Cập nhật dữ liệu đồng bộ theo thời gian thực (Realtime).

### 🧾 Quản lý đơn hàng
- [x] Tạo đơn hàng mới (Order).
- [x] Xem chi tiết hóa đơn.
- [x] Cập nhật trạng thái đơn hàng (Chờ xử lý, Đang nấu, Hoàn thành).

🎨 Thiết kế giao diện
Được thiết kế dựa trên bản mẫu Figma.

Phong cách tối giản (Minimalism), tập trung vào thao tác nhanh.

Tối ưu hóa trải nghiệm người dùng (UX) trên thiết bị Android.

🚀 Hướng phát triển (Roadmap)
[ ] 📊 Thống kê báo cáo doanh thu theo Ngày / Tháng.

[ ] 💳 Tích hợp cổng thanh toán Online (VNPay, Momo).

[ ] 🧾 Xuất hóa đơn định dạng PDF.

[ ] 🔐 Phân quyền tài khoản nâng cao (Admin / Staff).

[ ] 🎨 Tiếp tục cải thiện UI / UX mượt mà hơn.

## 🗂️ Cấu trúc thư mục

Cấu trúc dự án được tổ chức theo mô hình phân tách rõ ràng để dễ dàng bảo trì:

```text
lib/
├── constants/       # Các hằng số, màu sắc, strings
├── models/          # Các lớp dữ liệu (Data Models)
├── providers/       # Quản lý trạng thái (State Management)
├── screens/         # Các màn hình giao diện (UI Screens)
├── services/        # Xử lý Logic, API, Firebase Service
├── theme/           # Cấu hình giao diện chung
├── utils/           # Các hàm tiện ích hỗ trợ
├── widgets/         # Các Widget tái sử dụng
├── firebase_options.dart
└── main.dart

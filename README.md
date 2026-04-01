# App Quan ly Quan an (TKA)

Ung dung quan ly van hanh quan an duoc xay dung bang Flutter, ho tro quy trinh tu nhan ban, goi mon, xu ly bep, thu ngan den bao cao doanh thu.

## Gioi thieu

**TKA** la ung dung quan ly quan an tap trung vao toc do thao tac va tinh thuc tien khi van hanh:

- Quan ly trang thai ban theo thoi gian thuc.
- Quan ly order xuyen suot giua Waiter - Kitchen - Cashier.
- Quan ly menu, nhan vien, ca lam va bao cao doanh thu.
- Ho tro phan quyen tai khoan theo vai tro nghiep vu.

## Cong nghe su dung

| Nhom | Cong nghe |
|---|---|
| Framework | Flutter (Dart SDK 3.x) |
| State Management | Provider |
| Backend/BaaS | Firebase Core + Cloud Firestore |
| Network/Upload | `http`, `image_picker`, Cloudinary |
| Bao cao | `excel`, `open_file`, `path_provider`, `intl` |
| Bao mat co ban | Hash mat khau (`crypto`), sanitize input |
| Cong cu | Git/GitHub |

## He thong phan quyen (RBAC)

He thong dang dung 3 role: `manager`, `cashier`, `staff`.

| Vai tro | Quyen chinh |
|---|---|
| Manager | Truy cap toan bo module; quan ly menu, ban, nhan vien, ca lam, bao cao; quan ly tai khoan tat ca role |
| Cashier | Xu ly thanh toan, theo doi ban cho thanh toan; truy cap module bep de phoi hop van hanh |
| Staff (Waiter) | Quan ly ban phuc vu, goi mon, goi them mon, doi ban, huy mon theo rule nghiep vu |

### Quy tac quyen va tai khoan

- Chi `manager` duoc tao/sua/xoa/khoa-mo tai khoan nhan vien.
- Tai khoan duoc tra cuu theo `username` (dinh danh duy nhat).
- Tai khoan bi khoa (`isActive = false`) khong the dang nhap.

## Tinh nang chinh

### 1) Quan ly ban va order

- Tao order cho ban dang phuc vu.
- **Goi them mon** vao order hien tai (append, khong tao order moi).
- **Doi ban** tu ban dang co khach sang ban trong.
- **Huy mon / tra mon** theo quy tac trang thai order.
- Dong bo trang thai ban: `available`, `occupied`, `paymentPending`.

### 2) Quan ly thuc don (Menu)

- Them / sua / xoa mon.
- Phan loai mon an - thuc uong.
- Ho tro anh mon (cuc bo hoac URL Cloudinary).

### 3) Module bep (Kitchen)

- Theo doi va cap nhat trang thai don hang:
  - `pending` -> `cooking` -> `readyToServe` -> `completed`.
- Hien thi uu tien don dang cho xu ly.
- Truy cap boi `manager` va `cashier`.

### 4) Thu ngan va thanh toan

- Xu ly don da hoan tat.
- Tinh tong tien, giam gia, tien thua.
- Luu lich su thanh toan theo phuong thuc (tien mat, the, chuyen khoan).

### 5) Quan ly nhan su va bao cao

- Quan ly tai khoan nhan vien theo role.
- Quan ly ca lam.
- Bao cao doanh thu tuan/thang/nam.
- Xuat bao cao ra file Excel.

## Huong dan cai dat

### 1. Chuan bi moi truong

- Flutter SDK (khuyen nghi theo `pubspec.yaml`).
- Android Studio / VS Code.
- Firebase project da cau hinh Firestore.

### 2. Cai dependencies

```bash
flutter pub get
```

### 3. Cau hinh Firebase

- Dam bao file `lib/firebase_options.dart` dung voi project Firebase cua ban.
- Bat Cloud Firestore va tao cac collection can thiet:
  - `menu`, `tables`, `orders`, `payments`, `employees`, `reports`, `shifts`.

### 4. Chay ung dung

```bash
flutter run
```

### 5. Build release (tuy chon)

```bash
flutter build apk
```

## Cau truc thu muc chinh

```text
lib/
|- main.dart                  # Entry point, dieu huong theo role
|- firebase_options.dart      # Cau hinh Firebase theo platform
|- models/                    # Data models (table, order, employee, report, ...)
|- providers/                 # State management + nghiep vu chinh (Auth/Restaurant)
|- screens/
|  |- auth/                   # Login
|  |- waiter/                 # Man hinh phuc vu
|  |- cashier/                # Man hinh thu ngan
|  |- kitchen/                # Man hinh bep
|  \- manager/                # Dashboard + quan tri
|- services/                  # Firestore, upload anh, export excel, error/log
|- widgets/                   # Reusable widgets/dialogs/sheets
|- utils/                     # Formatter, sanitizer, transition utils
\- theme/                     # Theme va style he thong
```

## Tai khoan mau (development)

- `manager / 1234`
- `cashier / 1234`
- `staff / 1234`

## Ghi chu

- `RestaurantProvider` la trung tam nghiep vu van hanh ban/order.
- Firestore stream duoc dung de dong bo du lieu thoi gian thuc.
- Cac tinh nang roadmap nhu in bill vat ly, thanh toan online co the tiep tuc mo rong o phien ban sau.
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
- Xây dựng giao diện (UI/UX) hiện đại kết hợp với tối giản và dễ sử dụng cho người dùng.
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
├── utils/           # Các hàm tiện ích hỗ trợ, dữ liệu mẫu
├── widgets/         # Các Widget tái sử dụng
├── firebase_options.dart
└── main.dart

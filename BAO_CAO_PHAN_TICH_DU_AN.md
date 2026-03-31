# BÁO CÁO PHÂN TÍCH DỰ ÁN QUẢN LÝ NHÀ HÀNG

## 1. BÁO CÁO CHỨC NĂNG ĐÃ HOÀN THIỆN

### 1.1. Xác thực và Phân quyền (Authentication & Authorization)
✅ **Đã hoàn thiện:**
- Đăng nhập với username/password từ Firestore
- Hỗ trợ tài khoản demo (staff/1234, manager/1234) làm fallback
- Phân quyền 2 cấp: Staff (nhân viên) và Manager (quản lý)
- Quản lý trạng thái đăng nhập với AuthProvider
- Kiểm tra tài khoản active/inactive
- Hash mật khẩu (SHA-256 + salt) và tự động migrate khi đăng nhập

### 1.2. Quản lý Đơn hàng (Order Management)
✅ **Đã hoàn thiện:**
- Tạo đơn hàng từ bàn ăn (Waiter Dashboard)
- Luồng trạng thái đơn: Pending → Cooking → ReadyToServe → Completed
- Cập nhật trạng thái đơn từ Kitchen Display Screen
- Hiển thị đơn hàng real-time với Firestore Streams
- Đồng bộ trạng thái bàn với đơn hàng
- Xử lý thanh toán và đánh dấu đơn đã thanh toán
- Xóa đơn đã thanh toán để tối ưu database

### 1.3. Quản lý Bàn ăn (Table Management)
✅ **Đã hoàn thiện:**
- Hiển thị danh sách bàn với trạng thái: Available, Occupied, PaymentPending
- Tạo, sửa, xóa bàn ăn
- Tự động cập nhật trạng thái bàn khi có đơn hàng
- Màu sắc trực quan cho từng trạng thái
- Lọc bàn theo trạng thái

### 1.4. Quản lý Menu (Menu Management)
✅ **Đã hoàn thiện:**
- Thêm, sửa, xóa món ăn/thức uống
- Phân loại: Food và Drink
- Hỗ trợ hình ảnh (URL hoặc chọn từ thư viện)
- Upload ảnh lên Cloudinary khi chọn từ thư viện
- Hiển thị menu trong Ordering Sheet với tìm kiếm
- Real-time sync với Firestore

### 1.5. Quản lý Nhân viên (Employee Management)
✅ **Đã hoàn thiện:**
- CRUD đầy đủ cho nhân viên
- Quản lý username, password, role (staff/manager)
- Trạng thái active/inactive
- Stream real-time danh sách nhân viên
- Tìm kiếm nhân viên theo username

### 1.6. Quản lý Ca làm việc (Shift Management)
✅ **Đã hoàn thiện:**
- Tạo, sửa, xóa ca làm việc
- Gán ca cho nhân viên với thời gian bắt đầu/kết thúc
- Kiểm tra ca trùng lặp (overlapping shifts)
- Hiển thị ca theo tuần với filter theo nhân viên
- Trạng thái ca: Scheduled, Completed, Cancelled
- Màn hình xem ca cho nhân viên (ShiftViewScreen)

### 1.7. Báo cáo (Reports)
✅ **Đã hoàn thiện:**
- Tạo báo cáo theo tuần/tháng/năm
- Tính toán doanh thu, số đơn, món bán chạy
- Lưu báo cáo vào Firestore
- Chọn khoảng thời gian tùy chỉnh
- Hiển thị top món bán chạy với doanh thu
- Xuất báo cáo ra Excel

### 1.8. Thanh toán (Payment)
✅ **Đã hoàn thiện:**
- Xử lý thanh toán cho nhiều đơn cùng lúc
- Hỗ trợ 3 phương thức: Tiền mặt, Thẻ, Chuyển khoản
- Tính giảm giá theo phần trăm
- Tính tiền thừa cho thanh toán tiền mặt
- Lưu lịch sử thanh toán vào Firestore

### 1.9. Kết nối Firebase
✅ **Đã hoàn thiện:**
- Sử dụng Cloud Firestore làm database
- Real-time synchronization với Streams
- Collections: menu, tables, orders, employees, shifts, reports, payments
- Xử lý lỗi và fallback mechanisms
- Batch operations cho hiệu suất tốt

### 1.10. Đa ngôn ngữ (Internationalization)
✅ **Đã hoàn thiện:**
- Hỗ trợ tiếng Việt và tiếng Anh
- Toggle language trong UI
- AppStrings provider quản lý tất cả strings

---

## 2. CẤU TRÚC HỆ THỐNG LẬP TRÌNH

Dự án được xây dựng theo kiến trúc phân lớp (Layered Architecture) kết hợp với mô hình quản lý trạng thái Provider, một phương pháp phổ biến và hiệu quả trong hệ sinh thái Flutter.

Kiến trúc này chia ứng dụng thành các lớp (layers) độc lập với các vai trò và trách nhiệm rõ ràng, giúp mã nguồn dễ đọc, dễ bảo trì và mở rộng.

```mermaid
graph TD
    A[UI Layer (Screens & Widgets)] --> B[State Management Layer (Providers)];
    B --> C[Service Layer (Business Logic & API Calls)];
    C --> D[Data Layer (Models & Data Sources)];
    D --> E[Firebase Firestore];

    subgraph "Tầng Trình Bày (Presentation Layer)"
        A
    end

    subgraph "Tầng Quản lý Trạng thái"
        B
    end

    subgraph "Tầng Dữ liệu (Data Layer)"
        C
        D
    end

    subgraph "Nguồn Dữ liệu (Data Source)"
        E
    end
```

### 2.1. Tầng Trình Bày (Presentation Layer)

-   **Thư mục:** `lib/screens/`, `lib/widgets/`
-   **Vai trò:** Chịu trách nhiệm hiển thị giao diện người dùng (UI) và bắt các sự kiện từ người dùng (như nhấn nút, nhập liệu).
-   **Mô tả:**
    -   `screens/`: Chứa các màn hình hoàn chỉnh của ứng dụng (ví dụ: `login_screen.dart`, `waiter_dashboard_screen.dart`).
    -   `widgets/`: Chứa các thành phần UI có thể tái sử dụng trên nhiều màn hình (ví dụ: `add_employee_dialog.dart`, `tka_logo.dart`).
    -   Tầng này không chứa logic nghiệp vụ. Nó chỉ "lắng nghe" sự thay đổi trạng thái từ `Provider` và cập nhật lại giao diện. Khi có tương tác từ người dùng, nó sẽ gọi các phương thức tương ứng trong `Provider`.

### 2.2. Tầng Quản lý Trạng thái (State Management Layer)

-   **Thư mục:** `lib/providers/`
-   **Vai trò:** Là cầu nối giữa Tầng Trình Bày và Tầng Dữ liệu. Nó chứa trạng thái của ứng dụng và logic nghiệp vụ (business logic).
-   **Mô tả:**
    -   Sử dụng `ChangeNotifierProvider` và `ChangeNotifier` để quản lý và thông báo các thay đổi về trạng thái cho UI.
    -   Ví dụ: `AuthProvider` quản lý trạng thái đăng nhập, `RestaurantProvider` quản lý dữ liệu về bàn, menu, đơn hàng...
    -   Khi cần dữ liệu, Provider sẽ gọi các phương thức từ `Service Layer`. Sau khi nhận được dữ liệu, nó sẽ cập nhật trạng thái của mình và thông báo cho UI (`notifyListeners()`).

### 2.3. Tầng Dịch vụ (Service Layer)

-   **Thư mục:** `lib/services/`
-   **Vai trò:** Trừu tượng hóa việc truy cập dữ liệu từ các nguồn bên ngoài (như Firebase Firestore). Tầng này đóng vai trò là một "Repository".
-   **Mô tả:**
-   `firestore_service.dart`: Chứa tất cả các phương thức để thực hiện thao tác CRUD (Create, Read, Update, Delete) với Firestore.
-   `cloudinary_service.dart`: Upload ảnh lên Cloudinary (unsigned).
-   `excel_export_service.dart`: Xuất báo cáo Excel.
-   `password_service.dart`: Hash/verify mật khẩu.
-   `error_handler.dart` & `logger_service.dart`: Xử lý lỗi tập trung và logging.
    -   Việc tách lớp Service giúp logic nghiệp vụ trong Provider không cần biết chi tiết về cách dữ liệu được lưu trữ hay truy xuất. Nếu sau này muốn đổi từ Firestore sang một database khác, chúng ta chỉ cần thay đổi lớp Service này mà không ảnh hưởng đến các lớp khác.

### 2.4. Tầng Dữ liệu (Data Layer)

-   **Thư mục:** `lib/models/`
-   **Vai trò:** Định nghĩa cấu trúc dữ liệu của ứng dụng.
-   **Mô tả:**
    -   Chứa các lớp Plain Old Dart Object (PODO) như `EmployeeModel`, `OrderModel`, `TableModel`.
    -   Các lớp này bao gồm các phương thức để chuyển đổi từ/sang định dạng của Firestore (`fromFirestore`, `toFirestore`), giúp việc serialize/deserialize dữ liệu trở nên dễ dàng.

### 2.5. Luồng Dữ liệu (Data Flow)

1.  **User Interaction:** Người dùng tương tác với một Widget trên màn hình (ví dụ: nhấn nút "Đăng nhập").
2.  **Call Provider:** Widget gọi một phương thức trong `AuthProvider` (ví dụ: `authProvider.login(user, pass)`).
3.  **Call Service:** `AuthProvider` gọi phương thức tương ứng trong `FirestoreService` (ví dụ: `firestoreService.getEmployeeByUsername(user)`).
4.  **Fetch Data:** `FirestoreService` tương tác với Firebase Firestore để lấy dữ liệu.
5.  **Return Data:** Dữ liệu được trả về qua các lớp, được chuyển đổi thành các đối tượng `Model`.
6.  **Update State:** `AuthProvider` nhận dữ liệu, cập nhật trạng thái bên trong nó (ví dụ: `_role`, `_currentEmployee`).
7.  **Notify UI:** `AuthProvider` gọi `notifyListeners()`.
8.  **Rebuild UI:** Các Widget đang "lắng nghe" `AuthProvider` sẽ tự động được xây dựng lại (rebuild) để hiển thị trạng thái mới.

---

## 3. GIẢI THÍCH FILE (DATA DICTIONARY)

### 3.1. Models (Cấu trúc dữ liệu)

- **`enums.dart`**: Định nghĩa các enum: TableStatus, OrderStatus, MenuCategory, UserRole, ShiftStatus, AppLanguage, PaymentMethod
- **`table_model.dart`**: Định nghĩa cấu trúc dữ liệu của một bàn ăn (id, name, status, currentOrderId)
- **`menu_item.dart`**: Định nghĩa cấu trúc món ăn/thức uống (id, name, price, category, imageUrl)
- **`order_item.dart`**: Định nghĩa một item trong đơn hàng (menuItem, quantity)
- **`order_model.dart`**: Định nghĩa cấu trúc đơn hàng (id, tableId, timestamp, status, items, total)
- **`employee_model.dart`**: Định nghĩa cấu trúc nhân viên (id, name, username, password, role, isActive)
- **`shift_model.dart`**: Định nghĩa cấu trúc ca làm việc (id, employeeId, date, startTime, endTime, status, notes)
- **`report_model.dart`**: Định nghĩa cấu trúc báo cáo (type, startDate, endDate, totalRevenue, totalOrders, itemSales, itemRevenue)
- **`models.dart`**: File export tập trung tất cả models

### 3.2. Providers (Quản lý State)

- **`restaurant_provider.dart`**: Provider chính quản lý toàn bộ state của nhà hàng (tables, menu, orders, employees, shifts), xử lý business logic và tương tác với Firestore
- **`auth_provider.dart`**: Quản lý xác thực người dùng, đăng nhập/đăng xuất, lưu thông tin user hiện tại
- **`language_provider.dart`**: Quản lý ngôn ngữ ứng dụng (tiếng Việt/tiếng Anh)
- **`app_strings.dart`**: Quản lý tất cả các chuỗi văn bản đa ngôn ngữ

### 3.3. Services (Dịch vụ)

- **`firestore_service.dart`**: Service xử lý tất cả các thao tác với Firestore (CRUD cho menu, tables, orders, employees, shifts, reports, payments)
- **`cloudinary_service.dart`**: Upload ảnh lên Cloudinary (unsigned)
- **`excel_export_service.dart`**: Xuất báo cáo Excel
- **`password_service.dart`**: Hash/verify mật khẩu
- **`error_handler.dart`**: Xử lý lỗi tập trung, trả thông điệp thân thiện
- **`logger_service.dart`**: Logging cho lỗi/cảnh báo

### 3.4. Screens (Màn hình)

#### Auth
- **`login_screen.dart`**: Màn hình đăng nhập với form validation

#### Waiter
- **`waiter_dashboard_screen.dart`**: Màn hình chính của nhân viên phục vụ, hiển thị danh sách bàn, cho phép tạo đơn và thanh toán
- **`shift_view_screen.dart`**: Màn hình xem ca làm việc của nhân viên theo tuần

#### Kitchen
- **`kitchen_display_screen.dart`**: Màn hình hiển thị đơn hàng cho bếp, cho phép cập nhật trạng thái đơn (pending → cooking → ready → completed)

#### Manager
- **`manager_dashboard_screen.dart`**: Màn hình chính của quản lý với 6 tabs: Dashboard, Menu, Tables, Reports, Shifts, Employees
- **`employee_management_screen.dart`**: Màn hình quản lý nhân viên (CRUD, khóa/mở khóa tài khoản)
- **`reports_screen.dart`**: Màn hình xem và tạo báo cáo theo tuần/tháng/năm
- **`shift_management_screen.dart`**: Màn hình quản lý ca làm việc, lọc theo tuần và nhân viên

### 3.5. Widgets (Component UI)

- **`add_employee_dialog.dart`**: Dialog thêm/sửa nhân viên
- **`add_menu_item_dialog.dart`**: Dialog thêm/sửa món ăn
- **`add_shift_dialog.dart`**: Dialog thêm/sửa ca làm việc với validation ca trùng
- **`add_table_dialog.dart`**: Dialog thêm/sửa bàn ăn
- **`ordering_sheet.dart`**: Bottom sheet để chọn món và tạo đơn hàng
- **`payment_dialog.dart`**: Dialog thanh toán với giảm giá và chọn phương thức thanh toán
- **`animated_card.dart`**: Widget card có animation
- **`tka_logo.dart`**: Widget logo của ứng dụng

### 3.6. Utils & Theme

- **`vnd_format.dart`**: Utility format số tiền theo định dạng VNĐ
- **`page_transitions.dart`**: Utility cho page transitions
- **`app_theme.dart`**: Định nghĩa theme, màu sắc của ứng dụng
- **`input_sanitizer.dart`**: Làm sạch input (tên, username, notes, search, URL)
- **`dummy_data.dart`**: Dữ liệu mẫu (seed/demo data)

---

## 4. PHÂN TÍCH PHẦN CHƯA HOÀN THIỆN (GAP ANALYSIS)

### 4.1. Màn hình chỉ có UI, chưa có Logic đầy đủ

#### ❌ **Không có màn hình nào chỉ có UI mà thiếu logic**
Tất cả các màn hình đều đã có logic xử lý đầy đủ và kết nối với Firestore.

### 4.2. Chức năng quan trọng còn thiếu hoặc chưa hoàn thiện

#### 🔴 **1. Quản lý Kho (Inventory Management)**
- **Thiếu hoàn toàn**: Không có module quản lý nguyên liệu, tồn kho
- **Cần bổ sung**: 
  - Theo dõi số lượng nguyên liệu
  - Cảnh báo hết hàng
  - Nhập/xuất kho
  - Liên kết nguyên liệu với món ăn (recipe)

#### 🔴 **2. Quản lý Nhà cung cấp (Supplier Management)**
- **Thiếu hoàn toàn**: Không có chức năng quản lý nhà cung cấp
- **Cần bổ sung**:
  - Danh sách nhà cung cấp
  - Lịch sử đặt hàng
  - Thanh toán cho nhà cung cấp

#### 🔴 **3. Thống kê và Analytics nâng cao**
- **Thiếu một phần**: 
  - Chỉ có báo cáo cơ bản (doanh thu, số đơn)
  - Thiếu biểu đồ, đồ thị
  - Thiếu phân tích xu hướng
  - Thiếu so sánh theo thời gian
- **Cần bổ sung**:
  - Biểu đồ doanh thu theo ngày/tuần/tháng
  - Phân tích giờ cao điểm
  - Phân tích món bán chạy theo thời gian
  - Dashboard với charts

#### 🟡 **4. Quản lý Khách hàng (Customer Management)**
- **Thiếu hoàn toàn**: Không có chức năng quản lý khách hàng
- **Cần bổ sung**:
  - Lưu thông tin khách hàng
  - Lịch sử đặt hàng của khách
  - Chương trình khách hàng thân thiết
  - Tích điểm, voucher

#### 🟡 **5. Đặt bàn trước (Reservation System)**
- **Thiếu hoàn toàn**: Không có chức năng đặt bàn trước
- **Cần bổ sung**:
  - Đặt bàn theo thời gian
  - Quản lý lịch đặt bàn
  - Thông báo khi đến giờ đặt bàn
  - Hủy/đổi lịch đặt bàn

#### 🟡 **6. In hóa đơn (Receipt Printing)**
- **Thiếu hoàn toàn**: Không có chức năng in hóa đơn
- **Cần bổ sung**:
  - In hóa đơn sau thanh toán
  - Kết nối máy in
  - Template hóa đơn tùy chỉnh
  - In lại hóa đơn

#### 🟡 **7. Thông báo và Cảnh báo (Notifications & Alerts)**
- **Thiếu một phần**: 
  - Có badge notification cho đơn chờ xử lý
  - Thiếu push notifications
  - Thiếu cảnh báo thời gian thực
- **Cần bổ sung**:
  - Push notification khi có đơn mới
  - Cảnh báo đơn chờ quá lâu
  - Thông báo bàn sắp hết thời gian
  - Cảnh báo hết nguyên liệu

#### 🟡 **8. Quản lý Nhân sự nâng cao (Advanced HR)**
- **Thiếu một phần**:
  - Có quản lý ca làm việc cơ bản
  - Thiếu tính lương
  - Thiếu chấm công
  - Thiếu đánh giá hiệu suất
- **Cần bổ sung**:
  - Chấm công vào/ra
  - Tính lương theo ca
  - Báo cáo giờ làm việc
  - Đánh giá nhân viên

#### 🟡 **9. Quản lý Chi phí (Expense Management)**
- **Thiếu hoàn toàn**: Không có chức năng quản lý chi phí
- **Cần bổ sung**:
  - Ghi nhận chi phí hàng ngày
  - Phân loại chi phí (nguyên liệu, điện nước, lương...)
  - Báo cáo chi phí
  - So sánh doanh thu vs chi phí

#### 🟡 **10. Báo cáo Tài chính (Financial Reports)**
- **Thiếu một phần**:
  - Có báo cáo doanh thu cơ bản
  - Thiếu báo cáo lợi nhuận
  - Thiếu báo cáo dòng tiền
- **Cần bổ sung**:
  - Báo cáo lợi nhuận (revenue - expenses)
  - Báo cáo dòng tiền
  - Báo cáo thuế
  - Export Excel/PDF

#### 🟡 **11. Quản lý Khuyến mãi (Promotion Management)**
- **Thiếu một phần**:
  - Có giảm giá trong thanh toán
  - Thiếu quản lý chương trình khuyến mãi
- **Cần bổ sung**:
  - Tạo chương trình khuyến mãi
  - Áp dụng tự động
  - Quản lý voucher/coupon
  - Lịch sử khuyến mãi

#### 🟡 **12. Backup và Restore dữ liệu**
- **Thiếu hoàn toàn**: Không có chức năng backup/restore
- **Cần bổ sung**:
  - Export dữ liệu
  - Import dữ liệu
  - Backup tự động
  - Restore từ backup

#### 🟡 **13. Quản lý Nhiều Chi nhánh (Multi-branch)**
- **Thiếu hoàn toàn**: Ứng dụng chỉ hỗ trợ 1 nhà hàng
- **Cần bổ sung**:
  - Quản lý nhiều chi nhánh
  - Chuyển dữ liệu giữa chi nhánh
  - Báo cáo tổng hợp

#### 🟡 **14. Tích hợp Thanh toán Online**
- **Thiếu một phần**:
  - Có UI chọn phương thức thanh toán
  - Thiếu tích hợp thực tế với payment gateway
- **Cần bổ sung**:
  - Tích hợp VNPay, Momo, ZaloPay
  - QR code thanh toán
  - Webhook xử lý kết quả thanh toán

#### 🟡 **15. Quản lý Feedback/Đánh giá**
- **Thiếu hoàn toàn**: Không có chức năng nhận feedback
- **Cần bổ sung**:
  - Form đánh giá sau khi ăn
  - Xem feedback của khách
  - Phân tích điểm đánh giá

### 4.3. Code đang viết dở dang hoặc cần cải thiện

#### ⚠️ **1. Error Handling**
- **Hiện tại**: Đã có ErrorHandler + LoggerService để xử lý lỗi tập trung
- **Cần cải thiện**: 
  - Error logging service ngoài debug (Sentry/Crashlytics)
  - User-friendly error messages
  - Retry mechanisms

#### ⚠️ **2. Offline Support**
- **Hiện tại**: Ứng dụng phụ thuộc hoàn toàn vào internet
- **Cần cải thiện**:
  - Cache dữ liệu local
  - Offline mode
  - Sync khi có internet lại

#### ⚠️ **3. Performance Optimization**
- **Hiện tại**: Có một số optimization nhưng chưa đầy đủ
- **Cần cải thiện**:
  - Pagination cho danh sách dài
  - Lazy loading images
  - Debounce cho search
  - Memoization

#### ⚠️ **4. Security**
- **Hiện tại**: Password đã được hash (SHA-256 + salt) và migrate khi đăng nhập
- **Cần cải thiện**:
  - Hash password mạnh hơn (bcrypt/argon2)
  - Firebase Authentication thay vì custom auth
  - Role-based access control (RBAC) chặt chẽ hơn
  - Input validation và sanitization

#### ⚠️ **5. Testing**
- **Hiện tại**: Không thấy có test files
- **Cần bổ sung**:
  - Unit tests
  - Widget tests
  - Integration tests

#### ⚠️ **6. Documentation**
- **Hiện tại**: Code có comments nhưng thiếu documentation
- **Cần bổ sung**:
  - API documentation
  - Architecture documentation
  - User manual

#### ✅ **7. Image Upload**
- **Đã bổ sung**: Upload ảnh lên Cloudinary (chọn từ thư viện) và hỗ trợ URL
- **Cần cải thiện**:
  - Thêm upload lên Firebase Storage (nếu muốn đồng bộ Firebase hoàn toàn)
  - Image picker từ camera (hiện mới chọn từ gallery)

---

## 5. TỔNG KẾT

### Điểm mạnh:
✅ Core features hoàn thiện và hoạt động tốt
✅ Real-time synchronization với Firestore
✅ UI/UX đẹp và trực quan
✅ Code structure rõ ràng, dễ maintain
✅ Hỗ trợ đa ngôn ngữ

### Điểm cần cải thiện:
⚠️ Thiếu nhiều tính năng nâng cao (inventory, customer, reservation...)
⚠️ Security cần được tăng cường
⚠️ Chưa có offline support
⚠️ Thiếu testing và documentation

### Đề xuất ưu tiên phát triển:
1. **Security**: Implement Firebase Authentication và hash password
2. **Inventory Management**: Module quản lý kho quan trọng cho nhà hàng
3. **Customer Management**: Tăng trải nghiệm khách hàng
4. **Advanced Reports**: Biểu đồ và phân tích sâu hơn
5. **Offline Support**: Đảm bảo hoạt động khi mất mạng

---

*Báo cáo được tạo vào: ${DateTime.now().toString()}*

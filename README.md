<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8" />
  <title>Ứng Dụng Quản Lý Quán Ăn - TKA</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>

  <style>
    body {
      margin: 0;
      font-family: "Segoe UI", sans-serif;
      background: #0f1117;
      color: #eaeaea;
      line-height: 1.7;
    }

    .container {
      max-width: 900px;
      margin: auto;
      padding: 40px 20px;
    }

    h1, h2, h3 {
      color: #ffffff;
    }

    h1 {
      text-align: center;
      margin-bottom: 10px;
    }

    .badges {
      text-align: center;
      margin: 20px 0 40px;
    }

    .badges img {
      margin: 6px;
      height: 32px;
    }

    section {
      margin-bottom: 40px;
    }

    ul {
      padding-left: 20px;
    }

    li {
      margin-bottom: 8px;
    }

    .box {
      background: #161b22;
      padding: 20px;
      border-radius: 10px;
      margin-top: 15px;
    }

    code {
      background: #1e1e1e;
      padding: 4px 6px;
      border-radius: 6px;
      color: #4fc3f7;
    }

    pre {
      background: #1e1e1e;
      padding: 16px;
      border-radius: 10px;
      overflow-x: auto;
      color: #dcdcdc;
    }

    footer {
      text-align: center;
      margin-top: 60px;
      opacity: 0.8;
    }
  </style>
</head>

<body>
  <div class="container">

    <h1>🍽️ Ứng Dụng Quản Lý Quán Ăn – TKA</h1>

    <div class="badges">
      <img src="https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter&logoColor=white">
      <img src="https://img.shields.io/badge/Firebase-Realtime%20Database-orange?style=for-the-badge&logo=firebase&logoColor=white">
      <img src="https://img.shields.io/badge/Platform-Android-green?style=for-the-badge&logo=android&logoColor=white">
      <img src="https://img.shields.io/badge/UI-Figma-purple?style=for-the-badge&logo=figma&logoColor=white">
    </div>

    <section>
      <h2>📌 Giới thiệu</h2>
      <p>
        <b>TKA – Ứng Dụng Quản Lý Quán Ăn</b> được xây dựng bằng Flutter,
        giúp quản lý hoạt động bán hàng một cách đơn giản, trực quan và hiệu quả.
      </p>
      <p>
        Ứng dụng phù hợp cho quán ăn nhỏ và vừa, phục vụ mục đích học tập và triển khai thực tế.
      </p>
    </section>

    <section>
      <h2>🎯 Mục tiêu dự án</h2>
      <ul>
        <li>Áp dụng kiến thức Flutter vào thực tế</li>
        <li>Rèn luyện tư duy tổ chức project</li>
        <li>Xây dựng giao diện thân thiện, dễ dùng</li>
        <li>Có khả năng mở rộng trong tương lai</li>
      </ul>
    </section>

    <section>
      <h2>🧠 Công nghệ sử dụng</h2>
      <div class="box">
        <ul>
          <li><b>Ngôn ngữ:</b> Dart (Flutter)</li>
          <li><b>Nền tảng:</b> Android</li>
          <li><b>Cơ sở dữ liệu:</b> Firebase Realtime Database</li>
          <li><b>Lưu ảnh:</b> Không sử dụng</li>
          <li><b>Xác thực:</b> Không sử dụng</li>
          <li><b>Thiết kế UI:</b> Figma</li>
        </ul>
      </div>
    </section>

    <section>
      <h2>📱 Chức năng chính</h2>

      <h3>🍔 Quản lý sản phẩm</h3>
      <ul>
        <li>Thêm / sửa / xóa món ăn</li>
        <li>Hiển thị danh sách món</li>
        <li>Cập nhật dữ liệu theo thời gian thực</li>
      </ul>

      <h3>🧾 Quản lý đơn hàng</h3>
      <ul>
        <li>Tạo đơn hàng</li>
        <li>Xem chi tiết đơn</li>
        <li>Cập nhật trạng thái</li>
      </ul>

      <p><b>⚠️ Ứng dụng không có chức năng quản lý khách hàng.</b></p>
    </section>

    <section>
      <h2>🗂️ Cấu trúc thư mục</h2>
      <pre>
lib/
├── constants/
├── models/
├── providers/
├── screens/
├── services/
├── theme/
├── utils/
├── widgets/
├── firebase_options.dart
└── main.dart
      </pre>
    </section>

    <section>
      <h2>🎨 Thiết kế giao diện</h2>
      <ul>
        <li>Thiết kế bằng Figma</li>
        <li>Giao diện tối giản, dễ sử dụng</li>
        <li>Tối ưu trải nghiệm người dùng Android</li>
      </ul>
    </section>

    <section>
      <h2>🚀 Hướng phát triển</h2>
      <ul>
        <li>📊 Thống kê doanh thu theo ngày / tháng</li>
        <li>💳 Thanh toán online (VNPay, Momo)</li>
        <li>🧾 Xuất hóa đơn PDF</li>
        <li>🔐 Phân quyền nâng cao</li>
        <li>🎨 Cải thiện UI / UX</li>
      </ul>
    </section>

    <footer>
      <p><b>👨‍💻 Tác giả:</b> Kun</p>
      <p><b>GitHub:</b> https://github.com/wanbetkun00</p>
      <p>⭐ Nếu thấy hay thì cho mình một star nhé!</p>
    </footer>

  </div>
</body>
</html>

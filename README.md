# Case Study 2 - Task Manager

- MSSV: KHMT2411002
- Họ tên: Phạm Phúc Duy

Ứng dụng quản lý công việc: tạo việc, giao việc cho nhiều người, chia sẻ, thông báo, gửi email, thống kê và lịch sử hoạt động.

## Cấu trúc
- `api/`: Backend Node.js/Express + MongoDB (Mongoose)
- `TaskManager/`: Frontend Flutter

## Chạy backend

1. Cài Node.js, tạo cơ sở dữ liệu MongoDB Atlas.
2. Vào thư mục `api` và cài thư viện:

        cd api
        npm install

3. Sao chép `.env.example` thành `.env` rồi điền giá trị thật (xem mục Biến môi trường).
4. Chạy server (mặc định cổng 3000):

        npm run dev

Server in ra `MongoDB Atlas connected` và `Server running on port 3000` khi chạy đúng.

## Biến môi trường (`api/.env`)

| Biến | Ý nghĩa |
|---|---|
| `PORT` | Cổng chạy server (mặc định 3000) |
| `MONGODB_URI` | Chuỗi kết nối MongoDB Atlas |
| `JWT_SECRET` | Chuỗi bí mật ký token đăng nhập |
| `JWT_EXPIRES_IN` | Thời hạn token, ví dụ `7d` |
| `SMTP_HOST` | Máy chủ gửi email, ví dụ `smtp.gmail.com` |
| `SMTP_PORT` | Cổng SMTP (587, hoặc 465 nếu dùng SSL) |
| `SMTP_USER` | Tài khoản gửi email |
| `SMTP_PASS` | Mật khẩu ứng dụng (với Gmail không dùng mật khẩu đăng nhập) |
| `SMTP_FROM` | Tên và địa chỉ người gửi, ví dụ `Task Manager <you@gmail.com>` |

Không đưa file `.env` lên Git. Thông tin SMTP chỉ nằm trong `.env`, không nằm trong mã nguồn. Khi chưa cấu hình SMTP, email được ghi vào lịch sử với trạng thái `failed` và các chức năng khác vẫn chạy bình thường. Sau khi sửa `.env` phải tắt và chạy lại server.

## Xác thực và quy ước

- Sau khi đăng nhập, gửi token trong header `Authorization: Bearer <token>` cho mọi API (trừ đăng ký và đăng nhập).
- `400`: dữ liệu không hợp lệ. `401`: thiếu hoặc sai token. `403`: có quyền xem nhưng không có quyền thực hiện thao tác. `404`: không tìm thấy, hoặc không có quyền xem (không tiết lộ công việc có tồn tại hay không).

## Phân quyền trên một công việc

| Thao tác | Người tạo | Chia sẻ quyền chỉnh sửa | Người được giao | Chia sẻ quyền chỉ xem |
|---|---|---|---|---|
| Xem | có | có | có | có |
| Sửa thông tin | có | có | không | không |
| Đổi trạng thái | có | có | có | không |
| Giao việc, hủy giao | có | có | không | không |
| Chia sẻ, đổi quyền, thu hồi | có | không | không | không |
| Xem lịch sử email, thử gửi lại | có | không | không | không |
| Xóa | có | không | không | không |

## Danh sách API

### Tài khoản (`/api/auth`)
- `POST /register`: đăng ký (`fullName`, `email`, `password`)
- `POST /login`: đăng nhập (`email`, `password`), trả về token
- `GET /me`: xem hồ sơ của mình
- `PUT /me`: cập nhật hồ sơ
- `PUT /change-password`: đổi mật khẩu

### Người dùng (`/api/users`)
- `GET /search`: tìm người dùng
- `GET /:id`: xem một người dùng

### Công việc (`/api/tasks`)
- `GET /`: danh sách; lọc theo `scope` (`created`, `assigned`, `shared`), `status`, `priority`, `q`, `assigneeId`; sắp xếp theo `sortBy` (`dueDate`, `priority`, `createdAt`) và `order`
- `POST /`: tạo công việc
- `GET /:id`: xem chi tiết
- `PUT /:id`: sửa thông tin
- `PATCH /:id/status`: đổi trạng thái (`todo`, `in_progress`, `completed`)
- `DELETE /:id`: xóa

### Giao việc (`/api/tasks/:id/assignees`)
- `GET /`: danh sách người được giao
- `POST /`: giao việc (`userIds` hoặc `emails`, tùy chọn `primaryAssigneeId`)
- `PATCH /:userId`: đặt hoặc bỏ người phụ trách chính (`isPrimary`)
- `DELETE /:userId`: hủy giao việc

### Chia sẻ (`/api/tasks/:id/shares`)
- `GET /`: danh sách chia sẻ
- `POST /`: chia sẻ (`userIds` hoặc `emails`, `permission`: `viewer` hoặc `editor`)
- `PATCH /:shareId`: đổi quyền
- `DELETE /:shareId`: thu hồi quyền

### Thông báo trong ứng dụng (`/api/notifications`)
- `GET /`: danh sách của mình (`limit`, `unreadOnly`)
- `GET /unread-count`: số thông báo chưa đọc
- `PATCH /read-all`: đánh dấu tất cả đã đọc
- `PATCH /:id/read`: đánh dấu một thông báo đã đọc

Các loại thông báo: `task_assigned`, `task_shared`, `due_date_changed`, `task_status_changed`, `task_completed`, `due_soon`.

### Email
- `GET /api/tasks/:id/email-logs`: lịch sử email của công việc (chỉ người tạo)
- `POST /api/email-logs/:id/retry`: thử gửi lại email `failed` (chỉ người tạo, tối đa 3 lần gửi tổng cộng)

Email được gửi khi: giao việc, chia sẻ, đổi hạn hoàn thành, hoàn thành công việc, và nhắc việc sắp đến hạn. Đổi sang trạng thái khác `completed` chỉ tạo thông báo trong ứng dụng, không gửi email.

### Lịch sử hoạt động
- `GET /api/tasks/:id/activities`: lịch sử của công việc, mới nhất trước (`limit` từ 1 đến 200, mặc định 50). Ghi lại: tạo, sửa (giá trị cũ và mới), đổi trạng thái, giao việc, đổi người phụ trách chính, hủy giao, chia sẻ, đổi quyền, thu hồi quyền.

### Thống kê (`/api/statistics`)
- `GET /tasks`: tổng số, theo trạng thái, theo vai trò (tạo, được giao, được chia sẻ)
- `GET /assignments`: việc được giao cho mình, việc mình phụ trách chính, việc mình đã giao cho người khác
- `GET /deadlines`: việc quá hạn và việc sắp đến hạn (`days` từ 1 đến 30, mặc định 3; `limit` từ 1 đến 100, mặc định 20)

## Nhắc việc trước hạn

Khi server chạy, cứ 10 phút hệ thống quét các công việc chưa hoàn thành có hạn trong 24 giờ tới, rồi tạo thông báo và gửi email cho người tạo, người được giao và người được chia sẻ. Mỗi hạn chỉ nhắc một lần; nếu hạn bị đổi thì được nhắc lại cho hạn mới.
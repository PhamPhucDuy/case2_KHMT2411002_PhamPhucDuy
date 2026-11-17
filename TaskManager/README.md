# Task Manager

- Họ tên: Phạm Phúc Duy
- MSSV: KHMT2411002
- Đề tài: Case Study 2 – Ứng dụng quản lý và giao việc nhóm

## Công nghệ
- Mobile: Flutter (Android Studio)
- API: Node.js, Express, Mongoose
- CSDL: MongoDB Atlas
- Email: Nodemailer (SMTP)

## Cấu trúc thư mục
```
api/      Server Node.js
mobile/   Ứng dụng Flutter
```

## Chạy API
```bash
cd api
npm install
copy .env.example .env   # rồi điền giá trị thật
npm run dev
```
Server chạy tại http://localhost:3000. Khi chạy emulator Android, dùng http://10.0.2.2:3000.

## Danh sách API
Tất cả API (trừ đăng ký, đăng nhập) cần header `Authorization: Bearer <token>`.

| Nhóm | Endpoint |
|---|---|
| Xác thực | POST /api/auth/register, POST /api/auth/login, GET /api/auth/me |
| Công việc | GET/POST /api/tasks, GET/PUT/DELETE /api/tasks/:id, PATCH /api/tasks/:id/status |
| Giao việc | /api/tasks/:id/assignees |
| Chia sẻ | /api/tasks/:id/shares |
| Thông báo | GET /api/notifications, GET /api/notifications/unread-count, PATCH /api/notifications/:id/read, PATCH /api/notifications/read-all |
| Lịch sử email | GET /api/tasks/:id/email-logs, POST /api/email-logs/:id/retry |

## Phân quyền
Người tạo (owner), người chỉnh sửa (editor), người được giao (assignee), người chỉ xem (viewer).
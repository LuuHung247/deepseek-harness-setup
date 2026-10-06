# deepseek-harness-setup

Cài và chạy [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`, gói npm `@deepseek-ai/dsh`) như một dịch vụ nền: chạy dưới pm2, cổng cố định, truy cập bằng `http://localhost`.

Bản này mới có phần **Windows**. Thư mục `linux/` để trống, chưa làm.

```
windows/
  ecosystem.config.js        pm2 app: node.exe bin.js web --no-open --port 47831
  open-dsh.ps1               bật dsh nếu chưa chạy, lấy link token mới nhất rồi mở trình duyệt
  setup-portproxy-admin.ps1  (cần admin) portproxy 127.0.0.1:80 -> 47831
linux/                       trống
```

## Windows

Yêu cầu: Node.js 20+ (đã thử với 24), PowerShell 5.1.

### 1. Cài dsh và pm2

```powershell
npm install -g @deepseek-ai/dsh pm2
```

`dsh` không có TUI. Các profile có sẵn: `web`, `headless`, `acp`, `sdk`, `sdk-minimal`.

### 2. Chép file cấu hình

```powershell
New-Item -ItemType Directory -Force $env:USERPROFILE\.dsh-pm2, $env:USERPROFILE\dsh-test | Out-Null
Copy-Item .\windows\* $env:USERPROFILE\.dsh-pm2\
```

`dsh-test` là thư mục làm việc mặc định của tiến trình, đổi trong `ecosystem.config.js` nếu muốn.

### 3. Chạy dưới pm2

```powershell
pm2 start $env:USERPROFILE\.dsh-pm2\ecosystem.config.js
pm2 save
```

Phải để pm2 gọi thẳng `node.exe`. Nếu trỏ `script` vào `bin.js`, pm2 báo online nhưng dsh không chạy (đoạn kiểm tra "chạy trực tiếp" của `bin.js` không kích hoạt qua wrapper của pm2).

Cổng **47831** nằm dưới dải cổng động của Windows (49152+) và không thuộc dải Hyper-V loại trừ (kiểm tra bằng `netsh int ipv4 show excludedportrange protocol=tcp`).

### 4. Tự khôi phục khi đăng nhập Windows

```powershell
$act = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -Command `"& '$env:APPDATA\npm\pm2.cmd' resurrect`""
$trg = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "pm2-resurrect" -Action $act -Trigger $trg -Settings $set -Force
```

### 5. Gõ `http://localhost` không cần số cổng (cần admin, tùy chọn)

Chạy trong PowerShell **Run as administrator**:

```powershell
powershell -ExecutionPolicy Bypass -File $env:USERPROFILE\.dsh-pm2\setup-portproxy-admin.ps1
```

`netsh interface portproxy` chuyển `127.0.0.1:80` sang `127.0.0.1:47831`. Không làm bước này thì dùng `http://127.0.0.1:47831`.

Gỡ portproxy khi cần cổng 80 trên loopback:

```powershell
netsh interface portproxy delete v4tov4 listenaddress=127.0.0.1 listenport=80
```

### 6. Mở web

```powershell
.\windows\open-dsh.ps1                            # trình duyệt mặc định
.\windows\open-dsh.ps1 -ChromeProfile "Profile 1" # một profile Chrome
.\windows\open-dsh.ps1 -AllChromeProfiles         # mọi profile Chrome
```

Lần đầu vào, nhập API key DeepSeek ở **Settings > Models**.

## Vì sao dùng `localhost`, không dùng domain tự đặt

dsh chỉ coi `localhost`, `[::1]` và IPv4 dạng `127.x.x.x` là "máy của bạn" (`packages/client/connection/src/loopback-hostname.ts`). Với hostname khác, ví dụ `deepseek.harness.local` trỏ về 127.0.0.1 trong file hosts, trang chạy ở chế độ không phải loopback:

- thiếu các trang cấu hình Host trong Plugins (Shell, Agent loop, Subagent, Web search): thấy 4 mục thay vì 8
- cài đặt Host chỉ giữ tạm trong trình duyệt (chế độ `memory`), không lưu bền, kể cả API key

`--trusted-host` chỉ cho `/api` qua hàng rào Host, không bật cờ loopback. Không có cấu hình nào đổi được điều này, chỉ có cách sửa code của dsh.

Nếu trước đây bạn đã dùng bản setup cũ của repo này với `deepseek.harness.local`: chạy `setup-portproxy-admin.ps1` (nó xóa dòng hosts cũ), chép lại `ecosystem.config.js` rồi `pm2 restart dsh-web`.

## Về token đăng nhập

- dsh sinh token ngẫu nhiên mỗi lần **khởi động** và không có tùy chọn đặt cố định. Đây là thiết kế bảo mật của dsh.
- Trình duyệt vào bằng link có `?token=...` sẽ nhận cookie ký sẵn (`dsh-auth-<hash>`). Cookie được tách theo từng trình duyệt/profile và theo từng `host:port`, nên `localhost` và `127.0.0.1:47831` là hai phiên khác nhau.
- Sau khi dsh khởi động lại (reboot, `pm2 restart`), chạy lại `open-dsh.ps1` để lấy link mới. Xem link thủ công: `pm2 logs dsh-web --nostream`.
- Đừng chia sẻ link có token.

## Lưu ý

- DeepSeek Harness 0.2 là bản developer preview, sẽ còn thay đổi làm hỏng tương thích.
- Terminal tích hợp trong web cần `node-pty`. npm có thể chặn script cài của gói này, xem `npm approve-scripts`.
- `open-dsh.ps1` tìm Chrome ở `C:\Program Files\Google\Chrome\Application\chrome.exe`.

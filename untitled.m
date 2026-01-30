clc; clear; close all;

% --- CẤU HÌNH ---
filename = 'raw_capture.dat';
sps = 4; % Phải khớp với sps lúc tạo file phát

% 1. ĐỌC FILE
fid = fopen(filename, 'r');
if fid == -1, error('Không tìm thấy file!'); end
c = fread(fid, 'float32'); % Nên dùng float32 cho chuẩn xác
fclose(fid);

% 2. TÁCH I/Q
c1 = c(1:2:end);
c2 = c(2:2:end);
cc = c1 + 1j*c2; % Tín hiệu đầy đủ (Waveform)

% 3. LẤY MẪU (DOWNSAMPLING) ĐỂ XEM 4 ĐIỂM
% Do bộ lọc RRC có độ trễ (delay), điểm đẹp nhất thường nằm ở mẫu thứ 1 hoặc thứ sps
% Ta lấy cứ 4 mẫu thì nhặt 1 mẫu (bắt đầu từ mẫu thứ 1)
cc_downsampled = downsample(cc, sps); 

% ... (Giữ nguyên đoạn đọc file và downsample) ...

% CẮT BỎ "ĐẦU" VÀ "ĐUÔI"
% Bỏ 50 mẫu đầu tiên (lúc khởi động) và 50 mẫu cuối (lúc tắt)
so_mau_bo_qua = 50; 

if length(cc_downsampled) > 2*so_mau_bo_qua
    cc_clean = cc_downsampled(so_mau_bo_qua : end-so_mau_bo_qua);
else
    cc_clean = cc_downsampled; % File ngắn quá thì thôi không cắt
end

% VẼ LẠI
figure;
plot(cc_clean, 'r.', 'MarkerSize', 15); % Vẽ điểm to lên cho rõ
axis square; grid on; xlim([-1.5 1.5]); ylim([-1.5 1.5]);
title('Chòm sao sau khi cắt bỏ phần khởi động');
xlabel('I'); ylabel('Q');
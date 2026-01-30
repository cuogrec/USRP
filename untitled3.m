% --- CODE 2: GIẢI MÃ TÍN HIỆU THU ---
clc; clear; close all;

% --- CẤU HÌNH ---
filename = 'raw_capture.dat';
Fs = 1e6;        % Sample Rate (Phải khớp với GNU Radio thu)
Rs = Fs / 4;     % Symbol Rate (Giả sử sps = 4)
sps = 4;         % 

% 1. ĐỌC FILE RAW
fid = fopen(filename, 'rb'); %Mở file chế độ đọc nhị phân 
if fid == -1, error('Chưa có file thu!'); end
% Chỉ đọc 1 phần file để xử lý cho nhanh (ví dụ 1 triệu mẫu)
raw = fread(fid, [2, 300000], 'float32'); %Đọc ma trận 2 hàng, hàng 1 I , hàng 2 Q 
fclose(fid);
rx_sig = raw(1,:) + 1j*raw(2,:); %Tái tạo tín hiệu phức 
rx_sig = rx_sig.'; % Chuyển từ vector hàng thành cột


% 2. ĐỒNG BỘ TẦN SỐ THÔ (Coarse Frequency Sync)
% Bù lại sự sai lệch tần số giữa 2 USRP
coarseSync = comm.CoarseFrequencyCompensator(...
    'Modulation','QPSK', ...
    'SampleRate', Fs, ...
    'FrequencyResolution', 1e3);
[rx_coarse, freq_offset] = coarseSync(rx_sig);
fprintf('Đã bù lệch tần số: %.2f Hz\n', freq_offset);

% 3. LỌC PHỐI HỢP (Matched Filter)
% Dùng bộ lọc giống hệt bên phát
rx_filter = rcosdesign(0.35, 6, sps); 
rx_filtered = conv(rx_coarse, rx_filter, 'same'); %Tích chập tín hiệu với bộ lọc 

% 4. ĐỒNG BỘ THỜI GIAN (Symbol Sync)
% Tìm đúng đỉnh của symbol để lấy mẫu 
% Tương đương khối Symbol Sync trong GNU Radio
% Từ 4 sps thành 1 sps 
symbolSync = comm.SymbolSynchronizer(...
    'TimingErrorDetector', 'Gardner (non-data-aided)', ...
    'SamplesPerSymbol', sps);
rx_syms = symbolSync(rx_filtered);

% 5. ĐỒNG BỘ PHA TINH CHỈNH (Costas Loop)
% Khóa pha, giữ chòm sao đứng yên tại 4 góc 
% Tương đương khối Costas Loop
carrierSync = comm.CarrierSynchronizer(...
    'Modulation', 'QPSK', ...
    'SamplesPerSymbol', 1, ...
    'DampingFactor', 0.7, ...
    'NormalizedLoopBandwidth', 0.01);
rx_sync_final = carrierSync(rx_syms);


% 6. TÌM KIẾM PREAMBLE (Frame Sync)
% Tạo lại preamble mẫu để so sánh
barker = [1 1 1 1 1 -1 -1 1 1 -1 1 -1 1]; 
% Map Barker sang QPSK symbol để tương quan (giả sử góc pha 0)
% (Bước này hơi phức tạp vì QPSK có thể bị xoay 90, 180, 270 độ)
% Để đơn giản, ta sẽ giải mã sang bit rồi tìm chuỗi bit Barker

% --- Giải điều chế QPSK ---
% Xử lý nhập nhằng pha 4 hướng (0, 90, 180, 270)
phase_shifts = [0, pi/2, pi, -pi/2]; % Thử xoay tín hiệu theo 4 hướng 
found_msg = false; % Cờ đánh dấu xem tìm thấy tin nhắn chưa 

fprintf('\n--- ĐANG QUÉT TÌM TIN NHẮN ---\n');

% Vòng lặp thử 4 trường hợp xoay pha 
for p = 1:4
    % Xoay toàn bộ tín hiệu đi 1 góc phase_shift(p)
    rotated = rx_sync_final * exp(1j * phase_shifts(p));
    
    % Slicing ra bit
    bits_out = [];
    % Logic giải mã khớp với code phát
    for k=1:length(rotated)
        re = real(rotated(k)); im = imag(rotated(k));
        val = 0;
        %Logic ánh xạ ngược 
        if re<0 && im<0, val=0;      % 00
        elseif re<0 && im>0, val=1;  % 01
        elseif re>0 && im<0, val=2;  % 10
        elseif re>0 && im>0, val=3;  % 11
        end
        % Đổi val sang 2 bit
        bits_out = [bits_out, bitget(val, 2), bitget(val, 1)];
    end
    
    % Tìm chuỗi Barker trong luồng bit (Correlator)
    preamble_seq = (barker + 1) / 2; % 1 1 1 1 1 0 0 ...
    idx = strfind(bits_out, [preamble_seq preamble_seq]); % Tìm 2 preamble liên tiếp
    
    if ~isempty(idx)
        start_idx = idx(1) + length(preamble_seq)*5; % Nhảy qua 5 cái preamble
        
        % --- ĐOẠN CODE MỚI (SỬA LỖI) ---
% Kiểm tra xem còn đủ dữ liệu để đọc không
if start_idx < length(bits_out)
    
    % SỬA Ở ĐÂY: Tăng số lượng ký tự muốn đọc lên 200 (hoặc 500 tùy thích)
    so_ky_tu_muon_doc = 200; 
    
    % Tính toán điểm kết thúc an toàn (tránh lỗi vượt quá độ dài file)
    end_idx = min(start_idx + 8*so_ky_tu_muon_doc, length(bits_out));
    
    % Lấy dữ liệu bit
    data_bits = bits_out(start_idx : end_idx);
    
    % Gom bit thành char (Giữ nguyên logic cũ)
    msg_str = '';
    % Đảm bảo chia hết cho 8 bit
    num_chars = floor(length(data_bits)/8);
    
    % --- ĐOẠN CODE MỚI (TỰ ĐỘNG NGẮT KHI GẶP #) ---
    msg_str = '';
    for c = 1:num_chars
        % 1. Lấy 8 bit
        b8 = data_bits((c-1)*8+1 : c*8);
        
        % 2. Tính giá trị ký tự
        char_val = sum(b8 .* [128 64 32 16 8 4 2 1]);
        ky_tu = char(char_val);
        
        % 3. KIỂM TRA ĐIỀU KIỆN DỪNG (QUAN TRỌNG NHẤT)
        if ky_tu == '#'
            break; % Lệnh này giúp thoát khỏi vòng lặp ngay lập tức
        end
        
        % 4. Nếu không phải # thì mới ghép vào chuỗi
        msg_str = [msg_str, ky_tu];
    end
    
    fprintf('>> TÌM THẤY (Góc xoay %d độ): %s\n', round(rad2deg(phase_shifts(p))), msg_str);
    found_msg = true;
end
    end
end

if ~found_msg
    disp('Không tìm thấy tin nhắn. Hãy kiểm tra Gain hoặc thử ghi lại dài hơn.');
end
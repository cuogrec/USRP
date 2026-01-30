% --- CODE 1: TẠO FILE PHÁT ---
clc; clear;

% Cấu hình
sps = 4;           % Samples per Symbol
message = ['HAPPY NEW YEAR 2026 chuc mung sinh nhat nun na na na anh do mi xo###']; 

% 1. Tạo Preamble (Chuỗi Barker 13 bit để đồng bộ)
% Đây là để máy thu tìm thấy tin nhắn
barker = [1 1 1 1 1 -1 -1 1 1 -1 1 -1 1]; 
preamble_bits = (barker + 1) / 2; % Đổi về 0/1
preamble_rep = repmat(preamble_bits, 1, 5); % Lặp lại 5 lần cho chắc

% 2. Chuyển tin nhắn thành bit
msg_uint8 = uint8(message); %chuyển chữ cái sang mã ascii 
msg_bits = reshape(dec2bin(msg_uint8, 8).' - '0', 1, []); %mã ascii thành nhị phân 

% 3. Ghép: [Preamble] + [Tin nhắn]
tx_bits = [preamble_rep, msg_bits];

% 4. Điều chế QPSK
% Map: 00->(-1-1i), 01->(-1+1i), 10->(1-1i), 11->(1+1i)
% (Đơn giản hóa không dùng Gray để code ngắn gọn)
tx_syms = [];
for i = 1:2:length(tx_bits)-1 %QPSK cần 2 bit tạo 1 symbol nên nhảy cóc 2 bước 1 
    bit_pair = tx_bits(i)*2 + tx_bits(i+1); %Gom 2 bit tạo thành 1 cặp 
    switch bit_pair %Gán tọa độ 
        case 0, pt = -1-1j;
        case 1, pt = -1+1j;
        case 2, pt =  1-1j;
        case 3, pt =  1+1j;
    end
    tx_syms = [tx_syms, pt];
end

% 5. Tạo xung (Pulse Shaping)
filter_coeffs = rcosdesign(0.35, 6, sps);%Tạo bộ lọc làm mượt 
tx_signal = upfirdn(tx_syms, filter_coeffs, sps);%Chèn điểm mẫu để đạt sps = 4 ; Lọc làm mượt các cạnh 
tx_signal = tx_signal / max(abs(tx_signal)); % Chuẩn hóa biên độ

% 6. Lưu file
fid = fopen('tx_signal.dat', 'wb');
% Lưu dạng interleaved I, Q, I, Q...
temp = zeros(1, 2*length(tx_signal));
temp(1:2:end) = real(tx_signal); %Hàng lẻ là thực I
temp(2:2:end) = imag(tx_signal); %Hàng chẵn là ảo Q 
fwrite(fid, temp, 'float32');
fclose(fid);

disp('Đã tạo file tx_signal.dat. Hãy phát file này bằng GNU Radio!');
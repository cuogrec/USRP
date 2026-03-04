# USRP
# python3 Padded_File_Source.py Hello.txt

Hướng dẫn sử dụng sơ đồ truyền dẫn tín hiệu qpsk

Lưu ý : Đây là sơ đồ thu phát trên 1 USRP

1.Tải file python Padded_File_Source.py và REAL_QPSK.grc

2.Chuẩn bị sẵn 1 file là Hello.txt mang thông tin muốn truyền

3.Ctrl + Alt + T ; gõ lệnh python3 Padded_File_Source.py Hello.txt ; do khối stream to tagged stream có độ dài gói là 252 byte nên sau khi dùng code python sẽ sinh ra file Padded.txt với dung lượng 252 byte

(HOẶC CÓ THỂ gõ python3 rồi kéo thả 2 file vào command)

<img width="1441" height="574" alt="image" src="https://github.com/user-attachments/assets/c39e55e4-d0ab-4e10-8ca4-3a7e2e9d8062" />

4.Vào khối file source chọn đúng địa chỉ của file Padded.txt

<img width="554" height="454" alt="image" src="https://github.com/user-attachments/assets/08c5278f-e101-4485-a577-63e8629b1aa7" />

5.Vào khối file sink chọn địa chỉ muốn nhận output

<img width="554" height="454" alt="image" src="https://github.com/user-attachments/assets/c23bc945-6cda-4d77-9400-793ee8940bad" />

6.Nếu muốn mô phỏng thì để lại 2 khối virtual sink và virtual source, còn chạy trên usrp thì disable 2 khối đó đi, enable UHD : USRP Sink và UHD : USRP Source vào vị trí tương ứng

7.CHẠY CHƯƠNG TRÌNH



--1. Thủ tục tính tổng doanh thu 
create or alter  proc TongDoanhThu_Ngay ( @Loaithoigian nvarchar(15))
as
begin 
	if @Loaithoigian = 'Ngay'
		begin
			select NgayMua, SUM(TongTien) as TongDoangThu from Don_Hang
			group by NgayMua
			order by NgayMua
		end
	else if @Loaithoigian = 'Tuan'
		begin
			select datepart(year, Ngaymua) as Nam, datepart(week, NgayMua) as Tuan, SUM(TongTien) as TongDoangThu from Don_Hang
			group by datepart(year, Ngaymua), datepart(week, NgayMua) 
			order by Nam, Tuan
		end
	else if @Loaithoigian = 'Thang'
		begin 
			select DATEPART(YEAR, NgayMua) AS Nam, DATEPART(MONTH, NgayMua) AS Thang, SUM(TongTien) as TongDoangThu from Don_Hang
			group by DATEPART(YEAR, NgayMua), DATEPART(MONTH, NgayMua)
			order by Nam, Thang
		end
	else if @Loaithoigian = 'Nam'
		begin 
			select DATEPART(YEAR, NgayMua) AS Nam, SUM(TongTien) as TongDoangThu from Don_Hang
			group by DATEPART(YEAR, NgayMua) 
			order by Nam
		end
	else
		begin
			print ('Loai thoi gian khong hop le')
		end
end
go

exec TongDoanhThu_Ngay 'Thang'
--2.Thủ tục tính tổng đơn hàng
Create or alter proc Tinhtongdonhang
    @Thoigian nvarchar(10)
as
begin
    if @Thoigian not in ('Ngay', 'Tuan', 'Thang', 'Nam')
    begin
        print 'Thời gian không hợp lệ';
        return
    end
    select 
        case 
            when @Thoigian = 'Ngay' then convert(varchar, Ngaymua, 23)
            when @Thoigian = 'Tuan' then cast(year(Ngaymua) as varchar) + '-' + cast(datepart(week, Ngaymua) as varchar)
            when @Thoigian = 'Thang' then cast(year(Ngaymua) as varchar) + '-' + cast(datepart(month, Ngaymua) as varchar)
            when @Thoigian = 'Nam' then cast(year(Ngaymua) as varchar)
        end as Thoigian,
        count(MaDonHang) as Tongdonhang
    from Don_Hang
    group by 
        case 
            when @Thoigian = 'Ngay' then convert(varchar, Ngaymua, 23)
            when @Thoigian = 'Tuan' then cast(year(Ngaymua) as varchar) + '-' + cast(datepart(week, Ngaymua) as varchar)
            when @Thoigian = 'Thang' then cast(year(Ngaymua) as varchar) + '-' + cast(datepart(month, Ngaymua) as varchar)
            when @Thoigian = 'Nam' then cast(year(Ngaymua) as varchar)
        end
end

exec Tinhtongdonhang 'Thang'
exec Tinhtongdonhang 'Tuan'
exec Tinhtongdonhang 'Ngay'
exec Tinhtongdonhang 'Nam'
--3.Thủ tục tính số lượng món
CREATE or alter PROCEDURE Tinh_So_Luong_Mon_Theo_Thoi_Gian
(
    @LoaiThoiGian NVARCHAR(15)  -- Giá trị có thể là 'Ngay', 'Tuan', 'Thang'
)
AS
BEGIN
    IF @LoaiThoiGian = N'Ngày'
    BEGIN
        SELECT DH.NgayMua, SUM(DCT.SoLuong) AS TongSoLuong
        FROM Don_Hang_Chi_Tiet DCT
        JOIN Don_Hang DH ON DCT.MaDonHang = DH.MaDonHang
        GROUP BY DH.NgayMua
        ORDER BY DH.NgayMua;
    END
    ELSE IF @LoaiThoiGian = N'Tuần'
    BEGIN
        SELECT DATEPART(YEAR, DH.NgayMua) AS Nam, DATEPART(WEEK, DH.NgayMua) AS Tuan, SUM(DCT.SoLuong) AS TongSoLuong
        FROM Don_Hang_Chi_Tiet DCT
        JOIN Don_Hang DH ON DCT.MaDonHang = DH.MaDonHang
        GROUP BY DATEPART(YEAR, DH.NgayMua), DATEPART(WEEK, DH.NgayMua)
        ORDER BY Nam, Tuan;
    END
    ELSE IF @LoaiThoiGian = N'Tháng'
    BEGIN
        SELECT DATEPART(YEAR, DH.NgayMua) AS Nam, DATEPART(MONTH, DH.NgayMua) AS Thang, SUM(DCT.SoLuong) AS TongSoLuong
        FROM Don_Hang_Chi_Tiet DCT
        JOIN Don_Hang DH ON DCT.MaDonHang = DH.MaDonHang
        GROUP BY DATEPART(YEAR, DH.NgayMua), DATEPART(MONTH, DH.NgayMua)
        ORDER BY Nam, Thang;
    END
    ELSE
    BEGIN
        PRINT N'Loại thời gian không hợp lệ. Vui lòng chọn "Ngay", "Tuan", hoặc "Thang".';
    END
END;
GO

EXEC Tinh_So_Luong_Mon_Theo_Thoi_Gian N'Ngày';  
EXEC Tinh_So_Luong_Mon_Theo_Thoi_Gian N'Tuần'; 
EXEC Tinh_So_Luong_Mon_Theo_Thoi_Gian N'Tháng'; 
--4.Thủ tục tính tổng tiền đơn hàng
create or alter proc TinhTongTienDH(@maDH CHAR(10), @sl int, @dongia numeric(15,0))
as
begin
	if @sl < 0
	begin
		print N'Số lượng không nhỏ hơn 0'
		RETURN
	end
	ELSE
	BEGIN
		UPDATE Don_Hang
		set TongTien = TongTien + @sl * @dongia
		WHERE MaDonHang = @maDH
		print N'Tính tiền đơn hàng thành công'
	END
end 
exec TinhTongTienDH 'DH00000003', 3, 100
exec TinhTongTienDH 'DH00000010', 4, 100
exec TinhTongTienDH 'DH00000010', -4, 100
select * from Don_Hang
--5.Thủ tục tạo đơn hàng
CREATE or alter PROCEDURE TaoDonHang
    @NgayMua DATE,
    @DiaChi NVARCHAR(100),
    @TongTien FLOAT,
    @SoBan CHAR(5),
    @GioThanhToan TIME
AS
BEGIN
	declare @MaDonHang CHAR(10)
	set @MaDonHang = dbo.Tao_Ma_Don_Hang_Tu_Dong()
    IF NOT EXISTS (SELECT 1 FROM Ban WHERE SoBan = @SoBan)
    BEGIN
        print('XX So ban khong ton tai!');
        RETURN;
    END
    INSERT INTO Don_Hang (MaDonHang, NgayMua, DiaChi, TongTien, SoBan, GioThanhToan)
    VALUES (@MaDonHang, @NgayMua, @DiaChi, @TongTien, @SoBan, @GioThanhToan);
    
    PRINT ('Them don hang thanh cong!');
END;
GO

exec TaoDonHang 
				@NgayMua = '2024-10-17',
				@DiaChi = N'123 Đường ABC',
				@TongTien = 600000,
				@SoBan = 'B0001',
				@GioThanhToan = '12:30:00';
select * from Don_Hang where NgayMua = '2024-10-17'
--6.Trigger cập nhật menu(chưa chạy được)
CREATE or alter  TRIGGER Capnhatmenu
ON Thuc_Don 
AFTER UPDATE
AS
BEGIN
    DECLARE @MaSP CHAR(10), @TenSP NVARCHAR(50), @AnhSP VARBINARY(MAX), @GiaSP FLOAT;

    SELECT @MaSP = MaSP, @TenSP = TenSP, @AnhSP = AnhSP, @GiaSP = GiaSP
    FROM inserted;
    EXEC Capnhatmenu @MaSP, @TenSP, @AnhSP, @GiaSP;
END;

select* from Thuc_don
--7.Thủ tục xóa món trong menu
CREATE or alter PROCEDURE Xoa_Mon_Trong_Thuc_Don
(
    @MaSP CHAR(10)
)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Thuc_don WHERE MaSP = @MaSP)
    BEGIN
        DELETE FROM Thuc_don
        WHERE MaSP = @MaSP;

        PRINT 'Đã xóa món thành công.';
    END
    ELSE
    BEGIN
        PRINT 'Mã sản phẩm không tồn tại.';
    END
END;

EXEC Xoa_Mon_Trong_Thuc_Don 'SP000001';
--8.Thủ tục thêm món trong menu
create or alter proc ThemMon( @TenSP nvarchar(50), @AnhSP VARBINARY(MAX), @GiaSP numeric(15,0))
as
begin
	DECLARE @MaSP NVARCHAR(50);
	SET @MaSP = dbo.Tao_Ma_San_Pham_Tu_Dong();
	if exists (select 1 from Thuc_don where MaSP = @MaSP)
	begin
		print N'Món này đã tồn tại rồi'
		return
	end
	
	ELSE
	begin
		Insert into Thuc_don(MaSP, TenSP, AnhSP, GiaSP)
		VALUES (@MaSP, @TenSP, @AnhSP, @GiaSP)
		PRINT N'Đã thêm mới món thành công'
	end
end

DECLARE @PIC_SP VARBINARY(MAX)
SET @PIC_SP = 0xFFD8FFE000104A464946
EXEC ThemMon  N'Trà Sữa Trân Châu đường đen', @PIC_SP, 7000

DECLARE @PIC_SP2 VARBINARY(MAX)
SET @PIC_SP2 = 0xFFD8FFE000104A464946
EXEC ThemMon  N'Nước chanh', @PIC_SP2, 5000
select*from Thuc_don where MaSP = 'SP001010'
--9.Thủ tục chỉnh sửa món trong menu
CREATE or alter PROCEDURE ChinhSuaMon
    @MaSP CHAR(10),
    @TenSP NVARCHAR(50),
    @AnhSP VARBINARY(MAX),
    @GiaSP FLOAT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Thuc_don WHERE MaSP = @MaSP)
    BEGIN
		print ('Ma san pham khong ton tai!');
        RETURN;
    END
    UPDATE Thuc_don
    SET 
        TenSP = @TenSP,
        AnhSP = @AnhSP,
        GiaSP = @GiaSP
    WHERE 
        MaSP = @MaSP;

    PRINT 'Chinh sua thong tin thanh cong!';
END;
GO

exec ChinhSuaMon @MaSP = 'SP000001',
				 @TenSP = N'Tra Sua Tran Chau',
				 @AnhSP = 0x89504E00,
				 @GiaSP = 60000;
select * from Thuc_don
--10.Thủ tục xóa đơn hàng
create or alter  PROc XoaDonHang
    @MaDonHang CHAR(10)
as
begin
    if not exists (select 1 FROM Don_Hang WHERE MaDonHang = @MaDonHang)
    begin
        print N'Mã đơn hàng không tồn tại!';
        return
    end
    delete from Don_Hang_Chi_Tiet WHERE MaDonHang = @MaDonHang
    delete from Phuong_Thuc_Thanh_Toan WHERE MaDonHang = @MaDonHang
    delete from Don_Hang WHERE MaDonHang = @MaDonHang
    PRINT 'Đã xóa đơn hàng thành công!';
END
select*from Don_Hang
exec XoaDonHang 'DH00000001'
--11.Trigger cập nhật Tổng tiền trong bảng Đơn hàng 
CREATE or alter TRIGGER Cap_Nhat_Tong_Tien_Don_Hang
ON Don_Hang_Chi_Tiet
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    DECLARE @MaDonHang CHAR(10);
    DECLARE @TongTien decimal(10,2);
    SELECT @MaDonHang = COALESCE(i.MaDonHang, d.MaDonHang)
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.MaDonHang = d.MaDonHang;

    SELECT @TongTien = SUM(ThanhTien)
    FROM Don_Hang_Chi_Tiet
    WHERE MaDonHang = @MaDonHang;

    UPDATE Don_Hang
    SET TongTien = COALESCE(@TongTien, 0) 
    WHERE MaDonHang = @MaDonHang;
END;
--chèn
update Don_Hang_Chi_Tiet
set SoLuong = 2 
where MaDonChiTiet = 'DCT0000546'
select*from Don_Hang_Chi_Tiet where MaDonHang = 'DH00000924'
select*from Don_Hang where MaDonHang = 'DH00000924'
select*from Don_Hang_Chi_Tiet where MaDonHang = 'DH00000088'
--thêm

insert into Don_Hang_Chi_Tiet(MaDonChiTiet,SoLuong,ThanhTien,MaSP,MaDonHang)
values (dbo.Tao_Ma_Don_Chi_Tiet_Tu_Dong(), 2,45000,'SP000002','DH00000924')
select*from Don_Hang where MaDonHang = 'DH00000924'
select*from Don_Hang_Chi_Tiet where MaDonHang = 'DH00000924'
select*from Thuc_don
--xoa
DELETE FROM Don_Hang_Chi_Tiet 
WHERE MaDonChiTiet = 'DCT0000820';

--12. Thủ tục thay đổi thông tin chủ quán
create or alter proc ThayDoiTK(	@ten nvarchar(50), 
					@ngaysinh date, 
					@email nvarchar(50), 
					@dc nvarchar(100), 
					@anh varbinary(max), 
					@sdt char(10))
as
begin
	if not exists (select 1 from Chu_Quan where TenNguoiDung = @ten)
	begin
		print N'Người dùng này không tồn tại'
		return
	end

	IF NOT EXISTS (SELECT 1 FROM Tai_Khoan WHERE SoDienThoai = @sdt)
    BEGIN
        PRINT N'Số điện thoại này không tồn tại'
        RETURN
    END

	else if @ngaysinh > GETDATE()
	BEGIN
		print N'Ngày sinh phải nhỏ hơn hôm nay'
		return
	END
	else
	begin
		update Chu_Quan
		set Email = @email,
			NgaySinh = @ngaysinh,
			DiaChi = @dc,
			Anh = @anh,
			SoDienThoai = @sdt
		where TenNguoiDung = @ten
		print N'Thay đổi thông tin thành công'
	end
end

declare @picture varbinary(max)
set @picture = 0xFFD8FFE000104A464946
exec ThayDoiTK 'Nguoi dung 109', '2004-04-20', 'meowmeow01@gmail.com', N'Hòa Vang, Đà Nẵng', @picture, '0915486071'
--Nguoi Dung 109	nguoidung109@gmail.com	1991-07-29	Dia chi 109	0x3078	0915486071


declare @picture2 varbinary(max)
set @picture2 = 0xFFD8FFE000104A464949
exec ThayDoiTK 'Nguoi dung 1001', '2004-04-20', 'meowmeow01@gmail.com', N'Hòa Vang, Đà Nẵng', @picture2, '0915486071'
--13.Hàm tạo mã sản phẩm tự động
CREATE or alter FUNCTION Tao_Ma_San_Pham_Tu_Dong()
RETURNS CHAR(10)
AS
BEGIN
    DECLARE @MaSPMoi CHAR(10);
    DECLARE @SoThuTu INT;

    -- Lấy số thứ tự lớn nhất từ bảng Thuc_Don
    SELECT @SoThuTu = ISNULL(MAX(CAST(SUBSTRING(MaSP, 3, 6) AS INT)), 0) + 1
    FROM Thuc_Don;

    -- Tạo mã sản phẩm mới dựa trên số thứ tự tiếp theo, với định dạng SPxxxxxx (6 chữ số)
    SET @MaSPMoi = 'SP' + RIGHT('000000' + CAST(@SoThuTu AS VARCHAR(6)), 6);

    RETURN @MaSPMoi;
END;
GO
select dbo.Tao_Ma_San_Pham_Tu_Dong()
select*from Thuc_don
--14.Hàm tạo đơn hàng tự động
CREATE OR ALTER FUNCTION Tao_Ma_Don_Hang_Tu_Dong()
RETURNS CHAR(10)
AS
BEGIN
    DECLARE @MaDonHangMoi CHAR(10);
    DECLARE @SoThuTu INT;

    -- Lấy mã đơn hàng có giá trị lớn nhất hiện tại
    SELECT @SoThuTu = ISNULL(MAX(CAST(SUBSTRING(MaDonHang, 3, 8) AS INT)), 0) + 1
    FROM Don_Hang;

    -- Tạo mã đơn hàng mới dựa trên số thứ tự tiếp theo, với định dạng DHxxxxxxxx (8 chữ số)
    SET @MaDonHangMoi = 'DH' + RIGHT('00000000' + CAST(@SoThuTu AS VARCHAR(8)), 8);

    RETURN @MaDonHangMoi;
END;
GO
select dbo.Tao_Ma_Don_Hang_Tu_Dong()
select*from Don_Hang
--15.Hàm tạo mã đơn chi tiết tự động
CREATE OR ALTER FUNCTION Tao_Ma_Don_Chi_Tiet_Tu_Dong()
RETURNS CHAR(10)
AS
BEGIN
    DECLARE @MaDonChiTietMoi CHAR(10);
    DECLARE @SoThuTu INT;

    -- Lấy mã đơn chi tiết có giá trị lớn nhất hiện tại
    SELECT @SoThuTu = ISNULL(MAX(CAST(SUBSTRING(MaDonChiTiet, 4, 7) AS INT)), 0) + 1
    FROM Don_Hang_Chi_Tiet;

    -- Tạo mã đơn chi tiết mới dựa trên số thứ tự tiếp theo, với định dạng DCTxxxxxxx (7 chữ số)
    SET @MaDonChiTietMoi = 'DCT' + RIGHT('0000000' + CAST(@SoThuTu AS VARCHAR(7)), 7);

    RETURN @MaDonChiTietMoi;
END;
GO
select dbo.Tao_Ma_Don_Chi_Tiet_Tu_Dong()
select*from Don_Hang_Chi_Tiet
--trigger cập nhật thành tiền khi thay đổi số lượng ở bảng DCT
CREATE OR ALTER TRIGGER CapNhatThanhTien
ON Don_Hang_Chi_Tiet
AFTER INSERT, UPDATE
AS
BEGIN
    -- Cập nhật thành tiền cho các bản ghi mới thêm hoặc thay đổi số lượng
    UPDATE DCT
    SET DCT.ThanhTien = DCT.SoLuong * TD.GiaSP
    FROM Don_Hang_Chi_Tiet DCT
    INNER JOIN Thuc_don TD ON DCT.MaSP = TD.MaSP
    WHERE DCT.MaDonChiTiet IN (
        SELECT MaDonChiTiet
        FROM inserted
    );
END;

update Don_Hang_Chi_Tiet 
set SoLuong = 2
where MaDonChiTiet = 'DCT0000002'
select*from Thuc_don where MaSP = 'SP000200'
INSERT INTO Don_Hang_Chi_Tiet (MaDonChiTiet, SoLuong, ThanhTien, MaSP, MaDonHang)
VALUES (dbo.Tao_Ma_Don_Chi_Tiet_Tu_Dong(), 2,45787*2 , 'SP000854', 'DH00000088');
select*from Don_Hang_Chi_Tiet where MaDonHang = 'DH00000178'
select*from Don_Hang where MaDonHang = 'DH00000178'
update Don_Hang_Chi_Tiet
set SoLuong = 1
where MaDonChiTiet = 'DCT0001002'













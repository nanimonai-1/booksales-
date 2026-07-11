-- 1. 创建数据库
CREATE DATABASE IF NOT EXISTS book_sales DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE book_sales;

-- 1.1 角色类型表 admin_role
CREATE TABLE admin_role (
    role_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '角色ID主键',
    role_name VARCHAR(50) NOT NULL UNIQUE COMMENT '角色名称：超级管理员/货商管理员/客户管理员',
    description TEXT COMMENT '角色描述',
    permissions TEXT COMMENT '权限JSON',
    license TEXT COMMENT '操作许可范围',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT '管理员角色表';

-- 1.2 管理员表 admin
CREATE TABLE admin (
    admin_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '管理员ID，自增主键',
    admin_name VARCHAR(50) NOT NULL COMMENT '管理员姓名',
    role_id INT NOT NULL COMMENT '关联角色ID',
    admin_account VARCHAR(50) NOT NULL UNIQUE COMMENT '登录账号（唯一）',
    admin_password VARCHAR(255) NOT NULL COMMENT '加密存储的登录密码',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (role_id) REFERENCES admin_role(role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT '管理员账户信息表';

-- 1.3 图书信息表 book
CREATE TABLE book (
    book_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '图书ID，自增主键',
    book_name VARCHAR(100) NOT NULL COMMENT '图书名称',
    author VARCHAR(50) NOT NULL COMMENT '作者',
    publisher VARCHAR(50) NOT NULL COMMENT '出版社',
    retail_price DECIMAL(10, 2) NOT NULL COMMENT '零售价',
    admin_id INT COMMENT '操作管理员ID，仅超级管理员可操作',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (admin_id) REFERENCES admin(admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT '图书基础信息表';

-- 1.4 库存表 inventory（移除CHECK，兼容低版本MySQL）
CREATE TABLE inventory (
    book_id INT PRIMARY KEY COMMENT '图书ID，主键+外键',
    quantity INT NOT NULL DEFAULT 0 COMMENT '库存数量，不可为负数',
    status ENUM('正常', '预警', '缺货') DEFAULT '正常' COMMENT '库存状态',
    warning_threshold INT DEFAULT 10 COMMENT '库存预警阈值，默认10',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (book_id) REFERENCES book(book_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT '图书库存表';

-- 1.5 客户信息表 customer
CREATE TABLE customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '客户ID，自增主键',
    customer_name VARCHAR(50) NOT NULL COMMENT '客户姓名',
    contact_info VARCHAR(100) NOT NULL COMMENT '联系方式（手机/邮箱）',
    shipping_address TEXT NOT NULL COMMENT '收货地址',
    account VARCHAR(50) NOT NULL UNIQUE COMMENT '客户登录账号（唯一）',
    password VARCHAR(255) NOT NULL COMMENT '加密密码',
    admin_id INT COMMENT '操作管理员ID，客户/超级管理员维护',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (admin_id) REFERENCES admin(admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT '客户信息表';

-- 1.6 客户订单主表 customer_order
CREATE TABLE customer_order (
    order_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '订单ID，自增主键',
    customer_id INT NOT NULL COMMENT '客户ID外键',
    admin_id INT COMMENT '处理订单管理员ID',
    status ENUM('待支付', '已支付', '已发货', '已完成', '已取消') DEFAULT '待支付' COMMENT '订单状态',
    total_amount DECIMAL(10, 2) NOT NULL COMMENT '订单总金额',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '下单时间',
    payment_time TIMESTAMP NULL COMMENT '支付完成时间，未支付为空',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (admin_id) REFERENCES admin(admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT '客户销售订单主表';

-- 1.7 客户订单明细表 order_detail
CREATE TABLE order_detail (
    detail_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '明细自增主键',
    order_id INT NOT NULL COMMENT '关联订单ID',
    book_id INT NOT NULL COMMENT '关联图书ID',
    quantity INT NOT NULL COMMENT '购买数量，大于0',
    price DECIMAL(10, 2) NOT NULL COMMENT '销售单价',
    FOREIGN KEY (order_id) REFERENCES customer_order(order_id),
    FOREIGN KEY (book_id) REFERENCES book(book_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT '客户订单明细';

-- 1.8 供应商表 supplier
CREATE TABLE supplier (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '供应商ID主键',
    supplier_name VARCHAR(100) NOT NULL UNIQUE COMMENT '供应商名称',
    contact_info VARCHAR(100) NOT NULL COMMENT '供应商联系方式',
    is_blacklisted BOOLEAN DEFAULT FALSE COMMENT '是否拉黑，默认false',
    admin_id INT COMMENT '操作管理员ID，仅超级管理员',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (admin_id) REFERENCES admin(admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT '图书供应商信息表';

-- 1.9 采购订单主表 purchase_order
CREATE TABLE purchase_order (
    purchase_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '采购订单ID主键',
    supplier_id INT NOT NULL COMMENT '供应商外键ID',
    admin_id INT COMMENT '操作管理员ID（超级/货商管理员）',
    total_amount DECIMAL(10, 2) NOT NULL COMMENT '采购总金额',
    status ENUM('待审核', '已确认', '已取消') NOT NULL COMMENT '采购订单状态',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id),
    FOREIGN KEY (admin_id) REFERENCES admin(admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT '图书采购订单主表';

-- 1.10 采购订单明细表 purchase_order_detail
CREATE TABLE purchase_order_detail (
    detail_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '采购明细主键',
    purchase_id INT NOT NULL COMMENT '采购订单ID外键',
    book_id INT NOT NULL COMMENT '图书ID外键',
    quantity INT NOT NULL COMMENT '采购数量',
    purchase_price DECIMAL(10, 2) NOT NULL COMMENT '采购单价',
    FOREIGN KEY (purchase_id) REFERENCES purchase_order(purchase_id),
    FOREIGN KEY (book_id) REFERENCES book(book_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT '采购订单明细';

-- 1.11 退货订单主表 return_order
CREATE TABLE return_order (
    return_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '退货单主键',
    order_id INT NOT NULL COMMENT '原订单ID外键',
    admin_id INT COMMENT '处理退货管理员ID',
    status ENUM('申请中', '已批准', '已拒绝', '已完成') DEFAULT '申请中' COMMENT '退货状态',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '退货申请时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (order_id) REFERENCES customer_order(order_id),
    FOREIGN KEY (admin_id) REFERENCES admin(admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT '客户退货订单主表';

-- 1.12 退货订单明细表 return_order_detail
CREATE TABLE return_order_detail (
    detail_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '退货明细主键',
    return_id INT NOT NULL COMMENT '退货单ID外键',
    book_id INT NOT NULL COMMENT '图书ID外键',
    quantity INT NOT NULL COMMENT '退货数量',
    FOREIGN KEY (return_id) REFERENCES return_order(return_id),
    FOREIGN KEY (book_id) REFERENCES book(book_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT '退货订单明细';

-- 1.13 操作日志表 operation_log
CREATE TABLE operation_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '日志主键',
    admin_id INT COMMENT '操作管理员ID',
    operation_type VARCHAR(50) NOT NULL COMMENT '操作类型：新增/修改/删除/查询/WARNING',
    operation_table VARCHAR(50) NOT NULL COMMENT '操作数据表名',
    record_id INT COMMENT '操作数据主键ID',
    operation_content TEXT COMMENT '操作详情描述',
    operation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
    FOREIGN KEY (admin_id) REFERENCES admin(admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT '管理员操作审计日志';

-- 1.14 用户注册信息表 registration_details
CREATE TABLE IF NOT EXISTS registration_details (
    registration_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '注册记录主键',
    username VARCHAR(50) NOT NULL UNIQUE COMMENT '登录用户名',
    password VARCHAR(255) NOT NULL COMMENT '加密密码',
    contact_info VARCHAR(100) NOT NULL COMMENT '联系方式',
    shipping_address TEXT NOT NULL COMMENT '收货地址',
    role_id INT NOT NULL COMMENT '角色ID外键',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
    FOREIGN KEY (role_id) REFERENCES admin_role(role_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT '用户注册信息总表';

-- 2. 索引创建语句
CREATE INDEX idx_book_name ON book(book_name);
CREATE INDEX idx_author ON book(author);
CREATE INDEX idx_publisher ON book(publisher);
CREATE INDEX idx_customer_order_status ON customer_order(status);
CREATE INDEX idx_customer_order_customer ON customer_order(customer_id);
CREATE INDEX idx_purchase_order_supplier ON purchase_order(supplier_id);
CREATE INDEX idx_inventory_status ON inventory(status);

-- 3. 视图创建
-- 3.1 货商管理员采购视图
CREATE VIEW supplier_admin_view AS
SELECT
    po.purchase_id,
    s.supplier_name,
    po.total_amount,
    po.status,
    po.created_at,
    GROUP_CONCAT(b.book_name SEPARATOR ', ') AS books
FROM purchase_order po
JOIN supplier s ON po.supplier_id = s.supplier_id
JOIN purchase_order_detail pod ON po.purchase_id = pod.purchase_id
JOIN book b ON pod.book_id = b.book_id
GROUP BY po.purchase_id, s.supplier_name, po.total_amount, po.status, po.created_at;

-- 3.2 客户管理员订单视图
CREATE VIEW customer_admin_view AS
SELECT
    co.order_id,
    c.customer_name,
    co.total_amount,
    co.status,
    co.created_at,
    GROUP_CONCAT(b.book_name SEPARATOR ', ') AS books
FROM customer_order co
JOIN customer c ON co.customer_id
JOIN order_detail od ON co.order_id = od.order_id
JOIN book b ON od.book_id = b.book_id
GROUP BY co.order_id, c.customer_name, co.total_amount, co.status, co.created_at;

-- 4. 触发器定义
DELIMITER //
-- 触发器1：仅超级管理员可新增图书
CREATE TRIGGER check_admin_permission_before_insert
BEFORE INSERT ON book
FOR EACH ROW
BEGIN
DECLARE is_super_admin BOOLEAN;
SELECT JSON_EXTRACT(permissions, '$.all') INTO is_super_admin
FROM admin_role
JOIN admin ON admin_role.role_id = admin.role_id
WHERE admin.admin_id = NEW.admin_id;
IF NOT is_super_admin THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = '只有超级管理员可以管理图书信息';
END IF;
END//

-- 触发器2：仅超级/货商管理员创建采购订单
CREATE TRIGGER check_purchase_admin_permission
BEFORE INSERT ON purchase_order
FOR EACH ROW
BEGIN
DECLARE role_name VARCHAR(50);
SELECT ar.role_name INTO role_name
FROM admin_role ar
JOIN admin a ON ar.role_id = a.role_id
WHERE a.admin_id = NEW.admin_id;
IF role_name NOT IN ('超级管理员', '货商管理员') THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = '只有超级管理员或货商管理员可以创建采购订单';
END IF;
END//

-- 触发器3：仅超级/客户管理员处理客户订单
CREATE TRIGGER check_customer_admin_permission
BEFORE INSERT ON customer_order
FOR EACH ROW
BEGIN
DECLARE role_name VARCHAR(50);
SELECT ar.role_name INTO role_name
FROM admin_role ar
JOIN admin a ON ar.role_id = a.role_id
WHERE a.admin_id = NEW.admin_id;
IF role_name NOT IN ('超级管理员', '客户管理员') THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = '只有超级管理员或客户管理员可以处理客户订单';
END IF;
END//
DELIMITER ;
USE book_sales;

-- ====================== 1 插入角色表 admin_role ======================
INSERT INTO admin_role(role_name, description, permissions, license)
VALUES
('超级管理员','拥有系统全部操作权限','{"all":true}','全局所有模块'),
('货商管理员','仅采购、供应商管理权限','{"purchase":1}','采购模块'),
('客户管理员','仅客户、销售订单管理权限','{"order":1}','客户订单模块'),
('普通客户','前台注册用户，仅个人购物权限','{"user":1}','个人中心');

-- ====================== 2 插入管理员账号 admin ======================
INSERT INTO admin(admin_name, role_id, admin_account, admin_password)
VALUES
('戴凯',1,'daikai','060215'),
('丁颖琪',2,'dingyingqi','050104'),
('曾丽娟',3,'zenglijuan','050701'),
('戢湘',1,'jixiang','051008'),
('刘耀文',3,'liuyaowen','05092'),
('马嘉祺',2,'majiaqi','021212');

-- ====================== 3 注册用户表 registration_details ======================
INSERT INTO registration_details(username, password, contact_info, shipping_address, role_id)
VALUES
('zhangzy','030416','13112345678','镇江市梦溪路2号',4),
('limx','e10adc3949ba59abbe56e057f20f883e','15811112222','北京市海淀区中关村大街1号',4),
('zhangxw','e10adc3949ba59abbe56e057f20f883e','15922223333','上海市浦东新区张江高科技园区',4),
('wangsc','e10adc3949ba59abbe56e057f20f883e','13733334444','广州市天河珠江新城',4),
('chenyt','e10adc3949ba59abbe56e057f20f883e','13644445555','深圳市南山区科技园',4),
('liuxc','e10adc3949ba59abbe56e057f20f883e','13555556666','成都市天府软件园',4),
('zhaoyz','e10adc3949ba59abbe56e057f20f883e','13466667777','杭州市西湖文三路',4),
('zhouj','e10adc3949ba59abbe56e057f20f883e','13377778888','南京市汉口路',4),
('linxr','e10adc3949ba59abbe56e057f20f883e','13288889999','武汉市珞喻路',4),
('zhangsan','131213','13855451234','镇江市京口区',4);

-- ====================== 4 客户信息表 customer ======================
INSERT INTO customer(customer_name, contact_info, shipping_address, account, password, admin_id)
VALUES
('李明轩','15811112222','北京市海淀区中关村大街1号','limx','e10adc3949ba59abbe56e057f20f883e',3),
('张晓雯','15922223333','上海市浦东新区张江高科技园区','zhangxw','e10adc3949ba59abbe56e057f20f883e',3),
('王思聪','13733334444','广州市天河区珠江新城','wangsc','e10adc3949ba59abbe56e057f20f883e',3),
('陈雨桐','13644445555','深圳市南山区科技园','chenyt','e10adc3949ba59abbe56e057f20f883e',5),
('刘星辰','13555556666','成都市武侯区天府软件园','liuxc','e10adc3949ba59abbe56e057f20f883e',5),
('赵雅芝','13466667777','杭州市西湖区文三路','zhaoyz','e10adc3949ba59abbe56e057f20f883e',5),
('周杰伦','13377778888','南京市鼓楼区汉口路','zhouj','e10adc3949ba59abbe56e057f20f883e',3),
('林心如','13288889999','武汉市洪山区珞喻路','linxr','e10adc3949ba59abbe56e057f20f883e',5),
('张元','13855451234','镇江市京口区','zhangsan','131213',NULL),
('张真源','13112345678','镇江市梦溪路2号','zhangzy','030416',NULL);

-- ====================== 5 图书表 book ======================
INSERT INTO book(book_name, author, publisher, retail_price, admin_id)
VALUES
('数据库系统概念','Abraham Silberschatz','机械工业出版社',89.50,1),
('深入理解计算机系统','Randal E.Bryant','机械工业出版社',139.00,1),
('人类简史','尤瓦尔·赫拉利','中信出版社',68.00,1),
('三体全集','刘慈欣','重庆出版社',128.00,1),
('活着','余华','作家出版社',28.00,1),
('百年孤独','加西亚·马尔克斯','南海出版公司',39.50,1),
('Python编程:从入门到实践','Eric Matthes','人民邮电出版社',89.00,1),
('JavaScript高级程序设计','Nicholas C.Zakas','人民邮电出版社',129.00,1),
('经济学原理','曼昆','北京大学出版社',98.00,1),
('围城','钱钟书','人民文学出版社',36.00,1),
('平凡的世界','路遥','北京十月文艺出版社',138.00,1),
('追风筝的人','卡勒德·胡赛尼','上海人民出版社',36.00,1),
('白夜行','东野圭吾','南海出版公司',59.60,1),
('小王子','圣埃克苏佩里','人民文学出版社',22.00,1),
('明朝那些事儿','当年明月','中国友谊出版',358.00,1),
('Python数据分析','Wes McKinney','机械工业出版社',99.00,1),
('Java核心技术','Cay S. Horstmann','机械工业出版社',129.00,2);

-- ====================== 6 库存表 inventory（修复字段数量，4字段全部赋值） ======================
INSERT INTO inventory(book_id, quantity, status, warning_threshold)
VALUES
(1,5,'预警',10),
(2,78,'正常',10),
(3,50,'正常',10),
(4,48,'正常',10),
(5,20,'正常',10),
(6,25,'正常',10),
(7,200,'正常',10),
(8,75,'正常',10),
(9,30,'正常',10),
(10,150,'正常',10),
(11,85,'正常',10),
(12,45,'正常',10), -- 原报错行，补充第四个阈值参数
(13,29,'预警',10),
(14,109,'正常',10),
(15,30,'正常',10),
(16,40,'正常',10),
(17,55,'正常',10);

-- ====================== 7 供应商表 supplier ======================
INSERT INTO supplier(supplier_name, contact_info, admin_id)
VALUES
('新知图书批发','13800138000',1),
('京图书业','13800131111',1),
('南方图书供应链','13800132222',1),
('华东书城供货商','13800133333',1),
('西南图书商行','13800134444',1),
('华北图书物流','13800135555',1),
('华中图书渠道','13800136666',1);

-- ====================== 8 采购订单 purchase_order ======================
INSERT INTO purchase_order(supplier_id, admin_id, total_amount, status)
VALUES
(1,2,5000.00,'已完成'),
(2,2,3000.00,'已完成'),
(3,2,4500.00,'已完成'),
(4,2,2800.00,'已完成'),
(5,2,3600.00,'已完成'),
(6,2,4200.00,'已完成'),
(7,2,3800.00,'已完成'),
(1,2,5200.00,'已完成'),
(3,2,4100.00,'已完成'),
(5,2,2900.00,'已完成'),
(1,2,1000.00,'已完成');

-- ====================== 9 采购订单明细 purchase_order_detail ======================
INSERT INTO purchase_order_detail(purchase_id, book_id, quantity, purchase_price)
VALUES
(1,1,30,45),
(1,3,20,30),
(2,5,50,12),
(11,16,10,50);

-- ====================== 10 客户订单 customer_order ======================
INSERT INTO customer_order(customer_id, admin_id, status, total_amount, payment_time)
VALUES
(1,3,'已完成',89.50,'2023-01-15 10:23:45'),
(1,3,'已完成',207.00,'2023-02-20 14:35:12'),
(2,3,'已发货',128.00,'2023-03-05 09:12:33'),
(2,5,'已支付',167.50,'2023-03-10 16:45:22'),
(3,5,'待支付',68.00,NULL),
(4,5,'已完成',249.00,'2023-04-18 11:23:44'),
(4,3,'已完成',36.00,'2023-05-22 13:34:55'),
(5,5,'已发货',138.00,'2023-06-30 15:12:11'),
(6,5,'已支付',59.60,'2023-07-05 10:45:33'),
(7,3,'已完成',358.00,'2023-08-12 09:23:22'),
(8,5,'已完成',89.00,'2023-09-15 14:56:44'),
(1,3,'已发货',129.00,'2023-10-20 16:34:11'),
(2,5,'已完成',98.00,'2023-11-25 10:12:33'),
(3,5,'已支付',36.00,'2023-12-05 11:45:22'),
(10,3,'待支付',100.00,NULL);

-- ====================== 11 客户订单明细 order_detail ======================
INSERT INTO order_detail(order_id, book_id, quantity, price)
VALUES
(1,1,1,89.50),
(15,3,2,128),
(15,7,1,149);

-- ====================== 12 操作日志 operation_log ======================
INSERT INTO operation_log(admin_id, operation_type, operation_table, record_id, operation_content)
VALUES
(1,'WARNING','inventory',1,'图书ID1库存低于预警值,当前数量:5');
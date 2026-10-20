-- ==============================================================================
-- مشروع نظام محاسبة وإدارة المناجر والمستودعات - Hussain OS
-- الإصدار المتطور الشامل: المعرض + الورشة + مستودع الأخشاب
-- مستند إلى خطة وملاحظات الأستاذ محمود مصطفى
-- ==============================================================================

-- 0. إعدادات النظام وأنماط التشغيل الأربعة (System Operational Modes)
CREATE TABLE IF NOT EXISTS system_settings (
    key VARCHAR(100) PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- الأنماط المتاحة:
-- 1. FULL_INTEGRATED (المتكامل: معرض + ورشة + مستودع أخشاب)
-- 2. SHOWROOM_ONLY (المعرض وصالة المبيعات والتفصيل فقط)
-- 3. WORKSHOP_ONLY (ورشة التصنيع والقص فقط)
-- 4. TIMBER_WAREHOUSE_ONLY (مستودع وتجارة الأخشاب فقط بالجملة والتجزئة)
INSERT INTO system_settings (key, value, description)
VALUES 
    ('OPERATIONAL_MODE', 'FULL_INTEGRATED', 'نمط التشغيل المعتمد للنظام'),
    ('DEFAULT_VAT_RATE', '15.00', 'نسبة الضريبة المضافة 15%'),
    ('CURRENCY', 'SAR', 'الريال السعودي')
ON CONFLICT (key) DO NOTHING;

-- 1. دليل الموردين المعتمدين (Suppliers Registry)
-- يشمل الموردين المسجلين في خطة الأستاذ محمود مصطفى
CREATE TABLE IF NOT EXISTS suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL, -- أخشاب طه، أراك، مستودع عزيز، ركن الخشب، المناع للقزاز...
    category VARCHAR(100) NOT NULL, -- TIMBER (أخشاب), GLASS (زجاج ومرايا), HARDWARE (إكسسوارات), BOXES (صناديق)
    contact_person VARCHAR(100),
    phone VARCHAR(50),
    current_balance NUMERIC(12, 2) DEFAULT 0.00, -- الرصيد المستحق للمورد (دائن)
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- إدراج الموردين الفعليين
INSERT INTO suppliers (code, name, category, phone)
VALUES 
    ('SUP-TAHA', 'أخشاب طه', 'TIMBER', '0501112233'),
    ('SUP-ARAK', 'أراك للأخشاب والإكسسوارات', 'TIMBER', '0502223344'),
    ('SUP-AZIZ', 'مستودع عزيز للأخشاب', 'TIMBER', '0503334455'),
    ('SUP-ROKN', 'ركن الخشب', 'TIMBER', '0504445566'),
    ('SUP-MANAR', 'المنار الأول', 'TIMBER', '0505556677'),
    ('SUP-TAGCO', 'تاجكو للأخشاب', 'TIMBER', '0506667788'),
    ('SUP-MANNA', 'المناع للقزاز والمرايا', 'GLASS', '0507778899'),
    ('SUP-BOXES', 'مورد الصناديق والتغليف', 'BOXES', '0508889900')
ON CONFLICT (code) DO NOTHING;

-- 2. دليل البائعين وموظفي المبيعات (Salesmen)
-- (محمد، عيسى، يونس...) لمتابعة مبيعات كل بائع وعمولاته
CREATE TABLE IF NOT EXISTS salesmen (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(50),
    commission_rate NUMERIC(5, 2) DEFAULT 2.00, -- نسبة العمولة 2%
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO salesmen (name, phone)
VALUES 
    ('محمد', '0501000001'),
    ('عيسى', '0501000002'),
    ('يونس', '0501000003')
ON CONFLICT DO NOTHING;

-- 3. دليل العملاء وسجل المديونيات الآجلة (Customers & Accounts Receivable)
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    customer_type VARCHAR(50) DEFAULT 'RETAIL', -- RETAIL (عميل معرض تفصيل), WORKSHOP_CLIENT (ورشة أو نجار خارجي يشتري خشب)
    city VARCHAR(100) DEFAULT 'الرياض',
    district VARCHAR(100),
    address_details TEXT,
    location_url TEXT,
    total_debit NUMERIC(12, 2) DEFAULT 0.00, -- مبالغ غير مسددة من قبل الزبون (ديون)
    total_paid NUMERIC(12, 2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. مستودع وتجارة الأخشاب والألواح (Timber Inventory & Multi-UOM)
CREATE TABLE IF NOT EXISTS inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    supplier_id UUID REFERENCES suppliers(id),
    category VARCHAR(100) NOT NULL, -- RAW_TIMBER, MDF_SHEET, HPL_SHEET, GLASS, HARDWARE
    primary_uom VARCHAR(50) NOT NULL, -- SHEET (لوح), CUBIC_METER (م3), METER (متر طولي), PIECE (حبة)
    secondary_uom VARCHAR(50), -- SQUARE_METER (م2)
    uom_conversion_ratio NUMERIC(10, 4) DEFAULT 1.0000,
    length_mm NUMERIC(8, 2) DEFAULT 2440.00,
    width_mm NUMERIC(8, 2) DEFAULT 1220.00,
    thickness_mm NUMERIC(8, 2) DEFAULT 18.00,
    current_stock NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    purchase_cost NUMERIC(12, 2) NOT NULL, -- تكلفة الشراء للوح/المتر
    wholesale_price NUMERIC(12, 2) NOT NULL, -- سعر بيع الجملة لمستودع الأخشاب
    retail_price NUMERIC(12, 2) NOT NULL, -- سعر التجزئة
    warehouse_location VARCHAR(100) DEFAULT 'المستودع الرئيسي - هنجر A',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. فواتير مشتريات الأخشاب من الموردين (Timber Purchases)
CREATE TABLE IF NOT EXISTS purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_number VARCHAR(50) UNIQUE NOT NULL,
    supplier_id UUID NOT NULL REFERENCES suppliers(id),
    purchase_date DATE NOT NULL DEFAULT CURRENT_DATE,
    subtotal NUMERIC(12, 2) NOT NULL,
    vat_amount NUMERIC(12, 2) NOT NULL,
    total_amount NUMERIC(12, 2) NOT NULL,
    paid_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    remaining_balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    payment_status VARCHAR(50) DEFAULT 'UNPAID', -- UNPAID, PARTIAL, FULLY_PAID
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. شجرة المصروفات المصنفة بمراكز التكلفة الأربعة (Cost Centers Expense Tree)
CREATE TABLE IF NOT EXISTS expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expense_number VARCHAR(50) UNIQUE NOT NULL,
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    cost_center VARCHAR(100) NOT NULL, -- SHOWROOM, WORKSHOP, WAREHOUSE, OWNER_DRAWINGS
    category VARCHAR(100) NOT NULL, 
    -- SHOWROOM: إيجار معرض، كهرباء، إفطار وضيافة، مطبوعات، عمولات
    -- WORKSHOP: إعاشة عمال (أرز، زيت، أكل)، وايت ماء وصرف صحي، سباكة، زيوت ماكينات، شحذ مناشير، رواتب
    -- WAREHOUSE: إيجار هنجر، ديزل فوركلفت، عمال تنزيل
    -- OWNER_DRAWINGS: مسحوبات شخصية، صدقة، رسوم حكومية
    amount NUMERIC(12, 2) NOT NULL,
    payment_method VARCHAR(50) DEFAULT 'CASH', -- نقد من الدرج، تحويل بنكي، شبكة
    beneficiary VARCHAR(255), -- المستفيد (اسم العامل أو جهة الصرف)
    notes TEXT,
    recorded_by VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. سجل العمال والرواتب واليوميات والسلف (Workers Payroll & Advances)
CREATE TABLE IF NOT EXISTS workers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    role VARCHAR(100) NOT NULL, -- معلم منجرة، نجار قص، فني قشاط، فني تجميع، عامل تحميل
    wage_type VARCHAR(50) DEFAULT 'MONTHLY', -- MONTHLY (شهري), DAILY (يومية), PIECE_RATE (بالمتر/القطعة)
    base_wage NUMERIC(10, 2) NOT NULL,
    current_advances NUMERIC(10, 2) DEFAULT 0.00, -- رصيد السلف المسحوبة
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 8. عقود ومبيعات المعرض مع الكروكي وتوجيه العربون (Contracts & Croquis)
CREATE TABLE IF NOT EXISTS contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id UUID NOT NULL REFERENCES customers(id),
    salesman_id UUID REFERENCES salesmen(id), -- البائع (محمد، عيسى، يونس)
    contract_title VARCHAR(255) NOT NULL,
    total_amount NUMERIC(12, 2) NOT NULL,
    
    -- إدارة العربون والمتبقي وتوجيهه للموردين (فكرة الأستاذ محمود مصطفى)
    advance_payment_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    advance_directed_to_supplier_id UUID REFERENCES suppliers(id), -- سداد مباشر لمورد خشب من العربون
    remaining_balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    remaining_directed_to_supplier_id UUID REFERENCES suppliers(id),
    
    -- صور ومخططات الكروكي قبل وبعد التنفيذ
    croquis_before_url TEXT, -- رابط أو ملف كروكي قبل التنفيذ
    croquis_after_url TEXT, -- رابط أو ملف كروكي بعد التنفيذ
    
    signing_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_delivery_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'SIGNED', -- SIGNED, IN_PRODUCTION, INSTALLED, COMPLETED, CANCELLED
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 9. مبيعات الأخشاب المباشرة والخارجية (Direct & External Timber Sales)
-- لخدمة نمط "مستودع الأخشاب فقط" ومبيعات الورش الخارجية
CREATE TABLE IF NOT EXISTS direct_sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id UUID REFERENCES customers(id),
    buyer_name VARCHAR(255) NOT NULL, -- المحل أو الشخص الخارجي
    sale_date DATE NOT NULL DEFAULT CURRENT_DATE,
    subtotal NUMERIC(12, 2) NOT NULL,
    vat_amount NUMERIC(12, 2) NOT NULL,
    total_amount NUMERIC(12, 2) NOT NULL,
    amount_paid NUMERIC(12, 2) NOT NULL,
    unpaid_balance NUMERIC(12, 2) DEFAULT 0.00, -- مبالغ غير مسددة
    payment_type VARCHAR(50) DEFAULT 'CASH', -- CASH, DEBIT_AR (آجل)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 10. إغلاق الصندوق اليومي (Daily Cash Flow Reconciliation)
-- المبيعات - (المشتريات + المصروفات) = الصافي المتبقي
CREATE TABLE IF NOT EXISTS daily_cash_closings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    closing_date DATE UNIQUE NOT NULL DEFAULT CURRENT_DATE,
    total_sales_cash NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    total_purchases_cash NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    total_expenses_cash NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    net_cash_remaining NUMERIC(12, 2) NOT NULL DEFAULT 0.00, -- المتبقي في الدرج
    notes TEXT,
    closed_by VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================================
-- إضافات مستندة إلى ملفات الأستاذ محمود مصطفى (عام 2026 م - 2027 م)
-- ============================================================================

-- 11. جدول ميزان التسوية الشهرية وحساب الأرباح (Monthly Financial Settlements)
-- لمطابقة الحوالات والشبكة مقابل فواتير المعارض ومصروفات الورشة وتحديد موقف الحساب (لك أو عليك)
CREATE TABLE IF NOT EXISTS monthly_settlements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fiscal_year INT NOT NULL DEFAULT 2026,
    month_number INT NOT NULL CHECK (month_number BETWEEN 1 AND 12),
    month_name VARCHAR(50) NOT NULL,
    total_transfers_pos NUMERIC(12, 2) NOT NULL DEFAULT 0.00, -- الحوالات + شبكة
    total_showroom_invoices NUMERIC(12, 2) NOT NULL DEFAULT 0.00, -- فواتير المعارض (داريفا، ماي هوم، ألمنيوم)
    total_workshop_expenses NUMERIC(12, 2) NOT NULL DEFAULT 0.00, -- مصاريف الورشة (إعاشة، ماء، صيانة، كفيل)
    net_difference NUMERIC(12, 2) NOT NULL DEFAULT 0.00, -- الفرق (لك أو عليك)
    supervisors VARCHAR(255) DEFAULT 'أبومعاذ / أبويوسف',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_monthly_settlement UNIQUE (fiscal_year, month_number)
);

-- 12. جدول كشف حسابات ومطابقة موردي الأخشاب (Timber Supplier Reconciliations)
-- لمطابقة طلبات الأخشاب مع الحوالات والشبكات والمردودات (مثل زاهد وعواجي)
CREATE TABLE IF NOT EXISTS timber_supplier_reconciliations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_code VARCHAR(50) NOT NULL,
    supplier_name VARCHAR(100) NOT NULL,
    fiscal_year INT NOT NULL DEFAULT 2026,
    total_orders_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00, -- إجمالي فواتير طلبات الخشب
    total_payments_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00, -- إجمالي السداد (حوالات + شبكة)
    total_returns_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00, -- إجمالي المردودات والترجيع
    net_balance_due NUMERIC(12, 2) NOT NULL DEFAULT 0.00, -- المتبقي في الذمة للمورد
    notes TEXT,
    last_reconciled_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 13. جدول كشف عمال المياومة الأسبوعية (Daily Wage Workers Attendance & Ledger)
-- لحساب أيام العمل، اليومية المعتمدة، إجمالي المستحق، الدفعات، والصافي المتبقي للعامل
CREATE TABLE IF NOT EXISTS worker_daily_wages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_name VARCHAR(100) NOT NULL,
    alias_name VARCHAR(100), -- مثل: عمر فاروق (مروان)، رفيق، ميزان
    base_salary_equivalent NUMERIC(10, 2) NOT NULL, -- الراتب الشهري الافتراضي
    calculated_daily_rate NUMERIC(10, 2) NOT NULL, -- أجر اليومية المحسوب
    total_days_worked NUMERIC(8, 2) NOT NULL DEFAULT 0.00, -- مجموع الأيام المنفذة
    total_amount_earned NUMERIC(12, 2) NOT NULL DEFAULT 0.00, -- إجمالي المستحق
    total_payments_received NUMERIC(12, 2) NOT NULL DEFAULT 0.00, -- مجموع الدفعات المستلمة
    remaining_balance_due NUMERIC(12, 2) NOT NULL DEFAULT 0.00, -- المتبقي للعامل
    fiscal_cycle VARCHAR(50) DEFAULT '2026-2027',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

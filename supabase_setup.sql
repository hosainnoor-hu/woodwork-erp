-- ============================================================================
-- سكربت تهيئة قاعدة البيانات السحابية المركزية لنظام الأخشاب والدواليب (Supabase / PostgreSQL)
-- ينسخ هذا الكود بالكامل ويُلصق في نافذة Supabase SQL Editor ثم الضغط على Run
-- ============================================================================

-- 1. جدول الحسابات التشغيلية والمزامنة المركزية
CREATE TABLE IF NOT EXISTS system_metadata (
    id TEXT PRIMARY KEY,
    app_version VARCHAR(20) DEFAULT '2.0.0',
    last_sync_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    data_payload JSONB NOT NULL
);

-- 2. جدول العقود وتفصيل الدواليب والكروكي
CREATE TABLE IF NOT EXISTS contracts (
    id TEXT PRIMARY KEY,
    contract_number VARCHAR(50) NOT NULL,
    customer_name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    salesman VARCHAR(100),
    title VARCHAR(255) NOT NULL,
    total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    advance_paid NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    advance_directed_to VARCHAR(255),
    remaining_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    croquis_before TEXT,
    croquis_after TEXT,
    signing_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(50) DEFAULT 'IN_WORKSHOP',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. جدول شجرة المصروفات ومراكز التكلفة الأربعة
CREATE TABLE IF NOT EXISTS expenses (
    id TEXT PRIMARY KEY,
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    cost_center VARCHAR(100) NOT NULL,
    category VARCHAR(100) NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    payment_method VARCHAR(50) DEFAULT 'CASH',
    beneficiary VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. جدول المبيعات المباشرة لمستودع الأخشاب
CREATE TABLE IF NOT EXISTS direct_sales (
    id TEXT PRIMARY KEY,
    buyer VARCHAR(255) NOT NULL,
    sale_date DATE NOT NULL DEFAULT CURRENT_DATE,
    timber VARCHAR(255) NOT NULL,
    qty NUMERIC(10, 2) NOT NULL,
    total NUMERIC(12, 2) NOT NULL,
    paid NUMERIC(12, 2) NOT NULL,
    unpaid NUMERIC(12, 2) DEFAULT 0.00,
    payment_method VARCHAR(50) DEFAULT 'CASH',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. جدول ميزان التسويات الشهرية (2026 م)
CREATE TABLE IF NOT EXISTS monthly_settlements (
    id SERIAL PRIMARY KEY,
    fiscal_year INT DEFAULT 2026,
    month_number INT NOT NULL,
    month_name VARCHAR(50) NOT NULL,
    transfers NUMERIC(12, 2) DEFAULT 0.00,
    invoices NUMERIC(12, 2) DEFAULT 0.00,
    expenses NUMERIC(12, 2) DEFAULT 0.00,
    diff NUMERIC(12, 2) DEFAULT 0.00,
    managers VARCHAR(255) DEFAULT 'أبومعاذ / أبويوسف',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. تفعيل سياسات الوصول العام (RLS) للسماح بتطبيق PWA بالقراءة والكتابة
ALTER TABLE system_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE direct_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_settlements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read access" ON system_metadata;
DROP POLICY IF EXISTS "Allow public write access" ON system_metadata;
CREATE POLICY "Allow public read access" ON system_metadata FOR SELECT USING (true);
CREATE POLICY "Allow public write access" ON system_metadata FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public read access" ON contracts;
DROP POLICY IF EXISTS "Allow public write access" ON contracts;
CREATE POLICY "Allow public read access" ON contracts FOR SELECT USING (true);
CREATE POLICY "Allow public write access" ON contracts FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public read access" ON expenses;
DROP POLICY IF EXISTS "Allow public write access" ON expenses;
CREATE POLICY "Allow public read access" ON expenses FOR SELECT USING (true);
CREATE POLICY "Allow public write access" ON expenses FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public read access" ON direct_sales;
DROP POLICY IF EXISTS "Allow public write access" ON direct_sales;
CREATE POLICY "Allow public read access" ON direct_sales FOR SELECT USING (true);
CREATE POLICY "Allow public write access" ON direct_sales FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public read access" ON monthly_settlements;
DROP POLICY IF EXISTS "Allow public write access" ON monthly_settlements;
CREATE POLICY "Allow public read access" ON monthly_settlements FOR SELECT USING (true);
CREATE POLICY "Allow public write access" ON monthly_settlements FOR ALL USING (true) WITH CHECK (true);

-- 7. إنشاء وتأمين مخزن الصور السحابي للكروكي والدواليب (Supabase Storage Bucket: croquis)
INSERT INTO storage.buckets (id, name, public)
VALUES ('croquis', 'croquis', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Allow public uploads to croquis" ON storage.objects;
DROP POLICY IF EXISTS "Allow public view of croquis" ON storage.objects;
CREATE POLICY "Allow public uploads to croquis" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'croquis');
CREATE POLICY "Allow public view of croquis" ON storage.objects FOR SELECT USING (bucket_id = 'croquis');

# Workforce Dispatch System (نظام توزيع الفنيين والمهندسين)

نظام توزيع أعمال (Dispatch Engine) مثل تطبيقات الخدمات — المنصة تستلم طلب الزبون، تبحث عن أفضل فني متوفر، ترسل المهمة له، الفني يقبل أو يرفض، النظام ينتقل للتالي. الزبون لا يرى الفنيين ولا أرقامهم. يشمل قاعدة البيانات، Go API، لوحة الإدارة React، وواجهة Flutter — مع نظام تسعير وعمولة متكامل. يحول المشروع من متجر طاقة إلى **منصة طاقة شمسية متكاملة** بـ 4 محركات.

---

## الرؤية المعمارية: 4 محركات متكاملة

```
┌──────────────────────────────────────────────────┐
│              منصة الطاقة الشمسية للعراق             │
├──────────────┬──────────────┬──────────┬──────────┤
│  Marketplace │  Calculator  │Workforce │ Service  │
│  (منتجات)    │   Engine     │ Dispatch │Marketplace│
│              │  (حاسبات)    │(توزيع)   │(طلبات)   │
├──────────────┼──────────────┼──────────┼──────────┤
│ بيع المنتجات │ حساب الأحمال │إدارة+    │ طلب خدمة │
│ + متاجر      │ + توصية     │توزيع     │ + عمولة  │
│ + طلبات      │ + ربط بالطلب │تلقائي    │ + تتبع   │
└──────────────┴──────────────┴──────────┴──────────┘
```

**التدفق الأساسي (Dispatch Flow)**:
```
الزبون يطلب خدمة (وصف + عنوان + نوع)
  ↓
النظام يبحث عن أفضل فنيين (فلترة + score)
  ↓
يرسل المهمة كـ Order للفني الأعلى score
  ↓
الفني يقبل أو يرفض
  ↓
إذا رفض → تنتقل للأولوية التالية (أو إرسال لعدة فنيين بنفس الوقت)
  ↓
بعد القبول يبدأ تتبع التنفيذ
  ↓
الزبون يرى: تم استلام طلبك → جاري التعيين → الفني في الطريق → تم الإنجاز
```

**التكامل بين المحركات**: الزبون يستخدم الحاسبة → يحصل على نتيجة → يضغط "اطلب فني معتمد" → يُنشأ Service Order تلقائياً → Dispatch Engine يوزعه.

---

## قرارات المستخدم
- **واجهة الفني**: داخل نفس تطبيق Flutter (بناءً على دور المستخدم)
- **التنفيذ**: متوازي لكل الطبقات (DB + API + Admin + Flutter)
- **الطلبات الخدمية**: جدول منفصل `service_orders` مستقل عن `orders`
- **التسعير والعمولة**: ضمن الخطة الحالية
- **نموذج التوزيع**: Dispatch Engine — النظام يوزع تلقائياً، الزبون لا يختار الفني
- **الزبون لا يرى الفنيين**: فقط حالة الطلب (جاري التعيين → في الطريق → تم الإنجاز)
- **الفني يمكنه إنشاء lead**: عميل وصل له خارج التطبيق يضيفه كـ technician_lead للمراجعة

---

## المرحلة 1: قاعدة البيانات (Migration 019)

**ملف**: `iraq-solar-api/migrations/019_workforce_management_system.sql`

### الجداول الجديدة (21 جدول)

#### 1.1 `technicians` — ملفات الفنيين
```sql
- id (UUID PK)
- user_id (UUID FK → users)
- full_name, profile_image_url
- phone_private, phone_public (nullable)
- role (engineer, installer, technician, worker)
- specializations JSONB -- [installation, maintenance, inspection, inverter, battery, wiring]
- governorate_id, district_id
- experience_years INT
- bio TEXT
- is_verified BOOLEAN
- is_active BOOLEAN
- availability_status (available, busy, suspended, offline, vacation)
- rating NUMERIC(3,2) DEFAULT 0
- completed_jobs_count INT DEFAULT 0
- acceptance_rate NUMERIC(5,2) DEFAULT 100.00 -- نسبة قبول الطلبات
- avg_response_minutes INT DEFAULT 0 -- متوسط وقت القبول
- verification_level INT DEFAULT 0 -- مستوى التوثيق (0=غير موثق, 1=هوية, 2=هوية+شهادة, 3=كامل)
- complaint_count INT DEFAULT 0 -- عدد شكاوى الزبائن
- level_id (UUID FK → technician_levels, nullable) -- مستوى الفني (Bronze/Silver/Gold)
- created_at, updated_at
```

#### 1.1c `technician_levels` — مستويات الفنيين (Bronze/Silver/Gold)
```sql
- id (UUID PK)
- name VARCHAR -- Bronze, Silver, Gold, Platinum
- name_ar VARCHAR -- برونزي, فضي, ذهبي, بلاتيني
- min_jobs INT -- الحد الأدنى من الأعمال للوصول لهذا المستوى
- min_rating NUMERIC(3,2) -- الحد الأدنى للتقييم
- commission_rate NUMERIC(5,2) -- نسبة العمولة لهذا المستوى
- badge_color VARCHAR -- لون الشارة للعرض
- sort_order INT
- created_at
-- Bronze: 0-20 أعمال، عمولة 15%
-- Silver: 20-100 أعمال، عمولة 12%
-- Gold: 100+ أعمال، عمولة 10%
-- Platinum: 200+ أعمال + تقييم 4.8+، عمولة 8%
-- يحفز الفنيين على إنجاز المزيد لتقليل العمولة
-- يتم ترقية/تخفيض المستوى تلقائياً بناءً على completed_jobs_count و rating
```

#### 1.1b `technician_availability` — توفر الفني وساعات العمل
```sql
- id (UUID PK)
- technician_id (UUID FK → technicians, UNIQUE)
- status (available, busy, offline, vacation) -- حالة لحظية
- available_from TIME (nullable) -- بداية يوم العمل
- available_until TIME (nullable) -- نهاية يوم العمل
- working_days JSONB -- ["sat","sun","mon","tue","wed","thu"]
- current_lat, current_lng (nullable) -- موقع لحظي (للتتبع)
- last_status_change_at TIMESTAMP
- updated_at
-- الفني يحدد: متوفر/مشغول/إجازة + ساعات العمل + أيام الأسبوع
-- Dispatch Engine يفحص هذا الجدول قبل إرسال أي مهمة
```

#### 1.2 `technician_documents` — التوثيق
```sql
- id (UUID PK)
- technician_id (UUID FK → technicians)
- type (id_card, electrical_certificate, solar_certificate, license, personal_photo, work_photo)
- url VARCHAR
- status (pending, under_review, approved, rejected)
- reviewed_by (UUID FK → users, nullable)
- reviewed_at TIMESTAMP
- created_at
```

#### 1.3 `technician_portfolio` — معرض الأعمال
```sql
- id (UUID PK)
- technician_id (UUID FK → technicians)
- title, description
- before_images JSONB -- [urls]
- after_images JSONB
- video_url (nullable)
- project_type (installation, maintenance, inspection, repair)
- system_capacity_kw NUMERIC
- governorate, city
- execution_date DATE
- created_at
```

#### 1.4 `technician_service_zones` — مناطق تغطية الفني
```sql
- id (UUID PK)
- technician_id (UUID FK → technicians)
- governorate_id (INT FK → governorates)
- is_primary BOOLEAN DEFAULT false -- المحافظة الرئيسية
- created_at
-- UNIQUE(technician_id, governorate_id)
-- يحدد أي المحافظات يظهر فيها الفني للزبون
-- عامل القرب في الترتيب يعتمد على هذا الجدول
```

#### 1.5 `technician_wallet` — محفظة الفني المالية
```sql
- id (UUID PK)
- technician_id (UUID FK → technicians, UNIQUE)
- balance_iqd NUMERIC DEFAULT 0 -- الرصيد الحالي
- total_earned_iqd NUMERIC DEFAULT 0 -- إجمالي الأرباك
- total_commission_iqd NUMERIC DEFAULT 0 -- إجمالي العمولات
- pending_payout_iqd NUMERIC DEFAULT 0 -- مستحق غير مدفوع
- last_settlement_at (nullable)
- created_at, updated_at
-- يُحدّث تلقائياً عند إكمال كل طلب
```

#### 1.6 `technician_ranking` — الترتيب
```sql
- id (UUID PK)
- technician_id (UUID FK → technicians, UNIQUE)
- priority_score NUMERIC(5,2) -- محسوب تلقائياً
- manual_order INT DEFAULT 0
- is_featured BOOLEAN DEFAULT false
- is_hidden BOOLEAN DEFAULT false
- last_recalculated_at TIMESTAMP
```

#### 1.6b `dispatch_queue` — طابور توزيع الطلبات على الفنيين
```sql
- id (UUID PK)
- service_order_id (UUID FK → service_orders)
- technician_id (UUID FK → technicians)
- priority_score NUMERIC(5,2) -- score الفني وقت الإرسال
- dispatch_mode (sequential, parallel, hybrid) -- تسلسلي/متوازي/هجين
- position INT -- ترتيب الفني في الطابور (1=الأول)
- status (queued, sent, accepted, rejected, expired, cancelled)
- selection_reason JSONB -- سبب اختيار هذا الفني
  -- مثال: {"distance":"primary_zone","rating":4.8,"completed_jobs":35,"specialization_match":true,"verification_level":3}
- sent_at (nullable)
- responded_at (nullable)
- expires_at (nullable) -- مهلة الرد (من dispatch_settings)
- created_at
-- عند وصول طلب: النظام يرتب الفنيين ويضعهم في الطابور
-- sequential: يرسل للأول → ينتظر → إذا رفض يرسل للثاني...
-- parallel: يرسل لأفضل N بنفس الوقت → أول من يقبل يحصل على المهمة
-- hybrid: النظام يختار الوضع بناءً على نوع/حجم الطلب (من dispatch_settings)
-- selection_reason يُعرض للفني: "تم اختيارك لأن: تغطي النجف ⋅ تقييمك 4.8 ⋅ 35 عملية مكتملة"
```

#### 1.6d `dispatch_settings` — إعدادات التوزيع القابلة للتغيير من الإدارة
```sql
- id (UUID PK)
- service_type VARCHAR -- installation, maintenance, inspection, consultation, repair
- dispatch_mode VARCHAR -- sequential, parallel, hybrid
- response_timeout_minutes INT -- مهلة الرد بالدقائق
- parallel_candidates_count INT -- عدد الفنيين في parallel
- minimum_score NUMERIC(5,2) -- أقل score مقبول للفني
- auto_assign_enabled BOOLEAN DEFAULT true -- توزيع تلقائي أم يدوي فقط
- created_at, updated_at
-- مثال:
-- تركيب: hybrid, timeout=10, parallel=3, min_score=60
-- صيانة: parallel, timeout=3, parallel=5, min_score=50
-- معاينة: parallel, timeout=5, parallel=3, min_score=40
-- الإدارة تغير هذه بدون تعديل الكود
```

#### 1.6f `technician_dispatch_stats` — إحصائيات توزيع Fair Dispatch
```sql
- id (UUID PK)
- technician_id (UUID FK → technicians, UNIQUE)
- orders_received_this_month INT DEFAULT 0
- orders_received_this_week INT DEFAULT 0
- total_orders_received INT DEFAULT 0
- total_earnings_this_month NUMERIC DEFAULT 0
- last_order_received_at (nullable) -- آخر مرة استلم فيها طلب
- last_order_completed_at (nullable)
- days_since_last_order INT DEFAULT 0 -- محسوب تلقائياً
- is_new_technician BOOLEAN DEFAULT true -- مرحلة الإثبات (أول 10 طلبات)
- new_technician_orders_count INT DEFAULT 0 -- عداد لمرحلة الإثبات
- fairness_boost NUMERIC(5,2) DEFAULT 0 -- زيادة مؤقتة للـ Score (محسوبة)
- last_boost_calculated_at (nullable)
- updated_at
-- Fair Dispatch: هذا الجدول يضمن عدم احتكار الفنيين الأقوياء للطلبات
-- يتم تحديثه عند كل توزيع وعند كل إكمال طلب
-- fairness_boost يُضاف للـ Score عند التوزيع
```

#### 1.6e `technician_tracking` — تتبع الفني اللحظي (GPS)
```sql
- id (UUID PK)
- order_id (UUID FK → service_orders)
- technician_id (UUID FK → technicians)
- lat NUMERIC(10,7)
- lng NUMERIC(10,7)
- status VARCHAR -- on_the_way, arrived, working, idle
- created_at
-- يُحدّث كل 30-60 ثانية من تطبيق الفني
-- الزبون يرى: "الفني على بعد 2.5 كم منك" (مثل تطبيقات التوصيل)
-- لا يُخزن تاريخ المسار، فقط آخر موقع (privacy)
```

#### 1.6c `technician_leads` — طلبات الفني الخاصة (عميل وصل له خارج التطبيق)
```sql
- id (UUID PK)
- technician_id (UUID FK → technicians) -- الفني الذي أنشأ الطلب
- customer_name VARCHAR
- customer_phone VARCHAR
- order_type (installation, maintenance, inspection, consultation, repair)
- description TEXT
- system_size_kw (nullable)
- governorate_id, district_id
- address TEXT
- estimated_price_iqd (nullable) -- سعر مقترح من الفني
- status (pending_review, approved, rejected, converted)
- reviewed_by (UUID FK → users, nullable)
- reviewed_at (nullable)
- converted_order_id (UUID FK → service_orders, nullable) -- إذا تم تحويله لطلب رسمي
- created_at
-- الفني يدخل: لدي عميل يريد تركيب → يرسل للمنصة → الإدارة تراجع
-- إذا قبول: يتحول لـ service_order ويُعين نفس الفني عليه
```

#### 1.7 `service_orders` — الطلبات الخدمية
```sql
- id (UUID PK)
- order_number VARCHAR UNIQUE -- مثلاً SRV-2026-0001
- customer_id (UUID FK → users, nullable) -- nullable للطلبات من leads
- order_type (installation, maintenance, inspection, consultation, repair)
- description TEXT
- system_size_kw (nullable)
- governorate_id, district_id
- address TEXT
- lat, lng (nullable)
- preferred_date (nullable)
- status (new, dispatching, assigned, tech_accepted, on_the_way, arrived, working, waiting_customer, completed, cancelled, no_technician_available)
- priority (low, normal, high, urgent)
- calculator_result JSONB (nullable) -- نتيجة الحاسبة المرتبطة بالطلب
- assigned_technician_id (UUID FK → technicians, nullable) -- الفني الذي قبل
- dispatch_mode (sequential, parallel) -- وضع التوزيع المستخدم
- created_at, updated_at, completed_at
-- الحالات الجديدة: dispatching (جاري التوزيع), no_technician_available (لا يوجد فني متوفر)
```

#### 1.8 `order_assignments` — توزيع الفنيين (سجل نهائي)
```sql
- id (UUID PK)
- order_id (UUID FK → service_orders)
- technician_id (UUID FK → technicians)
- assigned_by (VARCHAR) -- 'dispatch_engine' أو 'admin' (UUID)
- assigned_by_admin (UUID FK → users, nullable) -- إذا كان يدوياً
- status (pending, accepted, rejected, completed, expired)
- assigned_at, accepted_at, rejected_at
- rejection_reason (nullable)
- completion_time (nullable)
-- هذا الجدول يسجل النتيجة النهائية للتوزيع
-- dispatch_queue يتتبع العملية، order_assignments يسجل النتيجة
```

#### 1.9 `order_status_history` — سجل حالات الطلب
```sql
- id (UUID PK)
- order_id (UUID FK → service_orders)
- status VARCHAR
- changed_by (UUID FK → users)
- notes (nullable)
- created_at
```

#### 1.10 `job_tasks` — قائمة مهام التنفيذ (Checklist)
```sql
- id (UUID PK)
- order_id (UUID FK → service_orders)
- title VARCHAR
- is_completed BOOLEAN DEFAULT false
- completed_at (nullable)
- sort_order INT
```

#### 1.11 `job_media` — صور وملاحظات التنفيذ
```sql
- id (UUID PK)
- order_id (UUID FK → service_orders)
- technician_id (UUID FK → technicians)
- type (photo, video, note, signature, gps_proof)
- url (nullable)
- content TEXT (nullable)
- lat, lng (nullable)
- created_at
```

#### 1.12 `customer_reviews` — تقييمات الزبائن
```sql
- id (UUID PK)
- order_id (UUID FK → service_orders, UNIQUE)
- customer_id (UUID FK → users)
- technician_id (UUID FK → technicians)
- quality_rating INT (1-5)
- punctuality_rating INT (1-5)
- speed_rating INT (1-5)
- comment TEXT (nullable)
- created_at
```

#### 1.13 `service_pricing` — التسعير والعمولة
```sql
- id (UUID PK)
- order_id (UUID FK → service_orders, UNIQUE)
- base_price_iqd NUMERIC
- platform_commission_percent NUMERIC(5,2) DEFAULT 15.00
- platform_commission_iqd NUMERIC
- technician_payout_iqd NUMERIC
- payment_status (unpaid, pending, paid_to_technician, settled)
- settled_at (nullable)
- created_at
```

### الفهارس (Indexes)
- idx_technicians_role, idx_technicians_governorate, idx_technicians_availability
- idx_technician_availability_status -- للبحث السريع عن المتوفرين
- idx_technician_zones_technician, idx_technician_zones_governorate
- idx_technician_wallet_technician
- idx_dispatch_queue_order, idx_dispatch_queue_technician, idx_dispatch_queue_status
- idx_technician_leads_technician, idx_technician_leads_status
- idx_service_orders_customer, idx_service_orders_status, idx_service_orders_type
- idx_order_assignments_order, idx_order_assignments_technician
- idx_technician_documents_technician, idx_technician_portfolio_technician

---

## المرحلة 2: Go API Backend

### 2.1 Domain Layer (`internal/domain/`)
- **`workforce.go`** — تعريف الـ structs:
  - `Technician`, `TechnicianDocument`, `TechnicianPortfolio`, `TechnicianRanking`
  - `TechnicianServiceZone`, `TechnicianWallet`, `TechnicianAvailability`, `TechnicianLevel`
  - `DispatchQueue`, `DispatchSettings`, `TechnicianLead`, `TechnicianTracking`
  - `ServiceOrder`, `OrderAssignment`, `OrderStatusHistory`
  - `JobTask`, `JobMedia`, `CustomerReview`, `ServicePricing`
  - Request/Response DTOs لكل كيان
  - Enums: `OrderStatus`, `AvailabilityStatus`, `OrderType`, `DocumentType`, `AssignmentStatus`, `DispatchMode`, `DispatchStatus`, `LeadStatus`, `TrackingStatus`

### 2.2 Repository Layer (`internal/repository/`)
- **`workforce_repository.go`** — واجهة `WorkforceRepository`:
  - `CreateTechnician`, `GetTechnicianByID`, `ListTechnicians`, `UpdateTechnician`, `UpdateAvailability`
  - `GetAvailability`, `UpdateAvailabilityStatus`, `UpdateWorkingHours`
  - `AddServiceZone`, `ListServiceZones`, `RemoveServiceZone`
  - `GetWallet`, `UpdateWalletBalance`, `GetWalletSummary`
  - `AddDocument`, `ListDocuments`, `UpdateDocumentStatus`
  - `AddPortfolioItem`, `ListPortfolio`, `DeletePortfolioItem`
  - `GetRanking`, `UpdateRanking`, `RecalculateRankingScores`
  - `CreateServiceOrder`, `GetServiceOrder`, `ListServiceOrders`, `UpdateOrderStatus`
  - `CreateAssignment`, `ListAssignmentsForOrder`, `UpdateAssignmentStatus`
  - `AddStatusHistory`, `GetStatusHistory`
  - `CreateJobTask`, `ListJobTasks`, `UpdateJobTask`
  - `AddJobMedia`, `ListJobMedia`
  - `CreateReview`, `GetReview`
  - `CreatePricing`, `UpdatePricingStatus`
  - `FindAvailableTechnicians` — البحث عن فنيين متوفرين في محافظة معينة + تخصص معين
  - `AddToDispatchQueue`, `GetDispatchQueue`, `UpdateDispatchStatus`, `GetNextDispatchCandidate`
  - `CreateLead`, `ListLeads`, `UpdateLeadStatus`, `ConvertLeadToOrder`
  - `GetDispatchSettings`, `UpdateDispatchSettings` — إعدادات التوزيع حسب نوع الخدمة
  - `AddTrackingPoint`, `GetLatestTracking` — تتبع GPS
  - `ListLevels`, `CreateLevel`, `UpdateLevel` — إدارة المستويات
  - `UpdateTechnicianLevel` — ترقية/تخفيض تلقائي بناءً على jobs + rating

### 2.3 Service Layer (`internal/service/`)
- **`workforce_service.go`** — منطق الأعمال العام:
  - `RegisterTechnician` — إنشاء ملف فني + ربط بـ user + تهيئة محفظة + ranking
  - `VerifyTechnician` — توثيق الفني (admin)
  - `UpdateAvailability` — الفني يحدد متوفر/مشغول/إجازة + ساعات العمل
  - `CalculateRankingScore` — خوارزمية الترتيب المحدثة (Quality Score):
    - **35%** تقييم العملاء (rating)
    - **20%** قرب المحافظة (بناءً على service_zones)
    - **15%** عدد الأعمال السابقة (completed_jobs_count)
    - **10%** سرعة قبول الطلبات (avg_response_minutes)
    - **5%** نسبة الالتزام (acceptance_rate)
    - **10%** مستوى التوثيق (verification_level: 0-3)
    - **5%** خلوص السجل (عكس complaint_count)
    -- فني جديد موثق بالكامل + خبرة 10 سنوات لا يكون آخر القائمة
    -- verification_level يعوض نقص الأعمال داخل التطبيق
  - `CalculateFairDispatchScore` — **طبقة عدالة التوزيع** (Fair Dispatch Layer):
    - **Quality Score** (من فوق) × **70%**
    - **Fairness Score** × **30%**:
      - **فرصة عادلة**: لم يستلم طلب منذ 14 يوم → boost +15 / يومياً → boost 0
      - **موازنة الحصة**: orders_this_month أقل من المتوسط → boost / أعلى من المتوسط → penalty
      - **مرحلة الإثبات**: فني جديد (أول 10 طلبات) → boost +20 لضمان حصوله على فرص
      - **موازنة الأرباح**: earnings_this_month أقل من المتوسط → boost
    - **Final Score** = Quality×0.7 + Fairness×0.3 + fairness_boost
    -- مثال: فني تقييمه 4.9 أخذ 20 طلب هذا الشهر → Score ينخفض مؤقتاً
    -- فني تقييمه 4.5 أخذ طلبين فقط → Score يرتفع مؤقتاً
    -- النتيجة: توزيع عادل بدون التضحية بالجودة
  - `CreditTechnicianWallet` — إضافة أرباح للمحفظة عند إكمال طلب
  - `GetWalletSummary` — ملخص مالي للفني
  - `CompleteOrder` — إغلاق الطلب + حساب التسعير + تحديث rating + تحديث المحفظة
  - `MarkCustomerUnavailable` — تسجيل عدم تجاوب الزبون
  - `CalculatePricing` — حساب التكلفة والعمولة

- **`dispatch_service.go`** — محرك التوزيع (Dispatch Engine) — **منطق الأعمال الأساسي**:
  - `CreateServiceOrder` — إنشاء طلب خدمي (من الزبون) → تشغيل Dispatch تلقائياً
  - `CreateServiceOrderFromCalculator` — إنشاء طلب من نتيجة حاسبة → تشغيل Dispatch
  - `ProcessDispatch` — الوظيفة الرئيسية:
    1. **قراءة dispatch_settings** لنوع الخدمة (mode, timeout, candidates, min_score)
    2. **فلترة**: فنيين متوفرين الآن + يغطون المحافظة + لديهم التخصص + غير موقوفين + score ≥ min_score
    3. **حساب Score** لكل فني مرشح
    4. **ترتيب** الفنيين تنازلياً حسب Score
    5. **إنشاء dispatch_queue** مع position + **selection_reason JSONB** لكل فني
    6. **Fair Competition**: إذا كان الوضع parallel وعدة فنيين متقاربين في Score (فرق < 5 نقاط)، يُرسل لهم بنفس الوقت — أسرع قبول يفوز
    7. **تحديد الوضع** (hybrid):
       - طلب صغير (صيانة/معاينة) → parallel (أفضل N بنفس الوقت)
       - طلب كبير (تركيب > 10KW) → sequential (واحد تلو الآخر)
       - الإدارة تتحكم عبر dispatch_settings
    8. **الإرسال**:
       - `sequential`: إرسال للأول → مهلة (من settings) → إذا رفض/انتهت → التالي
       - `parallel`: إرسال لأفضل N بنفس الوقت → أول من يقبل يحصل على المهمة → إلغاء الباقي
    9. **تحديث** `service_orders.status` → `dispatching` → `assigned`
    10. **إشعار** الفني عبر WebSocket (real-time) مع **selection_reason**
    11. **تحديث** `technician_dispatch_stats` (orders_received, last_order_received_at)
    12. إذا لم يوجد أي فني متوفر → `status = no_technician_available` + إشعار Admin
  - `AcceptDispatch` — فني يقبل مهمة من الطابور:
    - تحديث `dispatch_queue.status = accepted`
    - إلغاء باقي الطابور (parallel mode)
    - إنشاء `order_assignments` نهائي
    - تحديث `service_orders.assigned_technician_id` + `status = assigned`
    - إشعار الزبون: "تم تعيين فني معتمد" + **الاسم الأول + التقييم + عدد المشاريع** (بدون رقم)
  - `RejectDispatch` — فني يرفض:
    - تحديث `dispatch_queue.status = rejected`
    - تحديث `acceptance_rate` للفني
    - الانتقال للتالي في الطابور (sequential)
  - `ExpireDispatch` — انتهت مهلة الرد:
    - تحديث `dispatch_queue.status = expired`
    - الانتقال للتالي
  - `ProcessLead` — الفني يرسل عميل خاص → مراجعة Admin → تحويل لـ service_order → **الفني نفسه يأخذ الأولوية**
  - `ManualAssign` — Admin يعين فني يدوياً (يتجاوز Dispatch Engine)
  - `UpdateTechnicianLevel` — فحص دوري: ترقية/تخفيض مستوى الفني بناءً على jobs + rating
  - `UpdateDispatchStats` — تحديث إحصائيات التوزيع بعد كل توزيع/إكمال
  - `CalculateFairnessBoost` — حساب fairness_boost لكل فني:
    - `days_since_last_order >= 14` → boost = +15
    - `days_since_last_order >= 7` → boost = +8
    - `is_new_technician && new_technician_orders_count < 10` → boost += +20
    - `orders_this_month > avg_orders_in_zone * 1.5` → boost -= 10 (penalty للإفراط)
    - `orders_this_month < avg_orders_in_zone * 0.5` → boost += +5
    - يُعاد حسابها دورياً (كل ساعة أو عند كل توزيع)
  - `GetSelectionReason` — بناء نص سبب الاختيار للفني:
    - "تم اختيارك لأن: تغطي محافظة النجف ⋅ تقييمك 4.8 ⋅ 35 عملية مكتملة ⋅ موثق بالكامل"
    - إذا كان fairness_boost: "⋅ لم تستلم طلباً منذ 9 أيام"
    - إذا كان جديد: "⋅ مرحلة الإثبات — نريد إعطاؤك فرصة"

### 2.4 Handler Layer (`internal/handler/`)
- **`workforce_handler.go`** — REST endpoints:
  - **Public**: `GET /technicians` (معرض الفنيين — للثقة فقط، بدون أرقام), `GET /technicians/:id`, `GET /technicians/:id/portfolio`
  - **Customer**: `POST /service-orders` (إنشاء → تشغيل Dispatch تلقائياً), `POST /service-orders/from-calculator`, `GET /service-orders`, `GET /service-orders/:id` (تتبع — بدون اسم/رقم الفني), `POST /service-orders/:id/review`
  - **Technician**: `GET /technician/dispatch-queue` (الطلبات المرسلة له + selection_reason), `POST /technician/dispatch/:id/accept`, `POST /technician/dispatch/:id/reject`, `GET /technician/assignments` (المهام المقبولة — التفاصيل الكاملة بعد القبول), `POST /technician/orders/:id/status`, `POST /technician/orders/:id/media`, `POST /technician/orders/:id/tasks/:taskId/toggle`, `POST /technician/orders/:id/customer-unavailable`, `POST /technician/orders/:id/tracking` (تحديث GPS), `GET /technician/wallet`, `PUT /technician/availability` (تحديث حالة التواجد + ساعات العمل), `POST /technician/leads` (إنشاء lead لعميل خاص), `GET /technician/leads`
  - **Admin**: `GET/POST/PUT /admin/technicians`, `PUT /admin/technicians/:id/verify`, `PUT /admin/technicians/:id/ranking`, `PUT /admin/technicians/:id/zones`, `GET /admin/service-orders`, `PUT /admin/service-orders/:id/assign` (تعيين يدوي), `PUT /admin/service-orders/:id/status`, `GET /admin/dispatch-queue/:orderId` (عرض طابور التوزيع لطلب), `GET/POST /admin/service-pricing`, `GET /admin/technicians/:id/wallet`, `POST /admin/technicians/:id/wallet/settle`, `GET /admin/leads` (مراجعة طلبات الفنيين), `PUT /admin/leads/:id/approve`, `PUT /admin/leads/:id/reject`, `GET/POST/PUT /admin/dispatch-settings` (إعدادات التوزيع), `GET/POST/PUT /admin/technician-levels` (إدارة المستويات)

### 2.5 Route Registration (`cmd/api/main.go`)
- إضافة `workforceRepo`, `workforceService`, `dispatchService`, `workforceHandler` للـ wiring
- تسجيل المسارات تحت `/api/v1` مع middleware مناسب (Auth, RequireRole, RequirePermission)
- WebSocket: إضافة event `new_dispatch` لإرسال المهمة للفني لحظياً

---

## المرحلة 3: React Admin Panel

### 3.1 صفحة إدارة الفنيين (`TechniciansPage.tsx`)
- جدول الفنيين مع: الاسم، الدور، التخصص، المحافظة، **حالة التواجد** (🟢🟡🔴)، التقييم، عدد الأعمال، **acceptance_rate**
- أزرار: إضافة، تعديل، توثيق، إيقاف، تثبيت بالأعلى، إخفاء
- مودال توثيق المستندات (approve/reject)
- مودال معرض الأعمال (عرض الصور قبل/بعد)
- **مودال مناطق التغطية**: اختيار المحافظات التي يغطيها الفني
- **مودال المحفظة**: عرض الرصيد، المستحق، العمولات، تسديد
- **مودال ساعات العمل**: عرض/تعديل ساعات وأيام العمل
- **مودال المستوى**: عرض/تعديل مستوى الفني (Bronze/Silver/Gold) + نسبة العمولة

### 3.2 صفحة الطلبات الخدمية (`ServiceOrdersPage.tsx`)
- Kanban board للحالات: جديد → **جاري التوزيع** → معين → قيد التنفيذ → مكتمل → ملغى → **لا يوجد فني متوفر**
- تفاصيل كل طلب: الزبون، النوع، الموقع، الوصف، الفني المعين
- **طابور التوزيع**: عرض dispatch_queue لكل طلب (أي فنيين تم الإرسال لهم، من قبل/رفض/ينتظر)
- **زر تعيين يدوي**: Admin يعين فني بنفسه (يتجاوز Dispatch Engine)
- **زر إعادة التوزيع**: إذا فشل التوزيع، إعادة تشغيل Dispatch Engine
- **عرض selection_reason**: لكل فني في الطابور، سبب اختياره
- **خريطة تتبع**: عرض موقع الفني اللحظي على خريطة (من technician_tracking)
- سجل الحالات (timeline)
- صور وملاحظات التنفيذ

### 3.2c صفحة إعدادات التوزيع (`DispatchSettingsPage.tsx`)
- جدول إعدادات لكل نوع خدمة: dispatch_mode, timeout, candidates, min_score, auto_assign
- الإدارة تغير السلوك بدون تعديل الكود
- مثال: تركيب → sequential 10min / صيانة → parallel 3min 5 candidates

### 3.2b صفحة طلبات الفنيين (`TechnicianLeadsPage.tsx`)
- قائمة الـ leads المرسلة من الفنيين
- مراجعة: قبول / رفض / تعديل السعر / تعيين فني آخر
- عند القبول: تحويل لـ service_order رسمي

### 3.3 صفحة التسعير والعمولة (`PricingPage.tsx`)
- جدول التسعير لكل طلب
- إعداد نسبة العمولة الافتراضية
- تتبع حالة الدفع للفنيين
- تقارير الأرباح
- **محافظ الفنيين**: عرض مستحقات كل فني + زر تسديد
- **تقارير ذكية**: أكثر المحافظات طلباً، أكثر أنواع الأعطال، متوسط سعر التركيب، أرباح شهرية
- **إدارة المستويات**: تعريف مستويات الفنيين (Bronze/Silver/Gold/Platinum) + نسب العمولة
- **إعدادات التوزيع**: تتم في صفحة منفصلة (`DispatchSettingsPage.tsx`)
- **عدالة التوزيع (Fair Dispatch)**: عرض إحصائيات التوزيع لكل فني:
  - طلبات هذا الشهر/الأسبوع، آخر طلب استلمه، fairness_boost الحالي
  - تنبيه إذا كان فني يحصل على نسبة > 30% من طلبات المحافظة
  - مؤشر "مرحلة الإثبات" للفنيين الجدد (أول 10 طلبات)

### 3.4 تحديث التنقل (`App.tsx` + `AdminLayout`)
- إضافة روابط: الفنيين، الطلبات الخدمية، التسعير، **إعدادات التوزيع**، **طلبات الفنيين (Leads)**

---

## المرحلة 4: Flutter App (واجهة الفني داخل نفس التطبيق)

### 4.1 توجيه بناءً على الدور (`main_navigation_screen.dart`)
- عند تسجيل الدخول، إذا كان الدور `installer` أو `engineer`:
  - عرض `TechnicianDashboardScreen` بدلاً من الواجهة العادية
  - تبويبات: المهام الجديدة (Dispatch Queue), المهام الحالية, السجل, المحفظة, الملف الشخصي
  - **شريط حالة التواجد**: زر toggling متوفر/مشغول/إجازة في الأعلى

### 4.2 شاشات الفني (`lib/features/workforce/technician/`)
- **`technician_dashboard_screen.dart`** — لوحة الفني الرئيسية
  - إحصائيات: طلبات جديدة، قيد التنفيذ، مكتملة، التقييم
  - **شريط حالة التواجد**: متوفر 🟢 / مشغول 🟡 / إجازة 🔴
  - قائمة المهام الحالية مع أزرار الحالة
- **`dispatch_queue_screen.dart`** — الطلبات الجديدة المرسلة له
  - بطاقة لكل طلب: نوع العمل، الموقع، حجم المنظومة، **الأجر المتوقع فقط** (لا تفاصيل كاملة قبل القبول)
  - **selection_reason**: "تم اختيارك لأن: تغطي النجف ⋅ تقييمك 4.8 ⋅ 35 عملية مكتملة"
  - **عد تنازلي** للمهلة (من dispatch_settings)
  - أزرار: **[قبول المهمة]** / **[رفض]**
  - WebSocket: استلام الطلبات لحظياً (لا حاجة لـ refresh)
  - **بعد القبول**: تظهر التفاصيل الكاملة (الزبون، العنوان، السعر الكامل، المهام)
- **`job_detail_screen.dart`** — تفاصيل المهمة (بعد القبول)
  - معلومات الطلب الكاملة، قائمة المهام (checklist)، رفع صور/ملاحظات
  - أزرار: في الطريق، وصلت، بدأت العمل، تم الإنجاز
  - زر "الزبون غير متجاوب" (رفع GPS + صورة)
  - **إرسال GPS تلقائي** كل 30-60 ثانية عند الحالة "في الطريق" (technician_tracking)
- **`technician_profile_screen.dart`** — ملف الفني الشخصي
  - معرض الأعمال، المستندات، التقييمات، الإحصائيات
  - **إدارة مناطق التغطية** + **ساعات العمل**
- **`technician_wallet_screen.dart`** — محفظة الفني
  - الرصيد الحالي، إجمالي الأرباح، العمولات، المستحق
  - سجل المعاملات (لكل طلب مكتمل)
- **`technician_lead_screen.dart`** — إنشاء lead لعميل خاص
  - نموذج: اسم العميل، هاتف، نوع العمل، عنوان، سعر مقترح
  - حالة الـ lead (pending_review / approved / rejected)

### 4.3 شاشات الزبون للطلبات الخدمية (`lib/features/workforce/customer/`)
- **`create_service_order_screen.dart`** — إنشاء طلب خدمي
  - اختيار النوع (تركيب/صيانة/معاينة/استشارة/إصلاح)
  - وصف، موقع، تاريخ مفضل
  - **لا يظهر الفنيين ولا أرقامهم** — فقط "سيتم تعيين فني معتمد تلقائياً"
  - عند الإرسال: "تم استلام طلبك، جاري البحث عن فني متوفر..."
- **`service_order_detail_screen.dart`** — تتبع الطلب
  - **الحالات التي يراها الزبون**: تم الاستلام → جاري التعيين → تم تعيين فني معتمد → الفني في الطريق → وصل الفني → جاري التنفيذ → تم الإنجاز
  - **بعد التعيين**: يظهر **الاسم الأول فقط** + التقييم + عدد المشاريع + **مستوى الفني** (Bronze/Silver/Gold) — بدون رقم هاتف
  - **خريطة تتبع**: موقع الفني اللحظي + المسافة ("الفني على بعد 2.5 كم")
  - timeline كامل للحالات
  - تقييم بعد الإكمال (جودة + التزام + سرعة)
- **`service_orders_list_screen.dart`** — سجل طلباتي

### 4.4 تحديث واجهة الفنيين الحالية (`home_screen.dart`)
- **تحويل قسم الفنيين لمعرض ثقة فقط** — عرض الإحصائيات والأعمال بدون أرقام
- بدل "اتصل بالفني" → زر **"اطلب خدمة شمسية"** → يفتح `create_service_order_screen`
- **لا يختار الزبون فني محدد** — النظام يوزع تلقائياً
- **فلترة الفنيين حسب المحافظة** — لا يظهر فني خارج منطقة الزبون

### 4.5 ربط الحاسبات بالطلبات الخدمية
- بعد عرض نتيجة أي حاسبة (مثل `system_sizing` أو `full_cost`):
  - زر **"اطلب فني معتمد للتركيب"**
  - ينشأ `ServiceOrder` مع `calculator_result` يحوي نتيجة الحساب
  - يمرر `system_size_kw` تلقائياً من نتيجة الحاسبة
  - **Dispatch Engine يبدأ تلقائياً** بعد إنشاء الطلب
- ملفات متأثرة: شاشات الحاسبات في `lib/features/calculator/`

### 4.6 API Client (`core/network/api_client.dart`)
- إضافة دوال: `getTechnicians`, `createServiceOrder`, `createServiceOrderFromCalculator`, `getMyServiceOrders`, `getDispatchQueue` (+ selection_reason), `acceptDispatch`, `rejectDispatch`, `getTechnicianAssignments`, `updateAssignmentStatus`, `uploadJobMedia`, `toggleJobTask`, `submitReview`, `markCustomerUnavailable`, `updateTracking` (GPS), `getTechnicianWallet`, `updateAvailability`, `createTechnicianLead`, `getTechnicianLeads`

---

## المرحلة 5: نظام التسعير والعمولة

### 5.1 منطق التسعير
- **سعر أساسي** حسب نوع الخدمة وحجم المنظومة:
  - تركيب: $/KW × حجم المنظومة + رسوم ثابتة
  - صيانة: رسوم ثابتة + قطع غيار
  - معاينة: رسوم ثابتة
  - إصلاح: تقدير بعد المعاينة
- **عمولة المنصة**: نسبة متغيرة حسب **مستوى الفني** (technician_levels):
  - Bronze (0-20 أعمال): 15%
  - Silver (20-100): 12%
  - Gold (100+): 10%
  - Platinum (200+ + تقييم 4.8+): 8%
  - تحفز الفنيين على إنجاز المزيد لتقليل العمولة
- **دفع الفني**: base_price - commission = technician_payout
- **قبل القبول**: الفني يرى **الأجر المتوقع فقط** (رقم تقريبي)
- **بعد القبول**: تظهر التفاصيل الكاملة

### 5.2 جدول أسعار الخدمات (`service_price_tiers`)
- يضاف ضمن migration 019 كجدول مرجعي:
  - service_type, min_price_iqd, max_price_iqd, default_price_iqd
  - commission_percent

### 5.3 محفظة الفني (`technician_wallet`)
- عند إكمال طلب: `technician_payout_iqd` يُضاف لـ `balance_iqd` و `total_earned_iqd`
- `platform_commission_iqd` يُضاف لـ `total_commission_iqd`
- `pending_payout_iqd` = الأرباح غير المسددة
- Admin يضغط "تسديد" → `balance_iqd` يُصفّى، `pending_payout_iqd` = 0، يُسجل `last_settlement_at`

### 5.4 تتبع المدفوعات
- `payment_status`: unpaid → pending → paid_to_technician → settled
- Admin يمكنه تحديث الحالة يدوياً
- تقارير: إجمالي الأرباح، عمولات الفنيين، المدفوعات المعلقة

---

## ترتيب التنفيذ (متوازي لكن بترتيب منطقي)

| الخطوة | المهمة | الملفات |
|--------|--------|---------|
| 1 | DB Migration 019 | `migrations/019_workforce_management_system.sql` |
| 2 | Domain structs | `internal/domain/workforce.go` |
| 3 | Repository | `internal/repository/workforce_repository.go` |
| 4 | Service (workforce + dispatch) | `internal/service/workforce_service.go` + `dispatch_service.go` |
| 5 | Handler | `internal/handler/workforce_handler.go` |
| 6 | Routes wiring | `cmd/api/main.go` |
| 7 | Admin: TechniciansPage | `iraq-solar-admin/src/pages/TechniciansPage.tsx` |
| 8 | Admin: ServiceOrdersPage | `iraq-solar-admin/src/pages/ServiceOrdersPage.tsx` |
| 9 | Admin: PricingPage | `iraq-solar-admin/src/pages/PricingPage.tsx` |
| 10 | Admin: App.tsx + Layout | `iraq-solar-admin/src/App.tsx` |
| 11 | Flutter: workforce feature | `lib/features/workforce/` |
| 12 | Flutter: API client methods | `lib/core/network/api_client.dart` |
| 13 | Flutter: role-based nav + availability toggle | `main_navigation_screen.dart` |
| 14 | Flutter: update home installers (trust gallery) | `home_screen.dart` |
| 15 | Flutter: calculator → service order integration | `lib/features/calculator/` |
| 16 | Admin: TechnicianLeadsPage | `iraq-solar-admin/src/pages/TechnicianLeadsPage.tsx` |
| 17 | Admin: DispatchSettingsPage | `iraq-solar-admin/src/pages/DispatchSettingsPage.tsx` |

---

## المبادئ الأساسية
- **الزبون لا يرى الفنيين قبل التعيين** — بعد التعيين يرى الاسم الأول + التقييم + المستوى فقط (بدون رقم)
- **المنصة هي الوسيط والمنسق** — تستلم، توزع، تراقب، تحاسب
- **Dispatch Engine** — توزيع تلقائي بناءً على التوفر + التخصص + الموقع + Score
- **Hybrid Dispatch** — النظام يختار sequential/parallel بناءً على نوع/حجم الطلب (dispatch_settings)
- **dispatch_settings** — الإدارة تتحكم بسلوك التوزيع بدون تعديل كود
- **selection_reason** — الفني يرى سبب اختياره (يزيد نسبة القبول)
- **مهلة الرد** — قابلة للتغيير حسب نوع الخدمة (3-10 دقائق)
- **الفني يحدد توفره** — متوفر/مشغول/إجازة + ساعات وأيام العمل
- **الفني يجلب عملاء** — technician_leads، والفني نفسه يأخذ الأولوية بعد التحويل
- **مستويات الفنيين** — Bronze/Silver/Gold/Platinum، العمولة تقل مع الترقية
- **ثقة الفني** — verification_level + complaint_count يدخلان في Score
- **تتبع GPS** — الفني في الطريق → الزبون يرى المسافة على خريطة
- **الأجر المتوقع قبل القبول** — الفني يرى رقماً تقريبياً، التفاصيل الكاملة بعد القبول
- **حماية الفني** — تسجيل عدم تجاوب الزبون بـ GPS + صورة
- **ترتيب ذكي** — 35% تقييم + 20% قرب + 15% أعمال + 10% سرعة + 5% التزام + 10% توثيق + 5% سجل
- **Fair Dispatch** — 70% جودة + 30% عدالة توزيع (فرص عادلة، موازنة الحصص، مرحلة إثبات للجدد)
- **فرصة عادلة** — الفني الذي لم يستلم طلباً منذ 14 يوم يحصل على boost في Score
- **مرحلة الإثبات** — أول 10 طلبات للفني الجديد تحصل على boost لضمان حصوله على فرص
- **موازنة الحصص** — فني أخذ 20 طلب هذا الشهر ينخفض Score مؤقتاً، فني أخذ طلبين يرتفع
- **منافسة عادلة** — في parallel، فنيين متقاربين في Score يتنافسون — أسرع قبول يفوز
- **مناطق تغطية** — الفني يظهر فقط في المحافظات التي يغطيها
- **محفظة مالية** — كل فني له محفظة تتبع أرباحه ومستحقاته
- **تكامل الحاسبات** — نتيجة الحاسبة تتحول لطلب خدمة → توزيع تلقائي
- **أرشيف مشاريع** — كل طلب مكتمل = ملف مشروع كامل بالصور والتقييم
- **تعيين يدوي** — Admin يمكنه تجاوز Dispatch Engine وتعيين فني محدد

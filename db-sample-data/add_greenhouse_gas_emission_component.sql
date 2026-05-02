-- 新增溫室氣體排放統計組件到資料庫
-- 使用說明：
-- 此 SQL 檔案應在 dashboardmanager 資料庫執行
-- 執行指令：psql -h 192.168.128.5 -U postgres -d dashboardmanager -f db-sample-data/add_greenhouse_gas_emission_component.sql

-- 如果資料表不存在，先建立資料表結構
CREATE TABLE IF NOT EXISTS public.components (
    id SERIAL PRIMARY KEY,
    index VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.component_charts (
    index VARCHAR(255) PRIMARY KEY,
    color TEXT[],
    types TEXT[],
    unit VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS public.query_charts (
    index VARCHAR(255) PRIMARY KEY,
    history_config TEXT,
    map_config_ids INTEGER[],
    map_filter JSONB,
    time_from VARCHAR(50),
    time_to VARCHAR(50),
    update_freq INTEGER,
    update_freq_unit VARCHAR(50),
    source VARCHAR(255),
    short_desc TEXT,
    long_desc TEXT,
    use_case TEXT,
    links TEXT[],
    contributors TEXT[],
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    query_type VARCHAR(50),
    query_chart TEXT,
    query_history TEXT,
    city VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS public.dashboards (
    id SERIAL PRIMARY KEY,
    index VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    components INTEGER[],
    icon VARCHAR(50),
    updated_at TIMESTAMP,
    created_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.dashboard_groups (
    dashboard_id INTEGER,
    group_id INTEGER,
    PRIMARY KEY (dashboard_id, group_id)
);

CREATE TABLE IF NOT EXISTS public.groups (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    is_personal BOOLEAN,
    create_by VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS public.component_maps (
    id SERIAL PRIMARY KEY,
    index VARCHAR(255) UNIQUE NOT NULL,
    title VARCHAR(255),
    type VARCHAR(50),
    source VARCHAR(50),
    size VARCHAR(50),
    icon VARCHAR(50),
    paint JSONB,
    property JSONB
);

CREATE TABLE IF NOT EXISTS public.contributors (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255),
    user_name VARCHAR(255),
    image VARCHAR(255),
    link VARCHAR(255),
    identity VARCHAR(50),
    description TEXT,
    include BOOLEAN,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- 1. 新增組件到 components 表 (使用 UPSERT 避免重複)
INSERT INTO public.components (id, index, name) VALUES (300, 'greenhouse_gas_emission', '溫室氣體排放統計')
ON CONFLICT (id) DO UPDATE SET index = EXCLUDED.index, name = EXCLUDED.name;

-- 2. 新增圖表配置到 component_charts 表 (使用 UPSERT 避免重複)
INSERT INTO public.component_charts (index, color, types, unit) VALUES
('greenhouse_gas_emission', '{#24B0DD,#56B96D,#F8CF58,#F5AD4A,#E170A6,#ED6A45}', '{StackedColumn100Chart}', '%')
ON CONFLICT (index) DO UPDATE SET color = EXCLUDED.color, types = EXCLUDED.types, unit = EXCLUDED.unit;

-- 3. 新增查詢配置到 query_charts 表 (臺北市)
INSERT INTO public.query_charts (
    index,
    history_config,
    map_config_ids,
    map_filter,
    time_from,
    time_to,
    update_freq,
    update_freq_unit,
    source,
    short_desc,
    long_desc,
    use_case,
    links,
    contributors,
    created_at,
    updated_at,
    query_type,
    query_chart,
    query_history,
    city
) VALUES (
    'greenhouse_gas_emission',
    NULL,
    NULL,
    '{}'::jsonb,
    'static',
    NULL,
    NULL,
    NULL,
    '環保局',
    '顯示臺北市溫室氣體排放統計',
    '此圖顯示臺北市溫室氣體排放統計，包含住商部門、運輸部門、廢棄物部門、工業部門、農業部門及森林部門的排放量與占比。資料涵蓋 2005 年至 2024 年，呈現各部門排放量的時間變化趨勢。透過 100% 堆疊柱狀圖，可以清楚看出各部門在總排放量中的占比變化，有助於評估減碳政策的成效與各部門的貢獻度。',
    '適用於環境政策評估、減碳規劃與氣候變遷監測。政府機構可運用此數據評估各部門的減碳成效，調整政策方向。企業可依據部門排放占比規劃減碳策略。研究人員可分析長期趨勢，評估氣候變遷對城市的影響，為未來的永續發展提供科學依據。',
    ARRAY['https://data.taipei/dataset/detail?id=XXXXX']::text[],
    ARRAY['doit']::text[],
    NOW(),
    NOW(),
    'two_d',
    'SELECT 年度 as x_axis, ''住商部門'' as y_axis, "住商部門占比_%" as data FROM public.greenhouse_gas_emission_tpe
    UNION ALL
    SELECT 年度 as x_axis, ''運輸部門'' as y_axis, "運輸部門占比_%" as data FROM public.greenhouse_gas_emission_tpe
    UNION ALL
    SELECT 年度 as x_axis, ''廢棄物部門'' as y_axis, "廢棄物部門占比_%" as data FROM public.greenhouse_gas_emission_tpe
    UNION ALL
    SELECT 年度 as x_axis, ''工業部門'' as y_axis, "工業部門占比_%" as data FROM public.greenhouse_gas_emission_tpe
    UNION ALL
    SELECT 年度 as x_axis, ''農業部門'' as y_axis, "農業部門占比_%" as data FROM public.greenhouse_gas_emission_tpe
    UNION ALL
    SELECT 年度 as x_axis, ''森林部門'' as y_axis, "森林部門占比_%" as data FROM public.greenhouse_gas_emission_tpe',
    NULL,
    'taipei'
)
ON CONFLICT (index) DO UPDATE SET
    history_config = EXCLUDED.history_config,
    map_config_ids = EXCLUDED.map_config_ids,
    map_filter = EXCLUDED.map_filter,
    time_from = EXCLUDED.time_from,
    time_to = EXCLUDED.time_to,
    update_freq = EXCLUDED.update_freq,
    update_freq_unit = EXCLUDED.update_freq_unit,
    source = EXCLUDED.source,
    short_desc = EXCLUDED.short_desc,
    long_desc = EXCLUDED.long_desc,
    use_case = EXCLUDED.use_case,
    links = EXCLUDED.links,
    contributors = EXCLUDED.contributors,
    updated_at = EXCLUDED.updated_at,
    query_type = EXCLUDED.query_type,
    query_chart = EXCLUDED.query_chart,
    query_history = EXCLUDED.query_history,
    city = EXCLUDED.city;

-- 4. 將組件加入到現有的儀表板或建立新的
-- 先嘗試加入到現有的 dashboard
UPDATE public.dashboards
SET components = array_append(components, 300)
WHERE index = 'transport-analysis' OR index = 'ltc_care_tpe';

-- 如果沒有更新任何記錄（沒有這些 dashboard），則建立新的
-- 註：這個邏輯需要手動執行，建議先檢查是否有現有的 dashboard

-- 5. 新增必要的群組 (如果不存在)
INSERT INTO public.groups (name, is_personal, create_by) VALUES
('public', false, NULL),
('taipei', false, NULL),
('metrotaipei', false, NULL)
ON CONFLICT (name) DO NOTHING;

-- 6. 設定儀表板群組 (加入 taipei 群組)
INSERT INTO public.dashboard_groups (dashboard_id, group_id)
SELECT d.id, g.id
FROM public.dashboards d
CROSS JOIN public.groups g
WHERE d.index = 'greenhouse_gas_dashboard' AND g.name = 'taipei'
ON CONFLICT (dashboard_id, group_id) DO NOTHING;

-- 註：執行此 SQL 前，請先確保已將 CSV 資料匯入到 public.greenhouse_gas_emission_tpe 表
-- 匯入指令範例：
-- CREATE TABLE public.greenhouse_gas_emission_tpe (
--     年度 INTEGER,
--     住商部門排放量_萬公噸 NUMERIC,
--     住商部門占比_百分比 NUMERIC,
--     運輸部門排放量_萬公噸 NUMERIC,
--     運輸部門占比_百分比 NUMERIC,
--     廢棄物部門排放量_萬公噸 NUMERIC,
--     廢棄物部門占比_百分比 NUMERIC,
--     工業部門排放量_萬公噸 NUMERIC,
--     工業部門占比_百分比 NUMERIC,
--     農業部門排放量_萬公噸 NUMERIC,
--     農業部門占比_百分比 NUMERIC,
--     森林部門排放量_萬公噸 NUMERIC,
--     森林部門占比_百分比 NUMERIC,
--     總排放量_萬公噸 NUMERIC,
--     人均排放量_公噸_年 NUMERIC
-- );
-- 
-- COPY public.greenhouse_gas_emission_tpe FROM '/path/to/臺北市溫室氣體排放統計 2024.csv' DELIMITER ',' CSV HEADER;

-- 臺北市溫室氣體排放統計：本市總排放量及人均排放量
--
-- 目的：
-- 1. 將 data/臺北市溫室氣體排放統計 2024.csv 的資料寫入 dashboard 資料庫。
-- 2. 在 dashboardmanager 資料庫新增一個使用現有 ColumnLineChart 的 dashboard component。
--
-- 為了避免容器讀不到本機 CSV 路徑，以及原始 CSV 為 Big5/CP950 編碼造成 COPY 亂碼，
-- 本檔已將 CSV 內容轉成 UTF-8 SQL INSERT values。
--
-- Docker 環境執行方式（請在專案根目錄執行）：
--
--   # 1. 寫入 dashboard 資料庫資料表
--   docker exec -i postgres-data psql -U postgres -d dashboard \
--     -v run_data=on -v run_manager=off \
--     < db-sample-data/add_greenhouse_gas_total_per_capita_component.sql
--
--   # 2. 寫入 dashboardmanager 組件設定，並加入預設 dashboard
--   docker exec -i postgres-manager psql -U postgres -d dashboardmanager \
--     -v run_data=off -v run_manager=on \
--     < db-sample-data/add_greenhouse_gas_total_per_capita_component.sql
--
-- 若你的資料庫 user 不是 postgres，請自行替換 -U 後面的使用者。
--
-- 預設會建立或使用 dashboard index = climate-environment。
-- 如果想加入既有 dashboard，可在第 2 步加上 target_dashboard_index：
--
--   docker exec -i postgres-manager psql -U postgres -d dashboardmanager \
--     -v run_data=off -v run_manager=on \
--     -v target_dashboard_index=your-dashboard-index \
--     < db-sample-data/add_greenhouse_gas_total_per_capita_component.sql

\set ON_ERROR_STOP on

\if :{?run_data}
\else
\set run_data on
\endif

\if :{?run_manager}
\else
\set run_manager on
\endif

\if :{?target_dashboard_index}
\else
\set target_dashboard_index climate-environment
\endif

\if :run_data

BEGIN;

CREATE TABLE IF NOT EXISTS public.greenhouse_gas_emission_tpe (
    year integer PRIMARY KEY,
    residential_commercial_emission_10k_tons numeric,
    residential_commercial_ratio_percent numeric,
    transport_emission_10k_tons numeric,
    transport_ratio_percent numeric,
    waste_emission_10k_tons numeric,
    waste_ratio_percent numeric,
    industrial_emission_10k_tons numeric,
    industrial_ratio_percent numeric,
    agriculture_emission_10k_tons numeric,
    agriculture_ratio_percent numeric,
    forest_emission_10k_tons numeric,
    forest_ratio_percent numeric,
    total_emission_10k_tons numeric,
    per_capita_emission_tons_per_year numeric,
    data_time timestamp with time zone DEFAULT now()
);

TRUNCATE TABLE public.greenhouse_gas_emission_tpe;

INSERT INTO public.greenhouse_gas_emission_tpe (
    year,
    residential_commercial_emission_10k_tons,
    residential_commercial_ratio_percent,
    transport_emission_10k_tons,
    transport_ratio_percent,
    waste_emission_10k_tons,
    waste_ratio_percent,
    industrial_emission_10k_tons,
    industrial_ratio_percent,
    agriculture_emission_10k_tons,
    agriculture_ratio_percent,
    forest_emission_10k_tons,
    forest_ratio_percent,
    total_emission_10k_tons,
    per_capita_emission_tons_per_year
) VALUES
    (2005, 977.57, 74.77, 255.23, 19.52, 37.86, 2.90, 36.51, 2.79, 0.20, 0.02, -8.83, -0.68, 1307.36, 5.00),
    (2006, 997.87, 75.64, 245.82, 18.63, 37.99, 2.88, 37.46, 2.84, 0.18, 0.01, -8.83, -0.67, 1319.32, 5.01),
    (2007, 997.65, 76.22, 237.32, 18.13, 36.20, 2.77, 37.51, 2.87, 0.19, 0.01, -8.83, -0.67, 1308.88, 4.98),
    (2008, 1015.48, 76.87, 232.94, 17.63, 34.10, 2.58, 38.32, 2.09, 0.18, 0.01, -8.83, -0.67, 1321.02, 5.04),
    (2009, 935.17, 75.37, 235.42, 18.97, 34.58, 2.79, 35.39, 2.85, 0.18, 0.01, -8.83, -0.71, 1240.73, 4.76),
    (2010, 933.84, 74.96, 241.59, 19.39, 34.81, 2.79, 35.40, 2.84, 0.17, 0.01, -8.83, -0.71, 1245.80, 4.76),
    (2011, 932.20, 74.82, 243.39, 19.53, 34.88, 2.80, 35.29, 2.83, 0.17, 0.01, -8.83, -0.71, 1245.92, 4.70),
    (2012, 909.60, 74.58, 242.13, 19.85, 33.25, 2.73, 34.48, 2.83, 0.17, 0.01, -8.83, -0.72, 1219.63, 4.56),
    (2013, 884.90, 74.02, 244.87, 20.48, 33.43, 2.80, 32.14, 2.69, 0.17, 0.01, -8.83, -0.74, 1195.52, 4.45),
    (2014, 886.63, 73.94, 251.57, 20.98, 29.28, 2.44, 31.52, 2.63, 0.16, 0.01, -8.83, -0.74, 1199.16, 4.44),
    (2015, 893.45, 73.93, 256.77, 21.25, 28.82, 2.38, 29.33, 2.43, 0.16, 0.01, -8.83, -0.73, 1208.53, 4.47),
    (2016, 921.30, 74.24, 261.03, 21.03, 28.97, 2.33, 29.52, 2.38, 0.15, 0.01, -8.83, -0.71, 1240.97, 4.60),
    (2017, 945.39, 74.93, 254.87, 20.20, 30.84, 2.44, 30.40, 2.41, 0.15, 0.01, -24.03, -1.91, 1261.64, 4.70),
    (2018, 902.21, 74.48, 249.28, 20.58, 30.96, 2.56, 28.76, 2.37, 0.15, 0.01, -24.03, -1.98, 1211.36, 4.54),
    (2019, 854.97, 73.73, 245.54, 21.18, 32.07, 2.77, 26.83, 2.31, 0.14, 0.01, -24.03, -2.07, 1159.55, 4.38),
    (2020, 845.49, 74.24, 238.43, 20.94, 30.61, 2.69, 24.12, 2.12, 0.15, 0.01, -24.03, -2.11, 1138.81, 4.38),
    (2021, 845.55, 75.88, 213.76, 19.18, 30.14, 2.70, 24.66, 2.21, 0.15, 0.01, -24.03, -2.16, 1114.26, 4.41),
    (2022, 814.94, 75.12, 215.73, 19.89, 29.70, 2.74, 24.36, 2.25, 0.15, 0.01, -24.03, -2.22, 1084.88, 4.37),
    (2023, 822.20, 75.21, 213.93, 19.57, 31.29, 2.86, 25.59, 2.34, 0.15, 0.01, -24.03, -2.20, 1093.15, 4.35),
    (2024, 802.29, 76.13, 201.76, 19.15, 30.15, 2.86, 19.45, 1.85, 0.16, 0.02, -24.03, -2.28, 1053.81, 4.23);

COMMIT;

\endif

\if :run_manager

BEGIN;

INSERT INTO public.components (index, name)
VALUES (
    'greenhouse_gas_total_per_capita',
    '臺北市溫室氣體排放統計—本市總排放量及人均排放量'
)
ON CONFLICT (index) DO UPDATE
SET name = EXCLUDED.name;

INSERT INTO public.component_charts (index, color, types, unit)
VALUES (
    'greenhouse_gas_total_per_capita',
    ARRAY['#56B96D', '#F5AD4A'],
    ARRAY['ColumnLineChart'],
    ''
)
ON CONFLICT (index) DO UPDATE
SET color = EXCLUDED.color,
    types = EXCLUDED.types,
    unit = EXCLUDED.unit;

DELETE FROM public.query_charts
WHERE index = 'greenhouse_gas_total_per_capita'
  AND city = 'taipei';

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
    'greenhouse_gas_total_per_capita',
    NULL,
    NULL,
    NULL,
    'static',
    NULL,
    NULL,
    NULL,
    '環保局',
    '顯示臺北市歷年溫室氣體總排放量與人均排放量。',
    '此組件呈現臺北市 2005 年至 2024 年溫室氣體總排放量與人均排放量。總排放量以萬公噸表示，人均排放量以公噸/年表示，可用於觀察城市整體排放趨勢與平均居民排放強度的變化。',
    '適用於氣候治理、減碳政策追蹤、城市永續指標監測，以及評估長期溫室氣體排放趨勢。',
    ARRAY['https://data.taipei/'],
    ARRAY['doit'],
    NOW(),
    NOW(),
    'time',
    'SELECT x_axis, y_axis, data
FROM (
    SELECT
        TO_TIMESTAMP(year::text || ''-12-31'', ''YYYY-MM-DD'') AT TIME ZONE ''Asia/Taipei'' AS x_axis,
        ''總排放量（萬公噸）'' AS y_axis,
        total_emission_10k_tons AS data,
        1 AS sort_order
    FROM public.greenhouse_gas_emission_tpe
    UNION ALL
    SELECT
        TO_TIMESTAMP(year::text || ''-12-31'', ''YYYY-MM-DD'') AT TIME ZONE ''Asia/Taipei'' AS x_axis,
        ''人均排放量（公噸/年）'' AS y_axis,
        per_capita_emission_tons_per_year AS data,
        2 AS sort_order
    FROM public.greenhouse_gas_emission_tpe
) AS greenhouse_gas_series
ORDER BY x_axis, sort_order',
    NULL,
    'taipei'
);

INSERT INTO public.dashboards (index, name, components, icon, updated_at, created_at)
VALUES (:'target_dashboard_index', '氣候環境', ARRAY[]::integer[], 'eco', NOW(), NOW())
ON CONFLICT (index) DO NOTHING;

UPDATE public.dashboards AS dashboards
SET components = CASE
        WHEN COALESCE(dashboards.components, ARRAY[]::integer[]) @> ARRAY[components.id::integer]
            THEN COALESCE(dashboards.components, ARRAY[]::integer[])
        ELSE array_append(COALESCE(dashboards.components, ARRAY[]::integer[]), components.id::integer)
    END,
    updated_at = NOW()
FROM public.components AS components
WHERE dashboards.index = :'target_dashboard_index'
  AND components.index = 'greenhouse_gas_total_per_capita';

INSERT INTO public.groups (name, is_personal, create_by)
SELECT group_values.name, group_values.is_personal, group_values.create_by
FROM (
    VALUES
        ('public', false, NULL::integer),
        ('taipei', false, NULL::integer)
) AS group_values(name, is_personal, create_by)
WHERE NOT EXISTS (
    SELECT 1
    FROM public.groups
    WHERE public.groups.name = group_values.name
);

INSERT INTO public.dashboard_groups (dashboard_id, group_id)
SELECT dashboards.id, groups.id
FROM public.dashboards AS dashboards
CROSS JOIN (
    SELECT MIN(id) AS id
    FROM public.groups
    WHERE name IN ('public', 'taipei')
    GROUP BY name
) AS groups
WHERE dashboards.index = :'target_dashboard_index'
ON CONFLICT (dashboard_id, group_id) DO NOTHING;

COMMIT;

\endif

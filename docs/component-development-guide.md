# 組件開發指南

本文說明如何在 Taipei City Dashboard 專案中新增組件。常見情境分成兩種：使用既有圖表類型建立新的資料組件，以及新增一個全新的圖表組件類型。

## 一、使用現有圖表類型建立新組件

### 步驟 1：準備資料與 SQL

先確認資料庫中已有可用資料表，並撰寫查詢讓後端能回傳前端圖表需要的欄位。

一般圖表常用欄位：

- `x_axis`：X 軸資料，例如類別名稱、時間或數值
- `y_axis`：Y 軸資料或系列名稱
- `data`：實際數值

範例：

```sql
SELECT
    COALESCE(direction, '未知') AS x_axis,
    '總長度' AS y_axis,
    ROUND((SUM(cycling_length) / 1000)::numeric, 2) AS data
FROM public.bike_network_tpe
WHERE city = '台北市'
GROUP BY direction
ORDER BY data DESC;
```

撰寫 SQL 時建議：

- 使用 `COALESCE` 處理 `NULL` 值，避免前端顯示空白標籤。
- 使用 `ROUND` 控制數值精度。
- 確認欄位名稱符合圖表組件預期格式。
- 先在資料庫直接執行 SQL，確認結果筆數、欄位名稱與資料型別。

### 步驟 2：新增資料庫組件設定

組件需要寫入 `dashboardmanager` 資料庫中的幾個資料表。以下是基本流程，實際欄位仍需依正式資料庫 schema 調整。

新增組件基本資訊：

```sql
INSERT INTO public.components (id, index, name)
VALUES (302, 'bike_network_length', '自行車路網長度統計');
```

新增圖表設定：

```sql
INSERT INTO public.component_charts (index, color, types, unit)
VALUES (
    'bike_network_length',
    ARRAY['#4CAF50', '#8BC34A', '#CDDC39', '#FFEB3B', '#FFC107', '#FF9800'],
    ARRAY['ColumnChart'],
    '公里'
);
```

新增查詢設定：

```sql
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
    'bike_network_length',
    NULL,
    '{}',
    '{}',
    'static',
    NULL,
    0,
    NULL,
    '交通局',
    '顯示臺北市各方向自行車路網總長度。',
    '此圖表呈現臺北市各方向的自行車路網總長度。',
    '適用於交通規劃與綠色運輸分析。',
    ARRAY['https://data.taipei/'],
    ARRAY['doit'],
    NOW(),
    NOW(),
    'two_d',
    'SELECT COALESCE(direction, ''未知'') AS x_axis, ''總長度'' AS y_axis, ROUND((SUM(cycling_length) / 1000)::numeric, 2) AS data FROM public.bike_network_tpe WHERE city = ''台北市'' GROUP BY direction ORDER BY data DESC',
    NULL,
    'taipei'
);
```

將組件加入儀表板：

```sql
UPDATE public.dashboards
SET components = array_append(components, 302)
WHERE index = 'transport-analysis';
```

若 SQL 需要重複執行，請改用 `ON CONFLICT` 或先檢查資料是否存在，避免重複插入。

### 步驟 3：重新整理前端

重新整理前端頁面。若前端是以開發模式啟動，Vite 會支援 Hot Reload；若組件設定來自資料庫，仍可能需要重新整理頁面或重新取得 API 資料。

## 二、新增全新的圖表類型

以下以 `BubbleChart` 為例，說明如何新增全新的圖表類型。

### 步驟 1：建立 Vue 圖表組件

在 `Taipei-City-Dashboard-FE/src/dashboardComponent/components/` 新增檔案：

```text
BubbleChart.vue
```

現有圖表組件大多使用 `vue3-apexcharts`。新組件應維持相同 props 與 emits，讓 `DashboardComponent.vue` 可以用一致方式傳入資料與地圖互動事件。

必要 props：

- `chart_config`
- `activeChart`
- `series`
- `map_config`
- `map_filter`
- `map_filter_on`

必要 emits：

- `filterByParam`
- `filterByLayer`
- `clearByParamFilter`
- `clearByLayerFilter`
- `fly`

氣泡圖資料格式建議：

- `x_axis`：X 軸數值
- `y_axis`：Y 軸數值
- `z_axis` 或 `data`：氣泡大小

範例：

```vue
<!-- Developed by Taipei Urban Intelligence Center 2023-2024-->
<script setup>
import { computed, ref } from "vue";
import VueApexCharts from "vue3-apexcharts";

const props = defineProps([
	"chart_config",
	"activeChart",
	"series",
	"map_config",
	"map_filter",
	"map_filter_on",
]);

defineEmits([
	"filterByParam",
	"filterByLayer",
	"clearByParamFilter",
	"clearByLayerFilter",
	"fly",
]);

const chartOptions = ref({
	chart: {
		type: "bubble",
		toolbar: { show: false },
		zoom: { enabled: false },
	},
	colors: props.chart_config.color || ["#4CAF50", "#2196F3", "#FF9800"],
	dataLabels: { enabled: false },
	legend: { show: false },
	fill: { opacity: 0.8 },
	xaxis: { title: { text: "X 軸" } },
	yaxis: { title: { text: "Y 軸" } },
	tooltip: {
		enabled: true,
		theme: "dark",
		z: { title: "大小" },
		followCursor: true,
		intersect: true,
	},
	plotOptions: {
		bubble: {
			minBubbleRadius: 5,
			maxBubbleRadius: 50,
		},
	},
});

const chartSeries = computed(() => [
	{
		data: (props.series[0]?.data || []).map((item) => ({
			x: Number.parseFloat(item.x_axis ?? item.x ?? 0),
			y: Number.parseFloat(item.y_axis ?? item.y ?? 0),
			z: Number.parseFloat(item.z_axis ?? item.data ?? item.z ?? 10),
		})),
	},
]);
</script>

<template>
  <div
    v-if="activeChart === 'BubbleChart'"
    class="bubble-chart"
  >
    <VueApexCharts
      width="100%"
      height="250px"
      type="bubble"
      :options="chartOptions"
      :series="chartSeries"
    />
  </div>
</template>

<style scoped lang="scss">
.bubble-chart {
	min-height: 250px;
	width: 100%;
}
</style>
```

### 步驟 2：註冊圖表組件

修改 `Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue`。

加入 Vue 組件 import：

```js
import BubbleChart from "./components/BubbleChart.vue";
```

加入 SVG 預覽圖 import：

```js
import BubbleChartSvg from "./assets/chart/BubbleChart.svg";
```

在 `returnChartComponent` 中加入分支：

```js
case "BubbleChart":
	return svg ? BubbleChartSvg : BubbleChart;
```

### 步驟 3：加入圖表名稱

修改 `Taipei-City-Dashboard-FE/src/dashboardComponent/utilities/chartTypes.ts`：

```ts
BubbleChart: "氣泡圖",
```

若後台表單或其他頁面仍引用 `Taipei-City-Dashboard-FE/src/assets/configs/apexcharts/chartTypes.js`，也需要同步加入同名設定，避免不同入口顯示不一致。

### 步驟 4：建立 SVG 預覽圖

在 `Taipei-City-Dashboard-FE/src/dashboardComponent/assets/chart/` 新增：

```text
BubbleChart.svg
```

範例：

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 40 40">
  <rect x="0" y="0" width="40" height="40" fill="#282a2c" rx="5"/>
  <circle cx="12" cy="28" r="4" fill="#4CAF50" opacity="0.8"/>
  <circle cx="20" cy="20" r="6" fill="#2196F3" opacity="0.8"/>
  <circle cx="28" cy="12" r="8" fill="#FF9800" opacity="0.8"/>
</svg>
```

### 步驟 5：新增資料庫設定

新增資料庫設定時，`component_charts.types` 需包含新的圖表名稱：

```sql
INSERT INTO public.component_charts (index, color, types, unit)
VALUES (
    'bubble_demo',
    ARRAY['#4CAF50', '#2196F3', '#FF9800'],
    ARRAY['BubbleChart'],
    '單位'
);
```

查詢結果需能被新組件轉成 ApexCharts bubble series：

```sql
SELECT
    x_value AS x_axis,
    y_value AS y_axis,
    bubble_size AS z_axis
FROM public.some_table;
```

### 步驟 6：啟動與檢查前端

Web 相關指令使用 `pnpm`：

```bash
cd Taipei-City-Dashboard-FE
pnpm install
pnpm dev
```

若只修改文件，不需要啟動前端。若新增或修改 Vue 組件，請至少執行：

```bash
cd Taipei-City-Dashboard-FE
pnpm build
```

## 三、資料庫表格重點

### `components`

- `id`：組件 ID，需唯一。
- `index`：組件索引，會與其他表格關聯。
- `name`：組件顯示名稱。

### `component_charts`

- `index`：組件索引，對應 `components.index`。
- `color`：圖表色彩陣列。
- `types`：圖表類型陣列，例如 `ARRAY['ColumnChart']` 或 `ARRAY['BubbleChart']`。
- `unit`：數值單位。

### `query_charts`

- `index`：組件索引，對應 `components.index`。
- `query_chart`：圖表資料 SQL。
- `query_type`：查詢類型，例如 `two_d`、`three_d`、`time`、`percent`、`map_legend`。
- `city`：城市代碼，例如 `taipei`。
- `short_desc`：簡短描述。
- `long_desc`：詳細描述。
- `source`：資料來源。

### `dashboards`

- `index`：儀表板索引。
- `components`：組件 ID 陣列。

## 四、資料格式要求

### 通用格式

```sql
SELECT x_axis, y_axis, data
FROM table_name;
```

### 氣泡圖格式

```sql
SELECT x_axis, y_axis, z_axis
FROM table_name;
```

如果既有資料管線只支援 `data` 欄位，也可以在 `BubbleChart.vue` 中把 `data` 當成氣泡大小備援欄位。

## 五、測試技巧

### 檢查前端資料格式

開發新圖表時，可以暫時加入 log 檢查 props：

```js
console.log("series:", props.series);
console.log("chart_config:", props.chart_config);
```

確認後請移除 log，避免正式環境輸出過多除錯資訊。

### 檢查資料庫查詢

可以在資料庫中直接執行 `query_chart`，確認結果欄位與資料型別正確。

若使用 Docker 進入資料庫，請避免執行會輸出敏感環境變數的指令，例如 `docker compose config`。

```bash
docker exec -it postgres-manager psql -U postgres -d dashboardmanager
```

## 六、常見問題

### Q1：組件出現但顯示資料異常

檢查 SQL 是否能正常執行，以及回傳欄位是否符合組件預期。特別注意 `x_axis`、`y_axis`、`data`、`z_axis` 的命名與數值型別。

### Q2：Tooltip 被裁切

可以調整圖表容器高度、padding，或設定 ApexCharts tooltip 的 `followCursor: true`。

### Q3：圖表高度不夠

在組件根節點或圖表容器設定穩定高度，例如：

```scss
.bubble-chart {
	min-height: 250px;
}
```

### Q4：預覽模式沒有顯示新圖表圖示

確認 `DashboardComponent.vue` 已 import SVG，且 `returnChartComponent` 已加入新圖表名稱對應。

### Q5：切換圖表按鈕顯示空白或英文 key

確認 `Taipei-City-Dashboard-FE/src/dashboardComponent/utilities/chartTypes.ts` 已加入新圖表名稱。若後台或其他頁面使用 `src/assets/configs/apexcharts/chartTypes.js`，也要同步更新。

## 七、參考資源

- ApexCharts 文件：https://apexcharts.com/docs/
- Vue 3 文件：https://vuejs.org/
- 現有圖表組件：`Taipei-City-Dashboard-FE/src/dashboardComponent/components/`
- 圖表預覽 SVG：`Taipei-City-Dashboard-FE/src/dashboardComponent/assets/chart/`
- 圖表註冊入口：`Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue`

$(document).ready(() => {
    const CURRENT_CHART_BAR_CATEGORY = "chartBarCategory";
    const CURRENT_CHART_WATERMARK = "chartWatermark";

    loadCharts();
    function loadCharts() {
        let chart_data_complete = null;
        let CHART_BAR_CATEGORY = document.getElementById(CURRENT_CHART_BAR_CATEGORY);
        if (CHART_BAR_CATEGORY != null) {
            chart_data_complete = document.getElementById("bar_y_category_data");
        }
        if (chart_data_complete != null && chart_data_complete.value != null) {
            let chart_data_complete_json = JSON.parse(chart_data_complete.value);
            generateBarYCategory(CURRENT_CHART_BAR_CATEGORY, chart_data_complete_json);
        }

        let CHART_WATERMARK = document.getElementById(CURRENT_CHART_WATERMARK);
        if (CHART_WATERMARK != null) {
            let echart_values = JSON.parse($('#echart_values').val());
            generateWatermarkChart(CURRENT_CHART_WATERMARK, echart_values);
        }
    }

});
let myBarYCategoryChart;

function generateBarYCategory(chartDomId, chartData){
    const chartDom = document.getElementById(chartDomId);
    chartDom.style.width = '1200px'; // Set to desired width
    chartDom.style.height = '600px'; // Set to desired height
    if (myBarYCategoryChart != null && echarts.getInstanceByDom(chartDom)) {
        echarts.dispose(chartDom);
    }
    myBarYCategoryChart = echarts.init(chartDom);
    const option = {
        title: {
            text: 'Saldo incluído X Saldo consumido'
        },
        tooltip: {
            trigger: 'axis',
            axisPointer: {
                type: 'shadow'
            }
        },
        legend: {},
        grid: {
            left: '3%',
            right: '4%',
            bottom: '3%',
            containLabel: true
        },
        xAxis: {
            type: 'value',
            boundaryGap: [0, 0.01]
        },
        yAxis: {
            type: 'category',
            data: chartData.y_data
        },
        series: [
            {
                name: 'Incluído',
                type: 'bar',
                data: chartData.series_1_data
            },
            {
                name: 'Consumido',
                type: 'bar',
                data: chartData.series_2_data
            }
        ]
    };
    myBarYCategoryChart.setOption(option);
}

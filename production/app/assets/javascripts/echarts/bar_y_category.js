let myBarYCategoryChart;

function generateBarYCategory(chartDomId, chartData){
    const chartDom = document.getElementById(chartDomId);
    if (myBarYCategoryChart != null && echarts.getInstanceByDom(chartDom)) {
        echarts.dispose(chartDom);
    }

    // Altura dinâmica: mínimo 400px, ~30px por item
    var itemCount = chartData.y_data ? chartData.y_data.length : 10;
    var dynamicHeight = Math.max(400, itemCount * 32 + 80);
    chartDom.style.height = dynamicHeight + 'px';

    myBarYCategoryChart = echarts.init(chartDom);

    // Truncar nomes longos nos labels do eixo Y
    var truncatedLabels = (chartData.y_data || []).map(function(name) {
        return name && name.length > 35 ? name.substring(0, 35) + '...' : name;
    });

    const option = {
        title: {
            text: 'Saldo incluído X Saldo consumido'
        },
        tooltip: {
            trigger: 'axis',
            axisPointer: {
                type: 'shadow'
            },
            formatter: function(params) {
                var idx = params[0].dataIndex;
                var fullName = chartData.y_data[idx] || '';
                var result = fullName + '<br/>';
                params.forEach(function(p) {
                    result += p.marker + ' ' + p.seriesName + ': ' +
                              p.value.toLocaleString('pt-BR', {style: 'currency', currency: 'BRL'}) + '<br/>';
                });
                return result;
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
            boundaryGap: [0, 0.01],
            axisLabel: {
                formatter: function(val) {
                    if (val >= 1000000) return (val / 1000000).toFixed(1) + 'M';
                    if (val >= 1000) return (val / 1000).toFixed(0) + 'K';
                    return val;
                }
            }
        },
        yAxis: {
            type: 'category',
            data: truncatedLabels,
            axisLabel: {
                fontSize: 10,
                width: 200,
                overflow: 'truncate'
            }
        },
        series: [
            {
                name: 'Incluído',
                type: 'bar',
                data: chartData.series_1_data,
                barMaxWidth: 20
            },
            {
                name: 'Consumido',
                type: 'bar',
                data: chartData.series_2_data,
                barMaxWidth: 20
            }
        ]
    };
    myBarYCategoryChart.setOption(option);

    // Responsividade: redimensiona quando a janela ou o container mudarem.
    if (!chartDom.dataset.echartResizeBound) {
        chartDom.dataset.echartResizeBound = '1';

        window.addEventListener('resize', () => {
            if (myBarYCategoryChart) myBarYCategoryChart.resize();
        });

        if (typeof ResizeObserver !== 'undefined') {
            const ro = new ResizeObserver(() => {
                if (myBarYCategoryChart) myBarYCategoryChart.resize();
            });
            ro.observe(chartDom);
        }
    }
}

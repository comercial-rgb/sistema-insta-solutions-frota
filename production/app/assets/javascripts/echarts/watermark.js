let myBarChart, myFrotaChart, myConsumoChart, mySaldoChart;

function formatCurrency(value) {
    return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value);
}

function formatCurrencyShort(value) {
    if (value >= 1000000) {
        return 'R$ ' + (value / 1000000).toFixed(1) + 'M';
    } else if (value >= 1000) {
        return 'R$ ' + (value / 1000).toFixed(1) + 'k';
    }
    return formatCurrency(value);
}

function generateWatermarkChart(chartDomId, chartData) {
    const builderJson = chartData.builderJson;
    const downloadJson = chartData.downloadJson;
    const themeJson = chartData.themeJson;
    const typesJson = chartData.typesJson;

    // Gráficos separados para melhor visualização
    renderBarChart(builderJson);
    renderFrotaChart(downloadJson);
    renderConsumoChart(typesJson);
    renderSaldoChart(themeJson);
}

function renderBarChart(builderJson) {
    var chartDom = document.getElementById('chartBarras');
    if (!chartDom) return;

    if (myBarChart && echarts.getInstanceByDom(chartDom)) { echarts.dispose(chartDom); }

    // Combinar dados de approved (charts) e authorized (components) numa única visão empilhada
    var allCostCenters = new Set([
        ...Object.keys(builderJson.charts || {}),
        ...Object.keys(builderJson.components || {})
    ]);

    // Ordenar por valor total decrescente (ECharts bar horizontal: primeiro item = bottom)
    var sortedCenters = Array.from(allCostCenters).map(function(name) {
        return {
            name: name,
            approved: (builderJson.charts || {})[name] || 0,
            authorized: (builderJson.components || {})[name] || 0,
            total: ((builderJson.charts || {})[name] || 0) + ((builderJson.components || {})[name] || 0)
        };
    }).sort(function(a, b) { return a.total - b.total; });

    var centerNames = sortedCenters.map(function(c) { return c.name; });
    var approvedValues = sortedCenters.map(function(c) { return c.approved; });
    var authorizedValues = sortedCenters.map(function(c) { return c.authorized; });

    // Altura dinâmica: 35px por centro de custo, mínimo 300px, máximo 2000px
    var numBars = centerNames.length;
    var dynamicHeight = Math.max(300, Math.min(2000, numBars * 35 + 80));
    chartDom.style.height = dynamicHeight + 'px';

    // Info label
    var infoEl = document.getElementById('barChartInfo');
    if (infoEl) {
        infoEl.textContent = numBars + ' centros de custo';
    }

    myBarChart = echarts.init(chartDom);

    var option = {
        tooltip: {
            trigger: 'axis',
            axisPointer: { type: 'shadow' },
            formatter: function(params) {
                var tooltip = '<strong>' + params[0].name + '</strong><br/>';
                var total = 0;
                params.forEach(function(p) {
                    if (p.value > 0) {
                        tooltip += '<span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:' + p.color + ';margin-right:5px;"></span>';
                        tooltip += p.seriesName + ': ' + formatCurrency(p.value) + '<br/>';
                        total += p.value;
                    }
                });
                tooltip += '<strong>Total: ' + formatCurrency(total) + '</strong>';
                return tooltip;
            }
        },
        legend: {
            data: ['Aprovada', 'NF Inserida / Autorizada / Ag. Pagamento / Paga'],
            top: 5,
            textStyle: { fontSize: 11 }
        },
        grid: {
            left: 10,
            right: 120,
            top: 40,
            bottom: 10,
            containLabel: true
        },
        xAxis: {
            type: 'value',
            axisLabel: {
                formatter: function(val) { return formatCurrencyShort(val); },
                fontSize: 10
            },
            splitLine: { lineStyle: { type: 'dashed', color: '#f0f0f0' } }
        },
        yAxis: {
            type: 'category',
            data: centerNames,
            axisLabel: {
                interval: 0,
                fontSize: 10,
                width: 200,
                overflow: 'truncate',
                ellipsis: '...'
            },
            splitLine: { show: false }
        },
        series: [
            {
                name: 'Aprovada',
                type: 'bar',
                stack: 'total',
                barMaxWidth: 22,
                itemStyle: {
                    color: '#f0ad4e',
                    borderRadius: [0, 0, 0, 0]
                },
                label: { show: false },
                data: approvedValues
            },
            {
                name: 'NF Inserida / Autorizada / Ag. Pagamento / Paga',
                type: 'bar',
                stack: 'total',
                barMaxWidth: 22,
                itemStyle: {
                    color: '#5cb85c',
                    borderRadius: [0, 2, 2, 0]
                },
                label: {
                    show: true,
                    position: 'right',
                    fontSize: 9,
                    color: '#555',
                    formatter: function(params) {
                        var idx = params.dataIndex;
                        var total = approvedValues[idx] + authorizedValues[idx];
                        if (total === 0) return '';
                        return formatCurrencyShort(total);
                    }
                },
                data: authorizedValues
            }
        ]
    };

    myBarChart.setOption(option);
    setupResize(chartDom, myBarChart);
}

function renderFrotaChart(downloadJson) {
    var chartDom = document.getElementById('chartFrota');
    if (!chartDom) return;

    if (myFrotaChart && echarts.getInstanceByDom(chartDom)) { echarts.dispose(chartDom); }
    myFrotaChart = echarts.init(chartDom);

    var total = Object.keys(downloadJson).reduce(function(sum, key) { return sum + (downloadJson[key] || 0); }, 0);

    var option = {
        tooltip: {
            trigger: 'item',
            formatter: '{b}: {c} ({d}%)'
        },
        legend: {
            orient: 'horizontal',
            bottom: 5,
            textStyle: { fontSize: 11 }
        },
        series: [{
            type: 'pie',
            radius: ['35%', '65%'],
            center: ['50%', '45%'],
            name: 'Frota ativa/inativa',
            avoidLabelOverlap: true,
            itemStyle: {
                borderRadius: 4,
                borderColor: '#fff',
                borderWidth: 2
            },
            color: ['#34a853', '#d93025'],
            label: {
                show: true,
                formatter: '{b}\n{c} ({d}%)',
                fontSize: 11
            },
            labelLine: { show: true },
            data: Object.keys(downloadJson).map(function(key) {
                return { name: key, value: downloadJson[key] };
            })
        }],
        graphic: [{
            type: 'text',
            left: 'center',
            top: '42%',
            style: {
                text: 'Total: ' + total,
                textAlign: 'center',
                fontSize: 13,
                fontWeight: 'bold',
                fill: '#666'
            }
        }]
    };

    myFrotaChart.setOption(option);
    setupResize(chartDom, myFrotaChart);
}

function renderConsumoChart(typesJson) {
    var chartDom = document.getElementById('chartConsumo');
    if (!chartDom) return;

    if (myConsumoChart && echarts.getInstanceByDom(chartDom)) { echarts.dispose(chartDom); }
    myConsumoChart = echarts.init(chartDom);

    var total = Object.keys(typesJson).reduce(function(sum, key) { return sum + (typesJson[key] || 0); }, 0);

    var option = {
        tooltip: {
            trigger: 'item',
            formatter: function(params) {
                return params.name + ': ' + formatCurrency(params.value) + ' (' + params.percent + '%)';
            }
        },
        legend: {
            orient: 'horizontal',
            bottom: 5,
            textStyle: { fontSize: 11 }
        },
        series: [{
            type: 'pie',
            radius: ['35%', '65%'],
            center: ['50%', '42%'],
            name: 'Consumo peças/serviços',
            avoidLabelOverlap: true,
            itemStyle: {
                borderRadius: 4,
                borderColor: '#fff',
                borderWidth: 2
            },
            color: ['#3366cc', '#00acc1'],
            label: {
                show: true,
                formatter: function(params) {
                    return params.name + '\n' + formatCurrency(params.value);
                },
                fontSize: 10
            },
            labelLine: { show: true },
            data: Object.keys(typesJson).map(function(key) {
                return { name: key, value: typesJson[key] };
            })
        }],
        graphic: [{
            type: 'text',
            left: 'center',
            top: '38%',
            style: {
                text: 'Total',
                textAlign: 'center',
                fontSize: 11,
                fill: '#999'
            }
        }, {
            type: 'text',
            left: 'center',
            top: '44%',
            style: {
                text: formatCurrency(total),
                textAlign: 'center',
                fontSize: 12,
                fontWeight: 'bold',
                fill: '#333'
            }
        }]
    };

    myConsumoChart.setOption(option);
    setupResize(chartDom, myConsumoChart);
}

function renderSaldoChart(themeJson) {
    var chartDom = document.getElementById('chartSaldo');
    if (!chartDom) return;

    if (mySaldoChart && echarts.getInstanceByDom(chartDom)) { echarts.dispose(chartDom); }
    mySaldoChart = echarts.init(chartDom);

    var option = {
        tooltip: {
            trigger: 'item',
            formatter: function(params) {
                return params.name + ': ' + formatCurrency(params.value) + ' (' + params.percent + '%)';
            }
        },
        legend: {
            orient: 'horizontal',
            bottom: 0,
            textStyle: { fontSize: 10 },
            itemWidth: 12,
            itemGap: 8
        },
        series: [{
            type: 'pie',
            radius: ['30%', '60%'],
            center: ['50%', '40%'],
            name: 'Saldo do contrato',
            avoidLabelOverlap: true,
            itemStyle: {
                borderRadius: 4,
                borderColor: '#fff',
                borderWidth: 2
            },
            color: ['#3498db', '#e74c3c', '#2ecc71', '#f39c12'],
            label: {
                show: true,
                formatter: function(params) {
                    return formatCurrencyShort(params.value);
                },
                fontSize: 10
            },
            labelLine: { show: true, length: 10, length2: 8 },
            data: Object.keys(themeJson).map(function(key) {
                return { name: key, value: themeJson[key] };
            })
        }]
    };

    mySaldoChart.setOption(option);
    setupResize(chartDom, mySaldoChart);
}

function setupResize(dom, chart) {
    if (dom.dataset.echartResizeBound) return;
    dom.dataset.echartResizeBound = '1';

    window.addEventListener('resize', function() {
        if (chart) chart.resize();
    });

    if (typeof ResizeObserver !== 'undefined') {
        var ro = new ResizeObserver(function() {
            if (chart) chart.resize();
        });
        ro.observe(dom);
    }
}

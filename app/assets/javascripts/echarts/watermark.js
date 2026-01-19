let myWatermarkChart;

function generateWatermarkChart(chartDomId, chartData){
    const chartDom = document.getElementById(chartDomId);
    chartDom.style.width = '1300px'; // Set to desired width
    chartDom.style.height = '600px'; // Set to desired height
    if (myWatermarkChart != null && echarts.getInstanceByDom(chartDom)) {
        echarts.dispose(chartDom);
    }
    myWatermarkChart = echarts.init(chartDom);
    console.log('Dashboard Data:', chartData);
    const builderJson = chartData.builderJson;
    const downloadJson = chartData.downloadJson;
    const themeJson = chartData.themeJson;
    const typesJson = chartData.typesJson;
    console.log('downloadJson (Frota):', downloadJson);
    console.log('themeJson (Saldo):', themeJson);
    // const waterMarkText = 'InstaSolutions';
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    canvas.width = canvas.height = 100;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.globalAlpha = 0.08;
    ctx.font = '20px Microsoft Yahei';
    ctx.translate(50, 50);
    ctx.rotate(-Math.PI / 4);
    // ctx.fillText(waterMarkText, 0, 0);
    let option = {
        backgroundColor: {
            type: 'pattern',
            image: canvas,
            repeat: 'repeat'
        },
        tooltip: {
            trigger: 'item',
            formatter: function(params) {
                const isPie = params.seriesType === 'pie';
                if (isPie) {
                    // Moeda para consumo/saldo; número absoluto para frota
                    if (params.seriesName === 'Frota ativa/inativa') {
                        return `${params.name}: ${params.value}`;
                    }
                    return `${params.name}: ${new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(params.value)}`;
                }
                // Barras
                return `${params.name}: ${new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(params.value)}`;
            }
        },
        title: [
            {
                text: 'Valores consumidos (Aprovados e Autorizados)',
                left: '25%',
                textAlign: 'center'
            },
            {
                text: 'Frota ativa/inativa',
                subtext: 'Total: ' +
                    Object.keys(downloadJson).reduce(function (all, key) {
                    return all + (downloadJson[key] || 0);
                    }, 0),
                left: '65%',
                textAlign: 'center'
            },
            {
                text: 'Saldo do contrato (contrato do cliente)',
                left: '75%',
                top: '50%',
                textAlign: 'center'
            },
            {
                text: 'Consumo peças/serviços',
                subtext: 'Total: ' +
                    new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(
                        Object.keys(typesJson).reduce(function (all, key) {
                            return all + (typesJson[key] || 0);
                        }, 0)
                    ),
                left: '85%',
                textAlign: 'center'
            }
        ],
        grid: [
            {
                top: 50,
                width: '50%',
                bottom: '45%',
                left: 10,
                containLabel: true
            },
            {
                top: '55%',
                width: '50%',
                bottom: 0,
                left: 10,
                containLabel: true
            }
        ],
        xAxis: [
            {
                type: 'value',
                max: builderJson.all,
                splitLine: {
                    show: false
                }
            },
            {
                type: 'value',
                max: builderJson.all,
                gridIndex: 1,
                splitLine: {
                    show: false
                }
            }
        ],
        yAxis: [
            {
                type: 'category',
                data: Object.keys(builderJson.charts),
                axisLabel: {
                    interval: 0,
                    rotate: 30
                },
                splitLine: {
                    show: false
                }
            },
            {
                gridIndex: 1,
                type: 'category',
                data: Object.keys(builderJson.components),
                axisLabel: {
                    interval: 0,
                    rotate: 30
                },
                splitLine: {
                    show: false
                }
            }
        ],
        series: [
            {
                type: 'bar',
                stack: 'chart',
                z: 3,
                label: {
                    position: 'right',
                    show: true
                },
                data: Object.keys(builderJson.charts).map(function (key) {
                    return {
                        value: builderJson.charts[key],
                        name: key,
                        label: {
                            formatter: function (params) {
                                return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(params.value);
                            }
                        }
                    };
                })
            },
            {
                type: 'bar',
                stack: 'chart',
                silent: true,
                itemStyle: {
                    color: '#eee'
                },
                data: Object.keys(builderJson.charts).map(function (key) {
                    return {
                        value: (builderJson.all - builderJson.charts[key]),
                        name: key,
                        label: {
                            formatter: function (params) {
                                return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(params.value);
                            }
                        }
                    };
                })
            },
            {
                type: 'bar',
                stack: 'component',
                xAxisIndex: 1,
                yAxisIndex: 1,
                z: 3,
                label: {
                    position: 'right',
                    show: true
                },
                data: Object.keys(builderJson.components).map(function (key) {
                    return {
                        value: builderJson.components[key],
                        name: key,
                        label: {
                            formatter: function (params) {
                                return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(params.value);
                            }
                        }
                    };
                })
            },
            {
                type: 'bar',
                stack: 'component',
                silent: true,
                xAxisIndex: 1,
                yAxisIndex: 1,
                itemStyle: {
                    color: '#eee'
                },
                data: Object.keys(builderJson.components).map(function (key) {
                    return {
                        value: builderJson.all - builderJson.components[key],
                        name: key,
                        label: {
                            formatter: function (params) {
                                return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(params.value);
                            }
                        }
                    };
                })
            },
            {
                type: 'pie',
                radius: [0, '30%'],
                center: ['65%', '25%'],
                name: 'Frota ativa/inativa',
                color: ['#34a853', '#d93025'],
                data: Object.keys(downloadJson).map(function (key) {
                    return {
                        name: key,
                        value: downloadJson[key]
                    };
                })
            },
            {
                type: 'pie',
                radius: [0, '30%'],
                center: ['75%', '75%'],
                name: 'Saldo do contrato',
                color: ['#f2c94c', '#f2994a', '#f6e27f'], // tons de amarelo/laranja
                data: Object.keys(themeJson).map(function (key) {
                    return {
                        name: key,
                        value: themeJson[key],
                        label: {
                            formatter: function (params) {
                                return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(params.value);
                            }
                        }
                    };
                })
            },
            {
                type: 'pie',
                radius: [0, '30%'],
                center: ['85%', '25%'],
                name: 'Consumo peças/serviços',
                color: ['#3366cc', '#00acc1'],
                label: {
                    position: 'inside',
                    formatter: function (params) {
                        return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(params.value);
                    },
                    fontSize: 10
                },
                data: Object.keys(typesJson).map(function (key) {
                    return {
                        name: key,
                        value: typesJson[key]
                    };
                })
            }
        ]
    };
    myWatermarkChart.setOption(option);
}

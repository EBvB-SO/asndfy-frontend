//
//  RadarChartWrapper.swift
//  Ascendify
//
//  Created by Ellis Barker on 12/08/2025.
//

import SwiftUI
import UIKit
import DGCharts

struct RadarChartConfig {
    let axes: [String]      // EXACT order of axis labels
    let initial: [Double]   // normalized 0...1
    let current: [Double]   // normalized 0...1
}

struct RadarChartViewSwiftUI: UIViewRepresentable {
    let config: RadarChartConfig

    func makeUIView(context: Context) -> RadarChartView {
        let chart = RadarChartView()

        // Layout/appearance
        chart.backgroundColor = .clear
        chart.rotationEnabled = false
        chart.noDataText = "No ability data"
        chart.chartDescription.enabled = false

        // Use as much vertical space as possible
        chart.minOffset = 0
        chart.setExtraOffsets(left: 0, top: -40, right: 0, bottom: -40)

        // Disable native legend (we'll draw our own below the chart)
        chart.legend.enabled = false

        // Web / grid
        chart.webLineWidth = 1.0
        chart.innerWebLineWidth = 0.8
        chart.webColor = UIColor.systemGray3
        chart.innerWebColor = UIColor.systemGray4.withAlphaComponent(0.7)
        chart.webAlpha = 1

        // X axis labels around the web
        chart.xAxis.labelFont = UIFont.systemFont(ofSize: 11) // Slightly smaller to reduce padding
        chart.xAxis.labelTextColor = UIColor.label

        // Y axis 0...1, hide labels
        chart.yAxis.axisMinimum = 0.0
        chart.yAxis.axisMaximum = 1.0
        chart.yAxis.labelCount = 5
        chart.yAxis.drawLabelsEnabled = false
        chart.yAxis.axisLineColor = .clear
        chart.yAxis.gridColor = UIColor.systemGray4
        chart.yAxis.gridAntialiasEnabled = true

        chart.animate(yAxisDuration: 0.35)
        return chart
    }

    func updateUIView(_ chart: RadarChartView, context: Context) {
        guard config.axes.count == config.initial.count,
              config.axes.count == config.current.count,
              !config.axes.isEmpty else {
            chart.data = nil
            return
        }

        // Data sets
        let initialEntries = config.initial.map { RadarChartDataEntry(value: $0) }
        let currentEntries = config.current.map { RadarChartDataEntry(value: $0) }

        let dsInitial = RadarChartDataSet(entries: initialEntries, label: "Initial")
        dsInitial.setColor(UIColor.systemGray)
        dsInitial.fillColor = UIColor.systemGray
        dsInitial.drawFilledEnabled = true
        dsInitial.fillAlpha = 0.22
        dsInitial.lineWidth = 1.6
        dsInitial.drawValuesEnabled = false

        let dsCurrent = RadarChartDataSet(entries: currentEntries, label: "Current")
        dsCurrent.setColor(UIColor.systemTeal)
        dsCurrent.fillColor = UIColor.systemTeal
        dsCurrent.drawFilledEnabled = true
        dsCurrent.fillAlpha = 0.35
        dsCurrent.lineWidth = 2.4
        dsCurrent.drawValuesEnabled = false

        let data = RadarChartData(dataSets: [dsInitial, dsCurrent])
        data.setDrawValues(false)

        chart.data = data
        chart.xAxis.valueFormatter = IndexAxisValueFormatter(values: config.axes)
        chart.notifyDataSetChanged()
    }
}

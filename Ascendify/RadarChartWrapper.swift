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

        // Appearance
        chart.backgroundColor = .clear
        chart.rotationEnabled = false
        chart.noDataText = "No ability data"

        // Legend
        chart.legend.enabled = true
        chart.legend.horizontalAlignment = .center
        chart.legend.verticalAlignment = .bottom
        chart.legend.orientation = .horizontal
        chart.legend.drawInside = false
        chart.legend.form = .square
        chart.legend.formSize = 8
        chart.legend.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        chart.legend.textColor = UIColor.label // use Brand color if you have UIColor

        // Web / grid
        chart.webLineWidth = 0.8
        chart.innerWebLineWidth = 0.6
        chart.webColor = UIColor.systemGray4
        chart.innerWebColor = UIColor.systemGray4.withAlphaComponent(0.5)
        chart.webAlpha = 1

        // X axis (category labels around the web)
        chart.xAxis.labelFont = UIFont.systemFont(ofSize: 12)
        chart.xAxis.labelTextColor = UIColor.label

        // Y axis (radius) — lock to 0...1 and hide labels
        chart.yAxis.axisMinimum = 0.0
        chart.yAxis.axisMaximum = 1.0
        chart.yAxis.labelCount = 6
        chart.yAxis.drawLabelsEnabled = false
        chart.yAxis.axisLineColor = .clear
        chart.yAxis.gridColor = UIColor.systemGray4
        chart.yAxis.gridAntialiasEnabled = true

        chart.animate(yAxisDuration: 0.35)

        return chart
    }

    func updateUIView(_ chart: RadarChartView, context: Context) {
        // Validate lengths to avoid crashes / weird plots
        guard config.axes.count == config.initial.count,
              config.axes.count == config.current.count,
              !config.axes.isEmpty else {
            chart.data = nil
            return
        }

        // Entries
        let initialEntries = config.initial.map { RadarChartDataEntry(value: $0) }
        let currentEntries = config.current.map { RadarChartDataEntry(value: $0) }

        // Initial dataset (grey)
        let dsInitial = RadarChartDataSet(entries: initialEntries, label: "Initial")
        dsInitial.setColor(UIColor.systemGray)
        dsInitial.fillColor = UIColor.systemGray
        dsInitial.drawFilledEnabled = true
        dsInitial.fillAlpha = 0.18
        dsInitial.lineWidth = 1.2
        dsInitial.drawValuesEnabled = false
        dsInitial.drawHighlightCircleEnabled = false

        // Current dataset (teal)
        let dsCurrent = RadarChartDataSet(entries: currentEntries, label: "Current")
        dsCurrent.setColor(UIColor.systemTeal)
        dsCurrent.fillColor = UIColor.systemTeal
        dsCurrent.drawFilledEnabled = true
        dsCurrent.fillAlpha = 0.28
        dsCurrent.lineWidth = 2.0
        dsCurrent.drawValuesEnabled = false
        dsCurrent.drawHighlightCircleEnabled = false

        // Data
        let data = RadarChartData(dataSets: [dsInitial, dsCurrent])
        data.setDrawValues(false) // no numbers at vertices
        chart.data = data

        // Axis labels order
        chart.xAxis.valueFormatter = IndexAxisValueFormatter(values: config.axes)

        chart.notifyDataSetChanged()
    }
}

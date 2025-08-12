//
//  LineChartWrapper.swift
//  Ascendify
//
//  Created by Ellis Barker on 12/08/2025.
//

import SwiftUI
import UIKit
import DGCharts

struct LineChartConfig {
    let completionRates: [Double]   // 0..100
    let completedSessions: [Double] // counts
    let xLabels: [String]           // Week 1..8
}

struct LineChartViewSwiftUI: UIViewRepresentable {
    let config: LineChartConfig

    func makeUIView(context: Context) -> LineChartView {
        let chart = LineChartView()
        chart.noDataText = "No sessions yet"
        chart.rightAxis.enabled = false
        chart.legend.enabled = true
        chart.legend.textColor = Brand.slate
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.drawGridLinesEnabled = false
        chart.xAxis.labelTextColor = Brand.slate
        chart.leftAxis.axisMinimum = 0
        chart.leftAxis.labelTextColor = Brand.slate
        chart.leftAxis.gridColor = Brand.grid
        chart.animate(xAxisDuration: 0.4, yAxisDuration: 0.4)
        return chart
    }

    func updateUIView(_ chart: LineChartView, context: Context) {
        // datasets
        let rateEntries = config.completionRates.enumerated().map { ChartDataEntry(x: Double($0.offset), y: $0.element) }
        let doneEntries = config.completedSessions.enumerated().map { ChartDataEntry(x: Double($0.offset), y: $0.element) }

        let rateSet = LineChartDataSet(entries: rateEntries, label: "Completion Rate %")
        rateSet.mode = .cubicBezier
        rateSet.lineWidth = 2.5
        rateSet.setColor(Brand.teal)
        rateSet.circleRadius = 3.5
        rateSet.setCircleColor(Brand.tealDark)
        rateSet.drawFilledEnabled = true
        rateSet.fillAlpha = 0.18
        rateSet.fillColor = Brand.teal
        rateSet.valueFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        rateSet.valueTextColor = Brand.slate

        let doneSet = LineChartDataSet(entries: doneEntries, label: "Completed Sessions")
        doneSet.mode = .linear
        doneSet.lineWidth = 1.8
        doneSet.setColor(Brand.slate.withAlphaComponent(0.55))
        doneSet.circleRadius = 3
        doneSet.setCircleColor(Brand.slate.withAlphaComponent(0.8))
        doneSet.drawFilledEnabled = false
        doneSet.valueFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        doneSet.valueTextColor = Brand.slate

        let data = LineChartData(dataSets: [rateSet, doneSet])
        data.setDrawValues(false) // hide value labels on points
        chart.data = data

        // x-axis labels
        chart.xAxis.valueFormatter = IndexAxisValueFormatter(values: config.xLabels)
        chart.xAxis.granularity = 1

        chart.notifyDataSetChanged()
    }
}

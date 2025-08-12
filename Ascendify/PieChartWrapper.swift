//
//  PieChartWrapper.swift
//  Ascendify
//
//  Created by Ellis Barker on 12/08/2025.
//

import SwiftUI
import DGCharts
import UIKit

struct PieSlice {
    let label: String
    let value: Double
}

struct PieChartConfig {
    let slices: [PieSlice]
}

struct PieChartViewSwiftUI: UIViewRepresentable {
    let config: PieChartConfig

    func makeUIView(context: Context) -> PieChartView {
        let chart = PieChartView()
        chart.usePercentValuesEnabled = true
        chart.drawEntryLabelsEnabled = false
        chart.legend.enabled = true
        chart.holeRadiusPercent = 0.48 // Donut
        chart.transparentCircleRadiusPercent = 0.54
        chart.animate(yAxisDuration: 0.4)
        return chart
    }

    func updateUIView(_ chart: PieChartView, context: Context) {
        let entries = config.slices.map { PieChartDataEntry(value: $0.value, label: $0.label) }

        // was: label: nil
        let set = PieChartDataSet(entries: entries, label: "")   // empty string is fine
        set.sliceSpace = 1

        // Brand palette
        set.colors = [
            Brand.teal, Brand.tealDark, Brand.tealLight,
            UIColor.systemTeal, UIColor.systemMint, UIColor.systemCyan,
            UIColor.systemGray2, UIColor.systemGray3
        ]

        let data = PieChartData(dataSet: set)
        let nf = NumberFormatter()
        nf.numberStyle = .percent
        nf.maximumFractionDigits = 0
        nf.multiplier = 1

        data.setValueFormatter(DefaultValueFormatter(formatter: nf))

        // was: .white / .systemFont(..., .semibold)
        data.setValueTextColor(UIColor.white)
        data.setValueFont(UIFont.systemFont(ofSize: 12, weight: .semibold))

        chart.data = data
        chart.centerText = "Exercises"
        chart.legend.textColor = Brand.slate
        chart.notifyDataSetChanged()
    }
}

//
//  TestDetailView.swift
//  Ascendify
//
//  Created by Ellis Barker on 13/08/2025.
//

import SwiftUI
import Charts

// MARK: - Shared spacing constants
private enum Metrics {
    static let cardPadding: CGFloat = 16
    static let cardCorner: CGFloat  = 14
    static let cardSpacing: CGFloat = 12
}

// MARK: - Reusable UI atoms

private struct SummaryTile: View {
    let title: String
    let value: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2).fontWeight(.heavy)
            if !subtitle.isEmpty {
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - View

struct TestDetailView: View {
    let test: TestDefinition
    @Environment(\.dismiss) private var dismiss
    @State private var showRunner = false
    @State private var showLog = false
    @EnvironmentObject var userViewModel: UserViewModel
    @ObservedObject private var testsVM = TestsViewModel.shared

    // Derived
    private var results: [TestResult] { testsVM.resultsByTest[test.id] ?? [] }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // MARK: Header
                    ZStack(alignment: .bottomLeading) {
                        BrandGradients.header
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        VStack(alignment: .leading, spacing: 8) {
                            Text(content.title ?? test.name)
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundStyle(.white)
                                .shadow(radius: 2)

                            HStack(spacing: 8) {
                                Pill(text: results.isEmpty ? "No results" : "\(results.count) results")
                                if let unit = test.unit, !unit.isEmpty { Pill(text: unit) }
                            }
                        }
                        .padding(16)
                    }

                    // MARK: Summary
                    if !results.isEmpty {
                        Card {
                            SectionLabel(text: "Summary")
                            HStack(spacing: 12) {
                                SummaryTile(
                                    title: "Best",
                                    value: formattedBest(results),
                                    subtitle: test.unit ?? ""
                                )
                                SummaryTile(
                                    title: "Latest",
                                    value: formattedLatest(results),
                                    subtitle: results.last?.dateString ?? ""
                                )
                                SummaryTile(
                                    title: "Trend",
                                    value: trendString(results),
                                    subtitle: "30d"
                                )
                            }
                        }
                    }

                    // MARK: Purpose & Setup
                    if let purpose = content.purpose {
                        Card {
                            SectionLabel(text: "Purpose")
                            Text(purpose)
                        }
                    }

                    if let equipment = content.equipment {
                        Card {
                            SectionLabel(text: "Equipment & Setup")
                            Text(equipment)
                        }
                    }

                    if let standardize = content.standardize, !standardize.isEmpty {
                        Card {
                            SectionLabel(text: "Standardize before each attempt")
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(standardize, id: \.self) { BulletRow(text: $0) }
                            }
                        }
                    }

                    if let warmup = content.warmup {
                        Card {
                            SectionLabel(text: "Warm-up (5–10 min)")
                            Text(warmup)
                        }
                    }

                    if let proto = content.`protocol`, !proto.isEmpty {
                        Card {
                            SectionLabel(text: "Protocol")
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(proto, id: \.self) { BulletRow(text: $0) }
                            }
                        }
                    }

                    if let recording = content.recording, !recording.isEmpty {
                        Card {
                            SectionLabel(text: "How to record")
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(recording, id: \.self) { BulletRow(text: $0) }
                            }
                        }
                    }

                    if let safety = content.safety, !safety.isEmpty {
                        Card {
                            SectionLabel(text: "Safety")
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(safety, id: \.self) { BulletRow(text: $0) }
                            }
                        }
                    }

                    // MARK: Results
                    Card {
                        SectionLabel(text: "Results")
                        if results.isEmpty {
                            HStack(spacing: 10) {
                                Image(systemName: "chart.xyaxis.line")
                                Text("No results yet. Start the test or log one manually.")
                            }
                            .foregroundStyle(.secondary)
                        } else {
                            ForEach(results) { r in
                                HStack {
                                    Text(r.dateString).foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(r.value, specifier: "%.1f") \(test.unit ?? "")")
                                        .fontWeight(.semibold)
                                }
                                .padding(.vertical, 4)

                                if r.id != results.last?.id { Divider() }
                            }
                        }
                    }

                    // MARK: Chart
                    if results.count >= 2 {
                        Card {
                            SectionLabel(text: "Progress")
                            Chart(results) {
                                LineMark(
                                    x: .value("Date", $0.date),
                                    y: .value("Value", $0.value)
                                )
                                PointMark(
                                    x: .value("Date", $0.date),
                                    y: .value("Value", $0.value)
                                )
                            }
                            .frame(height: 200)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { bottomActionBar }
            .sheet(isPresented: $showRunner) {
                TestRunnerView(
                    kind: content.kind,
                    title: content.title ?? test.name,
                    onFinished: {
                        showRunner = false
                        showLog = true
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showLog) {
                LogResultSheet(test: test, onSaved: { refresh() })
                    .environmentObject(userViewModel)
                    .presentationDetents([.medium, .large])
            }
            .refreshable { refresh() }   // pull to refresh
            .onAppear { refresh() }      // load on open
        }
    }
}

// MARK: - Bottom bar

private extension TestDetailView {
    var bottomActionBar: some View {
        HStack(spacing: 12) {
            Button {
                showRunner = true
            } label: {
                Text("Start Test")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.teal)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button {
                showLog = true
            } label: {
                Text("Log Result")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.tertiarySystemFill))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Formatting + refresh helpers

private extension TestDetailView {
    func refresh() {
        Task {
            if let email = userViewModel.userProfile?.email,
               let token = userViewModel.accessToken, !token.isEmpty {
                try? await testsVM.refreshResults(for: test, userEmail: email, token: token)
            }
        }
    }

    func formattedBest(_ results: [TestResult]) -> String {
        guard let best = results.map({ $0.value }).max() else { return "—" }
        return String(format: "%.1f", best)
    }

    func formattedLatest(_ results: [TestResult]) -> String {
        guard let latest = results.last?.value else { return "—" }
        return String(format: "%.1f", latest)
    }

    func trendString(_ results: [TestResult]) -> String {
        guard results.count >= 2 else { return "—" }
        let first = results.first!.value
        let last  = results.last!.value
        if last > first { return "up" }
        if last < first { return "down" }
        return "flat"
    }
}

// MARK: - Detailed content mapping (unchanged logic)

private struct DetailedContent {
    var title: String?
    var purpose: String?
    var equipment: String?
    var standardize: [String]?
    var warmup: String?
    var `protocol`: [String]?
    var recording: [String]?
    var safety: [String]?
    var kind: TestProtocolKind = .twoArmMaxHang7s
}

private extension TestDetailView {
    var content: DetailedContent {
        let n = test.name.lowercased()

        if n.contains("half crimp") {
            return DetailedContent(
                title: "Finger Strength Test — Half Crimp (two-arm)",
                purpose: "Estimate max finger force in a strict half-crimp (fingers at ~90°, no thumb over the top).",
                equipment: """
Hangboard edge (e.g. 20 mm), timer, harness + weight belt or pulley for assistance.
Stand on a box so you can load gradually, then lift feet.
""",
                standardize: [
                    "Half-crimp only; no thumb wrap.",
                    "Elbows extended or softly bent (150–180°).",
                    "No kipping or stepping; still body."
                ],
                warmup: "Easy hangs, progressive loading (e.g., 3–4 sub-max 5–7 s hangs with 90–120 s rest).",
                protocol: [
                    "Start around bodyweight if that’s comfortable, otherwise use assistance.",
                    "Increase load in small steps (1–5 kg).",
                    "For each attempt, hang 7 seconds. Stop if the grip opens or the elbow angle changes.",
                    "Rest 2 minutes between attempts.",
                    "Continue until you fail to hold a full 7 s. Your score is the heaviest successful 7-second hang in the same grip."
                ],
                recording: [
                    "Total load (kg) = bodyweight ± added/assisted.",
                    "% bodyweight = Total load / bodyweight × 100.",
                    "Log total load as the numeric value; add notes like “+22.5 kg” or “−10 kg assist”."
                ],
                safety: [
                    "Increase in small increments; if fingers start to open, lower immediately.",
                    "Stop with any sharp pain.",
                    "Avoid hard crimping; do not lock at 90°."
                ],
                kind: .twoArmMaxHang7s
            )
        }

        if n.contains("open grip") {
            return DetailedContent(
                title: "Open Grip Test — Four Fingers (two-arm)",
                purpose: "Assess open-hand strength with all four fingertips in contact (not three-finger drag).",
                equipment: "Hangboard edge, timer, harness/weights or assistance pulley.",
                standardize: [
                    "Open hand only; don’t drift into crimp.",
                    "Elbows 150–180°, still body."
                ],
                warmup: "5–10 min progressive hangs.",
                protocol: [
                    "Increase load in 1–5 kg steps.",
                    "Hang 7 s; rest 2 min.",
                    "Stop if grip changes."
                ],
                recording: [
                    "Total load (kg) = bodyweight ± added/assisted.",
                    "Optionally record % bodyweight."
                ],
                safety: [
                    "Respect any pain; reduce load.",
                    "Use small increments."
                ],
                kind: .twoArmMaxHang7s
            )
        }

        if n.contains("front-3") || n.contains("front 3") {
            return DetailedContent(
                title: "Front-3 Open Drag Test (two-arm)",
                purpose: "Assess strength using index–middle–ring in open drag.",
                equipment: "Hangboard, timer, harness/weights or pulley.",
                standardize: [
                    "Only front-3; all three stay on the edge.",
                    "Elbows 150–180°, body still."
                ],
                warmup: "5–10 min progressive hangs.",
                protocol: [
                    "Use smaller steps (1–2 kg).",
                    "Hang 7 s; rest 2 min.",
                    "Abort if any finger loses contact."
                ],
                recording: ["Record heaviest 7-second total load (kg)."],
                safety: ["Stop on pain or finger slip."],
                kind: .twoArmMaxHang7s
            )
        }

        if n.contains("one arm") || n.contains("one-arm") {
            return DetailedContent(
                title: "Finger Strength Test — One Arm",
                purpose: "Estimate one-arm finger force over a 10-second hang.",
                equipment: "Hangboard, timer, assistance pulley or added weight as needed.",
                standardize: [
                    "Half-crimp or open hand, consistent grip.",
                    "Shoulder engaged; elbow 90–180°."
                ],
                warmup: "5–10 min progressive hangs.",
                protocol: [
                    "Use assistance if needed to be sub-bodyweight.",
                    "Adjust in 1–2 kg steps; rest 2–3 min.",
                    "Hang 10 s per side.",
                    "After the first arm, rest ~30 s, then test the other arm."
                ],
                recording: [
                    "Total load (kg) = bodyweight ± added/assisted.",
                    "Record best total load; note L/R values."
                ],
                safety: [
                    "Maintain shoulder engagement.",
                    "Stop if grip or elbow angle breaks; avoid pain."
                ],
                kind: .oneArmMaxHang10s
            )
        }

        if n.contains("lactate curve") {
            return DetailedContent(
                title: "Lactate Curve Test — 7:3",
                purpose: "Assess local endurance via continuous 7 s on / 3 s off to failure, then 7 follow-up sets.",
                equipment: "Hangboard and timer.",
                standardize: ["Same edge, grip and elbow angle each time (150–180°)."],
                warmup: "5–10 min progressive hangs.",
                protocol: [
                    "Max bout: 7 s hang, 3 s rest to failure — record total time (s).",
                    "Then complete 7 additional 7:3 sets to failure, resting the same time as your last achieved total before each set."
                ],
                recording: [
                    "Record max-bout total time (s).",
                    "Put the seven follow-up set times in notes (comma-separated)."
                ],
                safety: ["Stop on pain; stay out of hard crimp. No locking at 90°."],
                kind: .sevenThreeRepeats
            )
        }

        if n.contains("max moves") {
            return DetailedContent(
                title: "Max Moves — Foot-On Campus",
                purpose: "Measure power-endurance using a campus board with foot support.",
                equipment: "Campus board with foot rungs; timer.",
                standardize: [
                    "Use the same rung sizes and foot support.",
                    "Keep a steady tempo and consistent body position."
                ],
                warmup: "Mobility + easy laddering.",
                protocol: [
                    "Repeat the hand sequence 1–2–3–2–1 at steady pace to failure.",
                    "Record total time (s)."
                ],
                recording: ["Log total time (s). Note rung sizes/settings."],
                safety: ["Stop on form break or elbow pain."],
                kind: .timeToFailure
            )
        }

        if n.contains("power endurance") {
            return DetailedContent(
                title: "Power Endurance — 75% (7:3)",
                purpose: "Assess endurance at 75% of your two-arm max-hang TOTAL load.",
                equipment: "Hangboard, timer, pulley/weights.",
                standardize: ["Same edge, grip and elbow angle as your max-hang baseline."],
                warmup: "5–10 min progressive hangs.",
                protocol: [
                    "Compute 75% of TOTAL load from your two-arm max hang.",
                    "Perform 7 s on / 3 s off to failure; record total time (s)."
                ],
                recording: [
                    "Log total time (s).",
                    "Put the load adjustment (assist or add) in notes."
                ],
                safety: ["Stop if grip opens, angle changes, or pain."],
                kind: .sevenThreeRepeats
            )
        }

        if n.contains("weighted pull") {
            return DetailedContent(
                title: "Weighted Pull-Up — 2RM",
                purpose: "Find the heaviest load for two strict pull-ups.",
                equipment: "Pull-up bar, dipping belt/harness, plates or assistance pulley.",
                standardize: ["Full range of motion; no kipping.", "Same grip width each session."],
                warmup: "General upper-body warm-up then sub-max sets.",
                protocol: [
                    "Increase weight in 2.5–5 kg steps.",
                    "2 reps per set; rest 3 min.",
                    "Max score = heaviest load with 2 clean reps."
                ],
                recording: [
                    "Log added weight (kg).",
                    "Use negative value for assistance if applicable."
                ],
                safety: ["Stop on shoulder or elbow pain; keep form strict."],
                kind: .twoRepMaxPullup
            )
        }

        // Fallback: API text
        return DetailedContent(
            title: test.name,
            purpose: test.description,
            equipment: nil,
            standardize: nil,
            warmup: nil,
            protocol: nil,
            recording: nil,
            safety: nil,
            kind: .twoArmMaxHang7s
        )
    }
}

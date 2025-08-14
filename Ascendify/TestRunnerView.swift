//
//  TestRunnerView.swift
//  Ascendify
//

import SwiftUI

struct TestRunnerView: View {
    let kind: TestProtocolKind
    let title: String
    var onFinished: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var countdown = 3
    @State private var phase: Phase = .countdown
    @State private var secondsRemaining = 7
    @State private var secondsElapsed = 0
    @State private var timer: Timer?

    enum Phase { case countdown, running, done }

    var body: some View {
        VStack(spacing: 18) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(Brand.slate))
                .padding(.top)

            Spacer()

            Group {
                switch phase {
                case .countdown:
                    Text("\(countdown)")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                case .running:
                    if kind == .twoArmMaxHang7s || kind == .oneArmMaxHang10s {
                        Text("\(secondsRemaining)")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundColor(.teal)
                            .monospacedDigit()
                    } else {
                        Text("\(secondsElapsed)s")
                            .font(.system(size: 54, weight: .bold))
                            .foregroundColor(.teal)
                            .monospacedDigit()
                    }
                case .done:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 72))
                        .foregroundColor(.green)
                    Text("Done").font(.title2).bold()
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Button(role: .destructive) {
                    stopTimer()
                    dismiss()
                } label: {
                    Text("Close")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.tertiarySystemFill))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if phase == .done {
                    Button {
                        if let onFinished { onFinished() } else { dismiss() }
                    } label: {
                        Text("Log Result")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.teal)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                } else {
                    Button {
                        start()
                    } label: {
                        Text(phase == .countdown ? "Start" : "Restart")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.teal)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .onDisappear { stopTimer() }
        .onAppear {
            if kind == .oneArmMaxHang10s { secondsRemaining = 10 }
        }
    }

    private func start() {
        stopTimer()
        phase = .countdown
        countdown = 3
        secondsElapsed = 0
        secondsRemaining = (kind == .oneArmMaxHang10s) ? 10 : 7

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            switch phase {
            case .countdown:
                if countdown > 1 { countdown -= 1 } else { phase = .running }
            case .running:
                if kind == .twoArmMaxHang7s || kind == .oneArmMaxHang10s {
                    if secondsRemaining > 1 { secondsRemaining -= 1 }
                    else { phase = .done; stopTimer() }
                } else {
                    secondsElapsed += 1
                }
            case .done:
                stopTimer()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

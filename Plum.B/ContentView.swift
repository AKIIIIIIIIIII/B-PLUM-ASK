//
//  ContentView.swift
//  Plum.B
//
//  Created by aki on 2026/4/10.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DivinationViewModel()
    @State private var isReadyPulseActive = false

    private var isInputReady: Bool {
        [viewModel.n1Text, viewModel.n2Text, viewModel.n3Text].allSatisfy { text in
            Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "FBFBF9")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: 48)

                    VStack(spacing: 8) {
                        Text("Plum.B")
                            .font(.custom("Noto Serif SC", size: 30))
                            .fontWeight(.light)
                            .tracking(3)
                            .foregroundStyle(Color(hex: "1A1A1A"))

                        Rectangle()
                            .fill(Color(hex: "1A1A1A").opacity(0.2))
                            .frame(width: 48, height: 1)
                    }

                    Spacer(minLength: 92)

                    HStack(alignment: .top, spacing: 24) {
                        InputColumn(title: "INPUT 1", text: $viewModel.n1Text)
                        InputColumn(title: "INPUT 2", text: $viewModel.n2Text)
                        InputColumn(title: "INPUT 3", text: $viewModel.n3Text)
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 96)

                    Button {
                        viewModel.castHexagram()
                    } label: {
                        VStack(spacing: 22) {
                            ZStack {
                                Circle()
                                    .fill(isInputReady ? Color(hex: "1A1A1A") : Color.clear)
                                    .overlay {
                                        Circle()
                                            .stroke(
                                                Color(hex: "1A1A1A").opacity(isInputReady ? 0 : 0.1),
                                                lineWidth: 0.8
                                            )
                                    }
                                    .frame(width: 96, height: 96)
                                    .shadow(
                                        color: Color.black.opacity(isInputReady ? 0.12 : 0),
                                        radius: isInputReady ? 22 : 0,
                                        y: isInputReady ? 10 : 0
                                    )
                                    .scaleEffect(isInputReady && isReadyPulseActive ? 1.03 : 1)
                                    .offset(y: isInputReady && isReadyPulseActive ? -3 : 0)
                                    .animation(.spring(response: 0.42, dampingFraction: 0.76), value: isInputReady)
                                    .animation(
                                        isInputReady
                                            ? .easeInOut(duration: 1.7).repeatForever(autoreverses: true)
                                            : .easeOut(duration: 0.2),
                                        value: isReadyPulseActive
                                    )
                                    .overlay {
                                        Circle()
                                            .stroke(Color(hex: "1A1A1A").opacity(isInputReady ? 0.08 : 0), lineWidth: 10)
                                            .scaleEffect(isInputReady && isReadyPulseActive ? 1.18 : 0.86)
                                            .opacity(isInputReady && isReadyPulseActive ? 0 : 1)
                                            .animation(
                                                isInputReady
                                                    ? .easeOut(duration: 1.5).repeatForever(autoreverses: false)
                                                    : .easeOut(duration: 0.2),
                                                value: isReadyPulseActive
                                            )
                                    }

                                Text("卜")
                                    .font(.custom("Noto Serif SC", size: 36))
                                    .fontWeight(.medium)
                                    .foregroundStyle(isInputReady ? Color.white : Color(hex: "1A1A1A").opacity(0.2))
                            }

                            if isInputReady {
                                Text("点 击 起 卦")
                                    .font(.custom("Noto Serif SC", size: 12))
                                    .fontWeight(.light)
                                    .tracking(3.6)
                                    .foregroundStyle(Color(hex: "1A1A1A").opacity(0.6))
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: isInputReady)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isInputReady)

                    Spacer(minLength: 120)

                    VStack(spacing: 4) {
                        Text("极数知来之谓占")
                            .font(.custom("Noto Serif SC", size: 12))
                            .tracking(0.6)
                            .foregroundStyle(Color(hex: "1A1A1A").opacity(0.3))

                        Text("通变之谓事")
                            .font(.custom("Noto Serif SC", size: 12))
                            .tracking(0.6)
                            .foregroundStyle(Color(hex: "1A1A1A").opacity(0.3))
                    }

                    if let message = viewModel.errorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red.opacity(0.85))
                            .padding(.top, 28)
                            .padding(.horizontal, 24)
                            .multilineTextAlignment(.center)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(
                isPresented: Binding(
                    get: { viewModel.result != nil },
                    set: { isPresented in
                        if !isPresented {
                            viewModel.result = nil
                        }
                    }
                )
            ) {
                if let result = viewModel.result {
                    ResultView(result: result)
                }
            }
            .onAppear {
                isReadyPulseActive = isInputReady
            }
            .onChange(of: isInputReady) { _, newValue in
                if newValue {
                    isReadyPulseActive = false
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                        isReadyPulseActive = true
                    }
                } else {
                    isReadyPulseActive = false
                }
            }
        }
    }
}

private struct InputColumn: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottom) {
                TextField("0", text: $text)
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.center)
                    .font(.custom("Noto Serif SC", size: 48))
                    .foregroundStyle(Color(hex: "1A1A1A").opacity(text.isEmpty ? 0.5 : 0.82))
                    .frame(width: 80, height: 104)

                Rectangle()
                    .fill(Color(hex: "1A1A1A").opacity(0.1))
                    .frame(width: 80, height: 2)
            }

            Text(title)
                .font(.custom("Noto Serif SC", size: 10))
                .tracking(-0.5)
                .foregroundStyle(Color(hex: "1A1A1A").opacity(0.4))
        }
    }
}

extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&int)

        let r, g, b: UInt64
        switch sanitized.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xff, int & 0xff)
        default:
            (r, g, b) = (0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

#Preview {
    ContentView()
}

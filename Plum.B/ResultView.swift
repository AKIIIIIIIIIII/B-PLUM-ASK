import SwiftUI

struct ResultView: View {
    @Environment(\.dismiss) private var dismiss
    let result: DivinationResult

    @State private var animateHexagram = false

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "FBFBF9")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                        .padding(.top, 128)

                    hexagramSection
                        .padding(.top, 64)

                    contentSection
                        .padding(.top, 64)

                    footerSection
                        .padding(.top, 64)
                        .padding(.bottom, 80)
                }
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            topBar
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            animateHexagram = true
        }
    }

    private var topBar: some View {
        ZStack {
            Rectangle()
                .fill(Color(hex: "FBFBF9").opacity(0.94))
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color(hex: "1A1A1A").opacity(0.05))
                        .frame(height: 0.7)
                }
                .ignoresSafeArea(edges: .top)

            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .medium))

                        Text("BACK")
                            .font(.custom("Inter", size: 14).weight(.medium))
                            .tracking(1.25)
                            .lineSpacing(20)
                    }
                    .foregroundStyle(Color(hex: "1A1A1A").opacity(0.6))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .frame(height: 84, alignment: .bottom)
        }
        .frame(height: 84)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom, spacing: 16) {
                Text(primaryDisplayCharacter)
                    .font(.custom("Noto Serif SC", size: 72))
                    .fontWeight(.light)
                    .lineSpacing(72)
                    .tracking(-3.6)
                    .foregroundStyle(Color(hex: "1A1A1A"))

                VStack(alignment: .leading, spacing: 4) {
                    Text(transliterationText)
                        .font(.custom("Inter", size: 20).weight(.thin))
                        .tracking(1.55)
                        .lineSpacing(28)
                        .foregroundStyle(Color(hex: "1A1A1A").opacity(0.4))

                    Text("I CHING DIVINATION")
                        .font(.custom("Noto Serif SC", size: 12))
                        .tracking(4.8)
                        .lineSpacing(16)
                        .foregroundStyle(Color(hex: "1A1A1A").opacity(0.3))
                }
                .padding(.bottom, 8)
            }

            Rectangle()
                .fill(Color(hex: "B22222").opacity(0.6))
                .frame(width: 96, height: 2)
        }
    }

    private var hexagramSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                ForEach(Array(displayLines.enumerated()), id: \.offset) { index, line in
                    HexagramLineView(
                        line: line,
                        animate: animateHexagram,
                        delay: Double(index) * 0.08
                    )
                }
            }
            .frame(width: 192)
            .padding(.top, 32)

            Text("Guà Xiàng")
                .font(.custom("Inter", size: 10))
                .tracking(6.12)
                .lineSpacing(15)
                .foregroundStyle(Color(hex: "1A1A1A").opacity(0.3))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 48) {
            // 卦辞
            VStack(alignment: .leading, spacing: 20) {
                sectionEyebrow(english: "Judgment", chinese: "卦 辞")

                Text(result.judgment)
                    .font(.custom("Noto Serif SC", size: 26))
                    .fontWeight(.medium)
                    .tracking(0.5)
                    .lineSpacing(8) // 显著调小
                    .foregroundStyle(Color(hex: "1A1A1A"))
            }

            // 大象
            if !result.daxiang.isEmpty {
                VStack(alignment: .leading, spacing: 18) {
                    sectionEyebrow(english: "Da Xiang", chinese: "大 象")

                    Text(result.daxiang)
                        .font(.custom("Noto Serif SC", size: 18))
                        .tracking(0.2)
                        .lineSpacing(6) // 显著调小
                        .foregroundStyle(Color(hex: "1A1A1A").opacity(0.85))
                }
            }

            // 彖传
            if !result.tuan.isEmpty {
                VStack(alignment: .leading, spacing: 18) {
                    sectionEyebrow(english: "Tuan Zhuan", chinese: "彖 传")

                    Text(result.tuan)
                        .font(.custom("Noto Serif SC", size: 18))
                        .tracking(0.2)
                        .lineSpacing(6) // 显著调小
                        .foregroundStyle(Color(hex: "1A1A1A").opacity(0.85))
                }
            }

            // 动爻
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: "B22222"))
                        .frame(width: 8, height: 8)

                    Text("DONG YAO")
                        .font(.custom("Inter", size: 14).weight(.bold))
                        .tracking(1.25)
                        .lineSpacing(20)
                        .foregroundStyle(Color(hex: "B22222"))

                    Text("第 \(result.movingLine) 爻")
                        .font(.custom("Noto Serif SC", size: 12))
                        .tracking(1.2)
                        .lineSpacing(16)
                        .foregroundStyle(Color(hex: "1A1A1A").opacity(0.3))
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text(result.movingLineText)
                        .font(.custom("Noto Serif SC", size: 22))
                        .fontWeight(.medium)
                        .tracking(0.32)
                        .lineSpacing(8) // 调小
                        .foregroundStyle(Color(hex: "1A1A1A"))

                    if !result.movingLineSummary.isEmpty {
                        Text(result.movingLineSummary)
                            .font(.custom("Inter", size: 15).weight(.light))
                            .tracking(0.1)
                            .lineSpacing(4) // 调小
                            .foregroundStyle(Color(hex: "1A1A1A").opacity(0.6))
                    }

                    if !result.movingLineXiang.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("象曰：")
                                .font(.custom("Inter", size: 11).weight(.bold))
                                .tracking(1.2)
                                .foregroundStyle(Color(hex: "1A1A1A").opacity(0.3))

                            Text(result.movingLineXiang)
                                .font(.custom("Noto Serif SC", size: 17))
                                .tracking(0.1)
                                .lineSpacing(6) // 调小
                                .foregroundStyle(Color(hex: "1A1A1A").opacity(0.7))
                        }
                        .padding(.leading, 16)
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(Color(hex: "1A1A1A").opacity(0.08))
                                .frame(width: 1.5)
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding(.leading, 24)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "B22222").opacity(0.02))
            )
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color(hex: "B22222").opacity(0.3))
                    .frame(width: 3)
            }
        }
    }

    private var footerSection: some View {
        VStack(spacing: 24) {
            Text("PLUM.B ORACLE")
                .font(.custom("Inter", size: 12))
                .tracking(9.6)
                .lineSpacing(16)
                .foregroundStyle(Color(hex: "1A1A1A").opacity(0.2))

            Text("\(result.upperRemainder) • \(result.lowerRemainder) • \(result.movingLine)")
                .font(.custom("Noto Serif SC", size: 10))
                .tracking(0.32)
                .lineSpacing(15)
                .foregroundStyle(Color(hex: "1A1A1A").opacity(0.2))
        }
        .frame(maxWidth: .infinity)
    }

    private func sectionEyebrow(english: String, chinese: String) -> some View {
        HStack(spacing: 12) {
            Text(english.uppercased())
                .font(.custom("Inter", size: 11))
                .tracking(4.46)
                .lineSpacing(16.5)
                .foregroundStyle(Color(hex: "1A1A1A").opacity(0.4))

            Rectangle()
                .fill(Color(hex: "1A1A1A").opacity(0.1))
                .frame(height: 0.5)

            Text(chinese)
                .font(.custom("Noto Serif SC", size: 12))
                .tracking(0.32)
                .lineSpacing(18)
                .foregroundStyle(Color(hex: "1A1A1A").opacity(0.4))
        }
    }

    private var primaryDisplayCharacter: String {
        String(result.hexagramName.first ?? Character("卦"))
    }

    private var transliterationText: String {
        let character = String(result.hexagramName.first ?? Character("卦"))
        switch character {
        case "乾": return "Qián"
        case "坤": return "Kūn"
        case "屯": return "Zhūn"
        case "蒙": return "Méng"
        case "需": return "Xū"
        case "讼": return "Sòng"
        case "师": return "Shī"
        case "比": return "Bǐ"
        case "履": return "Lǚ"
        case "泰": return "Tài"
        case "否": return "Pǐ"
        case "谦": return "Qiān"
        case "豫": return "Yù"
        case "随": return "Suí"
        case "蛊": return "Gǔ"
        case "临": return "Lín"
        case "观": return "Guān"
        case "噬": return "Shì"
        case "贲": return "Bì"
        case "剥": return "Bō"
        case "复": return "Fù"
        case "无": return "Wú"
        case "夬": return "Guài"
        case "姤": return "Gòu"
        case "萃": return "Cuì"
        case "升": return "Shēng"
        case "困": return "Kùn"
        case "井": return "Jǐng"
        case "革": return "Gé"
        case "鼎": return "Dǐng"
        case "震": return "Zhèn"
        case "艮": return "Gèn"
        case "渐": return "Jiàn"
        case "归": return "Guī"
        case "丰": return "Fēng"
        case "旅": return "Lǚ"
        case "巽": return "Xùn"
        case "兑": return "Duì"
        case "涣": return "Huàn"
        case "节": return "Jié"
        case "中": return "Zhōng"
        case "既": return "Jì"
        case "未": return "Wèi"
        default: return result.hexagramName
        }
    }

    private var meaningText: String {
        let sections = [result.judgmentSummary, result.daxiang]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return sections.isEmpty ? "暂无白话释义。" : sections.joined(separator: " ")
    }

    private var movingMeaningText: String {
        let sections = [result.movingLineSummary, result.movingLineXiang]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return sections.isEmpty ? "此爻动，变象将成，宜结合当下处境细察其机。" : sections.joined(separator: " ")
    }

    private var displayLines: [HexagramLineState] {
        let lower = trigramBits(for: result.lowerRemainder)
        let upper = trigramBits(for: result.upperRemainder)
        let lines = lower + upper

        return lines.enumerated().reversed().map { index, bit in
            HexagramLineState(
                isYang: bit == 1,
                isMoving: index + 1 == result.movingLine
            )
        }
    }

    private func trigramBits(for userIndex: Int) -> [Int] {
        let userToBitsIndex = [0, 7, 3, 1, 6, 5, 2, 4]
        guard userToBitsIndex.indices.contains(userIndex) else {
            return [0, 0, 0]
        }
        let bitsIndex = userToBitsIndex[userIndex]
        return [
            bitsIndex & 1,
            (bitsIndex >> 1) & 1,
            (bitsIndex >> 2) & 1
        ]
    }
}

private struct HexagramLineState {
    let isYang: Bool
    let isMoving: Bool
}

private struct HexagramLineView: View {
    let line: HexagramLineState
    let animate: Bool
    let delay: Double

    var body: some View {
        ZStack(alignment: .leading) {
            if line.isMoving {
                Text("DONG")
                    .font(.custom("Inter", size: 10).weight(.bold))
                    .tracking(1.12)
                    .lineSpacing(15)
                    .foregroundStyle(Color(hex: "B22222"))
                    .offset(x: -36)
            }

            HStack(spacing: 20) {
                segment

                if line.isYang {
                    EmptyView()
                } else {
                    segment
                }
            }
            .frame(width: 192, alignment: .leading)
        }
    }

    @ViewBuilder
    private var segment: some View {
        let width: CGFloat = line.isYang ? 192 : 86

        RoundedRectangle(cornerRadius: 4)
            .fill(line.isMoving ? Color(hex: "B22222") : Color(hex: "1A1A1A"))
            .frame(width: width, height: 10)
            .shadow(color: line.isMoving ? Color(hex: "B22222").opacity(0.2) : .clear, radius: 15)
            .scaleEffect(x: animate ? 1 : 0.2, y: 1, anchor: .leading)
            .opacity(animate ? 1 : 0.2)
            .animation(.easeOut(duration: 0.45).delay(delay), value: animate)
    }
}

#Preview {
    ResultView(
        result: DivinationResult(
            upperRemainder: 1,
            lowerRemainder: 1,
            movingRemainder: 1,
            upperName: "天",
            lowerName: "天",
            hexagramName: "乾为天",
            judgment: "乾：元，亨，利，贞。",
            judgmentSummary: "汇聚了良好条件，宜于坚定守正。",
            tuan: "大哉乾元，万物资始。",
            daxiang: "天行健，君子以自强不息。",
            movingLine: 1,
            movingLineText: "初九：潜龙勿用。",
            movingLineXiang: "潜龙，勿用，阳在下也。",
            movingLineSummary: "潜藏的龙，切勿有任何作为。",
            allLineTexts: [],
            allLineXiang: [],
            allLineSummaries: []
        )
    )
}

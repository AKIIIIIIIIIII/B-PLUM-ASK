import Foundation

// 远程卦数据：john-walks-slow/open-iching（raw JSON，HTTPS）
// https://github.com/john-walks-slow/open-iching

private struct OpenIchingLineDTO: Codable {
    let id: Int
    let name: String
    let scripture: String
}

private struct OpenIchingHexDTO: Codable {
    let id: Int
    let name: String
    let array: [Int]
    let scripture: String
    let lines: [OpenIchingLineDTO]
}

@MainActor
final class DivinationViewModel: ObservableObject {
    @Published var n1Text = ""
    @Published var n2Text = ""
    @Published var n3Text = ""
    @Published var errorMessage: String?
    @Published var result: DivinationResult?
    /// 最近一次远程加载说明（成功或失败摘要）
    @Published var remoteStatus: String = ""

    private var hexagramTable: [[Hexagram?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
    private var remoteLoadSucceeded = false

    private let trigramMap: [Int: String] = [
        1: "天",
        2: "泽",
        3: "火",
        4: "雷",
        5: "风",
        6: "水",
        7: "山",
        0: "地"
    ]

    private let trigramChars = ["地", "天", "泽", "火", "雷", "风", "水", "山"]

    /// 下三爻或上三爻：`b0 + 2*b1 + 4*b2`（初爻为 b0）→ 与 App 中 0…7 八卦余数对应
    private static let bitsToUserIndex = [0, 4, 6, 2, 7, 3, 5, 1]

    private static let remoteURL = URL(string: "https://raw.githubusercontent.com/john-walks-slow/open-iching/main/iching/iching.json")!
    private static let remoteTuanURL = URL(string: "https://raw.githubusercontent.com/john-walks-slow/open-iching/main/ichuan/tuan.json")!
    private static let remoteXiangURL = URL(string: "https://raw.githubusercontent.com/john-walks-slow/open-iching/main/ichuan/xiang.json")!

    init() {
        loadLocalBundleHexagrams()
        Task { await refreshHexagramsFromNetwork() }
    }

    func castHexagram() {
        Task { await castHexagramAsync() }
    }

    func castHexagramAsync() async {
        errorMessage = nil
        result = nil

        let t1 = n1Text.trimmingCharacters(in: .whitespacesAndNewlines)
        let t2 = n2Text.trimmingCharacters(in: .whitespacesAndNewlines)
        let t3 = n3Text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !t1.isEmpty, !t2.isEmpty, !t3.isEmpty else {
            errorMessage = "请输入 n1、n2、n3。"
            return
        }

        guard let n1 = Int(t1), let n2 = Int(t2), let n3 = Int(t3) else {
            errorMessage = "请输入有效整数（不可包含非数字字符）。"
            return
        }

        if !remoteLoadSucceeded {
            await refreshHexagramsFromNetwork()
        }

        let upperIndex = positiveMod(n1, by: 8)
        let lowerIndex = positiveMod(n2, by: 8)
        let movingRemainder = positiveMod(n3, by: 6)
        var movingLine = movingRemainder
        if movingLine == 0 {
            movingLine = 6
        }

        let upperName = trigramMap[upperIndex] ?? "未知"
        let lowerName = trigramMap[lowerIndex] ?? "未知"
        var hexagramName = "暂无数据"
        var judgment = "无卦辞数据。"
        var judgmentSummary = ""
        var tuanText = ""
        var daxiangText = ""
        var allLineTexts = (1...6).map { "第\($0)爻：暂无爻辞。" }
        var allLineXiang = (1...6).map { _ in "" }
        var allLineSummaries = (1...6).map { _ in "" }

        if let hexagram = hexagramTable[upperIndex][lowerIndex] {
            hexagramName = hexagram.name
            judgment = hexagram.judgment
            judgmentSummary = (hexagram.judgmentSummary ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            tuanText = (hexagram.tuan ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            daxiangText = (hexagram.daxiang ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            allLineTexts = normalizedLines(from: hexagram.lines)
            allLineXiang = normalizedLineXiang(from: hexagram.lineXiang)
            allLineSummaries = normalizedLineSummaries(from: hexagram.lineSummary)
        }

        let lineText = allLineTexts[movingLine - 1]
        let lineXiangMoving = allLineXiang[movingLine - 1]
        let lineSummaryMoving = allLineSummaries[movingLine - 1]

        result = DivinationResult(
            upperRemainder: upperIndex,
            lowerRemainder: lowerIndex,
            movingRemainder: movingRemainder,
            upperName: upperName,
            lowerName: lowerName,
            hexagramName: hexagramName,
            judgment: judgment,
            judgmentSummary: judgmentSummary,
            tuan: tuanText,
            daxiang: daxiangText,
            movingLine: movingLine,
            movingLineText: lineText,
            movingLineXiang: lineXiangMoving,
            movingLineSummary: lineSummaryMoving,
            allLineTexts: allLineTexts,
            allLineXiang: allLineXiang,
            allLineSummaries: allLineSummaries
        )
    }

    /// 从网络拉取 64 卦全文；失败则保留包内数据。
    func refreshHexagramsFromNetwork() async {
        do {
            async let ichingTask = URLSession.shared.data(from: Self.remoteURL)
            async let tuanTask = URLSession.shared.data(from: Self.remoteTuanURL)
            async let xiangTask = URLSession.shared.data(from: Self.remoteXiangURL)

            let (iData, iResp) = try await ichingTask
            if let http = iResp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }
            let dtos = try JSONDecoder().decode([OpenIchingHexDTO].self, from: iData)

            var tuanMap: [String: String] = [:]
            var xiangMap: [String: String] = [:]
            if let (tData, tResp) = try? await tuanTask,
               let http = tResp as? HTTPURLResponse, (200...299).contains(http.statusCode),
               let decoded = try? JSONDecoder().decode([String: String].self, from: tData) {
                tuanMap = decoded
            }
            if let (xData, xResp) = try? await xiangTask,
               let http = xResp as? HTTPURLResponse, (200...299).contains(http.statusCode),
               let decoded = try? JSONDecoder().decode([String: String].self, from: xData) {
                xiangMap = decoded
            }

            let localByID = Dictionary(
                uniqueKeysWithValues: hexagramTable.flatMap { $0 }.compactMap { $0 }.map { ($0.id, $0) }
            )
            let converted = dtos.compactMap {
                Self.hexagram(
                    from: $0,
                    trigramChars: trigramChars,
                    tuan: tuanMap,
                    xiang: xiangMap,
                    localFallback: localByID[$0.id]
                )
            }
            guard converted.count == 64 else {
                remoteStatus = "网络数据条数异常（\(converted.count)/64），已沿用本地。"
                return
            }
            fillTable(from: converted)
            remoteLoadSucceeded = true
            let extra = tuanMap.isEmpty && xiangMap.isEmpty ? "" : "（含彖、象传）"
            remoteStatus = "已从网络加载卦辞、爻辞\(extra)。"
        } catch {
            remoteStatus = "网络不可用：\(error.localizedDescription)。已用包内 hexagrams.json（若有）。"
        }
    }

    private func loadLocalBundleHexagrams() {
        do {
            if let url = Bundle.main.url(forResource: "hexagrams", withExtension: "json") {
                let data = try Data(contentsOf: url)
                let list = try JSONDecoder().decode([Hexagram].self, from: data)
                fillTable(from: list)
                remoteStatus = "已加载包内 hexagrams.json。"
                return
            }
            for bundle in [Bundle(for: Self.self), .main] {
                if let url = bundle.url(forResource: "hexagrams", withExtension: "json") {
                    let data = try Data(contentsOf: url)
                    let list = try JSONDecoder().decode([Hexagram].self, from: data)
                    fillTable(from: list)
                    remoteStatus = "已加载包内 hexagrams.json。"
                    return
                }
            }
            errorMessage = "未找到 hexagrams.json，且尚未从网络加载成功。"
        } catch {
            errorMessage = "hexagrams.json 读取失败：\(error.localizedDescription)"
        }
    }

    private func fillTable(from list: [Hexagram]) {
        hexagramTable = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        for h in list where (0..<8).contains(h.upper) && (0..<8).contains(h.lower) {
            hexagramTable[h.upper][h.lower] = h
        }
    }

    private static func hexagram(
        from dto: OpenIchingHexDTO,
        trigramChars: [String],
        tuan: [String: String],
        xiang: [String: String],
        localFallback: Hexagram?
    ) -> Hexagram? {
        guard dto.array.count == 6 else { return nil }
        let bits = dto.array
        let tLower = bits[0] + 2 * bits[1] + 4 * bits[2]
        let tUpper = bits[3] + 2 * bits[4] + 4 * bits[5]
        guard (0..<8).contains(tLower), (0..<8).contains(tUpper) else { return nil }
        let lowerUser = bitsToUserIndex[tLower]
        let upperUser = bitsToUserIndex[tUpper]

        let short = dto.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName: String
        if upperUser == lowerUser {
            displayName = pureHexagramName(upperUser: upperUser, short: short)
        } else {
            displayName = "\(trigramChars[upperUser])\(trigramChars[lowerUser])\(short)"
        }

        let six = dto.lines.filter { $0.id >= 1 && $0.id <= 6 }.sorted { $0.id < $1.id }
        guard six.count == 6 else { return nil }
        let lineStrings = six.map { "\($0.name)：\($0.scripture)" }

        let kid = dto.id
        let tuanKey = "iching__\(kid)"
        let tuanText = tuan[tuanKey].map { Self.stripCurlyQuotes($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        let daxiangText = xiang[tuanKey].map { Self.stripCurlyQuotes($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        var lineXiang: [String] = []
        for i in 1...6 {
            let k = "iching__\(kid)_\(i)"
            let raw = xiang[k]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            lineXiang.append(Self.stripCurlyQuotes(raw))
        }

        return Hexagram(
            id: dto.id,
            upper: upperUser,
            lower: lowerUser,
            name: displayName,
            judgment: dto.scripture.trimmingCharacters(in: .whitespacesAndNewlines),
            judgmentSummary: localFallback?.judgmentSummary,
            tuan: nonEmptyOptional(tuanText),
            daxiang: nonEmptyOptional(daxiangText),
            lines: lineStrings,
            lineSummary: localFallback?.lineSummary,
            lineXiang: lineXiang.allSatisfy(\.isEmpty) ? nil : lineXiang
        )
    }

    private static func nonEmptyOptional(_ s: String?) -> String? {
        guard let t = s?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
        return t
    }

    /// 去掉易传文本中的弯引号 “ ”（与 hexagrams.json 中写法一致）
    private static func stripCurlyQuotes(_ s: String) -> String {
        s.replacingOccurrences(of: "\u{201C}", with: "")
            .replacingOccurrences(of: "\u{201D}", with: "")
    }

    private static func pureHexagramName(upperUser: Int, short: String) -> String {
        switch (upperUser, short) {
        case (0, "坤"): return "坤为地"
        case (1, "乾"): return "乾为天"
        case (2, "兑"): return "兑为泽"
        case (3, "离"), (3, "離"): return "离为火"
        case (4, "震"): return "震为雷"
        case (5, "巽"): return "巽为风"
        case (6, "坎"): return "坎为水"
        case (7, "艮"): return "艮为山"
        default: return short
        }
    }

    private func positiveMod(_ value: Int, by mod: Int) -> Int {
        let r = value % mod
        return r >= 0 ? r : r + mod
    }

    private func normalizedLines(from lines: [String]) -> [String] {
        if lines.count == 6 {
            return lines
        }
        var merged = lines
        if merged.count < 6 {
            for i in merged.count..<6 {
                merged.append("第\(i + 1)爻：暂无爻辞。")
            }
        } else if merged.count > 6 {
            merged = Array(merged.prefix(6))
        }
        return merged
    }

    private func normalizedLineXiang(from lineXiang: [String]?) -> [String] {
        guard var xs = lineXiang else {
            return (0..<6).map { _ in "" }
        }
        if xs.count < 6 {
            for _ in xs.count..<6 { xs.append("") }
        } else if xs.count > 6 {
            xs = Array(xs.prefix(6))
        }
        return xs
    }

    private func normalizedLineSummaries(from lineSummary: [String]?) -> [String] {
        guard var summaries = lineSummary else {
            return (0..<6).map { _ in "" }
        }
        if summaries.count < 6 {
            for _ in summaries.count..<6 { summaries.append("") }
        } else if summaries.count > 6 {
            summaries = Array(summaries.prefix(6))
        }
        return summaries
    }
}

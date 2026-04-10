import Foundation

struct Hexagram: Codable, Identifiable {
    let id: Int
    let upper: Int
    let lower: Int
    let name: String
    let judgment: String
    /// 卦辞白话说明
    let judgmentSummary: String?
    /// 《彖传》释卦辞（可与卦辞分开展示）
    let tuan: String?
    /// 《大象》
    let daxiang: String?
    let lines: [String]
    /// 六爻白话说明，与 lines 按下标 0…5 一一对应
    let lineSummary: [String]?
    /// 六爻《小象》，与 lines 按下标 0…5 一一对应
    let lineXiang: [String]?
}

struct DivinationResult {
    let upperRemainder: Int
    let lowerRemainder: Int
    let movingRemainder: Int
    let upperName: String
    let lowerName: String
    let hexagramName: String
    let judgment: String
    let judgmentSummary: String
    let tuan: String
    let daxiang: String
    let movingLine: Int
    let movingLineText: String
    let movingLineXiang: String
    let movingLineSummary: String
    let allLineTexts: [String]
    let allLineXiang: [String]
    let allLineSummaries: [String]
}

//
//  DivinationResultSections.swift
//  Plum.B
//

import SwiftUI

/// 起卦后展示的经文结构：卦名、卦辞、大象、彖传、六爻爻辞与各爻小象。
struct DivinationResultSections: View {
    let result: DivinationResult

    var body: some View {
        Section("卦名") {
            Text(result.hexagramName)
                .font(.title3.weight(.medium))
        }

        Section("卦辞") {
            Text(result.judgment.isEmpty ? "（暂无）" : result.judgment)
                .foregroundStyle(result.judgment.isEmpty ? .secondary : .primary)
        }

        Section("卦辞白话") {
            Text(result.judgmentSummary.isEmpty ? "（暂无）" : result.judgmentSummary)
                .foregroundStyle(result.judgmentSummary.isEmpty ? .secondary : .primary)
        }

        Section("大象") {
            Text(result.daxiang.isEmpty ? "（暂无）" : result.daxiang)
                .foregroundStyle(result.daxiang.isEmpty ? .secondary : .primary)
        }

        Section("彖传") {
            Text(result.tuan.isEmpty ? "（暂无）" : result.tuan)
                .foregroundStyle(result.tuan.isEmpty ? .secondary : .primary)
        }

        Section("六爻爻辞与小象") {
            ForEach(0..<6, id: \.self) { i in
                yaoBlock(index: i)
            }
        }
    }

    @ViewBuilder
    private func yaoBlock(index i: Int) -> some View {
        let isMoving = i + 1 == result.movingLine
        let yao = i < result.allLineTexts.count ? result.allLineTexts[i] : "（暂无）"
        let xx = i < result.allLineXiang.count ? result.allLineXiang[i] : ""

        VStack(alignment: .leading, spacing: 6) {
            Text("第\(i + 1)爻\(isMoving ? "（动爻）" : "")")
                .font(.subheadline.weight(isMoving ? .semibold : .regular))
                .foregroundStyle(isMoving ? .red : .secondary)

            Text("爻辞")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text(yao)
                .foregroundStyle(.primary)

            Text("白话")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text(result.allLineSummaries[i].isEmpty ? "（暂无）" : result.allLineSummaries[i])
                .foregroundStyle(result.allLineSummaries[i].isEmpty ? .secondary : .primary)

            if xx.isEmpty {
                Text("象曰：（暂无）")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            } else {
                Text("象曰：\(xx)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

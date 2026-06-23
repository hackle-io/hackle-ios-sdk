import SwiftUI

struct InAppMessageDetailSheetView: View {

    let presentation: InAppMessageDetailPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    content
                }
                .padding(16)
            }
        }
        .modifier(SheetDetentsIfAvailable())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(presentation.keyLabel)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
            Text(presentation.reason)
                .font(.system(size: 12))
                .foregroundColor(presentation.isEligible ? Color.blue : Color.explorerSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    @ViewBuilder
    private var content: some View {
        switch presentation.detail {
        case .target(let groups):
            targetContent(groups)
        case .frequency(let detail):
            frequencyContent(detail)
        case .hidden(let detail):
            hiddenContent(detail)
        }
    }

    // MARK: - Target

    @ViewBuilder
    private func targetContent(_ groups: [TargetGroupDetail]) -> some View {
        if groups.isEmpty {
            Text("전체 노출 대상입니다.")
                .font(.system(size: 13))
                .foregroundColor(Color.explorerSecondaryText)
        } else {
            ForEach(groups, id: \.index) { group in
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(group.conditions.enumerated()), id: \.offset) { _, condition in
                        conditionRow(condition)
                    }
                }
                Divider()
            }
        }
    }

    private func conditionRow(_ c: ConditionDetail) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("\(c.keyName)")
                    .font(.system(size: 13))
                    .foregroundColor(.black)
                Text("타겟팅 조건: \(c.requirement)")
                    .font(.system(size: 12))
                    .foregroundColor(Color.explorerSecondaryText)
                Spacer()
                if let isMatched = c.isMatched {
                    Text(isMatched ? "✓" : "✕")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isMatched ? .blue : .red)
                } else {
                    Text("-")
                        .font(.system(size: 13))
                        .foregroundColor(Color.explorerSecondaryText)
                }
            }
            if c.isUserProperty {
                Text("현재 값: \(c.userValue ?? "(nil)")")
                    .font(.system(size: 12))
                    .foregroundColor(Color.explorerSecondaryText)
            }
        }
    }

    // MARK: - Frequency

    @ViewBuilder
    private func frequencyContent(_ detail: FrequencyDetail) -> some View {
        if detail.caps.isEmpty {
            Text("빈도 제한이 설정되지 않았습니다")
                .font(.system(size: 13))
                .foregroundColor(Color.explorerSecondaryText)
        } else {
            ForEach(Array(detail.caps.enumerated()), id: \.offset) { _, cap in
                HStack {
                    Text(cap.label)
                        .font(.system(size: 13))
                        .foregroundColor(.black)
                    Spacer()
                    Text("\(cap.threshold)회 중 \(cap.currentCount)회\(cap.isExceeded ? " (초과)" : "")")
                        .font(.system(size: 13))
                        .foregroundColor(cap.isExceeded ? .red : Color.explorerSecondaryText)
                }
            }
        }
        Divider()
        Text("노출 이력 (\(detail.impressions.count))")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.black)
        if detail.impressions.isEmpty {
            Text("노출 이력이 없습니다")
                .font(.system(size: 12))
                .foregroundColor(Color.explorerSecondaryText)
        } else {
            ForEach(Array(detail.impressions.enumerated()), id: \.offset) { _, impression in
                VStack(alignment: .leading, spacing: 2) {
                    Text(impression.timestamp)
                        .font(.system(size: 12))
                        .foregroundColor(.black)
                    Text(impression.identifiers)
                        .font(.system(size: 11))
                        .foregroundColor(Color.explorerSecondaryText)
                }
            }
        }
    }

    // MARK: - Hidden

    @ViewBuilder
    private func hiddenContent(_ detail: HiddenDetail) -> some View {
        Text("사용자가 숨김 처리한 메시지입니다")
            .font(.system(size: 13))
            .foregroundColor(.black)
        if let expireAt = detail.expireAt {
            let formatter = Self.dateFormatter
            Text("\(formatter.string(from: expireAt)) 까지 숨김")
                .font(.system(size: 13))
                .foregroundColor(Color.explorerSecondaryText)
        } else {
            Text("만료 정보 없음")
                .font(.system(size: 13))
                .foregroundColor(Color.explorerSecondaryText)
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()
}

/// iOS 16+ 에서만 medium/large detents 적용. 이하 버전은 풀 모달.
private struct SheetDetentsIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.presentationDetents([.medium, .large])
        } else {
            content
        }
    }
}

#Preview {
    InAppMessageDetailSheetView(
        presentation: InAppMessageDetailPresentation(
            id: 0,
            keyLabel: "key",
            reason: "reason",
            isEligible: true,
            detail: InAppMessageDetail.target([
                TargetGroupDetail(index: 1, conditions: [
                    ConditionDetail(
                        keyType: "USER_PROPERTY",
                        keyName: "test",
                        requirement: "IN [VIP, GOLD]",
                        userValue: "VIP",
                        isMatched: true,
                        isUserProperty: true
                    )
                ])
            ])
        )
    )
}

import SwiftUI

/// Что показать на кружке: секунды для коротких перерывов, м:сс для длинных.
@MainActor
private func countdownText(_ controller: BreakController) -> (label: String, caption: String?) {
    let seconds = Int(controller.remaining.rounded(.up))
    if controller.breakDuration > 60 {
        return (Format.clock(controller.remaining), nil)
    }
    return ("\(seconds)", Format.plural(seconds, "секунда", "секунды", "секунд"))
}

/// Режим «Затемнять»: весь экран мягко затуманивается.
struct FullBreakView: View {
    @ObservedObject var controller: BreakController
    let phrase: String
    @State private var shown = false

    var body: some View {
        let text = countdownText(controller)
        ZStack {
            Haze()
                .opacity(0.94)

            VStack(spacing: 40) {
                Text(phrase)
                    .font(Fonts.typewriter(30))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)

                CountdownRing(progress: controller.progress, label: text.label, caption: text.caption,
                              size: 210, lineWidth: 5, fontSize: 60)

                HStack(spacing: 32) {
                    QuietButton("через 5 минут") { controller.snooze() }
                    QuietButton("пропустить") { controller.skipBreak() }
                }
            }
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 10)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) { shown = true }
        }
    }
}

/// Режим «В уголке»: маленькое окошко, ничего не перекрывает.
struct CornerBreakView: View {
    @ObservedObject var controller: BreakController
    let phrase: String

    var body: some View {
        let text = countdownText(controller)
        HStack(spacing: 14) {
            CountdownRing(progress: controller.progress, label: text.label, caption: nil,
                          size: 56, lineWidth: 3.5, fontSize: text.label.count > 2 ? 14 : 20)

            VStack(alignment: .leading, spacing: 8) {
                Text(phrase.replacingOccurrences(of: "\n", with: " "))
                    .font(Fonts.typewriter(14))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 16) {
                    QuietButton("через 5 мин", size: 11) { controller.snooze() }
                    QuietButton("пропустить", size: 11) { controller.skipBreak() }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(width: 330)
        .background(Haze())
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Palette.ink.opacity(0.08))
        )
        .shadow(color: .black.opacity(0.15), radius: 14, y: 5)
        .padding(24) // место для тени
    }
}

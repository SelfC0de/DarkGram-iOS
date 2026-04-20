import SwiftUI

struct AuthView: View {
    @EnvironmentObject var tdManager: TDManager
    @EnvironmentObject var theme: ThemeManager

    @State private var phone    = ""
    @State private var code     = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMsg: String?

    var body: some View {
        ZStack {
            theme.colors.bg.ignoresSafeArea()

            VStack(spacing: 32) {
                // Logo
                VStack(spacing: 8) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 56))
                        .foregroundColor(theme.colors.accent)
                    Text("DarkGram+")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(theme.colors.text)
                }
                .padding(.top, 60)

                Spacer()

                VStack(spacing: 16) {
                    switch tdManager.authState {
                    case .waitPhoneNumber:
                        phoneStep
                    case .waitCode:
                        codeStep
                    case .waitPassword:
                        passwordStep
                    default:
                        EmptyView()
                    }

                    if let err = errorMsg {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
    }

    // MARK: - Steps

    private var phoneStep: some View {
        VStack(spacing: 16) {
            Text("Введи номер телефона")
                .foregroundColor(theme.colors.textSecondary)
                .font(.subheadline)

            DarkTextField(placeholder: "+7 000 000 00 00", text: $phone, keyboardType: .phonePad)

            DarkButton(title: "Далее", isLoading: isLoading) {
                submit { try await tdManager.sendPhone(phone) }
            }
        }
    }

    private var codeStep: some View {
        VStack(spacing: 16) {
            Text("Код из Telegram")
                .foregroundColor(theme.colors.textSecondary)
                .font(.subheadline)

            DarkTextField(placeholder: "12345", text: $code, keyboardType: .numberPad)

            DarkButton(title: "Подтвердить", isLoading: isLoading) {
                submit { try await tdManager.sendCode(code) }
            }
        }
    }

    private var passwordStep: some View {
        VStack(spacing: 16) {
            Text("Двухфакторный пароль")
                .foregroundColor(theme.colors.textSecondary)
                .font(.subheadline)

            DarkTextField(placeholder: "Пароль", text: $password, isSecure: true)

            DarkButton(title: "Войти", isLoading: isLoading) {
                submit { try await tdManager.sendPassword(password) }
            }
        }
    }

    // MARK: - Helper

    private func submit(_ action: @escaping () async throws -> Void) {
        errorMsg = nil
        isLoading = true
        Task {
            do {
                try await action()
            } catch {
                await MainActor.run {
                    errorMsg = error.localizedDescription
                }
            }
            await MainActor.run { isLoading = false }
        }
    }
}

// MARK: - Reusable components

struct DarkTextField: View {
    @EnvironmentObject var theme: ThemeManager
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
            }
        }
        .foregroundColor(theme.colors.text)
        .padding()
        .background(theme.colors.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.colors.separator, lineWidth: 1)
        )
    }
}

struct DarkButton: View {
    @EnvironmentObject var theme: ThemeManager
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(theme.colors.accent)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}

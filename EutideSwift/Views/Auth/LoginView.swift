import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isRegistering = false
    @FocusState private var focusedField: Field?

    // Forgot password sheet
    @State private var showForgotSheet = false
    @State private var resetEmail = ""
    @State private var resetSent = false
    @State private var resetLoading = false

    enum Field { case email, password }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo / title
            VStack(spacing: 8) {
                Text("Annuli")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("记录你的每一刻")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 48)

            // Form
            VStack(spacing: 14) {
                TextField("邮箱", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                // Password field with eye toggle
                HStack {
                    Group {
                        if showPassword {
                            TextField("密码", text: $password)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("密码", text: $password)
                        }
                    }
                    .focused($focusedField, equals: .password)

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

                // 忘记密码（仅登录模式显示）
                if !isRegistering {
                    HStack {
                        Spacer()
                        Button("忘记密码？") {
                            resetEmail = email
                            resetSent = false
                            showForgotSheet = true
                        }
                        .font(.system(size: 13))
                        .foregroundColor(.blue)
                    }
                }

                if let err = auth.errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    focusedField = nil
                    Task {
                        if isRegistering {
                            await auth.signUp(email: email, password: password)
                        } else {
                            await auth.signIn(email: email, password: password)
                        }
                    }
                } label: {
                    Text(isRegistering ? "注册" : "登录")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .disabled(email.isEmpty || password.isEmpty)

                Button(isRegistering ? "已有账号？登录" : "没有账号？注册") {
                    isRegistering.toggle()
                    auth.errorMessage = nil
                }
                .font(.system(size: 14))
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 28)

            Spacer()
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showForgotSheet) {
            ForgotPasswordSheet(
                email: $resetEmail,
                isSent: $resetSent,
                isLoading: $resetLoading
            ) {
                resetLoading = true
                let ok = await auth.resetPassword(email: resetEmail)
                resetLoading = false
                if ok { resetSent = true }
            }
            .presentationDetents([.height(300)])
        }
    }
}

private struct ForgotPasswordSheet: View {
    @Binding var email: String
    @Binding var isSent: Bool
    @Binding var isLoading: Bool
    var onSend: () async -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("找回密码")
                .font(.system(size: 20, weight: .semibold))
                .padding(.top, 24)

            if isSent {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    Text("重置邮件已发送")
                        .font(.system(size: 16, weight: .medium))
                    Text("请检查 \(email) 的收件箱")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                Button("关闭") { dismiss() }
                    .font(.system(size: 15))
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            } else {
                Text("输入账号邮箱，我们将发送重置链接")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                TextField("邮箱", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal, 24)

                Button {
                    Task { await onSend() }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("发送重置邮件")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(13)
                    .background(email.isEmpty ? Color.blue.opacity(0.4) : Color.blue)
                    .cornerRadius(10)
                }
                .disabled(email.isEmpty || isLoading)
                .padding(.horizontal, 24)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

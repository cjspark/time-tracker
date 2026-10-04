import SwiftUI

struct ResetPasswordView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showNew = false
    @State private var showConfirm = false
    @State private var isLoading = false
    @State private var done = false

    private var mismatch: Bool { !confirmPassword.isEmpty && newPassword != confirmPassword }
    private var canSubmit: Bool { newPassword.count >= 6 && newPassword == confirmPassword && !isLoading }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 44))
                    .foregroundColor(.blue)
                    .padding(.bottom, 8)
                Text("设置新密码")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text("请输入你的新密码")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 40)

            VStack(spacing: 14) {
                passwordField(label: "新密码", text: $newPassword, show: $showNew)
                passwordField(label: "确认密码", text: $confirmPassword, show: $showConfirm)

                if mismatch {
                    Text("两次密码不一致")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                if newPassword.count > 0 && newPassword.count < 6 {
                    Text("密码至少需要 6 位")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                if let err = auth.errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        isLoading = true
                        let ok = await auth.updatePassword(newPassword)
                        isLoading = false
                        if ok { done = true }
                    }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("确认修改")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(canSubmit ? Color.blue : Color.blue.opacity(0.4))
                    .cornerRadius(10)
                }
                .disabled(!canSubmit)
            }
            .padding(.horizontal, 28)

            Spacer()
        }
        .background(Color(.systemBackground))
        .alert("密码已更新", isPresented: $done) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("你的密码已成功修改，请用新密码登录。")
        }
    }

    @ViewBuilder
    private func passwordField(label: String, text: Binding<String>, show: Binding<Bool>) -> some View {
        HStack {
            Group {
                if show.wrappedValue {
                    TextField(label, text: text)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } else {
                    SecureField(label, text: text)
                }
            }
            Button { show.wrappedValue.toggle() } label: {
                Image(systemName: show.wrappedValue ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

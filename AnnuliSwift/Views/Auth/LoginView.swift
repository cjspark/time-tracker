import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @FocusState private var focusedField: Field?

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

                SecureField("密码", text: $password)
                    .focused($focusedField, equals: .password)
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

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
    }
}

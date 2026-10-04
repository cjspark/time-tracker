import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var showSignOutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    accountRow
                }

                Section {
                    Button(role: .destructive) {
                        showSignOutConfirm = true
                    } label: {
                        Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("删除账号", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                } footer: {
                    Text("删除账号后，你的所有数据将永久清除且无法恢复。")
                        .font(.caption)
                }
            }
            .navigationTitle("设置")
            .confirmationDialog("确认退出登录？", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button("退出登录", role: .destructive) {
                    Task { await auth.signOut() }
                }
                Button("取消", role: .cancel) {}
            }
            .confirmationDialog("确认删除账号？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("永久删除账号", role: .destructive) {
                    Task {
                        isDeleting = true
                        await auth.deleteAccount()
                        isDeleting = false
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("此操作不可撤销，所有数据将永久删除。")
            }
            .overlay {
                if isDeleting {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("正在删除账号…")
                                .font(.system(size: 14))
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var accountRow: some View {
        if let email = auth.currentEmail {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("当前账号")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(email)
                        .font(.system(size: 15))
                }
            }
            .padding(.vertical, 4)
        }
    }
}

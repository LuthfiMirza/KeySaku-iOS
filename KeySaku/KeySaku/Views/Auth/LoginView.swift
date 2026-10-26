import SwiftUI

/// Tampilan Login Utama KeySaku dengan integrasi Laravel Sanctum dan Mode Offline / Lokal
public struct LoginView: View {
    private var authService = AuthService.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var showRegisterSheet = false
    @State private var showServerSettingsAlert = false
    @State private var customServerURL = APIConfig.baseURL
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Logo & Hero Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#10B981"), Color(hex: "#059669")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 88, height: 88)
                                .shadow(color: Color(hex: "#10B981").opacity(0.35), radius: 12, y: 6)
                            
                            Image(systemName: "wallet.pass.fill")
                                .font(.system(size: 42))
                                .foregroundStyle(.white)
                        }
                        
                        Text("KeySaku")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        
                        Text("Catat & Kelola Keuangan Keluarga Lebih Cepat")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 24)
                    
                    // Form Login Card
                    VStack(spacing: 16) {
                        if let error = authService.errorMessage {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Alamat Email")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(.secondary)
                                TextField("nama@domain.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                            .padding()
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Kata Sandi")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.secondary)
                                SecureField("Masukkan kata sandi", text: $password)
                            }
                            .padding()
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Tombol Masuk Online
                        Button(action: handleLogin) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                    Text("Masuk ke Akun")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#10B981"), Color(hex: "#059669")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color(hex: "#10B981").opacity(0.3), radius: 8, y: 4)
                        }
                        .disabled(email.isEmpty || password.isEmpty || authService.isLoading)
                        .padding(.top, 4)
                    }
                    .padding(20)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal)
                    
                    // Pembatas Mode Offline
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 1)
                        Text("ATAU")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 32)
                    
                    // Tombol Mode Offline / Lokal (Bypass Server)
                    VStack(spacing: 8) {
                        Button(action: {
                            withAnimation(.spring()) {
                                authService.enterOfflineMode()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "bolt.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color(hex: "#10B981"))
                                    .frame(width: 36, height: 36)
                                    .background(Color(hex: "#10B981").opacity(0.15))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Masuk Mode Offline / Lokal")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    Text("Uji coba penuh tanpa server / internet")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: "#10B981").opacity(0.4), lineWidth: 1.5)
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Link Daftar Akun Baru
                    HStack {
                        Text("Belum punya akun?")
                            .foregroundStyle(.secondary)
                        Button("Daftar Sekarang") {
                            showRegisterSheet = true
                        }
                        .fontWeight(.bold)
                        .foregroundStyle(Color(hex: "#10B981"))
                    }
                    .font(.subheadline)
                    .padding(.bottom, 20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        customServerURL = APIConfig.baseURL
                        showServerSettingsAlert = true
                    } label: {
                        Image(systemName: "server.rack")
                            .font(.subheadline)
                    }
                }
            }
            .alert("Pengaturan Server API", isPresented: $showServerSettingsAlert) {
                TextField("URL Server Laravel", text: $customServerURL)
                Button("Simpan") {
                    APIConfig.baseURL = customServerURL
                }
                Button("Batal", role: .cancel) {}
            } message: {
                Text("Ubah alamat base URL backend Laravel jika sedang menjalankan server lokal (misal: http://192.168.1.x:8000/api/v1).")
            }
            .sheet(isPresented: $showRegisterSheet) {
                RegisterView()
            }
        }
    }
    
    private func handleLogin() {
        Task {
            _ = await authService.login(email: email, password: password)
        }
    }
}

#Preview {
    LoginView()
}

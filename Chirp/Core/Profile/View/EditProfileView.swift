//
//  EditProfileView.swift
//  Chirp
//
//  Created by Juan Palacio on 08.12.2025.
//

import SwiftUI
import PhotosUI
import Supabase

struct EditProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var fullName: String = ""
    @State private var bio: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var pendingCropImage: UIImage?
    @State private var cropperImage: IdentifiableImage?
    @State private var isUploading = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let twitterBlue = Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0))
    private let supabase = SupabaseManager.shared.client

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Picture Section
                    VStack(spacing: 12) {
                        // Current/Selected avatar
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let imageData = selectedImageData,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else if let avatarUrl = authManager.currentProfile?.avatarUrl,
                                          let url = URL(string: avatarUrl) {
                                    AsyncImage(url: url) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else {
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .foregroundColor(.gray)
                                        }
                                    }
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())

                            // Camera overlay
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(twitterBlue)
                                    .clipShape(Circle())
                            }
                        }

                        if isUploading {
                            ProgressView("Uploading...")
                                .font(.caption)
                        }
                    }
                    .padding(.top, 20)

                    // Form Fields
                    VStack(spacing: 20) {
                        // Full Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            TextField("Your name", text: $fullName)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                        }

                        // Bio
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bio")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            TextField("Write something about yourself...", text: $bio, axis: .vertical)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                                .lineLimit(3...6)
                        }

                        // Username (read-only for now)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            HStack {
                                Text("@\(authManager.currentProfile?.username ?? "")")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding(12)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving || isUploading)
                }
            }
            .onAppear {
                loadCurrentProfile()
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    await loadSelectedImage(from: newValue)
                }
            }
            .fullScreenCover(item: $cropperImage) { item in
                ImageCropperView(
                    image: item.image,
                    onCrop: { croppedImage in
                        handleCroppedImage(croppedImage)
                    },
                    onCancel: {
                        cropperImage = nil
                        pendingCropImage = nil
                    }
                )
            }
        }
    }

    private func loadCurrentProfile() {
        guard let profile = authManager.currentProfile else { return }
        fullName = profile.fullName
        bio = profile.bio ?? ""
    }

    private func loadSelectedImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        // Try loading the image data
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            await MainActor.run {
                pendingCropImage = uiImage
                cropperImage = IdentifiableImage(image: uiImage)
            }
            return
        }

        // Fallback: try using ImageTransferable
        if let imageData = try? await item.loadTransferable(type: ImageTransferable.self) {
            await MainActor.run {
                pendingCropImage = imageData.image
                cropperImage = IdentifiableImage(image: imageData.image)
            }
            return
        }

        await MainActor.run {
            errorMessage = "Failed to load image. Please try again."
        }
    }

    private func handleCroppedImage(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.9) {
            selectedImageData = data
        }
        cropperImage = nil
        pendingCropImage = nil
    }

    private func saveProfile() {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil

        Task {
            do {
                var avatarUrl: String? = nil

                // Upload new image if selected
                if let imageData = selectedImageData {
                    avatarUrl = try await uploadAvatar(imageData: imageData)
                }

                // Build update
                var update = ProfileUpdate()
                update.fullName = fullName.isEmpty ? nil : fullName
                update.bio = bio.isEmpty ? nil : bio
                if let url = avatarUrl {
                    update.avatarUrl = url
                }

                // Save to database
                try await authManager.updateProfile(updates: update)

                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save profile: \(error.localizedDescription)"
                    isSaving = false
                }
            }
        }
    }

    private func uploadAvatar(imageData: Data) async throws -> String {
        guard let userId = authManager.currentUser?.id else {
            throw NSError(domain: "EditProfile", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        await MainActor.run {
            isUploading = true
        }

        defer {
            Task { @MainActor in
                isUploading = false
            }
        }

        // Compress image if needed
        let compressedData: Data
        if let uiImage = UIImage(data: imageData) {
            compressedData = uiImage.jpegData(compressionQuality: 0.7) ?? imageData
        } else {
            compressedData = imageData
        }

        // Upload to Supabase Storage (use lowercase UUID for consistency with Postgres)
        let fileName = "\(userId.uuidString.lowercased())/avatar.jpg"

        try await supabase.storage
            .from("avatars")
            .upload(
                fileName,
                data: compressedData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )

        // Get public URL
        let publicUrl = try supabase.storage
            .from("avatars")
            .getPublicURL(path: fileName)

        return publicUrl.absoluteString
    }
}

#Preview {
    EditProfileView()
        .environmentObject(AuthManager())
}

// MARK: - Helper Types

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ImageTransferable: Transferable {
    let image: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let uiImage = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            return ImageTransferable(image: uiImage)
        }
    }

    enum TransferError: Error {
        case importFailed
    }
}

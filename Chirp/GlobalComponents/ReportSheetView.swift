//
//  ReportSheetView.swift
//  Chirp
//
//  Created by Juan Palacio on 07.12.2025.
//

import SwiftUI

struct ReportSheetView: View {
    let postId: UUID?
    let userId: UUID?
    let commentId: UUID?
    let reporterId: UUID

    @Environment(\.dismiss) var dismiss
    @State private var selectedReason: ReportReason?
    @State private var additionalDetails = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    private let postRepository = PostRepository()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showSuccess {
                    successView
                } else {
                    reportForm
                }
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var reportForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Why are you reporting this?")
                    .font(.headline)
                    .padding(.top)

                Text("Select the reason that best describes the issue.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Reason selection
                VStack(spacing: 12) {
                    ForEach(ReportReason.allCases, id: \.self) { reason in
                        ReportReasonRow(
                            reason: reason,
                            isSelected: selectedReason == reason
                        ) {
                            selectedReason = reason
                        }
                    }
                }
                .padding(.top, 8)

                // Additional details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Additional details (optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("Provide more context...", text: $additionalDetails, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .lineLimit(3...6)
                }
                .padding(.top, 8)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                // Submit button
                Button {
                    submitReport()
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Submit Report")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedReason != nil ? Color.red : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(selectedReason == nil || isSubmitting)
                .padding(.top, 16)

                Text("Reports are reviewed by our team. False reports may result in action against your account.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding()
        }
    }

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Report Submitted")
                .font(.title2)
                .fontWeight(.bold)

            Text("Thank you for helping keep Chirp safe. We'll review this report and take appropriate action.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Button("Done") {
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding()
        }
    }

    private func submitReport() {
        guard let reason = selectedReason else { return }
        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                let details = additionalDetails.isEmpty ? nil : additionalDetails

                if let postId = postId {
                    try await postRepository.reportPost(postId: postId, reporterId: reporterId, reason: reason, description: details)
                } else if let userId = userId {
                    try await postRepository.reportUser(userId: userId, reporterId: reporterId, reason: reason, description: details)
                } else if let commentId = commentId {
                    try await postRepository.reportComment(commentId: commentId, reporterId: reporterId, reason: reason, description: details)
                }

                await MainActor.run {
                    withAnimation {
                        showSuccess = true
                    }
                    isSubmitting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to submit report. Please try again."
                    isSubmitting = false
                }
            }
        }
    }
}

// MARK: - Report Reason Row

struct ReportReasonRow: View {
    let reason: ReportReason
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .red : .secondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(reason.displayName)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(reason.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(12)
            .background(isSelected ? Color.red.opacity(0.1) : Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.red : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

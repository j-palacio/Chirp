//
//  ImageCropperView.swift
//  Chirp
//
//  Created by Juan Palacio on 08.12.2025.
//

import SwiftUI

struct ImageCropperView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let cropSize: CGFloat = 280

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer()

                    // Crop area
                    ZStack {
                        // Image with gestures
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .scaleEffect(scale)
                            .offset(offset)
                            .frame(width: cropSize, height: cropSize)
                            .clipShape(Circle())
                            .gesture(
                                SimultaneousGesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            let newScale = lastScale * value
                                            scale = min(max(newScale, 1.0), 5.0)
                                        }
                                        .onEnded { _ in
                                            lastScale = scale
                                            constrainOffset()
                                        },
                                    DragGesture()
                                        .onChanged { value in
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                        .onEnded { _ in
                                            lastOffset = offset
                                            constrainOffset()
                                        }
                                )
                            )

                        // Circle overlay border
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: cropSize, height: cropSize)
                    }

                    Text("Pinch to zoom, drag to move")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 16)

                    Spacer()

                    // Action buttons
                    HStack(spacing: 40) {
                        Button {
                            onCancel()
                        } label: {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 120, height: 44)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(22)
                        }

                        Button {
                            let croppedImage = cropImage()
                            onCrop(croppedImage)
                        } label: {
                            Text("Done")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 120, height: 44)
                                .background(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))
                                .cornerRadius(22)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func constrainOffset() {
        // Calculate the bounds based on scale
        let imageSize = min(image.size.width, image.size.height)
        let scaledSize = imageSize * scale
        let maxOffset = (scaledSize - cropSize) / 2 / scale

        withAnimation(.easeOut(duration: 0.2)) {
            offset.width = min(max(offset.width, -maxOffset), maxOffset)
            offset.height = min(max(offset.height, -maxOffset), maxOffset)
            lastOffset = offset
        }
    }

    private func cropImage() -> UIImage {
        // Calculate the crop rect based on current scale and offset
        let imageSize = image.size
        let shortSide = min(imageSize.width, imageSize.height)

        // The visible area in image coordinates
        let visibleSize = shortSide / scale

        // Center point adjusted by offset
        let centerX = imageSize.width / 2 - (offset.width / cropSize) * visibleSize
        let centerY = imageSize.height / 2 - (offset.height / cropSize) * visibleSize

        // Crop rect
        let cropRect = CGRect(
            x: centerX - visibleSize / 2,
            y: centerY - visibleSize / 2,
            width: visibleSize,
            height: visibleSize
        )

        // Perform the crop
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }

        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)

        // Resize to a reasonable size for profile pictures (e.g., 400x400)
        let targetSize = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let finalImage = renderer.image { _ in
            croppedImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return finalImage
    }
}

#Preview {
    ImageCropperView(
        image: UIImage(systemName: "person.fill")!,
        onCrop: { _ in },
        onCancel: { }
    )
}

import SwiftUI

/// Custom Shape dengan kurva lengkung organik halus di bagian bawah untuk Hero Header
public struct CurvedHeaderShape: Shape {
    public var curveDepth: CGFloat
    
    public init(curveDepth: CGFloat = 32) {
        self.curveDepth = curveDepth
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - curveDepth))
        
        // Buat kurva organik halus di bagian bawah
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - curveDepth),
            control: CGPoint(x: rect.width / 2, y: rect.height + (curveDepth * 0.35))
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    CurvedHeaderShape()
        .fill(
            LinearGradient(
                colors: [Color(hex: "#10B981"), Color(hex: "#059669")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .frame(height: 180)
}

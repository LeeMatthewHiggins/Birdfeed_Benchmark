# Birdfeed Benchmark

A high-performance 2D rendering benchmark tool built with Flutter, demonstrating the power of Entity-Component-System (ECS) architecture using the [Dentity](https://pub.dev/packages/dentity) framework.

## 🚀 Live Demo

**[Try it now →](https://leematthewhiggins.github.io/Birdfeed_Benchmark/)**

## 📋 Overview

Birdfeed Benchmark compares rendering performance between:
- **Rive** - Vector graphics with native rendering
- **GIF** - Raster graphics with Flutter's CustomPaint

The benchmark renders thousands of animated particles with realistic physics, providing real-time FPS metrics to help you understand rendering performance characteristics.

## ✨ Features

- **ECS Architecture** - Clean, modular design using Dentity
- **Real-time FPS Tracking** - Live performance metrics with historical graphs
- **Adjustable Particle Count** - Test with 1 to 5000 particles
- **Drag & Drop** - Easy file loading for Rive (.riv) and GIF files
- **Physics Simulation** - Realistic bouncing particles with velocity and collision detection
- **Melos Monorepo** - Professional workspace setup for scalability

## 🏗️ Architecture

### ECS Components
- `PositionComponent` - Entity position (x, y)
- `VelocityComponent` - Movement velocity
- `BoundsComponent` - Collision boundaries
- `RiveContentComponent` - Rive artboard data
- `GifContentComponent` - GIF animation frames

### ECS Systems
- `MovementSystem` - Updates positions based on velocity
- `BoundsCollisionSystem` - Handles edge bouncing
- `RiveAnimationSystem` - Advances Rive animations
- `GifAnimationSystem` - Advances GIF frame animations

### Why ECS?

The Entity-Component-System pattern provides:
- **Separation of Concerns** - Data (components) separated from logic (systems)
- **Code Reuse** - Physics systems work for both Rive and GIF
- **Performance** - Cache-friendly iteration over components
- **Extensibility** - Easy to add new content types or behaviors

## 🛠️ Development

### Prerequisites
- Flutter SDK ^3.5.0
- Dart SDK ^3.5.0

### Setup

```bash
# Install dependencies
dart pub global activate melos
melos bootstrap

# Run the app
cd benchmark
flutter run -d chrome

# Analyze code
melos analyze

# Format code
melos format

# Run tests
melos test
```

### Project Structure

```
birdfeed_benchmark/
├── benchmark/              # Main Flutter application
│   ├── lib/
│   │   ├── ecs/           # ECS architecture
│   │   │   ├── components/    # Data components
│   │   │   ├── systems/       # Logic systems
│   │   │   └── benchmark_world.dart
│   │   ├── models/        # Data models
│   │   ├── screens/       # UI screens
│   │   ├── services/      # Business logic
│   │   └── widgets/       # Reusable widgets
├── melos.yaml            # Monorepo configuration
└── README.md
```

## 📊 Benchmarking Tips

1. **Start Small** - Begin with 100 particles to establish baseline
2. **Incremental Testing** - Increase count gradually to find performance limits
3. **Monitor FPS** - Watch for frame drops (target: 60 FPS)
4. **Compare Formats** - Test identical content in both Rive and GIF
5. **Device Variance** - Performance varies significantly across devices

## 🤝 Contributing

This is a reference implementation demonstrating ECS architecture and 2D rendering performance. Contributions that improve code clarity, performance, or documentation are welcome!

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- [Dentity](https://pub.dev/packages/dentity) - Excellent ECS framework by @LeeMatthewHiggins
- [Rive](https://rive.app) - Beautiful vector animations
- [Very Good Analysis](https://pub.dev/packages/very_good_analysis) - Strict linting rules

---

Built with ❤️ using Flutter and Dentity ECS

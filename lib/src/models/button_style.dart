/// Klarna Express Checkout Theme
enum KlarnaTheme {
  dark,
  light,
  auto,
}

/// Klarna Express Checkout Button Shape
enum KlarnaButtonShape {
  roundedRect,
  pill,
  rectangle,
}

/// Klarna Express Checkout Button Style
enum KlarnaButtonStyle {
  filled,
  outlined,
}

/// Klarna Environment
enum KlarnaEnvironment {
  production,
  sandbox,
}

/// Button styling configuration
class KlarnaButtonConfig {
  final KlarnaTheme theme;
  final KlarnaButtonShape shape;
  final KlarnaButtonStyle style;

  const KlarnaButtonConfig({
    this.theme = KlarnaTheme.dark,
    this.shape = KlarnaButtonShape.roundedRect,
    this.style = KlarnaButtonStyle.filled,
  });

  Map<String, dynamic> toMap() {
    return {
      'theme': theme.name,
      'shape': shape.name,
      'buttonStyle': style.name,
    };
  }
}

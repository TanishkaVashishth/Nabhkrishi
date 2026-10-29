/// Represents the current state of the farm boundary drawing workflow.
enum DrawingState {
  /// Map is idle. Normal map navigation (pan, zoom, rotate) is enabled.
  /// User can tap "Draw Farm Boundary" to begin.
  idle,

  /// Drawing mode is active. Map navigation is locked so touch events trace
  /// the field boundary instead of panning the map.
  drawing,

  /// Drawing has concluded. The boundary is closed and highlighted.
  /// The farmer can inspect the area, zoom/pan to review, tap "Redraw",
  /// or tap "Confirm Farm".
  reviewing,

  /// The boundary has been confirmed and submitted via the callback.
  confirmed,
}

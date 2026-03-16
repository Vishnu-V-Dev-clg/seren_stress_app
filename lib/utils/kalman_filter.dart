class KalmanFilter {
  double _estimate;
  double _errorEstimate;
  final double _q;
  final double _r;

  KalmanFilter({
    double initialEstimate = 0,
    double initialError = 1,
    double processNoise = 0.01,
    double measurementNoise = 0.5,
  }) : _estimate = initialEstimate,
       _errorEstimate = initialError,
       _q = processNoise,
       _r = measurementNoise;

  double update(double measurement) {
    _errorEstimate += _q;
    double k = _errorEstimate / (_errorEstimate + _r);
    _estimate = _estimate + k * (measurement - _estimate);
    _errorEstimate = (1 - k) * _errorEstimate;
    return _estimate;
  }
}

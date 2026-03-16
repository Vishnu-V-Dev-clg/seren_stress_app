class GsrConverter {
  static double adcToMicroSiemens(double adc) {
    if (adc == 0) return 0;
    double resistance = ((1023 - adc) * 10000) / adc;
    return (1 / resistance) * 1000000;
  }
}

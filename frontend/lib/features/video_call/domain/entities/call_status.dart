enum CallStatus {
  ringing,
  unavailable,
  rejected,
  accepted,
  cancelled;

  String get label => switch (this) {
        CallStatus.ringing => 'Sonnerie',
        CallStatus.unavailable => 'Patient indisponible',
        CallStatus.rejected => 'Appel refusé',
        CallStatus.accepted => 'Appel accepté',
        CallStatus.cancelled => 'Appel annulé',
      };

  bool get canEnterCall => this == CallStatus.accepted;
  bool get isTerminal =>
      this == CallStatus.unavailable ||
      this == CallStatus.rejected ||
      this == CallStatus.cancelled;
}

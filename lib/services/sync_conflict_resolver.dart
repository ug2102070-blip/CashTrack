class SyncConflictResolver {
  const SyncConflictResolver._();

  /// Last-update-wins with a deterministic tie-break: remote wins on equal
  /// timestamps, making all devices converge after a successful sync.
  static bool shouldApplyRemote({
    required String? remoteUpdatedAt,
    required String? localUpdatedAt,
  }) {
    final remote = remoteUpdatedAt == null
        ? null
        : DateTime.tryParse(remoteUpdatedAt)?.toUtc();
    final local = localUpdatedAt == null
        ? null
        : DateTime.tryParse(localUpdatedAt)?.toUtc();
    if (remote == null) return false;
    if (local == null) return true;
    return !remote.isBefore(local);
  }
}

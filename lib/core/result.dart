// ============================================================
// CORE RESULT TYPES
// Dipindah dari supabase_service.dart ke sini supaya bisa
// di-import secara independen tanpa menarik seluruh service.
// ============================================================

// -----------------------------------------------------------
//  AUTH RESULT
// -----------------------------------------------------------

class AuthResult {
  final bool success;
  final String? errorMessage;

  AuthResult._({required this.success, this.errorMessage});

  factory AuthResult.success() => AuthResult._(success: true);
  factory AuthResult.error(String msg) =>
      AuthResult._(success: false, errorMessage: msg);
}

// -----------------------------------------------------------
//  SUBMIT RESULT
// -----------------------------------------------------------

enum SubmitStatus { success, duplicate, error }

class SubmitResult {
  final SubmitStatus status;
  final int poin;

  SubmitResult._({required this.status, this.poin = 0});

  factory SubmitResult.success(int p) =>
      SubmitResult._(status: SubmitStatus.success, poin: p);
  factory SubmitResult.duplicate() =>
      SubmitResult._(status: SubmitStatus.duplicate);
  factory SubmitResult.error() =>
      SubmitResult._(status: SubmitStatus.error);
}

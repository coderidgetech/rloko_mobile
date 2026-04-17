/// Passed as [GoRouterState.extra] for `/otp-verification` (login OTP flow).
class LoginOtpRouteExtra {
  const LoginOtpRouteExtra({
    required this.phone,
    required this.returnTo,
  });

  final String phone;
  final String returnTo;
}

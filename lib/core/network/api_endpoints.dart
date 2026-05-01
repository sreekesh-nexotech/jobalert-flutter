/// Path templates for the JobAlert REST API. All paths are relative to the
/// base URL configured in `.env` (defaults to `/api/v1`).
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ──
  static const register = '/auth/register/';
  static const login = '/auth/login/';
  static const refresh = '/auth/refresh/';
  static const logout = '/auth/logout/';
  static const changePassword = '/auth/change-password/';
  static const otpSend = '/auth/otp/send/';
  static const otpVerify = '/auth/otp/verify/';
  static const passwordResetRequest = '/auth/password-reset/request/';
  static const passwordResetConfirm = '/auth/password-reset/confirm/';

  // ── Users ──
  static const me = '/users/me/';
  static const meAvatar = '/users/me/avatar/';
  static const meStats = '/users/me/stats/';
  static const meRequestDeletion = '/users/me/request-deletion/';
  static const userDetails = '/user-details/';

  // ── Home ──
  static const homeFeed = '/home/feed/';

  // ── Listings ──
  static const jobListings = '/job-listings/';
  static const bizListings = '/biz-listings/';
  static const canSubmit = '/listings/can-submit/';
  static String jobUpvote(String uid) => '/job-listings/$uid/upvote/';
  static String jobSave(String uid) => '/job-listings/$uid/save/';
  static String jobApply(String uid) => '/job-listings/$uid/apply/';
  static String jobView(String uid) => '/job-listings/$uid/view/';
  static String bizUpvote(String uid) => '/biz-listings/$uid/upvote/';
  static String bizSave(String uid) => '/biz-listings/$uid/save/';
  static String bizApply(String uid) => '/biz-listings/$uid/apply/';
  static String bizView(String uid) => '/biz-listings/$uid/view/';

  // ── Engagement ──
  static const comments = '/comments/';
  static String commentLike(String uid) => '/comments/$uid/like/';
  static const upvotes = '/upvotes/';
  static const savedListings = '/saved-listings/';
  static const pointsHistory = '/points/history/';

  // ── Subscriptions ──
  static const subscriptions = '/subscriptions/';

  // ── Notifications ──
  static const notifications = '/notifications/';
  static const notificationsUnread = '/notifications/unread-count/';
  static String notificationRead(String uid) => '/notifications/$uid/read/';
  static const notificationsMarkAll = '/notifications/mark-all-read/';

  // ── Filters / Reports / Files / Activity / Meta / Static ──
  static const filterPrefs = '/filter-prefs/';
  static const reports = '/reports/';
  static const files = '/files/';
  static const activityLogs = '/activity-logs/';
  static const appMeta = '/app-meta/';
  static String staticPage(String slug) => '/static-pages/$slug/';
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/EmailCheckResult.dart';
import '../models/User.dart';
import '../models/Address.dart';

class UserService {
  /// AuthController base URL
  final String _authBase;

  /// UserController base URL
  final String _userBase;
  final String _chatBase;

  UserService({
    // use 10.0.2.2 on Android emulator, localhost on web/desktop
    String authBase = 'https://usermanagementservice-production-697c.up.railway.app/api/auth',
    String userBase = 'https://usermanagementservice-production-697c.up.railway.app/api/user',
    String chatBase = 'https://usermanagementservice-production-697c.up.railway.app/api/complaint',

  })  : _authBase = authBase,
        _userBase = userBase,
        _chatBase = chatBase;


  // ─── AuthController ─────────────────────────────────────────────────────────
  Future<void> updateAvatar(String userId, String base64Image) async {
    final uri = Uri.parse('$_userBase/$userId/avatar');
    final res = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'avatarUrl': base64Image}),
    );
    if (res.statusCode != 204) {
      throw Exception('updateAvatar failed: ${res.statusCode}');
    }
  }

  Future<void> deleteAvatar(String userId) async {
    final uri = Uri.parse('$_userBase/$userId/avatar');
    final res = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'avatarUrl': ''}), // hoặc null tùy backend xử lý
    );

    if (res.statusCode != 204) {
      throw Exception('deleteAvatar failed: ${res.statusCode}');
    }
  }

  /// 1. Check if an email exists and whether it's verified
  Future<EmailCheckResult> checkEmailExists(String email) async {
    final uri = Uri.parse('$_authBase/check-email?email=$email');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return EmailCheckResult.fromJson(body);
    }

    throw Exception('checkEmailExists failed: ${res.statusCode}');
  }


  /// 2. Register a new user (with initial address)
  Future<void> register({
    required String email,
    required String fullName,
    required String password,
    String? receiverName,
    String? phone,
    String? addressLine,
    String? commune,
    String? district,
    String? city,
  }) async {
    final body = {
      'email': email,
      'fullName': fullName,
      'password': password,
      'receiverName': receiverName,
      'phone': phone,
      'addressLine': addressLine,
      'commune': commune,
      'district': district,
      'city': city,
    }..removeWhere((_, v) => v == null);

    final res = await http.post(
      Uri.parse('$_authBase/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw Exception('register failed: ${res.body}');
    }
  }
  Future<void> registerGuest({
    required String email,
    String? receiverName,
    String? phone,
    String? addressLine,
    String? commune,
    String? district,
    String? city,
  }) async {
    final String fullName = email.split('@').first;

    final body = {
      'email': email,
      'fullName': fullName,
      'password': 'guest123',
      'isVerifiedMail': false,   // xác định là guest
      'receiverName': receiverName,
      'phone': phone,
      'addressLine': addressLine,
      'commune': commune,
      'district': district,
      'city': city,
    }..removeWhere((_, v) => v == null);

    final res = await http.post(
      Uri.parse('$_authBase/register-guest'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw Exception('registerGuest failed: ${res.body}');
    }
  }

  /// 3. Login, returns JWT token
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_authBase/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as Map<String, dynamic>)['token'] as String;
    }
    throw Exception('login failed: ${res.body}');
  }

  /// 4. Fetch users via AuthController (DTO)
  Future<List<User>> fetchAuthUsers({String? excludeRole}) async {
    final uri = excludeRole != null && excludeRole.isNotEmpty
        ? Uri.parse('$_authBase/users?excludeRole=$excludeRole')
        : Uri.parse('$_authBase/users');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => User.fromJson(j)).toList();
    }
    throw Exception('fetchAuthUsers failed: ${res.statusCode}');
  }

  /// 5. Fetch a single user via AuthController
  Future<User> fetchAuthUserById(String id) async {
    final res = await http.get(Uri.parse('$_authBase/users/$id'));
    if (res.statusCode == 200) {
      return User.fromJson(jsonDecode(res.body));
    }
    throw Exception('fetchAuthUserById failed: ${res.statusCode}');
  }

  // ─── UserController ─────────────────────────────────────────────────────────

  /// 6. Fetch all users (full model)
  Future<List<User>> fetchUsers() async {
    final res = await http.get(Uri.parse(_userBase));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => User.fromJson(j)).toList();
    }
    throw Exception('fetchUsers failed: ${res.statusCode}');
  }

  /// 7. Fetch a single user by ID (full model)
  Future<User> fetchUserById(String id) async {
    final res = await http.get(Uri.parse('$_userBase/$id'));
    if (res.statusCode == 200) {
      return User.fromJson(jsonDecode(res.body));
    }
    throw Exception('fetchUserById failed: ${res.statusCode}');
  }

  /// Gửi OTP, trả về otp string
  Future<String> sendOtp(String email) async {
    final resp = await http.post(
      Uri.parse('$_authBase/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Gửi OTP thất bại (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['otp'] as String;
  }

  /// Đổi mật khẩu: email + newPassword
  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final resp = await http.post(
      Uri.parse('$_authBase/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'newPassword': newPassword,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception(
          'Reset password thất bại (${resp.statusCode}): ${resp.body}');
    }
  }
  /// Fetches the raw JSON map for the user.
  Future<Map<String, dynamic>> _fetchRawUserJson(String id) async {
    final res = await http.get(Uri.parse('$_userBase/$id'));
    if (res.statusCode != 200) {
      throw Exception('fetchRawUserJson failed: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Replaces the entire user document, preserving server-only fields.
  Future<void> updateUserFull(User edited) async {
    final url = Uri.parse('$_userBase/${edited.id}');

    // 1) Pull down the existing JSON (includes passwordHash, createdAt, updatedAt, etc.)
    final payload = await _fetchRawUserJson(edited.id!);

    // 2) Overwrite only the fields the UI allows editing:
    payload['fullName']    = edited.fullName;
    payload['phoneNumber'] = edited.phoneNumber;
    payload['avatarUrl']   = edited.avatarUrl;
    payload['gender']      = edited.gender;
    payload['dateOfBirth'] = edited.dateOfBirth?.toIso8601String();
    payload['status']      = edited.status;
    // role/email/loyaltyPoints/etc. are left untouched

    // 3) Replace addresses array wholesale:
    payload['addresses'] = edited.addresses.map((a) => a.toJson()).toList();

    // 4) Send back the full payload
    final res = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 204) {
      throw Exception('updateUserFull failed: ${res.statusCode}');
    }
  }

  /// 9. Delete a user
  Future<void> deleteUser(String id) async {
    final res = await http.delete(Uri.parse('$_userBase/$id'));
    if (res.statusCode != 204) {
      throw Exception('deleteUser failed: ${res.statusCode}');
    }
  }

  /// 10. Change status (Active/Suspended/Banned)
  Future<void> changeStatus(String id, String status) async {
    final res = await http.put(
      Uri.parse('$_userBase/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    if (res.statusCode != 204) {
      throw Exception('changeStatus failed: ${res.statusCode}');
    }
  }
  Future<void> banUser(String id) => changeStatus(id, 'Banned');
  Future<void> suspendUser(String id) => changeStatus(id, 'Suspended');
  Future<void> activateUser(String id) => changeStatus(id, 'Active');

  // ─── Address CRUD ────────────────────────────────────────────────────────────

  /// 11. Fetch all addresses of a user
  Future<List<Address>> fetchAddresses(String userId) async {
    final res = await http.get(Uri.parse('$_userBase/$userId/addresses'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => Address.fromJson(j)).toList();
    }
    throw Exception('fetchAddresses failed: ${res.statusCode}');
  }

  /// 12. Add a new address
  Future<void> addAddress(String userId, Address a) async {
    final res = await http.post(
      Uri.parse('$_userBase/$userId/addresses'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(a.toJson()),
    );
    if (res.statusCode != 204) {
      throw Exception('addAddress failed: ${res.statusCode}');
    }
  }

  /// 13. Update an address by index
  Future<void> updateAddress(String userId, int index, Address a) async {
    final res = await http.put(
      Uri.parse('$_userBase/$userId/addresses/$index'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(a.toJson()),
    );
    if (res.statusCode != 204) {
      throw Exception('updateAddress failed: ${res.statusCode}');
    }
  }

  /// 14. Delete an address by index
  Future<void> deleteAddress(String userId, int index) async {
    final res = await http.delete(
      Uri.parse('$_userBase/$userId/addresses/$index'),
    );
    if (res.statusCode != 204) {
      throw Exception('deleteAddress failed: ${res.statusCode}');
    }
  }
  Future<User> fetchUserByEmail(String email) async {
    final res = await http.get(Uri.parse('$_userBase/by-email?email=$email'));
    if (res.statusCode == 200) {
      return User.fromJson(jsonDecode(res.body));
    }
    throw Exception('fetchUserByEmail failed: ${res.statusCode}');
  }
  Future<List<Map<String, dynamic>>> getMessages(String user1Id, String user2Id) async {
    final url = Uri.parse('$_chatBase/chat?user1Id=$user1Id&user2Id=$user2Id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Lỗi khi tải tin nhắn');
    }
  }

  Future<void> sendMessage({
    required String userId,        // chính là receiverId
    required String senderId,      // chính là người gửi (ObjectId)
    required String content,
    required bool isFromCustomer,
    String? imageUrl,
  }) async {
    final body = {
      'senderId': senderId,
      'receiverId': userId,
      'content': content,
      'isFromCustomer': isFromCustomer,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };

    debugPrint('[DEBUG] Gửi tin nhắn body: ${jsonEncode(body)}');

    final response = await http.post(
      Uri.parse('$_chatBase/send'),  // <== thay vì /$userId/messages
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      debugPrint('[ERROR] Server response: ${response.body}');
      throw Exception('Gửi tin nhắn thất bại');
    }

  }

  Future<List<User>> getComplainingUsers() async {
    final response = await http.get(Uri.parse('$_userBase/complained'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load complaining users');
    }
  }
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$_authBase/change-password');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (resp.statusCode != 200) {
      // Nếu server trả về plain-text, resp.body sẽ là chuỗi lỗi bạn muốn show
      throw Exception(resp.body);
    }
    // nếu cần parse JSON thành object thì mới gọi jsonDecode ở đây
  }

}


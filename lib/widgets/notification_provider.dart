import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationProvider extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  StreamSubscription? _realtimeSub;

  // Call this once from main.dart or after login
  void startListening() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Initial fetch
    fetchUnreadCount();

    // Realtime: re-fetch whenever notifications table changes for this user
    _realtimeSub = supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .listen((data) {
          _unreadCount = data.where((n) => n['is_read'] == false).length;
          notifyListeners();
        });
  }

  void stopListening() {
    _realtimeSub?.cancel();
    _realtimeSub = null;
  }

  Future<void> fetchUnreadCount() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .eq('is_read', false);

    _unreadCount = data.length;
    notifyListeners();
  }

  void increment() {
    _unreadCount++;
    notifyListeners();
  }

  void clear() {
    _unreadCount = 0;
    notifyListeners();
  }

  void markAsReadLocal() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await fetchUnreadCount();
  }
}
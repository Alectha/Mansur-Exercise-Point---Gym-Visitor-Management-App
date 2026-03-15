import 'package:flutter/material.dart';
import '../models/member.dart';
import '../services/database_helper.dart';

class MemberProvider extends ChangeNotifier {
  List<Member> _members = [];
  bool _isLoading = false;

  List<Member> get members => _members;
  bool get isLoading => _isLoading;

  Future<void> loadMembers() async {
    _isLoading = true;
    notifyListeners();

    _members = await DatabaseHelper.instance.getAllMembers();

    _isLoading = false;
    notifyListeners();
  }

  Future<List<Member>> searchMembers(String name) async {
    if (name.isEmpty) return [];
    return await DatabaseHelper.instance.searchMembers(name);
  }

  Future<int> addMember(Member member) async {
    final id = await DatabaseHelper.instance.createMember(member);
    await loadMembers();
    return id;
  }

  Future<Member?> getMember(int id) async {
    return await DatabaseHelper.instance.getMember(id);
  }
}

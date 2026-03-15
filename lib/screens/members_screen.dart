import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/member.dart';
import '../providers/member_provider.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({Key? key}) : super(key: key);

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<MemberProvider>(context, listen: false).loadMembers();
    });
  }

  Color _getDaysRemainingColor(int days) {
    if (days > 7) return Colors.green;
    if (days >= 4) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Member'),
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<MemberProvider>(context, listen: false).loadMembers();
            },
          ),
        ],
      ),
      body: Consumer<MemberProvider>(
        builder: (context, memberProvider, child) {
          if (memberProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = memberProvider.members;

          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 100,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada member',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return _buildMemberCard(member);
            },
          );
        },
      ),
    );
  }

  Widget _buildMemberCard(Member member) {
    final daysRemaining = member.daysRemaining;
    final color = _getDaysRemainingColor(daysRemaining);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: const Color(0xFF2c3e50),
                  child: Text(
                    member.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2c3e50),
                        ),
                      ),
                      if (member.phone != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              member.phone!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        member.isExpired ? '0' : daysRemaining.toString(),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        'hari',
                        style: TextStyle(
                          fontSize: 9,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Bergabung',
                    _formatDate(member.joinDate),
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    'Kadaluarsa',
                    _formatDate(member.expireDate),
                    Icons.event_busy,
                  ),
                ),
              ],
            ),
            if (member.isExpired) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Member sudah kadaluarsa',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (member.isExpiringSoon) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Segera kadaluarsa',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2c3e50),
          ),
        ),
      ],
    );
  }
}

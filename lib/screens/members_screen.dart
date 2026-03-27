import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/member_provider.dart';
import '../models/member.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({Key? key}) : super(key: key);

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _searchController = TextEditingController();
  List<Member> _filteredMembers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMembers();
    });
  }

  Future<void> _loadMembers() async {
    final memberProvider = Provider.of<MemberProvider>(context, listen: false);
    await memberProvider.loadMembers();
    setState(() {
      _filteredMembers = memberProvider.members;
    });
  }

  void _filterMembers(String query) {
    final memberProvider = Provider.of<MemberProvider>(context, listen: false);
    if (query.isEmpty) {
      setState(() {
        _filteredMembers = memberProvider.members;
      });
      return;
    }
    setState(() {
      _filteredMembers = memberProvider.members
          .where((m) => m.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _showAddMemberModal(BuildContext context, [Member? existingMember]) {
    final nameController = TextEditingController(text: existingMember?.name);
    final phoneController = TextEditingController(text: existingMember?.phone);
    DateTime? expireDate = existingMember?.expireDate;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBuilder) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  existingMember == null ? 'Tambah Member Baru' : 'Edit Member',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Nama Lengkap',
                      hintStyle: const TextStyle(color: Color(0xFF757575)),
                      prefixIcon: const Icon(Icons.person_outline,
                          color: Color(0xFF4FC3F7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: phoneController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Nomor Telepon',
                      hintStyle: const TextStyle(color: Color(0xFF757575)),
                      prefixIcon: const Icon(Icons.phone_outlined,
                          color: Color(0xFF4FC3F7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                        context: context,
                        initialDate: expireDate ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 10)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF4FC3F7),
                                onPrimary: Colors.black,
                                surface: Color(0xFF2C2C2C),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        });
                    if (date != null) {
                      setStateBuilder(() => expireDate = date);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: Color(0xFF4FC3F7)),
                        const SizedBox(width: 12),
                        Text(
                          expireDate == null
                              ? 'Pilih Tanggal Kedaluwarsa'
                              : '${expireDate!.day}/${expireDate!.month}/${expireDate!.year}',
                          style: TextStyle(
                            color: expireDate == null
                                ? const Color(0xFF757575)
                                : Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty || expireDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Nama dan Tanggal Kedaluwarsa harus diisi'),
                              backgroundColor: Colors.red),
                        );
                        return;
                      }

                      final member = Member(
                        id: existingMember?.id,
                        name: nameController.text.trim(),
                        phone: phoneController.text.trim(),
                        joinDate: existingMember?.joinDate ?? DateTime.now(),
                        expireDate: expireDate!,
                        createdAt: existingMember?.createdAt ?? DateTime.now(),
                      );

                      final provider =
                          Provider.of<MemberProvider>(context, listen: false);
                      if (existingMember == null) {
                        await provider.addMember(member);
                      } else {
                        await provider.updateMember(member);
                      }

                      if (!mounted) return;
                      Navigator.pop(context);
                      _loadMembers(); // Refresh List
                    },
                    child: Text(
                        existingMember == null ? 'Simpan Member' : 'Perbarui',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Member member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Text('Hapus Member?', style: TextStyle(color: Colors.white)),
        content: Text('Apakah Anda yakin ingin menghapus ${member.name}?',
            style: const TextStyle(color: Color(0xFFAAAAAA))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Batal', style: TextStyle(color: Color(0xFF4FC3F7))),
          ),
          ElevatedButton(
            onPressed: () async {
              await Provider.of<MemberProvider>(context, listen: false)
                  .deleteMember(member.id!);
              if (!mounted) return;
              Navigator.pop(context);
              _loadMembers();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Daftar Member',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMemberModal(context),
        child: const Icon(Icons.person_add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2C2C2C)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Cari member...',
                  hintStyle: TextStyle(color: Color(0xFF757575)),
                  prefixIcon:
                      Icon(Icons.search_rounded, color: Color(0xFF757575)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: _filterMembers,
              ),
            ),
          ),
          Expanded(
            child: Consumer<MemberProvider>(
              builder: (context, provider, child) {
                if (_filteredMembers.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 80, color: Color(0xFF333333)),
                        SizedBox(height: 16),
                        Text('Belum ada member',
                            style: TextStyle(
                                fontSize: 16, color: Color(0xFF757575))),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _filteredMembers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final member = _filteredMembers[index];
                    final isExpired = member.isExpired;

                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2C2C2C)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isExpired
                                ? Colors.red.withOpacity(0.1)
                                : const Color(0xFF4FC3F7).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              member.name[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isExpired
                                    ? Colors.redAccent
                                    : const Color(0xFF4FC3F7),
                              ),
                            ),
                          ),
                        ),
                        title: Text(member.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (member.phone != null &&
                                  member.phone!.isNotEmpty)
                                Text('📱 ${member.phone}',
                                    style: const TextStyle(
                                        color: Color(0xFFAAAAAA),
                                        fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                isExpired
                                    ? 'Status: Kadaluarsa'
                                    : 'Aktif hingga: ${member.expireDate.day}/${member.expireDate.month}/${member.expireDate.year}',
                                style: TextStyle(
                                  color: isExpired
                                      ? Colors.redAccent
                                      : const Color(0xFF81D4FA),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: Color(0xFF4FC3F7)),
                              onPressed: () =>
                                  _showAddMemberModal(context, member),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              onPressed: () =>
                                  _showDeleteConfirmation(context, member),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class SupportHelpScreen extends StatefulWidget {
  const SupportHelpScreen({Key? key}) : super(key: key);

  @override
  State<SupportHelpScreen> createState() => _SupportHelpScreenState();
}

class _SupportHelpScreenState extends State<SupportHelpScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _msgController = TextEditingController();
  final _subjectController = TextEditingController();
  bool _isSending = false;
  bool _isLoadingTickets = true;
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoggedIn = false;

  final List<Map<String, String>> _faqs = [
    {
      'q': 'ما هي المنظومة الهجينة (Hybrid Solar System)؟',
      'a': 'هي منظومة تجمع بين طاقة الألواح الشمسية، والبطاريات للخزن، مع إمكانية السحب والتصدير للشبكة الوطنية أو المولد عند الحاجة.'
    },
    {
      'q': 'هل تضمنون البطاريات والألواح؟',
      'a': 'نعم، جميع المنتجات من المتاجر المعتمدة مشمولة بضمان الوكيل الرسمي (25 سنة للألواح و 5 سنوات لبطاريات الليثيوم).'
    },
    {
      'q': 'كيف يتم الشحن والتوصيل للمحافظات؟',
      'a': 'يتم التوصيل الميداني مع كادر فني متخصص لمعاينة الموقع والتركيب والتراخيص الرسمية في كافة المحافظات العراقية.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _msgController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    final isAuth = await AuthStorageService.isLoggedIn();
    setState(() => _isLoggedIn = isAuth);

    if (!isAuth) {
      setState(() => _isLoadingTickets = false);
      return;
    }

    try {
      final res = await ApiClient.getSupportTickets();
      if (res['success'] == true && res['data'] is List) {
        setState(() {
          _tickets = (res['data'] as List).cast<Map<String, dynamic>>();
          _isLoadingTickets = false;
        });
      } else {
        setState(() => _isLoadingTickets = false);
      }
    } catch (_) {
      setState(() => _isLoadingTickets = false);
    }
  }

  Future<void> _sendTicket() async {
    final msg = _msgController.text.trim();
    if (msg.isEmpty) {
      AppNotification.showError(context, 'يرجى كتابة تفاصيل استفسارك أو مشكلتك');
      return;
    }

    final isAuth = await AuthStorageService.isLoggedIn();
    if (!isAuth) {
      final loginSuccess = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const SolarLoginScreen()),
      );
      if (!mounted) return;
      if (loginSuccess != true) return;
    }

    setState(() => _isSending = true);

    final subject = _subjectController.text.trim().isEmpty ? 'بلاغ / استفسار عام' : _subjectController.text.trim();

    final res = await ApiClient.createSupportTicket(
      message: msg,
      subject: subject,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    if (res['success'] == true) {
      _msgController.clear();
      _subjectController.clear();
      AppNotification.showSuccess(context, 'تم إرسال تذكرة البلاغ والدعم الفني، وسيتواصل معك المهندس المختص 💬');
      _loadTickets();
      _tabController.animateTo(1); // Switch to tickets list
    } else {
      AppNotification.showError(context, res['message']?.toString() ?? 'فشل إرسال التذكرة');
    }
  }

  Widget _buildStatusBadge(String status) {
    String label = 'قيد المتابعة';
    Color color = Colors.orange;
    Color bg = Colors.orange.shade50;
    IconData icon = Icons.hourglass_top_rounded;

    if (status == 'resolved') {
      label = 'تم الحل بنجاح';
      color = Colors.green;
      bg = Colors.green.shade50;
      icon = Icons.check_circle_rounded;
    } else if (status == 'in_progress') {
      label = 'جاري المعالجة';
      color = Colors.blue;
      bg = Colors.blue.shade50;
      icon = Icons.sync_rounded;
    } else if (status == 'closed') {
      label = 'مغلقة';
      color = Colors.grey;
      bg = Colors.grey.shade100;
      icon = Icons.lock_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('الدعم الفني وتذاكر البلاغات والمشاكل'),
          backgroundColor: AppTheme.darkNavy,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryGold,
            indicatorWeight: 3,
            labelColor: AppTheme.primaryGold,
            unselectedLabelColor: Colors.white70,
            tabs: [
              const Tab(icon: Icon(Icons.support_agent_rounded, size: 18), text: 'إرسال تذكرة / استفسار'),
              Tab(icon: const Icon(Icons.confirmation_number_outlined, size: 18), text: 'سجل البلاغات والتذاكر (${_tickets.length})'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildNewTicketTab(),
            _buildMyTicketsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildNewTicketTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Channels Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkNavy,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppTheme.darkNavy.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.headset_mic_rounded, color: AppTheme.primaryGold, size: 36),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('مركز الدعم الفني والميداني 24/7', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('فريق هندسي متخصص للإجابة على استفسارات وحل مشكلات المنظومات.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => AppNotification.showInfo(context, 'الاتصال الفوري بالخط الساخن: 07701234567 📞'),
                        icon: const Icon(Icons.call_rounded, color: Colors.white, size: 18),
                        label: const Text('اتصال مباشر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => AppNotification.showInfo(context, 'فتح محادثة واتساب الدعم الهندسي المباشرة 🟢'),
                        icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                        label: const Text('واتساب الدعم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // FAQ Section
          const Text('الأسئلة الشائعة (FAQ)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
          const SizedBox(height: 10),
          ..._faqs.map((faq) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  title: Text(faq['q']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkNavy)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(faq['a']!, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 20),

          // Ticket Submission Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إرسال بلاغ أو تذكرة دعم فني جديدة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                const SizedBox(height: 12),
                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الموضوع (اختر مثلاً: مشكلة بالألواح / استفسار تركيب / ضمان)',
                    hintText: 'مثال: استفسار عن ربط الانفيرتر بالبطارية',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _msgController,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'اكتب تفاصيل سؤالك أو مشكلتك بالتفصيل هنا...'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendTicket,
                    icon: _isSending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white),
                    label: Text(_isSending ? 'جاري إرسال التذكرة...' : 'إرسال التذكرة وحفظها بالفاتورة', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTicketsTab() {
    if (!_isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_person_rounded, size: 64, color: AppTheme.primaryGold),
              const SizedBox(height: 16),
              const Text('تسجيل الدخول مطلوب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.darkNavy)),
              const SizedBox(height: 8),
              const Text('يرجى تسجيل الدخول لمتابعة سجل البلاغات والتذاكر السابقة وحالات المعالجة.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final loginSuccess = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const SolarLoginScreen()),
                  );
                  if (loginSuccess == true) {
                    _loadTickets();
                  }
                },
                icon: const Icon(Icons.login_rounded),
                label: const Text('تسجيل الدخول / حساب جديد'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoadingTickets) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
    }

    if (_tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('لا توجد تذاكر أو بلاغات سابقة', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
            const SizedBox(height: 6),
            const Text('يمكنك تقديم تذكرة جديدة من التبويب السابق في حال واجهتك أي مشكلة.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryGold,
      onRefresh: _loadTickets,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tickets.length,
        itemBuilder: (ctx, i) {
          final t = _tickets[i];
          final subject = t['subject']?.toString() ?? 'تذكرة دعم';
          final message = t['message']?.toString() ?? '';
          final responseText = t['response']?.toString();
          final status = t['status']?.toString() ?? 'open';
          final date = _formatDate(t['created_at']?.toString());

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy)),
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(date, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 10),
                Text(message, style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.4)),
                if (responseText != null && responseText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.engineering_rounded, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('رد المهندس الفني:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                              const SizedBox(height: 4),
                              Text(responseText, style: const TextStyle(fontSize: 12, color: AppTheme.darkNavy)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

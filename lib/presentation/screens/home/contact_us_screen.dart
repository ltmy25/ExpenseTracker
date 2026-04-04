import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static final Uri _githubUri = Uri.parse('https://github.com/ltmy25');
  static final Uri _facebookUri = Uri.parse('https://facebook.com/ltmy25');
  static final Uri _linkedinUri = Uri.parse('https://linkedin.com/in/ltmy25');
  static final Uri _emailUri = Uri(
    scheme: 'mailto',
    path: 'ltmy25.dev@gmail.com',
    query: 'subject=ExpenseTracker%20Support',
  );

  Future<void> _openUri(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở liên kết. Vui lòng thử lại.')),
      );
    }
  }

  Future<void> _copyContact(BuildContext context, String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã sao chép $label')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liên hệ chúng tôi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 6, 8, 14),
            child: Text(
              'Liên hệ với chúng tôi nếu bạn gặp bất kỳ vấn đề nào hoặc có góp ý để cải thiện ứng dụng.',
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.code_rounded),
              title: const Text('GitHub'),
              subtitle: const Text('github.com/ltmy25'),
              trailing: IconButton(
                tooltip: 'Sao chép link',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => _copyContact(context, _githubUri.toString(), 'link GitHub'),
              ),
              onTap: () => _openUri(context, _githubUri),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.facebook_rounded),
              title: const Text('Facebook'),
              subtitle: const Text('facebook.com/ltmy25'),
              trailing: IconButton(
                tooltip: 'Sao chép link',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => _copyContact(context, _facebookUri.toString(), 'link Facebook'),
              ),
              onTap: () => _openUri(context, _facebookUri),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.business_center_rounded),
              title: const Text('LinkedIn'),
              subtitle: const Text('linkedin.com/in/ltmy25'),
              trailing: IconButton(
                tooltip: 'Sao chép link',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => _copyContact(context, _linkedinUri.toString(), 'link LinkedIn'),
              ),
              onTap: () => _openUri(context, _linkedinUri),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('E-mail'),
              subtitle: const Text('ltmy25.dev@gmail.com'),
              trailing: IconButton(
                tooltip: 'Sao chép email',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => _copyContact(context, 'ltmy25.dev@gmail.com', 'email'),
              ),
              onTap: () => _openUri(context, _emailUri),
            ),
          ),
        ],
      ),
    );
  }
}

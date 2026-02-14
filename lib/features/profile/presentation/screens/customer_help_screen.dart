import 'package:flutter/material.dart';
import 'package:eco_market/core/constants/app_colors.dart';

/// Customer Help Screen placeholder
class CustomerHelpScreen extends StatelessWidget {
  const CustomerHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Yardım',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FAQ Section
          _buildHelpSection(
            title: 'Sık Sorulan Sorular',
            items: [
              _HelpItem(
                question: 'Nasıl sipariş veririm?',
                answer:
                    'Ana sayfadan bir market seçin, ürünleri inceleyin ve rezerve edin.',
              ),
              _HelpItem(
                question: 'Ödeme nasıl yapılır?',
                answer: 'Ödeme markette teslim alırken yapılır.',
              ),
              _HelpItem(
                question: 'Rezervasyonumu nasıl iptal ederim?',
                answer: 'Rezervasyonlarım sayfasından iptal edebilirsiniz.',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Contact Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bize Ulaşın',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildContactTile(
                  icon: Icons.email_outlined,
                  label: 'E-posta',
                  value: 'destek@ecomarket.com',
                ),
                const Divider(height: 24),
                _buildContactTile(
                  icon: Icons.phone_outlined,
                  label: 'Telefon',
                  value: '+90 555 123 4567',
                ),
                const Divider(height: 24),
                _buildContactTile(
                  icon: Icons.chat_bubble_outline,
                  label: 'Canlı Destek',
                  value: 'Yakında',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryGreenLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.eco, color: AppColors.primaryGreen, size: 48),
                SizedBox(height: 12),
                Text(
                  'EcoMarket',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sürüm 1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection({
    required String title,
    required List<_HelpItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ExpansionPanelList.radio(
            elevation: 0,
            expandedHeaderPadding: EdgeInsets.zero,
            children: items.asMap().entries.map((entry) {
              final item = entry.value;
              return ExpansionPanelRadio(
                value: entry.key,
                headerBuilder: (context, isExpanded) {
                  return ListTile(
                    leading: const Icon(
                      Icons.help_outline,
                      color: AppColors.primaryGreen,
                    ),
                    title: Text(
                      item.question,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                },
                body: Padding(
                  padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                  child: Text(
                    item.answer,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryGreenLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HelpItem {
  final String question;
  final String answer;

  _HelpItem({required this.question, required this.answer});
}

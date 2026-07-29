import 'package:flutter/material.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({required this.isBangla, super.key});

  final bool isBangla;

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

enum _LearnCategory { all, nutrition, activity, sleep, habits }

class _LearnArticle {
  const _LearnArticle({
    required this.category,
    required this.icon,
    required this.titleEn,
    required this.titleBn,
    required this.summaryEn,
    required this.summaryBn,
    required this.pointsEn,
    required this.pointsBn,
    required this.sourceLabel,
  });

  final _LearnCategory category;
  final IconData icon;
  final String titleEn;
  final String titleBn;
  final String summaryEn;
  final String summaryBn;
  final List<String> pointsEn;
  final List<String> pointsBn;
  final String sourceLabel;
}

class _LearnScreenState extends State<LearnScreen> {
  _LearnCategory _selectedCategory = _LearnCategory.all;

  static const List<_LearnArticle> _articles = [
    _LearnArticle(
      category: _LearnCategory.nutrition,
      icon: Icons.restaurant_outlined,
      titleEn: 'Build a balanced eating pattern',
      titleBn: 'সুষম খাবারের অভ্যাস গড়ে তুলুন',
      summaryEn:
          'Healthy eating is the pattern across the day and week—not one perfect meal.',
      summaryBn:
          'স্বাস্থ্যকর খাবার মানে একটি নিখুঁত বেলা নয়; পুরো দিন ও সপ্তাহের খাবারের ধরন গুরুত্বপূর্ণ।',
      pointsEn: [
        'Choose a variety of vegetables, fruit, pulses, wholegrains, nuts, and suitable protein foods.',
        'A general adult target is at least 400 g, or about 5 portions, of fruit and vegetables a day.',
        'Keep foods high in salt, free sugars, saturated fat, and trans fat less frequent.',
        'Use familiar local foods and adjust portions to your goal, budget, and appetite.',
      ],
      pointsBn: [
        'বিভিন্ন ধরনের শাকসবজি, ফল, ডাল, পূর্ণশস্য, বাদাম এবং উপযুক্ত আমিষের উৎস বেছে নিন।',
        'প্রাপ্তবয়স্কদের জন্য সাধারণ লক্ষ্য হলো দিনে অন্তত ৪০০ গ্রাম বা প্রায় ৫ ভাগ ফল ও শাকসবজি।',
        'বেশি লবণ, মুক্ত চিনি, সম্পৃক্ত চর্বি ও ট্রান্স চর্বিযুক্ত খাবার কম ঘনঘন খান।',
        'নিজের লক্ষ্য, বাজেট ও ক্ষুধা অনুযায়ী পরিচিত স্থানীয় খাবার এবং পরিমাণ বেছে নিন।',
      ],
      sourceLabel: 'WHO',
    ),
    _LearnArticle(
      category: _LearnCategory.nutrition,
      icon: Icons.water_drop_outlined,
      titleEn: 'Make hydration simple',
      titleBn: 'পানি পান সহজ ও নিয়মিত করুন',
      summaryEn:
          'Use water as the default drink and adjust intake for heat, activity, and illness.',
      summaryBn:
          'পানিকে প্রধান পানীয় হিসেবে রাখুন এবং গরম আবহাওয়া, শারীরিক কার্যকলাপ ও অসুস্থতা অনুযায়ী পরিমাণ বাড়ান।',
      pointsEn: [
        'Six to eight cups or glasses of fluid a day is a general guide for many adults.',
        'You may need more in hot weather, during long activity, pregnancy, breastfeeding, or illness.',
        'Water, lower-sugar drinks, tea, and coffee can contribute to fluid intake.',
        'Keep sugary soft drinks occasional because they add sugar and calories quickly.',
      ],
      pointsBn: [
        'অনেক প্রাপ্তবয়স্কের জন্য দিনে ৬–৮ কাপ বা গ্লাস তরল একটি সাধারণ নির্দেশনা।',
        'গরম আবহাওয়া, দীর্ঘ সময় শারীরিক কার্যকলাপ, গর্ভাবস্থা, স্তন্যদান বা অসুস্থতায় বেশি প্রয়োজন হতে পারে।',
        'পানি, কম চিনিযুক্ত পানীয়, চা ও কফি দৈনিক তরল গ্রহণে যোগ হতে পারে।',
        'কোমল পানীয় মাঝে মাঝে রাখুন, কারণ এতে দ্রুত চিনি ও ক্যালরি যোগ হয়।',
      ],
      sourceLabel: 'NHS',
    ),
    _LearnArticle(
      category: _LearnCategory.activity,
      icon: Icons.directions_walk_outlined,
      titleEn: 'Start with movement you can repeat',
      titleBn: 'যে শারীরিক কাজ নিয়মিত করা যায়, সেটি দিয়ে শুরু করুন',
      summaryEn:
          'Small, repeatable sessions are more useful than an intense plan you cannot maintain.',
      summaryBn:
          'যে কঠিন পরিকল্পনা ধরে রাখা যায় না, তার চেয়ে ছোট ও নিয়মিত অনুশীলন বেশি কার্যকর।',
      pointsEn: [
        'Adults should work towards at least 150 minutes of moderate activity each week.',
        'An alternative is 75 minutes of vigorous activity, or a suitable combination.',
        'Include muscle-strengthening activity on at least 2 days each week.',
        'Break activity into smaller sessions when that fits your schedule better.',
      ],
      pointsBn: [
        'প্রাপ্তবয়স্কদের সপ্তাহে অন্তত ১৫০ মিনিট মাঝারি মাত্রার শারীরিক কার্যকলাপের দিকে ধীরে ধীরে এগোনো উচিত।',
        'বিকল্পভাবে ৭৫ মিনিট জোরালো শারীরিক কার্যকলাপ বা উপযুক্ত সমন্বয় করা যায়।',
        'সপ্তাহে অন্তত ২ দিন পেশি শক্তিশালী করার ব্যায়াম রাখুন।',
        'সময়সূচির সঙ্গে মানালে শারীরিক কার্যকলাপ ছোট ছোট সময়ে ভাগ করুন।',
      ],
      sourceLabel: 'CDC',
    ),
    _LearnArticle(
      category: _LearnCategory.activity,
      icon: Icons.stairs_outlined,
      titleEn: 'Add movement to ordinary days',
      titleBn: 'দৈনন্দিন কাজের মধ্যে নড়াচড়া যোগ করুন',
      summaryEn:
          'Walking, stairs, active chores, and short movement breaks all count.',
      summaryBn:
          'হাঁটা, সিঁড়ি, সক্রিয় ঘরের কাজ এবং ছোট বিরতিতে নড়াচড়া—সবই কাজে আসে।',
      pointsEn: [
        'Walk before or after a meal when it feels comfortable.',
        'Stand up and move briefly after long periods of sitting.',
        'Choose a pace that raises breathing while still allowing conversation for moderate intensity.',
        'Increase duration or intensity gradually to reduce injury risk.',
      ],
      pointsBn: [
        'স্বস্তি থাকলে খাবারের আগে বা পরে কিছুক্ষণ হাঁটুন।',
        'দীর্ঘ সময় বসে থাকলে মাঝে মাঝে উঠে অল্প নড়াচড়া করুন।',
        'মাঝারি মাত্রায় শ্বাস কিছুটা বাড়বে, কিন্তু কথা বলা সম্ভব থাকবে।',
        'আঘাতের ঝুঁকি কমাতে সময় বা মাত্রা ধীরে ধীরে বাড়ান।',
      ],
      sourceLabel: 'CDC',
    ),
    _LearnArticle(
      category: _LearnCategory.sleep,
      icon: Icons.bedtime_outlined,
      titleEn: 'Protect a regular sleep routine',
      titleBn: 'নিয়মিত ঘুমের অভ্যাস বজায় রাখুন',
      summaryEn:
          'Sleep duration and sleep quality both matter for daily wellbeing.',
      summaryBn:
          'দৈনন্দিন সুস্থতার জন্য ঘুমের সময় এবং ঘুমের মান—দুটোই গুরুত্বপূর্ণ।',
      pointsEn: [
        'Adults aged 18–60 generally need 7 or more hours of sleep each day.',
        'Try to keep sleep and wake times reasonably consistent.',
        'Use a calm wind-down routine and reduce bright light or screens before bed.',
        'Repeated waking or feeling tired after enough hours can suggest poor sleep quality.',
      ],
      pointsBn: [
        '১৮–৬০ বছর বয়সী প্রাপ্তবয়স্কদের সাধারণত প্রতিদিন ৭ ঘণ্টা বা তার বেশি ঘুম প্রয়োজন।',
        'ঘুমানো ও জাগার সময় যতটা সম্ভব নিয়মিত রাখুন।',
        'ঘুমের আগে শান্ত অভ্যাস গড়ে তুলুন এবং উজ্জ্বল আলো বা পর্দা দেখা কমান।',
        'পর্যাপ্ত সময় ঘুমিয়েও বারবার জাগা বা ক্লান্ত থাকা খারাপ ঘুমের মানের লক্ষণ হতে পারে।',
      ],
      sourceLabel: 'CDC • NHS',
    ),
    _LearnArticle(
      category: _LearnCategory.sleep,
      icon: Icons.nightlight_outlined,
      titleEn: 'Know when sleep needs attention',
      titleBn: 'কখন ঘুমের সমস্যায় সহায়তা প্রয়োজন বুঝুন',
      summaryEn:
          'Persistent sleep problems are worth discussing with a qualified health professional.',
      summaryBn:
          'দীর্ঘদিন ঘুমের সমস্যা থাকলে যোগ্য স্বাস্থ্যকর্মীর পরামর্শ নেওয়া ভালো।',
      pointsEn: [
        'Seek advice if sleep problems continue and affect daily function.',
        'Loud snoring, breathing pauses, or severe daytime sleepiness should not be ignored.',
        'Pain, stress, medicines, and health conditions can all affect sleep.',
        'Do not start sleep medicines or supplements without appropriate advice.',
      ],
      pointsBn: [
        'ঘুমের সমস্যা চলতে থাকলে এবং দৈনন্দিন কাজে প্রভাব ফেললে পরামর্শ নিন।',
        'জোরে নাক ডাকা, শ্বাস বন্ধ হওয়ার মতো বিরতি বা দিনে তীব্র ঘুমঘুম ভাব অবহেলা করবেন না।',
        'ব্যথা, মানসিক চাপ, ওষুধ এবং বিভিন্ন স্বাস্থ্যসমস্যা ঘুমে প্রভাব ফেলতে পারে।',
        'উপযুক্ত পরামর্শ ছাড়া ঘুমের ওষুধ বা সম্পূরক শুরু করবেন না।',
      ],
      sourceLabel: 'CDC • NHS',
    ),
    _LearnArticle(
      category: _LearnCategory.habits,
      icon: Icons.track_changes_outlined,
      titleEn: 'Change one small behaviour at a time',
      titleBn: 'একবারে একটি ছোট অভ্যাস পরিবর্তন করুন',
      summaryEn:
          'A clear and easy action is more likely to become part of your routine.',
      summaryBn: 'পরিষ্কার ও সহজ কাজ নিয়মিত অভ্যাসের অংশ হওয়ার সম্ভাবনা বেশি।',
      pointsEn: [
        'Choose one action that is small enough to repeat on busy days.',
        'Attach it to an existing cue, such as after breakfast or before a shower.',
        'Track completion rather than trying to feel motivated every day.',
        'After the habit feels stable, increase it gradually or add another one.',
      ],
      pointsBn: [
        'এমন একটি কাজ বেছে নিন যা ব্যস্ত দিনেও করা সম্ভব।',
        'নাশতার পরে বা গোসলের আগে—এমন পরিচিত সংকেতের সঙ্গে অভ্যাসটি যুক্ত করুন।',
        'প্রতিদিন উৎসাহের অপেক্ষা না করে কাজটি সম্পন্ন হয়েছে কি না লিখে রাখুন।',
        'অভ্যাসটি স্থির হলে ধীরে ধীরে বাড়ান বা আরেকটি অভ্যাস যোগ করুন।',
      ],
      sourceLabel: 'Behaviour-change principle',
    ),
    _LearnArticle(
      category: _LearnCategory.habits,
      icon: Icons.replay_outlined,
      titleEn: 'Resume after a missed day',
      titleBn: 'একদিন বাদ গেলে আবার শুরু করুন',
      summaryEn:
          'A missed day is a normal interruption, not proof that the plan failed.',
      summaryBn:
          'একদিন বাদ যাওয়া স্বাভাবিক বিরতি; এতে পুরো পরিকল্পনা ব্যর্থ হয় না।',
      pointsEn: [
        'Restart at the next practical opportunity instead of waiting for a perfect Monday.',
        'Review what made the action difficult and make the next step easier.',
        'Look at the weekly pattern rather than judging one day.',
        'Use supportive language with yourself and focus on the next action.',
      ],
      pointsBn: [
        'নিখুঁত কোনো দিনের অপেক্ষা না করে পরবর্তী বাস্তবসম্মত সুযোগেই আবার শুরু করুন।',
        'কী কারণে কাজটি কঠিন হয়েছিল দেখুন এবং পরের ধাপ আরও সহজ করুন।',
        'একদিনকে বিচার না করে পুরো সপ্তাহের ধারা দেখুন।',
        'নিজের সঙ্গে সহায়ক ভাষায় কথা বলুন এবং পরবর্তী কাজে মন দিন।',
      ],
      sourceLabel: 'Behaviour-change principle',
    ),
  ];

  List<_LearnArticle> get _visibleArticles {
    if (_selectedCategory == _LearnCategory.all) {
      return _articles;
    }

    return _articles
        .where((article) => article.category == _selectedCategory)
        .toList(growable: false);
  }

  String _categoryLabel(_LearnCategory category) {
    switch (category) {
      case _LearnCategory.all:
        return widget.isBangla ? 'সব' : 'All';
      case _LearnCategory.nutrition:
        return widget.isBangla ? 'পুষ্টি' : 'Nutrition';
      case _LearnCategory.activity:
        return widget.isBangla ? 'শারীরিক কার্যকলাপ' : 'Activity';
      case _LearnCategory.sleep:
        return widget.isBangla ? 'ঘুম' : 'Sleep';
      case _LearnCategory.habits:
        return widget.isBangla ? 'অভ্যাস' : 'Habits';
    }
  }

  IconData _categoryIcon(_LearnCategory category) {
    switch (category) {
      case _LearnCategory.all:
        return Icons.grid_view_outlined;
      case _LearnCategory.nutrition:
        return Icons.restaurant_outlined;
      case _LearnCategory.activity:
        return Icons.directions_run;
      case _LearnCategory.sleep:
        return Icons.bedtime_outlined;
      case _LearnCategory.habits:
        return Icons.check_circle_outline;
    }
  }

  void _openArticle(_LearnArticle article) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return _LearnArticleScreen(
            article: article,
            isBangla: widget.isBangla,
            categoryLabel: _categoryLabel(article.category),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final articles = _visibleArticles;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.isBangla ? 'শিখুন' : 'Learn'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              widget.isBangla
                  ? 'ছোট ছোট স্বাস্থ্য পাঠ'
                  : 'Small health lessons',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isBangla
                  ? 'পুষ্টি, শারীরিক কার্যকলাপ, ঘুম ও অভ্যাস নিয়ে সংক্ষিপ্ত এবং ব্যবহারযোগ্য তথ্য।'
                  : 'Short, practical guidance about nutrition, activity, sleep, and habits.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _LearnCategory.values
                    .map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(_categoryIcon(category), size: 18),
                          label: Text(_categoryLabel(category)),
                          selected: _selectedCategory == category,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 18),
            ...articles.map((article) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LearnArticleCard(
                  article: article,
                  isBangla: widget.isBangla,
                  categoryLabel: _categoryLabel(article.category),
                  onOpen: () => _openArticle(article),
                ),
              );
            }),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.medical_information_outlined,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isBangla
                          ? 'এগুলো প্রাপ্তবয়স্কদের জন্য সাধারণ শিক্ষা। গর্ভাবস্থা, বয়স ১৮ বছরের কম, দীর্ঘমেয়াদি রোগ, ওষুধ ব্যবহার বা বিশেষ খাদ্যচাহিদা থাকলে যোগ্য স্বাস্থ্যকর্মীর পরামর্শ নিন।'
                          : 'This is general adult education. Seek qualified advice for pregnancy, age under 18, chronic conditions, medicines, or special dietary needs.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearnArticleCard extends StatelessWidget {
  const _LearnArticleCard({
    required this.article,
    required this.isBangla,
    required this.categoryLabel,
    required this.onOpen,
  });

  final _LearnArticle article;
  final bool isBangla;
  final String categoryLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = isBangla ? article.titleBn : article.titleEn;
    final summary = isBangla ? article.summaryBn : article.summaryEn;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  article.icon,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${isBangla ? 'তথ্যসূত্র' : 'Based on'}: ${article.sourceLabel}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 15,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearnArticleScreen extends StatelessWidget {
  const _LearnArticleScreen({
    required this.article,
    required this.isBangla,
    required this.categoryLabel,
  });

  final _LearnArticle article;
  final bool isBangla;
  final String categoryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = isBangla ? article.titleBn : article.titleEn;
    final summary = isBangla ? article.summaryBn : article.summaryEn;
    final points = isBangla ? article.pointsBn : article.pointsEn;

    return Scaffold(
      appBar: AppBar(title: Text(categoryLabel)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                article.icon,
                size: 32,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              summary,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            ...points.map((point) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 21,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          point,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '${isBangla ? 'তথ্যসূত্র' : 'Information basis'}: ${article.sourceLabel}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isBangla
                  ? 'এই তথ্য সাধারণ শিক্ষা; এটি ব্যক্তিগত রোগনির্ণয় বা চিকিৎসা পরিকল্পনা নয়।'
                  : 'This is general education, not a personal diagnosis or treatment plan.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

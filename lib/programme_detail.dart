import 'package:flutter/material.dart';

import 'cms/editable.dart';
import 'cms/site_content.dart';
import 'pages.dart' show services, serviceImages;
import 'shared/motion.dart';
import 'shared/ui_kit.dart';
import 'theme.dart';
import 'widgets.dart';

/// Address of a programme's own page, e.g. `/programme/leadership-communication`.
String programmeRoute(String title) => '/programme/${SitePage.slugify(title)}';

/// What each focus area covers. Every line can be changed by the admin in
/// edit mode.
const programmeDetails = <String, (List<String>, String)>{
  'Emotional Intelligence & Mindfulness': (
    [
      'Recognise emotions and triggers in yourself and others',
      'Respond to pressure with calm, deliberate choices',
      'Use simple mindfulness practices during the working day',
      'Build empathy into everyday conversations',
    ],
    'Staff at every level, especially teams working under pressure or through change.',
  ),
  'Leadership & Communication': (
    [
      'Lead with empathy while keeping standards clear',
      'Give and receive feedback that builds trust',
      'Communicate decisions clearly across teams',
      'Influence and motivate without relying on authority',
    ],
    'New and experienced managers, supervisors and team leads.',
  ),
  'Organization Well-being Assessment': (
    [
      'Understand how people across the organisation are really doing',
      'Identify the pressures that affect performance and retention',
      'Turn findings into a practical, prioritised action plan',
      'Measure progress over time',
    ],
    'HR teams and leaders who want evidence before choosing an intervention.',
  ),
  'Team Building & Effectiveness': (
    [
      'Strengthen trust and psychological safety',
      'Improve collaboration and problem-solving',
      'Agree on shared goals and ways of working',
      'Turn team strengths into everyday habits',
    ],
    'Intact teams, newly formed teams and cross-functional groups.',
  ),
  'CSR & ESG': (
    [
      'Connect staff with meaningful community initiatives',
      'Align activities with your organisation\'s values',
      'Build pride, engagement and a sense of purpose',
      'Report outcomes in a clear, simple way',
    ],
    'Organisations planning CSR days or building their ESG commitments.',
  ),
  'Customized Programmes': (
    [
      'Start from a needs assessment of your people',
      'Combine workshops, coaching and follow-up sessions',
      'Fit timing and delivery to your team\'s schedule',
      'Review results together at the end',
    ],
    'Organisations with specific goals that a standard programme does not cover.',
  ),
};

class ProgrammeDetailPage extends StatelessWidget {
  const ProgrammeDetailPage({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context) {
    final match = services.where((s) => SitePage.slugify(s.$1) == slug);
    if (match.isEmpty) {
      return PageWidth(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            children: [
              Text('Programme not found', style: Tok.heading(28)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => go(context, '/services'),
                child: const Text('See all programmes'),
              ),
            ],
          ),
        ),
      );
    }
    final (title, icon, summary) = match.first;
    final (outcomes, audience) = programmeDetails[title] ?? (const [], '');
    final key = 'programme.$slug';
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final others = services.where((s) => s.$1 != title).toList();

    final about = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Tok.accent,
            borderRadius: BorderRadius.circular(Tok.rMd),
          ),
          child: Icon(icon, color: Tok.brandDeep),
        ),
        const SizedBox(height: Tok.s4),
        CmsText(
          '$key.summary',
          summary,
          multiline: true,
          label: 'Programme summary',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.5),
        ),
        const SizedBox(height: Tok.s6),
        Text('What your team will gain', style: Tok.heading(22)),
        const SizedBox(height: Tok.s3),
        for (final (i, o) in outcomes.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Tok.brand,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CmsText(
                    '$key.outcome${i + 1}',
                    o,
                    label: 'Outcome ${i + 1}',
                    style: const TextStyle(height: 1.45, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: Tok.s5),
        Text('Who it is for', style: Tok.heading(22)),
        const SizedBox(height: Tok.s2),
        CmsText(
          '$key.audience',
          audience,
          multiline: true,
          label: 'Who it is for',
          style: const TextStyle(color: Tok.textMuted, height: 1.5),
        ),
      ],
    );

    final action = InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Bring this to your team', style: Tok.heading(20)),
          const SizedBox(height: Tok.s2),
          const Text(
            'Run it as a workshop, a coaching series or part of a longer programme. Tell us about your team and we will suggest a format.',
            style: TextStyle(color: Tok.textMuted, height: 1.5),
          ),
          const SizedBox(height: Tok.s4),
          FilledButton.icon(
            onPressed: () =>
                go(context, '/contact', arguments: 'Corporate Training'),
            icon: const Icon(Icons.mail_outline, size: 18),
            label: const Text('Enquire about this programme'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => go(context, '/upskilling'),
            icon: const Icon(Icons.school_outlined, size: 18),
            label: const Text('Browse related online courses'),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ImageBanner(
          image: serviceImages[title] ?? 'assets/images/stock/planning.jpg',
          eyebrow: 'Corporate programme',
          title: title,
          subtitle: summary,
          height: 300,
        ),
        PageWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Tok.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => go(context, '/services'),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('All programmes'),
                  ),
                ),
                const SizedBox(height: Tok.s4),
                Reveal(
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: about),
                            const SizedBox(width: 40),
                            Expanded(flex: 2, child: action),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [about, const SizedBox(height: 28), action],
                        ),
                ),
                const SizedBox(height: Tok.s8),
                Text('Other programmes', style: Tok.heading(24)),
                const SizedBox(height: Tok.s4),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final o in others)
                      ActionChip(
                        avatar: Icon(o.$2, size: 18, color: Tok.brand),
                        label: Text(o.$1),
                        onPressed: () => go(context, programmeRoute(o.$1)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

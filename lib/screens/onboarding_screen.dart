import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../widgets/neuro_button.dart';
import 'main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      title: 'Prótese Cognitiva',
      description: 'Externalize sua memória e reduza a fadiga de decisão.',
      icon: Icons.psychology_alt,
    ),
    _OnboardingSlide(
      title: 'Foco na Execução',
      description:
          'Cronômetros e roteiros passo a passo para garantir que você faça, não apenas planeje.',
      icon: Icons.timer,
    ),
    _OnboardingSlide(
      title: 'Baseado em Ciência',
      description:
          'Protocolos desenhados para sustentação de hábitos por 6 meses.',
      icon: Icons.science,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleFinish() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('hasSeenOnboarding', true);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          slide.icon,
                          size: AppSizes.iconHero,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    width: _currentIndex == index
                        ? AppSizes.indicatorActive
                        : AppSizes.indicator,
                    height: AppSizes.indicator,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? AppColors.primary
                          : AppColors.outline,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_currentIndex == _slides.length - 1)
                SizedBox(
                  width: double.infinity,
                  child: NeuroButton(
                    label: 'COMEÇAR JORNADA',
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _handleFinish,
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      _pageController.animateToPage(
                        _slides.length - 1,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                      );
                    },
                    child: const Text('Pular'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

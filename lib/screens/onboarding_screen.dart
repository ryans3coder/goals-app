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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                          size: 96,
                          color: AppTheme.wine,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
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
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          _currentIndex == index ? AppTheme.wine : Colors.white30,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_currentIndex == _slides.length - 1)
                SizedBox(
                  width: double.infinity,
                  child: NeuroButton(
                    label: 'COMEÇAR JORNADA',
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
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

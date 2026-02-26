import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PromoBanner extends StatelessWidget {
  final Color secondaryColor;
  final VoidCallback? onTap;

  const PromoBanner({super.key, required this.secondaryColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: const DecorationImage(
            image: NetworkImage(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuCQzi6FvdVl_U9nntl9LO9AlHWPqrBeua7UiVsIlTtXcPLLDoYcIg-cMd50qaExmuoohRIgKdmGxjOwVK3vplRHVh6ezct2feyGwnm_SqLHVMg9vuvQ8N531TnLgUxxv5gbkXDtsoQV8JpfqAZlWh7HAobrMpDTeF8biHKOb9TnUJk-wo1WVCdBNa2ISCKnbgISEHiA5oNamWF5AMWiMsyCLQEKpLjJCk_qVBb87JnYILGmSbOPwuPBMLM-pSYWyWgDLY17o21N',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ôpadoca Express',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Suas padarias favoritas na palma da mão',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

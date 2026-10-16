import 'dart:io';

import 'package:flutter/material.dart';

import '../models.dart';

class PersonaPhoto extends StatelessWidget {
  final Persona persona;
  final double? width, height;
  final BoxFit fit;
  const PersonaPhoto({super.key, required this.persona, this.width, this.height, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final align = Alignment(
      (persona.mouthX * 2 - 1).clamp(-1.0, 1.0),
      (((persona.eyeLY + persona.mouthY) / 2) * 2 - 1).clamp(-1.0, 1.0),
    );
    if (persona.asset != null) {
      return Image.asset(persona.asset!, width: width, height: height, fit: fit, alignment: align);
    }
    return Image.file(
      File(persona.photoPath!),
      width: width,
      height: height,
      fit: fit,
      alignment: align,
      cacheWidth: 500,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.black26,
        child: const Icon(Icons.person_rounded, size: 48),
      ),
    );
  }
}

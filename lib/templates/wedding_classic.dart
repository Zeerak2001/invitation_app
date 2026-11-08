import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'template_def.dart';

const _gold = Color(0xFFB08D57);
const _ink = Color(0xFF4A3B2A);

final weddingClassic = TemplateDef(
  id: 'wedding_classic',
  name: 'Classic Gold',
  category: 'Wedding',
  fields: const [
    FieldDef('names', 'Couple names', initial: 'Sara & Ali'),
    FieldDef(
      'message',
      'Message',
      multiline: true,
      initial:
          'Together with their families\ninvite you to celebrate their wedding',
    ),
    FieldDef(
      'date',
      'Date',
      type: FieldType.date,
      initial: 'Saturday, 12 December 2026',
    ),
    FieldDef('time', 'Time', type: FieldType.time, initial: '7:00 PM'),
    FieldDef(
      'venue',
      'Venue',
      type: FieldType.location,
      multiline: true,
      initial: 'The Grand Hall\nKarachi',
    ),
  ],
  builder: (d) => Container(
    color: const Color(0xFFFBF6EE),
    padding: const EdgeInsets.all(14),
    child: Container(
      decoration: BoxDecoration(border: Border.all(color: _gold, width: 1.5)),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'WEDDING INVITATION',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 13,
              letterSpacing: 4,
              color: _gold,
            ),
          ),
          Text(
            d['names'] ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.greatVibes(
              fontSize: 46,
              color: _ink,
              height: 1.1,
            ),
          ),
          Text(
            d['message'] ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 16,
              color: _ink,
              height: 1.4,
            ),
          ),
          Column(
            children: [
              Text(
                d['date'] ?? '',
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                d['time'] ?? '',
                style: GoogleFonts.cormorantGaramond(fontSize: 16, color: _ink),
              ),
            ],
          ),
          Text(
            d['venue'] ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 16,
              color: _ink,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  ),
);

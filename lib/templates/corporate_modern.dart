import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'template_def.dart';

const _navy = Color(0xFF14213D);
const _accent = Color(0xFFFCA311);

final corporateModern = TemplateDef(
  id: 'corporate_modern',
  name: 'Modern Navy',
  category: 'Corporate',
  fields: const [
    FieldDef('company', 'Company', initial: 'ACME Technologies'),
    FieldDef('event', 'Event title', initial: 'Annual Innovation Summit'),
    FieldDef(
      'message',
      'Description',
      multiline: true,
      initial: 'Join us for an evening of keynotes, demos and networking.',
    ),
    FieldDef('date', 'Date', type: FieldType.date, initial: '20 January 2027'),
    FieldDef('time', 'Time', type: FieldType.time, initial: '6:00 PM onwards'),
    FieldDef(
      'venue',
      'Venue',
      type: FieldType.location,
      initial: 'Marriott Hotel, Karachi',
    ),
  ],
  builder: (d) => Container(
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: Container(
            color: _navy,
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  (d['company'] ?? '').toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    letterSpacing: 3,
                    color: _accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  d['event'] ?? '',
                  style: GoogleFonts.montserrat(
                    fontSize: 30,
                    height: 1.15,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(height: 5, color: _accent),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  d['message'] ?? '',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row(Icons.calendar_today, d['date'] ?? ''),
                    _row(Icons.schedule, d['time'] ?? ''),
                    _row(Icons.place, d['venue'] ?? ''),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
);

Widget _row(IconData icon, String text) => Padding(
  padding: const EdgeInsets.only(top: 6),
  child: Row(
    children: [
      Icon(icon, size: 14, color: _navy),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _navy,
          ),
        ),
      ),
    ],
  ),
);

const geminiNeedClassificationSchema = {
  'type': 'OBJECT',
  'properties': {
    'categories': {
      'type': 'ARRAY',
      'items': {
        'type': 'STRING',
        'enum': ['hospital', 'general', 'professional', 'none'],
      },
      'minItems': 1,
      'description':
          'Actionable service categories. Use ["none"] only when there is no actionable need.',
    },
    'confidence': {
      'type': 'NUMBER',
      'minimum': 0,
      'maximum': 1,
      'description': 'Confidence from 0 to 1.',
    },
    'reason': {'type': 'STRING', 'description': 'A brief Korean reason.'},
  },
  'required': ['categories', 'confidence', 'reason'],
  'propertyOrdering': ['categories', 'confidence', 'reason'],
};

/// Display helpers for a stored portion ("1 cup", "2 pieces", "150 g").
///
/// Units are free text from parsers, barcodes or the user, so they are tidied
/// here rather than printed raw: underscores and stray spacing go, gram and
/// milliliter spellings collapse to "g" / "ml", and common countable units
/// pluralize ("2 pieces").
String foodPortionLabel(double quantity, String unit) {
  final amount = formatPortionQuantity(quantity);
  final label = displayUnit(unit, quantity: quantity);
  return label.isEmpty ? amount : '$amount $label';
}

/// "1" / "1.5" / "0.3": whole numbers without a trailing ".0".
String formatPortionQuantity(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}

/// A readable unit for [raw], pluralized for [quantity] when it's countable.
String displayUnit(String raw, {double quantity = 1}) {
  final cleaned = raw.trim().replaceAll(RegExp(r'[_\s]+'), ' ');
  if (cleaned.isEmpty) return '';
  final key = cleaned.toLowerCase();
  final alias = _aliases[key];
  if (alias != null) return alias;
  final singular = _countable.containsKey(key) ? key : _singularOf[key];
  if (singular == null) return cleaned;
  return quantity > 1 ? _countable[singular]! : singular;
}

const _aliases = {
  'g': 'g',
  'gm': 'g',
  'gms': 'g',
  'gr': 'g',
  'gram': 'g',
  'grams': 'g',
  'serving g': 'g',
  'ml': 'ml',
  'milliliter': 'ml',
  'milliliters': 'ml',
  'millilitre': 'ml',
  'millilitres': 'ml',
  'serving ml': 'ml',
  'kg': 'kg',
  'oz': 'oz',
  'lb': 'lb',
  'tbsp': 'tbsp',
  'tsp': 'tsp',
};

const _countable = {
  'serving': 'servings',
  'piece': 'pieces',
  'slice': 'slices',
  'bowl': 'bowls',
  'cup': 'cups',
  'plate': 'plates',
  'katori': 'katoris',
  'roti': 'rotis',
  'glass': 'glasses',
  'scoop': 'scoops',
  'bar': 'bars',
  'can': 'cans',
  'bottle': 'bottles',
  'packet': 'packets',
  'pack': 'packs',
  'handful': 'handfuls',
  'tablespoon': 'tablespoons',
  'teaspoon': 'teaspoons',
  'egg': 'eggs',
};

final _singularOf = {for (final e in _countable.entries) e.value: e.key};

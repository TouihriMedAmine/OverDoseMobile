class ReportCopy {
  static String aiSafetyOverviewLabel() => 'AI Safety Overview';

  static String aiSafetyOverviewSubtitle() =>
      'Trusted safety signals from verified report data.';

  static String neutralSummary({required String subject}) {
    return 'We have reviewed the available data for $subject. No major safety signal is currently highlighted, and additional verified insights will appear as they become available.';
  }

  static String partialSummary({required String subject}) {
    return 'This $subject has a partial analysis so far. The insights shown are based on verified signals only, and the report will deepen as more data is confirmed.';
  }

  static String minimalSummary({required String subject}) {
    return 'We do not yet have enough verified data to complete the $subject overview. The most reliable signals available are shown here.';
  }

  static String riskTableFallback() {
    return 'This report does not include a detailed risk table yet. We are showing the most reliable signals available and will expand this section as the analysis matures.';
  }

  static String scientificNotesFallback() {
    return 'No detailed scientific notes are available at the moment. We will enrich this section as more peer-reviewed evidence is linked to the ingredients.';
  }

  static String organImpactFallback() {
    return 'No specific organ impact signals are confirmed for this product right now. If new findings emerge, they will appear here.';
  }

  static String organImpactHint() {
    return 'Tap an organ chip to view the linked safety context.';
  }

  static String alternativesFallback() {
    return 'No credible alternatives were attached to this analysis yet.';
  }

  static String safetyReassurance() {
    return 'Based on the verified signals we have, this product does not show major safety concerns at the moment.';
  }

  static String scanAnalysisHint() {
    return 'Add photos, then run a single analysis pass across your queue.';
  }

  static String queueEmpty() {
    return 'Add one or more product photos to build a scan batch and launch your AI analysis.';
  }
}

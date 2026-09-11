import 'package:flutter_test/flutter_test.dart';
import 'package:smart_solar_mobile/models/proposal.dart';

void main() {
  test('proposal survey response parses the API list contract', () {
    final proposals = parseProposalList([
      {'id': 'proposal-1', 'proposalStatus': 'PENDING_APPROVAL'},
    ]);

    expect(proposals, hasLength(1));
    expect(EngineeringProposalModel.fromJson(proposals.first).id, 'proposal-1');
    expect(parseProposalList({'id': 'not-a-list'}), isEmpty);
  });

  test('all Phase 4 proposal statuses deserialize without client-side approval controls', () {
    const statuses = [
      'PENDING_APPROVAL',
      'APPROVED',
      'REJECTED',
      'REVISION_REQUESTED',
      'PROCESSING',
      'DRAFT',
    ];

    for (final status in statuses) {
      final proposal = EngineeringProposalModel.fromJson({
        'id': 'proposal-$status',
        'solarSurveyId': 'survey-1',
        'proposalStatus': status,
        'recommendedKw': 5,
        'panelCount': 12,
        'inverterSizeKw': 5,
        'estimatedCostLkr': 1000000,
        'gridComplianceStatus': 'COMPLIANT',
        'riskLevel': 'LOW',
        'safetyStatus': 'SAFE',
        'auditLogs': [],
      });
      expect(proposal.proposalStatus, status);
    }
  });
}
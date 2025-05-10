// Law tip notifier
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_life/models/lawtip_model.dart';

class LawTipsNotifier extends StateNotifier<List<LawTip>> {
  LawTipsNotifier()
      : super([
          LawTip(
            id: 'tip1',
            title: '휴게시간',
            summary:
                '근로기준법 제54조에 따라 사용자는 근로시간이 4시간인 경우 30분 이상, 8시간인 경우 1시간 이상의 휴게시간을 근로시간 도중에 주어야 합니다.',
            detailedContent:
                '휴게시간은 근로자가 자유롭게 이용할 수 있어야 합니다. 이 시간에 대해서는 임금을 지급할 의무가 없습니다. 휴게시간은 근로시간 도중에 주어야 하며, 일반적으로 식사시간 등으로 활용됩니다.\n\n'
                '특히 주의할 점은 휴게시간은 반드시 일하는 중간에 제공되어야 한다는 것입니다. 업무 시작 전이나 종료 후에 제공되는 시간은 휴게시간으로 인정되지 않습니다.',
            source: '근로기준법 제54조',
            category: '근무시간',
            relatedTipIds: ['tip2', 'tip3'],
          ),
          LawTip(
            id: 'tip2',
            title: '주휴수당',
            summary: '주휴수당은 1주일에 15시간 이상 근무한 근로자에게 1일치의 임금을 추가로 지급하는 제도입니다.',
            detailedContent:
                '주휴수당은 근로기준법에 따라 사용자가 근로자에게 제공해야 하는 유급휴일에 대한 수당입니다. 주 15시간 이상 근무한 근로자에게는 1주일에 1일 이상의 유급휴일을 보장해야 하며, 이때 지급되는 수당을 주휴수당이라고 합니다.\n\n'
                '주휴수당은 근로자의 기본급을 기준으로 계산되며, 주 소정근로시간을 만근한 경우 1일의 임금에 해당하는 금액을 지급받을 수 있습니다.',
            source: '근로기준법 제55조',
            category: '임금',
            relatedTipIds: ['tip1', 'tip4'],
          ),
          LawTip(
            id: 'tip3',
            title: '야간근로수당',
            summary: '오후 10시부터 오전 6시 사이의 근로에 대해서는 통상임금의 50%를 가산하여 지급해야 합니다.',
            detailedContent:
                '야간근로는 오후 10시부터 다음 날 오전 6시 사이의 근로를 의미합니다. 이 시간대에 근무하는 경우, 사용자는 통상임금의 50%를 추가로 지급해야 합니다.\n\n'
                '만약 연장근로와 야간근로가 중복되는 경우에는 각각의 가산율을 합하여 통상임금의 100%를 가산하여 지급해야 합니다. 즉, 연장근로수당 50%와 야간근로수당 50%를 합산한 금액입니다.',
            source: '근로기준법 제56조',
            category: '임금',
            relatedTipIds: ['tip2', 'tip4'],
          ),
          LawTip(
            id: 'tip4',
            title: '연차유급휴가',
            summary:
                '1년간 80% 이상 출근한 근로자에게는 15일의 유급휴가가 주어지며, 3년 이상 계속 근로한 근로자에게는 추가 유급휴가가 부여됩니다.',
            detailedContent:
                '연차유급휴가는 근로자가 1년간 80% 이상 출근한 경우 15일의 유급휴가를 사용할 수 있는 제도입니다. 또한 3년 이상 계속 근로한 근로자에게는 최초 1년을 초과하는 계속 근로 연수 매 2년에 대하여 1일을 가산한 유급휴가가 주어집니다.\n\n'
                '근로자는 연차유급휴가를 원하는 시기에 사용할 수 있으나, 사업 운영에 큰 지장이 있는 경우 사용자는 그 시기를 변경할 수 있습니다. 연차유급휴가는 1년 이내에 사용해야 하며, 사용하지 않은 휴가에 대해서는 금전으로 보상받을 수 있습니다.',
            source: '근로기준법 제60조',
            category: '휴가',
            relatedTipIds: ['tip1', 'tip2'],
          ),
        ]);

  // Get daily tip based on date
  LawTip getDailyTip() {
    final today = DateTime.now();
    final index = today.day % state.length;
    return state[index];
  }

  // Get tip by ID
  LawTip? getTipById(String id) {
    try {
      return state.firstWhere((tip) => tip.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get related tips
  List<LawTip> getRelatedTips(String tipId) {
    final currentTip = getTipById(tipId);
    if (currentTip == null) return [];

    return state
        .where((tip) => currentTip.relatedTipIds.contains(tip.id))
        .toList();
  }

  // Toggle bookmark
  void toggleBookmark(String tipId) {
    state = state.map((tip) {
      if (tip.id == tipId) {
        return tip.copyWith(isBookmarked: !tip.isBookmarked);
      }
      return tip;
    }).toList();
  }
}

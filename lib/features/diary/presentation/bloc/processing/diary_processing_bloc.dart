import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:kakikaki/core/base/bloc/base_bloc.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';
import 'package:kakikaki/features/diary/domain/model/diary_flow_models.dart';
import 'package:kakikaki/features/home/presentation/bloc/home_bloc.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'diary_processing_bloc.freezed.dart';
part 'diary_processing_event.dart';
part 'diary_processing_state.dart';

@injectable
class DiaryProcessingBloc
    extends BaseBloc<DiaryProcessingEvent, DiaryProcessingState> {
  DiaryProcessingBloc() : super(const DiaryProcessingState()) {
    onWithoutAutoLoading<DiaryProcessingStarted>(_onStarted);
    onWithoutAutoLoading<DiaryProcessingCompleted>((event, emit) => emit(
        state.copyWith(isDone: true, isError: false, result: event.result)));
    onWithoutAutoLoading<DiaryProcessingFailed>((event, emit) => emit(
        state.copyWith(
            isDone: true, isError: true, errorMessage: event.errorMessage)));
  }

  RealtimeChannel? _realtimeChannel;

  @override
  Future<void> close() {
    _realtimeChannel?.unsubscribe();
    return super.close();
  }

  Future<void> _onStarted(
      DiaryProcessingStarted event, Emitter<DiaryProcessingState> emit) async {
    await runBlocCatching(
      handleLoading: false, // 커스텀 로티 애니메이션 화면이므로 스피너 비활성화
      handleError: false, // 에러를 State로 받아서 화면에 그려주기 위해 공통 예외 팝업 비활성화
      action: () async {
        final client = SupabaseUtils.getClientOrNull();
        final userId = client?.auth.currentUser?.id;
        if (client == null || userId == null) {
          add(const DiaryProcessingEvent.failed('로그인 정보가 만료되었어요.'));
          return;
        }

        final payload = event.payload;
        final selectedDate = payload.date;
        final utcMidnight =
            DateTime(selectedDate.year, selectedDate.month, selectedDate.day)
                .toUtc();
        String diaryId;

        // 💡 1. 현재 앱에 설정된 언어 코드를 가져옵니다.
        final currentLangCode = getIt<GlobalBloc>().state.languageCode;

        if (payload.diaryId != null) {
          diaryId = payload.diaryId!;
          await client.from('diaries').update({
            'content': payload.content,
            'char_count': payload.content.length,
            'feedback_status': 'pending',
            'corrected_content': null,
            'language_code': currentLangCode, // 💡 2. 업데이트할 때 언어 코드 추가
          }).eq('id', diaryId);
        } else {
          final diaryInsert = await client
              .from('diaries')
              .insert({
                'user_id': userId,
                'content': payload.content,
                'char_count': payload.content.length,
                'created_at': utcMidnight.toIso8601String(),
                'feedback_status': 'pending',
                'language_code': currentLangCode, // 💡 3. 새로 저장할 때 언어 코드 추가
              })
              .select('id')
              .single();
          diaryId = (diaryInsert['id'] ?? '').toString();
        }

        final homeBloc = getIt<HomeBloc>();
        homeBloc.add(HomeEvent.dateChanged(payload.date));
        homeBloc.add(const HomeEvent.refreshDiary());
        homeBloc.add(HomeEvent.loadDiaryForDate(payload.date, true));

        _realtimeChannel = client
            .channel('diary_processing_$diaryId')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'diaries',
              filter: PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'id',
                  value: diaryId),
              callback: (payloadDb) async {
                final status = payloadDb.newRecord['feedback_status'];
                if (status == 'completed') {
                  _realtimeChannel?.unsubscribe();
                  final result = await _fetchFeedbackResultFromDB(
                      client, diaryId, payload.date, payload.content);
                  if (!isClosed) add(DiaryProcessingEvent.completed(result));
                } else if (status == 'failed') {
                  _realtimeChannel?.unsubscribe();
                  if (!isClosed) {
                    add(DiaryProcessingEvent.failed(
                        lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
                            .diary_processing_error));
                  }
                }
              },
            )
            .subscribe();

        final checkRes = await client
            .from('diaries')
            .select('feedback_status')
            .eq('id', diaryId)
            .single();
        if (checkRes['feedback_status'] == 'completed') {
          _realtimeChannel?.unsubscribe();
          final result = await _fetchFeedbackResultFromDB(
              client, diaryId, payload.date, payload.content);
          if (!isClosed) add(DiaryProcessingEvent.completed(result));
        }
      },
      doOnError: (e) {
        if (!isClosed) {
          add(DiaryProcessingEvent.failed(
              lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
                  .diary_processing_save_failed));
        }
      },
    );
  }

  Future<DiaryFeedbackResult> _fetchFeedbackResultFromDB(SupabaseClient client,
      String diaryId, DateTime date, String originalContent) async {
    final diaryRes =
        await client.from('diaries').select().eq('id', diaryId).single();
    final rawNotes = diaryRes['correction_notes'] as List<dynamic>? ?? [];
    final spellings = rawNotes
        .map((e) => SpellingFeedbackItem.fromJson({
              'original': e['original']?.toString() ?? '',
              'corrected': e['corrected']?.toString() ?? '',
              'reason': e['reason']?.toString() ?? ''
            }))
        .toList();

    final recsRes = await client.from('user_recommendations').select('''
      item_type,
      vocabulary ( word, reading, ruby, pos, meanings, examples, level ),
      grammar ( title, reading, ruby, meaning, connection, examples, level )
    ''').eq('diary_id', diaryId);

    final List<DiaryRecommendationItem> recommendations = [];
    final languageCode = getIt<GlobalBloc>().state.languageCode;

    for (var row in (recsRes as List<dynamic>)) {
      final type = row['item_type'];
      if (type == 'word' && row['vocabulary'] != null) {
        final v = row['vocabulary'];
        final examples = (v['examples'] as List<dynamic>?) ?? [];
        final firstEx = examples.isNotEmpty ? examples.first : {};

        final meaningsRaw = v['meanings'];
        String meaningTranslated = '';
        if (meaningsRaw is Map) {
          meaningTranslated = meaningsRaw[languageCode]?.toString() ??
              meaningsRaw['ko']?.toString() ??
              '';
        } else if (meaningsRaw is List && meaningsRaw.isNotEmpty) {
          meaningTranslated = meaningsRaw.first.toString();
        }

        recommendations.add(DiaryRecommendationItem(
          type: 'word',
          word: v['word']?.toString() ?? '',
          reading: v['reading']?.toString() ?? '',
          ruby: (v['ruby'] as String?)?.isNotEmpty == true
              ? v['ruby'] as String?
              : null,
          pos: PartOfSpeech.fromString(
              (v['pos'] as List?)?.firstOrNull?.toString() ?? ''),
          meaningTranslated: meaningTranslated,
          connection: '',
          exampleJp: firstEx['jp']?.toString() ?? '',
          exampleTranslated: firstEx['ko']?.toString() ?? '',
          exampleEn: firstEx['en']?.toString() ?? '',
          level: JLPTLevel.fromString(
              (v['level'] as List?)?.firstOrNull?.toString() ?? 'ETC'),
        ));
      } else if (type == 'grammar' && row['grammar'] != null) {
        final g = row['grammar'];
        final examples = (g['examples'] as List<dynamic>?) ?? [];
        final firstEx = examples.isNotEmpty ? examples.first : {};

        final meaningRaw = g['meaning'];
        String meaningTranslated = '';
        if (meaningRaw is Map) {
          meaningTranslated = meaningRaw[languageCode]?.toString() ??
              meaningRaw['ko']?.toString() ??
              '';
        } else if (meaningRaw is List && meaningRaw.isNotEmpty) {
          meaningTranslated = meaningRaw.first.toString();
        } else {
          meaningTranslated = meaningRaw?.toString() ?? '';
        }

        recommendations.add(DiaryRecommendationItem(
          type: 'grammar',
          word: g['title']?.toString() ?? '',
          reading: g['reading']?.toString() ?? '',
          ruby: (g['ruby'] as String?)?.isNotEmpty == true
              ? g['ruby'] as String?
              : null,
          pos: PartOfSpeech.etc,
          meaningTranslated: meaningTranslated,
          connection: g['connection']?.toString() ?? '',
          exampleJp: firstEx['jp']?.toString() ?? '',
          exampleTranslated: firstEx['ko']?.toString() ?? '',
          exampleEn: firstEx['en']?.toString() ?? '',
          level: JLPTLevel.fromString(g['level']?.toString() ?? 'ETC'),
        ));
      }
    }

    return DiaryFeedbackResult(
      diaryId: diaryId,
      date: date,
      originalText: diaryRes['content'] ?? originalContent,
      correctedText: diaryRes['corrected_content'] ?? originalContent,
      contentFurigana: diaryRes['content_furigana'] ?? '',
      correctedContentFurigana: diaryRes['corrected_content_furigana'] ?? '',
      spellingFeedback: spellings,
      recommendations: recommendations,
    );
  }
}

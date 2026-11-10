/// Display languages of the app's own text. Titles and episode names from
/// the source are never translated.
enum AppLanguage {
  en('en', 'EN - English'),
  km('km', 'KH - ភាសាខ្មែរ'),
  zh('zh', 'ZH - 中文');

  const AppLanguage(this.code, this.label);

  /// Stored in the settings box.
  final String code;

  /// Shown in Settings, the same in every language.
  final String label;

  /// Unknown or missing codes fall back to English.
  static AppLanguage fromCode(String? code) {
    for (final language in AppLanguage.values) {
      if (language.code == code) return language;
    }
    return AppLanguage.en;
  }
}

/// Every text the app shows by itself. Placeholders are written `{name}` and
/// filled by [AppStrings.fmt].
enum S {
  // Navigation and shared actions
  explore,
  library,
  settings,
  retry,
  cancel,
  refresh,
  clear,
  clearAll,
  loadFailed,

  // Weekdays, short
  weekdayMon,
  weekdayTue,
  weekdayWed,
  weekdayThu,
  weekdayFri,
  weekdaySat,
  weekdaySun,

  // Explore
  categorySchedule,
  categoryNewSeries,
  categoryPopular,
  categoryCompleted,
  released,
  exploreEmptyDay,
  exploreEmptyList,

  // Search
  search,
  searchHint,
  searchEmpty,

  // Detail
  favoriteAdd,
  favoriteRemove,
  favoriteAdded,
  favoriteRemoved,
  continueEpisode,
  watchNow,
  synopsis,
  episodes,
  episodesCount,
  switchToList,
  switchToGrid,
  episodesLoadFailed,
  noEpisodes,
  watchedProgress,
  episodeShort,

  // Library
  libraryTitle,
  history,
  favorites,
  historyEmptyTitle,
  historyEmptyBody,
  historyCount,
  clearHistoryQuestion,
  clearHistoryWarning,
  favoritesEmptyTitle,
  favoritesEmptyBody,
  episode,

  // Settings
  sectionGeneral,
  displayLanguage,
  chooseLanguage,
  sectionPlayback,
  defaultQuality,
  chooseQuality,
  qualityAuto,
  preferredSubtitle,
  chooseSubtitle,
  videoPlayer,
  chooseVideoPlayer,
  subtitleEnglish,
  subtitleIndonesian,
  subtitleNone,
  sectionData,
  clearHistory,
  clearHistoryDesc,
  clearHistoryConfirmTitle,
  clearHistoryConfirmBody,
  historyCleared,
  clearFavorites,
  clearFavoritesDesc,
  clearFavoritesConfirmTitle,
  clearFavoritesConfirmBody,
  favoritesCleared,
  clearCache,
  cacheUsage,
  cacheCalculating,
  cacheCleared,
  sectionAbout,
  versionLine,
  credits,
  creditPlayer,
  creditContents,
  development,
  developmentBody,
  privacy,
  privacyBody,

  // Player
  playerResolving,
  playerError,
  playerNoStreams,
  goBack,
  playerConnecting,
  playerServerWord,
  playerNoServer,
  retryStream,
  back,
  selectSource,
  rewind10,
  forward10,
  play,
  pause,
  playbackSpeed,
  nextEpisode,
}

const Map<S, String> _en = {
  S.explore: 'Explore',
  S.library: 'Library',
  S.settings: 'Settings',
  S.retry: 'Retry',
  S.cancel: 'Cancel',
  S.refresh: 'Refresh',
  S.clear: 'Clear',
  S.clearAll: 'Clear All',
  S.loadFailed: 'Could not load. Check your connection and try again.',

  S.weekdayMon: 'Mon',
  S.weekdayTue: 'Tue',
  S.weekdayWed: 'Wed',
  S.weekdayThu: 'Thu',
  S.weekdayFri: 'Fri',
  S.weekdaySat: 'Sat',
  S.weekdaySun: 'Sun',

  S.categorySchedule: 'Schedule',
  S.categoryNewSeries: 'New Series',
  S.categoryPopular: 'Popular',
  S.categoryCompleted: 'Completed',
  S.released: 'Released',
  S.exploreEmptyDay: 'No shows are scheduled for this day.',
  S.exploreEmptyList: 'Nothing to show yet.',

  S.search: 'Search',
  S.searchHint: 'Search Donghua (e.g. BTTH, Soul Land)...',
  S.searchEmpty: 'No donghua found. Try another title.',

  S.favoriteAdd: 'Add to Favorites',
  S.favoriteRemove: 'Remove Favorite',
  S.favoriteAdded: 'Added to favorites',
  S.favoriteRemoved: 'Removed from favorites',
  S.continueEpisode: 'Continue Ep {number} ({time})',
  S.watchNow: 'Watch Now • {title}',
  S.synopsis: 'Synopsis',
  S.episodes: 'Episodes',
  S.episodesCount: 'Episodes ({count})',
  S.switchToList: 'Switch to List',
  S.switchToGrid: 'Switch to Grid',
  S.episodesLoadFailed: 'Could not load the episodes.',
  S.noEpisodes: 'No episodes available.',
  S.watchedProgress: 'Watched {position} / {duration}',
  S.episodeShort: 'EP {number}',

  S.libraryTitle: 'My Library',
  S.history: 'History',
  S.favorites: 'Favorites',
  S.historyEmptyTitle: 'No watch history yet',
  S.historyEmptyBody: 'Episodes you start watching will appear here.',
  S.historyCount: '{count} items',
  S.clearHistoryQuestion: 'Clear Watch History?',
  S.clearHistoryWarning: 'All your progress and resume points will be removed.',
  S.favoritesEmptyTitle: 'No favorite donghua yet',
  S.favoritesEmptyBody: 'Tap the heart icon on any donghua to save it here.',
  S.episode: 'Episode',

  S.sectionGeneral: 'GENERAL',
  S.displayLanguage: 'Display Language',
  S.chooseLanguage: 'Choose Display Language',
  S.sectionPlayback: 'PLAYBACK PREFERENCES',
  S.defaultQuality: 'Default Stream Quality',
  S.chooseQuality: 'Choose Default Quality',
  S.qualityAuto: 'Auto',
  S.preferredSubtitle: 'Preferred Subtitle Language',
  S.chooseSubtitle: 'Preferred Subtitle',
  S.videoPlayer: 'Video Player',
  S.chooseVideoPlayer: 'Choose Video Player',
  S.subtitleEnglish: 'English',
  S.subtitleIndonesian: 'Indonesian',
  S.subtitleNone: 'None',
  S.sectionData: 'DATA & STORAGE',
  S.clearHistory: 'Clear Watch History',
  S.clearHistoryDesc: 'Remove all watched progress and history entries',
  S.clearHistoryConfirmTitle: 'Clear History?',
  S.clearHistoryConfirmBody: 'This will erase all recorded watch progress.',
  S.historyCleared: 'Watch history cleared',
  S.clearFavorites: 'Clear Favorites',
  S.clearFavoritesDesc: 'Remove all saved donghua favorites',
  S.clearFavoritesConfirmTitle: 'Clear Favorites?',
  S.clearFavoritesConfirmBody:
      'All saved shows will be removed from your library.',
  S.favoritesCleared: 'Favorites cleared',
  S.clearCache: 'Clear Cache',
  S.cacheUsage: '{used} of {limit}',
  S.cacheCalculating: 'Measuring...',
  S.cacheCleared: 'Cache cleared',
  S.sectionAbout: 'ABOUT',
  S.versionLine: 'Version {version}',
  S.credits: 'Credits',
  S.creditPlayer: 'Player',
  S.creditContents: 'Contents',
  S.development: 'Development',
  S.developmentBody: 'AMSCenter by AMSDev',
  S.privacy: 'Privacy',
  S.privacyBody:
      'No ads.\n'
      'No tracking.\n'
      'History and favorites\n'
      'are stored only on this device.',

  S.playerResolving: 'Resolving stream sources...',
  S.playerError: 'Error: {error}',
  S.playerNoStreams: 'No active streams available.',
  S.goBack: 'Go Back',
  S.playerConnecting: 'Connecting to {server} ({index}/{total})',
  S.playerServerWord: 'server',
  S.playerNoServer:
      'No server could play this episode. Check your connection and retry.',
  S.retryStream: 'Retry Stream',
  S.back: 'Back',
  S.selectSource: 'Select Server / Quality',
  S.rewind10: 'Rewind 10 seconds',
  S.forward10: 'Forward 10 seconds',
  S.play: 'Play',
  S.pause: 'Pause',
  S.playbackSpeed: 'Playback Speed',
  S.nextEpisode: 'Next Episode',
};

const Map<S, String> _km = {
  S.explore: 'រុករក',
  S.library: 'បណ្ណាល័យ',
  S.settings: 'ការកំណត់',
  S.retry: 'ព្យាយាមម្ដងទៀត',
  S.cancel: 'បោះបង់',
  S.refresh: 'ផ្ទុកឡើងវិញ',
  S.clear: 'លុប',
  S.clearAll: 'លុបទាំងអស់',
  S.loadFailed:
      'មិនអាចផ្ទុកបានទេ។ សូមពិនិត្យការតភ្ជាប់អ៊ីនធឺណិត រួចព្យាយាមម្ដងទៀត។',

  S.weekdayMon: 'ច័ន្ទ',
  S.weekdayTue: 'អង្គារ',
  S.weekdayWed: 'ពុធ',
  S.weekdayThu: 'ព្រហ',
  S.weekdayFri: 'សុក្រ',
  S.weekdaySat: 'សៅរ៍',
  S.weekdaySun: 'អាទិត្យ',

  S.categorySchedule: 'កាលវិភាគ',
  S.categoryNewSeries: 'រឿងថ្មី',
  S.categoryPopular: 'ពេញនិយម',
  S.categoryCompleted: 'បានបញ្ចប់',
  S.released: 'ចេញហើយ',
  S.exploreEmptyDay: 'គ្មានរឿងក្នុងកាលវិភាគសម្រាប់ថ្ងៃដែលបានជ្រើសទេ។',
  S.exploreEmptyList: 'មិនទាន់មានរឿងសម្រាប់បង្ហាញទេ។',

  S.search: 'ស្វែងរក',
  S.searchHint: 'ស្វែងរក Donghua (ឧ. BTTH, Soul Land)...',
  S.searchEmpty: 'រកមិនឃើញ Donghua ទេ។ សូមសាកចំណងជើងផ្សេង។',

  S.favoriteAdd: 'បន្ថែមទៅចំណូលចិត្ត',
  S.favoriteRemove: 'ដកចេញពីចំណូលចិត្ត',
  S.favoriteAdded: 'បានបន្ថែមទៅចំណូលចិត្ត',
  S.favoriteRemoved: 'បានដកចេញពីចំណូលចិត្ត',
  S.continueEpisode: 'មើលបន្ត ភាគ {number} ({time})',
  S.watchNow: 'មើលឥឡូវនេះ • {title}',
  S.synopsis: 'សាច់រឿងសង្ខេប',
  S.episodes: 'បញ្ជីភាគ',
  S.episodesCount: 'បញ្ជីភាគ ({count})',
  S.switchToList: 'បង្ហាញជាបញ្ជី',
  S.switchToGrid: 'បង្ហាញជាក្រឡា',
  S.episodesLoadFailed: 'មិនអាចផ្ទុកបញ្ជីភាគបានទេ។',
  S.noEpisodes: 'មិនទាន់មានភាគទេ។',
  S.watchedProgress: 'បានមើល {position} / {duration}',
  S.episodeShort: 'ភាគ {number}',

  S.libraryTitle: 'បណ្ណាល័យរបស់ខ្ញុំ',
  S.history: 'ប្រវត្តិ',
  S.favorites: 'ចំណូលចិត្ត',
  S.historyEmptyTitle: 'មិនទាន់មានប្រវត្តិការមើលទេ',
  S.historyEmptyBody: 'ភាគដែលអ្នកចាប់ផ្ដើមមើលនឹងបង្ហាញនៅទីនេះ។',
  S.historyCount: '{count} ភាគ',
  S.clearHistoryQuestion: 'លុបប្រវត្តិការមើល?',
  S.clearHistoryWarning: 'វឌ្ឍនភាពការមើល និងចំណុចមើលបន្តទាំងអស់នឹងត្រូវលុប។',
  S.favoritesEmptyTitle: 'មិនទាន់មាន Donghua ក្នុងចំណូលចិត្តទេ',
  S.favoritesEmptyBody: 'ចុចរូបបេះដូងលើ Donghua ណាមួយ ដើម្បីរក្សាទុកនៅទីនេះ។',
  S.episode: 'ភាគ',

  S.sectionGeneral: 'ទូទៅ',
  S.displayLanguage: 'ភាសាបង្ហាញ',
  S.chooseLanguage: 'ជ្រើសរើសភាសាបង្ហាញ',
  S.sectionPlayback: 'ការកំណត់ការចាក់វីដេអូ',
  S.defaultQuality: 'គុណភាពវីដេអូលំនាំដើម',
  S.chooseQuality: 'ជ្រើសរើសគុណភាពលំនាំដើម',
  S.qualityAuto: 'ស្វ័យប្រវត្តិ',
  S.preferredSubtitle: 'ភាសាអក្សររត់',
  S.chooseSubtitle: 'ជ្រើសរើសភាសាអក្សររត់',
  S.videoPlayer: 'ម៉ាស៊ីនចាក់វីដេអូ',
  S.chooseVideoPlayer: 'ជ្រើសរើសម៉ាស៊ីនចាក់វីដេអូ',
  S.subtitleEnglish: 'អង់គ្លេស',
  S.subtitleIndonesian: 'ឥណ្ឌូនេស៊ី',
  S.subtitleNone: 'គ្មាន',
  S.sectionData: 'ទិន្នន័យ និងទំហំផ្ទុក',
  S.clearHistory: 'លុបប្រវត្តិការមើល',
  S.clearHistoryDesc: 'លុបវឌ្ឍនភាពការមើល និងប្រវត្តិទាំងអស់',
  S.clearHistoryConfirmTitle: 'លុបប្រវត្តិ?',
  S.clearHistoryConfirmBody: 'វឌ្ឍនភាពការមើលដែលបានរក្សាទុកទាំងអស់នឹងត្រូវលុប។',
  S.historyCleared: 'បានលុបប្រវត្តិការមើល',
  S.clearFavorites: 'លុបបញ្ជីចំណូលចិត្ត',
  S.clearFavoritesDesc: 'លុប Donghua ទាំងអស់ចេញពីចំណូលចិត្ត',
  S.clearFavoritesConfirmTitle: 'លុបបញ្ជីចំណូលចិត្ត?',
  S.clearFavoritesConfirmBody:
      'រឿងដែលបានរក្សាទុកទាំងអស់នឹងត្រូវដកចេញពីបណ្ណាល័យរបស់អ្នក។',
  S.favoritesCleared: 'បានលុបបញ្ជីចំណូលចិត្ត',
  S.clearCache: 'សម្អាត Cache',
  S.cacheUsage: '{used} ក្នុងចំណោម {limit}',
  S.cacheCalculating: 'កំពុងវាស់...',
  S.cacheCleared: 'បានសម្អាត Cache',
  S.sectionAbout: 'អំពីកម្មវិធី',
  S.versionLine: 'កំណែ {version}',
  S.credits: 'ការទទួលស្គាល់',
  S.creditPlayer: 'កម្មវិធីចាក់',
  S.creditContents: 'មាតិកា',
  S.development: 'ការអភិវឌ្ឍ',
  S.developmentBody: 'AMSCenter ដោយ AMSDev',
  S.privacy: 'ឯកជនភាព',
  S.privacyBody:
      'គ្មានការផ្សាយពាណិជ្ជកម្ម។\n'
      'គ្មានការតាមដាន។\n'
      'ប្រវត្តិ និងចំណូលចិត្ត\n'
      'ត្រូវបានរក្សាទុកតែលើឧបករណ៍នេះប៉ុណ្ណោះ។',

  S.playerResolving: 'កំពុងស្វែងរកប្រភពវីដេអូ...',
  S.playerError: 'បញ្ហា៖ {error}',
  S.playerNoStreams: 'មិនមានប្រភពវីដេអូដែលអាចចាក់បានទេ។',
  S.goBack: 'ត្រឡប់ក្រោយ',
  S.playerConnecting: 'កំពុងភ្ជាប់ទៅ {server} ({index}/{total})',
  S.playerServerWord: 'Server',
  S.playerNoServer:
      'គ្មាន Server ណាអាចចាក់ភាគនេះបានទេ។ '
      'សូមពិនិត្យការតភ្ជាប់អ៊ីនធឺណិត រួចព្យាយាមម្ដងទៀត។',
  S.retryStream: 'សាកចាក់ម្ដងទៀត',
  S.back: 'ត្រឡប់ក្រោយ',
  S.selectSource: 'ជ្រើសរើស Server / គុណភាព',
  S.rewind10: 'ថយក្រោយ 10 វិនាទី',
  S.forward10: 'ទៅមុខ 10 វិនាទី',
  S.play: 'ចាក់',
  S.pause: 'ផ្អាក',
  S.playbackSpeed: 'ល្បឿនចាក់',
  S.nextEpisode: 'ភាគបន្ទាប់',
};

/// Simplified Chinese (TASK-034).
const Map<S, String> _zh = {
  S.explore: '发现',
  S.library: '片库',
  S.settings: '设置',
  S.retry: '重试',
  S.cancel: '取消',
  S.refresh: '刷新',
  S.clear: '清除',
  S.clearAll: '全部清除',
  S.loadFailed: '无法加载。请检查网络后重试。',

  S.weekdayMon: '周一',
  S.weekdayTue: '周二',
  S.weekdayWed: '周三',
  S.weekdayThu: '周四',
  S.weekdayFri: '周五',
  S.weekdaySat: '周六',
  S.weekdaySun: '周日',

  S.categorySchedule: '更新表',
  S.categoryNewSeries: '新番',
  S.categoryPopular: '热门',
  S.categoryCompleted: '已完结',
  S.released: '已更新',
  S.exploreEmptyDay: '这一天没有排期的节目。',
  S.exploreEmptyList: '暂无内容。',

  S.search: '搜索',
  S.searchHint: '搜索国漫（如 BTTH、Soul Land）…',
  S.searchEmpty: '未找到国漫。请换个标题试试。',

  S.favoriteAdd: '加入收藏',
  S.favoriteRemove: '取消收藏',
  S.favoriteAdded: '已加入收藏',
  S.favoriteRemoved: '已取消收藏',
  S.continueEpisode: '继续观看第 {number} 集（{time}）',
  S.watchNow: '立即观看 • {title}',
  S.synopsis: '简介',
  S.episodes: '剧集',
  S.episodesCount: '剧集（{count}）',
  S.switchToList: '切换为列表',
  S.switchToGrid: '切换为网格',
  S.episodesLoadFailed: '无法加载剧集。',
  S.noEpisodes: '暂无剧集。',
  S.watchedProgress: '已观看 {position} / {duration}',
  S.episodeShort: '第 {number} 集',

  S.libraryTitle: '我的片库',
  S.history: '历史',
  S.favorites: '收藏',
  S.historyEmptyTitle: '暂无观看历史',
  S.historyEmptyBody: '开始观看的剧集会显示在这里。',
  S.historyCount: '{count} 项',
  S.clearHistoryQuestion: '清除观看历史？',
  S.clearHistoryWarning: '所有观看进度和续播位置都将被删除。',
  S.favoritesEmptyTitle: '暂无收藏的国漫',
  S.favoritesEmptyBody: '点按任意国漫上的爱心图标即可收藏到这里。',
  S.episode: '集数',

  S.sectionGeneral: '常规',
  S.displayLanguage: '显示语言',
  S.chooseLanguage: '选择显示语言',
  S.sectionPlayback: '播放偏好',
  S.defaultQuality: '默认画质',
  S.chooseQuality: '选择默认画质',
  S.qualityAuto: '自动',
  S.preferredSubtitle: '首选字幕语言',
  S.chooseSubtitle: '首选字幕',
  S.videoPlayer: '视频播放器',
  S.chooseVideoPlayer: '选择视频播放器',
  S.subtitleEnglish: '英语',
  S.subtitleIndonesian: '印尼语',
  S.subtitleNone: '无',
  S.sectionData: '数据与存储',
  S.clearHistory: '清除观看历史',
  S.clearHistoryDesc: '删除所有观看进度和历史记录',
  S.clearHistoryConfirmTitle: '清除历史？',
  S.clearHistoryConfirmBody: '这将删除所有已记录的观看进度。',
  S.historyCleared: '观看历史已清除',
  S.clearFavorites: '清除收藏',
  S.clearFavoritesDesc: '删除所有已收藏的国漫',
  S.clearFavoritesConfirmTitle: '清除收藏？',
  S.clearFavoritesConfirmBody: '所有已收藏的节目都将从片库中移除。',
  S.favoritesCleared: '收藏已清除',
  S.clearCache: '清除缓存',
  S.cacheUsage: '{used} / {limit}',
  S.cacheCalculating: '正在计算…',
  S.cacheCleared: '缓存已清除',
  S.sectionAbout: '关于',
  S.versionLine: '版本 {version}',
  S.credits: '致谢',
  S.creditPlayer: '播放器',
  S.creditContents: '内容',
  S.development: '开发',
  S.developmentBody: 'AMSCenter by AMSDev',
  S.privacy: '隐私',
  S.privacyBody:
      '无广告。\n'
      '无追踪。\n'
      '历史和收藏\n'
      '仅保存在此设备上。',

  S.playerResolving: '正在解析视频源…',
  S.playerError: '错误：{error}',
  S.playerNoStreams: '没有可用的视频源。',
  S.goBack: '返回',
  S.playerConnecting: '正在连接 {server}（{index}/{total}）',
  S.playerServerWord: '服务器',
  S.playerNoServer: '没有服务器能播放这一集。请检查网络后重试。',
  S.retryStream: '重新播放',
  S.back: '返回',
  S.selectSource: '选择服务器 / 画质',
  S.rewind10: '后退 10 秒',
  S.forward10: '前进 10 秒',
  S.play: '播放',
  S.pause: '暂停',
  S.playbackSpeed: '播放速度',
  S.nextEpisode: '下一集',
};

final RegExp _placeholder = RegExp(r'\{(\w+)\}');

const List<S> _weekdayKeys = [
  S.weekdayMon,
  S.weekdayTue,
  S.weekdayWed,
  S.weekdayThu,
  S.weekdayFri,
  S.weekdaySat,
  S.weekdaySun,
];

/// The strings of one language. Widgets get it from `stringsProvider`.
class AppStrings {
  final AppLanguage language;

  const AppStrings(this.language);

  /// The whole table of [language]. Used by the tests.
  static Map<S, String> tableOf(AppLanguage language) {
    switch (language) {
      case AppLanguage.en:
        return _en;
      case AppLanguage.km:
        return _km;
      case AppLanguage.zh:
        return _zh;
    }
  }

  /// The text for [key]. A key that is missing in [language] falls back to
  /// English, so the UI never shows an empty label.
  String call(S key) => tableOf(language)[key] ?? _en[key] ?? key.name;

  /// The text for [key] with every `{name}` placeholder replaced by
  /// `args[name]`. It is one pass over the template, so a value that itself
  /// contains braces (a title from the source) is never expanded again.
  String fmt(S key, Map<String, Object> args) {
    return call(key).replaceAllMapped(_placeholder, (match) {
      final value = args[match.group(1)];
      return value == null ? match.group(0)! : '$value';
    });
  }

  /// Short weekday name, 1 (Monday) to 7 (Sunday). Other values are clamped.
  String weekdayShort(int day) => call(_weekdayKeys[day.clamp(1, 7) - 1]);
}

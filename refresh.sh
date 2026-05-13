#!/bin/bash
# 재생목록에 새 영상을 올린 뒤 실행하면 videos.json이 갱신됩니다.
set -e
cd "$(dirname "$0")"

YT_DLP="${HOME}/Library/Python/3.9/bin/yt-dlp"
PLAYLIST_URL="https://youtube.com/playlist?list=PLHfcFNenGFHCTBmwUxo_qXw_BPE1mDtot"

echo "→ Fetching playlist..."
"$YT_DLP" --flat-playlist --dump-single-json "$PLAYLIST_URL" > playlist_raw.json

echo "→ Rebuilding videos.json..."
python3 << 'EOF'
import json
with open('playlist_raw.json') as f:
    data = json.load(f)

# 리스트 하단으로 보낼 영상 ID (재생목록 내 순서와 무관하게 맨 뒤로)
PIN_TO_BOTTOM = [
    'lNEVSwurS1w',  # 인형 남은 구멍 오므리기, 마무리하는 방법
    'NgbynZusqn4',  # How to crochet a knit-like stitch (짧은뜨기 메리야스뜨기)
    'UgifLbsuWYM',  # 뜨개인형 손가락 연결방법
    'Gss1ySXmKF4',  # How to make the most perfect circle without the pillar nose
]

# 상품 소개 영상 ID — 메인 그리드에서 빠지고 하단 "뜨린이 추천 상품" 코너로 이동
PRODUCT_IDS = [
    'kfg6TmAoDXM',  # 뜨개초보인데, 너무 헷갈려요
    'L_a1kfHgkE8',  # When I see a beginner knitter, I want to help them...
    'whWT8fWAmoQ',  # I just couldn't pass it up
]

# 리스트에서 숨길 영상 ID (기초기법과 무관한 영상 등)
EXCLUDE_IDS = {
    '-y2MmAyS4wg',  # 공중부얀 _ 뜨개실홀더, 얀스피너 소개 및 제작방법
    'yRFXfuOLkv4',  # 긴뜨기 뜨는 방법입니다 :)
    'vcmM0ap84_E',  # 한길긴뜨기 뜨는 방법입니다 :)
    'SYyqfSWEEwc',  # 3강. 코늘리기
    'c3dNs_Rm0r0',  # 4강. 코줄이기
}

# 영문 코바늘 용어 → 한국어 별칭 (검색용)
# 긴 패턴부터 먼저 매칭하기 위해 단어 길이 내림차순으로 적용됨
TERM_ALIASES = {
    # 기본 스티치
    'magic ring': ['매직링', '매직 링', '원형코', '매직서클', '시작코'],
    'chain': ['사슬', '사슬뜨기', '체인', 'ch'],
    'slip stitch': ['빼뜨기', '빼뜨', '슬립스티치', 'sl st', 'slst'],
    'single crochet': ['짧은뜨기', '짧뜨', '단뜨기', 'sc'],
    'half double crochet': ['긴뜨기', '반긴뜨기', 'hdc'],
    'double crochet': ['한길긴뜨기', '한길긴', '더블크로셰', 'dc'],
    'treble crochet': ['두길긴뜨기', '두길긴', '트리플', 'tr'],
    'double treble crochet': ['세길긴뜨기', '세길긴', 'dtr'],
    'triple treble crochet': ['네길긴뜨기', '네길긴', 'trtr'],
    # 코 늘리기/줄이기
    'increase': ['코늘리기', '늘리기', '늘림코', '늘림'],
    'stitches together': ['코줄이기', '줄이기', '줄임코', '줄임', '모아뜨기'],
    'stitch together': ['코줄이기', '줄이기', '줄임', '모아뜨기'],
    # 앞/뒤 고리/기둥
    'back loops only': ['뒷고리', '뒷코뜨기', '뒷루프', 'blo'],
    'front loops only': ['앞고리', '앞코뜨기', '앞루프', 'flo'],
    'back post': ['뒷기둥', '뒷걸어뜨기', '뒤걸어뜨기'],
    'front post': ['앞기둥', '앞걸어뜨기'],
    'reverse': ['역방향', '새우뜨기', '리버스'],
    # 변형 스티치
    'bobble stitch': ['방울뜨기', '보블', '보블스티치'],
    'bobble': ['방울뜨기', '보블'],
    'puff stitch': ['퍼프뜨기', '퍼프', '퍼프스티치'],
    'puff': ['퍼프뜨기', '퍼프'],
    'popcorn stitch': ['팝콘뜨기', '팝콘'],
    'popcorn': ['팝콘뜨기', '팝콘'],
    'picot': ['피코', '피콧'],
    'cross over': ['교차뜨기', '교차', '크로스오버'],
    'loop stitch': ['루프뜨기', '루프스티치'],
    'twisted': ['꼬임뜨기', '꼬임', '트위스티드'],
    'y stitch': ['y자뜨기', 'y스티치'],
    'inverted': ['역', '뒤집힌'],
    # 코드/매듭
    'romanian cord': ['루마니안 코드', '루마니아 코드', '루마니안코드'],
    'cord': ['코드', '끈'],
    'solomon': ['솔로몬', '솔로몬매듭', '솔로몬 매듭'],
    'lover': ['러버스', '러버스놋'],
    'knot': ['매듭', '놋'],
    # 기타
    'pillar nose': ['기둥코', '기둥'],
    'perfect circle': ['완벽한 원', '깔끔한 원'],
    'circle': ['원형', '원'],
    'knit-like': ['니트같은', '니트풍'],
    'how to': ['방법', '법'],
    'how to crochet': ['뜨는법', '뜨는 법', '뜨는방법'],
    'how to make': ['만드는법', '만드는 법'],
}

# 숫자 prefix는 따로 처리 ("2 single crochet increase" → "sc 2코늘림" 등)
def build_keywords(title):
    """제목에서 한국어 검색 키워드 생성"""
    t = title.lower()
    kws = set()
    # 긴 표현부터 매칭 (single crochet 보다 single crochet increase가 먼저)
    for term in sorted(TERM_ALIASES.keys(), key=len, reverse=True):
        if term in t:
            for a in TERM_ALIASES[term]:
                kws.add(a)
    # 숫자가 앞에 붙는 경우 ("2 single crochet increase")
    import re
    m = re.match(r'^(\d+)\s+', title)
    if m:
        n = m.group(1)
        # n코늘림/n코줄임 형태 추가
        if 'increase' in t:
            kws.add(f'{n}코늘림')
            kws.add(f'{n}코 늘림')
            kws.add(f'{n}코늘리기')
        if 'together' in t:
            kws.add(f'{n}코줄임')
            kws.add(f'{n}코 줄임')
            kws.add(f'{n}코줄이기')
    return sorted(kws)

def is_unavailable(entry):
    title = (entry.get('title') or '').strip()
    avail = entry.get('availability')
    if avail in ('private', 'needs_auth', 'subscriber_only', 'premium_only'):
        return True
    if title in ('[Private video]', '[Deleted video]', '[Unavailable]'):
        return True
    return False

videos = []
seen_ids = set()
for e in data.get('entries', []):
    if is_unavailable(e):
        continue
    vid_id = e.get('id')
    if vid_id in EXCLUDE_IDS or vid_id in seen_ids:
        continue
    seen_ids.add(vid_id)
    title = (e.get('title') or '').strip()
    videos.append({
        'id': vid_id,
        'title': title,
        'keywords': build_keywords(title),
        'thumbnail': f"https://i.ytimg.com/vi/{vid_id}/hqdefault.jpg",
        'duration': e.get('duration'),
    })

# 상품 영상 분리
product_set = set(PRODUCT_IDS)
products_lookup = {v['id']: v for v in videos if v['id'] in product_set}
products = [products_lookup[i] for i in PRODUCT_IDS if i in products_lookup]
videos = [v for v in videos if v['id'] not in product_set]

# 지정된 영상은 맨 뒤로 (PIN_TO_BOTTOM 순서 유지)
pinned_set = set(PIN_TO_BOTTOM)
top = [v for v in videos if v['id'] not in pinned_set]
pinned_lookup = {v['id']: v for v in videos if v['id'] in pinned_set}
bottom = [pinned_lookup[i] for i in PIN_TO_BOTTOM if i in pinned_lookup]
videos = top + bottom

out = {
    'playlist_title': data.get('title'),
    'channel': data.get('uploader') or data.get('channel'),
    'playlist_id': data.get('id'),
    'count': len(videos),
    'videos': videos,
    'products': products,
}

with open('videos.json', 'w', encoding='utf-8') as f:
    json.dump(out, f, ensure_ascii=False, indent=2)

print(f"  ✓ {len(videos)} videos")
EOF

echo "→ Done. Commit & push to redeploy."
